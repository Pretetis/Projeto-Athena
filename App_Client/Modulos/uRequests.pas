unit uRequests;

interface

uses
  System.SysUtils, System.Classes, System.JSON, FMX.Forms, System.DateUtils,
  REST.Client, REST.Types, REST.Authenticator.Basic, System.IOUtils;

type
  TContextoRequest = (ctxCarregarMaquina, ctxCarregarUtilidades, ctxEnviarParametros,
                      ctxListarCortes, ctxHistorico, ctxCarregarAlarmes, ctxEditarAlarme,
                      ctxSolicitarAlarme, ctxConferirUsuarios);

  TOnRequestResult = procedure(Sender: TObject;
                               const AJsonContent: string;
                               AStatusCode: Integer;
                               AContext: TContextoRequest) of object;

  TModuloRequest = class
  private
    FParentForm: TForm;
    FOnResult: TOnRequestResult;
    FContexto: TContextoRequest;
    FRESTClient: TRESTClient;
    FRESTRequest: TRESTRequest;
    FRESTResponse: TRESTResponse;
    FAuthenticator: THTTPBasicAuthenticator;
    FFieldId: string;
    FFieldNome: string;
    FUltimoMaqIdSolicitado: Integer;
    FCallbackAlarmes: TProc<TJSONArray>;

    procedure ResetarComponentesRest;
    procedure TratarRetornoJSON;
    procedure CallbackFimDaThread(Sender: TObject);

  public
    property UltimoMaqIdSolicitado: Integer read FUltimoMaqIdSolicitado;

    constructor Create(AParentForm: TForm; AOnResult: TOnRequestResult);
    destructor Destroy; override;

    procedure CarregarHistoricoCorte(ACncID: Integer; AMaqId: Integer);
    procedure CarregarMaquina(Apelido: string);
    procedure CarregarUtilidades(categoria: string);
    procedure EnviarParametros(AJsonBody: TJSONObject);
    procedure ListarCortes(maq_id: Integer; status: Integer);
    procedure ListarCortesMonitoramento(AMaqID: Integer);
    procedure VerificarAlarmes(ACallback: TProc<TJSONArray>);
    procedure EditarAlarme(AAlrID, Status: Integer; Programador: string);
    procedure ListarAlarmes(ACallback: TProc<TJSONArray>);
    procedure SolicitarAlarme(AMaq_id: Integer;
                             ACnc_ID: Integer;
                             ACnc_cnc: Integer;
                             AMensagem: string;
                             AProposta: string);
    procedure ConferirUsuarios(ACallback: TProc<TJSONArray>);
    procedure ConsultarTodosAlarmes(ACallback: TProc<TJSONArray>);
  end;

implementation

uses
  uParametros, uLoading, FMX.frame.PopUpToast;

{ TModuloRequest }

constructor TModuloRequest.Create(AParentForm: TForm; AOnResult: TOnRequestResult);
begin
    inherited Create;
    FParentForm := AParentForm;
    FOnResult := AOnResult;
end;

destructor TModuloRequest.Destroy;
begin
    if Assigned(FAuthenticator) then FAuthenticator.Free;
    if Assigned(FRESTResponse) then FRESTResponse.Free;
    if Assigned(FRESTRequest) then FRESTRequest.Free;
    if Assigned(FRESTClient) then FRESTClient.Free;
    inherited;
end;

procedure TModuloRequest.ResetarComponentesRest;
begin
    if Assigned(FAuthenticator) then FreeAndNil(FAuthenticator);
    if Assigned(FRESTResponse) then FreeAndNil(FRESTResponse);
    if Assigned(FRESTRequest) then FreeAndNil(FRESTRequest);
    if Assigned(FRESTClient) then FreeAndNil(FRESTClient);

    FRESTClient := TRESTClient.Create(nil);
    FRESTRequest := TRESTRequest.Create(nil);
    FRESTResponse := TRESTResponse.Create(nil);
    FAuthenticator := THTTPBasicAuthenticator.Create(nil);

    FAuthenticator.Username := UserName;
    FAuthenticator.Password := Password;

    FRESTClient.Authenticator := FAuthenticator;
    FRESTRequest.Client := FRESTClient;
    FRESTRequest.Response := FRESTResponse;
    FRESTRequest.SynchronizedEvents := False;
