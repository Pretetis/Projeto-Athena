unit frame.TelaFuncionario;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Objects, FMX.Edit, FMX.Effects,
  System.JSON, System.Threading, System.Net.HttpClient, System.Net.HttpClientComponent,
  System.Net.URLClient,
  uRequests, uParametros;

type
  TDocDownloadInfo = record
    Id: string;
    Url: string;
    FileName: string;
  end;

  TfTelaFuncionario = class(TFrame)
    recFundo: TRectangle;
    Layout1: TLayout;
    recFoto: TRectangle;
    lbNomeFuncionario: TLabel;
    lbCargo: TLabel;
    lbSetor: TLabel;
    pathSetor: TPath;
    lbChapa: TLabel;
    pathChapa: TPath;
    recFiltroDados: TRectangle;
    ShadowEffect2: TShadowEffect;
    recBuscaDocumentos: TRectangle;
    pathBusca: TPath;
    edtBuscaDocumentos: TEdit;
    tmrBusca: TTimer;
    recPlanilhaDocumentos: TRectangle;
    ShadowEffect1: TShadowEffect;
    layCabecalhoPlanilhaAlerta: TLayout;
    recCabecalhoPlanilha: TRectangle;
    gplCabecalhoPlanilhaAlerta: TGridPanelLayout;
    recCabecalhoDoc: TRectangle;
    lbDoc: TLabel;
    recVencimento: TRectangle;
    lbVencimento: TLabel;
    recVisualizar: TRectangle;
    lbVisualizar: TLabel;
    layTituloPlanilha: TLayout;
    lbTituloPlanilhaAlerta: TLabel;
    vscrollboxLinhaPlanilha: TVertScrollBox;
    procedure edtBuscaDocumentosChangeTracking(Sender: TObject);
    procedure tmrBuscaTimer(Sender: TObject);
    procedure edtBuscaDocumentosKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
  private
    FReqFunc: TModuloRequest;
    FReqDoc: TModuloRequest;
    FIdFuncionario: string;

    procedure OnRequestFuncionarioResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
    procedure OnRequestDocumentosResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
    procedure CarregarFotoAssincrona(AIdFuncionario: string);
    procedure LimparTabela;
    procedure BuscarDocumentos;
    procedure IniciarDownloadEmSegundoPlano(AListaDocs: TArray<TDocDownloadInfo>);
    procedure ProcessarJsonDocumentos(const AJsonContent: string);
  public
    constructor Create(AOwner: TComponent); override;
    procedure CarregarDadosTela;
  end;

implementation

uses
  frame.LinhaTelaFuncionario, uDesignSystem, System.IOUtils, System.DateUtils, IdHTTP;
{$R *.fmx}

constructor TfTelaFuncionario.Create(AOwner: TComponent);
begin
  inherited;
  // LimparTabela;
  // Limpa os dados visuais antes de carregar
  lbNomeFuncionario.Text := 'Carregando...';
  lbCargo.Text := '';
  lbSetor.Text := '';
  lbChapa.Text := '';
end;

procedure TfTelaFuncionario.CarregarDadosTela;
begin
  // 1. IMPORTANTE: Recupera o ID do cache global para o filtro funcionar offline
  FIdFuncionario := mIdFuncionario;

  // 2. Preenchimento visual imediato
  lbNomeFuncionario.Text := mNomeUsuario;
  lbCargo.Text := mFuncao;
  lbSetor.Text := mSetor;

  // 3. Tenta atualizar os dados do servidor (se estiver online)
  FReqFunc := TModuloRequest.Create(nil, OnRequestFuncionarioResult);
  FReqFunc.ListarFuncionarios(mUsuario, 'true');

  // 4. Dispara a busca de documentos (que agora vai ler o cache se falhar a rede)
  BuscarDocumentos;
end;
procedure TfTelaFuncionario.OnRequestFuncionarioResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
var
  LJsonArray: TJSONArray;
  LJsonObj: TJSONObject;
