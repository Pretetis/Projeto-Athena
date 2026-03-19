require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const multer = require('multer');
const { Readable } = require('stream');
const Documento = require('./models/Documento');
const iniciarAutomacoes = require('./services/cron'); 

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
    if (!req.file) return res.status(400).send('Arquivo não enviado.');

    const fileName = `${Date.now()}-athena-${req.file.originalname}`;

    const uploadStream = gfsBucket.openUploadStream(fileName, {
        contentType: req.file.mimetype
    });

    const bufferStream = new Readable();
    bufferStream.push(req.file.buffer);
    bufferStream.push(null); 

    bufferStream.pipe(uploadStream);

    uploadStream.on('finish', async () => {
      try {
        const novoDoc = new Documento({
          entidadeId: req.body.entidadeId,
          entidadeTipo: req.body.entidadeTipo,
          tipoDocumento: req.body.tipoDocumento,
          dataValidade: req.body.dataValidade,
          fileId: uploadStream.id 
        });

        await novoDoc.save();
        res.status(201).json({ 
            mensagem: 'Sucesso! PDF salvo no Atlas manualmente.',
            fileId: uploadStream.id 
        });
      } catch (saveErr) {
        res.status(500).send('Erro ao salvar metadados: ' + saveErr.message);
      }
    });

    uploadStream.on('error', (err) => {
      res.status(500).send('Erro no upload para o GridFS: ' + err.message);
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
          from: 'funcionarios', // <-- AQUI ESTÁ O SEGREDO DO "JOIN"
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
app.get('/documentos/:id/download', async (req, res) => {
  try {
    const doc = await Documento.findById(req.params.id);
    if (!doc || !doc.fileId) return res.status(404).send('Registro não encontrado.');

    res.set({
      'Content-Type': 'application/pdf',
      'x-documento-id': doc._id.toString(),
      'x-entidade-id': doc.entidadeId.toString(),
      'x-tipo-documento': encodeURIComponent(doc.tipoDocumento || 'Sem Tipo'),
      'x-data-validade': doc.dataValidade ? doc.dataValidade.toISOString() : '',
      'Content-Disposition': `attachment; filename="athena_doc_${doc._id}.pdf"`
    });

    // Garante que é um ObjectId antes de passar para o GridFS
    const fileId = new mongoose.Types.ObjectId(doc.fileId);
    const downloadStream = gfsBucket.openDownloadStream(fileId);
    
    downloadStream.on('error', () => res.status(404).send('Arquivo físico não encontrado.'));
    
    downloadStream.pipe(res);

  } catch (err) {
    res.status(500).send(err.message);
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

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Servidor rodando na porta ${PORT}`));