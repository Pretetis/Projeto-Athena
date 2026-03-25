unit uRequests;

interface

uses
  System.SysUtils, System.Classes, System.JSON, FMX.Forms, System.DateUtils,
  REST.Client, REST.Types, REST.Authenticator.Basic, System.IOUtils, IdHTTP,
  IdMultipartFormData;

type
  TContextoRequest = (ctxDocumentosVencer, ctxEditarAlarme, ctxSolicitarAlarme,
                      ctxConferirUsuarios, ctxCarregarAlarmes, ctxTotalDocumentos,
                      ctxPesquisarDocumentos, ctxEnviarDocumento, ctxCarregarFuncionarios,
                      ctxCarregarMaquinas, ctxCarregarEmpresas, ctxDesativarDocumento,
                      ctxReativarDocumento, ctxEditarDocumento, ctxListarFuncionarios,
                      ctxCriarFuncionario, ctxProximaChapa, ctxEditarFuncionario);

  TOnRequestResult = procedure(Sender: TObject;
                               const AJsonContent: string;
                               AStatusCode: Integer;
                               AContext: TContextoRequest) of object;

  TModuloRequest = class
  private
    FParentForm: TForm;
    FOnResult: TOnRequestResult;
    FContexto: TContextoRequest;
    FIdResponse: string;
    FIdStatusCode: Integer;
    FRESTClient: TRESTClient;
    FRESTRequest: TRESTRequest;
    FRESTResponse: TRESTResponse;
    FAuthenticator: THTTPBasicAuthenticator;
    FUltimoMaqIdSolicitado: Integer;
    FCallbackAlarmes: TProc<TJSONArray>;

  public
    property UltimoMaqIdSolicitado: Integer read FUltimoMaqIdSolicitado;

    procedure CallbackFimDaThread(Sender: TObject);
    procedure ConferirUsuarios(ACallback: TProc<TJSONArray>);
    procedure EditarAlarme(AAlrID, Status: Integer; Programador: string);
    procedure ListarDocumentosVencer;
    procedure ResetarComponentesRest;
    procedure SolicitarAlarme(AMaq_id, ACnc_ID, ACnc_cnc: Integer; AMensagem, AProposta: string);
    procedure PesquisarDocumentos(ABusca: string; AStatus: string = ''; AAtivo: string = '');
    procedure EnviarDocumento(AEntidadeId, AEntidadeTipo, ATipoDoc, ANomeDoc: string; ADataValidade: TDate; ACaminhoArquivo: string);
    procedure CarregarCatalogoFuncionarios;
    procedure CarregarCatalogoMaquinas;
    procedure CarregarCatalogoEmpresas;
    procedure ListarFuncionarios;
    procedure DesativarDocumento(ADocId: string);
    procedure ReativarDocumento(ADocId: string);
    procedure EditarDocumento(ADocId, ANomeDoc, ATipoDoc, AEntidadeId, AEntidadeTipo: string; ADataValidade: TDate; AAtivo: Boolean; AUsuario, ACaminhoArquivo: string);
    procedure BuscarProximaChapa;
    procedure EnviarFuncionario(ANome, AFuncao, ASetor, AChapa, ACaminhoFoto: string);
    procedure EditarFuncionario(AId, ANome, AFuncao, ASetor, AChapa: string; AAtivo: Boolean; ACaminhoFoto: string);
    procedure ListarTotalDocumentos;
    procedure TratarRetornoJSON;

    constructor Create(AParentForm: TForm; AOnResult: TOnRequestResult);
    destructor Destroy; override;
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

procedure TModuloRequest.ListarDocumentosVencer;
begin
    FContexto := ctxDocumentosVencer;
    ResetarComponentesRest;

    // Utilize a variável global EndPoint que já deve existir na sua uParametros
    FRESTClient.BaseURL := EndPoint + '/alertas/documentos-a-vencer';
    FRESTRequest.Method := rmGET;

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

procedure TModuloRequest.ListarTotalDocumentos;
begin
    FContexto := ctxTotalDocumentos;
    ResetarComponentesRest;

    // Utilize a variável global EndPoint que já deve existir na sua uParametros
    FRESTClient.BaseURL := EndPoint + '/documentos/resumo/status';
    FRESTRequest.Method := rmGET;

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

