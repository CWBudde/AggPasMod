unit FMX.Canvas.AggPas;

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//  Anti-Grain Geometry (modernized Pascal fork, aka 'AggPasMod')             //
//    Maintained by Christian-W. Budde (Christian@pcjv.de)          //
//    Copyright (c) 2012-2017                                                 //
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
//                                                                            //
//  B.Verhue 1-11-2016                                                        //
//                                                                            //
//  - Compatibility with higher Delphi versions                               //
//  - Added buffering system and BeginScene Endscne methods                   //
//  - Aditions and fixes to font rendering                                    //
//  - Added text layout classes                                               //
//  - Updated compiler versions ifdefs                                        //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

interface
uses
  System.Classes;

{$I ..\AggCompiler.inc}

{$WARN SYMBOL_DEPRECATED OFF}

// See also Agg2D.pas
{-$DEFINE AGG2D_USE_FREETYPE}

procedure SetAggPasDefault;
{$IFDEF AGG2D_USE_FREETYPE}
procedure GetFontNames(aStrings: TStrings);
{$ENDIF}

implementation

{$WARNINGS ON}
{$HINTS ON}

{$IFNDEF VER230}
  {$LEGACYIFEND ON}
{$ENDIF}

// CompilerVersion23: XE2
// CompilerVersion24: XE3
// CompilerVersion25: XE4
// CompilerVersion26: XE5
// CompilerVersion27: XE6
// CompilerVersion28: XE7
// CompilerVersion29: XE8
// CompilerVersion30: DX
// CompilerVersion31: DX1

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
  Winapi.ShlObj,
  FMX.Platform.Win,
  {$ENDIF}
  {$IFDEF ANDROID}
  FMX.Platform.Android,
  {$ENDIF}
  FMX.Types,
  System.Character,
  System.Types,
  System.UIConsts,
  System.SysUtils,
  System.UITypes,
  System.Math,
  {$IF CompilerVersion > 23}
  {$IF CompilerVersion < 27}
  FMX.PixelFormats,
  {$IFEND}
  {$IFEND}
  {$IF CompilerVersion = 24}
  FMX.Text,
  {$IFEND}
  {$IF CompilerVersion > 24}
  FMX.TextLayout,
  {$IFEND}
  {$IF CompilerVersion > 25}
  FMX.Graphics,
  {$IFEND}
  {$IF CompilerVersion >= 27}
  System.Math.Vectors,
  {$IFEND}
  {$IF CompilerVersion >= 29}
  System.Generics.Collections,
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
  AggConvContour,
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

  {$IFDEF AGG2D_USE_FREETYPE}
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

  {$IF CompilerVersion >= 28}
  TCanvasAggPasBitmap = class
  private
    FData: pointer;
    FWidth: integer;
    FHeight: integer;
    FPixelformat: TPixelFormat;
  public
    constructor Create(const aWidth, aHeight: integer);
    destructor Destroy; override;

    property Data: pointer read FData;
    property Width: integer read FWidth;
    property Height: integer read FHeight;
    property Pixelformat: TPixelformat read FPixelFormat;
  end;
  {$IFEND}

  {$IF CompilerVersion <= 23}
  TBitmapData = record
    Data: pointer;
    Width: integer;
    Height: integer;
    Pitch: integer;
  end;

  TRegion = array of TRectF;
  TTextRange = record
    Pos: integer;
    Length: integer;
  end;

  TTextLayoutAggPas = class;

  TTextLayout = class
  private
    FText: string;
    FTopLeft: TPointF;
    FFont: TFont;
    FPadding: TBounds;
    FMaxSize: TPointF;
    FWordWrap: boolean;
    FHorizontalAlign: TTextAlign;
    FVerticalAlign: TTextAlign;
    FColor: TAlphaColor;
    FOpacity: single;
    FUpdating: Integer;
    FNeedUpdate: Boolean;
    procedure SetFont(const aValue: TFont);
    procedure SetHorizontalAlign(const Value: TTextAlign);
    procedure SetVerticalAlign(const Value: TTextAlign);
    procedure SetPadding(const Value: TBounds);
    procedure SetMaxSize(const Value: TPointF);
    procedure NeedUpdate;
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

    procedure BeginUpdate;
    procedure EndUpdate;

    property Color: TAlphaColor read FColor;
    property Text: string read FText write FText;
    property TextRect: TRectF read GetTextRect;
    property TextWidth: Single read GetTextWidth;
    property TopLeft: TPointF read FTopLeft write FTopLeft;
    property Font: TFont read FFont write SetFont;
    property Padding: TBounds read FPadding write SetPadding;
    property MaxSize: TPointF read FMaxSize write SetMaxSize;
    property WordWrap: boolean read FWordWrap write FWordWrap;
    property HorizontalAlign: TTextAlign read FHorizontalAlign write SetHorizontalAlign;
    property VerticalAlign: TTextAlign read FVerticalAlign write SetVerticalAlign;
    property Opacity: Single read FOpacity write FOpacity;
  end;
  {$IFEND}

  TCanvasAggPas = class(TCanvas)
  private
    {$IF CompilerVersion <= 24}
    FBitmapInfo: TBitmapInfo;
    FBufferBitmap: THandle;
    {$ELSE}
    [Weak] FBitmap: TBitmap;
    FContextHandle: THandle;
    FClipRects: PClipRects;
    {$IFEND}

    {$IF CompilerVersion > 23}
    FBitmapData: TBitmapData;
    {$IFEND}

    {$IFDEF MACOS}
    FBitmapContext: CGContextRef;
    FImage: CGImageRef;
    {$ENDIF}

    {$IFNDEF AGG2D_USE_FREETYPE}
    FFontHandle: HFONT;
    {$ENDIF}

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
    //FTextHints: Boolean;
    //FFontHeight: Double;
    //FFontAscent: Double;
    //FFontDescent: Double;
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

    // TODO
    //procedure SetTextHints(Value: Boolean); overload;
    procedure SetImageResample(F: TAggImageResample); overload;
    procedure SetFillEvenOdd(EvenOddFlag: Boolean); overload;
    procedure SetBlendMode(Value: TAggBlendMode);
    procedure SetImageBlendMode(Value: TAggBlendMode);
    procedure SetImageBlendColor(R, G, B: Cardinal; A: Cardinal = 255); overload;
    procedure SetImageBlendColor(C: TAggRgba8); overload;
    function GetRow(Y: Cardinal): PInt8U;

    function CreateSaveState: TCanvasSaveState; override;

    {$IF CompilerVersion <= 24}
    procedure FreeBuffer; override;
    {$IFEND}
    procedure MapBuffer;
    procedure UnmapBuffer;

    procedure InternalRenderImage(Img: TCanvasAggPasImage;
      RendererBase: TAggRendererBase; Interpolator: TAggSpanInterpolatorLinear);

    procedure CopyPath(APath: TPathData);

    function PrepareColor(ARect: TRectF; const ABrush: TBrush; const AOpacity: Single): boolean;
    {$IF CompilerVersion <= 23}
    procedure PrepareStroke(const AStroke: TBrush; const AStrokeThickness: Single;
      const AStrokeCap: TStrokeCap; const ADashArray: TDashArray;
      const ADashOffset: single; const AStrokeJoin: TStrokeJoin; ARect: TRectF;
      const AOpacity: Single);
    {$ELSE}
    procedure PrepareStroke(const AStroke: TStrokeBrush; ARect: TRectF; const AOpacity: Single);
    {$IFEND}
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

    {$IF CompilerVersion <= 23}
    procedure RenderPathFill(ARect: TRectF; AOpacity: Single);
    procedure RenderPathStroke(ARect: TRectF; AOpacity: Single);
    {$ELSE}
    procedure RenderPathFill(ARect: TRectF; const ABrush: TBrush; AOpacity: Single);
    procedure RenderPathStroke(ARect: TRectF; const ABrush: TStrokeBrush; AOpacity: Single);
    {$IFEND}

    procedure RenderText(aFontCacheManager: TAggFontCacheManager;
      const aText: string; const aAscend: single; const aTextRect: TRectF);

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

    procedure FontChanged(Sender: TObject); override;

    { Bitmaps }
    {$IF CompilerVersion <= 23}
    procedure UpdateBitmapHandle(ABitmap: TBitmap); override;
    procedure DestroyBitmapHandle(ABitmap: TBitmap); override;

    class function GetBitmapScanline(ABitmap: TBitmap; Y: Integer): PAlphaColorArray; override;
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

    {$IF CompilerVersion > 24}
    { style }
    class function GetCanvasStyle: TCanvasStyles; override;
    {$IFEND}

    {$IF CompilerVersion <= 24}
    { buffer }
    procedure ResizeBuffer(const AWidth, AHeight: Integer); override;
    procedure FlushBufferRect(const X, Y: Integer; const Context; const ARect: TRectF); override;
    {$IF CompilerVersion <= 23}
    function DoBeginScene(const AClipRects: PClipRects = nil): Boolean; override;
    {$ELSE}
    function DoBeginScene(const AClipRects: PClipRects = nil; AContextHandle: THandle = 0): Boolean; override;
    {$IFEND}
    {$ELSE}

    function DoBeginScene(const AClipRects: PClipRects = nil; AContextHandle: THandle = 0): Boolean; override;
    procedure DoEndScene; override;

    procedure SetSize(const AWidth, AHeight: Integer); override;
    {$IFEND}

    {$IF CompilerVersion > 23}
    { Bitmaps }
    {$IF CompilerVersion < 28}
    class procedure DoInitializeBitmap(const ABitmap: TBitmap); override;
    class procedure DoFinalizeBitmap(const ABitmap: TBitmap); override;

    class function DoMapBitmap(const ABitmap: TBitmap; const Access: TMapAccess; var Data: TBitmapData): Boolean; override;
    class procedure DoUnmapBitmap(const ABitmap: TBitmap; var Data: TBitmapData); override;
    {$ELSE}
    class function DoInitializeBitmap(const Width, Height: Integer; const Scale: Single; var PixelFormat: TPixelFormat): THandle; override;
    class procedure DoFinalizeBitmap(var Bitmap: THandle); override;
    class function DoMapBitmap(const Bitmap: THandle; const Access: TMapAccess; var Data: TBitmapData): Boolean; override;
    class procedure DoUnmapBitmap(const Bitmap: THandle; var Data: TBitmapData); override;
    {$IFEND}
    {$IFEND}

    procedure Clear(const Color: TAlphaColor); override;
    procedure ClearRect(const ARect: TRectF; const AColor: TAlphaColor = 0); override;

    { matrix }
    {$IF CompilerVersion < 30}
    procedure SetMatrix(const M: TMatrix); override;
    {$ELSE}
    procedure DoSetMatrix(const M: TMatrix); override;
    {$IFEND}
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

  TFontNames = record
    Filename: string;
    FontFamily: string;
    FontSubFamily: string;
    UniqueFontID: string;
    FontFullName: string;
  end;

  TProcRenderText = reference to procedure(const aText: string; const aTextRect: TRectF);

  TTextLayoutAggPas = class(TTextLayout)
  private class var
    {$IFDEF AGG2D_USE_FREETYPE}
    FFontNamesList: array of TFontNames;
    {$ELSE}
    FFontDC: HDC;
    {$ENDIF}
    FFontEngine: TAggFontEngine;
    FFontCacheManager: TAggFontCacheManager;

    FFontFamily: string;
    FFontFileName: string;
    FFontSize: Single;
    FBold: boolean;
    FItalic: boolean;

    FTextHints: Boolean;
  private
    FLeft: Single;
    FTop: Single;
    FHeight: Single;
    FWidth: Single;

    procedure SetFont(FontFamily: string; FontSize: Double; Bold: Boolean = False;
      Italic: Boolean = False; Angle: Double = 0);
    class procedure SetTextHints(Value: Boolean); static;
    function MeasureRange(const APos, ALength: Integer): TRegion;
    procedure RenderText(const APos, ALength: Integer; aTextRenderProc: TProcRenderText);
  protected
    procedure DoRenderLayout; override;
    {$IF CompilerVersion = 24}
    procedure DoDrawLayout(ACanvas: TCanvas); override;
    {$ELSE}
    procedure DoDrawLayout(const ACanvas: TCanvas); override;
    {$IFEND}
    function GetTextHeight: Single; override;
    function GetTextWidth: Single; override;
    function GetTextRect: TRectF; override;
    {$IF CompilerVersion = 24}
    function PositionAtPoint(const APoint: TPointF): Integer; override;
    function RegionForRange(const ARange: TTextRange): TRegion; override;
    {$ELSE}
    function DoPositionAtPoint(const APoint: TPointF): Integer; override;
    function DoRegionForRange(const ARange: TTextRange): TRegion; override;
    {$IFEND}

    class constructor Create;
    class destructor Destroy;

    {$IFDEF AGG2D_USE_FREETYPE}
    class function GetFontDir: string;
    class procedure ParseFonts(const aDir: string);
    {$ENDIF}
  public
    {$IF CompilerVersion = 24}
    constructor Create(ACanvas: TCanvas = nil); override;
    {$ELSE}
    constructor Create(const ACanvas: TCanvas = nil); override;
    {$IFEND}
    destructor Destroy; override;

    {$IFDEF AGG2D_USE_FREETYPE}
    class procedure GetFontNames(aStrings: TStrings);
    {$ENDIF}

    {$IF CompilerVersion = 24}
    procedure ConvertToPath(APath: TPathData); override;
    {$ELSE}
    procedure ConvertToPath(const APath: TPathData); override;
    {$IFEND}

    class property TextHints: Boolean read FTextHints write SetTextHints;
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
  {$IF CompilerVersion > 24}
  inherited;

  InitializeAggPas;

  MapBuffer;
  {$ELSE}
  FBuffered := True;

  {$IF CompilerVersion <= 23}
  FTextLayout := TTextLayoutAggPas.Create;
  {$IFEND}

  InitializeAggPas;

  inherited;
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
  FBitmap := ABItmap;

  {$IF CompilerVersion > 24}
  inherited;

  InitializeAggPas;

  MapBuffer;
  {$ELSE}

  {$IF CompilerVersion <= 23}
  FTextLayout := TTextLayoutAggPas.Create;
  {$IFEND}

  InitializeAggPas;

  MapBuffer;

  inherited;
  {$IFEND}

  ResetClipRect;
