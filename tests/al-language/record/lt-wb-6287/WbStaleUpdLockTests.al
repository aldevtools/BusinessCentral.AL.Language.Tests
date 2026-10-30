// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: none
// Facts: al-runner issue 6287 (follow-up to 6040, reporter's repro, passed on real BC): a stale buffer from the variable's own Insert, four Commits later, after a transaction that reads another table under ReadIsolation UpdLock and Modifies it (as No. Series does): the Modify through the stale buffer raises DB:RecordChanged (same as after a plain Get).

codeunit 90569 "LT WB P4 Stale Buffer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Row's buffer comes from its own Insert and its own Modify; another variable Modifies the row in the same transaction
    // (Row is now stale); four Commits follow. The new transaction never touches Repro P4 Row: it Modifies a row of another
    // table, takes a number from a series the way No. Series does (ReadIsolation UpdLock, Find, Modify) and Inserts into
    // another table. Then Modify(true) through the stale buffer. BC passes one test of the pair.
    [Test]
    procedure UpdLockReadOfAnotherTableFourCommitsLaterRecordChanged()
    var
        Row: Record "LT WB P4 Row";
    begin
        PrepareFourCommits(Row);
        WriteOtherTablesWithUpdLockRead();
        Row.Qty := 5;
        asserterror Row.Modify(true);
        VerifyRecordChanged();
    end;

    // Contrast: the same writes without the UpdLock read; al-runner raises DB:RecordChanged here
    [Test]
    procedure PlainWritesOfAnotherTableFourCommitsLaterRecordChanged()
    var
        Row: Record "LT WB P4 Row";
    begin
        PrepareFourCommits(Row);
        WriteOtherTablesWithoutLock();
        Row.Qty := 5;
        asserterror Row.Modify(true);
        VerifyRecordChanged();
    end;

    local procedure PrepareFourCommits(var Row: Record "LT WB P4 Row")
    var
        Changer: Record "LT WB P4 Row";
    begin
        ClearTables();
        Row."No." := 'P4';
        Row.Note := 'start';
        Row.Insert(true);
        Row.Qty := 1;
        Row.Modify(true);
        Changer.Get('P4');
        Changer.Note := 'other';
        Changer.Modify(false);
        Commit(); // 1
        InsertOther('MIDDLE-1');
        Commit(); // 2
        Commit(); // 3
        InsertOther('MIDDLE-2');
        Commit(); // 4
    end;

    local procedure ClearTables()
    var
        Row: Record "LT WB P4 Row";
        Other: Record "LT WB P4 Other";
        Series: Record "LT WB P4 Series";
    begin
        Row.DeleteAll();
        Other.DeleteAll();
        Series.DeleteAll();
        Other."No." := 'ITEM-1';
        Other.Insert();
        Series.Code := 'ITEM';
        Series."Last No. Used" := 'X0000';
        Series.Insert();
        Commit();
    end;

    // As the partner test: two items Modified, then a new item whose number comes from a No. Series
    local procedure WriteOtherTablesWithUpdLockRead()
    var
        Other: Record "LT WB P4 Other";
        Series: Record "LT WB P4 Series";
    begin
        Other.Get('ITEM-1');
        Other.Qty := 12;
        Other.Modify(true);
        Series.Code := 'ITEM';
        Series.ReadIsolation(IsolationLevel::UpdLock);
        Series.Find();
        Series."Last No. Used" := IncStr(Series."Last No. Used");
        Series.Modify();
        InsertOther(Series."Last No. Used");
    end;

    local procedure WriteOtherTablesWithoutLock()
    var
        Other: Record "LT WB P4 Other";
        Series: Record "LT WB P4 Series";
    begin
        Other.Get('ITEM-1');
        Other.Qty := 12;
        Other.Modify(true);
        Series.Get('ITEM');
        Series."Last No. Used" := IncStr(Series."Last No. Used");
        Series.Modify();
        InsertOther(Series."Last No. Used");
    end;

    local procedure InsertOther(No: Code[20])
    var
        Other: Record "LT WB P4 Other";
    begin
        Other."No." := No;
        Other.Insert(true);
    end;

    local procedure VerifyStored(ExpectedNote: Text; ExpectedQty: Integer)
    var
        Stored: Record "LT WB P4 Row";
    begin
        Stored.Get('P4');
        if (Stored.Note <> ExpectedNote) or (Stored.Qty <> ExpectedQty) then
            Error('Stored row is %1|%2, expected %3|%4', Stored.Note, Stored.Qty, ExpectedNote, ExpectedQty);
    end;

    local procedure VerifyRecordChanged()
    begin
        if GetLastErrorCode() <> 'DB:RecordChanged' then
            Error('Expected DB:RecordChanged, got %1: %2', GetLastErrorCode(), GetLastErrorText());
    end;
}
