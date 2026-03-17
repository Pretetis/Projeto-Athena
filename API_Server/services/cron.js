const cron = require('node-cron');
const nodemailer = require('nodemailer');
const Documento = require('../models/Documento');

// 1. Configurar o email
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

const iniciarAutomacoes = () => {
  // O padrão '0 8 * * *' significa: Minuto 0, Hora 8, Todos os dias.
  cron.schedule('0 8 * * *', async () => {
  // cron.schedule('* * * * *', async () => {        // linha para teste
    console.log('⏳ A iniciar a verificação diária de documentos...');

    try {
      const hoje = new Date();
      const trintaDias = new Date();
      trintaDias.setDate(hoje.getDate() + 30);

      // Procura os documentos tal como fizemos na rota de alertas
      const docs = await Documento.find({
        ativo: true,
        dataValidade: { $lte: trintaDias }
      }).sort({ dataValidade: 1 });

      if (docs.length === 0) {
        console.log('✅ Nenhum documento a vencer. Email não enviado.');
        return; // Interrompe a execução aqui
      }

      // 2. Construir o conteúdo do Email em HTML
      let htmlBody = `
        <h2 style="color: #d9534f;">⚠️ Alerta Athena: Documentos Pendentes</h2>
        <p>Bom dia! Os seguintes documentos necessitam de atenção (vencidos ou a vencer nos próximos 30 dias):</p>
        <table border="1" cellpadding="8" cellspacing="0" style="border-collapse: collapse; width: 100%;">
          <tr style="background-color: #f2f2f2;">
            <th>Tipo de Documento</th>
            <th>ID da Entidade</th>
            <th>Data de Validade</th>
            <th>Estado</th>
          </tr>
      `;

      docs.forEach(doc => {
        const dataFormatada = doc.dataValidade.toLocaleDateString('pt-PT');
        const estaVencido = doc.dataValidade < hoje;
        const corEstado = estaVencido ? 'color: red; font-weight: bold;' : 'color: orange;';
        const textoEstado = estaVencido ? 'Vencido' : 'A Vencer';

        htmlBody += `
          <tr>
            <td>${doc.tipoDocumento}</td>
            <td>${doc.entidadeId}</td>
            <td>${dataFormatada}</td>
            <td style="${corEstado}">${textoEstado}</td>
          </tr>
        `;
      });

      htmlBody += '</table><br><p>Sistema automatizado AthenaDocs.</p>';

      // 3. Enviar o Email
      await transporter.sendMail({
        from: `"AthenaDocs Alertas" <${process.env.EMAIL_USER}>`,
        to: process.env.EMAIL_DESTINO,
        subject: `⚠️ ${docs.length} Documento(s) a Vencer - AthenaDocs`,
        html: htmlBody
      });

      console.log('📧 Email diário enviado com sucesso aos gestores!');

    } catch (error) {
      console.error('❌ Erro na execução do Cron Job:', error);
    }
  }, {
    scheduled: true,
    timezone: "America/Sao_Paulo" // Garante que as 08:00 são no fuso horário do Brasil
  });

  console.log('⏰ Automação de Emails configurada para as 08:00 (Fuso: Brasília).');
};

module.exports = iniciarAutomacoes;