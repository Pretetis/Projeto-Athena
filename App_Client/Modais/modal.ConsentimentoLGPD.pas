unit modal.ConsentimentoLGPD;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.WebBrowser, FMX.Effects, FMX.Objects, FMX.Controls.Presentation, FMX.Layouts, FMX.Filter.Effects;

type
  TFrameModalConsentimentoLGPD = class(TFrame)
    OpenDialog1: TOpenDialog;
    recFundo: TRectangle;
    layTitulo: TLayout;
    lbTitulo: TLabel;
    Line1: TLine;
    layFecharModal: TLayout;
    layOpcoes: TLayout;
    Layout3: TLayout;
    Layout1: TLayout;
    recBtnCancelarDocumento: TRectangle;
    lbBtnCancelarDocumento: TLabel;
    btnSalvar: TRectangle;
    Label1: TLabel;
    recOverlay: TRectangle;
    BlurEffect1: TBlurEffect;
    wbConsentimento: TWebBrowser;
    Layout2: TLayout;
    recFundoCinza: TRectangle;
    Layout4: TLayout;
    cbFoto: TCheckBox;
    Layout5: TLayout;
    cbConsentimentoTotal: TCheckBox;
    imgAdicionar: TImage;
    FillRGBEffect3: TFillRGBEffect;
    imgFechar: TImage;
    FillRGBEffect1: TFillRGBEffect;
    procedure btnSalvarClick(Sender: TObject);
    procedure recBtnCancelarDocumentoClick(Sender: TObject);
  private
    FOnAccept: TProc<Boolean>;
    FOnCancel: TProc;
  public
    class procedure Exibir(AOwner: TComponent; AParent: TControl; ATextoLGPD: string; AOnAccept: TProc<Boolean>; AOnCancel: TProc);
  end;

implementation

{$R *.fmx}

class procedure TFrameModalConsentimentoLGPD.Exibir(AOwner: TComponent; AParent: TControl; ATextoLGPD: string; AOnAccept: TProc<Boolean>; AOnCancel: TProc);
var
  Frame: TFrameModalConsentimentoLGPD;
  TextoHtml: string;
begin
  Frame := TFrameModalConsentimentoLGPD.Create(AOwner);
  Frame.Parent := AParent;
  Frame.Align := TAlignLayout.Contents;
  Frame.BringToFront;

  Frame.FOnAccept := AOnAccept;
  Frame.FOnCancel := AOnCancel;

  // Monta o HTML com o texto que veio do banco e substitui quebras de linha nativas por <br>
  TextoHtml :=
    '<html><head><style>' +
    '  body { font-family: Arial, sans-serif; font-size: 14px; color: #333333; text-align: justify; line-height: 1.6; padding: 15px; }' +
    '</style></head><body>' +
    ATextoLGPD.Replace(#10, '<br>').Replace(#13, '') +
    '</body></html>';

  Frame.wbConsentimento.LoadFromStrings(TextoHtml, '');
end;

procedure TFrameModalConsentimentoLGPD.btnSalvarClick(Sender: TObject);
begin
  // Bloqueia caso o consentimento obrigatório não esteja marcado
  if not cbConsentimentoTotal.IsChecked then
  begin
    ShowMessage('É obrigatório aceitar o termo principal de LGPD para continuar.');
    Exit;
  end;

  if Assigned(FOnAccept) then
    FOnAccept(cbFoto.IsChecked); // Passa se aceitou ou não o uso da foto

  Self.Free;
end;

procedure TFrameModalConsentimentoLGPD.recBtnCancelarDocumentoClick(Sender: TObject);
begin
  if Assigned(FOnCancel) then
    FOnCancel;

  Self.Free;
end;

end.
