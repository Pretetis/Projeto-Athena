unit uMenuMobile;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, IdHTTP, FMX.Effects,
  // Units do Projeto Athena
  frame.Menu_Dashboard, frame.Documentos, uRequests, uCatalogos,
  frame.Funcionarios, frame.Maquina, frame.TelaFuncionario, FMX.Filter.Effects;

type
  TfMenuMobile  = class(TForm)
    layMenu: TLayout;
    layHostName: TLayout;
    recMenu: TRectangle;
    layTitulo: TLayout;
    VertScrollBox1: TVertScrollBox;
    recBtnMaquinas: TRectangle;
    lbMaquinas: TLabel;
    Path2: TPath;
    recBtnFuncionarios: TRectangle;
    lbFuncionarios: TLabel;
    recBtnDocumentos: TRectangle;
    lbDocumentos: TLabel;
    recBtnDashboard: TRectangle;
    lbDashboard: TLabel;
    Layout4: TLayout;
    Layout5: TLayout;
    Layout6: TLayout;
    Layout8: TLayout;
    recFundo: TRectangle;
    scrollboxContainerFrame: TScrollBox;
    EfeitoBlur: TBlurEffect;
    cirFotoPerfil: TCircle;
    lbNomeFuncionario: TLabel;
    lbCargo: TLabel;
    lbMenu: TLabel;
    Line1: TLine;
    GridPanelLayout1: TGridPanelLayout;
    GridPanelLayout2: TGridPanelLayout;
    Line2: TLine;
    Line3: TLine;
    Line4: TLine;
    Line5: TLine;
    Image1: TImage;
    FillRGBEffect1: TFillRGBEffect;
    Image2: TImage;
    FillRGBEffect2: TFillRGBEffect;
    Image3: TImage;
    FillRGBEffect3: TFillRGBEffect;
    imgConfig: TImage;
    FillRGBEffect4: TFillRGBEffect;
    procedure MenuBtnClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure imgConfigClick(Sender: TObject);
  private
    { Gerenciamento SPA Mobile }
    FFrameAtual: TFrame;
    FBotaoAtivo: TRectangle;
    procedure FecharTelaAtual;
    procedure ExibirHost;

    { Regras de Negócio do Athena }
    procedure IniciarCatalogos;
    procedure OnCatalogoResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
    procedure CarregarDashboard;
    procedure CarregarDocumentos;
    procedure CarregarFuncionarios;
    procedure CarregarMaquinas;
    procedure CarregarFuncionarioIndividual;
    procedure CarregarDadosPerfil;

  public
    procedure AbrirDocumentosFuncionario(const ANomeFuncionario: string);
  end;

var
  fMenuMobile: TfMenuMobile;

implementation

uses
  uDesignSystem, uParametros, modal.ConfiguracoesFuncionario;

{$R *.fmx}

{ ==============================================================================
  GERENCIAMENTO MOBILE (SPA) E BOTÃO VOLTAR
  ============================================================================== }
procedure TfMenuMobile.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
    if Key = vkHardwareBack then
    begin
        // Se NÃO for Admin/RH (Ou seja, é o nível 3 - Funcionário Comum)
        if (mNivelAcesso <> 0) and (mNivelAcesso <> 1) then
        begin
            // Ele não tem menu para voltar. Anulamos a tecla para ele não sair da tela de perfil.
            Key := 0;
        end
        else
        begin
            // Níveis 0 e 1 (Admin/RH) - Tem permissão para voltar ao menu
            if layHostName.Visible then
            begin
                FecharTelaAtual;

                layMenu.Visible := True;

                Key := 0;
            end
            else
            begin

            end;
        end;
    end;
end;

