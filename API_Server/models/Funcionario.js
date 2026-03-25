const mongoose = require('mongoose');

const FuncionarioSchema = new mongoose.Schema({
  nome: { type: String, required: true },
  funcao: { type: String, required: true },
  setor: { type: String }, 
  chapa: { type: String, required: true, unique: true },
  fotoId: { type: mongoose.Schema.Types.ObjectId }, 
  ativo: { type: Boolean, default: true }
}, { 
  timestamps: true 
});

module.exports = mongoose.model('Funcionario', FuncionarioSchema);