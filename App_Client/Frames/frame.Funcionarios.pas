unit frame.Funcionarios;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Edit, FMX.Effects, FMX.Objects, FMX.Controls.Presentation,
  System.JSON,

  uRequests, modal.AdicionarFuncionario;

type
  TFrameFuncionarios = class(TFrame)
    recFundo: TRectangle;
    layTitulo: TLayout;
    lbSubTitulo: TLabel;
    lbTitulo: TLabel;
    layBtnAddFuncionario: TLayout;
    recBtnAddFuncionario: TRectangle;
    pathAddDocumento: TPath;
    lbBtnAddFuncionario: TLabel;
    LayDadosDocs: TLayout;
    recFiltroDados: TRectangle;
    ShadowEffect2: TShadowEffect;
    recBuscaFuncionarios: TRectangle;
    pathBusca: TPath;
    edtBuscaFuncionarios: TEdit;
    tmrBusca: TTimer;
    vsbContainerVerticalCards: TVertScrollBox;
    flowlayCardHorzFuncionarios: TFlowLayout;
    procedure recBtnAddFuncionarioClick(Sender: TObject);
    procedure FrameResize(Sender: TObject);
  private
    procedure AjustarAlturaFlowLayout;
    procedure OnRequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
  public
    procedure CarregarFuncionarios;
    { Public declarations }
  end;

implementation

uses
  uMenu, card.Funcionario;

{$R *.fmx}

procedure TFrameFuncionarios.CarregarFuncionarios;
var
    LReq: TModuloRequest;
    LForm: TForm;
begin
    if Assigned(Self.Root) and (Self.Root.GetObject is TForm) then
        LForm := TForm(Self.Root.GetObject)
    else
        LForm := nil;

    LReq := TModuloRequest.Create(LForm, OnRequestResult);
    LReq.ListarFuncionarios;
    FrameResize(Self);
end;

procedure TFrameFuncionarios.FrameResize(Sender: TObject);
var
    LAvailableWidth: Single;
    LMinCardWidth: Single;
    LColumns: Integer;
    LNewCardWidth: Single;
    I: Integer;
begin
    // 1. Defina a largura mínima que seu card deve ter para não ficar esmagado
    LMinCardWidth := 320;

    // 2. Pega a largura útil do ScrollBox
    LAvailableWidth := vsbContainerVerticalCards.Width;

    // 3. Descobre quantas colunas inteiras cabem nesse espaço
    LColumns := Trunc(LAvailableWidth / LMinCardWidth);
    if LColumns < 1 then
        LColumns := 1;

    // 4. Calcula a nova largura para os cards preencherem todo o espaço
    // Subtraímos os espaços (Gaps) entre os cards para a conta fechar perfeita
    LNewCardWidth := (LAvailableWidth - (flowlayCardHorzFuncionarios.HorizontalGap * (LColumns - 1))) / LColumns;

    // 5. Aplica a nova largura em todos os cards que já foram criados
    flowlayCardHorzFuncionarios.BeginUpdate;
    try
        for I := 0 to flowlayCardHorzFuncionarios.ControlsCount - 1 do
            flowlayCardHorzFuncionarios.Controls[I].Width := Trunc(LNewCardWidth); // Trunc evita pixels quebrados
    finally
        flowlayCardHorzFuncionarios.EndUpdate;
    end;

    // 6. Recalcula a altura do layout
    AjustarAlturaFlowLayout;
end;

procedure TFrameFuncionarios.OnRequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
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
                    while flowlayCardHorzFuncionarios.ControlsCount > 0 do
                        flowlayCardHorzFuncionarios.Controls[0].Free;

                    for I := 0 to LJsonArray.Count - 1 do
                    begin
                        LJsonObj := LJsonArray.Items[I] as TJSONObject;

                        LCard := TFrameCardFuncionario.Create(Self);
                        LCard.Name := 'CardFunc_' + I.ToString;

                        LCard.lbNomeFuncionario.Text := LJsonObj.GetValue<string>('nome', 'Sem Nome');
                        LCard.lbCargo.Text := LJsonObj.GetValue<string>('funcao', 'Sem Função');
                        LCard.lbChapa.Text := LJsonObj.GetValue<string>('chapa', 'S/C');
                        LCard.lbMatricula.Text := LCard.lbChapa.Text;

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
                AjustarAlturaFlowLayout;
            finally
                LJsonArray.Free;
            end;
        end;
    end;
end;

procedure TFrameFuncionarios.recBtnAddFuncionarioClick(Sender: TObject);
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

procedure TFrameFuncionarios.AjustarAlturaFlowLayout;
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
