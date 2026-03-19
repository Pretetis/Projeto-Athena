unit uTelaUtils;

interface

uses
    FMX.Forms, FMX.Platform;

implementation

procedure ConfigurarModoTela(AForm: TForm);
begin
  if AForm = nil then Exit;

  {$IFDEF ANDROID}
  AForm.FullScreen := True;

  {$ELSEIF defined(MSWINDOWS)}
  AForm.FullScreen := False;

  {$ENDIF}

end;

end.
