unit uGemini;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.NetEncoding,
  System.Generics.Collections,
  REST.Client,
  REST.Types,
  System.IOUtils;

function LerVariavelEnv(const ACaminhoArquivo, AChave: string): string;

type
  TGeminiRole = (grUser, grModel);

  TGeminiMessage = class
  public
    Role: TGeminiRole;
    Text: string;
    constructor Create(ARole: TGeminiRole; const AText: string);
  end;

  TGemini = class
  private
    FApiKey: string;
    FModel: string;
    FSystemInstruction: string;
    FHistory: TObjectList<TGeminiMessage>;

    function RoleToString(ARole: TGeminiRole): string;
    function GetMimeType(const AFileName: string): string;
    function FileToBase64(const AFileName: string): string;

    function BuildSystemInstruction: TJSONObject;
    function BuildHistoryArray: TJSONArray;
    function BuildUserTextContent(const AText: string): TJSONObject;

    // Alterado de ImageContent (inlineData) para FileContent (fileData URI)
    function BuildUserFileContent(const AFileUri, AMimeType, APrompt: string): TJSONObject;

    // Nova função para fazer o upload em duas etapas
    function UploadFileToNode(const AMimeType, ABase64: string): string;

    function ExecuteRequest(const ABody: string): string;
    function ExtractTextFromResponse(const AResponseJSON: string): string;
    function ExtractErrorMessage(const AResponseJSON: string): string;
  public
    constructor Create(const AModel: string = 'gemini-2.5-flash');
    destructor Destroy; override;

    procedure ClearHistory;
    procedure AddUserMessage(const AText: string);
    procedure AddModelMessage(const AText: string);

    function SendText(const APrompt: string): string;
    // O SendImage agora suporta arquivos maiores usando o novo fluxo
    function SendImage(const AFileName, APrompt: string): string;

    property Model: string read FModel write FModel;
    property SystemInstruction: string read FSystemInstruction write FSystemInstruction;
  end;

implementation

uses
  uParametros; // Assume-se que a variável 'endPoint' está aqui

{ TGeminiMessage }

function LerVariavelEnv(const ACaminhoArquivo, AChave: string): string;
var
  LArquivoEnv: TStringList;
begin
  Result := '';
  if not TFile.Exists(ACaminhoArquivo) then Exit;

  LArquivoEnv := TStringList.Create;
  try
    LArquivoEnv.LoadFromFile(ACaminhoArquivo);
    Result := LArquivoEnv.Values[AChave];
  finally
    LArquivoEnv.Free;
  end;
end;

constructor TGeminiMessage.Create(ARole: TGeminiRole; const AText: string);
begin
  inherited Create;
  Role := ARole;
  Text := AText;
end;

{ TGemini }

constructor TGemini.Create(const AModel: string = 'gemini-2.5-flash');
begin
  inherited Create;
  FModel := Trim(AModel);
  if FModel = '' then
    FModel := 'gemini-2.5-flash';
  FHistory := TObjectList<TGeminiMessage>.Create(True);
end;

destructor TGemini.Destroy;
begin
  FHistory.Free;
  inherited;
end;

procedure TGemini.ClearHistory;
begin
  FHistory.Clear;
end;

procedure TGemini.AddUserMessage(const AText: string);
begin
  if Trim(AText) <> '' then
    FHistory.Add(TGeminiMessage.Create(grUser, AText));
end;

procedure TGemini.AddModelMessage(const AText: string);
begin
  if Trim(AText) <> '' then
    FHistory.Add(TGeminiMessage.Create(grModel, AText));
end;

function TGemini.RoleToString(ARole: TGeminiRole): string;
begin
  case ARole of
    grUser:  Result := 'user';
    grModel: Result := 'model';
  else
    Result := 'user';
  end;
end;

function TGemini.GetMimeType(const AFileName: string): string;
var
  LExt: string;
begin
  LExt := LowerCase(ExtractFileExt(AFileName));
  if (LExt = '.jpg') or (LExt = '.jpeg') then Result := 'image/jpeg'
  else if LExt = '.png' then Result := 'image/png'
  else if LExt = '.webp' then Result := 'image/webp'
  else if LExt = '.gif' then Result := 'image/gif'
  else if LExt = '.bmp' then Result := 'image/bmp'
  else if LExt = '.pdf' then Result := 'application/pdf'
  else if (LExt = '.xls') or (LExt = '.xlsx') then Result := 'application/vnd.ms-excel'
  else if LExt = '.csv' then Result := 'text/csv'
  else if (LExt = '.mp3') or (LExt = '.wav') or (LExt = '.ogg') then Result := 'audio/' + Copy(LExt, 2, Length(LExt))
  else if (LExt = '.mp4') or (LExt = '.avi') then Result := 'video/' + Copy(LExt, 2, Length(LExt))
  else raise Exception.Create('Formato de arquivo não suportado: ' + LExt);
end;

function TGemini.FileToBase64(const AFileName: string): string;
var
  LStream: TFileStream;
  LBytes: TBytes;
