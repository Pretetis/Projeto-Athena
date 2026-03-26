unit modal.AlterarDocumento;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Layouts,
  FMX.Effects, FMX.DateTimeCtrls, FMX.ListBox, FMX.Edit, FMX.Objects, FMX.Controls.Presentation,
  uRequests, System.StrUtils;
type
  TFrameAlterarDocumento = class(TFrame)
    OpenDialog1: TOpenDialog;
    recFundo: TRectangle;
    layTitulo: TLayout;
    lbTitulo: TLabel;
    Line1: TLine;
    pathFecharModal: TPath;
    layOpcoes: TLayout;
    layTituloDoc: TLayout;
    lbTituloDoc: TLabel;
    recFundoTituloDoc: TRectangle;
    edtTituloDoc: TEdit;
    layTipoDoc: TLayout;
    lbTipoDoc: TLabel;
    recTIpoDoc: TRectangle;
    edtTipoDoc: TEdit;
    layFuncionario: TLayout;
    lbFuncionario: TLabel;
    recFuncionario: TRectangle;
    edtFuncionario: TEdit;
    recListaUsuarios: TRectangle;
    lbSugestoes: TListBox;
    layVencimento: TLayout;
    lbVencimento: TLabel;
    recVencimento: TRectangle;
    DateEdit1: TDateEdit;
    layDropZone: TLayout;
    lbDropZone: TLabel;
    recDropZone: TRectangle;
    lbInsideDropZone: TLabel;
    layFinalMaior: TLayout;
    recFundoCinza: TRectangle;
    recFundoCinza2: TRectangle;
    layFinal: TLayout;
    recBtnCancelarAlteracao: TRectangle;
    lbBtnCancelarAlteracao: TLabel;
    recBtnSalvar: TRectangle;
    pathBtnSalvar: TPath;
    lbBtnSalvar: TLabel;
    recOverlay: TRectangle;
    BlurEffect1: TBlurEffect;
    layBtnsEstadoDoc: TLayout;
    lbEstadoDOc: TLabel;
    recBtnDesativarDoc: TRectangle;
    GridPanelLayout1: TGridPanelLayout;
    recBtnAtivo: TRectangle;
    lbBtnDesativarDoc: TLabel;
    pathBtnDesativarDoc: TPath;
    lbBtnAtivo: TLabel;
    pathBtnAivo: TPath;
    layFecharModal: TLayout;
    procedure lbBtnCancelarAlteracaoClick(Sender: TObject);
    procedure pathFecharModalClick(Sender: TObject);
    procedure recBtnAtivoClick(Sender: TObject);
    procedure recBtnDesativarDocClick(Sender: TObject);
    procedure recBtnSalvarClick(Sender: TObject);
    procedure recDropZoneClick(Sender: TObject);
    procedure recDropZoneDragDrop(Sender: TObject; const Data: TDragObject; const Point: TPointF);
    procedure recDropZoneDragOver(Sender: TObject; const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation);
    procedure recBtnCancelarAlteracaoClick(Sender: TObject);
    procedure lbSugestoesItemClick(const Sender: TCustomListBox; const Item: TListBoxItem);
    procedure edtFuncionarioChangeTracking(Sender: TObject);

  private
    FDocId: string;
    FAtivo: Boolean;
    FEntidadeTipo: string;
    FCaminhoArquivo: string;
    FFuncionarioId: string;
    FOnRefresh: TProc;
    procedure AtualizarVisualBotoesEstado;
    procedure OnRequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
    procedure ProcessarArquivo(const ACaminho: string);
    procedure FiltrarFuncionarios(const ATexto: string);
    procedure OcultarSugestoes;
    { Private declarations }
  public
    procedure AbrirModal(ADocId, ANomeDoc, ATipoDoc, AEntidadeId, ANomeEntidade, AEntidadeTipo, AValidade: string; AIsAtivo: Boolean; AOnRefresh: TProc = nil);
    { Public declarations }
  end;

implementation

uses
  uDesignSystem, FMX.frame.PopUpToast, uParametros, uCatalogos, uMenu;

{$R *.fmx}

{ TFrameAlterarDocumento }

