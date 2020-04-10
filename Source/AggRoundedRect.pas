unit AggRoundedRect;

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//  Anti-Grain Geometry (modernized Pascal fork, aka 'AggPasMod')             //
//    Maintained by Christian-W. Budde (Christian@pcjv.de)                    //
//    Copyright (c) 2012-2020                                                 //
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

interface

{$I AggCompiler.inc}

uses
  AggBasics,
  AggVertexSource,
  AggArc;

type
  TAggRoundedRect = class(TAggVertexSource)
  private
    FPoint: array [0..1] of TPointDouble;
    FRadius: array [0..3] of TPointDouble;

    FStatus: Cardinal;
    FArc: TAggArc;

    procedure SetApproximationScale(Value: Double);
    function GetApproximationScale: Double;
  public
    constructor Create; overload;
    constructor Create(X1, Y1, X2, Y2, R: Double); overload;
    destructor Destroy; override;

    procedure Rect(X1, Y1, X2, Y2: Double); overload;
    procedure Rect(Value: TRectDouble); overload;

    procedure Radius(R: Double); overload;
    procedure Radius(Rx, Ry: Double); overload;
    procedure Radius(Radius: TPointDouble); overload;
    procedure Radius(BottomX, BottomY, TopX, TopY: Double); overload;
    procedure Radius(Bottom, Top: TPointDouble); overload;
    procedure Radius(Rx1, Ry1, Rx2, Ry2, Rx3, Ry3, Rx4, Ry4: Double); overload;
    procedure Radius(Radius1, Radius2, Radius3, Radius4: TPointDouble); overload;

    procedure NormalizeRadius;

    procedure Rewind(PathID: Cardinal); override;
    function Vertex(X, Y: PDouble): Cardinal; override;

    property ApproximationScale: Double read GetApproximationScale write
      SetApproximationScale;
  end;

implementation


{ TAggRoundedRect }

constructor TAggRoundedRect.Create;
begin
  FPoint[0] := PointDouble(0);
  FPoint[1] := PointDouble(0);
  FRadius[0] := PointDouble(0);
  FRadius[1] := PointDouble(0);
  FRadius[2] := PointDouble(0);
  FRadius[3] := PointDouble(0);

  FStatus := 0;

  FArc := TAggArc.Create;
end;

constructor TAggRoundedRect.Create(X1, Y1, X2, Y2, R: Double);
begin
  Create;

  FPoint[0] := PointDouble(X1, Y1);
  FPoint[1] := PointDouble(X2, Y2);
  FRadius[0] := PointDouble(R);
  FRadius[1] := PointDouble(R);
  FRadius[2] := PointDouble(R);
  FRadius[3] := PointDouble(R);

  if X1 > X2 then
  begin
    FPoint[0].X := X2;
    FPoint[1].X := X1;
  end;

  if Y1 > Y2 then
  begin
    FPoint[0].Y := Y2;
    FPoint[1].Y := Y1;
  end;
end;

destructor TAggRoundedRect.Destroy;
begin
  FArc.Free;
  inherited;
end;

procedure TAggRoundedRect.Rect(X1, Y1, X2, Y2: Double);
begin
  FPoint[0] := PointDouble(X1, Y1);
  FPoint[1] := PointDouble(X2, Y2);

  if X1 > X2 then
  begin
    FPoint[0].X := X2;
    FPoint[1].X := X1;
  end;

  if Y1 > Y2 then
  begin
    FPoint[0].Y := Y2;
    FPoint[1].Y := Y1;
  end;
end;

procedure TAggRoundedRect.Rect(Value: TRectDouble);
begin
  FPoint[0] := PointDouble(Value.X1, Value.Y1);
  FPoint[1] := PointDouble(Value.X2, Value.Y2);

  if Value.X1 > Value.X2 then
  begin
    FPoint[0].X := Value.X2;
    FPoint[1].X := Value.X1;
  end;

  if Value.Y1 > Value.Y2 then
  begin
    FPoint[0].Y := Value.Y2;
    FPoint[1].Y := Value.Y1;
  end;
end;

procedure TAggRoundedRect.Radius(R: Double);
begin
  FRadius[0] := PointDouble(R);
  FRadius[1] := PointDouble(R);
  FRadius[2] := PointDouble(R);
  FRadius[3] := PointDouble(R);
end;

procedure TAggRoundedRect.Radius(Rx, Ry: Double);
begin
  FRadius[0] := PointDouble(Rx, Ry);
  FRadius[1] := PointDouble(Rx, Ry);
  FRadius[2] := PointDouble(Rx, Ry);
  FRadius[3] := PointDouble(Rx, Ry);
end;

procedure TAggRoundedRect.Radius(Radius: TPointDouble);
begin
  FRadius[0] := Radius;
  FRadius[1] := Radius;
  FRadius[2] := Radius;
  FRadius[3] := Radius;
end;

procedure TAggRoundedRect.Radius(BottomX, BottomY, TopX, TopY: Double);
begin
  FRadius[0] := PointDouble(BottomX, BottomY);
  FRadius[1] := PointDouble(BottomX, BottomY);
  FRadius[2] := PointDouble(TopX, TopY);
  FRadius[3] := PointDouble(TopX, TopY);
end;

procedure TAggRoundedRect.Radius(Bottom, Top: TPointDouble);
begin
  FRadius[0] := Bottom;
  FRadius[1] := Bottom;
  FRadius[2] := Top;
  FRadius[3] := Top;
