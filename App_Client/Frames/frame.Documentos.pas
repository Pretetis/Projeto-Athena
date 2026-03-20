unit frame.Documentos;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Effects, FMX.Controls.Presentation, FMX.Objects, FMX.Edit,
  System.JSON, uRequests, FMX.ListBox;

type
  TFrameDocumentos = class(TFrame)
    recFundo: TRectangle;
    layTitulo: TLayout;
    lbSubTitulo: TLabel;
    lbTitulo: TLabel;
    LayDadosDocs: TLayout;
    recPlanilhaDocumentos: TRectangle;
    ShadowEffect1: TShadowEffect;
    layCabecalhoPlanilhaAlerta: TLayout;
    recCabecalhoPlanilha: TRectangle;
    gplCabecalhoPlanilhaAlerta: TGridPanelLayout;
    recCabecalhoStatus: TRectangle;
    lbStatus: TLabel;
    recCabecalhoDoc: TRectangle;
    lbDoc: TLabel;
    recFuncMaq: TRectangle;
    lbFuncMaq: TLabel;
    recVencimento: TRectangle;
    lbVencimento: TLabel;
    recVisualizar: TRectangle;
    lbVisualizar: TLabel;
    recFiltroDados: TRectangle;
    ShadowEffect2: TShadowEffect;
    Rectangle2: TRectangle;
    Label1: TLabel;
    recBuscaDocumentos: TRectangle;
    layBotoesFiltro: TLayout;
    GridPanelLayout1: TGridPanelLayout;
    layFiltroValidade: TLayout;
    layTituloFiltroValidade: TLayout;
    layBtnValidade: TLayout;
    recBtnValidos: TRectangle;
    lbBtnValidos: TLabel;
    pathFiltroValidade: TPath;
    lbTituloValidade: TLabel;
    recBtnAExpirar: TRectangle;
    lbBtnAExpirar: TLabel;
    recBtnExpirados: TRectangle;
    lbBtnExpirados: TLabel;
    layFiltroAtivos: TLayout;
    layTituloFiltroAtivos: TLayout;
    PathFiltroAtivos: TPath;
    layTituloAtivos: TLabel;
    Layout4: TLayout;
    recBtnAtivos: TRectangle;
    lbBtnAtivos: TLabel;
    recBtnDesativados: TRectangle;
    lbBtnDesativados: TLabel;
    layBtnAddDocumento: TLayout;
    recBtnAddDocumento: TRectangle;
    pathAddDocumento: TPath;
    lbBtnAddDocumento: TLabel;
    pathBusca: TPath;
    edtBuscaDocumentos: TEdit;
    layTituloPlanilha: TLayout;
    lbTituloPlanilhaAlerta: TLabel;
    tmrBusca: TTimer;
    vscrollboxLinhaPlanilha: TVertScrollBox;

    procedure edtBuscaDocumentosKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure BtnFiltroClick(Sender: TObject);
    procedure edtBuscaDocumentosChange(Sender: TObject);
    procedure tmrBuscaTimer(Sender: TObject);
    procedure recBtnAddDocumentoClick(Sender: TObject);

  private
    FReq: TModuloRequest;
    FStatusFiltro: string;
    FAtivoFiltro: string;

    procedure RequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
    procedure LimparTabela;
   // procedure AtualizarVisualBotoes;
    { Private declarations }

  public
    constructor Create(AOwner: TComponent); override;
    procedure BuscarDados;
    { Public declarations }
  end;

implementation

uses
    uDesignSystem, frame.Documentos_LinhaTabelaDocumentos, modal.AdicionarDocumento;

{$R *.fmx}

constructor TFrameDocumentos.Create(AOwner: TComponent);
begin
  inherited;
  FStatusFiltro := '';
  FAtivoFiltro := 'true';
end;

procedure TFrameDocumentos.BtnFiltroClick(Sender: TObject);
var
  Rec: TRectangle;
begin
  if not (Sender is TRectangle) then Exit;
  Rec := TRectangle(Sender);

  if Rec.Tag = 0 then
  begin
    Rec.Tag := 1;
    Rec.Fill.Color := TThemeColors.Indigo100;
    Rec.Fill.Kind := TBrushKind.Solid;
    Rec.Stroke.Color := TThemeColors.Indigo600;
  end
  else
  begin
    Rec.Tag := 0;
    Rec.Fill.Kind := TBrushKind.None;
    Rec.Stroke.Color := TThemeColors.Slate300;
  end;

  BuscarDados;
