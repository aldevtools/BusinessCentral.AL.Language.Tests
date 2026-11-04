// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-method
// Scope: in-scope
// Fixtures used: none
//
// Format of a Decimal with a format string starting with <C,CODE> (Base Application's Amount
// Auto Format builds '<C,%1>' + '<Precision,2:2><Standard Format,0>'): the text for a known code,
// an unknown code, an empty code, a missing comma, other tag combinations, in the default
// language and in German (1031). A TryFunction captures text or error; GlobalLanguage is
// restored on every path (the TryFunction swallows errors).
//
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 70378 "LT Fmt Currency Prefix"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Result: Text;

    [TryFunction]
    local procedure TryFormat(Value: Decimal; FormatString: Text)
    begin
        Result := Format(Value, 0, FormatString);
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; ObsName: Text; Value: Decimal; FormatString: Text)
    var
        Ok: Boolean;
    begin
        Result := '';
        ClearLastError();
        Ok := TryFormat(Value, FormatString);
        Observer.Observe(ObsName + '.ok', Format(Ok));
        Observer.Observe(ObsName + '.text', Result);
        if not Ok then
            Observer.ObserveError(ObsName + '.err');
    end;

    [Test]
    procedure P157_Gbp_AmountAutoFormatShape()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'pos', 1234.5, '<C,GBP><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'neg', -1234.5, '<C,GBP><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'zero', 0, '<C,GBP><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'big', 1234567.891, '<C,GBP><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'small', 0.005, '<C,GBP><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'noPrefix', 1234.5, '<Precision,2:2><Standard Format,0>');
        Probe(Observer, 'prefixOnly', 1234.5, '<C,GBP>');
        Probe(Observer, 'prefixOnlyNeg', -1234.5, '<C,GBP>');
        Observer.Expect('pos.ok', 'Yes');
        Observer.Expect('pos.text', '1,234.50');
        Observer.Expect('neg.ok', 'Yes');
        Observer.Expect('neg.text', '-1,234.50');
        Observer.Expect('zero.ok', 'Yes');
        Observer.Expect('zero.text', '0.00');
        Observer.Expect('big.ok', 'Yes');
        Observer.Expect('big.text', '1,234,567.89');
        Observer.Expect('small.ok', 'Yes');
        Observer.Expect('small.text', '0.01');
        Observer.Expect('noPrefix.ok', 'Yes');
        Observer.Expect('noPrefix.text', '1,234.50');
        Observer.Expect('prefixOnly.ok', 'Yes');
        Observer.Expect('prefixOnly.text', '');
        Observer.Expect('prefixOnlyNeg.ok', 'Yes');
        Observer.Expect('prefixOnlyNeg.text', '');
        Observer.Verify();
    end;

    [Test]
    procedure P157_Gbp_PrefixPlusOtherTags()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'std1', 1234.5, '<C,GBP><Standard Format,1>');
        Probe(Observer, 'std2', 1234.5, '<C,GBP><Standard Format,2>');
        Probe(Observer, 'std9', 1234.5, '<C,GBP><Standard Format,9>');
        Probe(Observer, 'prec05', 1234.5, '<C,GBP><Precision,0:5>');
        Probe(Observer, 'prec33', 1234.5, '<C,GBP><Precision,3:3>');
        Probe(Observer, 'digits', 1234.5, '<C,GBP>0');
        Probe(Observer, 'digitsHash', 1234.5, '<C,GBP>#,##0.00');
        Probe(Observer, 'afterText', 1234.5, '<C,GBP>x<Precision,2:2><Standard Format,0>');
        Observer.Expect('std1.ok', 'Yes');
        Observer.Expect('std1.text', '1234.5');
        Observer.Expect('std2.ok', 'Yes');
        Observer.Expect('std2.text', '1234.5');
        Observer.Expect('std9.ok', 'Yes');
        Observer.Expect('std9.text', '1234.5');
        Observer.Expect('prec05.ok', 'Yes');
        Observer.Expect('prec05.text', '');
        Observer.Expect('prec33.ok', 'Yes');
        Observer.Expect('prec33.text', '');
        Observer.Expect('digits.ok', 'Yes');
        Observer.Expect('digits.text', '0');
        Observer.Expect('digitsHash.ok', 'Yes');
        Observer.Expect('digitsHash.text', '#,##0.00');
        Observer.Expect('afterText.ok', 'Yes');
        Observer.Expect('afterText.text', 'x1,234.50');
        Observer.Verify();
    end;

    [Test]
    procedure P157_OtherCurrencyCodes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'eur', 1234.5, '<C,EUR><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'usd', 1234.5, '<C,USD><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'lower', 1234.5, '<C,gbp><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'long', 1234.5, '<C,ABCDEFGHIJ><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'digitCode', 1234.5, '<C,123><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'space', 1234.5, '<C, GBP><Precision,2:2><Standard Format,0>');
        Observer.Expect('eur.ok', 'Yes');
        Observer.Expect('eur.text', '1,234.50');
        Observer.Expect('usd.ok', 'Yes');
        Observer.Expect('usd.text', '1,234.50');
        Observer.Expect('lower.ok', 'Yes');
        Observer.Expect('lower.text', '1,234.50');
        Observer.Expect('long.ok', 'Yes');
        Observer.Expect('long.text', '1,234.50');
        Observer.Expect('digitCode.ok', 'Yes');
        Observer.Expect('digitCode.text', '1,234.50');
        Observer.Expect('space.ok', 'Yes');
        Observer.Expect('space.text', '1,234.50');
        Observer.Verify();
    end;

    [Test]
    procedure P157_UnknownAndEmptyCurrency()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'xxx', 1234.5, '<C,XXX><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'xxxOnly', 1234.5, '<C,XXX>');
        Probe(Observer, 'empty', 1234.5, '<C,><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'emptyOnly', 1234.5, '<C,>');
        Probe(Observer, 'noComma', 1234.5, '<C><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'noCommaGbp', 1234.5, '<CGBP><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'unclosed', 1234.5, '<C,GBP');
        Probe(Observer, 'twice', 1234.5, '<C,GBP><C,EUR><Precision,2:2><Standard Format,0>');
        Observer.Expect('xxx.ok', 'Yes');
        Observer.Expect('xxx.text', '1,234.50');
        Observer.Expect('xxxOnly.ok', 'Yes');
        Observer.Expect('xxxOnly.text', '');
        Observer.Expect('empty.ok', 'Yes');
        Observer.Expect('empty.text', '1,234.50');
        Observer.Expect('emptyOnly.ok', 'Yes');
        Observer.Expect('emptyOnly.text', '');
        Observer.Expect('noComma.ok', 'Yes');
        Observer.Expect('noComma.text', '1,234.50');
        Observer.Expect('noCommaGbp.ok', 'No');
        Observer.Expect('noCommaGbp.text', '');
        Observer.Expect('noCommaGbp.err|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<CGBP><Precision,2:2><Standard Format,0>');
        Observer.Expect('noCommaGbp.err|code', 'InvalidFormatString');
        Observer.Expect('unclosed.ok', 'No');
        Observer.Expect('unclosed.text', '');
        Observer.Expect('unclosed.err|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<C,GBP');
        Observer.Expect('unclosed.err|code', 'InvalidFormatString');
        Observer.Expect('twice.ok', 'Yes');
        Observer.Expect('twice.text', '1,234.50');
        Observer.Verify();
    end;

    [Test]
    procedure P157_NotAtStart()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'afterPrecision', 1234.5, '<Precision,2:2><C,GBP><Standard Format,0>');
        Probe(Observer, 'atEnd', 1234.5, '<Precision,2:2><Standard Format,0><C,GBP>');
        Probe(Observer, 'afterLiteral', 1234.5, 'x<C,GBP><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'beforeSign', 1234.5, '<C,GBP><Sign><Integer Thousand><Decimal,3>');
        Probe(Observer, 'integerDecimal', 1234.5, '<C,GBP><Integer><Decimal,3>');
        Observer.Expect('afterPrecision.ok', 'Yes');
        Observer.Expect('afterPrecision.text', '1,234.50');
        Observer.Expect('atEnd.ok', 'Yes');
        Observer.Expect('atEnd.text', '1,234.50');
        Observer.Expect('afterLiteral.ok', 'Yes');
        Observer.Expect('afterLiteral.text', 'x1,234.50');
        Observer.Expect('beforeSign.ok', 'Yes');
        Observer.Expect('beforeSign.text', '1,234.50');
        Observer.Expect('integerDecimal.ok', 'Yes');
        Observer.Expect('integerDecimal.text', '1234.50');
        Observer.Verify();
    end;
}

