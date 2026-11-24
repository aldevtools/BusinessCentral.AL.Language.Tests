// Helper of the format-length probes (not a test codeunit): Format of one typed value with a length, and optionally a format number
// (N >= 0) or a format string, inside a TryFunction, so a raised error is recorded instead of failing the test.
// The result is the text in brackets ([...] shows the padding), or ERR followed by the error text and code.
codeunit 96388 "FLN Fmt"
{
    var
        Got: Text;

    local procedure Done(Ok: Boolean): Text
    var
        Result: Text;
    begin
        if Ok then
            exit('[' + Got + ']');
        Result := 'ERR ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    // Format(V, L) when N < 0, else Format(V, L, N).
    procedure Date(V: Date; L: Integer; N: Integer): Text
    begin
        exit(Done(TryDate(V, L, N)));
    end;

    // Format(V, L, S).
    procedure DateS(V: Date; L: Integer; S: Text): Text
    begin
        exit(Done(TryDateS(V, L, S)));
    end;

    [TryFunction]
    local procedure TryDate(V: Date; L: Integer; N: Integer)
    begin
        Got := '';
        if N < 0 then
            Got := Format(V, L)
        else
            Got := Format(V, L, N);
    end;

    [TryFunction]
    local procedure TryDateS(V: Date; L: Integer; S: Text)
    begin
        Got := '';
        Got := Format(V, L, S);
    end;

    // Format(V, L) when N < 0, else Format(V, L, N).
    procedure DateTime(V: DateTime; L: Integer; N: Integer): Text
    begin
        exit(Done(TryDateTime(V, L, N)));
    end;

    // Format(V, L, S).
    procedure DateTimeS(V: DateTime; L: Integer; S: Text): Text
    begin
        exit(Done(TryDateTimeS(V, L, S)));
    end;

    [TryFunction]
    local procedure TryDateTime(V: DateTime; L: Integer; N: Integer)
    begin
        Got := '';
        if N < 0 then
            Got := Format(V, L)
        else
            Got := Format(V, L, N);
    end;

    [TryFunction]
    local procedure TryDateTimeS(V: DateTime; L: Integer; S: Text)
    begin
        Got := '';
        Got := Format(V, L, S);
    end;

    // Format(V, L) when N < 0, else Format(V, L, N).
    procedure Duration(V: Duration; L: Integer; N: Integer): Text
    begin
        exit(Done(TryDuration(V, L, N)));
    end;

    // Format(V, L, S).
    procedure DurationS(V: Duration; L: Integer; S: Text): Text
    begin
        exit(Done(TryDurationS(V, L, S)));
    end;

    [TryFunction]
    local procedure TryDuration(V: Duration; L: Integer; N: Integer)
    begin
        Got := '';
        if N < 0 then
            Got := Format(V, L)
        else
            Got := Format(V, L, N);
    end;

    [TryFunction]
    local procedure TryDurationS(V: Duration; L: Integer; S: Text)
    begin
        Got := '';
        Got := Format(V, L, S);
    end;

    // Format(V, L) when N < 0, else Format(V, L, N).
    procedure Char(V: Char; L: Integer; N: Integer): Text
    begin
        exit(Done(TryChar(V, L, N)));
    end;

    // Format(V, L, S).
    procedure CharS(V: Char; L: Integer; S: Text): Text
    begin
        exit(Done(TryCharS(V, L, S)));
    end;

    [TryFunction]
    local procedure TryChar(V: Char; L: Integer; N: Integer)
    begin
        Got := '';
        if N < 0 then
            Got := Format(V, L)
        else
            Got := Format(V, L, N);
    end;

    [TryFunction]
    local procedure TryCharS(V: Char; L: Integer; S: Text)
    begin
        Got := '';
        Got := Format(V, L, S);
    end;

    // Format(V, L) when N < 0, else Format(V, L, N).
    procedure Byte(V: Byte; L: Integer; N: Integer): Text
    begin
        exit(Done(TryByte(V, L, N)));
    end;

    // Format(V, L, S).
    procedure ByteS(V: Byte; L: Integer; S: Text): Text
    begin
        exit(Done(TryByteS(V, L, S)));
    end;

    [TryFunction]
    local procedure TryByte(V: Byte; L: Integer; N: Integer)
    begin
        Got := '';
        if N < 0 then
            Got := Format(V, L)
        else
            Got := Format(V, L, N);
    end;

    [TryFunction]
    local procedure TryByteS(V: Byte; L: Integer; S: Text)
    begin
        Got := '';
        Got := Format(V, L, S);
    end;

    // Format(V, L) when N < 0, else Format(V, L, N).
    procedure BigInteger(V: BigInteger; L: Integer; N: Integer): Text
    begin
        exit(Done(TryBigInteger(V, L, N)));
    end;

    // Format(V, L, S).
    procedure BigIntegerS(V: BigInteger; L: Integer; S: Text): Text
    begin
        exit(Done(TryBigIntegerS(V, L, S)));
    end;

    [TryFunction]
    local procedure TryBigInteger(V: BigInteger; L: Integer; N: Integer)
    begin
        Got := '';
        if N < 0 then
            Got := Format(V, L)
        else
            Got := Format(V, L, N);
    end;

    [TryFunction]
    local procedure TryBigIntegerS(V: BigInteger; L: Integer; S: Text)
    begin
        Got := '';
        Got := Format(V, L, S);
    end;

    // Format(V, L) when N < 0, else Format(V, L, N).
    procedure Time(V: Time; L: Integer; N: Integer): Text
    begin
        exit(Done(TryTime(V, L, N)));
    end;

    // Format(V, L, S).
    procedure TimeS(V: Time; L: Integer; S: Text): Text
    begin
        exit(Done(TryTimeS(V, L, S)));
    end;

    [TryFunction]
    local procedure TryTime(V: Time; L: Integer; N: Integer)
    begin
        Got := '';
        if N < 0 then
            Got := Format(V, L)
        else
            Got := Format(V, L, N);
    end;

    [TryFunction]
    local procedure TryTimeS(V: Time; L: Integer; S: Text)
    begin
        Got := '';
        Got := Format(V, L, S);
    end;

    // Format(V, L) when N < 0, else Format(V, L, N).
    procedure Code(V: Code[20]; L: Integer; N: Integer): Text
    begin
        exit(Done(TryCode(V, L, N)));
    end;

    // Format(V, L, S).
    procedure CodeS(V: Code[20]; L: Integer; S: Text): Text
    begin
        exit(Done(TryCodeS(V, L, S)));
    end;

    [TryFunction]
    local procedure TryCode(V: Code[20]; L: Integer; N: Integer)
    begin
        Got := '';
        if N < 0 then
            Got := Format(V, L)
        else
            Got := Format(V, L, N);
    end;

    [TryFunction]
    local procedure TryCodeS(V: Code[20]; L: Integer; S: Text)
    begin
        Got := '';
        Got := Format(V, L, S);
    end;

    // Format(V, L) when N < 0, else Format(V, L, N).
    procedure Guid(V: Guid; L: Integer; N: Integer): Text
    begin
        exit(Done(TryGuid(V, L, N)));
    end;

    // Format(V, L, S).
    procedure GuidS(V: Guid; L: Integer; S: Text): Text
    begin
        exit(Done(TryGuidS(V, L, S)));
    end;

    [TryFunction]
    local procedure TryGuid(V: Guid; L: Integer; N: Integer)
    begin
        Got := '';
        if N < 0 then
            Got := Format(V, L)
        else
            Got := Format(V, L, N);
    end;

    [TryFunction]
    local procedure TryGuidS(V: Guid; L: Integer; S: Text)
    begin
        Got := '';
        Got := Format(V, L, S);
    end;

    // Format(V, L) when N < 0, else Format(V, L, N).
    procedure Integer(V: Integer; L: Integer; N: Integer): Text
    begin
        exit(Done(TryInteger(V, L, N)));
    end;

    // Format(V, L, S).
    procedure IntegerS(V: Integer; L: Integer; S: Text): Text
    begin
        exit(Done(TryIntegerS(V, L, S)));
    end;

    [TryFunction]
    local procedure TryInteger(V: Integer; L: Integer; N: Integer)
    begin
        Got := '';
        if N < 0 then
            Got := Format(V, L)
        else
            Got := Format(V, L, N);
    end;

    [TryFunction]
    local procedure TryIntegerS(V: Integer; L: Integer; S: Text)
    begin
        Got := '';
        Got := Format(V, L, S);
    end;

    // Format(V, L) when N < 0, else Format(V, L, N).
    procedure Decimal(V: Decimal; L: Integer; N: Integer): Text
    begin
        exit(Done(TryDecimal(V, L, N)));
    end;

    // Format(V, L, S).
    procedure DecimalS(V: Decimal; L: Integer; S: Text): Text
    begin
        exit(Done(TryDecimalS(V, L, S)));
    end;

    [TryFunction]
    local procedure TryDecimal(V: Decimal; L: Integer; N: Integer)
    begin
        Got := '';
        if N < 0 then
            Got := Format(V, L)
        else
            Got := Format(V, L, N);
    end;

    [TryFunction]
    local procedure TryDecimalS(V: Decimal; L: Integer; S: Text)
    begin
        Got := '';
        Got := Format(V, L, S);
    end;

    // Format(V, L) when N < 0, else Format(V, L, N).
    procedure Text(V: Text; L: Integer; N: Integer): Text
    begin
        exit(Done(TryText(V, L, N)));
    end;

    // Format(V, L, S).
    procedure TextS(V: Text; L: Integer; S: Text): Text
    begin
        exit(Done(TryTextS(V, L, S)));
    end;

    [TryFunction]
    local procedure TryText(V: Text; L: Integer; N: Integer)
    begin
        Got := '';
        if N < 0 then
            Got := Format(V, L)
        else
            Got := Format(V, L, N);
    end;

    [TryFunction]
    local procedure TryTextS(V: Text; L: Integer; S: Text)
    begin
        Got := '';
        Got := Format(V, L, S);
    end;
    // Format(V, L) when N < 0, else Format(V, L, N).
    procedure Boolean(V: Boolean; L: Integer; N: Integer): Text
    begin
        exit(Done(TryBoolean(V, L, N)));
    end;

    // Format(V, L, S).
    procedure BooleanS(V: Boolean; L: Integer; S: Text): Text
    begin
        exit(Done(TryBooleanS(V, L, S)));
    end;

    [TryFunction]
    local procedure TryBoolean(V: Boolean; L: Integer; N: Integer)
    begin
        Got := '';
        if N < 0 then
            Got := Format(V, L)
        else
            Got := Format(V, L, N);
    end;

    [TryFunction]
    local procedure TryBooleanS(V: Boolean; L: Integer; S: Text)
    begin
        Got := '';
        Got := Format(V, L, S);
    end;
}
