program CompileX11;

{ skip }

uses
  Math,
  SysUtils,
  CTypes,
  {$IFNDEF FPC}
  Libc,
  {$ELSE}
  baseunix,
  unix,
  {$ENDIF}
  X,
  Xlib,
  Xutil,
  Xatom,
  Keysym;

begin
  Writeln('For compilation of AggPas on Linux X11 we need the following units:');
  Writeln('  Math');
  Writeln('  SysUtils');
  Writeln('  CTypes');
  Writeln('  X');
  Writeln('  Xlib');
  Writeln('  Xutil');
  Writeln('  Xatom');
  Writeln('  keysym');
  {$IFNDEF FPC}
  Writeln('  libc');
  {$ELSE}
  Writeln('  baseunix');
  Writeln('  unix');
  {$ENDIF}
end.
