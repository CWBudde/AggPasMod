unit FMX.Canvas.AggPas;

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//  Anti-Grain Geometry (modernized Pascal fork, aka 'AggPasMod')             //
//    Maintained by Christian-W. Budde (Christian@savioursofsoul.de)          //
//    Copyright (c) 2012-2015                                                 //
//                                                                            //
//  Based on:                                                                 //
//    Pascal port by Milan Marusinec alias Milano (milan@marusinec.sk)        //
//    Copyright (c) 2005-2006, see http://www.aggpas.org                      //
//                                                                            //
//  Original License:                                                         //
//    Anti-Grain Geometry - Version 2.4 (Public License)                      //
//    Copyright (C) 2002-2005 Maxim Shemanarev (http://www.antigrain.com)     //
//    Contact: McSeem@antigrain.com / McSeemAgg@yahoo.com                     //
//                                                                            //
//  Permission to copy, use, modify, sell and distribute this software        //
//  is granted provided this copyright notice appears in all copies.          //
//  This software is provided "as is" without express or implied              //
//  warranty, and with no claim as to its suitability for any purpose.        //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//  FMX.Canvas.AggPas is a backend replacement for Firemonkey implemented     //
//  in software using AggPasMod.                                              //
//                                                                            //
//  It is not optimized for a good performance and still an alpha proof-of-   //
//  concept.                                                                  //
//                                                                            //
//  This unit may contain code fragments from the VPR backend written by      //
//  Mattias Andersson (see https://sourceforge.net/projects/vpr/)             //
//                                                                            //
//  It may also contain traces of code fragments from the original backends   //
//  by Embarcardero                                                           //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//  B.Verhue 1-11-2016                                                        //
//                                                                            //
//  - Added buffering system and BeginScene Endscne methods                   //
//  - Moved font engine to class var                                          //
//  - Added text layout claa                                                  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

interface

{$I ..\AggCompiler.inc}

procedure SetAggPasDefault;

implementation

{$WARNINGS ON}
{$HINTS ON}

{$IFNDEF VER230}
  {$LEGACYIFEND ON}
{$ENDIF}

// See also Agg2D.pas
{$DEFINE AGG2D_USE_FREETYPE}

// CompilerVersion23: XE2
// CompilerVersion24: XE3
// CompilerVersion25: XE4
// CompilerVersion26: XE5
// CompilerVersion27: XE6
// ..

uses
  {$IFDEF IOS}
  FMX.Platform.iOS,
  {$ELSE}
  {$IFDEF MACOS}
  Macapi.CoreGraphics,
  Macapi.CocoaTypes,
  FMX.Platform.Mac,
  {$ENDIF MACOS}
  {$ENDIF IOS}
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  FMX.Platform.Win,
  {$ENDIF}
  {$IFDEF ANDROID}
  FMX.Platform.Android,
  {$ENDIF}
  FMX.Types,
  System.Types,
  System.UIConsts,
  System.Classes,
  System.SysUtils,
  System.UITypes,
  System.Math,
  {$IF CompilerVersion > 23}
  FMX.Graphics,
  FMX.TextLayout,
  FMX.PixelFormats,
  {$IFEND}
  {$IF CompilerVersion >= 27}
  System.Math.Vectors,
  {$IFEND}
  AggBasics,
  AggMath,
  AggArray,
  AggTransAffine,
  AggTransViewport,
  AggPathStorage,
  AggConvStroke,
  AggConvTransform,
  AggConvCurve,
  AggConvDash,
  AggRenderingBuffer,
  AggRendererBase,
  AggRendererScanLine,
  AggSpanGradient,
  AggSpanImageFilterRgba,
  AggSpanImageResampleRgba,
  AggSpanConverter,
  AggSpanPattern,
  AggSpanPatternRgba,
  AggSpanPatternFilterRgba,
  AggSpanInterpolatorLinear,
  AggSpanAllocator,
  AggRasterizerScanLineAA,
  AggGammaFunctions,
  AggScanlineUnpacked,
  AggArc,
  AggBezierArc,
  AggRoundedRect,
  AggPixelFormat,
  AggPixelFormatRgba,
  AggColor,
  AggMathStroke,
  AggImageFilters,
  AggRenderScanLines,
  AggFontEngine,
  AggFontCacheManager,
{$IFDEF AGG2D_USE_FREETYPE}
  AggFontFreeType,
{$ELSE}
  AggFontWin32TrueType,
{$ENDIF}
  AggVertexSource;

const
  CAntiAliasGamma: Double = 1;

type
  TAggBrushType = (btSolid, btGradientLinear, btGradientRadial, btBitmap);
  TAggViewportOption = (voAnisotropic, voXMinYMin, voXMidYMin, voXMaxYMin,
    voXMinYMid, voXMidYMid, voXMaxYMid, voXMinYMax, voXMidYMax, voXMaxYMax);

  TAggImageFilterType = (ifNoFilter, ifBilinear, ifHanning, ifHermite,
    ifQuadric, ifBicubic, ifCatrom, ifSpline16, ifSpline36, ifBlackman144);

  TAggImageResample = (irNever, irAlways, irOnZoomOut);

{$IFDEF AGG2D_USE_FREETYPE }
  TAggFontEngine = TAggFontEngineFreetypeInt32;
{$ELSE }
  TAggFontEngine = TAggFontEngineWin32TrueTypeInt32;
{$ENDIF}

  TCanvasAggPasImage = class
  private
    FRenderingBuffer: TAggRenderingBuffer;
    function GetWidth: Integer;
    function GetHeight: Integer;
    function GetScanLine(Index: Cardinal): Pointer;
  public
    constructor Create; overload;
    constructor Create(Buffer: PInt8u; AWidth, AHeight: Cardinal;
      Stride: Integer); overload;
    destructor Destroy; override;

    procedure Attach(Buffer: PInt8u; AWidth, AHeight: Cardinal;
      Stride: Integer);

    procedure PreMultiply;
    procedure DeMultiply;

    property ScanLine[Index: Cardinal]: Pointer read GetScanLine;
    property Width: Integer read GetWidth;
    property Height: Integer read GetHeight;
  end;

  TCanvasAggPasRasterizerGamma = class(TAggCustomVertexSource)
  private
    FAlpha: TAggGammaMultiply;
    FGamma: TAggGammaPower;
  public
    constructor Create(Alpha, Gamma: Double);
    destructor Destroy; override;

    function FuncOperatorGamma(X: Double): Double; override;
  end;

  TCanvasAggPasSaveState = class(TCanvasSaveState)
  private
    FClipRect: TRectF;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    procedure Assign(Source: TPersistent); override;
  end;

  TGetPixel = function(const X, Y: Single): TAlphaColor of object;

{$IF CompilerVersion <= 23}
  TBitmapData = record
    Data: pointer;
    Width: integer;
    Height: integer;
    Pitch: integer;
  end;

  TRegion = array of TRectF;
  TTextRange = TRectF;

  TTextLayoutAggPas = class;

  TTextLayout = class
  private
    FText: string;
    FTextRect: TRectF;
    FTopLeft: TPointF;
    FFont: TFont;
    FWordWrap: boolean;
    FHorizontalAlign: TTextAlign;
    FVerticalAlign: TTextAlign;
    FOpacity: single;
    procedure SetFont(const aValue: TFont);
    procedure SetHorizontalAlign(const Value: TTextAlign);
    procedure SetVerticalAlign(const Value: TTextAlign);
  protected
    procedure DoRenderLayout; virtual; abstract;
    procedure DoDrawLayout(const ACanvas: TCanvas); virtual; abstract;
    function GetTextHeight: Single; virtual; abstract;
    function GetTextWidth: Single; virtual; abstract;
    function GetTextRect: TRectF; virtual; abstract;
    function DoPositionAtPoint(const APoint: TPointF): Integer; virtual; abstract;
    function DoRegionForRange(const ARange: TTextRange): TRegion; virtual; abstract;
  public
    constructor Create(const ACanvas: TCanvas = nil); virtual;
    destructor Destroy; override;

    procedure ConvertToPath(const APath: TPathData); virtual; abstract;

    property Text: string read FText write FText;
    property TextRect: TRectF read GetTextRect;
    property TextWidth: Single read GetTextWidth;
    property TopLeft: TPointF read FTopLeft write FTopLeft;
    property Font: TFont read FFont write SetFont;
    property WordWrap: boolean read FWordWrap write FWordWrap;
    property HorizontalAlign: TTextAlign read FHorizontalAlign write SetHorizontalAlign;
    property VerticalAlign: TTextAlign read FVerticalAlign write SetVerticalAlign;
    property Opacity: Single read FOpacity write FOpacity;
  end;
{$IFEND}

  TCanvasAggPas = class(TCanvas)
  private
{$IF CompilerVersion <= 23}
    FBitmapInfo: TBitmapInfo;
    FBufferBitmap: THandle;
{$IFEND}
{$IFDEF MACOS}
    FBitmapContext: CGContextRef;
    FImage: CGImageRef;
{$ENDIF}
    FBitmapData: TBitmapData;
    FContextHandle: THandle;
    FClipRects: PClipRects;

    FClipRect: TRectF;
    FSceneCount: integer;

    FFillImage: TCanvasAggPasImage;
    FPatternWrapX, FPatternWrapY: TAggWrapMode;
    FSpanPattern: TAggSpanPatternFilterRgbaBilinear;

    FRenderingBuffer: TAggRenderingBuffer;

    FRendererBase: TAggRendererBase;
    FRendererBaseComp: TAggRendererBase;
    FRendererBasePre: TAggRendererBase;
    FRendererBaseCompPre: TAggRendererBase;

    FRendererSolid: TAggRendererScanLineAASolid;
    FRendererSolidComp: TAggRendererScanLineAASolid;

    FAllocator: TAggSpanAllocator;
    FClipBox: TRectDouble;

    FBlendMode: TAggBlendMode;
    FImageBlendMode: TAggBlendMode;

    FImageBlendColor: TAggRgba8;

    FScanLine: TAggScanLineUnpacked8;
    FRasterizer: TAggRasterizerScanLineAA;

    FAggColor: TAggRgba8;
    FBrushType: TAggBrushType;
    FGradientColors: TAggPodAutoArray;
    FGradientMatrix: TAggTransAffine;
    FGradientD1: Double;
    FGradientD2: Double;

    {$IF CompilerVersion <= 23}
    FTextLayout: TTextLayoutAggPas;
    FTextHints: Boolean;
    FFontHeight: Double;
    FFontAscent: Double;
    FFontDescent: Double;
    {$IFEND}

    FImageFilter: TAggImageFilterType;
    FImageResample: TAggImageResample;
    FImageFilterLUT: TAggImageFilter;

    FGradientInterpolator: TAggSpanInterpolatorLinear;

    FLinearGradientFunction: TAggGradientX;
    FRadialGradientFunction: TAggGradientCircle;

    FEvenOddFlag: Boolean;

    FPath: TAggPathStorage;
    FTransform: TAggTransAffine;

    FConvCurve : TAggConvCurve;
    FConvStroke: TAggConvStroke;
    FConvDash: TAggConvDash;

    FPathTransform: TAggConvTransform;
    FStrokeTransform: TAggConvTransform;

    FOpacity: single;
    FFillVisible: boolean;
    FStrokeVisible: boolean;
    FStrokeThickness: single;

    // Other Pascal-specific members
    FGammaNone: TAggGammaNone;
    FGammaAgg2D: TCanvasAggPasRasterizerGamma;

    FImageFilterBilinear: TAggImageFilterBilinear;
    FImageFilterHanning: TAggImageFilterHanning;
    FImageFilterHermite: TAggImageFilterHermite;
    FImageFilterQuadric: TAggImageFilterQuadric;
    FImageFilterBicubic: TAggImageFilterBicubic;
    FImageFilterCatrom: TAggImageFilterCatrom;
    FImageFilterSpline16: TAggImageFilterSpline16;
    FImageFilterSpline36: TAggImageFilterSpline36;
    FImageFilterBlackman144: TAggImageFilterBlackman144;

    procedure Render(ABrush: TBrush);

    procedure RenderImage(Img: TCanvasAggPasImage; X, Y: Integer); overload;
    procedure RenderImage(Img: TCanvasAggPasImage; X1, Y1, X2, Y2: Integer;
      Parl: PDouble); overload;
    procedure RenderImage(Img: TCanvasAggPasImage; Rect: TRectInteger;
      Parl: PDouble); overload;
    procedure SetImageFilter(F: TAggImageFilterType);

    {$IF CompilerVersion <= 23}
    procedure SetTextHints(Value: Boolean); overload;
    {$IFEND}
    procedure SetImageResample(F: TAggImageResample); overload;
    procedure SetFillEvenOdd(EvenOddFlag: Boolean); overload;
    procedure SetBlendMode(Value: TAggBlendMode);
    procedure SetImageBlendMode(Value: TAggBlendMode);
    procedure SetImageBlendColor(R, G, B: Cardinal; A: Cardinal = 255); overload;
    procedure SetImageBlendColor(C: TAggRgba8); overload;
    function GetRow(Y: Cardinal): PInt8U;

    function CreateSaveState: TCanvasSaveState; override;

    {$IF CompilerVersion > 23}
    procedure MapBuffer;
    procedure UnmapBuffer;
    {$IFEND}

    procedure InternalRenderImage(Img: TCanvasAggPasImage;
      RendererBase: TAggRendererBase; Interpolator: TAggSpanInterpolatorLinear);

    procedure CopyPath(APath: TPathData);

    procedure PrepareGradient(AGradient: TGradient; ARect: TRectF);

    procedure UpdateTransformation;
    procedure UpdateApproximationScale;
    procedure UpdateRasterizerGamma(MasterAlpha: Double);

    procedure InitializeAggPas;
  protected
    FPixelFormat: TAggPixelFormatProcessor;
    FPixelFormatComp: TAggPixelFormatProcessor;
    FPixelFormatPre: TAggPixelFormatProcessor;
    FPixelFormatCompPre: TAggPixelFormatProcessor;

    // Setup
    procedure Attach(Buffer: PInt8u; Width, Height: Cardinal;
      Stride: Integer); overload;
    procedure Attach(Img: TCanvasAggPasImage); overload;

    procedure SetClipBox(X1, Y1, X2, Y2: Double); overload;
    function GetClipBox: TRectDouble; overload;

    procedure ClearAll(C: TAggRgba8); overload;
    procedure ClearAll(R, G, B: Cardinal; A: Cardinal = 255); overload;

    procedure ClearClipBox(C: TAggRgba8); overload;
    procedure ClearClipBox(R, G, B: Cardinal; A: Cardinal = 255); overload;

    procedure AlignPoint(X, Y: PDouble); overload;
    procedure AlignPoint(var X, Y: Double); overload;

    function InBox(WorldX, WorldY: Double): Boolean; overload;
    function InBox(World: TPointDouble): Boolean; overload;

    // Transformations
    procedure Viewport(WorldX1, WorldY1, WorldX2, WorldY2, ScreenX1, ScreenY1,
      ScreenX2, ScreenY2: Double; Opt: TAggViewportOption = voXMidYMid); overload;
    procedure Viewport(World, Screen: TRectDouble; Opt: TAggViewportOption =
      voXMidYMid); overload;

    // Text
    {$IF CompilerVersion <= 23}
    //procedure SetFont(FileName: TFileName; Height: Double; Bold: Boolean = False;
    //  Italic: Boolean = False; Angle: Double = 0);

    //function TextWidth(Str: PAnsiChar): Double; overload;
    //function TextWidth(Str: AnsiString): Double; overload;
    {$IFEND}

    // Path commands
    procedure RenderPath(ARect: TRectF; AOpacity: Single;
      const ABrush: TBrush; FillFlag: Boolean = True); overload;

    // Image Transformations
    procedure TransformImage(Img: TCanvasAggPasImage; ImgX1, ImgY1, ImgX2,
      ImgY2: Integer; DstX1, DstY1, DstX2, DstY2: Double); overload;
    procedure TransformImage(Img: TCanvasAggPasImage; ImgRect: TRectInteger;
      DstX1, DstY1, DstX2, DstY2: Double); overload;
    procedure TransformImage(Img: TCanvasAggPasImage; ImgRect: TRectInteger;
      Destination: TRectDouble); overload;

    procedure TransformImage(Img: TCanvasAggPasImage;
      DstX1, DstY1, DstX2, DstY2: Double); overload;
    procedure TransformImage(Img: TCanvasAggPasImage;
      Destination: TRectDouble); overload;

    procedure TransformImage(Img: TCanvasAggPasImage; ImgX1, ImgY1, ImgX2,
      ImgY2: Integer; Parallelogram: PDouble); overload;
    procedure TransformImage(Img: TCanvasAggPasImage; ImgRect: TRectInteger;
      Parallelogram: PDouble); overload;

    procedure TransformImage(Img: TCanvasAggPasImage; Parallelogram: PDouble); overload;

    procedure TransformImagePath(Img: TCanvasAggPasImage;
      ImgX1, ImgY1, ImgX2, ImgY2: Integer;
      DstX1, DstY1, DstX2, DstY2: Double); overload;

    procedure TransformImagePath(Img: TCanvasAggPasImage;
      DstX1, DstY1, DstX2, DstY2: Double); overload;

    procedure TransformImagePath(Img: TCanvasAggPasImage;
      ImgX1, ImgY1, ImgX2, ImgY2: Integer; Parallelogram: PDouble); overload;

    procedure TransformImagePath(Img: TCanvasAggPasImage;
      Parallelogram: PDouble); overload;

    procedure ApplyFill(const ABrush: TBrush; ARect: TRectF; const AOpacity: Single);
    {$IF CompilerVersion <= 23}
    procedure ApplyStroke(const AStroke: TBrush; const AStrokeThickness: Single;
      const AStrokeCap: TStrokeCap; const ADashArray: TDashArray;
      const ADashOffset: single; const AStrokeJoin: TStrokeJoin; ARect: TRectF;
      const AOpacity: Single);
    {$ELSE}
    procedure ApplyStroke(const AStroke: TStrokeBrush; ARect: TRectF; const AOpacity: Single);
    {$IFEND}

    // Image Blending (no transformations available)
    procedure BlendImage(Img: TCanvasAggPasImage; ImgX1, ImgY1, ImgX2, ImgY2: Integer;
      DstX, DstY: Double; Alpha: Cardinal = 255); overload;

    procedure BlendImage(Img: TCanvasAggPasImage; DstX, DstY: Double;
      Alpha: Cardinal = 255); overload;

    // Copy image directly, together with alpha-channel
    procedure CopyImage(Img: TCanvasAggPasImage; ImgX1, ImgY1, ImgX2, ImgY2: Integer;
      DstX, DstY: Double); overload;
    procedure CopyImage(Img: TCanvasAggPasImage; ImgRect: TRectInteger;
      Destination: TPointDouble); overload;

    procedure CopyImage(Img: TCanvasAggPasImage; DstX, DstY: Double); overload;
    procedure CopyImage(Img: TCanvasAggPasImage; Destination: TPointDouble); overload;

    // Conversions
    procedure WorldToScreen(X, Y: PDouble); overload;
    procedure WorldToScreen(var X, Y: Double); overload;
    procedure ScreenToWorld(X, Y: PDouble); overload;
    procedure ScreenToWorld(var X, Y: Double); overload;
    function WorldToScreen(Scalar: Double): Double; overload;
    function ScreenToWorld(Scalar: Double): Double; overload;

    {$IF CompilerVersion <= 23}
    procedure FillPolygon(const APolygon: TPolygon; const AOpacity: Single); override;
    procedure DrawPolygon(const APolygon: TPolygon; const AOpacity: Single); override;
    {$IFEND}

    {$IFNDEF AGG2D_USE_FREETYPE }
    procedure FontChanged(Sender: TObject); override;
    {$ENDIF}

    { Bitmaps }
    {$IF CompilerVersion <= 23}
    procedure UpdateBitmapHandle(ABitmap: TBitmap); override;
    procedure DestroyBitmapHandle(ABitmap: TBitmap); override;
    procedure FreeBuffer; override;

    class function GetBitmapScanline(Bitmap: TBitmap; Y: Integer): PAlphaColorArray; override;

    property TextHints: Boolean read FTextHints write SetTextHints;
    {$IFEND}

    property ImageBlendColor: TAggRgba8 read FImageBlendColor write SetImageBlendColor;
    property ImageFilter: TAggImageFilterType read FImageFilter write SetImageFilter;
    property BlendMode: TAggBlendMode read FBlendMode write SetBlendMode;
    property FillEvenOdd: Boolean read FEvenOddFlag write SetFillEvenOdd;
    property ImageResample: TAggImageResample read FImageResample write SetImageResample;
    property Row[Y: Cardinal]: PInt8U read GetRow;

    property ImageBlendMode: TAggBlendMode read FImageBlendMode write SetImageBlendMode;
  public
    {$IF CompilerVersion <= 24}
    constructor CreateFromWindow(const AParent: THandle; const AWidth,
      AHeight: Integer); override;
    constructor CreateFromBitmap(const ABitmap: TBitmap); override;
    {$ELSE}
    constructor CreateFromWindow(const AParent: TWindowHandle; const AWidth, AHeight: Integer;
      const AQuality: TCanvasQuality = {$IF CompilerVersion <= 26} TCanvasQuality.ccSystemDefault
                                       {$ELSE} TCanvasQuality.SystemDefault {$IFEND}); override;
    constructor CreateFromBitmap(const ABitmap: TBitmap;
      const AQuality: TCanvasQuality = {$IF CompilerVersion <= 26} TCanvasQuality.ccSystemDefault
                                       {$ELSE} TCanvasQuality.SystemDefault {$IFEND}); override;
    {$IFEND}
    constructor CreateFromPrinter(const APrinter: TAbstractPrinter); override;
    destructor Destroy; override;

    {$IF CompilerVersion <= 23}
    { buffer }
    procedure ResizeBuffer(const AWidth, AHeight: Integer); override;
    procedure FlushBufferRect(const X, Y: Integer; const Context; const ARect: TRectF); override;

    function DoBeginScene(const AClipRects: PClipRects = nil): Boolean; virtual;
    {$ELSE}
    { Bitmaps }
    class procedure DoInitializeBitmap(const Bitmap: TBitmap); override;
    class procedure DoFinalizeBitmap(const Bitmap: TBitmap); override;
    class function DoMapBitmap(const Bitmap: TBitmap; const Access: TMapAccess; var Data: TBitmapData): Boolean; override;
    class procedure DoUnmapBitmap(const Bitmap: TBitmap; var Data: TBitmapData); override;

    function DoBeginScene(const AClipRects: PClipRects = nil; AContextHandle: THandle = 0): Boolean; override;
    procedure DoEndScene; override;

    procedure SetSize(const AWidth, AHeight: Integer); override;
    {$IFEND}

    procedure Clear(const Color: TAlphaColor); override;
    procedure ClearRect(const ARect: TRectF; const AColor: TAlphaColor = 0); override;

    { matrix }
    procedure SetMatrix(const M: TMatrix); override;
    {$IF CompilerVersion <= 23}
    procedure MultyMatrix(const M: TMatrix); override;
    {$IFEND}

    { clipping }
    procedure SetClipRects(const ARects: array of TRectF); // override;
    procedure IntersectClipRect(const ARect: TRectF); override;
    procedure ExcludeClipRect(const ARect: TRectF); override;
    procedure ResetClipRect; // override;

    { drawing }
    {$IF CompilerVersion <= 23}
    procedure DrawLine(const APt1, APt2: TPointF; const AOpacity: Single); override;
    procedure FillRect(const ARect: TRectF; const XRadius, YRadius: Single;
      const ACorners: TCorners; const AOpacity: Single;
      const ACornerType: TCornerType = TCornerType.ctRound); override;
    procedure DrawRect(const ARect: TRectF; const XRadius, YRadius: Single;
      const ACorners: TCorners; const AOpacity: Single;
      const ACornerType: TCornerType = TCornerType.ctRound); override;
    procedure FillEllipse(const ARect: TRectF; const AOpacity: Single); override;
    procedure DrawEllipse(const ARect: TRectF; const AOpacity: Single); override;
    function LoadFontFromStream(AStream: TStream): Boolean; override;
    procedure FillText(const ARect: TRectF; const AText: string;
      const WordWrap: Boolean; const AOpacity: Single;
      const Flags: TFillTextFlags; const ATextAlign: TTextAlign;
      const AVTextAlign: TTextAlign = TTextAlign.taCenter); override;
    procedure MeasureText(var ARect: TRectF;
      const AText: string; const WordWrap: Boolean;
      const Flags: TFillTextFlags; const ATextAlign: TTextAlign;
      const AVTextAlign: TTextAlign = TTextAlign.taCenter); override;
    function TextToPath(Path: TPathData; const ARect: TRectF;
      const AText: string; const WordWrap: Boolean;
      const ATextAlign: TTextAlign;
      const AVTextAlign: TTextAlign = TTextAlign.taCenter): Boolean; override;
    procedure FillPath(const APath: TPathData; const AOpacity: Single); override;
    procedure DrawPath(const APath: TPathData; const AOpacity: Single); overload; override;
    procedure DrawBitmap(const ABitmap: TBitmap; const SrcRect, DstRect: TRectF;
      const AOpacity: Single; const HighSpeed: Boolean = False); override;
    procedure DrawThumbnail(const ABitmap: TBitmap; const Width, Height: Single); override;
    {$ELSE}
    procedure DoFillRect(const ARect: TRectF; const AOpacity: Single; const ABrush: TBrush); override;
    procedure DoFillPath(const APath: TPathData; const AOpacity: Single; const ABrush: TBrush); override;
    procedure DoFillEllipse(const ARect: TRectF; const AOpacity: Single; const ABrush: TBrush); override;
    procedure DoDrawBitmap(const ABitmap: TBitmap; const SrcRect, DstRect: TRectF; const AOpacity: Single;
      const HighSpeed: Boolean = False); override;
    procedure DoDrawLine(const APt1, APt2: TPointF; const AOpacity: Single; const ABrush: TStrokeBrush); override;
    procedure DoDrawRect(const ARect: TRectF; const AOpacity: Single; const ABrush: TStrokeBrush); override;
    procedure DoDrawPath(const APath: TPathData; const AOpacity: Single; const ABrush: TStrokeBrush); override;
    procedure DoDrawEllipse(const ARect: TRectF; const AOpacity: Single; const ABrush: TStrokeBrush); override;
    {$IFEND}
    function PtInPath(const APoint: TPointF; const APath: TPathData): Boolean; override;
  end;

  TTextLayoutAggPas = class(TTextLayout)
  class var
    {$IFNDEF AGG2D_USE_FREETYPE}
    FFontHandle: HFONT;
    FFontDC: HDC;
    {$ENDIF}
    FFontEngine: TAggFontEngine;
    FFontCacheManager: TAggFontCacheManager;
  private
    FLeft: Single;
    FTop: Single;
    FHeight: Single;
    FWidth: Single;

    FTextHints: Boolean;

    procedure SetFont(FileName: TFileName; Height: Double; Bold: Boolean = False;
      Italic: Boolean = False; Angle: Double = 0);
    function MeasureRange(const APos, ALength: Integer): TRegion;
  protected
    procedure DoRenderLayout; override;
    procedure DoDrawLayout(const ACanvas: TCanvas); override;
    function GetTextHeight: Single; override;
    function GetTextWidth: Single; override;
    function GetTextRect: TRectF; override;
    function DoPositionAtPoint(const APoint: TPointF): Integer; override;
    function DoRegionForRange(const ARange: TTextRange): TRegion; override;

    class constructor Create;
    class destructor Destroy;
  public
    constructor Create(const ACanvas: TCanvas = nil); override;
    destructor Destroy; override;
    //
    procedure ConvertToPath(const APath: TPathData); override;
  end;

  TAggSpanConvImageBlend = class(TAggSpanConvertor)
  private
    FMode: TAggBlendMode;
    FColor: TAggRgba8;
    FPixel: TAggPixelFormatProcessor; // FPixelFormatCompPre
  public
    constructor Create(BlendMode: TAggBlendMode; C: TAggRgba8;
      P: TAggPixelFormatProcessor);

    procedure Convert(Span: PAggColor; X, Y: Integer; Len: Cardinal); override;
  end;

