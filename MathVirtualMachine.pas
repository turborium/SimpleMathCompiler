unit MathVirtualMachine;

{$SCOPEDENUMS ON}

interface

uses
  Classes, SysUtils, Generics.Collections;

type
  EVirtualMachineError = class(Exception)
  end;

  TOpcodeKind = (
    PUSH,
    PUSH_VAR,
    PUSH_PI,
    ADD, SUB, MUL, &DIV, POW,
    NEG,
    SQRT,
    SIN,
    COS,
    TAN,
    ASIN,
    ACOS,
    ATAN,
    LOG,
    EXP
  );

  TOpcode = record
    Kind: TOpcodeKind;
    // opt
    Value: Double;
    Name: string;
    function ToString: string;
  end;

  TMathCode = class(TList<TOpcode>);
  TMathVariables = class(TDictionary<string, Double>);

  TMathVirtualMachine = class
  private
    Stack: TStack<Double>;
    Code: TMathCode;
    Variables: TMathVariables;
  public
    constructor Create(const ACode: TMathCode; const AVariables: TMathVariables);
    destructor Destroy; override;
    function Execute: Double;
    function PrintCode: string;
  end;

implementation

uses
  Math;

{ TMathVM }

constructor TMathVirtualMachine.Create(const ACode: TMathCode; const AVariables: TMathVariables);
begin
  Stack := TStack<Double>.Create;
  Code := ACode;
  Variables := AVariables;
end;

destructor TMathVirtualMachine.Destroy;
begin
  Stack.Free;
  inherited;
end;

function TMathVirtualMachine.Execute: Double;
var
  Opcode: TOpcode;
  A, B, Res: Double;
begin
  Stack.Clear;

  for Opcode in Code do
  begin
    case Opcode.Kind of

      TOpcodeKind.PUSH:
      begin
        Stack.Push(Opcode.Value);
      end;

      TOpcodeKind.PUSH_VAR:
      begin
        if not Variables.TryGetValue(Opcode.Name, A) then
          raise EVirtualMachineError.Create('VARIABLE "' + Opcode.Name + '" NOT FOUND');
        Stack.Push(A);
      end;

      TOpcodeKind.PUSH_PI:
      begin
        Stack.Push(System.Pi);
      end;

      TOpcodeKind.ADD:
      begin
        B := Stack.Pop;
        A := Stack.Pop;
        Res := A + B;
        Stack.Push(Res);
      end;

      TOpcodeKind.SUB:
      begin
        B := Stack.Pop;
        A := Stack.Pop;
        Res := A - B;
        Stack.Push(Res);
      end;

      TOpcodeKind.MUL:
      begin
        B := Stack.Pop;
        A := Stack.Pop;
        Res := A * B;
        Stack.Push(Res);
      end;

      TOpcodeKind.DIV:
      begin
        B := Stack.Pop;
        A := Stack.Pop;
        if B = 0.0 then
          raise EVirtualMachineError.Create('DIV BY ZERO');
        Res := A / B;
        Stack.Push(Res);
      end;

      TOpcodeKind.POW:
      begin
        B := Stack.Pop;
        A := Stack.Pop;
        Res := Math.Power(A, B);
        Stack.Push(Res);
      end;

      TOpcodeKind.NEG:
      begin
        A := Stack.Pop;
        Res := -A;
        Stack.Push(Res);
      end;

      TOpcodeKind.SQRT:
      begin
        A := Stack.Pop;
        if A < 0 then
          raise EVirtualMachineError.Create('BAD SQRT ARGUMENT');
        Res := System.Sqrt(A);
        Stack.Push(Res);
      end;

      TOpcodeKind.SIN:
      begin
        A := Stack.Pop;
        Res := System.Sin(A);
        Stack.Push(Res);
      end;

      TOpcodeKind.COS:
      begin
        A := Stack.Pop;
        Res := System.Cos(A);
        Stack.Push(Res);
      end;

      TOpcodeKind.TAN:
      begin
        A := Stack.Pop;
        Res := Math.Tan(A);
        Stack.Push(Res);
      end;

      TOpcodeKind.ASIN:
      begin
        A := Stack.Pop;
        if (A < -1) or (A > 1) then
          raise EVirtualMachineError.Create('BAD ASIN ARGUMENT');
        Res := Math.ArcSin(A);
        Stack.Push(Res);
      end;

      TOpcodeKind.ACOS:
      begin
        A := Stack.Pop;
        if (A < -1) or (A > 1) then
          raise EVirtualMachineError.Create('BAD ACOS ARGUMENT');
        Res := Math.ArcCos(A);
        Stack.Push(Res);
      end;

      TOpcodeKind.ATAN:
      begin
        A := Stack.Pop;
        Res := System.ArcTan(A);
        Stack.Push(Res);
      end;

      TOpcodeKind.LOG:
      begin
        A := Stack.Pop;
        if (A <= 0) then
          raise EVirtualMachineError.Create('BAD LOG ARGUMENT');
        Res := Math.Log10(A);
        Stack.Push(Res);
      end;

      TOpcodeKind.EXP:
      begin
        A := Stack.Pop;
        Res := System.Exp(A);
        Stack.Push(Res);
      end;

      else
        raise EVirtualMachineError.Create('BAD OPCODE KIND');
    end;
  end;

  if Stack.Count <> 1 then
    raise EVirtualMachineError.Create('STACK ERROR');

  Result := Stack.Peek;
end;

function TMathVirtualMachine.PrintCode: string;
var
  I: Integer;
begin
  for I := 0 to Code.Count - 1 do
  begin
    Result := Result + Code[I].ToString;
    if I <> Code.Count - 1 then
      Result := Result + sLineBreak;
  end;
end;

{ TOpcode }

function TOpcode.ToString: string;
begin
    case Kind of

      TOpcodeKind.PUSH:
        Result := 'PUSH ' + FloatToStr(Value, TFormatSettings.Invariant);

      TOpcodeKind.PUSH_VAR:
        Result := 'PUSH_VAR "' + Name + '"';

      TOpcodeKind.PUSH_PI:
        Result := 'PUSH_PI';

      TOpcodeKind.ADD:
        Result := 'ADD';

      TOpcodeKind.SUB:
        Result := 'SUB';

      TOpcodeKind.MUL:
        Result := 'MUL';

      TOpcodeKind.&DIV:
        Result := 'DIV';

      TOpcodeKind.POW:
        Result := 'POW';

      TOpcodeKind.NEG:
        Result := 'NEG';

      TOpcodeKind.SQRT:
        Result := 'SQRT';

      TOpcodeKind.SIN:
        Result := 'SIN';

      TOpcodeKind.COS:
        Result := 'COS';

      TOpcodeKind.TAN:
        Result := 'TAN';

      TOpcodeKind.ASIN:
        Result := 'ASIN';

      TOpcodeKind.ACOS:
        Result := 'ACOS';

      TOpcodeKind.ATAN:
        Result := 'ATAN';

      TOpcodeKind.LOG:
        Result := 'LOG';

      TOpcodeKind.EXP:
        Result := 'EXP';

      else
        raise Exception.Create('BAD OPCODE KIND');
    end;
end;

end.
