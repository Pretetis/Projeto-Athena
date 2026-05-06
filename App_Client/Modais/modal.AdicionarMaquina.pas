unit modal.AdicionarMaquina;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Effects, FMX.Edit, FMX.Objects, FMX.Controls.Presentation, FMX.Layouts,
  uRequests, System.JSON, FMX.Filter.Effects;

type
  TFrameModalAdicionarMaquina = class(TFrame)
    OpenDialog1: TOpenDialog;
    recFundo: TRectangle;
    layTitulo: TLayout;
    lbTitulo: TLabel;
    Line1: TLine;
    layFecharModal: TLayout;
    layOpcoes: TLayout;
    layFuncionario: TLayout;
    lbNomeFuncionario: TLabel;
    recFundoNomeMaquina: TRectangle;
    edtNomeMaq: TEdit;
    layTipo: TLayout;
    lbTipo: TLabel;
    recTipo: TRectangle;
    edtTipo: TEdit;
    layModelo: TLayout;
    lbModelo: TLabel;
    recModelo: TRectangle;
    edtModelo: TEdit;
    layChapa: TLayout;
    lbChapa: TLabel;
    recChapa: TRectangle;
    edtChapa: TEdit;
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
    btnSalvar: TRectangle;
    Label1: TLabel;
    recOverlay: TRectangle;
    BlurEffect1: TBlurEffect;
    recLimpar: TRectangle;
    pathLimpar: TPath;
    imgAdicionar: TImage;
    FillRGBEffect3: TFillRGBEffect;
    imgFechar: TImage;
    FillRGBEffect1: TFillRGBEffect;
    procedure btnSalvarClick(Sender: TObject);
    procedure recDropZoneClick(Sender: TObject);
    procedure recDropZoneDragDrop(Sender: TObject; const Data: TDragObject; const Point: TPointF);
    procedure recDropZoneDragOver(Sender: TObject; const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation);
    procedure layFecharModalClick(Sender: TObject);
    procedure recLimparClick(Sender: TObject);
  private
    FCaminhoArquivo: string;
    procedure ProcessarArquivo(const ACaminho: string);
    procedure OnRequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
  public
    OnSalvoComSucesso: TProc;
    procedure CarregarChapa;
  end;

implementation

uses
  uMenu, FMX.frame.PopUpToast, uTelaUtils;

{$R *.fmx}

procedure TFrameModalAdicionarMaquina.CarregarChapa;
begin
    with TModuloRequest.Create(Self.Root.GetObject as TForm, OnRequestResult) do
        BuscarProximaChapa;
end;

procedure TFrameModalAdicionarMaquina.btnSalvarClick(Sender: TObject);
begin
    if Trim(edtNomeMaq.Text) = '' then
    begin
        TFramePopUp.Show(Self.Root.GetObject as TForm, E, 'Preencha o nome da Máquina.');
        Exit;
    end;

    btnSalvar.Enabled := False;

    with TModuloRequest.Create(Self.Root.GetObject as TForm, OnRequestResult) do
        EnviarMaquina(edtNomeMaq.Text, edtTipo.Text, edtModelo.Text, edtChapa.Text, FCaminhoArquivo);
end;

procedure TFrameModalAdicionarMaquina.OnRequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
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
    else if AContext = ctxCriarMaquina then
    begin
        if (AStatusCode = 201) or (AStatusCode = 200) then
        begin
            TFramePopUp.Show(Self.Root.GetObject as TForm, S, 'Máquina adicionada com sucesso!');

            if Assigned(OnSalvoComSucesso) then
                OnSalvoComSucesso();

            AlterarBlurPai(Self, False);
            Self.DisposeOf;
        end
        else
            TFramePopUp.Show(Self.Root.GetObject as TForm, E, 'Erro: ' + AJsonContent);
            btnSalvar.Enabled := True;
    end;
end;

procedure TFrameModalAdicionarMaquina.recDropZoneClick(Sender: TObject);
begin
    OpenDialog1.Filter := 'Arquivos de Imagem|*.jpg;*.jpeg;*.png';
    if OpenDialog1.Execute then
    begin
        ProcessarArquivo(OpenDialog1.FileName);
    end;
end;

procedure TFrameModalAdicionarMaquina.recDropZoneDragDrop(Sender: TObject; const Data: TDragObject; const Point: TPointF);
begin
    if Length(Data.Files) > 0 then
        ProcessarArquivo(Data.Files[0]);
end;

procedure TFrameModalAdicionarMaquina.recDropZoneDragOver(Sender: TObject; const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation);
var
  Extensao: string;
begin
    Operation := TDragOperation.None;
    if Length(Data.Files) > 0 then
    begin
        Extensao := LowerCase(ExtractFileExt(Data.Files[0]));
        if (Extensao = '.jpg') or (Extensao = '.jpeg') or (Extensao = '.png') then
            Operation := TDragOperation.Copy;
    end;
end;

procedure TFrameModalAdicionarMaquina.recLimparClick(Sender: TObject);
begin
    FCaminhoArquivo := '';

    recDropZone.Fill.Kind := TBrushKind.None;
    lbInsideDropZone.Text := 'Arraste o documento aqui ou clique para selecionar';

    recLimpar.Visible := False;
end;

procedure TFrameModalAdicionarMaquina.layFecharModalClick(Sender: TObject);
begin
    AlterarBlurPai(Self, False);
    Self.DisposeOf;
end;

procedure TFrameModalAdicionarMaquina.ProcessarArquivo(const ACaminho: string);
begin
    FCaminhoArquivo := ACaminho;
    recDropZone.Fill.Color := $FFD4EDDA;
    lbInsideDropZone.Text := 'Nova Imagem: ' + ExtractFileName(ACaminho);
    recLimpar.Visible := True;
end;

end.
