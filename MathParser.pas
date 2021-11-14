unit MathParser;

interface

uses
  MathCompiller, MathVirtualMachine;

type
  TMathParser = class
  private
    Code: TMathCode;
    VariablesDict: TMathVariables;
    Compiller: TMathCompiller;
    VirtualMachine: TMathVirtualMachine;
    Expression: string;
    function GetVariable(const Name: string): Double;
    procedure SetVariable(const Name: string; const Value: Double);
  public
    constructor Create;
    destructor Destroy; override;
    // exp
    procedure CompileExpression(const AExpression: string);
    function Calculate: Double;
    // vars
    property Variables[const Name: string]: Double read GetVariable write SetVariable; default;
    procedure ClearAllVariables;
    procedure DeleteVariable(const Name: string);
    function TryGetVariable(const Name: string; out VariableValue: Double): Boolean;
    //
    function PrintState: string;
  end;

implementation

uses
  SysUtils, StrUtils;

{ TMathParser }

constructor TMathParser.Create;
begin
  Code := TMathCode.Create;
  VariablesDict := TMathVariables.Create;

  Compiller := TMathCompiller.Create(Code);
  VirtualMachine := TMathVirtualMachine.Create(Code, VariablesDict);
end;

destructor TMathParser.Destroy;
begin
  Code.Free;
  VariablesDict.Free;

  Compiller.Free;
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
  if Expression <> AExpression then
  begin
    Expression := AExpression;
    Compiller.Compile(Expression);
  end;
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

function TMathParser.PrintState: string;
var
  Key: string;
  First: Boolean;
begin
  // vars
  Result := '*** VARIABLES ***';
  First := True;
  for Key in VariablesDict.Keys do
  begin
    if First then
      Result := Result + sLineBreak;
    Result := Result + Key + ' = ' + FloatToStr(VariablesDict[Key], TFormatSettings.Invariant);
  end;
  //
  Result := Result + sLineBreak + '*** CODE ***' + sLineBreak;
  Result := Result + VirtualMachine.PrintCode;
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
