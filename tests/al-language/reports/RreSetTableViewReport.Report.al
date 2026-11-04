// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-settableview-method
// Scope: in-scope
// Fixtures used: RRE Row (60866), RRE Log (60867)
//
// A ProcessingOnly report over the shared "RRE Row" table, dedicated to proving
// Report.SetTableView(Record) actually constrains the data item to the view that
// was set — as opposed to running unfiltered, or not running at all.
//
// The data item reports what it iterated through the "RRE Log" TABLE rather than
// through a report global. That is deliberate: the instance Run method
// (https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/reportinstance-run-method)
// documents that "With the Run method, the variable is automatically cleared after
// the method is run", so any global counter is back to 0 by the time the caller can
// read it. A table write survives that clear, which is the same reasoning "RRE Log"
// was introduced for.
//
// Each row logs its own Name, so the assertions can name WHICH rows the data item
// visited, not merely how many.

report 60913 "STV Counting Report"
{
    Caption = 'STV Counting Report';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Rows; "RRE Row")
        {
            trigger OnAfterGetRecord()
            var
                LogRec: Record "RRE Log";
            begin
                LogRec.Log(CopyStr('STV-' + Rows.Name, 1, 50));
            end;
        }
    }
}