end;

constructor TCanvasAggPas.CreateFromPrinter(const APrinter: TAbstractPrinter);
begin
  {$IF CompilerVersion > 24}
  inherited;

  InitializeAggPas;

  MapBuffer;
  {$ELSE}
  FBuffered := True;

  {$IF CompilerVersion <= 23}
  FTextLayout := TTextLayoutAggPas.Create;
  {$IFEND}

  InitializeAggPas;

  inherited;
  {$IFEND}

  ResetClipRect;
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

  FPatternWrapX.Free;
  FPatternWrapY.Free;

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

  UnmapBuffer;

  {$IFNDEF AGG2D_USE_FREETYPE}
  DeleteObject(FFontHandle);
  {$ENDIF}

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

  FImageFilter := ifBilinear;
  FImageResample := irNever;

  FEvenOddFlag := False;
end;

procedure TCanvasAggPas.MapBuffer;
begin
  {$IF CompilerVersion = 23}
  Attach(pointer(FBitmap.StartLine), FBitmap.Width, FBitmap.Height, FBitmap.Width * 4);
  {$IFEND}

  {$IF CompilerVersion = 24}
  FBitmap.Map(TMapAccess.maReadWrite, FBitmapData);
  Attach(FBitmapData.Data, FBitmap.Width, FBitmap.Height, FBitmapData.Pitch);
  {$IFEND}

  {$IF CompilerVersion > 24}
  if assigned(FBitmap) then
  begin
    FBitmap.Map(TMapAccess.maReadWrite, FBitmapData);
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
  {$IFEND}
