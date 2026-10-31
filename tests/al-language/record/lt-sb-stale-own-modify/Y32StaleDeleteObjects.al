// Objects of the Y32 stale own-Insert Delete tests (Y32StaleDeleteTests.al, al-runner issue 6546): a row table whose OnDelete trigger
// logs itself, a mark table the trigger and the subscribers write to (to see what a failed Delete rolls back), the log, the manual
// OnBeforeDeleteEvent / OnAfterDeleteEvent subscribers, and the codeunit that writes the row through its own record variables.

table 92330 "LT Y32 Stale Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[50]) { }
        field(3; Quantity; Decimal) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnDelete()
    var
        DeleteLog: Codeunit "LT Y32 Delete Log";
    begin
        DeleteLog.Add('OnDelete;');
        DeleteLog.Mark('trigger');
    end;
}

table 92331 "LT Y32 Delete Mark"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; What; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

// Keeps the order in which the delete trigger and the delete events ran, in memory (an asserterror does not roll it back).
// Used by test codeunit 92335 only.
codeunit 92332 "LT Y32 Delete Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;

    // Writes a database row, which a failed Delete under asserterror may roll back.
    procedure Mark(What: Text[50])
    var
        DeleteMark: Record "LT Y32 Delete Mark";
    begin
        DeleteMark.Init();
        DeleteMark.What := What;
        DeleteMark.Insert();
    end;
}

codeunit 92333 "LT Y32 Delete Subscribers"
{
    EventSubscriberInstance = Manual;

    var
        DeleteLog: Codeunit "LT Y32 Delete Log";

    [EventSubscriber(ObjectType::Table, Database::"LT Y32 Stale Row", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDelete(var Rec: Record "LT Y32 Stale Row"; RunTrigger: Boolean)
    begin
        DeleteLog.Add('OnBeforeDeleteEvent(' + Format(RunTrigger) + ');');
        DeleteLog.Mark('before');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT Y32 Stale Row", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDelete(var Rec: Record "LT Y32 Stale Row"; RunTrigger: Boolean)
    begin
        DeleteLog.Add('OnAfterDeleteEvent(' + Format(RunTrigger) + ');');
        DeleteLog.Mark('after');
    end;
}

// Writes row "No." through a record variable of its own.
codeunit 92334 "LT Y32 Stale Row Poster"
{
    procedure PostAndCommit(No: Code[20]; Amount: Decimal)
    begin
        Post(No, Amount);
        Commit();
    end;

    procedure Post(No: Code[20]; Amount: Decimal)
    var
        StaleRow: Record "LT Y32 Stale Row";
    begin
        StaleRow.Get(No);
        StaleRow.Quantity -= Amount;
        StaleRow.Modify();
    end;
}
