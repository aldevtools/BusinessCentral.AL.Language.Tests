// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonvalue/jsonvalue-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own fixtures declared in this file (LT RW)
// Probe (al-runner issue 5794): the JSON text of a Time whose milliseconds end in zero (10, 100, 120, 500, 990) and of other milliseconds
// (1, 5, 12, 123), written through JsonValue.SetValue + WriteTo, JsonObject.Add + Format, JsonArray.Add + Format and WriteTo; the reporter's
// stored Time field written into a JsonObject in a JsonArray; and whether the written text reads back as the same Time. Object ids 88781, 88791-88792.
// BC versions: 27, 28, 29 (CI matrix; values observed on 27.5, 28.5, 29.0)

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
        Observer.Expect('stored-123', '[{"Entry No":1,"Starting Time":"10:00:00.123"}]');
        Observer.Expect('stored-120', '[{"Entry No":1,"Starting Time":"10:00:00.12"}]');
        Observer.Expect('stored-100', '[{"Entry No":1,"Starting Time":"10:00:00.1"}]');
        Observer.Expect('stored-500', '[{"Entry No":1,"Starting Time":"10:00:00.5"}]');
        Observer.Expect('stored-010', '[{"Entry No":1,"Starting Time":"10:00:00.01"}]');
        Observer.Verify();
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
        Observer.Expect('1-format9', '10:00:00.001');
        Observer.Expect('1-value', '"10:00:00.001"');
        Observer.Expect('1-object', '{"t":"10:00:00.001"}');
        Observer.Expect('1-array', '["10:00:00.001"]');
        Observer.Expect('1-array-format', '["10:00:00.001"]');
        Observer.Expect('1-astime-same', 'Yes');
        Observer.Expect('1-reread-astime-same', 'Yes');
        Observer.Expect('5-format9', '10:00:00.005');
        Observer.Expect('5-value', '"10:00:00.005"');
        Observer.Expect('5-object', '{"t":"10:00:00.005"}');
        Observer.Expect('5-array', '["10:00:00.005"]');
        Observer.Expect('5-array-format', '["10:00:00.005"]');
        Observer.Expect('5-astime-same', 'Yes');
        Observer.Expect('5-reread-astime-same', 'Yes');
        Observer.Expect('10-format9', '10:00:00.01');
        Observer.Expect('10-value', '"10:00:00.01"');
        Observer.Expect('10-object', '{"t":"10:00:00.01"}');
        Observer.Expect('10-array', '["10:00:00.01"]');
        Observer.Expect('10-array-format', '["10:00:00.01"]');
        Observer.Expect('10-astime-same', 'Yes');
        Observer.Expect('10-reread-astime-same', 'Yes');
        Observer.Expect('12-format9', '10:00:00.012');
        Observer.Expect('12-value', '"10:00:00.012"');
        Observer.Expect('12-object', '{"t":"10:00:00.012"}');
        Observer.Expect('12-array', '["10:00:00.012"]');
        Observer.Expect('12-array-format', '["10:00:00.012"]');
        Observer.Expect('12-astime-same', 'Yes');
        Observer.Expect('12-reread-astime-same', 'Yes');
        Observer.Expect('100-format9', '10:00:00.1');
        Observer.Expect('100-value', '"10:00:00.1"');
        Observer.Expect('100-object', '{"t":"10:00:00.1"}');
        Observer.Expect('100-array', '["10:00:00.1"]');
        Observer.Expect('100-array-format', '["10:00:00.1"]');
        Observer.Expect('100-astime-same', 'Yes');
        Observer.Expect('100-reread-astime-same', 'Yes');
        Observer.Expect('120-format9', '10:00:00.12');
        Observer.Expect('120-value', '"10:00:00.12"');
        Observer.Expect('120-object', '{"t":"10:00:00.12"}');
        Observer.Expect('120-array', '["10:00:00.12"]');
        Observer.Expect('120-array-format', '["10:00:00.12"]');
        Observer.Expect('120-astime-same', 'Yes');
        Observer.Expect('120-reread-astime-same', 'Yes');
        Observer.Expect('123-format9', '10:00:00.123');
        Observer.Expect('123-value', '"10:00:00.123"');
        Observer.Expect('123-object', '{"t":"10:00:00.123"}');
        Observer.Expect('123-array', '["10:00:00.123"]');
        Observer.Expect('123-array-format', '["10:00:00.123"]');
        Observer.Expect('123-astime-same', 'Yes');
        Observer.Expect('123-reread-astime-same', 'Yes');
        Observer.Expect('500-format9', '10:00:00.5');
        Observer.Expect('500-value', '"10:00:00.5"');
        Observer.Expect('500-object', '{"t":"10:00:00.5"}');
        Observer.Expect('500-array', '["10:00:00.5"]');
        Observer.Expect('500-array-format', '["10:00:00.5"]');
        Observer.Expect('500-astime-same', 'Yes');
        Observer.Expect('500-reread-astime-same', 'Yes');
        Observer.Expect('990-format9', '10:00:00.99');
        Observer.Expect('990-value', '"10:00:00.99"');
        Observer.Expect('990-object', '{"t":"10:00:00.99"}');
        Observer.Expect('990-array', '["10:00:00.99"]');
        Observer.Expect('990-array-format', '["10:00:00.99"]');
        Observer.Expect('990-astime-same', 'Yes');
        Observer.Expect('990-reread-astime-same', 'Yes');
        Observer.Verify();
    end;
}
