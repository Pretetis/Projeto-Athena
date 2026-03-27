unit uConnection;

interface

uses
  System.Classes, System.SysUtils, System.IOUtils,
  FireDAC.Stan.Def, FireDAC.DApt, FireDAC.UI.Intf, FireDAC.FMXUI.Wait,
  FireDAC.Stan.Async, FireDAC.Phys.SQLite, FireDAC.Comp.Client;

var
  FDConnectionSIP: TFDConnection;

procedure ConnectSIP;
procedure DisconectSIP;

implementation

procedure ConnectSIP;
begin
  if not Assigned(FDConnectionSIP) then
    FDConnectionSIP := TFDConnection.Create(nil);

  FDConnectionSIP.Params.Clear;
  FDConnectionSIP.Params.Values['DriverID'] := 'SQLite';

  {$IFDEF MSWINDOWS}
    if not DirectoryExists(GetCurrentDir + '\db') then CreateDir(GetCurrentDir + '\db');
    FDConnectionSIP.Params.Values['Database'] := GetCurrentDir + '\db\banco.db';
  {$ELSE}
    FDConnectionSIP.Params.Values['Database'] := TPath.Combine(TPath.GetDocumentsPath, 'banco.db');
  {$ENDIF}

  FDConnectionSIP.LoginPrompt := False;
  FDConnectionSIP.Connected := True;

  FDConnectionSIP.ExecSQL('CREATE TABLE IF NOT EXISTS USUARIO (NOME VARCHAR(50), USUARIO VARCHAR(50), SENHA VARCHAR(50));');
end;

procedure DisconectSIP;
begin
  if Assigned(FDConnectionSIP) then
  begin
    FDConnectionSIP.Connected := False;
    FreeAndNil(FDConnectionSIP);
  end;
end;

end.
