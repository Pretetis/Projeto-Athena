unit Model.Connection;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, System.IOUtils,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.ConsoleUI.Wait,
  FireDAC.Phys.MongoDBDef, FireDAC.Phys.MongoDB, FireDAC.Phys.MongoDBWrapper,
  FireDAC.Comp.Client;

type
  TModelConnection = class
  private
    FConn: TFDConnection;
    FMongoLink: TFDPhysMongoDriverLink;
    procedure LerConfiguracoes;
  public
    constructor Create;
    destructor Destroy; override;
    property Connection: TFDConnection read FConn;
  end;

implementation

{ TModelConnection }

constructor TModelConnection.Create;
begin
  FConn := TFDConnection.Create(nil);
  FMongoLink := TFDPhysMongoDriverLink.Create(nil);

  // Configuração base do driver
  FConn.DriverName := 'Mongo';
  FConn.LoginPrompt := False;

  // Carrega as credenciais dinamicamente
  LerConfiguracoes;

  // Estabelece a ligação ao MongoDB
  FConn.Connected := True;
end;

destructor TModelConnection.Destroy;
begin
  FConn.Connected := False;
  FConn.Free;
  FMongoLink.Free;
  inherited;
end;

procedure TModelConnection.LerConfiguracoes;
var
  LIniFile: TIniFile;
  LCaminhoIni: string;
begin
  LCaminhoIni := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'config.ini');
  LIniFile := TIniFile.Create(LCaminhoIni);
  try
    // Passamos a lista de servidores reais (os 3 endereços)
    FConn.Params.Values['Server'] := LIniFile.ReadString('BancoDeDados', 'Servidores', '');

    // Passamos o nome do ReplicaSet do Atlas
    FConn.Params.Values['ReplicaSet'] := LIniFile.ReadString('BancoDeDados', 'ReplicaSet', '');

    FConn.Params.Values['Database'] := LIniFile.ReadString('BancoDeDados', 'Database', 'AthenaDocs');
    FConn.Params.Values['User_Name'] := LIniFile.ReadString('BancoDeDados', 'Usuario', '');
    FConn.Params.Values['Password'] := LIniFile.ReadString('BancoDeDados', 'Senha', '');
    FConn.Params.Values['MongoAdvanced'] := 'authSource=admin';
    // O TLS é obrigatório para a nuvem
    FConn.Params.Values['UseTLS'] := 'True';
  finally
    LIniFile.Free;
  end;
end;

end.
