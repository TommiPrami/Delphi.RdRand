program Delphi.RdRnd.Demo;

uses
  Vcl.Forms,
  DRRForm.Main in 'DRRForm.Main.pas' {DRRMainForm},
  Delphi.RdRnd in '..\Source\Delphi.RdRnd.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDRRMainForm, DRRMainForm);
  Application.Run;
end.