procedure TModuloRequest.PesquisarDocumentos(ABusca, AStatus, AAtivo: string);
begin
    FContexto := ctxPesquisarDocumentos;
    ResetarComponentesRest;

    FRESTClient.BaseURL := EndPoint + '/documentos/pesquisa';
    FRESTRequest.Method := rmGET;

    // Adiciona os parâmetros na URL (?busca=...&status=...&ativo=...)
    if Trim(ABusca) <> '' then
      FRESTRequest.AddParameter('busca', ABusca, TRESTRequestParameterKind.pkQUERY);

    if Trim(AStatus) <> '' then
      FRESTRequest.AddParameter('status', AStatus, TRESTRequestParameterKind.pkQUERY);

    if Trim(AAtivo) <> '' then
      FRESTRequest.AddParameter('ativo', AAtivo, TRESTRequestParameterKind.pkQUERY);

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

procedure TModuloRequest.EnviarDocumento(AEntidadeId, AEntidadeTipo, ATipoDoc, ANomeDoc: string; ADataValidade: TDate; ACaminhoArquivo: string);
var
  LHttp: TIdHTTP;
  LFormData: TIdMultiPartFormDataStream;
  LJson: TJSONObject;
  LJsonStr: string;
  LField: TIdFormDataField;
begin
  FContexto := ctxEnviarDocumento;
  FIdResponse := '';
  FIdStatusCode := 0;

  if Trim(AEntidadeId) = '' then
    raise Exception.Create('AEntidadeId está vazio!');

  LJson := TJSONObject.Create;
  try
    LJson.AddPair('entidadeId',    AEntidadeId);
    LJson.AddPair('entidadeTipo',  AEntidadeTipo);
    LJson.AddPair('tipoDocumento', ATipoDoc);
    LJson.AddPair('nomeDocumento', ANomeDoc);
    LJson.AddPair('dataValidade',  FormatDateTime('yyyy-mm-dd', ADataValidade));
    LJsonStr := LJson.ToString;
  finally
    LJson.Free;
  end;

  LHttp := TIdHTTP.Create(nil);
  LFormData := TIdMultiPartFormDataStream.Create;

  // Sem SSL — HTTP local
  LHttp.Request.BasicAuthentication := True;
  LHttp.Request.Username := UserName;
  LHttp.Request.Password := Password;

  LField := LFormData.AddFormField('dados', LJsonStr, 'utf-8');
  LField.ContentType := 'application/json';
  LField.ContentTransfer := '8bit'; // <- impede o quoted-printable
  LFormData.AddFile('pdf', ACaminhoArquivo);

  TLoading.ExecuteThread(
    procedure
    begin
      try
        FIdResponse   := LHttp.Post(EndPoint + '/documentos', LFormData);
        FIdStatusCode := LHttp.ResponseCode;
      except
        on E: EIdHTTPProtocolException do
        begin
          FIdResponse   := E.ErrorMessage;
          FIdStatusCode := LHttp.ResponseCode;
        end;
        on E: Exception do
        begin
          FIdResponse   := E.Message;
          FIdStatusCode := 0;
        end;
      end;

      LFormData.Free;
      LHttp.Free;
    end,
    CallbackFimDaThread
  );
end;

procedure TModuloRequest.CarregarCatalogoFuncionarios;
begin
  FContexto := ctxCarregarFuncionarios;
  ResetarComponentesRest;
  FRESTClient.BaseURL := EndPoint + '/funcionarios/lookup';
  FRESTRequest.Method := rmGET;
  TLoading.ExecuteThread(
    procedure begin try FRESTRequest.Execute; except end; end,
    CallbackFimDaThread
  );
end;

procedure TModuloRequest.CarregarCatalogoMaquinas;
begin
  FContexto := ctxCarregarMaquinas;
  ResetarComponentesRest;
  FRESTClient.BaseURL := EndPoint + '/maquinas/lookup';
  FRESTRequest.Method := rmGET;
  TLoading.ExecuteThread(
    procedure begin try FRESTRequest.Execute; except end; end,
    CallbackFimDaThread
  );
end;

procedure TModuloRequest.CarregarCatalogoEmpresas;
begin
  FContexto := ctxCarregarEmpresas;
  ResetarComponentesRest;
  FRESTClient.BaseURL := EndPoint + '/empresas/lookup';
  FRESTRequest.Method := rmGET;
  TLoading.ExecuteThread(
    procedure begin try FRESTRequest.Execute; except end; end,
    CallbackFimDaThread
  );
end;

