unit uLogin;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Edit, FMX.Controls.Presentation, FMX.StdCtrls,
  REST.Client, REST.Authenticator.Basic, system.json, REST.Types, FMX.Ani,
  System.IOUtils, System.IniFiles, FMX.ListBox, uRequests, System.Actions, FMX.ActnList,
  FMX.MediaLibrary.Actions, FMX.StdActns, System.Hash, FireDAC.Comp.Client,
  FireDAC.FMXUI.Wait, FireDAC.Comp.UI, FireDAC.UI.Intf, FireDAC.Stan.Intf;

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
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
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
    procedure SalvarCredenciaisOffline(AUsuario, ASenha, ANome: string);
    function TentarLoginOffline(AUsuario, ASenha: string): Boolean;
    procedure AbrirSistemaPrincipal;
  public
  end;

var
  fLogin: TfLogin;

implementation

uses
  uMenu, uMenuMobile, uParametros, FMX.frame.PopUpToast, uConnection,
  modal.ConsentimentoLGPD;

{$R *.fmx}

procedure TfLogin.FormCreate(Sender: TObject);
begin
  ConnectATHENA;
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

procedure TfLogin.AbrirSistemaPrincipal;
begin
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
end;

//procedure TfLogin.rectAcessarClick(Sender: TObject);
//var
//    Req: TModuloRequest;
//    LUsuarioDigitado, LSenhaDigitada: string;
//begin
//    LUsuarioDigitado := Trim(edtUsuario.Text);
//    LSenhaDigitada := Trim(edtSenha.Text);
//
//    if (LUsuarioDigitado = '') or (LSenhaDigitada = '') then
//    begin
//        TFramePopUp.Show(Self, A, 'Preencha usuário e senha!');
//        Exit;
//    end;
//
//    // Req := TModuloRequest.Create(Self, nil);
//    Req := TModuloRequest.Create(Self, RetornoRequest);
//    Req.EfetuarLogin(LUsuarioDigitado, LSenhaDigitada,
//        procedure(Sucesso: Boolean; Msg: string)
//        begin
//            TThread.Queue(nil, procedure
//            var
//              Ini: TIniFile;
//            begin
//                try // <--- BLINDAGEM MÁXIMA INICIA AQUI
//                    if Sucesso then
//                    begin
//                        Ini := TIniFile.Create(TPath.Combine(TPath.GetDocumentsPath, 'athena_config.ini'));
//                        try
//                          Ini.WriteString('Credenciais', 'Usuario', LUsuarioDigitado);
//                          Ini.WriteString('Credenciais', 'Senha', LSenhaDigitada);
//                          Ini.WriteString('Perfil', 'Setor', mSetor);
//                          Ini.WriteString('Perfil', 'Funcao', mFuncao);
//                          Ini.WriteString('Perfil', 'IdFuncionario', mIdFuncionario);
//                          Ini.WriteInteger('Perfil', 'NivelAcesso', mNivelAcesso);
//                        finally
//                          Ini.Free;
//                        end;
//
//                        mNomeUsuario := LUsuarioDigitado;
//                        mUsuario := LUsuarioDigitado;
//
//                        SalvarCredenciaisOffline(LUsuarioDigitado, LSenhaDigitada, mNomeUsuario);
//
//                      {$IFDEF ANDROID}
//                        if not Assigned(fMenuMobile) then
//                          Application.CreateForm(TfMenuMobile, fMenuMobile);
//                        fMenuMobile.Show;
//                        Application.MainForm := fMenuMobile;
//                      {$ELSE}
//                        if not Assigned(fMenu) then
//                          Application.CreateForm(TfMenu, fMenu);
//                        fMenu.Show;
//                        Application.MainForm := fMenu;
//                      {$ENDIF}
//                        Self.Close;
//                    end
//                    else
//                    begin
//                        // Protegemos o acesso offline para ele não afogar a Exception
//                        try
//                            if TentarLoginOffline(LUsuarioDigitado, LSenhaDigitada) then
//                            begin
//                                {$IFDEF ANDROID}
//                                  if not Assigned(fMenuMobile) then Application.CreateForm(TfMenuMobile, fMenuMobile);
//                                  fMenuMobile.Show;
//                                  Application.MainForm := fMenuMobile;
//                                {$ELSE}
//                                  if not Assigned(fMenu) then Application.CreateForm(TfMenu, fMenu);
//                                  fMenu.Show;
//                                  Application.MainForm := fMenu;
//                                {$ENDIF}
//                                Self.Close;
//                            end
//                            else
//                            begin
//                                TFramePopUp.Show(Self, E, Msg + ' (Falha também no acesso offline)');
//                            end;
//                        except
//                            on ExOffline: Exception do
//                                ShowMessage('ERRO CRÍTICO NO BANCO OFFLINE: ' + ExOffline.Message);
//                        end;
//                    end;
//                except
//                    on ExGeral: Exception do
//                        ShowMessage('ERRO GERAL DE ROTEAMENTO: ' + ExGeral.Message);
//                end; // <--- FIM DA BLINDAGEM
//            end);
//        end
//    );
//end;
procedure TfLogin.rectAcessarClick(Sender: TObject);
var
    Req: TModuloRequest;
    LUsuarioDigitado, LSenhaDigitada: string;