var
  GApproxScale: Double = 2;

function Agg2DUsesFreeType: Boolean;
begin
{$IFDEF AGG2D_USE_FREETYPE}
  Result := True;
{$ELSE}
  Result := False;
{$ENDIF}
end;

function AggColorToAlphaColor(AggColor: TAggRgba8): TAlphaColor;
var
  AlphaColor: TAlphaColorRec absolute Result;
begin
  AlphaColor.R := AggColor.R;
  AlphaColor.G := AggColor.G;
  AlphaColor.B := AggColor.B;
  AlphaColor.A := AggColor.A;
end;

function AlphaColorToAggColor(AlphaColor: TAlphaColor): TAggRgba8;
  overload;
begin
  Result.R := TAlphaColorRec(AlphaColor).R;
  Result.G := TAlphaColorRec(AlphaColor).G;
  Result.B := TAlphaColorRec(AlphaColor).B;
  Result.A := TAlphaColorRec(AlphaColor).A;
end;

function AlphaColorToAggColor(AlphaColor: TAlphaColor; AOpacity: Single):
  TAggRgba8; overload;
begin
  Result.R := TAlphaColorRec(AlphaColor).R;
  Result.G := TAlphaColorRec(AlphaColor).G;
  Result.B := TAlphaColorRec(AlphaColor).B;
  Result.A := Trunc(AOpacity * TAlphaColorRec(AlphaColor).A);
end;

function TransformPoint(const P: TPointF; const M: TMatrix): TPointF;
begin
  Result.X := P.X * M.M[0].V[0] + P.Y * M.M[1].V[0] + M.M[2].V[0];
  Result.Y := P.X * M.M[0].V[1] + P.Y * M.M[1].V[1] + M.M[2].V[1];
end;

function TransformClipRect(const R: TRectF; const Matrix: TMatrix): TRectF;
var
  P1, P2, P3, P4: TPointF;
begin
  with R do
  begin
    P1 := TransformPoint(PointF(Left, Top), Matrix);
    P2 := TransformPoint(PointF(Right, Top), Matrix);
    P3 := TransformPoint(PointF(Right, Bottom), Matrix);
    P4 := TransformPoint(PointF(Left, Bottom), Matrix);
  end;
  Result.Left := Min(Min(P1.X, P2.X), Min(P3.X, P4.X));
  Result.Top := Min(Min(P1.Y, P2.Y), Min(P3.Y, P4.Y));
  Result.Right := Max(Max(P1.X, P2.X), Max(P3.X, P4.X));
  Result.Bottom := Max(Max(P1.Y, P2.Y), Max(P3.Y, P4.Y));
end;

{$IFDEF MACOS}
type
  TRGBFloat = packed record
    r, g, b, a: single;
  end;

var
  MyColorSpace: CGColorSpaceRef;

function ColorSpace: CGColorSpaceRef;
begin
  if MyColorSpace = nil then
    MyColorSpace := CGColorSpaceCreateDeviceRGB;
  Result := MyColorSpace;
end;

function CGColor(const C: TAlphaColor; Opacity: single = 1): TRGBFloat;
var
  cc: TAlphaColor;
begin
  cc := MakeColor(C, Opacity);
  Result.a := TAlphaColorRec(cc).a / $FF;
  Result.r := TAlphaColorRec(cc).r / $FF;
  Result.g := TAlphaColorRec(cc).g / $FF;
  Result.b := TAlphaColorRec(cc).b / $FF;
end;

function CGRectFromRect(const R: TRectF): CGRect;
begin
  Result.origin.x := R.Left;
  Result.origin.Y := R.Top;
  Result.size.Width := R.Right - R.Left;
  Result.size.Height := R.Bottom - R.Top;
end;
{$ENDIF}

{ TCanvasAggPasImage }

constructor TCanvasAggPasImage.Create;
begin
  FRenderingBuffer := TAggRenderingBuffer.Create;
end;

constructor TCanvasAggPasImage.Create(Buffer: PInt8u; AWidth, AHeight: Cardinal;
  Stride: Integer);
begin
  FRenderingBuffer := TAggRenderingBuffer.Create(Buffer, AWidth, AHeight,
    Stride);
end;

destructor TCanvasAggPasImage.Destroy;
begin
  FRenderingBuffer.Free;
  inherited;
end;

procedure TCanvasAggPasImage.Attach(Buffer: PInt8u; AWidth, AHeight: Cardinal; Stride: Integer);
begin
  FRenderingBuffer.Attach(Buffer, AWidth, AHeight, Stride);
end;

function TCanvasAggPasImage.GetWidth: Integer;
begin
  Result := FRenderingBuffer.Width;
end;

function TCanvasAggPasImage.GetHeight: Integer;
begin
  Result := FRenderingBuffer.Height;
end;

function TCanvasAggPasImage.GetScanLine(Index: Cardinal): Pointer;
begin
  Result := FRenderingBuffer.Row(Index)
end;

procedure TCanvasAggPasImage.PreMultiply;
var
  PixelFormatProcessor: TAggPixelFormatProcessor;
begin
  PixelFormatBgra32(PixelFormatProcessor, FRenderingBuffer);
  PixelFormatProcessor.PreMultiply;
end;

procedure TCanvasAggPasImage.DeMultiply;
var
  PixelFormatProcessor: TAggPixelFormatProcessor;
begin
  PixelFormatBgra32(PixelFormatProcessor, FRenderingBuffer);
  PixelFormatProcessor.DeMultiply;
end;

{ TCanvasAggPasRasterizerGamma }

constructor TCanvasAggPasRasterizerGamma.Create(Alpha, Gamma: Double);
begin
  FAlpha := TAggGammaMultiply.Create(Alpha);
  FGamma := TAggGammaPower.Create(Gamma);
end;

destructor TCanvasAggPasRasterizerGamma.Destroy;
begin
  FAlpha.Free;
  FGamma.Free;

  inherited;
end;

function TCanvasAggPasRasterizerGamma.FuncOperatorGamma(X: Double): Double;
begin
  Result := FAlpha.FuncOperatorGamma(FGamma.FuncOperatorGamma(X));
end;

{ TCanvasAggPas }

{$IF CompilerVersion <= 24}
constructor TCanvasAggPas.CreateFromWindow(const AParent: THandle; const AWidth,
  AHeight: Integer);
{$ELSE}
constructor TCanvasAggPas.CreateFromWindow(const AParent: TWindowHandle;
  const AWidth, AHeight: Integer;
  const AQuality: TCanvasQuality =
    {$IF CompilerVersion <= 26}
      TCanvasQuality.ccSystemDefault
    {$ELSE}
      TCanvasQuality.SystemDefault
    {$IFEND});
{$IFEND}
begin
  InitializeAggPas;

  inherited;

{$IF CompilerVersion > 23}
  MapBuffer;
{$ELSE}
  FBuffered := True;
  FTextLayout := TTextLayoutAggPas.Create;
{$IFEND}

  ResetClipRect;
end;

