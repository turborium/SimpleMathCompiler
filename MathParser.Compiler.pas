// copyright 2021-2021 crazzzypeter
// license GNU 3.0
unit MathParser.Compiler;

{$IFDEF FPC}{$MODE DELPHIUNICODE}{$ENDIF}
{$SCOPEDENUMS ON}

interface

uses
  Classes, SysUtils, Generics.Collections, MathParser.Types, MathParser.VirtualMachine;

type

  // Plus := '+'
  // Minus := '-'
  // Multiply := '*'
  // Divide := '/'

  // <Number> := <'0'..'9'>[.]<'0'..'9'>[e<['0'..'9']>] ...
  // <Primitive> := <'('><AddAndSub><')'> | <Number>
  // <MulAndDiv> := <Primitive> [<Multiply> | <Divide>] <Primitive> ...
  // <AddAndSub> := <MulAndDiv> [<Plus> | <Minus>] <MulAndDiv> ...

  TLogEvent = procedure (sender: TObject; str: string) of object;

  TTokenType = (Number, Plus, Minus, Multiply, Divide, Power, LeftBracket, RightBracket, &Function, Variable,
    Terminal);

  TMathCall = procedure() of object;

  TMathCompiler = class sealed
  private
    Expression: string;
    Code: TMathCode;
    Position: Integer;
    PrevPosition: Integer;
    Token: TTokenType;
    Value: Double;
    Identifier: string;
    StackLevel: Integer;
    CurentChar: Char;
    procedure NextChar;
    procedure NextToken;
    procedure SkipSpaces;
    procedure CompilePrimitive;
    procedure CompileAddAndSub;
    procedure CompileMulAndDiv;
    function CompileFunctionCall(const FunctionName: string): Boolean;
    procedure CompilePow;
    procedure RecursiveCall(const Func: TMathCall);
  public
    constructor Create(const ACode: TMathCode);
    destructor Destroy; override;
    procedure Compile(const AExpression: string);
  end;

implementation

uses
  Math;

const
  MaxStackLevel = 32;

  sClosingParenthesisExpected = 'Closing parenthesis expected';
  sPrimitiveExpected = 'Primitive expected';
  sMissingOperator = 'Missing operator';
  sUnmatchedRightParenthesis = 'Unmatched right parenthesis';
  sUnexpectedSymbol = 'Unexpected symbol';
  sBadNumber = 'Bad number';
  sDivisionByZero = 'Division by zero';
  sBadFunctionArgument = 'Bad function argument';
  sBadFunction = 'Bad function';
  sOverflow = 'Overflow';
  sInternalError = 'Internal error!';
  sStackOverflow = 'Stack overflow';
  sContantNotFound = 'Constant not found';

// helpers for opcodes

function MakeOpPushValue(const Value: Double): TOpcode;
begin
  Result.Kind := TOpcodeKind.PUSH;
  Result.Name := '%NOVAR%';
  Result.Value := Value;
end;

function MakeOpPushVariable(const Value: string): TOpcode;
begin
  Result.Kind := TOpcodeKind.PUSH_VAR;
  Result.Name := Value;
  Result.Value := $DEADC0DE;
end;

function MakeOpOperation(const Value: TOpcodeKind): TOpcode;
begin
  Result.Kind := Value;
  Result.Name := '%NOVAR%';
  Result.Value := $DEADC0DE;
end;

{ TMathCompiler }

procedure TMathCompiler.NextChar;
begin
  Position := Position + 1;
  CurentChar := PChar(Expression)[Position];
end;

procedure TMathCompiler.NextToken;
var
  TokenString: string;
