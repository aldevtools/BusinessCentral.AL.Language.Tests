// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-getfilter-method
// Scope: in-scope
// Fixtures used: RRE Row (60866), RRE Log (60867), RGF Filter Report (60998)
//
// AL Runner #1895: a report's data-item filters — applied either through the instance
// Report.SetTableView(Rec) form or the record-parameter static Report.Run/RunModal
// overload — must be visible through Record.GetFilter() from INSIDE the report's own
// triggers, not just constrain which rows the data item iterates. Both are the same
// filter operation observed two different ways; a runner that filters iteration but
// leaves GetFilter() reading empty passes the iteration half and fails this one.
//
// Every scenario checks BOTH OnPreReport (fires before the data-item loop even starts)
// and OnPreDataItem (fires at the start of that item's own loop) so a fix that only
// patches one call site is caught by the other.
//
// The no-filter-applied control is the same reasoning TestReportSetTableView.al
// documents: without it, an implementation that always returns some fixed non-empty
// string (rather than the actual applied filter) would pass the positive scenarios
// by coincidence.

codeunit 60999 "RGF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Row: Record "RRE Row";
        Log: Record "RRE Log";
    begin
        Row.DeleteAll();
        Log.DeleteAll();
        Row.Init();
        Row."Entry No." := 1;
        Row.Name := 'first';
        Row.Insert();
        Row.Init();
        Row."Entry No." := 2;
        Row.Name := 'second';
        Row.Insert();
    end;

    // The suffix of the single "RRE Log" row whose Marker starts with Prefix — i.e. the
    // filter text the report's trigger actually read via GetFilter(). '<NOT-LOGGED>' means
    // the trigger never ran at all, which is itself a distinct, loud failure from "read
    // empty".
    local procedure LoggedFilterValue(Prefix: Text[50]): Text
    var
        Log: Record "RRE Log";
    begin
        Log.SetFilter(Marker, Prefix + '*');
        if Log.FindFirst() then
            exit(DelStr(Log.Marker, 1, StrLen(Prefix)));
        exit('<NOT-LOGGED>');
    end;

    [Test]
    procedure Report_InstanceSetTableView_GetFilter_ReadsAppliedFilter_InOnPreReportAndOnPreDataItem()
    var
        Row: Record "RRE Row";
        Probe: Report "RGF Filter Report";
    begin
        Initialize();
        Row.SetRange("Entry No.", 1, 2);
        Probe.SetTableView(Row);
        Probe.UseRequestPage(false);
        Probe.RunModal();

        if LoggedFilterValue('RGF-PRE-REPORT:') <> '1..2' then
            Error('instance SetTableView: OnPreReport''s GetFilter() should read "1..2", got "%1"', LoggedFilterValue('RGF-PRE-REPORT:'));
        if LoggedFilterValue('RGF-PRE-DI:') <> '1..2' then
            Error('instance SetTableView: OnPreDataItem''s GetFilter() should read "1..2", got "%1"', LoggedFilterValue('RGF-PRE-DI:'));
    end;

    [Test]
    procedure Report_StaticRunModalRecordParam_GetFilter_ReadsAppliedFilter_InOnPreReportAndOnPreDataItem()
    var
        Row: Record "RRE Row";
    begin
        Initialize();
        Row.Get(1);
        Row.SetRecFilter();
        Report.RunModal(Report::"RGF Filter Report", false, false, Row);

        if LoggedFilterValue('RGF-PRE-REPORT:') <> '1' then
            Error('static RunModal(id,...,Row): OnPreReport''s GetFilter() should read "1", got "%1"', LoggedFilterValue('RGF-PRE-REPORT:'));
        if LoggedFilterValue('RGF-PRE-DI:') <> '1' then
            Error('static RunModal(id,...,Row): OnPreDataItem''s GetFilter() should read "1", got "%1"', LoggedFilterValue('RGF-PRE-DI:'));
    end;

    [Test]
    procedure Report_NoFilterApplied_GetFilter_ReadsEmpty_InOnPreReportAndOnPreDataItem()
    var
        Probe: Report "RGF Filter Report";
    begin
        // Control: same report, no SetTableView/record-param call at all, so GetFilter()
        // must read back empty in both triggers. Proves the "1..2" / "1" results above
        // come from the applied view, not from an implementation that always answers some
        // fixed non-empty string.
        Initialize();
        Probe.UseRequestPage(false);
        Probe.RunModal();

        if LoggedFilterValue('RGF-PRE-REPORT:') <> '' then
            Error('no filter applied: OnPreReport''s GetFilter() should read empty, got "%1"', LoggedFilterValue('RGF-PRE-REPORT:'));
        if LoggedFilterValue('RGF-PRE-DI:') <> '' then
            Error('no filter applied: OnPreDataItem''s GetFilter() should read empty, got "%1"', LoggedFilterValue('RGF-PRE-DI:'));
    end;
}
