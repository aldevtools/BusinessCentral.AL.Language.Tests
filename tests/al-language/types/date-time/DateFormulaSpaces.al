// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-calcdate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70369
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: spaces inside date formulas, in CalcDate(Text, Date) and in Evaluate of a DateFormula followed by CalcDate(DateFormula, Date), base date 15 March 2027: the result date (ISO) or the error text start and code.
// BC versions: 29 (27 and 28 by CI)

codeunit 70369 "LT Date Formula Spaces"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCalc(Formula: Text; Base: Date; var Result: Text)
    begin
        Result := Format(CalcDate(Formula, Base), 0, 9);
    end;

    [TryFunction]
    local procedure TryEvaluate(Formula: Text; Base: Date; var Result: Text)
    var
        DF: DateFormula;
    begin
        Evaluate(DF, Formula);
        Result := Format(CalcDate(DF, Base), 0, 9) + ' | formula text [' + Format(DF) + ']';
    end;

    local procedure Calc(Formula: Text): Text
    var
        Result: Text;
    begin
        if TryCalc(Formula, 20270315D, Result) then
            exit(Result);
        exit('ERR:' + CopyStr(GetLastErrorText(), 1, 120) + '|' + GetLastErrorCode());
    end;

    local procedure Eval(Formula: Text): Text
    var
        Result: Text;
    begin
        if TryEvaluate(Formula, 20270315D, Result) then
            exit(Result);
        exit('ERR:' + CopyStr(GetLastErrorText(), 1, 120) + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure CalcDate_Spaces()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('<CM+1D> (no spaces)', Calc('<CM+1D>'));
        Observer.Observe('<CM + 1D>', Calc('<CM + 1D>'));
        Observer.Observe('<CM+ 1D>', Calc('<CM+ 1D>'));
        Observer.Observe('< CM+1D >', Calc('< CM+1D >'));
        Observer.Observe('<CM +1D>', Calc('<CM +1D>'));
        Observer.Observe('<CM+1D > (trailing)', Calc('<CM+1D >'));
        Observer.Observe('< CM+1D> (leading)', Calc('< CM+1D>'));
        Observer.Observe('<1 D>', Calc('<1 D>'));
        Observer.Observe('<1D> with outer spaces', Calc(' <1D> '));
        Observer.Observe('CM + 1D without angle brackets', Calc('CM + 1D'));
        Observer.Observe('<- 1D>', Calc('<- 1D>'));
        Observer.Observe('<-1D + 1W>', Calc('<-1D + 1W>'));
        Observer.Observe('<CM-1D> (no spaces)', Calc('<CM-1D>'));
        Observer.Observe('<CM - 1D>', Calc('<CM - 1D>'));
        Observer.Observe('<CM -1D>', Calc('<CM -1D>'));
        Observer.Observe('<CM- 1D>', Calc('<CM- 1D>'));
        Observer.Expect('<CM+1D> (no spaces)', '2027-04-01');
        Observer.Expect('<CM + 1D>', '2027-04-01');
        Observer.Expect('<CM+ 1D>', '2027-04-01');
        Observer.Expect('< CM+1D >', '2027-04-01');
        Observer.Expect('<CM +1D>', '2027-04-01');
        Observer.Expect('<CM+1D > (trailing)', '2027-04-01');
        Observer.Expect('< CM+1D> (leading)', '2027-04-01');
        Observer.Expect('<1 D>', '2027-03-16');
        Observer.Expect('<1D> with outer spaces', '2027-03-16');
        Observer.Expect('CM + 1D without angle brackets', '2027-04-01');
        Observer.Expect('<- 1D>', '2027-03-14');
        Observer.Expect('<-1D + 1W>', '2027-03-21');
        Observer.Expect('<CM-1D> (no spaces)', '2027-03-30');
        Observer.Expect('<CM - 1D>', '2027-03-30');
        Observer.Expect('<CM -1D>', '2027-03-30');
        Observer.Expect('<CM- 1D>', '2027-03-30');
        Observer.Verify();
    end;

    [Test]
    procedure EvaluateDateFormula_Spaces()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('<CM+1D> (no spaces)', Eval('<CM+1D>'));
        Observer.Observe('<CM + 1D>', Eval('<CM + 1D>'));
        Observer.Observe('<CM+ 1D>', Eval('<CM+ 1D>'));
        Observer.Observe('< CM+1D >', Eval('< CM+1D >'));
        Observer.Observe('<CM +1D>', Eval('<CM +1D>'));
        Observer.Observe('<CM+1D > (trailing)', Eval('<CM+1D >'));
        Observer.Observe('< CM+1D> (leading)', Eval('< CM+1D>'));
        Observer.Observe('<1 D>', Eval('<1 D>'));
        Observer.Observe('<1D> with outer spaces', Eval(' <1D> '));
        Observer.Observe('CM + 1D without angle brackets', Eval('CM + 1D'));
        Observer.Observe('<CM - 1D>', Eval('<CM - 1D>'));
        Observer.Observe('<CM -1D>', Eval('<CM -1D>'));
        Observer.Observe('<CM- 1D>', Eval('<CM- 1D>'));
        Observer.Expect('<CM+1D> (no spaces)', '2027-04-01 | formula text [CM+1D]');
        Observer.Expect('<CM + 1D>', '2027-04-01 | formula text [CM+1D]');
        Observer.Expect('<CM+ 1D>', '2027-04-01 | formula text [CM+1D]');
        Observer.Expect('< CM+1D >', '2027-04-01 | formula text [CM+1D]');
        Observer.Expect('<CM +1D>', '2027-04-01 | formula text [CM+1D]');
        Observer.Expect('<CM+1D > (trailing)', '2027-04-01 | formula text [CM+1D]');
        Observer.Expect('< CM+1D> (leading)', '2027-04-01 | formula text [CM+1D]');
        Observer.Expect('<1 D>', '2027-03-16 | formula text [1D]');
        Observer.Expect('<1D> with outer spaces', '2027-03-16 | formula text [1D]');
        Observer.Expect('CM + 1D without angle brackets', '2027-04-01 | formula text [CM+1D]');
        Observer.Expect('<CM - 1D>', '2027-03-30 | formula text [CM-1D]');
        Observer.Expect('<CM -1D>', '2027-03-30 | formula text [CM-1D]');
        Observer.Expect('<CM- 1D>', '2027-03-30 | formula text [CM-1D]');
        Observer.Verify();
    end;
}