end;

procedure TModuloRequest.CarregarMaquina(Apelido: string);
begin
    FContexto := ctxCarregarMaquina;
    TLoading.Show(FParentForm, 'Carregando máquinas...');
    ResetarComponentesRest;

    FFieldId := 'maq_id';
    FFieldNome := 'maq_apelido';

    if (Apelido <> '') then
      FRESTClient.BaseURL := EndPoint + '/fila_cnc/' + Apelido.Trim() + '/1'
    else
      FRESTClient.BaseURL := EndPoint + '/maquina';

    FRESTRequest.Method := rmGET;

    TLoading.ExecuteThread(
      procedure
      begin
          try
            FRESTRequest.Execute;
          except
            on Ex: Exception do
              TThread.Synchronize(nil, procedure begin
                  TFramePopUp.Show(FParentForm, E, 'Erro request: ' + Ex.Message);
              end);
          end;
      end,
      CallbackFimDaThread
    );
end;

procedure TModuloRequest.CarregarUtilidades(categoria: string);
begin
    FContexto := ctxCarregarUtilidades;
    TLoading.Show(FParentForm, 'Carregando ' + categoria + '...');
    ResetarComponentesRest;

    FRESTClient.BaseURL := EndPoint + '/utilidades/' + categoria.Trim();
    FRESTRequest.Method := rmGET;

    FFieldId := 'pcp_utils_id';
    FFieldNome := 'pcp_utils_nome';

    TLoading.ExecuteThread(
      procedure
      begin
          try
              FRESTRequest.Execute;
          except
              on Ex: Exception do
                TThread.Synchronize(nil, procedure begin
                    TFramePopUp.Show(FParentForm, E, 'Erro request: ' + Ex.Message);
                end);
          end;
      end,
      CallbackFimDaThread
    );
end;

procedure TModuloRequest.EnviarParametros(AJsonBody: TJSONObject);
begin
    FContexto := ctxEnviarParametros;
    TLoading.Show(FParentForm, 'Processando parâmetros...');
    ResetarComponentesRest;

    FRESTClient.BaseURL := EndPoint + '/parametros';
    FRESTRequest.Method := rmPOST;

    if Assigned(AJsonBody) then
      FRESTRequest.Body.Add(AJsonBody.ToString, TRESTContentType.ctAPPLICATION_JSON);

    TLoading.ExecuteThread(
      procedure
      begin
          try
            FRESTRequest.Execute;
          except
              on Ex: Exception do
              TThread.Synchronize(nil, procedure
              begin
                  TFramePopUp.Show(FParentForm, E, 'Erro ao enviar parâmetros: ' + Ex.Message);
              end);
          end;
      end,
      CallbackFimDaThread
    );
end;

procedure TModuloRequest.ListarCortes(maq_id: Integer; status: Integer);
begin
    FContexto := ctxListarCortes;
    FUltimoMaqIdSolicitado := maq_id;

    ResetarComponentesRest;

    FRESTClient.BaseURL := EndPoint +
                           '/fila_cnc/' +
                           IntToStr(maq_id) +
                           '/' + IntToStr(status) +
                           '/0';

    FRESTRequest.Method := rmGET;

    TLoading.ExecuteThread(
      procedure
      begin
          try
              FRESTRequest.Execute;
          except
              on Ex: Exception do
                TThread.Synchronize(nil, procedure begin
                   TFramePopUp.Show(FParentForm, E, 'Erro ao listar cortes ID ' + IntToStr(maq_id));
                end);
          end;
      end,
      CallbackFimDaThread
    );
end;

procedure TModuloRequest.CarregarHistoricoCorte(ACncID: Integer; AMaqId: Integer);
var
    LJsonObject: TJSONObject;
