// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70059
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Round with precision and direction, Abs, Power
// BC versions: 29 (27 and 28 by CI)

codeunit 70059 "LT ScT Round"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Round_Default()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := 2.5;
        Observer.Observe('2_5', Format(Round(D)));
        D := 3.5;
        Observer.Observe('3_5', Format(Round(D)));
        D := -2.5;
        Observer.Observe('n2_5', Format(Round(D)));
        D := 0.49999;
        Observer.Observe('0_49999', Format(Round(D)));
        D := 0.5;
        Observer.Observe('0_5', Format(Round(D)));
        D := -0.5;
        Observer.Observe('n0_5', Format(Round(D)));
        D := 1234.5678;
        Observer.Observe('big', Format(Round(D)));
        Observer.Observe('zero', Format(Round(0.0)));
        Observer.Expect('2_5', '2.5');
        Observer.Expect('3_5', '3.5');
        Observer.Expect('n2_5', '-2.5');
        Observer.Expect('0_49999', '0.5');
        Observer.Expect('0_5', '0.5');
        Observer.Expect('n0_5', '-0.5');
        Observer.Expect('big', '1,234.57');
        Observer.Expect('zero', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Round_Precision()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := 1234.5678;
        Observer.Observe('p0_01', Format(Round(D, 0.01)));
        Observer.Observe('p0_1', Format(Round(D, 0.1)));
        Observer.Observe('p1', Format(Round(D, 1)));
        Observer.Observe('p5', Format(Round(D, 5)));
        Observer.Observe('p10', Format(Round(D, 10)));
        Observer.Observe('p100', Format(Round(D, 100)));
        Observer.Observe('p1000', Format(Round(D, 1000)));
        Observer.Observe('p0_05', Format(Round(D, 0.05)));
        Observer.Observe('p0_25', Format(Round(D, 0.25)));
        Observer.Observe('p0_001', Format(Round(D, 0.001)));
        Observer.Observe('p0_0001', Format(Round(D, 0.0001)));
        Observer.Observe('p0_00001', Format(Round(D, 0.00001)));
        Observer.Observe('p3', Format(Round(D, 3)));
        Observer.Observe('p7', Format(Round(D, 7)));
        Observer.Expect('p0_01', '1,234.57');
        Observer.Expect('p0_1', '1,234.6');
        Observer.Expect('p1', '1,235');
        Observer.Expect('p5', '1,235');
        Observer.Expect('p10', '1,230');
        Observer.Expect('p100', '1,200');
        Observer.Expect('p1000', '1,000');
        Observer.Expect('p0_05', '1,234.55');
        Observer.Expect('p0_25', '1,234.5');
        Observer.Expect('p0_001', '1,234.568');
        Observer.Expect('p0_0001', '1,234.5678');
        Observer.Expect('p0_00001', '1,234.5678');
        Observer.Expect('p3', '1,236');
        Observer.Expect('p7', '1,232');
        Observer.Verify();
    end;

    [Test]
    procedure Round_Directions()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := 2.345;
        Observer.Observe('nearest', Format(Round(D, 0.01, '=')));
        Observer.Observe('down', Format(Round(D, 0.01, '<')));
        Observer.Observe('up', Format(Round(D, 0.01, '>')));
        D := -2.345;
        Observer.Observe('n_nearest', Format(Round(D, 0.01, '=')));
        Observer.Observe('n_down', Format(Round(D, 0.01, '<')));
        Observer.Observe('n_up', Format(Round(D, 0.01, '>')));
        D := 2.5;
        Observer.Observe('i_nearest', Format(Round(D, 1, '=')));
        Observer.Observe('i_down', Format(Round(D, 1, '<')));
        Observer.Observe('i_up', Format(Round(D, 1, '>')));
        D := 2;
        Observer.Observe('exact_down', Format(Round(D, 1, '<')));
        Observer.Observe('exact_up', Format(Round(D, 1, '>')));
        D := 2.0000001;
        Observer.Observe('tiny_up', Format(Round(D, 1, '>')));
        D := 1234.5678;
        Observer.Observe('p100_up', Format(Round(D, 100, '>')));
        Observer.Observe('p100_down', Format(Round(D, 100, '<')));
        Observer.Observe('p0_05_up', Format(Round(D, 0.05, '>')));
        Observer.Observe('p0_05_down', Format(Round(D, 0.05, '<')));
        Observer.Expect('nearest', '2.35');
        Observer.Expect('down', '2.34');
        Observer.Expect('up', '2.35');
        Observer.Expect('n_nearest', '-2.35');
        Observer.Expect('n_down', '-2.34');
        Observer.Expect('n_up', '-2.35');
        Observer.Expect('i_nearest', '3');
        Observer.Expect('i_down', '2');
        Observer.Expect('i_up', '3');
        Observer.Expect('exact_down', '2');
        Observer.Expect('exact_up', '2');
        Observer.Expect('tiny_up', '3');
        Observer.Expect('p100_up', '1,300');
        Observer.Expect('p100_down', '1,200');
        Observer.Expect('p0_05_up', '1,234.6');
        Observer.Expect('p0_05_down', '1,234.55');
        Observer.Verify();
    end;

    [Test]
    procedure Round_Errors()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        Zero: Decimal;
        R: Decimal;
        Dir: Text;
    begin
        D := 1.5;
        Zero := 0;
        asserterror R := Round(D, Zero);
        Observer.ObserveError('zero_precision');
        Dir := 'x';
        asserterror R := Round(D, 1, Dir);
        Observer.ObserveError('bad_direction');
        Dir := '';
        asserterror R := Round(D, 1, Dir);
        Observer.ObserveError('empty_direction');
        Dir := '==';
        asserterror R := Round(D, 1, Dir);
        Observer.ObserveError('long_direction');
        Dir := '<';
        R := Round(D, 1, Dir);
        Observer.Observe('dir_var_ok', Format(R));
        asserterror R := Round(D, -1);
        Observer.Observe('neg_precision_raised', Format(GetLastErrorText() <> ''));
        ClearLastError();
        Observer.Expect('zero_precision|text', 'The value of ROUND parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('zero_precision|code', 'OutsidePermittedRange');
        Observer.Expect('bad_direction|text', 'The supplied value is not valid.');
        Observer.Expect('bad_direction|code', 'InvalidValue');
        Observer.Expect('empty_direction|text', 'The supplied value is not valid.');
        Observer.Expect('empty_direction|code', 'InvalidValue');
        Observer.Expect('long_direction|text', 'The supplied value is not valid.');
        Observer.Expect('long_direction|code', 'InvalidValue');
        Observer.Expect('dir_var_ok', '1');
        Observer.Expect('neg_precision_raised', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Round_NegativePrecision()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        P: Decimal;
    begin
        D := 1234.5678;
        P := -1;
        asserterror Observer.Observe('neg1', Format(Round(D, P)));
        Observer.ObserveError('af132');
        P := -0.01;
        asserterror Observer.Observe('neg0_01', Format(Round(D, P)));
        Observer.ObserveError('af135');
        Observer.Expect('af132|text', 'The value of ROUND parameter 2 is outside of the permitted range. The current value is: 1. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('af132|code', 'OutsidePermittedRange');
        Observer.Expect('af135|text', 'The value of ROUND parameter 2 is outside of the permitted range. The current value is: 0.01. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('af135|code', 'OutsidePermittedRange');
        Observer.Verify();
    end;

    [Test]
    procedure Round_IntegerArgs()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
    begin
        I := 1234567;
        Observer.Observe('int_p1000', Format(Round(I, 1000)));
        Observer.Observe('int_p1000_up', Format(Round(I, 1000, '>')));
        Observer.Observe('int_p1000_down', Format(Round(I, 1000, '<')));
        Evaluate(B, '5000000007');
        Observer.Observe('big_p10', Format(Round(B, 10)));
        Observer.Observe('big_p10_up', Format(Round(B, 10, '>')));
        Observer.Observe('int_div_round', Format(Round(I / 7, 0.01)));
        Observer.Expect('int_p1000', '1,235,000');
        Observer.Expect('int_p1000_up', '1,235,000');
        Observer.Expect('int_p1000_down', '1,234,000');
        Observer.Expect('big_p10', '5,000,000,010');
        Observer.Expect('big_p10_up', '5,000,000,010');
        Observer.Expect('int_div_round', '176,366.71');
        Observer.Verify();
    end;

    [Test]
    procedure Abs_Values()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        I: Integer;
        B: BigInteger;
    begin
        D := -12.345;
        Observer.Observe('dec_neg', Format(Abs(D)));
        D := 12.345;
        Observer.Observe('dec_pos', Format(Abs(D)));
        D := 0;
        Observer.Observe('dec_zero', Format(Abs(D)));
        D := -0.0000001;
        Observer.Observe('dec_tiny', Format(Abs(D), 0, 9));
        I := -2147483647;
        Observer.Observe('int_neg', Format(Abs(I)));
        I := 0;
        Observer.Observe('int_zero', Format(Abs(I)));
        Evaluate(B, '-9223372036854775807');
        Observer.Observe('big_neg', Format(Abs(B)));
        Observer.Observe('lit', Format(Abs(-5)));
        Observer.Expect('dec_neg', '12.345');
        Observer.Expect('dec_pos', '12.345');
        Observer.Expect('dec_zero', '0');
        Observer.Expect('dec_tiny', '0.0000001');
        Observer.Expect('int_neg', '2147483647');
        Observer.Expect('int_zero', '0');
        Observer.Expect('big_neg', '9223372036854775807');
        Observer.Expect('lit', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Power_Values()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        Observer.Observe('2_10', Format(Power(2, 10)));
        Observer.Observe('2_0', Format(Power(2, 0)));
        Observer.Observe('0_0', Format(Power(0, 0)));
        Observer.Observe('0_5', Format(Power(0, 5)));
        Observer.Observe('2_neg1', Format(Power(2, -1)));
        Observer.Observe('2_neg2', Format(Power(2, -2)));
        Observer.Observe('4_0_5', Format(Power(4, 0.5)));
        Observer.Observe('8_third', Format(Power(8, 1 / 3), 0, 9));
        Observer.Observe('neg2_2', Format(Power(-2, 2)));
        Observer.Observe('neg2_3', Format(Power(-2, 3)));
        Observer.Observe('1_5_2', Format(Power(1.5, 2)));
        asserterror Observer.Observe('10_18', Format(Power(10, 18)));
        Observer.ObserveError('af200');
        Observer.Observe('10_9', Format(Power(10, 9)));
        Observer.Observe('2_31', Format(Power(2, 31)));
        asserterror Observer.Observe('2_62', Format(Power(2, 62)));
        Observer.ObserveError('af205');
        asserterror Observer.Observe('2_64', Format(Power(2, 64)));
        Observer.ObserveError('af207');
        asserterror Observer.Observe('2_100', Format(Power(2, 100)));
        Observer.ObserveError('af209');
        D := Power(2, 0.5);
        Observer.Observe('sqrt2', Format(D, 0, 9));
        Observer.Expect('2_10', '1,024');
        Observer.Expect('2_0', '1');
        Observer.Expect('0_0', '1');
        Observer.Expect('0_5', '0');
        Observer.Expect('2_neg1', '0.5');
        Observer.Expect('2_neg2', '0.25');
        Observer.Expect('4_0_5', '2');
        Observer.Expect('8_third', '2');
        Observer.Expect('neg2_2', '4');
        Observer.Expect('neg2_3', '-8');
        Observer.Expect('1_5_2', '2.25');
        Observer.Expect('af200|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 1,000,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('af200|code', 'OutsidePermittedRange');
        Observer.Expect('10_9', '1,000,000,000');
        Observer.Expect('2_31', '2,147,483,648');
        Observer.Expect('af205|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 4,611,686,018,427,387,900. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('af205|code', 'OutsidePermittedRange');
        Observer.Expect('af207|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 18,446,744,073,709,551,600. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('af207|code', 'OutsidePermittedRange');
        Observer.Expect('af209|text', 'Value was either too large or too small for a Decimal.');
        Observer.Expect('af209|code', 'AL:Overflow');
        Observer.Expect('sqrt2', '1.4142135623731');
        Observer.Verify();
    end;

    [Test]
    procedure Power_Errors()
    var
        Observer: Codeunit "Probe Observer";
        Zero: Decimal;
        Neg: Decimal;
        Half: Decimal;
        R: Decimal;
    begin
        Zero := 0;
        Neg := -1;
        Half := 0.5;
        asserterror R := Power(Zero, Neg);
        Observer.ObserveError('zero_neg');
        asserterror R := Power(Neg, Half);
        Observer.ObserveError('neg_frac');
        Neg := 10;
        asserterror R := Power(Neg, 1000);
        Observer.ObserveError('overflow');
        Observer.Expect('zero_neg|text', 'Value was either too large or too small for a Decimal.');
        Observer.Expect('zero_neg|code', 'AL:Overflow');
        Observer.Expect('neg_frac|text', 'Value was either too large or too small for a Decimal.');
        Observer.Expect('neg_frac|code', 'AL:Overflow');
        Observer.Expect('overflow|text', 'Value was either too large or too small for a Decimal.');
        Observer.Expect('overflow|code', 'AL:Overflow');
        Observer.Verify();
    end;
}
