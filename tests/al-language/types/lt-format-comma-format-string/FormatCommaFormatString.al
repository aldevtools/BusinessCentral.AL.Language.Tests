// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); test codeunit 74320
// Probe: written against BC; every literal asserted below is what BC produced (BC 27, 28 and 29 by the corpus CI matrix).
// Settles GitHub issue 216 item 6 (NP Retail blockers): Format(Value, 0, '<Sign><Integer><Decimals><Comma,.>') and similar strings with a <Comma,...> element
// on a Decimal, Integer, Text and Date value: the text returned, or the error text and code (raised when Format runs, not when the code compiles).
// The Format PROPERTY on a table field does not compile in AL (AL0124): tests/must-not-compile/cases/0481-table-field-format-property.al.
// Invalid format strings with other elements are pinned in types/lt-evaluate-format-lasterror-setview/P86FormatDecimal.al.
// Writer TQ (2026-10-29, TQ_* tests): <Precision,A:B> before <Standard Format,0|2|9> for A:B 0:0, 0:2, 1:3, 2:5, 3:3, 2:26, and before
//   <Integer>/<Integer Thousand>/<Sign>, <Decimals> and <Comma,x>. The value is rounded half away from zero to B decimals and padded to A
//   (1.5 and 2.5 at 0:0 give 2 and 3, -2.5 gives -3, 1.2345 at 3:3 gives 1.235, 99.9996 at 1:3 gives 100.0); Standard Format 0 adds thousands
//   separators (-1,234,568), 2 and 9 do not.
// Writer TV (2026-10-29, TV_* tests): <Precision,0:B> with B above 18 (0:19, 0:26, 0:28) and 26:26, alone and before <Standard Format,N>.
//   Not asserted: B of 29 or more raises a CLR ArgumentOutOfRangeException ("Decimal can only round to between 0 and 28 digits") that a TryFunction
//   does not catch (BC 29 SaaS sandbox, 2026-10-29).
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
        Observer.Expect('0.125 p26sf2', 'ok:0.125');
        Observer.Expect('0.125 p2comma.', 'ok:0.13');
        Observer.Expect('0.125 p2comma,', 'ok:0,13');
        Observer.Expect('0.125 p2thousand', 'ok:0,13');
        Observer.Expect('0.125 signfirst', 'ok:0.125');
        Observer.Expect('1234567.891 p26sf4', 'ok:1234567.891 ');
        Observer.Expect('1234567.891 p26sf2', 'ok:1234567.891');
        Observer.Expect('1234567.891 p2comma.', 'ok:1234567.89');
        Observer.Expect('1234567.891 p2comma,', 'ok:1234567,89');
        Observer.Expect('1234567.891 p2thousand', 'ok:1,234,567,89');
        Observer.Expect('1234567.891 signfirst', 'ok:1234567.891');
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
        Observer.Expect('12 signfirst', 'ok:12');
        Observer.Verify();
    end;

    // Writer TQ (NP lane, 2026-10-29): a leading <Precision,A:B> followed by <Standard Format,N>, for A:B 0:0, 0:2, 1:3, 2:5, 3:3 and 2:26,
    // on values that round up, round down or need no rounding; then <Precision,A:B> with <Integer>/<Integer Thousand>, <Decimals> and <Comma,x>.
    local procedure TqObserveStd(var Observer: Codeunit "Probe Observer"; Prefix: Text; Value: Decimal)
    var
        Precisions: List of [Text];
        Precision: Text;
        Res: Text;
    begin
        Precisions.AddRange('0:0', '0:2', '1:3', '2:5', '3:3', '2:26');
        foreach Precision in Precisions do begin
            Observer.Observe(Prefix + ' ' + Precision + ' sf0', Show(TryFormat(Value, '<Precision,' + Precision + '><Standard Format,0>', Res), Res));
            Observer.Observe(Prefix + ' ' + Precision + ' sf2', Show(TryFormat(Value, '<Precision,' + Precision + '><Standard Format,2>', Res), Res));
            Observer.Observe(Prefix + ' ' + Precision + ' sf9', Show(TryFormat(Value, '<Precision,' + Precision + '><Standard Format,9>', Res), Res));
        end;
    end;

    local procedure TqObserveComma(var Observer: Codeunit "Probe Observer"; Prefix: Text; Value: Decimal)
    var
        Res: Text;
    begin
        Observer.Observe(Prefix + ' p00comma,', Show(TryFormat(Value, '<Precision,0:0><Integer><Decimals><Comma,,>', Res), Res));
        Observer.Observe(Prefix + ' p13thousand.', Show(TryFormat(Value, '<Precision,1:3><Integer Thousand><Decimals><Comma,.>', Res), Res));
        Observer.Observe(Prefix + ' p33signcomma,', Show(TryFormat(Value, '<Precision,3:3><Sign><Integer><Decimals><Comma,,>', Res), Res));
    end;

    [Test]
    procedure TQ_Format_PrecisionStd_Up15()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TqObserveStd(Observer, '1.5', 1.5);
        Observer.Expect('1.5 0:0 sf0', 'ok:2');
        Observer.Expect('1.5 0:0 sf2', 'ok:2');
        Observer.Expect('1.5 0:0 sf9', 'ok:2');
        Observer.Expect('1.5 0:2 sf0', 'ok:1.5');
        Observer.Expect('1.5 0:2 sf2', 'ok:1.5');
        Observer.Expect('1.5 0:2 sf9', 'ok:1.5');
        Observer.Expect('1.5 1:3 sf0', 'ok:1.5');
        Observer.Expect('1.5 1:3 sf2', 'ok:1.5');
        Observer.Expect('1.5 1:3 sf9', 'ok:1.5');
        Observer.Expect('1.5 2:5 sf0', 'ok:1.50');
        Observer.Expect('1.5 2:5 sf2', 'ok:1.50');
        Observer.Expect('1.5 2:5 sf9', 'ok:1.50');
        Observer.Expect('1.5 3:3 sf0', 'ok:1.500');
        Observer.Expect('1.5 3:3 sf2', 'ok:1.500');
        Observer.Expect('1.5 3:3 sf9', 'ok:1.500');
        Observer.Expect('1.5 2:26 sf0', 'ok:1.50');
        Observer.Expect('1.5 2:26 sf2', 'ok:1.50');
        Observer.Expect('1.5 2:26 sf9', 'ok:1.50');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_Format_PrecisionStd_Up25()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TqObserveStd(Observer, '2.5', 2.5);
        Observer.Expect('2.5 0:0 sf0', 'ok:3');
        Observer.Expect('2.5 0:0 sf2', 'ok:3');
        Observer.Expect('2.5 0:0 sf9', 'ok:3');
        Observer.Expect('2.5 0:2 sf0', 'ok:2.5');
        Observer.Expect('2.5 0:2 sf2', 'ok:2.5');
        Observer.Expect('2.5 0:2 sf9', 'ok:2.5');
        Observer.Expect('2.5 1:3 sf0', 'ok:2.5');
        Observer.Expect('2.5 1:3 sf2', 'ok:2.5');
        Observer.Expect('2.5 1:3 sf9', 'ok:2.5');
        Observer.Expect('2.5 2:5 sf0', 'ok:2.50');
        Observer.Expect('2.5 2:5 sf2', 'ok:2.50');
        Observer.Expect('2.5 2:5 sf9', 'ok:2.50');
        Observer.Expect('2.5 3:3 sf0', 'ok:2.500');
        Observer.Expect('2.5 3:3 sf2', 'ok:2.500');
        Observer.Expect('2.5 3:3 sf9', 'ok:2.500');
        Observer.Expect('2.5 2:26 sf0', 'ok:2.50');
        Observer.Expect('2.5 2:26 sf2', 'ok:2.50');
        Observer.Expect('2.5 2:26 sf9', 'ok:2.50');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_Format_PrecisionStd_Neg25()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TqObserveStd(Observer, '-2.5', -2.5);
        Observer.Expect('-2.5 0:0 sf0', 'ok:-3');
        Observer.Expect('-2.5 0:0 sf2', 'ok:-3');
        Observer.Expect('-2.5 0:0 sf9', 'ok:-3');
        Observer.Expect('-2.5 0:2 sf0', 'ok:-2.5');
        Observer.Expect('-2.5 0:2 sf2', 'ok:-2.5');
        Observer.Expect('-2.5 0:2 sf9', 'ok:-2.5');
        Observer.Expect('-2.5 1:3 sf0', 'ok:-2.5');
        Observer.Expect('-2.5 1:3 sf2', 'ok:-2.5');
        Observer.Expect('-2.5 1:3 sf9', 'ok:-2.5');
        Observer.Expect('-2.5 2:5 sf0', 'ok:-2.50');
        Observer.Expect('-2.5 2:5 sf2', 'ok:-2.50');
        Observer.Expect('-2.5 2:5 sf9', 'ok:-2.50');
        Observer.Expect('-2.5 3:3 sf0', 'ok:-2.500');
        Observer.Expect('-2.5 3:3 sf2', 'ok:-2.500');
        Observer.Expect('-2.5 3:3 sf9', 'ok:-2.500');
        Observer.Expect('-2.5 2:26 sf0', 'ok:-2.50');
        Observer.Expect('-2.5 2:26 sf2', 'ok:-2.50');
        Observer.Expect('-2.5 2:26 sf9', 'ok:-2.50');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_Format_PrecisionStd_Down12345()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TqObserveStd(Observer, '1.2345', 1.2345);
        Observer.Expect('1.2345 0:0 sf0', 'ok:1');
        Observer.Expect('1.2345 0:0 sf2', 'ok:1');
        Observer.Expect('1.2345 0:0 sf9', 'ok:1');
        Observer.Expect('1.2345 0:2 sf0', 'ok:1.23');
        Observer.Expect('1.2345 0:2 sf2', 'ok:1.23');
        Observer.Expect('1.2345 0:2 sf9', 'ok:1.23');
        Observer.Expect('1.2345 1:3 sf0', 'ok:1.235');
        Observer.Expect('1.2345 1:3 sf2', 'ok:1.235');
        Observer.Expect('1.2345 1:3 sf9', 'ok:1.235');
        Observer.Expect('1.2345 2:5 sf0', 'ok:1.2345');
        Observer.Expect('1.2345 2:5 sf2', 'ok:1.2345');
        Observer.Expect('1.2345 2:5 sf9', 'ok:1.2345');
        Observer.Expect('1.2345 3:3 sf0', 'ok:1.235');
        Observer.Expect('1.2345 3:3 sf2', 'ok:1.235');
        Observer.Expect('1.2345 3:3 sf9', 'ok:1.235');
        Observer.Expect('1.2345 2:26 sf0', 'ok:1.2345');
        Observer.Expect('1.2345 2:26 sf2', 'ok:1.2345');
        Observer.Expect('1.2345 2:26 sf9', 'ok:1.2345');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_Format_PrecisionStd_Long()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TqObserveStd(Observer, '1.23456789', 1.23456789);
        Observer.Expect('1.23456789 0:0 sf0', 'ok:1');
        Observer.Expect('1.23456789 0:0 sf2', 'ok:1');
        Observer.Expect('1.23456789 0:0 sf9', 'ok:1');
        Observer.Expect('1.23456789 0:2 sf0', 'ok:1.23');
        Observer.Expect('1.23456789 0:2 sf2', 'ok:1.23');
        Observer.Expect('1.23456789 0:2 sf9', 'ok:1.23');
        Observer.Expect('1.23456789 1:3 sf0', 'ok:1.235');
        Observer.Expect('1.23456789 1:3 sf2', 'ok:1.235');
        Observer.Expect('1.23456789 1:3 sf9', 'ok:1.235');
        Observer.Expect('1.23456789 2:5 sf0', 'ok:1.23457');
        Observer.Expect('1.23456789 2:5 sf2', 'ok:1.23457');
        Observer.Expect('1.23456789 2:5 sf9', 'ok:1.23457');
        Observer.Expect('1.23456789 3:3 sf0', 'ok:1.235');
        Observer.Expect('1.23456789 3:3 sf2', 'ok:1.235');
        Observer.Expect('1.23456789 3:3 sf9', 'ok:1.235');
        Observer.Expect('1.23456789 2:26 sf0', 'ok:1.23456789');
        Observer.Expect('1.23456789 2:26 sf2', 'ok:1.23456789');
        Observer.Expect('1.23456789 2:26 sf9', 'ok:1.23456789');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_Format_PrecisionStd_Zero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TqObserveStd(Observer, '0', 0);
        Observer.Expect('0 0:0 sf0', 'ok:0');
        Observer.Expect('0 0:0 sf2', 'ok:0');
        Observer.Expect('0 0:0 sf9', 'ok:0');
        Observer.Expect('0 0:2 sf0', 'ok:0');
        Observer.Expect('0 0:2 sf2', 'ok:0');
        Observer.Expect('0 0:2 sf9', 'ok:0');
        Observer.Expect('0 1:3 sf0', 'ok:0.0');
        Observer.Expect('0 1:3 sf2', 'ok:0.0');
        Observer.Expect('0 1:3 sf9', 'ok:0.0');
        Observer.Expect('0 2:5 sf0', 'ok:0.00');
        Observer.Expect('0 2:5 sf2', 'ok:0.00');
        Observer.Expect('0 2:5 sf9', 'ok:0.00');
        Observer.Expect('0 3:3 sf0', 'ok:0.000');
        Observer.Expect('0 3:3 sf2', 'ok:0.000');
        Observer.Expect('0 3:3 sf9', 'ok:0.000');
        Observer.Expect('0 2:26 sf0', 'ok:0.00');
        Observer.Expect('0 2:26 sf2', 'ok:0.00');
        Observer.Expect('0 2:26 sf9', 'ok:0.00');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_Format_PrecisionStd_Tiny()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TqObserveStd(Observer, '0.0004', 0.0004);
        Observer.Expect('0.0004 0:0 sf0', 'ok:0');
        Observer.Expect('0.0004 0:0 sf2', 'ok:0');
        Observer.Expect('0.0004 0:0 sf9', 'ok:0');
        Observer.Expect('0.0004 0:2 sf0', 'ok:0');
        Observer.Expect('0.0004 0:2 sf2', 'ok:0');
        Observer.Expect('0.0004 0:2 sf9', 'ok:0');
        Observer.Expect('0.0004 1:3 sf0', 'ok:0.0');
        Observer.Expect('0.0004 1:3 sf2', 'ok:0.0');
        Observer.Expect('0.0004 1:3 sf9', 'ok:0.0');
        Observer.Expect('0.0004 2:5 sf0', 'ok:0.0004');
        Observer.Expect('0.0004 2:5 sf2', 'ok:0.0004');
        Observer.Expect('0.0004 2:5 sf9', 'ok:0.0004');
        Observer.Expect('0.0004 3:3 sf0', 'ok:0.000');
        Observer.Expect('0.0004 3:3 sf2', 'ok:0.000');
        Observer.Expect('0.0004 3:3 sf9', 'ok:0.000');
        Observer.Expect('0.0004 2:26 sf0', 'ok:0.0004');
        Observer.Expect('0.0004 2:26 sf2', 'ok:0.0004');
        Observer.Expect('0.0004 2:26 sf9', 'ok:0.0004');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_Format_PrecisionStd_Carry()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TqObserveStd(Observer, '99.9996', 99.9996);
        Observer.Expect('99.9996 0:0 sf0', 'ok:100');
        Observer.Expect('99.9996 0:0 sf2', 'ok:100');
        Observer.Expect('99.9996 0:0 sf9', 'ok:100');
        Observer.Expect('99.9996 0:2 sf0', 'ok:100');
        Observer.Expect('99.9996 0:2 sf2', 'ok:100');
        Observer.Expect('99.9996 0:2 sf9', 'ok:100');
        Observer.Expect('99.9996 1:3 sf0', 'ok:100.0');
        Observer.Expect('99.9996 1:3 sf2', 'ok:100.0');
        Observer.Expect('99.9996 1:3 sf9', 'ok:100.0');
        Observer.Expect('99.9996 2:5 sf0', 'ok:99.9996');
        Observer.Expect('99.9996 2:5 sf2', 'ok:99.9996');
        Observer.Expect('99.9996 2:5 sf9', 'ok:99.9996');
        Observer.Expect('99.9996 3:3 sf0', 'ok:100.000');
        Observer.Expect('99.9996 3:3 sf2', 'ok:100.000');
        Observer.Expect('99.9996 3:3 sf9', 'ok:100.000');
        Observer.Expect('99.9996 2:26 sf0', 'ok:99.9996');
        Observer.Expect('99.9996 2:26 sf2', 'ok:99.9996');
        Observer.Expect('99.9996 2:26 sf9', 'ok:99.9996');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_Format_PrecisionStd_Big()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TqObserveStd(Observer, '-1234567.891', -1234567.891);
        Observer.Expect('-1234567.891 0:0 sf0', 'ok:-1,234,568');
        Observer.Expect('-1234567.891 0:0 sf2', 'ok:-1234568');
        Observer.Expect('-1234567.891 0:0 sf9', 'ok:-1234568');
        Observer.Expect('-1234567.891 0:2 sf0', 'ok:-1,234,567.89');
        Observer.Expect('-1234567.891 0:2 sf2', 'ok:-1234567.89');
        Observer.Expect('-1234567.891 0:2 sf9', 'ok:-1234567.89');
        Observer.Expect('-1234567.891 1:3 sf0', 'ok:-1,234,567.891');
        Observer.Expect('-1234567.891 1:3 sf2', 'ok:-1234567.891');
        Observer.Expect('-1234567.891 1:3 sf9', 'ok:-1234567.891');
        Observer.Expect('-1234567.891 2:5 sf0', 'ok:-1,234,567.891');
        Observer.Expect('-1234567.891 2:5 sf2', 'ok:-1234567.891');
        Observer.Expect('-1234567.891 2:5 sf9', 'ok:-1234567.891');
        Observer.Expect('-1234567.891 3:3 sf0', 'ok:-1,234,567.891');
        Observer.Expect('-1234567.891 3:3 sf2', 'ok:-1234567.891');
        Observer.Expect('-1234567.891 3:3 sf9', 'ok:-1234567.891');
        Observer.Expect('-1234567.891 2:26 sf0', 'ok:-1,234,567.891');
        Observer.Expect('-1234567.891 2:26 sf2', 'ok:-1234567.891');
        Observer.Expect('-1234567.891 2:26 sf9', 'ok:-1234567.891');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_Format_PrecisionStd_Whole()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TqObserveStd(Observer, '7', 7);
        Observer.Expect('7 0:0 sf0', 'ok:7');
        Observer.Expect('7 0:0 sf2', 'ok:7');
        Observer.Expect('7 0:0 sf9', 'ok:7');
        Observer.Expect('7 0:2 sf0', 'ok:7');
        Observer.Expect('7 0:2 sf2', 'ok:7');
        Observer.Expect('7 0:2 sf9', 'ok:7');
        Observer.Expect('7 1:3 sf0', 'ok:7.0');
        Observer.Expect('7 1:3 sf2', 'ok:7.0');
        Observer.Expect('7 1:3 sf9', 'ok:7.0');
        Observer.Expect('7 2:5 sf0', 'ok:7.00');
        Observer.Expect('7 2:5 sf2', 'ok:7.00');
        Observer.Expect('7 2:5 sf9', 'ok:7.00');
        Observer.Expect('7 3:3 sf0', 'ok:7.000');
        Observer.Expect('7 3:3 sf2', 'ok:7.000');
        Observer.Expect('7 3:3 sf9', 'ok:7.000');
        Observer.Expect('7 2:26 sf0', 'ok:7.00');
        Observer.Expect('7 2:26 sf2', 'ok:7.00');
        Observer.Expect('7 2:26 sf9', 'ok:7.00');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_Format_PrecisionComma()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TqObserveComma(Observer, '1.5', 1.5);
        TqObserveComma(Observer, '-2.5', -2.5);
        TqObserveComma(Observer, '1234.56789', 1234.56789);
        TqObserveComma(Observer, '0.0004', 0.0004);
        TqObserveComma(Observer, '-0.4', -0.4);
        Observer.Expect('1.5 p00comma,', 'ok:2');
        Observer.Expect('1.5 p13thousand.', 'ok:1.5');
        Observer.Expect('1.5 p33signcomma,', 'ok:1,500');
        Observer.Expect('-2.5 p00comma,', 'ok:3');
        Observer.Expect('-2.5 p13thousand.', 'ok:2.5');
        Observer.Expect('-2.5 p33signcomma,', 'ok:-2,500');
        Observer.Expect('1234.56789 p00comma,', 'ok:1235');
        Observer.Expect('1234.56789 p13thousand.', 'ok:1,234.568');
        Observer.Expect('1234.56789 p33signcomma,', 'ok:1234,568');
        Observer.Expect('0.0004 p00comma,', 'ok:0');
        Observer.Expect('0.0004 p13thousand.', 'ok:0.0');
        Observer.Expect('0.0004 p33signcomma,', 'ok:0,000');
        Observer.Expect('-0.4 p00comma,', 'ok:0');
        Observer.Expect('-0.4 p13thousand.', 'ok:0.4');
        Observer.Expect('-0.4 p33signcomma,', 'ok:-0,400');
        Observer.Verify();
    end;

    // ---- Writer TV (NP lane, 2026-10-29): <Precision,0:B> with B above 18 (0:19, 0:26, 0:28) and <Precision,26:26>, alone and before
    // <Standard Format,2>, <Standard Format,0> and <Standard Format,9>. ----

    local procedure TvObserve(var Observer: Codeunit "Probe Observer"; Prefix: Text; Value: Decimal)
    var
        Res: Text;
    begin
        Observer.Observe(Prefix + ' 0:26 sf2', Show(TryFormat(Value, '<Precision,0:26><Standard Format,2>', Res), Res));
        Observer.Observe(Prefix + ' 0:26 sf0', Show(TryFormat(Value, '<Precision,0:26><Standard Format,0>', Res), Res));
        Observer.Observe(Prefix + ' 0:26 sf9', Show(TryFormat(Value, '<Precision,0:26><Standard Format,9>', Res), Res));
        Observer.Observe(Prefix + ' 0:26 alone', Show(TryFormat(Value, '<Precision,0:26>', Res), Res));
        Observer.Observe(Prefix + ' 0:19 sf2', Show(TryFormat(Value, '<Precision,0:19><Standard Format,2>', Res), Res));
    end;

    [Test]
    procedure TV_Format_Precision0To26_Values()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TvObserve(Observer, '1', 1);
        TvObserve(Observer, '1.5', 1.5);
        TvObserve(Observer, '-2.25', -2.25);
        TvObserve(Observer, '0', 0);
        Observer.Expect('1 0:26 sf2', 'ok:1');
        Observer.Expect('1 0:26 sf0', 'ok:1');
        Observer.Expect('1 0:26 sf9', 'ok:1');
        Observer.Expect('1 0:26 alone', 'ok:');
        Observer.Expect('1 0:19 sf2', 'ok:1');
        Observer.Expect('1.5 0:26 sf2', 'ok:1.5');
        Observer.Expect('1.5 0:26 sf0', 'ok:1.5');
        Observer.Expect('1.5 0:26 sf9', 'ok:1.5');
        Observer.Expect('1.5 0:26 alone', 'ok:');
        Observer.Expect('1.5 0:19 sf2', 'ok:1.5');
        Observer.Expect('-2.25 0:26 sf2', 'ok:-2.25');
        Observer.Expect('-2.25 0:26 sf0', 'ok:-2.25');
        Observer.Expect('-2.25 0:26 sf9', 'ok:-2.25');
        Observer.Expect('-2.25 0:26 alone', 'ok:');
        Observer.Expect('-2.25 0:19 sf2', 'ok:-2.25');
        Observer.Expect('0 0:26 sf2', 'ok:0');
        Observer.Expect('0 0:26 sf0', 'ok:0');
        Observer.Expect('0 0:26 sf9', 'ok:0');
        Observer.Expect('0 0:26 alone', 'ok:');
        Observer.Expect('0 0:19 sf2', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure TV_Format_Precision0To26_OtherValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TvObserve(Observer, '0.01', 0.01);
        TvObserve(Observer, '12345.6789', 12345.6789);
        TvObserve(Observer, '1/3', 1 / 3);
        TvObserve(Observer, 'round 2.346', Round(2.346, 0.01));
        Observer.Finish();
    end;

    [Test]
    procedure TV_Format_PrecisionAbove18_Forms()
    var
        Observer: Codeunit "Probe Observer";
        Res: Text;
    begin
        Observer.Observe('1.5 0:28 sf2', Show(TryFormat(1.5, '<Precision,0:28><Standard Format,2>', Res), Res));
        Observer.Observe('1.5 26:26 sf2', Show(TryFormat(1.5, '<Precision,26:26><Standard Format,2>', Res), Res));
        Observer.Observe('1/3 0:28 sf2', Show(TryFormat(1 / 3, '<Precision,0:28><Standard Format,2>', Res), Res));
        Observer.Observe('15 integer 0:26 sf2', Show(TryFormat(15, '<Precision,0:26><Standard Format,2>', Res), Res));
        Observer.Finish();
    end;
}