begin
  SkipSpaces;

  PrevPosition := Position;

  case CurentChar of
    '0'..'9':
    begin
      // for ex: 12.34e+56
      // 12
      Token := TTokenType.Number;
      while CharInSet(CurentChar, ['0'..'9']) do
      begin
        TokenString := TokenString + CurentChar;
        NextChar;
      end;
      // .
      if CurentChar = '.' then
      begin
        TokenString := TokenString + CurentChar;
        NextChar;
      end;
      // 34
      while CharInSet(CurentChar, ['0'..'9']) do
      begin
        TokenString := TokenString + CurentChar;
        NextChar;
      end;
      // e
      if CharInSet(CurentChar, ['e', 'E']) then
      begin
        TokenString := TokenString + CurentChar;
        NextChar;
        // +/-
        if CharInSet(CurentChar, ['-', '+']) then
        begin
          TokenString := TokenString + CurentChar;
          NextChar;
        end;
        // 56
        if not CharInSet(CurentChar, ['0'..'9']) then
          raise Exception.Create(sBadNumber);// error
        while CharInSet(CurentChar, ['0'..'9']) do
        begin
          TokenString := TokenString + CurentChar;
          NextChar;
        end;
      end;

      if not TryStrToFloat(TokenString, Value,
        {$IFNDEF FPC}TFormatSettings.Invariant{$ELSE}DefaultFormatSettings{$ENDIF}) then
        raise EMathCompillerError.Create(PrevPosition, sBadNumber);// error
    end;
    '+':
    begin
      Token := TTokenType.Plus;
      NextChar;
    end;
    '-':
    begin
      Token := TTokenType.Minus;
      NextChar;
    end;
    '*':
    begin
      Token := TTokenType.Multiply;
      NextChar;
    end;
    '/':
    begin
      Token := TTokenType.Divide;
      NextChar;
    end;
    '^':
    begin
      Token := TTokenType.Power;
      NextChar;
    end;
    '(':
    begin
      Token := TTokenType.LeftBracket;
      NextChar;
    end;
    ')':
    begin
      Token := TTokenType.RightBracket;
      NextChar;
    end;
    'a'..'z', 'A'..'Z':
    begin
      Identifier := '';
      // abc
      while CharInSet(CurentChar, ['a'..'z', 'A'..'Z', '0'..'9']) do
      begin
        Identifier := Identifier + CurentChar;
        NextChar;
      end;
      // SkipSpaces;
      // (
      if CurentChar = '(' then
      begin
        Token := TTokenType.&Function;
        NextChar;
      end else
        Token := TTokenType.Variable;
    end;
    #0:
    begin
      Token := TTokenType.Terminal;
    end;
    else
      raise EMathCompillerError.Create(Position, sUnexpectedSymbol);// error
  end;
end;

procedure TMathCompiler.CompilePrimitive;
var
  FunctionName: string;
  FunctionPos: Integer;
begin
  //NextToken;
  case Token of
    // unary operators +/-
    TTokenType.Plus:
    begin
      NextToken;
      RecursiveCall(CompilePrimitive);
    end;
    TTokenType.Minus:
    begin
      NextToken;
      RecursiveCall(CompilePrimitive);
      Code.Add(MakeOpOperation(TOpcodeKind.NEG));
    end;
    // primitives
    TTokenType.Number:
    begin
      NextToken;
      //Result := Value;
      Code.Add(MakeOpPushValue(Value));
    end;
    TTokenType.LeftBracket:
    begin
      NextToken;
      RecursiveCall(CompileAddAndSub);
      if Token <> TTokenType.RightBracket then
        raise EMathCompillerError.Create(PrevPosition, sClosingParenthesisExpected);// error
      NextToken;
    end;
    TTokenType.&Function:
    begin
      FunctionName := UpperCase(Identifier);// hmmm...
      FunctionPos := PrevPosition;
      NextToken;
      RecursiveCall(CompileAddAndSub);
      if Token <> TTokenType.RightBracket then
        raise EMathCompillerError.Create(Position, sClosingParenthesisExpected);// error

      if not CompileFunctionCall(FunctionName) then
        raise EMathCompillerError.Create(FunctionPos, sBadFunction);

      NextToken;
    end;
    TTokenType.Variable:
    begin
      if UpperCase(Identifier) = 'PI' then
        Code.Add(MakeOpOperation(TOpcodeKind.PUSH_PI))
      else
        Code.Add(MakeOpPushVariable(UpperCase(Identifier)));
      NextToken;
    end
    else
      raise EMathCompillerError.Create(PrevPosition, sPrimitiveExpected);// error
  end;
end;

