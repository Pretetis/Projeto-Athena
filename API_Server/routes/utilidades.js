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
      { $addFields: { chapaNum: { $toInt: "$chapa" } } },
      { $sort: { chapaNum: -1 } },
      { $limit: 1 }
    ]);

    let maxMaq = [];
    try {
      maxMaq = await Maquina.aggregate([
        { $addFields: { chapaNum: { $toInt: "$chapa" } } },
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

module.exports = router;