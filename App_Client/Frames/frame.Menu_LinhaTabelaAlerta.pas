unit frame.Menu_LinhaTabelaAlerta;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation;

type
  TFrameLinhaPlanilhaAlerta = class(TFrame)
    gplLinhaPlanilhaAlerta: TGridPanelLayout;
    recLinhaStatus: TRectangle;
    lbInfoStatus: TLabel;
    recLinhaDoc: TRectangle;
    lbInfoDoc: TLabel;
    recLinhaFuncMaq: TRectangle;
    lbFuncMaq: TLabel;
    recLinhaVencimento: TRectangle;
    lbInfoVencimento: TLabel;
    recLinhaVisualizar: TRectangle;
    lbBtnVisualizar: TLabel;
    Layout1: TLayout;
    layLinhaStatus: TLayout;
    recInfoLinhaStatus: TRectangle;
    pathStatus: TPath;
    lbInfoTipoDoc: TLabel;
    Layout2: TLayout;
    lbFuncaoFuncMaq: TLabel;
    recBtnVisualizar: TRectangle;
    recFundoLinha: TRectangle;
    recBtnDownload: TRectangle;
    pathDownload: TPath;
    recBtnAlterarDoc: TRectangle;
    pathBtnAlterar: TPath;
    procedure recBtnVisualizarClick(Sender: TObject);
    procedure recBtnDownloadClick(Sender: TObject);
    procedure recBtnAlterarDocClick(Sender: TObject);
  private
    procedure BaixarArquivo(const ACaminhoDestino: string);
    { Private declarations }
  public
    FEntidadeID: string;
    FAtivo: Boolean;
    FDocId: string;
    FNomeDoc: string;
    FNomeEntidade: string;
    procedure TipoStatus(Sender: TObject);
    { Public declarations }
  end;

implementation

uses
  uDesignSystem,
  modal.VisualizarDocumento,
  uParametros,
  uLoading,
  System.DateUtils,
  System.Math,
  System.IOUtils,
  IdHTTP,
  modal.AlterarDocumento,
  frame.Menu_Dashboard,
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


procedure TFrameLinhaPlanilhaAlerta.recBtnAlterarDocClick(Sender: TObject);
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
            if Self.Owner is TFrameMenuDashboard then
                TFrameMenuDashboard(Self.Owner).CarregarDados;
        end
    );
end;

procedure TFrameLinhaPlanilhaAlerta.recBtnDownloadClick(Sender: TObject);
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

procedure TFrameLinhaPlanilhaAlerta.BaixarArquivo(const ACaminhoDestino: string);
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

                    TThread.Synchronize(nil, procedure
                    begin
                        TLoading.Hide;
                        ShowMessage('Download concluído com sucesso!');
                    end);
                except
                    on E: Exception do
                    begin
                        TThread.Synchronize(nil, procedure
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

procedure TFrameLinhaPlanilhaAlerta.recBtnVisualizarClick(Sender: TObject);
var
  LModal: TFrameVisualizarDocumento;
begin
    LModal := TFrameVisualizarDocumento.Create(Self.Root.GetObject as TForm);
    LModal.Parent := Self.Root.GetObject as TForm;
    LModal.Align := TAlignLayout.Contents;

    LModal.AbrirModal(FDocId, FNomeDoc, FNomeEntidade);
end;

procedure TFrameLinhaPlanilhaAlerta.TipoStatus(Sender: TObject);
var
    vDataVencimento: TDateTime;
    vDiferencaDias: Integer;
    vData: string;
begin
    vData := lbInfoVencimento.Text;
    vDataVencimento := StrToDateDef(vData, Date);

    vDiferencaDias := Trunc(vDataVencimento) - Trunc(Date);

    // --- LÓGICA: A EXPIRAR ---
    if vDiferencaDias > 0 then
    begin
        recInfoLinhaStatus.Stroke.Color := TThemeColors.Yellow500;
        recInfoLinhaStatus.Fill.Color   := TThemeColors.Yellow100;
        lbInfoStatus.FontColor          := TThemeColors.Yellow600;
        pathStatus.Stroke.Color         := TThemeColors.Yellow600;
        pathStatus.Data.Data            := TThemeIcons.Expirando;

        if vDiferencaDias = 1 then
            lbInfoStatus.Text := 'A EXPIRAR EM 1 DIA'
        else
            lbInfoStatus.Text := Format('A EXPIRAR EM %d DIAS', [vDiferencaDias]);
    end

    // --- LÓGICA: EXPIRADO ---
    else
    begin
        recInfoLinhaStatus.Stroke.Color := TThemeColors.Red500;
        recInfoLinhaStatus.Fill.Color   := TThemeColors.Red100;
        lbInfoStatus.FontColor          := TThemeColors.Red600;
        pathStatus.Stroke.Color         := TThemeColors.Red600;
        pathStatus.Data.Data            := TThemeIcons.Expirado;

        if vDiferencaDias = 0 then
            lbInfoStatus.Text := 'EXPIRADO HOJE'
        else if vDiferencaDias = -1 then
            lbInfoStatus.Text := 'EXPIRADO HÁ 1 DIA'
        else
            lbInfoStatus.Text := Format('EXPIRADO HÁ %d DIAS', [Abs(vDiferencaDias)]);
    end;
end;

end.