procedure TModuloRequest.DesativarDocumento(ADocId: string);
begin
    FContexto := ctxDesativarDocumento;
    ResetarComponentesRest;

    FRESTClient.BaseURL := EndPoint + '/documentos/' + ADocId;
    FRESTRequest.Method := rmDELETE;

    TLoading.ExecuteThread(
      procedure
      begin
          try FRESTRequest.Execute; except end;
      end,
      CallbackFimDaThread
    );
end;

procedure TModuloRequest.ReativarDocumento(ADocId: string);
begin
    FContexto := ctxReativarDocumento;
    ResetarComponentesRest;

    FRESTClient.BaseURL := EndPoint + '/documentos/' + ADocId + '/reativar';
    FRESTRequest.Method := rmPUT;

    TLoading.ExecuteThread(
      procedure
      begin
          try FRESTRequest.Execute; except end;
      end,
      CallbackFimDaThread
    );
end;

procedure TModuloRequest.EditarDocumento(ADocId, ANomeDoc, ATipoDoc, AEntidadeId, AEntidadeTipo: string; ADataValidade: TDate; AAtivo: Boolean; AUsuario, ACaminhoArquivo: string);
var
    LHttp: TIdHTTP;
    LFormData: TIdMultiPartFormDataStream;
    LJson: TJSONObject;
    LJsonStr: string;
    LField: TIdFormDataField;
begin
    FContexto := ctxEditarDocumento;
    FIdResponse := '';
    FIdStatusCode := 0;

    LJson := TJSONObject.Create;
    try
      // Adicionamos o Título e a EntidadeId no JSON que vai pro Node
      LJson.AddPair('nomeDocumento', ANomeDoc);
      LJson.AddPair('tipoDocumento', ATipoDoc);
      LJson.AddPair('entidadeId', AEntidadeId);
      LJson.AddPair('entidadeTipo', AEntidadeTipo);
      LJson.AddPair('dataValidade', FormatDateTime('yyyy-mm-dd', ADataValidade));
      LJson.AddPair('usuarioAlteracao', AUsuario);
      if AAtivo then
          LJson.AddPair('ativo', TJSONTrue.Create)
      else
          LJson.AddPair('ativo', TJSONFalse.Create);
      LJsonStr := LJson.ToString;
    finally
      LJson.Free;
    end;

    LHttp := TIdHTTP.Create(nil);
    LFormData := TIdMultiPartFormDataStream.Create;

    LHttp.Request.BasicAuthentication := True;
    LHttp.Request.Username := UserName;
    LHttp.Request.Password := Password;

    LField := LFormData.AddFormField('dados', LJsonStr, 'utf-8');
    LField.ContentType := 'application/json';
    LField.ContentTransfer := '8bit';

    if Trim(ACaminhoArquivo) <> '' then
        LFormData.AddFile('pdf', ACaminhoArquivo);

    TLoading.ExecuteThread(
      procedure
      begin
          try
              LHttp.Request.ContentType := LFormData.RequestContentType;
              FIdResponse   := LHttp.Put(EndPoint + '/documentos/' + ADocId, LFormData);
              FIdStatusCode := LHttp.ResponseCode;
          except
              on E: EIdHTTPProtocolException do
              begin
                  FIdResponse   := E.ErrorMessage;
                  FIdStatusCode := LHttp.ResponseCode;
              end;
              on E: Exception do
              begin
                  FIdResponse   := E.Message;
                  FIdStatusCode := 0;
              end;
          end;

          LFormData.Free;
          LHttp.Free;
      end,
      CallbackFimDaThread
    );
end;

procedure TModuloRequest.ListarFuncionarios;
begin
    FContexto := ctxListarFuncionarios;
    ResetarComponentesRest;

    // Aponta para a rota principal que retorna todos os dados do funcionário
    FRESTClient.BaseURL := EndPoint + '/funcionarios';
    FRESTRequest.Method := rmGET;

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

procedure TModuloRequest.BuscarProximaChapa;
begin
    FContexto := ctxProximaChapa;
    ResetarComponentesRest;

    FRESTClient.BaseURL := EndPoint + '/chapa/proxima';
    FRESTRequest.Method := rmGET;

    TLoading.ExecuteThread(
      procedure
      begin
          try FRESTRequest.Execute; except end;
      end,
      CallbackFimDaThread
    );
end;

