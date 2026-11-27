// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73490, helper codeunits 73490 and 73492, test codeunits 73491 and 73493
// Probe (AL Runner issues 9265 and 9264, with the places of 9268):
//   9265: X := FR.Value() with FR a Date, Time or DateTime field and X a number (no Variant in between). Sources: a blank and a set
//     value of each field (0D, 2026-01-15, 0T, 12:00:00, 0DT, 2026-01-15 12:00:00). Targets in a plain local: Integer, BigInteger,
//     Decimal, Duration, Option (A,B,C), Boolean, Byte, Char. Places of an Integer target: a var parameter, a by-value parameter (the
//     argument), a named return value, exit, a global, a record field, an array element, List.Add (of Integer, Decimal, BigInteger),
//     and Abs; the control is a Variant in between (V := FR.Value(); I := V). Not probed: I += FR.Value() and I -= FR.Value()
//     do not compile (AL0175 "Operator '+=' cannot be applied to operands of type 'Integer' and 'Joker'").
//   9264: FR.Value(X), FR.Value := X and FR.Validate(X) on a Date field with X an Integer of 0, 1, 31 or 32 (typed), a Variant holding
//     0, 1 or 31, a BigInteger 1 and a Decimal 1; and an Integer 1 into a Time and a DateTime field.
//   Each cell runs in a TryFunction on a fresh RecordRef and records "ok: <Format(result, 0, 9)>" (9264: the field's value) or
//   "E: <GetLastErrorText> | <GetLastErrorCode>". A 9265 test is <Source>_Targets or <Source>_Places; a 9264 test is named for its group.
//   Already pinned (FvcTemporalFields.al, var parameter shape, set values): Date, Time and DateTime into Integer and Decimal and
//   DateTime into BigInteger, Boolean and Duration; kept here as part of each source's row.
//   Observe round: every test ends with Observer.Finish(), which fails the test with the readings (OBSERVE:...); nothing is asserted yet.
// BC versions: 27, 28, 29 by CI
table 73490 "LT FVR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; IntT; Integer) { }
        field(4; DtF; DateTime) { }
        field(5; DateF; Date) { }
        field(6; TimeF; Time) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

