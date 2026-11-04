// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-readisolation-method
// Scope: in-scope

codeunit 60176 "Test BC Locking Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure ReadIsolation_Default_IsCallable()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.ReadIsolation(IsolationLevel::Default);
        Assert.IsTrue(true, 'ReadIsolation(Default) must be callable without throwing in BC Cloud');
    end;

    [Test]
    procedure ReadIsolation_ReadUncommitted_IsCallable()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.ReadIsolation(IsolationLevel::ReadUncommitted);
        Assert.IsTrue(true, 'ReadIsolation(ReadUncommitted) must be callable without throwing in BC Cloud');
    end;

    [Test]
    procedure ReadIsolation_ReadCommitted_IsCallable()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.ReadIsolation(IsolationLevel::ReadCommitted);
        Assert.IsTrue(true, 'ReadIsolation(ReadCommitted) must be callable without throwing in BC Cloud');
    end;

    [Test]
    procedure ReadIsolation_RepeatableRead_IsCallable()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.ReadIsolation(IsolationLevel::RepeatableRead);
        Assert.IsTrue(true, 'ReadIsolation(RepeatableRead) must be callable without throwing in BC Cloud');
    end;

    [Test]
    procedure ReadIsolation_WithReadUncommitted_IsCallable()
    var
        Rec: Record "ALT Universal";
        Rec2: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1; Rec.Insert(); Commit();
        Rec2.ReadIsolation(IsolationLevel::ReadUncommitted);
        Assert.IsTrue(true, 'ReadIsolation(ReadUncommitted) must be callable without throwing in BC Cloud');
    end;

    [Test]
    procedure ReadConsistency_Default_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Assert.IsFalse(Rec.ReadConsistency(), 'ReadConsistency() must return false in BC Cloud');
    end;

    [Test]
    procedure ReadConsistency_AfterInsert_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1; Rec.Insert();
        Assert.IsFalse(Rec.ReadConsistency(), 'ReadConsistency() must still return false in BC Cloud after Insert');
    end;

    [Test]
    procedure Consistent_SetTrue_DoesNotThrow()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.Consistent(true);
        Assert.IsTrue(true, 'Rec.Consistent(true) must not throw');
    end;

    [Test]
    procedure Consistent_SetFalse_IsCallable()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.Consistent(false);  // must not throw on its own
        Rec.Consistent(true);   // restore
        Assert.IsTrue(true, 'Consistent(false/true) must be callable without throwing in isolation');
    end;

    [Test]
    procedure LockTable_AllowsSubsequentFind()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1; Rec.Insert();
        Rec.LockTable();
        Assert.IsTrue(Rec.FindFirst(), 'FindFirst must work after LockTable()');
        Assert.AreEqual(1, Rec."Entry No.", 'Record must be findable after LockTable');
    end;

    [Test]
    procedure LockTable_WithWaitFalse_CloudSandbox_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1; Rec.Insert();
        asserterror Rec.LockTable(false, false);
        Assert.ExpectedError('not supported');
    end;

    [Test]
    procedure RecordLevelLocking_ReturnsBoolean()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Assert.IsTrue(true, 'RecordLevelLocking() must be callable: ' + Format(Rec.RecordLevelLocking()));
    end;

    local procedure Initialize()
    begin
        ClearLastError();
        Cleanup.Initialize();
    end;
}
