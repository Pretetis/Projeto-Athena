unit uMenu;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Layouts, frame.Menu_Dashboard, FMX.Controls.Presentation, FMX.StdCtrls;

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
    procedure FormShow(Sender: TObject);
    procedure MenuBtnMouseEnter(Sender: TObject);
    procedure MenuBtnMouseLeave(Sender: TObject);
    procedure MenuBtnClick(Sender: TObject);

  public
    procedure CarregarDashboard;

  private
    FFrameDashboard: TFrameMenuDashboard;
    FBotaoAtivo: TRectangle;

  end;

var
  fMenu: TfMenu;

implementation

uses

  uDesignSystem;

{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}

procedure TfMenu.MenuBtnMouseEnter(Sender: TObject);
var
  Rec: TRectangle;
begin
  if Sender is TRectangle then
  begin
    Rec := TRectangle(Sender);

    // Só aplica o hover se o botão NÃO for o ativo
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

    // Só retira o hover se o botão NÃO for o ativo
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

  // Se clicou no botão que já está ativo, não precisa fazer nada
  if Rec = FBotaoAtivo then Exit;

  // 1. Limpa o botão que estava ativo ANTES (se houver algum)
  if Assigned(FBotaoAtivo) then
    FBotaoAtivo.Fill.Kind := TBrushKind.None;

  // 2. Atualiza a "memória" dizendo que este novo botão é o ativo agora
  FBotaoAtivo := Rec;

  // 3. Pinta o NOVO botão ativo
  FBotaoAtivo.Fill.Color := TThemeColors.Indigo600;
  FBotaoAtivo.Fill.Kind := TBrushKind.Solid;

  // 4. Executa a ação correspondente à tela
  if Rec.Name = 'recBtnDashboard' then
  begin
    CarregarDashboard;
  end
  else if Rec.Name = 'recBtnMaquinas' then
  begin
    // ShowMessage('Abrir Máquinas');
  end
  else if Rec.Name = 'recBtnFuncionarios' then
  begin
    // ShowMessage('Abrir Funcionários');
  end;
end;

procedure TfMenu.FormShow(Sender: TObject);
begin
  MenuBtnClick(recBtnDashboard);
end;

procedure TfMenu.CarregarDashboard;
begin
  // Cria e posiciona o frame
  if not Assigned(FFrameDashboard) then
  begin
    FFrameDashboard := TFrameMenuDashboard.Create(Self);
    FFrameDashboard.Parent := layContainer;
    FFrameDashboard.Align := TAlignLayout.Client;
  end;

  // Traz o frame para frente (útil se houver outros frames ocultos no layContainer)
  FFrameDashboard.BringToFront;

  // Manda o frame carregar os dados dele mesmo
  FFrameDashboard.CarregarDados;
end;

end.