end;

procedure TCanvasAggPas.UnmapBuffer;
begin
  {$IF CompilerVersion = 24}
  if assigned(FBitmap) then
    FBitmap.Unmap(FBitmapData);
  {$IFEND}

  {$IF CompilerVersion > 24}
  if assigned(FBitmap) then
  begin
    FBitmap.Unmap(FBitmapData);
  end else begin
    {$IFDEF MSWINDOWS}
    if assigned(Parent) then
    begin
      WindowHandleToPlatform(Parent).FreeBuffer;
    end;
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
  {$IFEND}
end;

{$IF CompilerVersion <= 24}

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

    // attach AGG2D canvas
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

{$IF CompilerVersion <= 23}
function TCanvasAggPas.DoBeginScene(const AClipRects: PClipRects): Boolean;
{$ELSE}
 function TCanvasAggPas.DoBeginScene(const AClipRects: PClipRects = nil; AContextHandle: THandle = 0): Boolean;
{$IFEND}
begin
  Result := inherited DoBeginScene(AClipRects);
  if Result and (AClipRects <> nil) then
    SetClipRects(AClipRects^);
end;

{$ELSE}

procedure TCanvasAggPas.SetSize(const AWidth, AHeight: Integer);
begin
  UnmapBuffer;
  inherited;
  MapBuffer;
end;

function TCanvasAggPas.DoBeginScene(const AClipRects: PClipRects = nil; AContextHandle: THandle = 0): Boolean;
begin
  Result := inherited DoBeginScene(AClipRects);

  if Result then
  begin

    FContextHandle := AContextHandle;
    if AClipRects <> nil then
      SetClipRects(AClipRects^);

    Inc(FSceneCount);
  end;
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
  Dec(FSceneCount);
  if FSceneCount <= 0 then
  begin
    if Assigned(Parent) then
    begin
      {$IFDEF MSWINDOWS}
      if Assigned(FClipRects) then
      begin
        for I := 0 to High(FClipRects^) do
        begin
          R := FClipRects^[I].Round;
          Winapi.Windows.BitBlt(FContextHandle, R.Left, R.Top, R.Width, R.Height,
            WindowHandleToPlatform(Parent).BufferHandle, R.Left, R.Top, SRCCOPY);
        end;
      end else
        Winapi.Windows.BitBlt(FContextHandle, 0, 0, Width, Height,
          WindowHandleToPlatform(Parent).BufferHandle, 0, 0, SRCCOPY);
      {$ENDIF}
      {$IFDEF MACOS}
      R := CGRectFromRect(RectF(0, 0, Width, Height));
      FImage := CGBitmapContextCreateImage(FBitmapContext);
      CGContextDrawImage(CGContextRef(FContextHandle), R, FImage);
      {$ENDIF}
    end;
    FSceneCount := 0;
  end;

  inherited;
end;
{$IFEND}

{$IF CompilerVersion > 23}

{$IF CompilerVersion < 28}

class procedure TCanvasAggPas.DoFinalizeBitmap(const ABitmap: TBitmap);
begin
  FreeMem(pointer(ABitmap.Handle));
end;

class procedure TCanvasAggPas.DoInitializeBitmap(const ABitmap: TBitmap);
var
  Ptr: pointer;
begin
  GetMem(Ptr, ABitmap.Width * ABitmap.Height * 4);

  {$IF CompilerVersion < 27}
  (ABitmap as IBitmapAccess).Handle := THandle(Ptr);
  (ABitmap as IBitmapAccess).PixelFormat := TPixelFormat.pfA8R8G8B8;
  {$ELSE}
  ABitmap.Handle := THandle(Ptr);
  ABitmap.PixelFormat := TPixelFormat.RGBA;
  {$IFEND}
end;

class function TCanvasAggPas.DoMapBitmap(const ABitmap: TBitmap;
  const Access: TMapAccess; var Data: TBitmapData): Boolean;
begin
  {$IF CompilerVersion > 24}
  Data.Create(ABitmap.Width, ABitmap.Height, ABitmap.PixelFormat);
  {$IFEND}
  Data.Data := pointer(ABitmap.Handle);
  Data.Pitch := ABitmap.Width * 4;
  Result := True;
end;

class procedure TCanvasAggPas.DoUnmapBitmap(const ABitmap: TBitmap;
  var Data: TBitmapData);
begin
  inherited;
end;

{$ELSE}

class function TCanvasAggPas.DoInitializeBitmap(const Width, Height: Integer;
  const Scale: Single; var PixelFormat: TPixelFormat): THandle;
var
  CanvasAggPasBitmap: TCanvasAggPasBitmap;
begin
  CanvasAggPasBitmap := TCanvasAggPasBitmap.Create(Width, Height);

  Result := THandle(CanvasAggPasBitmap);

  PixelFormat := CanvasAggPasBitmap.Pixelformat;
end;

class procedure TCanvasAggPas.DoFinalizeBitmap(var Bitmap: THandle);
begin
  TCanvasAggPasBitmap(Bitmap).Free;
end;

class function TCanvasAggPas.DoMapBitmap(const Bitmap: THandle;
  const Access: TMapAccess; var Data: TBitmapData): Boolean;
var
  CanvasAggPasBitmap: TCanvasAggPasBitmap;
begin
  CanvasAggPasBitmap := TCanvasAggPasBitmap(Bitmap);

  Data.Create(
    CanvasAggPasBitmap.Width,
    CanvasAggPasBitmap.Height,
    CanvasAggPasBitmap.PixelFormat);
  Data.Data := CanvasAggPasBitmap.Data;
  Data.Pitch := CanvasAggPasBitmap.Width * 4;

  Result := True;
end;

class procedure TCanvasAggPas.DoUnmapBitmap(const Bitmap: THandle;
  var Data: TBitmapData);
begin
  inherited;
end;

{$IFEND}

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

  M[0] := Matrix.m11;
  M[1] := Matrix.m12;
  M[2] := Matrix.m21;
  M[3] := Matrix.m22;
  M[4] := Matrix.m31;
  M[5] := Matrix.m32;

  FTransform.LoadFrom(@M);
  UpdateApproximationScale;
end;

{$IF CompilerVersion < 30}
procedure TCanvasAggPas.SetMatrix(const M: TMatrix);
{$ELSE}
procedure TCanvasAggPas.DoSetMatrix(const M: TMatrix);
{$IFEND}
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
  FClipRect := TransformClipRect(ARects[0], Matrix);
  for I := 1 to High(ARects) do
    FClipRect := UnionRect(FClipRect, TransformClipRect(ARects[I], Matrix));
  IntersectRect(FClipRect, FClipRect, RectF(0, 0, Width, Height));

  SetClipBox(FClipRect.Left, FClipRect.Top, FClipRect.Right, FClipRect.Bottom);
end;

procedure TCanvasAggPas.IntersectClipRect(const ARect: TRectF);
begin
  IntersectRect(FClipRect, FClipRect, TransformClipRect(ARect, Matrix));

  SetClipBox(FClipRect.Left, FClipRect.Top, FClipRect.Right, FClipRect.Bottom);
end;

procedure TCanvasAggPas.ExcludeClipRect(const ARect: TRectF);
begin
  // unsupported
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

{$IF CompilerVersion > 24}
class function TCanvasAggPas.GetCanvasStyle: TCanvasStyles;
begin
  Result := [TCanvasStyle.SupportClipRects];
end;
{$IFEND}

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

function TCanvasAggPas.PrepareColor(ARect: TRectF; const ABrush: TBrush;
  const AOpacity: Single): boolean;
