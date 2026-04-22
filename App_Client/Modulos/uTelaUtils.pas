unit uTelaUtils;

interface

uses
  System.Classes, System.UITypes, FMX.Types, FMX.Forms, FMX.Platform,
  FMX.Effects, FMX.Objects;

// 1. DECLARAÇÕES PARA OUTRAS UNITS ENXERGAREM AS FUNÇÕES
procedure ConfigurarModoTela(AForm: TForm);
procedure AlterarBlurPai(AComponenteOrigem: TFmxObject; AAtivar: Boolean);
procedure ConfigurarBotaoAnimado(ABotao: TRectangle);

implementation

uses
    FMX.Ani;

type
  TBotaoEfeitoHandler = class
  public
    procedure MouseEnter(Sender: TObject);
    procedure MouseLeave(Sender: TObject);
    procedure MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  end;

var
  HandlerEfeitos: TBotaoEfeitoHandler;

{ TBotaoEfeitoHandler }

procedure TBotaoEfeitoHandler.MouseEnter(Sender: TObject);
begin
  // Hover (Windows): Diminui levemente a opacidade
  TAnimator.AnimateFloat(TFmxObject(Sender), 'Opacity', 0.8, 0.1);
end;

procedure TBotaoEfeitoHandler.MouseLeave(Sender: TObject);
begin
  // Mouse fora (Windows) ou Fim do toque (Mobile): Retorna ao normal
  TAnimator.AnimateFloat(TFmxObject(Sender), 'Opacity', 1.0, 0.1);
end;

procedure TBotaoEfeitoHandler.MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  // Clique/Toque Inciado: Efeito de "afundar" o botão
  TAnimator.AnimateFloat(TFmxObject(Sender), 'Opacity', 0.5, 0.05);
end;

procedure TBotaoEfeitoHandler.MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  // Soltou o Clique/Toque: Volta para a opacidade de Hover (no PC)
  // No mobile, o evento MouseLeave disparará logo em seguida para voltar a 1.0
  TAnimator.AnimateFloat(TFmxObject(Sender), 'Opacity', 0.8, 0.1);
end;

{ Funções Exportadas }

procedure ConfigurarBotaoAnimado(ABotao: TRectangle);
begin
  if not Assigned(ABotao) then Exit;

  // 1. Muda o cursor para "Mãozinha" (apenas afeta Desktop/Windows)
  ABotao.Cursor := crHandPoint;

  // 2. Garante a opacidade inicial
  ABotao.Opacity := 1.0;

  // 3. Injeta os eventos (IMPORTANTE: Isso não apaga o seu OnClick já existente!)
  ABotao.OnMouseEnter := HandlerEfeitos.MouseEnter;
  ABotao.OnMouseLeave := HandlerEfeitos.MouseLeave;
  ABotao.OnMouseDown  := HandlerEfeitos.MouseDown;
  ABotao.OnMouseUp    := HandlerEfeitos.MouseUp;
end;

procedure ConfigurarModoTela(AForm: TForm);
begin
  if AForm = nil then Exit;

  {$IFDEF ANDROID}
  AForm.FullScreen := True;
  {$ELSEIF defined(MSWINDOWS)}
  AForm.FullScreen := False;
  {$ENDIF}
end;

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

initialization
  HandlerEfeitos := TBotaoEfeitoHandler.Create;
finalization
  HandlerEfeitos.Free;

end.
