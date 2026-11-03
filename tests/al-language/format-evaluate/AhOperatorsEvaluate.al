// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/evaluate-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-operators
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunits 78600, 78601
// Probe: (1) `a xor b or c` and `a or b xor c` without parentheses, all eight value combinations, against the two explicit groupings;
// (2) Evaluate of a Text into a Decimal with more than 18 fractional digits (zero and non-zero integer part, rounding or cutting at
// digit 19) and with exponents (corpus issue 636, items 1 and 2).
// BC versions: 27+

codeunit 78600 "LT AH Precedence"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure XorOr(A: Boolean; B: Boolean; C: Boolean): Boolean
    begin
        exit(A xor B or C);
    end;

    local procedure OrXor(A: Boolean; B: Boolean; C: Boolean): Boolean
    begin
        exit(A or B xor C);
    end;

    local procedure XorOrLeft(A: Boolean; B: Boolean; C: Boolean): Boolean
    begin
        exit((A xor B) or C);
    end;

    local procedure XorOrRight(A: Boolean; B: Boolean; C: Boolean): Boolean
    begin
        exit(A xor (B or C));
    end;

    local procedure OrXorLeft(A: Boolean; B: Boolean; C: Boolean): Boolean
    begin
        exit((A or B) xor C);
    end;

    local procedure OrXorRight(A: Boolean; B: Boolean; C: Boolean): Boolean
    begin
        exit(A or (B xor C));
    end;

    local procedure Bits(A: Boolean; B: Boolean; C: Boolean): Text
    begin
        exit(Format(A, 0, 2) + Format(B, 0, 2) + Format(C, 0, 2));
    end;

    [Test]
    procedure XorOr_AllCombinations()
    var
        Observer: Codeunit "Probe Observer";
        A: Integer;
        B: Integer;
        C: Integer;
        Combo: Text;
    begin
        for A := 0 to 1 do
            for B := 0 to 1 do
                for C := 0 to 1 do begin
                    Combo := Format(A) + Format(B) + Format(C);
                    Observer.Observe('xor_or_' + Combo, Format(XorOr(A = 1, B = 1, C = 1), 0, 2));
                    Observer.Observe('xor_or_leftgroup_' + Combo, Format(XorOrLeft(A = 1, B = 1, C = 1), 0, 2));
                    Observer.Observe('xor_or_rightgroup_' + Combo, Format(XorOrRight(A = 1, B = 1, C = 1), 0, 2));
                end;
        Observer.Expect('xor_or_000', '0');
        Observer.Expect('xor_or_leftgroup_000', '0');
        Observer.Expect('xor_or_rightgroup_000', '0');
        Observer.Expect('xor_or_001', '1');
        Observer.Expect('xor_or_leftgroup_001', '1');
        Observer.Expect('xor_or_rightgroup_001', '1');
        Observer.Expect('xor_or_010', '1');
        Observer.Expect('xor_or_leftgroup_010', '1');
        Observer.Expect('xor_or_rightgroup_010', '1');
        Observer.Expect('xor_or_011', '1');
        Observer.Expect('xor_or_leftgroup_011', '1');
        Observer.Expect('xor_or_rightgroup_011', '1');
        Observer.Expect('xor_or_100', '1');
        Observer.Expect('xor_or_leftgroup_100', '1');
        Observer.Expect('xor_or_rightgroup_100', '1');
        Observer.Expect('xor_or_101', '1');
        Observer.Expect('xor_or_leftgroup_101', '1');
        Observer.Expect('xor_or_rightgroup_101', '0');
        Observer.Expect('xor_or_110', '0');
        Observer.Expect('xor_or_leftgroup_110', '0');
        Observer.Expect('xor_or_rightgroup_110', '0');
        Observer.Expect('xor_or_111', '1');
        Observer.Expect('xor_or_leftgroup_111', '1');
        Observer.Expect('xor_or_rightgroup_111', '0');
        Observer.Verify();
    end;

    [Test]
    procedure OrXor_AllCombinations()
    var
        Observer: Codeunit "Probe Observer";
        A: Integer;
        B: Integer;
        C: Integer;
        Combo: Text;
    begin
        for A := 0 to 1 do
            for B := 0 to 1 do
                for C := 0 to 1 do begin
                    Combo := Format(A) + Format(B) + Format(C);
                    Observer.Observe('or_xor_' + Combo, Format(OrXor(A = 1, B = 1, C = 1), 0, 2));
                    Observer.Observe('or_xor_leftgroup_' + Combo, Format(OrXorLeft(A = 1, B = 1, C = 1), 0, 2));
                    Observer.Observe('or_xor_rightgroup_' + Combo, Format(OrXorRight(A = 1, B = 1, C = 1), 0, 2));
                end;
        Observer.Expect('or_xor_000', '0');
        Observer.Expect('or_xor_leftgroup_000', '0');
        Observer.Expect('or_xor_rightgroup_000', '0');
        Observer.Expect('or_xor_001', '1');
        Observer.Expect('or_xor_leftgroup_001', '1');
        Observer.Expect('or_xor_rightgroup_001', '1');
        Observer.Expect('or_xor_010', '1');
        Observer.Expect('or_xor_leftgroup_010', '1');
        Observer.Expect('or_xor_rightgroup_010', '1');
        Observer.Expect('or_xor_011', '0');
        Observer.Expect('or_xor_leftgroup_011', '0');
        Observer.Expect('or_xor_rightgroup_011', '0');
        Observer.Expect('or_xor_100', '1');
        Observer.Expect('or_xor_leftgroup_100', '1');
        Observer.Expect('or_xor_rightgroup_100', '1');
        Observer.Expect('or_xor_101', '0');
        Observer.Expect('or_xor_leftgroup_101', '0');
        Observer.Expect('or_xor_rightgroup_101', '1');
        Observer.Expect('or_xor_110', '1');
        Observer.Expect('or_xor_leftgroup_110', '1');
        Observer.Expect('or_xor_rightgroup_110', '1');
        Observer.Expect('or_xor_111', '0');
        Observer.Expect('or_xor_leftgroup_111', '0');
        Observer.Expect('or_xor_rightgroup_111', '1');
        Observer.Verify();
    end;

    [Test]
    procedure XorOr_WithAnd_AndNot()
    var
        Observer: Codeunit "Probe Observer";
        A: Integer;
        B: Integer;
        C: Integer;
        D: Integer;
        Combo: Text;
    begin
        // Four operands: a mixed chain of all three operators, to show how xor and or relate to and when chained.
        for A := 0 to 1 do
            for B := 0 to 1 do
                for C := 0 to 1 do
                    for D := 0 to 1 do begin
                        Combo := Format(A) + Format(B) + Format(C) + Format(D);
                        Observer.Observe('xor_or_xor_' + Combo, Format(Chain1(A = 1, B = 1, C = 1, D = 1), 0, 2));
                        Observer.Observe('or_xor_or_' + Combo, Format(Chain2(A = 1, B = 1, C = 1, D = 1), 0, 2));
                        Observer.Observe('xor_or_and_' + Combo, Format(Chain3(A = 1, B = 1, C = 1, D = 1), 0, 2));
                    end;
        Observer.Expect('xor_or_xor_0000', '0');
        Observer.Expect('or_xor_or_0000', '0');
        Observer.Expect('xor_or_and_0000', '0');
        Observer.Expect('xor_or_xor_0001', '1');
        Observer.Expect('or_xor_or_0001', '1');
        Observer.Expect('xor_or_and_0001', '0');
        Observer.Expect('xor_or_xor_0010', '1');
        Observer.Expect('or_xor_or_0010', '1');
        Observer.Expect('xor_or_and_0010', '0');
        Observer.Expect('xor_or_xor_0011', '0');
        Observer.Expect('or_xor_or_0011', '1');
        Observer.Expect('xor_or_and_0011', '1');
        Observer.Expect('xor_or_xor_0100', '1');
        Observer.Expect('or_xor_or_0100', '1');
        Observer.Expect('xor_or_and_0100', '1');
        Observer.Expect('xor_or_xor_0101', '0');
        Observer.Expect('or_xor_or_0101', '1');
        Observer.Expect('xor_or_and_0101', '1');
        Observer.Expect('xor_or_xor_0110', '1');
        Observer.Expect('or_xor_or_0110', '0');
        Observer.Expect('xor_or_and_0110', '1');
        Observer.Expect('xor_or_xor_0111', '0');
        Observer.Expect('or_xor_or_0111', '1');
        Observer.Expect('xor_or_and_0111', '1');
        Observer.Expect('xor_or_xor_1000', '1');
        Observer.Expect('or_xor_or_1000', '1');
        Observer.Expect('xor_or_and_1000', '1');
        Observer.Expect('xor_or_xor_1001', '0');
        Observer.Expect('or_xor_or_1001', '1');
        Observer.Expect('xor_or_and_1001', '1');
        Observer.Expect('xor_or_xor_1010', '1');
        Observer.Expect('or_xor_or_1010', '0');
        Observer.Expect('xor_or_and_1010', '1');
        Observer.Expect('xor_or_xor_1011', '0');
        Observer.Expect('or_xor_or_1011', '1');
        Observer.Expect('xor_or_and_1011', '1');
        Observer.Expect('xor_or_xor_1100', '0');
        Observer.Expect('or_xor_or_1100', '1');
        Observer.Expect('xor_or_and_1100', '0');
        Observer.Expect('xor_or_xor_1101', '1');
        Observer.Expect('or_xor_or_1101', '1');
        Observer.Expect('xor_or_and_1101', '0');
        Observer.Expect('xor_or_xor_1110', '1');
        Observer.Expect('or_xor_or_1110', '0');
        Observer.Expect('xor_or_and_1110', '0');
        Observer.Expect('xor_or_xor_1111', '0');
        Observer.Expect('or_xor_or_1111', '1');
        Observer.Expect('xor_or_and_1111', '1');
        Observer.Verify();
    end;

    local procedure Chain1(A: Boolean; B: Boolean; C: Boolean; D: Boolean): Boolean
    begin
        exit(A xor B or C xor D);
    end;

    local procedure Chain2(A: Boolean; B: Boolean; C: Boolean; D: Boolean): Boolean
    begin
        exit(A or B xor C or D);
    end;

    local procedure Chain3(A: Boolean; B: Boolean; C: Boolean; D: Boolean): Boolean
    begin
        exit(A xor B or C and D);
    end;
}