{$IF CompilerVersion <= 24}
constructor TCanvasAggPas.CreateFromBitmap(const ABitmap: TBitmap);
{$ELSE}
constructor TCanvasAggPas.CreateFromBitmap(const ABitmap: TBitmap;
  const AQuality: TCanvasQuality =
    {$IF CompilerVersion <= 26}
      TCanvasQuality.ccSystemDefault
    {$ELSE}
      TCanvasQuality.SystemDefault
    {$IFEND});
{$IFEND}
begin
  InitializeAggPas;

  inherited;

{$IF CompilerVersion > 23}
  MapBuffer;
{$ELSE}
  FTextLayout := TTextLayoutAggPas.Create;
{$IFEND}

  ResetClipRect;
end;

constructor TCanvasAggPas.CreateFromPrinter(const APrinter: TAbstractPrinter);
begin
  // unsupported
  inherited;
end;

destructor TCanvasAggPas.Destroy;
begin
  FRendererBase.Free;
  FRendererBaseComp.Free;
  FRendererBasePre.Free;
  FRendererBaseCompPre.Free;

  FRendererSolid.Free;
  FRendererSolidComp.Free;
  FRenderingBuffer.Free;

  FPathTransform.Free;
  FStrokeTransform.Free;
  FConvDash.Free;

  FAllocator.Free;

  FScanLine.Free;
  FRasterizer.Free;
  FTransform.Free;

  FGradientColors.Free;

  FLinearGradientFunction.Free;
  FRadialGradientFunction.Free;

  FGradientInterpolator.Free;
  FGradientMatrix.Free;

  FFillImage.Free;
  FSpanPattern.Free;

  FImageFilterBilinear.Free;
  FImageFilterHanning.Free;
  FImageFilterHermite.Free;
  FImageFilterQuadric.Free;
  FImageFilterBicubic.Free;
  FImageFilterCatrom.Free;
  FImageFilterSpline16.Free;
  FImageFilterSpline36.Free;
  FImageFilterBlackman144.Free;

  FImageFilterLUT.Free;
  FPath.Free;
  FGammaNone.Free;
  FGammaAgg2D.Free;

  FConvCurve.Free;
  FConvStroke.Free;

  FPixelFormat.Free;
  FPixelFormatComp.Free;
  FPixelFormatPre.Free;
  FPixelFormatCompPre.Free;

{$IF CompilerVersion <= 23}
  FTextLayout.Free;
{$IFEND}

  inherited;
end;

procedure TCanvasAggPas.InitializeAggPas;
begin
  FSceneCount := 0;

  FGammaAgg2D := nil;

  FRenderingBuffer := TAggRenderingBuffer.Create;

  PixelFormatBgra32(FPixelFormat, FRenderingBuffer);
  PixelFormatCustomBlendRgba(FPixelFormatComp, FRenderingBuffer,
    @BlendModeAdaptorRgba, CAggOrderBgra);
  PixelFormatBgra32(FPixelFormatPre, FRenderingBuffer);
  PixelFormatCustomBlendRgba(FPixelFormatCompPre, FRenderingBuffer,
    @BlendModeAdaptorRgba, CAggOrderBgra);

  FRendererBase := TAggRendererBase.Create(FPixelFormat);
  FRendererBaseComp := TAggRendererBase.Create(FPixelFormatComp);
  FRendererBasePre := TAggRendererBase.Create(FPixelFormatPre);
  FRendererBaseCompPre := TAggRendererBase.Create(FPixelFormatCompPre);

  FRendererSolid := TAggRendererScanLineAASolid.Create(FRendererBase);
  FRendererSolidComp  := TAggRendererScanLineAASolid.Create(FRendererBaseComp);

  FAllocator := TAggSpanAllocator.Create;
  FClipBox := RectDouble(0, 0, 0, 0);

  FImageBlendColor.Initialize(0, 0, 0);

  FScanLine := TAggScanLineUnpacked8.Create;
  FRasterizer := TAggRasterizerScanLineAA.Create;

  FGradientColors := TAggPodAutoArray.Create(256, SizeOf(TAggColor));

  FGammaNone := TAggGammaNone.Create;

  FFillImage := TCanvasAggPasImage.Create;
  FPatternWrapX := TAggWrapModeRepeatAutoPow2.Create;
  FPatternWrapY := TAggWrapModeRepeatAutoPow2.Create;
  FSpanPattern := TAggSpanPatternFilterRgbaBilinear.Create(FAllocator, FPatternWrapX,
    FPatternWrapY, CAggOrderBgra);

  // image filters
  FImageFilterBilinear := TAggImageFilterBilinear.Create;
  FImageFilterHanning := TAggImageFilterHanning.Create;
  FImageFilterHermite := TAggImageFilterHermite.Create;
  FImageFilterQuadric := TAggImageFilterQuadric.Create;
  FImageFilterBicubic := TAggImageFilterBicubic.Create;
  FImageFilterCatrom := TAggImageFilterCatrom.Create;
  FImageFilterSpline16 := TAggImageFilterSpline16.Create;
  FImageFilterSpline36 := TAggImageFilterSpline36.Create;
  FImageFilterBlackman144 := TAggImageFilterBlackman144.Create;

  FImageFilterLUT := TAggImageFilter.Create(FImageFilterBilinear, True);

  // gradients
  FBrushType := btSolid;

  FGradientMatrix := TAggTransAffine.Create;

  FGradientD1 := 0;
  FGradientD2 := 100;

  FLinearGradientFunction := TAggGradientX.Create;
  FRadialGradientFunction := TAggGradientCircle.Create;

  FGradientInterpolator := TAggSpanInterpolatorLinear.Create(
    FGradientMatrix);

  // vertex sources
  FPath := TAggPathStorage.Create;
  FTransform := TAggTransAffine.Create;

  FConvCurve := TAggConvCurve.Create(FPath);
  FConvDash := TAggConvDash.Create(FConvCurve);
  FConvStroke := TAggConvStroke.Create(FConvCurve);

  FPathTransform := TAggConvTransform.Create(FConvCurve, FTransform);
  FStrokeTransform := TAggConvTransform.Create(FConvStroke, FTransform);

  // initialize variables
  FBlendMode := bmAlpha;
  FImageBlendMode := bmDestination;

{$IF CompilerVersion <= 23}
  FTextHints := True;
  FFontHeight := 0;
  FFontAscent := 0;
  FFontDescent := 0;
{$IFEND}

  FImageFilter := ifBilinear;
  FImageResample := irNever;

  FEvenOddFlag := False;
end;

{$IF CompilerVersion <= 23}

procedure TCanvasAggPas.FreeBuffer;
begin
  if FBuffered then
  begin
    if FBufferHandle = 0 then
      Exit;
    if FBufferHandle <> 0 then
      DeleteDC(FBufferHandle);
    FBufferHandle := 0;
    if FBufferBitmap <> 0 then
      DeleteObject(FBufferBitmap);
    FBufferBitmap := 0;
  end;
end;

procedure TCanvasAggPas.ResizeBuffer(const AWidth, AHeight: Integer);
begin
  if (AWidth = FWidth) and (AHeight = FHeight) then
    Exit;

  FreeBuffer;

  FWidth := AWidth;
  FHeight := AHeight;

  if FWidth <= 0 then
    FWidth := 1;
  if FHeight <= 0 then
    FHeight := 1;

  FResized := True;

  if FBuffered then
  begin

    // Initialization
    with FBitmapInfo.bmiHeader do
    begin
      biSize := SizeOf(TBitmapInfoHeader);
      biPlanes := 1;
      biBitCount := 32;
      biCompression := BI_RGB;
      biWidth := AWidth;
      if biWidth <= 0 then
        biWidth := 1;
      biHeight := -AHeight;
      if biHeight >= 0 then
        biHeight := -1;
    end;

    // Create new DIB
    FBufferBitmap := CreateDIBSection(0, FBitmapInfo, DIB_RGB_COLORS,
      Pointer(FBufferBits), 0, 0);
    if FBufferBits = nil then
      raise Exception.Create('Can''t allocate the DIB handle ' +
        IntToStr(AWidth) + 'x' + IntToStr(AHeight));

    // attache AGG2D canvas
    Attach(FBufferBits, AWidth, AHeight, 4 * AWidth);

    FBufferHandle := CreateCompatibleDC(0);
    if FBufferHandle = 0 then
    begin
      DeleteObject(FBufferBitmap);
      FBufferHandle := 0;
      FBufferBits := nil;
      raise Exception.Create('Can''t create compatible DC');
    end;

    if SelectObject(FBufferHandle, FBufferBitmap) = 0 then
    begin
      DeleteDC(FBufferHandle);
      DeleteObject(FBufferBitmap);
      FBufferBitmap := 0;
      FBufferHandle := 0;
      FBufferBits := nil;
      raise Exception.Create('Can''t select an object into DC');
    end;
  end;

  inherited;
end;

procedure TCanvasAggPas.FlushBufferRect(const X, Y: Integer; const Context;
  const ARect: TRectF);
var
  R: Winapi.Windows.TRect;
  DstDC: THandle;
begin
  DstDC := THandle(Context);
  if DstDC = 0 then
    Exit;

  R := System.Classes.Rect(Trunc(ARect.Left), Trunc(ARect.Top),
    Trunc(ARect.Right) + 1, Trunc(ARect.Bottom) + 1);

  Winapi.Windows.BitBlt(DstDC, X + R.Left, y + R.Top, R.Right - R.Left,
    R.Bottom - R.Top, FBufferHandle, R.Left, R.Top, SRCCOPY);
end;

function TCanvasAggPas.DoBeginScene(const AClipRects: PClipRects): Boolean;
begin
  Result := inherited DoBeginScene(AClipRects);
  if Result and (AClipRects <> nil) then
    SetClipRects(AClipRects^);
end;

{$ELSE}

procedure TCanvasAggPas.MapBuffer;
begin
  if assigned(Bitmap) then
  begin
    Bitmap.Map(TMapAccess.maReadWrite, FBitmapData);
    Attach(FBitmapData.Data, FBitmapData.Width, FBitmapData.Height, FBitmapData.Pitch);
  end else begin
{$IFDEF MSWINDOWS}
    if assigned(Parent) then
    begin
      WindowHandleToPlatform(Parent).CreateBuffer(Width, Height);
      Attach(WindowHandleToPlatform(Parent).BufferBits, Width, Height, Width * 4);
    end;
{$ENDIF}
{$IFDEF MACOS}
    if assigned(Parent) then
    begin
      GetMem(FBitmapData.Data, Width * Height * 4);
      FBitmapContext := CGBitmapContextCreate(FBitmapData.Data, Width, Height, 8,
          Width * 4, ColorSpace, kCGImageAlphaPremultipliedLast);
      Attach(FBitmapData.Data, Width, Height, Width * 4);
    end;
{$ENDIF}
  end;
end;

procedure TCanvasAggPas.UnmapBuffer;
begin
  if assigned(Bitmap) then
  begin
    Bitmap.Unmap(FBitmapData);
  end else begin
{$IFDEF MSWINDOWS}
{$ENDIF}
{$IFDEF MACOS}
    if assigned(Parent) then
    begin
      if assigned(FBitmapContext) then
      begin
        CGImageRelease(FBitmapContext);
        FBitmapContext := nil;
      end;
      if assigned(FBitmapData.Data) then
      begin
        FreeMem(FBitmapData.Data);
        FBitmapData.Data := nil;
      end;
    end;
{$ENDIF}
  end;
end;

procedure TCanvasAggPas.SetSize(const AWidth, AHeight: Integer);
begin
  UnmapBuffer;
  inherited;
  MapBuffer;
end;

function TCanvasAggPas.DoBeginScene(const AClipRects: PClipRects = nil; AContextHandle: THandle = 0): Boolean;
begin
  FContextHandle := AContextHandle;
  FClipRects := AClipRects;

  if FSceneCount = 0 then
    MapBuffer;
  Inc(FSceneCount);

  Result := inherited DoBeginScene(AClipRects);
end;

procedure TCanvasAggPas.DoEndScene;
var
{$IFDEF MSWINDOWS}
  R: TRect;
{$ELSE}
  R: CGRect;
{$ENDIF}
  I: Integer;
begin
  inherited;

  Dec(FSceneCount);
  if FSceneCount <= 0 then
  begin
    if Assigned(Parent) and (FContextHandle <> 0) then
    begin
{$IFDEF MSWINDOWS}
      if Assigned(FClipRects) then
      begin
        for I := 0 to High(FClipRects^) do
        begin
          R := FClipRects^[I].Round;
          Winapi.Windows.BitBlt(FContextHandle, R.Left, R.Top, R.Width, R.Height, WindowHandleToPlatform(Parent).BufferHandle, R.Left, R.Top, SRCCOPY);
        end;
      end else
        Winapi.Windows.BitBlt(FContextHandle, 0, 0, Width, Height, WindowHandleToPlatform(Parent).BufferHandle, 0, 0, SRCCOPY);
{$ENDIF}
{$IFDEF MACOS}
      R := CGRectFromRect(RectF(0, 0, Width, Height));
      FImage := CGBitmapContextCreateImage(FBitmapContext);
      CGContextDrawImage(CGContextRef(FContextHandle), R, FImage);
{$ENDIF}
    end;
    UnmapBuffer;
    FSceneCount := 0;
  end;
end;
{$IFEND}

procedure TCanvasAggPas.Clear(const Color: TAlphaColor);
begin
  FRendererBase.Clear(AlphaColorToAggColor(Color));
end;

procedure TCanvasAggPas.ClearRect(const ARect: TRectF; const AColor: TAlphaColor);
var
  R: TRectF;
  Clr: TAggColor;
begin
  IntersectRect(R, ARect, FClipRect);

  Clr.FromRgba8(AlphaColorToAggColor(AColor));
  FRendererBase.CopyBar(Round(ARect.Left), Round(ARect.Top), Round(ARect.Right),
    Round(ARect.Bottom), @Clr);
end;

procedure TCanvasAggPas.UpdateTransformation;
var
  M: TAggParallelogram;
begin
  FTransform.Reset;

  M[0] := FMatrix.m11;
  M[1] := FMatrix.m12;
  M[2] := FMatrix.m21;
  M[3] := FMatrix.m22;
  M[4] := FMatrix.m31;
  M[5] := FMatrix.m32;

  FTransform.LoadFrom(@M);
  UpdateApproximationScale;
end;

procedure TCanvasAggPas.SetMatrix(const M: TMatrix);
begin
  inherited;

  UpdateTransformation;
end;

{$IF CompilerVersion <= 23}
procedure TCanvasAggPas.MultyMatrix(const M: TMatrix);
begin
  FMatrix := MatrixMultiply(M, FMatrix);
  UpdateTransformation;
end;
{$IFEND}

procedure TCanvasAggPas.SetClipRects(const ARects: array of TRectF);
var
  I: Integer;
begin
  if Length(ARects) = 0 then
    Exit;
  FClipRect := TransformClipRect(ARects[0], FMatrix);
  for I := 1 to High(ARects) do
    FClipRect := UnionRect(FClipRect, TransformClipRect(ARects[I], FMatrix));
  IntersectRect(FClipRect, FClipRect, RectF(0, 0, Width, Height));

  SetClipBox(FClipRect.Left, FClipRect.Top, FClipRect.Right, FClipRect.Bottom);
end;

procedure TCanvasAggPas.IntersectClipRect(const ARect: TRectF);
begin
  IntersectRect(FClipRect, FClipRect, TransformClipRect(ARect, FMatrix));

  SetClipBox(FClipRect.Left, FClipRect.Top, FClipRect.Right, FClipRect.Bottom);
end;

procedure TCanvasAggPas.ExcludeClipRect(const ARect: TRectF);
begin
  // unsupported
end;

procedure TCanvasAggPas.Render(ABrush: TBrush);
var
  Span: TAggSpanGradient;
  Ren : TAggRendererScanLineAA;
  Clr : TAggColor;

  Mtx: TAggTransAffine;
  Interpolator: TAggSpanInterpolatorLinear;
  SpanConverter: TAggSpanConverter;
  SpanImageResample: TAggSpanImageResampleRgbaAffine;
  Blend: TAggSpanConvImageBlend;
  RendererScanLineAA: TAggRendererScanLineAA;
