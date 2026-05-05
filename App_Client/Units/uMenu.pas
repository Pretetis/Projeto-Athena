unit uMenu;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Effects,
  frame.Menu_Dashboard, frame.Documentos, uRequests, uCatalogos, IdHTTP,

  frame.Funcionarios, frame.Maquina, frame.TelaFuncionario;

type
  TfMenu = class(TForm)
    layMenu: TLayout;
    recMenu: TRectangle;
    layContainer: TLayout;
    ScrollBox1: TScrollBox;
    VertScrollBox1: TVertScrollBox;
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
    layTitulo: TLayout;
    cirFotoPerfil: TCircle;
    lbNomeFuncionario: TLabel;
    lbCargo: TLabel;
    Line1: TLine;
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
    FFrameMaquinas: TFrameMaquinas;
    FFrameFuncionario: TfTelaFuncionario;
    FBotaoAtivo: TRectangle;
    procedure FecharTelasAbertas;
    procedure IniciarCatalogos;

    procedure OnCatalogoResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
    procedure CarregarFuncionarios;
    procedure CarregarMaquinas;
    procedure CarregarFuncionarioIndividual;
    procedure CarregarDadosPerfil;
  end;

var
  fMenu: TfMenu;

implementation

uses

  uDesignSystem, uParametros, modal.ConfiguracoesFuncionario;

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
                with TModuloRequest.Create(Self, OnCatalogoResult) do
                    CarregarCatalogoMaquinas;
            end;

            ctxCarregarMaquinas:
            begin
                PreencherCatalogo(AJsonContent, 'nome',
                                  CatMaquinasIds, CatMaquinasNomes);
                with TModuloRequest.Create(Self, OnCatalogoResult) do
                    CarregarCatalogoEmpresas;
            end;

            ctxCarregarEmpresas:
            begin
                PreencherCatalogo(AJsonContent, 'razaoSocial',
                                  CatEmpresasIds, CatEmpresasNomes);
            end;
        end;
    end;
end;

procedure TfMenu.FecharTelasAbertas;
begin
    if Assigned(FFrameDashboard) then
        FFrameDashboard.Visible := False;

    if Assigned(FFrameDocumentos) then
        FFrameDocumentos.Visible := False;

    if Assigned(FFrameFuncionarios) then
        FFrameFuncionarios.Visible := False;

    if Assigned(FFrameMaquinas) then
        FFrameMaquinas.Visible := False;

    if Assigned(FFrameFuncionario) then
        FFrameFuncionario.Visible := False;
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
  NomeComponente: string;
begin
  // 1. Descobrimos o nome do componente clicado de forma segura
  if Sender is TComponent then
    NomeComponente := TComponent(Sender).Name
  else
    Exit; // Se não for um componente válido, aborta

  // 2. Regra visual (SÓ acontece se quem chamou foi um TRectangle)
  if Sender is TRectangle then
  begin
    Rec := TRectangle(Sender);

    if Assigned(FBotaoAtivo) and (FBotaoAtivo <> Rec) then
      FBotaoAtivo.Fill.Kind := TBrushKind.None;

    FBotaoAtivo := Rec;
    FBotaoAtivo.Fill.Color := TThemeColors.Indigo600; // Substitua pelo seu método de cor
    FBotaoAtivo.Fill.Kind := TBrushKind.Solid;
  end;

  // 3. Roteamento para as telas (Funciona para Rectangle ou Layout)
  if NomeComponente = 'recBtnDashboard' then
    CarregarDashboard
  else if NomeComponente = 'recBtnDocumentos' then
    CarregarDocumentos
  else if NomeComponente = 'recBtnFuncionarios' then
    CarregarFuncionarios
  else if NomeComponente = 'recBtnMaquinas' then
    CarregarMaquinas
  else if NomeComponente = 'layTitulo' then
    CarregarFuncionarioIndividual;
end;

procedure TfMenu.FormShow(Sender: TObject);
begin
  IniciarCatalogos;
  CarregarDadosPerfil;

  if mPrimeiroAcesso then
  begin
    TFrameModalConfiguracoesFuncionario.Exibir(Self, layPrincipal,
      procedure
      begin

      end
    );
  end;

  if (mNivelAcesso = 0) or (mNivelAcesso = 1) then
  begin
    // Fluxo Normal - Tem acesso a tudo
    MenuBtnClick(recBtnDashboard);
  end
  else
  begin
    // Fluxo Restrito (Funcionário Comum)
    layMenu.Visible := False; // Esconde o menu lateral/inferior inteiro!

    // Traz o container de telas para a frente e deixa sempre visível
    layPrincipal.Visible := True;
    layPrincipal.BringToFront;
    //MenuBtnClick(recBtnEmpresas);

    // Carrega direto a tela do funcionário
    CarregarFuncionarioIndividual;

  end;
