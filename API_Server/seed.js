require('dotenv').config();
const mongoose = require('mongoose');

// Importe seus modelos (ajuste o caminho se necessário)
const Funcionario = require('./models/Funcionario');
const Maquina = require('./models/Maquina');
const Empresa = require('./models/Empresa');
const Documento = require('./models/Documento');

async function executarSeed() {
  try {
    // 1. Conexão
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Conectado ao MongoDB para executar o seed...');

    // 2. Limpar os registros anteriores (Evita duplicações ao rodar várias vezes)
    await Funcionario.deleteMany({});
    await Maquina.deleteMany({});
    await Empresa.deleteMany({});
    await Documento.deleteMany({});
    console.log('🗑️  Bancos de Funcionários, Máquinas, Empresas e Documentos limpos.');

    // 3. Inserir Funcionários (Os _ids serão gerados automaticamente)
    const funcionarios = await Funcionario.insertMany([
      { nome: 'Dalinar Kholin', funcao: 'Diretor de Obras', chapa: 'F1001', ativo: true },
      { nome: 'Kaladin Stormblessed', funcao: 'Engenheiro de Segurança', chapa: 'F1002', ativo: true },
      { nome: 'Adolin Kholin', funcao: 'Supervisor de Frota', chapa: 'F1003', ativo: true }
    ]);
    console.log(`👥 ${funcionarios.length} funcionários criados.`);

    // 4. Inserir Máquinas
    const maquinas = await Maquina.insertMany([
      { nome: 'Escavadeira Hidráulica CAT 320', chapa: 'M1001', ativo: true },
      { nome: 'Trator de Esteira D6', chapa: 'M1002', ativo: true },
      { nome: 'Caminhão Munck Volvo', chapa: 'M1003', ativo: true }
    ]);
    console.log(`🚜 ${maquinas.length} máquinas criadas.`);

    // --- Auxiliares de Data para simular os status do seu Dashboard ---
    const hoje = new Date();
    const daqui1Ano = new Date(hoje.getTime() + (365 * 24 * 60 * 60 * 1000)); // Válido
    const daqui15Dias = new Date(hoje.getTime() + (15 * 24 * 60 * 60 * 1000)); // A expirar (<= 30 dias)
    const mesPassado = new Date(hoje.getTime() - (30 * 24 * 60 * 60 * 1000));  // Expirado

    // 5. Inserir Documentos amarrados aos IDs recém-criados
    const documentos = await Documento.insertMany([
      // --- Documentos do Dalinar ---
      {
        nomeDocumento: 'ASO - Dalinar Kholin',
        tipoDocumento: 'Saúde Ocupacional',
        entidadeId: funcionarios[0]._id, // Pega o ID gerado para o Dalinar
        entidadeTipo: 'funcionario',
        dataValidade: daqui1Ano,
        ativo: true,
        fileId: new mongoose.Types.ObjectId()
      },
      {
        nomeDocumento: 'Certificado NR-35 - Dalinar',
        tipoDocumento: 'Treinamento',
        entidadeId: funcionarios[0]._id,
        entidadeTipo: 'funcionario',
        dataValidade: mesPassado, // Simulando um doc vencido
        ativo: true,
        fileId: new mongoose.Types.ObjectId()
      },

      // --- Documentos do Kaladin ---
      {
        nomeDocumento: 'ASO - Kaladin',
        tipoDocumento: 'Saúde Ocupacional',
        entidadeId: funcionarios[1]._id,
        entidadeTipo: 'funcionario',
        dataValidade: daqui15Dias, // Simulando um doc a vencer em < 30 dias
        ativo: true,
        fileId: new mongoose.Types.ObjectId()
      },
      {
        nomeDocumento: 'Ficha de EPI - Kaladin',
        tipoDocumento: 'Controle de Equipamentos',
        entidadeId: funcionarios[1]._id,
        entidadeTipo: 'funcionario',
        dataValidade: daqui1Ano,
        ativo: true,
        fileId: new mongoose.Types.ObjectId()
      },

      // --- Documentos do Adolin ---
      {
        nomeDocumento: 'CNH Categoria E - Adolin',
        tipoDocumento: 'Identificação',
        entidadeId: funcionarios[2]._id,
        entidadeTipo: 'funcionario',
        dataValidade: daqui1Ano,
        ativo: true,
        fileId: new mongoose.Types.ObjectId()
      },

      // --- Documentos da Escavadeira ---
      {
        nomeDocumento: 'Laudo de Manutenção Preventiva - CAT 320',
        tipoDocumento: 'Manutenção',
        entidadeId: maquinas[0]._id, // Pega o ID gerado para a Escavadeira
        entidadeTipo: 'maquina',
        dataValidade: daqui1Ano,
        ativo: true,
        fileId: new mongoose.Types.ObjectId()
      },
      {
        nomeDocumento: 'Seguro Obrigatório - CAT 320',
        tipoDocumento: 'Seguro',
        entidadeId: maquinas[0]._id,
        entidadeTipo: 'maquina',
        dataValidade: daqui15Dias, // A vencer
        ativo: true,
        fileId: new mongoose.Types.ObjectId()
      },

      // --- Documentos do Caminhão Munck ---
      {
        nomeDocumento: 'Licença de Tráfego - Caminhão Munck',
        tipoDocumento: 'Licença',
        entidadeId: maquinas[2]._id,
        entidadeTipo: 'maquina',
        dataValidade: mesPassado, // Expirado
        ativo: true,
        fileId: new mongoose.Types.ObjectId()
      }
    ]);
    console.log(`📄 ${documentos.length} documentos criados e vinculados com sucesso.`);

    console.log('🎉 Processo de Seed finalizado!');
    process.exit(0); // Encerra o script com sucesso

  } catch (error) {
    console.error('❌ Erro ao popular o banco:', error);
    process.exit(1); // Encerra o script com erro
  }
}

executarSeed();