begin
  Result := False;

  with ABrush do
  begin
    case Kind of
      TBrushKind.bkSolid:
        begin
          FAggColor := AlphaColorToAggColor(Color, AOpacity);
          Result := FAggColor.A <> 0;
        end;
      TBrushKind.bkGradient:
        begin
          PrepareGradient(ABrush.Gradient, ARect);
          Result := True;
        end;
    end;
  end;
end;

{$IF CompilerVersion <= 23}

procedure TCanvasAggPas.PrepareStroke(const AStroke: TBrush;
  const AStrokeThickness: Single; const AStrokeCap: TStrokeCap;
  const ADashArray: TDashArray; const ADashOffset: single;
  const AStrokeJoin: TStrokeJoin; ARect: TRectF; const AOpacity: Single);
var
  i, l, k: integer;
  GapLength, DashLength: Double;
begin
  FConvStroke.Width := aStrokeThickness;

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

procedure TCanvasAggPas.PrepareStroke(const AStroke: TStrokeBrush; ARect: TRectF;
  const AOpacity: Single);
var
  i, l, k: integer;
  GapLength, DashLength: Double;
begin
  FConvStroke.Width := aStroke.Thickness;

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
            ARect.Left + RotationCenter.X * RectWidth(ARect),
            ARect.Top + RotationCenter.Y * RectHeight(ARect));
        end;
        FGradientMatrix.Multiply(FTransform);
        FGradientMatrix.Invert;

        FBrushType := btGradientRadial;
      end;
  end;
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

{$IF CompilerVersion <= 23}

procedure TCanvasAggPas.RenderPathFill(ARect: TRectF; AOpacity: Single);
begin
  FRasterizer.Reset;

  if AOpacity = 0 then
    Exit;
  UpdateRasterizerGamma(AOpacity);

  if PrepareColor(ARect, Fill, AOpacity) then
  begin
    FRasterizer.AddPath(FPathTransform);
    Render(Fill);
  end;
end;

procedure TCanvasAggPas.RenderPathStroke(ARect: TRectF; AOpacity: Single);
begin
  FRasterizer.Reset;

  if AOpacity = 0 then
    Exit;
  UpdateRasterizerGamma(AOpacity);

  PrepareStroke(Stroke, StrokeThickness, StrokeCap, FDash, FDashOffset,
    StrokeJoin, ARect, AOpacity);

  if PrepareColor(ARect, Stroke, AOpacity) and (StrokeThickness > 0) then
  begin
    FRasterizer.AddPath(FStrokeTransform);
    Render(Stroke);
  end;
end;

{$ELSE}

procedure TCanvasAggPas.RenderPathFill(ARect: TRectF; const ABrush: TBrush;
  AOpacity: Single);
begin
  FRasterizer.Reset;

  if AOpacity = 0 then
    Exit;
  UpdateRasterizerGamma(AOpacity);

  if PrepareColor(ARect, ABrush, AOpacity) then
  begin
    FRasterizer.AddPath(FPathTransform);
    Render(ABrush);
  end;
end;

procedure TCanvasAggPas.RenderPathStroke(ARect: TRectF;
  const ABrush: TStrokeBrush; AOpacity: Single);
begin
  FRasterizer.Reset;

  if AOpacity = 0 then
    Exit;
  UpdateRasterizerGamma(AOpacity);

  PrepareStroke(ABrush, ARect, AOpacity);
  if PrepareColor(ARect, ABrush, AOpacity) and (StrokeThickness > 0) then
  begin
    FRasterizer.AddPath(FStrokeTransform);
    Render(ABrush);
  end;
end;

{$IFEND}

procedure TCanvasAggPas.RenderText(aFontCacheManager: TAggFontCacheManager;
  const aText: string; const aAscend: single; const aTextRect: TRectF);
var
  i: integer;
  X, Y: Double;
  Glyph: PAggGlyphCache;
  Curves: TAggConvCurve;
  Contour: TAggConvContour;
  ContourTransform: TAggConvTransform;
  RenBin: TAggRendererScanLineBinSolid;
begin
  X := aTextRect.Left;
  Y := aTextRect.Top - aAscend;

  Assert(Assigned(aFontCacheManager));

  Curves := TAggConvCurve.Create(aFontCacheManager.PathAdaptor);
  ContourTransform := TAggConvTransform.Create(Curves, FTransform);
  Contour := TAggConvContour.Create(ContourTransform);

  Contour.Width := 0.1;

  UpdateRasterizerGamma(1.0);

  Curves.ApproximationScale := 2;
  Contour.AutoDetectOrientation := False;
  RenBin := TAggRendererScanLineBinSolid.Create(FRendererBase);
  try
    i := 0;
    while i < Length(aText) do
    begin
      Glyph := aFontCacheManager.Glyph(Ord(aText[i + 1]));

      if Glyph <> nil then
      begin
        {$IFDEF AGG2D_USE_FREETYPE}
        // TODO: Gives wrong results for some fonts on Win32TrueType
        aFontCacheManager.AddKerning(@X, @Y);
       {$ENDIF}

        case Glyph.DataType of
          gdMono:
            begin
              aFontCacheManager.InitEmbeddedAdaptors(Glyph,
                FTransform.M4 + X, FTransform.M5 + Y);

              RenBin.SetColor(CRgba8Black);

              RenderScanLines(aFontCacheManager.MonoAdaptor,
                aFontCacheManager.MonoScanLine, RenBin);
            end;

          gdGray8:
            begin
              aFontCacheManager.InitEmbeddedAdaptors(Glyph,
                FTransform.M4 + X, FTransform.M5 + Y);

              FRendererSolid.SetColor(CRgba8Black);

              RenderScanLines(aFontCacheManager.Gray8Adaptor,
                aFontCacheManager.Gray8ScanLine, FRendererSolid);
            end;

          gdOutline:
            begin
              aFontCacheManager.InitEmbeddedAdaptors(Glyph, X, Y);

              FRasterizer.Reset;

              {if Abs(FSliderWeight.Value) <= 0.01 then
                // For the sake of efficiency skip the
                // contour converter if the weight is about zero.
                FRasterizer.AddPath(FCurves)
              else}
                FRasterizer.AddPath(Contour);

              FRendererSolid.SetColor(CRgba8Black);

              RenderScanLines(FRasterizer, FScanLine, FRendererSolid);
            end;
        end;

        // increment pen position
        X := X + Glyph.AdvanceX;
        Y := Y + Glyph.AdvanceY;

      end;
      Inc(i);
    end;
  finally
    RenBin.Free;
    ContourTransform.Free;
    Curves.Free;
    Contour.Free;
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

{$IF CompilerVersion <= 23}

procedure TCanvasAggPas.DrawLine(const APt1, APt2: TPointF;
  const AOpacity: Single);
begin
  FPath.RemoveAll;

  FPath.MoveTo(APt1.X, APt1.Y);
  FPath.LineTo(APt2.X, APt2.Y);

  RenderPathStroke(RectF(APt1.X, APt1.Y, APt2.X, APt2.Y), AOpacity);
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

  RenderPathFill(ARect, AOpacity);
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

  RenderPathStroke(ARect, AOpacity);
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

procedure TCanvasAggPas.MeasureText(var ARect: TRectF; const AText: string;
  const WordWrap: Boolean; const Flags: TFillTextFlags; const ATextAlign,
  AVTextAlign: TTextAlign);
var
  TextRange: TTextRange;
  Region: TRegion;
  i: integer;
begin
  FTextLayout.BeginUpdate;
  FTextLayout.MaxSize := PointF(ARect.Width, ARect.Height);
  FTextLayout.TopLeft := PointF(ARect.Left, ARect.Top);
  FTextLayout.Text := AText;
  FTextLayout.WordWrap := WordWrap;
  FTextLayout.HorizontalAlign := ATextAlign;
  FTextLayout.VerticalAlign := AVTextAlign;
  FTextLayout.Font := Font;
  FTextLayout.EndUpdate;

  ARect.Right := ARect.Left;

  if AText = '' then
    exit;

  TextRange.Pos := 0;
  TextRange.Length := Length(AText);

  Region := FTextLayout.DoRegionForRange(TextRange);
  if Length(Region) > 0 then
  begin
    for i := 0 to Length(Region) - 1 do
      ARect := TRectF.Union(ARect, Region[i]);
  end;
