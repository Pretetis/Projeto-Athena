unit frame.TelaFuncionario;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Controls.Presentation,
  FMX.Layouts, FMX.Objects, FMX.Edit, FMX.Effects,
  System.JSON, System.Threading, System.Net.HttpClient, System.Net.HttpClientComponent, System.Net.URLClient,
  uRequests, uParametros;

type
  TfTelaFuncionario = class(TFrame)
    recFundo: TRectangle;
    Layout1: TLayout;
    recFoto: TRectangle; // Recomendo usar TCircle para a foto como no Card
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
  public
    constructor Create(AOwner: TComponent); override;
    procedure CarregarDadosTela;
  end;

implementation

uses
  frame.LinhaTelaFuncionario, uDesignSystem;

{$R *.fmx}

constructor TfTelaFuncionario.Create(AOwner: TComponent);
begin
  inherited;
  LimparTabela;
  // Limpa os dados visuais antes de carregar
  lbNomeFuncionario.Text := 'Carregando...';
  lbCargo.Text := '';
  lbSetor.Text := '';
  lbChapa.Text := '';
end;

procedure TfTelaFuncionario.CarregarDadosTela;
begin
  // Utiliza a variável global mNomeUsuario do uParametros para buscar o funcionário exato
  FReqFunc := TModuloRequest.Create(nil, OnRequestFuncionarioResult);
  FReqFunc.ListarFuncionarios(mUsuario, 'true'); // Apenas funcionário ativo
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

procedure TfTelaFuncionario.OnRequestDocumentosResult(Sender: TObject; const AJsonContent: string; AStatusCode: Integer; AContext: TContextoRequest);
var
  LJsonArray: TJSONArray;
  LJsonObj: TJSONObject;
  i: Integer;
  LFrame: TfLinhaTelaFuncionario;
begin
  LimparTabela;
  if AStatusCode = 200 then
  begin
    LJsonArray := TJSONObject.ParseJSONValue(AJsonContent) as TJSONArray;
    if Assigned(LJsonArray) then
    begin
      try
        vscrollboxLinhaPlanilha.BeginUpdate;
        try
          for i := 0 to LJsonArray.Count - 1 do
          begin
            LJsonObj := LJsonArray.Items[i] as TJSONObject;

            // Dupla checagem para garantir que o documento é do funcionário (caso a busca genérica traga lixo)
            if LJsonObj.GetValue<string>('entidadeId', '') <> FIdFuncionario then
              Continue;

            LFrame := TfLinhaTelaFuncionario.Create(Self);

            // Popula os dados
            LFrame.FDocId := LJsonObj.GetValue<string>('_id');
            LFrame.FNomeDoc := LJsonObj.GetValue<string>('nomeDocumento', 'Sem Nome');
            LFrame.FNomeEntidade := LJsonObj.GetValue<string>('nomeEntidade', lbNomeFuncionario.Text);

            // Configurações de UI
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
          end;
        finally
          vscrollboxLinhaPlanilha.EndUpdate;
          // Força o redesenho do scroll
          Self.Width := Self.Width + 1;
          Application.ProcessMessages;
          Self.Width := Self.Width - 1;
        end;
      finally
        LJsonArray.Free;
      end;
    end;
  end;
end;

procedure TfTelaFuncionario.LimparTabela;
var
  i: Integer;
begin
  for i := vscrollboxLinhaPlanilha.Content.ChildrenCount - 1 downto 0 do
  begin
    if vscrollboxLinhaPlanilha.Content.Children[i] is TfLinhaTelaFuncionario then
      vscrollboxLinhaPlanilha.Content.Children[i].Free;
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

end.
