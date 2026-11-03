// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/duration/duration-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Duration plus and minus Duration on variables, negative results, zero, Format(…, 0, 9), overflow beyond the BigInteger edge (assumption duration-add-duration); D_Duration.al pins add/sub of 60 s values, this adds the edges.
// BC versions: 29 (27 and 28 by CI)

codeunit 70391 "LT DurAdd Arithmetic"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Big(Factor: BigInteger; Times: Integer): BigInteger
    var
        Result: BigInteger;
        I: Integer;
    begin
        Result := 1;
        for I := 1 to Times do
            Result := Result * Factor;
        exit(Result);
    end;

    [Test]
    procedure Add_TwoVariables_Result()
    var
        Observer: Codeunit "Probe Observer";
        D1: Duration;
        D2: Duration;
        R: Duration;
    begin
        D1 := 1500;
        D2 := 2500;
        R := D1 + D2;
        Observer.Observe('sum_ms', Format(R, 0, 9));
        Observer.Observe('sum_int', Format(R div 1));
        R := D2 - D1;
        Observer.Observe('diff_ms', Format(R, 0, 9));
        R := D1 - D2;
        Observer.Observe('diff_negative', Format(R, 0, 9));
        R := D1 - D1;
        Observer.Observe('diff_zero', Format(R, 0, 9));
        R := D1 + 0;
        Observer.Observe('plus_zero_literal', Format(R, 0, 9));
        Observer.Observe('sum_format_default', Format(D1 + D2));
        Observer.Observe('sum_equals_4000', Format(D1 + D2 = 4000));
        Observer.Expect('sum_ms', 'P0DT0H0M4.0S');
        Observer.Expect('sum_int', '4,000');
        Observer.Expect('diff_ms', 'P0DT0H0M1.0S');
        Observer.Expect('diff_negative', '-P0DT0H0M1.0S');
        Observer.Expect('diff_zero', 'P0DT0H0M0.0S');
        Observer.Expect('plus_zero_literal', 'P0DT0H0M1.5S');
        Observer.Expect('sum_format_default', '4000');
        Observer.Expect('sum_equals_4000', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Add_NegativeOperands_Result()
    var
        Observer: Codeunit "Probe Observer";
        D1: Duration;
        D2: Duration;
        R: Duration;
    begin
        D1 := -1000;
        D2 := 400;
        R := D1 + D2;
        Observer.Observe('neg_plus_pos', Format(R, 0, 9));
        R := D1 - D2;
        Observer.Observe('neg_minus_pos', Format(R, 0, 9));
        R := D1 + D1;
        Observer.Observe('neg_plus_neg', Format(R, 0, 9));
        R := D1 - D1;
        Observer.Observe('neg_minus_neg', Format(R, 0, 9));
        Observer.Expect('neg_plus_pos', '-P0DT0H0M0.6S');
        Observer.Expect('neg_minus_pos', '-P0DT0H0M1.4S');
        Observer.Expect('neg_plus_neg', '-P0DT0H0M2.0S');
        Observer.Expect('neg_minus_neg', 'P0DT0H0M0.0S');
        Observer.Verify();
    end;

    [Test]
    procedure Add_LargeValues_Result()
    var
        Observer: Codeunit "Probe Observer";
        D1: Duration;
        D2: Duration;
        R: Duration;
        Day: BigInteger;
        Dec: Decimal;
    begin
        Day := 86400000;
        D1 := Day * 1000;
        D2 := Day * 500;
        R := D1 + D2;
        Dec := R;
        Observer.Observe('large_sum', Format(Dec, 0, 9));
        R := D1 - D2;
        Dec := R;
        Observer.Observe('large_diff', Format(Dec, 0, 9));
        R := D2 - D1;
        Dec := R;
        Observer.Observe('large_diff_negative', Format(Dec, 0, 9));
        Observer.Expect('large_sum', '129600000000');
        Observer.Expect('large_diff', '43200000000');
        Observer.Expect('large_diff_negative', '-43200000000');
        Observer.Verify();
    end;
}
