unit Agg2D;

// ----------------------------------------------------------------------------
// Agg2DObject - Version 1.0
// Based on Anti-Grain Geometry
// Copyright (C) 2005 Maxim Shemanarev (http://www.antigrain.com)
//
// Agg2DObject - Version 1.0 Release Milano 3 (AggPas 2.3 RM3)
// Pascal Port By: Milan Marusinec alias Milano
// milan@marusinec.sk
// http://www.aggpas.org
// Copyright (c) 2007
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

interface

{$I AggCompiler.inc}

// With this define uncommented you can use FreeType font engine
{-$DEFINE AGG2D_USE_FREETYPE }

uses
  AggBasics,
  AggMath,
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
  Windows,

{$ENDIF}
  Math;

const
  // LineJoin
  CJoinMiter = CMiterJoin;
  CJoinRound = CRoundJoin;
  CJoinBevel = CBevelJoin;

  // SetLineCap
  CCapButt = CButtCap;
  CCapSquare = CSquareCap;
  CCapRound = CRoundCap;

  // TextAlignment
  CAlignLeft = 0;
  CAlignRight = 1;
  CAlignCenter = 2;
  CAlignTop = CAlignRight;
  CAlignBottom = CAlignLeft;

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
  PAggColorRgba8 = ^TAggColorRgba8;
  TAggColorRgba8 = Rgba8;

  Affine = TransAffineObject;
  PAffine = PTransAffineObject;

  FontRasterizer = Gray8_Adaptor_Type;
  PFontRasterizer = PGray8AdaptorTypeObject;

  FontScanLine = Gray8_ScanLine_Type;
  PFontScanLine = PGray8ScanLineTypeObject;

{$IFDEF AGG2D_USE_FREETYPE }
  FontEngine = FontEngineFreetypeInt32;
{$ELSE }
  FontEngine = FontEngineWin32TrueTypeInt32Object;
{$ENDIF}

  TAggGradient = (grdSolid, grdLinear, grdRadial);
  TAggDirection = (dirCW, dirCCW);

  LineJoin_ = Integer;
  LineCap_ = Integer;
  BlendMode_ = TCompOp;

  TextAlignment = Integer;

  TAggDrawPathFlag = (dpfFillOnly, dpfStrokeOnly, dpfFillAndStroke, dpfFillWitHorizontalLineColor);

  ViewportOption = (Anisotropic, XMinYMin, XMidYMin, XMaxYMin, XMinYMid,
    XMidYMid, XMaxYMid, XMinYMax, XMidYMax, XMaxYMax);

  ImageFilter_ = (NoFilter, Bilinear, Hanning, Hermite, Quadric, Bicubic,
    Catrom, Spline16, Spline36, Blackman144);

  ImageResample_ = (NoResample, ResampleAlways, ResampleOnZoomOut);

  FontCacheType = (RasterFontCache, VectorFontCache);

  PAggTransformations = ^TAggTransformations;

  TAggTransformations = record
    AffineMatrix: array [0..5] of Double;
  end;

  TAggImage = class
  private
    FRenderingBuffer: RenderingBufferObject;
  public
    constructor Create; overload;
    constructor Create(Buf: PInt8u; Width_, Height_: Cardinal;
      Stride: Integer); overload;
    destructor Destroy; override;

    procedure Attach(Buf: PInt8u; Width_, Height_: Cardinal; Stride: Integer);

    function Width: Integer;
    function Height: Integer;

    procedure PreMultiply;
    procedure DeMultiply;
  end;

  Agg2DRasterizerGammaObject = object(VertexSourceObject)
  private
    FAlpha: GammaMultiplyObject;
    FGamma: GammaPowerObject;
  public
    constructor Create(Alpha, Gamma: Double);

    function FuncOperatorGamma(X: Double): Double; virtual;
  end;

  TAgg2D = class
  private
    FRenderingBuffer: RenderingBufferObject;

    FPixelFormat, FPixelFormatComp, FPixelFormatPre, FPixelFormatCompPre
      : PixelFormatsObject;
    FRendererBase, FRendererBaseComp, FRendererBasePre, FRendererBaseCompPre: RendererBaseObject;

    FRendererSolid, FRendererSolidComp: RendererScanLineAASolidObject;

    FAllocator: SpanAllocatorObject;
    FClipBox  : TRectDouble;

    FBlendMode, FImageBlendMode: BlendMode_;

    FImageBlendColor: TAggColorRgba8;

    FScanLine  : ScanLineU8Object;
    FRasterizer: RasterizerScanLineAAObject;

    FMasterAlpha, FAntiAliasGamma: Double;

    FFillColor, FLineColor: TAggColorRgba8;

    FFillGradient, FLineGradient: PodAutoArrayObject;

    FLineCap : LineCap_;
    FLineJoin: LineJoin_;

    FFillGradientFlag, FLineGradientFlag: TAggGradient;

    FFillGradientMatrix, FLineGradientMatrix: TransAffineObject;

    FFillGradientD1, FLineGradientD1, FFillGradientD2: Double;
    FLineGradientD2, FTextAngle: Double;
    FTextAlignX, FTextAlignY: TextAlignment;
    FTextHints: Boolean;
    FFontHeight, FFontAscent, FFontDescent: Double;
    FFontCacheType: FontCacheType;

    FImageFilter   : ImageFilter_;
    FImageResample : ImageResample_;
    FImageFilterLUT: ImageFilterLUTObject;

    FFillGradientInterpolator, FLineGradientInterpolator
      : SpanInterpolatorLinearObject;

    FLinearGradientFunction: GradientXObject;
    FRadialGradientFunction: GradientCircleObject;

    FLineWidth  : Double;
    FEvenOddFlag: Boolean;

    FPath     : PathStorageObject;
    FTransform: TransAffineObject;

    FConvCurve : ConvCurveObject;
    FConvStroke: ConvStrokeObject;

    FPathTransform, FStrokeTransform: ConvTransformObject;

