program DelphiLogo;

uses
  FMX.Forms,
  FMX.Canvas.AggPas in '..\..\..\Source\FireMonkey\FMX.Canvas.AggPas.pas',
  MainUnit in 'MainUnit.pas' {FmDelphiLogo};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFmDelphiLogo, FmDelphiLogo);
  Application.Run;
end.

