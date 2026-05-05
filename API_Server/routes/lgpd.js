// routes/lgpd.js
const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

const Funcionario = require('../models/Funcionario');
const Documento = require('../models/Documento');

// ==========================================
// 1. PORTABILIDADE DE DADOS (Art. 18, II LGPD)
// GET /lgpd/funcionarios/:id/portabilidade
// Retorna todos os dados do titular em formato estruturado
// ==========================================
router.get('/funcionarios/:id/portabilidade', async (req, res) => {
  try {
    const func = await Funcionario.findById(req.params.id).lean();
    if (!func) return res.status(404).send('Funcionário não encontrado.');

    const documentos = await Documento.find({ entidadeId: req.params.id, ativo: true }).lean();

    const relatorio = {
      exportadoEm: new Date().toISOString(),
      titular: {
        id: func._id,
        nome: func.anonimizado ? '[ANONIMIZADO]' : func.nome,
        funcao: func.funcao,
        setor: func.setor,
        chapa: func.anonimizado ? '[ANONIMIZADO]' : func.chapa,
        nivelAcesso: func.nivelAcesso,
        ativo: func.ativo,
        criadoEm: func.createdAt,
        atualizadoEm: func.updatedAt,
      },
      lgpd: {
        termosAceitos: func.termosAceitos,
        dataAceiteTermos: func.dataAceiteTermos,
        baseLegal: func.baseLegal,
        consentimentoRevogado: func.consentimentoRevogado,
        dataRevogacaoConsentimento: func.dataRevogacaoConsentimento,
        motivoRevogacao: func.motivoRevogacao,
        anonimizado: func.anonimizado,
        dataAnonimizacao: func.dataAnonimizacao,
      },
      documentos: documentos.map(doc => ({
        id: doc._id,
        nomeDocumento: doc.nomeDocumento,
        tipoDocumento: doc.tipoDocumento,
        dataValidade: doc.dataValidade,
        isDadoSensivel: doc.isDadoSensivel,
        baseLegal: doc.baseLegal,
        criadoEm: doc.createdAt,
      })),
    };

    res.set('Content-Disposition', `attachment; filename="portabilidade_${func._id}.json"`);
    res.json(relatorio);
  } catch (err) {
    res.status(500).send('Erro ao gerar relatório de portabilidade: ' + err.message);
  }
});

// ==========================================
// 2. REVOGAÇÃO DE CONSENTIMENTO (Art. 8, §5 LGPD)
// POST /lgpd/funcionarios/:id/revogar-consentimento
// Body: { motivo: String }
// ==========================================
router.post('/funcionarios/:id/revogar-consentimento', async (req, res) => {
  try {
    const func = await Funcionario.findById(req.params.id);
    if (!func) return res.status(404).send('Funcionário não encontrado.');

    if (func.anonimizado) {
      return res.status(400).send('Titular já anonimizado. Operação não aplicável.');
    }

    if (func.consentimentoRevogado) {
      return res.status(409).send('Consentimento já havia sido revogado anteriormente.');
    }

    func.termosAceitos = false;
    func.consentimentoRevogado = true;
    func.dataRevogacaoConsentimento = new Date();
    func.motivoRevogacao = req.body.motivo || 'Revogado pelo titular';
    await func.save();

    res.json({
      mensagem: 'Consentimento revogado com sucesso.',
      dataRevogacao: func.dataRevogacaoConsentimento,
      motivo: func.motivoRevogacao,
    });
  } catch (err) {
    res.status(500).send('Erro ao revogar consentimento: ' + err.message);
  }
});

// ==========================================
// 3. ANONIMIZAÇÃO DE DADOS (Art. 18, IV LGPD)
// POST /lgpd/funcionarios/:id/anonimizar
// Substitui dados pessoais por tokens neutros e remove a foto
// ==========================================
router.post('/funcionarios/:id/anonimizar', async (req, res) => {
  try {
    const gfsBucket = req.gfsBucket;

    const func = await Funcionario.findById(req.params.id);
    if (!func) return res.status(404).send('Funcionário não encontrado.');

    if (func.anonimizado) {
      return res.status(409).send('Titular já foi anonimizado anteriormente.');
    }

    // Remove a foto do GridFS se existir
    if (func.fotoId && gfsBucket) {
      try {
        await gfsBucket.delete(new mongoose.Types.ObjectId(func.fotoId));
      } catch (errGrid) {
        // Foto pode já não existir no storage — continua sem bloquear
      }
    }

    const token = func._id.toString().slice(-6).toUpperCase();

    func.nome = `TITULAR_${token}`;
    func.chapa = `ANON_${token}`;
    func.setor = null;
    func.fotoId = null;
    func.senha = null;
    func.anonimizado = true;
    func.dataAnonimizacao = new Date();
    func.ativo = false;
    await func.save();

    res.json({
      mensagem: 'Dados do titular anonimizados com sucesso.',
      dataAnonimizacao: func.dataAnonimizacao,
    });
  } catch (err) {
    res.status(500).send('Erro ao anonimizar titular: ' + err.message);
  }
});

module.exports = router;
