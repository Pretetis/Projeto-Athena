unit modal.AlterarMaquina;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Effects, FMX.Edit, FMX.Objects, FMX.Controls.Presentation,
  uRequests;

type
  TFrameModalAlterarMaquina = class(TFrame)
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
    recFundoNomeMaquina: TRectangle;
    edtNomeMaq: TEdit;
    layTipo: TLayout;
    lbTipo: TLabel;
    recTipo: TRectangle;
    edtTipo: TEdit;
    layModelo: TLayout;
    lbModelo: TLabel;
    recModelo: TRectangle;
    edtModelo: TEdit;
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
    recBtnSalvar: TRectangle;
    Path2: TPath;
    Label1: TLabel;
    recOverlay: TRectangle;
    BlurEffect1: TBlurEffect;
    layBtnsEstadoDoc: TLayout;
    lbEstadoDOc: TLabel;
    GridPanelLayout1: TGridPanelLayout;
    recBtnDesativar: TRectangle;
    lbBtnDesativarDoc: TLabel;
    pathBtnDesativarDoc: TPath;
    recBtnAtivo: TRectangle;
    lbBtnAtivo: TLabel;
    pathBtnAivo: TPath;
    procedure recDropZoneClick(Sender: TObject);
    procedure recDropZoneDragDrop(Sender: TObject; const Data: TDragObject; const Point: TPointF);
    procedure recDropZoneDragOver(Sender: TObject; const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation);
    procedure recBtnSalvarClick(Sender: TObject);
    procedure layFecharModalClick(Sender: TObject);
    procedure recBtnAtivoClick(Sender: TObject);
    procedure recBtnDesativarClick(Sender: TObject);
  private
    FIdMaquina: string;
    FAtivo: Boolean;
    FCaminhoArquivo: string;
    FOnRefresh: TProc;
    procedure ProcessarArquivo(const ACaminho: string);
    procedure AtualizarVisualBotoesEstado;
    procedure OnRequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
  public
    procedure AbrirModal(AId, ANome, ATipo, AModelo, AChapa: string; AIsAtivo: Boolean; AOnRefresh: TProc);
  end;

implementation

uses
    uDesignSystem, uMenu, FMX.frame.PopUpToast;

{$R *.fmx}

procedure TFrameModalAlterarMaquina.AbrirModal(AId, ANome, ATipo, AModelo, AChapa: string; AIsAtivo: Boolean; AOnRefresh: TProc);
begin
    FIdMaquina := AId;
    FAtivo := AIsAtivo;
    FOnRefresh := AOnRefresh;
    FCaminhoArquivo := '';

    edtNomeMaq.Text := ANome;
    edtTipo.Text := ATipo;
    edtModelo.Text := AModelo;
    edtChapa.Text := AChapa;

    fMenu.EfeitoBlur.Enabled := True;

    AtualizarVisualBotoesEstado;
end;

procedure TFrameModalAlterarMaquina.AtualizarVisualBotoesEstado;
begin
    if FAtivo then
    begin
        recBtnAtivo.Fill.Color := TThemeColors.Green100;
        recBtnAtivo.Fill.Kind := TBrushKind.Solid;
        recBtnAtivo.Stroke.Color := TThemeColors.Green400;

        recBtnDesativar.Fill.Kind := TBrushKind.None;
        recBtnDesativar.Stroke.Color := TThemeColors.Slate300;
    end
    else
    begin
        recBtnDesativar.Fill.Color := TThemeColors.Red100;
        recBtnDesativar.Fill.Kind := TBrushKind.Solid;
        recBtnDesativar.Stroke.Color := TThemeColors.Red600;

        recBtnAtivo.Fill.Kind := TBrushKind.None;
        recBtnAtivo.Stroke.Color := TThemeColors.Slate300;
    end;
end;

procedure TFrameModalAlterarMaquina.recBtnAtivoClick(Sender: TObject);
begin
    if FAtivo then Exit;
    FAtivo := True;
    AtualizarVisualBotoesEstado;
end;

procedure TFrameModalAlterarMaquina.recBtnDesativarClick(Sender: TObject);
begin
    if not FAtivo then Exit;
    FAtivo := False;
    AtualizarVisualBotoesEstado;
end;

procedure TFrameModalAlterarMaquina.layFecharModalClick(Sender: TObject);
begin
    fMenu.EfeitoBlur.Enabled := False;
    Self.Free;
end;

procedure TFrameModalAlterarMaquina.recBtnSalvarClick(Sender: TObject);
begin
    if Trim(edtNomeMaq.Text) = '' then
    begin
        TFramePopUp.Show(Self.Root.GetObject as TForm, E, 'Preencha o nome da Máquina.');
        Exit;
    end;

    with TModuloRequest.Create(Self.Root.GetObject as TForm, OnRequestResult) do
        EditarMaquina(FIdMaquina, edtNomeMaq.Text, edtTipo.Text, edtModelo.Text, edtChapa.Text, FAtivo, FCaminhoArquivo);
end;

procedure TFrameModalAlterarMaquina.OnRequestResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
begin
    if AStatusCode = 200 then
    begin
        TFramePopUp.Show(Self.Root.GetObject as TForm, S, 'Máquina atualizada com sucesso!');

        if Assigned(FOnRefresh) then
            FOnRefresh();

        fMenu.EfeitoBlur.Enabled := False;
        Self.Free;
    end
    else
    begin
        TFramePopUp.Show(Self.Root.GetObject as TForm, E, 'Erro ao atualizar: ' + AJsonContent);
    end;
end;

procedure TFrameModalAlterarMaquina.recDropZoneClick(Sender: TObject);
begin
    OpenDialog1.Filter := 'Arquivos de Imagem|*.jpg;*.jpeg;*.png';
    if OpenDialog1.Execute then
    begin
        ProcessarArquivo(OpenDialog1.FileName);
    end;
end;

procedure TFrameModalAlterarMaquina.recDropZoneDragDrop(Sender: TObject; const Data: TDragObject; const Point: TPointF);
begin
    if Length(Data.Files) > 0 then
        ProcessarArquivo(Data.Files[0]);
end;

procedure TFrameModalAlterarMaquina.recDropZoneDragOver(Sender: TObject; const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation);
var
  Extensao: string;
begin
    Operation := TDragOperation.None;
    if Length(Data.Files) > 0 then
    begin
        Extensao := LowerCase(ExtractFileExt(Data.Files[0]));
        if (Extensao = '.jpg') or (Extensao = '.jpeg') or (Extensao = '.png') then
            Operation := TDragOperation.Copy;
    end;
end;

procedure TFrameModalAlterarMaquina.ProcessarArquivo(const ACaminho: string);
begin
    FCaminhoArquivo := ACaminho;
    recDropZone.Fill.Color := $FFD4EDDA;
    lbInsideDropZone.Text := 'Nova Imagem: ' + ExtractFileName(ACaminho);
end;

end.
