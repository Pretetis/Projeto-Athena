unit frame.Documentos_LinhaTabelaDocumentos;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Layouts, uRequests;

type
  TFrameLinhaPlanilhaDocumento = class(TFrame)
    gplCabecalhoPlanilhaAlerta: TGridPanelLayout;
    recBtnAlterarDoc: TRectangle;
    pathBtnAlterar: TPath;
    recLinhaDoc: TLayout;
    lbInfoDoc: TLabel;
    lbInfoTipoDoc: TLabel;
    recLinhaFuncMaq: TRectangle;
    Layout2: TLayout;
    lbFuncMaq: TLabel;
    lbFuncaoFuncMaq: TLabel;
    recLinhaStatus: TRectangle;
    layLinhaStatus: TLayout;
    recInfoLinhaStatus: TRectangle;
    pathStatus: TPath;
    recLinhaVencimento: TRectangle;
    lbInfoVencimento: TLabel;
    recLinhaVisualizar: TRectangle;
    recBtnVisualizar: TRectangle;
    lbBtnVisualizar: TLabel;
    recBtnDownload: TRectangle;
    pathDownload: TPath;
    recFundoLinha: TRectangle;
    procedure FrameResize(Sender: TObject);
    procedure recBtnVisualizarClick(Sender: TObject);
    procedure recBtnDownloadClick(Sender: TObject);
    procedure recBtnAlterarDocClick(Sender: TObject);
  private
    procedure BaixarArquivo(const ACaminhoDestino: string);
    { Private declarations }
  public
    FDocId: string;
    FNomeDoc: string;
    FNomeEntidade: string;
    FAtivo: Boolean;
    FEntidadeId: string;
    procedure TipoStatus(Sender: TObject);
    procedure CarregarDados(ANomeDoc, ATipoDoc, AFuncMaq, AVencimento: string);
    procedure TipoAtivo(Sender: TObject);
    { Public declarations }
  end;

implementation

uses
  uDesignSystem, modal.VisualizarDocumento, uParametros,
  uLoading,
  System.DateUtils,
  System.Math,
  System.IOUtils,
  IdHTTP,
  modal.AlterarDocumento,
  frame.Documentos,
  // --- BIBLIOTECAS PARA WINDOWS ---
  {$IFDEF MSWINDOWS}
    Winapi.ShellAPI,
  {$ENDIF}
  // --- BIBLIOTECAS PARA ANDROID ---
  {$IFDEF ANDROID}
    Androidapi.Helpers,
    Androidapi.JNI.GraphicsContentViewText,
    Androidapi.JNI.Net,
  {$ENDIF}
  FMX.frame.PopUpToast;

{$R *.fmx}

procedure TFrameLinhaPlanilhaDocumento.FrameResize(Sender: TObject);
var
    LWidthTotal: Single;
begin
    LWidthTotal := Self.Width;
end;

procedure TFrameLinhaPlanilhaDocumento.recBtnAlterarDocClick(Sender: TObject);
var
    LModal: TFrameAlterarDocumento;
begin
    LModal := TFrameAlterarDocumento.Create(Self.Root.GetObject as TForm);
    LModal.Parent := Self.Root.GetObject as TForm;
    LModal.Align := TAlignLayout.Contents;
    LModal.BringToFront;

    LModal.AbrirModal(
        FDocId,
        lbInfoDoc.Text,
        lbInfoTipoDoc.Text,
        FEntidadeId,
        lbFuncMaq.Text,
        'funcionario',
        lbInfoVencimento.Text,
        FAtivo,
        procedure
        begin
            if Self.Owner is TFrameDocumentos then
                TFrameDocumentos(Self.Owner).BuscarDados;
        end
    );
end;

procedure TFrameLinhaPlanilhaDocumento.recBtnDownloadClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
begin
    {$IFDEF MSWINDOWS}
    SaveDialog := TSaveDialog.Create(nil);
    try
        SaveDialog.Title := 'Salvar Documento';
        SaveDialog.FileName := FNomeDoc + '.pdf';
        SaveDialog.Filter := 'Arquivos PDF|*.pdf|Imagens PNG|*.png|Imagens JPG|*.jpg';

        if SaveDialog.Execute then
        begin
            BaixarArquivo(SaveDialog.FileName);
        end;
    finally
        SaveDialog.Free;
    end;
    {$ENDIF}

    {$IFDEF ANDROID}
    recBtnVisualizarClick(Sender);
    {$ENDIF}
end;