end;

procedure TAggRoundedRect.Radius(Rx1, Ry1, Rx2, Ry2, Rx3, Ry3, Rx4, Ry4: Double);
begin
  FRadius[0] := PointDouble(Rx1, Ry1);
  FRadius[1] := PointDouble(Rx2, Ry2);
  FRadius[2] := PointDouble(Rx3, Ry3);
  FRadius[3] := PointDouble(Rx4, Ry4);
end;

procedure TAggRoundedRect.Radius(Radius1, Radius2, Radius3,
  Radius4: TPointDouble);
begin
  FRadius[0] := Radius1;
  FRadius[1] := Radius2;
  FRadius[2] := Radius3;
  FRadius[3] := Radius4;
end;

procedure TAggRoundedRect.NormalizeRadius;
var
  Delta: TPointDouble;
  K, T: Double;
begin
  Delta.X := Abs(FPoint[1].Y - FPoint[0].Y);
  Delta.Y := Abs(FPoint[1].X - FPoint[0].X);

  K := 1.0;
  try
    T := Delta.X / (FRadius[0].X + FRadius[1].X);

    if T < K then
      K := T;
  except
  end;

  try
    T := Delta.X / (FRadius[2].X + FRadius[3].X);

    if T < K then
      K := T;
  except
  end;

  try
    T := Delta.Y / (FRadius[0].Y + FRadius[1].Y);

    if T < K then
      K := T;
  except
  end;

  try
    T := Delta.Y / (FRadius[2].Y + FRadius[3].Y);

    if T < K then
      K := T;
  except
  end;

  if K < 1.0 then
  begin
    FRadius[0].X := FRadius[0].X * K;
    FRadius[0].Y := FRadius[0].Y * K;
    FRadius[1].X := FRadius[1].X * K;
    FRadius[1].Y := FRadius[1].Y * K;
    FRadius[2].X := FRadius[2].X * K;
    FRadius[2].Y := FRadius[2].Y * K;
    FRadius[3].X := FRadius[3].X * K;
    FRadius[3].Y := FRadius[3].Y * K;
  end;
end;

procedure TAggRoundedRect.SetApproximationScale(Value: Double);
begin
  FArc.ApproximationScale := Value;
end;

function TAggRoundedRect.GetApproximationScale: Double;
begin
  Result := FArc.ApproximationScale;
end;

procedure TAggRoundedRect.Rewind(PathID: Cardinal);
begin
  FStatus := 0;
end;

function TAggRoundedRect.Vertex(X, Y: PDouble): Cardinal;
var
  Cmd: Cardinal;
label
  _1, _2, _3, _4, _5, _6, _7, _8;
begin
  Cmd := CAggPathCmdStop;

  case FStatus of
    0:
      begin
        FArc.Init(FPoint[0].X + FRadius[0].X, FPoint[0].Y + FRadius[0].Y,
          FRadius[0].X, FRadius[0].Y, Pi, Pi + Pi * 0.5);
        FArc.Rewind(0);

        Inc(FStatus);

        goto _1;
      end;

    1:
    _1:
      begin
        Cmd := FArc.Vertex(X, Y);

        if IsStop(Cmd) then
        begin
          Inc(FStatus);
          goto _2;
        end
        else
        begin
          Result := Cmd;
          Exit;
        end;
      end;

    2:
    _2:
      begin
        FArc.Init(FPoint[1].X - FRadius[1].X, FPoint[0].Y + FRadius[1].Y,
          FRadius[1].X, FRadius[1].Y, Pi + Pi * 0.5, 0.0);
        FArc.Rewind(0);

        Inc(FStatus);
        goto _3;
      end;

    3:
    _3:
      begin
        Cmd := FArc.Vertex(X, Y);

        if IsStop(Cmd) then
        begin
          Inc(FStatus);
          goto _4;
        end
        else
        begin
          Result := CAggPathCmdLineTo;
          Exit;
        end;
      end;

    4:
    _4:
      begin
        FArc.Init(FPoint[1].X - FRadius[2].X, FPoint[1].Y - FRadius[2].Y,
          FRadius[2].X, FRadius[2].Y, 0.0, Pi * 0.5);
        FArc.Rewind(0);

        Inc(FStatus);
        goto _5;
      end;

    5:
    _5:
      begin
        Cmd := FArc.Vertex(X, Y);

        if IsStop(Cmd) then
        begin
          Inc(FStatus);
          goto _6;
        end
        else
        begin
          Result := CAggPathCmdLineTo;
          Exit;
        end;
      end;

    6:
    _6:
      begin
        FArc.Init(FPoint[0].X + FRadius[3].X, FPoint[1].Y - FRadius[3].Y,
          FRadius[3].X, FRadius[3].Y, Pi * 0.5, Pi);
        FArc.Rewind(0);

        Inc(FStatus);
        goto _7;
      end;

    7:
    _7:
      begin
        Cmd := FArc.Vertex(X, Y);

        if IsStop(Cmd) then
        begin
          Inc(FStatus);
          goto _8;
        end
        else
        begin
          Result := CAggPathCmdLineTo;
          Exit;
        end;
      end;

    8:
    _8:
      begin
        Cmd := CAggPathCmdEndPoly or CAggPathFlagsClose or CAggPathFlagsCcw;
        Inc(FStatus);
      end;
  end;

  Result := Cmd;
end;

end.
