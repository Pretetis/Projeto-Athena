unit FMX.frame.PopUpToast;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  System.ImageList, FMX.ImgList, FMX.Controls.Presentation, FMX.Layouts,
  FMX.Objects, FMX.Ani, FMX.Effects, System.IOUtils, FMX.Media;

type
  TToastType = (S,E,A);

  TFramePopUp = class(TFrame)
    recPrincipal: TRectangle;
    layIcone: TLayout;
    layInfo: TLayout;
    recCor: TRectangle;
    gpIcone: TGlyph;
    lbTitulo: TLabel;
    lbTexto: TLabel;
    imlNotificacao: TImageList;
    lbFechar: TLabel;
    MediaPlayer1: TMediaPlayer;
    procedure lbFecharClick(Sender: TObject);
  private
    FTimerClose: TTimer;
    FJaFechou: Boolean;
    procedure ConfigurarToast(ATipo: TToastType; AMensagem: string);
    procedure btnFecharClick(Sender: TObject);
    procedure OnTimerClose(Sender: TObject);
    procedure FecharFrame;
    procedure TocarSomNotificacao;
  public
    class procedure Show(AParent: TFmxObject; ATipo: TToastType; AMensagem: string);
    constructor Create(AOwner: TComponent);
  end;

implementation

{$R *.fmx}

{ TFramePopUp }

constructor TFramePopUp.Create(AOwner: TComponent);
begin
    inherited Create(AOwner);
    FJaFechou := False;

    FTimerClose := TTimer.Create(Self);
    FTimerClose.Interval := 3500;
    FTimerClose.Enabled := False;
    FTimerClose.OnTimer := OnTimerClose;
end;

procedure TFramePopUp.lbFecharClick(Sender: TObject);
begin
    FecharFrame;
end;

procedure TFramePopUp.OnTimerClose(Sender: TObject);
begin
    FecharFrame;
end;

procedure TFramePopUp.FecharFrame;
begin
    if FJaFechou then Exit;
    FJaFechou := True;

    FTimerClose.Enabled := False;

    TAnimator.AnimateFloat(Self, 'Opacity', 0, 0.3);

    TThread.CreateAnonymousThread(procedure
    begin
        TThread.Synchronize(nil, procedure
        begin
            TAnimator.AnimateFloatWait(Self, 'Position.Y', -100, 0.3, TAnimationType.In, TInterpolationType.Back);
            Self.DisposeOf;
        end);
    end).Start;
end;

class procedure TFramePopUp.Show(AParent: TFmxObject; ATipo: TToastType; AMensagem: string);
var
    LFrame: TFramePopUp;
    LBaseWidth: Single;
    i: Integer;
    LChild: TFmxObject;
    LExistingToast: TControl;
    LOffset: Single;
begin
    LFrame := TFramePopUp.Create(nil);

    if AParent = nil then
        LFrame.Parent := Screen.ActiveForm
    else
        LFrame.Parent := AParent;

    LFrame.recPrincipal.Align := TAlignLayout.Contents;
    LFrame.recPrincipal.Margins.Rect := TRectF.Create(0,0,0,0);
    LFrame.Align := TAlignLayout.None;

    if Application.MainForm <> nil then
        LBaseWidth := TForm(Application.MainForm).ClientWidth
    else
        LBaseWidth := Screen.Size.Width;

    LFrame.SetBounds(20, -100, LBaseWidth - 40, LFrame.Height);
    LFrame.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];
    LFrame.Opacity := 0;
    LFrame.ConfigurarToast(ATipo, AMensagem);

    if Assigned(LFrame.lbFechar) then
        LFrame.lbFechar.OnClick := LFrame.lbFecharClick;

    LOffset := LFrame.Height + 10;

    if LFrame.Parent <> nil then
    begin
        for i := 0 to LFrame.Parent.ChildrenCount - 1 do
        begin
            LChild := LFrame.Parent.Children[i];

            if (LChild is TFramePopUp) and (LChild <> LFrame) then
            begin
                LExistingToast := TControl(LChild);

                if LExistingToast.Opacity > 0.1 then
                begin
                    TAnimator.AnimateFloat(LExistingToast, 'Position.Y',
                      LExistingToast.Position.Y + LOffset, 0.3, TAnimationType.Out, TInterpolationType.Linear);
                end;
            end;
        end;
    end;

    LFrame.BringToFront;

    TAnimator.AnimateFloat(LFrame, 'Position.Y', 20, 0.4, TAnimationType.Out, TInterpolationType.Back);
    TAnimator.AnimateFloat(LFrame, 'Opacity', 1, 0.3);

    LFrame.FTimerClose.Enabled := True;
    LFrame.TocarSomNotificacao;
end;

procedure TFramePopUp.btnFecharClick(Sender: TObject);
begin
    FecharFrame;
end;

procedure TFramePopUp.ConfigurarToast(ATipo: TToastType; AMensagem: string);
begin
    case ATipo of
        S:
          begin
              gpIcone.ImageIndex := 2;
              lbTitulo.Text := 'SUCESSO';
              recCor.Fill.Color := $FF04BC04;
          end;
        E:
          begin
              gpIcone.ImageIndex := 0;
              lbTitulo.Text := 'ERRO';
              recCor.Fill.Color := $FFF44434;
          end;
        A:
          begin
              gpIcone.ImageIndex := 1;
              lbTitulo.Text := 'ALERTA';
              recCor.Fill.Color := $FFFAD062;
          end;
    end;
    lbTexto.Text := AMensagem;
end;

procedure TFramePopUp.TocarSomNotificacao;
var
  CaminhoSom: string;
begin
    {$IFDEF ANDROID}
      CaminhoSom := TPath.Combine(TPath.GetDocumentsPath, 'beep_notificacao_padrao.mp3');
    {$ELSEIF DEFINED(IOS)}
      CaminhoSom := TPath.Combine(TPath.GetDocumentsPath, 'beep_notificacao_padrao.mp3');
    {$ELSE}
      CaminhoSom := TPath.Combine(ExtractFilePath(ParamStr(0)), 'assets\internal\beep_notificacao_padrao.mp3');
    {$ENDIF}

    if FileExists(CaminhoSom) then
    begin
        try
            MediaPlayer1.FileName := CaminhoSom;

            if MediaPlayer1.State = TMediaState.Playing then
                MediaPlayer1.Stop;

            MediaPlayer1.CurrentTime := 0;
            MediaPlayer1.Play;
        except

        end;
    end;
end;

end.
