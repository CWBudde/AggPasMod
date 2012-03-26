program Agg2DDemoAll;

// AggPas 2.4 RM3 Demo application
// Note: Press F1 key on run to see more info about this demo

{$I AggCompiler.inc}

uses
  {$IFDEF USE_FASTMM4}
  FastMM4,
  {$ENDIF}
  SysUtils,

  Agg2D in '..\..\Source\Agg2D.pas',
  AggAlphaMaskUnpacked8 in '..\..\Source\AggAlphaMaskUnpacked8.pas',
  AggArc in '..\..\Source\AggArc.pas',
  AggArray in '..\..\Source\AggArray.pas',
  AggBezierArc in '..\..\Source\AggBezierArc.pas',
  AggBezierControl in '..\..\Source\Controls\AggBezierControl.pas',
  AggBlur in '..\..\Source\AggBlur.pas',
  AggCheckBoxControl in '..\..\Source\Controls\AggCheckBoxControl.pas',
  AggControl in '..\..\Source\Controls\AggControl.pas',
  AggCurves in '..\..\Source\AggCurves.pas',
  AggDdaLine in '..\..\Source\AggDdaLine.pas',
  AggEllipse in '..\..\Source\AggEllipse.pas',
  AggEllipseBresenham in '..\..\Source\AggEllipseBresenham.pas',
  AggEmbeddedRasterFonts in '..\..\Source\AggEmbeddedRasterFonts.pas',
  AggFontCacheManager in '..\..\Source\AggFontCacheManager.pas',
  AggFontEngine in '..\..\Source\AggFontEngine.pas',
  AggFontFreeType in '..\..\Source\AggFontFreeType.pas',
  AggFontFreeTypeLib in '..\..\Source\AggFontFreeTypeLib.pas',
  AggFontWin32TrueType in '..\..\Source\AggFontWin32TrueType.pas',
  AggGammaControl in '..\..\Source\Controls\AggGammaControl.pas',
  AggGammaFunctions in '..\..\Source\AggGammaFunctions.pas',
  AggGammaLUT in '..\..\Source\AggGammaLUT.pas',
  AggGlyphRasterBin in '..\..\Source\AggGlyphRasterBin.pas',
  AggGradientLut in '..\..\Source\AggGradientLut.pas',
  AggGsvText in '..\..\Source\AggGsvText.pas',
  AggImageFilters in '..\..\Source\AggImageFilters.pas',
  AggLineAABasics in '..\..\Source\AggLineAABasics.pas',
  AggMathStroke in '..\..\Source\AggMathStroke.pas',
  AggPathStorage in '..\..\Source\AggPathStorage.pas',
  AggPathStorageInteger in '..\..\Source\AggPathStorageInteger.pas',
  AggPatternFiltersRgba in '..\..\Source\AggPatternFiltersRgba.pas',
  AggPolygonControl in '..\..\Source\Controls\AggPolygonControl.pas',
  AggRasterizerCellsAA in '..\..\Source\AggRasterizerCellsAA.pas',
  AggRasterizerCompoundAA in '..\..\Source\AggRasterizerCompoundAA.pas',
  AggRasterizerOutline in '..\..\Source\AggRasterizerOutline.pas',
  AggRasterizerOutlineAA in '..\..\Source\AggRasterizerOutlineAA.pas',
  AggRasterizerScanLineAA in '..\..\Source\AggRasterizerScanLineAA.pas',
  AggRasterizerScanlineClip in '..\..\Source\AggRasterizerScanlineClip.pas',
  AggRadioBoxControl in '..\..\Source\Controls\AggRadioBoxControl.pas',
  AggRendererBase in '..\..\Source\AggRendererBase.pas',
  AggRendererMarkers in '..\..\Source\AggRendererMarkers.pas',
  AggRendererMultiClip in '..\..\Source\AggRendererMultiClip.pas',
  AggRendererOutlineAA in '..\..\Source\AggRendererOutlineAA.pas',
  AggRendererOutlineImage in '..\..\Source\AggRendererOutlineImage.pas',
  AggRendererPrimitives in '..\..\Source\AggRendererPrimitives.pas',
  AggRendererRasterText in '..\..\Source\AggRendererRasterText.pas',
  AggRendererScanLine in '..\..\Source\AggRendererScanLine.pas',
  AggRenderingBuffer in '..\..\Source\AggRenderingBuffer.pas',
  AggRenderingBufferDynaRow in '..\..\Source\AggRenderingBufferDynaRow.pas',
  AggRoundedRect in '..\..\Source\AggRoundedRect.pas',
  AggScaleControl in '..\..\Source\Controls\AggScaleControl.pas',
  AggSimulEq in '..\..\Source\AggSimulEq.pas',
  AggSliderControl in '..\..\Source\Controls\AggSliderControl.pas',
  AggSpanGouraud in '..\..\Source\AggSpanGouraud.pas',
  AggSpanGouraudGray in '..\..\Source\AggSpanGouraudGray.pas',
  AggSpanGouraudRgba in '..\..\Source\AggSpanGouraudRgba.pas',
  AggSpanGradient in '..\..\Source\AggSpanGradient.pas',
  AggSpanGradientAlpha in '..\..\Source\AggSpanGradientAlpha.pas',
  AggSpanGradientContour in '..\..\Source\AggSpanGradientContour.pas',
  AggSpanGradientImage in '..\..\Source\AggSpanGradientImage.pas',
  AggSpanImageFilter in '..\..\Source\AggSpanImageFilter.pas',
  AggSpanImageFilterGray in '..\..\Source\AggSpanImageFilterGray.pas',
  AggSpanImageFilterRgb in '..\..\Source\AggSpanImageFilterRgb.pas',
  AggSpanImageFilterRgba in '..\..\Source\AggSpanImageFilterRgba.pas',
  AggSpanImageResample in '..\..\Source\AggSpanImageResample.pas',
  AggSpanImageResampleGray in '..\..\Source\AggSpanImageResampleGray.pas',
  AggSpanImageResampleRGB in '..\..\Source\AggSpanImageResampleRGB.pas',
  AggSpanImageResampleRgba in '..\..\Source\AggSpanImageResampleRgba.pas',
  AggSpanInterpolatorLinear in '..\..\Source\AggSpanInterpolatorLinear.pas',
  AggSpanInterpolatorPerspective in '..\..\Source\AggSpanInterpolatorPerspective.pas',
  AggSpanInterpolatorTrans in '..\..\Source\AggSpanInterpolatorTrans.pas',
  AggSpanPattern in '..\..\Source\AggSpanPattern.pas',
  AggSpanPatternFilterGray in '..\..\Source\AggSpanPatternFilterGray.pas',
  AggSpanPatternFilterRgb in '..\..\Source\AggSpanPatternFilterRgb.pas',
  AggSpanPatternFilterRgba in '..\..\Source\AggSpanPatternFilterRgba.pas',
  AggSpanPatternResampleGray in '..\..\Source\AggSpanPatternResampleGray.pas',
  AggSpanPatternResampleRgb in '..\..\Source\AggSpanPatternResampleRgb.pas',
  AggSpanPatternResampleRgba in '..\..\Source\AggSpanPatternResampleRgba.pas',
  AggSpanPatternRgb in '..\..\Source\AggSpanPatternRgb.pas',
  AggSpanPatternRgba in '..\..\Source\AggSpanPatternRgba.pas',
  AggSpanSubdivAdaptor in '..\..\Source\AggSpanSubdivAdaptor.pas',
  AggSplineControl in '..\..\Source\Controls\AggSplineControl.pas',
  AggTransAffine in '..\..\Source\AggTransAffine.pas',
  AggTransBilinear in '..\..\Source\AggTransBilinear.pas',
  AggTransDoublePath in '..\..\Source\AggTransDoublePath.pas',
  AggTransPerspective in '..\..\Source\AggTransPerspective.pas',
  AggTransSinglePath in '..\..\Source\AggTransSinglePath.pas',
  AggTransViewport in '..\..\Source\AggTransViewport.pas',
  AggTransWarpMagnifier in '..\..\Source\AggTransWarpMagnifier.pas',
  AggVcgenBSpline in '..\..\Source\AggVcgenBSpline.pas',
  AggVcgenContour in '..\..\Source\AggVcgenContour.pas',
  AggVcgenDash in '..\..\Source\AggVcgenDash.pas',
  AggVcgenMarkersTerm in '..\..\Source\AggVcgenMarkersTerm.pas',
  AggVcgenSmoothPoly1 in '..\..\Source\AggVcgenSmoothPoly1.pas',
  AggVcgenStroke in '..\..\Source\AggVcgenStroke.pas',
  AggVcgenVertexSequence in '..\..\Source\AggVcgenVertexSequence.pas',
  AggVertexSequence in '..\..\Source\AggVertexSequence.pas',
  AggArrowHead in '..\..\Source\AggArrowHead.pas',
  AggBasics in '..\..\Source\AggBasics.pas',
  AggBitsetIterator in '..\..\Source\AggBitsetIterator.pas',
  AggBoundingRect in '..\..\Source\AggBoundingRect.pas',
  AggBSpline in '..\..\Source\AggBSpline.pas',
  AggClipLiangBarsky in '..\..\Source\AggClipLiangBarsky.pas',
  AggColor in '..\..\Source\AggColor.pas',
  AggConvAdaptorVcgen in '..\..\Source\AggConvAdaptorVcgen.pas',
  AggConvAdaptorVpgen in '..\..\Source\AggConvAdaptorVpgen.pas',
  AggConvBSpline in '..\..\Source\AggConvBSpline.pas',
  AggConvClipPolygon in '..\..\Source\AggConvClipPolygon.pas',
  AggConvClipPolyline in '..\..\Source\AggConvClipPolyline.pas',
  AggConvConcat in '..\..\Source\AggConvConcat.pas',
  AggConvContour in '..\..\Source\AggConvContour.pas',
  AggConvCurve in '..\..\Source\AggConvCurve.pas',
  AggConvDash in '..\..\Source\AggConvDash.pas',
  AggConvGPC in '..\..\Source\AggConvGPC.pas',
  AggConvMarker in '..\..\Source\AggConvMarker.pas',
  AggConvMarkerAdaptor in '..\..\Source\AggConvMarkerAdaptor.pas',
  AggConvSegmentator in '..\..\Source\AggConvSegmentator.pas',
  AggConvShortenPath in '..\..\Source\AggConvShortenPath.pas',
  AggConvSmoothPoly in '..\..\Source\AggConvSmoothPoly.pas',
  AggConvStroke in '..\..\Source\AggConvStroke.pas',
  AggConvTransform in '..\..\Source\AggConvTransform.pas',
  AggFileUtils in '..\..\Source\platform\Win\AggFileUtils.pas',
  AggGammaSpline in '..\..\Source\Controls\AggGammaSpline.pas',
  AggMath in '..\..\Source\AggMath.pas',
  AggPixelFormat in '..\..\Source\AggPixelFormat.pas',
  AggPixelFormatAlphaMaskAdaptor in '..\..\Source\AggPixelFormatAlphaMaskAdaptor.pas',
  AggPixelFormatGray in '..\..\Source\AggPixelFormatGray.pas',
  AggPixelFormatRgb in '..\..\Source\AggPixelFormatRgb.pas',
  AggPixelFormatRgba in '..\..\Source\AggPixelFormatRgba.pas',
  AggPixelFormatRgbPacked in '..\..\Source\AggPixelFormatRgbPacked.pas',
  AggPixelFormatTransposer in '..\..\Source\AggPixelFormatTransposer.pas',
  AggPlatformSupport in '..\..\Source\platform\Win\AggPlatformSupport.pas',
  AggRenderScanLines in '..\..\Source\AggRenderScanLines.pas',
  AggScanLine in '..\..\Source\AggScanLine.pas',
  AggScanLineBin in '..\..\Source\AggScanLineBin.pas',
  AggScanLinePacked in '..\..\Source\AggScanLinePacked.pas',
  AggScanLineStorageAA in '..\..\Source\AggScanLineStorageAA.pas',
  AggScanLineStorageBin in '..\..\Source\AggScanLineStorageBin.pas',
  AggScanlineUnpacked in '..\..\Source\AggScanlineUnpacked.pas',
  AggScanLineBooleanAlgebra in '..\..\Source\AggScanLineBooleanAlgebra.pas',
  AggShortenPath in '..\..\Source\AggShortenPath.pas',
  AggSpanAllocator in '..\..\Source\AggSpanAllocator.pas',
  AggSpanConverter in '..\..\Source\AggSpanConverter.pas',
  AggSpanGenerator in '..\..\Source\AggSpanGenerator.pas',
  AggSpanInterpolatorAdaptor in '..\..\Source\AggSpanInterpolatorAdaptor.pas',
  AggSpanSolid in '..\..\Source\AggSpanSolid.pas',
  AggVertexSource in '..\..\Source\AggVertexSource.pas',
  AggVpGen in '..\..\Source\AggVpGen.pas',
  AggVpGenClipPolygon in '..\..\Source\AggVpGenClipPolygon.pas',
  AggVpGenClipPolyline in '..\..\Source\AggVpgenClipPolyline.pas',
  AggVpGenSegmentator in '..\..\Source\AggVpgenSegmentator.pas',
  AggWin32Bmp in '..\..\Source\Platform\Win\AggWin32Bmp.pas';

