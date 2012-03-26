program LinePatterns;

// AggPas 2.4 RM3 Demo application
// Note: Press F1 key on run to see more info about this demo

{$I AggCompiler.inc}
{$I-}

uses
  FastMM4,
  Math,
  SysUtils,
  AggBasics,
  AggMath,
  AggPlatformSupport,
  AggColor,
  AggPixelFormat,
  AggPixelFormatRgb,
  AggControl,
  AggSliderControl,
  AggPolygonControl,
  AggRenderingBuffer,
  AggRendererBase,
  AggRendererScanLine,
  AggRendererOutlineAA,
  AggRendererOutlineImage,
  AggRasterizerScanLineClip,
  AggRasterizerScanLine,
  AggRasterizerCompoundAA,
  AggRasterizerOutlineAA,
  AggScanLine,
  AggScanLinePacked,
  AggRenderScanLines,
  AggTransAffine,
  AggPatternFiltersRgba,
  AggPathStorage,
  AggConvStroke,
  AggConvTransform,
  AggConvClipPolyline,
  AggVertexSource;

const
  CFlipY = True;

  CBrightnessToAlpha: array [0..256 * 3 - 1] of Int8u = (
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 254, 254, 254, 254, 254, 254, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 254, 254, 254, 254, 254, 254, 254,
    254, 254, 254, 254, 254, 254, 254, 253, 253, 253, 253, 253, 253, 253, 253,
    253, 253, 253, 253, 253, 253, 253, 253, 253, 252, 252, 252, 252, 252, 252,
    252, 252, 252, 252, 252, 252, 251, 251, 251, 251, 251, 251, 251, 251, 251,
    250, 250, 250, 250, 250, 250, 250, 250, 249, 249, 249, 249, 249, 249, 249,
    248, 248, 248, 248, 248, 248, 248, 247, 247, 247, 247, 247, 246, 246, 246,
    246, 246, 246, 245, 245, 245, 245, 245, 244, 244, 244, 244, 243, 243, 243,
    243, 243, 242, 242, 242, 242, 241, 241, 241, 241, 240, 240, 240, 239, 239,
    239, 239, 238, 238, 238, 238, 237, 237, 237, 236, 236, 236, 235, 235, 235,
    234, 234, 234, 233, 233, 233, 232, 232, 232, 231, 231, 230, 230, 230, 229,
    229, 229, 228, 228, 227, 227, 227, 226, 226, 225, 225, 224, 224, 224, 223,
    223, 222, 222, 221, 221, 220, 220, 219, 219, 219, 218, 218, 217, 217, 216,
    216, 215, 214, 214, 213, 213, 212, 212, 211, 211, 210, 210, 209, 209, 208,
    207, 207, 206, 206, 205, 204, 204, 203, 203, 202, 201, 201, 200, 200, 199,
    198, 198, 197, 196, 196, 195, 194, 194, 193, 192, 192, 191, 190, 190, 189,
    188, 188, 187, 186, 186, 185, 184, 183, 183, 182, 181, 180, 180, 179, 178,
    177, 177, 176, 175, 174, 174, 173, 172, 171, 171, 170, 169, 168, 167, 166,
    166, 165, 164, 163, 162, 162, 161, 160, 159, 158, 157, 156, 156, 155, 154,
    153, 152, 151, 150, 149, 148, 148, 147, 146, 145, 144, 143, 142, 141, 140,
    139, 138, 137, 136, 135, 134, 133, 132, 131, 130, 129, 128, 128, 127, 125,
    124, 123, 122, 121, 120, 119, 118, 117, 116, 115, 114, 113, 112, 111, 110,
    109, 108, 107, 106, 105, 104, 102, 101, 100, 99, 98, 97, 96, 95, 94, 93, 91,
    90, 89, 88, 87, 86, 85, 84, 82, 81, 80, 79, 78, 77, 75, 74, 73, 72, 71, 70,
    69, 67, 66, 65, 64, 63, 61, 60, 59, 58, 57, 56, 54, 53, 52, 51, 50, 48, 47,
    46, 45, 44, 42, 41, 40, 39, 37, 36, 35, 34, 33, 31, 30, 29, 28, 27, 25, 24,
    23, 22, 20, 19, 18, 17, 15, 14, 13, 12, 11, 9, 8, 7, 6, 4, 3, 2, 1);

