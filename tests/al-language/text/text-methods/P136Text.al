// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-delchr-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: DelChr with a Where text that is not exactly one of = < > <> >< (three-character mixes such as =<>, doubled characters, empty, blank, extra characters), with and without the Which argument; CalcDate with a formula text that has one angle bracket, two opening or closing brackets, or blanks
// BC versions: 29 (27 and 28 by CI)

codeunit 74331 "LT P136 DelChr"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryDel(S: Text; W: Text; C: Text; var R: Text)
    begin
        R := DelChr(S, W, C);
    end;

    [TryFunction]
    local procedure TryDel2(S: Text; W: Text; var R: Text)
    begin
        R := DelChr(S, W);
    end;

    local procedure Del(var Observer: Codeunit "Probe Observer"; Name: Text; S: Text; W: Text; C: Text)
    var
        R: Text;
    begin
        if TryDel(S, W, C, R) then
            Observer.Observe(Name, '[' + R + ']')
        else
            Observer.ObserveError(Name);
    end;

    local procedure Del2(var Observer: Codeunit "Probe Observer"; Name: Text; S: Text; W: Text)
    var
        R: Text;
    begin
        if TryDel2(S, W, R) then
            Observer.Observe(Name, '[' + R + ']')
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure P136_DelChr_ThreeCharWhere()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Del(Observer, 'eqLtGt', 'xxaxbxx', '=<>', 'x');
        Del(Observer, 'ltEqGt', 'xxaxbxx', '<=>', 'x');
        Del(Observer, 'gtLtEq', 'xxaxbxx', '><=', 'x');
        Del(Observer, 'ltGtEq', 'xxaxbxx', '<>=', 'x');
        Del(Observer, 'eqGtLt', 'xxaxbxx', '=><', 'x');
        Del(Observer, 'gtEqLt', 'xxaxbxx', '>=<', 'x');
        Del(Observer, 'eqLt', 'xxaxbxx', '=<', 'x');
        Del(Observer, 'eqGt', 'xxaxbxx', '=>', 'x');
        Del(Observer, 'ltEq', 'xxaxbxx', '<=', 'x');
        Del(Observer, 'gtEq', 'xxaxbxx', '>=', 'x');
        Del2(Observer, 'eqLtGtNoWhich', '  a b  ', '=<>');
        Del2(Observer, 'ltEqGtNoWhich', '  a b  ', '<=>');
        Del(Observer, 'eqLtGtBlankWhich', '  a b  ', '=<>', ' ');
        Del(Observer, 'eqLtGtEmptyWhich', 'xxaxbxx', '=<>', '');
        Del(Observer, 'eqLtGtEmptyString', '', '=<>', 'x');
        Observer.Expect('eqLtGt', '[ab]');
        Observer.Expect('ltEqGt', '[ab]');
        Observer.Expect('gtLtEq', '[ab]');
        Observer.Expect('ltGtEq', '[ab]');
        Observer.Expect('eqGtLt', '[ab]');
        Observer.Expect('gtEqLt', '[ab]');
        Observer.Expect('eqLt', '[ab]');
        Observer.Expect('eqGt', '[ab]');
        Observer.Expect('ltEq', '[ab]');
        Observer.Expect('gtEq', '[ab]');
        Observer.Expect('eqLtGtNoWhich', '[ab]');
        Observer.Expect('ltEqGtNoWhich', '[ab]');
        Observer.Expect('eqLtGtBlankWhich', '[ab]');
        Observer.Expect('eqLtGtEmptyWhich', '[xxaxbxx]');
        Observer.Expect('eqLtGtEmptyString', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure P136_DelChr_DoubledAndOddWhere()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Del(Observer, 'ltlt', 'xxaxbxx', '<<', 'x');
        Del(Observer, 'gtgt', 'xxaxbxx', '>>', 'x');
        Del(Observer, 'eqeq', 'xxaxbxx', '==', 'x');
        Del(Observer, 'ltgtgt', 'xxaxbxx', '<>>', 'x');
        Del(Observer, 'ltltgt', 'xxaxbxx', '<<>', 'x');
        Del(Observer, 'emptyWhere', 'xxaxbxx', '', 'x');
        Del(Observer, 'blankWhere', 'xxaxbxx', ' ', 'x');
        Del(Observer, 'letterWhere', 'xxaxbxx', 'x', 'x');
        Del(Observer, 'ltBlank', 'xxaxbxx', '< ', 'x');
        Del(Observer, 'blankLt', 'xxaxbxx', ' <', 'x');
        Del(Observer, 'ltgtBlank', 'xxaxbxx', '<> ', 'x');
        Del(Observer, 'eqltgtLetter', 'xxaxbxx', '=<>x', 'x');
        Del(Observer, 'eqOnly', 'xxaxbxx', '=', 'x');
        Del(Observer, 'ltOnly', 'xxaxbxx', '<', 'x');
        Del(Observer, 'gtOnly', 'xxaxbxx', '>', 'x');
        Del(Observer, 'gtlt', 'xxaxbxx', '><', 'x');
        Del(Observer, 'ltgt', 'xxaxbxx', '<>', 'x');
        Del(Observer, 'whichLtGt', '<<a>>', '=', '<>');
        Del(Observer, 'whichLtGtTrim', '<<a>>', '<>', '<>');
        Observer.Expect('ltlt', '[axbxx]');
        Observer.Expect('gtgt', '[xxaxb]');
        Observer.Expect('eqeq', '[ab]');
        Observer.Expect('ltgtgt', '[axb]');
        Observer.Expect('ltltgt', '[axb]');
        Observer.Expect('emptyWhere', '[xxaxbxx]');
        Observer.Expect('blankWhere|text', 'Incorrect use of the where parameter.');
        Observer.Expect('blankWhere|code', 'ALSystemString');
        Observer.Expect('letterWhere|text', 'Incorrect use of the where parameter.');
        Observer.Expect('letterWhere|code', 'ALSystemString');
        Observer.Expect('ltBlank|text', 'Incorrect use of the where parameter.');
        Observer.Expect('ltBlank|code', 'ALSystemString');
        Observer.Expect('blankLt|text', 'Incorrect use of the where parameter.');
        Observer.Expect('blankLt|code', 'ALSystemString');
        Observer.Expect('ltgtBlank|text', 'Incorrect use of the where parameter.');
        Observer.Expect('ltgtBlank|code', 'ALSystemString');
        Observer.Expect('eqltgtLetter|text', 'Incorrect use of the where parameter.');
        Observer.Expect('eqltgtLetter|code', 'ALSystemString');
        Observer.Expect('eqOnly', '[ab]');
        Observer.Expect('ltOnly', '[axbxx]');
        Observer.Expect('gtOnly', '[xxaxb]');
        Observer.Expect('gtlt', '[axb]');
        Observer.Expect('ltgt', '[axb]');
        Observer.Expect('whichLtGt', '[a]');
        Observer.Expect('whichLtGtTrim', '[a]');
        Observer.Verify();
    end;

    [Test]
    procedure P136_DelChr_PaymentExportShape()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // the shapes of DelChr calls in bank export code: a text with spaces and a Which of blank, dash or slash
        Del(Observer, 'dashes', 'DE12 3456-7890', '=', '- ');
        Del(Observer, 'dashesTrim', '--DE12--', '<>', '-');
        Del(Observer, 'leadingOnly', '--DE12--', '<', '-');
        Del(Observer, 'trailingOnly', '--DE12--', '>', '-');
        Del(Observer, 'upperLower', 'xXaXx', '=', 'x');
        Del(Observer, 'unicode', 'aäbäc', '=', 'ä');
        Del(Observer, 'longWhich', 'abcdefabc', '=', 'abcdef');
        Observer.Expect('dashes', '[DE1234567890]');
        Observer.Expect('dashesTrim', '[DE12]');
        Observer.Expect('leadingOnly', '[DE12--]');
        Observer.Expect('trailingOnly', '[--DE12]');
        Observer.Expect('upperLower', '[XaX]');
        Observer.Expect('unicode', '[abc]');
        Observer.Expect('longWhich', '[]');
        Observer.Verify();
    end;
}