begin
  case ABrush.Kind of
    TBrushKind.bkSolid:
      begin
        Clr.FromRgba8(FAggColor);
        FRendererSolid.SetColor(@Clr);
        RenderScanLines(FRasterizer, FScanLine, FRendererSolid);
      end;
    TBrushKind.bkGradient:
      case ABrush.Gradient.Style of
        TGradientStyle.gsLinear:
          begin
            Span := TAggSpanGradient.Create(FAllocator, FGradientInterpolator,
              FLinearGradientFunction, FGradientColors, FGradientD1, FGradientD2);
            try
              Ren := TAggRendererScanLineAA.Create(FRendererBase, Span);
              try
                RenderScanLines(FRasterizer, FScanLine, Ren);
              finally
                Ren.Free;
              end;
            finally
              Span.Free;
            end;
          end;
        TGradientStyle.gsRadial:
          begin
            Span := TAggSpanGradient.Create(FAllocator, FGradientInterpolator,
              FRadialGradientFunction, FGradientColors, FGradientD1, FGradientD2);
            try
              Ren := TAggRendererScanLineAA.Create(FRendererBase, Span);
              try
                RenderScanLines(FRasterizer, FScanLine, Ren);
              finally
                Ren.Free;
              end;
            finally
              Span.Free;
            end;
          end;
      end;
    TBrushKind.bkBitmap:
      begin
        FRasterizer.Reset;
        FRasterizer.AddPath(FPathTransform);

        Mtx := TAggTransAffine.Create;
        try
          Mtx.Assign(FTransform);
          Mtx.Invert;

          Interpolator := TAggSpanInterpolatorLinear.Create(Mtx);
          try
            Clr.Clear;
            case ABrush.Bitmap.WrapMode of
              TWrapMode.wmTile:
                begin
                  FSpanPattern.Interpolator := Interpolator;
                  FSpanPattern.Filter := FImageFilterLUT;
                  FSpanPattern.SourceImage := FFillImage.FRenderingBuffer;
                  RendererScanLineAA := TAggRendererScanLineAA.Create(
                    FRendererBasePre, FSpanPattern);
                  try
                    RenderScanLines(FRasterizer, FScanLine, RendererScanLineAA);
                  finally
                    RendererScanLineAA.Free;
                  end;
                end;
              TWrapMode.wmTileOriginal:
                begin
                  Blend := TAggSpanConvImageBlend.Create(FImageBlendMode,
                    FImageBlendColor, FPixelFormatCompPre);
                  try
                    SpanImageResample := TAggSpanImageResampleRgbaAffine.Create(
                      FAllocator, FFillImage.FRenderingBuffer, @Clr,
                      Interpolator, FImageFilterLUT, CAggOrderBgra);
                    try
                      SpanConverter := TAggSpanConverter.Create(
                        SpanImageResample, Blend);
                      try
                        RendererScanLineAA := TAggRendererScanLineAA.Create(
                          FRendererBasePre, SpanConverter);
                        try
                          RenderScanLines(FRasterizer, FScanLine,
                            RendererScanLineAA);
                        finally
                          RendererScanLineAA.Free;
                        end;
                      finally
                        SpanConverter.Free;
                      end;
                    finally
                      SpanImageResample.Free;
                    end;
                  finally
                    Blend.Free;
                  end;
                end;
              TWrapMode.wmTileStretch:
                begin
                  NoP; // not implemented
                end;
            end;
          finally
            Interpolator.Free;
          end;
        finally
          Mtx.Free;
        end;
      end;
    TBrushKind.bkResource: ;
{$IF CompilerVersion <= 24}
    TBrushKind.bkGrab: ;
{$IFEND}
  end;
end;

procedure TCanvasAggPas.InternalRenderImage(Img: TCanvasAggPasImage;
  RendererBase: TAggRendererBase; Interpolator: TAggSpanInterpolatorLinear);
var
  Blend: TAggSpanConvImageBlend;
  Si: TAggSpanImageFilterRgba;
  Sg: TAggSpanImageFilterRgbaNN;
  Sb: TAggSpanImageFilterRgbaBilinear;
  S2: TAggSpanImageFilterRgba2x2;
  Sa: TAggSpanImageResampleRgbaAffine;
  Sc: TAggSpanConverter;
  Ri: TAggRendererScanLineAA;
  Clr: TAggColor;
  Resample: Boolean;
  Scaling: TPointDouble;
begin
  Blend := TAggSpanConvImageBlend.Create(FImageBlendMode,
    FImageBlendColor, FPixelFormatCompPre);
  try
    if FImageFilter = ifNoFilter then
    begin
      Clr.Clear;
      Sg := TAggSpanImageFilterRgbaNN.Create(FAllocator,
        Img.FRenderingBuffer, @Clr, Interpolator, CAggOrderBgra);
      try
        Sc := TAggSpanConverter.Create(Sg, Blend);
        try
          Ri := TAggRendererScanLineAA.Create(RendererBase, Sc);
          try
            RenderScanLines(FRasterizer, FScanLine, Ri);
          finally
            Ri.Free;
          end;
        finally
          Sc.Free;
        end;
      finally
        Sg.Free;
      end;
    end
    else
    begin
      Resample := FImageResample = irAlways;

      if FImageResample = irOnZoomOut then
      begin
        Interpolator.Transformer.GetScalingAbs(Scaling.X, Scaling.Y);

        if (Scaling.X > 1.125) or (Scaling.Y > 1.125) then
          Resample := True;
      end;

      if Resample then
      begin
        Clr.Clear;
        Sa := TAggSpanImageResampleRgbaAffine.Create(FAllocator,
          Img.FRenderingBuffer, @Clr, Interpolator, FImageFilterLUT,
          CAggOrderBgra);
        try
          Sc := TAggSpanConverter.Create(Sa, Blend);
          try
            Ri := TAggRendererScanLineAA.Create(RendererBase, Sc);
            try
              RenderScanLines(FRasterizer, FScanLine, Ri);
            finally
              Ri.Free;
            end;
          finally
            Sc.Free;
          end;
        finally
          Sa.Free;
        end;
      end
      else if FImageFilter = ifBilinear then
      begin
        Clr.Clear;
        Sb := TAggSpanImageFilterRgbaBilinear.Create(FAllocator,
          Img.FRenderingBuffer, @Clr, Interpolator, CAggOrderBgra);
        try
          Sc := TAggSpanConverter.Create(Sb, Blend);
          try
            Ri := TAggRendererScanLineAA.Create(RendererBase, Sc);
            try
              RenderScanLines(FRasterizer, FScanLine, Ri);
            finally
              Ri.Free;
            end;
          finally
            Sc.Free;
          end;
        finally
          Sb.Free;
        end;
      end
      else if FImageFilterLUT.Diameter = 2 then
      begin
        Clr.Clear;
        S2 := TAggSpanImageFilterRgba2x2.Create(FAllocator,
          Img.FRenderingBuffer, @Clr, Interpolator, FImageFilterLUT,
          CAggOrderBgra);
        try
          Sc := TAggSpanConverter.Create(S2, Blend);
          try
            Ri := TAggRendererScanLineAA.Create(RendererBase, Sc);
            try
              RenderScanLines(FRasterizer, FScanLine, Ri);
            finally
              Ri.Free;
            end;
          finally
            Sc.Free;
          end;
        finally
          S2.Free;
        end;
      end
      else
      begin
        Clr.Clear;
        Si := TAggSpanImageFilterRgba.Create(FAllocator,
          Img.FRenderingBuffer, @Clr, Interpolator, FImageFilterLUT,
          CAggOrderBgra);
        try
          Sc := TAggSpanConverter.Create(Si, Blend);
          try
            Ri := TAggRendererScanLineAA.Create(RendererBase, Sc);
            try
              RenderScanLines(FRasterizer, FScanLine, Ri);
            finally
              Ri.Free;
            end;
          finally
            Sc.Free;
          end;
        finally
          Si.Free;
        end;
      end;
    end;
  finally
    Blend.Free;
  end;
end;

procedure TCanvasAggPas.RenderImage(Img: TCanvasAggPasImage; X, Y: Integer);
var
  Mtx: TAggTransAffine;
  Interpolator: TAggSpanInterpolatorLinear;
begin
  FRasterizer.Reset;
  FRasterizer.AddPath(FPathTransform);

  Mtx := TAggTransAffine.Create;
  try
    Mtx.Translate(X, Y);
    Mtx.Multiply(FTransform);
    Mtx.Invert;

    Interpolator := TAggSpanInterpolatorLinear.Create(Mtx);
    try
      if FBlendMode = bmAlpha then
        InternalRenderImage(Img, FRendererBasePre, Interpolator)
      else
        InternalRenderImage(Img, FRendererBaseCompPre, Interpolator);
    finally
      Interpolator.Free;
    end;
  finally
    Mtx.Free;
  end;
end;

procedure TCanvasAggPas.RenderImage(Img: TCanvasAggPasImage; X1, Y1, X2, Y2: Integer;
  Parl: PDouble);
begin
  RenderImage(Img, RectInteger(X1, Y1, X2, Y2), Parl);
end;

procedure TCanvasAggPas.RenderImage(Img: TCanvasAggPasImage; Rect: TRectInteger;
  Parl: PDouble);
var
  Mtx: TAggTransAffine;
  Interpolator: TAggSpanInterpolatorLinear;
begin
  FRasterizer.Reset;
  FRasterizer.AddPath(FPathTransform);

  Mtx := TAggTransAffine.Create(Rect.X1, Rect.Y1, Rect.X2, Rect.Y2,
    PAggParallelogram(Parl));
  try
    Mtx.Multiply(FTransform);
    Mtx.Invert;

    Interpolator := TAggSpanInterpolatorLinear.Create(Mtx);
    try
      if FBlendMode = bmAlpha then
        InternalRenderImage(Img, FRendererBasePre, Interpolator)
      else
        InternalRenderImage(Img, FRendererBaseCompPre, Interpolator);
    finally
      Interpolator.Free;
    end;
  finally
    Mtx.Free;
  end;
end;

procedure TCanvasAggPas.SetImageFilter(F: TAggImageFilterType);
begin
  FImageFilter := F;

  case F of
    ifBilinear:
      FImageFilterLUT.Calculate(FImageFilterBilinear, True);

    ifHanning:
      FImageFilterLUT.Calculate(FImageFilterHanning, True);

    ifHermite:
      FImageFilterLUT.Calculate(FImageFilterHermite, True);

    ifQuadric:
      FImageFilterLUT.Calculate(FImageFilterQuadric, True);

    ifBicubic:
      FImageFilterLUT.Calculate(FImageFilterBicubic, True);

    ifCatrom:
      FImageFilterLUT.Calculate(FImageFilterCatrom, True);

    ifSpline16:
      FImageFilterLUT.Calculate(FImageFilterSpline16, True);

    ifSpline36:
      FImageFilterLUT.Calculate(FImageFilterSpline36, True);

    ifBlackman144:
      FImageFilterLUT.Calculate(FImageFilterBlackman144, True);
  end;
end;

procedure TCanvasAggPas.Attach(Buffer: PInt8u; Width, Height: Cardinal; Stride: Integer);
begin
  FRenderingBuffer.Attach(Buffer, Width, Height, Stride);

  FRendererBase.ResetClipping(True);
  FRendererBaseComp.ResetClipping(True);
  FRendererBasePre.ResetClipping(True);
  FRendererBaseCompPre.ResetClipping(True);

  FTransform.Reset;

  SetClipBox(0, 0, Width, Height);

  SetImageFilter(ifBilinear);
  SetImageResample(irNever);

  FRasterizer.Gamma(FGammaNone);

  FBlendMode := bmAlpha;
end;

procedure TCanvasAggPas.Attach(Img: TCanvasAggPasImage);
begin
  Attach(Img.FRenderingBuffer.Buffer, Img.FRenderingBuffer.Width,
    Img.FRenderingBuffer.Height, Img.FRenderingBuffer.Stride);
end;

procedure TCanvasAggPas.SetClipBox(X1, Y1, X2, Y2: Double);
var
  Rect: TRectInteger;
begin
  FClipBox := RectDouble(X1, Y1, X2, Y2);

  Rect := RectInteger(Trunc(X1), Trunc(Y1), Trunc(X2), Trunc(Y2));

  if (FRenderingBuffer.Width = 0) then
    Exit;

  FRendererBase.SetClipBox(Rect.X1, Rect.Y1, Rect.X2, Rect.Y2);
  FRendererBaseComp.SetClipBox(Rect.X1, Rect.Y1, Rect.X2, Rect.Y2);
  FRendererBasePre.SetClipBox(Rect.X1, Rect.Y1, Rect.X2, Rect.Y2);
  FRendererBaseCompPre.SetClipBox(Rect.X1, Rect.Y1, Rect.X2, Rect.Y2);

  FRasterizer.SetClipBox(X1, Y1, X2, Y2);
end;

function TCanvasAggPas.GetClipBox: TRectDouble;
begin
  Result := FClipBox;
end;

procedure TCanvasAggPas.ClearAll(C: TAggRgba8);
begin
  FRendererBase.Clear(C);
end;

procedure TCanvasAggPas.ClearAll(R, G, B: Cardinal; A: Cardinal = 255);
var
  Clr: TAggRgba8;
begin
  Clr.Initialize(R, G, B, A);
  ClearAll(Clr);
end;

procedure TCanvasAggPas.ClearClipBox(C: TAggRgba8);
var
  Clr: TAggColor;
begin
  Clr.FromRgba8(C);

  FRendererBase.CopyBar(0, 0, FRendererBase.Width, FRendererBase.Height,
    @Clr);
end;

procedure TCanvasAggPas.ClearClipBox(R, G, B: Cardinal; A: Cardinal = 255);
var
  Clr: TAggRgba8;
begin
  Clr.Initialize(R, G, B, A);
  ClearClipBox(Clr);
end;

procedure TCanvasAggPas.WorldToScreen(X, Y: PDouble);
begin
  FTransform.Transform(FTransform, X, Y);
end;

procedure TCanvasAggPas.WorldToScreen(var X, Y: Double);
begin
  FTransform.Transform(FTransform, @X, @Y);
end;

procedure TCanvasAggPas.ScreenToWorld(X, Y: PDouble);
begin
  FTransform.InverseTransform(FTransform, X, Y);
end;

procedure TCanvasAggPas.ScreenToWorld(var X, Y: Double);
begin
  FTransform.InverseTransform(FTransform, @X, @Y);
end;

function TCanvasAggPas.WorldToScreen(Scalar: Double): Double;
var
  Rect: TRectDouble;
begin
  Rect.X1 := 0;
  Rect.Y1 := 0;
  Rect.X2 := Scalar;
  Rect.Y2 := Scalar;

  WorldToScreen(Rect.X1, Rect.Y1);
  WorldToScreen(Rect.X2, Rect.Y2);

  Result := Sqrt(0.5 * (Sqr(Rect.X2 - Rect.X1) + Sqr(Rect.Y2 - Rect.Y1)));
end;

function TCanvasAggPas.ScreenToWorld(Scalar: Double): Double;
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

procedure TCanvasAggPas.AlignPoint(X, Y: PDouble);
begin
  WorldToScreen(X, Y);

  X^ := Floor(X^) + 0.5;
  Y^ := Floor(Y^) + 0.5;

  ScreenToWorld(X, Y);
end;

procedure TCanvasAggPas.AlignPoint(var X, Y: Double);
begin
  WorldToScreen(X, Y);

  X := Floor(X) + 0.5;
  Y := Floor(Y) + 0.5;

  ScreenToWorld(X, Y);
end;

procedure TCanvasAggPas.ApplyFill(const ABrush: TBrush; ARect: TRectF;
  const AOpacity: Single);
begin
  Fill.Assign(ABrush);
  FOpacity := AOpacity;
  FFillVisible := False;

  with ABrush do
  begin
    case Kind of
      TBrushKind.bkSolid:
        begin
          FAggColor := AlphaColorToAggColor(Color, AOpacity);
          FFillVisible := FAggColor.A <> 0;
        end;
      TBrushKind.bkGradient:
        begin
          PrepareGradient(ABrush.Gradient, ARect);
          FFillVisible := True;
        end;
    end;
  end;
end;

{$IF CompilerVersion <= 23}
procedure TCanvasAggPas.ApplyStroke(const AStroke: TBrush;
  const AStrokeThickness: Single; const AStrokeCap: TStrokeCap;
  const ADashArray: TDashArray; const ADashOffset: single;
  const AStrokeJoin: TStrokeJoin; ARect: TRectF; const AOpacity: Single);
var
  i, l, k: integer;
  GapLength, DashLength: Double;
begin
  FStrokeThickness := aStrokeThickness;
  FConvStroke.Width := FStrokeThickness;
  FOpacity := aOpacity;

  Stroke.Assign(aStroke);
  Stroke.Color := MakeColor(Stroke.Color, FOpacity);
  FStrokeVisible := False;

  with aStroke do
  begin
    case Kind of
      TBrushKind.bkSolid:
        begin
          FAggColor := AlphaColorToAggColor(Color, FOpacity);
          FStrokeVisible := FAggColor.A <> 0;
        end;
      TBrushKind.bkGradient:
        begin
          PrepareGradient(AStroke.Gradient, ARect);
          FFillVisible := True;
        end;
    end;
  end;

  case aStrokeJoin of
    TStrokeJoin.sjMiter:
      FConvStroke.LineJoin := ljMiter;
    TStrokeJoin.sjRound:
      FConvStroke.LineJoin := ljRound;
    TStrokeJoin.sjBevel:
      FConvStroke.LineJoin := ljBevel;
  end;

  case aStrokeCap of
    TStrokeCap.scFlat:
      FConvStroke.LineCap := lcButt;
    TStrokeCap.scRound:
      FConvStroke.LineCap := lcRound;
  end;

  FConvStroke.MiterLimit := 0;

  if Length(aDashArray) = 0 then
    FConvStroke.Source := FConvCurve
  else
  begin
    FConvStroke.Source := FConvDash;
    FConvDash.RemoveAllDashes;
    FConvDash.DashStart := aDashOffset;

    l := Length(aDashArray);
    if Odd(l) then
      k := l * 2
    else
      k := l;

    i := 0;
    while i < k do
    begin
      DashLength := aDashArray[i mod l];
      Inc(i);
      GapLength := aDashArray[i mod l];
      Inc(i);

      if DashLength = 0 then
      begin
        FConvStroke.Source := FConvCurve;
        exit;
      end;

      FConvDash.AddDash(
        DashLength * aStrokeThickness,
        GapLength * aStrokeThickness);
    end;
  end;
end;
{$ELSE}
procedure TCanvasAggPas.ApplyStroke(const AStroke: TStrokeBrush; ARect: TRectF;
  const AOpacity: Single);
var
  i, l, k: integer;
  GapLength, DashLength: Double;
