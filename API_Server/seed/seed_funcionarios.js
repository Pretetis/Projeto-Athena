require('dotenv').config();
const mongoose = require('mongoose');
const Documento = require('../models/Documento');
const Funcionario = require('../models/Funcionario');

// IDs fictícios para amarrar os relacionamentos
const ids = {
  func1: new mongoose.Types.ObjectId('65f1a2b3c4d5e6f7a8b90001'),
  func2: new mongoose.Types.ObjectId('65f1a2b3c4d5e6f7a8b90002'),
  func3: new mongoose.Types.ObjectId('65f1a2b3c4d5e6f7a8b90003'),
  maq1: new mongoose.Types.ObjectId('65f1a2b3c4d5e6f7a8b90004'),
};

const fakeFileId = new mongoose.Types.ObjectId('65f1a2b3c4d5e6f7a8b99999');

// Controle de Datas
const hoje = new Date();
const dataVencida = new Date(hoje); dataVencida.setMonth(hoje.getMonth() - 2);
const dataAlerta = new Date(hoje); dataAlerta.setDate(hoje.getDate() + 15);
const dataValida = new Date(hoje); dataValida.setFullYear(hoje.getFullYear() + 1);

const funcionariosSeed = [
  { _id: ids.func1, nome: 'Dalinar Kholin', funcao: 'Líder', chapa: '001', ativo: true },
  { _id: ids.func2, nome: 'Kaladin Stormblessed', funcao: 'Barbeiro', chapa: '002', ativo: true },
  { _id: ids.func3, nome: 'Adolin Kholin', funcao: 'Barbeiro', chapa: '003', ativo: true }
];

const documentosSeed = [
  // --- FUNCIONÁRIO 1 (Dalinar) ---
  { entidadeId: ids.func1, entidadeTipo: 'Funcionario', nomeDocumento: 'Contrato de Trabalho', tipoDocumento: 'Trabalhista', dataValidade: dataValida, fileId: fakeFileId },
  { entidadeId: ids.func1, entidadeTipo: 'Funcionario', nomeDocumento: 'Licença Sanitária Individual', tipoDocumento: 'Saúde', dataValidade: dataAlerta, fileId: fakeFileId },

  // --- FUNCIONÁRIO 2 (Kaladin) ---
  { entidadeId: ids.func2, entidadeTipo: 'Funcionario', nomeDocumento: 'Atestado de Saúde (ASO)', tipoDocumento: 'Saúde', dataValidade: dataVencida, fileId: fakeFileId },
  { entidadeId: ids.func2, entidadeTipo: 'Funcionario', nomeDocumento: 'Certificado de Biossegurança', tipoDocumento: 'Norma', dataValidade: dataValida, fileId: fakeFileId },

  // --- FUNCIONÁRIO 3 (Adolin) ---
  { entidadeId: ids.func3, entidadeTipo: 'Funcionario', nomeDocumento: 'Treinamento de Máquinas', tipoDocumento: 'Norma', dataValidade: dataAlerta, fileId: fakeFileId },

  // --- MÁQUINA 1 (Autoclave) ---
  { entidadeId: ids.maq1, entidadeTipo: 'Maquina', nomeDocumento: 'Certificado de Calibração', tipoDocumento: 'Manutenção', dataValidade: dataAlerta, fileId: fakeFileId }
];

async function popularBanco() {
  try {
    console.log('⏳ Conectando ao Atlas...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Conectado!');

    console.log('🧹 Limpando coleções antigas...');
    await Funcionario.deleteMany({});
    await Documento.deleteMany({});

    console.log('⏳ Inserindo Funcionários...');
    await Funcionario.insertMany(funcionariosSeed);

    console.log('⏳ Inserindo Documentos...');
    await Documento.insertMany(documentosSeed);
    
    console.log('🚀 Seed concluída com sucesso!');
    process.exit(0);
  } catch (erro) {
    console.error('❌ Erro ao popular banco:', erro);
    process.exit(1);
  }
}

popularBanco();