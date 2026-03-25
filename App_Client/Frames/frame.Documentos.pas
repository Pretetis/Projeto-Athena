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
    recCabecalhoEditar: TRectangle;
    lbCabecalhoEditar: TLabel;
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
    recBtnTodosStatus: TRectangle;
    lbBtnTodosStatus: TLabel;
    recBtnTodosativosDesa: TRectangle;
    lbBtnTodosativosDesa: TLabel;

    procedure edtBuscaDocumentosKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure BtnFiltroClick(Sender: TObject);
    procedure edtBuscaDocumentosChange(Sender: TObject);
    procedure tmrBuscaTimer(Sender: TObject);
    procedure recBtnAddDocumentoClick(Sender: TObject);

  private
    FReq: TModuloRequest;

    procedure RequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
    procedure LimparTabela;
    { Private declarations }

  public
    constructor Create(AOwner: TComponent); override;
    procedure BuscarDados;
    { Public declarations }
  end;

implementation

uses
    uDesignSystem, frame.Documentos_LinhaTabelaDocumentos, modal.AdicionarDocumento, uMenu;

{$R *.fmx}

constructor TFrameDocumentos.Create(AOwner: TComponent);
begin
    inherited;

    // Inicia com "Ativos" (Verde)
    recBtnAtivos.Tag := 1;
    recBtnAtivos.Fill.Color := TThemeColors.Green100;
    recBtnAtivos.Fill.Kind := TBrushKind.Solid;
    recBtnAtivos.Stroke.Color := TThemeColors.Green400;
    lbBtnAtivos.StyledSettings := lbBtnAtivos.StyledSettings - [TStyledSetting.FontColor];
    lbBtnAtivos.TextSettings.FontColor := TThemeColors.Green800;

    // Inicia com "Válidos" (Verde) e "A Expirar" (Amarelo)
    recBtnValidos.Tag := 1;
    recBtnValidos.Fill.Color := TThemeColors.Green100;
    recBtnValidos.Fill.Kind := TBrushKind.Solid;
    recBtnValidos.Stroke.Color := TThemeColors.Green400;
    lbBtnValidos.StyledSettings := lbBtnValidos.StyledSettings - [TStyledSetting.FontColor];
    lbBtnValidos.TextSettings.FontColor := TThemeColors.Green800;

    recBtnAExpirar.Tag := 1;
    recBtnAExpirar.Fill.Color := TThemeColors.Yellow100;
    recBtnAExpirar.Fill.Kind := TBrushKind.Solid;
    recBtnAExpirar.Stroke.Color := TThemeColors.Yellow500;
    lbBtnAExpirar.StyledSettings := lbBtnAExpirar.StyledSettings - [TStyledSetting.FontColor];
    lbBtnAExpirar.TextSettings.FontColor := TThemeColors.Yellow800;

    BuscarDados;
end;

