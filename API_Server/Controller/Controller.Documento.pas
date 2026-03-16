unit Controller.Documento;

interface

uses
  Horse, System.SysUtils, Model.Connection; // <-- Adicionamos a Model.Connection aqui!

type
  TControllerDocumento = class
  public
    class procedure Registry;
  end;

implementation

// --- Rota antiga de teste ---
procedure GetDocumentos(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send('Lista de documentos retornada com sucesso!');
end;

// --- NOVA Rota para testar o MongoDB ---
procedure TestarBanco(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LConexao: TModelConnection;
begin
  try
    // Ao criar a classe, ela vai ler o config.ini e tentar conectar no Atlas
    LConexao := TModelConnection.Create;
    try
      if LConexao.Connection.Connected then
        Res.Status(200).Send('Sucesso! A API conectou perfeitamente no MongoDB Atlas.')
      else
        Res.Status(500).Send('Falha: A classe foi criada, mas a conexão não está ativa.');
    finally
      LConexao.Free; // Libera a conexão da memória (muito importante em APIs!)
    end;
  except
    on E: Exception do
      // Se der erro de senha, IP bloqueado ou falta de DLL, o erro vai cair aqui
      Res.Status(500).Send('Erro fatal ao conectar no banco: ' + E.Message);
  end;
end;

class procedure TControllerDocumento.Registry;
begin
  // Registra as rotas no Horse
  THorse.Get('/documentos', GetDocumentos);
  THorse.Get('/testar-banco', TestarBanco); // <-- Registramos a nova rota aqui
end;

end.