procedure TFrameAlterarDocumento.AbrirModal(ADocId, ANomeDoc, ATipoDoc, AEntidadeId, ANomeEntidade, AEntidadeTipo, AValidade: string; AIsAtivo: Boolean; AOnRefresh: TProc = nil);
begin
    FDocId := ADocId;
    FAtivo := AIsAtivo;
    FEntidadeTipo := AEntidadeTipo;
    FCaminhoArquivo := '';
    FFuncionarioId := AEntidadeId;
    FOnRefresh := AOnRefresh;

    OcultarSugestoes;
    fMenu.EfeitoBlur.Enabled := True;

    edtFuncionario.OnChangeTracking := nil;
    try
        edtFuncionario.Text := ANomeEntidade;
    finally
        edtFuncionario.OnChangeTracking := edtFuncionarioChangeTracking;
    end;

    edtTituloDoc.Text := ANomeDoc;
    edtTipoDoc.Text := ATipoDoc;
    edtFuncionario.Text := ANomeEntidade;

    try
        DateEdit1.Date := StrToDate(AValidade);
    except
        DateEdit1.Date := Date;
    end;

    AtualizarVisualBotoesEstado;
end;

procedure TFrameAlterarDocumento.AtualizarVisualBotoesEstado;
begin
    // --- SE ESTIVER ATIVO ---
    if FAtivo then
    begin
        // Botão Ativo (Verde)
        recBtnAtivo.Fill.Color := TThemeColors.Green100;
        recBtnAtivo.Fill.Kind := TBrushKind.Solid;
        recBtnAtivo.Stroke.Color := TThemeColors.Green400;

        // Botão Inativo (Cinza)
        recBtnDesativarDoc.Fill.Kind := TBrushKind.None;
        recBtnDesativarDoc.Stroke.Color := TThemeColors.Slate300;
    end
    // --- SE ESTIVER INATIVO ---
    else
    begin
        // Botão Inativo (Vermelho/Amarelo)
        recBtnDesativarDoc.Fill.Color := TThemeColors.Red100;
        recBtnDesativarDoc.Fill.Kind := TBrushKind.Solid;
        recBtnDesativarDoc.Stroke.Color := TThemeColors.Red600;

        // Botão Ativo (Cinza)
        recBtnAtivo.Fill.Kind := TBrushKind.None;
        recBtnAtivo.Stroke.Color := TThemeColors.Slate300;
    end;
end;

procedure TFrameAlterarDocumento.edtFuncionarioChangeTracking(Sender: TObject);
begin
  FFuncionarioId := '';
  FiltrarFuncionarios(edtFuncionario.Text);
end;

procedure TFrameAlterarDocumento.FiltrarFuncionarios(const ATexto: string);
var
    I   : Integer;
    Item: TListBoxItem;
begin
    lbSugestoes.Clear;

    if Trim(ATexto) = '' then
    begin
        OcultarSugestoes;
        Exit;
    end;

    lbSugestoes.BeginUpdate;
    try
        for I := 0 to High(CatFuncionariosNomes) do
        begin
            if ContainsText(CatFuncionariosNomes[I], ATexto) then
            begin
                Item := TListBoxItem.Create(lbSugestoes);
                Item.Parent := lbSugestoes;
                Item.Text := CatFuncionariosNomes[I];
                Item.TagString := CatFuncionariosIds[I];
                Item.Height := 50;
                Item.StyledSettings := Item.StyledSettings - [TStyledSetting.Family, TStyledSetting.Size, TStyledSetting.Style, TStyledSetting.FontColor];
                Item.TextSettings.Font.Family := 'Roboto';
                Item.TextSettings.Font.Size := 16;
                Item.TextSettings.Font.Style := [TFontStyle.fsBold];
                Item.StyleLookup := 'listboxitembottomdetail';
                Item.TextSettings.VertAlign := TTextAlign.Center;
                Item.TextSettings.HorzAlign := TTextAlign.Leading;
                Item.Padding.Left := 10;
            end;
        end;
    finally
        lbSugestoes.EndUpdate;
    end;

    recListaUsuarios.Visible := lbSugestoes.Count > 0;

    if recListaUsuarios.Visible then
        recListaUsuarios.BringToFront;
end;