end;

procedure TFrameDocumentos.BuscarDados;
var
  LStatusParam, LAtivoParam: string;
begin
  LStatusParam := '';
  if recBtnValidos.Tag = 1 then LStatusParam := LStatusParam + 'valido,';
  if recBtnAExpirar.Tag = 1 then LStatusParam := LStatusParam + 'a_expirar,';
  if recBtnExpirados.Tag = 1 then LStatusParam := LStatusParam + 'expirado,';

  if LStatusParam <> '' then
    SetLength(LStatusParam, Length(LStatusParam) - 1);

  LAtivoParam := '';
  if recBtnAtivos.Tag = 1 then LAtivoParam := LAtivoParam + 'true,';
  if recBtnDesativados.Tag = 1 then LAtivoParam := LAtivoParam + 'false,';

  if LAtivoParam <> '' then
    SetLength(LAtivoParam, Length(LAtivoParam) - 1);

  FReq := TModuloRequest.Create(nil, RequestResult);
  FReq.PesquisarDocumentos(edtBuscaDocumentos.Text, LStatusParam, LAtivoParam);
end;

procedure TFrameDocumentos.edtBuscaDocumentosChange(Sender: TObject);
begin
  tmrBusca.Enabled := False;

  if (Length(edtBuscaDocumentos.Text) >= 3) or (Length(edtBuscaDocumentos.Text) = 0) then
  begin
    tmrBusca.Enabled := True;
  end;
end;

procedure TFrameDocumentos.edtBuscaDocumentosKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    Key := 0;
    BuscarDados;
  end;
end;

procedure TFrameDocumentos.LimparTabela;
var
  i: Integer;
begin
  for i := vscrollboxLinhaPlanilha.Content.ChildrenCount - 1 downto 0 do
  begin
    if vscrollboxLinhaPlanilha.Content.Children[i] is TFrameLinhaPlanilhaDocumento then
      vscrollboxLinhaPlanilha.Content.Children[i].Free;
  end;
end;

procedure TFrameDocumentos.recBtnAddDocumentoClick(Sender: TObject);
var
  LModal: TFrameModalEnivarDocumento;
begin
  LModal := TFrameModalEnivarDocumento.Create(Self);

  LModal.Parent := Self;
  LModal.Align := TAlignLayout.Contents;
  LModal.BringToFront;
end;

procedure TFrameDocumentos.RequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
var
  LJsonArray: TJSONArray;
  LJsonObj: TJSONObject;
  i: Integer;
  LFrame: TFrameLinhaPlanilhaDocumento;
  LNome, LTipo, LValidade: string;
begin
  if AContext = ctxPesquisarDocumentos then
  begin
    LimparTabela;

    if AStatusCode = 200 then
    begin
      LJsonArray := TJSONObject.ParseJSONValue(AJsonContent) as TJSONArray;
      if Assigned(LJsonArray) then
      begin
        try
          vscrollboxLinhaPlanilha.BeginUpdate;
          try
            for i := 0 to LJsonArray.Count - 1 do
            begin
              LJsonObj := LJsonArray.Items[i] as TJSONObject;

              // Evita null pointer exceptions no parse
              LNome := LJsonObj.GetValue<string>('nomeDocumento', 'Sem Nome');
              LTipo := LJsonObj.GetValue<string>('tipoDocumento', '-');
              LValidade := LJsonObj.GetValue<string>('dataValidade', DateToStr(Date));

              // Cria o Frame
              LFrame := TFrameLinhaPlanilhaDocumento.Create(Self);
              LFrame.Name := '';
              LFrame.Parent := vscrollboxLinhaPlanilha;
              LFrame.Align := TAlignLayout.Top;
              LFrame.Margins.Bottom := 4;
              LFrame.Position.Y := 99999;

              // Popula a linha
              LFrame.CarregarDados(LNome, LTipo, 'Funcionário/Máq.', LValidade);
            end;
          finally
            vscrollboxLinhaPlanilha.EndUpdate;
            Self.Width := Self.Width + 1;

            Application.ProcessMessages;

            Self.Width := Self.Width - 1;
          end;
        finally
          LJsonArray.Free;
        end;
      end;
    end;
  end;
end;

procedure TFrameDocumentos.tmrBuscaTimer(Sender: TObject);
begin
  tmrBusca.Enabled := False;

  BuscarDados;
end;

end.
