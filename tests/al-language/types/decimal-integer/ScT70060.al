// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70060
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Conversions between Integer, BigInteger, Decimal, Boolean, Byte, Char, Text
// BC versions: 29 (27 and 28 by CI)

codeunit 70060 "LT ScT Conversions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Boolean_ToInteger()
    var
        Observer: Codeunit "Probe Observer";
        B: Boolean;
        I: Integer;
        D: Decimal;
    begin
        B := true;
        Evaluate(I, Format(B, 0, 2));
        Observer.Observe('true_num', Format(I));
        Observer.Observe('true_fmt2', Format(B, 0, 2));
        Observer.Observe('false_fmt2', Format(false, 0, 2));
        Observer.Observe('eval_true_int', Format(Evaluate(I, 'true')));
        Observer.Observe('eval_false_int', Format(Evaluate(I, 'false')));
        Observer.Observe('eval_bool_1', Format(Evaluate(B, '1')));
        Observer.Observe('eval_bool_1_v', Format(B));
        Observer.Observe('eval_bool_0', Format(Evaluate(B, '0')));
        Observer.Observe('eval_bool_0_v', Format(B));
        Observer.Observe('eval_bool_2', Format(Evaluate(B, '2')));
        Observer.Observe('eval_bool_Yes', Format(Evaluate(B, 'Yes')));
        Observer.Observe('eval_bool_Yes_v', Format(B));
        Observer.Observe('eval_bool_No', Format(Evaluate(B, 'No')));
        Observer.Observe('eval_bool_No_v', Format(B));
        Observer.Observe('eval_bool_TRUE', Format(Evaluate(B, 'TRUE')));
        Observer.Observe('eval_bool_TRUE_v', Format(B));
        Observer.Observe('eval_bool_False', Format(Evaluate(B, 'False')));
        Observer.Observe('eval_bool_False_v', Format(B));
        Observer.Observe('eval_bool_empty', Format(Evaluate(B, '')));
        Observer.Observe('eval_bool_abc', Format(Evaluate(B, 'abc')));
        Observer.Observe('eval_bool_ja', Format(Evaluate(B, 'Ja')));
        Observer.Observe('eval_bool_t', Format(Evaluate(B, 'T')));
        Observer.Expect('true_num', '1');
        Observer.Expect('true_fmt2', '1');
        Observer.Expect('false_fmt2', '0');
        Observer.Expect('eval_true_int', 'No');
        Observer.Expect('eval_false_int', 'No');
        Observer.Expect('eval_bool_1', 'Yes');
        Observer.Expect('eval_bool_1_v', 'Yes');
        Observer.Expect('eval_bool_0', 'Yes');
        Observer.Expect('eval_bool_0_v', 'No');
        Observer.Expect('eval_bool_2', 'No');
        Observer.Expect('eval_bool_Yes', 'Yes');
        Observer.Expect('eval_bool_Yes_v', 'Yes');
        Observer.Expect('eval_bool_No', 'Yes');
        Observer.Expect('eval_bool_No_v', 'No');
        Observer.Expect('eval_bool_TRUE', 'Yes');
        Observer.Expect('eval_bool_TRUE_v', 'Yes');
        Observer.Expect('eval_bool_False', 'Yes');
        Observer.Expect('eval_bool_False_v', 'No');
        Observer.Expect('eval_bool_empty', 'No');
        Observer.Expect('eval_bool_abc', 'No');
        Observer.Expect('eval_bool_ja', 'No');
        Observer.Expect('eval_bool_t', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_FromNumber()
    var
        Observer: Codeunit "Probe Observer";
        B: Boolean;
        V: Variant;
    begin
        V := 1;
        B := V;
        Observer.Observe('variant_int_1', Format(B));
        V := 0;
        B := V;
        Observer.Observe('variant_int_0', Format(B));
        V := 2;
        B := V;
        Observer.Observe('variant_int_2', 'no error');
        V := true;
        Observer.Observe('variant_bool_is_boolean', Format(V.IsBoolean()));
        Observer.Observe('variant_bool_is_integer', Format(V.IsInteger()));
        V := 1;
        Observer.Observe('variant_int_is_boolean', Format(V.IsBoolean()));
        Observer.Expect('variant_int_1', 'Yes');
        Observer.Expect('variant_int_0', 'No');
        Observer.Expect('variant_int_2', 'no error');
        Observer.Expect('variant_bool_is_boolean', 'Yes');
        Observer.Expect('variant_bool_is_integer', 'No');
        Observer.Expect('variant_int_is_boolean', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_ToDecimalAndBack()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        D: Decimal;
        B: BigInteger;
    begin
        I := 42;
        D := I;
        Observer.Observe('int_dec', Format(D));
        D := 42.0;
        I := D;
        Observer.Observe('dec_int', Format(I));
        D := 42.1;
        asserterror I := D;
        Observer.ObserveError('dec_frac_int');
        Evaluate(D, '3000000000');
        asserterror I := D;
        Observer.ObserveError('dec_big_int');
        B := D;
        Observer.Observe('dec_big', Format(B));
        D := -42.9;
        asserterror I := D;
        Observer.ObserveError('neg_frac');
        Observer.Observe('truncate_round', Format(Round(D, 1, '<')));
        I := Round(D, 1, '=');
        Observer.Observe('round_nearest_int', Format(I));
        Observer.Expect('int_dec', '42');
        Observer.Expect('dec_int', '42');
        Observer.Expect('dec_frac_int|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 42.1 to System.Int32.');
        Observer.Expect('dec_frac_int|code', 'ConversionCast');
        Observer.Expect('dec_big_int|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3000000000 to System.Int32.');
        Observer.Expect('dec_big_int|code', 'ConversionCast');
        Observer.Expect('dec_big', '3000000000');
        Observer.Expect('neg_frac|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -42.9 to System.Int32.');
        Observer.Expect('neg_frac|code', 'ConversionCast');
        Observer.Expect('truncate_round', '-42');
        Observer.Expect('round_nearest_int', '-43');
        Observer.Verify();
    end;

    [Test]
    procedure Byte_Conversions()
    var
        Observer: Codeunit "Probe Observer";
        By: Byte;
        I: Integer;
    begin
        I := 255;
        By := I;
        Observer.Observe('255', Format(By));
        I := 256;
        asserterror By := I;
        Observer.ObserveError('256');
        I := -1;
        asserterror By := I;
        Observer.ObserveError('neg1');
        By := 255;
        I := By + 1;
        Observer.Observe('byte_plus_int', Format(I));
        asserterror By := By + 1;
        Observer.ObserveError('byte_inc');
        By := 0;
        asserterror By := By - 1;
        Observer.ObserveError('byte_dec');
        By := 16;
        Observer.Observe('byte_mul', Format(By * 16));
        Observer.Observe('byte_div', Format(By div 3));
        Observer.Observe('byte_mod', Format(By mod 3));
        Observer.Observe('byte_default', Format(Dflt()));
        Observer.Expect('255', ' ');
        Observer.Expect('256|text', 'Overflow under conversion of System.Int32 value 256 to System.Byte.');
        Observer.Expect('256|code', 'ConversionCast');
        Observer.Expect('neg1|text', 'Overflow under conversion of System.Int32 value -1 to System.Byte.');
        Observer.Expect('neg1|code', 'ConversionCast');
        Observer.Expect('byte_plus_int', '256');
        Observer.Expect('byte_inc|text', 'Overflow under conversion of System.Int32 value 256 to System.Byte.');
        Observer.Expect('byte_inc|code', 'ConversionCast');
        Observer.Expect('byte_dec|text', 'Overflow under conversion of System.Int32 value -1 to System.Byte.');
        Observer.Expect('byte_dec|code', 'ConversionCast');
        Observer.Expect('byte_mul', '256');
        Observer.Expect('byte_div', '5');
        Observer.Expect('byte_mod', '1');
        Observer.Expect('byte_default', '\u0000');
        Observer.Verify();
    end;

    local procedure Dflt(): Byte
    var
        B: Byte;
    begin
        exit(B);
    end;

    [Test]
    procedure Text_ToNumbers()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        D: Decimal;
        B: BigInteger;
    begin
        Observer.Observe('int_text', Format(Evaluate(I, '12')) + '|' + Format(I));
        Observer.Observe('dec_text', Format(Evaluate(D, '12.5')) + '|' + Format(D));
        Observer.Observe('big_text', Format(Evaluate(B, '12')) + '|' + Format(B));
        I := 3;
        Observer.Observe('int_format_concat', 'v=' + Format(I));
        Observer.Observe('int_in_text_fmt', StrSubstNo('%1-%2', I, 2.5));
        Observer.Observe('subst_bool', StrSubstNo('%1/%2', true, false));
        Observer.Observe('subst_dec', StrSubstNo('%1', 1234567.891));
        Observer.Observe('subst_neg', StrSubstNo('%1', -0.5));
        Observer.Observe('subst_pad', StrSubstNo('%1', 7, 5));
        Observer.Observe('subst_pad_len', StrSubstNo('%1%2', 7, 5));
        Observer.Expect('int_text', 'Yes|12');
        Observer.Expect('dec_text', 'Yes|12.5');
        Observer.Expect('big_text', 'Yes|12');
        Observer.Expect('int_format_concat', 'v=3');
        Observer.Expect('int_in_text_fmt', '3-2.5');
        Observer.Expect('subst_bool', 'Yes/No');
        Observer.Expect('subst_dec', '1,234,567.891');
        Observer.Expect('subst_neg', '-0.5');
        Observer.Expect('subst_pad', '7');
        Observer.Expect('subst_pad_len', '75');
        Observer.Verify();
    end;
}
