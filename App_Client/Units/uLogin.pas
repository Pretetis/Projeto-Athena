unit uLogin;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts, FMX.MediaLibrary.Actions,
  System.Actions, FMX.ActnList, FMX.StdActns, FMX.Objects, FMX.Edit, FMX.Controls.Presentation, FMX.StdCtrls,
  REST.Client, REST.Authenticator.Basic, REST.Response.Adapter, system.json, REST.Types, FMX.Ani, System.IOUtils,
  FireDAC.Comp.Client, uRequests, FMX.ListBox;

type
  TfLogin = class(TForm)
    layCentral: TLayout;
    rectAcessar: TRoundRect;
    lblAcessar: TLabel;
    lblLogin: TLabel;
    imgUsuario: TImage;
    recUsuario: TRectangle;
    edtUsuario: TEdit;
    recSenha: TRectangle;
    edtSenha: TEdit;
    imgQrCode: TImage;
    layPrincipalTop: TLayout;
    lineTop: TLine;
    imgLogoEmpresa: TImage;
    lblInformacao: TLabel;
    layPrincipalBottom: TLayout;
    lineBottom: TLine;
    imgSair: TImage;
    OpenDialog: TOpenDialog;
    imgNotificacao: TImage;
    ActionList1: TActionList;
    ActCamera: TTakePhotoFromCameraAction;
    ActLibrary: TTakePhotoFromLibraryAction;
    lbSugestoes: TListBox;
    recListaUsuarios: TRectangle;
    Edit1: TEdit;
    procedure imgSairClick(Sender: TObject);
    procedure rectAcessarClick(Sender: TObject);
    procedure edtSenhaEnter(Sender: TObject);
    procedure edtSenhaExit(Sender: TObject);
    procedure edtUsuarioEnter(Sender: TObject);
    procedure edtUsuarioExit(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure edtUsuarioTyping(Sender: TObject);
  private
    FListaUsuariosCache: TStringList;

    procedure CarregarUsuario(usuario, senha: string);
    procedure VerificarLogin(Sender: TObject);
    procedure CarregarListaUsuariosDoServidor;
    procedure FiltrarUsuarios(Texto: String);
    procedure SelecionarUsuarioLista(Sender: TObject);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fLogin: TfLogin;

implementation

uses
  uMenu, uLoading,
  uTelaUtils,
  uParametros, uConnection,
  uFormConfig, FMX.frame.PopUpToast;

{$R *.fmx}

procedure TfLogin.edtSenhaEnter(Sender: TObject);
begin
    recSenha.Stroke.Color :=  $FFEF8F1C;
    recSenha.Stroke.Kind := TBrushKind.Solid;
    recSenha.Fill.Color := $FFC8F4FF;

    rectAcessar.Align := TAlignLayout.None;
    lblLogin.Margins.Top := 5;
    TAnimator.AnimateFloat(rectAcessar, 'Position.Y', 240, 0.2);
end;

procedure TfLogin.edtSenhaExit(Sender: TObject);
begin
    recSenha.Stroke.Color :=  $FF12365D;
    recSenha.Stroke.Kind := TBrushKind.Solid;
    recSenha.Fill.Color := $FFFFFFFF;

    rectAcessar.Align := TAlignLayout.Center;
end;

procedure TfLogin.edtUsuarioEnter(Sender: TObject);
begin
    recUsuario.Stroke.Color :=  $FFEF8F1C;
    recUsuario.Stroke.Kind := TBrushKind.Solid;
    recUsuario.Fill.Color := $FFC8F4FF;
end;

procedure TfLogin.edtUsuarioExit(Sender: TObject);
begin
    recUsuario.Stroke.Color :=  $FF12365D;
    recUsuario.Stroke.Kind := TBrushKind.Solid;
    recUsuario.Fill.Color := $FFFFFFFF;

    lblLogin.Margins.Top := 30;
    TAnimator.AnimateFloat(rectAcessar, 'Position.Y', 360, 0.2);

    TThread.ForceQueue(nil, procedure
    begin
        try
            if Assigned(lbSugestoes) and (not lbSugestoes.IsFocused) then
                 if Assigned(recListaUsuarios) then
                      recListaUsuarios.Visible := False;
        except
        end;
    end);
end;

procedure TfLogin.edtUsuarioTyping(Sender: TObject);
begin
    FiltrarUsuarios(edtUsuario.Text);
end;

procedure TfLogin.FiltrarUsuarios(Texto: String);
var
    S: String;
    LItem: TListBoxItem;
begin
    lbSugestoes.Items.Clear;
    recListaUsuarios.Visible := False;

    if (Trim(Texto) = '') then Exit;

    lbSugestoes.BeginUpdate;
    try
        for S in FListaUsuariosCache do
        begin
            if S.Contains(Texto.ToUpper) then
            begin
                LItem := TListBoxItem.Create(lbSugestoes);

                LItem.Text := S;

                LItem.Height := 50;

                LItem.Font.Size := 16;
                LItem.StyledSettings := LItem.StyledSettings - [TStyledSetting.Size, TStyledSetting.Style];
                LItem.StyleLookup := 'listboxitembottomdetail';
                LItem.TextSettings.VertAlign := TTextAlign.Center;
                LItem.TextSettings.HorzAlign := TTextAlign.Leading;

                LItem.Padding.Left := 10;

                LItem.OnClick := SelecionarUsuarioLista;

                lbSugestoes.AddObject(LItem);
            end;
        end;
    finally
        lbSugestoes.EndUpdate;
    end;

    if lbSugestoes.Count > 0 then
    begin
       recListaUsuarios.Visible := True;
       lbSugestoes.BringToFront;
    end;
end;

procedure TfLogin.SelecionarUsuarioLista(Sender: TObject);
var
  LItem: TListBoxItem;
begin
    if Sender is TListBoxItem then
    begin
        LItem := TListBoxItem(Sender);
        edtUsuario.Text := LItem.Text;

        edtSenha.SetFocus;

        recListaUsuarios.Visible := False;
        lbSugestoes.Items.Clear;
        edtSenha.Text := '';
    end;
end;

procedure TfLogin.FormClose(Sender: TObject; var Action: TCloseAction);
var
    ip: string;
begin
    {$IFDEF MSWINDOWS}
    if edtUsuario.Text.Trim <> '' then
        SalvarConfigForm(Self, edtUsuario.Text.Trim);
    {$ENDIF}

    if Edit1.Text <> '' then
    begin
        ip := Edit1.Text;;
    end
end;

procedure TfLogin.FormCreate(Sender: TObject);
var
    qry: TFDQuery;
begin
    uConnection.ConnectSIP;
    mProgramador := 0;

    qry := TFDQuery.Create(nil);
    try
        qry.Connection := uConnection.FDConnectionSIP;

        try
            uConnection.FDConnectionSIP.Connected := true;
        except on e:exception do
            raise Exception.Create('Erro de conexão com o banco de dados: ' + e.Message);
        end;

        imgNotificacao.visible := False;
        ConfigurarModoTela(Self);

        qry.Active := False;
        qry.Params.Clear;
        qry.SQL.Clear;
        qry.SQL.Add('SELECT * FROM USUARIO');
        qry.Active := True;

        if (not qry.IsEmpty) then
        begin
            edtUsuario.Text := qry.FieldByName('USUARIO').Value;
            edtSenha.Text := qry.FieldByName('SENHA').Value;
        end;
    finally
        qry.Free;
    end;

    // Configura o foco e carrega config
    edtUsuario.SetFocus;
    {$IFDEF MSWINDOWS}
    if edtUsuario.Text.Trim <> '' then
      CarregarConfigForm(Self, edtUsuario.Text.Trim);
    {$ENDIF}

    FListaUsuariosCache := TStringList.Create;
    recListaUsuarios.Visible := False;
    CarregarListaUsuariosDoServidor;
end;

procedure TfLogin.FormDestroy(Sender: TObject);
begin
  // uConnection.DisconectSIP;
  if Assigned(FListaUsuariosCache) then
     FreeAndNil(FListaUsuariosCache);
end;

procedure TfLogin.imgSairClick(Sender: TObject);
begin
  Close;
end;

procedure TfLogin.rectAcessarClick(Sender: TObject);
begin
    if (edtUsuario.Text.Trim() = '') or (edtSenha.Text.Trim() = '') then
    begin
        TFramePopUp.Show(fLogin, A, 'Verifique Usuário e senha.');
        Abort;
    end;

    CarregarUsuario(edtUsuario.Text.Trim(), edtSenha.Text.Trim());
end;

procedure TfLogin.CarregarUsuario(usuario: string; senha: string);
begin
    TLoading.Show(fLogin, 'Aguarde...');

    TLoading.ExecuteThread(procedure
    begin
        RESTClient := TRESTClient.Create(nil);
        RESTRequest := TRESTRequest.Create(nil);
        RESTResponse := TRESTResponse.Create(nil);

        Authenticator := THTTPBasicAuthenticator.Create(nil);
        Authenticator.Username := userName;
        Authenticator.Password := password;

        try
            if (usuario <> '') and (senha <> '') then
            begin
                RESTClient.BaseURL := endPoint + '/login/' + usuario.Trim() + '/' + senha.Trim();
            end;

            RESTClient.Authenticator := Authenticator;

            RESTRequest.Client := RESTClient;
            RESTRequest.Response := RESTResponse;
            RESTRequest.Method := rmGET;
            RESTRequest.Execute;

        except on ex:exception do
            TFramePopUp.Show(fLogin, e, 'Erro ao acessar o servidor: ' + ex.Message);
        end;
    end,
    VerificarLogin);
end;

procedure TfLogin.VerificarLogin( Sender: TObject);
var
    qry: TFDQuery;
begin
    TLoading.Hide;

    try
        if (RESTRequest.Response.StatusCode > 299) then
        begin
            TFramePopUp.Show(fLogin, E, RESTResponse.Content);
            Exit;
        end;

        if RESTRequest.Response.StatusCode  = 202 then
        begin
            TFramePopUp.Show(fLogin, A, RESTResponse.Content);
            Exit;
        end;

        if RESTRequest.Response.StatusCode  = 203 then
        begin
            TFramePopUp.Show(Self, A, RESTResponse.Content);
            Exit;
        end;

        if RESTRequest.Response.StatusCode  = 200 then
        begin

            JSONValue := TJSONObject.ParseJSONValue(RESTResponse.Content);
            if Assigned(JSONValue) and (JSONValue is TJSONArray) then
            begin
                JSONArray := TJSONArray(JSONValue);
                JSONObject := JSONArray.Items[0] as TJSONObject;

                mNomeUsuario := JSONObject.GetValue('dnome').Value;
                mUsuario := JSONObject.GetValue('dusuario').Value;
                mSenha := JSONObject.GetValue('dsenha').Value;
                mProgramador :=JSONObject.GetValue('d01progra').Value.ToInteger;


                try
                    qry := TFDQuery.Create(nil);
                    qry.Connection := uConnection.FDConnectionSIP;

                    qry.Active := False;
                    qry.Params.Clear;
                    qry.SQL.Clear;
                    qry.SQL.Add('SELECT * FROM USUARIO');
                    qry.SQL.Add('WHERE USUARIO = :USUARIO');
                    qry.ParamByName('USUARIO').Value := mUsuario;
                    qry.Active := True;

                    if (qry.IsEmpty) then
                    begin
                        qry.Active := False;
                        qry.Params.Clear;
                        qry.SQL.Clear;
                        qry.SQL.Add('DELETE FROM USUARIO');
                        qry.ExecSQL;

                        qry.Active := False;
                        qry.Params.Clear;
                        qry.SQL.Clear;
                        qry.SQL.Add('INSERT INTO USUARIO ( NOME,  USUARIO,  SENHA) ');
                        qry.SQL.Add('             VALUES (:NOME, :USUARIO, :SENHA) ');
                        qry.ParamByName('NOME').Value := mNomeUsuario;
                        qry.ParamByName('USUARIO').Value := mUsuario;
                        qry.ParamByName('SENHA').Value := mSenha;
                        qry.ExecSQL;
                    end;
                except
                    TFramePopUp.Show(fLogin, A,'Erro na Validação do Login, Tente Novamente!');
                end;

                try
                    if fMenu <> nil then
                        FreeAndNil(fMenu);
                        Application.CreateForm(TfMenu, fMenu);
                        SalvarConfigForm(Self, edtUsuario.Text.Trim);

                        fMenu.Show;

                        Application.MainForm := fMenu;
                        fLogin.Close;
                finally
                    qry.Close;
                    // uConnection.FDConnectionSIP.Close;
                end;

                JSONValue.Free;
            end
            else
            begin
                TFramePopUp.Show(fLogin, E, 'Erro ao interpretar JSON');
            end;
        end;
    finally
        Authenticator.Free;
        RESTResponse.Free;
        RESTRequest.Free;
        RESTClient.Free;
    end;
end;

procedure TfLogin.CarregarListaUsuariosDoServidor;
begin
  TModuloRequest.Create(Self, nil).ConferirUsuarios(
    procedure(AJson: TJSONArray)
    var
      I: Integer;
      LItem: TJSONObject;
      LNome: string;
    begin
        if not Assigned(AJson) then Exit;

        try
            FListaUsuariosCache.Clear;

            for I := 0 to AJson.Count - 1 do
            begin
                LItem := AJson.Items[I] as TJSONObject;
                if LItem.TryGetValue<string>('dusuario', LNome) then
                begin
                    FListaUsuariosCache.Add(LNome.ToUpper);
                end;
            end;
        except

        end;
    end
  );
end;

end.
