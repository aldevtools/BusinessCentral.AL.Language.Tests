// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 74766 (with OnInsert) and 74767 (without), codeunits 74797 (log) and 74796 (tests)
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: Insert of a record whose primary key already exists, in a table with an OnInsert trigger and in a table without one: Insert(true) with the result left unused,
//   Insert(true) with the result used, Insert(), Insert(false) unused and used. Whether it raised (the first measurement showed that a duplicate key error inside Codeunit.Run ends the whole test with
//   'An error occurred and the transaction is stopped', so the cases run plain; the second measurement showed that with the result unused the statement raises nothing at once, so a read of the table follows it inside a TryFunction to see where the error surfaces),
//   the error text and code, whether OnInsert ran (log) and in which order relative to the error, the returned value, and the row count afterwards.
//   The own-table version of the Vendor and Item Journal Line cases of the Microsoft tests.
// BC versions: all (CI)

table 74766 "LT DIO With Trigger"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    var
        Log: Codeunit "LT DIO Log";
    begin
        Log.Add('OnInsert ' + Format(Id) + '/' + Name);
    end;
}

table 74767 "LT DIO Without Trigger"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 74797 "LT DIO Log"
{
    SingleInstance = true;

    var
        Buffer: Text;

    procedure Add(Entry: Text)
    begin
        Buffer += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Buffer;
        Buffer := '';
        exit(Result);
    end;
}

