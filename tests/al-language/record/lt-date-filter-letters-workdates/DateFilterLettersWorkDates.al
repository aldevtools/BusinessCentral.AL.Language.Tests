// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 70316 "LT P81 DF" (record/lt-loadfields-pagesource-validate/P81DateFilters.al)
// Probe: the date filter letters TODAY, WORKDATE, M, Y, D, CM, CY, CW, -1D, +1D, T-1D and 1D set with Record.SetFilter, each under five fixed work dates, so
// that the filter text shows which letters follow the work date and which follow Today(). Moved here from P81DateFilters.al (test
// SetFilter_Date_OtherKeywordLetters, which asserted dates of the day it was written). Object id 78000.
// Observed on BC 29.0 (run date 2026-10-18): M is the Monday of the week of the work date; D is the work date; 1D is day 1 of the month of the work date;
// CM, CY, CW, -1D and +1D follow Today() (CW and CY are not told apart from the work date unless the work date is in another year: 2030-05-15);
// Y covers the year of the work date for the 2026 work dates, but gives 01/01/27..12/31/9999 for 2030-05-15, and T-1D gives 12/30/25 for the 2026 work dates but
// 01/01/30 for 2030-05-15. Those two are asserted only for the work date 2026-01-01 (as before) and ignored for the others.

