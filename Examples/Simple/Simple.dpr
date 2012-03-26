program Simple;

// AggPas 2.4 RM3 Demo application
// Note: Press F1 key on run to see more info about this demo

{$I AggCompiler.inc}

uses
  FastMM4,
  AggBasics,
  AggPlatformSupport,

  AggColor,
  AggPixelFormat,
  AggPixelFormatRgb,

  AggRenderingBuffer,
  AggRendererBase,
  AggRendererPrimitives,
  AggRendererScanLine,
  AggRasterizerScanLineAA,
  AggScanLine,
  AggScanLinePacked,
  AggEllipse,
  AggConvStroke,
  AggRenderScanLines;

const
  CFlipY = True;

type
  TAggApplication = class(TPlatformSupport)
  public
    constructor Create(PixelFormat: TPixelFormat; FlipY: Boolean);
    destructor Destroy; override;

    procedure OnDraw; override;

    procedure OnMouseMove(X, Y: Integer; Flags: TMouseKeyboardFlags); override;
    procedure OnMouseButtonDown(X, Y: Integer; Flags: TMouseKeyboardFlags);
      override;

    procedure OnKey(X, Y: Integer; Key: Cardinal; Flags: TMouseKeyboardFlags);
      override;
  end;


{ TAggApplication }

constructor TAggApplication.Create(PixelFormat: TPixelFormat; FlipY: Boolean);
begin
  inherited Create(PixelFormat, FlipY);
end;

destructor TAggApplication.Destroy;
begin
  inherited;
end;

procedure TAggApplication.OnDraw;
var
  PixelFormatProcessor: TAggPixelFormatProcessor;

  RendererBase: TAggRendererBase;
  RendererScanLine : TAggRendererScanLineAASolid;
  RasterizerScanLine : TAggRasterizerScanlineAA;
  ScanLine : TAggScanLinePacked8;
  Ellipse: TAggEllipse;

  Rgba : TAggColor;
begin
  // Initialize structures
  PixelFormatBgr24(PixelFormatProcessor, RenderingBufferWindow);

  RendererBase := TAggRendererBase.Create(PixelFormatProcessor, True);
  try
    Rgba.FromRgbaInteger($90, $60, $30);
    RendererBase.Clear(@Rgba);

    Rgba.FromRgbaInteger($30, $60, $90);
    RendererBase.CopyBar(10, 10, 20, 20, @Rgba);
    RendererBase.CopyVerticalLine(30, 10, 20, @Rgba);
    RendererBase.CopyHorizontalLine(40, 15, 50, @Rgba);

    with TAggRendererPrimitives.Create(RendererBase) do
    try
      SetFillColor(@Rgba);

      SolidEllipse(100, 80, 90, 60);

      Rgba.FromRgbaInteger($60, $90, $30);
      SetLineColor(@Rgba);
      Ellipse(100, 80, 90, 60);
    finally
      Free;
    end;

    RasterizerScanLine := TAggRasterizerScanlineAA.Create;
    RendererScanLine := TAggRendererScanLineAASolid.Create(RendererBase);
    ScanLine := TAggScanLinePacked8.Create;
    try
      Ellipse := TAggEllipse.Create(200, 200, 90, 120);
      try
        Rgba.White;
        RendererScanLine.SetColor(@Rgba);
        RasterizerScanLine.AddPath(Ellipse);
        RenderScanLines(RasterizerScanLine, ScanLine, RendererScanLine);
      finally
        Ellipse.Free;
      end;
    finally
      ScanLine.Free;
      RasterizerScanLine.Free;
      RendererScanLine.Free;
    end;
  finally
    RendererBase.Free;
  end;
end;

procedure TAggApplication.OnMouseMove(X, Y: Integer;
  Flags: TMouseKeyboardFlags);
begin
  OnMouseButtonDown(X, Y, Flags);
end;

procedure TAggApplication.OnMouseButtonDown(X, Y: Integer;
  Flags: TMouseKeyboardFlags);
begin
  if mkfMouseLeft in Flags then
  begin

    ForceRedraw;
  end;
end;

procedure TAggApplication.OnKey(X, Y: Integer; Key: Cardinal;
  Flags: TMouseKeyboardFlags);
begin
  if Key = Cardinal(kcF1) then
    DisplayMessage('The example demonstrates how to write custom span '
      + 'generators. This one just applies the simplest "blur" filter 3x3 to a '
      + 'prerendered image. It calculates the average value of 9 neighbor '
      + 'pixels.'#13#13
      + 'How to play with:'#13#13
      + 'Just press the left mouse button and drag.'#13
      + 'Uncomment and recompile the part of the demo source code to get '
      + 'more blur.'#13#13
      + 'Note: F2 key saves current "screenshot" file in this demo''s'
      + 'directory.');
end;

begin
  with TAggApplication.Create(pfBgr24, CFlipY) do
  try
    Caption := 'AGG Example. Lion with Alpha-Masking (F1-Help)';
    if Init(512, 400, [wfResize]) then
      Run;
  finally
    Free;
  end;
end.
