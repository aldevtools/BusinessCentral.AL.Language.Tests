// Migrated from AL Runner tests/runner-extras/report-run-execution (RreSrc.al).
// Shape B — a normal (non-ProcessingOnly) report WITH a rendering layout, so the
// difference between "needs a layout" and "never executes" is separable from shape A.
report 60869 "RRE Layout Report"
{
    Caption = 'RRE Layout Report';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = RreWordish;

    dataset
    {
        dataitem(Rows; "RRE Row")
        {
            column(EntryNo; "Entry No.") { }
            column(RowName; Name) { }

            trigger OnAfterGetRecord()
            begin
                RowCount += 1;
            end;
        }
    }

    rendering
    {
        layout(RreWordish)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/RreLayout.rdl';
            Caption = 'RRE layout';
        }
    }

    var
        RowCount: Integer;
        PreReportRan: Boolean;

    trigger OnPreReport()
    begin
        PreReportRan := true;
    end;

    procedure RowsProcessed(): Integer
    begin
        exit(RowCount);
    end;

    procedure DidPreReportRun(): Boolean
    begin
        exit(PreReportRan);
    end;
}