begin
  FStrokeThickness := aStroke.Thickness;
  FConvStroke.Width := FStrokeThickness;
  FOpacity := aOpacity;

  Stroke.Assign(aStroke);
  Stroke.Color := MakeColor(Stroke.Color, FOpacity);
  FStrokeVisible := False;

  with aStroke do
  begin
    case Kind of
      TBrushKind.bkSolid:
        begin
          FAggColor := AlphaColorToAggColor(Color, FOpacity);
          FStrokeVisible := FAggColor.A <> 0;
        end;
      TBrushKind.bkGradient:
        begin
          PrepareGradient(AStroke.Gradient, ARect);
          FFillVisible := True;
        end;
    end;
  end;

  case aStroke.Join of
    TStrokeJoin.sjMiter:
      FConvStroke.LineJoin := ljMiter;
    TStrokeJoin.sjRound:
      FConvStroke.LineJoin := ljRound;
    TStrokeJoin.sjBevel:
      FConvStroke.LineJoin := ljBevel;
  end;

  case aStroke.Cap of
    TStrokeCap.scFlat:
      FConvStroke.LineCap := lcButt;
    TStrokeCap.scRound:
      FConvStroke.LineCap := lcRound;
  end;

  FConvStroke.MiterLimit := 0;

  if Length(aStroke.DashArray) = 0 then
    FConvStroke.Source := FConvCurve
  else
  begin
    FConvStroke.Source := FConvDash;
    FConvDash.RemoveAllDashes;
    FConvDash.DashStart := aStroke.DashOffset;

    l := Length(aStroke.DashArray);
    if Odd(l) then
      k := l * 2
    else
      k := l;

    i := 0;
    while i < k do
    begin
      DashLength := aStroke.DashArray[i mod l];
      Inc(i);
      GapLength := aStroke.DashArray[i mod l];
      Inc(i);

      if DashLength = 0 then
      begin
        FConvStroke.Source := FConvCurve;
        exit;
      end;

      FConvDash.AddDash(
        DashLength * aStroke.Thickness,
        GapLength * aStroke.Thickness);
    end;
  end;
end;
{$IFEND}

function TCanvasAggPas.InBox(WorldX, WorldY: Double): Boolean;
begin
  WorldToScreen(@WorldX, @WorldY);

  Result := FRendererBase.Inbox(Trunc(WorldX), Trunc(WorldY));
end;

function TCanvasAggPas.InBox(World: TPointDouble): Boolean;
begin
  WorldToScreen(World.X, World.Y);

  Result := FRendererBase.Inbox(Trunc(World.X), Trunc(World.Y));
end;

procedure TCanvasAggPas.SetBlendMode(Value: TAggBlendMode);
begin
  FBlendMode := Value;

  FPixelFormatComp.BlendMode := Value;
  FPixelFormatCompPre.BlendMode := Value;
end;

procedure TCanvasAggPas.SetImageBlendMode(Value: TAggBlendMode);
begin
  FImageBlendMode := Value;
end;

procedure TCanvasAggPas.SetImageBlendColor(C: TAggRgba8);
begin
  FImageBlendColor := C;
end;

procedure TCanvasAggPas.SetImageBlendColor(R, G, B: Cardinal; A: Cardinal = 255);
var
  Clr: TAggRgba8;
begin
  Clr.Initialize(R, G, B, A);
  SetImageBlendColor(Clr);
end;

procedure TCanvasAggPas.PrepareGradient(AGradient: TGradient; ARect: TRectF);
var
  I: Integer;
  Temp: array [0..1] of Double;
  H: Double;
  PClr: PAggColor;
  AlphaColor: TAlphaColor;
  M: TAggParallelogram;
const
  CByteScale = 1 / 255;
begin
  case AGradient.Style of
    TGradientStyle.gsLinear:
      begin
        for I := 0 to 255 do
        begin
          PClr := FGradientColors[I];
          AlphaColor := AGradient.InterpolateColor(I * CByteScale);
          PClr^.FromRgbaInteger(
            TAlphaColorRec(AlphaColor).R,
            TAlphaColorRec(AlphaColor).G,
            TAlphaColorRec(AlphaColor).B,
            Trunc(TAlphaColorRec(AlphaColor).A));
        end;

        FGradientMatrix.Reset;

        with AGradient do
        begin
          Temp[0] := StopPosition.Point.X - StartPosition.Point.X;
          Temp[1] := StopPosition.Point.Y - StartPosition.Point.Y;

          H := Hypot(Temp[0] * aRect.Width, Temp[1] * aRect.Height);
          if H = 0 then
            exit;

          FGradientD1 := 0;
          FGradientD2 := Hypot(Temp[0] * H, Temp[1] * H);
          FGradientMatrix.Rotate(ArcTan2(Temp[1], Temp[0]));
          FGradientMatrix.Scale(aRect.Width / H, aRect.Height / H);
          FGradientMatrix.Translate(
            ARect.Left + StartPosition.Point.X * ARect.Width,
            ARect.Top +  StartPosition.Point.Y * ARect.Height);

          FGradientMatrix.Multiply(FTransform);
          FGradientMatrix.Invert;
        end;

        FBrushType := btGradientLinear;
      end;

    TGradientStyle.gsRadial:
      begin
        M[0] := aGradient.RadialTransform.Matrix.m11;
        M[1] := aGradient.RadialTransform.Matrix.m12;
        M[2] := aGradient.RadialTransform.Matrix.m21;
        M[3] := aGradient.RadialTransform.Matrix.m22;
        M[4] := aGradient.RadialTransform.Matrix.m31;
        M[5] := aGradient.RadialTransform.Matrix.m32;

        for I := 0 to 255 do
        begin
          PClr := FGradientColors[I];
          AlphaColor := AGradient.InterpolateColor(1 - I * CByteScale);
          PClr^.FromRgbaInteger(
            TAlphaColorRec(AlphaColor).R,
            TAlphaColorRec(AlphaColor).G,
            TAlphaColorRec(AlphaColor).B,
            Trunc(TAlphaColorRec(AlphaColor).A));
        end;

        FGradientD1 := 0;
        FGradientD2 := 0.5 * Min(ARect.Width, ARect.Height);
        Temp[0] := 0.5 / FGradientD2;

        FGradientMatrix.Reset;
        with AGradient.RadialTransform do
        begin
          FGradientMatrix.Scale(
            ARect.Width * Temp[0],
            ARect.Height * Temp[0]);
          FGradientMatrix.Translate(
            RotationCenter.X * RectWidth(ARect),
            RotationCenter.Y * RectHeight(ARect));
        end;
        FGradientMatrix.Multiply(FTransform);
        FGradientMatrix.Invert;

        FBrushType := btGradientRadial;
      end;
  end;
end;

procedure TCanvasAggPas.SetFillEvenOdd(EvenOddFlag: Boolean);
begin
  FEvenOddFlag := EvenOddFlag;

  if EvenOddFlag then
    FRasterizer.FillingRule := frEvenOdd
  else
    FRasterizer.FillingRule  := frNonZero;
end;

procedure TCanvasAggPas.Viewport(WorldX1, WorldY1, WorldX2, WorldY2, ScreenX1, ScreenY1,
  ScreenX2, ScreenY2: Double; Opt: TAggViewportOption = voXMidYMid);
var
  Vp: TAggTransViewport;
  Mx: TAggTransAffine;
begin
  Vp := TAggTransViewport.Create;
  try
    case Opt of
      voAnisotropic:
        Vp.PreserveAspectRatio(0, 0, arStretch);

      voXMinYMin:
        Vp.PreserveAspectRatio(0, 0, arMeet);

      voXMidYMin:
        Vp.PreserveAspectRatio(0.5, 0, arMeet);

      voXMaxYMin:
        Vp.PreserveAspectRatio(1, 0, arMeet);

      voXMinYMid:
        Vp.PreserveAspectRatio(0, 0.5, arMeet);

      voXMidYMid:
        Vp.PreserveAspectRatio(0.5, 0.5, arMeet);

      voXMaxYMid:
        Vp.PreserveAspectRatio(1, 0.5, arMeet);

      voXMinYMax:
        Vp.PreserveAspectRatio(0, 1, arMeet);

      voXMidYMax:
        Vp.PreserveAspectRatio(0.5, 1, arMeet);

      voXMaxYMax:
        Vp.PreserveAspectRatio(1, 1, arMeet);
    end;

    Vp.WorldViewport(WorldX1, WorldY1, WorldX2, WorldY2);
    Vp.DeviceViewport(ScreenX1, ScreenY1, ScreenX2, ScreenY2);

    Mx := TAggTransAffine.Create;
    try
      Vp.ToAffine(Mx);
      FTransform.Multiply(Mx);
    finally
      Mx.Free;
    end;
  finally
    Vp.Free;
  end;

  UpdateApproximationScale;
end;

procedure TCanvasAggPas.Viewport(World, Screen: TRectDouble; Opt: TAggViewportOption);
var
  Vp: TAggTransViewport;
  Mx: TAggTransAffine;
begin
  Vp := TAggTransViewport.Create;
  try
    case Opt of
      voAnisotropic:
        Vp.PreserveAspectRatio(0, 0, arStretch);

      voXMinYMin:
        Vp.PreserveAspectRatio(0, 0, arMeet);

      voXMidYMin:
        Vp.PreserveAspectRatio(0.5, 0, arMeet);

      voXMaxYMin:
        Vp.PreserveAspectRatio(1, 0, arMeet);

      voXMinYMid:
        Vp.PreserveAspectRatio(0, 0.5, arMeet);

      voXMidYMid:
        Vp.PreserveAspectRatio(0.5, 0.5, arMeet);

      voXMaxYMid:
        Vp.PreserveAspectRatio(1, 0.5, arMeet);

      voXMinYMax:
        Vp.PreserveAspectRatio(0, 1, arMeet);

      voXMidYMax:
        Vp.PreserveAspectRatio(0.5, 1, arMeet);

      voXMaxYMax:
        Vp.PreserveAspectRatio(1, 1, arMeet);
    end;

    Vp.WorldViewport(World);
    Vp.DeviceViewport(Screen);

    Mx := TAggTransAffine.Create;
    try
      Vp.ToAffine(Mx);
      FTransform.Multiply(Mx);
    finally
      Mx.Free;
    end;
  finally
    Vp.Free;
  end;

  UpdateApproximationScale;
end;

function TCanvasAggPas.GetRow(Y: Cardinal): PInt8U;
begin
  Result := FRenderingBuffer.Row(Y);
end;

procedure TCanvasAggPas.RenderPath(ARect: TRectF; AOpacity: Single;
 const ABrush: TBrush; FillFlag: Boolean = True);
begin
  FRasterizer.Reset;

  if AOpacity = 0 then
    Exit;
  UpdateRasterizerGamma(AOpacity);

  if FillFlag then
  begin
{$IF CompilerVersion <= 23}
    ApplyFill(ABrush, ARect, AOpacity);
{$IFEND}
    if FFillVisible then
    begin
      FRasterizer.AddPath(FPathTransform);
      Render(Fill);
    end;
  end
  else
  begin
{$IF CompilerVersion <= 23}
    ApplyStroke(ABrush, StrokeThickness, StrokeCap, FDash, FDashOffset,
      StrokeJoin,  ARect, AOpacity);
{$IFEND}
    if FStrokeVisible and (StrokeThickness > 0) then
    begin
      FRasterizer.AddPath(FStrokeTransform);
      Render(Stroke);
    end;
  end;
end;

procedure TCanvasAggPas.SetImageResample(F: TAggImageResample);
begin
  FImageResample := F;
end;

procedure TCanvasAggPas.TransformImage(Img: TCanvasAggPasImage; ImgX1, ImgY1,
  ImgX2, ImgY2: Integer; DstX1, DstY1, DstX2, DstY2: Double);
var
  Parall: TAggParallelogram;
begin
  FPath.RemoveAll;
  FPath.MoveTo(DstX1, DstY1);
  FPath.LineTo(DstX2, DstY1);
  FPath.LineTo(DstX2, DstY2);
  FPath.LineTo(DstX1, DstY2);
  FPath.ClosePolygon;

  Parall[0] := DstX1;
  Parall[1] := DstY1;
  Parall[2] := DstX2;
  Parall[3] := DstY1;
  Parall[4] := DstX2;
  Parall[5] := DstY2;

  RenderImage(Img, ImgX1, ImgY1, ImgX2, ImgY2, @Parall[0]);
end;

procedure TCanvasAggPas.TransformImage(Img: TCanvasAggPasImage;
  DstX1, DstY1, DstX2, DstY2: Double);
var
  Parall: TAggParallelogram;
begin
  FPath.RemoveAll;
  FPath.MoveTo(DstX1, DstY1);
  FPath.LineTo(DstX2, DstY1);
  FPath.LineTo(DstX2, DstY2);
  FPath.LineTo(DstX1, DstY2);
  FPath.ClosePolygon;

  Parall[0] := DstX1;
  Parall[1] := DstY1;
  Parall[2] := DstX2;
  Parall[3] := DstY1;
  Parall[4] := DstX2;
  Parall[5] := DstY2;

  RenderImage(Img, 0, 0, Img.FRenderingBuffer.Width,
    Img.FRenderingBuffer.Height, @Parall[0]);
end;

procedure TCanvasAggPas.TransformImage(Img: TCanvasAggPasImage;
  Destination: TRectDouble);
var
  Parall: TAggParallelogram;
begin
  FPath.RemoveAll;
  FPath.MoveTo(Destination.X1, Destination.Y1);
  FPath.LineTo(Destination.X2, Destination.Y1);
  FPath.LineTo(Destination.X2, Destination.Y2);
  FPath.LineTo(Destination.X1, Destination.Y2);
  FPath.ClosePolygon;

  Parall[0] := Destination.X1;
  Parall[1] := Destination.Y1;
  Parall[2] := Destination.X2;
  Parall[3] := Destination.Y1;
  Parall[4] := Destination.X2;
  Parall[5] := Destination.Y2;

  RenderImage(Img, 0, 0, Img.FRenderingBuffer.Width,
    Img.FRenderingBuffer.Height, @Parall[0]);
end;

procedure TCanvasAggPas.TransformImage(Img: TCanvasAggPasImage; ImgX1, ImgY1,
  ImgX2, ImgY2: Integer; Parallelogram: PDouble);
begin
  FPath.RemoveAll;
  FPath.MoveTo(PDouble(PtrComp(Parallelogram))^,
    PDouble(PtrComp(Parallelogram) + SizeOf(Double))^);
  FPath.LineTo(PDouble(PtrComp(Parallelogram) + 2 * SizeOf(Double))^,
    PDouble(PtrComp(Parallelogram) + 3 * SizeOf(Double))^);
  FPath.LineTo(PDouble(PtrComp(Parallelogram) + 4 * SizeOf(Double))^,
    PDouble(PtrComp(Parallelogram) + 5 * SizeOf(Double))^);
  FPath.LineTo(PDouble(PtrComp(Parallelogram))^ +
    PDouble(PtrComp(Parallelogram) + 4 * SizeOf(Double))^ -
    PDouble(PtrComp(Parallelogram) + 2 * SizeOf(Double))^,
    PDouble(PtrComp(Parallelogram) + SizeOf(Double))^ +
    PDouble(PtrComp(Parallelogram) + 5 * SizeOf(Double))^ -
    PDouble(PtrComp(Parallelogram) + 3 * SizeOf(Double))^);
  FPath.ClosePolygon;

  RenderImage(Img, ImgX1, ImgY1, ImgX2, ImgY2, Parallelogram);
end;

procedure TCanvasAggPas.TransformImage(Img: TCanvasAggPasImage;
  ImgRect: TRectInteger; Parallelogram: PDouble);
begin
  FPath.RemoveAll;
  FPath.MoveTo(PDouble(PtrComp(Parallelogram))^,
    PDouble(PtrComp(Parallelogram) + SizeOf(Double))^);
  FPath.LineTo(PDouble(PtrComp(Parallelogram) + 2 * SizeOf(Double))^,
    PDouble(PtrComp(Parallelogram) + 3 * SizeOf(Double))^);
  FPath.LineTo(PDouble(PtrComp(Parallelogram) + 4 * SizeOf(Double))^,
    PDouble(PtrComp(Parallelogram) + 5 * SizeOf(Double))^);
  FPath.LineTo(PDouble(PtrComp(Parallelogram))^ +
    PDouble(PtrComp(Parallelogram) + 4 * SizeOf(Double))^ -
    PDouble(PtrComp(Parallelogram) + 2 * SizeOf(Double))^,
    PDouble(PtrComp(Parallelogram) + SizeOf(Double))^ +
    PDouble(PtrComp(Parallelogram) + 5 * SizeOf(Double))^ -
    PDouble(PtrComp(Parallelogram) + 3 * SizeOf(Double))^);
  FPath.ClosePolygon;

  RenderImage(Img, ImgRect, Parallelogram);
end;

procedure TCanvasAggPas.TransformImage(Img: TCanvasAggPasImage;
  Parallelogram: PDouble);
begin
  FPath.RemoveAll;
  FPath.MoveTo(PDouble(Parallelogram)^, PDouble(PtrComp(Parallelogram) +
    SizeOf(Double))^);
  FPath.LineTo(PDouble(PtrComp(Parallelogram) + 2 * SizeOf(Double))^,
    PDouble(PtrComp(Parallelogram) + 3 * SizeOf(Double))^);
  FPath.LineTo(PDouble(PtrComp(Parallelogram) + 4 * SizeOf(Double))^,
    PDouble(PtrComp(Parallelogram) + 5 * SizeOf(Double))^);
  FPath.LineTo(PDouble(Parallelogram)^ +
    PDouble(PtrComp(Parallelogram) + 4 * SizeOf(Double))^ -
    PDouble(PtrComp(Parallelogram) + 2 * SizeOf(Double))^,
    PDouble(PtrComp(Parallelogram) + SizeOf(Double))^ +
    PDouble(PtrComp(Parallelogram) + 5 * SizeOf(Double))^ -
    PDouble(PtrComp(Parallelogram) + 3 * SizeOf(Double))^);
  FPath.ClosePolygon;

  RenderImage(Img, 0, 0, Img.FRenderingBuffer.Width,
    Img.FRenderingBuffer.Height, Parallelogram);