type
  TAggPatternSourceBrightnessToAlphaRgba8 = class(TAggPixelSource)
  private
    FRenderingBuffer: TAggRenderingBuffer;
    FPixelFormatProcessor: TAggPixelFormatProcessor;
  protected
    function GetWidth: Cardinal; override;
    function GetHeight: Cardinal; override;
  public
    constructor Create(Rb: TAggRenderingBuffer);
    destructor Destroy; override;

    function Pixel(X, Y: Integer): TAggRgba8; override;
  end;

  TAggApplication = class(TPlatformSupport)
  private
    FControlColor: TAggColor;
    FScale: TAggTransAffine;
    FLine: TPolygonControl;
    FSliderScaleX, FSliderStartX: TAggControlSlider;
  public
    constructor Create(PixelFormat: TPixelFormat; FlipY: Boolean);
    destructor Destroy; override;

    procedure DrawPolyline(Ras: TAggRasterizerOutlineAA; Ren: TAggRendererOutlineAA;
      PolyLine: PDouble; NumPoints: Integer);

    procedure OnDraw; override;

    procedure OnKey(X, Y: Integer; Key: Cardinal; Flags: TMouseKeyboardFlags); override;
  end;


{ TAggPatternSourceBrightnessToAlphaRgba8 }

constructor TAggPatternSourceBrightnessToAlphaRgba8.Create(Rb: TAggRenderingBuffer);
begin
  FRenderingBuffer := Rb;

  PixelFormatBgr24(FPixelFormatProcessor, FRenderingBuffer);
end;

function TAggPatternSourceBrightnessToAlphaRgba8.GetWidth;
begin
  Result := FPixelFormatProcessor.Width;
end;

destructor TAggPatternSourceBrightnessToAlphaRgba8.Destroy;
begin
  FPixelFormatProcessor.Free;
  inherited;
end;

function TAggPatternSourceBrightnessToAlphaRgba8.GetHeight;
begin
  Result := FPixelFormatProcessor.Height;
end;

function TAggPatternSourceBrightnessToAlphaRgba8.Pixel(X, Y: Integer): TAggRgba8;
var
  C: TAggColor;
begin
  C := FPixelFormatProcessor.Pixel(FPixelFormatProcessor, X, Y);
  C.Rgba8.A := CBrightnessToAlpha[C.Rgba8.R + C.Rgba8.G + C.Rgba8.B];

  Result := C.Rgba8;
end;


{ TAggApplication }

constructor TAggApplication.Create(PixelFormat: TPixelFormat; FlipY: Boolean);
begin
  inherited Create(PixelFormat, FlipY);

  FControlColor.FromRgbaDouble(0, 0.3, 0.5, 0.3);

  FSliderScaleX := TAggControlSlider.Create(5.0, 5.0, 240.0, 12.0, not FlipY);
  FSliderScaleX.Caption := 'Scale X=%.2f';
  FSliderScaleX.SetRange(0.2, 3.0);
  FSliderScaleX.Value := 1.0;
  AddControl(FSliderScaleX);
  FSliderScaleX.NoTransform;

  FSliderStartX := TAggControlSlider.Create(250.0, 5.0, 495.0, 12.0, not FlipY);
  FSliderStartX.Caption := 'Start X=%.2f';
  FSliderStartX.SetRange(0.0, 10.0);
  FSliderStartX.Value := 0.0;
  AddControl(FSliderStartX);
  FSliderStartX.NoTransform;

  FScale := TAggTransAffine.Create;

  FLine := TPolygonControl.Create(5);
  FLine.SetLineColor(@FControlColor);
  FLine.Xn[0] := 20;
  FLine.Yn[0] := 20;
  FLine.Xn[1] := 500-20;
  FLine.Yn[1] := 500-20;
  FLine.Xn[2] := 500-60;
  FLine.Yn[2] := 20;
  FLine.Xn[3] := 40;
  FLine.Yn[3] := 500-40;
  FLine.Xn[4] := 100;
  FLine.Yn[4] := 300;
  FLine.Close := False;
  FLine.Transform(FScale);

  AddControl(FLine);
end;

destructor TAggApplication.Destroy;
begin
  FSliderScaleX.Free;
  FSliderStartX.Free;

  FLine.Free;
  FScale.Free;

  inherited;
end;

procedure TAggApplication.DrawPolyline(Ras: TAggRasterizerOutlineAA;
  Ren: TAggRendererOutlineAA; PolyLine: PDouble; NumPoints: Integer);
var
  VertexSource: TAggVertexSource;
  Trans : TAggConvTransform;
