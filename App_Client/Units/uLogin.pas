unit uLogin;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Edit, FMX.Controls.Presentation, FMX.StdCtrls,
  REST.Client, REST.Authenticator.Basic, system.json, REST.Types, FMX.Ani,
  System.IOUtils, System.IniFiles, FMX.ListBox, uRequests, System.Actions, FMX.ActnList, FMX.MediaLibrary.Actions, FMX.StdActns;

type
  TfLogin = class(TForm)
    layCentral: TLayout;
    rectAcessar: TRoundRect;
    lblAcessar: TLabel;
    lblLogin: TLabel;
    recUsuario: TRectangle;
    edtUsuario: TEdit;
    recSenha: TRectangle;
    edtSenha: TEdit;
    lbSugestoes: TListBox;
    recListaUsuarios: TRectangle;
    procedure rectAcessarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure edtUsuarioTyping(Sender: TObject);
    procedure edtUsuarioExit(Sender: TObject);
  private
    FListaUsuariosCache: TStringList;
    procedure InicializarDados;
    procedure FiltrarUsuarios(Texto: String);
    procedure SelecionarUsuarioLista(Sender: TObject);
    procedure CarregarListaUsuariosDoServidor;
    procedure RetornoRequest(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
  public
  end;

var
  fLogin: TfLogin;

implementation

uses
  uMenu, uMenuMobile, uParametros, FMX.frame.PopUpToast;

{$R *.fmx}

procedure TfLogin.FormCreate(Sender: TObject);
begin
  FListaUsuariosCache := TStringList.Create;
  recListaUsuarios.Visible := False;

  TThread.ForceQueue(nil, procedure
  begin
    InicializarDados;
  end);
end;

procedure TfLogin.InicializarDados;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(TPath.Combine(TPath.GetDocumentsPath, 'athena_config.ini'));
  try
    edtUsuario.Text := Ini.ReadString('Credenciais', 'Usuario', '');
    edtSenha.Text := Ini.ReadString('Credenciais', 'Senha', '');
  finally
    Ini.Free;
  end;

  CarregarListaUsuariosDoServidor;
end;


procedure TfLogin.rectAcessarClick(Sender: TObject);
var
  Req: TModuloRequest;
begin
  if (Trim(edtUsuario.Text) = '') or (Trim(edtSenha.Text) = '') then
  begin
    ShowMessage('Preencha usuário e senha!');
    Exit;
  end;

  Req := TModuloRequest.Create(Self, nil);
  Req.EfetuarLogin(edtUsuario.Text, edtSenha.Text,
      procedure(Sucesso: Boolean; Msg: string)
      var
        Ini: TIniFile;
      begin
          if Sucesso then
          begin
              // 1. Salva localmente para os próximos acessos
              Ini := TIniFile.Create(TPath.Combine(TPath.GetDocumentsPath, 'athena_config.ini'));
              try
                Ini.WriteString('Credenciais', 'Usuario', Trim(edtUsuario.Text));
                Ini.WriteString('Credenciais', 'Senha', Trim(edtSenha.Text));
              finally
                Ini.Free;
              end;

              // 2. AQUI: Atualiza as variáveis globais dos parâmetros!
              mNomeUsuario := Trim(edtUsuario.Text);
              mUsuario := Trim(edtUsuario.Text); // Substitui a Shallan pelo usuário real

              // 3. Redireciona para o Menu
              {$IFDEF ANDROID}
              if not Assigned(fMenuMobile) then
                Application.CreateForm(TfMenuMobile, fMenuMobile);
              fMenuMobile.Show;
              Application.MainForm := fMenuMobile;
            {$ELSE}
              if not Assigned(fMenu) then
                Application.CreateForm(TfMenu, fMenu);
              fMenu.Show;
              Application.MainForm := fMenu;
            {$ENDIF}
            Self.Close;
          end
          else
          begin
            TFramePopUp.Show(Self, E, Msg); // Usa seu popup amigável de erro
          end;
      end
  );
end;

procedure TfLogin.FiltrarUsuarios(Texto: String);
var S: String; LItem: TListBoxItem;
begin
  lbSugestoes.Items.Clear;
  if (Trim(Texto) = '') then
  begin
    recListaUsuarios.Visible := False;
    Exit;
  end;

  lbSugestoes.BeginUpdate;
  try
    for S in FListaUsuariosCache do
      if S.Contains(Texto.ToUpper) then
      begin
        LItem := TListBoxItem.Create(lbSugestoes);
        LItem.Text := S;
        LItem.OnClick := SelecionarUsuarioLista;
        lbSugestoes.AddObject(LItem);
      end;
  finally
    lbSugestoes.EndUpdate;
  end;
  recListaUsuarios.Visible := lbSugestoes.Count > 0;
end;

procedure TfLogin.SelecionarUsuarioLista(Sender: TObject);
begin
  edtUsuario.Text := TListBoxItem(Sender).Text;
  recListaUsuarios.Visible := False;
  edtSenha.SetFocus;
end;

procedure TfLogin.edtUsuarioTyping(Sender: TObject);
begin
  FiltrarUsuarios(edtUsuario.Text);
end;

procedure TfLogin.edtUsuarioExit(Sender: TObject);
begin
  // Esconde a lista após um pequeno delay para permitir o clique
  TThread.CreateAnonymousThread(procedure begin
    Sleep(200);
    TThread.Synchronize(nil, procedure begin
      recListaUsuarios.Visible := False;
    end);
  end).Start;
end;

procedure TfLogin.CarregarListaUsuariosDoServidor;
begin
  // Passamos o RetornoRequest no Create e chamamos o Listar com apenas as 2 strings
  TModuloRequest.Create(Self, RetornoRequest).ListarFuncionarios('', 'true');
end;

procedure TfLogin.RetornoRequest(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
var
  LJsonArray: TJSONArray;
  I: Integer;
begin
  // Verifica se o retorno veio da requisição certa e se deu tudo OK
  if (AContext = ctxListarFuncionarios) and (AStatusCode = 200) and (AJsonContent <> '') then
  begin
    LJsonArray := TJSONObject.ParseJSONValue(AJsonContent) as TJSONArray;
    if Assigned(LJsonArray) then
    begin
      try
        FListaUsuariosCache.Clear;
        for I := 0 to LJsonArray.Count - 1 do
        begin
          // Pega o nome do funcionário e joga no cache de sugestões
          FListaUsuariosCache.Add(LJsonArray.Items[I].GetValue<string>('nome').ToUpper);
        end;
      finally
        LJsonArray.Free;
      end;
    end;
  end;
end;

procedure TfLogin.FormDestroy(Sender: TObject);
begin
  FListaUsuariosCache.Free;
end;

end.
