codeunit 81596 "LT WB P5 Stale Delete"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Each test: Row's buffer comes from its own Insert, another variable Modifies the row in the same transaction (Row is now
    // stale), seven Commits follow (one transaction among them locks the table, reads it and Modifies another row), and the new
    // transaction deletes another row with Delete(false) before the Delete through the stale buffer. That is #6040's shape 3
    // (BC deletes the row); here the table also has database triggers on (Tests-TestLibraries), and per test an OnDelete
    // trigger run by Delete(true) or OnBeforeDeleteEvent / OnAfterDeleteEvent subscribers.
    // Each shape is a pair: ...Deleted and ...RecordChanged; BC passes one of them.

    // The partner test's shape: Delete(false), only OnDatabaseDelete
    [Test]
    procedure DatabaseTriggerDeleteFalseDeleted()
    var
        Row: Record "LT WB P5 Row";
    begin
        PrepareSevenCommits(Row);
        DeleteAnotherRow();
        Row.Delete(false);
        VerifyDeleted();
        VerifyTrace('OnDatabaseDelete(P5-OTHER:) OnDatabaseDelete(P5:start)');
    end;

    // Delete(true): the table's OnDelete trigger runs
    [Test]
    procedure OnDeleteTriggerDeleteTrueDeleted()
    var
        Row: Record "LT WB P5 Row";
    begin
        PrepareSevenCommits(Row);
        DeleteAnotherRow();
        Row.Delete(true);
        VerifyDeleted();
        VerifyTrace('OnDatabaseDelete(P5-OTHER:) OnDelete(P5:start) OnDatabaseDelete(P5:start)');
    end;

    // Delete(false) with OnBeforeDeleteEvent and OnAfterDeleteEvent subscribers bound
    [Test]
    procedure DeleteEventsDeleteFalseDeleted()
    var
        Row: Record "LT WB P5 Row";
        DeleteEvents: Codeunit "LT WB P5 Delete Events";
    begin
        PrepareSevenCommits(Row);
        BindSubscription(DeleteEvents);
        DeleteAnotherRow();
        Row.Delete(false);
        UnbindSubscription(DeleteEvents);
        VerifyDeleted();
        VerifyTrace('OnBeforeDeleteEvent(P5-OTHER:) OnDatabaseDelete(P5-OTHER:) OnAfterDeleteEvent(P5-OTHER:) ' +
            'OnBeforeDeleteEvent(P5:start) OnDatabaseDelete(P5:start) OnAfterDeleteEvent(P5:start)');
    end;

    local procedure ClearTables()
    var
        Row: Record "LT WB P5 Row";
        Log: Record "LT WB P5 Log";
    begin
        Row.DeleteAll();
        Log.DeleteAll();
        Commit();
    end;

    local procedure PrepareSevenCommits(var Row: Record "LT WB P5 Row")
    var
        Another: Record "LT WB P5 Row";
        Changer: Record "LT WB P5 Row";
        Log: Record "LT WB P5 Log";
        Trace: Codeunit "LT WB P5 Trace";
    begin
        ClearTables();
        Row."No." := 'P5';
        Row.Note := 'start';
        Row.Insert(true);
        Another."No." := 'P5-OTHER';
        Another.Insert(true);
        Changer.Get('P5');
        Changer.Note := 'other';
        Changer.Modify(false);
        Commit(); // 1
        Commit(); // 2
        Commit(); // 3
        LockReadAndTouchAnotherRow();
        Commit(); // 4
        Commit(); // 5
        Log.DeleteAll();
        Commit(); // 6
        Commit(); // 7
        Trace.Reset();
    end;

    local procedure LockReadAndTouchAnotherRow()
    var
        Reader: Record "LT WB P5 Row";
        Another: Record "LT WB P5 Row";
    begin
        Reader.LockTable();
        Reader.FindSet();
        Another.Get('P5-OTHER');
        Another.Qty := 3;
        Another.Modify(false);
    end;

    local procedure DeleteAnotherRow()
    var
        Another: Record "LT WB P5 Row";
    begin
        Another.Get('P5-OTHER');
        Another.Delete(false);
    end;

    local procedure VerifyDeleted()
    var
        Stored: Record "LT WB P5 Row";
    begin
        if Stored.Get('P5') then
            Error('Row P5 is still there (%1), expected it deleted', Stored.Note);
    end;

    local procedure VerifyRecordChanged()
    begin
        if GetLastErrorCode() <> 'DB:RecordChanged' then
            Error('Expected DB:RecordChanged, got %1: %2', GetLastErrorCode(), GetLastErrorText());
    end;

    // Checked after the verdict: a failure here means the verdict held and only the triggers that ran differ
    local procedure VerifyTrace(Expected: Text)
    var
        Trace: Codeunit "LT WB P5 Trace";
    begin
        if Trace.Get() <> Expected then
            Error('TRACE differs. Ran: [%1]. Expected: [%2]', Trace.Get(), Expected);
    end;
}
