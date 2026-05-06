unit card.Funcionario;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Effects, FMX.Layouts, System.Threading,
  System.Net.HttpClient, System.Net.HttpClientComponent, System.Net.URLClient,

  uParametros, FMX.Filter.Effects, FMX.ImgList;

type
  TFrameCardFuncionario = class(TFrame)
    recFundo: TRectangle;
    lbNomeFuncionario: TLabel;
    lbCargo: TLabel;
    layCabecalho: TLayout;
    layInfos: TLayout;
    layFinalMaior: TLayout;
    recFundoCinza: TRectangle;
    recBtnVisualizar: TRectangle;
    lbBtnVisualizar: TLabel;
    ShadowEffect2: TShadowEffect;
    cirFotoFuncionario: TCircle;
    lbChapa: TLabel;
    lbSetor: TLabel;
    recBtnEditarFlutuante: TRectangle;
    Label1: TLabel;
    gpSetor: TGlyph;
    FillRGBEffect1: TFillRGBEffect;
    gpChapa: TGlyph;
    FillRGBEffect2: TFillRGBEffect;
    gbVisualizar: TGlyph;
    FillRGBEffect3: TFillRGBEffect;
    procedure recBtnVisualizarClick(Sender: TObject);
    procedure recFundoMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure recBtnEditarFlutuanteClick(Sender: TObject);
    procedure recFundoGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
  private
    FIdFuncionario: string;
    { Private declarations }
  public
    FOnRecarregarLista: TProc;
    FIsAtivo: Boolean;
    procedure CarregarFotoAssincrona(AIdFuncionario: string);
    { Public declarations }
  end;

implementation

uses
  uMenu, uMenuMobile, modal.AlterarFuncionario, IdHTTP;

{$R *.fmx}

procedure TFrameCardFuncionario.CarregarFotoAssincrona(AIdFuncionario: string);
begin
  FIdFuncionario := AIdFuncionario;

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
          if Assigned(Self) and Assigned(cirFotoFuncionario) then
          begin
            try
              ResStream := TResourceStream.Create(MainInstance, 'AVATAR_PADRAO', RT_RCDATA);
              try
                cirFotoFuncionario.Fill.Kind := TBrushKind.Bitmap;
                cirFotoFuncionario.Fill.Bitmap.Bitmap.LoadFromStream(ResStream);
                cirFotoFuncionario.Fill.Bitmap.WrapMode := TWrapMode.TileStretch;
                cirFotoFuncionario.Repaint;
              finally
                ResStream.Free;
              end;
            except
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
          LHttp.Get(EndPoint + '/funcionarios/' + AIdFuncionario + '/foto', LStream);

          LStream.Position := 0;

          TThread.Synchronize(nil,
            procedure
            begin
              if Assigned(Self) and Assigned(cirFotoFuncionario) then
              begin
                cirFotoFuncionario.Fill.Kind := TBrushKind.Bitmap;
                cirFotoFuncionario.Fill.Bitmap.Bitmap.LoadFromStream(LStream);
                cirFotoFuncionario.Fill.Bitmap.WrapMode := TWrapMode.TileStretch;
                cirFotoFuncionario.Repaint;
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

procedure TFrameCardFuncionario.recBtnEditarFlutuanteClick(Sender: TObject);
var
  LModal: TFrameAlterarFuncionario;
begin
  recBtnEditarFlutuante.Visible := False;
  LModal := TFrameAlterarFuncionario.Create(Self);
  LModal.Parent := Application.MainForm;
  LModal.Align := TAlignLayout.Contents;

  LModal.AbrirModal(
    FIdFuncionario,
    lbNomeFuncionario.Text,
    lbCargo.Text,
    lbSetor.Text,
    lbChapa.Text,
    FIsAtivo,
    FOnRecarregarLista
  );

  LModal.BringToFront;
end;

procedure TFrameCardFuncionario.recBtnVisualizarClick(Sender: TObject);
begin
    {$IFDEF ANDROID}
    fMenuMobile.AbrirDocumentosFuncionario(lbNomeFuncionario.Text);
    {$ELSEIF defined(MSWINDOWS)}
    fMenu.AbrirDocumentosFuncionario(lbNomeFuncionario.Text);
    {$ENDIF}
end;

procedure TFrameCardFuncionario.recFundoGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
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

procedure TFrameCardFuncionario.recFundoMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
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
