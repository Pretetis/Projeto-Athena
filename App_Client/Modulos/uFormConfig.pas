unit uFormConfig;

interface

uses
  FMX.Forms, System.SysUtils, FireDAC.Comp.Client, uConnection;

procedure SalvarConfigForm(AForm: TForm; const AUsuario: string);
procedure CarregarConfigForm(AForm: TForm; const AUsuario: string);


implementation

uses
    System.Classes;

const
    SHARED_FORM_KEY = 'DEFAULT_POSITION';

procedure SalvarConfigForm(AForm: TForm; const AUsuario: string);
var
  qry: TFDQuery;
begin
    {$IFDEF MSWINDOWS}
    if (AUsuario.Trim = '') or (not Assigned(AForm)) then Exit;

    if not Assigned(FDConnectionSIP) or (not FDConnectionSIP.Connected) then Exit;

    qry := TFDQuery.Create(nil);
    try
        qry.Connection := FDConnectionSIP;

        qry.SQL.Text := 'SELECT COUNT(*) FROM FORM_CONFIG WHERE USUARIO = :USUARIO AND FORM_NAME = :FORM_NAME';
        qry.ParamByName('USUARIO').AsString := AUsuario;
        qry.ParamByName('FORM_NAME').AsString := SHARED_FORM_KEY;
        qry.Open;

        if qry.Fields[0].AsInteger > 0 then
        begin
            qry.Close;
            qry.SQL.Text := 'UPDATE FORM_CONFIG SET ' +
                          '  POS_TOP = :POS_TOP, POS_LEFT = :POS_LEFT, ' +
                          '  SIZE_WIDTH = :SIZE_WIDTH, SIZE_HEIGHT = :SIZE_HEIGHT ' +
                          'WHERE USUARIO = :USUARIO AND FORM_NAME = :FORM_NAME';
        end
        else
        begin
            qry.Close;
            qry.SQL.Text := 'INSERT INTO FORM_CONFIG (USUARIO, FORM_NAME, POS_TOP, POS_LEFT, SIZE_WIDTH, SIZE_HEIGHT) ' +
                          'VALUES (:USUARIO, :FORM_NAME, :POS_TOP, :POS_LEFT, :SIZE_WIDTH, :SIZE_HEIGHT)';
        end;

        qry.ParamByName('USUARIO').AsString := AUsuario;
        qry.ParamByName('FORM_NAME').AsString := SHARED_FORM_KEY;
        qry.ParamByName('POS_TOP').AsInteger := Round(AForm.Top);
        qry.ParamByName('POS_LEFT').AsInteger := Round(AForm.Left);
        qry.ParamByName('SIZE_WIDTH').AsInteger := Round(AForm.Width);
        qry.ParamByName('SIZE_HEIGHT').AsInteger := Round(AForm.Height);

        qry.ExecSQL;
    finally
        qry.Free;
    end;
    {$ENDIF}
end;

procedure CarregarConfigForm(AForm: TForm; const AUsuario: string);
var
    qry: TFDQuery;
begin
    {$IFDEF MSWINDOWS}
    if (AUsuario.Trim = '') or (not Assigned(AForm)) then Exit;

    if not Assigned(FDConnectionSIP) or (not FDConnectionSIP.Connected) then Exit;

    qry := TFDQuery.Create(nil);
    try
        qry.Connection := FDConnectionSIP;
        qry.SQL.Text := 'SELECT * FROM FORM_CONFIG WHERE USUARIO = :USUARIO AND FORM_NAME = :FORM_NAME';
        qry.ParamByName('USUARIO').AsString := AUsuario;
        qry.ParamByName('FORM_NAME').AsString := SHARED_FORM_KEY;
        qry.Open;

        if not qry.IsEmpty then
        begin
            AForm.Left := qry.FieldByName('POS_LEFT').AsInteger;
            AForm.Top := qry.FieldByName('POS_TOP').AsInteger;

            AForm.Width := qry.FieldByName('SIZE_WIDTH').AsInteger;
            AForm.Height := qry.FieldByName('SIZE_HEIGHT').AsInteger;
        end;
    finally
        qry.Free;
    end;
    {$ENDIF}
end;

end.
