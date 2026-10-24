// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000)
// BC versions: 27+

/// <summary>
/// What Modify and Delete do when the record buffer they write through is STALE: another variable
/// changed the row after this buffer read it (StefanMaron/BusinessCentral.AL.Runner#5204, #5355).
///
/// Measured on the service tiers, not assumed. A stale Modify is ACCEPTED (last writer wins) when
/// the newer row came from a Modify, Insert, Rename or RecordRef write of the same transaction,
/// also under LockTable, and a stale Delete is accepted too. It is REFUSED with DB:RecordChanged
/// when a Commit sits between the other variable's Modify and the stale write. A write to a row
/// the other variable removed or renamed fails as RecordNotFound, not as stale. A temporary
/// record has no row version at all.
///
/// NOT pinned: a stale Modify after a ModifyAll. The official Windows container (BC 28.4.53241.55757)
/// accepts it while the Linux image refuses it with DB:RecordChanged "Sorry, we just updated this
/// page. Reopen it, and try again." (corpus PR 546), so no assertion holds on both; the Windows
/// answer is the reference. The decompiled site is DataAccess.PerformModifyAsync /
/// HandleStaleRecordAsync (Ncl 28.4.53241.54346); the tests pin outcomes, not that mechanism.
/// </summary>
codeunit 69920 "Test Record Stale Buffer Write"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        StaleAfterCommitErr: Label 'The changes to the ALT Universal record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.', Locked = true;
        RowNotFoundErr: Label 'The ALT Universal does not exist. Identification fields and values: Entry No.=''2''', Locked = true;

    [Test]
    procedure Record_Modify_ThroughStaleVariable_AfterOtherVariableModified_IsAccepted()
    // CLAIM: the issue's shape. Both variables read row 2, one Modifies it, the stale one Modifies
    // it too: no error, and the stale buffer's field value is what is stored (last writer wins).
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
    begin
        Initialize();
        InsertRow2(Rec);
        Stale.Get(2);
        Rec.Get(2);
        Rec."Integer Field" := 42;
        Rec.Modify();

        Stale."Integer Field" := 7;
        Stale.Modify();

        Rec.Get(2);
        Assert.AreEqual(7, Rec."Integer Field", 'the stale variable''s Modify must have been applied');
    end;

    [Test]
    procedure Record_ModifyTrue_ThroughStaleVariable_AfterOtherVariableModified_IsAccepted()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
    begin
        Initialize();
        InsertRow2(Rec);
        Stale.Get(2);
        Rec.Get(2);
        Rec."Integer Field" := 42;
        Rec.Modify(true);

        Stale."Integer Field" := 7;
        Stale.Modify(true);

        Rec.Get(2);
        Assert.AreEqual(7, Rec."Integer Field", 'the stale variable''s Modify(true) must have been applied');
    end;

    [Test]
    procedure Record_Modify_ThroughStaleVariableReadByFindFirst_IsAccepted()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
    begin
        Initialize();
        InsertRow2(Rec);
        Stale.FindFirst();
        Rec.Get(2);
        Rec."Integer Field" := 42;
        Rec.Modify();

        Stale."Integer Field" := 7;
        Stale.Modify();

        Rec.Get(2);
        Assert.AreEqual(7, Rec."Integer Field", 'the stale variable''s Modify must have been applied');
    end;

    [Test]
    procedure Record_Modify_ThroughStaleVariableThatReadUnderLockTable_IsAccepted()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
    begin
        Initialize();
        InsertRow2(Rec);
        Stale.LockTable();
        Stale.Get(2);
        Rec.Get(2);
        Rec."Integer Field" := 42;
        Rec.Modify();

        Stale."Integer Field" := 7;
        Stale.Modify();

        Rec.Get(2);
        Assert.AreEqual(7, Rec."Integer Field", 'the stale variable''s Modify must have been applied');
    end;

    [Test]
    procedure Record_Modify_ThroughVariableThatInsertedTheRow_AfterOtherVariableModified_IsAccepted()
    var
        Rec: Record "ALT Universal";
        Other: Record "ALT Universal";
    begin
        Initialize();
        InsertRow2(Rec);
        Other.Get(2);
        Other."Integer Field" := 42;
        Other.Modify();

        Rec."Integer Field" := 7;
        Rec.Modify();

        Other.Get(2);
        Assert.AreEqual(7, Other."Integer Field", 'the inserting variable''s Modify must have been applied');
    end;

    [Test]
    procedure Record_Modify_ThroughStaleVariable_AfterOtherVariableRenamedAndBack_IsAccepted()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
    begin
        Initialize();
        InsertRow2(Rec);
        Stale.Get(2);
        Rec.Get(2);
        Rec.Rename(3);
        Rec.Rename(2);

        Stale."Integer Field" := 7;
        Stale.Modify();

        Rec.Get(2);
        Assert.AreEqual(7, Rec."Integer Field", 'the stale variable''s Modify must have been applied');
    end;

    [Test]
    procedure Record_Modify_ThroughStaleVariable_AfterRowDeletedAndReinserted_IsAccepted()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
    begin
        Initialize();
        InsertRow2(Rec);
        Stale.Get(2);
        Rec.Delete();
        Rec.Init();
        Rec."Entry No." := 2;
        Rec.Insert();

        Stale."Integer Field" := 7;
        Stale.Modify();

        Rec.Get(2);
        Assert.AreEqual(7, Rec."Integer Field", 'the stale variable''s Modify must have been applied');
    end;

    [Test]
    procedure Record_Modify_ThroughStaleVariable_AfterRecordRefModify_IsAccepted()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
        Ref: RecordRef;
    begin
        Initialize();
        InsertRow2(Rec);
        Stale.Get(2);
        Ref.GetTable(Rec);
        Ref.Get(Rec.RecordId);
        Ref.Field(3).Value := 42;
        Ref.Modify();

        Stale."Integer Field" := 7;
        Stale.Modify();

        Rec.Get(2);
        Assert.AreEqual(7, Rec."Integer Field", 'the stale variable''s Modify must have been applied');
    end;

    [Test]
    procedure Record_Delete_ThroughStaleVariable_AfterOtherVariableModified_IsAccepted()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
    begin
        Initialize();
        InsertRow2(Rec);
        Stale.Get(2);
        Rec.Get(2);
        Rec."Integer Field" := 42;
        Rec.Modify();

        Stale.Delete();

        Assert.IsFalse(Rec.Get(2), 'the stale variable''s Delete must have removed the row');
    end;

    [Test]
    procedure Record_Delete_ThroughStaleVariable_AfterOtherVariableModifyAll_IsAccepted()
    // Unlike Modify, a stale Delete is not refused even when ModifyAll made the buffer stale.
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
    begin
        Initialize();
        InsertRow2(Rec);
        Stale.Get(2);
        Rec.ModifyAll("Integer Field", 42);

        Stale.Delete();

        Assert.IsFalse(Rec.Get(2), 'the stale variable''s Delete must have removed the row');
    end;

    [Test]
    procedure Record_Modify_AfterGetFollowingModifyAll_IsAccepted()
    // Control for the pinned Windows-and-Linux answers: a variable that re-reads after a ModifyAll is current.
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
    begin
        Initialize();
        InsertRow2(Rec);
        Stale.Get(2);
        Rec.ModifyAll("Integer Field", 42);
        Stale.Get(2);

        Stale."Integer Field" := 7;
        Stale.Modify();

        Rec.Get(2);
        Assert.AreEqual(7, Rec."Integer Field", 'a Modify after a fresh Get must have been applied');
    end;

    [Test]
    procedure Record_Modify_ThroughStaleVariable_AfterOtherVariableModifiedAndCommit_IsRefused()
    // Without the Commit this is the accepted shape of the first test; with it, the stale write is
    // refused and the message names the row.
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
    begin
        Initialize();
        InsertRow2(Rec);
        Commit();
        Stale.Get(2);
        Rec.Get(2);
        Rec."Integer Field" := 42;
        Rec.Modify();
        Commit();

        Stale."Integer Field" := 7;
        asserterror Stale.Modify();

        Assert.ExpectedErrorCode('DB:RecordChanged');
        Assert.ExpectedError(StaleAfterCommitErr);
        Assert.ExpectedError('Entry No.=''2''');
        Rec.Get(2);
        Assert.AreEqual(42, Rec."Integer Field", 'a refused Modify must leave the other variable''s value in place');

        // The rows were committed: remove them so no later test inherits them.
        Rec.DeleteAll();
        Commit();
    end;

    [Test]
    procedure Record_Modify_ThroughTemporaryRecordSharingTheBuffer_IsAccepted()
    // A temporary record has no row version, so there is nothing to be stale against.
    var
        Rec: Record "ALT Universal" temporary;
        Stale: Record "ALT Universal" temporary;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.Copy(Rec, true);
        Stale.Get(2);
        Rec.Get(2);
        Rec."Integer Field" := 42;
        Rec.Modify();

        Stale."Integer Field" := 7;
        Stale.Modify();

        Rec.Get(2);
        Assert.AreEqual(7, Rec."Integer Field", 'the stale variable''s Modify must have been applied');
    end;

    [Test]
    procedure Record_Modify_ThroughTemporaryRecordAfterModifyAll_IsAccepted()
    var
        Rec: Record "ALT Universal" temporary;
        Stale: Record "ALT Universal" temporary;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.Copy(Rec, true);
        Stale.Get(2);
        Rec.ModifyAll("Integer Field", 42);

        Stale."Integer Field" := 7;
        Stale.Modify();

        Rec.Get(2);
        Assert.AreEqual(7, Rec."Integer Field", 'the stale variable''s Modify must have been applied');
    end;

    [Test]
    procedure Record_Modify_ThroughStaleVariable_AfterOtherVariableRenamed_RowNotFound()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
    begin
        Initialize();
        InsertRow2(Rec);
        Stale.Get(2);
        Rec.Get(2);
        Rec.Rename(3);

        Stale."Integer Field" := 7;
        asserterror Stale.Modify();

        Assert.ExpectedErrorCode('DB:RecordNotFound');
        Assert.ExpectedError(RowNotFoundErr);
    end;

    [Test]
    procedure Record_Modify_ThroughStaleVariable_AfterOtherVariableDeleted_RowNotFound()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
    begin
        Initialize();
        InsertRow2(Rec);
        Stale.Get(2);
        Rec.Get(2);
        Rec.Delete();

        Stale."Integer Field" := 7;
        asserterror Stale.Modify();

        Assert.ExpectedErrorCode('DB:RecordNotFound');
        Assert.ExpectedError(RowNotFoundErr);
    end;

    [Test]
    procedure Record_Delete_ThroughStaleVariable_AfterOtherVariableDeleted_RowNotFound()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
    begin
        Initialize();
        InsertRow2(Rec);
        Stale.Get(2);
        Rec.Get(2);
        Rec.Delete();

        asserterror Stale.Delete();

        Assert.ExpectedErrorCode('DB:RecordNotFound');
        Assert.ExpectedError(RowNotFoundErr);
    end;

    local procedure InsertRow2(var Rec: Record "ALT Universal")
    begin
        Rec."Entry No." := 2;
        Rec.Insert();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;


    // ---- AL Runner issue 5805 (writer RU): a buffer made stale before a Commit, written after the Commit, depending on what the new
    // transaction did to the row first. "Text Field" plays the issue's Note, "Integer Field" its Qty. Row 5 holds the row; every test
    // removes it and commits at its end. Each test observes the stale write (ok or the error), then the stored Text and Integer fields.

    local procedure RuInsertRow(var Row: Record "ALT Universal")
    begin
        Row.Init();
        Row."Entry No." := 5;
        Row."Text Field" := 'start';
        Row.Insert(false);
    end;

    local procedure RuChangeAndCommit()
    var
        Other: Record "ALT Universal";
    begin
        Other.Get(5);
        Other."Text Field" := 'other';
        Other.Modify(false);
        Commit();
    end;

    local procedure RuModifyStale(var Row: Record "ALT Universal"; var Observer: Codeunit "Probe Observer")
    begin
        Row."Integer Field" := 5;
        Row.Modify(false);
        Observer.Observe('write', 'ok');
        RuObserveStored(Observer);
    end;

    local procedure RuDeleteStale(var Row: Record "ALT Universal"; var Observer: Codeunit "Probe Observer")
    var
        Stored: Record "ALT Universal";
    begin
        Row.Delete(false);
        Observer.Observe('delete', 'ok');
        Observer.Observe('stored exists', Format(Stored.Get(5)));
        RuCleanup();
    end;

    local procedure RuObserveStored(var Observer: Codeunit "Probe Observer")
    var
        Stored: Record "ALT Universal";
    begin
        Stored.Get(5);
        Observer.Observe('stored', Stored."Text Field" + '|' + Format(Stored."Integer Field"));
        RuCleanup();
    end;

    local procedure RuCleanup()
    var
        Rows: Record "ALT Universal";
    begin
        Rows.DeleteAll();
        Commit();
    end;

    [Test]
    procedure RU_Stale_InsertBuffer_NothingAfterCommit()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RuInsertRow(Row);
        RuChangeAndCommit();
        RuModifyStale(Row, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RU_Stale_InsertBuffer_OtherGetModifyUnchanged()
    var
        Row: Record "ALT Universal";
        Later: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RuInsertRow(Row);
        RuChangeAndCommit();
        Later.Get(5);
        Later.Modify(false);
        RuModifyStale(Row, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RU_Stale_InsertBuffer_WriterModifiesAgainUnchanged()
    var
        Row: Record "ALT Universal";
        Other: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RuInsertRow(Row);
        Other.Get(5);
        Other."Text Field" := 'other';
        Other.Modify(false);
        Commit();
        Other.Modify(false);
        RuModifyStale(Row, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RU_Stale_InsertBuffer_OtherLockTableGet()
    var
        Row: Record "ALT Universal";
        Later: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RuInsertRow(Row);
        RuChangeAndCommit();
        Later.LockTable();
        Later.Get(5);
        RuModifyStale(Row, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RU_Stale_InsertBuffer_OtherGetOnly()
    var
        Row: Record "ALT Universal";
        Later: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RuInsertRow(Row);
        RuChangeAndCommit();
        Later.Get(5);
        RuModifyStale(Row, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RU_Stale_InsertBuffer_OtherGetChangeModify()
    var
        Row: Record "ALT Universal";
        Later: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RuInsertRow(Row);
        RuChangeAndCommit();
        Later.Get(5);
        Later."Text Field" := 'later';
        Later.Modify(false);
        RuModifyStale(Row, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RU_Stale_InsertBuffer_OtherGetModifyUnchanged_ThenCommit()
    var
        Row: Record "ALT Universal";
        Later: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RuInsertRow(Row);
        RuChangeAndCommit();
        Later.Get(5);
        Later.Modify(false);
        Commit();
        RuModifyStale(Row, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RU_Stale_GetBuffer_OtherGetModifyUnchanged()
    var
        Row: Record "ALT Universal";
        Later: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RuInsertRow(Row);
        Commit();
        Row.Get(5);
        RuChangeAndCommit();
        Later.Get(5);
        Later.Modify(false);
        RuModifyStale(Row, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RU_Stale_GetBuffer_OtherLockTableGet()
    var
        Row: Record "ALT Universal";
        Later: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RuInsertRow(Row);
        Commit();
        Row.Get(5);
        RuChangeAndCommit();
        Later.LockTable();
        Later.Get(5);
        RuModifyStale(Row, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RU_Stale_GetBuffer_OtherGetChangeModify()
    var
        Row: Record "ALT Universal";
        Later: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RuInsertRow(Row);
        Commit();
        Row.Get(5);
        RuChangeAndCommit();
        Later.Get(5);
        Later."Text Field" := 'later';
        Later.Modify(false);
        RuModifyStale(Row, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RU_Stale_InsertBuffer_Delete_NothingAfterCommit()
    var
        Row: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RuInsertRow(Row);
        RuChangeAndCommit();
        RuDeleteStale(Row, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RU_Stale_InsertBuffer_Delete_OtherGetModifyUnchanged()
    var
        Row: Record "ALT Universal";
        Later: Record "ALT Universal";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RuInsertRow(Row);
        RuChangeAndCommit();
        Later.Get(5);
        Later.Modify(false);
        RuDeleteStale(Row, Observer);
        Observer.Finish();
    end;
}
