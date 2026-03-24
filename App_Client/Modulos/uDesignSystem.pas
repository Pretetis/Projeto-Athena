unit uDesignSystem;

interface

uses
  System.UITypes, FMX.Graphics, FMX.Effects, FMX.Types, System.Classes;

type
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
    // Válido / Sucesso (Verde)
    Green100  = $FFDCFCE7;
    Green400  = $FF4ADE80;
    Green800  = $FF166534;

    // A Expirar / Atenção (Amarelo)
    Yellow50  = $FFFEFCE8;
    Yellow100 = $FFFEF9C3;
    Yellow500 = $FFEAB308;
    Yellow600 = $FFCA8A04;
    Yellow800 = $FF854D0E;

    // Expirado / Crítico (Vermelho)
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
    // Arredondamento de Bordas (Border Radius)
    RadiusButton = 8.0;
    RadiusCard   = 16.0;
    RadiusAvatar = 9999.0;
  public
    // Métodos utilitários para aplicar Estilos
    class procedure ApplyFontH1(AFont: TFont; ASmallerScreen: Boolean = False);
    class procedure ApplyFontH2(AFont: TFont);
    class procedure ApplyFontH3(AFont: TFont);
    class procedure ApplyFontBase(AFont: TFont);
    class procedure ApplyFontSecondary(AFont: TFont);

    // Sombras (TShadowEffect)
    class procedure ApplyCardShadow(AShadow: TShadowEffect);
    class procedure ApplyModalShadow(AShadow: TShadowEffect);
  end;

  /// Banco de Ícones (SVG Paths)
  /// </summary>
  TThemeIcons = record
  public const
    {$REGION ' SVGs de Status '}
    // Ícone de Alerta / A Expirar
    Expirando = 'M21.73,17.5 L13.73,3.5 A2,2 0 0 0 10.25,3.5 L2.25,17.5 ' +
                'A2,2 0 0 0 4,20.5 H20 A2,2 0 0 0 21.73,17.5 M12,8.5 V12.5 M12,16.5 H12.01';

    Expirado  = 'M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 ' +
                '13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 ' +
                '0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z M12 8v4 M12 16h.01';

    Valido    = 'M 6 22 a 2 2 0 0 1 -2 -2 V 4 a 2 2 0 0 1 2 -2 h 8 a 2.4 2.4 ' +
                '0 0 1 1.704 0.706 l 3.588 3.588 A 2.4 2.4 0 0 1 20 8 v 12 a 2 2 0 0 1 -2 2 z ' +
                'M 14 2 v 5 a 1 1 0 0 0 1 1 h 5 M 9 15 l 2 2 l 4 -4';

    Download  = 'M0,0 M24,24 M12,15 L12,3 M21,15 L21,19 C21,20.1045703887939 ' +
                '20.1045703887939,21 19,21 L5,21 C3.89543056488037,21 3,20.1045703887939 ' +
                '3,19 L3,15 M7,10 L12,15 L17,10';

    Cancelar  = 'M0,0 M24,24 M20,4 L4,20 M4,4 L20,20';

    Dots      = 'M0,0 M24,24 M 11,12 A 1,1 0 1,0 13,12 A 1,1 0 1,0 11,12 M 18,12 A 1,1 0 1,0 20,12 ' +
                'A 1,1 0 1,0 18,12 M 4,12 A 1,1 0 1,0 6,12 A 1,1 0 1,0 4,12';
    {$ENDREGION}
  end;


implementation

{ TThemeUI }

// --- TIPOGRAFIA ---

class procedure TThemeUI.ApplyFontH1(AFont: TFont; ASmallerScreen: Boolean);
begin
  AFont.Family := 'Roboto'; // Fallback para Inter
  //AFont.Size := If Then(ASmallerScreen, 24.0, 30.0);
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
  AFont.Style := []; // Regular
end;

class procedure TThemeUI.ApplyFontSecondary(AFont: TFont);
begin
  AFont.Family := 'Roboto';
  AFont.Size := 14.0;
  AFont.Style := [];
end;

// --- SOMBRAS ---

class procedure TThemeUI.ApplyCardShadow(AShadow: TShadowEffect);
begin
  AShadow.ShadowColor := TAlphaColorRec.Black;
  AShadow.Opacity := 0.05;
  AShadow.Softness := 4.0;
  // No FMX, o Offset Y é controlado pela distância e direção (90 graus = para baixo)
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
