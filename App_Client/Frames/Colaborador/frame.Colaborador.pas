unit frame.Colaborador;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Edit, FMX.Effects, FMX.Objects, FMX.Controls.Presentation,
  System.JSON,

  uRequests, modal.ColaboradorAdicionar, FMX.ImgList, FMX.Filter.Effects;

type
  TFrameColaborador = class(TFrame)
    recFundo: TRectangle;
    layTitulo: TLayout;
    lbSubTitulo: TLabel;
    lbTitulo: TLabel;
    layBtnAddFuncionario: TLayout;
    recBtnAddFuncionario: TRectangle;
    lbBtnAddFuncionario: TLabel;
    LayDadosDocs: TLayout;
    recFiltroDados: TRectangle;
    ShadowEffect2: TShadowEffect;
    recBuscaFuncionarios: TRectangle;
    edtBuscaFuncionarios: TEdit;
    tmrBusca: TTimer;
    vsbContainerVerticalCards: TVertScrollBox;
    flowlayCardHorzFuncionarios: TFlowLayout;
    recBtnAtivos: TRectangle;
    lbBtnAtivos: TLabel;
    recBtnDesativados: TRectangle;
    lbBtnDesativados: TLabel;
    imgAdicionar: TImage;
    FillRGBEffect1: TFillRGBEffect;
    gpBusca: TGlyph;
    FillRGBEffect4: TFillRGBEffect;
    procedure recBtnAddFuncionarioClick(Sender: TObject);
    procedure FrameResize(Sender: TObject);
    procedure edtBuscaFuncionariosChangeTracking(Sender: TObject);
    procedure tmrBuscaTimer(Sender: TObject);
    procedure edtBuscaFuncionariosKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure BtnFiltroClick(Sender: TObject);
  private
    FReq: TModuloRequest;
    procedure AjustarAlturaFlowLayout;
    procedure OnRequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
    procedure BuscarDados;
  public
    constructor Create(AOwner: TComponent); override;
    procedure CarregarFuncionarios;
  end;

implementation

uses
  uMenu, card.Colaborador, uDesignSystem, uTelaUtils, uLoading;

{$R *.fmx}

constructor TFrameColaborador.Create(AOwner: TComponent);
begin
    inherited;

    // Define o estado inicial: Botão de Ativos ligado (Verde) e Desativados desligado (Cinza)
    recBtnAtivos.Tag := 1;
    recBtnAtivos.Fill.Color := TThemeColors.Green100;
    recBtnAtivos.Fill.Kind := TBrushKind.Solid;
    recBtnAtivos.Stroke.Color := TThemeColors.Green400;
    lbBtnAtivos.StyledSettings := lbBtnAtivos.StyledSettings - [TStyledSetting.FontColor];
    lbBtnAtivos.TextSettings.FontColor := TThemeColors.Green800;

    recBtnDesativados.Tag := 0;
    recBtnDesativados.Fill.Color := TThemeColors.Slate50;
    recBtnDesativados.Fill.Kind := TBrushKind.Solid;
    recBtnDesativados.Stroke.Color := TThemeColors.Slate500;
    lbBtnDesativados.StyledSettings := lbBtnDesativados.StyledSettings - [TStyledSetting.FontColor];
    lbBtnDesativados.TextSettings.FontColor := $F064748B;

    uTelaUtils.ConfigurarBotaoAnimado(recBtnAddFuncionario);
    uTelaUtils.ConfigurarBotaoAnimado(recBtnAtivos);
    uTelaUtils.ConfigurarBotaoAnimado(recBtnDesativados);
end;

procedure TFrameColaborador.BtnFiltroClick(Sender: TObject);
var
    Rec: TRectangle;

    // Funções internas para trocar as cores exatamente como no frame de Documentos
    procedure DesligarBotao(ABotao: TRectangle; ALabel: TLabel);
    begin
        ABotao.Tag := 0;
        ABotao.Fill.Color := TThemeColors.Slate50;
        ABotao.Stroke.Color := TThemeColors.Slate500;
        ALabel.StyledSettings := ALabel.StyledSettings - [TStyledSetting.FontColor];
        ALabel.TextSettings.FontColor := $F064748B;
    end;

    procedure LigarBotao(ABotao: TRectangle; ALabel: TLabel; IsAtivoBtn: Boolean);
    begin
        ABotao.Tag := 1;
        ALabel.StyledSettings := ALabel.StyledSettings - [TStyledSetting.FontColor];

        if IsAtivoBtn then
        begin
            ABotao.Fill.Color := TThemeColors.Green100;
            ABotao.Stroke.Color := TThemeColors.Green400;
            ALabel.TextSettings.FontColor := TThemeColors.Green800;
        end
        else
        begin
            ABotao.Fill.Color := TThemeColors.Slate200;
            ABotao.Stroke.Color := TThemeColors.Slate500;
            ALabel.TextSettings.FontColor := TThemeColors.Slate800;
        end;
    end;

begin
    if not (Sender is TRectangle) then Exit;
    Rec := TRectangle(Sender);

    // Regra: Não deixa desligar o botão se for o único ligado. Troca de um para o outro.
    if Rec.Tag = 1 then Exit;

    if Rec = recBtnAtivos then
    begin
        LigarBotao(recBtnAtivos, lbBtnAtivos, True);
        DesligarBotao(recBtnDesativados, lbBtnDesativados);
    end
    else if Rec = recBtnDesativados then
    begin
        LigarBotao(recBtnDesativados, lbBtnDesativados, False);
        DesligarBotao(recBtnAtivos, lbBtnAtivos);
    end;

    BuscarDados;
end;

