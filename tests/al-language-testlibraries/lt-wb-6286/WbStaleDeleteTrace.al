// What ran during a Delete, kept in memory: a write into a table here would change the transaction under test
codeunit 81593 "LT WB P5 Trace"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(What: Text; No: Code[20]; Note: Text)
    begin
        Lines += StrSubstNo('%1(%2:%3) ', What, No, Note);
    end;

    procedure Reset()
    begin
        Lines := '';
    end;

    procedure Get(): Text
    begin
        exit(Lines.TrimEnd());
    end;
}

// Database trigger OnDatabaseDelete: Tests-TestLibraries (codeunit 130011 "Backup Management") switches it on for every table
// with an id in 1..99999, through GlobalTriggerManagement.OnAfterGetDatabaseTableTriggerSetup
codeunit 81594 "LT WB P5 Database Delete"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseDelete', '', false, false)]
    local procedure OnDatabaseDelete(RecRef: RecordRef)
    var
        Row: Record "LT WB P5 Row";
        Trace: Codeunit "LT WB P5 Trace";
    begin
        if RecRef.Number <> Database::"LT WB P5 Row" then
            exit;
        RecRef.SetTable(Row);
        Trace.Add('OnDatabaseDelete', Row."No.", Row.Note);
    end;
}

// Table events of Repro P5 Row, bound only in the tests that ask for them
codeunit 81595 "LT WB P5 Delete Events"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"LT WB P5 Row", OnBeforeDeleteEvent, '', false, false)]
    local procedure OnBeforeDelete(var Rec: Record "LT WB P5 Row"; RunTrigger: Boolean)
    var
        Trace: Codeunit "LT WB P5 Trace";
    begin
        Trace.Add('OnBeforeDeleteEvent', Rec."No.", Rec.Note);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT WB P5 Row", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDelete(var Rec: Record "LT WB P5 Row"; RunTrigger: Boolean)
    var
        Trace: Codeunit "LT WB P5 Trace";
    begin
        Trace.Add('OnAfterDeleteEvent', Rec."No.", Rec.Note);
    end;
}
