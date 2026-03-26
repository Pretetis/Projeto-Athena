unit modal.AlterarFuncionario;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Effects, FMX.Edit, FMX.Objects, FMX.Controls.Presentation,

  uRequests;

type
  TFrameAlterarFuncionario = class(TFrame)
    OpenDialog1: TOpenDialog;
    recFundo: TRectangle;
    layTitulo: TLayout;
    lbTitulo: TLabel;
    Line1: TLine;
    layFecharModal: TLayout;
    pathFecharModal: TPath;
    layOpcoes: TLayout;
    layFuncionario: TLayout;
    lbNomeFuncionario: TLabel;
    recFundoNomeFunc: TRectangle;
    edtNomeFunc: TEdit;
    layFuncao: TLayout;
    lbFuncao: TLabel;
    recFuncao: TRectangle;
    edtFuncao: TEdit;
    laySetor: TLayout;
    lbSetor: TLabel;
    recSetor: TRectangle;
    edtSetor: TEdit;
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
    Rectangle3: TRectangle;
    Path2: TPath;
    Label1: TLabel;
    recOverlay: TRectangle;
    BlurEffect1: TBlurEffect;
    layBtnsEstadoFunc: TLayout;
    lbEstadoFunc: TLabel;
    GridPanelLayout1: TGridPanelLayout;
    recBtnDesativarFunc: TRectangle;
    lbBtnDesativarDoc: TLabel;
    pathBtnDesativarDoc: TPath;
    recBtnAtivo: TRectangle;
    lbBtnAtivo: TLabel;
    pathBtnAivo: TPath;
    procedure FecharModalClick(Sender: TObject);
    procedure recBtnAtivoClick(Sender: TObject);
    procedure recBtnDesativarFuncClick(Sender: TObject);
    procedure recDropZoneClick(Sender: TObject);
    procedure layFecharModalClick(Sender: TObject);
    procedure Rectangle3Click(Sender: TObject);
  private
    FIdFuncionario: string;
    FAtivo: Boolean;
    FCaminhoArquivo: string;
    FOnRefresh: TProc;

    procedure AtualizarVisualBotoesEstado;
    procedure ProcessarArquivo(const ACaminho: string);
    procedure OnRequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
    { Private declarations }
  public
    procedure AbrirModal(AId, ANome, AFuncao, ASetor, AChapa: string; AIsAtivo: Boolean; AOnRefresh: TProc);
    { Public declarations }
  end;

implementation

uses
  uDesignSystem, uMenu, FMX.frame.PopUpToast;

{$R *.fmx}

procedure TFrameAlterarFuncionario.AbrirModal(AId, ANome, AFuncao, ASetor, AChapa: string; AIsAtivo: Boolean; AOnRefresh: TProc);
begin
    FIdFuncionario := AId;
    FAtivo := AIsAtivo;
    FOnRefresh := AOnRefresh;
    FCaminhoArquivo := '';

    edtNomeFunc.Text := ANome;
    edtFuncao.Text := AFuncao;
    edtSetor.Text := ASetor;
    edtChapa.Text := AChapa;

    fMenu.EfeitoBlur.Enabled := True;

    AtualizarVisualBotoesEstado;
end;

procedure TFrameAlterarFuncionario.AtualizarVisualBotoesEstado;
begin
    if FAtivo then
    begin
        recBtnAtivo.Fill.Color := TThemeColors.Green100;
        recBtnAtivo.Fill.Kind := TBrushKind.Solid;
        recBtnAtivo.Stroke.Color := TThemeColors.Green400;

        recBtnDesativarFunc.Fill.Kind := TBrushKind.None;
        recBtnDesativarFunc.Stroke.Color := TThemeColors.Slate300;
    end
    else
    begin
        recBtnDesativarFunc.Fill.Color := TThemeColors.Red100;
        recBtnDesativarFunc.Fill.Kind := TBrushKind.Solid;
        recBtnDesativarFunc.Stroke.Color := TThemeColors.Red600;

        recBtnAtivo.Fill.Kind := TBrushKind.None;
        recBtnAtivo.Stroke.Color := TThemeColors.Slate300;
    end;
end;

procedure TFrameAlterarFuncionario.recBtnAtivoClick(Sender: TObject);
begin
    if FAtivo then Exit;
    FAtivo := True;
    AtualizarVisualBotoesEstado;
end;

procedure TFrameAlterarFuncionario.recBtnDesativarFuncClick(Sender: TObject);
begin
    if not FAtivo then Exit;
    FAtivo := False;
    AtualizarVisualBotoesEstado;
end;

procedure TFrameAlterarFuncionario.FecharModalClick(Sender: TObject);
begin
    fMenu.EfeitoBlur.Enabled := False;
    Self.Free;
end;

procedure TFrameAlterarFuncionario.layFecharModalClick(Sender: TObject);
begin
    fMenu.EfeitoBlur.Enabled := False;
    Self.Free;
end;

procedure TFrameAlterarFuncionario.ProcessarArquivo(const ACaminho: string);
begin
    FCaminhoArquivo := ACaminho;
    recDropZone.Fill.Color := TThemeColors.Green400;
    lbInsideDropZone.Text := 'Nova Imagem: ' + ExtractFileName(ACaminho);
end;

procedure TFrameAlterarFuncionario.recDropZoneClick(Sender: TObject);
begin
    OpenDialog1.Filter := 'Arquivos de Imagem|*.jpg;*.jpeg;*.png';
    if OpenDialog1.Execute then
        ProcessarArquivo(OpenDialog1.FileName);
end;

procedure TFrameAlterarFuncionario.Rectangle3Click(Sender: TObject);
begin
    if Trim(edtNomeFunc.Text) = '' then
    begin
        TFramePopUp.Show(Self.Root.GetObject as TForm, E, 'O nome é obrigatório!');
        Exit;
    end;

    with TModuloRequest.Create(Self.Root.GetObject as TForm, OnRequestResult) do
        EditarFuncionario(FIdFuncionario, edtNomeFunc.Text, edtFuncao.Text, edtSetor.Text, edtChapa.Text, FAtivo, FCaminhoArquivo);
end;

procedure TFrameAlterarFuncionario.OnRequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
begin
    if AStatusCode = 200 then
    begin
        TFramePopUp.Show(Self.Root.GetObject as TForm, S, 'Funcionário atualizado com sucesso!');

        if Assigned(FOnRefresh) then
          FOnRefresh();

        fMenu.EfeitoBlur.Enabled := False;
        Self.Free;
    end
    else
    begin
        TFramePopUp.Show(Self.Root.GetObject as TForm, E, 'Erro ao salvar: ' + AJsonContent);
    end;
end;

end.
