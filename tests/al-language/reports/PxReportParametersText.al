//sub:report
// Writer PX (al-runtime-rs probes-needed "Request page" parameters text, PR 333): a report over "W3 Row" without a DataItemTableView, so a
// view handed by SetTableView reaches the parameters text unchanged. The tests are in W3ReportParametersText.al (codeunit 67740, PX_*).
// Not a test codeunit.

report 86222 "LT PX Params Rpt"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            RequestFilterFields = Id, Flag;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(IntCtl; IntVal) { ApplicationArea = All; }
            }
        }
    }

    var
        IntVal: Integer;
}
