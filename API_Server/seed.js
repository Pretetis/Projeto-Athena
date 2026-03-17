require('dotenv').config();
const mongoose = require('mongoose');
const Documento = require('./models/Documento');

// IDs fictícios gerados para simular suas entidades
const ids = {
  func1: new mongoose.Types.ObjectId('65f1a2b3c4d5e6f7a8b90001'), // João (Barbeiro)
  func2: new mongoose.Types.ObjectId('65f1a2b3c4d5e6f7a8b90002'), // Marcos (Barbeiro)
  func3: new mongoose.Types.ObjectId('65f1a2b3c4d5e6f7a8b90003'), // Lucas (Recepção)
  maq1: new mongoose.Types.ObjectId('65f1a2b3c4d5e6f7a8b90004'),  // Autoclave (Esterilização)
  maq2: new mongoose.Types.ObjectId('65f1a2b3c4d5e6f7a8b90005')   // Máquina de Corte Wahl
};

// ID fictício para o GridFS (apenas para o banco aceitar o registro)
const fakeFileId = new mongoose.Types.ObjectId('65f1a2b3c4d5e6f7a8b99999');

// Datas baseadas no dia de hoje para testar os filtros perfeitamente
const hoje = new Date();

const dataVencida = new Date(hoje);
dataVencida.setMonth(hoje.getMonth() - 2); // Venceu há 2 meses

const dataAlerta = new Date(hoje);
dataAlerta.setDate(hoje.getDate() + 15); // Vence em 15 dias (Vai cair no alerta de 30 dias)

const dataValida = new Date(hoje);
dataValida.setFullYear(hoje.getFullYear() + 1); // Vence só daqui a 1 ano

const registros = [
  // --- FUNCIONÁRIO 1 (João) ---
  { entidadeId: ids.func1, entidadeTipo: 'Funcionario', tipoDocumento: 'Contrato de Trabalho', dataValidade: dataValida, fileId: fakeFileId },
  { entidadeId: ids.func1, entidadeTipo: 'Funcionario', tipoDocumento: 'Atestado de Saúde (ASO)', dataValidade: dataAlerta, fileId: fakeFileId },
  { entidadeId: ids.func1, entidadeTipo: 'Funcionario', tipoDocumento: 'Certificado de Curso', dataValidade: dataVencida, fileId: fakeFileId },

  // --- FUNCIONÁRIO 2 (Marcos) ---
  { entidadeId: ids.func2, entidadeTipo: 'Funcionario', tipoDocumento: 'Contrato de Trabalho', dataValidade: dataValida, fileId: fakeFileId },
  { entidadeId: ids.func2, entidadeTipo: 'Funcionario', tipoDocumento: 'Atestado de Saúde (ASO)', dataValidade: dataValida, fileId: fakeFileId },
  { entidadeId: ids.func2, entidadeTipo: 'Funcionario', tipoDocumento: 'Licença Sanitária Individual', dataValidade: dataVencida, fileId: fakeFileId },

  // --- FUNCIONÁRIO 3 (Lucas) ---
  { entidadeId: ids.func3, entidadeTipo: 'Funcionario', tipoDocumento: 'Contrato de Trabalho', dataValidade: dataValida, fileId: fakeFileId },
  { entidadeId: ids.func3, entidadeTipo: 'Funcionario', tipoDocumento: 'Treinamento de Biossegurança', dataValidade: dataAlerta, fileId: fakeFileId },

  // --- MÁQUINA 1 (Autoclave) ---
  { entidadeId: ids.maq1, entidadeTipo: 'Maquina', tipoDocumento: 'Certificado de Calibração', dataValidade: dataAlerta, fileId: fakeFileId },

  // --- MÁQUINA 2 (Máquina de Corte) ---
  { entidadeId: ids.maq2, entidadeTipo: 'Maquina', tipoDocumento: 'Garantia', dataValidade: dataVencida, fileId: fakeFileId }
];

async function popularBanco() {
  try {
    console.log('⏳ Conectando ao Atlas...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Conectado!');

    console.log('⏳ Inserindo registros de teste...');
    await Documento.insertMany(registros);
    
    console.log('🚀 10 Registros criados com sucesso!');
    process.exit(0); // Fecha o script
  } catch (erro) {
    console.error('❌ Erro ao popular banco:', erro);
    process.exit(1);
  }
}

popularBanco();