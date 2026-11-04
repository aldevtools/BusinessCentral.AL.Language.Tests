// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), enum 73945, own table 73946, test codeunits 73947-73949
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Integer and BigInteger to Enum via FromInteger/Evaluate, Enum to Integer via AsInteger/Format(x,0,2), arithmetic on the ordinal, Format numbers 0-9
// BC versions: 29 (27 and 28 by CI)

enum 73945 "LT P79 Color"
{
    Extensible = true;
    value(0; Red) { Caption = 'Red'; }
    value(1; Green) { Caption = 'Green'; }
    value(5; Blue) { Caption = 'Blue Caption'; }
    value(100; Big) { Caption = 'Big'; }
}

table 73946 "LT P79 EnumRec"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Col; Enum "LT P79 Color") { }
        field(3; Num; Integer) { }
        field(4; BigNum; BigInteger) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73947 "LT P79 Enum From Numbers"
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
            4: exit(5);
            5: exit(100);
            6: exit(-1);
            7: Evaluate(B, '4294967296');
            8: Evaluate(B, '2147483648');
            9: Evaluate(B, '-2147483649');
        end;
        exit(B);
    end;

    [TryFunction]
    local procedure TryFromInt(I: Integer; var R: Text)
    var
        E: Enum "LT P79 Color";
    begin
        E := Enum::"LT P79 Color".FromInteger(I);
        R := Format(E) + '/' + Format(E, 0, 2);
    end;

    [TryFunction]
    local procedure TryEvalBig(Big: BigInteger; var R: Text)
    var
        E: Enum "LT P79 Color";
    begin
        if Evaluate(E, Format(Big, 0, 2)) then
            R := 'ok/' + Format(E) + '/' + Format(E, 0, 2)
        else
            R := 'false';
    end;

    [TryFunction]
    local procedure TryFromBigViaInteger(Big: BigInteger; var R: Text)
    var
        E: Enum "LT P79 Color";
        I: Integer;
    begin
        I := Big;
        E := Enum::"LT P79 Color".FromInteger(I);
        R := Format(E) + '/' + Format(E, 0, 2);
    end;

    local procedure Run(Which: Integer; Big: BigInteger): Text
    var
        R: Text;
        Ok: Boolean;
    begin
        case Which of
            1:
                Ok := TryFromInt(Big, R);
            2:
                Ok := TryEvalBig(Big, R);
            3:
                Ok := TryFromBigViaInteger(Big, R);
        end;
        if Ok then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure FromInteger_WithBigIntegerArgument()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 9 do
            Observer.Observe('v' + Format(BigVal(i)), Run(1, BigVal(i)));
        Observer.Expect('v0', 'Red/0');
        Observer.Expect('v1', 'Green/1');
        Observer.Expect('v2', '2/2');
        Observer.Expect('v5', 'Blue Caption/5');
        Observer.Expect('v100', 'Big/100');
        Observer.Expect('v-1', '-1/-1');
        Observer.Expect('v4294967296', 'error:Overflow under conversion of System.Int64 value 4294967296 to System.Int32.|ConversionCast');
        Observer.Expect('v2147483648', 'error:Overflow under conversion of System.Int64 value 2147483648 to System.Int32.|ConversionCast');
        Observer.Expect('v-2147483649', 'error:Overflow under conversion of System.Int64 value -2147483649 to System.Int32.|ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_FromBigIntegerText()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 9 do
            Observer.Observe('v' + Format(BigVal(i)), Run(2, BigVal(i)));
        Observer.Expect('v0', 'ok/Red/0');
        Observer.Expect('v1', 'ok/Green/1');
        Observer.Expect('v2', 'ok/2/2');
        Observer.Expect('v5', 'ok/Blue Caption/5');
        Observer.Expect('v100', 'ok/Big/100');
        Observer.Expect('v-1', 'false');
        Observer.Expect('v4294967296', 'false');
        Observer.Expect('v2147483648', 'false');
        Observer.Expect('v-2147483649', 'false');
        Observer.Verify();
    end;

    [Test]
    procedure FromInteger_ViaIntegerVariable()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 9 do
            Observer.Observe('v' + Format(BigVal(i)), Run(3, BigVal(i)));
        Observer.Expect('v0', 'Red/0');
        Observer.Expect('v1', 'Green/1');
        Observer.Expect('v2', '2/2');
        Observer.Expect('v5', 'Blue Caption/5');
        Observer.Expect('v100', 'Big/100');
        Observer.Expect('v-1', '-1/-1');
        Observer.Expect('v4294967296', 'error:Overflow under conversion of System.Int64 value 4294967296 to System.Int32.|ConversionCast');
        Observer.Expect('v2147483648', 'error:Overflow under conversion of System.Int64 value 2147483648 to System.Int32.|ConversionCast');
        Observer.Expect('v-2147483649', 'error:Overflow under conversion of System.Int64 value -2147483649 to System.Int32.|ConversionCast');
        Observer.Verify();
    end;
}

