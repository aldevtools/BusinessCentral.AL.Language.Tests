// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-validate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93630, enum 93632, codeunit 93631 (writer Y67, gap cycle 6 follow-up)
// Probe: FieldRef.Validate(Variant) and FieldRef.Value := Variant with a Variant that holds an Integer, a Decimal, a BigInteger, a Boolean, a
//   Date, a Time, a DateTime, a Text (a number, other text, empty), a Code, an Option, an Enum, a Guid or a Duration, into a field of each type
//   (Text, Code, Integer, Decimal, BigInteger, Boolean, Date, Time, DateTime, Option, Enum, Guid, Duration). Per cell: the value of the field
//   (Format(.., 0, 9)) and how many times its OnValidate ran after Validate, and the value after FieldRef.Value :=; or the error text and code.
// BC versions: 27, 28, 29

enum 93632 "LT Y67 FV Kind"
{
    Extensible = false;

    value(0; One) { }
    value(1; Two) { }
    value(5; Five) { }
}

table 93630 "LT Y67 FV Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30])
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(3; Cod; Code[20])
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(4; Int; Integer)
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(5; Dec; Decimal)
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(6; Big; BigInteger)
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(7; Bool; Boolean)
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(8; D; Date)
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(9; T; Time)
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(10; DT; DateTime)
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(11; Opt; Option)
        {
            OptionMembers = Alpha,Beta,Gamma;

            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(12; En; Enum "LT Y67 FV Kind")
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(13; G; Guid)
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(14; Dur; Duration)
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(15; Hits; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 93631 "LT Y67 FV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryValidate(var FRef: FieldRef; V: Variant)
    begin
        FRef.Validate(V);
    end;

    [TryFunction]
    local procedure TryAssign(var FRef: FieldRef; V: Variant)
    begin
        FRef.Value := V;
    end;

    local procedure Source(Index: Integer; var V: Variant; var Name: Text)
    var
        Big: BigInteger;
        Cd: Code[10];
        Op: Option Alpha,Beta,Gamma;
        Kind: Enum "LT Y67 FV Kind";
        Gd: Guid;
        Du: Duration;
    begin
        case Index of
            1:
                begin
                V := 42;
                Name := 'integer 42';
                end;
            2:
                begin
                V := -3;
                Name := 'integer -3';
                end;
            3:
                begin
                V := 2.5;
                Name := 'decimal 2.5';
                end;
            4:
                begin
                Evaluate(Big, '5000000000');
                V := Big;
                Name := 'biginteger';
                end;
            5:
                begin
                V := true;
                Name := 'boolean true';
                end;
            6:
                begin
                V := 20260115D;
                Name := 'date 20260115D';
                end;
            7:
                begin
                V := 120000T;
                Name := 'time 120000T';
                end;
            8:
                begin
                V := CreateDateTime(20260115D, 120000T);
                Name := 'datetime';
                end;
            9:
                begin
                V := '42';
                Name := 'text 42';
                end;
            10:
                begin
                V := 'abc';
                Name := 'text abc';
                end;
            11:
                begin
                Cd := 'C1';
                V := Cd;
                Name := 'code C1';
                end;
            12:
                begin
                Op := Op::Beta;
                V := Op;
                Name := 'option 1';
                end;
            13:
                begin
                V := Kind::Two;
                Name := 'enum Two';
                end;
            14:
                begin
                Gd := '{12345678-1234-1234-1234-123456789012}';
                V := Gd;
                Name := 'guid';
                end;
            15:
                begin
                Du := 1500;
                V := Du;
                Name := 'duration 1500';
                end;
            16:
                begin
                V := '';
                Name := 'text empty';
                end;
        end;
    end;

    // The long fixed tails and namespace prefixes of the texts are written as tags so that an observation stays short.
    local procedure Short(ErrText: Text): Text
    begin
        ErrText := ErrText.Replace('Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.', '<datehelp>');
        ErrText := ErrText.Replace('Microsoft.Dynamics.Nav.Runtime.', '<ns>');
        exit(ErrText);
    end;

    local procedure Cell(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; Index: Integer)
    var
        Row: Record "LT Y67 FV Row";
        RecRef: RecordRef;
        FRef: FieldRef;
        V: Variant;
        Name: Text;
        Result: Text;
    begin
        Source(Index, V, Name);
        RecRef.GetTable(Row);
        FRef := RecRef.Field(FieldNo);
        ClearLastError();
        if TryValidate(FRef, V) then
            Result := 'validate=' + Format(FRef.Value, 0, 9) + ' hits=' + Format(RecRef.Field(15).Value, 0, 9)
        else
            Result := 'validate error:' + Short(GetLastErrorText()) + '|' + GetLastErrorCode();
        Clear(Row);
        RecRef.GetTable(Row);
        FRef := RecRef.Field(FieldNo);
        ClearLastError();
        if TryAssign(FRef, V) then
            Result += ' ; assign=' + Format(FRef.Value, 0, 9) + ' hits=' + Format(RecRef.Field(15).Value, 0, 9)
        else
            Result += ' ; assign error:' + Short(GetLastErrorText()) + '|' + GetLastErrorCode();
        Observer.Observe(Name, Result);
    end;

    local procedure Into(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; First: Integer; Last: Integer)
    var
        i: Integer;
    begin
        for i := First to Last do
            Cell(Observer, FieldNo, i);
    end;

    [Test]
    procedure Validate_Into_Txt_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 2, 1, 8);
        Observer.Expect('integer 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('integer -3', 'validate=-3 hits=1 ; assign=-3 hits=0');
        Observer.Expect('decimal 2.5', 'validate=2.5 hits=1 ; assign=2.5 hits=0');
        Observer.Expect('biginteger', 'validate=5000000000 hits=1 ; assign=5000000000 hits=0');
        Observer.Expect('boolean true', 'validate=Yes hits=1 ; assign=Yes hits=0');
        Observer.Expect('date 20260115D', 'validate=01/15/26 hits=1 ; assign=01/15/26 hits=0');
        Observer.Expect('time 120000T', 'validate=12:00:00 PM hits=1 ; assign=12:00:00 PM hits=0');
        Observer.Expect('datetime', 'validate=01/15/26 12:00 PM hits=1 ; assign=01/15/26 12:00 PM hits=0');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_Txt_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 2, 9, 16);
        Observer.Expect('text 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('text abc', 'validate=abc hits=1 ; assign=abc hits=0');
        Observer.Expect('code C1', 'validate=C1 hits=1 ; assign=C1 hits=0');
        Observer.Expect('option 1', 'validate=Beta hits=1 ; assign=Beta hits=0');
        Observer.Expect('enum Two', 'validate=Two hits=1 ; assign=Two hits=0');
        Observer.Expect('guid', 'validate error:The length of the string is 38, but it must be less than or equal to 30 characters. Value: {12345678-1234-1234-1234-123456789012}|StringLengthExceeded ; assign error:The length of the string is 38, but it must be less than or equal to 30 characters. Value: {12345678-1234-1234-1234-123456789012}|StringLengthExceeded');
        Observer.Expect('duration 1500', 'validate=1 second 500 milliseconds hits=1 ; assign=1 second 500 milliseconds hits=0');
        Observer.Expect('text empty', 'validate= hits=1 ; assign= hits=0');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_Cod_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 3, 1, 8);
        Observer.Expect('integer 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('integer -3', 'validate=-3 hits=1 ; assign=-3 hits=0');
        Observer.Expect('decimal 2.5', 'validate=2.5 hits=1 ; assign=2.5 hits=0');
        Observer.Expect('biginteger', 'validate=5000000000 hits=1 ; assign=5000000000 hits=0');
        Observer.Expect('boolean true', 'validate=YES hits=1 ; assign=YES hits=0');
        Observer.Expect('date 20260115D', 'validate=01/15/26 hits=1 ; assign=01/15/26 hits=0');
        Observer.Expect('time 120000T', 'validate=12:00:00 PM hits=1 ; assign=12:00:00 PM hits=0');
        Observer.Expect('datetime', 'validate=01/15/26 12:00 PM hits=1 ; assign=01/15/26 12:00 PM hits=0');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_Cod_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 3, 9, 16);
        Observer.Expect('text 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('text abc', 'validate=ABC hits=1 ; assign=ABC hits=0');
        Observer.Expect('code C1', 'validate=C1 hits=1 ; assign=C1 hits=0');
        Observer.Expect('option 1', 'validate=BETA hits=1 ; assign=BETA hits=0');
        Observer.Expect('enum Two', 'validate=TWO hits=1 ; assign=TWO hits=0');
        Observer.Expect('guid', 'validate error:The length of the string is 38, but it must be less than or equal to 20 characters. Value: {12345678-1234-1234-1234-123456789012}|StringLengthExceeded ; assign error:The length of the string is 38, but it must be less than or equal to 20 characters. Value: {12345678-1234-1234-1234-123456789012}|StringLengthExceeded');
        Observer.Expect('duration 1500', 'validate error:The length of the string is 25, but it must be less than or equal to 20 characters. Value: 1 second 500 milliseconds|StringLengthExceeded ; assign error:The length of the string is 25, but it must be less than or equal to 20 characters. Value: 1 second 500 milliseconds|StringLengthExceeded');
        Observer.Expect('text empty', 'validate= hits=1 ; assign= hits=0');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_Int_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 4, 1, 8);
        Observer.Expect('integer 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('integer -3', 'validate=-3 hits=1 ; assign=-3 hits=0');
        Observer.Expect('decimal 2.5', 'validate error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int32.|ConversionCast ; assign error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int32.|ConversionCast');
        Observer.Expect('biginteger', 'validate error:Arithmetic operation resulted in an overflow.|AL:Overflow ; assign error:Arithmetic operation resulted in an overflow.|AL:Overflow');
        Observer.Expect('boolean true', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Expect('date 20260115D', 'validate=1479993 hits=1 ; assign=1479993 hits=0');
        Observer.Expect('time 120000T', 'validate=43200001 hits=1 ; assign=43200001 hits=0');
#if BC28PLUS
        Observer.Expect('datetime', 'validate error:The value "01/15/26 12:00 PM" can''t be evaluated into type Integer.|Evaluate:Conversion ; assign error:The value "01/15/26 12:00 PM" can''t be evaluated into type Integer.|Evaluate:Conversion');
#else
        Observer.Expect('datetime', 'validate error:Unable to convert from <ns>NavDateTime to System.Int32.|Conversion ; assign error:Unable to convert from <ns>NavDateTime to System.Int32.|Conversion');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_Int_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 4, 9, 16);
        Observer.Expect('text 42', 'validate=42 hits=1 ; assign=42 hits=0');
#if BC28PLUS
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type Integer.|Evaluate:Format ; assign error:The value "abc" can''t be evaluated into type Integer.|Evaluate:Format');
#else
        Observer.Expect('text abc', 'validate error:The type NavInteger is unknown.|NotSupportedType ; assign error:The type NavInteger is unknown.|NotSupportedType');
#endif
#if BC28PLUS
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type Integer.|Evaluate:Format ; assign error:The value "C1" can''t be evaluated into type Integer.|Evaluate:Format');
#else
        Observer.Expect('code C1', 'validate error:The type NavInteger is unknown.|NotSupportedType ; assign error:The type NavInteger is unknown.|NotSupportedType');
#endif
        Observer.Expect('option 1', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Expect('enum Two', 'validate=1 hits=1 ; assign=1 hits=0');
#if BC28PLUS
        Observer.Expect('guid', 'validate error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Integer.|Evaluate:Conversion ; assign error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Integer.|Evaluate:Conversion');
#else
        Observer.Expect('guid', 'validate error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion ; assign error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion');
#endif
        Observer.Expect('duration 1500', 'validate=1500 hits=1 ; assign=1500 hits=0');
#if BC28PLUS
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type Integer.|Evaluate:Format ; assign error:The value "" can''t be evaluated into type Integer.|Evaluate:Format');
#else
        Observer.Expect('text empty', 'validate error:The type NavInteger is unknown.|NotSupportedType ; assign error:The type NavInteger is unknown.|NotSupportedType');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_Dec_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 5, 1, 8);
        Observer.Expect('integer 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('integer -3', 'validate=-3 hits=1 ; assign=-3 hits=0');
        Observer.Expect('decimal 2.5', 'validate=2.5 hits=1 ; assign=2.5 hits=0');
        Observer.Expect('biginteger', 'validate=5000000000 hits=1 ; assign=5000000000 hits=0');
        Observer.Expect('boolean true', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Expect('date 20260115D', 'validate=1479993 hits=1 ; assign=1479993 hits=0');
        Observer.Expect('time 120000T', 'validate=43200001 hits=1 ; assign=43200001 hits=0');
        Observer.Expect('datetime', 'validate=63935697600001 hits=1 ; assign=63935697600001 hits=0');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_Dec_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 5, 9, 16);
        Observer.Expect('text 42', 'validate=42 hits=1 ; assign=42 hits=0');
#if BC28PLUS
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type Decimal.|Evaluate:Format ; assign error:The value "abc" can''t be evaluated into type Decimal.|Evaluate:Format');
#else
        Observer.Expect('text abc', 'validate error:The type NavDecimal is unknown.|NotSupportedType ; assign error:The type NavDecimal is unknown.|NotSupportedType');
#endif
#if BC28PLUS
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type Decimal.|Evaluate:Format ; assign error:The value "C1" can''t be evaluated into type Decimal.|Evaluate:Format');
#else
        Observer.Expect('code C1', 'validate error:The type NavDecimal is unknown.|NotSupportedType ; assign error:The type NavDecimal is unknown.|NotSupportedType');
#endif
        Observer.Expect('option 1', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Expect('enum Two', 'validate=1 hits=1 ; assign=1 hits=0');
#if BC28PLUS
        Observer.Expect('guid', 'validate error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Decimal.|Evaluate:Conversion ; assign error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Decimal.|Evaluate:Conversion');
#else
        Observer.Expect('guid', 'validate error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion ; assign error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion');
#endif
        Observer.Expect('duration 1500', 'validate=1500 hits=1 ; assign=1500 hits=0');
#if BC28PLUS
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type Decimal.|Evaluate:Format ; assign error:The value "" can''t be evaluated into type Decimal.|Evaluate:Format');
#else
        Observer.Expect('text empty', 'validate error:The type NavDecimal is unknown.|NotSupportedType ; assign error:The type NavDecimal is unknown.|NotSupportedType');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_Big_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 6, 1, 8);
        Observer.Expect('integer 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('integer -3', 'validate=-3 hits=1 ; assign=-3 hits=0');
        Observer.Expect('decimal 2.5', 'validate error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int64.|ConversionCast ; assign error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int64.|ConversionCast');
        Observer.Expect('biginteger', 'validate=5000000000 hits=1 ; assign=5000000000 hits=0');
        Observer.Expect('boolean true', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Expect('date 20260115D', 'validate=1479993 hits=1 ; assign=1479993 hits=0');
        Observer.Expect('time 120000T', 'validate=43200001 hits=1 ; assign=43200001 hits=0');
        Observer.Expect('datetime', 'validate=63935697600001 hits=1 ; assign=63935697600001 hits=0');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_Big_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 6, 9, 16);
        Observer.Expect('text 42', 'validate=42 hits=1 ; assign=42 hits=0');
#if BC28PLUS
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type BigInteger.|Evaluate:Format ; assign error:The value "abc" can''t be evaluated into type BigInteger.|Evaluate:Format');
#else
        Observer.Expect('text abc', 'validate error:The type NavBigInteger is unknown.|NotSupportedType ; assign error:The type NavBigInteger is unknown.|NotSupportedType');
#endif
#if BC28PLUS
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type BigInteger.|Evaluate:Format ; assign error:The value "C1" can''t be evaluated into type BigInteger.|Evaluate:Format');
#else
        Observer.Expect('code C1', 'validate error:The type NavBigInteger is unknown.|NotSupportedType ; assign error:The type NavBigInteger is unknown.|NotSupportedType');
#endif
        Observer.Expect('option 1', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Expect('enum Two', 'validate=1 hits=1 ; assign=1 hits=0');
#if BC28PLUS
        Observer.Expect('guid', 'validate error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type BigInteger.|Evaluate:Conversion ; assign error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type BigInteger.|Evaluate:Conversion');
#else
        Observer.Expect('guid', 'validate error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion ; assign error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion');
#endif
        Observer.Expect('duration 1500', 'validate=1500 hits=1 ; assign=1500 hits=0');
#if BC28PLUS
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type BigInteger.|Evaluate:Format ; assign error:The value "" can''t be evaluated into type BigInteger.|Evaluate:Format');
#else
        Observer.Expect('text empty', 'validate error:The type NavBigInteger is unknown.|NotSupportedType ; assign error:The type NavBigInteger is unknown.|NotSupportedType');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_Bool_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 7, 1, 8);
        Observer.Expect('integer 42', 'validate=true hits=1 ; assign=true hits=0');
        Observer.Expect('integer -3', 'validate=true hits=1 ; assign=true hits=0');
        Observer.Expect('decimal 2.5', 'validate error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int32.|ConversionCast ; assign error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int32.|ConversionCast');
        Observer.Expect('biginteger', 'validate error:Arithmetic operation resulted in an overflow.|AL:Overflow ; assign error:Arithmetic operation resulted in an overflow.|AL:Overflow');
        Observer.Expect('boolean true', 'validate=true hits=1 ; assign=true hits=0');
        Observer.Expect('date 20260115D', 'validate=true hits=1 ; assign=true hits=0');
        Observer.Expect('time 120000T', 'validate=true hits=1 ; assign=true hits=0');
#if BC28PLUS
        Observer.Expect('datetime', 'validate error:The value "01/15/26 12:00 PM" can''t be evaluated into type Boolean.|Evaluate:Conversion ; assign error:The value "01/15/26 12:00 PM" can''t be evaluated into type Boolean.|Evaluate:Conversion');
#else
        Observer.Expect('datetime', 'validate error:Unable to convert from <ns>NavDateTime to System.Int32.|Conversion ; assign error:Unable to convert from <ns>NavDateTime to System.Int32.|Conversion');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_Bool_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 7, 9, 16);
        Observer.Expect('text 42', 'validate=true hits=1 ; assign=true hits=0');
#if BC28PLUS
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type Boolean.|Evaluate:Format ; assign error:The value "abc" can''t be evaluated into type Boolean.|Evaluate:Format');
#else
        Observer.Expect('text abc', 'validate error:The type NavBoolean is unknown.|NotSupportedType ; assign error:The type NavBoolean is unknown.|NotSupportedType');
#endif
#if BC28PLUS
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type Boolean.|Evaluate:Format ; assign error:The value "C1" can''t be evaluated into type Boolean.|Evaluate:Format');
#else
        Observer.Expect('code C1', 'validate error:The type NavBoolean is unknown.|NotSupportedType ; assign error:The type NavBoolean is unknown.|NotSupportedType');
#endif
        Observer.Expect('option 1', 'validate=true hits=1 ; assign=true hits=0');
        Observer.Expect('enum Two', 'validate=true hits=1 ; assign=true hits=0');
#if BC28PLUS
        Observer.Expect('guid', 'validate error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Boolean.|Evaluate:Conversion ; assign error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Boolean.|Evaluate:Conversion');
#else
        Observer.Expect('guid', 'validate error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion ; assign error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion');
#endif
        Observer.Expect('duration 1500', 'validate=true hits=1 ; assign=true hits=0');
#if BC28PLUS
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type Boolean.|Evaluate:Format ; assign error:The value "" can''t be evaluated into type Boolean.|Evaluate:Format');
#else
        Observer.Expect('text empty', 'validate error:The type NavBoolean is unknown.|NotSupportedType ; assign error:The type NavBoolean is unknown.|NotSupportedType');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_D_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 8, 1, 8);
#if BC28PLUS
        Observer.Expect('integer 42', 'validate error:The format of the Date ''42'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The format of the Date ''42'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion');
#else
        Observer.Expect('integer 42', 'validate error:Unable to convert from <ns>NavInteger to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavInteger to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('integer -3', 'validate error:The format of the Date ''-3'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The format of the Date ''-3'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion');
#else
        Observer.Expect('integer -3', 'validate error:Unable to convert from <ns>NavInteger to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavInteger to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('decimal 2.5', 'validate error:The format of the Date ''2.5'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The format of the Date ''2.5'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion');
#else
        Observer.Expect('decimal 2.5', 'validate error:Unable to convert from <ns>NavDecimal to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavDecimal to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('biginteger', 'validate error:The format of the Date ''5000000000'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The format of the Date ''5000000000'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion');
#else
        Observer.Expect('biginteger', 'validate error:Unable to convert from <ns>NavBigInteger to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavBigInteger to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('boolean true', 'validate error:The format of the Date ''Yes'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The format of the Date ''Yes'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion');
#else
        Observer.Expect('boolean true', 'validate error:Unable to convert from <ns>NavBoolean to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavBoolean to System.DateTime.|Conversion');
#endif
        Observer.Expect('date 20260115D', 'validate=2026-01-15 hits=1 ; assign=2026-01-15 hits=0');
        Observer.Expect('time 120000T', 'validate error:The date is not valid.|DateInvalid ; assign error:The date is not valid.|DateInvalid');
        Observer.Expect('datetime', 'validate error:The date is not valid.|DateInvalid ; assign error:The date is not valid.|DateInvalid');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_D_B1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 8, 9, 12);
#if BC28PLUS
        Observer.Expect('text 42', 'validate error:The format of the Date ''42'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The format of the Date ''42'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion');
#else
        Observer.Expect('text 42', 'validate error:Unable to convert from <ns>NavText to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavText to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('text abc', 'validate error:The format of the Date ''abc'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The format of the Date ''abc'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion');
#else
        Observer.Expect('text abc', 'validate error:Unable to convert from <ns>NavText to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavText to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('code C1', 'validate error:The format of the Date ''C1'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The format of the Date ''C1'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion');
#else
        Observer.Expect('code C1', 'validate error:Unable to convert from <ns>NavCode to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavCode to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('option 1', 'validate error:The format of the Date ''Beta'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The format of the Date ''Beta'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion');
#else
        Observer.Expect('option 1', 'validate error:Unable to convert from <ns>NavOption to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavOption to System.DateTime.|Conversion');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_D_B2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 8, 13, 16);
#if BC28PLUS
        Observer.Expect('enum Two', 'validate error:The format of the Date ''Two'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The format of the Date ''Two'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion');
#else
        Observer.Expect('enum Two', 'validate error:Unable to convert from <ns>NavOption to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavOption to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('guid', 'validate error:The format of the Date ''{12345678-1234-1234-1234-123456789012}'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The format of the Date ''{12345678-1234-1234-1234-123456789012}'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion');
#else
        Observer.Expect('guid', 'validate error:Unable to convert from <ns>NavGuid to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavGuid to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('duration 1500', 'validate error:The format of the Date ''1 second 500 milliseconds'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The format of the Date ''1 second 500 milliseconds'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion');
#else
        Observer.Expect('duration 1500', 'validate error:Unable to convert from <ns>NavDuration to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavDuration to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('text empty', 'validate error:The format of the Date '''' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The format of the Date '''' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion');
#else
        Observer.Expect('text empty', 'validate error:Unable to convert from <ns>NavText to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavText to System.DateTime.|Conversion');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_T_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 9, 1, 8);
#if BC28PLUS
        Observer.Expect('integer 42', 'validate error:The value "42" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The value "42" can''t be evaluated into type Time.|Evaluate:Conversion');
#else
        Observer.Expect('integer 42', 'validate error:Unable to convert from <ns>NavInteger to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavInteger to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('integer -3', 'validate error:The value "-3" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The value "-3" can''t be evaluated into type Time.|Evaluate:Conversion');
#else
        Observer.Expect('integer -3', 'validate error:Unable to convert from <ns>NavInteger to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavInteger to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('decimal 2.5', 'validate error:The value "2.5" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The value "2.5" can''t be evaluated into type Time.|Evaluate:Conversion');
#else
        Observer.Expect('decimal 2.5', 'validate error:Unable to convert from <ns>NavDecimal to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavDecimal to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('biginteger', 'validate error:The value "5000000000" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The value "5000000000" can''t be evaluated into type Time.|Evaluate:Conversion');
#else
        Observer.Expect('biginteger', 'validate error:Unable to convert from <ns>NavBigInteger to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavBigInteger to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('boolean true', 'validate error:The value "Yes" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The value "Yes" can''t be evaluated into type Time.|Evaluate:Conversion');
#else
        Observer.Expect('boolean true', 'validate error:Unable to convert from <ns>NavBoolean to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavBoolean to System.DateTime.|Conversion');
#endif
        Observer.Expect('date 20260115D', 'validate error:The time is not valid.|InvalidTime ; assign error:The time is not valid.|InvalidTime');
        Observer.Expect('time 120000T', 'validate=12:00:00 hits=1 ; assign=12:00:00 hits=0');
        Observer.Expect('datetime', 'validate error:The time is not valid.|InvalidTime ; assign error:The time is not valid.|InvalidTime');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_T_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 9, 9, 16);
#if BC28PLUS
        Observer.Expect('text 42', 'validate error:The value "42" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The value "42" can''t be evaluated into type Time.|Evaluate:Conversion');
#else
        Observer.Expect('text 42', 'validate error:Unable to convert from <ns>NavText to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavText to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The value "abc" can''t be evaluated into type Time.|Evaluate:Conversion');
#else
        Observer.Expect('text abc', 'validate error:Unable to convert from <ns>NavText to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavText to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The value "C1" can''t be evaluated into type Time.|Evaluate:Conversion');
#else
        Observer.Expect('code C1', 'validate error:Unable to convert from <ns>NavCode to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavCode to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('option 1', 'validate error:The value "Beta" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The value "Beta" can''t be evaluated into type Time.|Evaluate:Conversion');
#else
        Observer.Expect('option 1', 'validate error:Unable to convert from <ns>NavOption to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavOption to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('enum Two', 'validate error:The value "Two" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The value "Two" can''t be evaluated into type Time.|Evaluate:Conversion');
#else
        Observer.Expect('enum Two', 'validate error:Unable to convert from <ns>NavOption to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavOption to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('guid', 'validate error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Time.|Evaluate:Conversion');
#else
        Observer.Expect('guid', 'validate error:Unable to convert from <ns>NavGuid to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavGuid to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('duration 1500', 'validate error:The value "1 second 500 milliseconds" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The value "1 second 500 milliseconds" can''t be evaluated into type Time.|Evaluate:Conversion');
#else
        Observer.Expect('duration 1500', 'validate error:Unable to convert from <ns>NavDuration to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavDuration to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The value "" can''t be evaluated into type Time.|Evaluate:Conversion');
#else
        Observer.Expect('text empty', 'validate error:Unable to convert from <ns>NavText to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavText to System.DateTime.|Conversion');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_DT_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 10, 1, 8);
#if BC28PLUS
        Observer.Expect('integer 42', 'validate error:The value "42" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The value "42" can''t be evaluated into type DateTime.|Evaluate:Conversion');
#else
        Observer.Expect('integer 42', 'validate error:Unable to convert from <ns>NavInteger to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavInteger to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('integer -3', 'validate error:The value "-3" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The value "-3" can''t be evaluated into type DateTime.|Evaluate:Conversion');
#else
        Observer.Expect('integer -3', 'validate error:Unable to convert from <ns>NavInteger to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavInteger to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('decimal 2.5', 'validate error:The value "2.5" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The value "2.5" can''t be evaluated into type DateTime.|Evaluate:Conversion');
#else
        Observer.Expect('decimal 2.5', 'validate error:Unable to convert from <ns>NavDecimal to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavDecimal to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('biginteger', 'validate error:The value "5000000000" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The value "5000000000" can''t be evaluated into type DateTime.|Evaluate:Conversion');
#else
        Observer.Expect('biginteger', 'validate error:Unable to convert from <ns>NavBigInteger to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavBigInteger to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('boolean true', 'validate error:The value "Yes" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The value "Yes" can''t be evaluated into type DateTime.|Evaluate:Conversion');
#else
        Observer.Expect('boolean true', 'validate error:Unable to convert from <ns>NavBoolean to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavBoolean to System.DateTime.|Conversion');
#endif
        Observer.Expect('date 20260115D', 'validate=2026-01-15T00:00:00Z hits=1 ; assign=2026-01-15T00:00:00Z hits=0');
        Observer.Expect('time 120000T', 'validate=0001-01-02T12:00:00Z hits=1 ; assign=0001-01-02T12:00:00Z hits=0');
        Observer.Expect('datetime', 'validate=2026-01-15T12:00:00Z hits=1 ; assign=2026-01-15T12:00:00Z hits=0');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_DT_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 10, 9, 16);
#if BC28PLUS
        Observer.Expect('text 42', 'validate error:The value "42" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The value "42" can''t be evaluated into type DateTime.|Evaluate:Conversion');
#else
        Observer.Expect('text 42', 'validate error:Unable to convert from <ns>NavText to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavText to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The value "abc" can''t be evaluated into type DateTime.|Evaluate:Conversion');
#else
        Observer.Expect('text abc', 'validate error:Unable to convert from <ns>NavText to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavText to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The value "C1" can''t be evaluated into type DateTime.|Evaluate:Conversion');
#else
        Observer.Expect('code C1', 'validate error:Unable to convert from <ns>NavCode to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavCode to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('option 1', 'validate error:The value "Beta" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The value "Beta" can''t be evaluated into type DateTime.|Evaluate:Conversion');
#else
        Observer.Expect('option 1', 'validate error:Unable to convert from <ns>NavOption to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavOption to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('enum Two', 'validate error:The value "Two" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The value "Two" can''t be evaluated into type DateTime.|Evaluate:Conversion');
#else
        Observer.Expect('enum Two', 'validate error:Unable to convert from <ns>NavOption to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavOption to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('guid', 'validate error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type DateTime.|Evaluate:Conversion');
#else
        Observer.Expect('guid', 'validate error:Unable to convert from <ns>NavGuid to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavGuid to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('duration 1500', 'validate error:The value "1 second 500 milliseconds" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The value "1 second 500 milliseconds" can''t be evaluated into type DateTime.|Evaluate:Conversion');
#else
        Observer.Expect('duration 1500', 'validate error:Unable to convert from <ns>NavDuration to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavDuration to System.DateTime.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The value "" can''t be evaluated into type DateTime.|Evaluate:Conversion');
#else
        Observer.Expect('text empty', 'validate error:Unable to convert from <ns>NavText to System.DateTime.|Conversion ; assign error:Unable to convert from <ns>NavText to System.DateTime.|Conversion');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_Opt_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 11, 1, 8);
        Observer.Expect('integer 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('integer -3', 'validate=-3 hits=1 ; assign=-3 hits=0');
        Observer.Expect('decimal 2.5', 'validate error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int32.|ConversionCast ; assign error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int32.|ConversionCast');
        Observer.Expect('biginteger', 'validate error:Arithmetic operation resulted in an overflow.|AL:Overflow ; assign error:Arithmetic operation resulted in an overflow.|AL:Overflow');
        Observer.Expect('boolean true', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Expect('date 20260115D', 'validate=1479993 hits=1 ; assign=1479993 hits=0');
        Observer.Expect('time 120000T', 'validate=43200001 hits=1 ; assign=43200001 hits=0');
#if BC28PLUS
        Observer.Expect('datetime', 'validate error:The value "01/15/26 12:00 PM" can''t be evaluated into type Option.|Evaluate:Conversion ; assign error:The value "01/15/26 12:00 PM" can''t be evaluated into type Option.|Evaluate:Conversion');
#else
        Observer.Expect('datetime', 'validate error:Unable to convert from <ns>NavDateTime to System.Int32.|Conversion ; assign error:Unable to convert from <ns>NavDateTime to System.Int32.|Conversion');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_Opt_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 11, 9, 16);
        Observer.Expect('text 42', 'validate=42 hits=1 ; assign=42 hits=0');
#if BC28PLUS
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type Option.|Evaluate:Format ; assign error:The value "abc" can''t be evaluated into type Option.|Evaluate:Format');
#else
        Observer.Expect('text abc', 'validate error:The type NavOption is unknown.|NotSupportedType ; assign error:The type NavOption is unknown.|NotSupportedType');
#endif
#if BC28PLUS
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type Option.|Evaluate:Format ; assign error:The value "C1" can''t be evaluated into type Option.|Evaluate:Format');
#else
        Observer.Expect('code C1', 'validate error:The type NavOption is unknown.|NotSupportedType ; assign error:The type NavOption is unknown.|NotSupportedType');
#endif
        Observer.Expect('option 1', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Expect('enum Two', 'validate=1 hits=1 ; assign=1 hits=0');
#if BC28PLUS
        Observer.Expect('guid', 'validate error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Option.|Evaluate:Conversion ; assign error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Option.|Evaluate:Conversion');
#else
        Observer.Expect('guid', 'validate error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion ; assign error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion');
#endif
        Observer.Expect('duration 1500', 'validate=1500 hits=1 ; assign=1500 hits=0');
#if BC28PLUS
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type Option.|Evaluate:Format ; assign error:The value "" can''t be evaluated into type Option.|Evaluate:Format');
#else
        Observer.Expect('text empty', 'validate error:The type NavOption is unknown.|NotSupportedType ; assign error:The type NavOption is unknown.|NotSupportedType');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_En_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 12, 1, 8);
        Observer.Expect('integer 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('integer -3', 'validate=-3 hits=1 ; assign=-3 hits=0');
        Observer.Expect('decimal 2.5', 'validate error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int32.|ConversionCast ; assign error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int32.|ConversionCast');
        Observer.Expect('biginteger', 'validate error:Arithmetic operation resulted in an overflow.|AL:Overflow ; assign error:Arithmetic operation resulted in an overflow.|AL:Overflow');
        Observer.Expect('boolean true', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Expect('date 20260115D', 'validate=1479993 hits=1 ; assign=1479993 hits=0');
        Observer.Expect('time 120000T', 'validate=43200001 hits=1 ; assign=43200001 hits=0');
#if BC28PLUS
        Observer.Expect('datetime', 'validate error:The value "01/15/26 12:00 PM" can''t be evaluated into type Option.|Evaluate:Conversion ; assign error:The value "01/15/26 12:00 PM" can''t be evaluated into type Option.|Evaluate:Conversion');
#else
        Observer.Expect('datetime', 'validate error:Unable to convert from <ns>NavDateTime to System.Int32.|Conversion ; assign error:Unable to convert from <ns>NavDateTime to System.Int32.|Conversion');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_En_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 12, 9, 16);
        Observer.Expect('text 42', 'validate=42 hits=1 ; assign=42 hits=0');
#if BC28PLUS
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type Option.|Evaluate:Format ; assign error:The value "abc" can''t be evaluated into type Option.|Evaluate:Format');
#else
        Observer.Expect('text abc', 'validate error:The type NavOption is unknown.|NotSupportedType ; assign error:The type NavOption is unknown.|NotSupportedType');
#endif
#if BC28PLUS
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type Option.|Evaluate:Format ; assign error:The value "C1" can''t be evaluated into type Option.|Evaluate:Format');
#else
        Observer.Expect('code C1', 'validate error:The type NavOption is unknown.|NotSupportedType ; assign error:The type NavOption is unknown.|NotSupportedType');
#endif
        Observer.Expect('option 1', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Expect('enum Two', 'validate=1 hits=1 ; assign=1 hits=0');
#if BC28PLUS
        Observer.Expect('guid', 'validate error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Option.|Evaluate:Conversion ; assign error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Option.|Evaluate:Conversion');
#else
        Observer.Expect('guid', 'validate error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion ; assign error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion');
#endif
        Observer.Expect('duration 1500', 'validate=1500 hits=1 ; assign=1500 hits=0');
#if BC28PLUS
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type Option.|Evaluate:Format ; assign error:The value "" can''t be evaluated into type Option.|Evaluate:Format');
#else
        Observer.Expect('text empty', 'validate error:The type NavOption is unknown.|NotSupportedType ; assign error:The type NavOption is unknown.|NotSupportedType');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_G_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 13, 1, 8);
#if BC28PLUS
        Observer.Expect('integer 42', 'validate error:The value "42" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The value "42" can''t be evaluated into type GUID.|Evaluate:Argument');
#else
        Observer.Expect('integer 42', 'validate error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument ; assign error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument');
#endif
#if BC28PLUS
        Observer.Expect('integer -3', 'validate error:The value "-3" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The value "-3" can''t be evaluated into type GUID.|Evaluate:Argument');
#else
        Observer.Expect('integer -3', 'validate error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument ; assign error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument');
#endif
#if BC28PLUS
        Observer.Expect('decimal 2.5', 'validate error:The value "2.5" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The value "2.5" can''t be evaluated into type GUID.|Evaluate:Argument');
#else
        Observer.Expect('decimal 2.5', 'validate error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument ; assign error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument');
#endif
#if BC28PLUS
        Observer.Expect('biginteger', 'validate error:The value "5000000000" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The value "5000000000" can''t be evaluated into type GUID.|Evaluate:Argument');
#else
        Observer.Expect('biginteger', 'validate error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument ; assign error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument');
#endif
#if BC28PLUS
        Observer.Expect('boolean true', 'validate error:The value "Yes" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The value "Yes" can''t be evaluated into type GUID.|Evaluate:Argument');
#else
        Observer.Expect('boolean true', 'validate error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument ; assign error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument');
#endif
#if BC28PLUS
        Observer.Expect('date 20260115D', 'validate error:The value "01/15/26" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The value "01/15/26" can''t be evaluated into type GUID.|Evaluate:Argument');
#else
        Observer.Expect('date 20260115D', 'validate error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument ; assign error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument');
#endif
#if BC28PLUS
        Observer.Expect('time 120000T', 'validate error:The value "12:00:00 PM" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The value "12:00:00 PM" can''t be evaluated into type GUID.|Evaluate:Argument');
#else
        Observer.Expect('time 120000T', 'validate error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument ; assign error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument');
#endif
#if BC28PLUS
        Observer.Expect('datetime', 'validate error:The value "01/15/26 12:00 PM" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The value "01/15/26 12:00 PM" can''t be evaluated into type GUID.|Evaluate:Argument');
#else
        Observer.Expect('datetime', 'validate error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument ; assign error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_G_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 13, 9, 16);
#if BC28PLUS
        Observer.Expect('text 42', 'validate error:The value "42" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The value "42" can''t be evaluated into type GUID.|Evaluate:Argument');
#else
        Observer.Expect('text 42', 'validate error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument ; assign error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument');
#endif
#if BC28PLUS
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The value "abc" can''t be evaluated into type GUID.|Evaluate:Argument');
#else
        Observer.Expect('text abc', 'validate error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument ; assign error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument');
#endif
#if BC28PLUS
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The value "C1" can''t be evaluated into type GUID.|Evaluate:Argument');
#else
        Observer.Expect('code C1', 'validate error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument ; assign error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument');
#endif
#if BC28PLUS
        Observer.Expect('option 1', 'validate error:The value "Beta" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The value "Beta" can''t be evaluated into type GUID.|Evaluate:Argument');
#else
        Observer.Expect('option 1', 'validate error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument ; assign error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument');
#endif
#if BC28PLUS
        Observer.Expect('enum Two', 'validate error:The value "Two" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The value "Two" can''t be evaluated into type GUID.|Evaluate:Argument');
#else
        Observer.Expect('enum Two', 'validate error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument ; assign error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument');
#endif
        Observer.Expect('guid', 'validate={12345678-1234-1234-1234-123456789012} hits=1 ; assign={12345678-1234-1234-1234-123456789012} hits=0');
#if BC28PLUS
        Observer.Expect('duration 1500', 'validate error:The value "1 second 500 milliseconds" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The value "1 second 500 milliseconds" can''t be evaluated into type GUID.|Evaluate:Argument');
#else
        Observer.Expect('duration 1500', 'validate error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument ; assign error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument');
#endif
#if BC28PLUS
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The value "" can''t be evaluated into type GUID.|Evaluate:Argument');
#else
        Observer.Expect('text empty', 'validate error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument ; assign error:Invalid Conversion. Source: NavVariant, Destination: NavGuid.|Argument');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_Dur_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 14, 1, 8);
        Observer.Expect('integer 42', 'validate=P0DT0H0M0.042S hits=1 ; assign=P0DT0H0M0.042S hits=0');
        Observer.Expect('integer -3', 'validate=-P0DT0H0M0.003S hits=1 ; assign=-P0DT0H0M0.003S hits=0');
        Observer.Expect('decimal 2.5', 'validate error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int64.|ConversionCast ; assign error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int64.|ConversionCast');
        Observer.Expect('biginteger', 'validate=P57DT20H53M20.0S hits=1 ; assign=P57DT20H53M20.0S hits=0');
        Observer.Expect('boolean true', 'validate=P0DT0H0M0.001S hits=1 ; assign=P0DT0H0M0.001S hits=0');
        Observer.Expect('date 20260115D', 'validate=P0DT0H24M39.993S hits=1 ; assign=P0DT0H24M39.993S hits=0');
        Observer.Expect('time 120000T', 'validate=P0DT12H0M0.001S hits=1 ; assign=P0DT12H0M0.001S hits=0');
        Observer.Expect('datetime', 'validate=P739996DT12H0M0.001S hits=1 ; assign=P739996DT12H0M0.001S hits=0');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Into_Dur_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 14, 9, 16);
        Observer.Expect('text 42', 'validate=P0DT0H0M0.042S hits=1 ; assign=P0DT0H0M0.042S hits=0');
#if BC28PLUS
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type Duration.|Evaluate:Format ; assign error:The value "abc" can''t be evaluated into type Duration.|Evaluate:Format');
#else
        Observer.Expect('text abc', 'validate error:The type NavDuration is unknown.|NotSupportedType ; assign error:The type NavDuration is unknown.|NotSupportedType');
#endif
#if BC28PLUS
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type Duration.|Evaluate:Format ; assign error:The value "C1" can''t be evaluated into type Duration.|Evaluate:Format');
#else
        Observer.Expect('code C1', 'validate error:The type NavDuration is unknown.|NotSupportedType ; assign error:The type NavDuration is unknown.|NotSupportedType');
#endif
        Observer.Expect('option 1', 'validate=P0DT0H0M0.001S hits=1 ; assign=P0DT0H0M0.001S hits=0');
        Observer.Expect('enum Two', 'validate=P0DT0H0M0.001S hits=1 ; assign=P0DT0H0M0.001S hits=0');
#if BC28PLUS
        Observer.Expect('guid', 'validate error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Duration.|Evaluate:Conversion ; assign error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Duration.|Evaluate:Conversion');
#else
        Observer.Expect('guid', 'validate error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion ; assign error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion');
#endif
        Observer.Expect('duration 1500', 'validate=P0DT0H0M1.5S hits=1 ; assign=P0DT0H0M1.5S hits=0');
#if BC28PLUS
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type Duration.|Evaluate:Format ; assign error:The value "" can''t be evaluated into type Duration.|Evaluate:Format');
#else
        Observer.Expect('text empty', 'validate error:The type NavDuration is unknown.|NotSupportedType ; assign error:The type NavDuration is unknown.|NotSupportedType');
#endif
        Observer.Verify();
    end;

}
