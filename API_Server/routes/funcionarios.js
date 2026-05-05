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

    const { nome, funcao, setor, chapa, termosAceitos, baseLegal } = dados;
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

    const dadosLgpd = {};
    if (termosAceitos) {
      dadosLgpd.termosAceitos = true;
      dadosLgpd.dataAceiteTermos = new Date();
    }
    if (baseLegal) dadosLgpd.baseLegal = baseLegal;

    const novoFunc = new Funcionario({ nome, funcao, setor, chapa, fotoId: fileId, ...dadosLgpd });
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

    if (!func) return res.status(404).send('Funcionário não encontrado.');

    // LGPD: se o funcionário não autorizou uso da foto, não expõe a imagem
    if (func.termosAceitosFotoPerfil === false) {
      return res.status(403).send('Uso da foto de perfil não autorizado pelo titular.');
    }

    if (!func.fotoId) return res.status(404).send('Funcionário sem foto.');

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

// Rota de Login (Confiar na primeira senha)
router.post('/login', async (req, res) => {
  try {
    const { nome, senha } = req.body;

    if (!nome || !senha) {
      return res.status(400).send('Nome e senha são obrigatórios.');
    }

    // Procura o funcionário pelo nome (case insensitive); senha excluída por padrão no schema
    const func = await Funcionario.findOne({ nome: new RegExp(`^${nome}$`, 'i') }).select('+senha');
    
    if (!func) {
      return res.status(404).send('Funcionário não encontrado.');
    }

    // Primeiro acesso: senha padrão é o primeiro nome do funcionário
    if (!func.senha) {
      const primeiroNome = func.nome.split(' ')[0];
      if (senha !== primeiroNome) {
        return res.status(401).send('Senha incorreta. No primeiro acesso, use seu primeiro nome como senha.');
      }
      func.senha = primeiroNome;
      await func.save();
      return res.json({
        sucesso: true,
        primeiroAcesso: true,
        mensagem: 'Primeiro acesso identificado. Troque sua senha antes de continuar.',
        funcionario: {
          id: func._id,
          nome: func.nome,
          funcao: func.funcao,
          setor: func.setor,
          nivelAcesso: func.nivelAcesso !== undefined ? func.nivelAcesso : 3,
          termosAceitos: func.termosAceitos
        }
      });
    }

    // Se ele já tem senha, apenas validamos
    if (func.senha !== senha) {
      return res.status(401).send('Senha incorreta.');
    }

    return res.json({ 
      sucesso: true, 
      mensagem: 'Login aprovado!',
      funcionario: { 
        id: func._id, 
        nome: func.nome, 
        funcao: func.funcao, 
        setor: func.setor, 
        nivelAcesso: func.nivelAcesso !== undefined ? func.nivelAcesso : 3,
        termosAceitos: func.termosAceitos
      }
    });

  } catch (err) {
    res.status(500).send('Erro interno: ' + err.message);
  }
});

// 5. ACEITAR TERMOS LGPD
// POST /funcionarios/:id/aceitar-termos
// Body opcional: { aceitarFotoPerfil: Boolean }
router.post('/:id/aceitar-termos', async (req, res) => {
  try {
    const func = await Funcionario.findById(req.params.id);
    if (!func) return res.status(404).send('Funcionário não encontrado.');

    if (func.termosAceitos) {
      return res.status(409).send('Termos já foram aceitos anteriormente.');
    }

    func.termosAceitos = true;
    func.dataAceiteTermos = new Date();

    if (req.body.aceitarFotoPerfil !== undefined) {
      func.termosAceitosFotoPerfil = req.body.aceitarFotoPerfil;
    }

    await func.save();

    res.json({
      mensagem: 'Termos LGPD aceitos com sucesso.',
      dataAceite: func.dataAceiteTermos,
      termosAceitosFotoPerfil: func.termosAceitosFotoPerfil
    });
  } catch (err) {
    res.status(500).send('Erro ao registrar aceite: ' + err.message);
  }
});

// 6. TROCAR SENHA DO FUNCIONÁRIO
// DEV: RESETAR PRIMEIRO ACESSO (apaga a senha para simular novo funcionário)
// POST /funcionarios/:id/resetar-acesso
router.post('/:id/resetar-acesso', async (req, res) => {
  try {
    const func = await Funcionario.findByIdAndUpdate(
      req.params.id,
      { $unset: { senha: '' } },
      { new: true }
    );
    if (!func) return res.status(404).send('Funcionário não encontrado.');
    res.json({ mensagem: `Acesso de "${func.nome}" resetado. Próximo login será tratado como primeiro acesso.` });
  } catch (err) {
    res.status(500).send('Erro ao resetar acesso: ' + err.message);
  }
});

// PUT /funcionarios/:id/senha
// Body: { senhaAtual: String, novaSenha: String }
router.put('/:id/senha', async (req, res) => {
  try {
    const { senhaAtual, novaSenha } = req.body;

    if (!senhaAtual || !novaSenha) {
      return res.status(400).send('senhaAtual e novaSenha são obrigatórios.');
    }

    if (novaSenha.length < 4) {
      return res.status(400).send('A nova senha deve ter ao menos 4 caracteres.');
    }

    // Busca incluindo senha (excluída por padrão no schema)
    const func = await Funcionario.findById(req.params.id).select('+senha');
    if (!func) return res.status(404).send('Funcionário não encontrado.');

    // Primeiro acesso: ainda não tem senha definida
    if (!func.senha) {
      return res.status(400).send('Funcionário sem senha cadastrada. Use o login para definir a senha inicial.');
    }

    if (func.senha !== senhaAtual) {
      return res.status(401).send('Senha atual incorreta.');
    }

    func.senha = novaSenha;
    await func.save();

    res.json({ mensagem: 'Senha alterada com sucesso.' });
  } catch (err) {
    res.status(500).send('Erro ao alterar senha: ' + err.message);
  }
});

module.exports = router;