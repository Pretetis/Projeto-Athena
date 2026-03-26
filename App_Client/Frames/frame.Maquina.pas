unit frame.Maquina;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Edit, FMX.Effects, FMX.Objects, FMX.Controls.Presentation,
  System.JSON,
  uRequests, modal.AdicionarMaquina;

type
  TFrameMaquinas = class(TFrame)
    recFundo: TRectangle;
    layTitulo: TLayout;
    lbSubTitulo: TLabel;
    lbTitulo: TLabel;
    layBtnAddMaquina: TLayout;
    recBtnAddMaquina: TRectangle;
    pathAddDocumento: TPath;
    lbBtnAddFuncionario: TLabel;
    LayDadosMaquinas: TLayout;
    recFiltroDados: TRectangle;
    ShadowEffect2: TShadowEffect;
    recBuscaMaquinas: TRectangle;
    pathBusca: TPath;
    edtBuscaMaquina: TEdit;
    tmrBusca: TTimer;
    recBtnAtivos: TRectangle;
    lbBtnAtivos: TLabel;
    recBtnDesativados: TRectangle;
    lbBtnDesativados: TLabel;
    vsbContainerVerticalCards: TVertScrollBox;
    flowlayCardHorzMaquina: TFlowLayout;
    procedure FrameResize(Sender: TObject);
    procedure edtBuscaMaquinaChangeTracking(Sender: TObject);
    procedure tmrBuscaTimer(Sender: TObject);
    procedure edtBuscaMaquinaKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure BtnFiltroClick(Sender: TObject);
    procedure recBtnAddMaquinaClick(Sender: TObject);
  private
    FReq: TModuloRequest;
    procedure AjustarAlturaFlowLayout;
    procedure OnRequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
    procedure BuscarDados;
  public
    constructor Create(AOwner: TComponent); override;
    procedure CarregarMaquinas;
  end;

implementation

uses
  uMenu, card.Maquina, uDesignSystem;

{$R *.fmx}

constructor TFrameMaquinas.Create(AOwner: TComponent);
begin
    inherited;
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
end;

procedure TFrameMaquinas.BtnFiltroClick(Sender: TObject);
var
    Rec: TRectangle;

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

procedure TFrameMaquinas.BuscarDados;
var
  LAtivoParam: string;
begin
    LAtivoParam := '';
    if recBtnAtivos.Tag = 1 then
        LAtivoParam := 'true'
    else if recBtnDesativados.Tag = 1 then
        LAtivoParam := 'false';

    FReq := TModuloRequest.Create(nil, OnRequestResult);
    FReq.ListarMaquinas(edtBuscaMaquina.Text, LAtivoParam);
end;

procedure TFrameMaquinas.CarregarMaquinas;
begin
    BuscarDados;
end;

procedure TFrameMaquinas.edtBuscaMaquinaChangeTracking(Sender: TObject);
begin
    tmrBusca.Enabled := False;
    if (Length(edtBuscaMaquina.Text) >= 3) or (Length(edtBuscaMaquina.Text) = 0) then
        tmrBusca.Enabled := True;
end;

procedure TFrameMaquinas.edtBuscaMaquinaKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
    if Key = vkReturn then
    begin
        Key := 0;
        BuscarDados;
    end;
end;

procedure TFrameMaquinas.tmrBuscaTimer(Sender: TObject);
begin
    tmrBusca.Enabled := False;
    BuscarDados;
end;

procedure TFrameMaquinas.FrameResize(Sender: TObject);
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
    if LColumns < 1 then LColumns := 1;

    LNewCardWidth := (LAvailableWidth - (flowlayCardHorzMaquina.HorizontalGap * (LColumns - 1))) / LColumns;

    flowlayCardHorzMaquina.BeginUpdate;
    try
        for I := 0 to flowlayCardHorzMaquina.ControlsCount - 1 do
            flowlayCardHorzMaquina.Controls[I].Width := Trunc(LNewCardWidth);
    finally
        flowlayCardHorzMaquina.EndUpdate;
    end;

    AjustarAlturaFlowLayout;
end;

procedure TFrameMaquinas.AjustarAlturaFlowLayout;
var
    I: Integer;
    LMaxHeight: Single;
    LControl: TControl;
begin
    LMaxHeight := 0;
    for I := 0 to flowlayCardHorzMaquina.ControlsCount - 1 do
    begin
        LControl := flowlayCardHorzMaquina.Controls[I];
        if (LControl.Position.Y + LControl.Height) > LMaxHeight then
            LMaxHeight := LControl.Position.Y + LControl.Height;
    end;
    flowlayCardHorzMaquina.Height := LMaxHeight + 20;
end;

procedure TFrameMaquinas.OnRequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
var
    LJsonArray: TJSONArray;
    LJsonObj: TJSONObject;
    LCard: TFrameCardMaquina;
    I: Integer;
    LIdMaquina: string;
begin
    if AContext <> ctxListarMaquinas then Exit;

    if AStatusCode = 200 then
    begin
        LJsonArray := TJSONObject.ParseJSONValue(AJsonContent) as TJSONArray;
        if Assigned(LJsonArray) then
        begin
            try
                flowlayCardHorzMaquina.BeginUpdate;
                try
                    while flowlayCardHorzMaquina.ControlsCount > 0 do
                        flowlayCardHorzMaquina.Controls[0].Free;

                    for I := 0 to LJsonArray.Count - 1 do
                    begin
                        LJsonObj := LJsonArray.Items[I] as TJSONObject;

                        LCard := TFrameCardMaquina.Create(Self);
                        LCard.Name := 'CardMaq_' + I.ToString;

                        LCard.lbNomeMaquina.Text := LJsonObj.GetValue<string>('nome', 'Sem Nome');
                        LCard.lbTipo.Text := LJsonObj.GetValue<string>('tipo', 'Sem Função');
                        LCard.lbChapa.Text := LJsonObj.GetValue<string>('chapa', 'S/C');
                        LCard.lbModelo.Text := LJsonObj.GetValue<string>('modelo', 'Não Declarado');
                        LCard.FIsAtivo := LJsonObj.GetValue<Boolean>('ativo', True);
                        LCard.FOnRecarregarLista := CarregarMaquinas;

                        LIdMaquina := LJsonObj.GetValue<string>('_id', '');
                        if LIdMaquina <> '' then
                        begin
                            LCard.CarregarFotoAssincrona(LIdMaquina);
                        end;

                        LCard.Parent := flowlayCardHorzMaquina;
                    end;
                finally
                    flowlayCardHorzMaquina.EndUpdate;
                end;
                FrameResize(Self);
            finally
                LJsonArray.Free;
            end;
        end;
    end;
end;

procedure TFrameMaquinas.recBtnAddMaquinaClick(Sender: TObject);
var
    LModal: TFrameModalAdicionarMaquina;
begin
    fMenu.EfeitoBlur.Enabled := True;
    LModal := TFrameModalAdicionarMaquina.Create(Self);
    LModal.Parent := Application.MainForm;
    LModal.Align := TAlignLayout.Contents;

    LModal.OnSalvoComSucesso := CarregarMaquinas;

    LModal.BringToFront;
    LModal.CarregarChapa;
end;

end.