end;

procedure TCanvasAggPas.TransformImage(Img: TCanvasAggPasImage;
  ImgRect: TRectInteger; DstX1, DstY1, DstX2, DstY2: Double);
var
  Parall: TAggParallelogram;
begin
  Parall[0] := DstX1;
  Parall[1] := DstY1;
  Parall[2] := DstX2;
  Parall[3] := DstY1;
  Parall[4] := DstX2;
  Parall[5] := DstY2;

  RenderImage(Img, ImgRect, @Parall[0]);
end;

procedure TCanvasAggPas.TransformImage(Img: TCanvasAggPasImage;
  ImgRect: TRectInteger; Destination: TRectDouble);
var
  Parall: TAggParallelogram;
begin
  Parall[0] := Destination.X1;
  Parall[1] := Destination.Y1;
  Parall[2] := Destination.X2;
  Parall[3] := Destination.Y1;
  Parall[4] := Destination.X2;
  Parall[5] := Destination.Y2;

  RenderImage(Img, ImgRect, @Parall[0]);
end;

procedure TCanvasAggPas.TransformImagePath(Img: TCanvasAggPasImage;
  ImgX1, ImgY1, ImgX2, ImgY2: Integer; DstX1, DstY1, DstX2, DstY2: Double);
var
  Parall: TAggParallelogram;
begin
  Parall[0] := DstX1;
  Parall[1] := DstY1;
  Parall[2] := DstX2;
  Parall[3] := DstY1;
  Parall[4] := DstX2;
  Parall[5] := DstY2;

  RenderImage(Img, ImgX1, ImgY1, ImgX2, ImgY2, @Parall[0]);
end;

procedure TCanvasAggPas.TransformImagePath(Img: TCanvasAggPasImage;
  DstX1, DstY1, DstX2, DstY2: Double);
var
  Parall: TAggParallelogram;
begin
  Parall[0] := DstX1;
  Parall[1] := DstY1;
  Parall[2] := DstX2;
  Parall[3] := DstY1;
  Parall[4] := DstX2;
  Parall[5] := DstY2;

  RenderImage(Img, 0, 0, Img.FRenderingBuffer.Width,
    Img.FRenderingBuffer.Height, @Parall[0]);
end;

procedure TCanvasAggPas.TransformImagePath(Img: TCanvasAggPasImage;
  ImgX1, ImgY1, ImgX2, ImgY2: Integer; Parallelogram: PDouble);
begin
  RenderImage(Img, ImgX1, ImgY1, ImgX2, ImgY2, Parallelogram);
end;

procedure TCanvasAggPas.TransformImagePath(Img: TCanvasAggPasImage;
  Parallelogram: PDouble);
begin
  RenderImage(Img, 0, 0, Img.FRenderingBuffer.Width,
    Img.FRenderingBuffer.Height, Parallelogram);
end;

procedure TCanvasAggPas.BlendImage(Img: TCanvasAggPasImage;
  ImgX1, ImgY1, ImgX2, ImgY2: Integer;
  DstX, DstY: Double; Alpha: Cardinal = 255);
var
  PixF: TAggPixelFormatProcessor;
  R: TRectInteger;
begin
  WorldToScreen(@DstX, @DstY);
  PixelFormatRgba32(PixF, Img.FRenderingBuffer);
  R := RectInteger(ImgX1, ImgY1, ImgX2, ImgY2);

  if FBlendMode = bmAlpha then
    FRendererBasePre.BlendFrom(PixF, @R, Trunc(DstX) - ImgX1,
      Trunc(DstY) - ImgY1, Alpha)
  else
    FRendererBaseCompPre.BlendFrom(PixF, @R, Trunc(DstX) - ImgX1,
      Trunc(DstY) - ImgY1, Alpha);
end;

procedure TCanvasAggPas.BlendImage(Img: TCanvasAggPasImage; DstX, DstY: Double;
  Alpha: Cardinal = 255);
var
  PixF: TAggPixelFormatProcessor;
begin
  WorldToScreen(@DstX, @DstY);
  PixelFormatRgba32(PixF, Img.FRenderingBuffer);

  FRendererBasePre.BlendFrom(PixF, nil, Trunc(DstX), Trunc(DstY), Alpha);

  if FBlendMode = bmAlpha then
    FRendererBasePre.BlendFrom(PixF, nil, Trunc(DstX), Trunc(DstY), Alpha)
  else
    FRendererBaseCompPre.BlendFrom(PixF, nil, Trunc(DstX), Trunc(DstY), Alpha);
end;

procedure TCanvasAggPas.CopyImage(Img: TCanvasAggPasImage; ImgX1, ImgY1, ImgX2,
  ImgY2: Integer; DstX, DstY: Double);
var
  R: TRectInteger;
begin
  WorldToScreen(@DstX, @DstY);
  R := RectInteger(ImgX1, ImgY1, ImgX2, ImgY2);

  FRendererBase.CopyFrom(Img.FRenderingBuffer, @R, Trunc(DstX) - ImgX1,
    Trunc(DstY) - ImgY1);
end;

procedure TCanvasAggPas.CopyImage(Img: TCanvasAggPasImage;
  ImgRect: TRectInteger; Destination: TPointDouble);
begin
  WorldToScreen(@Destination.X, @Destination.Y);

  FRendererBase.CopyFrom(Img.FRenderingBuffer, @ImgRect,
    Trunc(Destination.X) - ImgRect.X1, Trunc(Destination.Y) - ImgRect.Y1);
end;

procedure TCanvasAggPas.CopyImage(Img: TCanvasAggPasImage; DstX, DstY: Double);
begin
  WorldToScreen(@DstX, @DstY);

  FRendererBase.CopyFrom(Img.FRenderingBuffer, nil, Trunc(DstX), Trunc(DstY));
end;

procedure TCanvasAggPas.CopyImage(Img: TCanvasAggPasImage;
  Destination: TPointDouble);
begin
  WorldToScreen(@Destination.X, @Destination.Y);

  FRendererBase.CopyFrom(Img.FRenderingBuffer, nil, Trunc(Destination.X),
    Trunc(Destination.Y));
end;

procedure TCanvasAggPas.UpdateApproximationScale;
begin
  FConvCurve.ApproximationScale := WorldToScreen(1) * GApproxScale;
  FConvStroke.ApproximationScale := WorldToScreen(1) * GApproxScale;
end;

procedure TCanvasAggPas.UpdateRasterizerGamma(MasterAlpha: Double);
begin
  if Assigned(FGammaAgg2D) then
    FGammaAgg2D.Free;

  FGammaAgg2D := TCanvasAggPasRasterizerGamma.Create(MasterAlpha,
    CAntiAliasGamma);
  FRasterizer.Gamma(FGammaAgg2D);
end;

procedure TCanvasAggPas.ResetClipRect;
begin
  FClipRect := RectF(0, 0, Width, Height);
  SetClipBox(FClipRect.Left, FClipRect.Top, FClipRect.Right,
    FClipRect.Bottom);
end;

procedure TCanvasAggPas.SetTextHints(Value: Boolean);
begin
  FTextHints := Value;
end;

{$IF CompilerVersion <= 23}
{procedure TCanvasAggPas.SetFont(FileName: TFileName; Height: Double;
  Bold: Boolean = False; Italic: Boolean = False; Angle: Double = 0);
var
  B: Integer;
begin
  FFontHeight := Height;

$IFDEF AGG2D_USE_FREETYPE
  FFontEngine.LoadFont(PAnsiChar(FileName), 0, grOutline);
  FFontEngine.Hinting := FTextHints;
  FFontEngine.SetHeight(Height)
$ELSE
  FFontEngine.Hinting := FTextHints;

  if Bold then
    B := 700
  else
    B := 400;

  FFontEngine.CreateFont(PAnsiChar(FileName), grOutline, Height, 0, B, Italic)
$ENDIF
end;

function TCanvasAggPas.TextWidth(Str: PAnsiChar): Double;
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

      First := False;
    end;

    Inc(PtrComp(Str));
  end;

  Result := X
end;

function TCanvasAggPas.TextWidth(Str: AnsiString): Double;
var
  X, Y : Double;
  First: Boolean;
  Glyph: PAggGlyphCache;
  I: Integer;
begin
  X := 0;
  Y := 0;

  First := True;

  for I := 1 to Length(Str) do
  begin
    Glyph := FFontCacheManager.Glyph(Int32u(Str[I]));

    if Glyph <> nil then
    begin
      if not First then
        FFontCacheManager.AddKerning(@X, @Y);

      X := X + Glyph.AdvanceX;
      Y := Y + Glyph.AdvanceY;

      First := False;
    end;
  end;

  Result := X;
end;}

procedure TCanvasAggPas.DrawLine(const APt1, APt2: TPointF;
  const AOpacity: Single);
begin
  FPath.RemoveAll;

  FPath.MoveTo(APt1.X, APt1.Y);
  FPath.LineTo(APt2.X, APt2.Y);
  RenderPath(RectF(APt1.X, APt1.Y, APt2.X, APt2.Y), AOpacity, Stroke, False);
end;

procedure TCanvasAggPas.FillRect(const ARect: TRectF; const XRadius,
  YRadius: Single; const ACorners: TCorners; const AOpacity: Single;
  const ACornerType: TCornerType);
var
  Path: TPathData;
begin
  if (ARect.Width <= 0) or (ARect.Height <= 0) then
    Exit;

  Path := TPathData.Create;
  try
    Path.AddRectangle(ARect, XRadius, YRadius, ACorners, ACornerType);
    FillPath(Path, AOpacity);
  finally
    Path.Free;
  end;
end;

procedure TCanvasAggPas.DrawRect(const ARect: TRectF; const XRadius,
  YRadius: Single; const ACorners: TCorners; const AOpacity: Single;
  const ACornerType: TCornerType);
var
  Path: TPathData;
begin
  Path := TPathData.Create;
  try
    Path.AddRectangle(ARect, XRadius, YRadius, ACorners, ACornerType);
    DrawPath(Path, AOpacity);
  finally
    Path.Free;
  end;
end;

procedure TCanvasAggPas.FillEllipse(const ARect: TRectF; const AOpacity: Single);
var
  El: TAggBezierArc;
begin
  FPath.RemoveAll;

  El := TAggBezierArc.Create(0.5 * (ARect.Left + ARect.Right),
    0.5 * (ARect.Top + ARect.Bottom), 0.5 * RectWidth(ARect),
    0.5 * RectHeight(ARect), 0, 2 * Pi);
  try
    FPath.AddPath(El, 0, False);
  finally
    El.Free;
  end;
  FPath.ClosePolygon;

  RenderPath(ARect, AOpacity, Fill);
end;

procedure TCanvasAggPas.DrawEllipse(const ARect: TRectF; const AOpacity: Single);
var
  El: TAggBezierArc;
begin
  FPath.RemoveAll;
  El := TAggBezierArc.Create(0.5 * (ARect.Left + ARect.Right),
    0.5 * (ARect.Top + ARect.Bottom), 0.5 * RectWidth(ARect),
    0.5 * RectHeight(ARect), 0, 2 * Pi);
  try
    FPath.AddPath(El, 0, False);
  finally
    El.Free;
  end;
  FPath.ClosePolygon;

  RenderPath(ARect, AOpacity, Stroke, False);
end;

function TCanvasAggPas.LoadFontFromStream(AStream: TStream): Boolean;
begin
  Result := False;
end;

procedure TCanvasAggPas.FillText(const ARect: TRectF; const AText: string;
  const WordWrap: Boolean; const AOpacity: Single; const Flags: TFillTextFlags;
  const ATextAlign, AVTextAlign: TTextAlign);
var
  Path: TPathData;
begin
  if (AText = '') or (AOpacity = 0) then
    Exit;

  Path := TPathData.Create;
  try
    TextToPath(Path, ARect, AText, WordWrap, ATextAlign, AVTextAlign);
    FillPath(Path, AOpacity);
  finally
    Path.Free;
  end;
end;

{procedure TCanvasAggPas.MeasureText(var ARect: TRectF; const AText: string;
  const WordWrap: Boolean; const Flags: TFillTextFlags; const ATextAlign,
  AVTextAlign: TTextAlign);
var
  Asc: Double;
  Str: AnsiString;
  CurPos: TPointDouble;
  Glyph: PAggGlyphCache;
  I: Integer;
begin
  SetFont(PAnsiChar(Font.Family), Font.Size, TFontStyle.fsBold in Font.Style,
    TFontStyle.fsItalic in Font.Style, 0);

  if AText = '' then
    Exit;

  Str := AnsiString(AText);

  Asc := FFontEngine.Height;
  Glyph := FFontCacheManager.Glyph(Int32u('H'));

  if Glyph <> nil then
    Asc := Glyph.Bounds.Y2 - Glyph.Bounds.Y1;

  if FFontEngine.FlipY then
    Asc := -Asc;

  // update alignment
  if WordWrap then
  begin
    CurPos.X := ARect.Left;
    CurPos.Y := ARect.Top - Asc;
  end
  else
  begin
    case ATextAlign of
      TTextAlign.taLeading:
        CurPos.X := ARect.Left;
      TTextAlign.taTrailing:
        CurPos.X := ARect.Right - TextWidth(Str);
      TTextAlign.taCenter:
        CurPos.X := 0.5 * (ARect.Right - ARect.Left - TextWidth(Str));
    end;

    case AVTextAlign of
      TTextAlign.taLeading:
        CurPos.Y := ARect.Top - Asc;
      TTextAlign.taTrailing:
        CurPos.Y := ARect.Bottom;
      TTextAlign.taCenter:
        CurPos.Y := 0.5 * (ARect.Bottom - ARect.Top - Asc);
    end;
  end;

  if False then
  begin
    CurPos.X := Trunc(CurPos.X);
    CurPos.Y := Trunc(CurPos.Y);
  end;

  I := 0;
  while PAnsiChar(PtrComp(Str) + I * SizeOf(AnsiChar))^ <> #0 do
  begin
    Glyph := FFontCacheManager.Glyph
      (Int32u(PAnsiChar(PtrComp(Str) + I * SizeOf(AnsiChar))^));

    if Glyph <> nil then
    begin
      if I <> 0 then
        FFontCacheManager.AddKerning(@CurPos.X, @CurPos.Y);

      FFontCacheManager.InitEmbeddedAdaptors(Glyph, CurPos.X, CurPos.Y);

      CurPos.X := CurPos.X + Glyph.AdvanceX;
      CurPos.Y := CurPos.Y + Glyph.AdvanceY;

      if WordWrap and (CurPos.X > ARect.Right) then
      begin
        CurPos.X := 0;
        CurPos.Y := CurPos.Y + Asc;
      end;
    end;
    Inc(I);
  end;

  ARect.Right := ARect.Left + CurPos.X;
  ARect.Bottom := ARect.Top + FFontEngine.Height + CurPos.Y;
end;}

procedure TCanvasAggPas.MeasureText(var ARect: TRectF; const AText: string;
  const WordWrap: Boolean; const Flags: TFillTextFlags; const ATextAlign,
  AVTextAlign: TTextAlign);
var
  Region: TRegion;
begin
  ARect := RectF(0, 0, 0, 0);
  if AText = '' then
    exit;

  FTextLayout.Text := AText;
  FTextLayout.WordWrap := WordWrap;
  FTextLayout.HorizontalAlign := ATextAlign;
  FTextLayout.VerticalAlign := AVTextAlign;

  Region := FTextLayout.MeasureRange(1, Length(AText));
  if Length(Region) > 0 then
    ARect := Region[0];
end;

{function TCanvasAggPas.TextToPath(Path: TPathData; const ARect: TRectF;
  const AText: string; const WordWrap: Boolean; const ATextAlign,
  AVTextAlign: TTextAlign): Boolean;
var
  Asc: Double;
  CurPos, Last: TPointDouble;
  Glyph: PAggGlyphCache;
  I: Integer;
  PX, PY: Double;
  Cmd: Cardinal;
  Str: AnsiString;
  VertexSource: TAggVertexSource;
  Bounds: PRectInteger;
begin
  Result := False;
  SetFont(PAnsiChar(Font.Family), Font.Size, TFontStyle.fsBold in Font.Style,
    TFontStyle.fsItalic in Font.Style, 0);

  Str := AnsiString(AText);

  if Str = '' then
    Exit;

  Asc := FFontHeight;
  Glyph := FFontCacheManager.Glyph(Int32u('H'));

  if Glyph <> nil then
    Asc := Glyph.Bounds.Y2 - Glyph.Bounds.Y1;

  if FFontEngine.FlipY then
    Asc := -Asc;

  // update alignment
  if WordWrap then
  begin
    CurPos.X := ARect.Left;
    CurPos.Y := ARect.Top - Asc;
  end
  else
  begin
    case ATextAlign of
      TTextAlign.taLeading:
        CurPos.X := ARect.Left;
      TTextAlign.taTrailing:
        CurPos.X := ARect.Right - TextWidth(Str);
      TTextAlign.taCenter:
        CurPos.X := 0.5 * (ARect.Right - ARect.Left - TextWidth(Str));
    end;

    case AVTextAlign of
      TTextAlign.taLeading:
        CurPos.Y := ARect.Top - Asc;
      TTextAlign.taTrailing:
        CurPos.Y := ARect.Bottom;
      TTextAlign.taCenter:
        CurPos.Y := 0.5 * (ARect.Bottom - ARect.Top - Asc);
    end;
  end;

  if False then
  begin
    CurPos.X := Trunc(CurPos.X);
    CurPos.Y := Trunc(CurPos.Y);
  end;

  VertexSource := FFontCacheManager.PathAdaptor;
  I := 0;

  while PAnsiChar(PtrComp(Str) + I * SizeOf(AnsiChar))^ <> #0 do
  begin
    Glyph := FFontCacheManager.Glyph
      (Int32u(PAnsiChar(PtrComp(Str) + I * SizeOf(AnsiChar))^));

    if Glyph <> nil then
    begin
      if I <> 0 then
        FFontCacheManager.AddKerning(@CurPos.X, @CurPos.Y);

      FFontCacheManager.InitEmbeddedAdaptors(Glyph, CurPos.X, CurPos.Y);
      if Glyph.DataType = gdOutline then
      begin
        VertexSource.Rewind(0);
        repeat
          Cmd := VertexSource.Vertex(@PX, @PY);
          case Cmd and CAggPathCmdMask of
            CAggPathCmdStop:
              Path.ClosePath;
            CAggPathCmdMoveTo:
              Path.MoveTo(PointF(PX, PY));
            CAggPathCmdLineTo:
              Path.LineTo(PointF(PX, PY));
            CAggPathCmdCurve3:
              begin
              Path.CurveTo(PointF(Last.X, Last.Y), PointF(Last.X, Last.Y),
                PointF(PX, PY));
              end;
            CAggPathCmdCurve4:
              Path.CurveTo(PointF(Last.X, Last.Y), PointF(Last.X, Last.Y),
                PointF(PX, PY));
            CAggPathCmdEndPoly:
              Path.ClosePath;
            else
              raise Exception.Create('not implemented');
          end;
          Last.X := PX;
          Last.Y := PY;
        until IsStop(Cmd);
      end;

      CurPos.X := CurPos.X + Glyph.AdvanceX;
      CurPos.Y := CurPos.Y + Glyph.AdvanceY;

      if WordWrap and (CurPos.X > ARect.Right) then
      begin
        CurPos.X := 0;
        CurPos.Y := CurPos.Y - Asc;
      end;
    end;
    Inc(I);
  end;

  Result := True;
end;}

