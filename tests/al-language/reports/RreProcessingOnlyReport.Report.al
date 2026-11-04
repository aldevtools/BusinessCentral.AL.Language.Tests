// Migrated from AL Runner tests/runner-extras/report-run-execution (RreSrc.al).
// Shape A — ProcessingOnly, no rendering layout. The simplest possible report.
report 60868 "RRE ProcessingOnly Report"
{
    Caption = 'RRE ProcessingOnly Report';
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
                RowCount += 1;
                LogRec.Log('A-row');
            end;
        }
    }

    var
        RowCount: Integer;
        PreReportRan: Boolean;
        PostReportRan: Boolean;

    trigger OnPreReport()
    var
        LogRec: Record "RRE Log";
    begin
        PreReportRan := true;
        LogRec.Log('A-pre');
    end;

    trigger OnPostReport()
    begin
        PostReportRan := true;
    end;

    procedure RowsProcessed(): Integer
    begin
        exit(RowCount);
    end;

    procedure DidPreReportRun(): Boolean
    begin
        exit(PreReportRan);
    end;

    procedure DidPostReportRun(): Boolean
    begin
        exit(PostReportRan);
    end;
}