begin
    FContexto := ctxHistorico;
    FUltimoMaqIdSolicitado := AMaqId;

    ResetarComponentesRest;

    FRESTClient.BaseURL := EndPoint + '/fila_cnc/historico';
    FRESTRequest.Method := rmPOST;

    FRESTRequest.Body.ClearBody;

    LJsonObject := TJSONObject.Create;
    try
        LJsonObject.AddPair('cnc_id', TJSONNumber.Create(ACncID));
        FRESTRequest.Body.Add(LJsonObject.ToString, TRESTContentType.ctAPPLICATION_JSON);
    finally
        LJsonObject.Free;
    end;

    TLoading.ExecuteThread(
      procedure
      begin
          try
              FRESTRequest.Execute;
          except

          end;
      end,
      CallbackFimDaThread
    );
end;

procedure TModuloRequest.ListarCortesMonitoramento(AMaqID: Integer);
begin
    FContexto := ctxListarCortes;
    FUltimoMaqIdSolicitado := AMaqID;

    ResetarComponentesRest;

    FRESTClient.BaseURL := EndPoint + '/fila_cnc/monitoramento/' + IntToStr(AMaqID);
    FRESTRequest.Method := rmGET;

    TLoading.ExecuteThread(
      procedure
      begin
          try FRESTRequest.Execute; except end;
      end,
      CallbackFimDaThread
    );
end;

procedure TModuloRequest.VerificarAlarmes(ACallback: TProc<TJSONArray>);
begin
    FContexto := ctxCarregarAlarmes;
    FCallbackAlarmes := ACallback;
    ResetarComponentesRest;

    FRESTClient.BaseURL := EndPoint + '/alarme/listar_alarmes/0';
    FRESTRequest.Method := rmGET;

    TLoading.ExecuteThread(
      procedure
      begin
          try
              FRESTRequest.Execute;
          except
              on Ex: Exception do
                TThread.Synchronize(nil, procedure begin
                  TFramePopUp.Show(FParentForm, E, 'Erro request: ' + Ex.Message);
                end);
          end;
      end,
      CallbackFimDaThread
    );
end;

procedure TModuloRequest.ListarAlarmes(ACallback: TProc<TJSONArray>);
begin
    FContexto := ctxCarregarAlarmes;
    FCallbackAlarmes := ACallback;
    ResetarComponentesRest;

    FRESTClient.BaseURL := EndPoint + '/alarme/listar_alarmes/-2';
    FRESTRequest.Method := rmGET;

    TLoading.ExecuteThread(
      procedure
      begin
          try
              FRESTRequest.Execute;
          except
              on Ex: Exception do
                TThread.Synchronize(nil, procedure begin
                    TFramePopUp.Show(FParentForm, E, 'Erro request: ' + Ex.Message);
                end);
          end;
      end,
      CallbackFimDaThread
    );
end;

procedure TModuloRequest.EditarAlarme(AAlrID: Integer; Status: Integer; Programador: string);
var
  LJson: TJSONObject;
begin
    FContexto := ctxEditarAlarme;
    ResetarComponentesRest;

    FRESTClient.BaseURL := EndPoint + '/alarme/editar/' + IntToStr(AAlrID);
    FRESTRequest.Method := rmPUT;

    LJson := TJSONObject.Create;
    try
        LJson.AddPair('alr_status', TJSONNumber.Create(Status));
        LJson.AddPair('programador', Programador);
        FRESTRequest.Body.Add(LJson.ToString, TRESTContentType.ctAPPLICATION_JSON);
    finally
        LJson.Free;
    end;

    TLoading.ExecuteThread(
      procedure
      begin
        try
          FRESTRequest.Execute;
        except

        end;
      end,
      CallbackFimDaThread
    );
end;

procedure TModuloRequest.SolicitarAlarme(AMaq_id: Integer;
                                         ACnc_ID: Integer;
                                         ACnc_cnc: Integer;
                                         AMensagem: string;
                                         AProposta: string);
var
    LJson: TJSONObject;
