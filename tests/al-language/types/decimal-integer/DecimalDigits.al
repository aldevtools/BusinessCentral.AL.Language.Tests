// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Operands are built with Evaluate from text so that no literal-length compile rule applies; results are printed with Format(x, 0, 9) (XML format, all digits).
// Writer QE (2026-10-20), QE_* tests: every result (sum, difference, product, quotient, BigInteger converted to Decimal) keeps
// 18 significant digits, rounded half away from zero, the same for negative results, mixed signs and BigInteger operands
// (Power(2, 62) and a BigInteger of 19 digits both hold 4611686018427387900). A product is rounded too: 1234.56 * (1/3) equals
// 411.52. Below 1E-18 the value keeps its digits, but Format(x, 0, 9) shows at most 18 decimals and shows '-0' for a negative
// value that rounds to zero there.

codeunit 73232 "LT P163 Decimal Digits"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure D(Value: Text): Decimal
    var
        Result: Decimal;
    begin
        if not Evaluate(Result, Value, 9) then
            exit(-999999);
        exit(Result);
    end;

    local procedure F(Value: Decimal): Text
    begin
        exit(Format(Value, 0, 9));
    end;

    [Test]
    procedure P163_Decimal_Operands_RoundTrip()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('18_decimals', F(D('0.123456789012345678')));
        Observer.Observe('19_decimals', F(D('0.1234567890123456789')));
        Observer.Observe('28_decimals', F(D('0.1234567890123456789012345678')));
        Observer.Observe('29_decimals', F(D('0.12345678901234567890123456789')));
        Observer.Observe('28_digits_integer_part', F(D('1234567890123456789012345678')));
        Observer.Observe('1_plus_17_decimals', F(D('1.12345678901234567')));
        Observer.Observe('20_digits_total', F(D('12345678901234567890')));
        Observer.Observe('10_decimals_with_7_integer_digits', F(D('1234567.1234567890')));
        Observer.Expect('18_decimals', '0.123456789012345678');
        Observer.Expect('19_decimals', '0.123456789012345678');
        Observer.Expect('28_decimals', '0.123456789012345678');
        Observer.Expect('29_decimals', '0.123456789012345678');
        Observer.Expect('28_digits_integer_part', '-999999');
        Observer.Expect('1_plus_17_decimals', '1.12345678901234567');
        Observer.Expect('20_digits_total', '-999999');
        Observer.Expect('10_decimals_with_7_integer_digits', '1234567.123456789');
        Observer.Verify();
    end;

    [Test]
    procedure P163_Decimal_Division_SignificantDigits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1_3', F(D('1') / D('3')));
        Observer.Observe('2_3', F(D('2') / D('3')));
        Observer.Observe('10_3', F(D('10') / D('3')));
        Observer.Observe('100_3', F(D('100') / D('3')));
        Observer.Observe('1000000_3', F(D('1000000') / D('3')));
        Observer.Observe('1e12_3', F(D('1000000000000') / D('3')));
        Observer.Observe('1_7', F(D('1') / D('7')));
        Observer.Observe('1_3000', F(D('1') / D('3000')));
        Observer.Observe('1_3000000', F(D('1') / D('3000000')));
        Observer.Observe('1_30000000000', F(D('1') / D('30000000000')));
        Observer.Observe('neg_2_3', F(D('-2') / D('3')));
        Observer.Observe('1_8', F(D('1') / D('8')));
        Observer.Observe('1_1024', F(D('1') / D('1024')));
        Observer.Observe('big_by_small', F(D('123456789012345678') / D('7')));
        Observer.Observe('small_decimals_by_3', F(D('0.000000000000000001') / D('3')));
        Observer.Expect('1_3', '0.333333333333333333');
        Observer.Expect('2_3', '0.666666666666666667');
        Observer.Expect('10_3', '3.33333333333333333');
        Observer.Expect('100_3', '33.3333333333333333');
        Observer.Expect('1000000_3', '333333.333333333333');
        Observer.Expect('1e12_3', '333333333333.333333');
        Observer.Expect('1_7', '0.142857142857142857');
        Observer.Expect('1_3000', '0.000333333333333333');
        Observer.Expect('1_3000000', '0.000000333333333333');
        Observer.Expect('1_30000000000', '0.000000000033333333');
        Observer.Expect('neg_2_3', '-0.666666666666666667');
        Observer.Expect('1_8', '0.125');
        Observer.Expect('1_1024', '0.0009765625');
        Observer.Expect('big_by_small', '-142857');
        Observer.Expect('small_decimals_by_3', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P163_Decimal_Multiplication_KeepsDigits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('18x18_decimals', F(D('0.123456789012345678') * D('0.123456789012345678')));
        Observer.Observe('14x14_decimals', F(D('0.12345678901234') * D('0.12345678901234')));
        Observer.Observe('10x10_decimals', F(D('0.1234567890') * D('0.1234567890')));
        asserterror Observer.Observe('big_x_big', F(D('123456789012') * D('123456789012')));
        Observer.ObserveError('af74');
        asserterror Observer.Observe('big_x_fraction', F(D('123456789.123456789') * D('987654321.987654321')));
        Observer.ObserveError('af76');
        Observer.Observe('third_times_3', F((D('1') / D('3')) * D('3')));
        Observer.Observe('third_times_third', F((D('1') / D('3')) * (D('1') / D('3'))));
        Observer.Expect('18x18_decimals', '0.015241578753238837');
        Observer.Expect('14x14_decimals', '0.015241578753237435');
        Observer.Expect('10x10_decimals', '0.015241578750190521');
        Observer.Expect('af74|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 15,241,578,753,153,483,900,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('af74|code', 'OutsidePermittedRange');
        Observer.Expect('af76|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 121,932,631,356,500,531. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('af76|code', 'OutsidePermittedRange');
        Observer.Expect('third_times_3', '0.999999999999999999');
        Observer.Expect('third_times_third', '0.111111111111111111');
        Observer.Verify();
    end;

    [Test]
    procedure P163_Decimal_AddSubtract_KeepsDigits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('add_18_decimals', F(D('0.123456789012345678') + D('0.000000000000000001')));
        Observer.Observe('add_28_decimals', F(D('0.1234567890123456789012345678') + D('0.0000000000000000000000000001')));
        Observer.Observe('add_big', F(D('12345678901234567890') + D('0.12345678')));
        Observer.Observe('sub_big', F(D('12345678901234567890.5') - D('0.25')));
        Observer.Observe('sub_to_zero', F(D('0.1234567890123456789') - D('0.1234567890123456789')));
        Observer.Observe('third_plus_third', F((D('1') / D('3')) + (D('1') / D('3'))));
        Observer.Observe('third_plus_third_plus_third', F((D('1') / D('3')) + (D('1') / D('3')) + (D('1') / D('3'))));
        Observer.Observe('add_third_to_big', F(D('100000000') + (D('1') / D('3'))));
        Observer.Expect('add_18_decimals', '0.123456789012345679');
        Observer.Expect('add_28_decimals', '0.123456789012345678');
        Observer.Expect('add_big', '-999998.87654322');
        Observer.Expect('sub_big', '-999999.25');
        Observer.Expect('sub_to_zero', '0');
        Observer.Expect('third_plus_third', '0.666666666666666666');
        Observer.Expect('third_plus_third_plus_third', '0.999999999999999999');
        Observer.Expect('add_third_to_big', '100000000.333333333');
        Observer.Verify();
    end;

    [Test]
    procedure P163_Decimal_PowerAndRound()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('2_pow_0_5', F(Power(2, 0.5)));
        Observer.Observe('2_pow_minus_1', F(Power(2, -1)));
        Observer.Observe('3_pow_minus_1', F(Power(3, -1)));
        asserterror Observer.Observe('10_pow_20', F(Power(10, 20)));
        Observer.ObserveError('af106');
        Observer.Observe('1_1_pow_30', F(Power(1.1, 30)));
        Observer.Observe('round_third_to_10', F(Round(D('1') / D('3'), 0.0000000001)));
        Observer.Observe('round_third_default', F(Round(D('1') / D('3'))));
        Observer.Observe('format_third_default', Format(D('1') / D('3')));
        Observer.Observe('format_third_precision_20', Format(D('1') / D('3'), 0, '<Precision,18:18><Standard Format,2>'));
        Observer.Observe('format_big_default', Format(D('12345678901234567890.123456')));
        Observer.Expect('2_pow_0_5', '1.4142135623731');
        Observer.Expect('2_pow_minus_1', '0.5');
        Observer.Expect('3_pow_minus_1', '0.333333333333333');
        Observer.Expect('af106|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 100,000,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('af106|code', 'OutsidePermittedRange');
        Observer.Expect('1_1_pow_30', '17.4494022688864073');
        Observer.Expect('round_third_to_10', '0.3333333333');
        Observer.Expect('round_third_default', '0.33');
        Observer.Expect('format_third_default', '0.333333333333333333');
        Observer.Expect('format_third_precision_20', '0.333333333333333333');
        Observer.Expect('format_big_default', '-999,999');
        Observer.Verify();
    end;

    // ── Added by writer QE (2026-10-20): results of more than 18 significant digits that are negative, mix signs, take a
    // BigInteger operand, or come from a product or quotient. Base Application's currency code multiplies amounts by a
    // factor of 18 significant digits (Amount * CurrencyFactor, then Round), which gives such products.

    [Test]
    procedure QE_Decimal_SumDifference_SignsAndTies()
    var
        Observer: Codeunit "Probe Observer";
        P62: Decimal;
        N62: Decimal;
    begin
        P62 := Power(2, 62);
        N62 := -P62;
        Observer.Observe('p62_minus_bigint', F(P62 - 4611686018427387904L));
        Observer.Observe('pos +1 back', F((P62 + 1) - P62));
        Observer.Observe('pos +11 back', F((P62 + 11) - P62));
        Observer.Observe('pos +6 back', F((P62 + 6) - P62));
        Observer.Observe('pos -1 back', F((P62 - 1) - P62));
        Observer.Observe('pos -11 back', F((P62 - 11) - P62));
        Observer.Observe('neg -1 back', F((N62 - 1) - N62));
        Observer.Observe('neg -11 back', F((N62 - 11) - N62));
        Observer.Observe('neg -6 back', F((N62 - 6) - N62));
        Observer.Observe('neg +1 back', F((N62 + 1) - N62));
        Observer.Observe('neg +11 back', F((N62 + 11) - N62));
        Observer.Observe('neg -1 = neg', Format(N62 - 1 = N62));
        Observer.Observe('neg -1 plus pos', F((N62 - 1) + P62));
        Observer.Observe('neg -11 plus pos', F((N62 - 11) + P62));
        Observer.Observe('pos plus -1 literal', F((P62 + (-1)) - P62));
        Observer.Observe('-1 plus pos', F((-1 + P62) - P62));
        Observer.Observe('half+0.999999999999999985', F(D('0.5') + D('0.999999999999999985')));
        Observer.Observe('-half-0.999999999999999985', F(D('-0.5') - D('0.999999999999999985')));
        Observer.Observe('-half+-0.999999999999999985', F(D('-0.5') + D('-0.999999999999999985')));
        Observer.Observe('half+0.999999999999999975', F(D('0.5') + D('0.999999999999999975')));
        Observer.Observe('-half-0.999999999999999975', F(D('-0.5') - D('0.999999999999999975')));
        Observer.Observe('half+0.999999999999999999', F(D('0.5') + D('0.999999999999999999')));
        Observer.Observe('-half-0.999999999999999999', F(D('-0.5') - D('0.999999999999999999')));
        Observer.Observe('0.999999999999999999-(-half)', F(D('0.999999999999999999') - D('-0.5')));
        Observer.Observe('-0.999999999999999999+half', F(D('-0.999999999999999999') + D('0.5')));
        Observer.Observe('-1-2/3', F(D('-1') - (D('2') / D('3'))));
        Observer.Observe('1+2/3', F(D('1') + (D('2') / D('3'))));
        Observer.Observe('-1234.56-1/3', F(D('-1234.56') - (D('1') / D('3'))));
        Observer.Observe('1234.56+1/3', F(D('1234.56') + (D('1') / D('3'))));
        Observer.Observe('-1/3-1/3-1/3', F(-(D('1') / D('3')) - (D('1') / D('3')) - (D('1') / D('3'))));
        Observer.Observe('-100000000-1/3', F(D('-100000000') - (D('1') / D('3'))));
        Observer.Observe('-0.123456789012345678-1e-18', F(D('-0.123456789012345678') - D('0.000000000000000001')));
        Observer.Observe('round -1.5ish', F(Round(D('-0.5') - D('0.999999999999999985'), 0.00000000000000001)));
        Observer.Expect('p62_minus_bigint', '0');
        Observer.Expect('pos +1 back', '0');
        Observer.Expect('pos +11 back', '10');
        Observer.Expect('pos +6 back', '10');
        Observer.Expect('pos -1 back', '0');
        Observer.Expect('pos -11 back', '-10');
        Observer.Expect('neg -1 back', '0');
        Observer.Expect('neg -11 back', '-10');
        Observer.Expect('neg -6 back', '-10');
        Observer.Expect('neg +1 back', '0');
        Observer.Expect('neg +11 back', '10');
        Observer.Expect('neg -1 = neg', 'Yes');
        Observer.Expect('neg -1 plus pos', '0');
        Observer.Expect('neg -11 plus pos', '-10');
        Observer.Expect('pos plus -1 literal', '0');
        Observer.Expect('-1 plus pos', '0');
        Observer.Expect('half+0.999999999999999985', '1.49999999999999999');
        Observer.Expect('-half-0.999999999999999985', '-1.49999999999999999');
        Observer.Expect('-half+-0.999999999999999985', '-1.49999999999999999');
        Observer.Expect('half+0.999999999999999975', '1.49999999999999998');
        Observer.Expect('-half-0.999999999999999975', '-1.49999999999999998');
        Observer.Expect('half+0.999999999999999999', '1.5');
        Observer.Expect('-half-0.999999999999999999', '-1.5');
        Observer.Expect('0.999999999999999999-(-half)', '1.5');
        Observer.Expect('-0.999999999999999999+half', '-0.499999999999999999');
        Observer.Expect('-1-2/3', '-1.66666666666666667');
        Observer.Expect('1+2/3', '1.66666666666666667');
        Observer.Expect('-1234.56-1/3', '-1234.89333333333333');
        Observer.Expect('1234.56+1/3', '1234.89333333333333');
        Observer.Expect('-1/3-1/3-1/3', '-0.999999999999999999');
        Observer.Expect('-100000000-1/3', '-100000000.333333333');
        Observer.Expect('-0.123456789012345678-1e-18', '-0.123456789012345679');
        Observer.Expect('round -1.5ish', '-1.49999999999999999');
        Observer.Verify();
    end;

    [Test]
    procedure QE_Decimal_BigIntegerOperands()
    var
        Observer: Codeunit "Probe Observer";
        P62: Decimal;
        Dec: Decimal;
        B1: BigInteger;
        B62: BigInteger;
        B62p1: BigInteger;
        BI: BigInteger;
    begin
        P62 := Power(2, 62);
        B1 := 1;
        B62 := 4611686018427387904L;
        B62p1 := 4611686018427387905L;
        Observer.Observe('p62 + b1 = p62', Format(P62 + B1 = P62));
        Observer.Observe('p62 + b1 back', F((P62 + B1) - P62));
        Observer.Observe('p62 + 11*b1 back', F((P62 + 11 * B1) - P62));
        Observer.Observe('-p62 - b1 back', F((-P62 - B1) + P62));
        Observer.Observe('-p62 - 11*b1 back', F((-P62 - 11 * B1) + P62));
        Observer.Observe('b62p1 = p62', Format(B62p1 = P62));
        Observer.Observe('p62 = b62p1', Format(P62 = B62p1));
        Observer.Observe('b62p1 > p62', Format(B62p1 > P62));
        Observer.Observe('p62 < b62p1', Format(P62 < B62p1));
        Observer.Observe('b62 = p62', Format(B62 = P62));
        Observer.Observe('-b62p1 = -p62', Format(-B62p1 = -P62));
        Observer.Observe('-b62p1 < -p62', Format(-B62p1 < -P62));
        Observer.Observe('b62p1 - p62', F(B62p1 - P62));
        Observer.Observe('p62 - b62p1', F(P62 - B62p1));
        Observer.Observe('-b62p1 + p62', F(-B62p1 + P62));
        Observer.Observe('b62p1 - b62 (bigint)', Format(B62p1 - B62));
        Dec := B62p1;
        Observer.Observe('dec := b62p1, back', F(Dec - P62));
        Dec := -B62p1;
        Observer.Observe('dec := -b62p1, back', F(Dec + P62));
        Observer.Observe('b62p1 + 0.5 back', F((B62p1 + 0.5) - P62));
        Observer.Observe('-b62p1 - 0.5 back', F((-B62p1 - 0.5) + P62));
        Observer.Observe('b62 + 0.5 back', F((B62 + 0.5) - P62));
        Observer.Observe('-b62 - 0.5 back', F((-B62 - 0.5) + P62));
        BI := P62 + 1;
        Observer.Observe('bi := p62 + 1', Format(BI));
        BI := -P62 - 1;
        Observer.Observe('bi := -p62 - 1', Format(BI));
        BI := B62p1 + 0.5;
        Observer.Observe('bi := b62p1 + 0.5', Format(BI));
        BI := -B62p1 - 0.5;
        Observer.Observe('bi := -b62p1 - 0.5', Format(BI));
        Observer.Observe('frac + 1000*b1', F(D('0.123456789012345678') + 1000 * B1));
        Observer.Observe('-frac - 1000*b1', F(D('-0.123456789012345678') - 1000 * B1));
        Observer.Observe('frac + 1000 int', F(D('0.123456789012345678') + 1000));
        Observer.Observe('-frac - 1000 int', F(D('-0.123456789012345678') - 1000));
        Observer.Observe('third * 1234567 b', F((D('1') / D('3')) * (B1 * 1234567)));
        Observer.Observe('third * -1234567 b', F((D('1') / D('3')) * (B1 * -1234567)));
        Observer.Observe('b62p1 / 3 back', F(B62p1 / 3 - 1537228672809129301L));
        Observer.Observe('-b62p1 / 3 back', F(-B62p1 / 3 + 1537228672809129301L));
        Observer.Expect('p62 + b1 = p62', 'Yes');
        Observer.Expect('p62 + b1 back', '0');
        Observer.Expect('p62 + 11*b1 back', '10');
        Observer.Expect('-p62 - b1 back', '0');
        Observer.Expect('-p62 - 11*b1 back', '-10');
        Observer.Expect('b62p1 = p62', 'No');
        Observer.Expect('p62 = b62p1', 'No');
        Observer.Expect('b62p1 > p62', 'Yes');
        Observer.Expect('p62 < b62p1', 'Yes');
        Observer.Expect('b62 = p62', 'Yes');
        Observer.Expect('-b62p1 = -p62', 'No');
        Observer.Expect('-b62p1 < -p62', 'Yes');
        Observer.Expect('b62p1 - p62', '10');
        Observer.Expect('p62 - b62p1', '-10');
        Observer.Expect('-b62p1 + p62', '-10');
        Observer.Expect('b62p1 - b62 (bigint)', '1');
        Observer.Expect('dec := b62p1, back', '10');
        Observer.Expect('dec := -b62p1, back', '-10');
        Observer.Expect('b62p1 + 0.5 back', '10');
        Observer.Expect('-b62p1 - 0.5 back', '-10');
        Observer.Expect('b62 + 0.5 back', '0');
        Observer.Expect('-b62 - 0.5 back', '0');
        Observer.Expect('bi := p62 + 1', '4611686018427387900');
        Observer.Expect('bi := -p62 - 1', '-4611686018427387900');
        Observer.Expect('bi := b62p1 + 0.5', '4611686018427387910');
        Observer.Expect('bi := -b62p1 - 0.5', '-4611686018427387910');
        Observer.Expect('frac + 1000*b1', '1000.12345678901235');
        Observer.Expect('-frac - 1000*b1', '-1000.12345678901235');
        Observer.Expect('frac + 1000 int', '1000.12345678901235');
        Observer.Expect('-frac - 1000 int', '-1000.12345678901235');
        Observer.Expect('third * 1234567 b', '411522.333333333333');
        Observer.Expect('third * -1234567 b', '-411522.333333333333');
        Observer.Expect('b62p1 / 3 back', '0');
        Observer.Expect('-b62p1 / 3 back', '0');
        Observer.Verify();
    end;

    [Test]
    procedure QE_Decimal_Products_SignsAndRound()
    var
        Observer: Codeunit "Probe Observer";
        T: Decimal;
        Factor: Decimal;
        P: Decimal;
    begin
        T := D('1') / D('3');
        Factor := D('100') / D('64.8824');
        Observer.Observe('factor', F(Factor));
        Observer.Observe('1234.56*t', F(D('1234.56') * T));
        Observer.Observe('-1234.56*t', F(D('-1234.56') * T));
        Observer.Observe('1234.56*-t', F(D('1234.56') * -T));
        Observer.Observe('-1234.56*-t', F(D('-1234.56') * -T));
        Observer.Observe('1234.56*t = 411.52', Format(D('1234.56') * T = 411.52));
        Observer.Observe('-1234.56*t = -411.52', Format(D('-1234.56') * T = -411.52));
        Observer.Observe('1234.56*t - 411.52', F(D('1234.56') * T - 411.52));
        Observer.Observe('-1234.56*t + 411.52', F(D('-1234.56') * T + 411.52));
        Observer.Observe('6.015*t', F(D('6.015') * T));
        Observer.Observe('-6.015*t', F(D('-6.015') * T));
        Observer.Observe('round 6.015*t', F(Round(D('6.015') * T, 0.01)));
        Observer.Observe('round -6.015*t', F(Round(D('-6.015') * T, 0.01)));
        Observer.Observe('round 6.015*-t', F(Round(D('6.015') * -T, 0.01)));
        Observer.Observe('6.015*t = 2.005', Format(D('6.015') * T = 2.005));
        Observer.Observe('-6.015*t = -2.005', Format(D('-6.015') * T = -2.005));
        P := D('6.015') * T;
        Observer.Observe('var 6.015*t', F(P));
        Observer.Observe('round var 6.015*t', F(Round(P, 0.01)));
        P := D('-6.015') * T;
        Observer.Observe('var -6.015*t', F(P));
        Observer.Observe('round var -6.015*t', F(Round(P, 0.01)));
        Observer.Observe('var -6.015*t = -2.005', Format(P = -2.005));
        Observer.Observe('123456.789*t', F(D('123456.789') * T));
        Observer.Observe('-123456.789*t', F(D('-123456.789') * T));
        Observer.Observe('-123456.789*t + 41152.263', F(D('-123456.789') * T + 41152.263));
        Observer.Observe('-1234.56*factor', F(D('-1234.56') * Factor));
        Observer.Observe('1234.56*factor', F(D('1234.56') * Factor));
        Observer.Observe('round -1234.56*factor', F(Round(D('-1234.56') * Factor, 0.01)));
        Observer.Observe('-1234.56*factor + 1902.76561902765619', F(D('-1234.56') * Factor + 1902.76561902765619));
        Observer.Observe('0.333333333333333329*0.5', F(D('0.333333333333333329') * D('0.5')));
        Observer.Observe('-0.333333333333333329*0.5', F(D('-0.333333333333333329') * D('0.5')));
        Observer.Observe('0.333333333333333331*0.5', F(D('0.333333333333333331') * D('0.5')));
        Observer.Observe('-0.333333333333333331*0.5', F(D('-0.333333333333333331') * D('0.5')));
        Observer.Observe('-0.333333333333333329*0.5 = -0.166666666666666665', Format(D('-0.333333333333333329') * D('0.5') = -0.166666666666666665));
        Observer.Observe('-third*third', F(-T * T));
        Observer.Observe('-2/3*2/3', F(-(D('2') / D('3')) * (D('2') / D('3'))));
        Observer.Observe('2/3*2/3', F((D('2') / D('3')) * (D('2') / D('3'))));
        Observer.Observe('-0.123456789012345678^2', F(D('-0.123456789012345678') * D('0.123456789012345678')));
        Observer.Observe('-7*t', F(D('-7') * T));
        Observer.Observe('-3*t', F(D('-3') * T));
        Observer.Expect('factor', '1.54125001541250015');
        Observer.Expect('1234.56*t', '411.52');
        Observer.Expect('-1234.56*t', '-411.52');
        Observer.Expect('1234.56*-t', '-411.52');
        Observer.Expect('-1234.56*-t', '411.52');
        Observer.Expect('1234.56*t = 411.52', 'Yes');
        Observer.Expect('-1234.56*t = -411.52', 'Yes');
        Observer.Expect('1234.56*t - 411.52', '0');
        Observer.Expect('-1234.56*t + 411.52', '0');
        Observer.Expect('6.015*t', '2.005');
        Observer.Expect('-6.015*t', '-2.005');
        Observer.Expect('round 6.015*t', '2.01');
        Observer.Expect('round -6.015*t', '-2.01');
        Observer.Expect('round 6.015*-t', '-2.01');
        Observer.Expect('6.015*t = 2.005', 'Yes');
        Observer.Expect('-6.015*t = -2.005', 'Yes');
        Observer.Expect('var 6.015*t', '2.005');
        Observer.Expect('round var 6.015*t', '2.01');
        Observer.Expect('var -6.015*t', '-2.005');
        Observer.Expect('round var -6.015*t', '-2.01');
        Observer.Expect('var -6.015*t = -2.005', 'Yes');
        Observer.Expect('123456.789*t', '41152.263');
        Observer.Expect('-123456.789*t', '-41152.263');
        Observer.Expect('-123456.789*t + 41152.263', '0');
        Observer.Expect('-1234.56*factor', '-1902.76561902765619');
        Observer.Expect('1234.56*factor', '1902.76561902765619');
        Observer.Expect('round -1234.56*factor', '-1902.77');
        Observer.Expect('-1234.56*factor + 1902.76561902765619', '0');
        Observer.Expect('0.333333333333333329*0.5', '0.166666666666666665');
        Observer.Expect('-0.333333333333333329*0.5', '-0.166666666666666665');
        Observer.Expect('0.333333333333333331*0.5', '0.166666666666666666');
        Observer.Expect('-0.333333333333333331*0.5', '-0.166666666666666666');
        Observer.Expect('-0.333333333333333329*0.5 = -0.166666666666666665', 'Yes');
        Observer.Expect('-third*third', '-0.111111111111111111');
        Observer.Expect('-2/3*2/3', '-0.444444444444444445');
        Observer.Expect('2/3*2/3', '0.444444444444444445');
        Observer.Expect('-0.123456789012345678^2', '-0.015241578753238837');
        Observer.Expect('-7*t', '-2.33333333333333333');
        Observer.Expect('-3*t', '-0.999999999999999999');
        Observer.Verify();
    end;

    [Test]
    procedure QE_Decimal_Quotients_SignsAndTies()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('-10/3', F(D('-10') / D('3')));
        Observer.Observe('10/-3', F(D('10') / D('-3')));
        Observer.Observe('-10/-3', F(D('-10') / D('-3')));
        Observer.Observe('-1e12/3', F(D('-1000000000000') / D('3')));
        Observer.Observe('-1/7', F(D('-1') / D('7')));
        Observer.Observe('-1234.56/3', F(D('-1234.56') / D('3')));
        Observer.Observe('0.333333333333333329/2', F(D('0.333333333333333329') / D('2')));
        Observer.Observe('-0.333333333333333329/2', F(D('-0.333333333333333329') / D('2')));
        Observer.Observe('0.333333333333333331/2', F(D('0.333333333333333331') / D('2')));
        Observer.Observe('-0.333333333333333331/2', F(D('-0.333333333333333331') / D('2')));
        Observer.Observe('-1234.56/64.8824', F(D('-1234.56') / D('64.8824')));
        Observer.Observe('-1/3000000', F(D('-1') / D('3000000')));
        Observer.Observe('-0.000000000000000001/3', F(D('-0.000000000000000001') / D('3')));
        Observer.Observe('-0.000000000000000002/3', F(D('-0.000000000000000002') / D('3')));
        Observer.Observe('0.000000000000000002/3', F(D('0.000000000000000002') / D('3')));
        Observer.Expect('-10/3', '-3.33333333333333333');
        Observer.Expect('10/-3', '-3.33333333333333333');
        Observer.Expect('-10/-3', '3.33333333333333333');
        Observer.Expect('-1e12/3', '-333333333333.333333');
        Observer.Expect('-1/7', '-0.142857142857142857');
        Observer.Expect('-1234.56/3', '-411.52');
        Observer.Expect('0.333333333333333329/2', '0.166666666666666665');
        Observer.Expect('-0.333333333333333329/2', '-0.166666666666666665');
        Observer.Expect('0.333333333333333331/2', '0.166666666666666666');
        Observer.Expect('-0.333333333333333331/2', '-0.166666666666666666');
        Observer.Expect('-1234.56/64.8824', '-19.0276561902765619');
        Observer.Expect('-1/3000000', '-0.000000333333333333');
        Observer.Expect('-0.000000000000000001/3', '-0');
        Observer.Expect('-0.000000000000000002/3', '-0.000000000000000001');
        Observer.Expect('0.000000000000000002/3', '0.000000000000000001');
        Observer.Verify();
    end;

    [Test]
    procedure QE_Decimal_SmallResults_DecimalPlaces()
    var
        Observer: Codeunit "Probe Observer";
        P: Decimal;
        Q: Decimal;
    begin
        Q := D('-0.000000000000000001') / D('3');
        Observer.Observe('neg tiny quotient', F(Q));
        Observer.Observe('neg tiny quotient = 0', Format(Q = 0));
        Observer.Observe('neg tiny quotient < 0', Format(Q < 0));
        Observer.Observe('neg tiny quotient default format', Format(Q));
        Observer.Observe('neg tiny quotient + 1', F(Q + 1));
        Observer.Observe('neg tiny quotient * 1000', F(Q * 1000));
        Observer.Observe('1e-18*0.5', F(D('0.000000000000000001') * D('0.5')));
        Observer.Observe('-1e-18*0.5', F(D('-0.000000000000000001') * D('0.5')));
        Observer.Observe('1e-18*0.4', F(D('0.000000000000000001') * D('0.4')));
        Observer.Observe('-1e-18*0.4', F(D('-0.000000000000000001') * D('0.4')));
        Observer.Observe('1e-10*1e-9', F(D('0.0000000001') * D('0.000000001')));
        Observer.Observe('-1e-10*1e-9', F(D('-0.0000000001') * D('0.000000001')));
        Observer.Observe('1e-10*1e-9 = 0', Format(D('0.0000000001') * D('0.000000001') = 0));
        P := D('0.123456789') * D('0.000000000123456789');
        Observer.Observe('small product', F(P));
        Observer.Observe('small product scaled up', F(P * 10000000000.0));
        P := D('-0.123456789') * D('0.000000000123456789');
        Observer.Observe('neg small product scaled up', F(P * 10000000000.0));
        Observer.Observe('small product inline scaled up', F(D('-0.123456789') * D('0.000000000123456789') * 10000000000.0));
        P := D('1') / D('30000000000');
        Observer.Observe('small quotient scaled up', F(P * 10000000000.0));
        P := D('-1') / D('30000000000');
        Observer.Observe('neg small quotient scaled up', F(P * 10000000000.0));
        Observer.Expect('neg tiny quotient', '-0');
        Observer.Expect('neg tiny quotient = 0', 'No');
        Observer.Expect('neg tiny quotient < 0', 'Yes');
        Observer.Expect('neg tiny quotient default format', '-0');
        Observer.Expect('neg tiny quotient + 1', '1');
        Observer.Expect('neg tiny quotient * 1000', '-0.000000000000000333');
        Observer.Expect('1e-18*0.5', '0.000000000000000001');
        Observer.Expect('-1e-18*0.5', '-0.000000000000000001');
        Observer.Expect('1e-18*0.4', '0');
        Observer.Expect('-1e-18*0.4', '-0');
        Observer.Expect('1e-10*1e-9', '0');
        Observer.Expect('-1e-10*1e-9', '-0');
        Observer.Expect('1e-10*1e-9 = 0', 'No');
        Observer.Expect('small product', '0.000000000015241579');
        Observer.Expect('small product scaled up', '0.15241578750190521');
        Observer.Expect('neg small product scaled up', '-0.15241578750190521');
        Observer.Expect('small product inline scaled up', '-0.15241578750190521');
        Observer.Expect('small quotient scaled up', '0.333333333333333333');
        Observer.Expect('neg small quotient scaled up', '-0.333333333333333333');
        Observer.Verify();
    end;
}
