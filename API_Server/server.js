require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const multer = require('multer');
const { Readable } = require('stream');
const Documento = require('./models/Documento');
const Funcionario = require('./models/Funcionario'); 
const Maquina = require('./models/Maquina');
const Empresa = require('./models/Empresa');
const iniciarAutomacoes = require('./services/cron'); 
const fs = require('fs');
const path = require('path');
const os = require('os');
const util = require('util');
const exec = util.promisify(require('child_process').exec);

const app = express();
app.use(express.json());

// 1. Conexão Atlas
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('✅ Conectado ao MongoDB Atlas'))
  .catch(err => console.error('❌ Erro de conexão:', err));

// 2. Configuração do GridFS (Bucket)
let gfsBucket;
mongoose.connection.once('open', () => {
  gfsBucket = new mongoose.mongo.GridFSBucket(mongoose.connection.db, {
    bucketName: 'pdfs_bucket'
  });
  console.log("✅ GridFS Bucket (Manual) pronto.");
});

// 3. Multer em Memória
const storage = multer.memoryStorage();
const upload = multer({ storage });

// --- FUNÇÃO AUXILIAR PARA FILTROS DE DATA ---
const aplicarFiltroValidade = (query, status) => {
  const hoje = new Date();
  if (status === 'valido') {
    query.dataValidade = { $gte: hoje };
  } else if (status === 'vencido') {
    query.dataValidade = { $lt: hoje };
  }
  return query;
};

iniciarAutomacoes(); 

// ==========================================
// ROTAS GERAIS E DE LISTAGEM (Devem vir antes do :id)
// ==========================================

// 1. CADASTRAR DOCUMENTO (UPLOAD)
app.post('/documentos', upload.single('pdf'), async (req, res) => {
  try {

    if (!req.file) return res.status(400).send('Arquivo não recebido.');
    if (!req.body.dados) return res.status(400).send('Campo dados não recebido.');

    let dados;
    try {
      dados = JSON.parse(req.body.dados);
    } catch (e) {
      return res.status(400).send('JSON inválido: ' + e.message);
    }

    const { entidadeId, entidadeTipo, tipoDocumento, nomeDocumento, dataValidade } = dados;

    if (!entidadeId) return res.status(400).send('entidadeId obrigatório.');

    const fileName = `${Date.now()}-athena-${req.file.originalname}`;
    const uploadStream = gfsBucket.openUploadStream(fileName, {
      metadata: { contentType: req.file.mimetype } 
    });

    const bufferStream = new Readable();
    bufferStream.push(req.file.buffer);
    bufferStream.push(null);
    bufferStream.pipe(uploadStream);

    uploadStream.on('finish', async () => {
      try {
        const novoDoc = new Documento({
          nomeDocumento,
          entidadeId,
          entidadeTipo,
          tipoDocumento,
          dataValidade,
          fileId: uploadStream.id
        });
        await novoDoc.save();
        res.status(201).json({ mensagem: 'Documento salvo com sucesso!', fileId: uploadStream.id });
      } catch (saveErr) {
        res.status(500).send('Erro ao salvar metadados: ' + saveErr.message);
      }
    });

    uploadStream.on('error', (err) => {
      res.status(500).send('Erro no GridFS: ' + err.message);
    });

  } catch (err) {
    res.status(500).send('Erro interno: ' + err.message);
  }
});