codeunit 78000 "LT AD Date Filter Letters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Base: Date)
    var
        Row: Record "LT P81 DF";
    begin
        Row.DeleteAll();
        AddRow('Z0', 0D);
        AddRow('P7', Base - 7);
        AddRow('P1', Base - 1);
        AddRow('P0', Base);
        AddRow('N1', Base + 1);
        AddRow('N7', Base + 7);
        AddRow('MS', CalcDate('<-CM>', Base));
        AddRow('ME', CalcDate('<CM>', Base));
        AddRow('YE', CalcDate('<CY>', Base));
    end;

    local procedure SeedOriginal()
    var
        Row: Record "LT P81 DF";
    begin
        Row.DeleteAll();
        AddRow('E0', 0D);
        AddRow('E1', 20251231D);
        AddRow('E2', 20260101D);
        AddRow('E3', 20260102D);
        AddRow('E4', 20260201D);
    end;

    local procedure AddRow(NewCode: Code[10]; NewDate: Date)
    var
        Row: Record "LT P81 DF";
    begin
        Row.Code := NewCode;
        Row.D := NewDate;
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryFilter(var Row: Record "LT P81 DF"; Txt: Text)
    begin
        Row.SetFilter(D, Txt);
    end;

    local procedure Scrub(Txt: Text): Text
    begin
        exit(Txt.Replace(Format(Today()), '<today>').Replace(Format(WorkDate()), '<workdate>'));
    end;

    local procedure Apply(Txt: Text): Text
    var
        Row: Record "LT P81 DF";
        Codes: Text;
    begin
        if TryFilter(Row, Txt) then begin
            if Row.FindSet() then
                repeat
                    Codes += Row.Code + ',';
                until Row.Next() = 0;
            exit('ok|filter=' + Scrub(Row.GetFilter(D)) + '|rows=' + Codes);
        end;
        exit('error:' + Scrub(GetLastErrorText()) + '|' + GetLastErrorCode());
    end;

    local procedure ObserveLetters(var Observer: Codeunit "Probe Observer"; Prefix: Text; Part: Integer)
    var
        Texts: List of [Text];
        i: Integer;
    begin
        if Part = 1 then begin
            Texts.Add('TODAY');
            Texts.Add('Today');
            Texts.Add('WORKDATE');
            Texts.Add('M');
            Texts.Add('Y');
            Texts.Add('D');
            Texts.Add('CM');
        end else begin
            Texts.Add('CY');
            Texts.Add('CW');
            Texts.Add('-1D');
            Texts.Add('+1D');
            Texts.Add('T-1D');
            Texts.Add('1D');
        end;
        for i := 1 to Texts.Count() do
            Observer.Observe(Prefix + Texts.Get(i), Apply(Texts.Get(i)));
    end;

    // The filter text of a letter that follows Today(): the date formula applied to Today(), in the format of GetFilter.
    // Scrubbed under the work date the observation ran with (RunWorkDate), as Apply scrubs it: scrubbed under the session's own
    // work date instead, the expected text became '<workdate>' on a day when that formula hit the session's work date (master run
    // 41377986019, 2026-11-02: '-1D' = 11/01/26 = the session's work date) while the observed text stayed a date.
    local procedure TodayRel(Formula: Text; RunWorkDate: Date): Text
    var
        SavedWorkDate: Date;
        Result: Text;
    begin
        SavedWorkDate := WorkDate();
        WorkDate(RunWorkDate);
        Result := 'ok|filter=' + Scrub(Format(CalcDate(Formula, Today()), 0, '<Month,2>/<Day,2>/<Year,2>')) + '|rows=';
        WorkDate(SavedWorkDate);
        exit(Result);
    end;

    local procedure RunFor(var Observer: Codeunit "Probe Observer"; WorkDay: Date; Part: Integer)
    var
        SavedWorkDate: Date;
    begin
        SavedWorkDate := WorkDate();
        WorkDate(WorkDay);
        Seed(WorkDay);
        ObserveLetters(Observer, 'w' + Format(WorkDay, 0, '<Year4>-<Month,2>-<Day,2>') + ' ', Part);
        WorkDate(SavedWorkDate);
    end;

    local procedure RunOriginal(var Observer: Codeunit "Probe Observer"; Part: Integer)
    var
        SavedWorkDate: Date;
    begin
        SavedWorkDate := WorkDate();
        WorkDate(20260101D);
        SeedOriginal();
        ObserveLetters(Observer, 'o ', Part);
        WorkDate(SavedWorkDate);
    end;

    [Test]
    procedure Letters_Original_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOriginal(Observer, 1);
        Observer.Expect('o TODAY', 'ok|filter=<today>|rows=');
        Observer.Expect('o Today', 'ok|filter=<today>|rows=');
        Observer.Expect('o WORKDATE', 'ok|filter=<workdate>|rows=E2,');
        Observer.Expect('o M', 'ok|filter=12/29/25|rows=');
        Observer.Expect('o Y', 'ok|filter=<workdate>..12/31/26|rows=E2,E3,E4,');
        Observer.Expect('o D', 'ok|filter=<workdate>|rows=E2,');
        Observer.Expect('o CM', TodayRel('<CM>', 20260101D));
        Observer.Verify();
    end;

    [Test]
    procedure Letters_Original_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOriginal(Observer, 2);
        Observer.Expect('o CY', TodayRel('<CY>', 20260101D));
        Observer.Expect('o CW', TodayRel('<CW>', 20260101D));
        Observer.Expect('o -1D', TodayRel('<-1D>', 20260101D));
        Observer.Expect('o +1D', TodayRel('<+1D>', 20260101D));
        Observer.Expect('o T-1D', 'ok|filter=12/30/25|rows=');
        Observer.Expect('o 1D', 'ok|filter=<workdate>|rows=E2,');
        Observer.Verify();
    end;

    [Test]
    procedure Letters_March18_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFor(Observer, 20260318D, 1);
        Observer.Expect('w2026-03-18 TODAY', 'ok|filter=<today>|rows=');
        Observer.Expect('w2026-03-18 Today', 'ok|filter=<today>|rows=');
        Observer.Expect('w2026-03-18 WORKDATE', 'ok|filter=<workdate>|rows=P0,');
        Observer.Expect('w2026-03-18 M', 'ok|filter=03/16/26|rows=');
        Observer.Ignore('w2026-03-18 Y'); // depends on Today() or its year; the row list can change with the run date
        Observer.Expect('w2026-03-18 D', 'ok|filter=<workdate>|rows=P0,');
        Observer.Ignore('w2026-03-18 CM'); // depends on Today() or its year; the row list can change with the run date
        Observer.Verify();
    end;

    [Test]
    procedure Letters_March18_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFor(Observer, 20260318D, 2);
        Observer.Ignore('w2026-03-18 CY'); // depends on Today() or its year; the row list can change with the run date
        Observer.Ignore('w2026-03-18 CW'); // depends on Today() or its year; the row list can change with the run date
        Observer.Ignore('w2026-03-18 -1D'); // depends on Today() or its year; the row list can change with the run date
        Observer.Ignore('w2026-03-18 +1D'); // depends on Today() or its year; the row list can change with the run date
        Observer.Ignore('w2026-03-18 T-1D'); // depends on Today() or its year; the row list can change with the run date
        Observer.Expect('w2026-03-18 1D', 'ok|filter=03/01/26|rows=MS,');
        Observer.Verify();
    end;

    [Test]
    procedure Letters_July1_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFor(Observer, 20260701D, 1);
        Observer.Expect('w2026-07-01 TODAY', 'ok|filter=<today>|rows=');
        Observer.Expect('w2026-07-01 Today', 'ok|filter=<today>|rows=');
        Observer.Expect('w2026-07-01 WORKDATE', 'ok|filter=<workdate>|rows=MS,P0,');
        Observer.Expect('w2026-07-01 M', 'ok|filter=06/29/26|rows=');
        Observer.Ignore('w2026-07-01 Y'); // depends on Today() or its year; the row list can change with the run date
        Observer.Expect('w2026-07-01 D', 'ok|filter=<workdate>|rows=MS,P0,');
        Observer.Ignore('w2026-07-01 CM'); // depends on Today() or its year; the row list can change with the run date
        Observer.Verify();
    end;

    [Test]
    procedure Letters_July1_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFor(Observer, 20260701D, 2);
        Observer.Ignore('w2026-07-01 CY'); // depends on Today() or its year; the row list can change with the run date
        Observer.Ignore('w2026-07-01 CW'); // depends on Today() or its year; the row list can change with the run date
        Observer.Ignore('w2026-07-01 -1D'); // depends on Today() or its year; the row list can change with the run date
        Observer.Ignore('w2026-07-01 +1D'); // depends on Today() or its year; the row list can change with the run date
        Observer.Ignore('w2026-07-01 T-1D'); // depends on Today() or its year; the row list can change with the run date
        Observer.Expect('w2026-07-01 1D', 'ok|filter=<workdate>|rows=MS,P0,');
        Observer.Verify();
    end;

    [Test]
    procedure Letters_Dec31_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFor(Observer, 20261231D, 1);
        Observer.Expect('w2026-12-31 TODAY', 'ok|filter=<today>|rows=');
        Observer.Expect('w2026-12-31 Today', 'ok|filter=<today>|rows=');
        Observer.Expect('w2026-12-31 WORKDATE', 'ok|filter=<workdate>|rows=ME,P0,YE,');
        Observer.Expect('w2026-12-31 M', 'ok|filter=12/28/26|rows=');
        Observer.Ignore('w2026-12-31 Y'); // depends on Today() or its year; the row list can change with the run date
        Observer.Expect('w2026-12-31 D', 'ok|filter=<workdate>|rows=ME,P0,YE,');
        Observer.Ignore('w2026-12-31 CM'); // depends on Today() or its year; the row list can change with the run date
        Observer.Verify();
    end;

    [Test]
    procedure Letters_Dec31_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFor(Observer, 20261231D, 2);
        Observer.Ignore('w2026-12-31 CY'); // depends on Today() or its year; the row list can change with the run date
        Observer.Ignore('w2026-12-31 CW'); // depends on Today() or its year; the row list can change with the run date
        Observer.Ignore('w2026-12-31 -1D'); // depends on Today() or its year; the row list can change with the run date
        Observer.Ignore('w2026-12-31 +1D'); // depends on Today() or its year; the row list can change with the run date
        Observer.Ignore('w2026-12-31 T-1D'); // depends on Today() or its year; the row list can change with the run date
        Observer.Expect('w2026-12-31 1D', 'ok|filter=12/01/26|rows=MS,');
        Observer.Verify();
    end;

    [Test]
    procedure Letters_2030_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFor(Observer, 20300515D, 1);
        Observer.Expect('w2030-05-15 TODAY', 'ok|filter=<today>|rows=');
        Observer.Expect('w2030-05-15 Today', 'ok|filter=<today>|rows=');
        Observer.Expect('w2030-05-15 WORKDATE', 'ok|filter=<workdate>|rows=P0,');
        Observer.Expect('w2030-05-15 M', 'ok|filter=05/13/30|rows=');
        Observer.Ignore('w2030-05-15 Y'); // follows neither the work date nor Today in a way that stays stable; see the file header
        Observer.Expect('w2030-05-15 D', 'ok|filter=<workdate>|rows=P0,');
        Observer.Expect('w2030-05-15 CM', TodayRel('<CM>', 20300515D));
        Observer.Verify();
    end;

    [Test]
    procedure Letters_2030_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFor(Observer, 20300515D, 2);
        Observer.Expect('w2030-05-15 CY', TodayRel('<CY>', 20300515D));
        Observer.Expect('w2030-05-15 CW', TodayRel('<CW>', 20300515D));
        Observer.Expect('w2030-05-15 -1D', TodayRel('<-1D>', 20300515D));
        Observer.Expect('w2030-05-15 +1D', TodayRel('<+1D>', 20300515D));
        Observer.Ignore('w2030-05-15 T-1D'); // follows neither the work date nor Today in a way that stays stable; see the file header
        Observer.Expect('w2030-05-15 1D', 'ok|filter=05/01/30|rows=MS,');
        Observer.Verify();
    end;
}
