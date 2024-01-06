program SvgTest;

// AggPas 2.4 RM3 Demo application
// Note: Press F1 key on run to see more info about this demo

{$I AggCompiler.inc}

uses
//  FastMM4,
  SysUtils,
  {$IFDEF AGG_WINDOWS}
  AggPlatformSupport in '..\..\Source\Platform\win\AggPlatformSupport.pas',
  AggFileUtils in '..\..\Source\Platform\win\AggFileUtils.pas',
  {$ENDIF}
  {$IFDEF AGG_LINUX}
  AggPlatformSupport in '..\..\Source\Platform\linux\AggPlatformSupport.pas',
  AggFileUtils in '..\..\Source\Platform\linux\AggFileUtils.pas',
  {$ENDIF}
  {$IFDEF AGG_MACOSX}
  AggPlatformSupport in '..\..\Source\Platform\mac\AggPlatformSupport.pas',
  AggFileUtils in '..\..\Source\Platform\mac\AggFileUtils.pas',
  {$ENDIF}
  AggBasics in '..\..\Source\AggBasics.pas',
  AggColor in '..\..\Source\AggColor.pas',
  AggPixelFormat in '..\..\Source\AggPixelFormat.pas',
  AggPixelFormatRgba in '..\..\Source\AggPixelFormatRgba.pas',
  AggControl in '..\..\Source\Controls\AggControl.pas',
  AggSliderControl in '..\..\Source\Controls\AggSliderControl.pas',
  AggRenderingBuffer in '..\..\Source\AggRenderingBuffer.pas',
  AggRendererBase in '..\..\Source\AggRendererBase.pas',
  AggRendererScanLine in '..\..\Source\AggRendererScanLine.pas',
  AggRasterizerScanLineAA in '..\..\Source\AggRasterizerScanLineAA.pas',
  AggScanLine in '..\..\Source\AggScanLine.pas',
  AggScanLinePacked in '..\..\Source\AggScanLinePacked.pas',
  AggRenderScanLines in '..\..\Source\AggRenderScanLines.pas',
  AggTransAffine in '..\..\Source\AggTransAffine.pas',
  AggGammaFunctions in '..\..\Source\AggGammaFunctions.pas',
  AggGsvText in '..\..\Source\AggGsvText.pas',
  AggConvStroke in '..\..\Source\AggConvStroke.pas',
  AggSvgParser in '..\..\Source\Svg\AggSvgParser.pas',
  AggSvgPathRenderer in '..\..\Source\Svg\AggSvgPathRenderer.pas',
  AggSvgException in '..\..\Source\Svg\AggSvgException.pas',
  Expat in '..\..\Source\3rd Party\Expat\Expat.pas',
  ExpatBasics in '..\..\Source\3rd Party\Expat\ExpatBasics.pas',
  ExpatExternal in '..\..\Source\3rd Party\Expat\ExpatExternal.pas',
  xmlrole in '..\..\Source\3rd Party\Expat\xmlrole.pas',
  xmltok in '..\..\Source\3rd Party\Expat\xmltok.pas';

const
  CFlipY = False;

type
  TAggApplication = class(TPlatformSupport)
  private
    FPath: TPathRenderer;
    FSliderExpand: TAggControlSlider;
    FSliderGamma: TAggControlSlider;
    FSliderScale: TAggControlSlider;
    FSliderRotate: TAggControlSlider;
    FPos: TPointDouble;
    FMin, FMax, FDelta: TPointDouble;
    FDragFlag: Boolean;
  public
    constructor Create(PixelFormat: TPixelFormat; FlipY: Boolean);
    destructor Destroy; override;

    procedure ParseSvg(FileName: ShortString);

    procedure OnDraw; override;

    procedure OnMouseMove(X, Y: Integer; Flags: TMouseKeyboardFlags); override;

    procedure OnMouseButtonDown(X, Y: Integer; Flags: TMouseKeyboardFlags);
      override;
    procedure OnMouseButtonUp(X, Y: Integer; Flags: TMouseKeyboardFlags);
      override;

    procedure OnKey(X, Y: Integer; Key: Cardinal; Flags: TMouseKeyboardFlags);
      override;
  end;


{ TAggApplication }

