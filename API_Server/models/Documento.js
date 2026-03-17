const mongoose = require('mongoose');

const DocumentoSchema = new mongoose.Schema({
  // Referência ao ID da Entidade 
  entidadeId: { 
    type: mongoose.Schema.Types.ObjectId, 
    required: true 
  },
  entidadeTipo: { type: String },
  tipoDocumento: { type: String },
  dataValidade: { type: Date, required: true },
  
  // Aqui está o segredo: salvamos o ID do arquivo que está lá no GridFS
  fileId: { 
    type: mongoose.Schema.Types.ObjectId, 
    required: true 
  },
  
  ativo: { type: Boolean, default: true }
}, { 
  timestamps: true // Isso cria automaticamente os campos 'createdAt' e 'updatedAt'
});

module.exports = mongoose.model('Documento', DocumentoSchema);