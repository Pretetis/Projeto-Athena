unit uMenu;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Effects,
  frame.Menu_Dashboard, frame.Documentos, uRequests, uCatalogos,

  frame.Funcionarios;

type
  TfMenu = class(TForm)
    layMenu: TLayout;
    recMenu: TRectangle;
    layContainer: TLayout;
    ScrollBox1: TScrollBox;
    VertScrollBox1: TVertScrollBox;
    Layout1: TLayout;
    recBtnMaquinas: TRectangle;
    lbMaquinas: TLabel;
    recBtnFuncionarios: TRectangle;
    pathFuncionarios: TPath;
    lbFuncionarios: TLabel;
    recBtnEmpresas: TRectangle;
    pathEmpresas: TPath;
    lbEmpresas: TLabel;
    recBtnDocumentos: TRectangle;
    pathDocumentos: TPath;
    lbDocumentos: TLabel;
    recBtnDashboard: TRectangle;
    pathDashboard: TPath;
    lbDashboard: TLabel;
    Path2: TPath;
    layPrincipal: TLayout;
    EfeitoBlur: TBlurEffect;
    procedure FormShow(Sender: TObject);
    procedure MenuBtnMouseEnter(Sender: TObject);
    procedure MenuBtnMouseLeave(Sender: TObject);
    procedure MenuBtnClick(Sender: TObject);

  public
    procedure CarregarDashboard;
    procedure CarregarDocumentos;
    procedure AbrirDocumentosFuncionario(const ANomeFuncionario: string);

  private
    FFrameDashboard: TFrameMenuDashboard;
    FFrameDocumentos: TFrameDocumentos;
    FFrameFuncionarios: TFrameFuncionarios;
    FBotaoAtivo: TRectangle;
    procedure FecharTelasAbertas;
    procedure IniciarCatalogos;

    procedure OnCatalogoResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
    procedure CarregarFuncionarios;
  end;

var
  fMenu: TfMenu;

implementation

uses

  uDesignSystem;

{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}

procedure TfMenu.IniciarCatalogos;
begin
    with TModuloRequest.Create(Self, OnCatalogoResult) do
        CarregarCatalogoFuncionarios;
end;

procedure TfMenu.OnCatalogoResult(Sender: TObject;
                                  const AJsonContent: string;
                                  AStatusCode: Integer;
                                  AContext: TContextoRequest);
begin
    if AStatusCode = 200 then
    begin
        case AContext of
            ctxCarregarFuncionarios:
            begin
                PreencherCatalogo(AJsonContent, 'nome',
                                  CatFuncionariosIds, CatFuncionariosNomes);
                // Dispara o próximo da cadeia
                with TModuloRequest.Create(Self, OnCatalogoResult) do
                  CarregarCatalogoMaquinas;
            end;

            ctxCarregarMaquinas:
            begin
                PreencherCatalogo(AJsonContent, 'nome',
                                  CatMaquinasIds, CatMaquinasNomes);
                // Dispara o próximo da cadeia
                with TModuloRequest.Create(Self, OnCatalogoResult) do
                  CarregarCatalogoEmpresas;
            end;

            ctxCarregarEmpresas:
            begin
                PreencherCatalogo(AJsonContent, 'razaoSocial',
                                  CatEmpresasIds, CatEmpresasNomes);
                // Cadeia concluída — todos os catálogos estão prontos
            end;
        end;
    end;
end;

procedure TfMenu.FecharTelasAbertas;
begin
    if Assigned(FFrameDashboard) then
        FreeAndNil(FFrameDashboard);

    if Assigned(FFrameDocumentos) then
        FreeAndNil(FFrameDocumentos);

    if Assigned(FFrameFuncionarios) then
        FreeAndNil(FFrameFuncionarios);
end;

procedure TfMenu.MenuBtnMouseEnter(Sender: TObject);
var
    Rec: TRectangle;
begin
    if Sender is TRectangle then
    begin
        Rec := TRectangle(Sender);

        if Rec <> FBotaoAtivo then
        begin
            Rec.Fill.Color := TThemeColors.Slate800;
            Rec.Fill.Kind := TBrushKind.Solid;
        end;
    end;
end;

procedure TfMenu.MenuBtnMouseLeave(Sender: TObject);
var
  Rec: TRectangle;
begin
    if Sender is TRectangle then
    begin
        Rec := TRectangle(Sender);

        if Rec <> FBotaoAtivo then
        begin
            Rec.Fill.Kind := TBrushKind.None;
        end;
    end;
end;

procedure TfMenu.MenuBtnClick(Sender: TObject);
var
  Rec: TRectangle;
begin
    if not (Sender is TRectangle) then Exit;

    Rec := TRectangle(Sender);

    if Rec = FBotaoAtivo then Exit;

    if Assigned(FBotaoAtivo) then
        FBotaoAtivo.Fill.Kind := TBrushKind.None;

    FBotaoAtivo := Rec;

    FBotaoAtivo.Fill.Color := TThemeColors.Indigo600;
    FBotaoAtivo.Fill.Kind := TBrushKind.Solid;

    if Rec.Name = 'recBtnDashboard' then
    begin
        CarregarDashboard;
    end
    else if Rec.Name = 'recBtnDocumentos' then
    begin
        CarregarDocumentos;
        // ShowMessage('Abrir Máquinas');
    end
    else if Rec.Name = 'recBtnFuncionarios' then
    begin
        CarregarFuncionarios;
    end;
end;

procedure TfMenu.FormShow(Sender: TObject);
begin
    MenuBtnClick(recBtnDashboard);
    IniciarCatalogos;
end;

procedure TfMenu.CarregarDashboard;
begin
    FecharTelasAbertas;

    FFrameDashboard := TFrameMenuDashboard.Create(Self);
    FFrameDashboard.Parent := layContainer;
    FFrameDashboard.Align := TAlignLayout.Client;

    FFrameDashboard.CarregarDados;
end;

procedure TfMenu.CarregarDocumentos;
begin
    FecharTelasAbertas;

    FFrameDocumentos := TFrameDocumentos.Create(Self);
    FFrameDocumentos.Parent := layContainer;
    FFrameDocumentos.Align := TAlignLayout.Client;
end;

procedure TfMenu.CarregarFuncionarios;
begin
    FecharTelasAbertas;

    FFrameFuncionarios := TFrameFuncionarios.Create(Self);
    FFrameFuncionarios.Parent := layContainer;
    FFrameFuncionarios.Align := TAlignLayout.Client;

    FFrameFuncionarios.CarregarFuncionarios;
end;

procedure TfMenu.AbrirDocumentosFuncionario(const ANomeFuncionario: string);
begin
  // 1. Simula o clique no menu de Documentos (Isso muda a cor do botão e chama o CarregarDocumentos)
  MenuBtnClick(recBtnDocumentos);

  // 2. Verifica se a frame foi instanciada com sucesso
  if Assigned(FFrameDocumentos) then
  begin
    // 3. Preenche o Edit com o nome do funcionário
    FFrameDocumentos.edtBuscaDocumentos.Text := ANomeFuncionario;

    // 4. Força a busca imediata ignorando o timer
    FFrameDocumentos.BuscarDados;
  end;
end;

end.