codeunit 70379 "LT Fmt Currency Prefix DE"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Result: Text;

    [TryFunction]
    local procedure TryFormat(Value: Decimal; FormatString: Text)
    begin
        Result := Format(Value, 0, FormatString);
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; ObsName: Text; Value: Decimal; FormatString: Text)
    var
        Ok: Boolean;
    begin
        Result := '';
        ClearLastError();
        Ok := TryFormat(Value, FormatString);
        Observer.Observe(ObsName + '.ok', Format(Ok));
        Observer.Observe(ObsName + '.text', Result);
        if not Ok then
            Observer.ObserveError(ObsName + '.err');
    end;

    [Test]
    procedure P157_German_KnownAndUnknownCode()
    var
        Observer: Codeunit "Probe Observer";
        OldLanguage: Integer;
    begin
        OldLanguage := GlobalLanguage();
        GlobalLanguage(1031);
        Probe(Observer, 'gbp', 1234.5, '<C,GBP><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'gbpNeg', -1234.5, '<C,GBP><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'gbpBig', 1234567.891, '<C,GBP><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'xxx', 1234.5, '<C,XXX><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'empty', 1234.5, '<C,><Precision,2:2><Standard Format,0>');
        Probe(Observer, 'prefixOnly', 1234.5, '<C,GBP>');
        Probe(Observer, 'noPrefix', 1234.5, '<Precision,2:2><Standard Format,0>');
        GlobalLanguage(OldLanguage);
        Observer.Expect('gbp.ok', 'Ja');
        Observer.Expect('gbp.text', '1,234.50');
        Observer.Expect('gbpNeg.ok', 'Ja');
        Observer.Expect('gbpNeg.text', '-1,234.50');
        Observer.Expect('gbpBig.ok', 'Ja');
        Observer.Expect('gbpBig.text', '1,234,567.89');
        Observer.Expect('xxx.ok', 'Ja');
        Observer.Expect('xxx.text', '1,234.50');
        Observer.Expect('empty.ok', 'Ja');
        Observer.Expect('empty.text', '1,234.50');
        Observer.Expect('prefixOnly.ok', 'Ja');
        Observer.Expect('prefixOnly.text', '');
        Observer.Expect('noPrefix.ok', 'Ja');
        Observer.Expect('noPrefix.text', '1,234.50');
        Observer.Verify();
    end;

    [Test]
    procedure P157_German_PrefixPlusOtherTags()
    var
        Observer: Codeunit "Probe Observer";
        OldLanguage: Integer;
    begin
        OldLanguage := GlobalLanguage();
        GlobalLanguage(1031);
        Probe(Observer, 'std1', 1234.5, '<C,GBP><Standard Format,1>');
        Probe(Observer, 'std2', 1234.5, '<C,GBP><Standard Format,2>');
        Probe(Observer, 'prec05', 1234.5, '<C,GBP><Precision,0:5>');
        Probe(Observer, 'digits', 1234.5, '<C,GBP>0');
        Probe(Observer, 'afterPrecision', 1234.5, '<Precision,2:2><C,GBP><Standard Format,0>');
        GlobalLanguage(OldLanguage);
        Observer.Expect('std1.ok', 'Ja');
        Observer.Expect('std1.text', '1234.5');
        Observer.Expect('std2.ok', 'Ja');
        Observer.Expect('std2.text', '1234.5');
        Observer.Expect('prec05.ok', 'Ja');
        Observer.Expect('prec05.text', '');
        Observer.Expect('digits.ok', 'Ja');
        Observer.Expect('digits.text', '0');
        Observer.Expect('afterPrecision.ok', 'Ja');
        Observer.Expect('afterPrecision.text', '1,234.50');
        Observer.Verify();
    end;
}