codeunit 78601 "LT AH Evaluate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Try(var Observer: Codeunit "Probe Observer"; Name: Text; Input: Text)
    var
        D: Decimal;
        Ok: Boolean;
    begin
        D := -1;
        Ok := Evaluate(D, Input);
        Observer.Observe(Name, '[' + Input + '] ' + Format(Ok) + ' ' + Format(D, 0, 9));
    end;

    [Test]
    procedure Decimal_MoreThanEighteenFractionalDigits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Try(Observer, 'zero_int_18', '0.123456789012345678');
        Try(Observer, 'zero_int_19', '0.1234567890123456789');
        Try(Observer, 'zero_int_19_round_down', '0.1234567890123456781');
        Try(Observer, 'zero_int_19_round_half', '0.1234567890123456785');
        Try(Observer, 'zero_int_21', '0.123456789012345678901');
        Try(Observer, 'zero_int_30', '0.123456789012345678901234567890');
        Try(Observer, 'nonzero_int_18', '1.123456789012345678');
        Try(Observer, 'nonzero_int_19', '1.1234567890123456789');
        Try(Observer, 'nonzero_int_19_half', '1.1234567890123456785');
        Try(Observer, 'nonzero_int_25', '3.1415926535897932384626433');
        Try(Observer, 'nonzero_int_40', '2.1234567890123456789012345678901234567890');
        Try(Observer, 'tiny_19th_digit', '0.0000000000000000009');
        Try(Observer, 'tiny_20th_digit', '0.00000000000000000001');
        Try(Observer, 'negative_19', '-0.1234567890123456789');
        Try(Observer, 'thousands_19', '1,234.1234567890123456789');
        Try(Observer, 'large_int_and_19', '123456789012345.1234567890123456789');
        Observer.Expect('zero_int_18', '[0.123456789012345678] Yes 0.123456789012345678');
        Observer.Expect('zero_int_19', '[0.1234567890123456789] Yes 0.123456789012345678');
        Observer.Expect('zero_int_19_round_down', '[0.1234567890123456781] Yes 0.123456789012345678');
        Observer.Expect('zero_int_19_round_half', '[0.1234567890123456785] Yes 0.123456789012345678');
        Observer.Expect('zero_int_21', '[0.123456789012345678901] Yes 0.123456789012345678');
        Observer.Expect('zero_int_30', '[0.123456789012345678901234567890] Yes 0.123456789012345678');
        Observer.Expect('nonzero_int_18', '[1.123456789012345678] Yes 1.12345678901234567');
        Observer.Expect('nonzero_int_19', '[1.1234567890123456789] Yes 1.12345678901234567');
        Observer.Expect('nonzero_int_19_half', '[1.1234567890123456785] Yes 1.12345678901234567');
        Observer.Expect('nonzero_int_25', '[3.1415926535897932384626433] Yes 3.14159265358979323');
        Observer.Expect('nonzero_int_40', '[2.1234567890123456789012345678901234567890] Yes 2.12345678901234567');
        Observer.Expect('tiny_19th_digit', '[0.0000000000000000009] Yes 0.000000000000000001');
        Observer.Expect('tiny_20th_digit', '[0.00000000000000000001] Yes 0');
        Observer.Expect('negative_19', '[-0.1234567890123456789] Yes -0.123456789012345678');
        Observer.Expect('thousands_19', '[1,234.1234567890123456789] Yes 1234.12345678901234');
        Observer.Expect('large_int_and_19', '[123456789012345.1234567890123456789] Yes 123456789012345.123');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Exponents()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Try(Observer, 'frac_e3_upper', '1.5E3');
        Try(Observer, 'frac_e3_lower', '1.5e3');
        Try(Observer, 'frac_plus', '1.5E+3');
        Try(Observer, 'neg_exp_lower', '1e-5');
        Try(Observer, 'neg_exp_upper', '1E-5');
        Try(Observer, 'neg_exp_frac', '2.5e-5');
        Try(Observer, 'neg_exp_underflow_18', '1e-18');
        Try(Observer, 'neg_exp_underflow_19', '1e-19');
        Try(Observer, 'neg_exp_underflow_30', '1e-30');
        Try(Observer, 'exp_mantissa_digits', '12345678901234567890E-10');
        Try(Observer, 'exp_long_mantissa', '0.1234567890123456789E1');
        Try(Observer, 'exp_big', '1e20');
        Try(Observer, 'exp_too_big', '1e40');
        Try(Observer, 'negative_mantissa', '-1.5E3');
        Try(Observer, 'exp_zero', '1E0');
        Try(Observer, 'exp_leading_zero', '1E03');
        Try(Observer, 'exp_blank_after', '1E3 ');
        Try(Observer, 'exp_fraction', '1E3.5');
        Observer.Expect('frac_e3_upper', '[1.5E3] Yes 1500');
        Observer.Expect('frac_e3_lower', '[1.5e3] Yes 1500');
        Observer.Expect('frac_plus', '[1.5E+3] Yes 1500');
        Observer.Expect('neg_exp_lower', '[1e-5] Yes 0.00001');
        Observer.Expect('neg_exp_upper', '[1E-5] Yes 0.00001');
        Observer.Expect('neg_exp_frac', '[2.5e-5] Yes 0.000025');
        Observer.Expect('neg_exp_underflow_18', '[1e-18] Yes 0.000000000000000001');
        Observer.Expect('neg_exp_underflow_19', '[1e-19] Yes 0');
        Observer.Expect('neg_exp_underflow_30', '[1e-30] Yes 0');
        Observer.Expect('exp_mantissa_digits', '[12345678901234567890E-10] Yes 1234567890.12345678');
        Observer.Expect('exp_long_mantissa', '[0.1234567890123456789E1] Yes 1.23456789012345678');
        Observer.Expect('exp_big', '[1e20] No -1');
        Observer.Expect('exp_too_big', '[1e40] No -1');
        Observer.Expect('negative_mantissa', '[-1.5E3] Yes -1500');
        Observer.Expect('exp_zero', '[1E0] Yes 1');
        Observer.Expect('exp_leading_zero', '[1E03] Yes 1000');
        Observer.Expect('exp_blank_after', '[1E3 ] Yes 1000');
        Observer.Expect('exp_fraction', '[1E3.5] No -1');
        Observer.Verify();
    end;
}