begin
  VertexSource := TPolyPlainAdaptor.Create(PolyLine, NumPoints, FLine.Close);
  try
    Trans := TAggConvTransform.Create(VertexSource, FScale);
    try
      Ras.AddPath(Trans);
    finally
      Trans.Free;
    end;
  finally
    VertexSource.Free;
  end;
end;

procedure TAggApplication.OnDraw;
var
  Pf : TAggPixelFormatProcessor;
  RenScan: TAggRendererScanLineAASolid;
  Rasterizer: TAggRasterizerScanlineClipIntegerSat;
  ScanLine: TAggScanLinePacked8;

  Rgba: TAggColor;
  Bounds: TRectInteger;
  w2: Double;

  RendererBase: TAggRendererBase;

  PatternSource: TAggPatternSourceBrightnessToAlphaRgba8;

  PatternFilter: TAggPatternFilterBilinearRgba;
  LineImagePattern: TAggLineImagePattern;

  Profile: TAggLineProfileAA;

  RendererLine: TAggRendererOutlineAA;
  RasLine: TAggRasterizerOutlineAA;

  RenImage: TAggRendererOutlineImage;
  RasImage: TAggRasterizerOutlineAA;
begin
  // Initialize structures
  PixelFormatBgr24(Pf, RenderingBufferWindow);
  RendererBase := TAggRendererBase.Create(Pf, True);
  try
    Rgba.FromRgbaDouble(0.5, 0.75, 0.85);
    RendererBase.Clear(@Rgba);

    RenScan := TAggRendererScanLineAASolid.Create(RendererBase);
    try
      Rasterizer := TAggRasterizerScanlineClipIntegerSat.Create;
      try
        ScanLine := TAggScanLinePacked8.Create;
        try
          Bounds.Create(0, 0, Trunc(Width), Trunc(Height));
          Rasterizer.SetClipBox(@Bounds);

          // Pattern source. Must have an interface:
          // width() const
          // height() const
          // pixel(int x, int y) const
          // Any agg::renderer_base<> or derived
          // is good for the use as a source.
          //-----------------------------------
          PatternSource := TAggPatternSourceBrightnessToAlphaRgba8.Create(RenderingBufferImage[0]);

          PatternFilter := TAggPatternFilterBilinearRgba.Create; // Filtering functor

          // TAggLineImagePattern is the main container for the patterns. It creates
          // a copy of the patterns extended according to the needs of the filter.
          // TAggLineImagePattern can operate with arbitrary image width, but if the
          // width of the pattern is power of 2, it's better to use the modified
          // version TAggLineImagePatternPow2 because it works about 15-25 percent
          // faster than TAggLineImagePattern (because of using simple masking instead
          // of expensive mod operation).

          {
            typedef agg::line_image_pattern<agg::pattern_filter_bilinear_rgba8> pattern_type;
            typedef agg::renderer_base<pixfmt> base_ren_type;
            typedef agg::renderer_outline_image<base_ren_type, pattern_type> renderer_img_type;
            typedef agg::rasterizer_outline_aa<renderer_img_type, agg::LineCoord_sat> rasterizer_img_type;

            typedef agg::renderer_outline_aa<base_ren_type> renderer_line_type;
            typedef agg::rasterizer_outline_aa<renderer_line_type, agg::LineCoord_sat> rasterizer_line_type;
          }

          // -- Create with specifying the source
          // LineImagePattern := TAggLineImagePattern.Create(PatternFilter, Src);


          // -- Create uninitialized and set the source
          LineImagePattern := TAggLineImagePattern.Create(PatternFilter);

          RenImage := TAggRendererOutlineImage.Create(RendererBase, LineImagePattern);
          RasImage := TAggRasterizerOutlineAA.Create(RenImage);
          try
//            DrawCurve(LineImagePattern, RasImage, RenImage, PatternSource, FCurve[0].GetCurve);
            Profile := TAggLineProfileAA.Create;
            Profile.SmootherWidth := 10;
            Profile.SetWidth(8.0);

            RendererLine := TAggRendererOutlineAA.Create(RendererBase, Profile);
            Rgba.FromRgbInteger(0, 0, 127);
            RendererLine.SetColor(@Rgba);
            RasLine := TAggRasterizerOutlineAA.Create(RendererLine);
            RasLine.RoundCap := True;                   //optional
            //RasLine.LineJoin := outline_no_join);     //optional

            // Calculate the dilation value so that, the line caps were
            // drawn correctly.
            //---------------
            w2 := 9.0;//p1.height() / 2 + 2;


            // Set the clip box a bit bigger than you expect. You need it
            // to draw the clipped line caps correctly. The correct result
            // is achieved with raster clipping.
            //------------------------
            RenImage.ScaleX := FSliderScaleX.Value;
            RenImage.StartX := FSliderScaleX.Value;
