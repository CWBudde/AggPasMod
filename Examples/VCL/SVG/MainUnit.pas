unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  AggControlVCL;

type
  TFmSvgViewer = class(TForm)
    AggSVG: TAggSVG;
    OpenDialog: TOpenDialog;
    procedure FormShow(Sender: TObject);
    procedure AggSVGMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  end;

var
  FmSvgViewer: TFmSvgViewer;

implementation

uses
  Math;

{$R *.dfm}

procedure TFmSvgViewer.AggSVGMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Invalidate;
end;

procedure TFmSvgViewer.FormShow(Sender: TObject);
var
  FileName: TFileName;
begin
  FileName := ExpandFileName(ParamStr(1));
  if not FileExists(FileName) then
    if OpenDialog.Execute then
      FileName := OpenDialog.FileName;

  if FileExists(FileName) then
  begin
    AggSVG.LoadFromFile(FileName);
(*
    ClientWidth := Round(Abs(AggSVG.Bounds.X2 - AggSVG.Bounds.X1));
    ClientHeight := Round(Abs(AggSVG.Bounds.Y2 - AggSVG.Bounds.Y1));
*)
    ClientWidth := Round(Max(AggSVG.Bounds.X1, AggSVG.Bounds.X2));
    ClientHeight := Round(Max(AggSVG.Bounds.Y1, AggSVG.Bounds.Y2));
  end;
end;

end.