procedure TFrameLinhaPlanilhaDocumento.BaixarArquivo(const ACaminhoDestino: string);
begin
    TLoading.Show(Self.Root.GetObject as TForm, 'Baixando arquivo...');

    TThread.CreateAnonymousThread(
        procedure
        var
          LHttp: TIdHTTP;
          LFileStream: TFileStream;
          LUrl: string;
        begin
            LUrl := EndPoint + '/documentos/' + FDocId + '/download?download=true';
            LHttp := TIdHTTP.Create(nil);
            LFileStream := TFileStream.Create(ACaminhoDestino, fmCreate);
            try
                try
                    LHttp.Request.BasicAuthentication := True;
                    LHttp.Request.Username := UserName;
                    LHttp.Request.Password := Password;

                    LHttp.Get(LUrl, LFileStream);

                    TThread.Synchronize(nil, procedure ()
                    begin
                        TLoading.Hide;
                        ShowMessage('Download concluído com sucesso!');
                    end);
                except
                    on E: Exception do
                    begin
                        TThread.Synchronize(nil, procedure ()
                        begin
                            TLoading.Hide;
                            ShowMessage('Erro ao baixar arquivo: ' + E.Message);
                        end);
                    end;
                end;
            finally
                LFileStream.Free;
                LHttp.Free;
            end;
        end).Start;
end;

procedure TFrameLinhaPlanilhaDocumento.recBtnVisualizarClick(Sender: TObject);
var
  LModal: TFrameVisualizarDocumento;
begin
    LModal := TFrameVisualizarDocumento.Create(Self.Root.GetObject as TForm);
    LModal.Parent := Self.Root.GetObject as TForm;
    LModal.Align := TAlignLayout.Contents;

    LModal.AbrirModal(FDocId, FNomeDoc, FNomeEntidade);
end;

procedure TFrameLinhaPlanilhaDocumento.TipoStatus(Sender: TObject);
var
    vDataVencimento: TDateTime;
    vDiferencaDias: Integer;
    vData: string;
begin
    vData := lbInfoVencimento.Text;
    vDataVencimento := StrToDateDef(vData, Date);

    vDiferencaDias := Trunc(vDataVencimento) - Trunc(Date);

    // --- LÓGICA: VALIDO ---
    if vDiferencaDias >= 31 then
    begin
        recInfoLinhaStatus.Stroke.Color := TThemeColors.Green400;
        recInfoLinhaStatus.Fill.Color   := TThemeColors.Green100;
        pathStatus.Stroke.Color         := TThemeColors.Green800;
        pathStatus.Data.Data            := TThemeIcons.Valido;
    end

    // --- LÓGICA: A EXPIRAR (FUTURO) ---
    else if (vDiferencaDias > 0) and (vDiferencaDias < 31) then
    begin
        recInfoLinhaStatus.Stroke.Color := TThemeColors.Yellow500;
        recInfoLinhaStatus.Fill.Color   := TThemeColors.Yellow100;
        pathStatus.Stroke.Color         := TThemeColors.Yellow600;
        pathStatus.Data.Data            := TThemeIcons.Expirando;
    end

    // --- LÓGICA: EXPIRADO (HOJE OU PASSADO) ---
    else if (vDiferencaDias <= 0) then
    begin
        recInfoLinhaStatus.Stroke.Color := TThemeColors.Red500;
        recInfoLinhaStatus.Fill.Color   := TThemeColors.Red100;
        pathStatus.Stroke.Color         := TThemeColors.Red600;
        pathStatus.Data.Data            := TThemeIcons.Expirado;;
    end;
end;

procedure TFrameLinhaPlanilhaDocumento.CarregarDados(ANomeDoc, ATipoDoc, AFuncMaq, AVencimento: string);
begin
    lbInfoDoc.Text := ANomeDoc;
    lbInfoTipoDoc.Text := ATipoDoc;
    lbFuncMaq.Text := AFuncMaq;

    try
        lbInfoVencimento.Text := FormatDateTime('dd/mm/yyyy', ISO8601ToDate(AVencimento));
    except
        lbInfoVencimento.Text := AVencimento;
    end;

    TipoStatus(Self);
end;

procedure TFrameLinhaPlanilhaDocumento.TipoAtivo(Sender: TObject);
begin
    // --- LÓGICA: ATIVO ---
    if fAtivo = false then
    begin
        lbInfoDoc.TextSettings.FontColor := TThemeColors.Red600;
    end;
end;


end.