const
  CFlipY = True;
  CAngleStep = 5;
  CGammaStep = 0.1;

var
  GFontTimes: AnsiString = 'Times New Roman';
  GFontArial: AnsiString = 'Arial';
  GFontVerdana: AnsiString = 'Verdana';

type
  TAggApplication = class(TPlatformSupport)
  private
    FGraphics, FTimer: TAgg2D;
    FAngle, FGamma: Double;
    FImage: Integer;
    FGmText: AnsiString;
  public
    constructor Create(PixelFormat: TPixelFormat; FlipY: Boolean);
    destructor Destroy; override;

    procedure OnDraw; override;

    procedure OnKey(X, Y: Integer; Key: Cardinal; Flags: TMouseKeyboardFlags);
      override;
  end;


{ TAggApplication }

constructor TAggApplication.Create(PixelFormat: TPixelFormat; FlipY: Boolean);
begin
  inherited Create(PixelFormat, FlipY);

  FGraphics := TAgg2D.Create;
  FTimer := TAgg2D.Create;

  FAngle := 0;
  FGamma := 1.4;
  FImage := 6;

  Str(FGamma: 0: 2, FGmText);
  FGmText := 'Gamma: ' + FGmText;
end;

destructor TAggApplication.Destroy;
begin
  FGraphics.Free;
  FTimer.Free;

  Finalize(FGmText);

  inherited Destroy;
