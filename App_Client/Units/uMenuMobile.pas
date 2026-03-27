unit uMenuMobile;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls,
  // Units do Projeto Athena
  frame.Menu_Dashboard, frame.Documentos, uRequests, uCatalogos,
  frame.Funcionarios, frame.Maquina, frame.TelaFuncionario;

type
  TfMenuMobile  = class(TForm)
    layMenu: TLayout;
    layHostName: TLayout;
    recMenu: TRectangle;
    Layout3: TLayout;
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
    procedure FormShow(Sender: TObject);
    procedure MenuBtnClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
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

procedure TfMenuMobile.FormShow(Sender: TObject);
var
  LSetor: string;
begin
  IniciarCatalogos;

  LSetor := UpperCase(Trim(mSetor));

  if (LSetor = 'ADMINISTRATIVO') or (LSetor = 'RH') then
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

    // Carrega direto a tela do funcionário
    CarregarFuncionarioIndividual;
  end;
end;

procedure TfMenuMobile.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
var
  LSetor: string;
begin
  // Intercepta o botão voltar nativo do Android
  if Key = vkHardwareBack then
  begin
    LSetor := UpperCase(Trim(mSetor));

    ShowMessage('Setor identificado pelo Delphi: [' + LSetor + ']');

    if (LSetor <> 'ADMINISTRATIVO') and (LSetor <> 'RH') then
    begin
      // Se for funcionário comum, ele ESTÁ TRAVADO na tela de perfil.
      // Anulamos a tecla para o app não fazer nada ao tentar voltar.
      // (Se quiser que o app minimize ao invés de travar, basta remover esta linha abaixo)
      Key := 0;
    end
    else
    begin
      // Comportamento normal para Admin/RH: fecha a tela e volta pro menu
      if layHostName.Visible then
      begin
        FecharTelaAtual;
        Key := 0; // Zera a chave para o app não fechar
      end;
    end;
  end;
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

end.