begin
  if not FileExists(AFileName) then
    raise Exception.Create('Arquivo não encontrado: ' + AFileName);

  LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(LBytes, LStream.Size);
    if LStream.Size > 0 then
      LStream.ReadBuffer(LBytes[0], Length(LBytes));
  finally
    LStream.Free;
  end;

  Result := TNetEncoding.Base64.EncodeBytesToString(LBytes);
  Result := StringReplace(Result, sLineBreak, '', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]);
  Result := StringReplace(Result, #9, '', [rfReplaceAll]);
  Result := StringReplace(Result, ' ', '', [rfReplaceAll]);
end;

function TGemini.BuildSystemInstruction: TJSONObject;
var
  LParts: TJSONArray;
begin
  Result := nil;
  if Trim(FSystemInstruction) = '' then Exit;

  LParts := TJSONArray.Create;
  LParts.AddElement(TJSONObject.Create.AddPair('text', FSystemInstruction));

  Result := TJSONObject.Create;
  Result.AddPair('parts', LParts);
end;

function TGemini.BuildHistoryArray: TJSONArray;
var
  I: Integer;
  LObj: TJSONObject;
  LParts: TJSONArray;
begin
  Result := TJSONArray.Create;
  for I := 0 to FHistory.Count - 1 do
  begin
    LParts := TJSONArray.Create;
    LParts.AddElement(TJSONObject.Create.AddPair('text', FHistory[I].Text));

    LObj := TJSONObject.Create;
    LObj.AddPair('role', RoleToString(FHistory[I].Role));
    LObj.AddPair('parts', LParts);

    Result.AddElement(LObj);
  end;
end;

function TGemini.BuildUserTextContent(const AText: string): TJSONObject;
var
  LParts: TJSONArray;
begin
  LParts := TJSONArray.Create;
  LParts.AddElement(TJSONObject.Create.AddPair('text', AText));

  Result := TJSONObject.Create;
  Result.AddPair('role', 'user');
  Result.AddPair('parts', LParts);
end;

// --- NOVA FUNÇÃO DE ESTRUTURA PARA A FILE API ---
function TGemini.BuildUserFileContent(const AFileUri, AMimeType, APrompt: string): TJSONObject;
var
  LParts: TJSONArray;
  LFileData: TJSONObject;
begin
  LFileData := TJSONObject.Create;
  LFileData.AddPair('mimeType', AMimeType);
  LFileData.AddPair('fileUri', AFileUri);

  LParts := TJSONArray.Create;
  LParts.AddElement(TJSONObject.Create.AddPair('fileData', LFileData));

  if Trim(APrompt) <> '' then
    LParts.AddElement(TJSONObject.Create.AddPair('text', APrompt));

  Result := TJSONObject.Create;
  Result.AddPair('role', 'user');
  Result.AddPair('parts', LParts);
end;

// --- NOVA FUNÇÃO QUE CHAMA A NOVA ROTA DO NODE.JS ---
function TGemini.UploadFileToNode(const AMimeType, ABase64: string): string;
var
  LClient: TRESTClient;
  LRequest: TRESTRequest;
  LResponse: TRESTResponse;
  LJSONBody: TJSONObject;
  LJSONResp: TJSONValue;
  LUriValue: TJSONValue;
begin
  LClient := TRESTClient.Create(endPoint + '/gemini-upload');
  LRequest := TRESTRequest.Create(nil);
  LResponse := TRESTResponse.Create(nil);
  LJSONBody := TJSONObject.Create;
  try
    LJSONBody.AddPair('mimeType', AMimeType);
    LJSONBody.AddPair('base64Data', ABase64);

    LRequest.Client := LClient;
    LRequest.Response := LResponse;
    LRequest.Method := rmPOST;
    LRequest.AddBody(LJSONBody.ToJSON, ctAPPLICATION_JSON);

    // Arquivos grandes exigem um timeout maior. Configuramos para 60 segundos.
    LRequest.Timeout := 60000;
    LRequest.Execute;

    if (LResponse.StatusCode < 200) or (LResponse.StatusCode >= 300) then
      raise Exception.Create('Erro ao fazer upload (Node.js): ' + LResponse.Content);

    LJSONResp := TJSONObject.ParseJSONValue(LResponse.Content);
    try
      if LJSONResp <> nil then
      begin
        LUriValue := LJSONResp.FindValue('file.uri');
        if LUriValue <> nil then
          Result := LUriValue.Value
        else
          raise Exception.Create('Resposta do Node não contém file.uri');
      end;
    finally
      LJSONResp.Free;
    end;
  finally
    LJSONBody.Free;
    LResponse.Free;
    LRequest.Free;
    LClient.Free;
  end;
end;

function TGemini.ExecuteRequest(const ABody: string): string;
var
  LClient: TRESTClient;
  LRequest: TRESTRequest;
  LResponse: TRESTResponse;
  LUrl: string;
  LError: string;
begin
  LUrl := endPoint + '/gemini/' + FModel;

  LClient := TRESTClient.Create(LUrl);
  LRequest := TRESTRequest.Create(nil);
  LResponse := TRESTResponse.Create(nil);
  try
    LRequest.Client := LClient;
    LRequest.Response := LResponse;
    LRequest.Method := rmPOST;
    LRequest.Timeout := 60000; // Aumentado para lidar com geração de conteúdo pesada

    LRequest.Params.Clear;
    LRequest.AddParameter('Content-Type', 'application/json', pkHTTPHEADER, [poDoNotEncode]);
    LRequest.AddBody(ABody, ctAPPLICATION_JSON);

    LRequest.Execute;
    Result := LResponse.Content;

    if (LResponse.StatusCode < 200) or (LResponse.StatusCode >= 300) then
    begin
      LError := ExtractErrorMessage(Result);
      if LError = '' then
        LError := 'HTTP ' + IntToStr(LResponse.StatusCode) + ' - ' + LResponse.StatusText;
      raise Exception.Create('Erro Gemini (via Servidor): ' + LError);
    end;
  finally
    LResponse.Free;
    LRequest.Free;
    LClient.Free;
  end;
end;

function TGemini.ExtractErrorMessage(const AResponseJSON: string): string;
var
  LJSON: TJSONValue;
  LValue: TJSONValue;
begin
  Result := '';
  LJSON := TJSONObject.ParseJSONValue(AResponseJSON);
  try
    if LJSON = nil then Exit;
    LValue := LJSON.FindValue('error.message');
    if LValue <> nil then
      Result := LValue.Value;
  finally
    LJSON.Free;
  end;
end;

function TGemini.ExtractTextFromResponse(const AResponseJSON: string): string;
var
  LJSON: TJSONValue;
  LCandidates: TJSONArray;
  LContent: TJSONObject;
  LParts: TJSONArray;
  I: Integer;
  LPartText: TJSONValue;
begin
  Result := '';
  LJSON := TJSONObject.ParseJSONValue(AResponseJSON);
  try
    if LJSON = nil then raise Exception.Create('Resposta JSON inválida.');

    LCandidates := LJSON.FindValue('candidates') as TJSONArray;
    if (LCandidates = nil) or (LCandidates.Count = 0) then
      raise Exception.Create('Resposta sem candidates.');

    LContent := LCandidates.Items[0].FindValue('content') as TJSONObject;
    if LContent = nil then raise Exception.Create('Resposta sem content.');

    LParts := LContent.FindValue('parts') as TJSONArray;
    if LParts = nil then raise Exception.Create('Resposta sem parts.');

    for I := 0 to LParts.Count - 1 do
    begin
      LPartText := LParts.Items[I].FindValue('text');
      if LPartText <> nil then
        Result := Result + LPartText.Value;
    end;

    Result := Trim(Result);
  finally
    LJSON.Free;
  end;
end;

function TGemini.SendText(const APrompt: string): string;
var
  LRoot: TJSONObject;
  LContents: TJSONArray;
  LSystem: TJSONObject;
  LResponse: string;
begin
  if Trim(APrompt) = '' then
    raise Exception.Create('Prompt não informado.');

  LRoot := TJSONObject.Create;
  try
    LSystem := BuildSystemInstruction;
    if LSystem <> nil then LRoot.AddPair('systemInstruction', LSystem);

    LContents := BuildHistoryArray;
    LContents.AddElement(BuildUserTextContent(APrompt));
    LRoot.AddPair('contents', LContents);

    LResponse := ExecuteRequest(LRoot.ToJSON);
  finally
    LRoot.Free;
  end;

  Result := ExtractTextFromResponse(LResponse);
  AddUserMessage(APrompt);
  AddModelMessage(Result);
end;

// --- SEND IMAGE TOTALMENTE REESCRITO PARA USAR O NOVO FLUXO ---
function TGemini.SendImage(const AFileName, APrompt: string): string;
var
  LRoot: TJSONObject;
  LContents: TJSONArray;
  LSystem: TJSONObject;
  LBase64: string;
  LMimeType: string;
  LFileUri: string;
  LResponse: string;
begin
  LMimeType := GetMimeType(AFileName);
  LBase64 := FileToBase64(AFileName);

  // Passo 1: Envia o Base64 para o Node.js e recebe a URI do Google
  LFileUri := UploadFileToNode(LMimeType, LBase64);

  // Passo 2: Monta a requisição padrão usando a URI que o Node devolveu
  LRoot := TJSONObject.Create;
  try
    LSystem := BuildSystemInstruction;
    if LSystem <> nil then LRoot.AddPair('systemInstruction', LSystem);

    LContents := BuildHistoryArray;
    LContents.AddElement(BuildUserFileContent(LFileUri, LMimeType, APrompt));
    LRoot.AddPair('contents', LContents);

    LResponse := ExecuteRequest(LRoot.ToJSON);
  finally
    LRoot.Free;
  end;

  Result := ExtractTextFromResponse(LResponse);

  if Trim(APrompt) <> '' then
    AddUserMessage(APrompt)
  else
    AddUserMessage('[arquivo enviado: ' + ExtractFileName(AFileName) + ']');

  AddModelMessage(Result);
end;

end.
