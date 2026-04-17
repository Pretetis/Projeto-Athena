// routes/utilidades.js
const express = require('express');
const router = express.Router();

const Funcionario = require('../models/Funcionario');
const Maquina = require('../models/Maquina');
const Empresa = require('../models/Empresa');
const Documento = require('../models/Documento');

// ==========================================
// LOOKUPS (Para popular ComboBoxes / Grids no Delphi)
// ==========================================

router.get('/funcionarios/lookup', async (req, res) => {
  try {
    const docs = await Funcionario.find({ ativo: true }, { _id: 1, nome: 1 }).sort({ nome: 1 });
    res.json(docs);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

router.get('/maquinas/lookup', async (req, res) => {
  try {
    const docs = await Maquina.find({ ativo: true }, { _id: 1, nome: 1 }).sort({ nome: 1 });
    res.json(docs);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

router.get('/empresas/lookup', async (req, res) => {
  try {
    const docs = await Empresa.find({ ativo: true }, { _id: 1, razaoSocial: 1 }).sort({ razaoSocial: 1 });
    res.json(docs);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// ==========================================
// UTILIDADES E CÁLCULOS
// ==========================================

// PRÓXIMA CHAPA DISPONÍVEL
router.get('/chapa/proxima', async (req, res) => {
  try {
    const maxFunc = await Funcionario.aggregate([
      { 
        $addFields: { 
          chapaNum: { $convert: { input: "$chapa", to: "int", onError: 0, onNull: 0 } } 
        } 
      },
      { $sort: { chapaNum: -1 } },
      { $limit: 1 }
    ]);

    let maxMaq = [];
    try {
      maxMaq = await Maquina.aggregate([
        { 
          $addFields: { 
            chapaNum: { $convert: { input: "$chapa", to: "int", onError: 0, onNull: 0 } } 
          } 
        },
        { $sort: { chapaNum: -1 } },
        { $limit: 1 }
      ]);
    } catch (e) {
      console.log("Aviso: Falha ao buscar chapa em Máquinas.");
    }

    const val1 = maxFunc.length > 0 && maxFunc[0].chapaNum ? maxFunc[0].chapaNum : 0;
    const val2 = maxMaq.length > 0 && maxMaq[0].chapaNum ? maxMaq[0].chapaNum : 0;

    const proxima = Math.max(val1, val2) + 1;

    res.json({ proximaChapa: proxima.toString() });
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// ALERTAS DE VENCIMENTO
router.get('/alertas/documentos-a-vencer', async (req, res) => {
  try {
    const hoje = new Date();
    const trintaDias = new Date();
    trintaDias.setDate(hoje.getDate() + 30);

    const docs = await Documento.aggregate([
      { $match: { ativo: true, dataValidade: { $lte: trintaDias } } },
      { $lookup: { from: 'funcionarios', localField: 'entidadeId', foreignField: '_id', as: 'dadosFuncionario' } },
      { $unwind: { path: '$dadosFuncionario', preserveNullAndEmptyArrays: true } },
      {
        $addFields: {
          nomeFuncionario: '$dadosFuncionario.nome',
          funcaoFuncionario: '$dadosFuncionario.funcao'
        }
      },
      { $project: { dadosFuncionario: 0 } },
      { $sort: { dataValidade: 1 } }
    ]);

    res.json(docs);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// ==========================================
// INTEGRAÇÃO GEMINI (PROXY)
// ==========================================
router.post('/gemini/:model', async (req, res) => {
  try {
    const { model } = req.params;
    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey) {
      return res.status(500).json({ error: { message: "API Key do Gemini não configurada no servidor." } });
    }

    // URL original da API do Google, montada com o modelo e a chave
    const googleUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

    // Repassa a requisição exata que veio do Delphi (req.body)
    const response = await fetch(googleUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(req.body) 
    });

    const data = await response.json();

    // Devolve para o Delphi o mesmo JSON e Status Code que o Google gerou
    res.status(response.status).json(data);

  } catch (err) {
    res.status(500).json({ error: { message: err.message } });
  }
});

// Rota exclusiva para receber o Base64 do Delphi e subir para a File API do Google
router.post('/gemini-upload', async (req, res) => {
  try {
    const { mimeType, base64Data, displayName } = req.body;
    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey) {
      return res.status(500).json({ error: { message: "API Key do Gemini não configurada." } });
    }

    // 1. Converter o Base64 que veio do Delphi para bytes (Buffer)
    const fileBuffer = Buffer.from(base64Data, 'base64');
    const numBytes = fileBuffer.length;

    // 2. Passo 1 do Upload: Iniciar (Start) e pegar a URL temporária
    const startUrl = `https://generativelanguage.googleapis.com/upload/v1beta/files?key=${apiKey}`;
    const startResponse = await fetch(startUrl, {
      method: 'POST',
      headers: {
        'X-Goog-Upload-Protocol': 'resumable',
        'X-Goog-Upload-Command': 'start',
        'X-Goog-Upload-Header-Content-Length': numBytes,
        'X-Goog-Upload-Header-Content-Type': mimeType,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ file: { displayName: displayName || 'Upload_Athena' } })
    });

    const uploadUrl = startResponse.headers.get('x-goog-upload-url');
    if (!uploadUrl) {
      throw new Error('Falha ao obter URL de upload da API do Google.');
    }

    // 3. Passo 2 do Upload: Enviar os bytes para a URL temporária
    const uploadResponse = await fetch(uploadUrl, {
      method: 'POST',
      headers: {
        'X-Goog-Upload-Protocol': 'resumable',
        'X-Goog-Upload-Command': 'upload, finalize',
        'X-Goog-Upload-Offset': '0'
      },
      body: fileBuffer
    });

    const fileData = await uploadResponse.json();
    
    // Devolve o JSON pro Delphi. O Delphi vai extrair o campo "file.uri"
    res.status(uploadResponse.status).json(fileData);

  } catch (err) {
    res.status(500).json({ error: { message: err.message } });
  }
});


module.exports = router;