unit card.Funcionario;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Effects, FMX.Layouts, System.Threading,
  System.Net.HttpClient, System.Net.HttpClientComponent, System.Net.URLClient,

  uParametros;

type
  TFrameCardFuncionario = class(TFrame)
    recFundo: TRectangle;
    lbNomeFuncionario: TLabel;
    lbCargo: TLabel;
    lbMatricula: TLabel;
    layCabecalho: TLayout;
    layInfos: TLayout;
    layFinalMaior: TLayout;
    recFundoCinza: TRectangle;
    recBtnVisualizar: TRectangle;
    pathBtnVisualizar: TPath;
    lbBtnVisualizar: TLabel;
    ShadowEffect2: TShadowEffect;
    cirFotoFuncionario: TCircle;
    lbChapa: TLabel;
    pathChapa: TPath;
    lbSetor: TLabel;
    pathSetor: TPath;
    procedure recBtnVisualizarClick(Sender: TObject);
    procedure layCabecalhoClick(Sender: TObject);
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
  uMenu, modal.AlterarFuncionario;

{$R *.fmx}

procedure TFrameCardFuncionario.CarregarFotoAssincrona(AIdFuncionario: string);
begin
  FIdFuncionario := AIdFuncionario;

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
                LResponse := LHttp.Get(EndPoint + '/funcionarios/' + AIdFuncionario + '/foto', LStream);

                if LResponse.StatusCode = 200 then
                begin
                  LStream.Position := 0;

                  TThread.Synchronize(nil,
                    procedure
                    begin
                        if Assigned(Self) and Assigned(cirFotoFuncionario) then
                        begin
                            cirFotoFuncionario.Fill.Kind := TBrushKind.Bitmap;
                            cirFotoFuncionario.Fill.Bitmap.Bitmap.LoadFromStream(LStream);
                            cirFotoFuncionario.Fill.Bitmap.WrapMode := TWrapMode.TileStretch; // Ajusta pra não distorcer
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

procedure TFrameCardFuncionario.layCabecalhoClick(Sender: TObject);
var
  LModal: TFrameAlterarFuncionario;
begin
  LModal := TFrameAlterarFuncionario.Create(Self);
  LModal.Parent := Application.MainForm;
  LModal.Align := TAlignLayout.Contents;

  // Passa os dados e a função genérica de recarregar
  LModal.AbrirModal(
    FIdFuncionario,
    lbNomeFuncionario.Text,
    lbCargo.Text,
    lbSetor.Text,
    lbChapa.Text,
    FIsAtivo,          // Usa a variável que salvamos no Card
    FOnRecarregarLista // Passa o gatilho direto para o modal!
  );

  LModal.BringToFront;
end;

procedure TFrameCardFuncionario.recBtnVisualizarClick(Sender: TObject);
begin
    fMenu.AbrirDocumentosFuncionario(lbNomeFuncionario.Text);
end;

end.
