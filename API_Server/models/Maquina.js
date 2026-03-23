const mongoose = require('mongoose');

const maquinaSchema = new mongoose.Schema({
  nome:          { type: String, required: true },
  funcao:        { type: String, required: false }, // ex: "Esterilização", "Corte"
  chapa:         { type: String, required: true, unique: true },
  ativo:         { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model('Maquina', maquinaSchema);