constructor TAggApplication.Create(PixelFormat: TPixelFormat; FlipY: Boolean);
begin
  inherited Create(PixelFormat, FlipY);

  FPath := TPathRenderer.Create;

  FSliderExpand := TAggControlSlider.Create(5, 5, 251, 11, not FlipY);
  FSliderGamma := TAggControlSlider.Create(5, 20, 251, 26, not FlipY);
  FSliderScale := TAggControlSlider.Create(261, 5, 507, 11, not FlipY);
  FSliderRotate := TAggControlSlider.Create(261, 20, 507, 26, not FlipY);

  FMin := PointDouble(0, 0);
  FMax := PointDouble(0, 0);
  FDelta := PointDouble(0, 0);

  FPos := PointDouble(0, 0);

  FDragFlag := False;

  AddControl(FSliderExpand);
  AddControl(FSliderGamma);
  AddControl(FSliderScale);
  AddControl(FSliderRotate);

  FSliderExpand.Caption := 'Expand=%3.2f';
  FSliderExpand.SetRange(-1, 1.2);
  FSliderExpand.Value := 0.0;

  FSliderGamma.Caption := 'Gamma=%3.2f';
  FSliderGamma.SetRange(0.0, 3.0);
  FSliderGamma.Value := 1.0;

  FSliderScale.Caption := 'Scale=%3.2f';
  FSliderScale.SetRange(0.2, 10.0);
  FSliderScale.Value := 1.0;

  FSliderRotate.Caption := 'Rotate=%3.2f';
  FSliderRotate.SetRange(-180.0, 180.0);
  FSliderRotate.Value := 0.0;
end;

destructor TAggApplication.Destroy;
begin
  FPath.Free;

  FSliderExpand.Free;
  FSliderGamma.Free;
  FSliderScale.Free;
  FSliderRotate.Free;

  inherited
end;

procedure TAggApplication.ParseSvg(FileName: ShortString);
var
  P: TParser;
begin
  P := TParser.Create(FPath);
  try
    P.Parse(FileName);

    FPath.ArrangeOrientations;
    FPath.BoundingRect(@FMin.X, @FMin.Y, @FMax.X, @FMax.Y);

    Caption := P.Title + ' (F1-Help)';
  finally
    P.Free;
  end;
end;

procedure TAggApplication.OnDraw;
var
  Pixf: TAggPixelFormatProcessor;

  RendererBase : TAggRendererBase;
  Ren: TAggRendererScanLineAASolid;
  Ras: TAggRasterizerScanLineAA;
  Sl : TAggScanLinePacked8;
  Mtx: TAggTransAffine;

  Gmpw: TAggGammaPower;
  Gmno: TAggGammaNone;

  Tm: Double;

  VertexCount: Cardinal;

  Txt: TAggGsvText;
  Pt: TAggConvStroke;
  V: Double;
begin
  // Initialize structures
  PixelFormatBgra32(Pixf, RenderingBufferWindow);

  RendererBase := TAggRendererBase.Create(Pixf, True);
  try
    Ren := TAggRendererScanLineAASolid.Create(RendererBase);
    try
      RendererBase.Clear(CRgba8White);

      Ras := TAggRasterizerScanLineAA.Create;
      Sl := TAggScanLinePacked8.Create;

      // Render
      Gmpw :=  TAggGammaPower.Create(FSliderGamma.Value);
      try
        Ras.Gamma(Gmpw);
      finally
        Gmpw.Free;
      end;

      Mtx := TAggTransAffine.Create;
      try
        Mtx.Translate((FMin.X + FMax.X) * -0.5, (FMin.Y + FMax.Y) * -0.5);
        Mtx.Scale(FSliderScale.Value);
        Mtx.Rotate(Deg2Rad(FSliderRotate.Value));
        Mtx.Translate((FMin.X + FMax.X) * 0.5 + FPos.X,
          (FMin.Y + FMax.Y) * 0.5 + FPos.Y + 30);

        FPath.Expand(FSliderExpand.Value);

        StartTimer;

        FPath.Render(Ras, Sl, Ren, Mtx, RendererBase.GetClipBox^, 1.0);

        Tm := GetElapsedTime;
      finally
        Mtx.Free;
      end;

      VertexCount := FPath.VertexCount;

      // Render the controls
      Gmno := TAggGammaNone.Create;
      try
        Ras.Gamma(Gmno);
      finally
        Gmno.Free;
      end;

      RenderControl(Ras, Sl, Ren, FSliderExpand);
      RenderControl(Ras, Sl, Ren, FSliderGamma);
      RenderControl(Ras, Sl, Ren, FSliderScale);
      RenderControl(Ras, Sl, Ren, FSliderRotate);

      // Display text
      Txt := TAggGsvText.Create;
      try
        Txt.SetSize(10.0);
        Txt.Flip := True;

        Pt := TAggConvStroke.Create(Txt);
        try
          Pt.Width := 1.5;

          Txt.SetStartPoint(10.0, 40.0);
          Txt.SetText(Format('Vertices=%d Time=%.3f ms', [VertexCount, Tm]));

          Ras.AddPath(Pt);
        finally
          Pt.Free;
        end;
      finally
        Txt.Free;
      end;

      Ren.SetColor(CRgba8Black);
      RenderScanLines(Ras, Sl, Ren);

      // Free AGG resources
      Ras.Free;
      Sl.Free;
    finally
      Ren.Free;
    end;
  finally
    RendererBase.Free;
  end;
