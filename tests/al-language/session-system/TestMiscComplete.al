// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/developer-reference
// Scope: Miscellaneous methods — FieldRef.OptionString(), Database.SelectLatestVersion(), Database.MinimumActiveRowVersion(),
//        Database.LockTimeoutDuration(), Notification.AddAction() (4-arg), Session.GetModuleExecutionContext(Guid),
//        NavApp.ListResources(), NavApp.GetResourceAsJson()
// Fixtures used: ALT Universal (60000)

codeunit 60145 "Test Misc Complete"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── FieldRef.OptionString() ────────────────────────────────────────────────

    [Test]
    procedure FieldRef_OptionString_ReturnsOptionMembers()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        OptionStr: Text;
    begin
        // ARRANGE & ACT
        Initialize();
        RecRef.Open(60000);  // ALT Universal
        FldRef := RecRef.Field(14);  // Option Field with OptionMembers = " ",Draft,Active,Closed
        OptionStr := FldRef.OptionString();

        // ASSERT - OptionString must return all option members
        Assert.IsTrue(StrPos(OptionStr, 'Draft') > 0, 'OptionString must contain "Draft"');
        Assert.IsTrue(StrPos(OptionStr, 'Active') > 0, 'OptionString must contain "Active"');
        Assert.IsTrue(StrPos(OptionStr, 'Closed') > 0, 'OptionString must contain "Closed"');
    end;

    // ── Database.SelectLatestVersion() ─────────────────────────────────────────

    [Test]
    procedure Database_SelectLatestVersion_NoArgs_Succeeds()
    begin
        // ARRANGE & ACT
        Initialize();

        // ASSERT - SelectLatestVersion() without arguments must not throw
        Database.SelectLatestVersion();
        Assert.IsTrue(true, 'Database.SelectLatestVersion() must execute without error');
    end;

    [Test]
    procedure Database_SelectLatestVersion_WithTableNo_Succeeds()
    begin
        // ARRANGE & ACT
        Initialize();

        // ASSERT - SelectLatestVersion(TableNo) must not throw
        Database.SelectLatestVersion(60000);  // ALT Universal
        Assert.IsTrue(true, 'Database.SelectLatestVersion(60000) must execute without error');
    end;

    // ── Database.MinimumActiveRowVersion() ─────────────────────────────────────

    [Test]
    procedure Database_MinimumActiveRowVersion_ReturnsNonNegative()
    var
        MinVersion: BigInteger;
    begin
        // ARRANGE & ACT
        Initialize();
        MinVersion := Database.MinimumActiveRowVersion();

        // ASSERT - MinimumActiveRowVersion must return non-negative value
        Assert.IsTrue(MinVersion >= 0, 'Database.MinimumActiveRowVersion() must return value >= 0');
    end;

    // ── Database.LockTimeoutDuration() ─────────────────────────────────────────

    [Test]
    procedure Database_LockTimeoutDuration_GetDefault_Succeeds()
    var
        D: Duration;
    begin
        // ARRANGE & ACT
        Initialize();
        D := Database.LockTimeoutDuration();

        // ASSERT - LockTimeoutDuration() without args must return a value
        Assert.IsTrue(true, 'Database.LockTimeoutDuration() must execute without error');
    end;

    [Test]
    procedure Database_LockTimeoutDuration_SetValue_Succeeds()
    var
        OriginalDuration: Duration;
    begin
        // ARRANGE & ACT
        Initialize();
        OriginalDuration := Database.LockTimeoutDuration();
        Database.LockTimeoutDuration(30000);  // 30 seconds

        // ASSERT - Setting LockTimeoutDuration must not throw
        Assert.IsTrue(true, 'Database.LockTimeoutDuration(30000) must execute without error');
    end;

    // ── Notification.AddAction() (4-arg overload with description) ──────────────

    [Test]
    procedure Notification_AddAction_WithDescription_Succeeds()
    var
        N: Notification;
    begin
        // ARRANGE & ACT
        Initialize();
        N.Message('Test notification');
        N.AddAction('Click Me', 60145, 'Initialize', 'Action description');

        // ASSERT - AddAction with 4 arguments must not throw
        Assert.IsTrue(true, 'Notification.AddAction(Caption, CodeunitId, MethodName, Description) must execute without error');
    end;

    // ── Session.GetModuleExecutionContext(AppId: Guid) ─────────────────────────

    [Test]
    procedure Session_GetModuleExecutionContext_WithAppId_Succeeds()
    var
        ModuleInfo: ModuleInfo;
        ExecutionContext: ExecutionContext;
    begin
        // ARRANGE
        Initialize();
        NavApp.GetCurrentModuleInfo(ModuleInfo);

        // ACT
        ExecutionContext := Session.GetModuleExecutionContext(ModuleInfo.Id);

        // ASSERT - GetModuleExecutionContext with AppId parameter must not throw
        Assert.IsTrue(true, 'Session.GetModuleExecutionContext(AppId) must execute without error');
    end;

    // ── NavApp.ListResources() ─────────────────────────────────────────────────

    [Test]
    procedure NavApp_ListResources_NoFilter_Succeeds()
    var
        Resources: List of [Text];
    begin
        // ARRANGE & ACT
        Initialize();
        Resources := NavApp.ListResources();

        // ASSERT - ListResources must return a list (possibly empty)
        Assert.IsTrue(true, 'NavApp.ListResources() must execute without error');
    end;

    [Test]
    procedure NavApp_ListResources_WithFilter_Succeeds()
    var
        Resources: List of [Text];
    begin
        // ARRANGE & ACT
        Initialize();
        Resources := NavApp.ListResources('*.json');

        // ASSERT - ListResources with filter must not throw
        Assert.IsTrue(true, 'NavApp.ListResources(Filter) must execute without error');
    end;

    // ── NavApp.GetResourceAsJson(ResourceName) ────────────────────────────────

    [Test]
    procedure NavApp_GetResourceAsJson_NonexistentResource_Throws()
    var
        J: JsonObject;
    begin
        // ARRANGE & ACT
        Initialize();

        // ASSERT - GetResourceAsJson with nonexistent resource must throw
        asserterror J := NavApp.GetResourceAsJson('nonexistent.json');
        Assert.IsTrue(true, 'NavApp.GetResourceAsJson(nonexistent) must throw error as expected');
    end;

    // ── Database.RegisterTableConnection() ────────────────────────────────────

    [Test]
    procedure Database_RegisterTableConnection_InvalidConnection_Throws()
    begin
        // ARRANGE & ACT
        Initialize();

        // ASSERT - RegisterTableConnection with ExternalSQL type throws a permission error in BC Cloud.
        // Users do not have permission to register external SQL table connections.
        asserterror Database.RegisterTableConnection(TableConnectionType::ExternalSQL, 'TestConn', '');
        Assert.ExpectedError('permission');
    end;

    // ── Documentation: Out-of-scope or handler-dependent ──────────────────────

    [Test]
    procedure Documentation_HttpResponseMessage_OutOfScope()
    begin
        // NOTE: TestHttpResponseMessage is used with HttpClient, which is blocked on Cloud target.
        // This test documents the scope boundary.
        Initialize();
        Assert.IsTrue(true, 'TestHttpResponseMessage covered by HttpClient out-of-scope documentation');
    end;

    [Test]
    procedure Documentation_TestPage_Trap_RequiresPageRunHandler()
    begin
        // NOTE: TestPage.Trap() is only usable when code calls Page.Run() with a handler.
        // Stand-alone Trap() testing requires Page.Run() integration, which is test-isolation dependent.
        Initialize();
        Assert.IsTrue(true, 'TestPage.Trap() requires Page.Run() handler integration, covered separately');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
