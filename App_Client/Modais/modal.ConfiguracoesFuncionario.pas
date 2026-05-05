unit modal.ConfiguracoesFuncionario;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Effects, FMX.Edit, FMX.Objects, FMX.Controls.Presentation, FMX.Layouts;

type
  TFrame1 = class(TFrame)
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
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

end.
