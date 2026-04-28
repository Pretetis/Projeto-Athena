unit uConnection;

interface

uses
  System.Classes, System.SysUtils, System.IOUtils,
  FireDAC.Stan.Def, FireDAC.DApt, FireDAC.UI.Intf, FireDAC.FMXUI.Wait,
  FireDAC.Stan.Async, FireDAC.Phys.SQLite, FireDAC.Comp.Client;

var
  FDConnectionATHENA: TFDConnection;

procedure ConnectATHENA;
procedure DisconectATHENA;

implementation

procedure ConnectATHENA;
begin
  if not Assigned(FDConnectionATHENA) then
    FDConnectionATHENA := TFDConnection.Create(nil);

  FDConnectionATHENA.Params.Clear;
  FDConnectionATHENA.Params.Values['DriverID'] := 'SQLite';

  {$IFDEF MSWINDOWS}
    if not DirectoryExists(GetCurrentDir + '\db') then CreateDir(GetCurrentDir + '\db');
    FDConnectionATHENA.Params.Values['Database'] := GetCurrentDir + '\db\banco.db';
  {$ELSE}
    FDConnectionATHENA.Params.Values['Database'] := TPath.Combine(TPath.GetDocumentsPath, 'banco.db');
  {$ENDIF}

  FDConnectionATHENA.LoginPrompt := False;
  FDConnectionATHENA.Connected := True;

  FDConnectionATHENA.ExecSQL('CREATE TABLE IF NOT EXISTS USUARIO (NOME VARCHAR(100), USUARIO VARCHAR(100), SENHA VARCHAR(100));');
end;

procedure DisconectATHENA;
begin
  if Assigned(FDConnectionATHENA) then
  begin
    FDConnectionATHENA.Connected := False;
    FreeAndNil(FDConnectionATHENA);
  end;
end;

end.
