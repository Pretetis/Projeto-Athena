const mongoose = require('mongoose');

const FuncionarioSchema = new mongoose.Schema({
  nome: { type: String, required: true },
  funcao: { type: String, required: true },
  setor: { type: String }, 
  chapa: { type: String, required: true, unique: true },
  fotoId: { type: mongoose.Schema.Types.ObjectId }, 
  nivelAcesso: { type: Number, default: 3 },
  senha: { type: String, select: false },
  ativo: { type: Boolean, default: true },

  // --- LGPD ---
  termosAceitos: { type: Boolean, default: false },
  termosAceitosFotoPerfil: { type: Boolean, default: true },
  dataAceiteTermos: { type: Date },
  baseLegal: { type: String, default: 'Execução de Contrato' },
  consentimentoRevogado: { type: Boolean, default: false },
  dataRevogacaoConsentimento: { type: Date },
  motivoRevogacao: { type: String },
  anonimizado: { type: Boolean, default: false },
  dataAnonimizacao: { type: Date }
}, {
  timestamps: true
});

module.exports = mongoose.model('Funcionario', FuncionarioSchema);