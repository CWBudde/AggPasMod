unit Agg2D;

// ----------------------------------------------------------------------------
// Agg2D - Version 1.0
// Based on Anti-Grain Geometry
// Copyright (C) 2005 Maxim Shemanarev (http://www.antigrain.com)
//
// TAgg2D - Version 1.0 Release Milano 3 (AggPas 2.4 RM3)
// Pascal Port By: Milan Marusinec alias Milano
// milan@marusinec.sk
// http://www.aggpas.org
// Copyright (c) 2007 - 2008
//
// Permission to copy, use, modify, sell and distribute this software
// is granted provided this copyright notice appears in all copies.
// This software is provided "as is" without express or implied
// warranty, and with no claim as to its suitability for any purpose.
//
// ----------------------------------------------------------------------------
// Contact: McSeem@antigrain.com
// McSeemagg@yahoo.com
// http://www.antigrain.com
//

interface

{$I AggCompiler.inc}
// With this define you can switch use of FreeType or Win32 TrueType font engine
{ DEFINE AGG2D_USE_FREETYPE }

uses
  AggBasics,
  AggArray,
  AggTransAffine,
  AggTransViewport,
  AggPathStorage,
  AggConvStroke,
  AggConvTransform,
  AggConvCurve,
  AggRenderingBuffer,
  AggRendererBase,
  AggRendererScanLine,
  AggSpanGradient,
  AggSpanImageFilterRgba,
  AggSpanImageResampleRgba,
  AggSpanConverter,
  AggSpanInterpolatorLinear,
  AggSpanAllocator,
  AggRasterizerScanLineAA,
  AggGammaFunctions,
  AggScanlineUnpacked,
  AggArc,
  AggBezierArc,
  AggRoundedRect,
  AggFontEngine,
  AggFontCacheManager,
  AggPixelFormat,
  AggPixelFormatRgb,
  AggPixelFormatRgba,
  AggColor,
  AggMathStroke,
  AggImageFilters,
  AggVertexSource,
  AggRenderScanLines,

{$IFDEF AGG2D_USE_FREETYPE}
  AggFontFreeType,
{$ELSE}
  AggFontWin32TrueType,
{$ENDIF}

  Math, Windows, Classes, Graphics;

const
  // LineJoin
  AGG_JoinMiter = MiterJoin;
  AGG_JoinRound = RoundJoin;
  AGG_JoinBevel = BevelJoin;

  // LineCap
  AGG_CapButt = ButtCap;
  AGG_CapSquare = SquareCap;
  AGG_CapRound = RoundCap;

  // TextAlignment
  AGG_AlignLeft = 0;
  AGG_AlignRight = 1;
  AGG_AlignCenter = 2;
  AGG_AlignTop = AGG_AlignRight;
  AGG_AlignBottom = AGG_AlignLeft;

  // BlendMode
  CBlendAlpha = End_of_TCompOp;
  CBlendClear = coClear;
  CBlendSrc = coSource;
  CBlendDst = coDestination;
  CBlendSrcOver = coSourceOver;
  CBlendDstOver = coDestinationOver;
  CBlendSrcIn = coSourceIn;
  CBlendDstIn = coDestinationIn;
  CBlendSrcOut = coSourceOut;
  CBlendDstOut = coDestinationOut;
  CBlendSrcAtop = coSourceATop;
  CBlendDstAtop = coDestinationATop;
  CBlendXor = coXor;
  CBlendAdd = coPlus;
  CBlendSub = coMinus;
  CBlendMultiply = coMultiply;
  CBlendScreen = coScreen;
  CBlendOverlay = coOverlay;
  CBlendDarken = coDarken;
  CBlendLighten = coLighten;
  CBlendColorDodge = coColorDodge;
  CBlendColorBurn = coColorBurn;
  CBlendHardLight = coHardLight;
  CBlendSoftLight = coSoftLight;
  CBlendDifference = coDifference;
  CBlendExclusion = coExclusion;
  CBlendContrast = coContrast;

  
type
(*
  PAggColor = ^TAggColor;
  TAggColor = Rgba8;
*)

  TAggRectD = AggBasics.RectDouble;

  TAggAffine = TransAffineObject;
  PAggAffine = PTransAffineObject;

  TAggFontRasterizer = Gray8AdaptorType;
  PAggFontRasterizer = PGray8AdaptorTypeObject;

  TAggFontScanLine = Gray8ScanLineType;
  PAggFontScanLine = PGray8ScanLineTypeObject;

{$IFDEF AGG2D_USE_FREETYPE}
  TAggFontEngine = FontEngineFreetypeInt32;
{$ELSE }
  TAggFontEngine = FontEngineWin32TrueTypeInt32Object;
{$ENDIF}

  TAggGradient = (AGG_Solid, AGG_Linear, AGG_Radial);
  TAggDirection = (AGG_CW, AGG_CCW);

  TAggLineJoin = Integer;
  TAggLineCap = Integer;
  TAggBlendMode = TCompOp;

  TAggTextAlignment = Integer;

  TAggDrawPathFlag = (AGG_FillOnly, AGG_StrokeOnly, AGG_FillAndStroke,
    AGG_FillWitHorizontalLineColor);

  TAggViewportOption = (AGG_Anisotropic, AGG_XMinYMin, AGG_XMidYMin,
    AGG_XMaxYMin, AGG_XMinYMid, AGG_XMidYMid, AGG_XMaxYMid, AGG_XMinYMax,
    AGG_XMidYMax, AGG_XMaxYMax);

  TAggImageFilter = (AGG_NoFilter, AGGBilinear, AGG_Hanning, AGG_Hermite,
    AGG_Quadric, AGG_Bicubic, AGG_Catrom, AGG_Spline16, AGG_Spline36,
    AGG_Blackman144);

  TAggImageResample = (AGG_NoResample, AGG_ResampleAlways,
    AGG_ResampleOnZoomOut);

  TAggFontCacheType = (AGG_RasterFontCache, AGG_VectorFontCache);

  PAggTransformations = ^TAggTransformations;

  TAggTransformations = record
    AffineMatrix: array [0..5] of Double;
  end;

  TAggRasterizerGamma = object(VertexSourceObject)
    FAlpha: GammaMultiplyObject;
    FGamma: GammaPowerObject;

    constructor Create(Alpha, Gamma: Double);

    function FuncOperatorGamma(X: Double): Double; virtual;
  end;

  TAggImage = class
  private
    FRenderingBuffer: RenderingBufferObject;
  public
    constructor Create;
    destructor Destroy; override;

    function Attach(Bitmap: TBitmap; Flip: Boolean): Boolean;

    function Width: Integer;
    function Height: Integer;
  end;

  TAgg2D = class
  private
    FPixFormat, FPixFormatComp: PixelFormatsObject;
    FPixFormatPre, FPixFormatCompPre: PixelFormatsObject;
    FRendererBase, FRendererBaseComp, FRendererBasePre, FRendererBaseCompPre: RendererBaseObject;
    FRenSolid, FRenSolidComp: RendererScanLineAASolidObject;
    FAllocator: SpanAllocatorObject;
    FClipBox  : TAggRectD;
    FBlendMode, FImageBlendMode: TAggBlendMode;
    FImageBlendColor: TAggColor;
    FScanLine  : ScanLineU8Object;
    FRasterizer: RasterizerScanLineAAObject;
    FMasterAlpha, FAntiAliasGamma: Double;
    FFillColor, FLineColor: TAggColor;
    FFillGradient, FLineGradient: PodAutoArrayObject;
    FLineCap : TAggLineCap;
    FLineJoin: TAggLineJoin;
    FFillGradientFlag, FLineGradientFlag: TAggGradient;
    FFillGradientMatrix, FLineGradientMatrix: TransAffineObject;
    FFillGradientD1, FLineGradientD1: Double;
    FFillGradientD2, FLineGradientD2: Double;
    FTextAngle: Double;
    FTextAlignX, FTextAlignY: TAggTextAlignment;
    FTextHints: Boolean;
    FFontHeight, FFontAscent, FFontDescent: Double;
    FFontCacheType: TAggFontCacheType;

    FImageFilter: TAggImageFilter;
    FImageResample: TAggImageResample;
    FImageFilterLut: ImageFilterLUTObject;

    FFillGradientInterpolator: SpanInterpolatorLinearObject;
    FLineGradientInterpolator: SpanInterpolatorLinearObject;

    FLinearGradientFunction: GradientXObject;
    FRadialGradientFunction: GradientCircleObject;

    FLineWidth: Double;
    FEvenOddFlag: Boolean;

    FPath: PathStorageObject;
    FTransform: TransAffineObject;

    FConvCurve: ConvCurveObject;
    FConvStroke: ConvStrokeObject;

    FPathTransform, FStrokeTransform: ConvTransformObject;

    FImageFlip: Boolean;

