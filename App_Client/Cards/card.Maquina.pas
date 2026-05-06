unit card.Maquina;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Effects, FMX.Layouts, System.Threading,
  System.Net.HttpClient, System.Net.HttpClientComponent, System.Net.URLClient,

  uParametros, FMX.Filter.Effects, FMX.ImgList;
type
  TFrameCardMaquina = class(TFrame)
    recFundo: TRectangle;
    layCabecalho: TLayout;
    cirFotoMaquina: TCircle;
    lbTipo: TLabel;
    lbNomeMaquina: TLabel;
    layInfos: TLayout;
    lbChapa: TLabel;
    lbModelo: TLabel;
    layFinalMaior: TLayout;
    recFundoCinza: TRectangle;
    recBtnVisualizar: TRectangle;
    lbBtnVisualizar: TLabel;
    ShadowEffect2: TShadowEffect;
    recBtnEditarFlutuante: TRectangle;
    Label1: TLabel;
    gpChapa: TGlyph;
    FillRGBEffect2: TFillRGBEffect;
    gpSetor: TGlyph;
    FillRGBEffect1: TFillRGBEffect;
    gbVisualizar: TGlyph;
    FillRGBEffect3: TFillRGBEffect;
    procedure recBtnEditarFlutuanteClick(Sender: TObject);
    procedure recBtnVisualizarClick(Sender: TObject);
    procedure recFundoMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure recFundoGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
  private
    FIdMaquina: string;
    { Private declarations }
  public
    FOnRecarregarLista: TProc;
    FIsAtivo: Boolean;
    procedure CarregarFotoAssincrona(AIdMaquina: string);
    { Public declarations }
  end;

implementation

uses
  uMenu, uMenuMobile, modal.AlterarMaquina, IdHTTP;

{$R *.fmx}

procedure TFrameCardMaquina.CarregarFotoAssincrona(AIdMaquina: string);
begin
  FIdMaquina := AIdMaquina;

  TTask.Run(
    procedure
    var
      LHttp: TIdHTTP;
      LStream: TMemoryStream;

      procedure AplicarAvatarPadrao;
      begin
        TThread.Synchronize(nil, procedure
        var
          ResStream: TResourceStream;
        begin
          if Assigned(Self) and Assigned(cirFotoMaquina) then
          begin
            try
              ResStream := TResourceStream.Create(MainInstance, 'MAQUINA_PADRAO', RT_RCDATA);
              try
                cirFotoMaquina.Fill.Kind := TBrushKind.Bitmap;
                cirFotoMaquina.Fill.Bitmap.Bitmap.LoadFromStream(ResStream);
                cirFotoMaquina.Fill.Bitmap.WrapMode := TWrapMode.TileStretch;
                cirFotoMaquina.Repaint;
              finally
                ResStream.Free;
              end;
            except
              cirFotoMaquina.Fill.Kind := TBrushKind.Solid;
              cirFotoMaquina.Fill.Color := TAlphaColors.Lightslategray;
              cirFotoMaquina.Repaint;
            end;
          end;
        end);
      end;

    begin
      LHttp := TIdHTTP.Create(nil);
      LStream := TMemoryStream.Create;
      try
        LHttp.Request.BasicAuthentication := True;
        LHttp.Request.Username := UserName;
        LHttp.Request.Password := Password;

        try
          LHttp.Get(EndPoint + '/maquinas/' + AIdMaquina + '/foto', LStream);

          LStream.Position := 0;

          TThread.Synchronize(nil,
            procedure
            begin
              if Assigned(Self) and Assigned(cirFotoMaquina) then
              begin
                cirFotoMaquina.Fill.Kind := TBrushKind.Bitmap;
                cirFotoMaquina.Fill.Bitmap.Bitmap.LoadFromStream(LStream);
                cirFotoMaquina.Fill.Bitmap.WrapMode := TWrapMode.TileStretch;
                cirFotoMaquina.Repaint;
              end;
            end);
        except
          AplicarAvatarPadrao;
        end;
      finally
        LStream.Free;
        LHttp.Free;
      end;
    end);
end;



procedure TFrameCardMaquina.recBtnEditarFlutuanteClick(Sender: TObject);
var
  LModal: TFrameModalAlterarMaquina;
begin
  recBtnEditarFlutuante.Visible := False;
  LModal := TFrameModalAlterarMaquina.Create(Self);
  LModal.Parent := Application.MainForm;
  LModal.Align := TAlignLayout.Contents;

  LModal.AbrirModal(
    FIdMaquina,
    lbNomeMaquina.Text,
    lbTipo.Text,
    lbModelo.Text,
    lbChapa.Text,
    FIsAtivo,
    FOnRecarregarLista
  );

  LModal.BringToFront;
end;

procedure TFrameCardMaquina.recBtnVisualizarClick(Sender: TObject);
begin
    {$IFDEF ANDROID}
    fMenuMobile.AbrirDocumentosFuncionario(lbNomeMaquina.Text);
    {$ELSEIF defined(MSWINDOWS)}
    fMenu.AbrirDocumentosFuncionario(lbNomeMaquina.Text);
    {$ENDIF}
end;

procedure TFrameCardMaquina.recFundoGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
begin
  if EventInfo.GestureID = igiLongTap then
  begin
    recBtnEditarFlutuante.Position.X := EventInfo.Location.X;
    recBtnEditarFlutuante.Position.Y := EventInfo.Location.Y;

    recBtnEditarFlutuante.BringToFront;
    recBtnEditarFlutuante.Visible := True;

    Handled := True;
  end;
end;

procedure TFrameCardMaquina.recFundoMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
    if Button = TMouseButton.mbRight then
    begin
        recBtnEditarFlutuante.Position.X := X;
        recBtnEditarFlutuante.Position.Y := Y;

        recBtnEditarFlutuante.BringToFront;
        recBtnEditarFlutuante.Visible := True;
    end

    else if Button = TMouseButton.mbLeft then
    begin
        recBtnEditarFlutuante.Visible := False;
    end;
end;



end.