codeunit 74332 "LT P136 CalcDate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCalc(F: Text; D: Date; var R: Date)
    begin
        R := CalcDate(F, D);
    end;

    local procedure Calc(var Observer: Codeunit "Probe Observer"; Name: Text; F: Text; D: Date)
    var
        R: Date;
    begin
        if TryCalc(F, D, R) then
            Observer.Observe(Name, Format(R, 0, 9))
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure P136_CalcDate_OneAngleBracket()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := 20240115D;
        Calc(Observer, 'openOnly6W', '<+6W', D);
        Calc(Observer, 'closeOnly6W', '+6W>', D);
        Calc(Observer, 'both6W', '<+6W>', D);
        Calc(Observer, 'none6W', '+6W', D);
        Calc(Observer, 'openOnly1M', '<1M', D);
        Calc(Observer, 'openOnlyMinus1D', '<-1D', D);
        Calc(Observer, 'openOnlyCM', '<CM', D);
        Calc(Observer, 'closeOnlyCM', 'CM>', D);
        Calc(Observer, 'openOnlyTwoParts', '<1M+2D', D);
        Calc(Observer, 'openOnlyTwoPartsClose', '<1M>+2D', D);
        Calc(Observer, 'doubleOpen', '<<+6W>', D);
        Calc(Observer, 'doubleClose', '<+6W>>', D);
        Calc(Observer, 'doubleBoth', '<<+6W>>', D);
        Calc(Observer, 'leadingBlank', ' <+6W>', D);
        Calc(Observer, 'blankInside', '< +6W >', D);
        Calc(Observer, 'trailingBlank', '<+6W> ', D);
        Calc(Observer, 'lowerCase', '<+6w>', D);
        Calc(Observer, 'lowerCaseOpenOnly', '<+6w', D);
        Calc(Observer, 'emptyAngles', '<>', D);
        Calc(Observer, 'openAlone', '<', D);
        Calc(Observer, 'closeAlone', '>', D);
        Calc(Observer, 'noNumber', '<W>', D);
        Calc(Observer, 'noNumberOpen', '<W', D);
        Observer.Expect('openOnly6W', '2024-02-26');
        Observer.Expect('closeOnly6W', '2024-02-26');
        Observer.Expect('both6W', '2024-02-26');
        Observer.Expect('none6W', '2024-02-26');
        Observer.Expect('openOnly1M', '2024-02-15');
        Observer.Expect('openOnlyMinus1D', '2024-01-14');
        Observer.Expect('openOnlyCM', '2024-01-31');
        Observer.Expect('closeOnlyCM', '2024-01-31');
        Observer.Expect('openOnlyTwoParts', '2024-02-17');
        Observer.Expect('openOnlyTwoPartsClose', '2024-02-17');
        Observer.Expect('doubleOpen', '2024-02-26');
        Observer.Expect('doubleClose', '2024-02-26');
        Observer.Expect('doubleBoth', '2024-02-26');
        Observer.Expect('leadingBlank', '2024-02-26');
        Observer.Expect('blankInside', '2024-02-26');
        Observer.Expect('trailingBlank', '2024-02-26');
        Observer.Expect('lowerCase', '2024-02-26');
        Observer.Expect('lowerCaseOpenOnly', '2024-02-26');
        Observer.Expect('emptyAngles', '2024-01-15');
        Observer.Expect('openAlone', '2024-01-15');
        Observer.Expect('closeAlone', '2024-01-15');
        Observer.Expect('noNumber|text', 'The date formula ''W'' should include a number.');
        Observer.Expect('noNumber|code', 'Evaluate');
        Observer.Expect('noNumberOpen|text', 'The date formula ''<W'' should include a number.');
        Observer.Expect('noNumberOpen|code', 'Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure P136_CalcDate_EvaluateOneBracket()
    var
        Observer: Codeunit "Probe Observer";
        DF: DateFormula;
        Ok: Boolean;
    begin
        Ok := Evaluate(DF, '<+6W');
        Observer.Observe('evalOpenOnly', Format(Ok) + '|' + Format(DF));
        Clear(DF);
        Ok := Evaluate(DF, '+6W>');
        Observer.Observe('evalCloseOnly', Format(Ok) + '|' + Format(DF));
        Clear(DF);
        Ok := Evaluate(DF, '<<+6W>');
        Observer.Observe('evalDoubleOpen', Format(Ok) + '|' + Format(DF));
        Clear(DF);
        Ok := Evaluate(DF, '<+6W>>');
        Observer.Observe('evalDoubleClose', Format(Ok) + '|' + Format(DF));
        Clear(DF);
        Ok := Evaluate(DF, ' <+6W> ');
        Observer.Observe('evalBlanks', Format(Ok) + '|' + Format(DF));
        Clear(DF);
        Ok := Evaluate(DF, '<1M');
        Observer.Observe('evalOpen1M', Format(Ok) + '|' + Format(DF));
        Observer.Expect('evalOpenOnly', 'Yes|+6W');
        Observer.Expect('evalCloseOnly', 'Yes|+6W');
        Observer.Expect('evalDoubleOpen', 'Yes|+6W');
        Observer.Expect('evalDoubleClose', 'Yes|+6W');
        Observer.Expect('evalBlanks', 'Yes|+6W');
        Observer.Expect('evalOpen1M', 'Yes|1M');
        Observer.Verify();
    end;
}