function TCanvasAggPas.TextToPath(Path: TPathData; const ARect: TRectF;
  const AText: string; const WordWrap: Boolean; const ATextAlign,
  AVTextAlign: TTextAlign): Boolean;
begin
  if AText = '' then
    exit;

  FTextLayout.Text := AText;
  FTextLayout.WordWrap := WordWrap;
  FTextLayout.HorizontalAlign := ATextAlign;
  FTextLayout.VerticalAlign := AVTextAlign;

  FTextLayout.ConvertToPath(Path);
end;
{$IFEND}

function TCanvasAggPas.PtInPath(const APoint: TPointF;
  const APath: TPathData): Boolean;
begin
  Result := False;
end;

{$IF CompilerVersion <= 23}
procedure TCanvasAggPas.FillPath(const APath: TPathData; const AOpacity: Single);
begin
  CopyPath(APath);
  RenderPath(APath.GetBounds, AOpacity, Fill);
end;

procedure TCanvasAggPas.DrawPath(const APath: TPathData; const AOpacity: Single);
begin
  CopyPath(APath);
  RenderPath(APath.GetBounds, AOpacity, Stroke, False);
end;

procedure TCanvasAggPas.DrawBitmap(const ABitmap: TBitmap; const SrcRect,
  DstRect: TRectF; const AOpacity: Single; const HighSpeed: Boolean);
var
  CanvasAggPasImage: TCanvasAggPasImage;
  Clr: TAggColor;
  Mtx: TAggTransAffine;
  Parl: TAggParallelogram;
  Interpolator: TAggSpanInterpolatorLinear;
  SpanConverter: TAggSpanConverter;
  SpanImageResample: TAggSpanImageResampleRgbaAffine;
  Blend: TAggSpanConvImageBlend;
  RendererScanLineAA: TAggRendererScanLineAA;
begin
  UpdateBitmapHandle(ABitmap);
  if not ABitmap.HandleExists(Self) then
    Exit;
  UpdateRasterizerGamma(AOpacity);

  CanvasAggPasImage := TCanvasAggPasImage.Create(PInt8U(ABitmap.ScanLine[0]),
    ABitmap.Width, ABitmap.Height, 4 * ABitmap.Width);
  try
    FPath.RemoveAll;
    FPath.MoveTo(DstRect.Left, DstRect.Top);
    FPath.LineTo(DstRect.Right, DstRect.Top);
    FPath.LineTo(DstRect.Right, DstRect.Bottom);
    FPath.LineTo(DstRect.Left, DstRect.Bottom);
    FPath.ClosePolygon;

    FRasterizer.Reset;
    FRasterizer.AddPath(FPathTransform);

    Parl[0] := DstRect.Left;
    Parl[1] := DstRect.Top;
    Parl[2] := DstRect.Right;
    Parl[3] := DstRect.Top;
    Parl[4] := DstRect.Right;
    Parl[5] := DstRect.Bottom;

    Mtx := TAggTransAffine.Create(Round(SrcRect.Left), Round(SrcRect.Top),
      Round(SrcRect.Right), Round(SrcRect.Bottom), @Parl);
    try
      Mtx.Multiply(FTransform);
      Mtx.Invert;

      Interpolator := TAggSpanInterpolatorLinear.Create(Mtx);
      try
        Blend := TAggSpanConvImageBlend.Create(FImageBlendMode,
          FImageBlendColor, FPixelFormatCompPre);
        try
          Clr.Clear;
          SpanImageResample := TAggSpanImageResampleRgbaAffine.Create(
            FAllocator, CanvasAggPasImage.FRenderingBuffer, @Clr, Interpolator,
            FImageFilterLUT, CAggOrderBgra);
          try
            SpanConverter := TAggSpanConverter.Create(SpanImageResample, Blend);
            try
              RendererScanLineAA := TAggRendererScanLineAA.Create(
                FRendererBase, SpanConverter);
              try
                RenderScanLines(FRasterizer, FScanLine, RendererScanLineAA);
              finally
                RendererScanLineAA.Free;
              end;
            finally
              SpanConverter.Free;
            end;
          finally
            SpanImageResample.Free;
          end;
        finally
          Blend.Free;
        end;
      finally
        Interpolator.Free;
      end;
    finally
      Mtx.Free;
    end;
  finally
    CanvasAggPasImage.Free;
  end;
end;

procedure TCanvasAggPas.DrawThumbnail(const ABitmap: TBitmap; const Width,
  Height: Single);
var
  R: TRectF;
begin
  R := RectF(0, 0, Width, Height);
end;

procedure TCanvasAggPas.FillPolygon(const APolygon: TPolygon; const AOpacity: Single);
var
  Index: Integer;
  Rect: TRectF;
  PolygonDouble: array of TPointDouble;
begin
  if (AOpacity = 0) or (Fill.Kind = TBrushKind.bkNone) or (Length(APolygon) = 0)
    then Exit;

  SetLength(PolygonDouble, Length(APolygon));
  PolygonDouble[0].X := APolygon[0].X;
  PolygonDouble[0].Y := APolygon[0].Y;
  Rect.Left := APolygon[0].X;
  Rect.Top := APolygon[0].Y;
  Rect.Right := APolygon[0].X;
  Rect.Bottom := APolygon[0].Y;

  for Index := 1 to Length(APolygon) - 1 do
  begin
    PolygonDouble[Index].X := APolygon[Index].X;
    PolygonDouble[Index].Y := APolygon[Index].Y;
    if APolygon[Index].X < Rect.Left then
      Rect.Left := APolygon[Index].X;
    if APolygon[Index].Y < Rect.Top then
      Rect.Top := APolygon[Index].Y;
    if APolygon[Index].X > Rect.Right then
      Rect.Right := APolygon[Index].X;
    if APolygon[Index].Y > Rect.Bottom then
      Rect.Bottom := APolygon[Index].Y;
  end;

  FPath.RemoveAll;
  FPath.AddPoly(@PolygonDouble[0], Length(APolygon));
  FPath.ClosePolygon;

  RenderPath(Rect, AOpacity, Fill);
end;

procedure TCanvasAggPas.DrawPolygon(const APolygon: TPolygon;
  const AOpacity: Single);
var
  Index: Integer;
  Rect: TRectF;
  PolygonDouble: array of TPointDouble;
begin
  if (AOpacity = 0) or (Fill.Kind = TBrushKind.bkNone) or (Length(APolygon) = 0)
    then Exit;

  SetLength(PolygonDouble, Length(APolygon));
  PolygonDouble[0].X := APolygon[0].X;
  PolygonDouble[0].Y := APolygon[0].Y;
  Rect.Left := APolygon[0].X;
  Rect.Top := APolygon[0].Y;
  Rect.Right := APolygon[0].X;
  Rect.Bottom := APolygon[0].Y;

  for Index := 1 to Length(APolygon) - 1 do
  begin
    PolygonDouble[Index].X := APolygon[Index].X;
    PolygonDouble[Index].Y := APolygon[Index].Y;
    if APolygon[Index].X < Rect.Left then
      Rect.Left := APolygon[Index].X;
    if APolygon[Index].Y < Rect.Top then
      Rect.Top := APolygon[Index].Y;
    if APolygon[Index].X > Rect.Right then
      Rect.Right := APolygon[Index].X;
    if APolygon[Index].Y > Rect.Bottom then
      Rect.Bottom := APolygon[Index].Y;
  end;

  FPath.RemoveAll;
  FPath.AddPoly(@PolygonDouble[0], Length(APolygon));

  RenderPath(Rect, AOpacity, Stroke, False);
end;

class function TCanvasAggPas.GetBitmapScanline(Bitmap: TBitmap;
  y: Integer): PAlphaColorArray;
begin
  if (y >= 0) and (y < Bitmap.Height) and (Bitmap.StartLine <> nil) then
    Result := @PAlphaColorArray(Bitmap.StartLine)[(y) * Bitmap.Width]
  else
    Result := nil;
end;

procedure TCanvasAggPas.UpdateBitmapHandle(ABitmap: TBitmap);
begin
  if ABitmap = nil then
    Exit;
  if ABitmap.IsEmpty then
    Exit;

  if not ABitmap.HandleExists(Self) then
  begin
    ABitmap.HandleAdd(Self);
    ABitmap.HandlesNeedUpdate[Self] := False;
    ABitmap.AddFreeNotify(Self);
    FBitmaps.Add(ABitmap);
  end;
end;

procedure TCanvasAggPas.DestroyBitmapHandle(ABitmap: TBitmap);
begin
  if (ABitmap.HandleExists(Self)) then
  begin
    FBitmaps.Remove(ABitmap);
    ABitmap.RemoveFreeNotify(Self);
    ABitmap.HandleRemove(Self);
  end;
end;
{$ELSE}

procedure TCanvasAggPas.DoFillRect(const ARect: TRectF; const AOpacity: Single;
  const ABrush: TBrush);
var
  Path: TPathData;
begin
  if (ARect.Width <= 0) or (ARect.Height <= 0) then
    Exit;

  Path := TPathData.Create;
  try
    Path.AddRectangle(ARect, 0, 0, AllCorners,
      {$IF CompilerVersion <= 26}
        TCornerType.ctBevel
      {$ELSE}
        TCornerType.Bevel
      {$IFEND});
    ApplyFill(ABrush, ARect, AOpacity);
    DoFillPath(Path, AOpacity, ABrush);
  finally
    Path.Free;
  end;
end;

class procedure TCanvasAggPas.DoFinalizeBitmap(const Bitmap: TBitmap);
begin
  FreeMem(pointer(Bitmap.Handle));
end;

class procedure TCanvasAggPas.DoInitializeBitmap(const Bitmap: TBitmap);
var
  Ptr: pointer;
begin
  GetMem(Ptr, Bitmap.Width * Bitmap.Height * 4);

  (Bitmap as IBitmapAccess).Handle := THandle(Ptr);
  (Bitmap as IBitmapAccess).PixelFormat := TPixelFormat.pfA8R8G8B8;
end;

class function TCanvasAggPas.DoMapBitmap(const Bitmap: TBitmap;
  const Access: TMapAccess; var Data: TBitmapData): Boolean;
begin
  Data.Create(Bitmap.Width, Bitmap.Height, Bitmap.PixelFormat);
  Data.Data := pointer(Bitmap.Handle);
  Data.Pitch := Bitmap.Width * 4;
  Result := True;
end;

class procedure TCanvasAggPas.DoUnmapBitmap(const Bitmap: TBitmap;
  var Data: TBitmapData);
begin
  inherited;
end;

procedure TCanvasAggPas.DoFillPath(const APath: TPathData;
  const AOpacity: Single; const ABrush: TBrush);
var
  Rect: TRectF;
begin
  Rect := APath.GetBounds;
  ApplyFill(ABrush, Rect, AOpacity);
  CopyPath(APath);
  RenderPath(Rect, AOpacity, ABrush);
end;

procedure TCanvasAggPas.DoFillEllipse(const ARect: TRectF;
  const AOpacity: Single; const ABrush: TBrush);
var
  El: TAggBezierArc;
begin
  FPath.RemoveAll;

  El := TAggBezierArc.Create(0.5 * (ARect.Left + ARect.Right),
    0.5 * (ARect.Top + ARect.Bottom), 0.5 * RectWidth(ARect),
    0.5 * RectHeight(ARect), 0, 2 * Pi);
  try
    FPath.AddPath(El, 0, False);
  finally
    El.Free;
  end;
  FPath.ClosePolygon;

  ApplyFill(ABrush, ARect, AOpacity);
  RenderPath(ARect, AOpacity, ABrush);
end;

procedure TCanvasAggPas.DoDrawBitmap(const ABitmap: TBitmap; const SrcRect,
  DstRect: TRectF; const AOpacity: Single; const HighSpeed: Boolean = False);
var
  //CanvasAggPasImage: TCanvasAggPasImage;
  Clr: TAggColor;
  Mtx: TAggTransAffine;
  Parl: TAggParallelogram;
  Interpolator: TAggSpanInterpolatorLinear;
  SpanConverter: TAggSpanConverter;
  SpanImageResample: TAggSpanImageResampleRgbaAffine;
  Blend: TAggSpanConvImageBlend;
  //BitmapData: TAggRendererScanLineAA;
  //BitmalData: TBitmapData;
  RendererScanLineAA: TAggRendererScanLineAA;
  BitmapBuffer: TAggRenderingBuffer;
begin
  if (SrcRect.Width <= 0) or (SrcRect.Height <= 0)
  or (DstRect.Width <= 0) or (DstRect.Height <= 0)
  then
    exit;


(*
  TODO !!!

  UpdateBitmapHandle(ABitmap);
  if not ABitmap.HandleExists(Self) then
    Exit;

  UpdateRasterizerGamma(AOpacity);

  ABitmap.Map(TMapAccess.Read, BitmapData);

  CanvasAggPasImage := TCanvasAggPasImage.Create(PInt8U(ABitmap.Image.ScanLine[0]),
    ABitmap.Width, ABitmap.Height, 4 * ABitmap.Width);
*)

  BitmapBuffer := TCanvasAggPas(aBitmap.Canvas).FRenderingBuffer;
  try
    FPath.RemoveAll;
    FPath.MoveTo(DstRect.Left, DstRect.Top);
    FPath.LineTo(DstRect.Right, DstRect.Top);
    FPath.LineTo(DstRect.Right, DstRect.Bottom);
    FPath.LineTo(DstRect.Left, DstRect.Bottom);
    FPath.ClosePolygon;

    FRasterizer.Reset;
    FRasterizer.AddPath(FPathTransform);

    Parl[0] := DstRect.Left;
    Parl[1] := DstRect.Top;
    Parl[2] := DstRect.Right;
    Parl[3] := DstRect.Top;
    Parl[4] := DstRect.Right;
    Parl[5] := DstRect.Bottom;

    Mtx := TAggTransAffine.Create(Round(SrcRect.Left), Round(SrcRect.Top),
      Round(SrcRect.Right), Round(SrcRect.Bottom), @Parl);
    try
      Mtx.Multiply(FTransform);
      Mtx.Invert;

      Interpolator := TAggSpanInterpolatorLinear.Create(Mtx);
      try
        Blend := TAggSpanConvImageBlend.Create(FImageBlendMode,
          FImageBlendColor, FPixelFormatCompPre);
        try
          Clr.Clear;
          SpanImageResample := TAggSpanImageResampleRgbaAffine.Create(
            FAllocator, {CanvasAggPasImage.FRenderingBuffer}BitmapBuffer, @Clr, Interpolator,
            FImageFilterLUT, CAggOrderBgra);
          try
            SpanConverter := TAggSpanConverter.Create(SpanImageResample, Blend);
            try
              RendererScanLineAA := TAggRendererScanLineAA.Create(
                FRendererBase, SpanConverter);
              try
                RenderScanLines(FRasterizer, FScanLine, RendererScanLineAA);
              finally
                RendererScanLineAA.Free;
              end;
            finally
              SpanConverter.Free;
            end;
          finally
            SpanImageResample.Free;
          end;
        finally
          Blend.Free;
        end;
      finally
        Interpolator.Free;
      end;
    finally
      Mtx.Free;
    end;
  finally
    //CanvasAggPasImage.Free;
  end;
end;

procedure TCanvasAggPas.DoDrawLine(const APt1, APt2: TPointF; const AOpacity: Single; const ABrush: TStrokeBrush);
var
  Rect: TRectF;
begin
  FPath.RemoveAll;
  FPath.MoveTo(APt1.X, APt1.Y);
  FPath.LineTo(APt2.X, APt2.Y);

  Rect := RectF(APt1.X, APt1.Y, APt2.X, APt2.Y);

  ApplyStroke(ABrush, Rect, AOpacity);
  RenderPath(Rect, AOpacity, ABrush, False);
end;

