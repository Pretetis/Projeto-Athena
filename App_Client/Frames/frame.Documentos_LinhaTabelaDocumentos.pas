unit frame.Documentos_LinhaTabelaDocumentos;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Objects, FMX.Controls.Presentation, FMX.Layouts;

type
  TFrameLinhaPlanilhaDocumento = class(TFrame)
    Layout3: TLayout;
    recBtnCancelarDoc: TRectangle;
    pathCancelar: TPath;
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
    procedure FrameResize(Sender: TObject);
  private

    { Private declarations }
  public
    procedure TipoStatus(Sender: TObject);
    procedure CarregarDados(ANomeDoc, ATipoDoc, AFuncMaq, AVencimento: string);
    { Public declarations }
  end;

implementation

uses
    uDesignSystem, System.DateUtils, System.Math;

{$R *.fmx}

procedure TFrameLinhaPlanilhaDocumento.FrameResize(Sender: TObject);
var
  LWidthTotal: Single;
begin
  // Pega a largura total disponível na linha
  LWidthTotal := Self.Width;

  // Define a largura de cada coluna multiplicando por 0.X (onde 0.10 = 10%)
  // Ajuste as porcentagens conforme o seu layout visual:

  recLinhaStatus.Width     := LWidthTotal * 0.09; // 8% para o ícone
  recLinhaDoc.Width        := LWidthTotal * 0.20; // 32% para o Nome do Documento
  recLinhaFuncMaq.Width    := LWidthTotal * 0.20; // 25% para o Func/Máquina
  recLinhaVencimento.Width := LWidthTotal * 0.20; // 15% para a Data
  recLinhaVisualizar.Width := LWidthTotal * 0.20; //

  // A última coluna (recLinhaVisualizar) não precisa de cálculo
  // pois está com Align := Client, então ela vai engolir os 20% restantes automaticamente.
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
        pathStatus.Data.Data            := TThemeIcons.Expirando;
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

  // Tratar a data vinda do Node (padrão ISO) para formato amigável BR
  try
    lbInfoVencimento.Text := FormatDateTime('dd/mm/yyyy', ISO8601ToDate(AVencimento));
  except
    lbInfoVencimento.Text := AVencimento; // Fallback se não vier no formato ISO
  end;

  // Chama a sua lógica já existente para pintar as cores corretas
  TipoStatus(Self);
end;

end.
