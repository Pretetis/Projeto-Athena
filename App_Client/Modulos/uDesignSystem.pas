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
    Expirando = 'M0,0 M24,24 M21.7299995422363,18 L13.7299995422363,4 ' +
                'C13.1853895187378,3.0390248298645 11.9648714065552,2.70149397850037 ' +
                '11.0038957595825,3.24610424041748 C10.6890106201172,3.42455768585205 ' +
                '10.4284534454346,3.68511533737183 10.25,4 L2.25,18 ' +
                'C1.69767069816589,18.9565582275391 2.02536392211914,20.1797542572021 ' +
                '2.9819233417511,20.732084274292 C3.29126739501953,20.9107036590576 ' +
                '3.6428050994873,21.0032138824463 4,21 L20,21 ' +
                'C21.1045684814453,20.9988689422607 21.999080657959,20.1025199890137 ' +
                '21.9979476928711,18.9979515075684 C21.9975891113281,18.6475734710693 ' +
                '21.9051895141602,18.3034362792969 21.7299995422363,18 ' +
                'M12,9 L12,13 M12,17 L12.0100002288818,17';

    Expirado  = 'M0,0 M24,24 M20,13 C20,18 16.5,20.5 12.3400001525879,21.9500007629395 ' +
                'C12.1221628189087,22.0238170623779 11.8855381011963,22.02028465271 ' +
                '11.6700010299683,21.939998626709 C7.5,20.5 4,18 4,13 L4,6 ' +
                'C4,5.44771480560303 4.44771528244019,5 5,5 C7,5 9.5,3.79999995231628 ' +
                '11.2399997711182,2.27999997138977 C11.6776733398438,1.90606701374054 ' +
                '12.3223266601563,1.90606689453125 12.7600002288818,2.27999973297119 ' +
                'C14.5100002288818,3.80999994277954 17,5 19,5 C19.5522842407227,5 ' +
                '20,5.44771528244019 20,6 Z M12,8 L12,12 M12,16 L12.0100002288818,16';

    Download  = 'M0,0 M24,24 M12,15 L12,3 M21,15 L21,19 C21,20.1045703887939 ' +
                '20.1045703887939,21 19,21 L5,21 C3.89543056488037,21 3,20.1045703887939 ' +
                '3,19 L3,15 M7,10 L12,15 L17,10';

    Cancelar  = 'M0,0 M24,24 M18 6 6 18 m6 6 12 12';
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
