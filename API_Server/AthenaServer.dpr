program AthenaServer;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Horse,
  Horse.Jhonson, // 1. Adicionamos a unit do Jhonson aqui
  Model.Connection in 'Model\Model.Connection.pas',
  Controller.Documento in 'Controller\Controller.Documento.pas';

begin
  try
    // 2. Avisamos o Horse para usar o Jhonson em TODAS as requisições
    THorse.Use(Jhonson());

    // Registra os controllers
    TControllerDocumento.Registry;

    Writeln('Servidor Athena rodando na porta 9000...');
    THorse.Listen(9000);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