procedure TfMenuMobile.FormShow(Sender: TObject);
begin
    IniciarCatalogos;
    CarregarDadosPerfil;

    if mPrimeiroAcesso then
    begin
        TFrameModalConfiguracoesFuncionario.Exibir(Self, layHostName,
          procedure
          begin

          end
        );
    end;

    if (mNivelAcesso = 0) or (mNivelAcesso = 1) then
    begin
        // Fluxo Normal (Admin/RH)
        layHostName.Visible := False;
        layMenu.Visible := True;
        // Opcional: MenuBtnClick(recBtnDashboard);
    end
    else
    begin
        // Fluxo Restrito (Funcionário Comum)
        layMenu.Visible := False;

        // Traz o container de telas para a frente e deixa sempre visível
        layHostName.Visible := True;
        layHostName.BringToFront;

        // Carrega direto a tela do funcionário
        CarregarFuncionarioIndividual;
    end;
end;

procedure TfMenuMobile.FormResize(Sender: TObject);
var
  Margem: Single;
begin
  // Calcula 20% da largura atual da tela
  Margem := Self.Width * 0.05;

  lbMenu.Margins.Left := Self.Width * 0.1;
  layTitulo.Margins.Top := Self.Width * 0.07;

  recBtnMaquinas.Margins.Right     := Margem;
  recBtnMaquinas.Margins.Left      := Margem;
  recBtnDashboard.Margins.Right    := Margem;
  recBtnDashboard.Margins.Left     := Margem;
  recBtnDocumentos.Margins.Right   := Margem;
  recBtnDocumentos.Margins.Left    := Margem;
  recBtnFuncionarios.Margins.Right := Margem;
  recBtnFuncionarios.Margins.Left  := Margem;
end;

procedure TfMenuMobile.FecharTelaAtual;
begin
  // Destrói o frame atual usando DisposeOf (recomendado para Delphi FMX Mobile)
  if Assigned(FFrameAtual) then
  begin
    FFrameAtual.DisposeOf;
    FFrameAtual := nil;
  end;

  // Esconde o container para revelar o menu por trás
  layHostName.Visible := False;
end;

procedure TfMenuMobile.ExibirHost;
begin
  // Traz o container com a tela carregada para a frente de tudo
  layHostName.Visible := True;
  layHostName.BringToFront;
end;

{ ==============================================================================
  NAVEGAÇÃO DO MENU
  ============================================================================== }

procedure TfMenuMobile.MenuBtnClick(Sender: TObject);
var
  Rec: TRectangle;
  NomeComponente: string;
begin
  if Sender is TComponent then
    NomeComponente := TComponent(Sender).Name
  else
    Exit;

  if Sender is TRectangle then
  begin
    Rec := TRectangle(Sender);

    if Assigned(FBotaoAtivo) and (FBotaoAtivo <> Rec) then
      FBotaoAtivo.Fill.Kind := TBrushKind.None;

    FBotaoAtivo := Rec;
    FBotaoAtivo.Fill.Color := TThemeColors.Indigo600; // Substitua pelo seu método de cor
    FBotaoAtivo.Fill.Kind := TBrushKind.Solid;
  end;

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

{ ==============================================================================
  CARREGAMENTO DOS FRAMES (REGRA DE NEGÓCIO ATHENA)
  ============================================================================== }

procedure TfMenuMobile.CarregarDashboard;
var
  FrameDash: TFrameMenuDashboard;
begin
  FecharTelaAtual;

  FrameDash := TFrameMenuDashboard.Create(Self);
  FFrameAtual := FrameDash;

  FFrameAtual.Parent := scrollboxContainerFrame;
  FFrameAtual.Align := TAlignLayout.Client;

  FrameDash.CarregarDados;
  ExibirHost;
end;

procedure TfMenuMobile.CarregarDocumentos;
begin
  FecharTelaAtual;

  FFrameAtual := TFrameDocumentos.Create(Self);
  FFrameAtual.Parent := scrollboxContainerFrame;
  FFrameAtual.Align := TAlignLayout.Client;

  ExibirHost;
end;

procedure TfMenuMobile.CarregarFuncionarios;
var
  FrameFunc: TFrameFuncionarios;