{$IFNDEF AGG2D_USE_FREETYPE}
    FFontDC: HDC;
{$ENDIF}

    FFontEngine: TAggFontEngine;
    FFontCacheManager: FontCacheManagerObject;

    // Other Pascal-specific members
    FGammaNone: GammaNoneObject;
    FGammaAgg2D: TAggRasterizerGamma;

    FImageFilterBilinear: ImageFilterBilinearObject;
    FImageFilterHanning: ImageFilterHanningObject;
    FImageFilterHermite: ImageFilterHermiteObject;
    FImageFilterQuadric: ImageFilterQuadricObject;
    FImageFilterBicubic: ImageFilterBicubicObject;
    FImageFilterCatrom: ImageFilterCatromObject;
    FImageFilterSpline16: ImageFilterSpline16Object;
    FImageFilterSpline36: ImageFilterSpline36Object;
    FImageFilterBlackman144: ImageFilterBlackmanObject144;
  protected
    FRenderingBuffer: RenderingBufferObject;
    FPixelFormat: TPixelFormat;
  public
    constructor Create;
    destructor Destroy; override;

    // Vector Graphics Engine Initialization
    function Attach(Bitmap: TBitmap; Flip_y: Boolean = False): Boolean;

    procedure ClearAll(C: TAggColor); overload;
    procedure ClearAll(R, G, B: Byte; A: Byte = 255); overload;

    // Master Rendering Properties
    procedure BlendMode(M: TAggBlendMode); overload;
    function BlendMode: TAggBlendMode; overload;

    procedure MasterAlpha(A: Double); overload;
    function MasterAlpha: Double; overload;

    procedure AntiAliasGamma(G: Double); overload;
    function AntiAliasGamma: Double; overload;

    procedure FillColor(C: TAggColor); overload;
    procedure FillColor(C: Rgba8); overload;
    procedure FillColor(R, G, B: Byte; A: Byte = 255); overload;
    procedure NoFill;

    procedure LineColor(C: TAggColor); overload;
    procedure LineColor(R, G, B: Byte; A: Byte = 255); overload;
    procedure NoLine;

    function FillColor: TAggColor; overload;
    function LineColor: TAggColor; overload;

    procedure FillLinearGradient(X1, Y1, X2, Y2: Double; C1, C2: TAggColor;
      Profile: Double = 1.0);
    procedure LineLinearGradient(X1, Y1, X2, Y2: Double; C1, C2: TAggColor;
      Profile: Double = 1.0);

    procedure FillRadialGradient(X, Y, R: Double; C1, C2: TAggColor;
      Profile: Double = 1.0); overload;
    procedure LineRadialGradient(X, Y, R: Double; C1, C2: TAggColor;
      Profile: Double = 1.0); overload;

    procedure FillRadialGradient(X, Y, R: Double;
      C1, C2, C3: TAggColor); overload;
    procedure LineRadialGradient(X, Y, R: Double;
      C1, C2, C3: TAggColor); overload;

    procedure FillRadialGradient(X, Y, R: Double); overload;
    procedure LineRadialGradient(X, Y, R: Double); overload;

    procedure LineWidth(W: Double); overload;
    function LineWidth: Double; overload;

    procedure LineCap(Cap: TAggLineCap); overload;
    function LineCap: TAggLineCap; overload;

    procedure LineJoin(Join: TAggLineJoin); overload;
    function LineJoin: TAggLineJoin; overload;

    procedure FillEvenOdd(EvenOddFlag: Boolean); overload;
    function FillEvenOdd: Boolean; overload;

    // Affine Transformations
    function Transformations: TAggTransformations; overload;
    procedure Transformations(Tr: PAggTransformations); overload;
    procedure ResetTransformations;

    procedure Affine(Tr: PAggAffine); overload;
    procedure Affine(Tr: PAggTransformations); overload;

    procedure Rotate(Angle: Double);
    procedure Scale(Sx, Sy: Double);
    procedure Skew(Sx, Sy: Double);
    procedure Translate(X, Y: Double);

    procedure Parallelogram(X1, Y1, X2, Y2: Double; Para: PDouble);

    procedure Viewport(WorldX1, WorldY1, WorldX2, WorldY2, ScreenX1, ScreenY1,
      ScreenX2, ScreenY2: Double; Opt: TAggViewportOption = AGG_XMidYMid);

    // Coordinates Conversions
    procedure WorldToScreen(X, Y: PDouble); overload;
    procedure ScreenToWorld(X, Y: PDouble); overload;
    function WorldToScreen(Scalar: Double): Double; overload;
    function ScreenToWorld(Scalar: Double): Double; overload;

    procedure AlignPoint(X, Y: PDouble);

    // Clipping
    procedure ClipBox(X1, Y1, X2, Y2: Double); overload;
    function ClipBox: TAggRectD; overload;

    procedure ClearClipBox(C: TAggColor); overload;
    procedure ClearClipBox(R, G, B: Byte; A: Byte = 255); overload;

    function InBox(WorldX, WorldY: Double): Boolean;

    // Basic Shapes
    procedure Line(X1, Y1, X2, Y2: Double);
    procedure Triangle(X1, Y1, X2, Y2, X3, Y3: Double);
    procedure Rectangle(X1, Y1, X2, Y2: Double);

    procedure RoundedRect(X1, Y1, X2, Y2, R: Double); overload;
    procedure RoundedRect(X1, Y1, X2, Y2, Rx, Ry: Double); overload;
    procedure RoundedRect(X1, Y1, X2, Y2, RxBottom, RyBottom, RxTop,
      RyTop: Double); overload;

    procedure EllipseObject(Cx, Cy, Rx, Ry: Double);

    procedure Arc(Cx, Cy, Rx, Ry, Start, Sweep: Double);
    procedure Star(Cx, Cy, R1, R2, StartAngle: Double; NumRays: Integer);

    procedure Curve(X1, Y1, X2, Y2, X3, Y3: Double); overload;
    procedure Curve(X1, Y1, X2, Y2, X3, Y3, X4, Y4: Double); overload;

    procedure Polygon(Xy: PDouble; NumPoints: Integer);
    procedure Polyline(Xy: PDouble; NumPoints: Integer);

    // Path Commands
    procedure ResetPath;

    procedure MoveTo(X, Y: Double);
    procedure MoveRel(Dx, Dy: Double);

    procedure LineTo(X, Y: Double);
    procedure LineRel(Dx, Dy: Double);

    procedure HorLineTo(X: Double);
    procedure HorLineRel(Dx: Double);

    procedure VerLineTo(Y: Double);
    procedure VerLineRel(Dy: Double);

    procedure ArcTo(Rx, Ry, Angle: Double; LargeArcFlag, SweepFlag: Boolean;
      X, Y: Double);

    procedure ArcRel(Rx, Ry, Angle: Double; LargeArcFlag, SweepFlag: Boolean;
      Dx, Dy: Double);

    procedure QuadricCurveTo(XCtrl, YCtrl, XTo, YTo: Double); overload;
    procedure QuadricCurveRel(DxCtrl, DyCtrl, DxTo, DyTo: Double); overload;
    procedure QuadricCurveTo(XTo, YTo: Double); overload;
    procedure QuadricCurveRel(DxTo, DyTo: Double); overload;

    procedure CubicCurveTo(XCtrl1, YCtrl1, XCtrl2, YCtrl2, XTo,
      YTo: Double); overload;
    procedure CubicCurveRel(DxCtrl1, DyCtrl1, DxCtrl2, DyCtrl2, DxTo,
      DyTo: Double); overload;
    procedure CubicCurveTo(XCtrl2, YCtrl2, XTo, YTo: Double); overload;
    procedure CubicCurveRel(DxCtrl2, DyCtrl2, DxTo, DyTo: Double); overload;

    procedure AddEllipseObject(Cx, Cy, Rx, Ry: Double; Dir: TAggDirection);
    procedure ClosePolygon;

    procedure DrawPath(Flag: TAggDrawPathFlag = AGG_FillAndStroke);

    // Text Rendering
    procedure FlipText(Flip: Boolean);

    procedure Font(FileName: AnsiString; Height: Double; Bold: Boolean = False;
      Italic: Boolean = False; Cache: TAggFontCacheType = AGG_VectorFontCache;
      Angle: Double = 0.0);

    function FontHeight: Double;

    procedure TextAlignment(AlignX, AlignY: TAggTextAlignment);

    function TextHints: Boolean; overload;
    procedure TextHints(Hints: Boolean); overload;
    function TextWidth(Str: AnsiString): Double;

    procedure Text(X, Y: Double; Str: AnsiString; RoundOff: Boolean = False;
      Ddx: Double = 0.0; Ddy: Double = 0.0);

    // Image Rendering
    procedure ImageFilter(F: TAggImageFilter); overload;
    function ImageFilter: TAggImageFilter; overload;

    procedure ImageResample(F: TAggImageResample); overload;
    function ImageResample: TAggImageResample; overload;

    procedure ImageFlip(F: Boolean);

    procedure TransformImage(Bitmap: TBitmap;
      ImgX1, ImgY1, ImgX2, ImgY2: Integer;
      DstX1, DstY1, DstX2, DstY2: Double); overload;

    procedure TransformImage(Bitmap: TBitmap;
      DstX1, DstY1, DstX2, DstY2: Double); overload;

    procedure TransformImage(Bitmap: TBitmap;
      ImgX1, ImgY1, ImgX2, ImgY2: Integer; Parallelo: PDouble); overload;

    procedure TransformImage(Bitmap: TBitmap; Parallelo: PDouble); overload;

    procedure TransformImagePath(Bitmap: TBitmap;
      ImgX1, ImgY1, ImgX2, ImgY2: Integer;
      DstX1, DstY1, DstX2, DstY2: Double); overload;

    procedure TransformImagePath(Bitmap: TBitmap;
      DstX1, DstY1, DstX2, DstY2: Double); overload;

    procedure TransformImagePath(Bitmap: TBitmap;
      ImgX1, ImgY1, ImgX2, ImgY2: Integer; Parallelo: PDouble); overload;

    procedure TransformImagePath(Bitmap: TBitmap; Parallelo: PDouble); overload;

    procedure CopyImage(Bitmap: TBitmap; ImgX1, ImgY1, ImgX2, ImgY2: Integer;
      DstX, DstY: Double); overload;

    procedure CopyImage(Bitmap: TBitmap; DstX, DstY: Double); overload;

  private
    procedure Render(FillColor_: Boolean); overload;
    procedure Render(Ras: PAggFontRasterizer; Sl: PAggFontScanLine); overload;

    procedure AddLine(X1, Y1, X2, Y2: Double);
    procedure UpdateRasterizerGamma;
    procedure RenderImage(Img: TAggImage; X1, Y1, X2, Y2: Integer;
      Parl: PDouble);
  end;

  { GLOBAL PROCEDURES }
  // Standalone API
function Deg2Rad(V: Double): Double;
function Rad2Deg(V: Double): Double;

function Agg2DUsesFreeType: Boolean;

function BitmapAlphaTransparency(Bitmap: TBitmap; Alpha: Byte): Boolean;

implementation


var
  GApproxScale: Double = 2.0;

type
  TAggSpanConvImageBlend = class(TAggSpanConvertor)
  private
    FMode: TAggBlendMode;
    FColor: TAggColor;
    FPixel: TAggPixelFormatProcessor; // FPixFormatCompPre
  public
    constructor Create(M: TAggBlendMode; C: TAggColor; P: TAggPixelFormatProcessor);

    procedure Convert(Span: PAggColor; X, Y: Integer; Len: Cardinal); virtual;
  end;

function Operator_is_equal(C1, C2: PAggColor): Boolean;
begin
  Result := (C1.R = C2.R) and (C1.G = C2.G) and (C1.B = C2.B) and (C1.A = C2.A);
end;

function Operator_is_NotEqual(C1, C2: PAggColor): Boolean;
begin
  Result := not Operator_is_equal(C1, C2);
end;

procedure Agg2DRenderer_render(Gr: TAgg2D; RendererBase: PRendererBaseObject;
  RenSolid: PRendererScanLineAASolidObject; FillColor_: Boolean); overload;
var
  Span: SpanGradientObject;
  Ren : RendererScanLineAAObject;
  Clr : TAggColor;