begin
  if AStatusCode = 200 then
  begin
    LJsonArray := TJSONObject.ParseJSONValue(AJsonContent) as TJSONArray;
    if Assigned(LJsonArray) and (LJsonArray.Count > 0) then
    begin
      try
        // Pega o primeiro resultado (que deve ser o usuário logado)
        LJsonObj := LJsonArray.Items[0] as TJSONObject;

        FIdFuncionario := LJsonObj.GetValue<string>('_id', '');
        lbNomeFuncionario.Text := LJsonObj.GetValue<string>('nome', mUsuario);
        lbCargo.Text := LJsonObj.GetValue<string>('funcao', 'Sem Função');
        lbSetor.Text := LJsonObj.GetValue<string>('setor', 'Não informado');
        lbChapa.Text := LJsonObj.GetValue<string>('chapa', 'S/C');

        // Carrega a foto se tiver ID
        if FIdFuncionario <> '' then
          CarregarFotoAssincrona(FIdFuncionario);

        // Após carregar os dados dele, busca os documentos
        BuscarDocumentos;
      finally
        LJsonArray.Free;
      end;
    end;
  end;
end;

procedure TfTelaFuncionario.BuscarDocumentos;
var
  LBusca: string;
begin
  // Se o usuário digitou algo, pesquisa por esse texto.
  // Se estiver vazio, pesquisa pelo nome do funcionário para não carregar o banco todo.
  if Trim(edtBuscaDocumentos.Text) <> '' then
    LBusca := Trim(edtBuscaDocumentos.Text)
  else
    LBusca := Trim(lbNomeFuncionario.Text);

  FReqDoc := TModuloRequest.Create(nil, OnRequestDocumentosResult);
  FReqDoc.PesquisarDocumentos(LBusca, '', 'true'); // Passamos 'true' para trazer apenas os ativos
end;

//procedure TfTelaFuncionario.OnRequestDocumentosResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
//var
//  LJsonArray: TJSONArray;
//  LJsonObj: TJSONObject;
//  i: Integer;
//  LFrame: TfLinhaTelaFuncionario;
//
//  // Variáveis para a fila de download
//  LListaDownload: TArray<TDocDownloadInfo>;
//  LDataStr: string;
//  LDataValidade: TDate;
//begin
//  LimparTabela;
//  if AStatusCode = 200 then
//  begin
//    LJsonArray := TJSONObject.ParseJSONValue(AJsonContent) as TJSONArray;
//    if Assigned(LJsonArray) then
//    begin
//      try
//        vscrollboxLinhaPlanilha.BeginUpdate;
//        try
//          SetLength(LListaDownload, 0); // Zera a lista
//
//          for i := 0 to LJsonArray.Count - 1 do
//          begin
//            LJsonObj := LJsonArray.Items[i] as TJSONObject;
//
//            // Dupla checagem
//            if LJsonObj.GetValue<string>('entidadeId', '') <> FIdFuncionario then
//              Continue;
//
//            // Transforma a data do JSON para verificar se está vencido
//            LDataStr := LJsonObj.GetValue<string>('dataValidade', '');
//            LDataValidade := Date;
//            try
//              LDataValidade := ISO8601ToDate(LDataStr);
//            except
//              // Se a data vier em branco ou fora do padrão, mantém o Date atual para não explodir
//            end;
//
//            // Criação visual do Card do Documento (seu código original)
//            LFrame := TfLinhaTelaFuncionario.Create(Self);
//            LFrame.FDocId := LJsonObj.GetValue<string>('_id');
//            LFrame.FNomeDoc := LJsonObj.GetValue<string>('nomeDocumento', 'Sem Nome');
//            LFrame.FNomeEntidade := LJsonObj.GetValue<string>('nomeEntidade', lbNomeFuncionario.Text);
//
//            LFrame.Name := 'DocFunc_' + i.ToString;
//            LFrame.Parent := vscrollboxLinhaPlanilha;
//            LFrame.Align := TAlignLayout.Top;
//            LFrame.Margins.Bottom := 4;
//            LFrame.Position.Y := 99999;
//
//            LFrame.CarregarDados(
//              LFrame.FNomeDoc,
//              LJsonObj.GetValue<string>('tipoDocumento', '-'),
//              LJsonObj.GetValue<string>('dataValidade', DateToStr(Date))
//            );
//
//            // --- LÓGICA DE DOWNLOAD OFFLINE ---
//            // Verifica se o documento é válido (a data de validade é >= hoje)
//            if Trunc(LDataValidade) >= Trunc(Date) then
//            begin
//              SetLength(LListaDownload, Length(LListaDownload) + 1);
//              LListaDownload[High(LListaDownload)].Id := LFrame.FDocId;
//              LListaDownload[High(LListaDownload)].FileName := 'Doc_' + LFrame.FDocId + '.pdf';
//
//              // Ajuste a rota '/documentos/download/' conforme configurou na sua API Node.js
//              LListaDownload[High(LListaDownload)].Url := EndPoint + '/documentos/download/' + LFrame.FDocId;
//            end;
//
//          end;
//        finally
//          vscrollboxLinhaPlanilha.EndUpdate;
//          Self.Width := Self.Width + 1;
//          Application.ProcessMessages;
//          Self.Width := Self.Width - 1;
//        end;
//
//        // Se houver documentos válidos, dispara a Thread de download em background
//        if Length(LListaDownload) > 0 then
//          IniciarDownloadEmSegundoPlano(LListaDownload);
//
//      finally
//        LJsonArray.Free;
//      end;
//    end;
//  end;
//end;
procedure TfTelaFuncionario.OnRequestDocumentosResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
var
  LArquivoCache: string;
