unit uTelaUtils;

interface

uses
  System.Classes, FMX.Types, FMX.Forms, FMX.Platform, FMX.Effects;

// 1. DECLARAÇÕES PARA OUTRAS UNITS ENXERGAREM AS FUNÇÕES
procedure ConfigurarModoTela(AForm: TForm);
procedure AlterarBlurPai(AComponenteOrigem: TFmxObject; AAtivar: Boolean);

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

// 2. RECEBER O COMPONENTE POR PARÂMETRO NO LUGAR DO "Self"
procedure AlterarBlurPai(AComponenteOrigem: TFmxObject; AAtivar: Boolean);
var
  LFormPai: TForm;
  LEfeito: TComponent;
begin
  if not Assigned(AComponenteOrigem) then Exit;

  // Usa o AComponenteOrigem passado por parâmetro em vez de Self
  if (AComponenteOrigem.Root <> nil) and (AComponenteOrigem.Root.GetObject is TForm) then
  begin
    LFormPai := TForm(AComponenteOrigem.Root.GetObject);

    // Procura dinamicamente um componente chamado 'EfeitoBlur' nesse Form
    LEfeito := LFormPai.FindComponent('EfeitoBlur');

    // Se o efeito existir na tela, liga ou desliga
    if Assigned(LEfeito) and (LEfeito is TBlurEffect) then
      TBlurEffect(LEfeito).Enabled := AAtivar;
  end;
end;

end.