// 9265: FieldRef.Value of a temporal field into a number.
codeunit 73490 "LT FVR Value Probe"
{
    var
        GlobalInt: Integer;

    // A RecordRef on the row table whose field FieldNo holds the source value.
    local procedure Source(var RR: RecordRef; var FR: FieldRef; Src: Text)
    begin
        RR.Open(Database::"LT FVR Row");
        case Src of
            'Date0':
                begin
                    FR := RR.Field(5);
                    FR.Value := 0D;
                end;
            'Date1':
                begin
                    FR := RR.Field(5);
                    FR.Value := 20260115D;
                end;
            'Time0':
                begin
                    FR := RR.Field(6);
                    FR.Value := 0T;
                end;
            'Time1':
                begin
                    FR := RR.Field(6);
                    FR.Value := 120000T;
                end;
            'DateTime0':
                begin
                    FR := RR.Field(4);
                    FR.Value := 0DT;
                end;
            'DateTime1':
                begin
                    FR := RR.Field(4);
                    FR.Value := CreateDateTime(20260115D, 120000T);
                end;
        end;
    end;

    local procedure Outcome(Ok: Boolean; Result: Text): Text
    var
        T: Text;
    begin
        if Ok then
            exit('ok: ' + Result);
        T := 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        ClearLastError();
        exit(T);
    end;

    local procedure AssignVar(var FR: FieldRef; var I: Integer)
    begin
        I := FR.Value();
    end;

    local procedure TakeInt(I: Integer): Text
    begin
        exit(Format(I, 0, 9));
    end;

    local procedure RetNamed(var FR: FieldRef) R: Integer
    begin
        R := FR.Value();
    end;

    local procedure RetExit(var FR: FieldRef): Integer
    begin
        exit(FR.Value());
    end;

    [TryFunction]
    local procedure TryTarget(var FR: FieldRef; Target: Text; var Result: Text)
    var
        XInteger: Integer;
        XBigInteger: BigInteger;
        XDecimal: Decimal;
        XDuration: Duration;
        XOption: Option A,B,C;
        XBoolean: Boolean;
        XByte: Byte;
        XChar: Char;
    begin
        case Target of
            'Integer':
                begin
                    XInteger := FR.Value();
                    Result := Format(XInteger, 0, 9);
                end;
            'BigInteger':
                begin
                    XBigInteger := FR.Value();
                    Result := Format(XBigInteger, 0, 9);
                end;
            'Decimal':
                begin
                    XDecimal := FR.Value();
                    Result := Format(XDecimal, 0, 9);
                end;
            'Duration':
                begin
                    XDuration := FR.Value();
                    Result := Format(XDuration, 0, 9);
                end;
            'Option':
                begin
                    XOption := FR.Value();
                    Result := Format(XOption, 0, 9);
                end;
            'Boolean':
                begin
                    XBoolean := FR.Value();
                    Result := Format(XBoolean, 0, 9);
                end;
            'Byte':
                begin
                    XByte := FR.Value();
                    Result := Format(XByte, 0, 9);
                end;
            'Char':
                begin
                    XChar := FR.Value();
                    Result := Format(XChar, 0, 9);
                end;
        end;
    end;

    [TryFunction]
    local procedure TryPlace(var FR: FieldRef; Place: Text; var Result: Text)
    var
        Row: Record "LT FVR Row";
        I: Integer;
        A: array[2] of Integer;
        LI: List of [Integer];
        LD: List of [Decimal];
        LB: List of [BigInteger];
        V: Variant;
    begin
        case Place of
            'var':
                begin
                    AssignVar(FR, I);
                    Result := Format(I, 0, 9);
                end;
            'argument':
                begin
                    Result := TakeInt(FR.Value());
                end;
            'named_return':
                begin
                    Result := Format(RetNamed(FR), 0, 9);
                end;
            'exit':
                begin
                    Result := Format(RetExit(FR), 0, 9);
                end;
            'global':
                begin
                    GlobalInt := FR.Value();
                    Result := Format(GlobalInt, 0, 9);
                end;
            'record_field':
                begin
                    Row.IntT := FR.Value();
                    Result := Format(Row.IntT, 0, 9);
                end;
            'array':
                begin
                    A[1] := FR.Value();
                    Result := Format(A[1], 0, 9);
                end;
            'list_integer':
                begin
                    LI.Add(FR.Value());
                    Result := Format(LI.Get(1), 0, 9);
                end;
            'list_decimal':
                begin
                    LD.Add(FR.Value());
                    Result := Format(LD.Get(1), 0, 9);
                end;
            'list_biginteger':
                begin
                    LB.Add(FR.Value());
                    Result := Format(LB.Get(1), 0, 9);
                end;
            'abs':
                begin
                    I := Abs(FR.Value());
                    Result := Format(I, 0, 9);
                end;
            'variant':
                begin
                    V := FR.Value();
                    I := V;
                    Result := Format(I, 0, 9);
                end;
        end;
    end;

    // One cell: a fresh RecordRef holding the source, then the target (plain local) or the place (Integer target).
    procedure TargetCell(var Observer: Codeunit "Probe Observer"; Src: Text; Target: Text)
    var
        RR: RecordRef;
        FR: FieldRef;
        Result: Text;
        Ok: Boolean;
    begin
        Source(RR, FR, Src);
        ClearLastError();
        Ok := TryTarget(FR, Target, Result);
        Observer.Observe(Target, Outcome(Ok, Result));
        RR.Close();
    end;

    procedure PlaceCell(var Observer: Codeunit "Probe Observer"; Src: Text; Place: Text)
    var
        RR: RecordRef;
        FR: FieldRef;
        Result: Text;
        Ok: Boolean;
    begin
        Source(RR, FR, Src);
        ClearLastError();
        Ok := TryPlace(FR, Place, Result);
        Observer.Observe(Place, Outcome(Ok, Result));
        RR.Close();
    end;
}

