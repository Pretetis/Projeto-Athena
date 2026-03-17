unit Controller.Documento;

interface

uses
  Horse, System.SysUtils, Model.Connection, System.JSON,
  FireDAC.Phys.MongoDBDataSet,  FireDAC.Comp.Client,
  FireDAC.Phys.MongoDBWrapper;

type
  TControllerDocumento = class
  public
    class procedure Registry;
  end;

implementation

procedure GetDocumentos(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
    Res.Send('Lista de documentos retornada com sucesso!');
end;

procedure TestarBanco(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
    LConexao: TModelConnection;
begin
    try
        LConexao := TModelConnection.Create;
        try
            if LConexao.Connection.Connected then
                Res.Status(200).Send('Sucesso! A API conectou perfeitamente no MongoDB.')
            else
                Res.Status(500).Send('Falha: A classe foi criada, mas a conexão não está ativa.');
        finally
            LConexao.Free; // Libera a conexão da memória (muito importante em APIs!)
        end;
    except
        on E: Exception do
            Res.Status(500).Send('Erro fatal ao conectar no banco: ' + E.Message);
    end;
end;

procedure CadastrarDocumento(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
    LJSONRecebido: TJSONObject;
    LModelConexao: TModelConnection;
    FMongoCon: TMongoConnection;
    FMongoEnv: TMongoEnv;
    FDatabase: TMongoDatabase;
    FCollection: TMongoCollection;
    LDocBSON: TMongoDocument;
begin
    LJSONRecebido := Req.Body<TJSONObject>;

    LModelConexao := TModelConnection.Create;

    try
        LModelConexao.Connection.Connected := True;

        FMongoCon := TMongoConnection(LModelConexao.Connection.CliObj);
        FMongoEnv := FMongoCon.Env;
        FDatabase := FMongoCon['AthenaDB'];
        FCollection := FDatabase['Documentos'];

        LDocBSON := FMongoEnv.NewDoc;
        LDocBSON
          .Add('funcionario', LJSONRecebido.GetValue('funcionario').Value)
          .Add('tipo', LJSONRecebido.GetValue('tipo').Value)
          .Add('validade', LJSONRecebido.GetValue('validade').Value);
        FCollection.Insert(LDocBSON);

        Res.Status(201).Send('Documento catalogado com sucesso!');
    finally
        LModelConexao.Free;
    end;
end;

class procedure TControllerDocumento.Registry;
begin
    THorse.Get('/documentos', GetDocumentos);
    THorse.Get('/testar-banco', TestarBanco);
    THorse.Post('/cadastrar-documentos', CadastrarDocumento);
end;

end.
