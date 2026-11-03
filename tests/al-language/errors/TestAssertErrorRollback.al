// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling
// Scope: in-scope
// Fixtures used: ALT Universal (60000, database-backed), ALT Temp Only (60025, TableType=Temporary)
//
// Pins down what asserterror rolls back when the error is UNRELATED to the write that
// preceded it — i.e. not a trigger firing on the write itself (TestTriggerRollback.al covers
// that shape), but a plain Error(), whether raised by a later, separate statement OR by the
// SAME statement asserterror wraps, after that statement's own writes already landed (see
// ..._InsideAssertErrorStatement below — the Error() is textually inside the asserterror'd
// call, but is not itself a write, so the writes before it are just as "unrelated" as if a
// later statement had thrown).
//
// The trigger already discovered this once, incidentally: CFV Tests (60942) originally
// asserted against fixture rows seeded by its own Initialize() right after an unrelated
// asserterror and failed on real BC 27.5/28.3, because the error rolled the write
// transaction back PAST that Initialize() call to the last Commit() (session start, since
// none had been issued). This suite isolates that mechanism on its own:
//   - does an uncommitted write survive an unrelated asserterror? (no)
//   - does Commit() move the surviving boundary forward? (yes — only writes since the last
//     Commit() are undone)
//   - do temporary-table writes participate in that rollback at all? (no — TableType=Temporary
//     has no database backing, so there is nothing for the SQL transaction to undo)
//   - does writing the SAME table twice since the last commit still roll back BOTH writes,
//     not just the last one? (yes — AlRunner#2191)
//   - do writes made INSIDE the asserterror'd statement, before an unrelated Error() in that
//     same statement, still roll back? (yes — AlRunner#2191)
codeunit 60943 "Test AssertError Rollback"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_Insert_UnrelatedAssertError_NoCommit_RowIsRolledBack()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 1;
        Rec.Insert(false);
        Assert.AreEqual(1, Rec.Count(), 'row must exist immediately after Insert, before the unrelated error');

        asserterror Error('unrelated error, nothing to do with the row above');
        Assert.ExpectedError('unrelated error, nothing to do with the row above');

        Assert.AreEqual(0, Rec.Count(),
            'an unrelated asserterror with no intervening Commit() must roll back the uncommitted Insert');
    end;

    [Test]
    procedure Record_Insert_Commit_UnrelatedAssertError_RowSurvives()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 1;
        Rec.Insert(false);
        Commit();

        asserterror Error('unrelated error after the commit');
        Assert.ExpectedError('unrelated error after the commit');

        Assert.AreEqual(1, Rec.Count(),
            'a Commit() before the error must make the Insert durable — the rollback boundary moves to the Commit(), not further back');
    end;

    [Test]
    procedure Record_Insert_Commit_SecondInsert_UnrelatedAssertError_OnlyUncommittedRowRolledBack()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 1;
        Rec.Insert(false);
        Commit();

        Rec."Entry No." := 2;
        Rec.Insert(false);
        Assert.AreEqual(2, Rec.Count(), 'both rows must exist immediately after the second Insert');

        asserterror Error('unrelated error after the second, uncommitted insert');
        Assert.ExpectedError('unrelated error after the second, uncommitted insert');

        Assert.IsTrue(Rec.Get(1), 'the row committed before the error must survive');
        Assert.IsFalse(Rec.Get(2), 'the row inserted after the last Commit() must be rolled back by the unrelated error');
        Assert.AreEqual(1, Rec.Count(), 'only the committed row must remain');
    end;

    [Test]
    procedure Record_Modify_UnrelatedAssertError_NoCommit_ChangeIsRolledBack()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 1;
        Rec."Integer Field" := 10;
        Rec.Insert(false);
        Commit();

        Rec.Get(1);
        Rec."Integer Field" := 99;
        Rec.Modify(false);

        asserterror Error('unrelated error after the uncommitted modify');
        Assert.ExpectedError('unrelated error after the uncommitted modify');

        Clear(Rec);
        Rec.Get(1);
        Assert.AreEqual(10, Rec."Integer Field",
            'an unrelated asserterror with no intervening Commit() must roll back the uncommitted Modify, restoring the committed value');
    end;

    [Test]
    procedure TempVar_Insert_UnrelatedAssertError_NoCommit_RowSurvives()
    var
        TempRec: Record "ALT Universal" temporary;
    begin
        Initialize();

        TempRec."Entry No." := 1;
        TempRec.Insert(false);

        asserterror Error('unrelated error, temp record has no database backing');
        Assert.ExpectedError('unrelated error, temp record has no database backing');

        Assert.AreEqual(1, TempRec.Count(),
            'a temporary-variable record has no SQL transaction to roll back — the row must survive an unrelated asserterror even without a Commit()');
    end;

    [Test]
    procedure TempOnly_Insert_UnrelatedAssertError_NoCommit_RowSurvives()
    var
        TempOnly: Record "ALT Temp Only";
    begin
        Initialize();

        TempOnly."Entry No." := 1;
        TempOnly.Insert(false);

        asserterror Error('unrelated error, TableType=Temporary has no database backing either');
        Assert.ExpectedError('unrelated error, TableType=Temporary has no database backing either');

        Assert.AreEqual(1, TempOnly.Count(),
            'TableType=Temporary is always in-memory — the row must survive an unrelated asserterror even without a Commit()');
    end;

    [Test]
    procedure Record_TwoInserts_SameTable_UnrelatedAssertError_NoCommit_BothRolledBack()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 1;
        Rec.Insert(false);
        Rec."Entry No." := 2;
        Rec.Insert(false);
        Assert.AreEqual(2, Rec.Count(), 'both rows must exist immediately after the second Insert');

        asserterror Error('unrelated error after two uncommitted inserts to the same table');
        Assert.ExpectedError('unrelated error after two uncommitted inserts to the same table');

        Assert.IsFalse(Rec.Get(1), 'the first uncommitted insert must be rolled back by the unrelated error');
        Assert.IsFalse(Rec.Get(2), 'the second uncommitted insert must be rolled back by the unrelated error');
        Assert.AreEqual(0, Rec.Count(),
            'writing the same table twice since the last commit must not narrow the rollback to only the last write');
    end;

    [Test]
    procedure Record_InsertThenModify_UnrelatedAssertError_NoCommit_RowRolledBack()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 1;
        Rec."Integer Field" := 10;
        Rec.Insert(false);
        Rec."Integer Field" := 99;
        Rec.Modify(false);
        Assert.AreEqual(1, Rec.Count(), 'the row must exist immediately after the Modify');

        asserterror Error('unrelated error after an uncommitted insert-then-modify');
        Assert.ExpectedError('unrelated error after an uncommitted insert-then-modify');

        Assert.IsFalse(Rec.Get(1),
            'an Insert followed by a Modify to the same table, both uncommitted, must both roll back on an unrelated error');
        Assert.AreEqual(0, Rec.Count(), 'no trace of the insert-then-modify may remain');
    end;

    [Test]
    procedure Record_InsertsInsideAssertErrorStatement_UnrelatedError_BothRolledBack()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        asserterror InsertTwoThenUnrelatedError();
        Assert.ExpectedError('unrelated error, raised after both inserts already landed');

        Assert.IsFalse(Rec.Get(1),
            'writes made inside the asserterror''d statement itself must still roll back when the failure is an unrelated Error(), not a trigger on the write');
        Assert.IsFalse(Rec.Get(2), 'same for the second row inserted inside the statement');
        Assert.AreEqual(0, Rec.Count(), 'both inserts made before the unrelated Error() must be rolled back');
    end;

    local procedure InsertTwoThenUnrelatedError()
    var
        Rec: Record "ALT Universal";
    begin
        Rec."Entry No." := 1;
        Rec.Insert(false);
        Rec."Entry No." := 2;
        Rec.Insert(false);
        Error('unrelated error, raised after both inserts already landed');
    end;

    [Test]
    procedure Record_DeleteLandsThenEmptyDeleteAll_UnrelatedError_LandedDeleteRolledBack()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 1;
        Rec.Insert(false);
        Commit();

        asserterror DeleteThenEmptyDeleteAllThenUnrelatedError();
        Assert.ExpectedError('unrelated error, raised after the delete landed and the empty DeleteAll matched nothing');

        // The Delete landed BEFORE the empty DeleteAll (which itself changed nothing) and the
        // unrelated Error() that followed both — the general rollback must still undo the
        // landed Delete, not skip this table just because the LAST write on it (the empty
        // DeleteAll) had no physical effect to compare against.
        Assert.IsTrue(Rec.Get(1),
            'a landed Delete earlier in the same asserterror''d statement must roll back even though a LATER, no-op write to the same table preceded the unrelated error');
    end;

    local procedure DeleteThenEmptyDeleteAllThenUnrelatedError()
    var
        Rec: Record "ALT Universal";
        Other: Record "ALT Universal";
    begin
        Rec.Get(1);
        Rec.Delete(false);
        Other.SetRange("Entry No.", 999);
        Other.DeleteAll(false);
        Error('unrelated error, raised after the delete landed and the empty DeleteAll matched nothing');
    end;

    local procedure Initialize()
    var
        Rec: Record "ALT Universal";
        TempOnly: Record "ALT Temp Only";
    begin
        Rec.DeleteAll(false);
        TempOnly.DeleteAll(false);
        // Commit the cleanup itself: TestIsolation = Codeunit does not reset table state
        // between test methods (TestIsolationRollbackScope, Codeunit 60897, pins that a row
        // one [Test] writes without committing is still visible to the next [Test] in the
        // same codeunit), and several tests in this suite (Record_Insert_Commit_..., every
        // "..._RowSurvives"/"..._SecondInsert..." case) deliberately leave a committed row
        // behind. Without this Commit(), that leftover row is on the WRONG side of a later
        // test's own rollback boundary: the DeleteAll() above is itself uncommitted since the
        // last commit point, so an unrelated asserterror in a LATER test rolls the DeleteAll()
        // back too, resurrecting the earlier test's leftover row under the same "Entry No." —
        // not a bug in the rollback mechanism, exactly the same "asserterror unwinds to the
        // last Commit()" rule this suite exists to pin, just applied to cleanup no test here
        // intended to be undoable.
        Commit();
    end;
}
