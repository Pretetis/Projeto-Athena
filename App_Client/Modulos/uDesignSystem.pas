unit uDesignSystem;

interface

uses
  System.SysUtils, System.Classes, System.UITypes, FMX.Graphics, FMX.Effects,
  FMX.Types, System.ImageList, FMX.ImgList;

type
  // =======================================================================
  // 1. SEU DESIGN SYSTEM (CÓDIGO)
  // =======================================================================

  /// <summary>
  /// Paleta de Cores do Sistema
  /// </summary>
  TThemeColors = record
  public const
    // 1. Cores da Marca (Indigo)
    Indigo50  = $FFEEF2FF;
    Indigo100 = $FFE0E7FF;
    Indigo600 = $FF4F46E5;
    Indigo700 = $FF4338CA;

    // 2. Cores Neutras (Slate)
    White     = $FFFFFFFF;
    Slate50   = $FFF8FAFC;
    Slate100  = $FFF1F5F9;
    Slate200  = $FFE2E8F0;
    Slate300  = $FFCBD5E1;
    Slate400  = $FF94A3B8;
    Slate500  = $FF64748B;
    Slate600  = $FF475569;
    Slate700  = $FF334155;
    Slate800  = $FF1E293B;
    Slate900  = $FF0F172A;

    // 3. Cores de Status (Semânticas)
    Green100  = $FFDCFCE7;
    Green400  = $FF4ADE80;
    Green800  = $FF166534;

    Yellow50  = $FFFEFCE8;
    Yellow100 = $FFFEF9C3;
    Yellow500 = $FFEAB308;
    Yellow600 = $FFCA8A04;
    Yellow800 = $FF854D0E;

    Red50     = $FFFEF2F2;
    Red100    = $FFFEE2E2;
    Red500    = $FFEF4444;
    Red600    = $FFDC2626;
    Red800    = $FF991B1B;
  end;

  /// <summary>
  /// Elementos de UI: Formas, Sombras e Tipografia
  /// </summary>
  TThemeUI = class
  public const
    RadiusButton = 8.0;
    RadiusCard   = 16.0;
    RadiusAvatar = 9999.0;
  public
    class procedure ApplyFontH1(AFont: TFont; ASmallerScreen: Boolean = False);
    class procedure ApplyFontH2(AFont: TFont);
    class procedure ApplyFontH3(AFont: TFont);
    class procedure ApplyFontBase(AFont: TFont);
    class procedure ApplyFontSecondary(AFont: TFont);
    class procedure ApplyCardShadow(AShadow: TShadowEffect);
    class procedure ApplyModalShadow(AShadow: TShadowEffect);
  end;

  TDesignSystem = class(TDataModule)
    ilIconesLinhas: TImageList;
    ilIconesSimples: TImageList;
    ilBotoes: TImageList;
  private
    { Private declarations }
  public
    { Public declarations }
  end;
//
var
  DesignSystem: TDesignSystem;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

{ TThemeUI }

class procedure TThemeUI.ApplyFontH1(AFont: TFont; ASmallerScreen: Boolean);
begin
  AFont.Family := 'Roboto';
  AFont.Style := [TFontStyle.fsBold];
end;

class procedure TThemeUI.ApplyFontH2(AFont: TFont);
begin
  AFont.Family := 'Roboto';
  AFont.Size := 24.0;
  AFont.Style := [TFontStyle.fsBold];
end;

class procedure TThemeUI.ApplyFontH3(AFont: TFont);
begin
  AFont.Family := 'Roboto';
  AFont.Size := 18.0;
  AFont.Style := [TFontStyle.fsBold];
end;

class procedure TThemeUI.ApplyFontBase(AFont: TFont);
begin
  AFont.Family := 'Roboto';
  AFont.Size := 14.0;
  AFont.Style := [];
end;

class procedure TThemeUI.ApplyFontSecondary(AFont: TFont);
begin
  AFont.Family := 'Roboto';
  AFont.Size := 14.0;
  AFont.Style := [];
end;

class procedure TThemeUI.ApplyCardShadow(AShadow: TShadowEffect);
begin
  AShadow.ShadowColor := TAlphaColorRec.Black;
  AShadow.Opacity := 0.05;
  AShadow.Softness := 4.0;
  AShadow.Distance := 1.0;
  AShadow.Direction := 90.0;
end;

class procedure TThemeUI.ApplyModalShadow(AShadow: TShadowEffect);
begin
  AShadow.ShadowColor := TAlphaColorRec.Black;
  AShadow.Opacity := 0.15;
  AShadow.Softness := 20.0;
  AShadow.Distance := 10.0;
  AShadow.Direction := 90.0;
end;

end.
