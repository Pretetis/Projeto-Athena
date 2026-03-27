// server.js
require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const iniciarAutomacoes = require('./services/cron'); 

// 1. Importando as rotas
const documentosRoutes = require('./routes/documentos');
const funcionariosRoutes = require('./routes/funcionarios');
const maquinasRoutes = require('./routes/maquinas');
const utilidadesRoutes = require('./routes/utilidades');

const app = express();
app.use(express.json());

// 2. Conexão Atlas e configuração do GridFS
let gfsBucket;
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('✅ Conectado ao MongoDB Atlas'))
  .catch(err => console.error('❌ Erro de conexão:', err));

mongoose.connection.once('open', () => {
  gfsBucket = new mongoose.mongo.GridFSBucket(mongoose.connection.db, {
    bucketName: 'pdfs_bucket'
  });
  console.log("✅ GridFS Bucket pronto.");
});

// 3. Middleware Mágico: Injeta o gfsBucket em todas as requisições
// Isso permite que os arquivos dentro da pasta /routes consigam ler/salvar arquivos
app.use((req, res, next) => {
  req.gfsBucket = gfsBucket;
  next();
});

// 4. Registrando as Rotas
// O prefixo é definido aqui. Ex: toda rota em documentosRoutes começará com /documentos
app.use('/documentos', documentosRoutes);
app.use('/funcionarios', funcionariosRoutes);
app.use('/maquinas', maquinasRoutes);
app.use('/', utilidadesRoutes); // Lookups e outras rotas gerais

// 5. Iniciar Cron Jobs
iniciarAutomacoes(); 

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => console.log(`🚀 Servidor rodando na porta ${PORT}`));