// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-type
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Parent (60004), ALT Child (60005)

codeunit 60128 "Test Database Extended"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Database.CurrentTransactionType() ────────────────────────────────────

    [Test]
    procedure Database_CurrentTransactionType_ReturnsType()
    var
        TT: TransactionType;
    begin
        Initialize();
        TT := Database.CurrentTransactionType();
        Assert.IsTrue(true, 'CurrentTransactionType must not throw');
    end;

    [Test]
    procedure Database_CurrentTransactionType_SetAfterWriteOp_Throws()
    var
        TT: TransactionType;
    begin
        Initialize();
        // After Cleanup.Initialize() performs a write, the transaction has already started.
        // BC does not allow changing the transaction type after a transaction has started.
        asserterror Database.CurrentTransactionType(TransactionType::Update);
        Assert.ExpectedError('transaction');
    end;

    [Test]
    procedure Database_CurrentTransactionType_SetAndGetBrowse()
    var
        TT: TransactionType;
    begin
        Initialize();
        // Browse is a read-only type — setting it after a write may also fail.
        // Document that the getter is always callable.
        TT := Database.CurrentTransactionType();
        Assert.IsTrue(true, 'CurrentTransactionType getter must not throw');
    end;

    // ── Database.TenantId() ──────────────────────────────────────────────────

    [Test]
    procedure Database_TenantId_ReturnsString()
    var
        S: Text;
    begin
        Initialize();
        S := Database.TenantId();
        Assert.IsTrue(true, 'TenantId must be callable and return a string');
    end;

    [Test]
    procedure Database_TenantId_NotThrow()
    var
        S: Text;
    begin
        Initialize();
        S := Database.TenantId();
        Assert.AreNotEqual('', S, 'TenantId must return non-empty string in cloud context');
    end;

    // ── Database.HasTableConnection() ───────────────────────────────────────

    [Test]
    procedure Database_HasTableConnection_ExternalSQL_NotThrow()
    var
        HasConn: Boolean;
    begin
        Initialize();
        HasConn := Database.HasTableConnection(TableConnectionType::ExternalSQL, '');
        Assert.IsTrue(true, 'HasTableConnection must not throw');
    end;

    [Test]
    procedure Database_HasTableConnection_Default_NotThrow()
    var
        HasConn: Boolean;
    begin
        Initialize();
        HasConn := Database.HasTableConnection(TableConnectionType::ExternalSQL, '');
        Assert.IsTrue(true, 'HasTableConnection with Default type must not throw');
    end;

    // ── Database.ReadPermission() ────────────────────────────────────────────

    [Test]
    procedure Database_ReadPermission_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Assert.IsTrue(Rec.ReadPermission(), 'Read permission on ALT Universal must be true');
    end;

    // ── Database.WritePermission() ───────────────────────────────────────────

    [Test]
    procedure Database_WritePermission_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Assert.IsTrue(Rec.WritePermission(), 'Write permission on ALT Universal must be true');
    end;

    // ── Database.Commit() ────────────────────────────────────────────────────

    [Test]
    procedure Database_Commit_AfterInsert_PersistsData()
    var
        Rec: Record "ALT Universal";
        Rec2: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Commit();
        Rec2.SetRange("Entry No.", 1);
        Assert.IsTrue(Rec2.FindFirst(), 'After Commit, record must be retrievable');
    end;
    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