{$IFNDEF AGG2D_USE_FREETYPE}
    FFontDC: HDC;
{$ENDIF}

    FFontEngine      : FontEngine;
    FFontCacheManager: FontCacheManagerObject;

    // Other Pascal-specific members
    FGammaNone : GammaNoneObject;
    FGammaAgg2D: Agg2DRasterizerGammaObject;

    FImageFilterBilinear   : ImageFilterBilinearObject;
    FImageFilterHanning    : ImageFilterHanningObject;
    FImageFilterHermite    : ImageFilterHermiteObject;
    FImageFilterQuadric    : ImageFilterQuadricObject;
    FImageFilterBicubic    : ImageFilterBicubicObject;
    FImageFilterCatrom     : ImageFilterCatromObject;
    FImageFilterSpline16   : ImageFilterSpline16Object;
    FImageFilterSpline36   : ImageFilterSpline36Object;
    FImageFilterBlackman144: ImageFilterBlackman144Object;
  public
    constructor Create;
    destructor Destroy; override;

    // Setup
    procedure Attach(Buf: PInt8u; Width_, Height_: Cardinal;
      Stride: Integer); overload;
    procedure Attach(Img: TAggImage); overload;

    procedure ClipBox(X1, Y1, X2, Y2: Double); overload;
    function ClipBox: TRectDouble; overload;

    procedure ClearAll(C: TAggColorRgba8); overload;
    procedure ClearAll(R, G, B: Cardinal; A: Cardinal = 255); overload;

    procedure ClearClipBox(C: TAggColorRgba8); overload;
    procedure ClearClipBox(R, G, B: Cardinal; A: Cardinal = 255); overload;

    // Conversions
    procedure WorldToScreen(X, Y: PDouble); overload;
    procedure ScreenToWorld(X, Y: PDouble); overload;
    function WorldToScreen(Scalar: Double): Double; overload;
    function ScreenToWorld(Scalar: Double): Double; overload;

    procedure AlignPoint(X, Y: PDouble);

    function InBox(WorldX, WorldY: Double): Boolean;

    // General Attributes
    procedure BlendMode(M: BlendMode_); overload;
    function BlendMode: BlendMode_; overload;

    procedure ImageBlendMode(M: BlendMode_); overload;
    function ImageBlendMode: BlendMode_; overload;

    procedure ImageBlendColor(C: TAggColorRgba8); overload;
    procedure ImageBlendColor(R, G, B: Cardinal; A: Cardinal = 255); overload;
    function ImageBlendColor: TAggColorRgba8; overload;

    procedure MasterAlpha(A: Double); overload;
    function MasterAlpha: Double; overload;

    procedure AntiAliasGamma(G: Double); overload;
    function AntiAliasGamma: Double; overload;

    procedure FillColor(C: TAggColorRgba8); overload;
    procedure FillColor(R, G, B: Cardinal; A: Cardinal = 255); overload;
    procedure NoFill;

    procedure LineColor(C: TAggColorRgba8); overload;
    procedure LineColor(R, G, B: Cardinal; A: Cardinal = 255); overload;
    procedure NoLine;

    function FillColor: TAggColorRgba8; overload;
    function LineColor: TAggColorRgba8; overload;

    procedure FillLinearGradient(X1, Y1, X2, Y2: Double; C1, C2: TAggColorRgba8;
      Profile: Double = 1.0);
    procedure LineLinearGradient(X1, Y1, X2, Y2: Double; C1, C2: TAggColorRgba8;
      Profile: Double = 1.0);

    procedure FillRadialGradient(X, Y, R: Double; C1, C2: TAggColorRgba8;
      Profile: Double = 1.0); overload;
    procedure LineRadialGradient(X, Y, R: Double; C1, C2: TAggColorRgba8;
      Profile: Double = 1.0); overload;

    procedure FillRadialGradient(X, Y, R: Double; C1, C2, C3: TAggColorRgba8); overload;
    procedure LineRadialGradient(X, Y, R: Double; C1, C2, C3: TAggColorRgba8); overload;

    procedure FillRadialGradient(X, Y, R: Double); overload;
    procedure LineRadialGradient(X, Y, R: Double); overload;

    procedure SetLineWidth(W: Double);
    function GetLineWidth(W: Double): Double;

    procedure SetLineCap(Cap: LineCap_); overload;
    function GetLineCap: LineCap_; overload;

    procedure SetLineJoin(Join: LineJoin_); overload;
    function GetLineJoin: LineJoin_; overload;

    procedure SetFillEvenOdd(EvenOddFlag: Boolean); overload;
    function GetFillEvenOdd: Boolean; overload;

    // Transformations
    function Transformations: TAggTransformations; overload;
    procedure Transformations(Tr: PAggTransformations); overload;
    procedure ResetTransformations;

    procedure Affine(Tr: PAffine); overload;
    procedure Affine(Tr: PAggTransformations); overload;

    procedure Rotate(Angle: Double);
    procedure Scale(Sx, Sy: Double);
    procedure Skew(Sx, Sy: Double);
    procedure Translate(X, Y: Double);

    procedure Parallelogram(X1, Y1, X2, Y2: Double; Para: PDouble);

    procedure Viewport(WorldX1, WorldY1, WorldX2, WorldY2, ScreenX1, ScreenY1,
      ScreenX2, ScreenY2: Double; Opt: ViewportOption = XMidYMid);

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

    // Text
    procedure FlipText(Flip: Boolean);

    procedure Font(FileName: PAnsiChar; Height: Double; Bold: Boolean = False;
      Italic: Boolean = False; Ch: FontCacheType = RasterFontCache;
      Angle: Double = 0.0);

    function FontHeight: Double;

    procedure TextAlignment(AlignX, AlignY: TextAlignment);

    function TextHints: Boolean; overload;
    procedure TextHints(Hints: Boolean); overload;
    function TextWidth(Str: PAnsiChar): Double;

    procedure Text(X, Y: Double; Str: PAnsiChar; RoundOff: Boolean = False;
      Ddx: Double = 0.0; Ddy: Double = 0.0);

    // Path commands
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
    procedure CubicCurveRel(XCtrl2, YCtrl2, XTo, YTo: Double); overload;

    procedure AddEllipseObject(Cx, Cy, Rx, Ry: Double; Dir: TAggDirection);
    procedure ClosePolygon;

    procedure DrawPath(Flag: TAggDrawPathFlag = dpfFillAndStroke);

    procedure DrawPathNoTransform(Flag: TAggDrawPathFlag = dpfFillAndStroke);

    // Image Transformations
    procedure ImageFilter(F: ImageFilter_); overload;
    function ImageFilter: ImageFilter_; overload;

    procedure ImageResample(F: ImageResample_); overload;
    function ImageResample: ImageResample_; overload;

    procedure TransformImage(Img: TAggImage; ImgX1, ImgY1, ImgX2, ImgY2: Integer;
      DstX1, DstY1, DstX2, DstY2: Double); overload;

    procedure TransformImage(Img: TAggImage;
      DstX1, DstY1, DstX2, DstY2: Double); overload;

    procedure TransformImage(Img: TAggImage; ImgX1, ImgY1, ImgX2, ImgY2: Integer;
      Parallelogram_: PDouble); overload;

    procedure TransformImage(Img: TAggImage;
      Parallelogram_: PDouble); overload;

    procedure TransformImagePath(Img: TAggImage;
      ImgX1, ImgY1, ImgX2, ImgY2: Integer;
      DstX1, DstY1, DstX2, DstY2: Double); overload;

    procedure TransformImagePath(Img: TAggImage;
      DstX1, DstY1, DstX2, DstY2: Double); overload;

    procedure TransformImagePath(Img: TAggImage;
      ImgX1, ImgY1, ImgX2, ImgY2: Integer; AParallelogram: PDouble); overload;

    procedure TransformImagePath(Img: TAggImage; AParallelogram: PDouble);
      overload;

    // Image Blending (no transformations available)
    procedure BlendImage(Img: TAggImage; ImgX1, ImgY1, ImgX2, ImgY2: Integer;
      DstX, DstY: Double; Alpha: Cardinal = 255); overload;

    procedure BlendImage(Img: TAggImage; DstX, DstY: Double;
      Alpha: Cardinal = 255); overload;

    // Copy image directly, together with alpha-channel
    procedure CopyImage(Img: TAggImage; ImgX1, ImgY1, ImgX2, ImgY2: Integer;
      DstX, DstY: Double); overload;

    procedure CopyImage(Img: TAggImage; DstX, DstY: Double); overload;
  private
    procedure Render(FillColor_: Boolean); overload;
    procedure Render(Ras: PFontRasterizer; Sl: PFontScanLine); overload;

    procedure AddLine(X1, Y1, X2, Y2: Double);
    procedure UpdateRasterizerGamma;
    procedure RenderImage(Img: TAggImage; X1, Y1, X2, Y2: Integer;
      Parl: PDouble);
  end;

  TAggSpanConvImageBlend = class(TAggSpanConvertor)
  private
    FMode : BlendMode_;
    FColor: TAggColorRgba8;
    FPixel: TAggPixelFormatProcessor; // FPixelFormatCompPre

  public
    constructor Create(M: BlendMode_; C: TAggColorRgba8; P: TAggPixelFormatProcessor);

    procedure Convert(Span: PAggColor; X, Y: Integer; Len: Cardinal); override;
  end;

function OperatorIsEqual(C1, C2: PAggColorRgba8): Boolean;
function OperatorIsNotEqual(C1, C2: PAggColorRgba8): Boolean;

procedure Agg2DRendererRender(Gr: TAgg2D; RendererBase: PRendererBaseObject;
  RenSolid: PRendererScanLineAASolidObject; FillColor_: Boolean); overload;

procedure Agg2DRendererRender(Gr: TAgg2D; RendererBase: PRendererBaseObject;
  RenSolid: PRendererScanLineAASolidObject; Ras: PGray8AdaptorTypeObject;
  Sl: PGray8ScanLineTypeObject); overload;

