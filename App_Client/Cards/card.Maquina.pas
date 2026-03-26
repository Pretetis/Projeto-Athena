unit card.Maquina;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Effects, FMX.Layouts, System.Threading,
  System.Net.HttpClient, System.Net.HttpClientComponent, System.Net.URLClient,

  uParametros;
type
  TFrameCardMaquina = class(TFrame)
    recFundo: TRectangle;
    layCabecalho: TLayout;
    cirFotoMaquina: TCircle;
    lbTipo: TLabel;
    lbNomeMaquina: TLabel;
    layInfos: TLayout;
    lbChapa: TLabel;
    pathChapa: TPath;
    lbModelo: TLabel;
    pathSetor: TPath;
    layFinalMaior: TLayout;
    recFundoCinza: TRectangle;
    recBtnVisualizar: TRectangle;
    lbBtnVisualizar: TLabel;
    pathBtnVisualizar: TPath;
    ShadowEffect2: TShadowEffect;
    recBtnEditarFlutuante: TRectangle;
    Label1: TLabel;
    procedure recBtnEditarFlutuanteClick(Sender: TObject);
    procedure recBtnVisualizarClick(Sender: TObject);
    procedure recFundoMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
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
  uMenu, modal.AlterarMaquina;

{$R *.fmx}

procedure TFrameCardMaquina.CarregarFotoAssincrona(AIdMaquina: string);
begin
  FIdMaquina := AIdMaquina;

  TTask.Run(
    procedure
    var
      LHttp: TNetHTTPClient;
      LResponse: IHTTPResponse;
      LStream: TMemoryStream;
    begin
        LHttp := TNetHTTPClient.Create(nil);
        LStream := TMemoryStream.Create;
        try
            try
                LResponse := LHttp.Get(EndPoint + '/maquinas/' + AIdMaquina + '/foto', LStream);

                if LResponse.StatusCode = 200 then
                begin
                  LStream.Position := 0;

                  TThread.Synchronize(nil,
                    procedure
                    begin
                        if Assigned(Self) and Assigned(cirFotoMaquina) then
                        begin
                            cirFotoMaquina.Fill.Kind := TBrushKind.Bitmap;
                            cirFotoMaquina.Fill.Bitmap.Bitmap.LoadFromStream(LStream);
                            cirFotoMaquina.Fill.Bitmap.WrapMode := TWrapMode.TileStretch; // Ajusta pra não distorcer
                        end;
                    end);
                end;
            except
              // Ignora erros de rede silenciosamente para os cards não quebrarem
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
    fMenu.AbrirDocumentosFuncionario(lbNomeMaquina.Text);
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
