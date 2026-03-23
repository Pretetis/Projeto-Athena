const mongoose = require('mongoose');

const empresaSchema = new mongoose.Schema({
  nome:          { type: String, required: true },
  dataCadastro:  { type: Date, default: Date.now }
}, { timestamps: true });

module.exports = mongoose.model('Empresa', empresaSchema);