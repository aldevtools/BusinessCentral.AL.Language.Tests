// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-getfilter-method
// Scope: in-scope
// Fixtures used: RRE Row (60866), RRE Log (60867)
//
// A ProcessingOnly report over the shared "RRE Row" table, dedicated to proving that
// Record.GetFilter() reads the ACTUAL filter a caller applied — via the instance
// Report.SetTableView(Rec) form or the record-parameter static Report.Run/RunModal
// overload — from INSIDE the report's own triggers, both OnPreReport (report-level,
// before any data item has started iterating) and OnPreDataItem (data-item-level,
// right before the loop for that item begins).
//
// Reported as AL Runner #1895: the filter demonstrably constrains which rows the data
// item visits, but GetFilter() read back empty from OnPreReport/OnPreDataItem on the
// runner — a report that guards on its own filters ("if GetFilter=''  then Error(...)",
// the same pattern Base App batch reports use) errored out despite the caller having
// set them.
//
// Logged to "RRE Log" rather than a report global for the same reason
// RreProcessingOnlyReport / RreSetTableViewReport do: Report.Run's own documentation
// says the report variable is cleared once Run returns, so a global read afterwards
// would say nothing about what the triggers actually saw while they ran.

report 60998 "RGF Filter Report"
{
    Caption = 'RGF Filter Report';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Rows; "RRE Row")
        {
            trigger OnPreDataItem()
            var
                LogRec: Record "RRE Log";
            begin
                LogRec.Log(CopyStr('RGF-PRE-DI:' + Rows.GetFilter("Entry No."), 1, 50));
            end;
        }
    }

    trigger OnPreReport()
    var
        LogRec: Record "RRE Log";
    begin
        // "Rows" is the dataset's data-item record variable — a report-level global, so
        // it is reachable here even though OnPreReport runs before the data-item loop
        // starts (TestReportSaveAsRecordRefFilterReport.al's OnPreReport guard reads the
        // same variable the same way).
        LogRec.Log(CopyStr('RGF-PRE-REPORT:' + Rows.GetFilter("Entry No."), 1, 50));
    end;
}
