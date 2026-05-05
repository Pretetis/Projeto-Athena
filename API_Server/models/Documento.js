const mongoose = require('mongoose');

const DocumentoSchema = new mongoose.Schema({
  entidadeId: { type: mongoose.Schema.Types.ObjectId, required: true },
  entidadeTipo: { type: String, required: true }, // Ex: 'Funcionario', 'Maquina'
  
  nomeDocumento: { type: String, required: true }, // Ex: 'Licença Sanitária Individual'
  tipoDocumento: { type: String, required: true }, // Ex: 'Saúde', 'Norma', 'Trabalhista'
  
  dataValidade: { type: Date, required: true },
  fileId: { type: mongoose.Schema.Types.ObjectId, required: true },
  ativo: { type: Boolean, default: true },

  //--- LGPD ---
  isDadoSensivel: { type: Boolean, default: false },
  baseLegal: { type: String, default: 'Execução de Contrato' },
  inseridoPor: { type: mongoose.Schema.Types.ObjectId, ref: 'Funcionario' }
}, {
  timestamps: true
});

module.exports = mongoose.model('Documento', DocumentoSchema);