codeunit 73948 "LT P79 Enum To Numbers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AsInteger_AndFormatTwo()
    var
        Observer: Codeunit "Probe Observer";
        E: Enum "LT P79 Color";
        I: Integer;
        Big: BigInteger;
    begin
        E := E::Blue;
        I := E.AsInteger();
        Observer.Observe('asint', Format(I));
        Observer.Observe('fmt2', Format(E, 0, 2));
        Observer.Observe('fmt-default', Format(E));
        Big := E.AsInteger();
        Observer.Observe('asbig', Format(Big));
        Observer.Observe('plus1', Format(E.AsInteger() + 1));
        Observer.Observe('times3', Format(E.AsInteger() * 3));
        Observer.Observe('div2', Format(E.AsInteger() div 2));
        Observer.Observe('mod3', Format(E.AsInteger() mod 3));
        Observer.Observe('neg', Format(-E.AsInteger()));
        E := E::Red;
        Observer.Observe('red-asint', Format(E.AsInteger()));
        Observer.Observe('red-fmt2', Format(E, 0, 2));
        E := E::Big;
        Observer.Observe('big-asint', Format(E.AsInteger()));
        asserterror Observer.Observe('big-times-big', Format(E.AsInteger() * 100000000));
        Observer.ObserveError('af166');
        Observer.Expect('asint', '5');
        Observer.Expect('fmt2', '5');
        Observer.Expect('fmt-default', 'Blue Caption');
        Observer.Expect('asbig', '5');
        Observer.Expect('plus1', '6');
        Observer.Expect('times3', '15');
        Observer.Expect('div2', '2');
        Observer.Expect('mod3', '2');
        Observer.Expect('neg', '-5');
        Observer.Expect('red-asint', '0');
        Observer.Expect('red-fmt2', '0');
        Observer.Expect('big-asint', '100');
        Observer.Expect('af166|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('af166|code', 'AL:Overflow');
        Observer.Verify();
    end;

    [Test]
    procedure RoundTrip_ArithmeticOnOrdinal()
    var
        Observer: Codeunit "Probe Observer";
        E: Enum "LT P79 Color";
        Next: Enum "LT P79 Color";
        Ok: Boolean;
    begin
        E := E::Red;
        Next := Enum::"LT P79 Color".FromInteger(E.AsInteger() + 1);
        Observer.Observe('red-plus-1', Format(Next));
        E := E::Green;
        Observer.Observe('green-plus-4', Format(Enum::"LT P79 Color".FromInteger(E.AsInteger() + 4)));
        Observer.Observe('green-minus-1', Format(Enum::"LT P79 Color".FromInteger(E.AsInteger() - 1)));
        Ok := Evaluate(Next, Format(E.AsInteger() + 1));
        Observer.Observe('eval-2', Format(Ok));
        Ok := Evaluate(Next, Format(E.AsInteger() + 4));
        Observer.Observe('eval-5', Format(Ok) + '/' + Format(Next));
        Observer.Observe('compare-int', Format(E.AsInteger() = 1));
        Observer.Observe('less-int', Format(E.AsInteger() < 5));
        Observer.Observe('in-int', Format(E.AsInteger() in [0, 1]));
        Observer.Expect('red-plus-1', 'Green');
        Observer.Expect('green-plus-4', 'Blue Caption');
        Observer.Expect('green-minus-1', 'Red');
        Observer.Expect('eval-2', 'Yes');
        Observer.Expect('eval-5', 'Yes/Blue Caption');
        Observer.Expect('compare-int', 'Yes');
        Observer.Expect('less-int', 'Yes');
        Observer.Expect('in-int', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Names_AndOrdinalsTable()
    var
        Observer: Codeunit "Probe Observer";
        Ords: List of [Integer];
        Names: List of [Text];
        i: Integer;
    begin
        Ords := Enum::"LT P79 Color".Ordinals();
        Names := Enum::"LT P79 Color".Names();
        Observer.Observe('count', Format(Ords.Count()));
        for i := 1 to Ords.Count() do
            Observer.Observe('ord' + Format(i), Format(Ords.Get(i)) + '=' + Names.Get(i));
        Observer.Expect('count', '4');
        Observer.Expect('ord1', '0=Red');
        Observer.Expect('ord2', '1=Green');
        Observer.Expect('ord3', '5=Blue');
        Observer.Expect('ord4', '100=Big');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryFormatNumber(E: Enum "LT P79 Color"; N: Integer; var R: Text)
    begin
        R := Format(E, 0, N);
    end;

    local procedure FN(E: Enum "LT P79 Color"; N: Integer): Text
    var
        R: Text;
    begin
        if TryFormatNumber(E, N, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Enum_FormatNumbers()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 0 to 9 do
            Observer.Observe('blue' + Format(i), FN(Enum::"LT P79 Color"::Blue, i));
        Observer.Observe('custom-x', Format(Enum::"LT P79 Color"::Blue, 0, 'X'));
        Observer.Observe('custom-std0', Format(Enum::"LT P79 Color"::Blue, 0, '<Standard Format,0>'));
        Observer.Observe('custom-std2', Format(Enum::"LT P79 Color"::Blue, 0, '<Standard Format,2>'));
        Observer.Observe('len-3', Format(Enum::"LT P79 Color"::Blue, 3));
        Observer.Expect('blue0', 'Blue Caption');
        Observer.Expect('blue1', 'Blue Caption');
        Observer.Expect('blue2', '5');
        Observer.Expect('blue3', 'error:Standard format number 3 does not exist for the type ''Option''.|InvalidStandardFormat');
        Observer.Expect('blue4', 'error:Standard format number 4 does not exist for the type ''Option''.|InvalidStandardFormat');
        Observer.Expect('blue5', 'error:Standard format number 5 does not exist for the type ''Option''.|InvalidStandardFormat');
        Observer.Expect('blue6', 'error:Standard format number 6 does not exist for the type ''Option''.|InvalidStandardFormat');
        Observer.Expect('blue7', 'error:Standard format number 7 does not exist for the type ''Option''.|InvalidStandardFormat');
        Observer.Expect('blue8', 'error:Standard format number 8 does not exist for the type ''Option''.|InvalidStandardFormat');
        Observer.Expect('blue9', '5');
        Observer.Expect('custom-x', 'X');
        Observer.Expect('custom-std0', 'Blue Caption');
        Observer.Expect('custom-std2', '5');
        Observer.Expect('len-3', 'Blu');
        Observer.Verify();
    end;
}

codeunit 73949 "LT P79 Enum Field Numbers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFilterCount(Flt: Text; var R: Text)
    var
        Rec: Record "LT P79 EnumRec";
    begin
        Rec.SetFilter(Col, Flt);
        R := Format(Rec.Count());
    end;

    local procedure FilterCount(Flt: Text): Text
    var
        R: Text;
    begin
        if TryFilterCount(Flt, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Field_NumbersAndEnum()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P79 EnumRec";
        Big: BigInteger;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        Rec.Col := Rec.Col::Blue;
        Rec.Num := Rec.Col.AsInteger();
        Rec.BigNum := Rec.Col.AsInteger();
        Observer.Observe('num', Format(Rec.Num));
        Observer.Observe('bignum', Format(Rec.BigNum));
        Rec.Insert();
        Rec.Num := 1;
        Rec.Validate(Col, Enum::"LT P79 Color".FromInteger(Rec.Num));
        Observer.Observe('validate-from-num', Format(Rec.Col));
        Rec.BigNum := 100;
        Rec.Col := Enum::"LT P79 Color".FromInteger(Rec.BigNum);
        Observer.Observe('from-bignum', Format(Rec.Col));
        Rec.Col := Rec.Col::Red;
        Rec.Modify();
        Rec.Get(1);
        Observer.Observe('stored', Format(Rec.Col, 0, 2));
        Observer.Observe('field-no-ordinal', Format(Rec.Col.AsInteger() + Rec.Num));
        Rec.SetRange(Col, Rec.Col::Red);
        Observer.Observe('filter-count', Format(Rec.Count()));
        Rec.SetFilter(Col, '0');
        Observer.Observe('filter-by-ordinal', Format(Rec.Count()));
        Rec.SetFilter(Col, '1');
        Observer.Observe('filter-by-ordinal-1', Format(Rec.Count()));
        Observer.Observe('filter-by-missing-ordinal', FilterCount('3'));
        Observer.Observe('filter-by-name', FilterCount('Red'));
        Rec.Reset();
        Rec.DeleteAll();
        Observer.Expect('num', '5');
        Observer.Expect('bignum', '5');
        Observer.Expect('validate-from-num', 'Green');
        Observer.Expect('from-bignum', 'Big');
        Observer.Expect('stored', '0');
        Observer.Expect('field-no-ordinal', '1');
        Observer.Expect('filter-count', '1');
        Observer.Expect('filter-by-ordinal', '1');
        Observer.Expect('filter-by-ordinal-1', '0');
        Observer.Expect('filter-by-missing-ordinal', '0');
        Observer.Expect('filter-by-name', '1');
        Observer.Verify();
    end;
}
