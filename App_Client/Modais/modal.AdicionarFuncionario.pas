unit modal.AdicionarFuncionario;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Effects, FMX.DateTimeCtrls, FMX.Layouts, FMX.ListBox, FMX.Edit, FMX.Objects,
  FMX.Controls.Presentation, System.JSON,

   uRequests;

type
  TFrameModalAdicionarFuncionario = class(TFrame)
    OpenDialog1: TOpenDialog;
    recFundo: TRectangle;
    layTitulo: TLayout;
    lbTitulo: TLabel;
    Line1: TLine;
    layFecharModal: TLayout;
    pathFecharModal: TPath;
    layOpcoes: TLayout;
    layFuncionario: TLayout;
    lbNomeFuncionario: TLabel;
    recFundoNomeFunc: TRectangle;
    edtNomeFunc: TEdit;
    layFuncao: TLayout;
    lbFuncao: TLabel;
    recFuncao: TRectangle;
    edtFuncao: TEdit;
    laySetor: TLayout;
    lbSetor: TLabel;
    recSetor: TRectangle;
    edtSetor: TEdit;
    layChapa: TLayout;
    lbChapa: TLabel;
    recChapa: TRectangle;
    layDropZone: TLayout;
    lbDropZone: TLabel;
    recDropZone: TRectangle;
    lbInsideDropZone: TLabel;
    Layout3: TLayout;
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
    edtChapa: TEdit;
    procedure lbInsideDropZoneClick(Sender: TObject);
    procedure lbInsideDropZoneDragDrop(Sender: TObject; const Data: TDragObject; const Point: TPointF);
    procedure lbInsideDropZoneDragOver(Sender: TObject; const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation);
    procedure layFecharModalClick(Sender: TObject);
    procedure Rectangle3Click(Sender: TObject);
  private
    FCaminhoArquivo: string;
    procedure ProcessarArquivo(const ACaminho: string);
    procedure OnRequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
    procedure SalvarFuncionario;
    { Private declarations }
  public
    OnSalvoComSucesso: TProc;
    procedure CarregarChapa;
    { Public declarations }
  end;

implementation

uses
    uMenu;
{$R *.fmx}


procedure TFrameModalAdicionarFuncionario.CarregarChapa;
var
  LReq: TModuloRequest;
begin
  LReq := TModuloRequest.Create(TForm(Self.Root.GetObject), OnRequestResult);
  LReq.BuscarProximaChapa;
end;

procedure TFrameModalAdicionarFuncionario.lbInsideDropZoneDragDrop(Sender: TObject; const Data: TDragObject; const Point: TPointF);
var
  CaminhoDoArquivo: string;
begin
    if Length(Data.Files) > 0 then
    begin
        CaminhoDoArquivo := Data.Files[0];
        ProcessarArquivo(CaminhoDoArquivo);
    end;
end;

procedure TFrameModalAdicionarFuncionario.lbInsideDropZoneDragOver(Sender: TObject; const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation);
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

procedure TFrameModalAdicionarFuncionario.ProcessarArquivo(const ACaminho: string);
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

procedure TFrameModalAdicionarFuncionario.Rectangle3Click(Sender: TObject);
begin
    SalvarFuncionario;
end;

procedure TFrameModalAdicionarFuncionario.SalvarFuncionario;
var
  LReq: TModuloRequest;
begin
    if Trim(edtNomeFunc.Text) = '' then
    begin
        ShowMessage('Preencha o nome.');
        Exit;
    end;

    LReq := TModuloRequest.Create(TForm(Self.Root.GetObject), OnRequestResult);
    LReq.EnviarFuncionario(
      edtNomeFunc.Text,
      edtFuncao.Text,
      edtSetor.Text,
      edtChapa.Text,
      FCaminhoArquivo
    );
end;

procedure TFrameModalAdicionarFuncionario.layFecharModalClick(Sender: TObject);
begin
    fMenu.EfeitoBlur.Enabled := False;
    Self.Free;
end;

procedure TFrameModalAdicionarFuncionario.lbInsideDropZoneClick(Sender: TObject);
begin
    OpenDialog1.Filter := 'Arquivos Suportados|*.pdf;*.jpg;*.jpeg;*.png';
    if OpenDialog1.Execute then
    begin
        ProcessarArquivo(OpenDialog1.FileName);
    end;
end;

procedure TFrameModalAdicionarFuncionario.OnRequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
var
  LJsonObj: TJSONObject;
begin
    if AContext = ctxProximaChapa then
    begin
        if AStatusCode = 200 then
        begin
            LJsonObj := TJSONObject.ParseJSONValue(AJsonContent) as TJSONObject;
            if Assigned(LJsonObj) then
            try
                edtChapa.Text := LJsonObj.GetValue<string>('proximaChapa', '');
            finally
                LJsonObj.Free;
            end;
        end;
    end
    else if AContext = ctxCriarFuncionario then
    begin
        if (AStatusCode = 201) or (AStatusCode = 200) then
        begin
            ShowMessage('Funcionário adicionado com sucesso!');
            if Assigned(OnSalvoComSucesso) then
                OnSalvoComSucesso();
            fMenu.EfeitoBlur.Enabled := False;
            Self.Free;
        end
        else
          ShowMessage('Erro: ' + AJsonContent);
    end;
end;

end.
