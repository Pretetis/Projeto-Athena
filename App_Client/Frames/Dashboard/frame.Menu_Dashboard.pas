unit frame.Menu_Dashboard;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Objects, FMX.Effects, System.JSON,
  System.DateUtils, uRequests, FMX.Filter.Effects;

type
  TFrameMenuDashboard = class(TFrame)
    recFundo: TRectangle;
    layTitulo: TLayout;
    lbSubTitulo: TLabel;
    lbTitulo: TLabel;
    LayDadosDocs: TLayout;
    gplDashboard: TGridPanelLayout;
    recDocsValidos: TRectangle;
    lbTituloValido: TLabel;
    lbInfoValido: TLabel;
    layIconeValido: TLayout;
    cirIconeValido: TCircle;
    ShadowAzul: TShadowEffect;
    recQntdValido: TRectangle;
    Path1: TPath;
    recDocumentosExpirados: TRectangle;
    layIconeExpirado: TLayout;
    cirIconeExpirado: TCircle;
    recQntdExpirado: TRectangle;
    lbTituloExpirado: TLabel;
    lbInfoExpirado: TLabel;
    shadowVermelho: TShadowEffect;
    recDocumentosExpirando: TRectangle;
    layIconeExpirando: TLayout;
    cirExpirando: TCircle;
    recQntdExpirando: TRectangle;
    lbTituloExpirando: TLabel;
    lbInfoExpirando: TLabel;
    shadowAmarelo: TShadowEffect;
    recPlanilhaAlertas: TRectangle;
    ShadowEffect1: TShadowEffect;
    layTituloPlanilhaAlerta: TLayout;
    lbTituloPlanilhaAlerta: TLabel;
    layCabecalhoPlanilhaAlerta: TLayout;
    gplCabecalhoPlanilhaAlerta: TGridPanelLayout;
    recCabecalhoPlanilha: TRectangle;
    recCabecalhoStatus: TRectangle;
    lbStatus: TLabel;
    lbSubTituloPlanilhaAlerta: TLabel;
    recCabecalhoDoc: TRectangle;
    lbDoc: TLabel;
    recFuncMaq: TRectangle;
    lbFuncMaq: TLabel;
    recVencimento: TRectangle;
    lbVencimento: TLabel;
    recVisualizar: TRectangle;
    lbVisualizar: TLabel;
    recEditar: TRectangle;
    lbEditar: TLabel;
    vscrollboxLinhaPlanilha: TScrollBox;
    layContainerLinhas: TLayout;
    layContainerCabecalho: TLayout;
    Image1: TImage;
    Image2: TImage;
    FillRGBEffect2: TFillRGBEffect;
    Image3: TImage;
    FillRGBEffect3: TFillRGBEffect;
    procedure FrameResize(Sender: TObject);
    procedure vscrollboxLinhaPlanilhaViewportPositionChange(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF; const ContentSizeChanged: Boolean);
  private
    procedure OnRequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
    { Private declarations }
  public
    procedure PreencherListaAlertas(const AJsonString: string);
    procedure PreencherResumoStatus(const AJsonString: string);
    procedure CarregarDados;
    { Public declarations }
  end;

implementation

uses
    frame.Menu_LinhaTabelaAlerta, FMX.frame.PopUpToast, uLoading;

{$R *.fmx}


procedure TFrameMenuDashboard.CarregarDados;
var
  LReqResumo, LReqLista: TModuloRequest;
begin
    TLoading.Show(Self, 'Carregando informações...');

    LReqResumo := TModuloRequest.Create(nil, OnRequestResult);
    LReqResumo.ListarTotalDocumentos;

    LReqLista := TModuloRequest.Create(nil, OnRequestResult);
    LReqLista.ListarDocumentosVencer;

end;

procedure TFrameMenuDashboard.FrameResize(Sender: TObject);
const
  LARGURA_MINIMA = 1150;
begin
  if Self.Width >= LARGURA_MINIMA then
  begin
    layCabecalhoPlanilhaAlerta.Width := Self.Width - 70;
    layContainerLinhas.Width         := layCabecalhoPlanilhaAlerta.Width;
  end
  else
  begin
    layCabecalhoPlanilhaAlerta.Width := LARGURA_MINIMA;
    layContainerLinhas.Width         := LARGURA_MINIMA;
  end;

  {$IFDEF ANDROID}
  lbInfoValido.Margins.Left    := recQntdValido.Width    * 0.10;
  lbInfoExpirado.Margins.Left  := recQntdExpirado.Width  * 0.10;
  lbInfoExpirando.Margins.Left := recQntdExpirando.Width * 0.10;
  {$ELSEIF defined(MSWINDOWS)}
  lbInfoValido.Margins.Left    := recQntdValido.Width    * 0.20;
  lbInfoExpirado.Margins.Left  := recQntdExpirado.Width  * 0.20;
  lbInfoExpirando.Margins.Left := recQntdExpirando.Width * 0.20;
  {$ENDIF}

end;

procedure TFrameMenuDashboard.OnRequestResult(Sender: TObject; const AJsonContent: string;
  AStatusCode: Integer; AContext: TContextoRequest);
