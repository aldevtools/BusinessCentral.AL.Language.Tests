// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonvalue/jsonvalue-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own fixtures declared in this file (LT RW)
// Probe (al-runner issue 5794): the JSON text of a Time whose milliseconds end in zero (10, 100, 120, 500, 990) and of other milliseconds
// (1, 5, 12, 123), written through JsonValue.SetValue + WriteTo, JsonObject.Add + Format, JsonArray.Add + Format and WriteTo; the reporter's
// stored Time field written into a JsonObject in a JsonArray; and whether the written text reads back as the same Time. Object ids 88781, 88791-88792.
// BC versions: 27, 28, 29 (CI matrix)

table 88781 "LT RW Time Entry"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Starting Time"; Time) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

// The reporter's payload builder: every row as a JsonObject in a JsonArray, formatted as text.
codeunit 88791 "LT RW Time Payload"
{
    procedure EntriesJson(): Text
    var
        TimeEntry: Record "LT RW Time Entry";
        Entries: JsonArray;
        Entry: JsonObject;
    begin
        if TimeEntry.FindSet() then
            repeat
                Clear(Entry);
                Entry.Add('Entry No', TimeEntry."Entry No.");
                Entry.Add('Starting Time', TimeEntry."Starting Time");
                Entries.Add(Entry);
            until TimeEntry.Next() = 0;
        exit(Format(Entries));
    end;
}

codeunit 88792 "LT RW Json Time Ms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure InsertEntry(StartingTime: Time)
    var
        TimeEntry: Record "LT RW Time Entry";
    begin
        TimeEntry.DeleteAll();
        TimeEntry."Entry No." := 1;
        TimeEntry."Starting Time" := StartingTime;
        TimeEntry.Insert();
    end;

    // The reporter's two tests: a stored Time field of 10:00:00.123 and 10:00:00.120, and the same for 10:00:00.100 and 10:00:00.500.
    [Test]
    procedure RW_JsonTime_StoredField_Reporter()
    var
        Observer: Codeunit "Probe Observer";
        Payload: Codeunit "LT RW Time Payload";
    begin
        InsertEntry(100000.123T);
        Observer.Observe('stored-123', Payload.EntriesJson());
        InsertEntry(100000.120T);
        Observer.Observe('stored-120', Payload.EntriesJson());
        InsertEntry(100000.100T);
        Observer.Observe('stored-100', Payload.EntriesJson());
        InsertEntry(100000.500T);
        Observer.Observe('stored-500', Payload.EntriesJson());
        InsertEntry(100000.010T);
        Observer.Observe('stored-010', Payload.EntriesJson());
        Observer.Finish();
    end;

    local procedure ObserveMs(var Observer: Codeunit "Probe Observer"; Ms: Integer)
    var
        T: Time;
        V: JsonValue;
        O: JsonObject;
        A: JsonArray;
        Tok: JsonToken;
        Txt: Text;
        Tag: Text;
    begin
        T := 100000T + Ms;
        Tag := Format(Ms);
        Observer.Observe(Tag + '-format9', Format(T, 0, 9));
        V.SetValue(T);
        V.WriteTo(Txt);
        Observer.Observe(Tag + '-value', Txt);
        O.Add('t', T);
        Observer.Observe(Tag + '-object', Format(O));
        A.Add(T);
        A.WriteTo(Txt);
        Observer.Observe(Tag + '-array', Txt);
        Observer.Observe(Tag + '-array-format', Format(A));
        O.Get('t', Tok);
        Observer.Observe(Tag + '-astime-same', Format(Tok.AsValue().AsTime() = T));
        O.ReadFrom(Format(O));
        O.Get('t', Tok);
        Observer.Observe(Tag + '-reread-astime-same', Format(Tok.AsValue().AsTime() = T));
    end;

    // In-memory Times: 10:00:00 plus the given milliseconds, written four ways.
    [Test]
    procedure RW_JsonTime_InMemory_Milliseconds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveMs(Observer, 1);
        ObserveMs(Observer, 5);
        ObserveMs(Observer, 10);
        ObserveMs(Observer, 12);
        ObserveMs(Observer, 100);
        ObserveMs(Observer, 120);
        ObserveMs(Observer, 123);
        ObserveMs(Observer, 500);
        ObserveMs(Observer, 990);
        Observer.Finish();
    end;

    [Test]
    procedure RW_JsonTime_InMemory_Milliseconds_More1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure RW_JsonTime_InMemory_Milliseconds_More2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;
}