// 2. ALERTAS: VENCEM EM 30 DIAS OU MENOS
app.get('/alertas/documentos-a-vencer', async (req, res) => {
  try {
    const hoje = new Date();
    const trintaDias = new Date();
    trintaDias.setDate(hoje.getDate() + 30);

    const docs = await Documento.aggregate([
      {
        $match: {
          ativo: true,
          dataValidade: { $lte: trintaDias }
        }
      },
      {
        $lookup: {
          from: 'funcionarios',
          localField: 'entidadeId',
          foreignField: '_id',
          as: 'dadosFuncionario'
        }
      },
      {
        $unwind: {
          path: '$dadosFuncionario',
          preserveNullAndEmptyArrays: true
        }
      },
      {
        $addFields: {
          nomeFuncionario: '$dadosFuncionario.nome',
          funcaoFuncionario: '$dadosFuncionario.funcao'
        }
      },
      {
        $project: {
          dadosFuncionario: 0 // Esconde o objeto temporário para deixar o JSON limpo
        }
      },
      { 
        $sort: { dataValidade: 1 } 
      }
    ]);

    res.json(docs);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// 3. LISTAR TODOS OS DOCUMENTOS (COM FILTROS)
app.get('/documentos', async (req, res) => {
  try {
    const query = { ativo: true };
    aplicarFiltroValidade(query, req.query.status);

    const docs = await Documento.find(query).sort({ dataValidade: 1 });
    res.json(docs);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// 4. LISTAR DOCUMENTOS DE UMA ENTIDADE
app.get('/documentos/entidade/:id', async (req, res) => {
  try {
    const mostrarAtivos = req.query.ativo !== 'false';
    const query = { entidadeId: req.params.id, ativo: mostrarAtivos };

    aplicarFiltroValidade(query, req.query.status);

    const docs = await Documento.find(query).sort({ dataValidade: 1 });
    res.json(docs);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// ==========================================
// ROTAS ESPECÍFICAS DE UM DOCUMENTO (:id)
// ==========================================

// 5. OBTER DADOS DO DOCUMENTO (SEM O PDF)
app.get('/documentos/:id/dados', async (req, res) => {
  try {
    const doc = await Documento.findById(req.params.id);
    if (!doc) return res.status(404).send('Documento não encontrado.');
    res.json(doc);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// 6. ROTA DE DOWNLOAD DO PDF
// 6. ROTA DE DOWNLOAD / VISUALIZAÇÃO
app.get('/documentos/:id/download', async (req, res) => {
  try {
    const doc = await Documento.findById(req.params.id);
    if (!doc || !doc.fileId) return res.status(404).send('Registro não encontrado.');

    const fileId = new mongoose.Types.ObjectId(doc.fileId);

    // Busca os metadados no GridFS para saber o formato real
    const files = await gfsBucket.find({ _id: fileId }).toArray();
    const contentType = files.length > 0 ? files[0].contentType : 'application/pdf';

    // Define a extensão dinamicamente para o Windows não se perder
    let ext = '.pdf';
    if (contentType === 'image/jpeg') ext = '.jpg';
    else if (contentType === 'image/png') ext = '.png';

    const isDownload = req.query.download === 'true';
    const disposition = isDownload ? 'attachment' : 'inline';

    res.set({
      'Content-Type': contentType,
      // O Segredo para o IE/Windows não falhar no download dinâmico:
      'Cache-Control': 'private, max-age=3600', 
      'x-documento-id': doc._id.toString(),
      'Content-Disposition': `${disposition}; filename="athena_doc_${doc._id}${ext}"`
    });
    
    const downloadStream = gfsBucket.openDownloadStream(fileId);
    downloadStream.on('error', () => res.status(404).send('Arquivo físico não encontrado.'));
    downloadStream.pipe(res);

  } catch (err) {
    res.status(500).send(err.message);
  }
});

// 6.5 ROTA DE PREVIEW (Imagem para o TImageViewer)
// ROTA DE PREVIEW (Imagem para o TImageViewer do Delphi)
app.get('/documentos/:id/preview', async (req, res) => {
  try {
    // 1. Captura a página solicitada (ex: ?page=2). Padrão é 1.
    const page = parseInt(req.query.page) || 1;

    // 2. Busca o registro do documento no MongoDB
    const doc = await Documento.findById(req.params.id);
    if (!doc || !doc.fileId) {
      return res.status(404).send('Registro não encontrado no banco de dados.');
    }

    // 3. Busca os metadados do arquivo físico no GridFS
    const fileId = new mongoose.Types.ObjectId(doc.fileId);
    const files = await gfsBucket.find({ _id: fileId }).toArray();
    if (files.length === 0) {
      return res.status(404).send('Arquivo físico não encontrado no Storage.');
    }

    // 4. Identifica o tipo do arquivo (Lógica "salva-vidas")
    let contentType = files[0].contentType || (files[0].metadata && files[0].metadata.contentType);
    if (!contentType) {
      const isPdf = files[0].filename.toLowerCase().endsWith('.pdf');
      contentType = isPdf ? 'application/pdf' : 'image/jpeg';
    }

    // 5. SE FOR IMAGEM: Retorna o arquivo original diretamente
    if (contentType.startsWith('image/')) {
      res.set('Content-Type', contentType);
      return gfsBucket.openDownloadStream(fileId).pipe(res);
    }

    // 6. SE FOR PDF: Converte a página solicitada usando Poppler
    if (contentType === 'application/pdf') {
      // Caminhos temporários (Windows usa os.tmpdir())
      const tempPdfPath = path.join(os.tmpdir(), `athena_temp_${doc._id}.pdf`);
      const tempImgPrefix = path.join(os.tmpdir(), `athena_prev_${doc._id}_pg${page}`);
      
      const writeStream = fs.createWriteStream(tempPdfPath);
      gfsBucket.openDownloadStream(fileId).pipe(writeStream);

      writeStream.on('finish', async () => {
        try {
          // Executa o Poppler: 
          // -f/-l define a página inicial/final (mesma página para pegar só uma)
          // -singlefile evita que o Poppler coloque sufixos como -1, -2 no nome do arquivo
          await exec(`pdftoppm -jpeg -f ${page} -l ${page} -scale-to 1024 -singlefile "${tempPdfPath}" "${tempImgPrefix}"`);
          
          const imgResultPath = `${tempImgPrefix}.jpg`; 
          
          if (fs.existsSync(imgResultPath)) {
            res.set('Content-Type', 'image/jpeg');
            const readStream = fs.createReadStream(imgResultPath);
            readStream.pipe(res);
            
            // Limpeza de arquivos temporários após o envio
            readStream.on('end', () => {
              try {
                if (fs.existsSync(tempPdfPath)) fs.unlinkSync(tempPdfPath);
                if (fs.existsSync(imgResultPath)) fs.unlinkSync(imgResultPath);
              } catch (err) {
                console.error('Erro ao deletar temporários:', err.message);
              }
            });
          } else {
            res.status(500).send('Erro: O Poppler não gerou a imagem desta página.');
          }
        } catch (cmdErr) {
          console.error('Erro no Poppler:', cmdErr.message);
          res.status(500).send('Erro no processamento do PDF (pdftoppm).');
        }
      });

      writeStream.on('error', (err) => {
        res.status(500).send('Erro ao baixar PDF para conversão: ' + err.message);
      });
    } else {
      res.status(400).send('Formato de arquivo não suportado para visualização.');
    }

  } catch (err) {
    console.error('Erro na rota de preview:', err.message);
    res.status(500).send('Erro interno do servidor: ' + err.message);
  }
});

// 7. ALTERAR DADOS DO DOCUMENTO
app.put('/documentos/:id', async (req, res) => {
  try {
    const dadosAtualizados = {
      tipoDocumento: req.body.tipoDocumento,
      dataValidade: req.body.dataValidade,
      entidadeTipo: req.body.entidadeTipo
    };

    const doc = await Documento.findByIdAndUpdate(req.params.id, dadosAtualizados, { new: true });
    
    if (!doc) return res.status(404).send('Documento não encontrado.');
    res.json({ mensagem: 'Dados atualizados com sucesso!', documento: doc });
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// 8. SOFT DELETE
app.delete('/documentos/:id', async (req, res) => {
  try {
    const doc = await Documento.findByIdAndUpdate(req.params.id, { ativo: false }, { new: true });
    if (!doc) return res.status(404).send('Documento não encontrado.');
    
    res.json({ mensagem: 'Documento movido para o arquivo (inativo).' });
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// 9. HARD DELETE (APAGAR O PDF DEFINITIVAMENTE DO ATLAS)
app.delete('/documentos/:id/fisico', async (req, res) => {
  try {
    const doc = await Documento.findById(req.params.id);
    if (!doc) return res.status(404).send('Documento não encontrado.');

    if (doc.fileId) {
       // Garante que é um ObjectId válido
       const fileId = new mongoose.Types.ObjectId(doc.fileId);
       await gfsBucket.delete(fileId);
    }

    await Documento.findByIdAndDelete(req.params.id);

    res.json({ mensagem: 'Documento e ficheiro PDF apagados permanentemente do servidor.' });
  } catch (err) {
    res.status(500).send('Erro ao apagar ficheiro: ' + err.message);
  }
});

// 10. resumo para dashboard sobre estados de documentos
app.get('/documentos/resumo/status', async (req, res) => {
  try {
    const hoje = new Date();
    
    const trintaDias = new Date();
    trintaDias.setDate(hoje.getDate() + 30);

    // O Promise.all executa as 3 buscas simultaneamente para maior performance
    const [total, vencendoEm30Dias, expirados] = await Promise.all([
      
      // 1. Total de documentos ativos
      Documento.countDocuments({ 
        ativo: true 
      }),
      
      // 2. Vencendo em 30 dias ou menos (mas que ainda não venceram)
      Documento.countDocuments({ 
        ativo: true, 
        dataValidade: { $gte: hoje, $lte: trintaDias } 
      }),
      
      // 3. Documentos já expirados (data de validade ficou para trás)
      Documento.countDocuments({ 
        ativo: true, 
        dataValidade: { $lt: hoje } 
      })

    ]);

    // Retorna o JSON formatado e mastigado para o Front-end ou Delphi
    res.json({
      total: total,
      vencendoEm30Dias: vencendoEm30Dias,
      expirados: expirados
    });

  } catch (err) {
    res.status(500).send('Erro ao buscar o resumo dos documentos: ' + err.message);
  }
});

// 11. ROTA DE PESQUISA AVANÇADA DE DOCUMENTOS
// 11. ROTA DE PESQUISA AVANÇADA DE DOCUMENTOS
app.get('/documentos/pesquisa', async (req, res) => {
  try {
    const { busca, status, ativo } = req.query;

    // --- 1. MATCH INICIAL (Filtros de Performance) ---
    const matchInicial = { $and: [] };

    if (ativo) {
      const ativoArray = ativo.split(',').map(a => a.trim());
      const ativoBools = [];
      if (ativoArray.includes('true'))  ativoBools.push(true);
      if (ativoArray.includes('false')) ativoBools.push(false);
      if (ativoBools.length > 0)
        matchInicial.$and.push({ ativo: { $in: ativoBools } });
    }

    if (status) {
      const statusArray = status.split(',').map(s => s.trim().toLowerCase());
      const orConditions = [];
      const hoje = new Date();
      const trintaDias = new Date();
      trintaDias.setDate(hoje.getDate() + 30);

      if (statusArray.includes('valido'))
        orConditions.push({ dataValidade: { $gte: trintaDias } });
      if (statusArray.includes('a_expirar'))
        orConditions.push({ dataValidade: { $gte: hoje, $lt: trintaDias } });
      if (statusArray.includes('expirado'))
        orConditions.push({ dataValidade: { $lt: hoje } });

      if (orConditions.length > 0)
        matchInicial.$and.push({ $or: orConditions });
    }

    const queryPrimeiroEstagio = matchInicial.$and.length > 0 ? matchInicial : {};

    // --- 2. CONSTRUINDO O PIPELINE ---
    const pipeline = [
      // Filtra ativos e validade primeiro
      { $match: queryPrimeiroEstagio },

      // Faz os Joins
      { $lookup: { from: 'funcionarios', localField: 'entidadeId', foreignField: '_id', as: '_joinFuncionario' } },
      { $lookup: { from: 'maquinas', localField: 'entidadeId', foreignField: '_id', as: '_joinMaquina' } },
      { $lookup: { from: 'empresas', localField: 'entidadeId', foreignField: '_id', as: '_joinEmpresa' } },

      // Monta o nome da Entidade com base no tipo
      {
        $addFields: {
          nomeEntidade: {
            $switch: {
              branches: [
                { case: { $eq: ['$entidadeTipo', 'funcionario'] }, then: { $arrayElemAt: ['$_joinFuncionario.nome', 0] } },
                { case: { $eq: ['$entidadeTipo', 'maquina'] }, then: { $arrayElemAt: ['$_joinMaquina.nome', 0] } },
                { case: { $eq: ['$entidadeTipo', 'empresa'] }, then: { $arrayElemAt: ['$_joinEmpresa.razaoSocial', 0] } }
              ],
              default: null
            }
          },
          funcaoFuncionario: {
            $cond: {
              if: { $eq: ['$entidadeTipo', 'funcionario'] },
              then: { $arrayElemAt: ['$_joinFuncionario.funcao', 0] },
              else: null
            } 
          }
        }
      }
    ];

    // --- 3. FILTRO DE BUSCA (APÓS OS JOINS) ---
    // Agora que temos o nomeEntidade, podemos pesquisar nele!
    if (busca) {
      pipeline.push({
        $match: {
          $or: [
            { nomeDocumento: { $regex: busca, $options: 'i' } },
            { nomeEntidade: { $regex: busca, $options: 'i' } }
          ]
        }
      });
    }

    // --- 4. LIMPEZA E ORDENAÇÃO ---
    pipeline.push({
      $project: {
        _joinFuncionario: 0,
        _joinMaquina: 0,
        _joinEmpresa: 0
      }
    });
    
    pipeline.push({ $sort: { dataValidade: 1 } });

    const docs = await Documento.aggregate(pipeline);
    res.json(docs);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// LOOKUP: Funcionários ativos
app.get('/funcionarios/lookup', async (req, res) => {
  try {
    const docs = await Funcionario
      .find({ ativo: true }, { _id: 1, nome: 1 })
      .sort({ nome: 1 });
    res.json(docs);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// LOOKUP: Máquinas ativas
app.get('/maquinas/lookup', async (req, res) => {
  try {
    const docs = await Maquina
      .find({ ativo: true }, { _id: 1, nome: 1 })
      .sort({ nome: 1 });
    res.json(docs);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// LOOKUP: Empresas ativas
app.get('/empresas/lookup', async (req, res) => {
  try {
    const docs = await Empresa
      .find({ ativo: true }, { _id: 1, razaoSocial: 1 })
      .sort({ razaoSocial: 1 });
    res.json(docs);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Servidor rodando na porta ${PORT}`));