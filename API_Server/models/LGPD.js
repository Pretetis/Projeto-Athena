const mongoose = require('mongoose');

const LGPDSchema = new mongoose.Schema({
  LGPD: { type: String, required: true },
  isAtivo: { type: Boolean, default: true }
}, {
  collection: 'LGPD',
  timestamps: true
});

module.exports = mongoose.model('LGPD', LGPDSchema);