end;

function TCanvasAggPas.TextToPath(Path: TPathData; const ARect: TRectF;
  const AText: string; const WordWrap: Boolean; const ATextAlign,
  AVTextAlign: TTextAlign): Boolean;
begin
  Result := False;
  if AText = '' then
    exit;

  FTextLayout.BeginUpdate;
  FTextLayout.MaxSize := PointF(ARect.Width, ARect.Height);
  FTextLayout.TopLeft := PointF(ARect.Left, ARect.Top);
  FTextLayout.Text := AText;
  FTextLayout.WordWrap := WordWrap;
  FTextLayout.HorizontalAlign := ATextAlign;
  FTextLayout.VerticalAlign := AVTextAlign;
  FTextLayout.Font := Font;
  FTextLayout.EndUpdate;

  FTextLayout.ConvertToPath(Path);
  Result := True;
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
  RenderPathFill(APath.GetBounds, AOpacity);
end;

procedure TCanvasAggPas.DrawPath(const APath: TPathData; const AOpacity: Single);
begin
  CopyPath(APath);
  RenderPathStroke(APath.GetBounds, AOpacity);
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

  RenderPathFill(Rect, AOpacity);
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

  RenderPathStroke(Rect, AOpacity);
end;

class function TCanvasAggPas.GetBitmapScanline(ABitmap: TBitmap;
  y: Integer): PAlphaColorArray;
begin
  if (y >= 0) and (y < ABitmap.Height) and (ABitmap.StartLine <> nil) then
    Result := @PAlphaColorArray(ABitmap.StartLine)[(y) * ABitmap.Width]
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
    CopyPath(Path);
    RenderPathFill(ARect, ABrush, AOpacity);
  finally
    Path.Free;
  end;
end;

procedure TCanvasAggPas.DoFillPath(const APath: TPathData;
  const AOpacity: Single; const ABrush: TBrush);
var
  Rect: TRectF;
begin
  Rect := APath.GetBounds;
  CopyPath(APath);
  RenderPathFill(Rect, ABrush, AOpacity);
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

  RenderPathFill(ARect, ABrush, AOpacity);
end;

procedure TCanvasAggPas.DoDrawBitmap(const ABitmap: TBitmap; const SrcRect,
  DstRect: TRectF; const AOpacity: Single; const HighSpeed: Boolean = False);
var
  Clr: TAggColor;
  Mtx: TAggTransAffine;
  Parl: TAggParallelogram;
  Interpolator: TAggSpanInterpolatorLinear;
  SpanConverter: TAggSpanConverter;
  SpanImageResample: TAggSpanImageResampleRgbaAffine;
  Blend: TAggSpanConvImageBlend;
  RendererScanLineAA: TAggRendererScanLineAA;
  BitmapBuffer: TAggRenderingBuffer;
begin

  if (SrcRect.Width <= 0) or (SrcRect.Height <= 0)
  or (DstRect.Width <= 0) or (DstRect.Height <= 0)
  then
    exit;

  BitmapBuffer := TCanvasAggPas(aBitmap.Canvas).FRenderingBuffer;

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
          FAllocator, BitmapBuffer, @Clr, Interpolator,
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
end;

procedure TCanvasAggPas.DoDrawLine(const APt1, APt2: TPointF; const AOpacity: Single; const ABrush: TStrokeBrush);
var
  Rect: TRectF;
begin
  FPath.RemoveAll;
  FPath.MoveTo(APt1.X, APt1.Y);
  FPath.LineTo(APt2.X, APt2.Y);

  Rect := RectF(APt1.X, APt1.Y, APt2.X, APt2.Y);

  RenderPathStroke(Rect, ABrush, AOpacity);
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

    CopyPath(Path);
    RenderPathStroke(ARect, ABrush, AOpacity);
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

  RenderPathStroke(Rect, ABrush, AOpacity);
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

  RenderPathStroke(ARect, ABrush, AOpacity);
end;
{$IFEND}

{$IFNDEF AGG2D_USE_FREETYPE}
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
{$ELSE}
procedure TCanvasAggPas.FontChanged(Sender: TObject);
begin
  //
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


{$IF CompilerVersion >= 28}

{ TCanvasAggPasBitmap }

constructor TCanvasAggPasBitmap.Create(const aWidth, aHeight: integer);
begin
  FWidth := aWidth;
  FHeight := aHeight;
  // Only BGRA supported!
  FPixelFormat := TPixelFormat.RGBA;

  GetMem(FData, FWidth * FHeight * 4);
end;

destructor TCanvasAggPasBitmap.Destroy;
begin
  FreeMem(FData);

  inherited;
end;

{$IFEND}

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
  begin
    TCanvasAggPas(Dest).FClipRect := FClipRect;
    TCanvasAggPas(Dest).SetClipBox(
      FClipRect.Left,
      FClipRect.Top,
      FClipRect.Right,
      FClipRect.Bottom);
  end;
end;

procedure SetAggPasDefault;
begin
  GlobalUseDirect2D := False;
  {$IF CompilerVersion <= 23}
  DefaultCanvasClass := TCanvasAggPas;
  {$ELSE}
  TCanvasManager.RegisterCanvas(TCanvasAggPas, True, True);
  TTextLayoutManager.RegisterTextLayout(TTextLayoutAggPas, TCanvasAggPas);
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
  FMaxSize := ClosePolygon;
  FTopLeft := PointF(0, 0);
  FFont := TFont.Create;
  FPadding := TBounds.Create(RectF(0, 0, 0, 0));
  FWordWrap := False;
  FHorizontalAlign := TTextAlign.taLeading;
  FVerticalAlign := TTextAlign.taLeading;
  FOpacity := 1;
  FUpdating := 0;
end;

destructor TTextLayout.Destroy;
begin
  FreeAndNil(FFont);
  FreeAndNil(FPadding);
end;

procedure TTextLayout.NeedUpdate;
begin
  FNeedUpdate := True;
  if FUpdating = 0 then
  begin
    DoRenderLayout;
    FNeedUpdate := False;
  end;
end;

procedure TTextLayout.BeginUpdate;
begin
  FUpdating := FUpdating + 1;
end;

procedure TTextLayout.EndUpdate;
begin
  if FUpdating > 0 then
  begin
    Dec(FUpdating);
    if (FUpdating = 0) and FNeedUpdate then
    begin
      DoRenderLayout;
      FNeedUpdate := False;
    end;
  end;
end;

procedure TTextLayout.SetFont(const aValue: TFont);
begin
  FFont.Assign(aValue);
end;

procedure TTextLayout.SetPadding(const Value: TBounds);
begin
  if FPadding.Equals(Value) then
    Exit;
  FPadding.Assign(Value);
  NeedUpdate;
end;

procedure TTextLayout.SetMaxSize(const Value: TPointF);
begin
  if FMaxSize = Value then
    Exit;
  FMaxSize := Value;
  NeedUpdate;
end;

procedure TTextLayout.SetHorizontalAlign(const Value: TTextAlign);
begin
  if FHorizontalAlign = Value then
    Exit;
  FHorizontalAlign := Value;
  NeedUpdate;
end;

procedure TTextLayout.SetVerticalAlign(const Value: TTextAlign);
begin
  if FVerticalAlign = Value then
    Exit;
  FVerticalAlign := Value;
  NeedUpdate;
end;
{$IFEND}

{ TTextLayoutAggPas }

