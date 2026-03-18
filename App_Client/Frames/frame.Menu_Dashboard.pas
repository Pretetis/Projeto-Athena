unit frame.Menu_Dashboard;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Layouts, FMX.Objects, FMX.Effects;

type
  TFrame1 = class(TFrame)
    recFundo: TRectangle;
    layTitulo: TLayout;
    lbSubTitulo: TLabel;
    lbTitulo: TLabel;
    LayDadosDocs: TLayout;
    GridPanelLayout1: TGridPanelLayout;
    recDocsValidos: TRectangle;
    lbTituloValido: TLabel;
    lbInfoValido: TLabel;
    layIconeValido: TLayout;
    cirIconeValido: TCircle;
    ShadowAzul: TShadowEffect;
    recCorValido: TRectangle;
    recQntdValido: TRectangle;
    Path1: TPath;
    recDocumentosExpirados: TRectangle;
    recCorExpirado: TRectangle;
    layIconeExpirado: TLayout;
    cirIconeExpirado: TCircle;
    pathExpirado: TPath;
    recQntdExpirado: TRectangle;
    lbTituloExpirado: TLabel;
    lbInfoExpirado: TLabel;
    shadowVermelho: TShadowEffect;
    recDocumentosExpirando: TRectangle;
    recCorExpirando: TRectangle;
    layIconeExpirando: TLayout;
    cirExpirando: TCircle;
    pathExpirando: TPath;
    recQntdExpirando: TRectangle;
    lbTituloExpirando: TLabel;
    lbInfoExpirando: TLabel;
    shadowAmarelo: TShadowEffect;
    recPlanilhaAlertas: TRectangle;
    ShadowEffect1: TShadowEffect;
    layTituloPlanilhaAlerta: TLayout;
    lbTituloPlanilhaAlerta: TLabel;
    Layout1: TLayout;
    GridPanelLayout2: TGridPanelLayout;
    VertScrollBox1: TVertScrollBox;
    Rectangle1: TRectangle;
    Rectangle2: TRectangle;
    lbStatus: TLabel;
    Rectangle3: TRectangle;
    Label2: TLabel;
    Rectangle4: TRectangle;
    Label3: TLabel;
    Rectangle5: TRectangle;
    Label4: TLabel;
    Rectangle6: TRectangle;
    Label5: TLabel;
    Label1: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

end.
