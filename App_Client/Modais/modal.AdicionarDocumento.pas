unit modal.AdicionarDocumento;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Objects, FMX.Controls.Presentation, FMX.Layouts, FMX.DateTimeCtrls,
  System.DateUtils, uRequests;

type
  TFrameModalEnivarDocumento = class(TFrame)
    recFundo: TRectangle;
    layTitulo: TLayout;
    layOpcoes: TLayout;
    Layout3: TLayout;
    lbTitulo: TLabel;
    Line1: TLine;
    layTituloDoc: TLayout;
    lbTituloDoc: TLabel;
    recFundoTituloDoc: TRectangle;
    edtTituloDoc: TEdit;
    layTipoDoc: TLayout;
    lbTipoDoc: TLabel;
    recTIpoDoc: TRectangle;
    edtTipoDoc: TEdit;
    layFuncionario: TLayout;
    lbFuncionario: TLabel;
    recFuncionario: TRectangle;
    edtFuncionario: TEdit;
    layVencimento: TLayout;
    lbVencimento: TLabel;
    recVencimento: TRectangle;
    DateEdit1: TDateEdit;
    layDropZone: TLayout;
    lbDropZone: TLabel;
    recDropZone: TRectangle;
    lbInsideDropZone: TLabel;
    OpenDialog1: TOpenDialog;
    Rectangle1: TRectangle;
    Rectangle2: TRectangle;
    recBtnAddDocumento: TRectangle;
    lbBtnAddDocumento: TLabel;
    Path1: TPath;
    Layout1: TLayout;
    Rectangle3: TRectangle;
    Path2: TPath;
    Label1: TLabel;
    procedure recDropZoneDragDrop(Sender: TObject; const Data: TDragObject; const Point: TPointF);
    procedure recDropZoneDragOver(Sender: TObject; const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation);
    procedure recDropZoneClick(Sender: TObject);
    procedure Rectangle3Click(Sender: TObject);
  private
    FCaminhoArquivo: string;
    FReq: TModuloRequest;
    procedure ProcessarArquivo(const ACaminho: string);
    procedure RequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest); // <-- ADICIONADO
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

procedure TFrameModalEnivarDocumento.recDropZoneClick(Sender: TObject);
begin
  OpenDialog1.Filter := 'Arquivos Suportados|*.pdf;*.jpg;*.jpeg;*.png';
  if OpenDialog1.Execute then
  begin
    ProcessarArquivo(OpenDialog1.FileName);
  end;
end;

procedure TFrameModalEnivarDocumento.recDropZoneDragDrop(Sender: TObject; const Data: TDragObject; const Point: TPointF);
var
  CaminhoDoArquivo: string;
begin
  if Length(Data.Files) > 0 then
  begin
    CaminhoDoArquivo := Data.Files[0];
    ProcessarArquivo(CaminhoDoArquivo);
  end;
end;

procedure TFrameModalEnivarDocumento.recDropZoneDragOver(Sender: TObject; const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation);
var
  Extensao: string;
begin
  Operation := TDragOperation.None;

  if Length(Data.Files) > 0 then
  begin
    Extensao := LowerCase(ExtractFileExt(Data.Files[0]));

    if (Extensao = '.pdf') or (Extensao = '.jpg') or (Extensao = '.jpeg') or (Extensao = '.png') then
      Operation := TDragOperation.Copy;
  end;
end;

procedure TFrameModalEnivarDocumento.Rectangle3Click(Sender: TObject);
begin
  // 1. Validações Básicas

  if Trim(edtFuncionario.Text) = '' then
  begin
    ShowMessage('Informe o funcionário (entidadeId).');
    edtFuncionario.SetFocus;
    Exit;
  end;

  if Trim(edtTituloDoc.Text) = '' then
  begin
    ShowMessage('Informe o título do documento.');
    edtTituloDoc.SetFocus;
    Exit;
  end;

  if Trim(edtTipoDoc.Text) = '' then
  begin
    ShowMessage('Informe o tipo do documento.');
    edtTipoDoc.SetFocus;
    Exit;
  end;

  if DateEdit1.Date <= 0 then
  begin
    ShowMessage('Informe uma data de validade.');
    DateEdit1.SetFocus;
    Exit;
  end;

  if FCaminhoArquivo = '' then
  begin
    ShowMessage('Por favor, selecione um arquivo (PDF ou Imagem) na DropZone.');
    Exit;
  end;

  // 2. Envia para o Servidor
  FReq := TModuloRequest.Create(nil, RequestResult);

  FReq.EnviarDocumento(
    edtFuncionario.Text,
    'funcionario',
    edtTipoDoc.Text,
    edtTituloDoc.Text,
    DateEdit1.Date,
    FCaminhoArquivo
  );
end;

procedure TFrameModalEnivarDocumento.ProcessarArquivo(const ACaminho: string);
var
  Extensao: string;
begin
  FCaminhoArquivo := ACaminho;

  Extensao := LowerCase(ExtractFileExt(ACaminho));

  if Extensao = '.pdf' then
  begin
    recDropZone.Fill.Color := $FFD4EDDA;
    lbInsideDropZone.Text := 'PDF Selecionado: ' + ExtractFileName(ACaminho);
  end
  else
  begin
    recDropZone.Fill.Color := $FFD4EDDA;
    lbInsideDropZone.Text := ExtractFileName(ACaminho);
  end;
end;

procedure TFrameModalEnivarDocumento.RequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
begin
  if AContext = ctxEnviarDocumento then
  begin
    if (AStatusCode = 200) or (AStatusCode = 201) then
    begin
      ShowMessage('Documento enviado com sucesso!');

      Self.Free;
    end
    else
      ShowMessage('Erro ao enviar documento: ' + AJsonContent);
  end;
end;

end.
