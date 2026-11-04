// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-commitbehavior-attribute
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling
// Scope: in-scope
// Fixtures used: ALT Universal (60000, database-backed)
//
// TestAssertErrorRollback.al (Codeunit 60943) pins the plain rule: an unrelated asserterror
// undoes every write made since the last Commit(), and an explicit Commit() moves that
// boundary forward. This suite pins what [CommitBehavior(...)] does to the SECOND half of
// that rule — the Commit() itself:
//   - CommitBehavior::Ignore  — Commit() does nothing at all, so the boundary does NOT move
//                               and a later unrelated error still undoes the write.
//   - CommitBehavior::Error   — Commit() raises instead of committing.
//   - the attribute governs the whole DYNAMIC scope of the attributed procedure, so a
//     Commit() in an unattributed callee is governed too;
//   - and the scope is popped on return, so a Commit() issued after the attributed call
//     returns is an ordinary commit again.
//
// The Ok-behaviour twin (..._Unattributed_...) is in this suite deliberately: it is the same
// helper body without the attribute, and it is what makes each Ignore assertion a statement
// about the ATTRIBUTE rather than about the shape of the call.
//
// How the two Ignore/Error behaviours interact with
// [TransactionModel(TransactionModel::AutoRollback)] is pinned separately, in
// record/TestTransactionModelAutoRollback.al (codeunit 60899, tests 07 and 08): Ignore exempts
// the platform's refusal of an explicit Commit() inside an AutoRollback test, and Error does not
// outrank it.
codeunit 60881 "Test Commit Behavior Attr"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        UnrelatedErr: Label 'unrelated error, nothing to do with the row above', Locked = true;

    [Test]
    procedure CommitBehavior_Unattributed_CommitBeforeErrorMakesRowDurable()
    var
        Rec: Record "ALT Universal";
    begin
        // Control twin for CommitBehavior_Ignore_CommitBeforeErrorDoesNotMakeRowDurable:
        // identical body, no attribute. Establishes that the shape itself commits.
        Initialize();

        asserterror InsertCommitThenError(1);
        Assert.ExpectedError(UnrelatedErr);

        Assert.IsTrue(Rec.Get(1),
            'without [CommitBehavior], the Commit() before the error is an ordinary commit — the row must survive');
        Assert.AreEqual(1, Rec.Count(), 'exactly the one committed row must remain');
    end;

    [Test]
    procedure CommitBehavior_Ignore_CommitBeforeErrorDoesNotMakeRowDurable()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        asserterror InsertCommitThenErrorIgnoringCommits(1);
        Assert.ExpectedError(UnrelatedErr);

        Assert.IsFalse(Rec.Get(1),
            'under [CommitBehavior(CommitBehavior::Ignore)] the Commit() does nothing, so the unrelated error must still roll the Insert back');
        Assert.AreEqual(0, Rec.Count(), 'no row may survive an ignored Commit()');
    end;

    [Test]
    procedure CommitBehavior_Ignore_GovernsCommitIssuedByAnUnattributedCallee()
    var
        Rec: Record "ALT Universal";
    begin
        // The attribute is on the CALLER; the Commit() is two frames down in a procedure
        // that carries no attribute of its own.
        Initialize();

        asserterror CallUnattributedHelperIgnoringCommits(2);
        Assert.ExpectedError(UnrelatedErr);

        Assert.IsFalse(Rec.Get(2),
            '[CommitBehavior(CommitBehavior::Ignore)] governs the whole dynamic scope — a Commit() in an unattributed callee is ignored too');
        Assert.AreEqual(0, Rec.Count(), 'the callee''s Commit() must not make the row durable');
    end;

    [Test]
    procedure CommitBehavior_Ignore_ScopeIsPoppedOnReturn()
    var
        Rec: Record "ALT Universal";
    begin
        // The write and the ignored Commit() happen inside the attributed call; the call
        // then RETURNS normally, and the test issues its own Commit(). That second Commit()
        // must be an ordinary one — the Ignore scope ended with the call.
        Initialize();

        InsertAndIgnoreCommit(3);
        Commit();

        asserterror Error(UnrelatedErr);
        Assert.ExpectedError(UnrelatedErr);

        Assert.IsTrue(Rec.Get(3),
            'the Ignore scope ends when the attributed procedure returns — the caller''s own later Commit() must commit normally');
        Assert.AreEqual(1, Rec.Count(), 'exactly the row committed after the scope ended must remain');
    end;

    [Test]
    procedure CommitBehavior_Error_CommitRaisesAndRowIsRolledBack()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        asserterror InsertThenCommitUnderErrorBehavior(4);
        Assert.ExpectedError('Commit is prohibited in the current scope');

        Assert.IsFalse(Rec.Get(4),
            'under [CommitBehavior(CommitBehavior::Error)] the Commit() raises instead of committing, so the Insert before it must roll back');
        Assert.AreEqual(0, Rec.Count(), 'nothing may survive a prohibited Commit()');
    end;

    local procedure InsertCommitThenError(EntryNo: Integer)
    var
        Rec: Record "ALT Universal";
    begin
        Rec."Entry No." := EntryNo;
        Rec.Insert(false);
        Commit();
        Error(UnrelatedErr);
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure InsertCommitThenErrorIgnoringCommits(EntryNo: Integer)
    var
        Rec: Record "ALT Universal";
    begin
        Rec."Entry No." := EntryNo;
        Rec.Insert(false);
        Commit();
        Error(UnrelatedErr);
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure CallUnattributedHelperIgnoringCommits(EntryNo: Integer)
    begin
        InsertCommitThenError(EntryNo);
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure InsertAndIgnoreCommit(EntryNo: Integer)
    var
        Rec: Record "ALT Universal";
    begin
        Rec."Entry No." := EntryNo;
        Rec.Insert(false);
        Commit();
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure InsertThenCommitUnderErrorBehavior(EntryNo: Integer)
    var
        Rec: Record "ALT Universal";
    begin
        Rec."Entry No." := EntryNo;
        Rec.Insert(false);
        Commit();
    end;

    local procedure Initialize()
    var
        Rec: Record "ALT Universal";
    begin
        Rec.DeleteAll(false);
        // Commit the cleanup for the same reason Codeunit 60943's Initialize() does:
        // TestIsolation = Codeunit does not reset table state between [Test] methods, and
        // tests here deliberately leave a committed row behind. Without this Commit() the
        // DeleteAll() is itself uncommitted, so a later test's unrelated asserterror rolls
        // it back and resurrects the earlier test's leftover row.
        Commit();
    end;
}