end;

procedure TAggApplication.OnDraw;
var
  Rect: TRectDouble;
  Clr, C1, C2, C3: TAggColorRgba8;

  Img: TAgg2DImage;

  Parl: TAggParallelogram;
  Poly: array [0..11] of Double;

  Tm : Double;
  Fps: Integer;

  Timer, Rate: AnsiString;
begin
  StartTimer;

  FGraphics.Attach(RenderingBufferWindow.Buffer,
    RenderingBufferWindow.Width, RenderingBufferWindow.Height,
    RenderingBufferWindow.Stride);

  FGraphics.ClearAll(255, 255, 255);

  // FGraphics.ClearAll(0, 0, 0);

  // FGraphics.blendMode(BlendSub);
  // FGraphics.blendMode(BlendAdd);

  FGraphics.AntiAliasGamma := FGamma;

  // Set flipText(true) if you have the Y axis upside down.
  FGraphics.FlipText := not CFlipY;

  // ClipBox.
  // FGraphics.clipBox(50, 50, RenderingBufferWindow.Width - 50,
  //   RenderingBufferWindow.Height - 50);

  // Transfornations - Rotate around (300,300) to 5 degree
  FGraphics.Translate(-300, -300);
  FGraphics.Rotate(Deg2Rad(FAngle));
  FGraphics.Translate(300, 300);
  // FGraphics.skew     (0.1 ,0.1 );

  // Viewport - set 0,0,600,600 to the actual window size
  // preserving aspect ratio and placing the viewport in the center.
  // To ignore aspect ratio use Agg2D::Anisotropic
  // Note that the viewport just adds transformations to the current
  // affine matrix. So that, set the viewport *after* all transformations!
  FGraphics.Viewport(0, 0, 600, 600, 0, 0, Width, Height,
    // Anisotropic );
    voXMidYMid);
  // XMinYMin );
  // XMidYMin );
  // XMaxYMin );
  // XMinYMid );
  // XMaxYMid );
  // XMinYMax );
  // XMidYMax );
  // XMaxYMax );

  // Rounded Rect
  FGraphics.SetLineColor(0, 0, 0);
  FGraphics.NoFill;
  FGraphics.RoundedRect(0.5, 0.5, 600 - 0.5, 600 - 0.5, 20.0);

  // Regular Text
  { FGraphics.font(PAnsiChar(GFontTimes ) ,14.0 ,false ,false );
    FGraphics.fillColor(0 ,0 ,0 );
    FGraphics.noLine;
    FGraphics.text(100 ,20 ,PAnsiChar(PAnsiChar('Regular Raster Text -- Fast, but can''t be rotated' ) ) );{ }

  // Outlined Text
  FGraphics.Font(PAnsiChar(GFontTimes), 50.0, False, False,
    { RasterFontCache } fcVector);
  FGraphics.SetLineColor(50, 0, 0);
  FGraphics.SetFillColor(180, 200, 100);
  FGraphics.LineWidth := 1.0;
  FGraphics.Text(100.5, 50.5, PAnsiChar(PAnsiChar('Outlined Text')));

  // Gamma Text
  (* FGraphics.font(PAnsiChar(GFontArial ) ,38.0 ,true ,true ,VectorFontCache );

    c1.Construct                 (255 ,0   ,0   ,255 );
    c2.Construct                 (0   ,255 ,0   ,255 );
    FGraphics.fillLinearGradient(50 ,1 ,300 ,10 ,c1 ,c2 );

    FGraphics.noLine;
    FGraphics.text(12.5 ,565.5 ,PAnsiChar(@FGmText[1 ] ) );
    //FGraphics.rectangle(12.5 ,565.5 ,290 ,590 ); (* *)

  // Text Alignment
  FGraphics.SetLineColor(0, 0, 0);
  FGraphics.Line(250.5 - 150, 150.5, 250.5 + 150, 150.5);
  FGraphics.Line(250.5, 150.5 - 20, 250.5, 150.5 + 20);
  FGraphics.Line(250.5 - 150, 200.5, 250.5 + 150, 200.5);
  FGraphics.Line(250.5, 200.5 - 20, 250.5, 200.5 + 20);
  FGraphics.Line(250.5 - 150, 250.5, 250.5 + 150, 250.5);
  FGraphics.Line(250.5, 250.5 - 20, 250.5, 250.5 + 20);
  FGraphics.Line(250.5 - 150, 300.5, 250.5 + 150, 300.5);
  FGraphics.Line(250.5, 300.5 - 20, 250.5, 300.5 + 20);
  FGraphics.Line(250.5 - 150, 350.5, 250.5 + 150, 350.5);
  FGraphics.Line(250.5, 350.5 - 20, 250.5, 350.5 + 20);
  FGraphics.Line(250.5 - 150, 400.5, 250.5 + 150, 400.5);
  FGraphics.Line(250.5, 400.5 - 20, 250.5, 400.5 + 20);
  FGraphics.Line(250.5 - 150, 450.5, 250.5 + 150, 450.5);
  FGraphics.Line(250.5, 450.5 - 20, 250.5, 450.5 + 20);
  FGraphics.Line(250.5 - 150, 500.5, 250.5 + 150, 500.5);
  FGraphics.Line(250.5, 500.5 - 20, 250.5, 500.5 + 20);
  FGraphics.Line(250.5 - 150, 550.5, 250.5 + 150, 550.5);
  FGraphics.Line(250.5, 550.5 - 20, 250.5, 550.5 + 20);

  FGraphics.SetFillColor(100, 50, 50);
  FGraphics.NoLine;
  // FGraphics.textHints(false );
  FGraphics.Font(PAnsiChar(GFontTimes), 40.0, False, False, fcVector);

  FGraphics.TextAlignment(tahLeft, tavBottom);
  FGraphics.Text(250.0, 150.0, PAnsiChar('Left-Bottom'), True, 0, 0);

  FGraphics.TextAlignment(tahCenter, tavBottom);
  FGraphics.Text(250, 200, PAnsiChar('Center-Bottom'), True, 0, 0);

  FGraphics.TextAlignment(tahRight, tavBottom);
  FGraphics.Text(250.0, 250.0, PAnsiChar('Right-Bottom'), True, 0, 0);

  FGraphics.TextAlignment(tahLeft, tavCenter);
  FGraphics.Text(250.0, 300.0, PAnsiChar('Left-Center'), True, 0, 0);

  FGraphics.TextAlignment(tahCenter, tavCenter);
  FGraphics.Text(250.0, 350.0, PAnsiChar('Center-Center'), True, 0, 0);

  FGraphics.TextAlignment(tahRight, tavCenter);
  FGraphics.Text(250.0, 400.0, PAnsiChar('Right-Center'), True, 0, 0);

  FGraphics.TextAlignment(tahLeft, tavTop);
  FGraphics.Text(250.0, 450.0, PAnsiChar('Left-Top'), True, 0, 0);

  FGraphics.TextAlignment(tahCenter, tavTop);
  FGraphics.Text(250.0, 500.0, PAnsiChar('Center-Top'), True, 0, 0);

  FGraphics.TextAlignment(tahRight, tavTop);
  FGraphics.Text(250.0, 550.0, PAnsiChar('Right-Top'), True, 0, 0);

  // Gradients (Aqua Buttons)
  // =======================================
  FGraphics.Font(PAnsiChar(GFontVerdana), 20.0, False, False, fcVector);

  Rect.X1 := 400;
  Rect.Y1 := 80;
  Rect.X2 := Rect.X1 + 150;
  Rect.Y2 := Rect.Y1 + 36;

  Clr.Initialize(0, 50, 180, 180);
  FGraphics.FillColor := Clr;
  Clr.Initialize(0, 0, 80, 255);
  FGraphics.LineColor := Clr;
  FGraphics.LineWidth := 1.0;
  FGraphics.RoundedRect(Rect, 12, 18);

  Clr.Initialize(0, 0, 0, 0);
  FGraphics.LineColor := Clr;

  C1.Initialize(100, 200, 255, 255);
  C2.Initialize(255, 255, 255, 0);
  FGraphics.FillLinearGradient(Rect.X1, Rect.Y1, Rect.X1, Rect.Y1 + 30, C1, C2);
  FGraphics.RoundedRect(Rect.X1 + 3, Rect.Y1 + 2.5, Rect.X2 - 3, Rect.Y1 + 30,
    9, 18, 1, 1);

  Clr.Initialize(0, 0, 50, 200);
  FGraphics.FillColor := Clr;
  FGraphics.NoLine;
  FGraphics.TextAlignment(tahCenter, tavCenter);
  FGraphics.Text(Rect.CenterX, Rect.CenterY, PAnsiChar('Aqua Button'), True,
    0, 0);

  C1.Initialize(0, 0, 255, 0);
  C2.Initialize(100, 255, 255, 255);
  FGraphics.FillLinearGradient(Rect.X1, Rect.Y2 - 20, Rect.X1, Rect.Y2 - 3,
    C1, C2);
  FGraphics.RoundedRect(Rect.X1 + 3, Rect.Y2 - 20, Rect.X2 - 3, Rect.Y2 - 2,
    1, 1, 9, 18);

  // Aqua Button Pressed
  Rect.X1 := 400;
  Rect.Y1 := 30;
  Rect.X2 := Rect.X1 + 150;
  Rect.Y2 := Rect.Y1 + 36;

  Clr.Initialize(0, 50, 180, 180);
  FGraphics.FillColor := Clr;
  Clr.Initialize(0, 0, 0, 255);
  FGraphics.LineColor := Clr;
  FGraphics.LineWidth := 2.0;
  FGraphics.RoundedRect(Rect.X1, Rect.Y1, Rect.X2, Rect.Y2, 12, 18);

  Clr.Initialize(0, 0, 0, 0);
  FGraphics.LineColor := Clr;

  C1.Initialize(60, 160, 255, 255);
  C2.Initialize(100, 255, 255, 0);
  FGraphics.FillLinearGradient(Rect.X1, Rect.Y1 + 2, Rect.X1, Rect.Y1 + 25,
    C1, C2);
  FGraphics.RoundedRect(Rect.X1 + 3, Rect.Y1 + 2.5, Rect.X2 - 3, Rect.Y1 + 30,
    9, 18, 1, 1);

  Clr.Initialize(0, 0, 50, 255);
  FGraphics.FillColor := Clr;
  FGraphics.NoLine;
  FGraphics.TextAlignment(tahCenter, tavCenter);
  FGraphics.Text(Rect.CenterX, Rect.CenterY, PAnsiChar('Aqua Pressed'),
    False, 0.0);

  C1.Initialize(0, 180, 255, 0);
  C2.Initialize(0, 200, 255, 255);
  FGraphics.FillLinearGradient(Rect.X1, Rect.Y2 - 25, Rect.X1, Rect.Y2 - 5,
    C1, C2);
  FGraphics.RoundedRect(Rect.X1 + 3, Rect.Y2 - 25, Rect.X2 - 3, Rect.Y2 - 2,
    1, 1, 9, 18);

  // Basic Shapes -- Ellipse
  // ===========================================
  FGraphics.LineWidth := 3.5;
  FGraphics.SetLineColor(20, 80, 80);
  FGraphics.SetFillColor(200, 255, 80, 200);
  FGraphics.Ellipse(450, 200, 50, 90);

  // Paths
  // ===========================================
  FGraphics.ResetPath;
  FGraphics.SetFillColor(255, 0, 0, 100);
  FGraphics.SetLineColor(0, 0, 255, 100);
  FGraphics.LineWidth := 2;
  FGraphics.MoveTo(150, 100);
  FGraphics.HorizontalLineRel(-75);
  FGraphics.ArcRel(75, 75, 0, True, False, 75, -75);
  FGraphics.ClosePolygon;
  FGraphics.DrawPath;

  FGraphics.ResetPath;
  FGraphics.SetFillColor(255, 255, 0, 100);
  FGraphics.SetLineColor(0, 0, 255, 100);
  FGraphics.LineWidth := 2;
  FGraphics.MoveTo(275 * 0.5, 175 * 0.5);
  FGraphics.VerticalLineRel(-75);
  FGraphics.ArcRel(75, 75, 0, False, False, -75, 75);
  FGraphics.ClosePolygon;
  FGraphics.DrawPath;

  FGraphics.ResetPath;
  FGraphics.NoFill;
  FGraphics.SetLineColor(127, 0, 0);
  FGraphics.LineWidth := 5;
  FGraphics.MoveTo(300, 175);
  FGraphics.LineRel(25, -12.5);
  FGraphics.ArcRel(12.5, 12.5, Deg2Rad(-30), False, True, 25, -12.5);
  FGraphics.LineRel(25, -12.5);
  FGraphics.ArcRel(12.5, 25, Deg2Rad(-30), False, True, 25, -12.5);
  FGraphics.LineRel(25, -12.5);
  FGraphics.ArcRel(12.5, 75 / 2, Deg2Rad(-30), False, True, 25, -12.5);
  FGraphics.LineRel(50, -25);
  FGraphics.ArcRel(12.5, 50, Deg2Rad(-30), False, True, 25, -12.5);
  FGraphics.LineRel(25, -12.5);
  FGraphics.DrawPath;

  // Master Alpha. From now on everything will be translucent
  // ===========================================
  FGraphics.MasterAlpha := 0.85;

  // Image Transformations
  // ===========================================
  Img := TAgg2DImage.Create(RenderingBufferImage[0].Buffer,
    RenderingBufferImage[0].Width, RenderingBufferImage[0].Height,
    RenderingBufferImage[0].Stride);

  FGraphics.ImageFilter := ifBilinear;

  // FGraphics.imageResample(NoResample );
  // FGraphics.imageResample(ResampleAlways );
  FGraphics.ImageResample := irOnZoomOut;

  // Set the initial image blending operation as BlendDst, that actually
  // does nothing.
  // -----------------
  FGraphics.ImageBlendMode := bmDestination;

  // Transform the whole image to the destination rectangle
  // -----------------
  if FImage = 1 then
    FGraphics.TransformImage(Img, 450, 200, 595, 350); { 1 }

  // Transform the rectangular part of the image to the destination rectangle
  // -----------------
  if FImage = 2 then
    FGraphics.TransformImage(Img, 60, 60, Img.Width - 60, Img.Height - 60,
      450, 200, 595, 350); { 2 }

  // Transform the whole image to the destination parallelogram
  // -----------------
  if FImage = 3 then
  begin
    Parl[0] := 450;
    Parl[1] := 200;
    Parl[2] := 595;
    Parl[3] := 220;
    Parl[4] := 575;
    Parl[5] := 350;

    FGraphics.TransformImage(Img, @Parl[0]); { 3 }
  end;

  // Transform the rectangular part of the image to the destination parallelogram
  // -----------------
  if FImage = 4 then
  begin
    Parl[0] := 450;
    Parl[1] := 200;
    Parl[2] := 595;
    Parl[3] := 220;
    Parl[4] := 575;
    Parl[5] := 350;

    FGraphics.TransformImage(Img, 60, 60, Img.Width - 60, Img.Height - 60,
      @Parl[0]); { 4 }
  end;

  // Transform image to the destination path. The scale is determined by a rectangle
  // -----------------
  if FImage = 5 then
  begin
    FGraphics.ResetPath;
    FGraphics.MoveTo(450, 200);
    FGraphics.CubicCurveTo(595, 220, 575, 350, 595, 350);
    FGraphics.LineTo(470, 340);
    FGraphics.TransformImagePath(Img, 450, 200, 595, 350); { 5 }
  end;

  // Transform image to the destination path.
  // The scale is determined by a rectangle
  // -----------------
  if FImage = 6 then
  begin
    FGraphics.ResetPath;
    FGraphics.MoveTo(450, 200);
    FGraphics.CubicCurveTo(595, 220, 575, 350, 595, 350);
    FGraphics.LineTo(470, 340);
    FGraphics.TransformImagePath(Img, 60, 60, Img.Width - 60, Img.Height - 60,
      450, 200, 595, 350); { 6 }
  end;

  // Transform image to the destination path.
  // The transformation is determined by a parallelogram
  if FImage = 7 then
  begin
    FGraphics.ResetPath;
    FGraphics.MoveTo(450, 200);
    FGraphics.CubicCurveTo(595, 220, 575, 350, 595, 350);
    FGraphics.LineTo(470, 340);

    Parl[0] := 450;
    Parl[1] := 200;
    Parl[2] := 595;
    Parl[3] := 220;
    Parl[4] := 575;
    Parl[5] := 350;

    FGraphics.TransformImagePath(Img, @Parl[0]); { 7 }
  end;

  // Transform the rectangular part of the image to the destination path.
  // The transformation is determined by a parallelogram
  if FImage = 8 then
  begin
    FGraphics.ResetPath;
    FGraphics.MoveTo(450, 200);
    FGraphics.CubicCurveTo(595, 220, 575, 350, 595, 350);
    FGraphics.LineTo(470, 340);

    Parl[0] := 450;
    Parl[1] := 200;
    Parl[2] := 595;
    Parl[3] := 220;
    Parl[4] := 575;
    Parl[5] := 350;

    FGraphics.TransformImagePath(Img, 60, 60, Img.Width - 60, Img.Height - 60,
      @Parl[0]); { 8 }
  end;

  // Free Image
  Img.Free;

  // Add/Sub/Contrast Blending Modes
  FGraphics.NoLine;
  FGraphics.SetFillColor(70, 70, 0);
  FGraphics.BlendMode := bmAlpha;
  FGraphics.Ellipse(500, 280, 20, 40);

  FGraphics.SetFillColor(255, 255, 255);
  FGraphics.BlendMode := bmContrast;
  FGraphics.Ellipse(500 + 40, 280, 20, 40);

  // Radial Gradient.
  FGraphics.BlendMode := bmAlpha;
  C1.Initialize(255, 255, 0, 0);
  C2.Initialize(0, 0, 127);
  C3.Initialize(0, 255, 0, 0);
  FGraphics.FillRadialGradient(400, 500, 40, C1, C2, C3);
  FGraphics.Ellipse(400, 500, 40, 40);

  // More ...
  (* FGraphics.masterAlpha(1 );

    //FGraphics.lineColor(50 ,60 ,70 );

    c1.Construct                 (255 ,0   ,0 ,255 );
    c2.Construct                 (0   ,255 ,0   ,255 );
    FGraphics.lineLinearGradient(0 ,0 ,500 ,0 ,c1 ,c2 );{}

    FGraphics.fillColor(255 ,0 ,0 );
    FGraphics.lineJoin (JoinMiter );
    FGraphics.lineWidth(15 );
    FGraphics.triangle (10 ,10 ,100 ,20 ,50 ,150 );

    FGraphics.lineJoin (JoinRound );
    FGraphics.lineWidth(4 );
    FGraphics.noFill;
    FGraphics.rectangle(55 ,540 ,135 ,495 );

    FGraphics.masterAlpha(0.5 );

    FGraphics.fillColor(255 ,127 ,65 );
    FGraphics.star     (300 ,300 ,30 ,70 ,55 ,5 );
    FGraphics.arc      (400 ,400 ,30 ,30 ,300 ,1150 );

    FGraphics.lineWidth(20 );
    FGraphics.lineCap  (CapRound );
    FGraphics.curve    (80 ,400 ,90 ,220 ,190 ,390 );
    FGraphics.curve    (80 ,500 ,90 ,320 ,190 ,490 ,310 ,330 );

    poly[0 ]:=400;
    poly[1 ]:=580;

    poly[2 ]:=530;
    poly[3 ]:=400;

    poly[4 ]:=590;
    poly[5 ]:=500;

    poly[6 ]:=450;
    poly[7 ]:=380;

    poly[8 ]:=490;
    poly[9 ]:=570;

    poly[10 ]:=420;
    poly[11 ]:=420;

    FGraphics.fillEvenOdd(false );
    FGraphics.lineWidth  (3 );
    FGraphics.polygon    (@poly[0 ] ,6 );

    FGraphics.lineColor(221 ,160 ,221 );
    FGraphics.lineWidth(6 );
    FGraphics.polyline (@poly[0 ] ,6 ); (* *)

  // TIMER DRAW
  // ----------
  Tm := GetElapsedTime;

  FTimer.Attach(RenderingBufferWindow.Buffer,
    RenderingBufferWindow.Width, RenderingBufferWindow.Height,
    RenderingBufferWindow.Stride);

  FTimer.AntiAliasGamma := 1.4;

  FTimer.FlipText := not CFlipY;
  FTimer.Viewport(0, 0, 600, 600, 0, 0, Width, Height, voXMidYMid);

  Str(Tm: 0: 2, Timer);

  Timer := 'Frame time: ' + Timer + ' ms';

  Fps := Trunc(1000 / Tm);

  Str(Fps, Rate);

  Timer := Timer + ' (' + Rate + ' FPS)';

  FTimer.Font(PAnsiChar(GFontArial), 15.0, True, False, fcVector);
  FTimer.NoLine;
  FTimer.SetFillColor(255, 0, 0);
  FTimer.Text(350, 8, PAnsiChar(@Timer[1]));
end;

procedure TAggApplication.OnKey(X, Y: Integer; Key: Cardinal; Flags: TMouseKeyboardFlags);
begin
  if Key = Cardinal(kcF1) then
    DisplayMessage('"Quick and dirty prototype" of 2D drawing API for AGG.'#13#13
      + 'Written and published by Maxim Shemanarev (c) 2005 - 2006.   '#13
      + 'Ported to Object Pascal by Milan Marusinec (c) 2007.'#13#13
      + 'How to play with:'#13#13
      + 'Key Down - Rotate clockwise'#13
      + 'Key Up - Rotate counterclockwise'#13
      + 'Key Right - Next image transformation'#13
      + 'Key Left - Previous image transformation'#13
      + 'Key Plus - Increase Gamma'#13
      + 'Key Minus - Decrease Gamma');

  if Key = Cardinal(kcDown) then
  begin
    FAngle := FAngle - CAngleStep;

    if FAngle < 0 then
      FAngle := 360 - CAngleStep;

    ForceRedraw;
  end;

  if Key = Cardinal(kcUp) then
  begin
    FAngle := FAngle + CAngleStep;

    if FAngle > 360 then
      FAngle := CAngleStep;

    ForceRedraw;
  end;

  if Key = Cardinal(kcRight) then
  begin
    Inc(FImage);

    if FImage > 8 then
      FImage := 1;

    ForceRedraw;
  end;

  if Key = Cardinal(kcLeft) then
  begin
    Dec(FImage);

    if FImage < 1 then
      FImage := 8;

    ForceRedraw;
  end;

  if Key = Cardinal(kcPadPlus) then
  begin
    FGamma := FGamma + CGammaStep;

    Str(FGamma: 0: 2, FGmText);
    FGmText := 'Gamma: ' + FGmText;

    ForceRedraw;
  end;

  if Key = Cardinal(kcPadMinus) then
  begin
    FGamma := FGamma - CGammaStep;

    Str(FGamma: 0: 2, FGmText);
    FGmText := 'Gamma: ' + FGmText;

    ForceRedraw;
  end;
end;

var
  Text: AnsiString;
  ImageName, P, N, X: ShortString;

begin
  if Agg2DUsesFreeType then
  begin
    GFontTimes := 'times.ttf';
    GFontArial := 'arial.ttf';
    GFontVerdana := 'verdana.ttf';
  end;

  with TAggApplication.Create(pfBgra32, CFlipY) do
  try
    Caption := 'Agg2DDemo (F1-Help)';

    ImageName := 'spheres2';

{$IFDEF WIN32}
    if ParamCount > 0 then
    begin
      SpreadName(ParamStr(1), P, N, X);

      ImageName := FoldName(P, N, '');
    end;
{$ENDIF}

    if not LoadImage(0, ImageName) then
    begin
      Text := 'File not found: ' + ImageName + ImageExtension;
      if ImageName = 'spheres2' then
        Text := Text + #13#13 + 'Download http://www.antigrain.com/'
          + ImageName + ImageExtension + #13 + 'or copy it from another ' +
          'directory if available.';

      DisplayMessage(Text);
    end
    else if Init(600, 600, [wfResize]) then
      Run;
  finally
    Free;
  end;
end.
