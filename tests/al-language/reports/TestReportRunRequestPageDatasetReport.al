// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-runrequestpage-method
// Scope: in-scope
// Fixtures used: Test Rpt RunReqPage Row (60541)
//
// Same request page, but a report that produces a DATASET — so the parameters a handler
// produced can be replayed through Report.SaveAs(id, paramsXml, Xml, stream) and the
// filter's effect observed in the output. That replay is the documented way to run a
// report headlessly with filters a user chose earlier, and it is what a caller does with
// what RunRequestPage handed back.

report 60544 "Test Rpt RunReqPage Dataset"
{
    Caption = 'Test Rpt RunReqPage Dataset';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = RunReqPageDatasetLayout;

    dataset
    {
        dataitem(Rows; "Test Rpt RunReqPage Row")
        {
            column(EntryNo; "Entry No.") { }
            column(RowName; Name) { }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(EchoText; EchoText)
                    {
                        ApplicationArea = All;
                        Caption = 'Echo Text';
                        ToolTip = 'Unused; present so the request page has a control.';
                    }
                }
            }
        }
    }

    rendering
    {
        layout(RunReqPageDatasetLayout)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/TestReportRunRequestPageDatasetReport.rdl';
            Caption = 'Test Rpt RunReqPage Dataset layout';
        }
    }

    var
        EchoText: Text[50];
}
