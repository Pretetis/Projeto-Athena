const mongoose = require('mongoose');

const maquinaSchema = new mongoose.Schema({
  nome: { type: String, required: true },
  tipo: { type: String, required: false },   
  modelo: { type: String, required: false }, 
  chapa: { type: String, required: true, unique: true },
  fotoId: { type: mongoose.Schema.Types.ObjectId }, // <-- ESSE CARA AQUI SALVA A FOTO!
  ativo: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model('Maquina', maquinaSchema);