unit uMenuMobile;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, IdHTTP, FMX.Effects,
  // Units do Projeto Athena
  frame.Menu_Dashboard, frame.Documentos, uRequests, uCatalogos,
  frame.Funcionarios, frame.Maquina, frame.TelaFuncionario;

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
    Layout4: TLayout;
    Layout5: TLayout;
    Layout6: TLayout;
    Layout7: TLayout;
    Layout8: TLayout;
    recFundo: TRectangle;
    scrollboxContainerFrame: TScrollBox;
    EfeitoBlur: TBlurEffect;
    cirFotoPerfil: TCircle;
    lbNomeFuncionario: TLabel;
    lbCargo: TLabel;
    lbMenu: TLabel;
    procedure MenuBtnClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
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
  uDesignSystem, uParametros;

{$R *.fmx}

{ ==============================================================================
  GERENCIAMENTO MOBILE (SPA) E BOTÃO VOLTAR
  ============================================================================== }
procedure TfMenuMobile.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  // Intercepta o botão voltar nativo do Android
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

      // Verifica se existe alguma tela aberta (layHostName visível)
      if layHostName.Visible then
      begin
        FecharTelaAtual; // Destrói o frame e esconde o host

        // Garante que o layout do menu volte a ficar visível
        layMenu.Visible := True;

        // Zera a chave para o aplicativo não fechar (voltou apenas de tela)
        Key := 0;
      end
      else
      begin
        // Se layHostName NÃO está visível, o usuário já está no Menu principal.
        // Como não estamos zerando a Key (Key := 0) aqui, o Android fará o
        // comportamento padrão, que é fechar/minimizar o aplicativo.
      end;
    end;
  end;
end;

procedure TfMenuMobile.FormShow(Sender: TObject);
begin
  IniciarCatalogos;
  CarregarDadosPerfil;

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
    layMenu.Visible := False; // Esconde o menu lateral/inferior inteiro!

    // Traz o container de telas para a frente e deixa sempre visível
    layHostName.Visible := True;
    layHostName.BringToFront;
    //MenuBtnClick(recBtnEmpresas);

    // Carrega direto a tela do funcionário
    CarregarFuncionarioIndividual;
  end;
end;

procedure TfMenuMobile.FormResize(Sender: TObject);
var
  Margem: Single;
begin
  // Calcula 20% da largura atual da tela
  Margem := Self.Width * 0.1;

  // Aplica a margem em todos os botões do menu
  Layout4.Margins.Left := Margem;
  Layout5.Margins.Left := Margem;
  Layout6.Margins.Left := Margem;
  Layout7.Margins.Left := Margem;
  Layout8.Margins.Left := Margem;

  lbMenu.Margins.Left := Self.Width * 0.1;

  layTitulo.Margins.Top := Self.Width * 0.07;
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
begin
  if not (Sender is TRectangle) then Exit;

  Rec := TRectangle(Sender);

  // Controle visual do botão ativo (cor do Theme)
  if Assigned(FBotaoAtivo) and (FBotaoAtivo <> Rec) then
    FBotaoAtivo.Fill.Kind := TBrushKind.None;

  FBotaoAtivo := Rec;
  FBotaoAtivo.Fill.Color := TThemeColors.Indigo600;
  FBotaoAtivo.Fill.Kind := TBrushKind.Solid;

  // Roteamento para as telas
  if Rec.Name = 'recBtnDashboard' then
    CarregarDashboard
  else if Rec.Name = 'recBtnDocumentos' then
    CarregarDocumentos
  else if Rec.Name = 'recBtnFuncionarios' then
    CarregarFuncionarios
  else if Rec.Name = 'recBtnMaquinas' then
    CarregarMaquinas
  else if Rec.Name = 'recBtnEmpresas' then
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
