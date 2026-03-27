unit frame.LinhaTelaFuncionario;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Layouts, FMX.Objects;

type
  TfLinhaTelaFuncionario = class(TFrame)
    recFundoLinha: TRectangle;
    GridPanelLayout1: TGridPanelLayout;
    recLinhaDoc: TLayout;
    lbInfoDoc: TLabel;
    lbInfoTipoDoc: TLabel;
    recLinhaVencimento: TRectangle;
    lbInfoVencimento: TLabel;
    recLinhaVisualizar: TRectangle;
    recBtnVisualizar: TRectangle;
    lbBtnVisualizar: TLabel;
    procedure recBtnVisualizarClick(Sender: TObject);
  private
    { Private declarations }
  public
    FDocId: string;
    FNomeDoc: string;
    FNomeEntidade: string;

    procedure CarregarDados(ANomeDoc, ATipoDoc, AVencimento: string);
  end;

implementation

uses
  System.DateUtils, uParametros, modal.VisualizarDocumento;

{$R *.fmx}

procedure TfLinhaTelaFuncionario.CarregarDados(ANomeDoc, ATipoDoc, AVencimento: string);
begin
  lbInfoDoc.Text := ANomeDoc;
  lbInfoTipoDoc.Text := ATipoDoc;

  try
    lbInfoVencimento.Text := FormatDateTime('dd/mm/yyyy', ISO8601ToDate(AVencimento));
  except
    lbInfoVencimento.Text := AVencimento;
  end;
end;

procedure TfLinhaTelaFuncionario.recBtnVisualizarClick(Sender: TObject);
var
  LModal: TFrameVisualizarDocumento;
begin
  // Aproveita a mesma modal que você já criou para a tela de documentos
  LModal := TFrameVisualizarDocumento.Create(Self.Root.GetObject as TForm);
  LModal.Parent := Self.Root.GetObject as TForm;
  LModal.Align := TAlignLayout.Contents;
  LModal.AbrirModal(FDocId, FNomeDoc, FNomeEntidade);
end;

end.
