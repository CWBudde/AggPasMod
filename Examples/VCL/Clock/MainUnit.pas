unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls,
  AggBasics, AggColor, Agg2D, Agg2DControl, AggWin32Bmp;

type
  TFmClock = class(TForm)
    Agg2DControl: TAgg2DControl;
    Timer: TTimer;
    procedure TimerTimer(Sender: TObject);
    procedure Agg2DControlPaint(Sender: TObject);
    procedure Agg2DControlMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  protected
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
  public
    procedure PaintClock(Agg2D: TAgg2D);
  end;

var
  FmClock: TFmClock;

implementation

{$R *.dfm}

uses
  Math, dialogs;

procedure TFmClock.Agg2DControlPaint(Sender: TObject);
begin
  PaintClock(Agg2DControl.Agg2D);
end;

procedure TFmClock.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    Close;
end;

procedure TFmClock.Agg2DControlMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
const
  SC_DRAGMOVE = $F012;
begin
  if Button = mbLeft then
  begin
    ReleaseCapture;
    Perform(WM_SYSCOMMAND, SC_DRAGMOVE, 0);
  end;
end;

procedure TFmClock.PaintClock(Agg2D: TAgg2D);
var
  Radius: Double;
  AggColor: TAggColorRgba8;
  Index: Integer;
  Pos: TPointDouble;
  Sn, Cn, Temp: Double;
  Hour, Mn, Sec, MSec: Word;
begin
  with Agg2D, Agg2DControl do
  begin
    ClearAll(CRgba8White);
    Radius := 0.95 * Min(0.5 * Width, 0.5 * Height);

    AggColor.ABGR := $FFFFEAC0;
    FillColor := AggColor;
    AggColor.ABGR := $FF997A50;
    LineWidth := 4;
    LineColor := AggColor;
    Circle(0.5 * Width, 0.5 * Height, Radius);

    LineColor := CRgba8Black;
    SinCos(2 * Pi / 60, Sn, Cn);
    Pos.X := 0;
    Pos.Y := -1;
    LineWidth := 1;
    for Index := 0 to 59 do
    begin
      LineWidth := 2 + 2 * Integer(Index mod 5 = 0);

      Temp := 0.85 * (Radius - 10 * Integer(Index mod 5 = 0));
      Line(0.5 * Width + Pos.X * Temp,
        0.5 * Height + Pos.Y * Temp,
        0.5 * Width + 0.95 * Pos.X * Radius,
        0.5 * Height + 0.95 * Pos.Y * Radius);

      Temp := Pos.Y;
      Pos.Y := Pos.Y * Cn - Pos.X * Sn;
      Pos.X := Pos.X * Cn + Temp * Sn;
    end;

    DecodeTime(Now, Hour, Mn, Sec, MSec);

    SinCos(Hour * 2 * Pi / 24, Sn, Cn);
    LineWidth := 8;
    Line(0.5 * Width + Sn * Temp,
      0.5 * Height - Cn * Temp,
      0.5 * Width + 0.5 * Sn * Radius,
      0.5 * Height - 0.5 * Cn * Radius);

    LineWidth := 4;
    SinCos(Mn * 2 * Pi / 60, Sn, Cn);
    Line(0.5 * Width + Sn * Temp,
      0.5 * Height - Cn * Temp,
      0.5 * Width + 0.8 * Sn * Radius,
      0.5 * Height - 0.8 * Cn * Radius);

    FillColor := CRgba8Black;
    Circle(0.5 * Width, 0.5 * Height, 6);
  end;
end;

procedure TFmClock.TimerTimer(Sender: TObject);
begin
  Agg2DControl.Invalidate;
end;

procedure TFmClock.WMNCHitTest(var Message: TWMNCHitTest);
begin
  Message.Result := HTCAPTION;
end;

end.
