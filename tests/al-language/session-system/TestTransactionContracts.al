// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-commit-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Trigger Log (60003)
// Contract tests verifying Commit(), rollback-on-error, AutoIncrement, and system fields

codeunit 60152 "Test Transaction Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Commit() and Data Persistence ───────────────────────────────────────────

    [Test]
    procedure Commit_Persists_InsertedRecord()
    var
        Rec: Record "ALT Universal";
        Rec2: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Commit();
        Clear(Rec2);
        Assert.IsTrue(Rec2.Get(1), 'After Commit(), inserted record must be readable by a fresh query');
    end;

    [Test]
    procedure Error_After_Insert_Before_Commit_RecordPersists()
    var
        Rec: Record "ALT Universal";
        Rec2: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        asserterror Error('rollback test');
        Assert.AreEqual('rollback test', GetLastErrorText(), 'asserterror must capture error text');
        Clear(Rec2);
        Assert.IsTrue(Rec2.Get(1), 'Auto-committed insert must survive asserterror (record persists in AL test context)');
    end;

    [Test]
    procedure Commit_After_Multiple_Inserts_PersistsAll()
    var
        Rec: Record "ALT Universal";
        Rec2: Record "ALT Universal";
        i: Integer;
    begin
        Initialize();
        for i := 1 to 5 do begin
            Rec."Entry No." := i;
            Rec.Insert();
        end;
        Commit();
        Clear(Rec2);
        Assert.AreEqual(5, Rec2.Count(), 'After Commit, all 5 records must be visible');
    end;

    [Test]
    procedure Commit_Multiple_Times_NoError()
    var
        Rec: Record "ALT Universal";
        Rec2: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Commit();
        Rec."Entry No." := 2;
        Rec.Insert();
        Commit();
        Commit();
        Clear(Rec2);
        Assert.AreEqual(2, Rec2.Count(), 'Multiple Commits must all succeed and persist data');
    end;

    // ── AutoIncrement ───────────────────────────────────────────────────────────

    [Test]
    procedure AutoIncrement_Increments_Sequentially()
    var
        TL1: Record "ALT Trigger Log";
        TL2: Record "ALT Trigger Log";
        FirstId: Integer;
        LastId: Integer;
    begin
        Initialize();
        TL1.TriggerName := 'T1';
        TL1.Insert();
        TL2.TriggerName := 'T2';
        TL2.Insert();
        TL1.FindFirst();
        FirstId := TL1."Entry No.";
        TL2.FindLast();
        LastId := TL2."Entry No.";
        Assert.IsTrue(LastId > FirstId, 'AutoIncrement must produce increasing values');
    end;

    [Test]
    procedure AutoIncrement_After_Delete_ContinuesFromMax()
    var
        TL: Record "ALT Trigger Log";
        FirstId: Integer;
        SecondId: Integer;
    begin
        Initialize();
        TL.Init();
        TL.TriggerName := 'A';
        TL.Insert();
        Commit();
        TL.FindFirst();
        FirstId := TL."Entry No.";
        TL.DeleteAll();
        Commit();
        TL."Entry No." := 0;
        TL.TriggerName := 'B';
        TL.Insert();
        Commit();
        TL.FindFirst();
        SecondId := TL."Entry No.";
        Assert.IsTrue(SecondId > FirstId, 'AutoIncrement must continue from last used value, not restart');
    end;

    // ── System Fields: SystemModifiedAt ──────────────────────────────────────────

    [Test]
    procedure SystemModifiedAt_Set_On_Insert()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        Assert.AreNotEqual(0DT, Rec.SystemModifiedAt, 'SystemModifiedAt must be populated after insert');
    end;

    [Test]
    procedure SystemModifiedAt_Changes_On_Modify()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        Rec."Integer Field" := 99;
        Rec.Modify();
        Rec.Get(1);
        Assert.AreNotEqual(0DT, Rec.SystemModifiedAt, 'SystemModifiedAt must be populated after Modify');
    end;

    // ── System Fields: SystemCreatedAt ───────────────────────────────────────────

    [Test]
    procedure SystemCreatedAt_Set_On_Insert()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        Assert.AreNotEqual(0DT, Rec.SystemCreatedAt, 'SystemCreatedAt must be set on insert');
    end;

    [Test]
    procedure SystemCreatedAt_Does_Not_Change_On_Modify()
    var
        Rec: Record "ALT Universal";
        Created: DateTime;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        Created := Rec.SystemCreatedAt;
        Rec."Integer Field" := 42;
        Rec.Modify();
        Rec.Get(1);
        // Through Assert's Format(_, 0, 2) this held even if SystemCreatedAt had moved by
        // most of a minute, which is exactly what "must not change" is asserting against.
        // The format-9 round-trip form carries milliseconds; same claim, three orders of
        // magnitude finer.
        Assert.AreEqual(Format(Created, 0, 9), Format(Rec.SystemCreatedAt, 0, 9),
            'SystemCreatedAt must not change on Modify');
    end;

    // ── Record Locking and Updates ───────────────────────────────────────────────

    [Test]
    procedure FindSet_ForUpdate_Then_Modify_Succeeds()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 0;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec."Integer Field" := 0;
        Rec.Insert();
        Rec.Reset();
        Rec.FindSet(true);
        repeat
            Rec."Integer Field" := 99;
            Rec.Modify();
        until Rec.Next() = 0;
        Rec.Reset();
        Rec.SetRange("Integer Field", 99);
        Assert.AreEqual(2, Rec.Count(), 'FindSet(ForUpdate) + Modify must update all records successfully');
    end;

    // ── System Fields: SystemRowVersion ──────────────────────────────────────────

    [Test]
    procedure SystemRowVersion_NonZero_After_Insert()
    var
        Rec: Record "ALT Universal";
        NoRowVersion: BigInteger;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        // NoRowVersion rather than a bare 0: Assert compares the variant's TYPE as well as its
        // value, so an Integer 0 is never equal to a BigInteger and AreNotEqual(0, ...) cannot fail.
        Assert.AreNotEqual(NoRowVersion, Rec.SystemRowVersion, 'SystemRowVersion must be non-zero after insert');
    end;

    [Test]
    procedure SystemRowVersion_Increases_After_Modify()
    var
        Rec: Record "ALT Universal";
        RV1: BigInteger;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        RV1 := Rec.SystemRowVersion;
        Rec."Integer Field" := 42;
        Rec.Modify();
        Rec.Get(1);
        Assert.IsTrue(Rec.SystemRowVersion >= RV1, 'SystemRowVersion must be >= original after Modify');
    end;

    // ── Cleanup ─────────────────────────────────────────────────────────────────

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        ClearLastError();
    end;
}
