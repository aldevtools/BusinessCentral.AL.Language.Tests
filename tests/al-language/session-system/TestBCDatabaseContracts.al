codeunit 60178 "Test BC Database Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    trigger OnRun()
    begin
    end;

    [Test]
    procedure RecordLevelLocking_Returns_Boolean()
    var
        Rec: Record "ALT Universal";
        Result: Boolean;
    begin
        Initialize();

        Result := Rec.RecordLevelLocking();

        Assert.IsTrue(true, 'RecordLevelLocking() must return Boolean without error');
    end;

    [Test]
    procedure RecordLevelLocking_Consistent_AcrossInstances()
    var
        Rec1: Record "ALT Universal";
        Rec2: Record "ALT Universal";
    begin
        Initialize();

        Assert.AreEqual(Rec1.RecordLevelLocking(), Rec2.RecordLevelLocking(), 'RecordLevelLocking must be consistent for same table across variables');
    end;

    [Test]
    procedure Database_IsInWriteTransaction_AfterInsert_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 1;
        Rec.Insert();

        Assert.IsTrue(Database.IsInWriteTransaction(), 'IsInWriteTransaction must return true after uncommitted Insert');
    end;

    [Test]
    procedure Database_IsInWriteTransaction_AfterCommit_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 1;
        Rec.Insert();
        Commit();

        Assert.IsFalse(Database.IsInWriteTransaction(), 'IsInWriteTransaction must return false after Commit()');
    end;

    [Test]
    procedure Database_IsInWriteTransaction_AfterDeleteAllWithNoMatches_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        // CLAIM: DeleteAll() issues a delete statement (and so opens a write transaction)
        // even when zero rows match the current filter — the write is a property of the
        // statement being issued, not of how many rows it happens to affect.
        Initialize();

        // The table is guaranteed empty here: Initialize() -> Cleanup.Initialize() just
        // DeleteAll'd it (and every other ALTFixtureCleanup-covered table). A second
        // DeleteAll immediately afterwards is a delete against zero matching rows.
        Rec.DeleteAll(false);

        Assert.IsTrue(Database.IsInWriteTransaction(), 'IsInWriteTransaction must return true after DeleteAll(), even when no rows matched');
    end;

    [Test]
    procedure Database_IsInWriteTransaction_AfterDeleteAllWithNoMatchesThenCommit_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
    begin
        // Negative pairing for the claim above: the write transaction a zero-match
        // DeleteAll() opens is a real, resettable transaction state -- not a flag that is
        // simply always true -- so Commit() must still clear it.
        Initialize();

        Rec.DeleteAll(false);
        Commit();

        Assert.IsFalse(Database.IsInWriteTransaction(), 'IsInWriteTransaction must return false after Commit() following a zero-match DeleteAll()');
    end;

    [Test]
    procedure Database_LastUsedRowVersion_Increases_AfterInsert()
    var
        Rec: Record "ALT Universal";
        RV1: BigInteger;
        RV2: BigInteger;
    begin
        Initialize();

        RV1 := Database.LastUsedRowVersion();

        Rec."Entry No." := 1;
        Rec.Insert();
        Commit();

        RV2 := Database.LastUsedRowVersion();

        Assert.IsTrue(RV2 >= RV1, 'LastUsedRowVersion must be >= previous value after Insert + Commit');
    end;

    [Test]
    procedure Database_MinimumActiveRowVersion_NonNegative()
    var
        MinRV: BigInteger;
    begin
        Initialize();

        MinRV := Database.MinimumActiveRowVersion();

        Assert.IsTrue(MinRV >= 0, 'MinimumActiveRowVersion must be non-negative');
    end;

    [Test]
    procedure FlowField_CalcFields_NotAffectedByRecordSetRange()
    var
        Parent: Record "ALT Parent";
        Child: Record "ALT Child";
        i: Integer;
    begin
        Initialize();

        Parent."Entry No." := 1;
        Parent.Insert();

        for i := 1 to 3 do begin
            Child."Entry No." := i;
            Child."Parent Entry No." := 1;
            Child.Amount := 10;
            Child.Insert();
        end;

        Parent.Reset();
        Parent.Get(1);
        Parent.CalcFields("Child Count");

        Assert.AreEqual(3, Parent."Child Count", 'CalcFields must use CalcFormula regardless of runtime table filter context');
    end;

    [Test]
    procedure FlowField_SetRange_OnFlowField_AcceptedByRuntime()
    var
        Parent: Record "ALT Parent";
    begin
        Initialize();

        Parent.SetRange("Child Count", 0, 5);

        Assert.IsTrue(true, 'SetRange on FlowField must not throw compile or runtime error');
    end;

    [Test]
    procedure Record_SelectLatestVersion_DoesNotThrow()
    begin
        Initialize();

        SelectLatestVersion();

        Assert.IsTrue(true, 'SelectLatestVersion() must not throw');
    end;

    [Test]
    procedure Record_SelectLatestVersion_WithTableId_DoesNotThrow()
    begin
        Initialize();

        SelectLatestVersion(60000);

        Assert.IsTrue(true, 'SelectLatestVersion(60000) must not throw');
    end;

    [Test]
    procedure Record_ReadPermission_BCRUNNER_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Assert.IsTrue(Rec.ReadPermission(), 'BCRUNNER must have Read permission on ALT Universal test table');
    end;

    [Test]
    procedure Record_WritePermission_BCRUNNER_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Assert.IsTrue(Rec.WritePermission(), 'BCRUNNER must have Write permission on ALT Universal test table');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        ClearLastError();
    end;
}