//            RenImage.SetClipBox(50 - w2, 50 - w2, Width - 50 + w2, height - 50 + w2);
//            RendererLine.SetClipBox(50 - w2, 50 - w2, Width - 50 + w2, height - 50 + w2);

            // First, draw polyline without raster clipping just to show the idea
            //------------------------
            DrawPolyline(RasLine, RendererLine, FLine.GetPolygon, FLine.NumPoints);
            DrawPolyline(RasImage, RendererLine, FLine.GetPolygon, FLine.NumPoints);

            // Clear the area, almost opaque, but not completely
            //------------------------
            Rgba.White;
            RendererBase.BlendBar(0, 0, Trunc(Width), Trunc(Height), @Rgba, 200);


            // Set the raster clip box and then, draw again.
            // In reality there shouldn't be two calls above.
            // It's done only for demonstration
            //------------------------
            RendererBase.SetClipBox(50, 50, Trunc(Width - 50),
              Trunc(Height - 50));

            // This "copy_bar" is also for demonstration only
            //------------------------
            RendererBase.CopyBar(0, 0, Trunc(Width), Trunc(Height), @Rgba);

            // Finally draw polyline correctly clipped: We use double clipping,
            // first is vector clipping, with extended clip box, second is raster
            // clipping with normal clip box.
            //------------------------
            RenImage.ScaleX := FSliderScaleX.Value;
            RenImage.StartX := FSliderStartX.Value;
            DrawPolyline(RasLine, RendererLine, FLine.GetPolygon, FLine.NumPoints);
//            DrawPolyline(RasImage, RenImage, FLine.GetPolygon, FLine.NumPoints);


            // Reset clipping and draw the controls and stuff
            RendererBase.ResetClipping(True);

            FLine.LineWidth := 1 / FScale.GetScale;
            FLine.PointRadius := 5 / FScale.GetScale;

(*
            RenderControl(Rasterizer, ScanLine, RenScan, FLine);
            RenderControl(Rasterizer, ScanLine, RenScan, FSliderScaleX);
            RenderControl(Rasterizer, ScanLine, RenScan, FSliderStartX);


(*
            char buf[256];
            agg::gsv_text t;
            t.size(10.0);

            agg::conv_stroke<agg::gsv_text> pt(t);
            pt.width(1.5);
            pt.line_cap(agg::round_cap);

            const double* p = FLine.polygon();
            sprintf(buf, "Len=%.2f", agg::calc_distance(p[0], p[1], p[2], p[3]) * FScale.scale());

            t.start_point(10.0, 30.0);
            t.text(buf);

            ras.add_path(pt);
            ren.color(agg::rgba(0,0,0));
            agg::render_scanlines(ras, sl, ren);
*)

          finally
            PatternSource.Free;

            PatternFilter.Free;
            LineImagePattern.Free;
            RenImage.Free;
            RasImage.Free;
          end;
        finally
          ScanLine.Free;
        end;
      finally
        Rasterizer.Free;
      end;
    finally
      RenScan.Free;
    end;
  finally
    RendererBase.Free;
  end;
end;

procedure TAggApplication.OnKey(X, Y: Integer; Key: Cardinal;
  Flags: TMouseKeyboardFlags);
begin
  if (Key = Ord('+')) or (Key = Cardinal(kcPadPlus) then
  begin
    FScale.Translate(-X, -Y);
    FScale.Scale(1.1);
    FScale.Translate(X, Y);
    ForceRedraw;
  end;

  if (key = Ord('-')) or (key = Cardinal(kcPadMinus) then
  begin
    FScale.Translate(-X, -Y);
    FScale.Scale(1 / 1.1);
    FScale.Translate(X, Y);
    ForceRedraw;
  end;
end;

var
  Ext: AnsiString;

begin
  with TAggApplication.Create(pfBgr24, CFlipY) do
  try
    Caption := 'AGG Example. Clipping Lines with Image Patterns';

    if not LoadImage(0, '1') then
    begin
      Ext := ImageExtension;

      DisplayMessage(Format('There must be files 1%s', [Ext]));
    end
    else if Init(500, 450, [wfResize]) then
      Run;
  finally
    Free;
  end;
end.
