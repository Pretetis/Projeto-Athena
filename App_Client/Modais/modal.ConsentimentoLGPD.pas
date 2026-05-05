unit modal.ConsentimentoLGPD;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.WebBrowser, FMX.Effects, FMX.Objects, FMX.Controls.Presentation, FMX.Layouts;

type
  TFrameModalConsentimentoLGPD = class(TFrame)
    OpenDialog1: TOpenDialog;
    recFundo: TRectangle;
    layTitulo: TLayout;
    lbTitulo: TLabel;
    Line1: TLine;
    layFecharModal: TLayout;
    pathFecharModal: TPath;
    layOpcoes: TLayout;
    Layout3: TLayout;
    Layout1: TLayout;
    recBtnCancelarDocumento: TRectangle;
    lbBtnCancelarDocumento: TLabel;
    recBtnSalvar: TRectangle;
    Path2: TPath;
    Label1: TLabel;
    recOverlay: TRectangle;
    BlurEffect1: TBlurEffect;
    wbConsentimento: TWebBrowser;
    Layout2: TLayout;
    Rectangle1: TRectangle;
    Layout4: TLayout;
    CheckBox1: TCheckBox;
    Layout5: TLayout;
    CheckBox2: TCheckBox;
  private
    { Private declarations }
  public
    constructor Create(AOwner: TComponent);
    { Public declarations }
  end;

implementation

{$R *.fmx}

constructor TFrameModalConsentimentoLGPD.Create(AOwner: TComponent);
var
    TextoLGPD: string;
begin
    // Monta o HTML com CSS para justificar (text-align) e dar espaçamento (line-height)
    TextoLGPD :=
      '<html>' +
      '<head>' +
      '<style>' +
      '  body { ' +
      '    font-family: Arial, sans-serif; ' +
      '    font-size: 16px; ' +
      '    color: #333333; ' +
      '    text-align: justify; ' + // Justifica o texto
      '    line-height: 1.6; ' +    // Aumenta o espaçamento entre linhas
      '    padding: 15px; ' +       // Dá uma margem interna nas bordas
      '  }' +
      '</style>' +
      '</head>' +
      '<body>' +
      '  <h3>Termo de Consentimento LGPD</h3>' +
      '  <p>Para continuarmos, precisamos do seu consentimento de acordo com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018). Seus dados serão utilizados exclusivamente para...</p>' +
      '  <p>Aqui entra o restante do seu texto longo, que agora terá barras de rolagem nativas, estará perfeitamente justificado e fácil de ler.</p>' +
      '</body>' +
      '</html>';

    // Carrega o HTML diretamente no componente
    wbConsentimento.LoadFromStrings(TextoLGPD, '');
end;

end.
