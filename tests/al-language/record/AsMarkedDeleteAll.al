// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-markedonly-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), AsFixtures.al (tables 79902, 79903, helper 79913)
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced (corpus issue 644, item 5).
// Facts: two of three rows marked, MarkedOnly(true), DeleteAll: which rows remain; the same with a filter that excludes a marked row;
//   DeleteAll(true) with an OnDelete trigger (the trigger log).
// BC versions: 27-29

codeunit 79923 "LT AS Marked DeleteAll"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT AS Helper";

    local procedure MarkAC(var Row: Record "LT AS Row")
    begin
        Row.Get('A');
        Row.Mark(true);
        Row.Get('C');
        Row.Mark(true);
        Row.MarkedOnly(true);
    end;

    [Test]
    procedure MarkedOnly_DeleteAll()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS Row";
        Log: Record "LT AS Log";
    begin
        Helper.SeedRows();
        MarkAC(Row);
        Row.DeleteAll();
        Observer.Observe('remain', Helper.Rows());
        Observer.Observe('log', Log.Dump());
        Observer.Expect('remain', 'B');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure MarkedOnly_FilterExcludesMarked_DeleteAll()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS Row";
    begin
        Helper.SeedRows();
        MarkAC(Row);
        Row.SetFilter("No.", '<>C');
        Observer.Observe('count', Format(Row.Count()));
        Row.DeleteAll();
        Observer.Observe('remain', Helper.Rows());
        Observer.Expect('count', '1');
        Observer.Expect('remain', 'BC');
        Observer.Verify();
    end;

    [Test]
    procedure MarkedOnly_DeleteAllTrue_Trigger()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS Row";
        Log: Record "LT AS Log";
    begin
        Helper.SeedRows();
        MarkAC(Row);
        Row.DeleteAll(true);
        Observer.Observe('remain', Helper.Rows());
        Observer.Observe('log', Log.Dump());
        Observer.Expect('remain', 'B');
        Observer.Expect('log', 'OnDelete A,OnDelete C');
        Observer.Verify();
    end;

    [Test]
    procedure MarkedOnly_Filter_DeleteAllTrue_Trigger()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS Row";
        Log: Record "LT AS Log";
    begin
        Helper.SeedRows();
        MarkAC(Row);
        Row.SetFilter("No.", '<>A');
        Row.DeleteAll(true);
        Observer.Observe('remain', Helper.Rows());
        Observer.Observe('log', Log.Dump());
        Observer.Observe('marks_left', Format(Row.Count()));
        Observer.Expect('remain', 'AB');
        Observer.Expect('log', 'OnDelete C');
        Observer.Expect('marks_left', '0');
        Observer.Verify();
    end;
}
