unit uConnection;

interface

uses

  System.Classes, System.SysUtils,
  System.IOUtils,
  FireDAC.Stan.Def,
  FireDAC.DApt,
  FireDAC.UI.Intf,
  FireDAC.FMXUI.Wait,
  FireDAC.Stan.Async,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Phys.SQLiteWrapper,
  // FireDAC.Phys.SQLiteWrapper.Stat,
  FireDAC.Comp.Client;


var
  FDConnectionSIP: TFDConnection;

function SetupConnectionSIP(FConn: TFDConnection): String;
function ConnectSIP : TFDConnection;
procedure DisconectSIP;

implementation

function SetupConnectionSIP(FConn: TFDConnection): string;
var
    lArquivoConfig : string;
begin
    try
//        FConn.Name := 'SQLite';

        {$IFDEF MSWINDOWS}
        if not DirectoryExists(System.SysUtils.GetCurrentDir + '\db') then CreateDir((System.SysUtils.GetCurrentDir + '\db'));
        FConn.Params.Values['Database'] := System.SysUtils.GetCurrentDir + '\db\banco.db';
        FConn.Params.Values['DriverID'] := 'SQLite';
        {$ELSE}
        FConn.Params.Values['Database'] := TPath.Combine(TPath.GetDocumentsPath, 'banco.db');
        FConn.Params.Values['DriverID'] := 'SQLite';
        {$ENDIF}
        FConn.LoginPrompt:= False;

        FConn.ExecSQL('create table IF NOT EXISTS usuario (NOME varchar(50), USUARIO VARCHAR(50), SENHA varchar(50));');

        Result := 'OK';
    except on ex:exception do
        Result := 'Erro ao configurar banco: ' + ex.Message;
    end;
end;

function ConnectSIP : TFDConnection;
begin
  FDConnectionSIP := TFDConnection.Create(nil);

  SetupConnectionSIP(FDConnectionSIP);
  FDConnectionSIP.Connected := true;

  Result := FDConnectionSIP;
end;

procedure DisconectSIP;
begin
  if Assigned(FDConnectionSIP) then
  begin
    if FDConnectionSIP.Connected then
      FDConnectionSIP.Connected := false;

    FDConnectionSIP.Free;
  end;
end;

end.
