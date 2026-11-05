// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 93630 "LT Y67 FV Row" and enum 93632 "LT Y67 FV Kind" of
//   recordref-fieldref/fieldref/Y67FieldRefValidateVariant.al (one field of each type, each OnValidate counts Hits)
// Probe: Record.Validate(Field, V) and Rec.Field := V with a Variant V that holds an Integer, a Decimal, a BigInteger, a Boolean, a Date,
//   a Time, a DateTime, a Text (a number, other text, empty), a Code, an Option, an Enum, a Guid or a Duration, into a field of each type
//   (Text, Code, Integer, Decimal, BigInteger, Boolean, Date, Time, DateTime, Option, Guid, Duration). An Enum field
//   is left out: Record.Validate(EnumField, Variant) and EnumField := Variant do not compile (AL0193, AL0122). The same matrix as the
//   FieldRef one in Y67FieldRefValidateVariant.al, through the record. Per cell: the value of the field (Format(.., 0, 9)) and how many
//   times its OnValidate ran after Validate, and the value after the assignment; or the error text and code.
//   Asked by al-runner issue 6975 (Validate of a Text field with a Variant that holds an Enum).
//   Measured on BC 29.0 (corpus CI): Record.Validate gives the same value or error as FieldRef.Validate in every cell of
//   Y67FieldRefValidateVariant.al; the assignment raises NavIndirectValue for a number, Boolean, date, time, Option, Enum or
//   Duration into a Text or Code field.
// BC versions: 27, 28, 29

codeunit 95786 "REC Validate Variant Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryValidate(var Row: Record "LT Y67 FV Row"; FieldNo: Integer; V: Variant)
    begin
        case FieldNo of
            2:
                Row.Validate(Txt, V);
            3:
                Row.Validate(Cod, V);
            4:
                Row.Validate(Int, V);
            5:
                Row.Validate(Dec, V);
            6:
                Row.Validate(Big, V);
            7:
                Row.Validate(Bool, V);
            8:
                Row.Validate(D, V);
            9:
                Row.Validate(T, V);
            10:
                Row.Validate(DT, V);
            11:
                Row.Validate(Opt, V);
            13:
                Row.Validate(G, V);
            14:
                Row.Validate(Dur, V);
        end;
    end;

    [TryFunction]
    local procedure TryAssign(var Row: Record "LT Y67 FV Row"; FieldNo: Integer; V: Variant)
    begin
        case FieldNo of
            2:
                Row.Txt := V;
            3:
                Row.Cod := V;
            4:
                Row.Int := V;
            5:
                Row.Dec := V;
            6:
                Row.Big := V;
            7:
                Row.Bool := V;
            8:
                Row.D := V;
            9:
                Row.T := V;
            10:
                Row.DT := V;
            11:
                Row.Opt := V;
            13:
                Row.G := V;
            14:
                Row.Dur := V;
        end;
    end;

    local procedure Value(var Row: Record "LT Y67 FV Row"; FieldNo: Integer): Text
    begin
        case FieldNo of
            2:
                exit(Format(Row.Txt, 0, 9));
            3:
                exit(Format(Row.Cod, 0, 9));
            4:
                exit(Format(Row.Int, 0, 9));
            5:
                exit(Format(Row.Dec, 0, 9));
            6:
                exit(Format(Row.Big, 0, 9));
            7:
                exit(Format(Row.Bool, 0, 9));
            8:
                exit(Format(Row.D, 0, 9));
            9:
                exit(Format(Row.T, 0, 9));
            10:
                exit(Format(Row.DT, 0, 9));
            11:
                exit(Format(Row.Opt, 0, 9));
            13:
                exit(Format(Row.G, 0, 9));
            14:
                exit(Format(Row.Dur, 0, 9));
        end;
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
        V: Variant;
        Name: Text;
        Result: Text;
    begin
        Source(Index, V, Name);
        ClearLastError();
        if TryValidate(Row, FieldNo, V) then
            Result := 'validate=' + Value(Row, FieldNo) + ' hits=' + Format(Row.Hits, 0, 9)
        else
            Result := 'validate error:' + Short(GetLastErrorText()) + '|' + GetLastErrorCode();
        Clear(Row);
        ClearLastError();
        if TryAssign(Row, FieldNo, V) then
            Result += ' ; assign=' + Value(Row, FieldNo) + ' hits=' + Format(Row.Hits, 0, 9)
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
    procedure RecordValidate_Into_Txt_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 2, 1, 4);