procedure TFrameAlterarDocumento.OcultarSugestoes;
begin
  lbSugestoes.Clear;
  recListaUsuarios.Visible := False;
end;

procedure TFrameAlterarDocumento.lbSugestoesItemClick(const Sender: TCustomListBox; const Item: TListBoxItem);
begin
    FFuncionarioId := Item.TagString;

    edtFuncionario.OnChangeTracking := nil;
    try
        edtFuncionario.Text := Item.Text;
    finally
        edtFuncionario.OnChangeTracking := edtFuncionarioChangeTracking;
    end;

    OcultarSugestoes;
end;

procedure TFrameAlterarDocumento.lbBtnCancelarAlteracaoClick(Sender: TObject);
begin
    fMenu.EfeitoBlur.Enabled := False;
    Self.Free;
end;

procedure TFrameAlterarDocumento.recBtnAtivoClick(Sender: TObject);
begin
    if FAtivo then Exit;

    FAtivo := True;
    AtualizarVisualBotoesEstado;
end;

procedure TFrameAlterarDocumento.recBtnCancelarAlteracaoClick(Sender: TObject);
begin
    fMenu.EfeitoBlur.Enabled := False;
    Self.Free;
end;

procedure TFrameAlterarDocumento.recBtnDesativarDocClick(Sender: TObject);
begin
    if not FAtivo then Exit;

    FAtivo := False;
    AtualizarVisualBotoesEstado;
end;

procedure TFrameAlterarDocumento.recBtnSalvarClick(Sender: TObject);
begin
    if Trim(FFuncionarioId) = '' then
    begin
        TFramePopUp.Show(Self.Root.GetObject as TForm, E, 'Por favor, selecione um funcionário válido da lista de sugestões.');
        edtFuncionario.SetFocus;
        Exit;
    end;

    with TModuloRequest.Create(Self.Root.GetObject as TForm, OnRequestResult) do
        EditarDocumento(FDocId, edtTituloDoc.Text, edtTipoDoc.Text, FFuncionarioId, FEntidadeTipo, DateEdit1.Date, FAtivo, mNomeUsuario, FCaminhoArquivo);
end;

procedure TFrameAlterarDocumento.OnRequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
begin
    if AStatusCode = 200 then
    begin
        if Assigned(FOnRefresh) then
            FOnRefresh();

        if AContext = ctxEditarDocumento then
        begin
            TFramePopUp.Show(Self.Root.GetObject as TForm, S, 'Documento salvo com sucesso!');
            fMenu.EfeitoBlur.Enabled := False;
            Self.Free;
        end;
    end
    else
    begin
        TFramePopUp.Show(Self.Root.GetObject as TForm, E, 'Erro ao processar: ' + AJsonContent);
    end;
end;

procedure TFrameAlterarDocumento.ProcessarArquivo(const ACaminho: string);
var
    Extensao: string;
begin
    FCaminhoArquivo := ACaminho;
    Extensao := LowerCase(ExtractFileExt(ACaminho));

    recDropZone.Fill.Color := $FFD4EDDA; // Fica verde avisando que pegou o arquivo
    if Extensao = '.pdf' then
        lbInsideDropZone.Text := 'Novo PDF: ' + ExtractFileName(ACaminho)
    else
        lbInsideDropZone.Text := 'Nova Imagem: ' + ExtractFileName(ACaminho);
end;

procedure TFrameAlterarDocumento.recDropZoneClick(Sender: TObject);
begin
    OpenDialog1.Filter := 'Arquivos Suportados|*.pdf;*.jpg;*.jpeg;*.png';
    if OpenDialog1.Execute then
    begin
        ProcessarArquivo(OpenDialog1.FileName);
    end;
end;

procedure TFrameAlterarDocumento.recDropZoneDragDrop(Sender: TObject; const Data: TDragObject; const Point: TPointF);
begin
    if Length(Data.Files) > 0 then ProcessarArquivo(Data.Files[0]);
end;

procedure TFrameAlterarDocumento.recDropZoneDragOver(Sender: TObject; const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation);
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

procedure TFrameAlterarDocumento.pathFecharModalClick(Sender: TObject);
begin
    fMenu.EfeitoBlur.Enabled := False;
    Self.Free;
end;

end.
