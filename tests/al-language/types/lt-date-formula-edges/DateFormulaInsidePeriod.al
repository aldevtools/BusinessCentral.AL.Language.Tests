// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own test codeunit 91352
// Probe: observe probe (writer Y7, 2026-10-30, asked by an al-runtime-rs runtime agent); every literal asserted below is what the BC service tier produced
//   (SaaS sandbox BC 29 first, then the corpus CI legs).
// Facts: CalcDate of <D1> from a date that is not the last day of its month (day 1 itself, day 2, the leap-year 28 February, ...); <W21> and <W25> before, on the
//   Monday of, inside, on the Sunday of and after that week (2024, 2020 with 53 weeks, 2026); <W17> on a date inside week 17 and <Q3> on a date inside the third
//   quarter. types/lt-date-formula-edges/DateFormulaEdges.al and misc/lt-np4-probes/Np4DateFormulas.al pin the same letters from other base dates.
//   No test depends on the run date.
// BC versions: 27, 28, 29

codeunit 91352 "LT Y7 Date Formula In Period"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCalc(Formula: Text; Base: Date; var Result: Date)
    begin
        Result := CalcDate(Formula, Base);
    end;

    local procedure One(var Observer: Codeunit "Probe Observer"; Formula: Text; Base: Date)
    var
        R: Date;
    begin
        if TryCalc(Formula, Base, R) then
            Observer.Observe(Formula + ' ' + Format(Base, 0, 9), 'ok|' + Format(R, 0, 9))
        else begin
            Observer.Observe(Formula + ' ' + Format(Base, 0, 9), CopyStr('error:' + GetLastErrorText() + '|' + GetLastErrorCode(), 1, 600));
            ClearLastError();
        end;
    end;

    [Test]
    procedure Y7_CalcDate_D1_NotLastDay()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, '<D1>', 20240101D);
        One(Observer, '<D1>', 20240102D);
        One(Observer, '<D1>', 20240228D);
        One(Observer, '<D1>', 20230227D);
        One(Observer, '<D1>', 20240329D);
        One(Observer, '<D1>', 20240429D);
        One(Observer, '<D1>', 20241201D);
        One(Observer, '<D1>', 20241230D);
        One(Observer, '<-D1>', 20240115D);
        One(Observer, '<-D1>', 20240101D);
        Observer.Finish();
    end;

    [Test]
    procedure Y7_CalcDate_W21()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, '<W21>', 20240519D);
        One(Observer, '<W21>', 20240520D);
        One(Observer, '<W21>', 20240522D);
        One(Observer, '<W21>', 20240526D);
        One(Observer, '<W21>', 20240527D);
        One(Observer, '<W21>', 20200518D);
        One(Observer, '<W21>', 20200520D);
        One(Observer, '<W21>', 20210101D);
        One(Observer, '<W21>', 20261030D);
        Observer.Finish();
    end;

    [Test]
    procedure Y7_CalcDate_W25()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, '<W25>', 20240616D);
        One(Observer, '<W25>', 20240617D);
        One(Observer, '<W25>', 20240619D);
        One(Observer, '<W25>', 20240623D);
        One(Observer, '<W25>', 20240624D);
        One(Observer, '<W25>', 20260615D);
        One(Observer, '<W25>', 20260617D);
        One(Observer, '<W25>', 20261030D);
        Observer.Finish();
    end;

    [Test]
    procedure Y7_CalcDate_W17_InsideWeek()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, '<W17>', 20240422D);
        One(Observer, '<W17>', 20240424D);
        One(Observer, '<W17>', 20240428D);
        One(Observer, '<W17>', 20230424D);
        One(Observer, '<W17>', 20230426D);
        One(Observer, '<W17>', 20230430D);
        Observer.Finish();
    end;

    [Test]
    procedure Y7_CalcDate_Q3_InsideQuarter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, '<Q3>', 20240701D);
        One(Observer, '<Q3>', 20240815D);
        One(Observer, '<Q3>', 20240930D);
        One(Observer, '<Q3>', 20230701D);
        One(Observer, '<Q3>', 20230915D);
        Observer.Finish();
    end;
}