begin
  // Define onde o cache de texto será salvo
  LArquivoCache := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetDocumentsPath, 'docs_cache.json');

  if AStatusCode = 200 then
  begin
    // MODO ONLINE: Salva a lista fresca e processa
    System.IOUtils.TFile.WriteAllText(LArquivoCache, AJsonContent, TEncoding.UTF8);
    ProcessarJsonDocumentos(AJsonContent);
  end
  else
  begin
    // MODO OFFLINE: Tenta ler o arquivo de cache
    if System.IOUtils.TFile.Exists(LArquivoCache) then
    begin
      ProcessarJsonDocumentos(System.IOUtils.TFile.ReadAllText(LArquivoCache, TEncoding.UTF8));
    end
    else
    begin
      LimparTabela;
      // Opcional: mostrar um TFramePopUp de que não há dados baixados
    end;
  end;
end;

procedure TfTelaFuncionario.ProcessarJsonDocumentos(const AJsonContent: string);
var
  LJsonArray: TJSONArray;
  LJsonObj: TJSONObject;
  i: Integer;
  LFrame: TfLinhaTelaFuncionario;
  LListaDownload: TArray<TDocDownloadInfo>;
  LDataStr: string;
  LDataValidade: TDate;
begin
  LimparTabela;
  LJsonArray := TJSONObject.ParseJSONValue(AJsonContent) as TJSONArray;
  if Assigned(LJsonArray) then
  begin
    try
      vscrollboxLinhaPlanilha.BeginUpdate;
      try
        SetLength(LListaDownload, 0);
        for i := 0 to LJsonArray.Count - 1 do
        begin
          LJsonObj := LJsonArray.Items[i] as TJSONObject;

          if LJsonObj.GetValue<string>('entidadeId', '') <> FIdFuncionario then
            Continue;

          LDataStr := LJsonObj.GetValue<string>('dataValidade', '');
          LDataValidade := Date;
          try
            LDataValidade := ISO8601ToDate(LDataStr);
          except
          end;

          LFrame := TfLinhaTelaFuncionario.Create(Self);
          LFrame.FDocId := LJsonObj.GetValue<string>('_id');
          LFrame.FNomeDoc := LJsonObj.GetValue<string>('nomeDocumento', 'Sem Nome');
          LFrame.FNomeEntidade := LJsonObj.GetValue<string>('nomeEntidade', lbNomeFuncionario.Text);

          LFrame.Name := 'DocFunc_' + i.ToString;
          LFrame.Parent := vscrollboxLinhaPlanilha;
          LFrame.Align := TAlignLayout.Top;
          LFrame.Margins.Bottom := 4;
          LFrame.Position.Y := 99999;

          LFrame.CarregarDados(
            LFrame.FNomeDoc,
            LJsonObj.GetValue<string>('tipoDocumento', '-'),
            LJsonObj.GetValue<string>('dataValidade', DateToStr(Date))
          );

          if Trunc(LDataValidade) >= Trunc(Date) then
          begin
            SetLength(LListaDownload, Length(LListaDownload) + 1);
            LListaDownload[High(LListaDownload)].Id := LFrame.FDocId;
            LListaDownload[High(LListaDownload)].FileName := 'Doc_' + LFrame.FDocId + '.pdf';
            LListaDownload[High(LListaDownload)].Url := EndPoint + '/documentos/download/' + LFrame.FDocId;
          end;
        end;
      finally
        vscrollboxLinhaPlanilha.EndUpdate;
        Self.Width := Self.Width + 1;
        Application.ProcessMessages;
        Self.Width := Self.Width - 1;
      end;

      if Length(LListaDownload) > 0 then
        IniciarDownloadEmSegundoPlano(LListaDownload);

    finally
      LJsonArray.Free;
    end;
  end;
