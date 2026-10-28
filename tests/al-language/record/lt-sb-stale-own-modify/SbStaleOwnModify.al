// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), Probe Observer (69160); test codeunit 88980
// BC versions: 27+

/// <summary>
/// AL Runner issue 5823 (writer SB), a follow-up to 5805 (record/TestRecordStaleBufferWrite.al, RU_* tests): a record buffer that
/// did its OWN Insert and then its own write (Modify, a second Modify, Rename) in the transaction a Commit closes, after another
/// variable changed the row in that transaction. The buffer is then stale. What happens when it writes after the Commit depends
/// on what the new transaction did to the row first.
/// "Text Field" plays the issue's Note, "Integer Field" its Qty, "Decimal Field" its Stamp. Row 6 holds the row (row 7 after a
/// Rename). Every test removes the rows and commits at its end. Each test observes the stale write (ok or the error), then the
/// stored Text|Integer|Decimal fields.
/// Already pinned for a buffer that only did its Insert (5805): nothing after the Commit is refused
/// (TestRecordStaleBufferWrite.al RU_Stale_InsertBuffer_NothingAfterCommit), a changed write in the new transaction lets the stale
/// buffer win (RU_Stale_InsertBuffer_OtherGetChangeModify). The SB tests add the buffer's own writes after its Insert.
/// Measured (CI legs 27.5, 28.5, 29.0, same on all three): the buffer's own Modify(false), Modify(true), a second Modify, an unchanged
/// Modify and a Rename after its Insert all follow the rule of the Insert-only buffer. After the Commit the stale write is ACCEPTED
/// once the new transaction Modified the row (changed or unchanged) or read it under LockTable: the stale buffer wins and writes
/// all its fields (stored start|5|<own stamp>). It is REFUSED with DB:RecordChanged, the row keeping other|0|<own stamp>, with
/// nothing in between, after a plain Get, and after the unchanged Modify followed by a second Commit. A stale Delete follows the
/// same rule. An own Modify that comes after another variable's change in the same transaction changes nothing.
/// NEW versus the 5805 Get buffer (RU_Stale_GetBuffer_*, always refused): a buffer that read the committed row by Get and then did
/// its own Modify is accepted after the unchanged Modify of the new transaction, as an Insert buffer is, and refused with nothing
/// in between.
/// Writer SF, al-runner issue 5913 (SF_* tests, CI legs 27.5, 28.5, 29.0 alike): a buffer that READ the row by Get, GetBySystemId or
/// FindFirst in the transaction that inserted it (inserted by another variable, or by the buffer itself followed by its own Modify)
/// follows the Insert-buffer rule too: accepted once the new transaction Modified the row (changed or unchanged) or read it under
/// LockTable (stale buffer wins, stored start|5|<stamp>; a stale Delete removes the row), refused with nothing in between or after a
/// plain Get. What decides is that the buffer's row version was written in the transaction the Commit closed.
/// </summary>
codeunit 88980 "LT SB Stale Own Modify"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        StaleAfterCommitErr: Label 'The changes to the ALT Universal record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.', Locked = true;

    local procedure SbInsertRow(var Row: Record "ALT Universal")
    begin
        Cleanup.Initialize();
        Row.Init();
        Row."Entry No." := 6;
        Row."Text Field" := 'start';
        Row.Insert(true);
    end;

    local procedure SbInsertAndOwnModify(var Row: Record "ALT Universal")
    begin
        SbInsertRow(Row);
        Row."Decimal Field" := 1;
        Row.Modify(false);
    end;

    local procedure SbOtherWrite(EntryNo: Integer; NewText: Text[100])
    var
        Other: Record "ALT Universal";
    begin
        Other.Get(EntryNo);
        Other."Text Field" := NewText;
        Other.Modify(false);
    end;

    local procedure SbUnchangedWrite(EntryNo: Integer)
    var
        Other: Record "ALT Universal";
    begin
        Other.Get(EntryNo);
        Other.Modify(false);
    end;

    local procedure SbModifyStale(var Row: Record "ALT Universal"; var Observer: Codeunit "Probe Observer")
    begin
        Row."Integer Field" := 5;
        Row.Modify(false);
        Observer.Observe('write', 'ok');
        SbObserveStored(Row."Entry No.", Observer);
    end;

    local procedure SbModifyRefused(var Row: Record "ALT Universal"; var Observer: Codeunit "Probe Observer")
    begin
        Row."Integer Field" := 5;
        asserterror Row.Modify(false);
        Assert.ExpectedErrorCode('DB:RecordChanged');
        Assert.ExpectedError(StaleAfterCommitErr);
        Assert.ExpectedError(StrSubstNo('Entry No.=''%1''', Row."Entry No."));
        Observer.Observe('write', 'refused');
        SbObserveStored(Row."Entry No.", Observer);
    end;

    local procedure SbDeleteStale(var Row: Record "ALT Universal"; var Observer: Codeunit "Probe Observer")
    var
        Stored: Record "ALT Universal";
    begin
        Row.Delete(false);
        Observer.Observe('delete', 'ok');
        Observer.Observe('stored exists', Format(Stored.Get(Row."Entry No.")));
        SbCleanup();
    end;

    local procedure SbDeleteRefused(var Row: Record "ALT Universal"; var Observer: Codeunit "Probe Observer")
    var
        Stored: Record "ALT Universal";
    begin
        asserterror Row.Delete(false);
        Assert.ExpectedErrorCode('DB:RecordChanged');
        Assert.ExpectedError(StaleAfterCommitErr);
        Assert.ExpectedError(StrSubstNo('Entry No.=''%1''', Row."Entry No."));
        Observer.Observe('delete', 'refused');
        Observer.Observe('stored exists', Format(Stored.Get(Row."Entry No.")));
        SbCleanup();
    end;

    local procedure SbObserveStored(EntryNo: Integer; var Observer: Codeunit "Probe Observer")
    var
        Stored: Record "ALT Universal";
    begin
        Stored.Get(EntryNo);
        Observer.Observe('stored', Stored."Text Field" + '|' + Format(Stored."Integer Field") + '|' + Format(Stored."Decimal Field"));
        SbCleanup();
    end;

    local procedure SbCleanup()
    var
        Rows: Record "ALT Universal";
    begin
        Rows.DeleteAll();
        Commit();
    end;

    // ---- The reporter's table (issue 5823), with the buffer's own Modify(false) after its Insert(true).

    [Test]
    procedure SB_OwnModify_OtherWriteCommit_OtherChangedWrite()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertAndOwnModify(Row);
        SbOtherWrite(6, 'other');
        Commit();
        SbOtherWrite(6, 'other');
        SbModifyStale(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Verify();
    end;

    [Test]
    procedure SB_OwnModify_OtherWriteCommit_NothingAfter()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertAndOwnModify(Row);
        SbOtherWrite(6, 'other');
        Commit();
        SbModifyRefused(Row, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('stored', 'other|0|1');
        Observer.Verify();
    end;

    [Test]
    procedure SB_OwnModify_OtherWriteCommit_UnchangedWrite()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertAndOwnModify(Row);
        SbOtherWrite(6, 'other');
        Commit();
        SbUnchangedWrite(6);
        SbModifyStale(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Verify();
    end;

    // ---- Neighbours: other own writes after the Insert.

    [Test]
    procedure SB_OwnModifyTrue_OtherWriteCommit_UnchangedWrite()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertRow(Row);
        Row."Decimal Field" := 1;
        Row.Modify(true);
        SbOtherWrite(6, 'other');
        Commit();
        SbUnchangedWrite(6);
        SbModifyStale(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Verify();
    end;

    [Test]
    procedure SB_OwnModifyTrue_OtherWriteCommit_NothingAfter()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertRow(Row);
        Row."Decimal Field" := 1;
        Row.Modify(true);
        SbOtherWrite(6, 'other');
        Commit();
        SbModifyRefused(Row, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('stored', 'other|0|1');
        Observer.Verify();
    end;

    [Test]
    procedure SB_TwoOwnModifies_OtherWriteCommit_UnchangedWrite()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertAndOwnModify(Row);
        Row."Decimal Field" := 2;
        Row.Modify(false);
        SbOtherWrite(6, 'other');
        Commit();
        SbUnchangedWrite(6);
        SbModifyStale(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|2');
        Observer.Verify();
    end;

    [Test]
    procedure SB_TwoOwnModifies_OtherWriteCommit_NothingAfter()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertAndOwnModify(Row);
        Row."Decimal Field" := 2;
        Row.Modify(false);
        SbOtherWrite(6, 'other');
        Commit();
        SbModifyRefused(Row, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('stored', 'other|0|2');
        Observer.Verify();
    end;

    [Test]
    procedure SB_OwnUnchangedModify_OtherWriteCommit_UnchangedWrite()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertRow(Row);
        Row.Modify(false);
        SbOtherWrite(6, 'other');
        Commit();
        SbUnchangedWrite(6);
        SbModifyStale(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|0');
        Observer.Verify();
    end;

    [Test]
    procedure SB_OwnRename_OtherWriteCommit_UnchangedWrite()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertRow(Row);
        Row.Rename(7);
        SbOtherWrite(7, 'other');
        Commit();
        SbUnchangedWrite(7);
        SbModifyStale(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|0');
        Observer.Verify();
    end;

    [Test]
    procedure SB_OwnRename_OtherWriteCommit_NothingAfter()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertRow(Row);
        Row.Rename(7);
        SbOtherWrite(7, 'other');
        Commit();
        SbModifyRefused(Row, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('stored', 'other|0|0');
        Observer.Verify();
    end;

    [Test]
    procedure SB_OwnModifyAfterOtherWrite_OtherWriteCommit_UnchangedWrite()
    // The own Modify comes after another variable's change in the same transaction (a stale write that is accepted there).
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertRow(Row);
        SbOtherWrite(6, 'mid');
        Row."Decimal Field" := 1;
        Row.Modify(false);
        SbOtherWrite(6, 'other');
        Commit();
        SbUnchangedWrite(6);
        SbModifyStale(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Verify();
    end;

    // ---- Neighbours: what the new transaction does before the stale write.

    [Test]
    procedure SB_OwnModify_OtherWriteCommit_LockTableGet()
    var
        Row: Record "ALT Universal";
        Later: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertAndOwnModify(Row);
        SbOtherWrite(6, 'other');
        Commit();
        Later.LockTable();
        Later.Get(6);
        SbModifyStale(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Verify();
    end;

    [Test]
    procedure SB_OwnModify_OtherWriteCommit_PlainGet()
    var
        Row: Record "ALT Universal";
        Later: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertAndOwnModify(Row);
        SbOtherWrite(6, 'other');
        Commit();
        Later.Get(6);
        SbModifyRefused(Row, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('stored', 'other|0|1');
        Observer.Verify();
    end;

    [Test]
    procedure SB_OwnModify_OtherWriteCommit_UnchangedWriteThenCommit()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertAndOwnModify(Row);
        SbOtherWrite(6, 'other');
        Commit();
        SbUnchangedWrite(6);
        Commit();
        SbModifyRefused(Row, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('stored', 'other|0|1');
        Observer.Verify();
    end;

    // ---- Neighbours: a stale Delete instead of the stale Modify.

    [Test]
    procedure SB_OwnModify_Delete_NothingAfter()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertAndOwnModify(Row);
        SbOtherWrite(6, 'other');
        Commit();
        SbDeleteRefused(Row, Observer);
        Observer.Expect('delete', 'refused');
        Observer.Expect('stored exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SB_OwnModify_Delete_UnchangedWrite()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertAndOwnModify(Row);
        SbOtherWrite(6, 'other');
        Commit();
        SbUnchangedWrite(6);
        SbDeleteStale(Row, Observer);
        Observer.Expect('delete', 'ok');
        Observer.Expect('stored exists', 'No');
        Observer.Verify();
    end;

    // ---- Neighbour: a buffer that read the committed row by Get and then did its own Modify (no own Insert).

    [Test]
    procedure SB_GetBufferOwnModify_OtherWriteCommit_UnchangedWrite()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertRow(Row);
        Commit();
        Clear(Row);
        Row.Get(6);
        Row."Decimal Field" := 1;
        Row.Modify(false);
        SbOtherWrite(6, 'other');
        Commit();
        SbUnchangedWrite(6);
        SbModifyStale(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Verify();
    end;

    [Test]
    procedure SB_GetBufferOwnModify_OtherWriteCommit_NothingAfter()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertRow(Row);
        Commit();
        Clear(Row);
        Row.Get(6);
        Row."Decimal Field" := 1;
        Row.Modify(false);
        SbOtherWrite(6, 'other');
        Commit();
        SbModifyRefused(Row, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('stored', 'other|0|1');
        Observer.Verify();
    end;

    // ---- AL Runner issue 5913 (writer SF): the buffer READ the row (Get, GetBySystemId, FindFirst) in the transaction that inserted
    // it, before the Commit, with no own write after that read. Another variable inserted the row (SfInsertByOther), or the buffer did
    // its own Insert and Modify and then read the row again.

    local procedure SfInsertByOther()
    var
        Other: Record "ALT Universal";
    begin
        SbInsertRow(Other);
    end;

    [Test]
    procedure SF_GetInInsertTx_OtherWriteCommit_OtherChangedWrite()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SfInsertByOther();
        Row.Get(6);
        SbOtherWrite(6, 'other');
        Commit();
        SbOtherWrite(6, 'later');
        SbModifyStale(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|0');
        Observer.Verify();
    end;

    [Test]
    procedure SF_OwnModifyThenGet_OtherWriteCommit_OtherChangedWrite()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertAndOwnModify(Row);
        Row.Get(6);
        SbOtherWrite(6, 'other');
        Commit();
        SbOtherWrite(6, 'later');
        SbModifyStale(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Verify();
    end;

    [Test]
    procedure SF_GetInInsertTx_OtherWriteCommit_LockTableGet()
    var
        Row: Record "ALT Universal";
        Later: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SfInsertByOther();
        Row.Get(6);
        SbOtherWrite(6, 'other');
        Commit();
        Later.LockTable();
        Later.Get(6);
        SbModifyStale(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|0');
        Observer.Verify();
    end;

    [Test]
    procedure SF_OwnModifyThenGetBySystemId_OtherWriteCommit_LockTableGet()
    var
        Row: Record "ALT Universal";
        Later: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertAndOwnModify(Row);
        Row.GetBySystemId(Row.SystemId);
        SbOtherWrite(6, 'other');
        Commit();
        Later.LockTable();
        Later.Get(6);
        SbModifyStale(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Verify();
    end;

    [Test]
    procedure SF_OwnModifyThenGetBySystemId_OtherWriteCommit_OtherChangedWrite()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertAndOwnModify(Row);
        Row.GetBySystemId(Row.SystemId);
        SbOtherWrite(6, 'other');
        Commit();
        SbOtherWrite(6, 'later');
        SbModifyStale(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Verify();
    end;

    [Test]
    procedure SF_FindFirstInInsertTx_OtherWriteCommit_OtherChangedWrite()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SfInsertByOther();
        Row.SetRange("Entry No.", 6);
        Row.FindFirst();
        SbOtherWrite(6, 'other');
        Commit();
        SbOtherWrite(6, 'later');
        SbModifyStale(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|0');
        Observer.Verify();
    end;

    [Test]
    procedure SF_GetInInsertTx_OtherWriteCommit_UnchangedWrite()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SfInsertByOther();
        Row.Get(6);
        SbOtherWrite(6, 'other');
        Commit();
        SbUnchangedWrite(6);
        SbModifyStale(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|0');
        Observer.Verify();
    end;

    [Test]
    procedure SF_GetInInsertTx_OtherWriteCommit_NothingAfter()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SfInsertByOther();
        Row.Get(6);
        SbOtherWrite(6, 'other');
        Commit();
        SbModifyRefused(Row, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('stored', 'other|0|0');
        Observer.Verify();
    end;

    [Test]
    procedure SF_GetInInsertTx_OtherWriteCommit_PlainGet()
    var
        Row: Record "ALT Universal";
        Later: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SfInsertByOther();
        Row.Get(6);
        SbOtherWrite(6, 'other');
        Commit();
        Later.Get(6);
        SbModifyRefused(Row, Observer);
        Observer.Expect('write', 'refused');
        Observer.Expect('stored', 'other|0|0');
        Observer.Verify();
    end;

    [Test]
    procedure SF_GetInInsertTx_Delete_OtherWriteCommit_OtherChangedWrite()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SfInsertByOther();
        Row.Get(6);
        SbOtherWrite(6, 'other');
        Commit();
        SbOtherWrite(6, 'later');
        SbDeleteStale(Row, Observer);
        Observer.Expect('delete', 'ok');
        Observer.Expect('stored exists', 'No');
        Observer.Verify();
    end;

    // ---- Writer SH, al-runner issue 5954: the buffer is made stale before TWO Commits (a write to another table between them); the
    // next transaction inserts another row of the same table (or of another table, or nothing) before the stale Modify.

    local procedure ShInsertMiddleRow()
    var
        Middle: Record "ALT Keyed";
    begin
        Middle.Init();
        Middle."Entry No." := 1;
        Middle.Name := 'MIDDLE';
        Middle.Insert(true);
    end;

    local procedure ShInsertAnotherRow(EntryNo: Integer)
    var
        Another: Record "ALT Universal";
    begin
        Another.Init();
        Another."Entry No." := EntryNo;
        Another."Text Field" := 'another';
        Another.Insert(true);
    end;

    local procedure ShCleanupKeyed()
    var
        Middle: Record "ALT Keyed";
    begin
        Middle.DeleteAll();
        Commit();
    end;

    [Test]
    procedure SH_OwnModify_TwoCommitsOtherTableBetween_AnotherRowInsert()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertAndOwnModify(Row);
        SbOtherWrite(6, 'other');
        Commit();
        ShInsertMiddleRow();
        Commit();
        ShInsertAnotherRow(8);
        SbModifyStale(Row, Observer);
        ShCleanupKeyed();
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Verify();
    end;

    [Test]
    procedure SH_OwnModify_OneCommit_AnotherRowInsert()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertAndOwnModify(Row);
        SbOtherWrite(6, 'other');
        Commit();
        ShInsertAnotherRow(8);
        SbModifyStale(Row, Observer);
        ShCleanupKeyed();
        Observer.Expect('write', 'ok');
        Observer.Expect('stored', 'start|5|1');
        Observer.Verify();
    end;

    [Test]
    procedure SH_OwnModify_TwoCommitsOtherTableBetween_NothingAfter()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertAndOwnModify(Row);
        SbOtherWrite(6, 'other');
        Commit();
        ShInsertMiddleRow();
        Commit();
        SbModifyRefused(Row, Observer);
        ShCleanupKeyed();
        Observer.Expect('write', 'refused');
        Observer.Expect('stored', 'other|0|1');
        Observer.Verify();
    end;

    [Test]
    procedure SH_OwnModify_TwoCommitsOtherTableBetween_OtherTableInsertAfter()
    var
        Row: Record "ALT Universal";
        Later: Record "ALT Keyed";
        Observer: Codeunit "Probe Observer";
    begin
        SbInsertAndOwnModify(Row);
        SbOtherWrite(6, 'other');
        Commit();
        ShInsertMiddleRow();
        Commit();
        Later.Init();
        Later."Entry No." := 2;
        Later.Insert(true);
        SbModifyRefused(Row, Observer);
        ShCleanupKeyed();
        Observer.Expect('write', 'refused');
        Observer.Expect('stored', 'other|0|1');
        Observer.Verify();
    end;

    // ---- Writer TE, al-runner issue 6028 (follow-up to 5954): the buffer is made stale before N Commits (N = 1, 2, 3; a write to another
    // table between consecutive Commits); the next transaction does one thing (LockTable on another table with an Insert and a read of the
    // table, LockTable only, the same Insert and read without LockTable, LockTable on the same table, Modify, Delete, Insert or Rename of
    // ANOTHER row of the table, or nothing) and then the stale buffer Modifies or Deletes. Row 6 is the buffer's row, row 8 the other row
    // (inserted in the first transaction, before the first Commit).

    [TryFunction]
    local procedure TeTryModify(var Row: Record "ALT Universal")
    begin
        Row.Modify(false);
    end;

    [TryFunction]
    local procedure TeTryDelete(var Row: Record "ALT Universal")
    begin
        Row.Delete(false);
    end;

    local procedure TePrepare(var Row: Record "ALT Universal"; Commits: Integer)
    var
        Middle: Record "ALT Keyed";
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
        Locked: Record "ALT Keyed";
        Reader: Record "ALT Universal";
    begin
        Locked.LockTable();
        Locked.Init();
        Locked."Entry No." := 100;
        Locked.Insert(false);
        Reader.FindSet();
    end;

    local procedure TeLockOtherOnly()
    var
        Locked: Record "ALT Keyed";
    begin
        Locked.LockTable();
    end;

    local procedure TeOtherTableInsertRead()
    var
        Other: Record "ALT Keyed";
        Reader: Record "ALT Universal";
    begin
        Other.Init();
        Other."Entry No." := 100;
        Other.Insert(false);
        Reader.FindSet();
    end;

    local procedure TeLockSame()
    var
        Locked: Record "ALT Universal";
    begin
        Locked.LockTable();
    end;

    local procedure TeModifyOther()
    var
        Another: Record "ALT Universal";
    begin
        Another.Get(8);
        Another."Integer Field" := 7;
        Another.Modify(false);
    end;

    local procedure TeDeleteOther()
    var
        Another: Record "ALT Universal";
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
        Another: Record "ALT Universal";
    begin
        Another.Get(8);
        Another.Rename(9);
    end;

    local procedure TeCleanup()
    var
        Rows: Record "ALT Universal";
        Middle: Record "ALT Keyed";
    begin
        Rows.DeleteAll();
        Middle.DeleteAll();
        Commit();
    end;

    local procedure TeObserveWrite(var Row: Record "ALT Universal"; Deleting: Boolean; var Observer: Codeunit "Probe Observer")
    var
        Stored: Record "ALT Universal";
        Done: Boolean;
    begin
        Row."Integer Field" := 5;
        ClearLastError();
        if Deleting then
            Done := TeTryDelete(Row)
        else
            Done := TeTryModify(Row);
        if Done then
            Observer.Observe('write', 'ok')
        else begin
            Observer.Observe('write', 'refused');
            Observer.Observe('code', GetLastErrorCode());
            Observer.Observe('text', GetLastErrorText());
        end;
        if Stored.Get(6) then
            Observer.Observe('stored', Stored."Text Field" + '|' + Format(Stored."Integer Field") + '|' + Format(Stored."Decimal Field"))
        else
            Observer.Observe('stored', 'none');
        Observer.Observe('row 8 exists', Format(Stored.Get(8)));
        TeCleanup();
    end;

    [Test]
    procedure TE_1C_LockOtherInsertRead_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeLockOtherInsertRead();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_1C_LockOtherInsertRead_StaleDelete()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeLockOtherInsertRead();
        TeObserveWrite(Row, True, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_1C_LockOtherOnly_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeLockOtherOnly();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_1C_OtherTableInsertRead_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeOtherTableInsertRead();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_1C_LockSameTable_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeLockSame();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_1C_ModifyOtherRow_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeModifyOther();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_1C_DeleteOtherRow_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeDeleteOther();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_1C_InsertOtherRow_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeInsertOther();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_1C_RenameOtherRow_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeRenameOther();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_1C_Nothing_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_1C_Nothing_StaleDelete()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 1);
        TeObserveWrite(Row, True, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_2C_LockOtherInsertRead_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeLockOtherInsertRead();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_2C_LockOtherInsertRead_StaleDelete()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeLockOtherInsertRead();
        TeObserveWrite(Row, True, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_2C_LockOtherOnly_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeLockOtherOnly();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_2C_OtherTableInsertRead_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeOtherTableInsertRead();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_2C_LockSameTable_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeLockSame();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_2C_ModifyOtherRow_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeModifyOther();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_2C_DeleteOtherRow_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeDeleteOther();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_2C_InsertOtherRow_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeInsertOther();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_2C_RenameOtherRow_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeRenameOther();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_2C_Nothing_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_2C_Nothing_StaleDelete()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 2);
        TeObserveWrite(Row, True, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_3C_LockOtherInsertRead_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeLockOtherInsertRead();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_3C_LockOtherInsertRead_StaleDelete()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeLockOtherInsertRead();
        TeObserveWrite(Row, True, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_3C_LockOtherOnly_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeLockOtherOnly();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_3C_LockOtherOnly_StaleDelete()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeLockOtherOnly();
        TeObserveWrite(Row, True, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_3C_OtherTableInsertRead_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeOtherTableInsertRead();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_3C_OtherTableInsertRead_StaleDelete()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeOtherTableInsertRead();
        TeObserveWrite(Row, True, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_3C_LockSameTable_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeLockSame();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_3C_LockSameTable_StaleDelete()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeLockSame();
        TeObserveWrite(Row, True, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_3C_ModifyOtherRow_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeModifyOther();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_3C_ModifyOtherRow_StaleDelete()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeModifyOther();
        TeObserveWrite(Row, True, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_3C_DeleteOtherRow_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeDeleteOther();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_3C_DeleteOtherRow_StaleDelete()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeDeleteOther();
        TeObserveWrite(Row, True, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_3C_InsertOtherRow_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeInsertOther();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_3C_InsertOtherRow_StaleDelete()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeInsertOther();
        TeObserveWrite(Row, True, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_3C_RenameOtherRow_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeRenameOther();
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_3C_RenameOtherRow_StaleDelete()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeRenameOther();
        TeObserveWrite(Row, True, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_3C_Nothing_StaleModify()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeObserveWrite(Row, False, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TE_3C_Nothing_StaleDelete()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        TePrepare(Row, 3);
        TeObserveWrite(Row, True, Observer);
        Observer.Finish();
    end;
}
