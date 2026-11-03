// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-request-page
// Scope: in-scope
// Fixtures used: (none)
//
// Execution log — a table write proves a handler body ran regardless of which
// report instance the request page was attached to.

table 60568 "RRP Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Marker; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }

    procedure Log(NewMarker: Text[50])
    var
        LogRec: Record "RRP Log";
        NextNo: Integer;
    begin
        if LogRec.FindLast() then
            NextNo := LogRec."Entry No.";
        LogRec.Init();
        LogRec."Entry No." := NextNo + 1;
        LogRec.Marker := NewMarker;
        LogRec.Insert();
    end;

    procedure MarkerCount(WantedMarker: Text[50]): Integer
    var
        LogRec: Record "RRP Log";
    begin
        LogRec.SetRange(Marker, WantedMarker);
        exit(LogRec.Count());
    end;
}