procedure Agg2DRendererRenderImage(Gr: TAgg2D; Img: TAggImage;
  RendererBase: PRendererBaseObject; Interpolator: PSpanInterpolatorLinearObject);

function Agg2DUsesFreeType: Boolean;

implementation

var
  GApproxScale: Double = 2.0;


{ TAggImage }

constructor TAggImage.Create;
begin
end;

constructor TAggImage.Create(Buf: PInt8u; Width_, Height_: Cardinal;
  Stride: Integer);
begin
  FRenderingBuffer.Create(Buf, Width_, Height_, Stride);
end;

destructor TAggImage.Destroy;
begin
  FRenderingBuffer.Free;
  inherited;
end;

procedure TAggImage.Attach(Buf: PInt8u; Width_, Height_: Cardinal; Stride: Integer);
begin
  FRenderingBuffer.Attach(Buf, Width_, Height_, Stride);
end;

function TAggImage.Width: Integer;
begin
  Result := FRenderingBuffer.GetWidth;
end;

function TAggImage.Height: Integer;
begin
  Result := FRenderingBuffer.GetHeight;
end;

procedure TAggImage.PreMultiply;
var
  Pixf: TAggPixelFormatProcessor;
begin
  { pixfmtRgba32(pixf ,@FRenderingBuffer );

    pixf.preMultiply; {! }
end;

procedure TAggImage.DeMultiply;
var
  Pixf: TAggPixelFormatProcessor;
begin
  { pixfmtRgba32(pixf ,@FRenderingBuffer );

    pixf.deMultiply; {! }
end;


{ Agg2DRasterizerGammaObject }

constructor Agg2DRasterizerGammaObject.Create(Alpha, Gamma: Double);
begin
  FAlpha.Create(Alpha);
  FGamma.Create(Gamma);
end;

function Agg2DRasterizerGammaObject.FuncOperatorGamma(X: Double): Double;
begin
  Result := FAlpha.FuncOperatorGamma(FGamma.FuncOperatorGamma(X));
end;


{ TAgg2D }

constructor TAgg2D.Create;
begin
  FRenderingBuffer.Create;

  PixelFormatRgba32(FPixelFormat, @FRenderingBuffer);
  PixelFormatCustomBlendRgba(FPixelFormatComp, @FRenderingBuffer, @CompOpAdaptorRgba,
    CAggOrderRgba);
  PixelFormatRgba32(FPixelFormatPre, @FRenderingBuffer);
  PixelFormatCustomBlendRgba(FPixelFormatCompPre, @FRenderingBuffer, @CompOpAdaptorRgba,
    CAggOrderRgba);

  FRendererBase.Create(@FPixelFormat);
  FRendererBaseComp.Create(@FPixelFormatComp);
  FRendererBasePre.Create(@FPixelFormatPre);
  FRendererBaseCompPre.Create(@FPixelFormatCompPre);

  FRendererSolid.Create(@FRendererBase);
  FRendererSolidComp.Create(@FRendererBaseComp);

  FAllocator.Create;
  FClipBox.Create(0, 0, 0, 0);

  FBlendMode := CBlendAlpha;
  FImageBlendMode := CBlendDst;

  FImageBlendColor.Create(0, 0, 0);

  FScanLine.Create;
  FRasterizer.Create;

  FMasterAlpha := 1.0;
  FAntiAliasGamma := 1.0;

  FFillColor.Create(255, 255, 255);
  FLineColor.Create(0, 0, 0);

  FFillGradient.Create(256, SizeOf(TAggColor));
  FLineGradient.Create(256, SizeOf(TAggColor));

  FLineCap := CCapRound;
  FLineJoin := CJoinRound;

  FFillGradientFlag := grdSolid;
  FLineGradientFlag := grdSolid;

  FFillGradientMatrix.Create;
  FLineGradientMatrix.Create;

  FFillGradientD1 := 0.0;
  FLineGradientD1 := 0.0;
  FFillGradientD2 := 100.0;
  FLineGradientD2 := 100.0;

  FTextAngle := 0.0;
  FTextAlignX := CAlignLeft;
  FTextAlignY := CAlignBottom;
  FTextHints := True;
  FFontHeight := 0.0;
  FFontAscent := 0.0;
  FFontDescent := 0.0;

  FFontCacheType := RasterFontCache;
  FImageFilter := Bilinear;
  FImageResample := NoResample;

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

  FImageFilterLUT.Create(@FImageFilterBilinear, True);

  FLinearGradientFunction.Create;
  FRadialGradientFunction.Create;

  FFillGradientInterpolator.Create(@FFillGradientMatrix);
  FLineGradientInterpolator.Create(@FLineGradientMatrix);

  FLineWidth := 1;
  FEvenOddFlag := False;

  FPath.Create;
  FTransform.Create;

  FConvCurve.Create(@FPath);
  FConvStroke.Create(@FConvCurve);

  FPathTransform.Create(@FConvCurve, @FTransform);
  FStrokeTransform.Create(@FConvStroke, @FTransform);

{$IFDEF AGG2D_USE_FREETYPE}
  FFontEngine.Create;
{$ELSE}
  FFontDC := GetDC(0);

  FFontEngine.Create(FFontDC);
{$ENDIF}

  FFontCacheManager.Create(@FFontEngine);

  SetLineCap(FLineCap);
  SetLineJoin(FLineJoin);
end;

destructor TAgg2D.Destroy;
begin
  FRenderingBuffer.Free;

  FAllocator.Free;

  FScanLine.Free;
  FRasterizer.Free;

  FFillGradient.Free;
  FLineGradient.Free;

  FImageFilterLUT.Free;
  FPath.Free;

  FConvCurve.Free;
  FConvStroke.Free;

  FFontEngine.Free;
  FFontCacheManager.Free;

{$IFNDEF AGG2D_USE_FREETYPE}
  ReleaseDC(0, FFontDC);
{$ENDIF}
end;

procedure TAgg2D.Attach(Buf: PInt8u; Width_, Height_: Cardinal; Stride: Integer);
begin
  FRenderingBuffer.Attach(Buf, Width_, Height_, Stride);

  FRendererBase.ResetClipping(True);
  FRendererBaseComp.ResetClipping(True);
  FRendererBasePre.ResetClipping(True);
  FRendererBaseCompPre.ResetClipping(True);

  ResetTransformations;

  SetLineWidth(1.0);
  LineColor(0, 0, 0);
  FillColor(255, 255, 255);

  TextAlignment(CAlignLeft, CAlignBottom);

  ClipBox(0, 0, Width_, Height_);
  SetLineCap(CCapRound);
  SetLineJoin(CJoinRound);
  FlipText(False);

  ImageFilter(Bilinear);
  ImageResample(NoResample);

  FMasterAlpha := 1.0;
  FAntiAliasGamma := 1.0;

  FRasterizer.Gamma(@FGammaNone);

  FBlendMode := CBlendAlpha;
end;

procedure TAgg2D.Attach(Img: TAggImage);
begin
  Attach(Img.FRenderingBuffer.GetBuffer, Img.FRenderingBuffer.GetWidth, Img.FRenderingBuffer.GetHeight,
    Img.FRenderingBuffer.GetStride);
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

function TAgg2D.ClipBox: TRectDouble;
begin
  Result := FClipBox;
end;

procedure TAgg2D.ClearAll(C: TAggColorRgba8);
var
  Clr: TAggColor;
begin
  Clr.Create(C);
  FRendererBase.Clear(@Clr);
end;

procedure TAgg2D.ClearAll(R, G, B: Cardinal; A: Cardinal = 255);
var
  Clr: TAggColorRgba8;
begin
  Clr.Create(R, G, B, A);
  ClearAll(Clr);
end;

procedure TAgg2D.ClearClipBox(C: TAggColorRgba8);
var
  Clr: TAggColor;
begin
  Clr.Create(C);

  FRendererBase.CopyBar(0, 0, FRendererBase.GetWidth, FRendererBase.GetHeight, @Clr);
end;

procedure TAgg2D.ClearClipBox(R, G, B: Cardinal; A: Cardinal = 255);
var
  Clr: TAggColorRgba8;
begin
  Clr.Create(R, G, B, A);
  ClearClipBox(Clr);
end;

procedure TAgg2D.WorldToScreen(X, Y: PDouble);
begin
  FTransform.Transform(@FTransform, X, Y);
end;

procedure TAgg2D.ScreenToWorld(X, Y: PDouble);
begin
  FTransform.InverseTransform(@FTransform, X, Y);
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

procedure TAgg2D.BlendMode(M: BlendMode_);
begin
  FBlendMode := M;

  FPixelFormatComp.SetCompOp(Cardinal(M));
  FPixelFormatCompPre.SetCompOp(Cardinal(M));
end;

function TAgg2D.BlendMode: BlendMode_;
begin
  Result := FBlendMode;
end;

procedure TAgg2D.ImageBlendMode(M: BlendMode_);
begin
  FImageBlendMode := M;
end;

function TAgg2D.ImageBlendMode: BlendMode_;
begin
  Result := FImageBlendMode;
end;

procedure TAgg2D.ImageBlendColor(C: TAggColorRgba8);
begin
  FImageBlendColor := C;
end;

procedure TAgg2D.ImageBlendColor(R, G, B: Cardinal; A: Cardinal = 255);
var
  Clr: TAggColorRgba8;
begin
  Clr.Create(R, G, B, A);
  ImageBlendColor(Clr);
end;

function TAgg2D.ImageBlendColor: TAggColorRgba8;
begin
  Result := FImageBlendColor;
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

procedure TAgg2D.FillColor(C: TAggColorRgba8);
begin
  FFillColor := C;
  FFillGradientFlag := grdSolid;
end;

procedure TAgg2D.FillColor(R, G, B: Cardinal; A: Cardinal = 255);
var
  Clr: TAggColorRgba8;
begin
  Clr.Create(R, G, B, A);
  FillColor(Clr);
end;

procedure TAgg2D.NoFill;
var
  Clr: TAggColorRgba8;
begin
  Clr.Create(0, 0, 0, 0);
  FillColor(Clr);
end;

procedure TAgg2D.LineColor(C: TAggColorRgba8);
begin
  FLineColor := C;
  FLineGradientFlag := grdSolid;
end;

procedure TAgg2D.LineColor(R, G, B: Cardinal; A: Cardinal = 255);
var
  Clr: TAggColorRgba8;
begin
  Clr.Create(R, G, B, A);
  LineColor(Clr);
end;

procedure TAgg2D.NoLine;
var
  Clr: TAggColorRgba8;
begin
  Clr.Create(0, 0, 0, 0);
  LineColor(Clr);
end;

function TAgg2D.FillColor: TAggColorRgba8;
begin
  Result := FFillColor;
end;

function TAgg2D.LineColor: TAggColorRgba8;
begin
  Result := FLineColor;
end;

procedure TAgg2D.FillLinearGradient(X1, Y1, X2, Y2: Double; C1, C2: TAggColorRgba8;
  Profile: Double = 1.0);
var
  I, StartGradient, EndGradient: Integer;

  K, Angle: Double;

  C: TAggColorRgba8;

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
    Clr.Create(C1);

    Move(Clr, FFillGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < EndGradient do
  begin
    C := C1.Gradient(C2, (I - StartGradient) * K);

    Clr.Create(C);

    Move(Clr, FFillGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < 256 do
  begin
    Clr.Create(C2);

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
  FFillGradientFlag := grdLinear;

  FFillColor.Create(0, 0, 0); // Set some real TAggColorRgba8
end;

procedure TAgg2D.LineLinearGradient(X1, Y1, X2, Y2: Double; C1, C2: TAggColorRgba8;
  Profile: Double = 1.0);
var
  I, StartGradient, EndGradient: Integer;

  K, Angle: Double;

  C: TAggColorRgba8;

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
    Clr.Create(C1);

    Move(Clr, FLineGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < EndGradient do
  begin
    C := C1.Gradient(C2, (I - StartGradient) * K);

    Clr.Create(C);

    Move(Clr, FLineGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < 256 do
  begin
    Clr.Create(C2);

    Move(Clr, FLineGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  Angle := ArcTan2(Y2 - Y1, X2 - X1);

  FLineGradientMatrix.Reset;

  Tar.Create(Angle);

  FLineGradientMatrix.Multiply(@Tar);

  Tat.Create(X1, Y1);

  FLineGradientMatrix.Multiply(@Tat);
  FLineGradientMatrix.Multiply(@FTransform); { ! }
  FLineGradientMatrix.Invert;

  FLineGradientD1 := 0.0;
  FLineGradientD2 := Sqrt((X2 - X1) * (X2 - X1) + (Y2 - Y1) * (Y2 - Y1));
  FLineGradientFlag := grdLinear;

  FLineColor.Create(0, 0, 0); // Set some real TAggColorRgba8
end;

procedure TAgg2D.FillRadialGradient(X, Y, R: Double; C1, C2: TAggColorRgba8;
  Profile: Double = 1.0);
var
  I, StartGradient, EndGradient: Integer;

  K: Double;
  C: TAggColorRgba8;

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
    Clr.Create(C1);

    Move(Clr, FFillGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < EndGradient do
  begin
    C := C1.Gradient(C2, (I - StartGradient) * K);

    Clr.Create(C);

    Move(Clr, FFillGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < 256 do
  begin
    Clr.Create(C2);

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
  FFillGradientFlag := grdRadial;

  FFillColor.Create(0, 0, 0); // Set some real TAggColorRgba8
end;

procedure TAgg2D.LineRadialGradient(X, Y, R: Double; C1, C2: TAggColorRgba8;
  Profile: Double = 1.0);
var
  I, StartGradient, EndGradient: Integer;

  K: Double;
  C: TAggColorRgba8;

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
    Clr.Create(C1);

    Move(Clr, FLineGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < EndGradient do
  begin
    C := C1.Gradient(C2, (I - StartGradient) * K);

    Clr.Create(C);

    Move(Clr, FLineGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < 256 do
  begin
    Clr.Create(C2);

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
  FLineGradientFlag := grdRadial;

  FLineColor.Create(0, 0, 0); // Set some real TAggColorRgba8
end;

procedure TAgg2D.FillRadialGradient(X, Y, R: Double; C1, C2, C3: TAggColorRgba8);
var
  I: Integer;
  C: TAggColorRgba8;

  Clr: TAggColor;
  Tat: TransAffineTranslationObject;
begin
  I := 0;

  while I < 128 do
  begin
    C := C1.Gradient(C2, I / 127.0);

    Clr.Create(C);

    Move(Clr, FFillGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < 256 do
  begin
    C := C2.Gradient(C3, (I - 128) / 127.0);

    Clr.Create(C);

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
  FFillGradientFlag := grdRadial;

  FFillColor.Create(0, 0, 0); // Set some real TAggColorRgba8
end;

procedure TAgg2D.LineRadialGradient(X, Y, R: Double; C1, C2, C3: TAggColorRgba8);
var
  I: Integer;
  C: TAggColorRgba8;

  Clr: TAggColor;
  Tat: TransAffineTranslationObject;
begin
  I := 0;

  while I < 128 do
  begin
    C := C1.Gradient(C2, I / 127.0);

    Clr.Create(C);

    Move(Clr, FLineGradient[I]^, SizeOf(TAggColor));
    Inc(I);
  end;

  while I < 256 do
  begin
    C := C2.Gradient(C3, (I - 128) / 127.0);

    Clr.Create(C);

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
  FLineGradientFlag := grdRadial;

  FLineColor.Create(0, 0, 0); // Set some real TAggColorRgba8
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

procedure TAgg2D.SetLineWidth(W: Double);
begin
  FLineWidth := W;

  FConvStroke.Width := W;
end;

function TAgg2D.GetLineWidth(W: Double): Double;
begin
  Result := FLineWidth;
end;

procedure TAgg2D.SetLineCap(Cap: LineCap_);
begin
  FLineCap := Cap;

  FConvStroke.LineCap := Cap;
end;

function TAgg2D.GetLineCap: LineCap_;
begin
  Result := FLineCap;
end;

procedure TAgg2D.SetLineJoin(Join: LineJoin_);
begin
  FLineJoin := Join;

  FConvStroke.LineJoin := Join;
end;

function TAgg2D.GetLineJoin: LineJoin_;
begin
  Result := FLineJoin;
end;

procedure TAgg2D.SetFillEvenOdd(EvenOddFlag: Boolean);
begin
  FEvenOddFlag := EvenOddFlag;

  if EvenOddFlag then
    FRasterizer.SetFillingRule(frEvenOdd)
  else
    FRasterizer.SetFillingRule(frNonZero);
end;

function TAgg2D.GetFillEvenOdd: Boolean;
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
  FConvStroke.ApproximationScale := WorldToScreen(1.0) * GApproxScale;
end;

procedure TAgg2D.ResetTransformations;
begin
  FTransform.Reset;
end;

procedure TAgg2D.Affine(Tr: PAffine);
begin
  FTransform.Multiply(Tr);

  FConvCurve.SetApproximationScale(WorldToScreen(1.0) * GApproxScale);
  FConvStroke.ApproximationScale := WorldToScreen(1.0) * GApproxScale;
end;

procedure TAgg2D.Affine(Tr: PAggTransformations);
var
  Ta: TransAffineObject;
begin
  Ta.Create(Tr.AffineMatrix[0], Tr.AffineMatrix[1], Tr.AffineMatrix[2],
    Tr.AffineMatrix[3], Tr.AffineMatrix[4], Tr.AffineMatrix[5]);

  Affine(PAffine(@Ta));
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
  FConvStroke.ApproximationScale := WorldToScreen(1.0) * GApproxScale;
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
  FConvStroke.ApproximationScale := WorldToScreen(1.0) * GApproxScale;
end;

procedure TAgg2D.Viewport(WorldX1, WorldY1, WorldX2, WorldY2, ScreenX1, ScreenY1,
  ScreenX2, ScreenY2: Double; Opt: ViewportOption = XMidYMid);
var
  Vp: TransViewportObject;
  Mx: TransAffineObject;
begin
  Vp.Create;

  case Opt of
    Anisotropic:
      Vp.PreserveAspectRatio(0.0, 0.0, arStretch);

    XMinYMin:
      Vp.PreserveAspectRatio(0.0, 0.0, arMeet);

    XMidYMin:
      Vp.PreserveAspectRatio(0.5, 0.0, arMeet);

    XMaxYMin:
      Vp.PreserveAspectRatio(1.0, 0.0, arMeet);

    XMinYMid:
      Vp.PreserveAspectRatio(0.0, 0.5, arMeet);

    XMidYMid:
      Vp.PreserveAspectRatio(0.5, 0.5, arMeet);

    XMaxYMid:
      Vp.PreserveAspectRatio(1.0, 0.5, arMeet);

    XMinYMax:
      Vp.PreserveAspectRatio(0.0, 1.0, arMeet);

    XMidYMax:
      Vp.PreserveAspectRatio(0.5, 1.0, arMeet);

    XMaxYMax:
      Vp.PreserveAspectRatio(1.0, 1.0, arMeet);
  end;

  Vp.WorldViewport(WorldX1, WorldY1, WorldX2, WorldY2);
  Vp.DeviceViewport(ScreenX1, ScreenY1, ScreenX2, ScreenY2);

  Mx.Create;

  Vp.ToAffine(@Mx);
  FTransform.Multiply(@Mx);

  FConvCurve.SetApproximationScale(WorldToScreen(1.0) * GApproxScale);
  FConvStroke.ApproximationScale := WorldToScreen(1.0) * GApproxScale;
end;

procedure TAgg2D.Line(X1, Y1, X2, Y2: Double);
begin
  FPath.RemoveAll;

  AddLine(X1, Y1, X2, Y2);
  DrawPath(dpfStrokeOnly);
end;

procedure TAgg2D.Triangle(X1, Y1, X2, Y2, X3, Y3: Double);
begin
  FPath.RemoveAll;
  FPath.MoveTo(X1, Y1);
  FPath.LineTo(X2, Y2);
  FPath.LineTo(X3, Y3);
  FPath.ClosePolygon;

  DrawPath(dpfFillAndStroke);
end;

procedure TAgg2D.Rectangle(X1, Y1, X2, Y2: Double);
begin
  FPath.RemoveAll;
  FPath.MoveTo(X1, Y1);
  FPath.LineTo(X2, Y1);
  FPath.LineTo(X2, Y2);
  FPath.LineTo(X1, Y2);
  FPath.ClosePolygon;

  DrawPath(dpfFillAndStroke);
end;

procedure TAgg2D.RoundedRect(X1, Y1, X2, Y2, R: Double);
var
  Rc: RoundedRectObject;
begin
  FPath.RemoveAll;
  Rc.Create(X1, Y1, X2, Y2, R);

  Rc.NormalizeRadius;
  Rc.ApproximationScale := WorldToScreen(1.0) * GApproxScale;

  FPath.AddPath(Rc, 0, False);

  DrawPath(dpfFillAndStroke);
end;

procedure TAgg2D.RoundedRect(X1, Y1, X2, Y2, Rx, Ry: Double);
var
  Rc: RoundedRectObject;
begin
  FPath.RemoveAll;
  Rc.Create;

  Rc.Rect(X1, Y1, X2, Y2);
  Rc.Radius(Rx, Ry);
  Rc.NormalizeRadius;

  FPath.AddPath(Rc, 0, False);

  DrawPath(dpfFillAndStroke);
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
  Rc.NormalizeRadius;

  Rc.ApproximationScale := WorldToScreen(1.0) * GApproxScale;

  FPath.AddPath(Rc, 0, False);

  DrawPath(dpfFillAndStroke);
end;

procedure TAgg2D.EllipseObject(Cx, Cy, Rx, Ry: Double);
var
  El: BezierArcObject;
begin
  FPath.RemoveAll;

  El.Create(Cx, Cy, Rx, Ry, 0, 2 * Pi);

  FPath.AddPath(El, 0, False);
  FPath.ClosePolygon;

  DrawPath(dpfFillAndStroke);
end;

procedure TAgg2D.Arc(Cx, Cy, Rx, Ry, Start, Sweep: Double);
var
  Ar: { bezier_ } AggArc.Arc;
begin
  FPath.RemoveAll;

  Ar.Create(Cx, Cy, Rx, Ry, Start, Sweep, False);

  FPath.AddPath(Ar, 0, False);

  DrawPath(dpfStrokeOnly);
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
    SinCosScaled(A, Y, X, R2);
    X := X + Cx;
    Y := Y + Cy;

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
  DrawPath(dpfFillAndStroke);
end;

procedure TAgg2D.Curve(X1, Y1, X2, Y2, X3, Y3: Double);
begin
  FPath.RemoveAll;
  FPath.MoveTo(X1, Y1);
  FPath.Curve3(X2, Y2, X3, Y3);

  DrawPath(dpfStrokeOnly);
end;

procedure TAgg2D.Curve(X1, Y1, X2, Y2, X3, Y3, X4, Y4: Double);
begin
  FPath.RemoveAll;
  FPath.MoveTo(X1, Y1);
  FPath.Curve4(X2, Y2, X3, Y3, X4, Y4);

  DrawPath(dpfStrokeOnly);
end;

procedure TAgg2D.Polygon(Xy: PDouble; NumPoints: Integer);
begin
  FPath.RemoveAll;
  FPath.AddPoly(PDoubleArray2(Xy), NumPoints);

  ClosePolygon;
  DrawPath(dpfFillAndStroke);
end;

procedure TAgg2D.Polyline(Xy: PDouble; NumPoints: Integer);
begin
  FPath.RemoveAll;
  FPath.AddPoly(PDoubleArray2(Xy), NumPoints);

  DrawPath(dpfStrokeOnly);
end;

procedure TAgg2D.FlipText(Flip: Boolean);
begin
  FFontEngine.SetFlipY(Flip);
end;

procedure TAgg2D.Font(FileName: PAnsiChar; Height: Double; Bold: Boolean = False;
  Italic: Boolean = False; Ch: FontCacheType = RasterFontCache;
  Angle: Double = 0.0);
var
  B: Integer;
begin
  FTextAngle := Angle;
  FFontHeight := Height;
  FFontCacheType := Ch;

{$IFDEF AGG2D_USE_FREETYPE}
  if Ch = VectorFontCache then
    FFontEngine.LoadFont(PAnsiChar(FileName), 0, grOutline)
  else
    FFontEngine.LoadFont(PAnsiChar(FileName), 0, grAgggray8);

  FFontEngine.SetHinting(FTextHints);

  if Ch = VectorFontCache then
    FFontEngine.SetHeight(Height)
  else
    FFontEngine.SetHeight(WorldToScreen(Height));
{$ELSE}
  FFontEngine.SetHinting(FTextHints);

  if Bold then
    B := 700
  else
    B := 400;

  if Ch = VectorFontCache then
    FFontEngine.CreateFont_(PAnsiChar(FileName), grOutline, Height, 0.0,
      B, Italic)
  else
    FFontEngine.CreateFont_(PAnsiChar(FileName), grAgggray8,
      WorldToScreen(Height), 0.0, B, Italic);
{$ENDIF}
end;

function TAgg2D.FontHeight: Double;
begin
  Result := FFontHeight;
end;

procedure TAgg2D.TextAlignment(AlignX, AlignY: TextAlignment);
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

function TAgg2D.TextWidth(Str: PAnsiChar): Double;
var
  X, Y : Double;
  First: Boolean;
  Glyph: PAggGlyphCache;
begin
  X := 0;
  Y := 0;

  First := True;

  while Str^ <> #0 do
  begin
    Glyph := FFontCacheManager.Glyph(Int32u(Str^));

    if Glyph <> nil then
    begin
      if not First then
        FFontCacheManager.AddKerning(@X, @Y);

      X := X + Glyph.AdvanceX;
      Y := Y + Glyph.AdvanceY;

      First := False; { ! }
    end;

    Inc(PtrComp(Str));
  end;

  if FFontCacheType = VectorFontCache then
    Result := X
  else
    Result := ScreenToWorld(X);
end;

procedure TAgg2D.Text(X, Y: Double; Str: PAnsiChar; RoundOff: Boolean = False;
  Ddx: Double = 0.0; Ddy: Double = 0.0);
var
  Dx, Dy, Asc, StartX, StartY: Double;

  Glyph: PAggGlyphCache;

  Mtx: TransAffineObject;

  I: Integer;

  Tat: TransAffineTranslationObject;
  Tar: TransAffineRotationObject;

  Tr: ConvTransformObject;
begin
  Dx := 0.0;
  Dy := 0.0;

  case FTextAlignX of
    CAlignCenter:
      Dx := -TextWidth(Str) * 0.5;

    CAlignRight:
      Dx := -TextWidth(Str);
  end;

  Asc := FontHeight;
  Glyph := FFontCacheManager.Glyph(Int32u('H'));

  if Glyph <> nil then
    Asc := Glyph.Bounds.Y2 - Glyph.Bounds.Y1;

  if FFontCacheType = RasterFontCache then
    Asc := ScreenToWorld(Asc);

  case FTextAlignY of
    CAlignCenter:
      Dy := -Asc * 0.5;

    CAlignTop:
      Dy := -Asc;
  end;

  if FFontEngine.GetFlipY then
    Dy := -Dy;

  Mtx.Create;

  StartX := X + Dx;
  StartY := Y + Dy;

  if RoundOff then
  begin
    StartX := Trunc(StartX);
    StartY := Trunc(StartY);
  end;

  StartX := StartX + Ddx;
  StartY := StartY + Ddy;

  Tat.Create(-X, -Y);
  Mtx.Multiply(@Tat);

  Tar.Create(FTextAngle);
  Mtx.Multiply(@Tar);

  Tat.Create(X, Y);
  Mtx.Multiply(@Tat);

  Tr.Create(FFontCacheManager.PathAdaptor, @Mtx);

  if FFontCacheType = RasterFontCache then
    WorldToScreen(@StartX, @StartY);

  I := 0;

  while PAnsiChar(PtrComp(Str) + I * SizeOf(AnsiChar))^ <> #0 do
  begin
    Glyph := FFontCacheManager.Glyph
      (Int32u(PAnsiChar(PtrComp(Str) + I * SizeOf(AnsiChar))^));

    if Glyph <> nil then
    begin
      if I <> 0 then
        FFontCacheManager.AddKerning(@X, @Y);

      FFontCacheManager.InitEmbeddedAdaptors(Glyph, StartX, StartY);

      if Glyph.DataType = gdOutline then
      begin
        FPath.RemoveAll;
        FPath.AddPath(Tr, 0, False);

        DrawPath;
      end;

      if Glyph.DataType = gdGray8 then
      begin
        Render(FFontCacheManager.Gray8Adaptor,
          FFontCacheManager.Gray8ScanLine);
      end;

      StartX := StartX + Glyph.AdvanceX;
      StartY := StartY + Glyph.AdvanceY;
    end;

    Inc(I);
  end;
end;

procedure TAgg2D.ResetPath;
begin
  FPath.RemoveAll;
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

procedure TAgg2D.CubicCurveRel(XCtrl2, YCtrl2, XTo, YTo: Double);
begin
  FPath.Curve4ObjectRelative(XCtrl2, YCtrl2, XTo, YTo);
end;

procedure TAgg2D.AddEllipseObject(Cx, Cy, Rx, Ry: Double; Dir: TAggDirection);
var
  Ar: BezierArcObject;
begin
  if Dir = dirCCW then
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

procedure TAgg2D.DrawPath(Flag: TAggDrawPathFlag = dpfFillAndStroke);
begin
  FRasterizer.Reset;

  case Flag of
    dpfFillOnly:
      if FFillColor.A <> 0 then
      begin
        FRasterizer.AddPath(FPathTransform);

        Render(True);
      end;

    dpfStrokeOnly:
      if (FLineColor.A <> 0) and (FLineWidth > 0.0) then
      begin
        FRasterizer.AddPath(FStrokeTransform);

        Render(False);
      end;

    dpfFillAndStroke:
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

    dpfFillWitHorizontalLineColor:
      if FLineColor.A <> 0 then
      begin
        FRasterizer.AddPath(FPathTransform);

        Render(False);
      end;
  end;
end;

procedure TAgg2D.DrawPathNoTransform(Flag: TAggDrawPathFlag = dpfFillAndStroke);
begin
end;

procedure TAgg2D.ImageFilter(F: ImageFilter_);
begin
  FImageFilter := F;

  case F of
    Bilinear:
      FImageFilterLUT.Calculate(@FImageFilterBilinear, True);

    Hanning:
      FImageFilterLUT.Calculate(@FImageFilterHanning, True);

    Hermite:
      FImageFilterLUT.Calculate(@FImageFilterHermite, True);

    Quadric:
      FImageFilterLUT.Calculate(@FImageFilterQuadric, True);

    Bicubic:
      FImageFilterLUT.Calculate(@FImageFilterBicubic, True);

    Catrom:
      FImageFilterLUT.Calculate(@FImageFilterCatrom, True);

    Spline16:
      FImageFilterLUT.Calculate(@FImageFilterSpline16, True);

    Spline36:
      FImageFilterLUT.Calculate(@FImageFilterSpline36, True);

    Blackman144:
      FImageFilterLUT.Calculate(@FImageFilterBlackman144, True);
  end;
end;

function TAgg2D.ImageFilter: ImageFilter_;
begin
  Result := FImageFilter;
end;

procedure TAgg2D.ImageResample(F: ImageResample_);
begin
  FImageResample := F;
end;

function TAgg2D.ImageResample: ImageResample_;
begin
  Result := FImageResample;
end;

procedure TAgg2D.TransformImage(Img: TAggImage; ImgX1, ImgY1, ImgX2, ImgY2: Integer;
  DstX1, DstY1, DstX2, DstY2: Double);
var
  Parall: array [0..5] of Double;

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

  RenderImage(Img, ImgX1, ImgY1, ImgX2, ImgY2, @Parall[0]);
end;

procedure TAgg2D.TransformImage(Img: TAggImage;
  DstX1, DstY1, DstX2, DstY2: Double);
var
  Parall: array [0..5] of Double;

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

  RenderImage(Img, 0, 0, Img.FRenderingBuffer.GetWidth, Img.FRenderingBuffer.GetHeight, @Parall[0]);
end;

procedure TAgg2D.TransformImage(Img: TAggImage; ImgX1, ImgY1, ImgX2, ImgY2: Integer;
  Parallelogram_: PDouble);
begin
  ResetPath;

  MoveTo(PDouble(PtrComp(Parallelogram_) + 0 * SizeOf(Double))^,
    PDouble(PtrComp(Parallelogram_) + 1 * SizeOf(Double))^);

  LineTo(PDouble(PtrComp(Parallelogram_) + 2 * SizeOf(Double))^,
    PDouble(PtrComp(Parallelogram_) + 3 * SizeOf(Double))^);

  LineTo(PDouble(PtrComp(Parallelogram_) + 4 * SizeOf(Double))^,
    PDouble(PtrComp(Parallelogram_) + 5 * SizeOf(Double))^);

  LineTo(PDouble(PtrComp(Parallelogram_) + 0 * SizeOf(Double))^ +
    PDouble(PtrComp(Parallelogram_) + 4 * SizeOf(Double))^ -
    PDouble(PtrComp(Parallelogram_) + 2 * SizeOf(Double))^,
    PDouble(PtrComp(Parallelogram_) + 1 * SizeOf(Double))^ +
    PDouble(PtrComp(Parallelogram_) + 5 * SizeOf(Double))^ -
    PDouble(PtrComp(Parallelogram_) + 3 * SizeOf(Double))^);

  ClosePolygon;

  RenderImage(Img, ImgX1, ImgY1, ImgX2, ImgY2, Parallelogram_);
end;

procedure TAgg2D.TransformImage(Img: TAggImage; Parallelogram_: PDouble);
begin
  ResetPath;

  MoveTo(PDouble(PtrComp(Parallelogram_) + 0 * SizeOf(Double))^,
    PDouble(PtrComp(Parallelogram_) + 1 * SizeOf(Double))^);

  LineTo(PDouble(PtrComp(Parallelogram_) + 2 * SizeOf(Double))^,
    PDouble(PtrComp(Parallelogram_) + 3 * SizeOf(Double))^);

  LineTo(PDouble(PtrComp(Parallelogram_) + 4 * SizeOf(Double))^,
    PDouble(PtrComp(Parallelogram_) + 5 * SizeOf(Double))^);

  LineTo(PDouble(PtrComp(Parallelogram_) + 0 * SizeOf(Double))^ +
    PDouble(PtrComp(Parallelogram_) + 4 * SizeOf(Double))^ -
    PDouble(PtrComp(Parallelogram_) + 2 * SizeOf(Double))^,
    PDouble(PtrComp(Parallelogram_) + 1 * SizeOf(Double))^ +
    PDouble(PtrComp(Parallelogram_) + 5 * SizeOf(Double))^ -
    PDouble(PtrComp(Parallelogram_) + 3 * SizeOf(Double))^);

  ClosePolygon;

  RenderImage(Img, 0, 0, Img.FRenderingBuffer.GetWidth, Img.FRenderingBuffer.GetHeight, Parallelogram_);
end;

procedure TAgg2D.TransformImagePath(Img: TAggImage;
  ImgX1, ImgY1, ImgX2, ImgY2: Integer; DstX1, DstY1, DstX2, DstY2: Double);
var
  Parall: array [0..5] of Double;
begin
  Parall[0] := DstX1;
  Parall[1] := DstY1;
  Parall[2] := DstX2;
  Parall[3] := DstY1;
  Parall[4] := DstX2;
  Parall[5] := DstY2;

  RenderImage(Img, ImgX1, ImgY1, ImgX2, ImgY2, @Parall[0]);
end;

procedure TAgg2D.TransformImagePath(Img: TAggImage;
  DstX1, DstY1, DstX2, DstY2: Double);
var
  Parall: array [0..5] of Double;
begin
  Parall[0] := DstX1;
  Parall[1] := DstY1;
  Parall[2] := DstX2;
  Parall[3] := DstY1;
  Parall[4] := DstX2;
  Parall[5] := DstY2;

  RenderImage(Img, 0, 0, Img.FRenderingBuffer.GetWidth,
    Img.FRenderingBuffer.GetHeight, @Parall[0]);
end;

procedure TAgg2D.TransformImagePath(Img: TAggImage;
  ImgX1, ImgY1, ImgX2, ImgY2: Integer; AParallelogram: PDouble);
begin
  RenderImage(Img, ImgX1, ImgY1, ImgX2, ImgY2, AParallelogram);
end;

procedure TAgg2D.TransformImagePath(Img: TAggImage; AParallelogram: PDouble);
begin
  RenderImage(Img, 0, 0, Img.FRenderingBuffer.GetWidth,
    Img.FRenderingBuffer.GetHeight, AParallelogram);
end;

procedure TAgg2D.BlendImage(Img: TAggImage; ImgX1, ImgY1, ImgX2, ImgY2: Integer;
  DstX, DstY: Double; Alpha: Cardinal = 255);
var
  Pixf: TAggPixelFormatProcessor;
  R: TRectInteger;
begin
  WorldToScreen(@DstX, @DstY);
  PixelFormatRgba32(PixF, @Img.FRenderingBuffer);
  R.Create(ImgX1, ImgY1, ImgX2, ImgY2);

  if FBlendMode = CBlendAlpha then
    FRendererBasePre.BlendFrom(@PixF, @R, Trunc(DstX) - ImgX1,
      Trunc(DstY) - ImgY1, Alpha)
  else
    FRendererBaseCompPre.BlendFrom(@PixF, @R, Trunc(DstX) - ImgX1,
      Trunc(DstY) - ImgY1, Alpha);
end;

procedure TAgg2D.BlendImage(Img: TAggImage; DstX, DstY: Double;
  Alpha: Cardinal = 255);
var
  Pixf: TAggPixelFormatProcessor;
begin
  WorldToScreen(@DstX, @DstY);
  PixelFormatRgba32(PixF, @Img.FRenderingBuffer);

  FRendererBasePre.BlendFrom(@PixF, nil, Trunc(DstX), Trunc(DstY), Alpha);

  if FBlendMode = CBlendAlpha then
    FRendererBasePre.BlendFrom(@PixF, nil, Trunc(DstX), Trunc(DstY), Alpha)
  else
    FRendererBaseCompPre.BlendFrom(@PixF, nil, Trunc(DstX), Trunc(DstY), Alpha);
end;

procedure TAgg2D.CopyImage(Img: TAggImage; ImgX1, ImgY1, ImgX2, ImgY2: Integer;
  DstX, DstY: Double);
var
  R: TRectInteger;
begin
  WorldToScreen(@DstX, @DstY);
  R.Create(ImgX1, ImgY1, ImgX2, ImgY2);

  FRendererBase.CopyFrom(@Img.FRenderingBuffer, @R, Trunc(DstX) - ImgX1,
    Trunc(DstY) - ImgY1);
end;

procedure TAgg2D.CopyImage(Img: TAggImage; DstX, DstY: Double);
begin
  WorldToScreen(@DstX, @DstY);

  FRendererBase.CopyFrom(@Img.FRenderingBuffer, nil, Trunc(DstX), Trunc(DstY));
end;

procedure TAgg2D.Render(FillColor_: Boolean);
begin
  if FBlendMode = CBlendAlpha then
    Agg2DRendererRender(@Self, @FRendererBase, @FRendererSolid, FillColor_)
  else
    Agg2DRendererRender(@Self, @FRendererBaseComp, @FRendererSolidComp, FillColor_);
end;

procedure TAgg2D.Render(Ras: PFontRasterizer; Sl: PFontScanLine);
begin
  if FBlendMode = CBlendAlpha then
    Agg2DRendererRender(@Self, @FRendererBase, @FRendererSolid, Ras, Sl)
  else
    Agg2DRendererRender(@Self, @FRendererBaseComp, @FRendererSolidComp, Ras, Sl);
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
  Matrix: TransAffineObject;
  Interpolator: SpanInterpolatorLinearObject;
begin
  Matrix.Create(X1, Y1, X2, Y2, PAggParallelogram(Parl));
  Matrix.Multiply(@FTransform);
  Matrix.Invert;

  FRasterizer.Reset;
  FRasterizer.AddPath(FPathTransform);

  Interpolator.Create(@Matrix);

  if FBlendMode = CBlendAlpha then
    Agg2DRendererRenderImage(@Self, Img, @FRendererBasePre, @Interpolator)
  else
    Agg2DRendererRenderImage(@Self, Img, @FRendererBaseCompPre, @Interpolator);
end;


{ TAggSpanConvImageBlend }

constructor TAggSpanConvImageBlend.Create(M: BlendMode_; C: TAggColorRgba8;
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
  S2: PAggColorRgba8;
begin
  if FMode <> CBlendDst then
  begin
    L2 := Len;
    S2 := PAggColorRgba8(Span);

    repeat
      CompOpAdaptorClipToDestinationRgbaPre(FPixel, Cardinal(FMode),
        PInt8u(S2), FColor.R, FColor.G, FColor.B, CAggBaseMask, CAggCoverFull);

      Inc(PtrComp(S2), SizeOf(TAggColorRgba8));
      Dec(L2);
    until L2 = 0;
  end;

  if FColor.A < CAggBaseMask then
  begin
    L2 := Len;
    S2 := PAggColorRgba8(Span);
    A := FColor.A;

    repeat
      S2.R := (S2.R * A) shr CAggBaseShift;
      S2.G := (S2.G * A) shr CAggBaseShift;
      S2.B := (S2.B * A) shr CAggBaseShift;
      S2.A := (S2.A * A) shr CAggBaseShift;

      Inc(PtrComp(S2), SizeOf(TAggColorRgba8));
      Dec(L2);
    until L2 = 0;
  end;
end;

function OperatorIsEqual(C1, C2: PAggColorRgba8): Boolean;
begin
  Result := (C1.R = C2.R) and (C1.G = C2.G) and (C1.B = C2.B) and (C1.A = C2.A);
end;

function OperatorIsNotEqual(C1, C2: PAggColorRgba8): Boolean;
begin
  Result := not OperatorIsEqual(C1, C2);
end;

procedure Agg2DRendererRender(Gr: TAgg2D; RendererBase: PRendererBaseObject;
  RenSolid: PRendererScanLineAASolidObject; FillColor_: Boolean);
var
  Span: SpanGradientObject;
  Ren : RendererScanLineAAObject;
  Clr : TAggColor;

begin
  if (FillColor_ and (Gr.FFillGradientFlag = grdLinear)) or
    (not FillColor_ and (Gr.FLineGradientFlag = grdLinear)) then
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
  else if (FillColor_ and (Gr.FFillGradientFlag = grdRadial)) or
    (not FillColor_ and (Gr.FLineGradientFlag = grdRadial)) then
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
      Clr.Create(Gr.FFillColor)
    else
      Clr.Create(Gr.FLineColor);

    RenSolid.SetColor(@Clr);
    RenderScanLines(@Gr.FRasterizer, @Gr.FScanLine, RenSolid);
  end;
end;

procedure Agg2DRendererRender(Gr: TAgg2D; RendererBase: PRendererBaseObject;
  RenSolid: PRendererScanLineAASolidObject; Ras: PGray8AdaptorTypeObject;
  Sl: PGray8ScanLineTypeObject);
var
  Span: SpanGradientObject;
  Ren : RendererScanLineAAObject;
  Clr : TAggColor;
begin
  if Gr.FFillGradientFlag = grdLinear then
  begin
    Span.Create(@Gr.FAllocator, @Gr.FFillGradientInterpolator,
      @Gr.FLinearGradientFunction, @Gr.FFillGradient, Gr.FFillGradientD1,
      Gr.FFillGradientD2);

    Ren.Create(RendererBase, @Span);
    RenderScanLines(Ras, Sl, @Ren);
  end
  else if Gr.FFillGradientFlag = grdRadial then
  begin
    Span.Create(@Gr.FAllocator, @Gr.FFillGradientInterpolator,
      @Gr.FRadialGradientFunction, @Gr.FFillGradient, Gr.FFillGradientD1,
      Gr.FFillGradientD2);

    Ren.Create(RendererBase, @Span);
    RenderScanLines(Ras, Sl, @Ren);
  end
  else
  begin
    Clr.Create(Gr.FFillColor);
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
  Blend := TAggSpanConvImageBlend.Create(Gr.FImageBlendMode,
    Gr.FImageBlendColor, @Gr.FPixelFormatCompPre);
  try
    if Gr.FImageFilter = NoFilter then
    begin
      Clr.Clear;
      Sg.Create(@Gr.FAllocator, @Img.FRenderingBuffer, @Clr, Interpolator, CAggOrderRgba);
      Sc.Create(@Sg, Blend);
      Ri.Create(RendererBase, @Sc);

      RenderScanLines(@Gr.FRasterizer, @Gr.FScanLine, @Ri);
    end
    else
    begin
      Resample := Gr.FImageResample = ResampleAlways;

      if Gr.FImageResample = ResampleOnZoomOut then
      begin
        Interpolator.GetTransformer.ScalingAbs(@Sx, @Sy);

        if (Sx > 1.125) or (Sy > 1.125) then
          Resample := True;
      end;

      if Resample then
      begin
        Clr.Clear;
        Sa.Create(@Gr.FAllocator, @Img.FRenderingBuffer, @Clr, Interpolator,
          @Gr.FImageFilterLUT, CAggOrderRgba);

        Sc.Create(@Sa, Blend);
        Ri.Create(RendererBase, @Sc);

        RenderScanLines(@Gr.FRasterizer, @Gr.FScanLine, @Ri);
      end
      else if Gr.FImageFilter = Bilinear then
      begin
        Clr.Clear;
        Sb.Create(@Gr.FAllocator, @Img.FRenderingBuffer, @Clr, Interpolator,
          CAggOrderRgba);

        Sc.Create(@Sb, Blend);
        Ri.Create(RendererBase, @Sc);

        RenderScanLines(@Gr.FRasterizer, @Gr.FScanLine, @Ri);
      end
      else if Gr.FImageFilterLUT.Diameter = 2 then
      begin
        Clr.Clear;
        S2.Create(@Gr.FAllocator, @Img.FRenderingBuffer, @Clr, Interpolator,
          @Gr.FImageFilterLUT, CAggOrderRgba);

        Sc.Create(@S2, Blend);
        Ri.Create(RendererBase, @Sc);

        RenderScanLines(@Gr.FRasterizer, @Gr.FScanLine, @Ri);
      end
      else
      begin
        Clr.Clear;
        Si.Create(@Gr.FAllocator, @Img.FRenderingBuffer, @Clr, Interpolator,
          @Gr.FImageFilterLUT, CAggOrderRgba);

        Sc.Create(@Si, Blend);
        Ri.Create(RendererBase, @Sc);

        RenderScanLines(@Gr.FRasterizer, @Gr.FScanLine, @Ri);
      end;
    end;
  finally
    Blend.Free;
  end;
end;

function Agg2DUsesFreeType: Boolean;
begin
{$IFDEF AGG2D_USE_FREETYPE}
  Result := True;
{$ELSE}
  Result := False;
{$ENDIF}
end;

end.
