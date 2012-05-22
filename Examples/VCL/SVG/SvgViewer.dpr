program SvgViewer;

uses
  Forms,
  MainUnit in 'MainUnit.pas' {FmSvgViewer};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFmSvgViewer, FmSvgViewer);
  Application.Run;
end.

