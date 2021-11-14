program MathParserProj;

uses
  Vcl.Forms,
  Main in 'Main.pas' {FormMain},
  MathCompiller in 'MathCompiller.pas',
  Vcl.Themes,
  Vcl.Styles,
  MathVirtualMachine in 'MathVirtualMachine.pas',
  MathParser in 'MathParser.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
