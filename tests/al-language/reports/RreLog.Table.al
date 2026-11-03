// Migrated from AL Runner tests/runner-extras/report-run-execution (RreSrc.al).
// Execution log. Instance globals are only visible if the report ran on the SAME
// instance the caller holds; a table write is observable regardless of which instance
// executed, which separates "did not execute" from "executed on another instance".
table 60867 "RRE Log"
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
        Log: Record "RRE Log";
        NextNo: Integer;
    begin
        if Log.FindLast() then
            NextNo := Log."Entry No.";
        Log.Init();
        Log."Entry No." := NextNo + 1;
        Log.Marker := NewMarker;
        Log.Insert();
    end;
}