begin
  if (FillColor_ and (Gr.FFillGradientFlag = AGG_Linear)) or
    (not FillColor_ and (Gr.FLineGradientFlag = AGG_Linear)) then
    if FillColor_ then
    begin
      Span.Create(@Gr.FAllocator, @Gr.FFillGradientInterpolator,
        @Gr.FLinearGradientFunction, @Gr.FFillGradient, Gr.FFillGradientD1,
        Gr.FFillGradientD2);

      Ren.Create(RendererBase, @Span);
      RenderScanLines(@Gr.FRasterizer, @Gr.FScanLine, @Ren);

    end
    else
    begin
      Span.Create(@Gr.FAllocator, @Gr.FLineGradientInterpolator,
        @Gr.FLinearGradientFunction, @Gr.FLineGradient, Gr.FLineGradientD1,
        Gr.FLineGradientD2);

      Ren.Create(RendererBase, @Span);
      RenderScanLines(@Gr.FRasterizer, @Gr.FScanLine, @Ren);

    end
  else if (FillColor_ and (Gr.FFillGradientFlag = AGG_Radial)) or
    (not FillColor_ and (Gr.FLineGradientFlag = AGG_Radial)) then
    if FillColor_ then
    begin
      Span.Create(@Gr.FAllocator, @Gr.FFillGradientInterpolator,
        @Gr.FRadialGradientFunction, @Gr.FFillGradient, Gr.FFillGradientD1,
        Gr.FFillGradientD2);

      Ren.Create(RendererBase, @Span);
      RenderScanLines(@Gr.FRasterizer, @Gr.FScanLine, @Ren);

    end
    else
    begin
      Span.Create(@Gr.FAllocator, @Gr.FLineGradientInterpolator,
        @Gr.FRadialGradientFunction, @Gr.FLineGradient, Gr.FLineGradientD1,
        Gr.FLineGradientD2);

      Ren.Create(RendererBase, @Span);
      RenderScanLines(@Gr.FRasterizer, @Gr.FScanLine, @Ren);

    end
  else
  begin
    if FillColor_ then
      Clr.Create(@Gr.FFillColor)
    else
      Clr.Create(@Gr.FLineColor);

    RenSolid.SetColor(@Clr);
    RenderScanLines(@Gr.FRasterizer, @Gr.FScanLine, RenSolid);
  end;
end;

procedure Agg2DRenderer_render(Gr: TAgg2D; RendererBase: PRendererBaseObject;
  RenSolid: PRendererScanLineAASolidObject; Ras: PGray8AdaptorTypeObject;
  Sl: PGray8ScanLineTypeObject); overload;
var
  Span: SpanGradientObject;
  Ren : RendererScanLineAAObject;
  Clr : TAggColor;

begin
  if Gr.FFillGradientFlag = AGG_Linear then
  begin
    Span.Create(@Gr.FAllocator, @Gr.FFillGradientInterpolator,
      @Gr.FLinearGradientFunction, @Gr.FFillGradient, Gr.FFillGradientD1,
      Gr.FFillGradientD2);

    Ren.Create(RendererBase, @Span);
    RenderScanLines(Ras, Sl, @Ren);

  end
  else if Gr.FFillGradientFlag = AGG_Radial then
  begin
    Span.Create(@Gr.FAllocator, @Gr.FFillGradientInterpolator,
      @Gr.FRadialGradientFunction, @Gr.FFillGradient, Gr.FFillGradientD1,
      Gr.FFillGradientD2);

    Ren.Create(RendererBase, @Span);
    RenderScanLines(Ras, Sl, @Ren);

  end
  else
  begin
    Clr.Create(@Gr.FFillColor);
    RenSolid.SetColor(@Clr);
    RenderScanLines(Ras, Sl, RenSolid);
  end;
end;

procedure Agg2DRendererRenderImage(Gr: TAgg2D; Img: TAggImage;
  RendererBase: PRendererBaseObject; Interpolator: PSpanInterpolatorLinearObject);
var
  Blend: TAggSpanConvImageBlend;

  Si: SpanImageFilterRgbaObject;
  Sg: SpanImageFilterRgbaObjectNNObject;
  Sb: SpanImageFilterRgbaBilinearObject;
  S2: SpanImageFilterRgba2x2Object;
  Sa: SpanImageResampleRgbaAffineObject;
  Sc: SpanConverterObject;
  Ri: RendererScanLineAAObject;

  Clr: TAggColor;

  Resample: Boolean;

  Sx, Sy: Double;

begin
  case Gr.FPixelFormat of
    Pf32bit:
      Blend.Create(Gr.FImageBlendMode, Gr.FImageBlendColor,
        @Gr.FPixFormatCompPre);

  else
    Blend.Create(Gr.FImageBlendMode, Gr.FImageBlendColor, nil);
  end;

  if Gr.FImageFilter = AGG_NoFilter then
  begin
    Clr.Clear;
    Sg.Create(@Gr.FAllocator, @Img.FRenderingBuffer, @Clr, Interpolator, CAggOrderRgba);
    Sc.Create(@Sg, @Blend);
    Ri.Create(RendererBase, @Sc);

    RenderScanLines(@Gr.FRasterizer, @Gr.FScanLine, @Ri);

  end
  else
  begin
    Resample := Gr.FImageResample = AGG_ResampleAlways;

    if Gr.FImageResample = AGG_ResampleOnZoomOut then
    begin
      Interpolator._transformer.ScalingAbs(@Sx, @Sy);

      if (Sx > 1.125) or (Sy > 1.125) then
        Resample := True;
    end;

    if Resample then
    begin
      Clr.Clear;
      Sa.Create(@Gr.FAllocator, @Img.FRenderingBuffer, @Clr, Interpolator,
        @Gr.FImageFilterLut, CAggOrderRgba);

      Sc.Create(@Sa, @Blend);
      Ri.Create(RendererBase, @Sc);

      RenderScanLines(@Gr.FRasterizer, @Gr.FScanLine, @Ri);

    end
    else if Gr.FImageFilter = AGGBilinear then
    begin
      Clr.Clear;
      Sb.Create(@Gr.FAllocator, @Img.FRenderingBuffer, @Clr, Interpolator,
        CAggOrderRgba);

      Sc.Create(@Sb, @Blend);
      Ri.Create(RendererBase, @Sc);

      RenderScanLines(@Gr.FRasterizer, @Gr.FScanLine, @Ri);

    end
    else if Gr.FImageFilterLut.Diameter = 2 then
    begin
      Clr.Clear;
      S2.Create(@Gr.FAllocator, @Img.FRenderingBuffer, @Clr, Interpolator,
        @Gr.FImageFilterLut, CAggOrderRgba);

      Sc.Create(@S2, @Blend);
      Ri.Create(RendererBase, @Sc);

      RenderScanLines(@Gr.FRasterizer, @Gr.FScanLine, @Ri);

    end
    else
    begin
      Clr.Clear;
      Si.Create(@Gr.FAllocator, @Img.FRenderingBuffer, @Clr, Interpolator,
        @Gr.FImageFilterLut, CAggOrderRgba);

      Sc.Create(@Si, @Blend);
      Ri.Create(RendererBase, @Sc);

      RenderScanLines(@Gr.FRasterizer, @Gr.FScanLine, @Ri);
    end;
  end;
end;

function Agg2DUsesFreeType: Boolean;
begin
{$IFDEF AGG2D_USE_FREETYPE}
  Result := True;
{$ELSE }
  Result := False;
{$ENDIF}
end;

constructor TAggSpanConvImageBlend.Create(M: TAggBlendMode; C: TAggColor;
  P: TAggPixelFormatProcessor);
begin
  FMode := M;
  FColor := C;
  FPixel := P;
end;

procedure TAggSpanConvImageBlend.Convert(Span: PAggColor; X, Y: Integer;
  Len: Cardinal);
var
  L2, A: Cardinal;

  S2: PAggColor;

begin
  if (FMode <> CBlendDst) and (FPixel <> nil) then
  begin { ! }
    L2 := Len;
    S2 := PAggColor(Span);

    repeat
      CompOpAdaptorClipToDestinationRgbaPre(FPixel, Cardinal(FMode),
        PInt8u(S2), FColor.R, FColor.G, FColor.B, CAggBaseMask, CAggCoverFull);

      Inc(PtrComp(S2), SizeOf(TAggColor));
      Dec(L2);

    until L2 = 0;
  end;

  if FColor.A < CAggBaseMask then
  begin
    L2 := Len;
    S2 := PAggColor(Span);
    A := FColor.A;

    repeat
      S2.R := (S2.R * A) shr CAggBaseShift;
      S2.G := (S2.G * A) shr CAggBaseShift;
      S2.B := (S2.B * A) shr CAggBaseShift;
      S2.A := (S2.A * A) shr CAggBaseShift;

      Inc(PtrComp(S2), SizeOf(TAggColor));
      Dec(L2);

    until L2 = 0;
  end;
end;


{ TAggImage }

constructor TAggImage.Create;
begin
  FRenderingBuffer.Create;
end;

destructor TAggImage.Destroy;
begin
  FRenderingBuffer.Free;
end;

function TAggImage.Attach(Bitmap: TBitmap; Flip: Boolean): Boolean;
var
  Buffer: Pointer;
  Stride: Integer;

begin
  Result := False;

  if Assigned(Bitmap) and not Bitmap.Empty then
    case Bitmap.PixelFormat of
      Pf32bit:
        begin
          { Rendering Buffer }
          Stride := Integer(Bitmap.ScanLine[1]) - Integer(Bitmap.ScanLine[0]);

          if Stride < 0 then
            Buffer := Bitmap.ScanLine[Bitmap.Height - 1]
          else
            Buffer := Bitmap.ScanLine[0];

          if Flip then
            Stride := Stride * -1;

          FRenderingBuffer.Attach(Buffer, Bitmap.Width, Bitmap.Height, Stride);

          { OK }
          Result := True;
        end;
    end;
end;

function TAggImage.Width: Integer;
begin
  Result := FRenderingBuffer.GetWidth;
end;

function TAggImage.Height: Integer;
begin
  Result := FRenderingBuffer.GetHeight;
end;

constructor TAggRasterizerGamma.Create(Alpha, Gamma: Double);
begin
  FAlpha.Create(Alpha);
  FGamma.Create(Gamma);
end;

function TAggRasterizerGamma.FuncOperatorGamma(X: Double): Double;
begin
  Result := FAlpha.FuncOperatorGamma(FGamma.FuncOperatorGamma(X));
end;

