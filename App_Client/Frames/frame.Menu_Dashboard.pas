unit frame.Menu_Dashboard;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Objects, FMX.Effects, System.JSON,
  System.DateUtils, uRequests;

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
    recCorValido: TRectangle;
    recQntdValido: TRectangle;
    Path1: TPath;
    recDocumentosExpirados: TRectangle;
    recCorExpirado: TRectangle;
    layIconeExpirado: TLayout;
    cirIconeExpirado: TCircle;
    pathExpirado: TPath;
    recQntdExpirado: TRectangle;
    lbTituloExpirado: TLabel;
    lbInfoExpirado: TLabel;
    shadowVermelho: TShadowEffect;
    recDocumentosExpirando: TRectangle;
    recCorExpirando: TRectangle;
    layIconeExpirando: TLayout;
    cirExpirando: TCircle;
    pathExpirando: TPath;
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
    vscrollboxLinhaPlanilha: TVertScrollBox;
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
    frame.Menu_LinhaTabelaAlerta;

{$R *.fmx}

procedure TFrameMenuDashboard.CarregarDados;
var
  LReqResumo, LReqLista: TModuloRequest;
begin
  // 1. Pede o resumo dos totais
  LReqResumo := TModuloRequest.Create(Self.Root.GetObject as TForm, OnRequestResult);
  LReqResumo.ListarTotalDocumentos;

  // 2. Pede a lista da tabela
  LReqLista := TModuloRequest.Create(Self.Root.GetObject as TForm, OnRequestResult);
  LReqLista.ListarDocumentosVencer;
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
    // Lida com erros (pode usar um Toast ou ShowMessage)
    ShowMessage(Format('Erro ao buscar dados. Código: %d', [AStatusCode]));
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
    // Lê os dados do novo JSON: { "total": 6, "vencendoEm30Dias": 3, "expirados": 1 }
    // Usa o TryGetValue para não quebrar caso a API mude as chaves no futuro

    // Supondo que lbInfoValido mostre os válidos (Total - Vencendo - Expirados)
    // Se a regra de negócio for diferente, ajuste o cálculo.
    // Usando GetValue<Integer> se tivermos certeza que as chaves sempre vêm.
    // Caso contrário, use TryGetValue. Vou usar TryGetValue para ser seguro.

    if not LJsonObj.TryGetValue<Integer>('total', LTotal) then LTotal := 0;
    if not LJsonObj.TryGetValue<Integer>('vencendoEm30Dias', LVencendo) then LVencendo := 0;
    if not LJsonObj.TryGetValue<Integer>('expirados', LExpirados) then LExpirados := 0;

    // Atualiza os labels
    // Se você tiver um label de "Total", pode colocar aqui.
    // Como você só tem expirando, expirado e "Validos", fiz uma matemática simples:

    lbInfoValido.Text     := IntToStr(LTotal - LExpirados);
    lbInfoExpirando.Text  := IntToStr(LVencendo);
    lbInfoExpirado.Text   := IntToStr(LExpirados);

  finally
    LJsonObj.Free;
  end;
end;

procedure TFrameMenuDashboard.PreencherListaAlertas(const AJsonString: string);
var
  LJsonArray: TJSONArray;
  LItem: TJSONValue;
  LFrameLinha: TFrameLinhaPlanilhaAlerta;
  LDataISO, LId: string;
  LDataValidade: TDateTime;

  // Função auxiliar interna para buscar dados com segurança
  function GetSafeString(AObj: TJSONValue; const AKey: string; const ADefault: string = ''): string;
  var
    LVal: string;
  begin
    // TryGetValue não trava se a chave não existir ou for nula
    if AObj.TryGetValue<string>(AKey, LVal) then
      Result := LVal
    else
      Result := ADefault;
  end;

begin
  if AJsonString.Trim.IsEmpty then
    Exit;

  while vscrollboxLinhaPlanilha.Content.ChildrenCount > 0 do
    vscrollboxLinhaPlanilha.Content.Children[0].Free;

  LJsonArray := TJSONObject.ParseJSONValue(AJsonString) as TJSONArray;

  if not Assigned(LJsonArray) then
    Exit;

  vscrollboxLinhaPlanilha.BeginUpdate;
  try
    try
      for LItem in LJsonArray do
      begin
        LFrameLinha := TFrameLinhaPlanilhaAlerta.Create(vscrollboxLinhaPlanilha);
        LFrameLinha.Parent := vscrollboxLinhaPlanilha;
        LFrameLinha.Align := TAlignLayout.Top;
        LFrameLinha.Position.Y := 99999;

        // Pega o ID com segurança. Se não vier, gera um provisório para não quebrar o Name do componente
        LId := GetSafeString(LItem, '_id', TGUID.NewGuid.ToString.Replace('{','').Replace('}',''));
        LFrameLinha.Name := 'FrameAlerta_' + LId;

        // --- PREENCHIMENTO SEGURO DOS DADOS ---
        // Se a chave não existir, ele vai usar o valor padrão que passamos no 3º parâmetro
        LFrameLinha.lbInfoDoc.Text       := GetSafeString(LItem, 'nomeDocumento', 'Documento não informado');
        LFrameLinha.lbInfoTipoDoc.Text   := GetSafeString(LItem, 'tipoDocumento', 'Não categorizado');
        LFrameLinha.lbFuncMaq.Text       := GetSafeString(LItem, 'nomeFuncionario', 'Não informado');
        LFrameLinha.lbFuncaoFuncMaq.Text := GetSafeString(LItem, 'funcaoFuncionario', '-'); // Padrão: '-'

        // --- TRATAMENTO SEGURO DA DATA ---
        LDataISO := GetSafeString(LItem, 'dataValidade');

        if not LDataISO.IsEmpty then
        begin
          LDataValidade := ISO8601ToDate(LDataISO);
          LFrameLinha.lbInfoVencimento.Text := DateToStr(LDataValidade);
          LFrameLinha.TipoStatus(nil);
        end
        else
        begin
          LFrameLinha.lbInfoVencimento.Text := 'Sem Validade';
          // Como não tem data, ele não vai chamar o TipoStatus.
          // O visual ficará com as cores padrão que você desenhou no frame.
        end;

      end;
    except on E: Exception do
      ShowMessage('Erro ao renderizar a lista: ' + E.Message);
    end;
  finally
    vscrollboxLinhaPlanilha.EndUpdate;
    LJsonArray.Free;
  end;
end;

end.
