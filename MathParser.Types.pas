// copyright 2021-2021 crazzzypeter
// license GNU 3.0
unit MathParser.Types;

{$IFDEF FPC}{$MODE DELPHIUNICODE}{$ENDIF}
{$SCOPEDENUMS ON}

interface

uses
  Classes, SysUtils;

type
  EMathCompillerError = class(Exception)
  private
    FPosition: Integer;
  public
    constructor Create(const Position: Integer; const Message: string);
    property Position: Integer read FPosition;
  end;

  EVirtualMachineError = class(Exception)
    constructor Create(const Message: string);
  end;

implementation

{ EMathCompillerError }

constructor EMathCompillerError.Create(const Position: Integer; const Message: string);
begin
  inherited Create('Error: "' + Message + '" at ' + IntToStr(Position));
  FPosition := Position;
end;

{ EVirtualMachineError }

constructor EVirtualMachineError.Create(const Message: string);
begin
  inherited Create('Error: "' + Message + '" at runtime');
end;

end.