{ BUILD }
constructor TAgg2D.Create;
begin
  FRenderingBuffer.Create;

  FPixelFormat := Pf32bit;

  PixelFormatRgba32(FPixFormat, @FRenderingBuffer);
  PixelFormatCustomBlendRgba(FPixFormatComp, @FRenderingBuffer, @CompOpAdaptorRgba,
    CAggOrderRgba);
  PixelFormatRgba32(FPixFormatPre, @FRenderingBuffer);
  PixelFormatCustomBlendRgba(FPixFormatCompPre, @FRenderingBuffer, @CompOpAdaptorRgba,
    CAggOrderRgba);

  FRendererBase.Create(@FPixFormat);
  FRendererBaseComp.Create(@FPixFormatComp);
  FRendererBasePre.Create(@FPixFormatPre);
  FRendererBaseCompPre.Create(@FPixFormatCompPre);

  FRenSolid.Create(@FRendererBase);
  FRenSolidComp.Create(@FRendererBaseComp);

  FAllocator.Create;
  FClipBox.Create(0, 0, 0, 0);

  FBlendMode := CBlendAlpha;
  FImageBlendMode := CBlendDst;

  FImageBlendColor.Black;

  FScanLine.Create;
  FRasterizer.Create;

  FMasterAlpha := 1.0;
  FAntiAliasGamma := 1.0;

  FFillColor.White;
  FLineColor.Black;

  FFillGradient.Create(256, SizeOf(TAggColor));
  FLineGradient.Create(256, SizeOf(TAggColor));

  FLineCap := AGG_CapRound;
  FLineJoin := AGG_JoinRound;

  FFillGradientFlag := AGG_Solid;
  FLineGradientFlag := AGG_Solid;

  FFillGradientMatrix.Create;
  FLineGradientMatrix.Create;

  FFillGradientD1 := 0.0;
  FLineGradientD1 := 0.0;
  FFillGradientD2 := 100.0;
  FLineGradientD2 := 100.0;

  FTextAngle := 0.0;
  FTextAlignX := AGG_AlignLeft;
  FTextAlignY := AGG_AlignBottom;
  FTextHints := True;
  FFontHeight := 0.0;
  FFontAscent := 0.0;
  FFontDescent := 0.0;

  FFontCacheType := AGG_RasterFontCache;
  FImageFilter := AGGBilinear;
  FImageResample := AGG_NoResample;

  FGammaNone.Create;

  FImageFilterBilinear.Create;
  FImageFilterHanning.Create;
  FImageFilterHermite.Create;
  FImageFilterQuadric.Create;
  FImageFilterBicubic.Create;
  FImageFilterCatrom.Create;
  FImageFilterSpline16.Create;
  FImageFilterSpline36.Create;
  FImageFilterBlackman144.Create;

  FImageFilterLut.Create(@FImageFilterBilinear, True);

  FLinearGradientFunction.Create;
  FRadialGradientFunction.Create;

  FFillGradientInterpolator.Create(@FFillGradientMatrix);
  FLineGradientInterpolator.Create(@FLineGradientMatrix);

  FLineWidth := 1;
  FEvenOddFlag := False;

  FImageFlip := False;

  FPath.Create;
  FTransform.Create;

  FConvCurve.Create(@FPath);
  FConvStroke.Create(@FConvCurve);

  FPathTransform.Create(@FConvCurve, @FTransform);
  FStrokeTransform.Create(@FConvStroke, @FTransform);

{$IFDEF AGG2D_USE_FREETYPE}
  FFontEngine.Create;
{$ELSE }
  FFontDC := GetDC(0);
  FFontEngine.Create(FFontDC);
{$ENDIF}

  FFontCacheManager.Create(@FFontEngine);

  LineCap(FLineCap);
  LineJoin(FLineJoin);
end;

destructor TAgg2D.Destroy;
begin
  FRenderingBuffer.Free;

  FAllocator.Free;

  FScanLine.Free;
  FRasterizer.Free;

  FFillGradient.Free;
  FLineGradient.Free;

  FImageFilterLut.Free;
  FPath.Free;

  FConvCurve.Free;
  FConvStroke.Free;

  FFontEngine.Free;
  FFontCacheManager.Free;

{$IFNDEF AGG2D_USE_FREETYPE}
  ReleaseDC(0, FFontDC);
{$ENDIF}
end;

function TAgg2D.Attach(Bitmap: TBitmap; Flip_y: Boolean = False): Boolean;
var
  Buffer: Pointer;
  Stride: Integer;

begin
  Result := False;

  if Assigned(Bitmap) and not Bitmap.Empty then
    case Bitmap.PixelFormat of
      Pf24bit, Pf32bit:
        begin
          { Rendering Buffer }
          Stride := Integer(Bitmap.ScanLine[1]) - Integer(Bitmap.ScanLine[0]);

          if Stride < 0 then
            Buffer := Bitmap.ScanLine[Bitmap.Height - 1]
          else
            Buffer := Bitmap.ScanLine[0];

          if Flip_y then
            Stride := Stride * -1;

          FRenderingBuffer.Attach(Buffer, Bitmap.Width, Bitmap.Height, Stride);

          { Pixel Format }
          FPixelFormat := Bitmap.PixelFormat;

          case FPixelFormat of
            Pf24bit:
              begin
                PixelFormatRgb24(FPixFormat, @FRenderingBuffer);
                PixelFormatRgb24(FPixFormatPre, @FRenderingBuffer);
              end;

            Pf32bit:
              begin
                PixelFormatRgba32(FPixFormat, @FRenderingBuffer);
                PixelFormatCustomBlendRgba(FPixFormatComp, @FRenderingBuffer,
                  @CompOpAdaptorRgba, CAggOrderRgba);
                PixelFormatRgba32(FPixFormatPre, @FRenderingBuffer);
                PixelFormatCustomBlendRgba(FPixFormatCompPre, @FRenderingBuffer,
                  @CompOpAdaptorRgba, CAggOrderRgba);
              end;
          end;

          { Reset state }
          FRendererBase.ResetClipping(True);
          FRendererBaseComp.ResetClipping(True);
          FRendererBasePre.ResetClipping(True);
          FRendererBaseCompPre.ResetClipping(True);

          ResetTransformations;

          LineWidth(1.0);
          LineColor(0, 0, 0);
          FillColor(255, 255, 255);

          TextAlignment(AGG_AlignLeft, AGG_AlignBottom);

          ClipBox(0, 0, Bitmap.Width, Bitmap.Height);
          LineCap(AGG_CapRound);
          LineJoin(AGG_JoinRound);
          FlipText(False);

          ImageFilter(AGGBilinear);
          ImageResample(AGG_NoResample);
          ImageFlip(False);

          FMasterAlpha := 1.0;
          FAntiAliasGamma := 1.0;

          FRasterizer.Gamma(@FGammaNone);

          FBlendMode := CBlendAlpha;

          FillEvenOdd(False);
          BlendMode(CBlendAlpha);

          FlipText(False);
          ResetPath;

          ImageFilter(AGGBilinear);
          ImageResample(AGG_NoResample);

          { OK }
          Result := True;
        end;
    end;
end;

procedure TAgg2D.ClipBox(X1, Y1, X2, Y2: Double);
var
  Rx1, Ry1, Rx2, Ry2: Integer;

begin
  FClipBox.Create(X1, Y1, X2, Y2);

  Rx1 := Trunc(X1);
  Ry1 := Trunc(Y1);
  Rx2 := Trunc(X2);
  Ry2 := Trunc(Y2);

  FRendererBase.SetClipBox(Rx1, Ry1, Rx2, Ry2);
  FRendererBaseComp.SetClipBox(Rx1, Ry1, Rx2, Ry2);
  FRendererBasePre.SetClipBox(Rx1, Ry1, Rx2, Ry2);
  FRendererBaseCompPre.SetClipBox(Rx1, Ry1, Rx2, Ry2);

  FRasterizer.ClipBox(X1, Y1, X2, Y2);
end;

function TAgg2D.ClipBox: TAggRectD;
begin
  Result := FClipBox;
end;

procedure TAgg2D.ClearAll(C: TAggColor);
var
  Clr: TAggColor;

begin
  Clr.Create(@C);
  FRendererBase.Clear(@Clr);
end;

procedure TAgg2D.ClearAll(R, G, B: Byte; A: Byte = 255);
var
  Clr: TAggColor;

begin
  Clr.CreateInt(R, G, B, A);
  ClearAll(Clr);
end;

procedure TAgg2D.ClearClipBox(C: TAggColor);
var
  Clr: TAggColor;

begin
  Clr.Create(@C);

  FRendererBase.CopyBar(0, 0, FRendererBase.GetWidth, FRendererBase.GetHeight, @Clr);
end;

procedure TAgg2D.ClearClipBox(R, G, B: Byte; A: Byte = 255);
var
  Clr: TAggColor;

begin
  Clr.CreateInt(R, G, B, A);
  ClearClipBox(Clr);
end;

procedure TAgg2D.WorldToScreen(X, Y: PDouble);
begin
  FTransform.Transform(@FTransform, PDouble(X), PDouble(Y));
end;

procedure TAgg2D.ScreenToWorld(X, Y: PDouble);
begin
  FTransform.InverseTransform(@FTransform, PDouble(X), PDouble(Y));
end;

function TAgg2D.WorldToScreen(Scalar: Double): Double;
var
  X1, Y1, X2, Y2: Double;

begin
  X1 := 0;
  Y1 := 0;
  X2 := Scalar;
  Y2 := Scalar;

  WorldToScreen(@X1, @Y1);
  WorldToScreen(@X2, @Y2);

  Result := Sqrt((X2 - X1) * (X2 - X1) + (Y2 - Y1) * (Y2 - Y1)) * 0.7071068;
end;

function TAgg2D.ScreenToWorld(Scalar: Double): Double;
var
  X1, Y1, X2, Y2: Double;

begin
  X1 := 0;
  Y1 := 0;
  X2 := Scalar;
  Y2 := Scalar;

  ScreenToWorld(@X1, @Y1);
  ScreenToWorld(@X2, @Y2);

  Result := Sqrt((X2 - X1) * (X2 - X1) + (Y2 - Y1) * (Y2 - Y1)) * 0.7071068;
end;

procedure TAgg2D.AlignPoint(X, Y: PDouble);
begin
  WorldToScreen(X, Y);

  X^ := Floor(X^) + 0.5;
  Y^ := Floor(Y^) + 0.5;

  ScreenToWorld(X, Y);
end;

function TAgg2D.InBox(WorldX, WorldY: Double): Boolean;
begin
  WorldToScreen(@WorldX, @WorldY);

  Result := FRendererBase.Inbox(Trunc(WorldX), Trunc(WorldY));
end;

procedure TAgg2D.BlendMode(M: TAggBlendMode);
begin
  FBlendMode := M;

  FPixFormatComp.SetCompOp(Cardinal(M));
  FPixFormatCompPre.SetCompOp(Cardinal(M));
end;

function TAgg2D.BlendMode: TAggBlendMode;
begin
  Result := FBlendMode;
end;

procedure TAgg2D.MasterAlpha(A: Double);
begin
  FMasterAlpha := A;

  UpdateRasterizerGamma;
end;

function TAgg2D.MasterAlpha: Double;
begin
  Result := FMasterAlpha;
end;

procedure TAgg2D.AntiAliasGamma(G: Double);
begin
  FAntiAliasGamma := G;

  UpdateRasterizerGamma;
end;

function TAgg2D.AntiAliasGamma: Double;
begin
  Result := FAntiAliasGamma;
end;

procedure TAgg2D.FillColor(C: TAggColor);
begin
  FFillColor := C;
  FFillGradientFlag := AGG_Solid;
end;

procedure TAgg2D.FillColor(C: Rgba8);
var
  Clr: TAggColor;
begin
  Clr.Create(C);
  FillColor(Clr);
end;

procedure TAgg2D.FillColor(R, G, B: Byte; A: Byte = 255);
var
  Clr: TAggColor;
begin
  Clr.CreateInt(R, G, B, A);
  FillColor(Clr);
end;

procedure TAgg2D.NoFill;
var
  Clr: TAggColor;

begin
  Clr.Clear;
  FillColor(Clr);
end;

procedure TAgg2D.LineColor(C: TAggColor);
begin
  FLineColor := C;
  FLineGradientFlag := AGG_Solid;
end;

procedure TAgg2D.LineColor(R, G, B: Byte; A: Byte = 255);
var
  Clr: TAggColor;

begin
  Clr.CreateInt(R, G, B, A);
  LineColor(Clr);
end;

procedure TAgg2D.NoLine;
var
  Clr: TAggColor;

