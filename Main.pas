unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, MathParser, MathCompiller, MathVirtualMachine,
  System.Diagnostics;

type
  TFormMain = class(TForm)
    EditExpression: TEdit;
    ButtonExecute: TButton;
    MemoLog: TMemo;
    ButtonBenchmark: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonExecuteClick(Sender: TObject);
    procedure ButtonBenchmarkClick(Sender: TObject);
  private
    Parser: TMathParser;
    procedure ParserLog(sender: TObject; str: string);
  public
  end;

var
  FormMain: TFormMain;

implementation

uses
  StrUtils, Math;

{$R *.dfm}

procedure TFormMain.ButtonBenchmarkClick(Sender: TObject);
const
  Iterations = 1000000;
  Exp = 'SIN(X) + (COS(Y) * EXP(6) + 23 - 8) * 10';
  //Exp = 'SIN(X) + (COS(Y) * EXP(6) + 23 - 8) * 10 + X * 0.2 + 0.1 * (X * 0.545 + X * 0.245 + X * 0.765 + Y + 23 + 219 + 93.0)';
var
  I: Integer;
  Ans: Double;
  Stopwath: TStopwatch;
begin
  MemoLog.Clear;

  ParserLog(self, 'Exp: ' + Exp);

  Parser['X'] := 10;
  Parser['Y'] := 50;
  Parser.CompileExpression(Exp);
  ParserLog(Self, Parser.PrintState);

  Stopwath := TStopwatch.StartNew;
  Ans := 0;
  for I := 0 to Iterations - 1 do
  begin
    Ans := Ans * 0.1 + Parser.Calculate;
    Parser['X'] := Parser['X'] + 0.1;
  end;
  Stopwath.Stop;

  ParserLog(self, 'Ans: ' + FloatToStr(Ans, TFormatSettings.Invariant));
  ParserLog(self, 'Time: ' + IntToStr(Stopwath.ElapsedMilliseconds) + ' at ' +
    IntToStr(Iterations) + ' iterations!');
end;

procedure TFormMain.ButtonExecuteClick(Sender: TObject);
var
  Ans: Double;
begin
  MemoLog.Clear;
  try
    Parser.CompileExpression(EditExpression.Text);
    Parser['X'] := 10;
    Parser['Y'] := 100;
    Parser['Z'] := 1000;

    ParserLog(Self, Parser.PrintState);
    Ans := Parser.Calculate;

    ParserLog(self, 'Ans: ' + FloatToStr(Ans, TFormatSettings.Invariant));
  except
    on E: EMathCompillerError do
    begin
      ParserLog(Self, 'COMPILE ERROR');
      ParserLog(Self, ' 0123456789012345678901234567890123456789');
      ParserLog(Self, '"' + EditExpression.Text + '_"');
      ParserLog(Self, ' ' + DupeString(' ', E.Position) + '^');
      ParserLog(Self, E.Message);
    end;
    on E: EVirtualMachineError do
    begin
      ParserLog(Self, 'VM ERROR');
      ParserLog(Self, E.Message);
    end;
  end;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  Parser := TMathParser.Create;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  Parser.Free;
end;

procedure TFormMain.ParserLog(sender: TObject; str: string);
begin
  MemoLog.Lines.Add(str);
end;

end.