end;

procedure TfMenu.CarregarDashboard;
begin
    FecharTelasAbertas;

    // Só cria o Frame se ele ainda não existir na memória
    if not Assigned(FFrameDashboard) then
    begin
        FFrameDashboard := TFrameMenuDashboard.Create(Self);
        FFrameDashboard.Parent := layContainer;
        FFrameDashboard.Align := TAlignLayout.Client;
    end;

    FFrameDashboard.Visible := True;
    FFrameDashboard.BringToFront;
    FFrameDashboard.CarregarDados;
end;

procedure TfMenu.CarregarDocumentos;
begin
    FecharTelasAbertas;

    if not Assigned(FFrameDocumentos) then
    begin
        FFrameDocumentos := TFrameDocumentos.Create(Self);
        FFrameDocumentos.Parent := layContainer;
        FFrameDocumentos.Align := TAlignLayout.Client;
    end;

    FFrameDocumentos.Visible := True;
    FFrameDocumentos.BringToFront;
end;

procedure TfMenu.CarregarFuncionarios;
begin
    FecharTelasAbertas;

    if not Assigned(FFrameFuncionarios) then
    begin
        FFrameFuncionarios := TFrameFuncionarios.Create(Self);
        FFrameFuncionarios.Parent := layContainer;
        FFrameFuncionarios.Align := TAlignLayout.Client;
    end;

    FFrameFuncionarios.Visible := True;
    FFrameFuncionarios.BringToFront;
    FFrameFuncionarios.CarregarFuncionarios;
end;

procedure TfMenu.CarregarMaquinas;
begin
    FecharTelasAbertas;

    if not Assigned(FFrameMaquinas) then
    begin
        FFrameMaquinas := TFrameMaquinas.Create(Self);
        FFrameMaquinas.Parent := layContainer;
        FFrameMaquinas.Align := TAlignLayout.Client;
    end;

    FFrameMaquinas.Visible := True;
    FFrameMaquinas.BringToFront;
    FFrameMaquinas.CarregarMaquinas;
end;

procedure TfMenu.CarregarFuncionarioIndividual;
begin
    FecharTelasAbertas;

    if not Assigned(FFrameFuncionario) then
    begin
        FFrameFuncionario := TfTelaFuncionario.Create(Self);
        FFrameFuncionario.Parent := layContainer;
        FFrameFuncionario.Align := TAlignLayout.Client;
    end;

    FFrameFuncionario.Visible := True;
    FFrameFuncionario.BringToFront;
    FFrameFuncionario.CarregarDadosTela;
end;

procedure TfMenu.AbrirDocumentosFuncionario(const ANomeFuncionario: string);
begin
    MenuBtnClick(recBtnDocumentos);

    if Assigned(FFrameDocumentos) then
    begin
        FFrameDocumentos.edtBuscaDocumentos.Text := ANomeFuncionario;
        FFrameDocumentos.BuscarDados;
    end;
end;

procedure TfMenu.CarregarDadosPerfil;
begin
  // 1. Preenche os textos
  lbNomeFuncionario.Text := mNomeUsuario;
  lbCargo.Text := mFuncao; // Ou pode usar mSetor se preferir

  // 2. Busca a foto em uma Thread separada (para não travar a tela)
  if Trim(mIdFuncionario) <> '' then
  begin
    TThread.CreateAnonymousThread(
      procedure
      var
        LHttp: TIdHTTP;
        LStream: TMemoryStream;
      begin
        LHttp := TIdHTTP.Create(nil);
        LStream := TMemoryStream.Create;
        try
          LHttp.Request.BasicAuthentication := True;
          LHttp.Request.Username := UserName;
          LHttp.Request.Password := Password;

          try
            // Faz o GET na rota da sua API que retorna a imagem
            LHttp.Get(EndPoint + '/funcionarios/' + mIdFuncionario + '/foto', LStream);
            LStream.Position := 0;

            // Atualiza a interface gráfica sincronizando com a thread principal
            TThread.Synchronize(nil, procedure
            begin
              cirFotoPerfil.Fill.Bitmap.Bitmap.LoadFromStream(LStream);
              cirFotoPerfil.Fill.Kind := TBrushKind.Bitmap;
              cirFotoPerfil.Fill.Bitmap.WrapMode := TWrapMode.TileStretch;
            end);
          except
            // Se der erro (ex: usuário não cadastrou foto), falha em silêncio e mantém o círculo vazio/padrão
          end;
        finally
          LStream.Free;
          LHttp.Free;
        end;
      end).Start;
  end;
end;


end.