codeunit 74796 "LT DIO Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        W: Record "LT DIO With Trigger";
        N: Record "LT DIO Without Trigger";
        Log: Codeunit "LT DIO Log";
    begin
        W.DeleteAll();
        N.DeleteAll();
        W.Id := 1;
        W.Name := 'original';
        W.Insert();
        N.Id := 1;
        N.Name := 'original';
        N.Insert();
        Log.Take();
    end;

    local procedure After(var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT DIO Log";
        W: Record "LT DIO With Trigger";
        N: Record "LT DIO Without Trigger";
    begin
        Observer.Observe('log', Log.Take());
        Observer.Observe('countWith', Format(W.Count()));
        Observer.Observe('countWithout', Format(N.Count()));
        if W.Get(1) then
            Observer.Observe('nameWith', W.Name);
        if N.Get(1) then
            Observer.Observe('nameWithout', N.Name);
    end;

    [TryFunction]
    local procedure TryFlushW()
    var
        W: Record "LT DIO With Trigger";
    begin
        if W.Count() < 0 then
            exit;
    end;

    [TryFunction]
    local procedure TryFlushN()
    var
        N: Record "LT DIO Without Trigger";
    begin
        if N.Count() < 0 then
            exit;
    end;

    local procedure Dup(var W: Record "LT DIO With Trigger")
    begin
        W.Id := 1;
        W.Name := 'duplicate';
    end;

    local procedure DupN(var N: Record "LT DIO Without Trigger")
    begin
        N.Id := 1;
        N.Name := 'duplicate';
    end;

    [Test]
    procedure Duplicate_WithOnInsert_InsertTrue_Unused()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DIO Log";
        W: Record "LT DIO With Trigger";
        Flushed: Boolean;
    begin
        Seed();
        Dup(W);
        W.Insert(true);
        Observer.Observe('logAfterInsert', Log.Take());
        Flushed := TryFlushW();
        Observer.Observe('flushOk', Format(Flushed));
        if not Flushed then
            Observer.ObserveError('flushErr');
        After(Observer);
        Observer.Expect('logAfterInsert', 'OnInsert 1/duplicate;');
        Observer.Expect('flushOk', 'No');
        Observer.Expect('flushErr|text', 'The record in table LT DIO With Trigger already exists. Identification fields and values: Id=''1''');
        Observer.Expect('flushErr|code', 'DB:RecordExists');
        Observer.Expect('log', '');
        Observer.Expect('countWith', '1');
        Observer.Expect('countWithout', '1');
        Observer.Expect('nameWith', 'original');
        Observer.Expect('nameWithout', 'original');
        Observer.Verify();
    end;

    [Test]
    procedure Duplicate_WithOnInsert_InsertTrue_Used()
    var
        Observer: Codeunit "Probe Observer";
        W: Record "LT DIO With Trigger";
        Ok: Boolean;
    begin
        Seed();
        Dup(W);
        Ok := W.Insert(true);
        Observer.Observe('returned', Format(Ok));
        After(Observer);
        Observer.Expect('returned', 'No');
        Observer.Expect('log', 'OnInsert 1/duplicate;');
        Observer.Expect('countWith', '1');
        Observer.Expect('countWithout', '1');
        Observer.Expect('nameWith', 'original');
        Observer.Expect('nameWithout', 'original');
        Observer.Verify();
    end;

    [Test]
    procedure Duplicate_WithOnInsert_InsertNoArg_Unused()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DIO Log";
        W: Record "LT DIO With Trigger";
        Flushed: Boolean;
    begin
        Seed();
        Dup(W);
        W.Insert();
        Observer.Observe('logAfterInsert', Log.Take());
        Flushed := TryFlushW();
        Observer.Observe('flushOk', Format(Flushed));
        if not Flushed then
            Observer.ObserveError('flushErr');
        After(Observer);
        Observer.Expect('logAfterInsert', '');
        Observer.Expect('flushOk', 'No');
        Observer.Expect('flushErr|text', 'The record in table LT DIO With Trigger already exists. Identification fields and values: Id=''1''');
        Observer.Expect('flushErr|code', 'DB:RecordExists');
        Observer.Expect('log', '');
        Observer.Expect('countWith', '1');
        Observer.Expect('countWithout', '1');
        Observer.Expect('nameWith', 'original');
        Observer.Expect('nameWithout', 'original');
        Observer.Verify();
    end;

    [Test]
    procedure Duplicate_WithOnInsert_InsertNoArg_Used()
    var
        Observer: Codeunit "Probe Observer";
        W: Record "LT DIO With Trigger";
        Ok: Boolean;
    begin
        Seed();
        Dup(W);
        Ok := W.Insert();
        Observer.Observe('returned', Format(Ok));
        After(Observer);
        Observer.Expect('returned', 'No');
        Observer.Expect('log', '');
        Observer.Expect('countWith', '1');
        Observer.Expect('countWithout', '1');
        Observer.Expect('nameWith', 'original');
        Observer.Expect('nameWithout', 'original');
        Observer.Verify();
    end;

    [Test]
    procedure Duplicate_WithOnInsert_InsertFalse_Unused()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DIO Log";
        W: Record "LT DIO With Trigger";
        Flushed: Boolean;
    begin
        Seed();
        Dup(W);
        W.Insert(false);
        Observer.Observe('logAfterInsert', Log.Take());
        Flushed := TryFlushW();
        Observer.Observe('flushOk', Format(Flushed));
        if not Flushed then
            Observer.ObserveError('flushErr');
        After(Observer);
        Observer.Expect('logAfterInsert', '');
        Observer.Expect('flushOk', 'No');
        Observer.Expect('flushErr|text', 'The record in table LT DIO With Trigger already exists. Identification fields and values: Id=''1''');
        Observer.Expect('flushErr|code', 'DB:RecordExists');
        Observer.Expect('log', '');
        Observer.Expect('countWith', '1');
        Observer.Expect('countWithout', '1');
        Observer.Expect('nameWith', 'original');
        Observer.Expect('nameWithout', 'original');
        Observer.Verify();
    end;

    [Test]
    procedure Duplicate_WithOnInsert_InsertFalse_Used()
    var
        Observer: Codeunit "Probe Observer";
        W: Record "LT DIO With Trigger";
        Ok: Boolean;
    begin
        Seed();
        Dup(W);
        Ok := W.Insert(false);
        Observer.Observe('returned', Format(Ok));
        After(Observer);
        Observer.Expect('returned', 'No');
        Observer.Expect('log', '');
        Observer.Expect('countWith', '1');
        Observer.Expect('countWithout', '1');
        Observer.Expect('nameWith', 'original');
        Observer.Expect('nameWithout', 'original');
        Observer.Verify();
    end;

    [Test]
    procedure Duplicate_WithoutOnInsert_InsertTrue_Unused()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DIO Log";
        N: Record "LT DIO Without Trigger";
        Flushed: Boolean;
    begin
        Seed();
        DupN(N);
        N.Insert(true);
        Observer.Observe('logAfterInsert', Log.Take());
        Flushed := TryFlushN();
        Observer.Observe('flushOk', Format(Flushed));
        if not Flushed then
            Observer.ObserveError('flushErr');
        After(Observer);
        Observer.Expect('logAfterInsert', '');
        Observer.Expect('flushOk', 'No');
        Observer.Expect('flushErr|text', 'The record in table LT DIO Without Trigger already exists. Identification fields and values: Id=''1''');
        Observer.Expect('flushErr|code', 'DB:RecordExists');
        Observer.Expect('log', '');
        Observer.Expect('countWith', '1');
        Observer.Expect('countWithout', '1');
        Observer.Expect('nameWith', 'original');
        Observer.Expect('nameWithout', 'original');
        Observer.Verify();
    end;

    [Test]
    procedure Duplicate_WithoutOnInsert_InsertTrue_Used()
    var
        Observer: Codeunit "Probe Observer";
        N: Record "LT DIO Without Trigger";
        Ok: Boolean;
    begin
        Seed();
        DupN(N);
        Ok := N.Insert(true);
        Observer.Observe('returned', Format(Ok));
        After(Observer);
        Observer.Expect('returned', 'No');
        Observer.Expect('log', '');
        Observer.Expect('countWith', '1');
        Observer.Expect('countWithout', '1');
        Observer.Expect('nameWith', 'original');
        Observer.Expect('nameWithout', 'original');
        Observer.Verify();
    end;

    [Test]
    procedure Duplicate_WithoutOnInsert_InsertNoArg_Unused()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DIO Log";
        N: Record "LT DIO Without Trigger";
        Flushed: Boolean;
    begin
        Seed();
        DupN(N);
        N.Insert();
        Observer.Observe('logAfterInsert', Log.Take());
        Flushed := TryFlushN();
        Observer.Observe('flushOk', Format(Flushed));
        if not Flushed then
            Observer.ObserveError('flushErr');
        After(Observer);
        Observer.Expect('logAfterInsert', '');
        Observer.Expect('flushOk', 'No');
        Observer.Expect('flushErr|text', 'The record in table LT DIO Without Trigger already exists. Identification fields and values: Id=''1''');
        Observer.Expect('flushErr|code', 'DB:RecordExists');
        Observer.Expect('log', '');
        Observer.Expect('countWith', '1');
        Observer.Expect('countWithout', '1');
        Observer.Expect('nameWith', 'original');
        Observer.Expect('nameWithout', 'original');
        Observer.Verify();
    end;

    [Test]
    procedure Duplicate_WithoutOnInsert_InsertNoArg_Used()
    var
        Observer: Codeunit "Probe Observer";
        N: Record "LT DIO Without Trigger";
        Ok: Boolean;
    begin
        Seed();
        DupN(N);
        Ok := N.Insert();
        Observer.Observe('returned', Format(Ok));
        After(Observer);
        Observer.Expect('returned', 'No');
        Observer.Expect('log', '');
        Observer.Expect('countWith', '1');
        Observer.Expect('countWithout', '1');
        Observer.Expect('nameWith', 'original');
        Observer.Expect('nameWithout', 'original');
        Observer.Verify();
    end;

    [Test]
    procedure Duplicate_WithoutOnInsert_InsertFalse_Unused()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DIO Log";
        N: Record "LT DIO Without Trigger";
        Flushed: Boolean;
    begin
        Seed();
        DupN(N);
        N.Insert(false);
        Observer.Observe('logAfterInsert', Log.Take());
        Flushed := TryFlushN();
        Observer.Observe('flushOk', Format(Flushed));
        if not Flushed then
            Observer.ObserveError('flushErr');
        After(Observer);
        Observer.Expect('logAfterInsert', '');
        Observer.Expect('flushOk', 'No');
        Observer.Expect('flushErr|text', 'The record in table LT DIO Without Trigger already exists. Identification fields and values: Id=''1''');
        Observer.Expect('flushErr|code', 'DB:RecordExists');
        Observer.Expect('log', '');
        Observer.Expect('countWith', '1');
        Observer.Expect('countWithout', '1');
        Observer.Expect('nameWith', 'original');
        Observer.Expect('nameWithout', 'original');
        Observer.Verify();
    end;

    [Test]
    procedure Duplicate_WithoutOnInsert_InsertFalse_Used()
    var
        Observer: Codeunit "Probe Observer";
        N: Record "LT DIO Without Trigger";
        Ok: Boolean;
    begin
        Seed();
        DupN(N);
        Ok := N.Insert(false);
        Observer.Observe('returned', Format(Ok));
        After(Observer);
        Observer.Expect('returned', 'No');
        Observer.Expect('log', '');
        Observer.Expect('countWith', '1');
        Observer.Expect('countWithout', '1');
        Observer.Expect('nameWith', 'original');
        Observer.Expect('nameWithout', 'original');
        Observer.Verify();
    end;
}