begin
  FecharTelaAtual;

  FrameFunc := TFrameFuncionarios.Create(Self);
  FFrameAtual := FrameFunc;

  FFrameAtual.Parent := scrollboxContainerFrame;
  FFrameAtual.Align := TAlignLayout.Client;

  FrameFunc.CarregarFuncionarios;
  ExibirHost;
end;

procedure TfMenuMobile.CarregarMaquinas;
var
  FrameMaq: TFrameMaquinas;
begin
  FecharTelaAtual;

  FrameMaq := TFrameMaquinas.Create(Self);
  FFrameAtual := FrameMaq;

  FFrameAtual.Parent := scrollboxContainerFrame;
  FFrameAtual.Align := TAlignLayout.Client;

  FrameMaq.CarregarMaquinas;
  ExibirHost;
end;

procedure TfMenuMobile.CarregarFuncionarioIndividual;
var FrameFuncInd: TfTelaFuncionario;
begin
    FecharTelaAtual;

    FrameFuncInd := TfTelaFuncionario.Create(Self);
    FFrameAtual := FrameFuncInd;

  FFrameAtual.Parent := scrollboxContainerFrame;
  FFrameAtual.Align := TAlignLayout.Client;

  FrameFuncInd.CarregarDadosTela;
  ExibirHost;
end;

procedure TfMenuMobile.AbrirDocumentosFuncionario(const ANomeFuncionario: string);
begin
  MenuBtnClick(recBtnDocumentos);

  if Assigned(FFrameAtual) and (FFrameAtual is TFrameDocumentos) then
  begin
    TFrameDocumentos(FFrameAtual).edtBuscaDocumentos.Text := ANomeFuncionario;
    TFrameDocumentos(FFrameAtual).BuscarDados;
  end;
end;

{ ==============================================================================
  CATÁLOGOS E INTEGRAÇÕES
  ============================================================================== }

procedure TfMenuMobile.imgConfigClick(Sender: TObject);
begin
    TFrameModalConfiguracoesFuncionario.Exibir(Self, layHostName,
      procedure
      begin

      end
    );
end;

procedure TfMenuMobile.IniciarCatalogos;
begin
  with TModuloRequest.Create(Self, OnCatalogoResult) do
    CarregarCatalogoFuncionarios;
end;


procedure TfMenuMobile.OnCatalogoResult(Sender: TObject;
  const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
begin
  if AStatusCode = 200 then
  begin
    case AContext of
      ctxCarregarFuncionarios:
      begin
        PreencherCatalogo(AJsonContent, 'nome', CatFuncionariosIds, CatFuncionariosNomes);
        with TModuloRequest.Create(Self, OnCatalogoResult) do
          CarregarCatalogoMaquinas;
      end;

      ctxCarregarMaquinas:
      begin
        PreencherCatalogo(AJsonContent, 'nome', CatMaquinasIds, CatMaquinasNomes);
        with TModuloRequest.Create(Self, OnCatalogoResult) do
          CarregarCatalogoEmpresas;
      end;

      ctxCarregarEmpresas:
      begin
        PreencherCatalogo(AJsonContent, 'razaoSocial', CatEmpresasIds, CatEmpresasNomes);
      end;
    end;
  end;
end;

procedure TfMenuMobile.CarregarDadosPerfil;
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
              TThread.Synchronize(nil, procedure
            var
              ResStream: TResourceStream;
              begin
                if FindResource(HInstance, 'AVATAR_PADRAO', RT_RCDATA) <> 0 then
                begin
                  ResStream := TResourceStream.Create(HInstance, 'AVATAR_PADRAO', RT_RCDATA);
                  try
                    cirFotoPerfil.Fill.Bitmap.Bitmap.LoadFromStream(ResStream);
                    cirFotoPerfil.Fill.Kind := TBrushKind.Bitmap;
                    cirFotoPerfil.Fill.Bitmap.WrapMode := TWrapMode.TileStretch;
                  finally
                    ResStream.Free;
                  end;
                end;
              end);
          end;
        finally
          LStream.Free;
          LHttp.Free;
        end;
      end).Start;
  end;
end;

end.