procedure TFrameDocumentos.BtnFiltroClick(Sender: TObject);
var
    Rec: TRectangle;

    // Descobre qual Label pertence a qual Botão
    function GetLabel(ABotao: TRectangle): TLabel;
    begin
        if ABotao = recBtnValidos then Result := lbBtnValidos
        else if ABotao = recBtnAExpirar then Result := lbBtnAExpirar
        else if ABotao = recBtnExpirados then Result := lbBtnExpirados
        else if ABotao = recBtnAtivos then Result := lbBtnAtivos
        else if ABotao = recBtnDesativados then Result := lbBtnDesativados
        else if ABotao = recBtnTodosStatus then Result := lbBtnTodosStatus
        else if ABotao = recBtnTodosativosDesa then Result := lbBtnTodosativosDesa
        else Result := nil;
    end;

    // Função interna para desligar um botão (Cor Cinza)
    procedure DesligarBotao(ABotao: TRectangle);
    var
        L: TLabel;
    begin
        ABotao.Tag := 0;
        ABotao.Fill.Color := TThemeColors.Slate50;
        ABotao.Stroke.Color := TThemeColors.Slate500;

        L := GetLabel(ABotao);
        if Assigned(L) then
        begin
            L.StyledSettings := L.StyledSettings - [TStyledSetting.FontColor];
            L.TextSettings.FontColor := $F064748B;
        end;
    end;

    // Função interna inteligente para ligar um botão com a cor correta
    procedure LigarBotao(ABotao: TRectangle);
    var
        L: TLabel;
    begin
        ABotao.Tag := 1;
        ABotao.Fill.Kind := TBrushKind.Solid;
        L := GetLabel(ABotao);

        if Assigned(L) then
            L.StyledSettings := L.StyledSettings - [TStyledSetting.FontColor];

        // 1. Cores Validade
        if ABotao = recBtnValidos then
        begin
            ABotao.Fill.Color := TThemeColors.Green100;
            ABotao.Stroke.Color := TThemeColors.Green400;
            if Assigned(L) then L.TextSettings.FontColor := TThemeColors.Green800;
        end
        else if ABotao = recBtnAExpirar then
        begin
            ABotao.Fill.Color := TThemeColors.Yellow100;
            ABotao.Stroke.Color := TThemeColors.Yellow500;
            if Assigned(L) then L.TextSettings.FontColor := TThemeColors.Yellow800;
        end
        else if ABotao = recBtnExpirados then
        begin
            ABotao.Fill.Color := TThemeColors.Red100;
            ABotao.Stroke.Color := TThemeColors.Red500;
            if Assigned(L) then L.TextSettings.FontColor := TThemeColors.Red800;
        end

        // 2. Cores Atividade
        else if ABotao = recBtnAtivos then
        begin
            ABotao.Fill.Color := TThemeColors.Green100;
            ABotao.Stroke.Color := TThemeColors.Green400;
            if Assigned(L) then L.TextSettings.FontColor := TThemeColors.Green800;
        end
        else if ABotao = recBtnDesativados then
        begin
            ABotao.Fill.Color := TThemeColors.Slate200;
            ABotao.Stroke.Color := TThemeColors.Slate500;
            if Assigned(L) then L.TextSettings.FontColor := TThemeColors.Slate800;
        end

        // 3. Botões "Todos" (Azul/Indigo)
        else
        begin
            ABotao.Fill.Color := TThemeColors.Indigo100;
            ABotao.Stroke.Color := TThemeColors.Indigo600;
            if Assigned(L) then L.TextSettings.FontColor := TThemeColors.Indigo700;
        end;
    end;

begin
    if not (Sender is TRectangle) then Exit;
    Rec := TRectangle(Sender);

    // --- GRUPO 1: ATIVIDADE (Apenas um selecionado por vez) ---
    if (Rec = recBtnAtivos) or (Rec = recBtnDesativados) or (Rec = recBtnTodosativosDesa) then
    begin
        // Se já está ligado, ignora para não ficar vazio
        if Rec.Tag = 1 then Exit;

        LigarBotao(Rec);
        if Rec <> recBtnAtivos then DesligarBotao(recBtnAtivos);
        if Rec <> recBtnDesativados then DesligarBotao(recBtnDesativados);
        if Rec <> recBtnTodosativosDesa then DesligarBotao(recBtnTodosativosDesa);
    end

    // --- GRUPO 2: VALIDADE (Múltipla Seleção com Inteligência) ---
    else if (Rec = recBtnValidos) or (Rec = recBtnAExpirar) or (Rec = recBtnExpirados) or (Rec = recBtnTodosStatus) then
    begin
        if Rec = recBtnTodosStatus then
        begin
            // Clicou no "Todos". Só processa se estava desligado.
            if Rec.Tag = 1 then Exit;

            LigarBotao(Rec);
            DesligarBotao(recBtnValidos);
            DesligarBotao(recBtnAExpirar);
            DesligarBotao(recBtnExpirados);
        end
        else
        begin
            // Clicou em um botão do Trio (Válidos, A Expirar, Expirados)
            if Rec.Tag = 1 then
            begin
                // Se já estava ligado, ele quer desligar
                DesligarBotao(Rec);

                // Regra Anti-Vazio: Se ao desligar este, todos do trio ficaram desligados, liga o "Todos" automaticamente!
                if (recBtnValidos.Tag = 0) and (recBtnAExpirar.Tag = 0) and (recBtnExpirados.Tag = 0) then
                    LigarBotao(recBtnTodosStatus);
            end
            else
            begin
                // Estava desligado, então liga
                LigarBotao(Rec);

                // NOVA REGRA: Verifica se, ao ligar este botão, os 3 acabaram ficando ligados
                if (recBtnValidos.Tag = 1) and (recBtnAExpirar.Tag = 1) and (recBtnExpirados.Tag = 1) then
                begin
                    // Se os 3 estão ligados, limpa o trio e acende apenas o "Todos"
                    DesligarBotao(recBtnValidos);
                    DesligarBotao(recBtnAExpirar);
                    DesligarBotao(recBtnExpirados);
                    LigarBotao(recBtnTodosStatus);
                end
                else
                begin
                    // Se não formou o trio completo, apenas garante que o "Todos" fique desligado
                    DesligarBotao(recBtnTodosStatus);
                end;
            end;
        end;
    end;

    // Chama a API com a nova formação
    BuscarDados;