procedure TFrameColaborador.BuscarDados;
var
  LAtivoParam: string;
  LReqFuncionario: TModuloRequest;
begin
    LAtivoParam := '';
    if recBtnAtivos.Tag = 1 then
        LAtivoParam := 'true'
    else if recBtnDesativados.Tag = 1 then
        LAtivoParam := 'false';

    TLoading.Show(Self, 'Buscando funcionários...');

    LReqFuncionario := TModuloRequest.Create(nil, OnRequestResult);
    LReqFuncionario.ListarFuncionarios(edtBuscaFuncionarios.Text, LAtivoParam);
end;

procedure TFrameColaborador.CarregarFuncionarios;
begin
    BuscarDados;
end;

procedure TFrameColaborador.edtBuscaFuncionariosChangeTracking(Sender: TObject);
begin
    tmrBusca.Enabled := False;

    if (Length(edtBuscaFuncionarios.Text) >= 3) or (Length(edtBuscaFuncionarios.Text) = 0) then
    begin
        tmrBusca.Enabled := True;
    end;
end;

procedure TFrameColaborador.edtBuscaFuncionariosKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
    if Key = vkReturn then
    begin
        Key := 0;
        BuscarDados;
    end;
end;

procedure TFrameColaborador.tmrBuscaTimer(Sender: TObject);
begin
    tmrBusca.Enabled := False;
    BuscarDados;
end;

procedure TFrameColaborador.FrameResize(Sender: TObject);
var
    LAvailableWidth: Single;
    LMinCardWidth: Single;
    LColumns: Integer;
    LNewCardWidth: Single;
    I: Integer;
begin
    LMinCardWidth := 320;
    LAvailableWidth := vsbContainerVerticalCards.Width;

    LColumns := Trunc(LAvailableWidth / LMinCardWidth);
    if LColumns < 1 then
        LColumns := 1;

    LNewCardWidth := (LAvailableWidth - (flowlayCardHorzFuncionarios.HorizontalGap * (LColumns - 1))) / LColumns;

    flowlayCardHorzFuncionarios.BeginUpdate;
    try
        for I := 0 to flowlayCardHorzFuncionarios.ControlsCount - 1 do
            flowlayCardHorzFuncionarios.Controls[I].Width := Trunc(LNewCardWidth);
    finally
        flowlayCardHorzFuncionarios.EndUpdate;
    end;

    AjustarAlturaFlowLayout;
end;

procedure TFrameColaborador.OnRequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
var
    LJsonArray: TJSONArray;
    LJsonObj: TJSONObject;
    LCard: TFrameCardFuncionario;
    I: Integer;
    LIdFuncionario: string;
begin
    if AContext <> ctxListarFuncionarios then
      Exit;

    if AStatusCode = 200 then
    begin
        LJsonArray := TJSONObject.ParseJSONValue(AJsonContent) as TJSONArray;
        if Assigned(LJsonArray) then
        begin
            try
                flowlayCardHorzFuncionarios.BeginUpdate;
                try
                    for I := flowlayCardHorzFuncionarios.ControlsCount - 1 downto 0 do
                    begin
                        flowlayCardHorzFuncionarios.Controls[I].DisposeOf;
                    end;

                    for I := 0 to LJsonArray.Count - 1 do
                    begin
                        LJsonObj := LJsonArray.Items[I] as TJSONObject;

                        LCard := TFrameCardFuncionario.Create(Self);
                        LCard.Name := 'CardFunc_' + I.ToString;

                        LCard.lbNomeFuncionario.Text := LJsonObj.GetValue<string>('nome', 'Sem Nome');
                        LCard.lbCargo.Text := LJsonObj.GetValue<string>('funcao', 'Sem Função');
                        LCard.lbChapa.Text := LJsonObj.GetValue<string>('chapa', 'S/C');

                        LCard.lbSetor.Text := LJsonObj.GetValue<string>('setor', 'Operacional');
                        LCard.FIsAtivo := LJsonObj.GetValue<Boolean>('ativo', True);
                        LCard.FOnRecarregarLista := CarregarFuncionarios;

                        LIdFuncionario := LJsonObj.GetValue<string>('_id', '');
                        if LIdFuncionario <> '' then
                        begin
                            LCard.CarregarFotoAssincrona(LIdFuncionario);
                        end;

                        LCard.Parent := flowlayCardHorzFuncionarios;
                    end;
                finally
                    flowlayCardHorzFuncionarios.EndUpdate;
                end;
                FrameResize(Self);
            finally
                LJsonArray.Free;
            end;
        end;
    end;
end;

procedure TFrameColaborador.recBtnAddFuncionarioClick(Sender: TObject);
var
    LModal: TFrameModalAdicionarFuncionario;
begin
    fMenu.EfeitoBlur.Enabled := True;
    LModal := TFrameModalAdicionarFuncionario.Create(Self);

    LModal.Parent := Application.MainForm;
    LModal.Align := TAlignLayout.Contents;
    LModal.OnSalvoComSucesso := CarregarFuncionarios;
    LModal.BringToFront;
    LModal.CarregarChapa;
end;

procedure TFrameColaborador.AjustarAlturaFlowLayout;
var
    I: Integer;
    LMaxHeight: Single;
    LControl: TControl;
begin
    LMaxHeight := 0;

    for I := 0 to flowlayCardHorzFuncionarios.ControlsCount - 1 do
    begin
        LControl := flowlayCardHorzFuncionarios.Controls[I];
        if (LControl.Position.Y + LControl.Height) > LMaxHeight then
            LMaxHeight := LControl.Position.Y + LControl.Height;
    end;

    flowlayCardHorzFuncionarios.Height := LMaxHeight + 20;
end;

end.
