unit modal.VisualizarDocumento;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Layouts, FMX.Objects, FMX.Controls.Presentation, FMX.WebBrowser, FMX.ExtCtrls;

type
  TFrameVisualizarDocumento = class(TFrame)
    recOverlay: TRectangle;
    recFundo: TRectangle;
    layTitulo: TLayout;
    lbTitulo: TLabel;
    Line1: TLine;
    pathCancelarDocumento: TPath;
    layIconeValido: TLayout;
    pathIcone: TPath;
    recIcone: TRectangle;
    layFechar: TLayout;
    lbFuncMaq: TLabel;
    layDownload: TLayout;
    pathDownload: TPath;
    imgVisualizacao: TImageViewer;
    layOpcoes: TLayout;
    layOpcoesCentro: TLayout;
    layAnterior: TLayout;
    layPagina: TLayout;
    layProximo: TLayout;
    lbPagina: TLabel;
    cirProximo: TCircle;
    pathProximo: TPath;
    cirAnterior: TCircle;
    pathAnterior: TPath;
    procedure layFecharClick(Sender: TObject);
    procedure layDownloadClick(Sender: TObject);
    procedure layProximoClick(Sender: TObject);
    procedure layAnteriorClick(Sender: TObject);
  protected
    procedure Resize; override;
  private
    FDocId: string;
    FPageAtiva: Integer;
    procedure CarregarPagina(APagina: Integer);
    { Private declarations }
  public
    procedure AbrirModal(const ADocId, ANomeDoc, AEntidade: string);
    { Public declarations }
  end;

implementation

uses
  uParametros, IdHTTP, uMenu
  {$IFDEF MSWINDOWS} , Winapi.ShellAPI {$ENDIF}
  {$IFDEF ANDROID} , Androidapi.Helpers, Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.Net {$ENDIF};
  {$R *.fmx}

procedure TFrameVisualizarDocumento.Resize;
var
  LMargem20: Single;
begin
  inherited; // Garante que o comportamento padrão do frame seja executado

  if Assigned(recOverlay) and Assigned(recFundo) then
  begin
    // Calcula 20% da largura atual do recOverlay
    LMargem20 := recOverlay.Width * 0.20;

    // Aplica o valor nas margens esquerda e direita do recFundo
    recFundo.Margins.Left := LMargem20;
    recFundo.Margins.Right := LMargem20;
  end;
end;

procedure TFrameVisualizarDocumento.AbrirModal(const ADocId, ANomeDoc, AEntidade: string);
begin
    FDocId := ADocId;
    FPageAtiva := 1;
    lbTitulo.Text := ANomeDoc;
    lbFuncMaq.Text := AEntidade;

    fMenu.EfeitoBlur.Enabled := True;

    Self.Visible := True;
    Self.BringToFront;

    imgVisualizacao.Bitmap := nil;

    TThread.CreateAnonymousThread(
        procedure
        var
          LHttp: TIdHTTP;
          LStream: TMemoryStream;
        begin
            LHttp := TIdHTTP.Create(nil);
            LStream := TMemoryStream.Create;
            try
                LHttp.Request.BasicAuthentication := True;
                LHttp.Request.Username := UserName;
                LHttp.Request.Password := Password;

                try
                  LHttp.Get(EndPoint + '/documentos/' + FDocId + '/preview', LStream);
                  LStream.Position := 0;

                  TThread.Synchronize(nil,
                    procedure
                    begin
                        imgVisualizacao.Bitmap.LoadFromStream(LStream);
                    end);
                except

                end;
            finally
                LStream.Free;
                LHttp.Free;
            end;
        end).Start;
        CarregarPagina(FPageAtiva);
end;

procedure TFrameVisualizarDocumento.CarregarPagina(APagina: Integer);
begin
  lbPagina.Text := 'Página: ' + APagina.ToString;

  TThread.CreateAnonymousThread(
      procedure
      var LHttp: TIdHTTP; LStream: TMemoryStream;
      begin
          LHttp := TIdHTTP.Create(nil);
          LStream := TMemoryStream.Create;
          try
              LHttp.Request.BasicAuthentication := True;
              LHttp.Request.Username := UserName;
              LHttp.Request.Password := Password;

              LHttp.Get(EndPoint + '/documentos/' + FDocId + '/preview?page=' + APagina.ToString, LStream);
              LStream.Position := 0;

              TThread.Synchronize(nil, procedure begin
                  imgVisualizacao.Bitmap.LoadFromStream(LStream);
              end);
          finally
              LStream.Free; LHttp.Free;
          end;
      end).Start;
end;

procedure TFrameVisualizarDocumento.layAnteriorClick(Sender: TObject);
begin
    if FPageAtiva > 1 then
    begin
        Dec(FPageAtiva);
        CarregarPagina(FPageAtiva);
    end;
end;

procedure TFrameVisualizarDocumento.layDownloadClick(Sender: TObject);
var
    LUrlDownload: string;
begin
    LUrlDownload := EndPoint + '/documentos/' + FDocId + '/download?download=true';

    {$IFDEF MSWINDOWS}
    Winapi.ShellAPI.ShellExecute(0, 'open', PChar(LUrlDownload), nil, nil, 1);
    {$ENDIF}

    {$IFDEF ANDROID}
    TAndroidHelper.Context.startActivity(
      TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW,
      StrToJURI(LUrlDownload))
    );
    {$ENDIF}
end;

procedure TFrameVisualizarDocumento.layFecharClick(Sender: TObject);
begin
    fMenu.EfeitoBlur.Enabled := False;
    Self.Free;
end;

procedure TFrameVisualizarDocumento.layProximoClick(Sender: TObject);
begin
    Inc(FPageAtiva);
    CarregarPagina(FPageAtiva);
end;

end.
