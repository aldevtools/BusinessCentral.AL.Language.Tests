// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: CalcDate with a signed working-day unit (+1WD, -1WD, with and without angle brackets) and with the percent forms <%Q> and <%Y>, for
// a Friday, a Saturday, a Sunday, a Monday, the end of a quarter, the end of a year and a mid-quarter date; the result or the error text and code.
// Object id 78001.

codeunit 78001 "LT AD Date Formula Signed WD"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCalc(Formula: Text; D: Date; var Result: Date)
    begin
        Result := CalcDate(Formula, D);
    end;

    local procedure Calc(Formula: Text; D: Date): Text
    var
        Result: Date;
    begin
        ClearLastError();
        if TryCalc(Formula, D, Result) then
            exit('ok:' + Format(Result, 0, '<Year4>-<Month,2>-<Day,2>'));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ObserveFormula(var Observer: Codeunit "Probe Observer"; Formula: Text)
    begin
        Observer.Observe(Formula + ' fri', Calc(Formula, 20240112D));
        Observer.Observe(Formula + ' sat', Calc(Formula, 20240113D));
        Observer.Observe(Formula + ' sun', Calc(Formula, 20240114D));
        Observer.Observe(Formula + ' mon', Calc(Formula, 20240115D));
        Observer.Observe(Formula + ' q-end', Calc(Formula, 20240331D));
        Observer.Observe(Formula + ' y-end', Calc(Formula, 20241231D));
        Observer.Observe(Formula + ' mid', Calc(Formula, 20260518D));
    end;

    [Test]
    procedure SignedWD_Plus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveFormula(Observer, '+1WD');
        ObserveFormula(Observer, '<+1WD>');
        Observer.Expect('+1WD fri', 'ok:2024-01-13');
        Observer.Expect('+1WD sat', 'ok:2024-01-14');
        Observer.Expect('+1WD sun', 'ok:2024-01-15');
        Observer.Expect('+1WD mon', 'ok:2024-01-16');
        Observer.Expect('+1WD q-end', 'ok:2024-04-01');
        Observer.Expect('+1WD y-end', 'ok:2025-01-01');
        Observer.Expect('+1WD mid', 'ok:2026-05-19');
        Observer.Expect('<+1WD> fri', 'ok:2024-01-13');
        Observer.Expect('<+1WD> sat', 'ok:2024-01-14');
        Observer.Expect('<+1WD> sun', 'ok:2024-01-15');
        Observer.Expect('<+1WD> mon', 'ok:2024-01-16');
        Observer.Expect('<+1WD> q-end', 'ok:2024-04-01');
        Observer.Expect('<+1WD> y-end', 'ok:2025-01-01');
        Observer.Expect('<+1WD> mid', 'ok:2026-05-19');
        Observer.Verify();
    end;

    [Test]
    procedure SignedWD_Minus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveFormula(Observer, '-1WD');
        ObserveFormula(Observer, '<-1WD>');
        Observer.Expect('-1WD fri', 'ok:2024-01-11');
        Observer.Expect('-1WD sat', 'ok:2024-01-12');
        Observer.Expect('-1WD sun', 'ok:2024-01-13');
        Observer.Expect('-1WD mon', 'ok:2024-01-14');
        Observer.Expect('-1WD q-end', 'ok:2024-03-30');
        Observer.Expect('-1WD y-end', 'ok:2024-12-30');
        Observer.Expect('-1WD mid', 'ok:2026-05-17');
        Observer.Expect('<-1WD> fri', 'ok:2024-01-11');
        Observer.Expect('<-1WD> sat', 'ok:2024-01-12');
        Observer.Expect('<-1WD> sun', 'ok:2024-01-13');
        Observer.Expect('<-1WD> mon', 'ok:2024-01-14');
        Observer.Expect('<-1WD> q-end', 'ok:2024-03-30');
        Observer.Expect('<-1WD> y-end', 'ok:2024-12-30');
        Observer.Expect('<-1WD> mid', 'ok:2026-05-17');
        Observer.Verify();
    end;

    [Test]
    procedure Percent_Quarter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveFormula(Observer, '<%Q>');
        ObserveFormula(Observer, '%Q');
        Observer.Expect('<%Q> fri', 'error:The date formula ''%Q'' should include a number.|Evaluate');
        Observer.Expect('<%Q> sat', 'error:The date formula ''%Q'' should include a number.|Evaluate');
        Observer.Expect('<%Q> sun', 'error:The date formula ''%Q'' should include a number.|Evaluate');
        Observer.Expect('<%Q> mon', 'error:The date formula ''%Q'' should include a number.|Evaluate');
        Observer.Expect('<%Q> q-end', 'error:The date formula ''%Q'' should include a number.|Evaluate');
        Observer.Expect('<%Q> y-end', 'error:The date formula ''%Q'' should include a number.|Evaluate');
        Observer.Expect('<%Q> mid', 'error:The date formula ''%Q'' should include a number.|Evaluate');
        Observer.Expect('%Q fri', 'error:The date formula ''%Q'' should include a number.|Evaluate');
        Observer.Expect('%Q sat', 'error:The date formula ''%Q'' should include a number.|Evaluate');
        Observer.Expect('%Q sun', 'error:The date formula ''%Q'' should include a number.|Evaluate');
        Observer.Expect('%Q mon', 'error:The date formula ''%Q'' should include a number.|Evaluate');
        Observer.Expect('%Q q-end', 'error:The date formula ''%Q'' should include a number.|Evaluate');
        Observer.Expect('%Q y-end', 'error:The date formula ''%Q'' should include a number.|Evaluate');
        Observer.Expect('%Q mid', 'error:The date formula ''%Q'' should include a number.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure Percent_Year()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveFormula(Observer, '<%Y>');
        ObserveFormula(Observer, '%Y');
        Observer.Expect('<%Y> fri', 'error:The date formula ''%Y'' should include a number.|Evaluate');
        Observer.Expect('<%Y> sat', 'error:The date formula ''%Y'' should include a number.|Evaluate');
        Observer.Expect('<%Y> sun', 'error:The date formula ''%Y'' should include a number.|Evaluate');
        Observer.Expect('<%Y> mon', 'error:The date formula ''%Y'' should include a number.|Evaluate');
        Observer.Expect('<%Y> q-end', 'error:The date formula ''%Y'' should include a number.|Evaluate');
        Observer.Expect('<%Y> y-end', 'error:The date formula ''%Y'' should include a number.|Evaluate');
        Observer.Expect('<%Y> mid', 'error:The date formula ''%Y'' should include a number.|Evaluate');
        Observer.Expect('%Y fri', 'error:The date formula ''%Y'' should include a number.|Evaluate');
        Observer.Expect('%Y sat', 'error:The date formula ''%Y'' should include a number.|Evaluate');
        Observer.Expect('%Y sun', 'error:The date formula ''%Y'' should include a number.|Evaluate');
        Observer.Expect('%Y mon', 'error:The date formula ''%Y'' should include a number.|Evaluate');
        Observer.Expect('%Y q-end', 'error:The date formula ''%Y'' should include a number.|Evaluate');
        Observer.Expect('%Y y-end', 'error:The date formula ''%Y'' should include a number.|Evaluate');
        Observer.Expect('%Y mid', 'error:The date formula ''%Y'' should include a number.|Evaluate');
        Observer.Verify();
    end;
}