begin
    LUsuarioDigitado := Trim(edtUsuario.Text);
    LSenhaDigitada := Trim(edtSenha.Text);

    if (LUsuarioDigitado = '') or (LSenhaDigitada = '') then
    begin
        TFramePopUp.Show(Self, A, 'Preencha usuário e senha!');
        Exit;
    end;

    Req := TModuloRequest.Create(Self, RetornoRequest);

    Req.EfetuarLogin(LUsuarioDigitado, LSenhaDigitada,
        procedure(Sucesso: Boolean; Msg: string; TermosAceitos: Boolean; PrimeiroAcesso: Boolean)
        begin
            TThread.Queue(nil, procedure
            var
              Ini: TIniFile;
            begin
                try
                    if Sucesso then
                    begin
                        Ini := TIniFile.Create(TPath.Combine(TPath.GetDocumentsPath, 'athena_config.ini'));
                        try
                          Ini.WriteString('Credenciais', 'Usuario', LUsuarioDigitado);
                          Ini.WriteString('Credenciais', 'Senha', LSenhaDigitada);
                          Ini.WriteString('Perfil', 'Setor', mSetor);
                          Ini.WriteString('Perfil', 'Funcao', mFuncao);
                          Ini.WriteString('Perfil', 'IdFuncionario', mIdFuncionario);
                          Ini.WriteInteger('Perfil', 'NivelAcesso', mNivelAcesso);
                        finally
                          Ini.Free;
                        end;

                        mNomeUsuario := LUsuarioDigitado;
                        mUsuario := LUsuarioDigitado;
                        mPrimeiroAcesso := PrimeiroAcesso;
                        SalvarCredenciaisOffline(LUsuarioDigitado, LSenhaDigitada, mNomeUsuario);

                        if not TermosAceitos then
                        begin
                            // IMPORTANTE: Criamos um NOVO TModuloRequest aqui, pois o "Req" já foi destruído!
                            TModuloRequest.Create(Self, RetornoRequest).BuscarTermoConsentimentoLGPD(
                              procedure(BSucesso: Boolean; BMsg, BTexto: string)
                              begin
                                if BSucesso then
                                begin
                                  TFrameModalConsentimentoLGPD.Exibir(Self, layCentral, BTexto,
                                    procedure(AceitouFoto: Boolean)
                                    begin
                                      // OUTRA NOVA INSTÂNCIA: para enviar o aceite!
                                      TModuloRequest.Create(Self, RetornoRequest).EnviarAceiteLGPD(mIdFuncionario, AceitouFoto,
                                        procedure(LgpdSucesso: Boolean; LgpdMsg: string)
                                        begin
                                          if LgpdSucesso then
                                            AbrirSistemaPrincipal
                                          else
                                            TFramePopUp.Show(Self, E, 'Erro ao gravar aceite: ' + LgpdMsg);
                                        end
                                      );
                                    end,
                                    procedure
                                    begin
                                      TFramePopUp.Show(Self, A, 'O aceite dos termos da LGPD é obrigatório para acessar o aplicativo.');
                                    end
                                  );
                                end
                                else
                                  TFramePopUp.Show(Self, E, 'Erro de comunicação ao buscar LGPD: ' + BMsg);
                              end
                            );
                        end
                        else
                        begin
                            AbrirSistemaPrincipal;
                        end;
                    end
                    else
                    begin
                        try
                            if TentarLoginOffline(LUsuarioDigitado, LSenhaDigitada) then
                                AbrirSistemaPrincipal
                            else
                                TFramePopUp.Show(Self, E, Msg + ' (Falha também no acesso offline)');
                        except
//                            on ExOffline: Exception do
//                                ShowMessage('ERRO CRÍTICO NO BANCO OFFLINE: ' + ExOffline.Message);
                        end;
                    end;
                except
                    on ExGeral: Exception do
                        ShowMessage('ERRO GERAL DE ROTEAMENTO: ' + ExGeral.Message);
                end;
            end);
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
  TThread.CreateAnonymousThread(procedure begin
    Sleep(200);
    // Sem o TThreadProc
    TThread.Synchronize(nil, procedure begin
      if Assigned(Self) and not (csDestroying in Self.ComponentState) then
      begin
        if Assigned(recListaUsuarios) then
          recListaUsuarios.Visible := False;
      end;
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

procedure TfLogin.SalvarCredenciaisOffline(AUsuario, ASenha, ANome: string);
var
  Qry: TFDQuery;
  LHashSenha: string;
begin
  if not Assigned(FDConnectionATHENA) then ConnectATHENA;

  // GERADOR DE HASH NATIVO DO DELPHI
  LHashSenha := THashSHA2.GetHashString(ASenha, THashSHA2.TSHA2Version.SHA256).ToLower;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnectionATHENA;
    Qry.ExecSQL('DELETE FROM USUARIO WHERE USUARIO = :U', [AUsuario]);
    Qry.ExecSQL('INSERT INTO USUARIO (NOME, USUARIO, SENHA) VALUES (:N, :U, :S)',
      [ANome, AUsuario, LHashSenha]);
  finally
    Qry.Free;
  end;
end;

function TfLogin.TentarLoginOffline(AUsuario, ASenha: string): Boolean;
var
  Qry: TFDQuery;
  LHashDigitado: string;
  Ini: TIniFile;
begin
  Result := False;

  if not Assigned(FDConnectionATHENA) then ConnectATHENA;

  LHashDigitado := THashSHA2.GetHashString(ASenha, THashSHA2.TSHA2Version.SHA256).ToLower;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnectionATHENA;
    // O comando UPPER protege contra erros de digitação de maiúsculas/minúsculas!
    Qry.SQL.Text := 'SELECT NOME, SENHA FROM USUARIO WHERE UPPER(USUARIO) = UPPER(:U)';
    Qry.ParamByName('U').AsString := AUsuario;
    Qry.Open;

    if not Qry.IsEmpty then
    begin
      if Qry.FieldByName('SENHA').AsString = LHashDigitado then
      begin
        mNomeUsuario := Qry.FieldByName('NOME').AsString;
        mUsuario := AUsuario;
        Ini := TIniFile.Create(TPath.Combine(TPath.GetDocumentsPath, 'athena_config.ini'));
        try
          mSetor := Ini.ReadString('Perfil', 'Setor', '');
          mFuncao := Ini.ReadString('Perfil', 'Funcao', '');
          mIdFuncionario := Ini.ReadString('Perfil', 'IdFuncionario', '');
          mNivelAcesso := Ini.ReadInteger('Perfil', 'NivelAcesso', 3); // 3 é o padrão
        finally
          Ini.Free;
        end;
        Result := True;
      end
      else
      begin
        TFramePopUp.Show(Self, A,'Senha recusada no SQLite!');
      end;
    end
    else
    begin
        TFramePopUp.Show(Self, A,'Usuário não encontrado no banco local: ' + AUsuario);
    end;
  finally
    Qry.Free;
  end;
end;
end.
