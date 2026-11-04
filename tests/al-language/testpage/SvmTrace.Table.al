// Scope: in-scope
// Fixtures used: (none)
//
// Out-of-row tally for the SVM suite. OnModify on "SVM Row" bumps this; keeping the count
// off the row under test means a same-value write to that row leaves every one of its own
// field values genuinely unchanged, which is exactly the condition being measured.

table 60409 "SVM Trace"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Modify Count"; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }

    procedure Reset()
    var
        Trace: Record "SVM Trace";
    begin
        Trace.DeleteAll();
        Trace.Init();
        Trace."Entry No." := 1;
        Trace."Modify Count" := 0;
        Trace.Insert();
    end;

    procedure Bump()
    var
        Trace: Record "SVM Trace";
    begin
        if not Trace.Get(1) then begin
            Trace.Init();
            Trace."Entry No." := 1;
            Trace."Modify Count" := 0;
            Trace.Insert();
        end;
        Trace."Modify Count" += 1;
        Trace.Modify();
    end;

    procedure Count(): Integer
    var
        Trace: Record "SVM Trace";
    begin
        if not Trace.Get(1) then
            exit(0);
        exit(Trace."Modify Count");
    end;
}