procedure TMathCompiler.CompilePow;
begin
  CompilePrimitive;

  while True do
  begin
    case Token of
      // ^
      TTokenType.Power:
      begin
        NextToken;
        RecursiveCall(CompilePow);
        Code.Add(MakeOpOperation(TOpcodeKind.POW));
      end;
      else
        break;
    end;
  end;
end;

procedure TMathCompiler.CompileMulAndDiv;
begin
  CompilePow;

  while True do
  begin
    case Token of
      // *
      TTokenType.Multiply:
      begin
        NextToken;
        CompilePow;
        Code.Add(MakeOpOperation(TOpcodeKind.MUL));
      end;
      // /
      TTokenType.Divide:
      begin
        NextToken;
        CompilePow;
        Code.Add(MakeOpOperation(TOpcodeKind.DIV));
      end;
      else
        break;
    end;
  end;
end;

procedure TMathCompiler.CompileAddAndSub;
begin
  CompileMulAndDiv;

  while True do
  begin
    case Token of
      // +
      TTokenType.Plus:
      begin
        NextToken;
        CompileMulAndDiv;
        Code.Add(MakeOpOperation(TOpcodeKind.ADD));
      end;
      // -
      TTokenType.Minus:
      begin
        NextToken;
        CompileMulAndDiv;
        Code.Add(MakeOpOperation(TOpcodeKind.SUB));
      end;
      else
        break;
    end;
  end;
end;

procedure TMathCompiler.Compile(const AExpression: string);
begin
  Code.Clear;
  Expression := AExpression;
  StackLevel := 0;
  Position := -1;// it's ok
  NextChar;

  // compile
  NextToken;
  CompileAddAndSub;

  // check errors
  if Token = TTokenType.RightBracket then
    raise EMathCompillerError.Create(PrevPosition, sUnmatchedRightParenthesis);// error

  if Token <> TTokenType.Terminal then
    raise EMathCompillerError.Create(PrevPosition, sMissingOperator);// error
end;

procedure TMathCompiler.RecursiveCall(const Func: TMathCall);
begin
  StackLevel := StackLevel + 1;
  if StackLevel > MaxStackLevel then
    raise EMathCompillerError.Create(PrevPosition, sStackOverflow);
  Func();
  StackLevel := StackLevel - 1;
end;

constructor TMathCompiler.Create(const ACode: TMathCode);
begin
  Code := ACode;
end;

destructor TMathCompiler.Destroy;
begin
  inherited;
end;

function TMathCompiler.CompileFunctionCall(const FunctionName: string): Boolean;
begin
  {  } if FunctionName = 'SQRT' then
    Code.Add(MakeOpOperation(TOpcodeKind.SQRT))
  else if FunctionName = 'SIN' then
    Code.Add(MakeOpOperation(TOpcodeKind.SIN))
  else if FunctionName = 'COS' then
    Code.Add(MakeOpOperation(TOpcodeKind.COS))
  else if FunctionName = 'TAN' then
    Code.Add(MakeOpOperation(TOpcodeKind.TAN))
  else if FunctionName = 'ARCSIN' then
    Code.Add(MakeOpOperation(TOpcodeKind.ASIN))
  else if FunctionName = 'ARCCOS' then
    Code.Add(MakeOpOperation(TOpcodeKind.ACOS))
  else if FunctionName = 'ARCTAN' then
    Code.Add(MakeOpOperation(TOpcodeKind.ATAN))
  else if FunctionName = 'LOG' then
    Code.Add(MakeOpOperation(TOpcodeKind.LOG))
  else if FunctionName = 'EXP' then
    Code.Add(MakeOpOperation(TOpcodeKind.EXP))
  else if FunctionName = 'ABS' then
    Code.Add(MakeOpOperation(TOpcodeKind.ABS))
  else if FunctionName = 'INT' then
    Code.Add(MakeOpOperation(TOpcodeKind.INT))
  else if FunctionName = 'FRAC' then
    Code.Add(MakeOpOperation(TOpcodeKind.FRAC))
  else
    Exit(False);

  Result := True;
end;

procedure TMathCompiler.SkipSpaces;
begin
  while CharInSet(CurentChar, [#9, ' ']) do
  begin
    NextChar;
  end;
end;

end.