end;

procedure TAggApplication.OnMouseMove(X, Y: Integer;
  Flags: TMouseKeyboardFlags);
begin
  if Flags = [] then
    FDragFlag := False;

  if FDragFlag then
  begin
    FPos.X := X - FDelta.X;
    FPos.Y := Y - FDelta.Y;

    ForceRedraw;
  end;
end;

procedure TAggApplication.OnMouseButtonDown(X, Y: Integer;
  Flags: TMouseKeyboardFlags);
begin
  FDelta := PointDouble(X - FPos.X, Y - FPos.Y);

  FDragFlag := True;
end;

procedure TAggApplication.OnMouseButtonUp(X, Y: Integer;
  Flags: TMouseKeyboardFlags);
begin
  FDragFlag := False;
end;

procedure TAggApplication.OnKey(X, Y: Integer; Key: Cardinal;
  Flags: TMouseKeyboardFlags);
var
  Mtx: TAggTransAffine;

  M  : TAggParallelogram;
  Fd : Text;
  V  : Double;
begin
  if Key = Byte(' ') then
  begin
    Mtx := TAggTransAffine.Create;
    try
      Mtx.Translate((FMin.X + FMax.X) * -0.5, (FMin.Y + FMax.Y) * -0.5);
      Mtx.Scale(FSliderScale.Value);
      Mtx.Rotate(Deg2Rad(FSliderRotate.Value));
      Mtx.Translate((FMin.X + FMax.X) * 0.5, (FMin.Y + FMax.Y) * 0.5);
      Mtx.Translate(FPos.X, FPos.Y);

      Mtx.StoreTo(@M);
    finally
      Mtx.Free;
    end;

    DisplayMessage(Format('%3.3f, %3.3f, %3.3f, %3.3f, %3.3f, %3.3f', [M[0],
      M[1], M[2], M[3], M[4], M[5]]));

{$I- }
    AssignFile(Fd, 'transform.txt');
    Rewrite(Fd);
//    Writeln(Fd, PAnsiChar(@Buf[0]));
    Close(Fd);
  end;

  if Key = Cardinal(kcF1) then
    DisplayMessage('The SVG viewer is just another example of using Anti-Grain '
      + 'Geometry. The viewer supports absolute minimum of the SVG '
      + 'specification, it basically can be used as a simple example of AGG '
      + 'plus SVG. But of course, its functionality can be extended. The main '
      + 'point of the viewer is High quality and High performance. The '
      + 'Anti-Aliasing algorithm produces 256 levels of transparency. '
      + 'Actually, AGG computes the exact coverage of the outline on each '
      + 'pixel cell.'#13
      + 'Besides, the viewer has a very nice feature that I haven''t seen in '
      + 'any other ones. It''s eliminating of the "problem of adjacent edges". '
      + 'It appears when rendering adjacent polygons with anti-aliasing and '
      + 'looks like thin "web" upon the image. Strictly speaking, it''s '
      + 'possible to get rid of it completely only when the polygons are fully '
      + 'opaque. When they are translucent, the effect will appear anyway. '
      + 'However, it''s possible to reduce the effect so that it becomes '
      + 'almost invisible.'#13#13
      + 'How to play with:'#13#13
      + 'Use mouse to move the drawing around. Change size & rotation with '
      + 'top controls. Press the spacebar key to display and save the current '
      + 'transformation matrix.');
end;

var
  FileName: ShortString;
  ApiFile: TApiFile;

begin
  with TAggApplication.Create(pfBgra32, CFlipY) do
  try
    FileName := FileSource('svg', 'tiger.svg');

    if ParamCount > 0 then
      FileName := Param_str(1)
    else
    begin
      if ApiOpenFile(ApiFile, FileName) then
        ApiCloseFile(ApiFile)
      else
      begin
        DisplayMessage('Usage: svg_test <svg_file>');
        Exit;
      end;
    end;

    try
      ParseSvg(FileName);

      if Init(512, 600, [wfResize]) then
        Run;
    except
      on E: TSvgException do
      begin
        DisplayMessage(PAnsiChar(E.GetMessage));
        E.Free;
      end;

      else
        DisplayMessage('Unknown exception');
    end;
  finally
    Free;
  end;
end.
