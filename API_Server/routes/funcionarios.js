// routes/funcionarios.js
const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { Readable } = require('stream');

// Importações locais
const Funcionario = require('../models/Funcionario');
const upload = require('../middlewares/upload'); // Aquele arquivo do Multer que criamos

// 1. LISTAR TODOS OS FUNCIONÁRIOS
router.get('/', async (req, res) => {
  try {
    const { busca, ativo } = req.query;
    const query = {};

    if (ativo) {
      const ativoArray = ativo.split(',').map(a => a.trim());
      const ativoBools = [];
      if (ativoArray.includes('true'))  ativoBools.push(true);
      if (ativoArray.includes('false')) ativoBools.push(false);
      query.ativo = { $in: ativoBools };
    } else {
      query.ativo = true;
    }

    if (busca) {
      query.$or = [
        { nome: { $regex: busca, $options: 'i' } },
        { chapa: { $regex: busca, $options: 'i' } }
      ];
    }

    const funcionarios = await Funcionario.find(query).sort({ nome: 1 });
    res.json(funcionarios);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// 2. CADASTRAR NOVO FUNCIONÁRIO (COM FOTO)
router.post('/', upload.single('foto'), async (req, res) => {
  try {
    const gfsBucket = req.gfsBucket;
    if (!gfsBucket) return res.status(503).send('Serviço de arquivos inativo.');

    if (!req.body.dados) return res.status(400).send('Campo dados não recebido.');

    let dados;
    try {
      dados = JSON.parse(req.body.dados);
    } catch (e) {
      return res.status(400).send('JSON inválido: ' + e.message);
    }

    const { nome, funcao, setor, chapa } = dados;
    let fileId = null;

    if (req.file) {
      const fileName = `${Date.now()}-foto-${req.file.originalname}`;
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

      fileId = uploadStream.id;
    }

    const novoFunc = new Funcionario({ nome, funcao, setor, chapa, fotoId: fileId });
    await novoFunc.save();
    res.status(201).json({ mensagem: 'Funcionário cadastrado com sucesso!', id: novoFunc._id });

  } catch (err) {
    if (err.code === 11000) return res.status(409).send('Esta chapa já está em uso.');
    console.error('❌ ERRO NO POST /funcionarios:', err);
    res.status(500).send('Erro interno: ' + err.message);
  }
});

// 3. BUSCAR A FOTO DO FUNCIONÁRIO (Para o TImageViewer)
router.get('/:id/foto', async (req, res) => {
  try {
    const gfsBucket = req.gfsBucket;
    const func = await Funcionario.findById(req.params.id);
    
    if (!func || !func.fotoId) return res.status(404).send('Funcionário sem foto.'); 

    const fileId = new mongoose.Types.ObjectId(func.fotoId);
    const files = await gfsBucket.find({ _id: fileId }).toArray();
    
    if (files.length === 0) return res.status(404).send('Arquivo físico não encontrado.');

    res.set('Content-Type', files[0].contentType || 'image/jpeg');
    gfsBucket.openDownloadStream(fileId).pipe(res);
  } catch (err) {
    res.status(500).send('Erro ao buscar foto: ' + err.message);
  }
});

// 4. ALTERAR FUNCIONÁRIO
router.put('/:id', upload.single('foto'), async (req, res) => {
  try {
    const gfsBucket = req.gfsBucket;
    if (!req.body.dados) return res.status(400).send('Campo dados não recebido.');

    let dados = JSON.parse(req.body.dados);
    const { nome, funcao, setor, chapa, ativo } = dados;
    
    const dadosAtualizados = {};
    if (nome) dadosAtualizados.nome = nome;
    if (funcao) dadosAtualizados.funcao = funcao;
    if (setor !== undefined) dadosAtualizados.setor = setor;
    if (chapa) dadosAtualizados.chapa = chapa;
    if (ativo !== undefined) dadosAtualizados.ativo = ativo;

    const funcAtual = await Funcionario.findById(req.params.id);
    if (!funcAtual) return res.status(404).send('Funcionário não encontrado.');

    if (req.file) {
      if (funcAtual.fotoId) {
        try {
          await gfsBucket.delete(new mongoose.Types.ObjectId(funcAtual.fotoId));
        } catch (errGrid) { /* Ignora se não existir */ }
      }

      const fileName = `${Date.now()}-foto-update-${req.file.originalname}`;
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

      dadosAtualizados.fotoId = uploadStream.id;
    }

    const funcAtualizado = await Funcionario.findByIdAndUpdate(req.params.id, dadosAtualizados, { returnDocument: 'after' });
    res.json({ mensagem: 'Funcionário atualizado com sucesso!', funcionario: funcAtualizado });

  } catch (err) {
    if (err.code === 11000) return res.status(409).send('Esta chapa já está em uso.');
    res.status(500).send('Erro interno: ' + err.message);
  }
});

module.exports = router;