codeunit 73491 "LT FVR Value Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // A blank Date (0D) into each target, in a plain local.
    [Test]
    procedure Date0_Targets()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FVR Value Probe";
    begin
        Probe.TargetCell(Observer, 'Date0', 'Integer');
        Probe.TargetCell(Observer, 'Date0', 'BigInteger');
        Probe.TargetCell(Observer, 'Date0', 'Decimal');
        Probe.TargetCell(Observer, 'Date0', 'Duration');
        Probe.TargetCell(Observer, 'Date0', 'Option');
        Probe.TargetCell(Observer, 'Date0', 'Boolean');
        Probe.TargetCell(Observer, 'Date0', 'Byte');
        Probe.TargetCell(Observer, 'Date0', 'Char');
        Observer.Finish();
    end;

    // A blank Date (0D) into an Integer in each place.
    [Test]
    procedure Date0_Places()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FVR Value Probe";
    begin
        Probe.PlaceCell(Observer, 'Date0', 'var');
        Probe.PlaceCell(Observer, 'Date0', 'argument');
        Probe.PlaceCell(Observer, 'Date0', 'named_return');
        Probe.PlaceCell(Observer, 'Date0', 'exit');
        Probe.PlaceCell(Observer, 'Date0', 'global');
        Probe.PlaceCell(Observer, 'Date0', 'record_field');
        Probe.PlaceCell(Observer, 'Date0', 'array');
        Probe.PlaceCell(Observer, 'Date0', 'list_integer');
        Probe.PlaceCell(Observer, 'Date0', 'list_decimal');
        Probe.PlaceCell(Observer, 'Date0', 'list_biginteger');
        Probe.PlaceCell(Observer, 'Date0', 'abs');
        Probe.PlaceCell(Observer, 'Date0', 'variant');
        Observer.Finish();
    end;

    // The Date 2026-01-15 into each target, in a plain local.
    [Test]
    procedure Date1_Targets()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FVR Value Probe";
    begin
        Probe.TargetCell(Observer, 'Date1', 'Integer');
        Probe.TargetCell(Observer, 'Date1', 'BigInteger');
        Probe.TargetCell(Observer, 'Date1', 'Decimal');
        Probe.TargetCell(Observer, 'Date1', 'Duration');
        Probe.TargetCell(Observer, 'Date1', 'Option');
        Probe.TargetCell(Observer, 'Date1', 'Boolean');
        Probe.TargetCell(Observer, 'Date1', 'Byte');
        Probe.TargetCell(Observer, 'Date1', 'Char');
        Observer.Finish();
    end;

    // The Date 2026-01-15 into an Integer in each place.
    [Test]
    procedure Date1_Places()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FVR Value Probe";
    begin
        Probe.PlaceCell(Observer, 'Date1', 'var');
        Probe.PlaceCell(Observer, 'Date1', 'argument');
        Probe.PlaceCell(Observer, 'Date1', 'named_return');
        Probe.PlaceCell(Observer, 'Date1', 'exit');
        Probe.PlaceCell(Observer, 'Date1', 'global');
        Probe.PlaceCell(Observer, 'Date1', 'record_field');
        Probe.PlaceCell(Observer, 'Date1', 'array');
        Probe.PlaceCell(Observer, 'Date1', 'list_integer');
        Probe.PlaceCell(Observer, 'Date1', 'list_decimal');
        Probe.PlaceCell(Observer, 'Date1', 'list_biginteger');
        Probe.PlaceCell(Observer, 'Date1', 'abs');
        Probe.PlaceCell(Observer, 'Date1', 'variant');
        Observer.Finish();
    end;

    // A blank Time (0T) into each target, in a plain local.
    [Test]
    procedure Time0_Targets()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FVR Value Probe";
    begin
        Probe.TargetCell(Observer, 'Time0', 'Integer');
        Probe.TargetCell(Observer, 'Time0', 'BigInteger');
        Probe.TargetCell(Observer, 'Time0', 'Decimal');
        Probe.TargetCell(Observer, 'Time0', 'Duration');
        Probe.TargetCell(Observer, 'Time0', 'Option');
        Probe.TargetCell(Observer, 'Time0', 'Boolean');
        Probe.TargetCell(Observer, 'Time0', 'Byte');
        Probe.TargetCell(Observer, 'Time0', 'Char');
        Observer.Finish();
    end;

    // A blank Time (0T) into an Integer in each place.
    [Test]
    procedure Time0_Places()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FVR Value Probe";
    begin
        Probe.PlaceCell(Observer, 'Time0', 'var');
        Probe.PlaceCell(Observer, 'Time0', 'argument');
        Probe.PlaceCell(Observer, 'Time0', 'named_return');
        Probe.PlaceCell(Observer, 'Time0', 'exit');
        Probe.PlaceCell(Observer, 'Time0', 'global');
        Probe.PlaceCell(Observer, 'Time0', 'record_field');
        Probe.PlaceCell(Observer, 'Time0', 'array');
        Probe.PlaceCell(Observer, 'Time0', 'list_integer');
        Probe.PlaceCell(Observer, 'Time0', 'list_decimal');
        Probe.PlaceCell(Observer, 'Time0', 'list_biginteger');
        Probe.PlaceCell(Observer, 'Time0', 'abs');
        Probe.PlaceCell(Observer, 'Time0', 'variant');
        Observer.Finish();
    end;

    // The Time 12:00:00 into each target, in a plain local.
    [Test]
    procedure Time1_Targets()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FVR Value Probe";
    begin
        Probe.TargetCell(Observer, 'Time1', 'Integer');
        Probe.TargetCell(Observer, 'Time1', 'BigInteger');
        Probe.TargetCell(Observer, 'Time1', 'Decimal');
        Probe.TargetCell(Observer, 'Time1', 'Duration');
        Probe.TargetCell(Observer, 'Time1', 'Option');
        Probe.TargetCell(Observer, 'Time1', 'Boolean');
        Probe.TargetCell(Observer, 'Time1', 'Byte');
        Probe.TargetCell(Observer, 'Time1', 'Char');
        Observer.Finish();
    end;

    // The Time 12:00:00 into an Integer in each place.
    [Test]
    procedure Time1_Places()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FVR Value Probe";
    begin
        Probe.PlaceCell(Observer, 'Time1', 'var');
        Probe.PlaceCell(Observer, 'Time1', 'argument');
        Probe.PlaceCell(Observer, 'Time1', 'named_return');
        Probe.PlaceCell(Observer, 'Time1', 'exit');
        Probe.PlaceCell(Observer, 'Time1', 'global');
        Probe.PlaceCell(Observer, 'Time1', 'record_field');
        Probe.PlaceCell(Observer, 'Time1', 'array');
        Probe.PlaceCell(Observer, 'Time1', 'list_integer');
        Probe.PlaceCell(Observer, 'Time1', 'list_decimal');
        Probe.PlaceCell(Observer, 'Time1', 'list_biginteger');
        Probe.PlaceCell(Observer, 'Time1', 'abs');
        Probe.PlaceCell(Observer, 'Time1', 'variant');
        Observer.Finish();
    end;

    // A blank DateTime (0DT) into each target, in a plain local.
    [Test]
    procedure DateTime0_Targets()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FVR Value Probe";
    begin
        Probe.TargetCell(Observer, 'DateTime0', 'Integer');
        Probe.TargetCell(Observer, 'DateTime0', 'BigInteger');
        Probe.TargetCell(Observer, 'DateTime0', 'Decimal');
        Probe.TargetCell(Observer, 'DateTime0', 'Duration');
        Probe.TargetCell(Observer, 'DateTime0', 'Option');
        Probe.TargetCell(Observer, 'DateTime0', 'Boolean');
        Probe.TargetCell(Observer, 'DateTime0', 'Byte');
        Probe.TargetCell(Observer, 'DateTime0', 'Char');
        Observer.Finish();
    end;

    // A blank DateTime (0DT) into an Integer in each place.
    [Test]
    procedure DateTime0_Places()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FVR Value Probe";
    begin
        Probe.PlaceCell(Observer, 'DateTime0', 'var');
        Probe.PlaceCell(Observer, 'DateTime0', 'argument');
        Probe.PlaceCell(Observer, 'DateTime0', 'named_return');
        Probe.PlaceCell(Observer, 'DateTime0', 'exit');
        Probe.PlaceCell(Observer, 'DateTime0', 'global');
        Probe.PlaceCell(Observer, 'DateTime0', 'record_field');
        Probe.PlaceCell(Observer, 'DateTime0', 'array');
        Probe.PlaceCell(Observer, 'DateTime0', 'list_integer');
        Probe.PlaceCell(Observer, 'DateTime0', 'list_decimal');
        Probe.PlaceCell(Observer, 'DateTime0', 'list_biginteger');
        Probe.PlaceCell(Observer, 'DateTime0', 'abs');
        Probe.PlaceCell(Observer, 'DateTime0', 'variant');
        Observer.Finish();
    end;

    // The DateTime 2026-01-15 12:00:00 into each target, in a plain local.
    [Test]
    procedure DateTime1_Targets()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FVR Value Probe";
    begin
        Probe.TargetCell(Observer, 'DateTime1', 'Integer');
        Probe.TargetCell(Observer, 'DateTime1', 'BigInteger');
        Probe.TargetCell(Observer, 'DateTime1', 'Decimal');
        Probe.TargetCell(Observer, 'DateTime1', 'Duration');
        Probe.TargetCell(Observer, 'DateTime1', 'Option');
        Probe.TargetCell(Observer, 'DateTime1', 'Boolean');
        Probe.TargetCell(Observer, 'DateTime1', 'Byte');
        Probe.TargetCell(Observer, 'DateTime1', 'Char');
        Observer.Finish();
    end;

    // The DateTime 2026-01-15 12:00:00 into an Integer in each place.
    [Test]
    procedure DateTime1_Places()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FVR Value Probe";
    begin
        Probe.PlaceCell(Observer, 'DateTime1', 'var');
        Probe.PlaceCell(Observer, 'DateTime1', 'argument');
        Probe.PlaceCell(Observer, 'DateTime1', 'named_return');
        Probe.PlaceCell(Observer, 'DateTime1', 'exit');
        Probe.PlaceCell(Observer, 'DateTime1', 'global');
        Probe.PlaceCell(Observer, 'DateTime1', 'record_field');
        Probe.PlaceCell(Observer, 'DateTime1', 'array');
        Probe.PlaceCell(Observer, 'DateTime1', 'list_integer');
        Probe.PlaceCell(Observer, 'DateTime1', 'list_decimal');
        Probe.PlaceCell(Observer, 'DateTime1', 'list_biginteger');
        Probe.PlaceCell(Observer, 'DateTime1', 'abs');
        Probe.PlaceCell(Observer, 'DateTime1', 'variant');
        Observer.Finish();
    end;
}

