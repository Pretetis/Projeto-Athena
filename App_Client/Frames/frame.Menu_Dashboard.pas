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
    hscrollboxTabela: THorzScrollBox;
    layTabelaCompleta: TLayout;
    procedure FrameResize(Sender: TObject);
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
    frame.Menu_LinhaTabelaAlerta, FMX.frame.PopUpToast;

{$R *.fmx}

procedure TFrameMenuDashboard.CarregarDados;
var
  LReqResumo, LReqLista: TModuloRequest;
begin
    LReqResumo := TModuloRequest.Create(Self.Root.GetObject as TForm, OnRequestResult);
    LReqResumo.ListarTotalDocumentos;

    LReqLista := TModuloRequest.Create(Self.Root.GetObject as TForm, OnRequestResult);
    LReqLista.ListarDocumentosVencer;
end;

procedure TFrameMenuDashboard.FrameResize(Sender: TObject);
const
  LARGURA_MINIMA = 1150;
begin
  // Se a tela for maior que a tabela, o "Container Mestre" e o "Container de Linhas"
  // acompanham o tamanho da tela. Sem barra horizontal.
  if Self.Width >= LARGURA_MINIMA then
  begin
    layTabelaCompleta.Width  := Self.Width - 70; // 70 é margem esq/dir
    layContainerLinhas.Width := layTabelaCompleta.Width;
  end
  else
  begin
    // Se for Mobile, trava tudo na largura mínima.
    // O hscrollboxTabela automaticamente mostrará a barra horizontal abraçando o cabeçalho!
    layTabelaCompleta.Width  := LARGURA_MINIMA;
    layContainerLinhas.Width := LARGURA_MINIMA;
  end;
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

//procedure TFrameMenuDashboard.PreencherListaAlertas(const AJsonString: string);
//var
//    LJsonValue: TJSONValue;
//    LJsonArray: TJSONArray;
//    LItem: TJSONValue;
//    LObj: TJSONObject;
//    LFrameLinha: TFrameLinhaPlanilhaAlerta;
//    LDataISO, LId: string;
//    LDataValidade: TDateTime;
//begin
//    if Trim(AJsonString).IsEmpty then
//        Exit;
//
//    while vscrollboxLinhaPlanilha.Content.ChildrenCount > 0 do
//        vscrollboxLinhaPlanilha.Content.Children[0].Free;
//
//    LJsonValue := TJSONObject.ParseJSONValue(AJsonString);
//    if not (LJsonValue is TJSONArray) then
//    begin
//        if Assigned(LJsonValue) then LJsonValue.Free;
//        Exit;
//    end;
//
//    LJsonArray := LJsonValue as TJSONArray;
//
//    vscrollboxLinhaPlanilha.BeginUpdate;
//    try
//        try
//            for LItem in LJsonArray do
//            begin
//                if not (LItem is TJSONObject) then Continue;
//                LObj := LItem as TJSONObject;
//
//                LFrameLinha := TFrameLinhaPlanilhaAlerta.Create(Self);
//                LFrameLinha.Parent := vscrollboxLinhaPlanilha;
//                LFrameLinha.Align := TAlignLayout.Top;
//                LFrameLinha.Position.Y := 99999;
//
//                LId := LObj.GetValue<string>('_id', TGUID.NewGuid.ToString.Replace('{','').Replace('}',''));
//                LFrameLinha.Name := 'FrameAlerta_' + LId;
//
//                LFrameLinha.FDocId := LId;
//                LFrameLinha.FEntidadeId := LObj.GetValue<string>('entidadeId', '');
//                LFrameLinha.FAtivo := LObj.GetValue<Boolean>('ativo', True);
//
//                LFrameLinha.FNomeDoc := LObj.GetValue<string>('nomeDocumento', 'Documento não informado');
//                LFrameLinha.FNomeEntidade := LObj.GetValue<string>('nomeFuncionario', 'Não informado');
//
//                LFrameLinha.lbInfoDoc.Text       := LFrameLinha.FNomeDoc;
//                LFrameLinha.lbInfoTipoDoc.Text   := LObj.GetValue<string>('tipoDocumento', 'Não categorizado');
//                LFrameLinha.lbFuncMaq.Text       := LFrameLinha.FNomeEntidade;
//                LFrameLinha.lbFuncaoFuncMaq.Text := LObj.GetValue<string>('funcaoFuncionario', '-');
//
//                LDataISO := LObj.GetValue<string>('dataValidade', '');
//                if not LDataISO.IsEmpty then
//                begin
//                    LDataValidade := ISO8601ToDate(LDataISO);
//                    LFrameLinha.lbInfoVencimento.Text := DateToStr(LDataValidade);
//                    LFrameLinha.TipoStatus(nil);
//                end
//                else
//                begin
//                    LFrameLinha.lbInfoVencimento.Text := 'Sem Validade';
//                end;
//            end;
//        except
//            on E: Exception do TFramePopUp.Show(Self.Root.GetObject as TForm, Er, 'Erro ao renderizar a lista: ' + E.Message);
//        end;
//    finally
//        vscrollboxLinhaPlanilha.EndUpdate;
//        LJsonArray.Free;
//    end;
//end;
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

    // CORREÇÃO 1: Limpar os filhos do layContainerLinhas, e não do ScrollBox!
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
            for LItem in LJsonArray do
            begin
                if not (LItem is TJSONObject) then Continue;
                LObj := LItem as TJSONObject;

                LFrameLinha := TFrameLinhaPlanilhaAlerta.Create(Self);

                // CORREÇÃO 2: O Parent agora é o layContainerLinhas
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

            // CORREÇÃO 3: Ajustar a altura do container para o scroll vertical funcionar.
            // 50 é a altura da sua linha (FrameLinhaPlanilhaAlerta.Height).
            // Se você tiver alguma margem/padding, talvez precise somar aqui.
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