class constructor TTextLayoutAggPas.Create;
begin
  inherited;

  {$IFDEF AGG2D_USE_FREETYPE}
  FFontEngine := TAggFontEngineFreetypeInt32.Create;
  SetLength(FFontNamesList, 0);
  ParseFonts(GetFontDir);
  {$ELSE}
  FFontDC := GetDC(0);
  FFontEngine := TAggFontEngineWin32TrueTypeInt32.Create(FFontDC);
  {$ENDIF}
  FFontCacheManager := TAggFontCacheManager.Create(FFontEngine);

  FFontFamily := '';
  FFontFileName := '';
  FFontSize := 12;
  FBold := False;
  FItalic := False;

  FFontEngine.FlipY := True;
end;

class destructor TTextLayoutAggPas.Destroy;
begin
  {$IFDEF AGG2D_USE_FREETYPE}
  Finalize(FFontNamesList);
  {$ELSE}
  ReleaseDC(0, FFontDC);
  {$ENDIF}
  FFontEngine.Free;
  FFontCacheManager.Free;

  inherited;
end;

{$IFDEF AGG2D_USE_FREETYPE}
class function TTextLayoutAggPas.GetFontDir: string;
{$IFDEF MSWINDOWS}
var
  P: PChar;
  PIDL: PItemIDList;
  A : array [0..max_path] of Char;
{$ENDIF}
begin
  // Get Fonts folder

  {$IFDEF MSWINDOWS}
  Result := '';

  SHGetSpecialFolderLocation(0, CSIDL_FONTS, PIDL);
  P := @A;
  if SHGetPathFromIDList(PIDL, P) then
    Result := String(P)
  {$ENDIF}
  {$IFDEF MACOS}
  Result := '/Library/Fonts';
  {$ENDIF}
end;

class procedure TTextLayoutAggPas.GetFontNames(aStrings: TStrings);
var
  i: integer;
begin
  for i := 0 to Length(FFontNamesList) - 1 do
    aStrings.Add(FFontNamesList[i].FontFamily);
end;

class procedure TTextLayoutAggPas.ParseFonts(const aDir: string);
var
  sr: TSearchRec;
  FontFamily, FontSubFamily, UniqueFontID, FontFullName: string;
  Index: integer;
begin
  SetLength(FFontNamesList, 0);
  if FindFirst(aDir + PathDelim + '*.ttf', faAnyFile, sr) = 0 then
  try
    repeat
      if not (sr.Attr and faDirectory = faDirectory) then
      begin
        if FFontEngine.GetNameInfo(aDir + PathDelim + sr.Name,
          FontFamily, FontSubFamily, UniqueFontID, FontFullName) then
        begin
          Index := Length(FFontNamesList);
          SetLength(FFontNamesList, Index + 1);
          FFontNamesList[Index].Filename := aDir + PathDelim + sr.Name;
          FFontNamesList[Index].FontFamily := FontFamily;
          FFontNamesList[Index].FontSubFamily := FontSubFamily;
          FFontNamesList[Index].UniqueFontID := UniqueFontID;
          FFontNamesList[Index].FontFullName := FontFullName;
        end;
      end;
    until FindNext(sr) <> 0;
  finally
    FindClose(sr);
  end;
end;
{$ENDIF}

{$IF CompilerVersion = 24}
constructor TTextLayoutAggPas.Create(ACanvas: TCanvas);
{$ELSE}
constructor TTextLayoutAggPas.Create(const ACanvas: TCanvas);
{$IFEND}
begin
  inherited;

  FLeft := 0;
  FTop := 0;
  FHeight := 0;
  FWidth := 0;
end;

destructor TTextLayoutAggPas.Destroy;
begin
  inherited;
end;

{$IF CompilerVersion = 24}
procedure TTextLayoutAggPas.ConvertToPath(APath: TPathData);
{$ELSE}
procedure TTextLayoutAggPas.ConvertToPath(const APath: TPathData);
{$IFEND}
var
  Glyph: PAggGlyphCache;
begin
  if Text = '' then
    exit;

  RenderText(0, Length(Text),
    procedure(const aText: string; const aTextRect: TRectF)
    const
      OneThird = 1 / 3;
      TwoThirds = 2 / 3;
    var
      i: integer;
      CurPos, Last, CP, CP1, CP2: TPointDouble;
      GlyphValue: Cardinal;
      PX, PY: Double;
      Cmd: Cardinal;
      VertexSource: TAggVertexSource;
      Asc: Double;
    begin
      VertexSource := FFontCacheManager.PathAdaptor;
      i := 0;

      Asc := FFontEngine.Ascender;

      if FFontEngine.FlipY then
        Asc := -Asc;

      {$IF CompilerVersion = 24}
      CurPos.X := TopLeft.X + aTextRect.Left;
      CurPos.Y := TopLeft.Y + aTextRect.Top - Asc;
      {$ELSE}
      CurPos.X := TopLeft.X + Padding.Left + aTextRect.Left;
      CurPos.Y := TopLeft.Y + Padding.Top + aTextRect.Top - Asc;
      {$IFEND}

      while (i < Length(aText)) do
      begin
        GlyphValue := Ord(aText[i + 1]);

        Glyph := FFontCacheManager.Glyph(GlyphValue);

        if Glyph <> nil then
        begin
          {$IFDEF AGG2D_USE_FREETYPE}
          // TODO: Gives wrong results for some fonts on Win32TrueType
          if i <> 0 then
            FFontCacheManager.AddKerning(@CurPos.X, @CurPos.Y);
          {$ENDIF}

          FFontCacheManager.InitEmbeddedAdaptors(Glyph, CurPos.X, CurPos.Y);

          if Glyph.DataType = gdOutline then
          begin
            VertexSource.Rewind(0);
            repeat
              Cmd := VertexSource.Vertex(@PX, @PY);
              case Cmd and CAggPathCmdMask of
                CAggPathCmdStop:
                  begin
                    if APath.Count > 0 then
                      APath.ClosePath;
                  end;
                CAggPathCmdMoveTo:
                  APath.MoveTo(PointF(PX, PY));
                CAggPathCmdLineTo:
                  APath.LineTo(PointF(PX, PY));
                CAggPathCmdCurve3:
                  begin
                    // Build a cubic bezier from a quadratic

                    CP.X := PX;
                    CP.Y := PY;

                    Cmd := VertexSource.Vertex(@PX, @PY);

                    CP1.X := OneThird * Last.X + TwoThirds * CP.X;
                    CP1.Y := OneThird * Last.Y + TwoThirds * CP.Y;
                    CP2.X := TwoThirds * CP.X + OneThird * PX;
                    CP2.Y := TwoThirds * CP.Y + OneThird * PY;

                    APath.CurveTo(
                      PointF(CP1.X, CP1.Y),
                      PointF(CP2.X, CP2.Y),
                      PointF(PX, PY));
                  end;
                CAggPathCmdCurve4:
                  begin
                    CP1.X := PX;
                    CP1.Y := PY;

                    VertexSource.Vertex(@PX, @PY);

                    CP2.X := PX;
                    CP2.Y := PY;

                    Cmd := VertexSource.Vertex(@PX, @PY);

                    APath.CurveTo(
                      PointF(CP1.X, CP1.Y),
                      PointF(CP2.X, CP2.Y),
                      PointF(PX, PY));
                    end;
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
        end;
        Inc(i);
      end;
    end);
end;

{$IF CompilerVersion = 24}
procedure TTextLayoutAggPas.DoDrawLayout(ACanvas: TCanvas);
{$ELSE}
procedure TTextLayoutAggPas.DoDrawLayout(const ACanvas: TCanvas);
{$IFEND}
begin
  if Text = '' then
    exit;

  if aCanvas is TCanvasAggPas then
  begin

    RenderText(0, Length(Text),
      procedure(const aText: string; const aTextRect: TRectF)
      var
        R: TRectF;
        Asc: Double;
      begin
        R := aTextRect;
        R.Offset(TopLeft);
        {$IF CompilerVersion <> 24}
        R.Offset(Padding.Left, Padding.Top);
        {$IFEND}

        Asc := FFontEngine.Ascender;

        if FFontEngine.FlipY then
          Asc := -Asc;

        (aCanvas as TCanvasAggPas).RenderText(FFontCacheManager, aText, Asc, R);
      end);

  end;
