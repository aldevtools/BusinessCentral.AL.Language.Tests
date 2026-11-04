// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/methods-auto/date/date-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Corpus issue 659 item 2 (from al-runtime-rs #251): the method forms Date.Year(), Day(), Month(), DayOfWeek() and WeekNo(), next to
// Date2DMY and Date2DWY, for ordinary dates, year and week edges and 0D. Day, Month and Year of 0D and of 0001-01-01 are also in
// types/lt-totext-bigtext-codeunit-run/P93Date.al.

codeunit 80960 "BC Date Methods"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryMethods(D: Date; var R: Text)
    begin
        R := Format(D.Year()) + '|' + Format(D.Month()) + '|' + Format(D.Day()) + '|' + Format(D.DayOfWeek()) + '|' + Format(D.WeekNo());
    end;

    [TryFunction]
    local procedure TryFunctions(D: Date; var R: Text)
    begin
        R := Format(Date2DMY(D, 3)) + '|' + Format(Date2DMY(D, 2)) + '|' + Format(Date2DMY(D, 1)) + '|' + Format(Date2DWY(D, 1)) + '|' + Format(Date2DWY(D, 2));
    end;

    local procedure Methods(D: Date): Text
    var
        R: Text;
    begin
        if TryMethods(D, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Functions(D: Date): Text
    var
        R: Text;
    begin
        if TryFunctions(D, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Both(var Observer: Codeunit "Probe Observer"; Name: Text; D: Date)
    begin
        Observer.Observe(Name, Methods(D));
        Observer.Observe(Name + ' fn', Functions(D));
    end;

    [Test]
    procedure DateMethods_OrdinaryAndEdgeDates()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, 'repro 2026-10-18', 20261018D);
        Both(Observer, '2024-02-29', 20240229D);
        Both(Observer, '2021-01-01 week 53', 20210101D);
        Both(Observer, '2024-12-30 week 1', 20241230D);
        Both(Observer, '2023-01-01 sunday', 20230101D);
        Both(Observer, '9999-12-31', 99991231D);
        Both(Observer, 'closing 2025-12-31', ClosingDate(20251231D));
        Observer.Expect('repro 2026-10-18', '2026|10|18|7|42');
        Observer.Expect('repro 2026-10-18 fn', '2026|10|18|7|42');
        Observer.Expect('2024-02-29', '2024|2|29|4|9');
        Observer.Expect('2024-02-29 fn', '2024|2|29|4|9');
        Observer.Expect('2021-01-01 week 53', '2021|1|1|5|53');
        Observer.Expect('2021-01-01 week 53 fn', '2021|1|1|5|53');
        Observer.Expect('2024-12-30 week 1', '2024|12|30|1|1');
        Observer.Expect('2024-12-30 week 1 fn', '2024|12|30|1|1');
        Observer.Expect('2023-01-01 sunday', '2023|1|1|7|52');
        Observer.Expect('2023-01-01 sunday fn', '2023|1|1|7|52');
        Observer.Expect('9999-12-31', '9999|12|31|5|52');
        Observer.Expect('9999-12-31 fn', '9999|12|31|5|52');
        Observer.Expect('closing 2025-12-31', '2025|12|31|3|1');
        Observer.Expect('closing 2025-12-31 fn', '2025|12|31|3|1');
        Observer.Verify();
    end;

    [Test]
    procedure DateMethods_MinDateLiteral()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Passing the literal 00010101D as an argument already fails (as in P93Date.al DayMonthYear_Normal), before any method runs.
        asserterror Both(Observer, '0001-01-01', 00010101D);
        Observer.ObserveError('min literal');
        Observer.Expect('min literal|text', 'The date is not valid.');
        Observer.Expect('min literal|code', 'DateInvalid');
        Observer.Verify();
    end;

    [Test]
    procedure DateMethods_ZeroDate()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
        Y: Integer;
    begin
        Both(Observer, '0D variable', D);
        Both(Observer, '0D literal', 0D);
        ClearLastError();
        asserterror Y := D.Year();
        Observer.ObserveError('year of 0D direct');
        Observer.Observe('y after', Format(Y));
        Observer.Expect('0D variable', 'error:The date is not valid.|DateInvalid');
        Observer.Expect('0D variable fn', 'error:The date is not valid.|DateInvalid');
        Observer.Expect('0D literal', 'error:The date is not valid.|DateInvalid');
        Observer.Expect('0D literal fn', 'error:The date is not valid.|DateInvalid');
        Observer.Expect('year of 0D direct|text', 'The date is not valid.');
        Observer.Expect('year of 0D direct|code', 'DateInvalid');
        Observer.Expect('y after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure DateMethods_ResultTypes()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        V := 20261018D.Year();
        Observer.Observe('year is integer', Format(V.IsInteger()));
        V := 20261018D.DayOfWeek();
        Observer.Observe('dayofweek is integer', Format(V.IsInteger()));
        V := 20261018D.WeekNo();
        Observer.Observe('weekno is integer', Format(V.IsInteger()));
        Observer.Expect('year is integer', 'Yes');
        Observer.Expect('dayofweek is integer', 'Yes');
        Observer.Expect('weekno is integer', 'Yes');
        Observer.Verify();
    end;
}