begin
    FContexto := ctxSolicitarAlarme;

    TLoading.Show(FParentForm, 'Enviando solicitação...');
    ResetarComponentesRest;

    FRESTClient.BaseURL := EndPoint + '/alarme/adicionar';
    FRESTRequest.Method := rmPOST;

    LJson := TJSONObject.Create;
    try
        LJson.AddPair('ALR_PROPOSTA', AProposta);
        LJson.AddPair('ALR_DATA_PEDIDO', DateToISO8601(Now));
        LJson.AddPair('ALR_OPERADOR', mNomeUsuario);
        LJson.AddPair('ALR_TEXTO', AMensagem);

        LJson.AddPair('MAQ_ID', TJSONNumber.Create(AMaq_id));
        LJson.AddPair('CNC_ID', TJSONNumber.Create(ACnc_ID));
        LJson.AddPair('CNC_CNC', TJSONNumber.Create(ACnc_cnc));
        LJson.AddPair('ALR_TIPO_ENVIO', TJSONNumber.Create(1));
        LJson.AddPair('ALR_STATUS', TJSONNumber.Create(0));

        FRESTRequest.AddBody(LJson.ToString, TRESTContentType.ctAPPLICATION_JSON);
    finally
        LJson.Free;
    end;

    TLoading.ExecuteThread(
      procedure
      begin
          try
              FRESTRequest.Execute;
          except
              on Ex: Exception do
                TThread.Synchronize(nil, procedure
                begin
                    TFramePopUp.Show(FParentForm, E, 'Erro ao enviar alarme: ' + Ex.Message);
                end);
          end;
      end,
      CallbackFimDaThread
    );
end;

procedure TModuloRequest.ConferirUsuarios(ACallback: TProc<TJSONArray>);
begin
    FContexto := ctxConferirUsuarios;
    FCallbackAlarmes := ACallback;
    ResetarComponentesRest;

    FRESTClient.BaseURL := EndPoint + '/login/conferir_usuarios';
    FRESTRequest.Method := rmGET;

    TLoading.ExecuteThread(
      procedure
      begin
          try
              FRESTRequest.Execute;
          except
              on Ex: Exception do
                TThread.Synchronize(nil, procedure begin
                  TFramePopUp.Show(FParentForm, E, 'Erro request: ' + Ex.Message);
                end);
          end;
      end,
      CallbackFimDaThread
    );
end;

procedure TModuloRequest.ConsultarTodosAlarmes(ACallback: TProc<TJSONArray>);
begin
    FContexto := ctxCarregarAlarmes;
    FCallbackAlarmes := ACallback;
    ResetarComponentesRest;

    FRESTClient.BaseURL := EndPoint + '/alarme/listar_alarmes/-1';
    FRESTRequest.Method := rmGET;

    TLoading.ExecuteThread(
      procedure
      begin
          try
              FRESTRequest.Execute;
          except
              on Ex: Exception do
                TThread.Synchronize(nil, procedure begin
                  TFramePopUp.Show(FParentForm, E, 'Erro request: ' + Ex.Message);
                end);
          end;
      end,
      CallbackFimDaThread
    );
end;

procedure TModuloRequest.CallbackFimDaThread(Sender: TObject);
begin
    TLoading.Hide;
    try
        TratarRetornoJSON;
    finally
        Self.Free;
    end;
end;

procedure TModuloRequest.TratarRetornoJSON;
var
    LStatusCode: Integer;
    LContent: string;
    LJSONArray: TJSONArray;
begin
    if not Assigned(FRESTResponse) then
    begin
        if Assigned(FOnResult) then FOnResult(Self, '', 0, FContexto);
        Exit;
    end;

    LStatusCode := FRESTResponse.StatusCode;
    LContent := FRESTResponse.Content;

    if LStatusCode = 404 then
        TFramePopUp.Show(FParentForm, E, 'URL não encontrada (404). Verifique o EndPoint.')
    else if LStatusCode >= 500 then
    begin
        TFramePopUp.Show(FParentForm, E, 'Erro 500 no Servidor: ' + LContent);
    end;

    if ((FContexto = ctxCarregarAlarmes) or (FContexto = ctxConferirUsuarios)) and Assigned(FCallbackAlarmes) then
    begin
        LJSONArray := nil;
        try
            if LStatusCode = 200 then
            begin
                try
                    LJSONArray := TJSONObject.ParseJSONValue(LContent) as TJSONArray;
                except
                    LJSONArray := nil;
                end;
            end;

            FCallbackAlarmes(LJSONArray);
        finally
            if LJSONArray <> nil then
                LJSONArray.Free;
        end;
        Exit;
    end;

    if Assigned(FOnResult) then
        FOnResult(Self, LContent, LStatusCode, FContexto);
end;

end.
