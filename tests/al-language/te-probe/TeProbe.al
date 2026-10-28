table 89815 "TE Universal"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Text Field"; Text[100]) { }
        field(3; "Integer Field"; Integer) { }
        field(4; "Decimal Field"; Decimal) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 89816 "TE Keyed"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Name; Text[50]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 89817 "TE Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Cleanup: Codeunit "TE Cleanup";
        StaleAfterCommitErr: Label 'The changes to the TE Universal record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.', Locked = true;
    local procedure SbInsertRow(var Row: Record "TE Universal")
    begin
        Cleanup.Initialize();
        Row.Init();
        Row."Entry No." := 6;
        Row."Text Field" := 'start';
        Row.Insert(true);
    end;
    local procedure SbInsertAndOwnModify(var Row: Record "TE Universal")
    begin
        SbInsertRow(Row);
        Row."Decimal Field" := 1;
        Row.Modify(false);
    end;
    local procedure SbOtherWrite(EntryNo: Integer; NewText: Text[100])
    var
        Other: Record "TE Universal";
    begin
        Other.Get(EntryNo);
        Other."Text Field" := NewText;
        Other.Modify(false);
    end;
    local procedure ShInsertAnotherRow(EntryNo: Integer)
    var
        Another: Record "TE Universal";
    begin
        Another.Init();
        Another."Entry No." := EntryNo;
        Another."Text Field" := 'another';
        Another.Insert(true);
    end;

    // ---- Writer TE, al-runner issue 6028 (follow-up to 5954): the buffer is made stale before N Commits (N = 1, 2, 3; a write to another
    // table between consecutive Commits); the next transaction does one thing (LockTable on another table with an Insert and a read of the
    // table, LockTable only, the same Insert and read without LockTable, LockTable on the same table, Modify, Delete, Insert or Rename of
    // ANOTHER row of the table, or nothing) and then the stale buffer Modifies or Deletes. Row 6 is the buffer's row, row 8 the other row
    // (inserted in the first transaction, before the first Commit).

    local procedure TePrepare(var Row: Record "TE Universal"; Commits: Integer)
    var
        Middle: Record "TE Keyed";
        i: Integer;
    begin
        SbInsertAndOwnModify(Row);
        ShInsertAnotherRow(8);
        SbOtherWrite(6, 'other');
        Commit();
        for i := 2 to Commits do begin
            Middle.Init();
            Middle."Entry No." := i;
            Middle.Insert(true);
            Commit();
        end;
    end;

    local procedure TeLockOtherInsertRead()
    var
        Locked: Record "TE Keyed";
        Reader: Record "TE Universal";
    begin
        Locked.LockTable();
        Locked.Init();
        Locked."Entry No." := 100;
        Locked.Insert(false);
        Reader.FindSet();
    end;

    local procedure TeLockOtherOnly()
    var
        Locked: Record "TE Keyed";
    begin
        Locked.LockTable();
    end;

    local procedure TeOtherTableInsertRead()
    var
        Other: Record "TE Keyed";
        Reader: Record "TE Universal";
    begin
        Other.Init();
        Other."Entry No." := 100;
        Other.Insert(false);
        Reader.FindSet();
    end;

    local procedure TeLockSame()
    var
        Locked: Record "TE Universal";
    begin
        Locked.LockTable();
    end;

    local procedure TeModifyOther()
    var
        Another: Record "TE Universal";
    begin
        Another.Get(8);
        Another."Integer Field" := 7;
        Another.Modify(false);
    end;

    local procedure TeDeleteOther()
    var
        Another: Record "TE Universal";
    begin
        Another.Get(8);
        Another.Delete(false);
    end;

    local procedure TeInsertOther()
    begin
        ShInsertAnotherRow(9);
    end;

    local procedure TeRenameOther()
    var
        Another: Record "TE Universal";
    begin
        Another.Get(8);
        Another.Rename(9);
    end;

    local procedure TeCleanup()
    var
        Rows: Record "TE Universal";
        Middle: Record "TE Keyed";
    begin
        Rows.DeleteAll();
        Middle.DeleteAll();
        Commit();
    end;

    local procedure TeObserveStored(var Observer: Codeunit "Probe Observer")
    var
        Stored: Record "TE Universal";
    begin
        if Stored.Get(6) then
            Observer.Observe('stored', Stored."Text Field" + '|' + Format(Stored."Integer Field") + '|' + Format(Stored."Decimal Field"))
        else
            Observer.Observe('stored', 'none');
        Observer.Observe('row 8 exists', Format(Stored.Get(8)));
        TeCleanup();
    end;

    local procedure TeWriteOk(var Row: Record "TE Universal"; Deleting: Boolean; var Observer: Codeunit "Probe Observer")
    begin
        Row."Integer Field" := 5;
        if Deleting then
            Row.Delete(false)
        else
            Row.Modify(false);
        Observer.Observe('write', 'ok');
        TeObserveStored(Observer);
    end;

    local procedure TeWriteRefused(var Row: Record "TE Universal"; Deleting: Boolean; var Observer: Codeunit "Probe Observer")
    begin
        Row."Integer Field" := 5;
        if Deleting then
            asserterror Row.Delete(false)
        else
            asserterror Row.Modify(false);
        Observer.Observe('write', 'refused');
        Observer.Observe('code', GetLastErrorCode());
        Observer.Observe('text', Format((StrPos(GetLastErrorText(), StaleAfterCommitErr) = 1) and (StrPos(GetLastErrorText(), 'Entry No.=''6''') > 0)));
        TeObserveStored(Observer);
    end;

    [Test]
    procedure TE_1C_LockOtherInsertRead_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeLockOtherInsertRead();
        TeWriteRefused(Row, false, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_1C_LockOtherInsertRead_StaleDelete()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeLockOtherInsertRead();
        TeWriteRefused(Row, true, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_1C_LockOtherOnly_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeLockOtherOnly();
        TeWriteRefused(Row, false, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_1C_OtherTableInsertRead_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeOtherTableInsertRead();
        TeWriteRefused(Row, false, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_1C_LockSameTable_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeLockSame();
        TeWriteOk(Row, false, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_1C_ModifyOtherRow_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeModifyOther();
        TeWriteOk(Row, false, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_1C_DeleteOtherRow_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeDeleteOther();
        TeWriteOk(Row, false, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Expect('row 8 exists', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TE_1C_InsertOtherRow_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeInsertOther();
        TeWriteOk(Row, false, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_1C_RenameOtherRow_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeRenameOther();
        TeWriteOk(Row, false, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Expect('row 8 exists', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TE_1C_Nothing_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeWriteRefused(Row, false, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_1C_Nothing_StaleDelete()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeWriteRefused(Row, true, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_2C_LockOtherInsertRead_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeLockOtherInsertRead();
        TeWriteRefused(Row, false, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_2C_LockOtherInsertRead_StaleDelete()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeLockOtherInsertRead();
        TeWriteRefused(Row, true, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_2C_LockOtherOnly_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeLockOtherOnly();
        TeWriteRefused(Row, false, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_2C_OtherTableInsertRead_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeOtherTableInsertRead();
        TeWriteRefused(Row, false, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_2C_LockSameTable_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeLockSame();
        TeWriteOk(Row, false, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_2C_ModifyOtherRow_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeModifyOther();
        TeWriteOk(Row, false, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_2C_DeleteOtherRow_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeDeleteOther();
        TeWriteOk(Row, false, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Expect('row 8 exists', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TE_2C_InsertOtherRow_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeInsertOther();
        TeWriteOk(Row, false, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_2C_RenameOtherRow_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeRenameOther();
        TeWriteOk(Row, false, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Expect('row 8 exists', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TE_2C_Nothing_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeWriteRefused(Row, false, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_2C_Nothing_StaleDelete()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeWriteRefused(Row, true, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_3C_LockOtherInsertRead_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeLockOtherInsertRead();
        TeWriteRefused(Row, false, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_3C_LockOtherInsertRead_StaleDelete()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeLockOtherInsertRead();
        TeWriteRefused(Row, true, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_3C_LockOtherOnly_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeLockOtherOnly();
        TeWriteRefused(Row, false, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_3C_LockOtherOnly_StaleDelete()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeLockOtherOnly();
        TeWriteRefused(Row, true, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_3C_OtherTableInsertRead_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeOtherTableInsertRead();
        TeWriteRefused(Row, false, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_3C_OtherTableInsertRead_StaleDelete()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeOtherTableInsertRead();
        TeWriteRefused(Row, true, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_3C_LockSameTable_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeLockSame();
        TeWriteOk(Row, false, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_3C_LockSameTable_StaleDelete()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeLockSame();
        TeWriteOk(Row, true, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'none');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_3C_ModifyOtherRow_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeModifyOther();
        TeWriteOk(Row, false, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_3C_ModifyOtherRow_StaleDelete()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeModifyOther();
        TeWriteOk(Row, true, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'none');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_3C_DeleteOtherRow_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeDeleteOther();
        TeWriteOk(Row, false, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Expect('row 8 exists', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TE_3C_DeleteOtherRow_StaleDelete()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeDeleteOther();
        TeWriteOk(Row, true, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'none');
        Observer.Expect('row 8 exists', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TE_3C_InsertOtherRow_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeInsertOther();
        TeWriteOk(Row, false, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_3C_InsertOtherRow_StaleDelete()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeInsertOther();
        TeWriteOk(Row, true, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'none');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_3C_RenameOtherRow_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeRenameOther();
        TeWriteOk(Row, false, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Expect('row 8 exists', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TE_3C_RenameOtherRow_StaleDelete()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeRenameOther();
        TeWriteOk(Row, true, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'none');
        Observer.Expect('row 8 exists', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TE_3C_Nothing_StaleModify()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeWriteRefused(Row, false, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TE_3C_Nothing_StaleDelete()
    var
        Row: Record "TE Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeWriteRefused(Row, true, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('code', 'DB:RecordChanged');
        Observer.Expect('text', 'Yes');
        Observer.Expect('stored', 'other|0|1');
        Observer.Expect('row 8 exists', 'Yes');
        Observer.Verify();
    end;
}

codeunit 89818 "TE Cleanup"
{
    procedure Initialize()
    var
        U: Record "TE Universal";
    begin
        U.DeleteAll();
    end;
}