begin
  Clr.Clear;
  LineColor(Clr);
end;

function TAgg2D.FillColor: TAggColor;
begin
  Result := FFillColor;
end;

function TAgg2D.LineColor: TAggColor;
begin
  Result := FLineColor;
end;

procedure TAgg2D.FillLinearGradient(X1, Y1, X2, Y2: Double; C1, C2: TAggColor;
  Profile: Double = 1.0);
var
  I, StartGradient, EndGradient: Integer;

  K, Angle: Double;

  C: TAggColor;

  Clr: TAggColor;
  Tar: TransAffineRotationObject;
  Tat: TransAffineTranslationObject;

begin
  StartGradient := 128 - Trunc(Profile * 127.0);
  EndGradient := 128 + Trunc(Profile * 127.0);

  if EndGradient <= StartGradient then
    EndGradient := StartGradient + 1;

  K := 1.0 / (EndGradient - StartGradient);
  I := 0;

  while I < StartGradient do
  begin
    Clr.Create(@C1);

    Move(Clr, FFillGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < EndGradient do
  begin
    C := C1.Gradient(@C2, (I - StartGradient) * K);

    Clr.Create(@C);

    Move(Clr, FFillGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < 256 do
  begin
    Clr.Create(@C2);

    Move(Clr, FFillGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  Angle := ArcTan2(Y2 - Y1, X2 - X1);

  FFillGradientMatrix.Reset;

  Tar.Create(Angle);

  FFillGradientMatrix.Multiply(@Tar);

  Tat.Create(X1, Y1);

  FFillGradientMatrix.Multiply(@Tat);
  FFillGradientMatrix.Multiply(@FTransform);
  FFillGradientMatrix.Invert;

  FFillGradientD1 := 0.0;
  FFillGradientD2 := Sqrt((X2 - X1) * (X2 - X1) + (Y2 - Y1) * (Y2 - Y1));
  FFillGradientFlag := AGG_Linear;

  FFillColor.Black; // Set some real color
end;

procedure TAgg2D.LineLinearGradient(X1, Y1, X2, Y2: Double; C1, C2: TAggColor;
  Profile: Double = 1.0);
var
  I, StartGradient, EndGradient: Integer;

  K, Angle: Double;

  C: TAggColor;

  Clr: TAggColor;
  Tar: TransAffineRotationObject;
  Tat: TransAffineTranslationObject;

begin
  StartGradient := 128 - Trunc(Profile * 128.0);
  EndGradient := 128 + Trunc(Profile * 128.0);

  if EndGradient <= StartGradient then
    EndGradient := StartGradient + 1;

  K := 1.0 / (EndGradient - StartGradient);
  I := 0;

  while I < StartGradient do
  begin
    Clr.Create(@C1);

    Move(Clr, FLineGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < EndGradient do
  begin
    C := C1.Gradient(@C2, (I - StartGradient) * K);

    Clr.Create(@C);

    Move(Clr, FLineGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < 256 do
  begin
    Clr.Create(@C2);

    Move(Clr, FLineGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  Angle := ArcTan2(Y2 - Y1, X2 - X1);

  FLineGradientMatrix.Reset;

  Tar.Create(Angle);

  FLineGradientMatrix.Multiply(@Tar);

  Tat.Create(X1, Y1);

  FLineGradientMatrix.Multiply(@Tat);
  FLineGradientMatrix.Multiply(@FTransform);
  FLineGradientMatrix.Invert;

  FLineGradientD1 := 0.0;
  FLineGradientD2 := Sqrt((X2 - X1) * (X2 - X1) + (Y2 - Y1) * (Y2 - Y1));
  FLineGradientFlag := AGG_Linear;

  FLineColor.Black; // Set some real color
end;

procedure TAgg2D.FillRadialGradient(X, Y, R: Double; C1, C2: TAggColor;
  Profile: Double = 1.0);
var
  I, StartGradient, EndGradient: Integer;

  K: Double;
  C: TAggColor;

  Clr: TAggColor;
  Tat: TransAffineTranslationObject;

begin
  StartGradient := 128 - Trunc(Profile * 127.0);
  EndGradient := 128 + Trunc(Profile * 127.0);

  if EndGradient <= StartGradient then
    EndGradient := StartGradient + 1;

  K := 1.0 / (EndGradient - StartGradient);
  I := 0;

  while I < StartGradient do
  begin
    Clr.Create(@C1);

    Move(Clr, FFillGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < EndGradient do
  begin
    C := C1.Gradient(@C2, (I - StartGradient) * K);

    Clr.Create(@C);

    Move(Clr, FFillGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < 256 do
  begin
    Clr.Create(@C2);

    Move(Clr, FFillGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  FFillGradientD2 := WorldToScreen(R);

  WorldToScreen(@X, @Y);

  FFillGradientMatrix.Reset;

  Tat.Create(X, Y);

  FFillGradientMatrix.Multiply(@Tat);
  FFillGradientMatrix.Invert;

  FFillGradientD1 := 0;
  FFillGradientFlag := AGG_Radial;

  FFillColor.Black; // Set some real color
end;

procedure TAgg2D.LineRadialGradient(X, Y, R: Double; C1, C2: TAggColor;
  Profile: Double = 1.0);
var
  I, StartGradient, EndGradient: Integer;

  K: Double;
  C: TAggColor;

  Clr: TAggColor;
  Tat: TransAffineTranslationObject;

begin
  StartGradient := 128 - Trunc(Profile * 128.0);
  EndGradient := 128 + Trunc(Profile * 128.0);

  if EndGradient <= StartGradient then
    EndGradient := StartGradient + 1;

  K := 1.0 / (EndGradient - StartGradient);
  I := 0;

  while I < StartGradient do
  begin
    Clr.Create(@C1);

    Move(Clr, FLineGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < EndGradient do
  begin
    C := C1.Gradient(@C2, (I - StartGradient) * K);

    Clr.Create(@C);

    Move(Clr, FLineGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < 256 do
  begin
    Clr.Create(@C2);

    Move(Clr, FLineGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  FLineGradientD2 := WorldToScreen(R);

  WorldToScreen(@X, @Y);

  FLineGradientMatrix.Reset;

  Tat.Create(X, Y);

  FLineGradientMatrix.Multiply(@Tat);
  FLineGradientMatrix.Invert;

  FLineGradientD1 := 0;
  FLineGradientFlag := AGG_Radial;

  FLineColor.Black; // Set some real color
end;

procedure TAgg2D.FillRadialGradient(X, Y, R: Double; C1, C2, C3: TAggColor);
var
  I: Integer;
  C: TAggColor;

  Clr: TAggColor;
  Tat: TransAffineTranslationObject;

begin
  I := 0;

  while I < 128 do
  begin
    C := C1.Gradient(@C2, I / 127.0);

    Clr.Create(@C);

    Move(Clr, FFillGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < 256 do
  begin
    C := C2.Gradient(@C3, (I - 128) / 127.0);

    Clr.Create(@C);

    Move(Clr, FFillGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  FFillGradientD2 := WorldToScreen(R);

  WorldToScreen(@X, @Y);

  FFillGradientMatrix.Reset;

  Tat.Create(X, Y);

  FFillGradientMatrix.Multiply(@Tat);
  FFillGradientMatrix.Invert;

  FFillGradientD1 := 0;
  FFillGradientFlag := AGG_Radial;

  FFillColor.Black; // Set some real color
end;

procedure TAgg2D.LineRadialGradient(X, Y, R: Double; C1, C2, C3: TAggColor);
var
  I: Integer;
  C: TAggColor;

  Clr: TAggColor;
  Tat: TransAffineTranslationObject;

begin
  I := 0;

  while I < 128 do
  begin
    C := C1.Gradient(@C2, I / 127.0);

    Clr.Create(@C);

    Move(Clr, FLineGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < 256 do
  begin
    C := C2.Gradient(@C3, (I - 128) / 127.0);

    Clr.Create(@C);

    Move(Clr, FLineGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  FLineGradientD2 := WorldToScreen(R);

  WorldToScreen(@X, @Y);

  FLineGradientMatrix.Reset;

  Tat.Create(X, Y);

  FLineGradientMatrix.Multiply(@Tat);
  FLineGradientMatrix.Invert;

  FLineGradientD1 := 0;
  FLineGradientFlag := AGG_Radial;

  FLineColor.Black; // Set some real color
end;

procedure TAgg2D.FillRadialGradient(X, Y, R: Double);
var
  Tat: TransAffineTranslationObject;

begin
  FFillGradientD2 := WorldToScreen(R);

  WorldToScreen(@X, @Y);

  FFillGradientMatrix.Reset;

  Tat.Create(X, Y);

  FFillGradientMatrix.Multiply(@Tat);
  FFillGradientMatrix.Invert;

  FFillGradientD1 := 0;
end;

procedure TAgg2D.LineRadialGradient(X, Y, R: Double);
var
  Tat: TransAffineTranslationObject;

begin
  FLineGradientD2 := WorldToScreen(R);

  WorldToScreen(@X, @Y);

  FLineGradientMatrix.Reset;

  Tat.Create(X, Y);

  FLineGradientMatrix.Multiply(@Tat);
  FLineGradientMatrix.Invert;

  FLineGradientD1 := 0;
end;

procedure TAgg2D.LineWidth(W: Double);
begin
  FLineWidth := W;

  FConvStroke.SetWidth(W);
end;

function TAgg2D.LineWidth: Double;
begin
  Result := FLineWidth;
end;

procedure TAgg2D.LineCap(Cap: TAggLineCap);
begin
  FLineCap := Cap;

  FConvStroke.SetLineCap(Cap);
end;

function TAgg2D.LineCap: TAggLineCap;
begin
  Result := FLineCap;
end;

procedure TAgg2D.LineJoin(Join: TAggLineJoin);
begin
  FLineJoin := Join;

  FConvStroke.SetLineJoin(Join);
end;

function TAgg2D.LineJoin: TAggLineJoin;
begin
  Result := FLineJoin;
end;

procedure TAgg2D.FillEvenOdd(EvenOddFlag: Boolean);
begin
  FEvenOddFlag := EvenOddFlag;

  if EvenOddFlag then
    FRasterizer.FillingRule(frEvenOdd)
  else
    FRasterizer.FillingRule(frNonZero);
end;

function TAgg2D.FillEvenOdd: Boolean;
begin
  Result := FEvenOddFlag;
end;

function TAgg2D.Transformations: TAggTransformations;
begin
  FTransform.StoreTo(@Result.AffineMatrix[0]);
end;

procedure TAgg2D.Transformations(Tr: PAggTransformations);
begin
  FTransform.LoadFrom(@Tr.AffineMatrix[0]);

  FConvCurve.SetApproximationScale(WorldToScreen(1.0) * GApproxScale);
  FConvStroke.SetApproximationScale(WorldToScreen(1.0) * GApproxScale);
end;

procedure TAgg2D.ResetTransformations;
begin
  FTransform.Reset;
end;

procedure TAgg2D.Affine(Tr: PAggAffine);
begin
  FTransform.Multiply(Tr);

  FConvCurve.SetApproximationScale(WorldToScreen(1.0) * GApproxScale);
  FConvStroke.SetApproximationScale(WorldToScreen(1.0) * GApproxScale);
end;

procedure TAgg2D.Affine(Tr: PAggTransformations);
var
  Ta: TransAffineObject;

begin
  Ta.Create(Tr.AffineMatrix[0], Tr.AffineMatrix[1], Tr.AffineMatrix[2],
    Tr.AffineMatrix[3], Tr.AffineMatrix[4], Tr.AffineMatrix[5]);

  Affine(PAggAffine(@Ta));
end;

procedure TAgg2D.Rotate(Angle: Double);
var
  Tar: TransAffineRotationObject;

begin
  Tar.Create(Angle);

  FTransform.Multiply(@Tar);
end;

procedure TAgg2D.Scale(Sx, Sy: Double);
var
  Tas: TransAffineScalingObject;

begin
  Tas.Create(Sx, Sy);

  FTransform.Multiply(@Tas);

  FConvCurve.SetApproximationScale(WorldToScreen(1.0) * GApproxScale);
  FConvStroke.SetApproximationScale(WorldToScreen(1.0) * GApproxScale);
end;

procedure TAgg2D.Skew(Sx, Sy: Double);
var
  Tas: TransAffineSkewingObject;

begin
  Tas.Create(Sx, Sy);

  FTransform.Multiply(@Tas);
end;

procedure TAgg2D.Translate(X, Y: Double);
var
  Tat: TransAffineTranslationObject;

begin
  Tat.Create(X, Y);

  FTransform.Multiply(@Tat);
end;

procedure TAgg2D.Parallelogram(X1, Y1, X2, Y2: Double; Para: PDouble);
var
  Ta: TransAffineObject;

begin
  Ta.Create(X1, Y1, X2, Y2, PAggParallelogram(Para));

  FTransform.Multiply(@Ta);

  FConvCurve.SetApproximationScale(WorldToScreen(1.0) * GApproxScale);
  FConvStroke.SetApproximationScale(WorldToScreen(1.0) * GApproxScale);
end;

procedure TAgg2D.Viewport(WorldX1, WorldY1, WorldX2, WorldY2, ScreenX1,
  ScreenY1, ScreenX2, ScreenY2: Double; Opt: TAggViewportOption = AGG_XMidYMid);
var
  Vp: TransViewportObject;
  Mx: TransAffineObject;

begin
  Vp.Create;

  case Opt of
    AGG_Anisotropic:
      Vp.PreserveAspectRatio(0.0, 0.0, arStretch);

    AGG_XMinYMin:
      Vp.PreserveAspectRatio(0.0, 0.0, arMeet);

    AGG_XMidYMin:
      Vp.PreserveAspectRatio(0.5, 0.0, arMeet);

    AGG_XMaxYMin:
      Vp.PreserveAspectRatio(1.0, 0.0, arMeet);

    AGG_XMinYMid:
      Vp.PreserveAspectRatio(0.0, 0.5, arMeet);

    AGG_XMidYMid:
      Vp.PreserveAspectRatio(0.5, 0.5, arMeet);

    AGG_XMaxYMid:
      Vp.PreserveAspectRatio(1.0, 0.5, arMeet);

    AGG_XMinYMax:
      Vp.PreserveAspectRatio(0.0, 1.0, arMeet);

    AGG_XMidYMax:
      Vp.PreserveAspectRatio(0.5, 1.0, arMeet);

    AGG_XMaxYMax:
      Vp.PreserveAspectRatio(1.0, 1.0, arMeet);
  end;

  Vp.WorldViewport(WorldX1, WorldY1, WorldX2, WorldY2);
  Vp.DeviceViewport(ScreenX1, ScreenY1, ScreenX2, ScreenY2);

  Mx.Create;

  Vp.ToAffine(@Mx);
  FTransform.Multiply(@Mx);

  FConvCurve.SetApproximationScale(WorldToScreen(1.0) * GApproxScale);
  FConvStroke.SetApproximationScale(WorldToScreen(1.0) * GApproxScale);
end;

procedure TAgg2D.Line(X1, Y1, X2, Y2: Double);
begin
  FPath.RemoveAll;

  AddLine(X1, Y1, X2, Y2);
  DrawPath(AGG_StrokeOnly);
end;

procedure TAgg2D.Triangle(X1, Y1, X2, Y2, X3, Y3: Double);
begin
  FPath.RemoveAll;
  FPath.MoveTo(X1, Y1);
  FPath.LineTo(X2, Y2);
  FPath.LineTo(X3, Y3);
  FPath.ClosePolygon;

  DrawPath(AGG_FillAndStroke);
end;

procedure TAgg2D.Rectangle(X1, Y1, X2, Y2: Double);
begin
  FPath.RemoveAll;
  FPath.MoveTo(X1, Y1);
  FPath.LineTo(X2, Y1);
  FPath.LineTo(X2, Y2);
  FPath.LineTo(X1, Y2);
  FPath.ClosePolygon;

  DrawPath(AGG_FillAndStroke);
end;

procedure TAgg2D.RoundedRect(X1, Y1, X2, Y2, R: Double);
var
  Rc: RoundedRectObject;

begin
  FPath.RemoveAll;
  Rc.Create(X1, Y1, X2, Y2, R);

  Rc.Normalize_radius;
  Rc.SetApproximationScale(WorldToScreen(1.0) * GApproxScale);

  FPath.AddPath(Rc, 0, False);

  DrawPath(AGG_FillAndStroke);
end;

procedure TAgg2D.RoundedRect(X1, Y1, X2, Y2, Rx, Ry: Double);
var
  Rc: RoundedRectObject;

begin
  FPath.RemoveAll;
  Rc.Create;

  Rc.Rect(X1, Y1, X2, Y2);
  Rc.Radius(Rx, Ry);
  Rc.Normalize_radius;

  FPath.AddPath(Rc, 0, False);

  DrawPath(AGG_FillAndStroke);
end;

procedure TAgg2D.RoundedRect(X1, Y1, X2, Y2, RxBottom, RyBottom, RxTop,
  RyTop: Double);
var
  Rc: RoundedRectObject;

begin
  FPath.RemoveAll;
  Rc.Create;

  Rc.Rect(X1, Y1, X2, Y2);
  Rc.Radius(RxBottom, RyBottom, RxTop, RyTop);
  Rc.Normalize_radius;

  Rc.SetApproximationScale(WorldToScreen(1.0) * GApproxScale);

  FPath.AddPath(Rc, 0, False);

  DrawPath(AGG_FillAndStroke);
end;

procedure TAgg2D.EllipseObject(Cx, Cy, Rx, Ry: Double);
var
  El: BezierArcObject;

begin
  FPath.RemoveAll;

  El.Create(Cx, Cy, Rx, Ry, 0, 2 * Pi);

  FPath.AddPath(El, 0, False);
  FPath.ClosePolygon;

  DrawPath(AGG_FillAndStroke);
end;

procedure TAgg2D.Arc(Cx, Cy, Rx, Ry, Start, Sweep: Double);
var
  Ar: { bezier_ } AggArc.Arc;

begin
  FPath.RemoveAll;

  Ar.Create(Cx, Cy, Rx, Ry, Sweep, Start, False);

  FPath.AddPath(Ar, 0, False);

  DrawPath(AGG_StrokeOnly);
end;

procedure TAgg2D.Star(Cx, Cy, R1, R2, StartAngle: Double; NumRays: Integer);
var
  Da, A, X, Y: Double;

  I: Integer;

begin
  FPath.RemoveAll;

  Da := Pi / NumRays;
  A := StartAngle;

  I := 0;

  while I < NumRays do
  begin
    X := Cos(A) * R2 + Cx;
    Y := Sin(A) * R2 + Cy;

    if I <> 0 then
      FPath.LineTo(X, Y)
    else
      FPath.MoveTo(X, Y);

    A := A + Da;

    FPath.LineTo(Cos(A) * R1 + Cx, Sin(A) * R1 + Cy);

    A := A + Da;

    Inc(I);
  end;

  ClosePolygon;
  DrawPath(AGG_FillAndStroke);
end;

procedure TAgg2D.Curve(X1, Y1, X2, Y2, X3, Y3: Double);
begin
  FPath.RemoveAll;
  FPath.MoveTo(X1, Y1);
  FPath.Curve3(X2, Y2, X3, Y3);

  DrawPath(AGG_StrokeOnly);
end;

procedure TAgg2D.Curve(X1, Y1, X2, Y2, X3, Y3, X4, Y4: Double);
begin
  FPath.RemoveAll;
  FPath.MoveTo(X1, Y1);
  FPath.Curve4(X2, Y2, X3, Y3, X4, Y4);

  DrawPath(AGG_StrokeOnly);
end;

procedure TAgg2D.Polygon(Xy: PDouble; NumPoints: Integer);
begin
  FPath.RemoveAll;
  FPath.AddPoly(PDoubleArray2(Xy), NumPoints);

  ClosePolygon;
  DrawPath(AGG_FillAndStroke);
end;

procedure TAgg2D.Polyline(Xy: PDouble; NumPoints: Integer);
begin
  FPath.RemoveAll;
  FPath.AddPoly(PDoubleArray2(Xy), NumPoints);

  DrawPath(AGG_StrokeOnly);
end;

procedure TAgg2D.FlipText(Flip: Boolean);
begin
  FFontEngine.SetFlipY(not Flip);
end;

procedure TAgg2D.Font(FileName: AnsiString; Height: Double;
  Bold: Boolean = False; Italic: Boolean = False;
  Cache: TAggFontCacheType = AGG_VectorFontCache; Angle: Double = 0.0);
var
  B: Integer;

begin
  FTextAngle := Angle;
  FFontHeight := Height;
  FFontCacheType := Cache;

{$IFDEF AGG2D_USE_FREETYPE}
  if Cache = AGG_VectorFontCache then
    FFontEngine.LoadFont(PAnsiChar(@FileName[1]), 0, grOutline)
  else
    FFontEngine.LoadFont(PAnsiChar(@FileName[1]), 0, grAgggray8);

  FFontEngine.SetHinting(FTextHints);

  if Cahce = AGG_VectorFontCache then
    FFontEngine.SetHeight(Height)
  else
    FFontEngine.SetHeight(WorldToScreen(Height));
{$ELSE}
  FFontEngine.SetHinting(FTextHints);

  if Bold then
    B := 700
  else
    B := 400;

  if Cache = AGG_VectorFontCache then
    FFontEngine.CreateFont_(PAnsiChar(@FileName[1]), grOutline, Height,
      0.0, B, Italic)
  else
    FFontEngine.CreateFont_(PAnsiChar(@FileName[1]), grAgggray8,
      WorldToScreen(Height), 0.0, B, Italic);
{$ENDIF}
end;

function TAgg2D.FontHeight: Double;
begin
  Result := FFontHeight;
end;

procedure TAgg2D.TextAlignment(AlignX, AlignY: TAggTextAlignment);
begin
  FTextAlignX := AlignX;
  FTextAlignY := AlignY;
end;

function TAgg2D.TextHints: Boolean;
begin
  Result := FTextHints;
end;

procedure TAgg2D.TextHints(Hints: Boolean);
begin
  FTextHints := Hints;
end;

function TAgg2D.TextWidth(Str: AnsiString): Double;
var
  X, Y : Double;
  First: Boolean;
  Glyph: PAggGlyphCache;
  Str_ : PAnsiChar;

begin
  X := 0;
  Y := 0;

  First := True;
  Str_ := @Str[1];

  while Str_^ <> #0 do
  begin
    Glyph := FFontCacheManager.Glyph(Int32u(Str_^));

    if Glyph <> nil then
    begin
      if not First then
        FFontCacheManager.AddKerning(@X, @Y);

      X := X + Glyph.AdvanceX;
      Y := Y + Glyph.AdvanceY;

      First := False;
    end;

    Inc(PtrComp(Str_));
  end;

  if FFontCacheType = AGG_VectorFontCache then
    Result := X
  else
    Result := ScreenToWorld(X);
end;

procedure TAgg2D.Text(X, Y: Double; Str: AnsiString; RoundOff: Boolean = False;
  Ddx: Double = 0.0; Ddy: Double = 0.0);
var
  Dx, Dy, Asc, Start_x, Start_y: Double;

  Glyph: PAggGlyphCache;

  Mtx : TransAffineObject;
  Str_: PAnsiChar;

  I: Integer;

  Tat: TransAffineTranslationObject;
  Tar: TransAffineRotationObject;

  Tr: ConvTransformObject;

begin
  Dx := 0.0;
  Dy := 0.0;

  case FTextAlignX of
    AGG_AlignCenter:
      Dx := -TextWidth(Str) * 0.5;

    AGG_AlignRight:
      Dx := -TextWidth(Str);
  end;

  Asc := FontHeight;
  Glyph := FFontCacheManager.Glyph(Int32u('H'));

  if Glyph <> nil then
    Asc := Glyph.Bounds.Y2 - Glyph.Bounds.Y1;

  if FFontCacheType = AGG_RasterFontCache then
    Asc := ScreenToWorld(Asc);

  case FTextAlignY of
    AGG_AlignCenter:
      Dy := -Asc * 0.5;

    AGG_AlignTop:
      Dy := -Asc;
  end;

  if FFontEngine.GetFlipY then
    Dy := -Dy;

  Mtx.Create;

  Start_x := X + Dx;
  Start_y := Y + Dy;

  if RoundOff then
  begin
    Start_x := Trunc(Start_x);
    Start_y := Trunc(Start_y);
  end;

  Start_x := Start_x + Ddx;
  Start_y := Start_y + Ddy;

  Tat.Create(-X, -Y);
  Mtx.Multiply(@Tat);

  Tar.Create(FTextAngle);
  Mtx.Multiply(@Tar);

  Tat.Create(X, Y);
  Mtx.Multiply(@Tat);

  Tr.Create(FFontCacheManager.PathAdaptor, @Mtx);

  if FFontCacheType = AGG_RasterFontCache then
    WorldToScreen(@Start_x, @Start_y);

  I := 0;

  Str_ := @Str[1];

  while PAnsiChar(PtrComp(Str_) + I * SizeOf(AnsiChar))^ <> #0 do
  begin
    Glyph := FFontCacheManager.Glyph
      (Int32u(PAnsiChar(PtrComp(Str_) + I * SizeOf(AnsiChar))^));

    if Glyph <> nil then
    begin
      if I <> 0 then
        FFontCacheManager.AddKerning(@X, @Y);

      FFontCacheManager.InitEmbeddedAdaptors(Glyph, Start_x, Start_y);

      if Glyph.DataType = Glyph_dataOutline then
      begin
        FPath.RemoveAll;
        FPath.AddPath(Tr, 0, False);

        DrawPath;
      end;

      if Glyph.DataType = Glyph_data_gray8 then
      begin
        Render(FFontCacheManager.Gray8Adaptor,
          FFontCacheManager.Gray8ScanLine);
      end;

      Start_x := Start_x + Glyph.AdvanceX;
      Start_y := Start_y + Glyph.AdvanceY;
    end;

    Inc(I);
  end;
end;

procedure TAgg2D.ResetPath;
begin
  FPath.RemoveAll;
  FPath.MoveTo(0, 0);
end;

procedure TAgg2D.MoveTo(X, Y: Double);
begin
  FPath.MoveTo(X, Y);
end;

procedure TAgg2D.MoveRel(Dx, Dy: Double);
begin
  FPath.MoveRelative(Dx, Dy);
end;

procedure TAgg2D.LineTo(X, Y: Double);
begin
  FPath.LineTo(X, Y);
end;

procedure TAgg2D.LineRel(Dx, Dy: Double);
begin
  FPath.LineRelative(Dx, Dy);
end;

procedure TAgg2D.HorLineTo(X: Double);
begin
  FPath.HorizontalLineTo(X);
end;

procedure TAgg2D.HorLineRel(Dx: Double);
begin
  FPath.HorizontalLineRelative(Dx);
end;

procedure TAgg2D.VerLineTo(Y: Double);
begin
  FPath.VerticalLineTo(Y);
end;

procedure TAgg2D.VerLineRel(Dy: Double);
begin
  FPath.VerticalLineRelative(Dy);
end;

procedure TAgg2D.ArcTo(Rx, Ry, Angle: Double; LargeArcFlag, SweepFlag: Boolean;
  X, Y: Double);
begin
  FPath.ArcTo(Rx, Ry, Angle, LargeArcFlag, SweepFlag, X, Y);
end;

procedure TAgg2D.ArcRel(Rx, Ry, Angle: Double; LargeArcFlag, SweepFlag: Boolean;
  Dx, Dy: Double);
begin
  FPath.ArcRelative(Rx, Ry, Angle, LargeArcFlag, SweepFlag, Dx, Dy);
end;

procedure TAgg2D.QuadricCurveTo(XCtrl, YCtrl, XTo, YTo: Double);
begin
  FPath.Curve3(XCtrl, YCtrl, XTo, YTo);
end;

procedure TAgg2D.QuadricCurveRel(DxCtrl, DyCtrl, DxTo, DyTo: Double);
begin
  FPath.Curve3ObjectRelative(DxCtrl, DyCtrl, DxTo, DyTo);
end;

procedure TAgg2D.QuadricCurveTo(XTo, YTo: Double);
begin
  FPath.Curve3(XTo, YTo);
end;

procedure TAgg2D.QuadricCurveRel(DxTo, DyTo: Double);
begin
  FPath.Curve3ObjectRelative(DxTo, DyTo);
end;

procedure TAgg2D.CubicCurveTo(XCtrl1, YCtrl1, XCtrl2, YCtrl2, XTo, YTo: Double);
begin
  FPath.Curve4(XCtrl1, YCtrl1, XCtrl2, YCtrl2, XTo, YTo);
end;

procedure TAgg2D.CubicCurveRel(DxCtrl1, DyCtrl1, DxCtrl2, DyCtrl2, DxTo,
  DyTo: Double);
begin
  FPath.Curve4ObjectRelative(DxCtrl1, DyCtrl1, DxCtrl2, DyCtrl2, DxTo, DyTo);
end;

procedure TAgg2D.CubicCurveTo(XCtrl2, YCtrl2, XTo, YTo: Double);
begin
  FPath.Curve4(XCtrl2, YCtrl2, XTo, YTo);
end;

procedure TAgg2D.CubicCurveRel(DxCtrl2, DyCtrl2, DxTo, DyTo: Double);
begin
  FPath.Curve4ObjectRelative(DxCtrl2, DyCtrl2, DxTo, DyTo);
end;

procedure TAgg2D.AddEllipseObject(Cx, Cy, Rx, Ry: Double; Dir: TAggDirection);
var
  Ar: BezierArcObject;

begin
  if Dir = AGG_CCW then
    Ar.Create(Cx, Cy, Rx, Ry, 0, 2 * Pi)
  else
    Ar.Create(Cx, Cy, Rx, Ry, 0, -2 * Pi);

  FPath.AddPath(Ar, 0, False);
  FPath.ClosePolygon;
end;

procedure TAgg2D.ClosePolygon;
begin
  FPath.ClosePolygon;
end;

procedure TAgg2D.DrawPath(Flag: TAggDrawPathFlag = AGG_FillAndStroke);
begin
  FRasterizer.Reset;

  case Flag of
    AGG_FillOnly:
      if FFillColor.A <> 0 then
      begin
        FRasterizer.AddPath(FPathTransform);

        Render(True);
      end;

    AGG_StrokeOnly:
      if (FLineColor.A <> 0) and (FLineWidth > 0.0) then
      begin
        FRasterizer.AddPath(FStrokeTransform);

        Render(False);
      end;

    AGG_FillAndStroke:
      begin
        if FFillColor.A <> 0 then
        begin
          FRasterizer.AddPath(FPathTransform);

          Render(True);
        end;

        if (FLineColor.A <> 0) and (FLineWidth > 0.0) then
        begin
          FRasterizer.AddPath(FStrokeTransform);

          Render(False);
        end;
      end;

    AGG_FillWitHorizontalLineColor:
      if FLineColor.A <> 0 then
      begin
        FRasterizer.AddPath(FPathTransform);

        Render(False);
      end;
  end;
end;

procedure TAgg2D.ImageFilter(F: TAggImageFilter);
begin
  FImageFilter := F;

  case F of
    AGGBilinear:
      FImageFilterLut.Calculate(@FImageFilterBilinear, True);

    AGG_Hanning:
      FImageFilterLut.Calculate(@FImageFilterHanning, True);

    AGG_Hermite:
      FImageFilterLut.Calculate(@FImageFilterHermite, True);

    AGG_Quadric:
      FImageFilterLut.Calculate(@FImageFilterQuadric, True);

    AGG_Bicubic:
      FImageFilterLut.Calculate(@FImageFilterBicubic, True);

    AGG_Catrom:
      FImageFilterLut.Calculate(@FImageFilterCatrom, True);

    AGG_Spline16:
      FImageFilterLut.Calculate(@FImageFilterSpline16, True);

    AGG_Spline36:
      FImageFilterLut.Calculate(@FImageFilterSpline36, True);

    AGG_Blackman144:
      FImageFilterLut.Calculate(@FImageFilterBlackman144, True);
  end;
end;

function TAgg2D.ImageFilter: TAggImageFilter;
begin
  Result := FImageFilter;
end;

procedure TAgg2D.ImageResample(F: TAggImageResample);
begin
  FImageResample := F;
end;

procedure TAgg2D.ImageFlip(F: Boolean);
begin
  FImageFlip := F;
end;

function TAgg2D.ImageResample: TAggImageResample;
begin
  Result := FImageResample;
end;

procedure TAgg2D.TransformImage(Bitmap: TBitmap;
  ImgX1, ImgY1, ImgX2, ImgY2: Integer; DstX1, DstY1, DstX2, DstY2: Double);
var
  Parall: array [0..5] of Double;
  Image : TAggImage;

begin
  Image.Create;

  if Image.Attach(Bitmap, FImageFlip) then
  begin
    ResetPath;
    MoveTo(DstX1, DstY1);
    LineTo(DstX2, DstY1);
    LineTo(DstX2, DstY2);
    LineTo(DstX1, DstY2);
    ClosePolygon;

    Parall[0] := DstX1;
    Parall[1] := DstY1;
    Parall[2] := DstX2;
    Parall[3] := DstY1;
    Parall[4] := DstX2;
    Parall[5] := DstY2;

    RenderImage(@Image, ImgX1, ImgY1, ImgX2, ImgY2, @Parall[0]);

    Image.Free;
  end;
end;

procedure TAgg2D.TransformImage(Bitmap: TBitmap;
  DstX1, DstY1, DstX2, DstY2: Double);
var
  Parall: array [0..5] of Double;
  Image : TAggImage;

begin
  Image.Create;

  if Image.Attach(Bitmap, FImageFlip) then
  begin
    ResetPath;
    MoveTo(DstX1, DstY1);
    LineTo(DstX2, DstY1);
    LineTo(DstX2, DstY2);
    LineTo(DstX1, DstY2);
    ClosePolygon;

    Parall[0] := DstX1;
    Parall[1] := DstY1;
    Parall[2] := DstX2;
    Parall[3] := DstY1;
    Parall[4] := DstX2;
    Parall[5] := DstY2;

    RenderImage(@Image, 0, 0, Image.FRenderingBuffer.GetWidth, Image.FRenderingBuffer.GetHeight,
      @Parall[0]);

    Image.Free;
  end;
end;

procedure TAgg2D.TransformImage(Bitmap: TBitmap;
  ImgX1, ImgY1, ImgX2, ImgY2: Integer; Parallelo: PDouble);
var
  Image: TAggImage;

begin
  Image.Create;

  if Image.Attach(Bitmap, FImageFlip) then
  begin
    ResetPath;

    MoveTo(PDouble(PtrComp(Parallelo) + 0 * SizeOf(Double))^,
      PDouble(PtrComp(Parallelo) + 1 * SizeOf(Double))^);

    LineTo(PDouble(PtrComp(Parallelo) + 2 * SizeOf(Double))^,
      PDouble(PtrComp(Parallelo) + 3 * SizeOf(Double))^);

    LineTo(PDouble(PtrComp(Parallelo) + 4 * SizeOf(Double))^,
      PDouble(PtrComp(Parallelo) + 5 * SizeOf(Double))^);

    LineTo(PDouble(PtrComp(Parallelo) + 0 * SizeOf(Double))^ +
      PDouble(PtrComp(Parallelo) + 4 * SizeOf(Double))^ -
      PDouble(PtrComp(Parallelo) + 2 * SizeOf(Double))^,
      PDouble(PtrComp(Parallelo) + 1 * SizeOf(Double))^ +
      PDouble(PtrComp(Parallelo) + 5 * SizeOf(Double))^ -
      PDouble(PtrComp(Parallelo) + 3 * SizeOf(Double))^);

    ClosePolygon;

    RenderImage(@Image, ImgX1, ImgY1, ImgX2, ImgY2, Parallelo);

    Image.Free;
  end;
end;

procedure TAgg2D.TransformImage(Bitmap: TBitmap; Parallelo: PDouble);
var
  Image: TAggImage;

begin
  Image.Create;

  if Image.Attach(Bitmap, FImageFlip) then
  begin
    ResetPath;

    MoveTo(PDouble(PtrComp(Parallelo) + 0 * SizeOf(Double))^,
      PDouble(PtrComp(Parallelo) + 1 * SizeOf(Double))^);

    LineTo(PDouble(PtrComp(Parallelo) + 2 * SizeOf(Double))^,
      PDouble(PtrComp(Parallelo) + 3 * SizeOf(Double))^);

    LineTo(PDouble(PtrComp(Parallelo) + 4 * SizeOf(Double))^,
      PDouble(PtrComp(Parallelo) + 5 * SizeOf(Double))^);

    LineTo(PDouble(PtrComp(Parallelo) + 0 * SizeOf(Double))^ +
      PDouble(PtrComp(Parallelo) + 4 * SizeOf(Double))^ -
      PDouble(PtrComp(Parallelo) + 2 * SizeOf(Double))^,
      PDouble(PtrComp(Parallelo) + 1 * SizeOf(Double))^ +
      PDouble(PtrComp(Parallelo) + 5 * SizeOf(Double))^ -
      PDouble(PtrComp(Parallelo) + 3 * SizeOf(Double))^);

    ClosePolygon;

    RenderImage(@Image, 0, 0, Image.FRenderingBuffer.GetWidth, Image.FRenderingBuffer.GetHeight,
      Parallelo);

    Image.Free;
  end;
end;

procedure TAgg2D.TransformImagePath(Bitmap: TBitmap;
  ImgX1, ImgY1, ImgX2, ImgY2: Integer; DstX1, DstY1, DstX2, DstY2: Double);
var
  Parall: array [0..5] of Double;
  Image : TAggImage;

begin
  Image.Create;

  if Image.Attach(Bitmap, FImageFlip) then
  begin
    Parall[0] := DstX1;
    Parall[1] := DstY1;
    Parall[2] := DstX2;
    Parall[3] := DstY1;
    Parall[4] := DstX2;
    Parall[5] := DstY2;

    RenderImage(@Image, ImgX1, ImgY1, ImgX2, ImgY2, @Parall[0]);

    Image.Free;
  end;
end;

procedure TAgg2D.TransformImagePath(Bitmap: TBitmap;
  DstX1, DstY1, DstX2, DstY2: Double);
var
  Parall: array [0..5] of Double;
  Image : TAggImage;

begin
  Image.Create;

  if Image.Attach(Bitmap, FImageFlip) then
  begin
    Parall[0] := DstX1;
    Parall[1] := DstY1;
    Parall[2] := DstX2;
    Parall[3] := DstY1;
    Parall[4] := DstX2;
    Parall[5] := DstY2;

    RenderImage(@Image, 0, 0, Image.FRenderingBuffer.GetWidth, Image.FRenderingBuffer.GetHeight,
      @Parall[0]);

    Image.Free;
  end;
end;

procedure TAgg2D.TransformImagePath(Bitmap: TBitmap;
  ImgX1, ImgY1, ImgX2, ImgY2: Integer; Parallelo: PDouble);
var
  Image: TAggImage;

begin
  Image.Create;

  if Image.Attach(Bitmap, FImageFlip) then
  begin
    RenderImage(@Image, ImgX1, ImgY1, ImgX2, ImgY2, Parallelo);

    Image.Free;
  end;
end;

procedure TAgg2D.TransformImagePath(Bitmap: TBitmap; Parallelo: PDouble);
var
  Image: TAggImage;

begin
  Image.Create;

  if Image.Attach(Bitmap, FImageFlip) then
  begin
    RenderImage(@Image, 0, 0, Image.FRenderingBuffer.GetWidth, Image.FRenderingBuffer.GetHeight,
      Parallelo);

    Image.Free;
  end;
end;

procedure TAgg2D.CopyImage(Bitmap: TBitmap; ImgX1, ImgY1, ImgX2, ImgY2: Integer;
  DstX, DstY: Double);
var
  R    : TRectObject;
  Image: TAggImage;

begin
  Image.Create;

  if Image.Attach(Bitmap, FImageFlip) then
  begin
    WorldToScreen(@DstX, @DstY);
    R.Create(ImgX1, ImgY1, ImgX2, ImgY2);

    FRendererBase.CopyFrom(@Image.FRenderingBuffer, @R, Trunc(DstX) - ImgX1,
      Trunc(DstY) - ImgY1);

    Image.Free;
  end;
end;

procedure TAgg2D.CopyImage(Bitmap: TBitmap; DstX, DstY: Double);
var
  Image: TAggImage;

begin
  Image.Create;

  if Image.Attach(Bitmap, FImageFlip) then
  begin
    WorldToScreen(@DstX, @DstY);

    FRendererBase.CopyFrom(@Image.FRenderingBuffer, nil, Trunc(DstX), Trunc(DstY));

    Image.Free;
  end;
end;

procedure TAgg2D.Render(FillColor_: Boolean);
begin
  if (FBlendMode = CBlendAlpha) or (FPixelFormat = Pf24bit) then
    Agg2DRenderer_render(Self, @FRendererBase, @FRenSolid, FillColor_)
  else
    Agg2DRenderer_render(Self, @FRendererBaseComp, @FRenSolidComp, FillColor_);
end;

procedure TAgg2D.Render(Ras: PAggFontRasterizer; Sl: PAggFontScanLine);
begin
  if (FBlendMode = CBlendAlpha) or (FPixelFormat = Pf24bit) then
    Agg2DRenderer_render(Self, @FRendererBase, @FRenSolid, Ras, Sl)
  else
    Agg2DRenderer_render(Self, @FRendererBaseComp, @FRenSolidComp, Ras, Sl);
end;

procedure TAgg2D.AddLine(X1, Y1, X2, Y2: Double);
begin
  FPath.MoveTo(X1, Y1);
  FPath.LineTo(X2, Y2);
end;

procedure TAgg2D.UpdateRasterizerGamma;
begin
  FGammaAgg2D.Create(FMasterAlpha, FAntiAliasGamma);
  FRasterizer.Gamma(@FGammaAgg2D);
end;

procedure TAgg2D.RenderImage(Img: TAggImage; X1, Y1, X2, Y2: Integer;
  Parl: PDouble);
var
  Mtx: TransAffineObject;

  Interpolator: SpanInterpolatorLinearObject;

begin
  Mtx.Create(X1, Y1, X2, Y2, PAggParallelogram(Parl));
  Mtx.Multiply(@FTransform);
  Mtx.Invert;

  FRasterizer.Reset;
  FRasterizer.AddPath(FPathTransform);

  Interpolator.Create(@Mtx);

  if (FBlendMode = CBlendAlpha) or (FPixelFormat = Pf24bit) then
    Agg2DRendererRenderImage(Self, Img, @FRendererBasePre, @Interpolator)
  else
    Agg2DRendererRenderImage(Self, Img, @FRendererBaseCompPre, @Interpolator);
end;

function BitmapAlphaTransparency(Bitmap: TBitmap; Alpha: Byte): Boolean;
var
  Fcx, Fcy: Integer;
  Transp  : ^Byte;

begin
  Result := False;

  if Assigned(Bitmap) and not Bitmap.Empty and (Bitmap.PixelFormat = Pf32bit)
  then
  begin
    for Fcy := 0 to Bitmap.Height - 1 do
    begin
      Transp := Pointer(PtrComp(Bitmap.ScanLine[Fcy]) + 3);

      for Fcx := 0 to Bitmap.Width - 1 do
      begin
        Transp^ := Alpha;

        Inc(PtrComp(Transp), 4);
      end;
    end;

    { OK }
    Result := True;
  end;
end;

end.

{ * }
{ ! }{ To look At }
