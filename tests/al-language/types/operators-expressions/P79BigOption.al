// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/biginteger/biginteger-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table 73939, test codeunits 73940-73942
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: BigInteger to Option: assignment, argument, field assignment, Validate, comparison, if/case; values 0, 1, existing and missing ordinals, negative, beyond Integer
// BC versions: 29 (27 and 28 by CI)

table 73939 "LT P79 BigRec"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option) { OptionMembers = A,B,C; }
        field(3; Big; BigInteger) { }
        field(4; Flag; Boolean) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73940 "LT P79 Big To Option"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure BigVal(i: Integer): BigInteger
    var
        B: BigInteger;
    begin
        case i of
            1: exit(0);
            2: exit(1);
            3: exit(2);
            4: exit(3);
            5: exit(99);
            6: exit(-1);
            7: Evaluate(B, '4294967296');
            8: Evaluate(B, '2147483648');
            9: Evaluate(B, '-2147483649');
            10: Evaluate(B, '9223372036854775807');
        end;
        exit(B);
    end;

    [TryFunction]
    local procedure TryAssign(Big: BigInteger; var R: Text)
    var
        O: Option A,B,C;
    begin
        O := Big;
        R := Format(O) + '/' + Format(O, 0, 2);
    end;

    [TryFunction]
    local procedure TryIntegerAssign(Big: BigInteger; var R: Text)
    var
        O: Option A,B,C;
        I: Integer;
    begin
        I := Big;
        O := I;
        R := Format(I) + '/' + Format(O) + '/' + Format(O, 0, 2);
    end;

    [TryFunction]
    local procedure TryFromOption(Big: BigInteger; var R: Text)
    var
        O: Option A,B,C;
        B2: BigInteger;
    begin
        O := Big;
        B2 := O;
        R := Format(B2);
    end;

    local procedure Run(Which: Integer; Big: BigInteger): Text
    var
        R: Text;
        Ok: Boolean;
    begin
        case Which of
            1:
                Ok := TryAssign(Big, R);
            2:
                Ok := TryIntegerAssign(Big, R);
            3:
                Ok := TryFromOption(Big, R);
        end;
        if Ok then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Assign_BigToOption()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 10 do
            Observer.Observe('v' + Format(BigVal(i)), Run(1, BigVal(i)));
        Observer.Expect('v0', 'A/0');
        Observer.Expect('v1', 'B/1');
        Observer.Expect('v2', 'C/2');
        Observer.Expect('v3', '3/3');
        Observer.Expect('v99', '99/99');
        Observer.Expect('v-1', '-1/-1');
        Observer.Expect('v4294967296', 'error:Overflow under conversion of System.Int64 value 4294967296 to System.Int32.|ConversionCast');
        Observer.Expect('v2147483648', 'error:Overflow under conversion of System.Int64 value 2147483648 to System.Int32.|ConversionCast');
        Observer.Expect('v-2147483649', 'error:Overflow under conversion of System.Int64 value -2147483649 to System.Int32.|ConversionCast');
        Observer.Expect('v9223372036854775807', 'error:Overflow under conversion of System.Int64 value 9223372036854775807 to System.Int32.|ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure Assign_BigToIntegerToOption()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 10 do
            Observer.Observe('v' + Format(BigVal(i)), Run(2, BigVal(i)));
        Observer.Expect('v0', '0/A/0');
        Observer.Expect('v1', '1/B/1');
        Observer.Expect('v2', '2/C/2');
        Observer.Expect('v3', '3/3/3');
        Observer.Expect('v99', '99/99/99');
        Observer.Expect('v-1', '-1/-1/-1');
        Observer.Expect('v4294967296', 'error:Overflow under conversion of System.Int64 value 4294967296 to System.Int32.|ConversionCast');
        Observer.Expect('v2147483648', 'error:Overflow under conversion of System.Int64 value 2147483648 to System.Int32.|ConversionCast');
        Observer.Expect('v-2147483649', 'error:Overflow under conversion of System.Int64 value -2147483649 to System.Int32.|ConversionCast');
        Observer.Expect('v9223372036854775807', 'error:Overflow under conversion of System.Int64 value 9223372036854775807 to System.Int32.|ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure Assign_OptionToBig()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 10 do
            Observer.Observe('v' + Format(BigVal(i)), Run(3, BigVal(i)));
        Observer.Expect('v0', '0');
        Observer.Expect('v1', '1');
        Observer.Expect('v2', '2');
        Observer.Expect('v3', '3');
        Observer.Expect('v99', '99');
        Observer.Expect('v-1', '-1');
        Observer.Expect('v4294967296', 'error:Overflow under conversion of System.Int64 value 4294967296 to System.Int32.|ConversionCast');
        Observer.Expect('v2147483648', 'error:Overflow under conversion of System.Int64 value 2147483648 to System.Int32.|ConversionCast');
        Observer.Expect('v-2147483649', 'error:Overflow under conversion of System.Int64 value -2147483649 to System.Int32.|ConversionCast');
        Observer.Expect('v9223372036854775807', 'error:Overflow under conversion of System.Int64 value 9223372036854775807 to System.Int32.|ConversionCast');
        Observer.Verify();
    end;
}

codeunit 73941 "LT P79 Big Option Arg Field"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure BigVal(i: Integer): BigInteger
    var
        B: BigInteger;
    begin
        case i of
            1: exit(0);
            2: exit(1);
            3: exit(2);
            4: exit(3);
            5: exit(99);
            6: exit(-1);
            7: Evaluate(B, '4294967296');
            8: Evaluate(B, '2147483648');
            9: Evaluate(B, '-2147483649');
            10: Evaluate(B, '9223372036854775807');
        end;
        exit(B);
    end;

    local procedure TakeOption(O: Option A,B,C): Text
    begin
        exit(Format(O) + '/' + Format(O, 0, 2));
    end;

    [TryFunction]
    local procedure TryArgument(Big: BigInteger; var R: Text)
    begin
        R := TakeOption(Big);
    end;

    [TryFunction]
    local procedure TryField(Big: BigInteger; var R: Text)
    var
        Rec: Record "LT P79 BigRec";
    begin
        Rec.Opt := Big;
        R := Format(Rec.Opt) + '/' + Format(Rec.Opt, 0, 2);
    end;

    [TryFunction]
    local procedure TryValidate(Big: BigInteger; var R: Text)
    var
        Rec: Record "LT P79 BigRec";
    begin
        Rec.Validate(Opt, Big);
        R := Format(Rec.Opt) + '/' + Format(Rec.Opt, 0, 2);
    end;

    [TryFunction]
    local procedure TryBigField(Big: BigInteger; var R: Text)
    var
        Rec: Record "LT P79 BigRec";
    begin
        Rec.Big := Big;
        Rec.Opt := Rec.Big;
        R := Format(Rec.Big) + '/' + Format(Rec.Opt, 0, 2);
    end;

    local procedure Run(Which: Integer; Big: BigInteger): Text
    var
        R: Text;
        Ok: Boolean;
    begin
        case Which of
            1:
                Ok := TryArgument(Big, R);
            2:
                Ok := TryField(Big, R);
            3:
                Ok := TryValidate(Big, R);
            4:
                Ok := TryBigField(Big, R);
        end;
        if Ok then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Argument_BigToOption()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 10 do
            Observer.Observe('v' + Format(BigVal(i)), Run(1, BigVal(i)));
        Observer.Expect('v0', 'A/0');
        Observer.Expect('v1', 'B/1');
        Observer.Expect('v2', 'C/2');
        Observer.Expect('v3', '3/3');
        Observer.Expect('v99', '99/99');
        Observer.Expect('v-1', '-1/-1');
        Observer.Expect('v4294967296', 'error:Overflow under conversion of System.Int64 value 4294967296 to System.Int32.|ConversionCast');
        Observer.Expect('v2147483648', 'error:Overflow under conversion of System.Int64 value 2147483648 to System.Int32.|ConversionCast');
        Observer.Expect('v-2147483649', 'error:Overflow under conversion of System.Int64 value -2147483649 to System.Int32.|ConversionCast');
        Observer.Expect('v9223372036854775807', 'error:Overflow under conversion of System.Int64 value 9223372036854775807 to System.Int32.|ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure Field_AssignBigToOption()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 10 do
            Observer.Observe('v' + Format(BigVal(i)), Run(2, BigVal(i)));
        Observer.Expect('v0', 'A/0');
        Observer.Expect('v1', 'B/1');
        Observer.Expect('v2', 'C/2');
        Observer.Expect('v3', '3/3');
        Observer.Expect('v99', '99/99');
        Observer.Expect('v-1', '-1/-1');
        Observer.Expect('v4294967296', 'error:Overflow under conversion of System.Int64 value 4294967296 to System.Int32.|ConversionCast');
        Observer.Expect('v2147483648', 'error:Overflow under conversion of System.Int64 value 2147483648 to System.Int32.|ConversionCast');
        Observer.Expect('v-2147483649', 'error:Overflow under conversion of System.Int64 value -2147483649 to System.Int32.|ConversionCast');
        Observer.Expect('v9223372036854775807', 'error:Overflow under conversion of System.Int64 value 9223372036854775807 to System.Int32.|ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure Field_ValidateBigToOption()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 10 do
            Observer.Observe('v' + Format(BigVal(i)), Run(3, BigVal(i)));
        Observer.Expect('v0', 'A/0');
        Observer.Expect('v1', 'B/1');
        Observer.Expect('v2', 'C/2');
        Observer.Expect('v3', '3/3');
        Observer.Expect('v99', '99/99');
        Observer.Expect('v-1', '-1/-1');
        Observer.Expect('v4294967296', 'error:Arithmetic operation resulted in an overflow.|AL:Overflow');
        Observer.Expect('v2147483648', 'error:Arithmetic operation resulted in an overflow.|AL:Overflow');
        Observer.Expect('v-2147483649', 'error:Arithmetic operation resulted in an overflow.|AL:Overflow');
        Observer.Expect('v9223372036854775807', 'error:Arithmetic operation resulted in an overflow.|AL:Overflow');
        Observer.Verify();
    end;

    [Test]
    procedure Field_BigFieldToOptionField()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 10 do
            Observer.Observe('v' + Format(BigVal(i)), Run(4, BigVal(i)));
        Observer.Expect('v0', '0/0');
        Observer.Expect('v1', '1/1');
        Observer.Expect('v2', '2/2');
        Observer.Expect('v3', '3/3');
        Observer.Expect('v99', '99/99');
        Observer.Expect('v-1', '-1/-1');
        Observer.Expect('v4294967296', 'error:Overflow under conversion of System.Int64 value 4294967296 to System.Int32.|ConversionCast');
        Observer.Expect('v2147483648', 'error:Overflow under conversion of System.Int64 value 2147483648 to System.Int32.|ConversionCast');
        Observer.Expect('v-2147483649', 'error:Overflow under conversion of System.Int64 value -2147483649 to System.Int32.|ConversionCast');
        Observer.Expect('v9223372036854775807', 'error:Overflow under conversion of System.Int64 value 9223372036854775807 to System.Int32.|ConversionCast');
        Observer.Verify();
    end;
}

codeunit 73942 "LT P79 Big Option Compare"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure BigVal(i: Integer): BigInteger
    var
        B: BigInteger;
    begin
        case i of
            1: exit(0);
            2: exit(1);
            3: exit(2);
            4: exit(3);
            5: exit(99);
            6: exit(-1);
            7: Evaluate(B, '4294967296');
            8: Evaluate(B, '2147483648');
            9: Evaluate(B, '-2147483649');
            10: Evaluate(B, '9223372036854775807');
        end;
        exit(B);
    end;

    [TryFunction]
    local procedure TryEq(Big: BigInteger; var R: Text)
    var
        O: Option A,B,C;
    begin
        O := O::B;
        R := Format(O = Big) + '/' + Format(Big = O) + '/' + Format(O <> Big);
    end;

    [TryFunction]
    local procedure TryOrder(Big: BigInteger; var R: Text)
    var
        O: Option A,B,C;
    begin
        O := O::B;
        R := Format(O < Big) + '/' + Format(O >= Big) + '/' + Format(Big > O);
    end;

    [TryFunction]
    local procedure TryIf(Big: BigInteger; var R: Text)
    var
        O: Option A,B,C;
    begin
        O := O::C;
        R := 'no';
        if O = Big then
            R := 'yes';
    end;

    [TryFunction]
    local procedure TryCase(Big: BigInteger; var R: Text)
    var
        O: Option A,B,C;
    begin
        R := 'none';
        case Big of
            O::A:
                R := 'A';
            O::B:
                R := 'B';
            O::C:
                R := 'C';
        end;
    end;

    [TryFunction]
    local procedure TryIn(Big: BigInteger; var R: Text)
    var
        O: Option A,B,C;
    begin
        O := O::A;
        R := Format(Big in [0, 1, 2]) + '/' + Format(O in [Big]);
    end;

    local procedure Run(Which: Integer; Big: BigInteger): Text
    var
        R: Text;
        Ok: Boolean;
    begin
        case Which of
            1:
                Ok := TryEq(Big, R);
            2:
                Ok := TryOrder(Big, R);
            3:
                Ok := TryIf(Big, R);
            4:
                Ok := TryCase(Big, R);
            5:
                Ok := TryIn(Big, R);
        end;
        if Ok then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Compare_Equality()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 10 do
            Observer.Observe('v' + Format(BigVal(i)), Run(1, BigVal(i)));
        Observer.Expect('v0', 'No/No/Yes');
        Observer.Expect('v1', 'Yes/Yes/No');
        Observer.Expect('v2', 'No/No/Yes');
        Observer.Expect('v3', 'No/No/Yes');
        Observer.Expect('v99', 'No/No/Yes');
        Observer.Expect('v-1', 'No/No/Yes');
        Observer.Expect('v4294967296', 'No/No/Yes');
        Observer.Expect('v2147483648', 'No/No/Yes');
        Observer.Expect('v-2147483649', 'No/No/Yes');
        Observer.Expect('v9223372036854775807', 'No/No/Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Compare_Order()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 10 do
            Observer.Observe('v' + Format(BigVal(i)), Run(2, BigVal(i)));
        Observer.Expect('v0', 'No/Yes/No');
        Observer.Expect('v1', 'No/Yes/No');
        Observer.Expect('v2', 'Yes/No/Yes');
        Observer.Expect('v3', 'Yes/No/Yes');
        Observer.Expect('v99', 'Yes/No/Yes');
        Observer.Expect('v-1', 'No/Yes/No');
        Observer.Expect('v4294967296', 'Yes/No/Yes');
        Observer.Expect('v2147483648', 'Yes/No/Yes');
        Observer.Expect('v-2147483649', 'No/Yes/No');
        Observer.Expect('v9223372036854775807', 'Yes/No/Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Compare_InIf()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 10 do
            Observer.Observe('v' + Format(BigVal(i)), Run(3, BigVal(i)));
        Observer.Expect('v0', 'no');
        Observer.Expect('v1', 'no');
        Observer.Expect('v2', 'yes');
        Observer.Expect('v3', 'no');
        Observer.Expect('v99', 'no');
        Observer.Expect('v-1', 'no');
        Observer.Expect('v4294967296', 'no');
        Observer.Expect('v2147483648', 'no');
        Observer.Expect('v-2147483649', 'no');
        Observer.Expect('v9223372036854775807', 'no');
        Observer.Verify();
    end;

    [Test]
    procedure Compare_Case()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 10 do
            Observer.Observe('v' + Format(BigVal(i)), Run(4, BigVal(i)));
        Observer.Expect('v0', 'A');
        Observer.Expect('v1', 'B');
        Observer.Expect('v2', 'C');
        Observer.Expect('v3', 'none');
        Observer.Expect('v99', 'none');
        Observer.Expect('v-1', 'none');
        Observer.Expect('v4294967296', 'none');
        Observer.Expect('v2147483648', 'none');
        Observer.Expect('v-2147483649', 'none');
        Observer.Expect('v9223372036854775807', 'none');
        Observer.Verify();
    end;

    [Test]
    procedure Compare_InSet()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 10 do
            Observer.Observe('v' + Format(BigVal(i)), Run(5, BigVal(i)));
        Observer.Expect('v0', 'Yes/Yes');
        Observer.Expect('v1', 'Yes/No');
        Observer.Expect('v2', 'Yes/No');
        Observer.Expect('v3', 'No/No');
        Observer.Expect('v99', 'No/No');
        Observer.Expect('v-1', 'No/No');
        Observer.Expect('v4294967296', 'error:Overflow under conversion of System.Int64 value 4294967296 to System.Int32.|ConversionCast');
        Observer.Expect('v2147483648', 'error:Overflow under conversion of System.Int64 value 2147483648 to System.Int32.|ConversionCast');
        Observer.Expect('v-2147483649', 'error:Overflow under conversion of System.Int64 value -2147483649 to System.Int32.|ConversionCast');
        Observer.Expect('v9223372036854775807', 'error:Overflow under conversion of System.Int64 value 9223372036854775807 to System.Int32.|ConversionCast');
        Observer.Verify();
    end;
}
