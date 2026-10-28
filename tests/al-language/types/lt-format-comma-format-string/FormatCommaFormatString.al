// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); test codeunit 74320
// Probe: written against BC; every literal asserted below is what BC produced (BC 27, 28 and 29 by the corpus CI matrix).
// Settles GitHub issue 216 item 6 (NP Retail blockers): Format(Value, 0, '<Sign><Integer><Decimals><Comma,.>') and similar strings with a <Comma,...> element
// on a Decimal, Integer, Text and Date value: the text returned, or the error text and code (raised when Format runs, not when the code compiles).
// The Format PROPERTY on a table field does not compile in AL (AL0124): tests/must-not-compile/cases/0481-table-field-format-property.al.
// Invalid format strings with other elements are pinned in types/lt-evaluate-format-lasterror-setview/P86FormatDecimal.al.
// BC versions: 27, 28, 29

codeunit 74320 "LT FCF Format Comma String"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFormat(Value: Variant; FormatString: Text; var Res: Text)
    begin
        Res := Format(Value, 0, FormatString);
    end;

    local procedure Show(Ok: Boolean; Res: Text): Text
    begin
        if Ok then
            exit('ok:' + Res);
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Format_CommaStrings_DecPos()
    var
        Observer: Codeunit "Probe Observer";
        Value: Decimal;
        Res: Text;
    begin
        Value := 1234.5;
        Res := '';
        Observer.Observe('s1', Show(TryFormat(Value, '<Sign><Integer><Decimals><Comma,.>', Res), Res));
        Res := '';
        Observer.Observe('s2', Show(TryFormat(Value, '<Comma,.>', Res), Res));
        Res := '';
        Observer.Observe('s3', Show(TryFormat(Value, '<Integer><Comma,.><Decimals>', Res), Res));
        Res := '';
        Observer.Observe('s4', Show(TryFormat(Value, '<Sign><Integer><Decimals><Comma,,>', Res), Res));
        Res := '';
        Observer.Observe('s5', Show(TryFormat(Value, '<Sign><Integer><Decimals><Comma>', Res), Res));
        Res := '';
        Observer.Observe('s6', Show(TryFormat(Value, '<Decimals><Comma,.>', Res), Res));
        Observer.Expect('s1', 'ok:1234.5');
        Observer.Expect('s2', 'ok:');
        Observer.Expect('s3', 'ok:1234.5');
        Observer.Expect('s4', 'ok:1234,5');
        Observer.Expect('s5', 'err:An invalid field or attribute has been specified for the ''Format'' property.\\<Sign><Integer><Decimals><Comma>|InvalidFormatString');
        Observer.Expect('s6', 'ok:.5');
        Observer.Verify();
    end;

    [Test]
    procedure Format_CommaStrings_DecNeg()
    var
        Observer: Codeunit "Probe Observer";
        Value: Decimal;
        Res: Text;
    begin
        Value := -1234.567;
        Res := '';
        Observer.Observe('s1', Show(TryFormat(Value, '<Sign><Integer><Decimals><Comma,.>', Res), Res));
        Res := '';
        Observer.Observe('s2', Show(TryFormat(Value, '<Comma,.>', Res), Res));
        Res := '';
        Observer.Observe('s3', Show(TryFormat(Value, '<Integer><Comma,.><Decimals>', Res), Res));
        Res := '';
        Observer.Observe('s4', Show(TryFormat(Value, '<Sign><Integer><Decimals><Comma,,>', Res), Res));
        Res := '';
        Observer.Observe('s5', Show(TryFormat(Value, '<Sign><Integer><Decimals><Comma>', Res), Res));
        Res := '';
        Observer.Observe('s6', Show(TryFormat(Value, '<Decimals><Comma,.>', Res), Res));
        Observer.Expect('s1', 'ok:-1234.567');
        Observer.Expect('s2', 'ok:');
        Observer.Expect('s3', 'ok:1234.567');
        Observer.Expect('s4', 'ok:-1234,567');
        Observer.Expect('s5', 'err:An invalid field or attribute has been specified for the ''Format'' property.\\<Sign><Integer><Decimals><Comma>|InvalidFormatString');
        Observer.Expect('s6', 'ok:.567');
        Observer.Verify();
    end;

    [Test]
    procedure Format_CommaStrings_DecZero()
    var
        Observer: Codeunit "Probe Observer";
        Value: Decimal;
        Res: Text;
    begin
        Value := 0;
        Res := '';
        Observer.Observe('s1', Show(TryFormat(Value, '<Sign><Integer><Decimals><Comma,.>', Res), Res));
        Res := '';
        Observer.Observe('s2', Show(TryFormat(Value, '<Comma,.>', Res), Res));
        Res := '';
        Observer.Observe('s3', Show(TryFormat(Value, '<Integer><Comma,.><Decimals>', Res), Res));
        Res := '';
        Observer.Observe('s4', Show(TryFormat(Value, '<Sign><Integer><Decimals><Comma,,>', Res), Res));
        Res := '';
        Observer.Observe('s5', Show(TryFormat(Value, '<Sign><Integer><Decimals><Comma>', Res), Res));
        Res := '';
        Observer.Observe('s6', Show(TryFormat(Value, '<Decimals><Comma,.>', Res), Res));
        Observer.Expect('s1', 'ok:0');
        Observer.Expect('s2', 'ok:');
        Observer.Expect('s3', 'ok:0');
        Observer.Expect('s4', 'ok:0');
        Observer.Expect('s5', 'err:An invalid field or attribute has been specified for the ''Format'' property.\\<Sign><Integer><Decimals><Comma>|InvalidFormatString');
        Observer.Expect('s6', 'ok:');
        Observer.Verify();
    end;

    [Test]
    procedure Format_CommaStrings_Int()
    var
        Observer: Codeunit "Probe Observer";
        Value: Integer;
        Res: Text;
    begin
        Value := 12;
        Res := '';
        Observer.Observe('s1', Show(TryFormat(Value, '<Sign><Integer><Decimals><Comma,.>', Res), Res));
        Res := '';
        Observer.Observe('s2', Show(TryFormat(Value, '<Comma,.>', Res), Res));
        Res := '';
        Observer.Observe('s3', Show(TryFormat(Value, '<Integer><Comma,.><Decimals>', Res), Res));
        Res := '';
        Observer.Observe('s4', Show(TryFormat(Value, '<Sign><Integer><Decimals><Comma,,>', Res), Res));
        Res := '';
        Observer.Observe('s5', Show(TryFormat(Value, '<Sign><Integer><Decimals><Comma>', Res), Res));
        Res := '';
        Observer.Observe('s6', Show(TryFormat(Value, '<Decimals><Comma,.>', Res), Res));
        Observer.Expect('s1', 'err:An invalid field or attribute has been specified for the ''Format'' property.\\<Sign><Integer><Decimals><Comma,.>|InvalidFormatString');
        Observer.Expect('s2', 'ok:');
        Observer.Expect('s3', 'err:An invalid field or attribute has been specified for the ''Format'' property.\\<Integer><Comma,.><Decimals>|InvalidFormatString');
        Observer.Expect('s4', 'err:An invalid field or attribute has been specified for the ''Format'' property.\\<Sign><Integer><Decimals><Comma,,>|InvalidFormatString');
        Observer.Expect('s5', 'err:An invalid field or attribute has been specified for the ''Format'' property.\\<Sign><Integer><Decimals><Comma>|InvalidFormatString');
        Observer.Expect('s6', 'err:An invalid field or attribute has been specified for the ''Format'' property.\\<Decimals><Comma,.>|InvalidFormatString');
        Observer.Verify();
    end;

    [Test]
    procedure Format_CommaStrings_Txt()
    var
        Observer: Codeunit "Probe Observer";
        Value: Text;
        Res: Text;
    begin
        Value := 'abc';
        Res := '';
        Observer.Observe('s1', Show(TryFormat(Value, '<Sign><Integer><Decimals><Comma,.>', Res), Res));
        Res := '';
        Observer.Observe('s2', Show(TryFormat(Value, '<Comma,.>', Res), Res));
        Res := '';
        Observer.Observe('s3', Show(TryFormat(Value, '<Integer><Comma,.><Decimals>', Res), Res));
        Res := '';
        Observer.Observe('s4', Show(TryFormat(Value, '<Sign><Integer><Decimals><Comma,,>', Res), Res));
        Res := '';
        Observer.Observe('s5', Show(TryFormat(Value, '<Sign><Integer><Decimals><Comma>', Res), Res));
        Res := '';
        Observer.Observe('s6', Show(TryFormat(Value, '<Decimals><Comma,.>', Res), Res));
        Observer.Expect('s1', 'err:An invalid field or attribute has been specified for the ''Format'' property.\\<Sign><Integer><Decimals><Comma,.>|InvalidFormatString');
        Observer.Expect('s2', 'ok:');
        Observer.Expect('s3', 'err:An invalid field or attribute has been specified for the ''Format'' property.\\<Integer><Comma,.><Decimals>|InvalidFormatString');
        Observer.Expect('s4', 'err:An invalid field or attribute has been specified for the ''Format'' property.\\<Sign><Integer><Decimals><Comma,,>|InvalidFormatString');
        Observer.Expect('s5', 'err:An invalid field or attribute has been specified for the ''Format'' property.\\<Sign><Integer><Decimals><Comma>|InvalidFormatString');
        Observer.Expect('s6', 'err:An invalid field or attribute has been specified for the ''Format'' property.\\<Decimals><Comma,.>|InvalidFormatString');
        Observer.Verify();
    end;

    [Test]
    procedure Format_CommaStrings_Dat()
    var
        Observer: Codeunit "Probe Observer";
        Value: Date;
        Res: Text;
    begin
        Value := DMY2Date(2,1,2026);
        Res := '';
        Observer.Observe('s1', Show(TryFormat(Value, '<Sign><Integer><Decimals><Comma,.>', Res), Res));
        Res := '';
        Observer.Observe('s2', Show(TryFormat(Value, '<Comma,.>', Res), Res));
        Res := '';
        Observer.Observe('s3', Show(TryFormat(Value, '<Integer><Comma,.><Decimals>', Res), Res));
        Res := '';
        Observer.Observe('s4', Show(TryFormat(Value, '<Sign><Integer><Decimals><Comma,,>', Res), Res));
        Res := '';
        Observer.Observe('s5', Show(TryFormat(Value, '<Sign><Integer><Decimals><Comma>', Res), Res));
        Res := '';
        Observer.Observe('s6', Show(TryFormat(Value, '<Decimals><Comma,.>', Res), Res));
        Observer.Expect('s1', 'err:An invalid field or attribute has been specified for the ''Format'' property.\\<Sign><Integer><Decimals><Comma,.>|InvalidFormatString');
        Observer.Expect('s2', 'ok:');
        Observer.Expect('s3', 'err:An invalid field or attribute has been specified for the ''Format'' property.\\<Integer><Comma,.><Decimals>|InvalidFormatString');
        Observer.Expect('s4', 'err:An invalid field or attribute has been specified for the ''Format'' property.\\<Sign><Integer><Decimals><Comma,,>|InvalidFormatString');
        Observer.Expect('s5', 'err:An invalid field or attribute has been specified for the ''Format'' property.\\<Sign><Integer><Decimals><Comma>|InvalidFormatString');
        Observer.Expect('s6', 'err:An invalid field or attribute has been specified for the ''Format'' property.\\<Decimals><Comma,.>|InvalidFormatString');
        Observer.Verify();
    end;

    // Writer TP (NP lane, 2026-10-28): <Precision,2:26> with Standard Format 2 and 4, and <Precision,2:2> before <Sign>/<Integer>/<Decimals>/<Comma,x>.
    local procedure TpObserve(var Observer: Codeunit "Probe Observer"; Prefix: Text; Value: Decimal)
    var
        Res: Text;
    begin
        Observer.Observe(Prefix + ' p26sf4', Show(TryFormat(Value, '<Precision,2:26><Standard Format,4>', Res), Res));
        Observer.Observe(Prefix + ' p26sf2', Show(TryFormat(Value, '<Precision,2:26><Standard Format,2>', Res), Res));
        Observer.Observe(Prefix + ' p2comma.', Show(TryFormat(Value, '<Precision,2:2><Sign><Integer><Decimals><Comma,.>', Res), Res));
        Observer.Observe(Prefix + ' p2comma,', Show(TryFormat(Value, '<Precision,2:2><Sign><Integer><Decimals><Comma,,>', Res), Res));
        Observer.Observe(Prefix + ' p2thousand', Show(TryFormat(Value, '<Precision,2:2><Integer Thousand><Decimals><Comma,,>', Res), Res));
        Observer.Observe(Prefix + ' signfirst', Show(TryFormat(Value, '<Sign><Precision,2:2><Integer><Decimals>', Res), Res));
    end;

    [Test]
    procedure TP_Format_PrecisionStrings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TpObserve(Observer, '0', 0);
        TpObserve(Observer, '1234.5', 1234.5);
        TpObserve(Observer, '-1234.567', -1234.567);
        TpObserve(Observer, '0.125', 0.125);
        TpObserve(Observer, '1234567.891', 1234567.891);
        Observer.Expect('0 p26sf4', 'ok:0.00 ');
        Observer.Expect('0 p26sf2', 'ok:0.00');
        Observer.Expect('0 p2comma.', 'ok:0.00');
        Observer.Expect('0 p2comma,', 'ok:0,00');
        Observer.Expect('0 p2thousand', 'ok:0,00');
        Observer.Expect('0 signfirst', 'ok:0');
        Observer.Expect('1234.5 p26sf4', 'ok:1234.50 ');
        Observer.Expect('1234.5 p26sf2', 'ok:1234.50');
        Observer.Expect('1234.5 p2comma.', 'ok:1234.50');
        Observer.Expect('1234.5 p2comma,', 'ok:1234,50');
        Observer.Expect('1234.5 p2thousand', 'ok:1,234,50');
        Observer.Expect('1234.5 signfirst', 'ok:1234.5');
        Observer.Expect('-1234.567 p26sf4', 'ok:1234.567-');
        Observer.Expect('-1234.567 p26sf2', 'ok:-1234.567');
        Observer.Expect('-1234.567 p2comma.', 'ok:-1234.57');
        Observer.Expect('-1234.567 p2comma,', 'ok:-1234,57');
        Observer.Expect('-1234.567 p2thousand', 'ok:1,234,57');
        Observer.Expect('-1234.567 signfirst', 'ok:-1234.567');
        Observer.Expect('0.125 p26sf4', 'ok:0.125 ');
        Observer.Verify();
    end;

    [Test]
    procedure TP_Format_PrecisionStrings_Small()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TpObserve(Observer, '0.1234567891234', 0.1234567891234);
        TpObserve(Observer, '-0.005', -0.005);
        TpObserve(Observer, '12', 12);
        Observer.Expect('0.1234567891234 p26sf4', 'ok:0.1234567891234 ');
        Observer.Expect('0.1234567891234 p26sf2', 'ok:0.1234567891234');
        Observer.Expect('0.1234567891234 p2comma.', 'ok:0.12');
        Observer.Expect('0.1234567891234 p2comma,', 'ok:0,12');
        Observer.Expect('0.1234567891234 p2thousand', 'ok:0,12');
        Observer.Expect('0.1234567891234 signfirst', 'ok:0.1234567891234');
        Observer.Expect('-0.005 p26sf4', 'ok:0.005-');
        Observer.Expect('-0.005 p26sf2', 'ok:-0.005');
        Observer.Expect('-0.005 p2comma.', 'ok:-0.01');
        Observer.Expect('-0.005 p2comma,', 'ok:-0,01');
        Observer.Expect('-0.005 p2thousand', 'ok:0,01');
        Observer.Expect('-0.005 signfirst', 'ok:-0.005');
        Observer.Expect('12 p26sf4', 'ok:12.00 ');
        Observer.Expect('12 p26sf2', 'ok:12.00');
        Observer.Expect('12 p2comma.', 'ok:12.00');
        Observer.Expect('12 p2comma,', 'ok:12,00');
        Observer.Expect('12 p2thousand', 'ok:12,00');
        Observer.Verify();
    end;
}