end;

{$IF CompilerVersion = 24}
function TTextLayoutAggPas.PositionAtPoint(const APoint: TPointF): Integer;
{$ELSE}
function TTextLayoutAggPas.DoPositionAtPoint(const APoint: TPointF): Integer;
{$IFEND}

  function RegionContains(const ARegion: TRegion; const APOint: TPointF): Boolean;
  var
    i: Integer;
  begin
    Result := False;
    for i := 0 to High(ARegion) do
      Result := Result or ((APoint.X >= ARegion[i].Left) and
        (APoint.X <= (ARegion[i].Left + MaxSize.X)) and
        (APoint.Y >= ARegion[i].Top) and (APoint.Y <= ARegion[i].Bottom));
  end;

var
  RegionL, RegionR: TRegion;
  LPoint: TPointF;
  L, M, R: Integer;
  LRect: TRectF;
begin
  // From FMX.Canvas.GDIP

  Result := -1;
  LRect := Self.TextRect;
  if not ((APoint.X >= LRect.Left) and (APoint.X <= LRect.Right) and
     (APoint.Y >= LRect.Top) and (APoint.Y <= LRect.Bottom)) then
    begin
      if ((APoint.X >= LRect.Left) and (APoint.X <= (LRect.Left + MaxSize.X)) and
         (APoint.Y >= LRect.Top) and (APoint.Y <= LRect.Bottom)) then
        Result := Length(Text);
      Exit;
    end;
  if Text = '' then
    Exit(0);
  LPoint := PointF(APoint.X - TopLeft.X, APoint.Y - TopLeft.Y);

  // Using binary search to find point position

  L := 0;
  R := Length(Text) - 1;
  while L <= R do
  begin
    M := (L + R) shr 1;
    RegionL := MeasureRange(L, M - L + 1);
    RegionR := MeasureRange(M + 1, R - M);
    if RegionContains(RegionR, LPoint) then
      L := M + 1
    else
    begin
      if (M - L) = 0 then
      begin
        Result := M;
        if APoint.X > (RegionL[0].Left + RegionL[0].Width * 3 / 5) then
          Inc(Result);
        Exit;
      end;
      R := M;
    end;
  end;
end;

{$IF CompilerVersion = 24}
function TTextLayoutAggPas.RegionForRange(const ARange: TTextRange): TRegion;
{$ELSE}
function TTextLayoutAggPas.DoRegionForRange(const ARange: TTextRange): TRegion;
{$IFEND}
var
  Region: TRegion;
  I, RemainsLength, RangeLength, LPos: Integer;
begin
  // Some parts from FMX.Canvas.GDIP

  if ARange.Pos < 0 then
    Exit;

  if Text = '' then
  begin
    SetLength(Result, 1);
    Result[0] := Self.TextRect;
    Exit;
  end;

  RangeLength := Length(Text);
  if ARange.Pos > RangeLength then
    Exit;

  SetLength(Result, 0);

  RemainsLength := Min(ARange.Length, RangeLength - ARange.Pos);

  if (ARange.Pos < Length(Text)) and IsLowSurrogate(Text[ARange.Pos + 1]) then
  begin
    LPos := ARange.Pos - 1;
    Inc(RemainsLength);
  end
  else
    LPos := ARange.Pos;

  Region := MeasureRange(LPos, RemainsLength);

  if Length(Region) > 0 then
    for I := 0 to Length(Region) - 1 do
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Region[I];
      Result[High(Result)].Offset(TopLeft);
      {$IF CompilerVersion <> 24}
      Result[High(Result)].Offset(Padding.Left, Padding.Top);
      {$IFEND}
  end;
end;

procedure TTextLayoutAggPas.DoRenderLayout;
var
  i: integer;
  LRegion: TRegion;
begin
  //Measuring text size

  LRegion := MeasureRange(0, Max(Length(Text), 1));
  if Length(LRegion) > 0 then
  begin
    for i := 1 to High(LRegion) do
      LRegion[0].Union(LRegion[i]);
    FLeft := LRegion[0].Left;
    FTop := LRegion[0].Top;
    FWidth := LRegion[0].Width;
    FHeight := LRegion[0].Height;
  end;
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

procedure TTextLayoutAggPas.RenderText(const APos, ALength: Integer;
  aTextRenderProc: TProcRenderText);
type
  TTextRange = record
    Start: Double;
    Length: Double;
    Text: string;
  end;
  TTextLine = record
    Length: Double;
    FromIndex: integer;
    ToIndex: integer;
  end;
var
  Glyph: PAggGlyphCache;
  PrevGlyphValue, GlyphValue: Char;
  CurPos: TPointDouble;
  PrevPos, StartPos, EndPos, BreakPos, LineAdvance: Double;
  i, j, PrevIndex, StartIndex, EndIndex, BreakIndex: Integer;
  TextLines: array of TTextLine;
  TextRanges: array of TTextRange;
  R: TRectF;

  function CanBreak: boolean;
  begin
    // TODO maybe use TUnicodeBreak in System.Character
    Result := (Ord(PrevGlyphValue) in [32, 10, 13])
           and not(Ord(GlyphValue) in [32, 10, 13]);
  end;

  function DirectionalChange: boolean;
  begin
    // TODO Bidi
    Result := False;
  end;

  function LineFeed: boolean;
  begin
    Result := False;

    if (Ord(GlyphValue) = 13) then
    begin
      if (i + 2 < Length(Text))
      and (Ord(Text[i + 2]) = 10) then
      begin
        // Windows linefeed
        i := i + 2;
        Result := True;
      end else begin
        // Mac linefeed
        i := i + 1;
        Result := True;
      end;
    end else
      if (Ord(GlyphValue) = 10) then
      begin
        // Unix linefeed
        i := i + 1;
        Result := True;
      end;
  end;

  procedure AddTextRange(const aText: string; const aStart, aLength: Double);
  begin
    SetLength(TextRanges, Length(TextRanges) + 1);
    TextRanges[High(TextRanges)].Text := aText;
    TextRanges[High(TextRanges)].Start := aStart;
    TextRanges[High(TextRanges)].Length := aLength;
  end;

  procedure AddTextLine(const aFromIndex, aToIndex: integer; const aLength: Double);
  begin
    SetLength(TextLines, Length(TextLines) + 1);
    TextLines[High(TextLines)].Length := aLength;
    TextLines[High(TextLines)].FromIndex := aFromIndex;
    TextLines[High(TextLines)].ToIndex := aToIndex;
  end;

