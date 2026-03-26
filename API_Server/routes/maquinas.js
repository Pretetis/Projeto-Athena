// routes/maquinas.js
const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { Readable } = require('stream');

const Maquina = require('../models/Maquina');
const upload = require('../middlewares/upload');

// 1. LISTAR MÁQUINAS
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

    const maquinas = await Maquina.find(query).sort({ nome: 1 });
    res.json(maquinas);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// 2. CADASTRAR NOVA MÁQUINA
router.post('/', upload.single('foto'), async (req, res) => {
  try {
    const gfsBucket = req.gfsBucket;
    if (!req.body.dados) return res.status(400).send('Campo dados não recebido.');

    let dados = JSON.parse(req.body.dados);
    const { nome, tipo, modelo, chapa } = dados;
    let fileId = null;

    if (req.file) {
      const fileName = `${Date.now()}-fotoMaq-${req.file.originalname}`;
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

    const novaMaq = new Maquina({ nome, tipo, modelo, chapa, fotoId: fileId });
    await novaMaq.save();
    
    res.status(201).json({ mensagem: 'Máquina cadastrada com sucesso!', id: novaMaq._id });
  } catch (err) {
    if (err.code === 11000) return res.status(409).send('Esta chapa já está em uso.');
    res.status(500).send('Erro interno: ' + err.message);
  }
});

// 3. BUSCAR A FOTO DA MÁQUINA
router.get('/:id/foto', async (req, res) => {
  try {
    const gfsBucket = req.gfsBucket;
    const maq = await Maquina.findById(req.params.id);
    if (!maq || !maq.fotoId) return res.status(404).send('Máquina sem foto.'); 

    const fileId = new mongoose.Types.ObjectId(maq.fotoId);
    const files = await gfsBucket.find({ _id: fileId }).toArray();
    if (files.length === 0) return res.status(404).send('Arquivo físico não encontrado.');

    res.set('Content-Type', files[0].contentType || 'image/jpeg');
    gfsBucket.openDownloadStream(fileId).pipe(res);
  } catch (err) {
    res.status(500).send('Erro ao buscar foto: ' + err.message);
  }
});

// 4. ALTERAR MÁQUINA
router.put('/:id', upload.single('foto'), async (req, res) => {
  try {
    const gfsBucket = req.gfsBucket;
    if (!req.body.dados) return res.status(400).send('Campo dados não recebido.');

    let dados = JSON.parse(req.body.dados);
    const { nome, tipo, modelo, chapa, ativo } = dados;
    
    const dadosAtualizados = {};
    if (nome) dadosAtualizados.nome = nome;
    if (tipo !== undefined) dadosAtualizados.tipo = tipo;
    if (modelo !== undefined) dadosAtualizados.modelo = modelo;
    if (chapa) dadosAtualizados.chapa = chapa;
    if (ativo !== undefined) dadosAtualizados.ativo = ativo;

    const maqAtual = await Maquina.findById(req.params.id);
    if (!maqAtual) return res.status(404).send('Máquina não encontrada.');

    if (req.file) {
      if (maqAtual.fotoId) {
        try {
          await gfsBucket.delete(new mongoose.Types.ObjectId(maqAtual.fotoId));
        } catch (errGrid) { /* Ignora erro de gridfs */ }
      }

      const fileName = `${Date.now()}-fotoMaq-update-${req.file.originalname}`;
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

    const maqAtualizada = await Maquina.findByIdAndUpdate(req.params.id, dadosAtualizados, { returnDocument: 'after' });
    res.json({ mensagem: 'Máquina atualizada com sucesso!', maquina: maqAtualizada });
  } catch (err) {
    if (err.code === 11000) return res.status(409).send('Esta chapa já está em uso.');
    res.status(500).send('Erro interno: ' + err.message);
  }
});

module.exports = router;