// 9264: a number into a Date, Time or DateTime field through FieldRef.Value(X), FieldRef.Value := X and FieldRef.Validate(X).
codeunit 73492 "LT FVR Date Probe"
{
    local procedure Outcome(var FR: FieldRef; Ok: Boolean): Text
    var
        T: Text;
    begin
        if Ok then
            exit('ok: ' + Format(FR.Value, 0, 9));
        T := 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        ClearLastError();
        exit(T);
    end;

    [TryFunction]
    local procedure TryInt(var FR: FieldRef; Call: Text; X: Integer)
    begin
        case Call of
            'value':
                FR.Value(X);
            'assign':
                FR.Value := X;
            'validate':
                FR.Validate(X);
        end;
    end;

    // FR.Value(X), FR.Value := X and FR.Validate(X) on the field FieldNo, each on a fresh RecordRef; names <Name>_value, _assign, _validate.
    procedure CellsInt(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; Name: Text; X: Integer)
    var
        RR: RecordRef;
        FR: FieldRef;
        Call: Text;
        Ok: Boolean;
    begin
        foreach Call in Calls() do begin
            RR.Open(Database::"LT FVR Row");
            FR := RR.Field(FieldNo);
            ClearLastError();
            Ok := TryInt(FR, Call, X);
            Observer.Observe(Name + '_' + Call, Outcome(FR, Ok));
            RR.Close();
        end;
    end;

    [TryFunction]
    local procedure TryBig(var FR: FieldRef; Call: Text; X: BigInteger)
    begin
        case Call of
            'value':
                FR.Value(X);
            'assign':
                FR.Value := X;
            'validate':
                FR.Validate(X);
        end;
    end;

    // FR.Value(X), FR.Value := X and FR.Validate(X) on the field FieldNo, each on a fresh RecordRef; names <Name>_value, _assign, _validate.
    procedure CellsBig(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; Name: Text; X: BigInteger)
    var
        RR: RecordRef;
        FR: FieldRef;
        Call: Text;
        Ok: Boolean;
    begin
        foreach Call in Calls() do begin
            RR.Open(Database::"LT FVR Row");
            FR := RR.Field(FieldNo);
            ClearLastError();
            Ok := TryBig(FR, Call, X);
            Observer.Observe(Name + '_' + Call, Outcome(FR, Ok));
            RR.Close();
        end;
    end;

    [TryFunction]
    local procedure TryDec(var FR: FieldRef; Call: Text; X: Decimal)
    begin
        case Call of
            'value':
                FR.Value(X);
            'assign':
                FR.Value := X;
            'validate':
                FR.Validate(X);
        end;
    end;

    // FR.Value(X), FR.Value := X and FR.Validate(X) on the field FieldNo, each on a fresh RecordRef; names <Name>_value, _assign, _validate.
    procedure CellsDec(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; Name: Text; X: Decimal)
    var
        RR: RecordRef;
        FR: FieldRef;
        Call: Text;
        Ok: Boolean;
    begin
        foreach Call in Calls() do begin
            RR.Open(Database::"LT FVR Row");
            FR := RR.Field(FieldNo);
            ClearLastError();
            Ok := TryDec(FR, Call, X);
            Observer.Observe(Name + '_' + Call, Outcome(FR, Ok));
            RR.Close();
        end;
    end;

    [TryFunction]
    local procedure TryVar(var FR: FieldRef; Call: Text; X: Variant)
    begin
        case Call of
            'value':
                FR.Value(X);
            'assign':
                FR.Value := X;
            'validate':
                FR.Validate(X);
        end;
    end;

    // FR.Value(X), FR.Value := X and FR.Validate(X) on the field FieldNo, each on a fresh RecordRef; names <Name>_value, _assign, _validate.
    procedure CellsVar(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; Name: Text; X: Variant)
    var
        RR: RecordRef;
        FR: FieldRef;
        Call: Text;
        Ok: Boolean;
    begin
        foreach Call in Calls() do begin
            RR.Open(Database::"LT FVR Row");
            FR := RR.Field(FieldNo);
            ClearLastError();
            Ok := TryVar(FR, Call, X);
            Observer.Observe(Name + '_' + Call, Outcome(FR, Ok));
            RR.Close();
        end;
    end;

    local procedure Calls() Result: List of [Text]
    begin
        Result.Add('value');
        Result.Add('assign');
        Result.Add('validate');
    end;
}

