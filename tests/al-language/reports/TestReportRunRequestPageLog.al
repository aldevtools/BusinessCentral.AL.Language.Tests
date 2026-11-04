// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-runrequestpage-method
// Scope: in-scope
// Fixtures used: none
//
// Execution log — a table write proves the handler body ran regardless of which
// report instance the request page was attached to.

table 60542 "Test Rpt RunReqPage Log"
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
        LogRec: Record "Test Rpt RunReqPage Log";
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
        LogRec: Record "Test Rpt RunReqPage Log";
    begin
        LogRec.SetRange(Marker, WantedMarker);
        exit(LogRec.Count());
    end;
}
