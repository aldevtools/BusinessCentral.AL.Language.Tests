// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70051
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format of Decimals with format strings
// BC versions: 29 (27 and 28 by CI)

codeunit 70051 "LT ScT Fmt Decimal Str"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure FormatString_Precision()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := 1234.56789;
        Observer.Observe('p0', Format(D, 0, '<Precision,0:0><Standard Format,0>'));
        Observer.Observe('p2', Format(D, 0, '<Precision,2:2><Standard Format,0>'));
        Observer.Observe('p2_3', Format(D, 0, '<Precision,2:3><Standard Format,0>'));
        Observer.Observe('p0_5', Format(D, 0, '<Precision,0:5><Standard Format,0>'));
        Observer.Observe('p5_5', Format(D, 0, '<Precision,5:5><Standard Format,0>'));
        Observer.Observe('p8_8', Format(D, 0, '<Precision,8:8><Standard Format,0>'));
        Observer.Observe('p1', Format(D, 0, '<Precision,1><Standard Format,0>'));
        Observer.Observe('p3', Format(D, 0, '<Precision,3><Standard Format,0>'));
        Observer.Expect('p0', '1,235');
        Observer.Expect('p2', '1,234.57');
        Observer.Expect('p2_3', '1,234.568');
        Observer.Expect('p0_5', '1,234.56789');
        Observer.Expect('p5_5', '1,234.56789');
        Observer.Expect('p8_8', '1,234.56789000');
        Observer.Expect('p1', '1,234.6');
        Observer.Expect('p3', '1,234.568');
        Observer.Verify();
    end;

    [Test]
    procedure FormatString_PrecisionRounding()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := 2.345;
        Observer.Observe('p2_2', Format(D, 0, '<Precision,2:2><Standard Format,0>'));
        D := 2.355;
        Observer.Observe('p2_2b', Format(D, 0, '<Precision,2:2><Standard Format,0>'));
        D := -2.345;
        Observer.Observe('p2_2n', Format(D, 0, '<Precision,2:2><Standard Format,0>'));
        D := 0.5;
        Observer.Observe('p0_0', Format(D, 0, '<Precision,0:0><Standard Format,0>'));
        D := 1.5;
        Observer.Observe('p0_0b', Format(D, 0, '<Precision,0:0><Standard Format,0>'));
        D := 2.5;
        Observer.Observe('p0_0c', Format(D, 0, '<Precision,0:0><Standard Format,0>'));
        Observer.Expect('p2_2', '2.35');
        Observer.Expect('p2_2b', '2.36');
        Observer.Expect('p2_2n', '-2.35');
        Observer.Expect('p0_0', '1');
        Observer.Expect('p0_0b', '2');
        Observer.Expect('p0_0c', '3');
        Observer.Verify();
    end;

    [Test]
    procedure FormatString_Sign()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := -42.5;
        Observer.Observe('sign_pos', Format(D, 0, '<Sign><Integer><Decimals>'));
        Observer.Observe('sign_pre', Format(D, 0, '<Sign,1><Integer><Decimals>'));
        Observer.Observe('sign_post', Format(D, 0, '<Integer><Decimals><Sign,1>'));
        Observer.Observe('sign_pos_pos', Format(42.5, 0, '<Sign><Integer><Decimals>'));
        Observer.Observe('sign_pos_pre', Format(42.5, 0, '<Sign,1><Integer><Decimals>'));
        Observer.Observe('sign_pos_post', Format(42.5, 0, '<Integer><Decimals><Sign,1>'));
        Observer.Observe('sign_pre2', Format(D, 0, '<Sign,2><Integer><Decimals>'));
        Observer.Observe('sign_post2', Format(42.5, 0, '<Integer><Decimals><Sign,2>'));
        Observer.Expect('sign_pos', '-42.5');
        Observer.Expect('sign_pre', '-42.5');
        Observer.Expect('sign_post', '42.5-');
        Observer.Expect('sign_pos_pos', '42.5');
        Observer.Expect('sign_pos_pre', ' 42.5');
        Observer.Expect('sign_pos_post', '42.5 ');
        Observer.Expect('sign_pre2', ' -42.5');
        Observer.Expect('sign_post2', '42.5  ');
        Observer.Verify();
    end;

    [Test]
    procedure FormatString_Integer()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := 1234567.891;
        Observer.Observe('int', Format(D, 0, '<Integer>'));
        Observer.Observe('int_th', Format(D, 0, '<Integer Thousand>'));
        Observer.Observe('int_th_dec', Format(D, 0, '<Integer Thousand><Decimals>'));
        Observer.Observe('int_dec', Format(D, 0, '<Integer><Decimals>'));
        Observer.Observe('int_dec3', Format(D, 0, '<Integer><Decimals,4>'));
        Observer.Observe('int_dec2', Format(D, 0, '<Integer><Decimals,2>'));
        Observer.Observe('int_dec0', Format(D, 0, '<Integer><Decimals,1>'));
        Observer.Observe('int_pad', Format(D, 0, '<Integer,12><Filler Character,0>'));
        Observer.Observe('int_pad_space', Format(D, 0, '<Integer,12><Filler Character, >'));
        Observer.Observe('int_pad_x', Format(D, 0, '<Integer,12><Filler Character,x>'));
        Observer.Expect('int', '1234567');
        Observer.Expect('int_th', '1,234,567');
        Observer.Expect('int_th_dec', '1,234,567.891');
        Observer.Expect('int_dec', '1234567.891');
        Observer.Expect('int_dec3', '1234567.891');
        Observer.Expect('int_dec2', '1234567**');
        Observer.Expect('int_dec0', '1234567*');
        Observer.Expect('int_pad', '000001234567');
        Observer.Expect('int_pad_space', '     1234567');
        Observer.Expect('int_pad_x', 'xxxxx1234567');
        Observer.Verify();
    end;

    [Test]
    procedure FormatString_Separators()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := 1234567.891;
        asserterror Observer.Observe('dec_sep', Format(D, 0, '<Integer Thousand><Decimal Separator><Decimals>'));
        Observer.ObserveError('af111');
        Observer.Observe('custom_th', Format(D, 0, '<Integer Thousand,3><Decimals>'));
        Observer.Observe('text_only', Format(D, 0, 'abc'));
        Observer.Observe('text_mixed', Format(D, 0, 'x<Integer>y'));
        Observer.Observe('empty', Format(D, 0, ''));
        Observer.Observe('two_int', Format(D, 0, '<Integer>-<Integer>'));
        Observer.Observe('neg_dec', Format(-0.5, 0, '<Sign><Integer><Decimals>'));
        Observer.Observe('neg_zero_dec', Format(-0.001, 0, '<Precision,2:2><Standard Format,0>'));
        Observer.Expect('af111|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Integer Thousand><Decimal Separator><Decimals>');
        Observer.Expect('af111|code', 'InvalidFormatString');
        Observer.Expect('custom_th', '***.891');
        Observer.Expect('text_only', 'abc');
        Observer.Expect('text_mixed', 'x1234567y');
        Observer.Expect('empty', '');
        Observer.Expect('two_int', '1234567-1234567');
        Observer.Expect('neg_dec', '-0.5');
        Observer.Expect('neg_zero_dec', '-0.00');
        Observer.Verify();
    end;

    [Test]
    procedure FormatString_Invalid()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        Result: Text;
    begin
        D := 12.5;
        asserterror Result := Format(D, 0, '<Unknown>');
        Observer.ObserveError('unknown');
        asserterror Result := Format(D, 0, '<Integer');
        Observer.ObserveError('unclosed');
        asserterror Result := Format(D, 0, '<Precision,x:y>');
        Observer.ObserveError('badprec');
        asserterror Result := Format(D, 0, '<Standard Format,99>');
        Observer.ObserveError('badstd');
        asserterror Result := Format(D, 0, 10);
        Observer.ObserveError('num10');
        asserterror Result := Format(D, 0, -1);
        Observer.ObserveError('numneg');
        Observer.Expect('unknown|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Unknown>');
        Observer.Expect('unknown|code', 'InvalidFormatString');
        Observer.Expect('unclosed|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Integer');
        Observer.Expect('unclosed|code', 'InvalidFormatString');
        Observer.Expect('badprec|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Precision,x:y>');
        Observer.Expect('badprec|code', 'InvalidFormatString');
        Observer.Expect('badstd|text', 'Standard format number 99 does not exist for the type ''Decimal''.');
        Observer.Expect('badstd|code', 'InvalidStandardFormat');
        Observer.Expect('num10|text', 'Standard format number 10 does not exist for the type ''Decimal''.');
        Observer.Expect('num10|code', 'InvalidStandardFormat');
        Observer.Expect('numneg|text', 'Standard format number -1 does not exist for the type ''Decimal''.');
        Observer.Expect('numneg|code', 'InvalidStandardFormat');
        Observer.Verify();
    end;
}