codeunit 73493 "LT FVR Date Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // An Integer of 0, 1, 31 and 32 into the Date field.
    [Test]
    procedure DateField_TypedInteger()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FVR Date Probe";
    begin
        Probe.CellsInt(Observer, 5, 'int0', 0);
        Probe.CellsInt(Observer, 5, 'int1', 1);
        Probe.CellsInt(Observer, 5, 'int31', 31);
        Probe.CellsInt(Observer, 5, 'int32', 32);
        Observer.Finish();
    end;

    // A Variant holding the Integer 0, 1 and 31 into the Date field.
    [Test]
    procedure DateField_VariantInteger()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FVR Date Probe";
        V: Variant;
    begin
        V := 0;
        Probe.CellsVar(Observer, 5, 'var0', V);
        V := 1;
        Probe.CellsVar(Observer, 5, 'var1', V);
        V := 31;
        Probe.CellsVar(Observer, 5, 'var31', V);
        Observer.Finish();
    end;

    // A BigInteger 1 and a Decimal 1 into the Date field.
    [Test]
    procedure DateField_BigIntegerDecimal()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FVR Date Probe";
        B: BigInteger;
        D: Decimal;
    begin
        B := 1;
        D := 1;
        Probe.CellsBig(Observer, 5, 'big1', B);
        Probe.CellsDec(Observer, 5, 'dec1', D);
        Observer.Finish();
    end;

    // An Integer 1 into the Time and the DateTime field.
    [Test]
    procedure TimeDateTimeFields_Integer()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FVR Date Probe";
    begin
        Probe.CellsInt(Observer, 6, 'time_int1', 1);
        Probe.CellsInt(Observer, 4, 'datetime_int1', 1);
        Observer.Finish();
    end;
}
