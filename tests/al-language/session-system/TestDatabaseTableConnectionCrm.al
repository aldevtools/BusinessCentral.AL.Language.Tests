// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-registertableconnection-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-hastableconnection-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-setdefaulttableconnection-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-getdefaulttableconnection-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-unregistertableconnection-method
// Scope: in-scope (Cloud-compatible — CRM is the one TableConnectionType a Cloud extension may register)
// Fixtures used: ALT CRM Entity (60291)
//
// A CRM table connection registered INSIDE A TEST with the connection string '@@test@@' is
// the platform's own test connection: no Dataverse org is contacted, a TableType = CRM table
// is served from an in-memory test provider that assigns a fresh Guid to an empty primary
// key on Insert. This is the mechanism Microsoft's own Tests-CRM integration suite runs on
// ("Library - Mock CRM Connection".RegisterTestConnection). The registration itself is
// session state: it outlives the test that made it, so every test here unregisters what it
// registered and Initialize() tolerates a leftover from an aborted earlier test.

codeunit 60292 "Test Database TableConn CRM"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        ConnectionNameTok: Label 'ALTTEST', Locked = true;
        TestConnectionStringTok: Label '@@test@@', Locked = true;

    // ── Database.RegisterTableConnection / HasTableConnection ────────────────

    [Test]
    procedure Database_RegisterTableConnection_CrmTest_HasTableConnection_True()
    // CLAIM: after RegisterTableConnection(CRM, name, '@@test@@'), HasTableConnection(CRM, name)
    //        is true; a name that was never registered stays false.
    begin
        Initialize();

        Assert.IsFalse(HasTableConnection(TableConnectionType::CRM, ConnectionNameTok),
            'no CRM connection must be registered before the test registers one');

        RegisterTableConnection(TableConnectionType::CRM, ConnectionNameTok, TestConnectionStringTok);

        Assert.IsTrue(HasTableConnection(TableConnectionType::CRM, ConnectionNameTok),
            'HasTableConnection must be true for the name just registered');
        Assert.IsFalse(HasTableConnection(TableConnectionType::CRM, 'ALTNEVER'),
            'HasTableConnection must be false for a name that was never registered');

        UnregisterTableConnection(TableConnectionType::CRM, ConnectionNameTok);
    end;

    [Test]
    procedure Database_HasTableConnection_CrmTest_NameIsCaseInsensitive()
    // CLAIM: table connection names are matched case-insensitively.
    begin
        Initialize();

        RegisterTableConnection(TableConnectionType::CRM, ConnectionNameTok, TestConnectionStringTok);

        Assert.IsTrue(HasTableConnection(TableConnectionType::CRM, LowerCase(ConnectionNameTok)),
            'HasTableConnection must find the connection by its lower-cased name');

        UnregisterTableConnection(TableConnectionType::CRM, ConnectionNameTok);
    end;

    [Test]
    procedure Database_RegisterTableConnection_CrmTest_Duplicate_Throws()
    // CLAIM: registering the same (type, name) twice throws.
    begin
        Initialize();

        RegisterTableConnection(TableConnectionType::CRM, ConnectionNameTok, TestConnectionStringTok);

        asserterror RegisterTableConnection(TableConnectionType::CRM, ConnectionNameTok, TestConnectionStringTok);
        Assert.ExpectedError(ConnectionNameTok);

        UnregisterTableConnection(TableConnectionType::CRM, ConnectionNameTok);
    end;

    // ── Database.SetDefaultTableConnection / GetDefaultTableConnection ───────

    [Test]
    procedure Database_GetDefaultTableConnection_Crm_NoDefault_ReturnsEmpty()
    // CLAIM: with no default set, GetDefaultTableConnection(CRM) returns ''.
    begin
        Initialize();

        Assert.AreEqual('', GetDefaultTableConnection(TableConnectionType::CRM),
            'GetDefaultTableConnection must be empty when no CRM default was set');
    end;

    [Test]
    procedure Database_SetDefaultTableConnection_CrmTest_GetDefault_ReturnsName()
    // CLAIM: after SetDefaultTableConnection(CRM, name), GetDefaultTableConnection(CRM) returns
    //        the registered connection's name.
    begin
        Initialize();

        RegisterTableConnection(TableConnectionType::CRM, ConnectionNameTok, TestConnectionStringTok);
        SetDefaultTableConnection(TableConnectionType::CRM, ConnectionNameTok);

        Assert.AreEqual(ConnectionNameTok, GetDefaultTableConnection(TableConnectionType::CRM),
            'GetDefaultTableConnection must return the name passed to SetDefaultTableConnection');

        UnregisterTableConnection(TableConnectionType::CRM, ConnectionNameTok);
    end;

    // ── Database.UnregisterTableConnection ───────────────────────────────────

    [Test]
    procedure Database_UnregisterTableConnection_CrmTest_ClearsDefaultAndHas()
    // CLAIM: UnregisterTableConnection removes the connection and, when it was the default,
    //        clears the default too.
    begin
        Initialize();

        RegisterTableConnection(TableConnectionType::CRM, ConnectionNameTok, TestConnectionStringTok);
        SetDefaultTableConnection(TableConnectionType::CRM, ConnectionNameTok);

        UnregisterTableConnection(TableConnectionType::CRM, ConnectionNameTok);

        Assert.IsFalse(HasTableConnection(TableConnectionType::CRM, ConnectionNameTok),
            'HasTableConnection must be false after UnregisterTableConnection');
        Assert.AreEqual('', GetDefaultTableConnection(TableConnectionType::CRM),
            'unregistering the default connection must clear GetDefaultTableConnection');
    end;

    // ── Record on a TableType = CRM table through the test connection ────────

    [Test]
    procedure Record_Insert_CrmTable_TestConnection_AssignsGuidPk()
    // CLAIM: Insert() into a TableType = CRM table over the '@@test@@' connection assigns a
    //        non-null Guid primary key when the record leaves it empty, keeps a caller-supplied
    //        Guid, and the rows read back through the same table.
    var
        Entity: Record "ALT CRM Entity";
        Found: Record "ALT CRM Entity";
        FirstId: Guid;
        SecondId: Guid;
        PresetId: Guid;
    begin
        Initialize();
        RegisterTestConnection();

        Entity.Init();
        Entity.Name := 'first';
        Entity.Amount := 1.5;
        Entity.Insert();
        FirstId := Entity.EntityId;
        Assert.IsFalse(IsNullGuid(FirstId), 'Insert must assign a Guid primary key to a CRM row that left it empty');

        Entity.Init();
        Clear(Entity.EntityId);
        Entity.Name := 'second';
        Entity.Insert();
        SecondId := Entity.EntityId;
        Assert.IsFalse(IsNullGuid(SecondId), 'the second Insert must also get a Guid');
        Assert.AreNotEqual(FirstId, SecondId, 'each Insert must get its own Guid');

        PresetId := CreateGuid();
        Entity.Init();
        Entity.EntityId := PresetId;
        Entity.Name := 'preset';
        Entity.Insert();
        Assert.AreEqual(PresetId, Entity.EntityId, 'a caller-supplied Guid primary key must be kept');

        Assert.IsTrue(Found.Get(FirstId), 'Get by the assigned Guid must find the first row');
        Assert.AreEqual('first', Found.Name, 'the row read back must carry the inserted Name');
        Assert.AreEqual(1.5, Found.Amount, 'the row read back must carry the inserted Amount');
        Assert.AreEqual(3, Found.Count(), 'all three rows must be visible through the same CRM table');

        Found.DeleteAll();
        Assert.AreEqual(0, Found.Count(), 'DeleteAll must empty the CRM table');

        UnregisterTableConnection(TableConnectionType::CRM, ConnectionNameTok);
    end;

    [Test]
    procedure Record_Insert_CrmTable_NoConnection_Throws()
    // CLAIM: touching a TableType = CRM table with no CRM table connection registered throws
    //        the platform's "must be registered using RegisterTableConnection" error.
    begin
        Initialize();

        Assert.IsFalse(HasTableConnection(TableConnectionType::CRM, ConnectionNameTok),
            'precondition: no CRM connection registered');

        // The record variable lives inside InsertRow: a CRM record is bound to its
        // connection's data access when the variable is first touched, so the touch must be
        // inside the asserterror rather than at this procedure's entry.
        asserterror InsertRow('orphan');
        Assert.ExpectedError('must be registered using RegisterTableConnection');
    end;

    local procedure InsertRow(Name: Text[100])
    var
        Entity: Record "ALT CRM Entity";
    begin
        Entity.Init();
        Entity.Name := Name;
        Entity.Insert();
    end;

    local procedure RegisterTestConnection()
    begin
        RegisterTableConnection(TableConnectionType::CRM, ConnectionNameTok, TestConnectionStringTok);
        SetDefaultTableConnection(TableConnectionType::CRM, ConnectionNameTok);
    end;

    local procedure Initialize()
    begin
        // Table connections are session state and survive a failed earlier test. Unregistering
        // also discards the test provider's rows, so no DeleteAll() is reachable — or needed —
        // without a connection.
        if HasTableConnection(TableConnectionType::CRM, ConnectionNameTok) then
            UnregisterTableConnection(TableConnectionType::CRM, ConnectionNameTok);
    end;
}
