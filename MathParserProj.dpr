program MathParserProj;

uses
  Vcl.Forms,
  Main in 'Main.pas' {FormMain},
  MathParser.Compiler in 'MathParser.Compiler.pas',
  Vcl.Themes,
  Vcl.Styles,
  MathParser.VirtualMachine in 'MathParser.VirtualMachine.pas',
  MathParser.Parser in 'MathParser.Parser.pas',
  MathParser.Types in 'MathParser.Types.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