begin
    if AStatusCode = 200 then
    begin
        case AContext of
            ctxTotalDocumentos:  PreencherResumoStatus(AJsonContent);
            ctxDocumentosVencer: PreencherListaAlertas(AJsonContent);
        end;
    end
    else
    begin
        TFramePopUp.Show(Self.Root.GetObject as TForm, E, 'Erro ao buscar dados');
    end;
end;

procedure TFrameMenuDashboard.PreencherResumoStatus(const AJsonString: string);
var
  LJsonObj: TJSONObject;
  LTotal, LVencendo, LExpirados: Integer;
begin
    if AJsonString.Trim.IsEmpty then Exit;

    LJsonObj := TJSONObject.ParseJSONValue(AJsonString) as TJSONObject;
    if not Assigned(LJsonObj) then Exit;

    try
        if not LJsonObj.TryGetValue<Integer>('total', LTotal) then LTotal := 0;
        if not LJsonObj.TryGetValue<Integer>('vencendoEm30Dias', LVencendo) then LVencendo := 0;
        if not LJsonObj.TryGetValue<Integer>('expirados', LExpirados) then LExpirados := 0;

        lbInfoValido.Text     := IntToStr(LTotal - LExpirados);
        lbInfoExpirando.Text  := IntToStr(LVencendo);
        lbInfoExpirado.Text   := IntToStr(LExpirados);

    finally
        LJsonObj.Free;
    end;
end;


procedure TFrameMenuDashboard.vscrollboxLinhaPlanilhaViewportPositionChange(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF; const ContentSizeChanged: Boolean);
begin
    layCabecalhoPlanilhaAlerta.Position.X := -NewViewportPosition.X;
end;

procedure TFrameMenuDashboard.PreencherListaAlertas(const AJsonString: string);
var
    LJsonValue: TJSONValue;
    LJsonArray: TJSONArray;
    LItem: TJSONValue;
    LObj: TJSONObject;
    LFrameLinha: TFrameLinhaPlanilhaAlerta;
    LDataISO, LId: string;
    LDataValidade: TDateTime;
begin
    if Trim(AJsonString).IsEmpty then
        Exit;

    while layContainerLinhas.ChildrenCount > 0 do
        layContainerLinhas.Children[0].Free;

    LJsonValue := TJSONObject.ParseJSONValue(AJsonString);
    if not (LJsonValue is TJSONArray) then
    begin
        if Assigned(LJsonValue) then LJsonValue.Free;
        Exit;
    end;

    LJsonArray := LJsonValue as TJSONArray;

    vscrollboxLinhaPlanilha.BeginUpdate;
    try
        try
            try
                for LItem in LJsonArray do
                begin
                    if not (LItem is TJSONObject) then Continue;
                    LObj := LItem as TJSONObject;

                    LFrameLinha := TFrameLinhaPlanilhaAlerta.Create(Self);

                    LFrameLinha.Parent := layContainerLinhas;
                    LFrameLinha.Align := TAlignLayout.Top;
                    LFrameLinha.Position.Y := 99999;

                    LId := LObj.GetValue<string>('_id', TGUID.NewGuid.ToString.Replace('{','').Replace('}',''));
                    LFrameLinha.Name := 'FrameAlerta_' + LId;

                    LFrameLinha.FDocId := LId;
                    LFrameLinha.FEntidadeId := LObj.GetValue<string>('entidadeId', '');
                    LFrameLinha.FAtivo := LObj.GetValue<Boolean>('ativo', True);

                    LFrameLinha.FNomeDoc := LObj.GetValue<string>('nomeDocumento', 'Documento não informado');
                    LFrameLinha.FNomeEntidade := LObj.GetValue<string>('nomeFuncionario', 'Não informado');

                    LFrameLinha.lbInfoDoc.Text       := LFrameLinha.FNomeDoc;
                    LFrameLinha.lbInfoTipoDoc.Text   := LObj.GetValue<string>('tipoDocumento', 'Não categorizado');
                    LFrameLinha.lbFuncMaq.Text       := LFrameLinha.FNomeEntidade;
                    LFrameLinha.lbFuncaoFuncMaq.Text := LObj.GetValue<string>('funcaoFuncionario', '-');

                    LDataISO := LObj.GetValue<string>('dataValidade', '');
                    if not LDataISO.IsEmpty then
                    begin
                        LDataValidade := ISO8601ToDate(LDataISO);
                        LFrameLinha.lbInfoVencimento.Text := DateToStr(LDataValidade);
                        LFrameLinha.TipoStatus(nil);
                    end
                    else
                    begin
                        LFrameLinha.lbInfoVencimento.Text := 'Sem Validade';
                    end;
                end;
            finally
                layContainerLinhas.RecalcSize;
                Self.Width := Self.Width - 1;
                Self.Width := Self.Width + 1;
            end;

            layContainerLinhas.Height := LJsonArray.Count * 50;

        except
            on E: Exception do TFramePopUp.Show(Self.Root.GetObject as TForm, Er, 'Erro ao renderizar a lista: ' + E.Message);
        end;
    finally
        vscrollboxLinhaPlanilha.EndUpdate;
        LJsonArray.Free;
    end;
end;

end.