#if BC28PLUS
        Observer.Expect('integer 42', 'validate=42 hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavText value.|TypeConversion');
        Observer.Expect('integer -3', 'validate=-3 hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavText value.|TypeConversion');
        Observer.Expect('decimal 2.5', 'validate=2.5 hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavText value.|TypeConversion');
        Observer.Expect('biginteger', 'validate=5000000000 hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavText value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Txt_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 2, 5, 8);
#if BC28PLUS
        Observer.Expect('boolean true', 'validate=Yes hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavText value.|TypeConversion');
        Observer.Expect('date 20260115D', 'validate=01/15/26 hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavText value.|TypeConversion');
        Observer.Expect('time 120000T', 'validate=12:00:00 PM hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavText value.|TypeConversion');
        Observer.Expect('datetime', 'validate=01/15/26 12:00 PM hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavText value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Txt_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 2, 9, 12);
#if BC28PLUS
        Observer.Expect('text 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('text abc', 'validate=abc hits=1 ; assign=abc hits=0');
        Observer.Expect('code C1', 'validate=C1 hits=1 ; assign=C1 hits=0');
        Observer.Expect('option 1', 'validate=Beta hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavText value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Txt_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 2, 13, 16);
#if BC28PLUS
        Observer.Expect('enum Two', 'validate=Two hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavText value.|TypeConversion');
        Observer.Expect('guid', 'validate error:The length of the string is 38, but it must be less than or equal to 30 characters. Value: {12345678-1234-1234-1234-123456789012}|StringLengthExceeded ; assign error:The length of the string is 38, but it must be less than or equal to 30 characters. Value: {12345678-1234-1234-1234-123456789012}|StringLengthExceeded');
        Observer.Expect('duration 1500', 'validate=1 second 500 milliseconds hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavText value.|TypeConversion');
        Observer.Expect('text empty', 'validate= hits=1 ; assign= hits=0');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Cod_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 3, 1, 4);
#if BC28PLUS
        Observer.Expect('integer 42', 'validate=42 hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavCode value.|TypeConversion');
        Observer.Expect('integer -3', 'validate=-3 hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavCode value.|TypeConversion');
        Observer.Expect('decimal 2.5', 'validate=2.5 hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavCode value.|TypeConversion');
        Observer.Expect('biginteger', 'validate=5000000000 hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavCode value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Cod_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 3, 5, 8);
#if BC28PLUS
        Observer.Expect('boolean true', 'validate=YES hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavCode value.|TypeConversion');
        Observer.Expect('date 20260115D', 'validate=01/15/26 hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavCode value.|TypeConversion');
        Observer.Expect('time 120000T', 'validate=12:00:00 PM hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavCode value.|TypeConversion');
        Observer.Expect('datetime', 'validate=01/15/26 12:00 PM hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavCode value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Cod_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 3, 9, 12);
#if BC28PLUS
        Observer.Expect('text 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('text abc', 'validate=ABC hits=1 ; assign=ABC hits=0');
        Observer.Expect('code C1', 'validate=C1 hits=1 ; assign=C1 hits=0');
        Observer.Expect('option 1', 'validate=BETA hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavCode value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Cod_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 3, 13, 16);
#if BC28PLUS
        Observer.Expect('enum Two', 'validate=TWO hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavCode value.|TypeConversion');
        Observer.Expect('guid', 'validate error:The length of the string is 38, but it must be less than or equal to 20 characters. Value: {12345678-1234-1234-1234-123456789012}|StringLengthExceeded ; assign error:The length of the string is 38, but it must be less than or equal to 20 characters. Value: {12345678-1234-1234-1234-123456789012}|StringLengthExceeded');
        Observer.Expect('duration 1500', 'validate error:The length of the string is 25, but it must be less than or equal to 20 characters. Value: 1 second 500 milliseconds|StringLengthExceeded ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavCode value.|TypeConversion');
        Observer.Expect('text empty', 'validate= hits=1 ; assign= hits=0');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Int_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 4, 1, 4);
#if BC28PLUS
        Observer.Expect('integer 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('integer -3', 'validate=-3 hits=1 ; assign=-3 hits=0');
        Observer.Expect('decimal 2.5', 'validate error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int32.|ConversionCast ; assign error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int32.|ConversionCast');
        Observer.Expect('biginteger', 'validate error:Arithmetic operation resulted in an overflow.|AL:Overflow ; assign error:The expression Variant cannot be type-converted to a Integer value.|TypeConversion:Overflow');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Int_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 4, 5, 8);
#if BC28PLUS
        Observer.Expect('boolean true', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Expect('date 20260115D', 'validate=1479993 hits=1 ; assign=1479993 hits=0');
        Observer.Expect('time 120000T', 'validate=43200001 hits=1 ; assign=43200001 hits=0');
        Observer.Expect('datetime', 'validate error:The value "01/15/26 12:00 PM" can''t be evaluated into type Integer.|Evaluate:Conversion ; assign error:Unable to convert from <ns>NavDateTime to System.Int32.|Conversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Int_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 4, 9, 12);
#if BC28PLUS
        Observer.Expect('text 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type Integer.|Evaluate:Format ; assign error:The expression Variant cannot be type-converted to a Integer value.|TypeConversion:Format');
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type Integer.|Evaluate:Format ; assign error:The expression Variant cannot be type-converted to a Integer value.|TypeConversion:Format');
        Observer.Expect('option 1', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Int_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 4, 13, 16);
#if BC28PLUS
        Observer.Expect('enum Two', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Expect('guid', 'validate error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Integer.|Evaluate:Conversion ; assign error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion');
        Observer.Expect('duration 1500', 'validate=1500 hits=1 ; assign=1500 hits=0');
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type Integer.|Evaluate:Format ; assign error:The expression Variant cannot be type-converted to a Integer value.|TypeConversion:Format');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Dec_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 5, 1, 4);
#if BC28PLUS
        Observer.Expect('integer 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('integer -3', 'validate=-3 hits=1 ; assign=-3 hits=0');
        Observer.Expect('decimal 2.5', 'validate=2.5 hits=1 ; assign=2.5 hits=0');
        Observer.Expect('biginteger', 'validate=5000000000 hits=1 ; assign=5000000000 hits=0');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Dec_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 5, 5, 8);
#if BC28PLUS
        Observer.Expect('boolean true', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Expect('date 20260115D', 'validate=1479993 hits=1 ; assign=1479993 hits=0');
        Observer.Expect('time 120000T', 'validate=43200001 hits=1 ; assign=43200001 hits=0');
        Observer.Expect('datetime', 'validate=63935697600001 hits=1 ; assign=63935697600001 hits=0');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Dec_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 5, 9, 12);
#if BC28PLUS
        Observer.Expect('text 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type Decimal.|Evaluate:Format ; assign error:The expression Variant cannot be type-converted to a Decimal value.|TypeConversion:Format');
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type Decimal.|Evaluate:Format ; assign error:The expression Variant cannot be type-converted to a Decimal value.|TypeConversion:Format');
        Observer.Expect('option 1', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Dec_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 5, 13, 16);
#if BC28PLUS
        Observer.Expect('enum Two', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Expect('guid', 'validate error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Decimal.|Evaluate:Conversion ; assign error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion');
        Observer.Expect('duration 1500', 'validate=1500 hits=1 ; assign=1500 hits=0');
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type Decimal.|Evaluate:Format ; assign error:The expression Variant cannot be type-converted to a Decimal value.|TypeConversion:Format');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Big_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 6, 1, 4);
#if BC28PLUS
        Observer.Expect('integer 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('integer -3', 'validate=-3 hits=1 ; assign=-3 hits=0');
        Observer.Expect('decimal 2.5', 'validate error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int64.|ConversionCast ; assign error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int64.|ConversionCast');
        Observer.Expect('biginteger', 'validate=5000000000 hits=1 ; assign=5000000000 hits=0');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Big_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 6, 5, 8);
#if BC28PLUS
        Observer.Expect('boolean true', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Expect('date 20260115D', 'validate=1479993 hits=1 ; assign=1479993 hits=0');
        Observer.Expect('time 120000T', 'validate=43200001 hits=1 ; assign=43200001 hits=0');
        Observer.Expect('datetime', 'validate=63935697600001 hits=1 ; assign=63935697600001 hits=0');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Big_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 6, 9, 12);
#if BC28PLUS
        Observer.Expect('text 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type BigInteger.|Evaluate:Format ; assign error:The expression Variant cannot be type-converted to a BigInteger value.|TypeConversion:Format');
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type BigInteger.|Evaluate:Format ; assign error:The expression Variant cannot be type-converted to a BigInteger value.|TypeConversion:Format');
        Observer.Expect('option 1', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Big_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 6, 13, 16);
#if BC28PLUS
        Observer.Expect('enum Two', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Expect('guid', 'validate error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type BigInteger.|Evaluate:Conversion ; assign error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion');
        Observer.Expect('duration 1500', 'validate=1500 hits=1 ; assign=1500 hits=0');
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type BigInteger.|Evaluate:Format ; assign error:The expression Variant cannot be type-converted to a BigInteger value.|TypeConversion:Format');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Bool_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 7, 1, 4);
#if BC28PLUS
        Observer.Expect('integer 42', 'validate=true hits=1 ; assign=true hits=0');
        Observer.Expect('integer -3', 'validate=true hits=1 ; assign=true hits=0');
        Observer.Expect('decimal 2.5', 'validate error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int32.|ConversionCast ; assign error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int32.|ConversionCast');
        Observer.Expect('biginteger', 'validate error:Arithmetic operation resulted in an overflow.|AL:Overflow ; assign error:The expression Variant cannot be type-converted to a Boolean value.|TypeConversion:Overflow');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Bool_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 7, 5, 8);
#if BC28PLUS
        Observer.Expect('boolean true', 'validate=true hits=1 ; assign=true hits=0');
        Observer.Expect('date 20260115D', 'validate=true hits=1 ; assign=true hits=0');
        Observer.Expect('time 120000T', 'validate=true hits=1 ; assign=true hits=0');
        Observer.Expect('datetime', 'validate error:The value "01/15/26 12:00 PM" can''t be evaluated into type Boolean.|Evaluate:Conversion ; assign error:Unable to convert from <ns>NavDateTime to System.Int32.|Conversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Bool_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 7, 9, 12);
#if BC28PLUS
        Observer.Expect('text 42', 'validate=true hits=1 ; assign=true hits=0');
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type Boolean.|Evaluate:Format ; assign error:The expression Variant cannot be type-converted to a Boolean value.|TypeConversion:Format');
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type Boolean.|Evaluate:Format ; assign error:The expression Variant cannot be type-converted to a Boolean value.|TypeConversion:Format');
        Observer.Expect('option 1', 'validate=true hits=1 ; assign=true hits=0');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Bool_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 7, 13, 16);
#if BC28PLUS
        Observer.Expect('enum Two', 'validate=true hits=1 ; assign=true hits=0');
        Observer.Expect('guid', 'validate error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Boolean.|Evaluate:Conversion ; assign error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion');
        Observer.Expect('duration 1500', 'validate=true hits=1 ; assign=true hits=0');
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type Boolean.|Evaluate:Format ; assign error:The expression Variant cannot be type-converted to a Boolean value.|TypeConversion:Format');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_D_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 8, 1, 4);
#if BC28PLUS
        Observer.Expect('integer 42', 'validate error:The format of the Date ''42'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDate value.|TypeConversion');
        Observer.Expect('integer -3', 'validate error:The format of the Date ''-3'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDate value.|TypeConversion');
        Observer.Expect('decimal 2.5', 'validate error:The format of the Date ''2.5'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDate value.|TypeConversion');
        Observer.Expect('biginteger', 'validate error:The format of the Date ''5000000000'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDate value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_D_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 8, 5, 8);
#if BC28PLUS
        Observer.Expect('boolean true', 'validate error:The format of the Date ''Yes'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDate value.|TypeConversion');
        Observer.Expect('date 20260115D', 'validate=2026-01-15 hits=1 ; assign=2026-01-15 hits=0');
        Observer.Expect('time 120000T', 'validate error:The date is not valid.|DateInvalid ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDate value.|TypeConversion');
        Observer.Expect('datetime', 'validate error:The date is not valid.|DateInvalid ; assign=2026-01-15 hits=0');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_D_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 8, 9, 12);
#if BC28PLUS
        Observer.Expect('text 42', 'validate error:The format of the Date ''42'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDate value.|TypeConversion');
        Observer.Expect('text abc', 'validate error:The format of the Date ''abc'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDate value.|TypeConversion');
        Observer.Expect('code C1', 'validate error:The format of the Date ''C1'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDate value.|TypeConversion');
        Observer.Expect('option 1', 'validate error:The format of the Date ''Beta'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDate value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_D_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 8, 13, 16);
#if BC28PLUS
        Observer.Expect('enum Two', 'validate error:The format of the Date ''Two'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDate value.|TypeConversion');
        Observer.Expect('guid', 'validate error:The format of the Date ''{12345678-1234-1234-1234-123456789012}'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDate value.|TypeConversion');
        Observer.Expect('duration 1500', 'validate error:The format of the Date ''1 second 500 milliseconds'' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDate value.|TypeConversion');
        Observer.Expect('text empty', 'validate error:The format of the Date '''' does not match your device''s date settings.\\<datehelp>|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDate value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_T_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 9, 1, 4);
#if BC28PLUS
        Observer.Expect('integer 42', 'validate error:The value "42" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavTime value.|TypeConversion');
        Observer.Expect('integer -3', 'validate error:The value "-3" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavTime value.|TypeConversion');
        Observer.Expect('decimal 2.5', 'validate error:The value "2.5" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavTime value.|TypeConversion');
        Observer.Expect('biginteger', 'validate error:The value "5000000000" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavTime value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_T_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 9, 5, 8);
#if BC28PLUS
        Observer.Expect('boolean true', 'validate error:The value "Yes" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavTime value.|TypeConversion');
        Observer.Expect('date 20260115D', 'validate error:The time is not valid.|InvalidTime ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavTime value.|TypeConversion');
        Observer.Expect('time 120000T', 'validate=12:00:00 hits=1 ; assign=12:00:00 hits=0');
        Observer.Expect('datetime', 'validate error:The time is not valid.|InvalidTime ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavTime value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_T_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 9, 9, 12);
#if BC28PLUS
        Observer.Expect('text 42', 'validate error:The value "42" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavTime value.|TypeConversion');
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavTime value.|TypeConversion');
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavTime value.|TypeConversion');
        Observer.Expect('option 1', 'validate error:The value "Beta" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavTime value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_T_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 9, 13, 16);
#if BC28PLUS
        Observer.Expect('enum Two', 'validate error:The value "Two" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavTime value.|TypeConversion');
        Observer.Expect('guid', 'validate error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavTime value.|TypeConversion');
        Observer.Expect('duration 1500', 'validate error:The value "1 second 500 milliseconds" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavTime value.|TypeConversion');
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type Time.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavTime value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_DT_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 10, 1, 4);
#if BC28PLUS
        Observer.Expect('integer 42', 'validate error:The value "42" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDateTime value.|TypeConversion');
        Observer.Expect('integer -3', 'validate error:The value "-3" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDateTime value.|TypeConversion');
        Observer.Expect('decimal 2.5', 'validate error:The value "2.5" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDateTime value.|TypeConversion');
        Observer.Expect('biginteger', 'validate error:The value "5000000000" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDateTime value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_DT_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 10, 5, 8);
#if BC28PLUS
        Observer.Expect('boolean true', 'validate error:The value "Yes" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDateTime value.|TypeConversion');
        Observer.Expect('date 20260115D', 'validate=2026-01-15T00:00:00Z hits=1 ; assign=2026-01-15T00:00:00Z hits=0');
        Observer.Expect('time 120000T', 'validate=0001-01-02T12:00:00Z hits=1 ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDateTime value.|TypeConversion');
        Observer.Expect('datetime', 'validate=2026-01-15T12:00:00Z hits=1 ; assign=2026-01-15T12:00:00Z hits=0');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_DT_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 10, 9, 12);
#if BC28PLUS
        Observer.Expect('text 42', 'validate error:The value "42" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDateTime value.|TypeConversion');
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDateTime value.|TypeConversion');
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDateTime value.|TypeConversion');
        Observer.Expect('option 1', 'validate error:The value "Beta" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDateTime value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_DT_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 10, 13, 16);
#if BC28PLUS
        Observer.Expect('enum Two', 'validate error:The value "Two" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDateTime value.|TypeConversion');
        Observer.Expect('guid', 'validate error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDateTime value.|TypeConversion');
        Observer.Expect('duration 1500', 'validate error:The value "1 second 500 milliseconds" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDateTime value.|TypeConversion');
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type DateTime.|Evaluate:Conversion ; assign error:The expression <ns>NavIndirectValue cannot be type-converted to a <ns>NavDateTime value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Opt_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 11, 1, 4);
#if BC28PLUS
        Observer.Expect('integer 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('integer -3', 'validate=-3 hits=1 ; assign=-3 hits=0');
        Observer.Expect('decimal 2.5', 'validate error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int32.|ConversionCast ; assign error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int32.|ConversionCast');
        Observer.Expect('biginteger', 'validate error:Arithmetic operation resulted in an overflow.|AL:Overflow ; assign error:The expression Variant cannot be type-converted to a Integer value.|TypeConversion:Overflow');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Opt_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 11, 5, 8);
#if BC28PLUS
        Observer.Expect('boolean true', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Expect('date 20260115D', 'validate=1479993 hits=1 ; assign=1479993 hits=0');
        Observer.Expect('time 120000T', 'validate=43200001 hits=1 ; assign=43200001 hits=0');
        Observer.Expect('datetime', 'validate error:The value "01/15/26 12:00 PM" can''t be evaluated into type Option.|Evaluate:Conversion ; assign error:Unable to convert from <ns>NavDateTime to System.Int32.|Conversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Opt_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 11, 9, 12);
#if BC28PLUS
        Observer.Expect('text 42', 'validate=42 hits=1 ; assign=42 hits=0');
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type Option.|Evaluate:Format ; assign error:The expression Variant cannot be type-converted to a Integer value.|TypeConversion:Format');
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type Option.|Evaluate:Format ; assign error:The expression Variant cannot be type-converted to a Integer value.|TypeConversion:Format');
        Observer.Expect('option 1', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Opt_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 11, 13, 16);
#if BC28PLUS
        Observer.Expect('enum Two', 'validate=1 hits=1 ; assign=1 hits=0');
        Observer.Expect('guid', 'validate error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Option.|Evaluate:Conversion ; assign error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion');
        Observer.Expect('duration 1500', 'validate=1500 hits=1 ; assign=1500 hits=0');
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type Option.|Evaluate:Format ; assign error:The expression Variant cannot be type-converted to a Integer value.|TypeConversion:Format');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_G_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 13, 1, 4);
#if BC28PLUS
        Observer.Expect('integer 42', 'validate error:The value "42" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The expression Variant cannot be type-converted to a GUID value.|TypeConversion');
        Observer.Expect('integer -3', 'validate error:The value "-3" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The expression Variant cannot be type-converted to a GUID value.|TypeConversion');
        Observer.Expect('decimal 2.5', 'validate error:The value "2.5" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The expression Variant cannot be type-converted to a GUID value.|TypeConversion');
        Observer.Expect('biginteger', 'validate error:The value "5000000000" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The expression Variant cannot be type-converted to a GUID value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_G_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 13, 5, 8);
#if BC28PLUS
        Observer.Expect('boolean true', 'validate error:The value "Yes" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The expression Variant cannot be type-converted to a GUID value.|TypeConversion');
        Observer.Expect('date 20260115D', 'validate error:The value "01/15/26" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The expression Variant cannot be type-converted to a GUID value.|TypeConversion');
        Observer.Expect('time 120000T', 'validate error:The value "12:00:00 PM" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The expression Variant cannot be type-converted to a GUID value.|TypeConversion');
        Observer.Expect('datetime', 'validate error:The value "01/15/26 12:00 PM" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The expression Variant cannot be type-converted to a GUID value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_G_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 13, 9, 12);
#if BC28PLUS
        Observer.Expect('text 42', 'validate error:The value "42" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat');
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat');
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat');
        Observer.Expect('option 1', 'validate error:The value "Beta" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The expression Variant cannot be type-converted to a GUID value.|TypeConversion');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_G_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 13, 13, 16);
#if BC28PLUS
        Observer.Expect('enum Two', 'validate error:The value "Two" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The expression Variant cannot be type-converted to a GUID value.|TypeConversion');
        Observer.Expect('guid', 'validate={12345678-1234-1234-1234-123456789012} hits=1 ; assign={12345678-1234-1234-1234-123456789012} hits=0');
        Observer.Expect('duration 1500', 'validate error:The value "1 second 500 milliseconds" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:The expression Variant cannot be type-converted to a GUID value.|TypeConversion');
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type GUID.|Evaluate:Argument ; assign error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Dur_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 14, 1, 4);
#if BC28PLUS
        Observer.Expect('integer 42', 'validate=P0DT0H0M0.042S hits=1 ; assign=P0DT0H0M0.042S hits=0');
        Observer.Expect('integer -3', 'validate=-P0DT0H0M0.003S hits=1 ; assign=-P0DT0H0M0.003S hits=0');
        Observer.Expect('decimal 2.5', 'validate error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int64.|ConversionCast ; assign error:Overflow under conversion of <ns>Decimal18 value 2.5 to System.Int64.|ConversionCast');
        Observer.Expect('biginteger', 'validate=P57DT20H53M20.0S hits=1 ; assign=P57DT20H53M20.0S hits=0');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Dur_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 14, 5, 8);
#if BC28PLUS
        Observer.Expect('boolean true', 'validate=P0DT0H0M0.001S hits=1 ; assign=P0DT0H0M0.001S hits=0');
        Observer.Expect('date 20260115D', 'validate=P0DT0H24M39.993S hits=1 ; assign=P0DT0H24M39.993S hits=0');
        Observer.Expect('time 120000T', 'validate=P0DT12H0M0.001S hits=1 ; assign=P0DT12H0M0.001S hits=0');
        Observer.Expect('datetime', 'validate=P739996DT12H0M0.001S hits=1 ; assign=P739996DT12H0M0.001S hits=0');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Dur_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 14, 9, 12);
#if BC28PLUS
        Observer.Expect('text 42', 'validate=P0DT0H0M0.042S hits=1 ; assign=P0DT0H0M0.042S hits=0');
        Observer.Expect('text abc', 'validate error:The value "abc" can''t be evaluated into type Duration.|Evaluate:Format ; assign error:The input string ''abc'' was not in a correct format.|AL:Format');
        Observer.Expect('code C1', 'validate error:The value "C1" can''t be evaluated into type Duration.|Evaluate:Format ; assign error:The input string ''C1'' was not in a correct format.|AL:Format');
        Observer.Expect('option 1', 'validate=P0DT0H0M0.001S hits=1 ; assign=P0DT0H0M0.001S hits=0');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;

    [Test]
    procedure RecordValidate_Into_Dur_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 14, 13, 16);
#if BC28PLUS
        Observer.Expect('enum Two', 'validate=P0DT0H0M0.001S hits=1 ; assign=P0DT0H0M0.001S hits=0');
        Observer.Expect('guid', 'validate error:The value "{12345678-1234-1234-1234-123456789012}" can''t be evaluated into type Duration.|Evaluate:Conversion ; assign error:Unable to convert from <ns>NavGuid to System.Int32.|Conversion');
        Observer.Expect('duration 1500', 'validate=P0DT0H0M1.5S hits=1 ; assign=P0DT0H0M1.5S hits=0');
        Observer.Expect('text empty', 'validate error:The value "" can''t be evaluated into type Duration.|Evaluate:Format ; assign error:The input string '''' was not in a correct format.|AL:Format');
        Observer.Verify();
#else
        Observer.Finish();
#endif
    end;
}
