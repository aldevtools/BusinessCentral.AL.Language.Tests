// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-settableview-method
// Scope: in-scope
// Fixtures used: RRE Row (60866), RRE Log (60867), STV Counting Report (60913)
//
// Report.SetTableView(Record) must constrain the report's matching data item to the
// filtered view before Run() executes it — not run every row in the table, and not
// silently skip execution either.
//
// Both directions, over the SAME report and SAME seeded rows, so the ONLY variable
// between the two outcomes is whether SetTableView was called:
//   * with a filtered Record  -> the data item iterates ONLY the rows within that view;
//   * with no filter at all   -> the data item iterates every row in the table.
// Without the negative case, a runner that filtered NOTHING and a runner that filtered
// correctly-but-happened-to-match-2 would be indistinguishable.
//
// How the outcome is observed: through the "RRE Log" table, not through a report
// global. The instance Run method
// (https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/reportinstance-run-method)
// documents that "With the Run method, the variable is automatically cleared after
// the method is run" — so a global row counter always reads 0 afterwards no matter
// how many rows the data item visited, and asserting on it would say nothing about
// SetTableView. The log rows survive that clear.
//
// The assertions compare the exact ordered list of visited row names rather than a
// count, so they pin WHICH rows the view admitted. An implementation that returns
// nothing, everything, or the right number of the wrong rows all fail distinctly.

codeunit 60914 "STV Tests"
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
        Row.Init();
        Row."Entry No." := 3;
        Row.Name := 'third';
        Row.Insert();
    end;

    // The ordered, comma-separated names of the rows the data item actually visited.
    local procedure VisitedRows(): Text
    var
        Log: Record "RRE Log";
        Visited: Text;
    begin
        Log.SetCurrentKey("Entry No.");
        Log.SetFilter(Marker, 'STV-*');
        if Log.FindSet() then
            repeat
                if Visited <> '' then
                    Visited += ',';
                Visited += Log.Marker;
            until Log.Next() = 0;
        exit(Visited);
    end;

    [Test]
    procedure Report_SetTableView_FiltersDataItemToTheAppliedView()
    var
        Row: Record "RRE Row";
        CountingReport: Report "STV Counting Report";
    begin
        Initialize();

        Row.SetRange("Entry No.", 1, 2);
        CountingReport.SetTableView(Row);
        CountingReport.UseRequestPage(false);
        CountingReport.Run();

        if VisitedRows() <> 'STV-first,STV-second' then
            Error('SetTableView(1..2): expected the data item to iterate exactly the two rows within the view (STV-first,STV-second), got "%1"', VisitedRows());
    end;

    [Test]
    procedure Report_Run_WithoutSetTableView_IteratesEveryRowInTheTable()
    var
        CountingReport: Report "STV Counting Report";
    begin
        // The control: same report, same 3 seeded rows, no SetTableView call at all —
        // so the data item must iterate all 3, proving the 2-row result above came
        // from the applied view rather than an implementation that always returns 2
        // (or that never applies any view and coincidentally matched).
        Initialize();

        CountingReport.UseRequestPage(false);
        CountingReport.Run();

        if VisitedRows() <> 'STV-first,STV-second,STV-third' then
            Error('No SetTableView call: expected the data item to iterate all 3 seeded rows (STV-first,STV-second,STV-third), got "%1"', VisitedRows());
    end;
}
