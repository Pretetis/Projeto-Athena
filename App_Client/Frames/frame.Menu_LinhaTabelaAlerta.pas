unit frame.Menu_LinhaTabelaAlerta;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Objects, FMX.Layouts, FMX.Controls.Presentation;

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
  private
    { Private declarations }
  public
    procedure TipoStatus(Sender: TObject);
    { Public declarations }
  end;

implementation

uses
    uDesignSystem, System.DateUtils, System.Math;

{$R *.fmx}


procedure TFrameLinhaPlanilhaAlerta.TipoStatus(Sender: TObject);
var
    vDataVencimento: TDateTime;
    vDiferencaDias: Integer;
    vData: string;
begin
    vData := lbInfoVencimento.Text;
    vDataVencimento := StrToDateDef(vData, Date);

    vDiferencaDias := Trunc(vDataVencimento) - Trunc(Date);

    // --- LÓGICA: A EXPIRAR (FUTURO) ---
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

    // --- LÓGICA: EXPIRADO (HOJE OU PASSADO) ---
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