procedure TModuloRequest.EnviarFuncionario(ANome, AFuncao, ASetor, AChapa, ACaminhoFoto: string);
var
  LHttp: TIdHTTP;
  LFormData: TIdMultiPartFormDataStream;
  LJson: TJSONObject;
  LJsonStr: string;
  LField: TIdFormDataField;
begin
  FContexto := ctxCriarFuncionario;
  FIdResponse := '';
  FIdStatusCode := 0;

  LJson := TJSONObject.Create;
  try
    LJson.AddPair('nome', ANome);
    LJson.AddPair('funcao', AFuncao);
    LJson.AddPair('setor', ASetor);
    LJson.AddPair('chapa', AChapa);
    LJsonStr := LJson.ToString;
  finally
    LJson.Free;
  end;

  LHttp := TIdHTTP.Create(nil);
  LFormData := TIdMultiPartFormDataStream.Create;

  LHttp.Request.BasicAuthentication := True;
  LHttp.Request.Username := UserName;
  LHttp.Request.Password := Password;

  LField := LFormData.AddFormField('dados', LJsonStr, 'utf-8');
  LField.ContentType := 'application/json';
  LField.ContentTransfer := '8bit';

  if Trim(ACaminhoFoto) <> '' then
    LFormData.AddFile('foto', ACaminhoFoto);

  TLoading.ExecuteThread(
    procedure
    begin
      try
        FIdResponse   := LHttp.Post(EndPoint + '/funcionarios', LFormData);
        FIdStatusCode := LHttp.ResponseCode;
      except
        on E: EIdHTTPProtocolException do
        begin
          FIdResponse   := E.ErrorMessage;
          FIdStatusCode := LHttp.ResponseCode;
        end;
        on E: Exception do
        begin
          FIdResponse   := E.Message;
          FIdStatusCode := 0;
        end;
      end;

      LFormData.Free;
      LHttp.Free;
    end,
    CallbackFimDaThread
  );
end;

procedure TModuloRequest.EditarFuncionario(AId, ANome, AFuncao, ASetor, AChapa: string; AAtivo: Boolean; ACaminhoFoto: string);
var
  LHttp: TIdHTTP;
  LFormData: TIdMultiPartFormDataStream;
  LJson: TJSONObject;
  LJsonStr: string;
  LField: TIdFormDataField;
begin
  FContexto := ctxEditarFuncionario;
  FIdResponse := '';
  FIdStatusCode := 0;

  LJson := TJSONObject.Create;
  try
    LJson.AddPair('nome', ANome);
    LJson.AddPair('funcao', AFuncao);
    LJson.AddPair('setor', ASetor);
    LJson.AddPair('chapa', AChapa);

    if AAtivo then
      LJson.AddPair('ativo', TJSONTrue.Create)
    else
      LJson.AddPair('ativo', TJSONFalse.Create);

    LJsonStr := LJson.ToString;
  finally
    LJson.Free;
  end;

  LHttp := TIdHTTP.Create(nil);
  LFormData := TIdMultiPartFormDataStream.Create;

  LHttp.Request.BasicAuthentication := True;
  LHttp.Request.Username := UserName;
  LHttp.Request.Password := Password;

  LField := LFormData.AddFormField('dados', LJsonStr, 'utf-8');
  LField.ContentType := 'application/json';
  LField.ContentTransfer := '8bit';

  if Trim(ACaminhoFoto) <> '' then
    LFormData.AddFile('foto', ACaminhoFoto);

  TLoading.ExecuteThread(
    procedure
    begin
      try
        LHttp.Request.ContentType := LFormData.RequestContentType;
        FIdResponse   := LHttp.Put(EndPoint + '/funcionarios/' + AId, LFormData);
        FIdStatusCode := LHttp.ResponseCode;
      except
        on E: EIdHTTPProtocolException do
        begin
          FIdResponse   := E.ErrorMessage;
          FIdStatusCode := LHttp.ResponseCode;
        end;
        on E: Exception do
        begin
          FIdResponse   := E.Message;
          FIdStatusCode := 0;
        end;
      end;

      LFormData.Free;
      LHttp.Free;
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
    if (FContexto = ctxEnviarDocumento) or (FContexto = ctxEditarDocumento) then
    begin
        if Assigned(FOnResult) then
            FOnResult(Self, FIdResponse, FIdStatusCode, FContexto);
        Exit;
    end;

    if FContexto = ctxCriarFuncionario then
    begin
        if Assigned(FOnResult) then
            FOnResult(Self, FIdResponse, FIdStatusCode, FContexto);
        Exit;
    end;

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
