unit modal.ConfiguracoesFuncionario;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Effects, FMX.Edit, FMX.Objects, FMX.Controls.Presentation, FMX.Layouts;

type
  TFrameModalConfiguracoesFuncionario = class(TFrame)
    OpenDialog1: TOpenDialog;
    recFundo: TRectangle;
    layTitulo: TLayout;
    lbTitulo: TLabel;
    Line1: TLine;
    layFecharModal: TLayout;
    pathFecharModal: TPath;
    laySenha: TLayout;
    laySenhaAtual: TLayout;
    lbSenhaAtual: TLabel;
    recSenhaAtual: TRectangle;
    edtSenhaAtual: TEdit;
    layNovaSenha: TLayout;
    lbNovaSenha: TLabel;
    recNovaSenha: TRectangle;
    edtNovaSenha: TEdit;
    layConfirmarSenha: TLayout;
    recConfirmarSenha: TRectangle;
    edtConfirmarSenha: TEdit;
    layFim: TLayout;
    Rectangle1: TRectangle;
    Rectangle2: TRectangle;
    Layout1: TLayout;
    recBtnCancelarDocumento: TRectangle;
    lbBtnCancelarDocumento: TLabel;
    Rectangle3: TRectangle;
    Path2: TPath;
    Label1: TLabel;
    recOverlay: TRectangle;
    BlurEffect1: TBlurEffect;
    Layout2: TLayout;
    btnConsentimentoLGPD: TRectangle;
    lbConsentimentoLGPD: TLabel;
    laySenhaCenter: TLayout;
    lbConfirmarSenha: TLabel;
    procedure recBtnSalvarClick(Sender: TObject); // Vincule ao botão Salvar (Rectangle1 ou Rectangle2)
    procedure recBtnCancelarDocumentoClick(Sender: TObject); // Vincule ao botão Cancelar
  private
    FOnSuccess: TProc;
  public
    class procedure Exibir(AOwner: TComponent; AParent: TControl; AOnSuccess: TProc);
  end;

implementation

uses uRequests, uParametros, FMX.frame.PopUpToast; // Não esqueça desses uses!

{$R *.fmx}

class procedure TFrameModalConfiguracoesFuncionario.Exibir(AOwner: TComponent; AParent: TControl; AOnSuccess: TProc);
var
  Frame: TFrameModalConfiguracoesFuncionario;
begin
  Frame := TFrameModalConfiguracoesFuncionario.Create(AOwner);
  Frame.Parent := AParent;
  Frame.Align := TAlignLayout.Contents;
  Frame.BringToFront;

  Frame.FOnSuccess := AOnSuccess;

  // Se for primeiro acesso, o usuário NÃO PODE cancelar, ele é obrigado a trocar a senha
  Frame.recBtnCancelarDocumento.Visible := not mPrimeiroAcesso;
  Frame.layFecharModal.Visible := not mPrimeiroAcesso;
end;

procedure TFrameModalConfiguracoesFuncionario.recBtnSalvarClick(Sender: TObject);
var
  LForm: TForm;
begin
  if Trim(edtSenhaAtual.Text) = '' then
  begin
    ShowMessage('Informe a senha atual.');
    Exit;
  end;

  if Trim(edtNovaSenha.Text) = '' then
  begin
    ShowMessage('Informe a nova senha.');
    Exit;
  end;

  if edtNovaSenha.Text <> edtConfirmarSenha.Text then
  begin
    ShowMessage('A nova senha e a confirmação não conferem.');
    Exit;
  end;

  // 1. Descobre quem é o Form principal que está segurando este Frame com o CAST correto
  if Self.Root.GetObject is TForm then
    LForm := TForm(Self.Root.GetObject)
  else
    LForm := TForm(Application.MainForm); // <-- CORREÇÃO AQUI (Cast explícito para TForm)

  // 2. Chama a API passando o LForm em vez do Self
  TModuloRequest.Create(LForm, nil).AlterarSenha(mIdFuncionario, edtSenhaAtual.Text, edtNovaSenha.Text,
    procedure(Sucesso: Boolean; Msg: string)
    begin
      if Sucesso then
      begin
        ShowMessage('Senha atualizada! Utilize-a nos próximos acessos.');

        // Atualiza a global para refletir a nova senha localmente
        mPrimeiroAcesso := False;

        if Assigned(FOnSuccess) then
          FOnSuccess;

        Self.Free;
      end
      else
        ShowMessage('Falha ao alterar senha: ' + Msg);
    end
  );
end;

procedure TFrameModalConfiguracoesFuncionario.recBtnCancelarDocumentoClick(Sender: TObject);
begin
  Self.Free;
end;

end.
