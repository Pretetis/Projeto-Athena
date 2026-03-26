// routes/documentos.js
const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { Readable } = require('stream');
const fs = require('fs');
const path = require('path');
const os = require('os');
const util = require('util');
const exec = util.promisify(require('child_process').exec);

// Importações locais
const Documento = require('../models/Documento');
const upload = require('../middlewares/upload');

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

// ==========================================
// ROTAS FIXAS (Devem vir antes de /:id)
// ==========================================

// 1. RESUMO PARA DASHBOARD SOBRE ESTADOS DE DOCUMENTOS
router.get('/resumo/status', async (req, res) => {
  try {
    const hoje = new Date();
    const trintaDias = new Date();
    trintaDias.setDate(hoje.getDate() + 30);

    const [total, vencendoEm30Dias, expirados] = await Promise.all([
      Documento.countDocuments({ ativo: true }),
      Documento.countDocuments({ ativo: true, dataValidade: { $gte: hoje, $lte: trintaDias } }),
      Documento.countDocuments({ ativo: true, dataValidade: { $lt: hoje } })
    ]);

    res.json({ total, vencendoEm30Dias, expirados });
  } catch (err) {
    res.status(500).send('Erro ao buscar o resumo: ' + err.message);
  }
});

// 2. ROTA DE PESQUISA AVANÇADA DE DOCUMENTOS
router.get('/pesquisa', async (req, res) => {
  try {
    const { busca, status, ativo } = req.query;
    const matchInicial = { $and: [] };

    if (ativo) {
      const ativoArray = ativo.split(',').map(a => a.trim());
      const ativoBools = [];
      if (ativoArray.includes('true'))  ativoBools.push(true);
      if (ativoArray.includes('false')) ativoBools.push(false);
      matchInicial.$and.push({ ativo: { $in: ativoBools } });
    }

    if (status) {
      const statusArray = status.split(',').map(s => s.trim().toLowerCase());
      const orConditions = [];
      const hoje = new Date();
      const trintaDias = new Date();
      trintaDias.setDate(hoje.getDate() + 30);

      if (statusArray.includes('valido')) orConditions.push({ dataValidade: { $gte: trintaDias } });
      if (statusArray.includes('a_expirar')) orConditions.push({ dataValidade: { $gte: hoje, $lt: trintaDias } });
      if (statusArray.includes('expirado')) orConditions.push({ dataValidade: { $lt: hoje } });

      if (orConditions.length > 0) matchInicial.$and.push({ $or: orConditions });
    }

    const queryPrimeiroEstagio = matchInicial.$and.length > 0 ? matchInicial : {};

    const pipeline = [
      { $match: queryPrimeiroEstagio },
      { $lookup: { from: 'funcionarios', localField: 'entidadeId', foreignField: '_id', as: '_joinFuncionario' } },
      { $lookup: { from: 'maquinas', localField: 'entidadeId', foreignField: '_id', as: '_joinMaquina' } },
      { $lookup: { from: 'empresas', localField: 'entidadeId', foreignField: '_id', as: '_joinEmpresa' } },
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

    pipeline.push({
      $project: { _joinFuncionario: 0, _joinMaquina: 0, _joinEmpresa: 0 }
    });
    
    pipeline.push({ $sort: { dataValidade: 1 } });

    const docs = await Documento.aggregate(pipeline);
    res.json(docs);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// 3. LISTAR DOCUMENTOS DE UMA ENTIDADE
router.get('/entidade/:id', async (req, res) => {
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

// 4. LISTAR TODOS OS DOCUMENTOS (COM FILTROS)
router.get('/', async (req, res) => {
  try {
    const query = { ativo: true };
    aplicarFiltroValidade(query, req.query.status);

    const docs = await Documento.find(query).sort({ dataValidade: 1 });
    res.json(docs);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// 5. CADASTRAR DOCUMENTO (UPLOAD)
router.post('/', upload.single('pdf'), async (req, res) => {
  try {
    const gfsBucket = req.gfsBucket;
    if (!gfsBucket) return res.status(503).send('Serviço de arquivos inativo.');

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


// ==========================================
// ROTAS ESPECÍFICAS DE UM DOCUMENTO (/:id)
// ==========================================

// 6. OBTER DADOS DO DOCUMENTO (SEM O PDF)
router.get('/:id/dados', async (req, res) => {
  try {
    const doc = await Documento.findById(req.params.id);
    if (!doc) return res.status(404).send('Documento não encontrado.');
    res.json(doc);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// 7. ROTA DE DOWNLOAD / VISUALIZAÇÃO
router.get('/:id/download', async (req, res) => {
  try {
    const gfsBucket = req.gfsBucket;
    const doc = await Documento.findById(req.params.id);
    if (!doc || !doc.fileId) return res.status(404).send('Registro não encontrado.');

    const fileId = new mongoose.Types.ObjectId(doc.fileId);
    const files = await gfsBucket.find({ _id: fileId }).toArray();
    const contentType = files.length > 0 ? files[0].contentType : 'application/pdf';

    let ext = '.pdf';
    if (contentType === 'image/jpeg') ext = '.jpg';
    else if (contentType === 'image/png') ext = '.png';

    const isDownload = req.query.download === 'true';
    const disposition = isDownload ? 'attachment' : 'inline';

    res.set({
      'Content-Type': contentType,
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

// 8. ROTA DE PREVIEW (Imagem para o TImageViewer do Delphi)
router.get('/:id/preview', async (req, res) => {
  try {
    const gfsBucket = req.gfsBucket;
    const page = parseInt(req.query.page) || 1;

    const doc = await Documento.findById(req.params.id);
    if (!doc || !doc.fileId) return res.status(404).send('Registro não encontrado no banco.');

    const fileId = new mongoose.Types.ObjectId(doc.fileId);
    const files = await gfsBucket.find({ _id: fileId }).toArray();
    if (files.length === 0) return res.status(404).send('Arquivo físico não encontrado.');

    let contentType = files[0].contentType || (files[0].metadata && files[0].metadata.contentType);
    if (!contentType) {
      const isPdf = files[0].filename.toLowerCase().endsWith('.pdf');
      contentType = isPdf ? 'application/pdf' : 'image/jpeg';
    }

    if (contentType.startsWith('image/')) {
      res.set('Content-Type', contentType);
      return gfsBucket.openDownloadStream(fileId).pipe(res);
    }

    if (contentType === 'application/pdf') {
      const tempPdfPath = path.join(os.tmpdir(), `athena_temp_${doc._id}.pdf`);
      const tempImgPrefix = path.join(os.tmpdir(), `athena_prev_${doc._id}_pg${page}`);
      
      const writeStream = fs.createWriteStream(tempPdfPath);
      gfsBucket.openDownloadStream(fileId).pipe(writeStream);

      writeStream.on('finish', async () => {
        try {
          await exec(`pdftoppm -jpeg -f ${page} -l ${page} -scale-to 1024 -singlefile "${tempPdfPath}" "${tempImgPrefix}"`);
          const imgResultPath = `${tempImgPrefix}.jpg`; 
          
          if (fs.existsSync(imgResultPath)) {
            res.set('Content-Type', 'image/jpeg');
            const readStream = fs.createReadStream(imgResultPath);
            readStream.pipe(res);
            
            readStream.on('end', () => {
              try {
                if (fs.existsSync(tempPdfPath)) fs.unlinkSync(tempPdfPath);
                if (fs.existsSync(imgResultPath)) fs.unlinkSync(imgResultPath);
              } catch (err) {
                console.error('Erro ao deletar temporários:', err.message);
              }
            });
          } else {
            res.status(500).send('Erro: O Poppler não gerou a imagem.');
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
      res.status(400).send('Formato não suportado para visualização.');
    }
  } catch (err) {
    console.error('Erro na rota de preview:', err.message);
    res.status(500).send('Erro interno do servidor: ' + err.message);
  }
});

// 9. RECUPERAÇÃO (REATIVAR DOCUMENTO)
router.put('/:id/reativar', async (req, res) => {
  try {
    const doc = await Documento.findByIdAndUpdate(req.params.id, { ativo: true }, { new: true });
    if (!doc) return res.status(404).send('Documento não encontrado.');
    res.json({ mensagem: 'Documento reativado com sucesso!' });
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// 10. ALTERAR DADOS DO DOCUMENTO (COM ARQUIVO E HISTÓRICO)
router.put('/:id', upload.single('pdf'), async (req, res) => {
  try {
    const gfsBucket = req.gfsBucket;
    if (!req.body.dados) return res.status(400).send('Campo dados não recebido.');

    let dados;
    try {
      dados = JSON.parse(req.body.dados);
    } catch (e) {
      return res.status(400).send('JSON inválido: ' + e.message);
    }

    const dadosAtualizados = { dataUltimaAlteracao: new Date() };
    
    if (dados.nomeDocumento) dadosAtualizados.nomeDocumento = dados.nomeDocumento;
    if (dados.tipoDocumento) dadosAtualizados.tipoDocumento = dados.tipoDocumento;
    if (dados.dataValidade) dadosAtualizados.dataValidade = dados.dataValidade;
    if (dados.entidadeId) dadosAtualizados.entidadeId = dados.entidadeId;
    if (dados.entidadeTipo) dadosAtualizados.entidadeTipo = dados.entidadeTipo;
    if (dados.usuarioAlteracao) dadosAtualizados.ultimaAlteracaoPor = dados.usuarioAlteracao;
    if (dados.ativo !== undefined) dadosAtualizados.ativo = dados.ativo;

    const docAtual = await Documento.findById(req.params.id);
    if (!docAtual) return res.status(404).send('Documento não encontrado.');

    if (req.file) {
      if (docAtual.fileId) {
        try {
          await gfsBucket.delete(new mongoose.Types.ObjectId(docAtual.fileId));
        } catch (errGrid) {
          console.log('Aviso: Arquivo antigo não estava no Storage.');
        }
      }

      const fileName = `${Date.now()}-athena-update-${req.file.originalname}`;
      const uploadStream = gfsBucket.openUploadStream(fileName, {
        metadata: { contentType: req.file.mimetype } 
      });

      const bufferStream = new Readable();
      bufferStream.push(req.file.buffer);
      bufferStream.push(null);
      bufferStream.pipe(uploadStream);

      await new Promise((resolve, reject) => {
        uploadStream.on('finish', resolve);
        uploadStream.on('error', reject);
      });

      dadosAtualizados.fileId = uploadStream.id;
    }

    const doc = await Documento.findByIdAndUpdate(req.params.id, dadosAtualizados, { returnDocument: 'after' });
    res.json({ mensagem: 'Documento atualizado com sucesso!', documento: doc });

  } catch (err) {
    console.error('❌ ERRO NO PUT /documentos:', err); 
    res.status(500).send('Erro interno: ' + err.message);
  }
});

// 11. SOFT DELETE
router.delete('/:id', async (req, res) => {
  try {
    const doc = await Documento.findByIdAndUpdate(req.params.id, { ativo: false }, { new: true });
    if (!doc) return res.status(404).send('Documento não encontrado.');
    res.json({ mensagem: 'Documento movido para o arquivo (inativo).' });
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// 12. HARD DELETE (APAGAR O PDF DEFINITIVAMENTE DO ATLAS)
router.delete('/:id/fisico', async (req, res) => {
  try {
    const gfsBucket = req.gfsBucket;
    const doc = await Documento.findById(req.params.id);
    if (!doc) return res.status(404).send('Documento não encontrado.');

    if (doc.fileId) {
       await gfsBucket.delete(new mongoose.Types.ObjectId(doc.fileId));
    }

    await Documento.findByIdAndDelete(req.params.id);
    res.json({ mensagem: 'Documento e ficheiro PDF apagados permanentemente do servidor.' });
  } catch (err) {
    res.status(500).send('Erro ao apagar ficheiro: ' + err.message);
  }
});

module.exports = router;