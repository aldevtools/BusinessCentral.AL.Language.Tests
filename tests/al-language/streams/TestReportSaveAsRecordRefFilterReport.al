// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: SaveAs RecordRef Row (60577)
//
// A report shaped like a document report: it refuses to run unless its data item carries a
// filter, the same guard Standard Sales - Invoice uses ("You must specify one or more
// filters to avoid accidentally printing all documents"). That guard is what turns a
// dropped record filter from a silently-too-wide dataset into an outright refusal.

report 60578 "SaveAs RecordRef Document"
{
    Caption = 'SaveAs RecordRef Document';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = SaveAsRecordRefLayout;

    dataset
    {
        dataitem(Rows; "SaveAs RecordRef Row")
        {
            column(RowNo; "No.") { }
            column(RowName; Name) { }

            trigger OnAfterGetRecord()
            begin
                RowsSeen += 1;
            end;
        }
    }

    rendering
    {
        layout(SaveAsRecordRefLayout)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/TestReportSaveAsRecordRefFilterReport.rdl';
            Caption = 'SaveAs RecordRef layout';
        }
    }

    var
        RowsSeen: Integer;
        NoFilterErr: Label 'You must specify one or more filters to avoid accidentally printing all documents.';

    trigger OnPreReport()
    begin
        if Rows.GetFilters() = '' then
            Error(NoFilterErr);
    end;

    procedure RowsProcessed(): Integer
    begin
        exit(RowsSeen);
    end;
}
