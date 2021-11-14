// copyright 2021-2021 crazzzypeter
// license GNU 3.0
unit MathParser.Parser;

{$IFDEF FPC}{$MODE DELPHIUNICODE}{$ENDIF}
{$SCOPEDENUMS ON}

interface

uses
  MathParser.Types, MathParser.Compiler, MathParser.VirtualMachine;

type
  TMathParser = class
  private
    Code: TMathCode;
    VariablesDict: TMathVariables;
    Compiler: TMathCompiler;
    VirtualMachine: TMathVirtualMachine;
    FExpression: string;
    function GetVariable(const Name: string): Double;
    procedure SetVariable(const Name: string; const Value: Double);
  public
    constructor Create;
    destructor Destroy; override;
    // exp
    procedure CompileExpression(const AExpression: string);
    function Calculate: Double;
    property Expression: string read FExpression;
    // vars
    property Variables[const Name: string]: Double read GetVariable write SetVariable; default;
    procedure ClearAllVariables;
    procedure DefineVariable(const Name: string; const Value: Double);
    procedure DeleteVariable(const Name: string);
    function TryGetVariable(const Name: string; out VariableValue: Double): Boolean;
    // debug
    function PrintVariables: string;
    function PrintCode: string;
  end;

implementation

uses
  SysUtils, StrUtils;

{ TMathParser }

constructor TMathParser.Create;
begin
  Code := TMathCode.Create;
  VariablesDict := TMathVariables.Create;

  Compiler := TMathCompiler.Create(Code);
  VirtualMachine := TMathVirtualMachine.Create(Code, VariablesDict);
end;

destructor TMathParser.Destroy;
begin
  Code.Free;
  VariablesDict.Free;

  Compiler.Free;
  VirtualMachine.Free;
  inherited;
end;

function TMathParser.Calculate: Double;
begin
  Result := VirtualMachine.Execute;
end;

procedure TMathParser.ClearAllVariables;
begin
  VariablesDict.Clear;
end;

procedure TMathParser.CompileExpression(const AExpression: string);
begin
  FExpression := AExpression;
  Compiler.Compile(FExpression);
end;

procedure TMathParser.DefineVariable(const Name: string; const Value: Double);
begin
  VariablesDict.AddOrSetValue(SysUtils.UpperCase(Name), Value);
end;

procedure TMathParser.DeleteVariable(const Name: string);
begin
  if VariablesDict.ContainsKey(SysUtils.UpperCase(Name)) then
  begin
    VariablesDict.Remove(SysUtils.UpperCase(Name));
  end else
    raise Exception.Create('Variable "' + Name +'" not found');
end;

function TMathParser.GetVariable(const Name: string): Double;
begin
  if not TryGetVariable(Name, Result) then
    raise Exception.Create('Variable "' + Name +'" not found');
end;

function TMathParser.PrintCode: string;
begin
  Result := VirtualMachine.PrintCode;
end;

function TMathParser.PrintVariables: string;
var
  I: Integer;
  Key: string;
begin
  I := 0;
  for Key in VariablesDict.Keys do
  begin
    Result := Result + Key + ' = ' + FloatToStr(VariablesDict[Key], TFormatSettings.Invariant);
    if I <> VariablesDict.Keys.Count - 1 then
      Result := Result + sLineBreak;
    I := I + 1;
  end;
end;

procedure TMathParser.SetVariable(const Name: string; const Value: Double);
begin
  VariablesDict.AddOrSetValue(SysUtils.UpperCase(Name), Value);
end;

function TMathParser.TryGetVariable(const Name: string; out VariableValue: Double): Boolean;
begin
  if VariablesDict.ContainsKey(SysUtils.UpperCase(Name)) then
  begin
    VariableValue := VariablesDict[SysUtils.UpperCase(Name)];
    Result := True;
  end else
    Result := False;
end;

end.