end;

procedure TFrameDocumentos.BuscarDados;
var
  LStatusParam, LAtivoParam: string;
begin
    // --- LÓGICA DO GRUPO VALIDADE (MÚLTIPLA SELEÇÃO) ---
    LStatusParam := '';

    // Se a flag "Todos" estiver Tag=0, quer dizer que temos que ler o Trio
    if recBtnTodosStatus.Tag = 0 then
    begin
        if recBtnValidos.Tag = 1 then LStatusParam := LStatusParam + 'valido,';
        if recBtnAExpirar.Tag = 1 then LStatusParam := LStatusParam + 'a_expirar,';
        if recBtnExpirados.Tag = 1 then LStatusParam := LStatusParam + 'expirado,';

        // Tira a última vírgula da string
        if LStatusParam <> '' then
            SetLength(LStatusParam, Length(LStatusParam) - 1);
    end;

    // --- LÓGICA DO GRUPO ATIVIDADE (ÚNICA SELEÇÃO) ---
    LAtivoParam := ''; // Por padrão, vazio atende o "TodosativosDesa"
    if recBtnAtivos.Tag = 1 then LAtivoParam := 'true'
    else if recBtnDesativados.Tag = 1 then LAtivoParam := 'false';

    // Envia a requisição
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
    fMenu.EfeitoBlur.Enabled := True;
    LModal := TFrameModalEnivarDocumento.Create(Self);

    LModal.Parent := Application.MainForm;
    LModal.Align := TAlignLayout.Contents;
    LModal.BringToFront;
end;

procedure TFrameDocumentos.RequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
var
    LJsonArray: TJSONArray;
    LJsonObj: TJSONObject;
    i: Integer;
    LFrame: TFrameLinhaPlanilhaDocumento;
    LNome, LTipo, LValidade, LTitulo: string;
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
                            LTitulo := LJsonObj.GetValue<string>('nomeDocumento', 'Sem Nome');
                            LTipo := LJsonObj.GetValue<string>('tipoDocumento', '-');
                            LValidade := LJsonObj.GetValue<string>('dataValidade', DateToStr(Date));
                            LNome := LJsonObj.GetValue<string>('nomeEntidade', 'Não informado');

                            // 1. PRIMEIRO: Cria o Frame
                            LFrame := TFrameLinhaPlanilhaDocumento.Create(Self);

                            // 2. SEGUNDO: Atribui os valores às propriedades do Frame criado
                            LFrame.FDocId := LJsonObj.GetValue<string>('_id');
                            LFrame.FEntidadeId := LJsonObj.GetValue<string>('entidadeId', '');
                            LFrame.FNomeDoc := LJsonObj.GetValue<string>('nomeDocumento', 'Sem Nome');
                            LFrame.FNomeEntidade := LJsonObj.GetValue<string>('nomeEntidade', 'Não informado');
                            LFrame.FAtivo := LJsonObj.GetValue<Boolean>('ativo', True);

                            // 3. TERCEIRO: Configurações visuais e de posicionamento
                            LFrame.Name := '';
                            LFrame.Parent := vscrollboxLinhaPlanilha;
                            LFrame.Align := TAlignLayout.Top;
                            LFrame.Margins.Bottom := 4;
                            LFrame.Position.Y := 99999;

                            LFrame.CarregarDados(LTitulo, LTipo, LNome, LValidade);
                            LFrame.TipoAtivo(LFrame);
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