end;

procedure TfTelaFuncionario.LimparTabela;
var
  i: Integer;
begin
  // Defesa FMX: Só tenta limpar se o Content já existir fisicamente na tela
  if Assigned(vscrollboxLinhaPlanilha) and Assigned(vscrollboxLinhaPlanilha.Content) then
  begin
    for i := vscrollboxLinhaPlanilha.Content.ChildrenCount - 1 downto 0 do
    begin
      if vscrollboxLinhaPlanilha.Content.Children[i] is TfLinhaTelaFuncionario then
      begin
        // No Delphi 10.3 Mobile, DisposeOf destrói o componente visual com segurança
        vscrollboxLinhaPlanilha.Content.Children[i].DisposeOf;
      end;
    end;
  end;
end;

procedure TfTelaFuncionario.CarregarFotoAssincrona(AIdFuncionario: string);
begin
  TTask.Run(
    procedure
    var
      LHttp: TNetHTTPClient;
      LResponse: IHTTPResponse;
      LStream: TMemoryStream;
    begin
      LHttp := TNetHTTPClient.Create(nil);
      LStream := TMemoryStream.Create;
      try
        try
          LResponse := LHttp.Get(EndPoint + '/funcionarios/' + AIdFuncionario + '/foto', LStream);
          if LResponse.StatusCode = 200 then
          begin
            LStream.Position := 0;
            TThread.Synchronize(nil,
              procedure
              begin
                if Assigned(Self) and Assigned(recFoto) then
                begin
                  recFoto.Fill.Kind := TBrushKind.Bitmap;
                  recFoto.Fill.Bitmap.Bitmap.LoadFromStream(LStream);
                  recFoto.Fill.Bitmap.WrapMode := TWrapMode.TileStretch;
                end;
              end);
          end;
        except
        end;
      finally
        LStream.Free;
        LHttp.Free;
      end;
    end);
end;

procedure TfTelaFuncionario.edtBuscaDocumentosChangeTracking(Sender: TObject);
begin
  tmrBusca.Enabled := False;
  if (Length(edtBuscaDocumentos.Text) >= 3) or (Length(edtBuscaDocumentos.Text) = 0) then
    tmrBusca.Enabled := True;
end;

procedure TfTelaFuncionario.edtBuscaDocumentosKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    Key := 0;
    BuscarDocumentos;
  end;
end;

procedure TfTelaFuncionario.tmrBuscaTimer(Sender: TObject);
begin
  tmrBusca.Enabled := False;
  BuscarDocumentos;
end;

procedure TfTelaFuncionario.IniciarDownloadEmSegundoPlano(AListaDocs: TArray<TDocDownloadInfo>);
begin
  TTask.Run(
    procedure
    var
      LHttp: TIdHTTP;
      LStream: TFileStream;
      LPathPasta, LPathCompleto: string;
      I: Integer;
    begin
      // Usamos System.IOUtils direto no comando para blindar o conflito!
      LPathPasta := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetDocumentsPath, 'AthenaDocs');

      if not System.IOUtils.TDirectory.Exists(LPathPasta) then
        System.IOUtils.TDirectory.CreateDirectory(LPathPasta);

      LHttp := TIdHTTP.Create(nil);
      try
        // Usa as credenciais globais do sistema (de uParametros)
        LHttp.Request.BasicAuthentication := True;
        LHttp.Request.Username := UserName;
        LHttp.Request.Password := Password;

        for I := Low(AListaDocs) to High(AListaDocs) do
        begin
          LPathCompleto := System.IOUtils.TPath.Combine(LPathPasta, AListaDocs[I].FileName);

          // Baixa apenas se o documento AINDA NÃO EXISTIR localmente
          if not System.IOUtils.TFile.Exists(LPathCompleto) then
          begin
            LStream := TFileStream.Create(LPathCompleto, fmCreate);
            try
              try
                // Efetua o download silencioso do PDF para a pasta
                LHttp.Get(AListaDocs[I].Url, LStream);
              except
                // Ignora erros isolados (ex: falha de rede em um único doc)
              end;
            finally
              LStream.Free;
            end;
          end;
        end;
      finally
        LHttp.Free;
      end;
    end
  );
end;

end.