procedure TCanvasAggPas.DoDrawRect(const ARect: TRectF; const AOpacity: Single; const ABrush: TStrokeBrush);
var
  Path: TPathData;
begin
  Path := TPathData.Create;
  try
    Path.AddRectangle(ARect, 0, 0, AllCorners,
      {$IF CompilerVersion <= 26}
        TCornerType.ctBevel
      {$ELSE}
        TCornerType.Bevel
      {$IFEND});

    ApplyStroke(ABrush, ARect, AOpacity);
    DoDrawPath(Path, AOpacity, ABrush);
  finally
    Path.Free;
  end;
end;

procedure TCanvasAggPas.DoDrawPath(const APath: TPathData; const AOpacity: Single; const ABrush: TStrokeBrush);
var
  Rect: TRectF;
begin
  CopyPath(APath);
  Rect := APath.GetBounds;

  ApplyStroke(ABrush, Rect, AOpacity);
  RenderPath(Rect, AOpacity, ABrush, False);
end;

procedure TCanvasAggPas.DoDrawEllipse(const ARect: TRectF; const AOpacity: Single; const ABrush: TStrokeBrush);
var
  El: TAggBezierArc;
begin
  FPath.RemoveAll;
  El := TAggBezierArc.Create(0.5 * (ARect.Left + ARect.Right),
    0.5 * (ARect.Top + ARect.Bottom), 0.5 * RectWidth(ARect),
    0.5 * RectHeight(ARect), 0, 2 * Pi);
  try
    FPath.AddPath(El, 0, False);
  finally
    El.Free;
  end;
  FPath.ClosePolygon;

  ApplyStroke(ABrush, ARect, AOpacity);
  RenderPath(ARect, AOpacity, ABrush, False);
end;
{$IFEND}

{$IFNDEF AGG2D_USE_FREETYPE }
procedure TCanvasAggPas.FontChanged(Sender: TObject);
var
  LF: TLogFont;
begin
  LF := Default(TLogFont);
  DeleteObject(FFontHandle);
  with LF do
  begin
    lfHeight := -Round(Font.Size);
    lfWidth := 0;
    lfEscapement := 0;
    lfOrientation := 0;
    if TFontStyle.fsBold in Font.Style then
      lfWeight := FW_BOLD
    else
      lfWeight := FW_NORMAL;
    lfItalic := Byte(TFontStyle.fsItalic in Font.Style);
    lfUnderline := Byte(TFontStyle.fsUnderline in Font.Style);
    lfStrikeOut := Byte(TFontStyle.fsStrikeOut in Font.Style);
{$WARNINGS OFF}
    StrPLCopy(lfFaceName, UTF8ToString(Font.Family), Length(lfFaceName) - 1);
{$WARNINGS ON}
    lfCharSet := DEFAULT_CHARSET;
    lfQuality := DEFAULT_QUALITY;
    lfOutPrecision := OUT_DEFAULT_PRECIS;
    lfClipPrecision := CLIP_DEFAULT_PRECIS;
    lfPitchAndFamily := DEFAULT_PITCH;
  end;
  FFontHandle := CreateFontIndirect(LF);
end;
{$ENDIF}

function TCanvasAggPas.CreateSaveState: TCanvasSaveState;
begin
  Result := TCanvasAggPasSaveState.Create;
end;

procedure TCanvasAggPas.CopyPath(APath: TPathData);
var
  I: Integer;
  Bounds, R: TRectF;
  StartPoint: TPointF;
  PathPoint: TPathPoint;
begin
  with APath do
    if Count > 0 then
    begin
      Bounds := GetBounds;
      R := Bounds;
      I := 0;
      FPath.RemoveAll;
      while i < Count do
      begin
        PathPoint := Points[I];
        case PathPoint.Kind of
          TPathPointKind.ppMoveTo:
            begin
              FPath.MoveTo(PathPoint.Point.X, PathPoint.Point.Y);
              StartPoint := PathPoint.Point;
            end;
          TPathPointKind.ppLineTo:
            FPath.LineTo(PathPoint.Point.X, PathPoint.Point.Y);
          TPathPointKind.ppCurveTo:
            begin
              FPath.Curve4(PathPoint.Point.X, PathPoint.Point.Y,
                Points[I + 1].Point.X, Points[I + 1].Point.Y,
                Points[I + 2].Point.X, Points[I + 2].Point.Y);
              Inc(I, 2);
            end;
          TPathPointKind.ppClose:
            Self.FPath.LineTo(StartPoint.X, StartPoint.Y);
        end;
        Inc(I);
      end;
    end;
end;

{ TCanvasAggPasSaveState }

procedure TCanvasAggPasSaveState.Assign(Source: TPersistent);
begin
  inherited;

  if Source is TCanvasAggPas then
    FClipRect := TCanvasAggPas(Source).FClipRect;
end;

procedure TCanvasAggPasSaveState.AssignTo(Dest: TPersistent);
begin
  inherited;

  if Dest is TCanvasAggPas then
    TCanvasAggPas(Dest).FClipRect := FClipRect;
end;

procedure SetAggPasDefault;
begin
  GlobalUseDirect2D := False;
{$IF CompilerVersion <= 23}
  DefaultCanvasClass := TCanvasAggPas;
{$ELSE}
  TCanvasManager.RegisterCanvas(TCanvasAggPas, True, False);
{$IFEND}
end;

{ TAggSpanConvImageBlend }

constructor TAggSpanConvImageBlend.Create(BlendMode: TAggBlendMode; C: TAggRgba8;
  P: TAggPixelFormatProcessor);
begin
  FMode := BlendMode;
  FColor := C;
  FPixel := P;
end;

procedure TAggSpanConvImageBlend.Convert(Span: PAggColor; X, Y: Integer;
  Len: Cardinal);
var
  L2, A: Cardinal;
  S2: PAggColor;
begin
  if FMode <> bmDestination then
  begin
    L2 := Len;
    S2 := PAggColor(Span);

    repeat
      BlendModeAdaptorClipToDestinationRgbaPre(FPixel, FMode,
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
      S2.Rgba8.R := (S2.Rgba8.R * A) shr CAggBaseShift;
      S2.Rgba8.G := (S2.Rgba8.G * A) shr CAggBaseShift;
      S2.Rgba8.B := (S2.Rgba8.B * A) shr CAggBaseShift;
      S2.Rgba8.A := (S2.Rgba8.A * A) shr CAggBaseShift;

      Inc(PtrComp(S2), SizeOf(TAggColor));
      Dec(L2);
    until L2 = 0;
  end;
end;

{$IF CompilerVersion <= 23}

{ TTextLayout }

constructor TTextLayout.Create(const ACanvas: TCanvas = nil);
begin
  FText := '';
  FTextRect := RectF(0, 0, 0, 0);
  FTopLeft := PointF(0, 0);
  FFont := TFont.Create;
  FWordWrap := False;
  FHorizontalAlign := TTextAlign.taLeading;
  FVerticalAlign := TTextAlign.taLeading;
  FOpacity := 1;
end;

destructor TTextLayout.Destroy;
begin
  FFont.Free;
end;

procedure TTextLayout.SetFont(const aValue: TFont);
begin
  FFont.Assign(aValue);
end;

procedure TTextLayout.SetHorizontalAlign(const Value: TTextAlign);
begin
  FHorizontalAlign := Value;
end;

procedure TTextLayout.SetVerticalAlign(const Value: TTextAlign);
begin
  FVerticalAlign := Value;
end;
{$IFEND}

{ TTextLayoutAggPas }

procedure TTextLayoutAggPas.ConvertToPath(const APath: TPathData);
var
  Asc: Double;
  CurPos, Last: TPointDouble;
  Glyph: PAggGlyphCache;
  I: Integer;
  PX, PY: Double;
  Cmd: Cardinal;
  Str: AnsiString;
  VertexSource: TAggVertexSource;
begin
  if Text = '' then
    exit;

  SetFont(Font.Family, Font.Size, TFontStyle.fsBold in Font.Style,
    TFontStyle.fsItalic in Font.Style, 0);

  Str := AnsiString(Text);

  if Str = '' then
    Exit;

  Asc := FHeight;
  Glyph := FFontCacheManager.Glyph(Int32u('H'));

  if Glyph <> nil then
    Asc := Glyph.Bounds.Y2 - Glyph.Bounds.Y1;

  if FFontEngine.FlipY then
    Asc := -Asc;

  // update alignment
  if WordWrap then
  begin
    CurPos.X := TextRect.Left;
    CurPos.Y := TextRect.Top - Asc;
  end
  else
  begin
    case HorizontalAlign of
      TTextAlign.taLeading:
        CurPos.X := TextRect.Left;
      TTextAlign.taTrailing:
        CurPos.X := TextRect.Right - TextWidth;
      TTextAlign.taCenter:
        CurPos.X := 0.5 * (TextRect.Right - TextRect.Left - TextWidth);
    end;

    case VerticalAlign of
      TTextAlign.taLeading:
        CurPos.Y := TextRect.Top - Asc;
      TTextAlign.taTrailing:
        CurPos.Y := TextRect.Bottom;
      TTextAlign.taCenter:
        CurPos.Y := 0.5 * (TextRect.Bottom - TextRect.Top - Asc);
    end;
  end;

  if False then
  begin
    CurPos.X := Trunc(CurPos.X);
    CurPos.Y := Trunc(CurPos.Y);
  end;

  VertexSource := FFontCacheManager.PathAdaptor;
  I := 0;

  while PAnsiChar(PtrComp(Str) + I * SizeOf(AnsiChar))^ <> #0 do
  begin
    Glyph := FFontCacheManager.Glyph
      (Int32u(PAnsiChar(PtrComp(Str) + I * SizeOf(AnsiChar))^));

    if Glyph <> nil then
    begin
      if I <> 0 then
        FFontCacheManager.AddKerning(@CurPos.X, @CurPos.Y);

      FFontCacheManager.InitEmbeddedAdaptors(Glyph, CurPos.X, CurPos.Y);
      if Glyph.DataType = gdOutline then
      begin
        VertexSource.Rewind(0);
        repeat
          Cmd := VertexSource.Vertex(@PX, @PY);
          case Cmd and CAggPathCmdMask of
            CAggPathCmdStop:
              APath.ClosePath;
            CAggPathCmdMoveTo:
              APath.MoveTo(PointF(PX, PY));
            CAggPathCmdLineTo:
              APath.LineTo(PointF(PX, PY));
            CAggPathCmdCurve3:
              begin
              APath.CurveTo(PointF(Last.X, Last.Y), PointF(Last.X, Last.Y),
                PointF(PX, PY));
              end;
            CAggPathCmdCurve4:
              APath.CurveTo(PointF(Last.X, Last.Y), PointF(Last.X, Last.Y),
                PointF(PX, PY));
            CAggPathCmdEndPoly:
              APath.ClosePath;
            else
              raise Exception.Create('not implemented');
          end;
          Last.X := PX;
          Last.Y := PY;
        until IsStop(Cmd);
      end;

      CurPos.X := CurPos.X + Glyph.AdvanceX;
      CurPos.Y := CurPos.Y + Glyph.AdvanceY;

      if WordWrap and (CurPos.X > TextRect.Right) then
      begin
        CurPos.X := 0;
        CurPos.Y := CurPos.Y - Asc;
      end;
    end;
    Inc(I);
  end;
end;

constructor TTextLayoutAggPas.Create(const ACanvas: TCanvas);
begin
  inherited;

  FLeft := 0;
  FTop := 0;
  FHeight := 0;
  FWidth := 0;

  FFontEngine.FlipY := True;
end;

class constructor TTextLayoutAggPas.Create;
begin
  inherited;

{$IFDEF AGG2D_USE_FREETYPE}
  FFontEngine := TAggFontEngineFreetypeInt32.Create;
{$ELSE}
  FFontDC := GetDC(0);
  FFontEngine := TAggFontEngineWin32TrueTypeInt32.Create(FFontDC);
{$ENDIF}
  FFontCacheManager := TAggFontCacheManager.Create(FFontEngine);
end;

destructor TTextLayoutAggPas.Destroy;
begin
  inherited;
end;

class destructor TTextLayoutAggPas.Destroy;
begin
{$IFNDEF AGG2D_USE_FREETYPE}
  ReleaseDC(0, FFontDC);
  DeleteObject(FFontHandle);
{$ENDIF}
  FFontEngine.Free;
  FFontCacheManager.Free;

  inherited;
end;

procedure TTextLayoutAggPas.DoDrawLayout(const ACanvas: TCanvas);
var
  Path: TPathData;
begin
  if Text = '' then
    exit;

  if aCanvas is TCanvasAggPas then
  begin

    Path := TPathData.Create;
    try
      ConvertToPath(Path);
      aCanvas.FillPath(Path, Opacity);
    finally
      Path.Free;
    end;
  end;
end;

function TTextLayoutAggPas.DoPositionAtPoint(const APoint: TPointF): Integer;
begin
  // Stub
  Result := 0;
end;

function TTextLayoutAggPas.DoRegionForRange(const ARange: TTextRange): TRegion;
begin
  // Stub
end;

procedure TTextLayoutAggPas.DoRenderLayout;
begin
  SetFont(
    Font.Family,
    Font.Size,
    TFontStyle.fsBold in Font.Style,
    TFontStyle.fsItalic in Font.Style,
    0);
end;

function TTextLayoutAggPas.GetTextHeight: Single;
begin
  Result := FHeight;
end;

function TTextLayoutAggPas.GetTextRect: TRectF;
begin
  Result := TRectF.Create(FLeft, FTop, FLeft + FWidth, FTop + FHeight);
  Result.Offset(TopLeft);
end;

function TTextLayoutAggPas.GetTextWidth: Single;
begin
  Result := FWidth;
end;

function TTextLayoutAggPas.MeasureRange(const APos, ALength: Integer): TRegion;
var
  Asc: Double;
  Str: AnsiString;
  CurPos: TPointDouble;
  Glyph: PAggGlyphCache;
  I: Integer;
begin
  SetLength(Result, 0);

  SetFont(Font.Family, Font.Size, TFontStyle.fsBold in Font.Style,
    TFontStyle.fsItalic in Font.Style, 0);

  if Text = '' then
    Exit;

  Str := AnsiString(Text);

  Asc := FFontEngine.GetHeight;
  Glyph := FFontCacheManager.Glyph(Int32u('H'));

  if Glyph <> nil then
    Asc := Glyph.Bounds.Y2 - Glyph.Bounds.Y1;

  if FFontEngine.FlipY then
    Asc := -Asc;

  // update alignment
  if WordWrap then
  begin
    CurPos.X := TextRect.Left;
    CurPos.Y := TextRect.Top - Asc;
  end
  else
  begin
    case HorizontalAlign of
      TTextAlign.taLeading:
        CurPos.X := TextRect.Left;
      TTextAlign.taTrailing:
        CurPos.X := TextRect.Right - TextWidth;
      TTextAlign.taCenter:
        CurPos.X := 0.5 * (TextRect.Right - TextRect.Left - TextWidth);
    end;

    case VerticalAlign of
      TTextAlign.taLeading:
        CurPos.Y := TextRect.Top - Asc;
      TTextAlign.taTrailing:
        CurPos.Y := TextRect.Bottom;
      TTextAlign.taCenter:
        CurPos.Y := 0.5 * (TextRect.Bottom - TextRect.Top - Asc);
    end;
  end;

  if False then
  begin
    CurPos.X := Trunc(CurPos.X);
    CurPos.Y := Trunc(CurPos.Y);
  end;

  I := 0;
  while (I < APos + ALength) and (PAnsiChar(PtrComp(Str) + I * SizeOf(AnsiChar))^ <> #0) do
  begin
    if I = APos then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := RectF(CurPos.X, CurPos.Y, CurPos.X, CurPos.Y);
    end;


    Glyph := FFontCacheManager.Glyph
      (Int32u(PAnsiChar(PtrComp(Str) + I * SizeOf(AnsiChar))^));

    if Glyph <> nil then
    begin
      if I <> 0 then
        FFontCacheManager.AddKerning(@CurPos.X, @CurPos.Y);

      FFontCacheManager.InitEmbeddedAdaptors(Glyph, CurPos.X, CurPos.Y);

      CurPos.X := CurPos.X + Glyph.AdvanceX;
      CurPos.Y := CurPos.Y + Glyph.AdvanceY;

      if WordWrap and (CurPos.X > TextRect.Right) then
      begin
        CurPos.X := 0;
        CurPos.Y := CurPos.Y + Asc;
      end;
    end;
    Inc(I);
  end;

  if I > APos then
  begin
    Result[High(Result)].Right := CurPos.X;
    Result[High(Result)].Bottom := CurPos.Y;
  end;
end;

procedure TTextLayoutAggPas.SetFont(FileName: TFileName; Height: Double; Bold,
  Italic: Boolean; Angle: Double);
var
  B: Integer;
begin
  FHeight := Height;

{$IFDEF AGG2D_USE_FREETYPE}
  FFontEngine.LoadFont('C:\Windows\Fonts\arial.ttf'{PAnsiChar(FileName)}, 0, grOutline);
  FFontEngine.Hinting := FTextHints;
  FFontEngine.SetHeight(Height)
{$ELSE}
  FFontEngine.Hinting := FTextHints;

  if Bold then
    B := 700
  else
    B := 400;

  FFontEngine.CreateFont(PAnsiChar(FileName), grOutline, Height, 0, B, Italic)
{$ENDIF}
end;

initialization
{$IFNDEF DISABLEAUTOINITIALIZE}
  SetAggPasDefault;
{$IF CompilerVersion > 23}
  TTextLayoutManager.RegisterTextLayout(TTextLayoutAggPas, TCanvasAggPas);
{$IFEND}
{$ENDIF}

end.
