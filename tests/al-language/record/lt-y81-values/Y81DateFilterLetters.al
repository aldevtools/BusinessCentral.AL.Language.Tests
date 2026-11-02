// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 94250, test codeunit 94251
// Probe (writer Y81): the date filter letters Y and T-1D set with Record.SetFilter under fixed work dates, and the letters around them (T, T+1D, T-xD, W, Q, M, D, 1Y, -1Y,
// and ranges with Y or T-1D). Today() and the work date are never written as literals: every expectation that depends on them is computed from them in the test.
// Facts measured (SaaS BC 29, Today() 2026-11-02): Y is the fiscal year of the work date taken from the Accounting Period table (rows with New Fiscal Year): from the
// latest New Fiscal Year row on or before the work date to the day before the next New Fiscal Year row (or 9999-12-31 after the last one); with no such row the filter
// fails ("The Accounting Period does not exist.", Filter:CSide). The test writes its own periods in 2060 to 2062 and removes them again. T-1D is the Tuesday of ISO week 1 of
// the ISO year of the work date; T and T+1D follow Today().
// Pinned elsewhere: record/lt-date-filter-letters-workdates/DateFilterLettersWorkDates.al (evaluates Y and T-1D but ignores their values).
// BC versions: 27, 28, 29

table 94250 "LT Y81 DF"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; D; Date) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 94251 "LT Y81 Date Filter Letters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        InsertedPeriods: List of [Date];

    [TryFunction]
    local procedure TryFilter(Txt: Text; var R: Text)
    var
        Row: Record "LT Y81 DF";
    begin
        Row.SetFilter(D, Txt);
        R := 'ok|' + Row.GetFilter(D);
        R += '|' + Format(Row.GetRangeMin(D), 0, 9);
        R += '|' + Format(Row.GetRangeMax(D), 0, 9);
    end;

    // The filter text, then the range ends in format 9; an error ends the text with ' E <text>|<code>'.
    local procedure Apply(Txt: Text): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryFilter(Txt, R) then
            exit(R);
        exit(R + ' E ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // Only the range ends (no filter text), for expectations computed from dates.
    local procedure Ends(Txt: Text): Text
    var
        R: Text;
        P: List of [Text];
    begin
        R := Apply(Txt);
        if not R.StartsWith('ok|') then
            exit(R);
        P := R.Split('|');
        exit('ok|' + P.Get(3) + '|' + P.Get(4));
    end;

    local procedure Range(MinDate: Date; MaxDate: Date): Text
    begin
        exit('ok|' + Format(MinDate, 0, 9) + '|' + Format(MaxDate, 0, 9));
    end;

    local procedure InsertPeriod(StartingDate: Date; NewFiscalYear: Boolean)
    var
        Period: Record "Accounting Period";
    begin
        if Period.Get(StartingDate) then
            exit;
        Period.Init();
        Period."Starting Date" := StartingDate;
        Period.Name := CopyStr('Y81 ' + Format(StartingDate, 0, 9), 1, MaxStrLen(Period.Name));
        Period."New Fiscal Year" := NewFiscalYear;
        Period.Insert();
        InsertedPeriods.Add(StartingDate);
    end;

    local procedure WritePeriods()
    var
        Month: Integer;
    begin
        InsertPeriod(20600101D, true);
        for Month := 2 to 12 do
            InsertPeriod(DMY2Date(1, Month, 2060), false);
        InsertPeriod(20610401D, true);
        InsertPeriod(20610501D, false);
        InsertPeriod(20620101D, true);
    end;

    local procedure RestorePeriods()
    var
        Period: Record "Accounting Period";
        StartingDate: Date;
    begin
        foreach StartingDate in InsertedPeriods do
            if Period.Get(StartingDate) then
                Period.Delete();
        Clear(InsertedPeriods);
    end;

    local procedure ObserveFor(WorkDay: Date; Txt: Text)
    var
        Saved: Date;
    begin
        Saved := WorkDate();
        WorkDate(WorkDay);
        Observer.Observe(Format(WorkDay, 0, 9) + ' ' + Txt, Apply(Txt));
        WorkDate(Saved);
    end;

    [Test]
    procedure Y81_Y_FiscalYearOfWorkDate()
    begin
        WritePeriods();
        ObserveFor(20600101D, 'Y');
        ObserveFor(20600615D, 'Y');
        ObserveFor(20601231D, 'Y');
        ObserveFor(20610331D, 'Y');
        ObserveFor(20610401D, 'Y');
        ObserveFor(20611231D, 'Y');
        ObserveFor(20620101D, 'Y');
        ObserveFor(20620615D, 'Y');
        ObserveFor(20700101D, 'Y');
        RestorePeriods();
        Observer.Finish();
    end;

    [Test]
    procedure Y81_Y_InRanges()
    begin
        WritePeriods();
        ObserveFor(20600615D, 'Y..');
        ObserveFor(20600615D, '..Y');
        ObserveFor(20600615D, 'Y|Y');
        ObserveFor(20600615D, '<>Y');
        ObserveFor(20600615D, '>Y');
        ObserveFor(20600615D, '<=Y');
        ObserveFor(20610615D, 'Y&>01/01/2061');
        RestorePeriods();
        Observer.Finish();
    end;

    [Test]
    procedure Y81_T1D_TuesdayOfIsoWeek1()
    var
        WorkDays: List of [Date];
        WorkDay: Date;
        Saved: Date;
        Tuesday: Date;
    begin
        WorkDays.Add(20200615D);
        WorkDays.Add(20201231D);
        WorkDays.Add(20210101D);
        WorkDays.Add(20210104D);
        WorkDays.Add(20240615D);
        WorkDays.Add(20251231D);
        WorkDays.Add(20260101D);
        WorkDays.Add(20260615D);
        WorkDays.Add(20261231D);
        WorkDays.Add(20270101D);
        WorkDays.Add(20270615D);
        WorkDays.Add(20280229D);
        WorkDays.Add(20300515D);
        WorkDays.Add(20310101D);
        WorkDays.Add(20991231D);
        Saved := WorkDate();
        foreach WorkDay in WorkDays do begin
            WorkDate(WorkDay);
            Tuesday := DWY2Date(1, 2, Date2DWY(WorkDay, 3));
            Observer.Observe(Format(WorkDay, 0, 9), Ends('T-1D'));
            Observer.Expect(Format(WorkDay, 0, 9), Range(Tuesday, Tuesday));
        end;
        WorkDate(Saved);
        Observer.Verify();
    end;

    [Test]
    procedure Y81_T1D_FilterTextAndRanges()
    var
        Saved: Date;
    begin
        Saved := WorkDate();
        WorkDate(20240615D);
        Observer.Observe('2024 text', Apply('T-1D'));
        Observer.Observe('2024 T-1D..T', Apply('T-1D..T'));
        Observer.Observe('2024 ..T-1D', Apply('..T-1D'));
        Observer.Observe('2024 T-1D..', Apply('T-1D..'));
        WorkDate(20260615D);
        Observer.Observe('2026 text', Apply('T-1D'));
        Observer.Observe('2026 T-1D..T', Apply('T-1D..T'));
        Observer.Observe('2026 ..T-1D', Apply('..T-1D'));
        Observer.Observe('2026 T-1D..', Apply('T-1D..'));
        Observer.Observe('2026 T..T-1D', Apply('T..T-1D'));
        WorkDate(Saved);
        Observer.Finish();
    end;

    [Test]
    procedure Y81_Letters_FollowingToday()
    var
        WorkDays: List of [Date];
        WorkDay: Date;
        Saved: Date;
        Pfx: Text;
    begin
        WorkDays.Add(20240615D);
        WorkDays.Add(20260615D);
        WorkDays.Add(20300515D);
        Saved := WorkDate();
        foreach WorkDay in WorkDays do begin
            WorkDate(WorkDay);
            Pfx := Format(WorkDay, 0, 9) + ' ';
            Observer.Observe(Pfx + 'T', Ends('T'));
            Observer.Expect(Pfx + 'T', Range(Today(), Today()));
            Observer.Observe(Pfx + 'T+1D', Ends('T+1D'));
            Observer.Expect(Pfx + 'T+1D', Range(Today() + 1, Today() + 1));
            Observer.Observe(Pfx + 'Q', Ends('Q'));
            Observer.Expect(Pfx + 'Q', Range(CalcDate('<-CQ>', Today()), CalcDate('<CQ>', Today())));
            Observer.Observe(Pfx + '-1Y', Ends('-1Y'));
            Observer.Expect(Pfx + '-1Y', Range(CalcDate('<-1Y>', Today()), CalcDate('<-1Y>', Today())));
            Observer.Observe(Pfx + 'W', Ends('W'));
            Observer.Expect(Pfx + 'W', Range(WorkDay, WorkDay));
            Observer.Observe(Pfx + 'D', Ends('D'));
            Observer.Expect(Pfx + 'D', Range(WorkDay, WorkDay));
            Observer.Observe(Pfx + 'M', Ends('M'));
            Observer.Expect(Pfx + 'M', Range(WorkDay - (Date2DWY(WorkDay, 1) - 1), WorkDay - (Date2DWY(WorkDay, 1) - 1)));
            Observer.Observe(Pfx + '1Y', Ends('1Y'));
            Observer.Expect(Pfx + '1Y', Range(CalcDate('<-CM>', WorkDay), CalcDate('<-CM>', WorkDay)));
        end;
        WorkDate(Saved);
        Observer.Verify();
    end;

    [Test]
    procedure Y81_Letters_TFamily()
    var
        Texts: List of [Text];
        Txt: Text;
        Saved: Date;
    begin
        Saved := WorkDate();
        WorkDate(20260615D);
        Texts.Add('T-0D');
        Texts.Add('T+0D');
        Texts.Add('T-2D');
        Texts.Add('T-3D');
        Texts.Add('T-7D');
        Texts.Add('T+7D');
        Texts.Add('T-1W');
        Texts.Add('T+1W');
        Texts.Add('T-1M');
        Texts.Add('T-1Y');
        Texts.Add('T-1CM');
        Texts.Add('T-D');
        foreach Txt in Texts do
            Observer.Observe(Txt, Ends(Txt));
        Observer.Observe('today', Format(Today(), 0, 9));
        WorkDate(Saved);
        Observer.Finish();
    end;
}