begin
  // TODO: this isn't perfect yet

  if APos < 0 then
    exit;

  if Text = '' then
    Exit;

  SetFont(
    Font.Family,
    Font.Size,
    TFontStyle.fsBold in Font.Style,
    TFontStyle.fsItalic in Font.Style,
    0);

  LineAdvance := FFontEngine.DefaultLineSpacing;

  CurPos.X := 0;
  CurPos.Y := 0;

  PrevPos := 0;
  PrevIndex := 0;
  BreakPos := 0;
  BreakIndex := 0;

  StartPos := 0;
  StartIndex := -1;
  EndPos := 0;
  EndIndex := -1;

  PrevGlyphValue := #0;

  AddTextLine(0, 0, 0);

  i := 0;
  while (i < Length(Text)) do
  begin
    if I = APos then
    begin
      StartIndex := Length(TextRanges);
      StartPos := CurPos.X - PrevPos;
    end;

    PrevGlyphValue := GlyphValue;
    GlyphValue := Text[i + 1];

    Glyph := FFontCacheManager.Glyph(Ord(GlyphValue));

    if Glyph <> nil then
    begin
      if CanBreak then
      begin
        BreakIndex := i;
        BreakPos := CurPos.X;
      end;

      if DirectionalChange then
      begin
        // Add a region if text direction changes

        AddTextRange(Copy(Text, PrevIndex + 1, i - PrevIndex), PrevPos, CurPos.X - PrevPos);
        TextLines[High(TextLines)].ToIndex := High(TextRanges);
        TextLines[High(TextLines)].Length :=
          TextLines[High(TextLines)].Length + CurPos.X - PrevPos;

        PrevIndex := i;
        PrevPos := CurPos.X;
      end;

      {$IFDEF AGG2D_USE_FREETYPE}
      // TODO: Gives wrong results for some fonts on Win32TrueType
      if I <> 0 then
        FFontCacheManager.AddKerning(@CurPos.X, @CurPos.Y);
      {$ENDIF}

      FFontCacheManager.InitEmbeddedAdaptors(Glyph, CurPos.X, CurPos.Y);

      CurPos.X := CurPos.X + Glyph.AdvanceX;
      CurPos.Y := CurPos.Y + Glyph.AdvanceY;

      if (WordWrap and (CurPos.X > MaxSize.X)) or LineFeed then
      begin
        // Add a region on line advance

        // Correct start and end position if it is in the current region after the break
        if (StartIndex = Length(TextRanges)) and (StartPos >= BreakPos) then
        begin
          StartIndex := StartIndex + 1;
          StartPos := StartPos - BreakPos;
        end;

        if (EndIndex = Length(TextRanges)) and (EndPos > BreakPos) then
        begin
          EndIndex := EndIndex + 1;
          EndPos := EndPos - BreakPos;
        end;

        AddTextRange(Copy(Text, PrevIndex + 1, BreakIndex - PrevIndex), PrevPos, BreakPos - PrevPos);

        TextLines[High(TextLines)].ToIndex := High(TextRanges);
        TextLines[High(TextLines)].Length :=
          TextLines[High(TextLines)].Length + BreakPos - PrevPos;

        PrevIndex := BreakIndex;

        AddTextLine(Length(TextRanges), Length(TextRanges), 0);
        CurPos.X := CurPos.X - BreakPos;
        CurPos.Y := CurPos.Y + LineAdvance;

        PrevPos := 0;
        PrevGlyphValue := #0;
      end;
    end;

    Inc(i);

    if i = APos + ALength then
    begin
      if StartIndex = -1 then
      begin
        StartIndex := Length(TextRanges);
        StartPos := CurPos.X - PrevPos;
      end;

      EndPos := CurPos.X - PrevPos;
      EndIndex := Length(TextRanges);
    end;
  end;

  // Add last region

  AddTextRange(Copy(Text, PrevIndex + 1, i - PrevIndex), PrevPos, CurPos.X - PrevPos);
  TextLines[High(TextLines)].ToIndex := High(TextRanges);
  TextLines[High(TextLines)].Length :=
    TextLines[High(TextLines)].Length + CurPos.X - PrevPos;

  for i := 0 to High(TextLines) do
  begin
    for j := TextLines[i].FromIndex to TextLines[i].ToIndex do
    begin
      case HorizontalAlign of
        TTextAlign.taLeading:
          begin
            R.Left := TextRanges[j].Start;
            R.Right := R.Left + TextRanges[j].Length;
          end;
        TTextAlign.taTrailing:
          begin
            R.Left := MaxSize.X - TextLines[i].Length + TextRanges[j].Start;
            R.Right := R.Left + TextRanges[j].Length;
          end;
        TTextAlign.taCenter:
          begin
            R.Left := 0.5 * (MaxSize.X - TextLines[i].Length) + TextRanges[j].Start;
            R.Right := R.Left + TextRanges[j].Length;
          end;
      end;

      case VerticalAlign of
        TTextAlign.taLeading:
          begin
            R.Top := i * LineAdvance;
            R.Bottom := R.Top + LineAdvance;
          end;
        TTextAlign.taTrailing:
          begin
            R.Top := MaxSize.Y - (Length(TextLines) - i) * LineAdvance;
            R.Bottom := R.Top + LineAdvance;
          end;
        TTextAlign.taCenter:
          begin
            R.Top := 0.5 * (MaxSize.Y - Length(TextLines) * LineAdvance) + i * LineAdvance;
            R.Bottom := R.Top + LineAdvance;
          end;
      end;

      if (StartIndex <= j) and (EndIndex >= j) then
      begin
        if j = EndIndex then
          R.Right := R.Left + EndPos;

        if j = StartIndex then
          R.Left := R.Left + StartPos;

        aTextRenderProc(TextRanges[j].Text, R);
      end;
    end;
  end;
end;

function TTextLayoutAggPas.MeasureRange(const APos, ALength: Integer): TRegion;
var
  Region: TRegion;
begin
  SetLength(Region, 0);

  RenderText(aPos, ALength,
    procedure(const aText: string; const aTextRect: TRectF)
    begin
      SetLength(Region, Length(Region) + 1);
      Region[High(Region)] := aTextRect;
    end);

  Result := Region;
end;

procedure TTextLayoutAggPas.SetFont(FontFamily: string; FontSize: Double; Bold,
  Italic: Boolean; Angle: Double);
var
  {$IFDEF AGG2D_USE_FREETYPE}
  i, Score, MaxScore: integer;
  {$ELSE}
  B: Integer;
  {$ENDIF}
begin
  {$IFDEF AGG2D_USE_FREETYPE}
  if (FontFamily <> FFontFamily) or (Bold <> FBold) or (Italic <> Italic) then
  begin
    // Select a best fitting font

    FFontFamily := FontFamily;
    FBold := Bold;
    FItalic := Italic;

    FFontFileName := '';
    MaxScore := 0;
    for i := 0 to Length(FFontNamesList) - 1 do
    begin
      Score := 0;
      if (Pos(Lowercase(FontFamily), Lowercase(FFontNamesList[i].FontFamily)) > 0) then
        Score := Score + 100;

      if (Pos('light', Lowercase(FFontNamesList[i].FontFamily)) > 0) then
        Score := Score - 5;

      if (Pos('black', Lowercase(FFontNamesList[i].FontFamily)) > 0) then
        Score := Score - 5;

      if (not Bold) and (not Italic)
      and (Pos('regular', Lowercase(FFontNamesList[i].FontSubFamily)) > 0) then
        Score := Score + 10;

      if Bold and (Pos('bold', Lowercase(FFontNamesList[i].FontSubFamily)) > 0) then
        Score := Score + 10;

      if Italic and (Pos('italic', Lowercase(FFontNamesList[i].FontSubFamily)) > 0) then
        Score := Score + 10;

      if Score > MaxScore then
      begin
        FFontFileName := FFontNamesList[i].Filename;
        MaxScore := Score;
      end;
    end;
  end;

  FFontEngine.LoadFont(FFontFileName, 0, grOutline);
  FFontEngine.Hinting := FTextHints;
  FFontSize := FontSize;
  FFontEngine.SetHeight(FontSize)
  {$ELSE}
  if (FontFamily <> FFontFamily) or (Bold <> FBold) or (Italic <> Italic)
  or (FontSize <> FFontSize)
  then
  begin
    FFontEngine.Hinting := FTextHints;

    FFontFamily := FontFamily;
    FBold := Bold;
    FItalic := Italic;
    FFontSize := FontSize;

    if Bold then
      B := 700
    else
      B := 400;

    FFontEngine.CreateFont(FontFamily, {grNativeMono}grNativeGray8{grOutline}, FontSize, 0, B, Italic)
  end;
  {$ENDIF}
end;

class procedure TTextLayoutAggPas.SetTextHints(Value: Boolean);
begin
  FTextHints := Value;
end;

{$IFDEF AGG2D_USE_FREETYPE}
procedure GetFontNames(aStrings: TStrings);
begin
  TTextLayoutAggPas.GetFontNames(aStrings);
end;
{$ENDIF}

initialization
{$IFNDEF DISABLEAUTOINITIALIZE}
  SetAggPasDefault;
{$ENDIF}

end.
