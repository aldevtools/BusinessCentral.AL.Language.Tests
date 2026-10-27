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
}
