unit modal.VisualizarDocumento;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Objects, FMX.Controls.Presentation, FMX.WebBrowser, FMX.ExtCtrls, FMX.ImgList, FMX.Effects, FMX.Filter.Effects;

type
  TFrameVisualizarDocumento = class(TFrame)
    recOverlay: TRectangle;
    recFundo: TRectangle;
    layTitulo: TLayout;
    lbTitulo: TLabel;
    Line1: TLine;
    layIconeValido: TLayout;
    pathIcone: TPath;
    recIcone: TRectangle;
    layFechar: TLayout;
    lbFuncMaq: TLabel;
    layDownload: TLayout;
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
    imgFechar: TImage;
    FillRGBEffect1: TFillRGBEffect;
    gpDownload: TGlyph;
    FillRGBEffect2: TFillRGBEffect;
    Image1: TImage;
    FillRGBEffect3: TFillRGBEffect;
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
  uParametros, IdHTTP, uMenu, uTelaUtils, System.IOUtils
  {$IFDEF MSWINDOWS} , Winapi.ShellAPI {$ENDIF}
  // Adicionamos JNIBridge e JavaTypes aqui para o Delphi entender os objetos do Java
  {$IFDEF ANDROID} , Androidapi.Helpers, Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.Net, Androidapi.JNI.Os, Androidapi.JNIBridge, Androidapi.JNI.JavaTypes {$ENDIF};

// =============================================================================
// TRADUTORES MANUAIS DO STRICT MODE PARA DELPHI 10.3 RIO
// =============================================================================
{$IFDEF ANDROID}
type
  JMyStrictMode_VmPolicy = interface;
  JMyStrictMode_VmPolicy_Builder = interface;

  JMyStrictMode_VmPolicyClass = interface(JObjectClass)
    ['{B636184C-8F74-4C5C-9A5A-1EE0BA7DBDCF}']
  end;
  [JavaSignature('android/os/StrictMode$VmPolicy')]
  JMyStrictMode_VmPolicy = interface(JObject)
    ['{DDB1F50A-A3E5-46F2-A5E8-DDEE3E6E298B}']
  end;
  TJMyStrictMode_VmPolicy = class(TJavaGenericImport<JMyStrictMode_VmPolicyClass, JMyStrictMode_VmPolicy>) end;

  JMyStrictMode_VmPolicy_BuilderClass = interface(JObjectClass)
    ['{B9FA0C5C-EFA7-4FEA-AA50-D7E50DB17D6E}']
    function init: JMyStrictMode_VmPolicy_Builder; cdecl;
  end;
  [JavaSignature('android/os/StrictMode$VmPolicy$Builder')]
  JMyStrictMode_VmPolicy_Builder = interface(JObject)
    ['{6502DBDD-BFBB-47FC-AE67-D85038F61CEB}']
    function build: JMyStrictMode_VmPolicy; cdecl;
  end;
  TJMyStrictMode_VmPolicy_Builder = class(TJavaGenericImport<JMyStrictMode_VmPolicy_BuilderClass, JMyStrictMode_VmPolicy_Builder>) end;

  JMyStrictModeClass = interface(JObjectClass)
    ['{860A3F1F-FA40-4DFB-8DBA-0D5BDC278351}']
    procedure setVmPolicy(policy: JMyStrictMode_VmPolicy); cdecl;
  end;
  [JavaSignature('android/os/StrictMode')]
  JMyStrictMode = interface(JObject)
    ['{08BC0CFA-A8A2-402E-A5DD-A4AC707928AA}']
  end;
  TJMyStrictMode = class(TJavaGenericImport<JMyStrictModeClass, JMyStrictMode>) end;
{$ENDIF}
// =============================================================================

{$R *.fmx}

procedure TFrameVisualizarDocumento.Resize;
var
  LMargem: Single;
begin
    inherited;

    if Assigned(recOverlay) and Assigned(recFundo) then
    begin
        {$IFDEF ANDROID}
            LMargem := recOverlay.Width * 0.04;
        {$ELSE}
            LMargem := recOverlay.Width * 0.20;
        {$ENDIF}

        recFundo.Margins.Left  := LMargem;
        recFundo.Margins.Right := LMargem;
    end;
end;

procedure TFrameVisualizarDocumento.AbrirModal(const ADocId, ANomeDoc, AEntidade: string);
begin
    FDocId := ADocId;
    FPageAtiva := 1;
    lbTitulo.Text := ANomeDoc;
    lbFuncMaq.Text := AEntidade;

    AlterarBlurPai(Self, True);

    Self.Visible := True;
    Self.BringToFront;
    imgVisualizacao.Bitmap := nil;

    CarregarPagina(FPageAtiva);
end;

procedure TFrameVisualizarDocumento.CarregarPagina(APagina: Integer);
var
    LPathLocal: string;
begin
    lbPagina.Text := 'Página: ' + APagina.ToString;

    // 1. Monta o caminho de onde a imagem deveria estar salva offline
    LPathLocal := System.IOUtils.TPath.Combine(System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetDocumentsPath, 'AthenaDocs'),
                                'Doc_' + FDocId + '_pg' + APagina.ToString + '.jpg');

    // 2. VERIFICAÇÃO OFFLINE: O arquivo existe no tablet/celular?
    if System.IOUtils.TFile.Exists(LPathLocal) then
    begin
        // Lê a imagem direto do armazenamento (rápido e offline!)
        TThread.ForceQueue(nil, procedure
        begin
          imgVisualizacao.Bitmap.LoadFromFile(LPathLocal);
        end);
    end
    else
    begin
      // 3. VERIFICAÇÃO ONLINE: Não tem offline, então busca da API Node.js
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
                    LHttp.Get(EndPoint + '/documentos/' + FDocId + '/preview?page=' + APagina.ToString, LStream);
                    LStream.Position := 0;

                    TThread.Synchronize(nil, procedure
                    begin
                        imgVisualizacao.Bitmap.LoadFromStream(LStream);
                    end);
                except
                  // Se der erro aqui (ex: sem net), podemos colocar um toast: "Você está sem internet e este doc não foi baixado."
                end;
            finally
                LStream.Free;
                LHttp.Free;
            end;
        end).Start;
    end;
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
    AlterarBlurPai(Self, False);
    Self.DisposeOf;
end;

procedure TFrameVisualizarDocumento.layProximoClick(Sender: TObject);
begin
    Inc(FPageAtiva);
    CarregarPagina(FPageAtiva);
end;

end.
