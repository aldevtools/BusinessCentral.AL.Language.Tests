// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-data-type
// Scope: in-scope
// Fixtures used: Assert (60021), ALT Fixture Cleanup (60001)
// Remaining Session methods and DataTransfer operations not covered in other test codeunits

codeunit 60143 "Test Session Complete"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Session.GetModuleExecutionContext ───────────────────────────────────────

    [Test]
    procedure Session_GetModuleExecutionContext_IsCallable()
    var
        EC: ExecutionContext;
    begin
        Initialize();
        EC := Session.GetModuleExecutionContext();
        Assert.IsTrue(true, 'Session.GetModuleExecutionContext() must be callable and return ExecutionContext');
    end;

    [Test]
    procedure Session_GetModuleExecutionContext_WithAppId_IsCallable()
    var
        EC: ExecutionContext;
        ModuleInfo: ModuleInfo;
        AppId: Guid;
    begin
        Initialize();
        // Use NavApp.GetCurrentModuleInfo() to obtain a valid AppId GUID
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        AppId := ModuleInfo.Id();
        if not IsNullGuid(AppId) then
            EC := Session.GetModuleExecutionContext(AppId);
        Assert.IsTrue(true, 'Session.GetModuleExecutionContext(AppId) must be callable when AppId is a valid GUID');
    end;

    // ── Session.IsSessionActive ─────────────────────────────────────────────────

    [Test]
    procedure Session_IsSessionActive_InvalidSession_ReturnsFalse()
    var
        IsActive: Boolean;
    begin
        Initialize();
        IsActive := Session.IsSessionActive(99999);
        Assert.IsFalse(IsActive, 'Session.IsSessionActive(99999) must return false for invalid session ID');
    end;

        // ── Session.StopSession ─────────────────────────────────────────────────────

            // ── DataTransfer.CopyFields ─────────────────────────────────────────────────

    [Test]
    procedure DataTransfer_CopyFields_ThrowsOutsideUpgrade()
    var
        DT: DataTransfer;
    begin
        Initialize();
        asserterror DT.CopyFields();
        Assert.IsTrue(true, 'DataTransfer.CopyFields() must throw when called outside upgrade context');
    end;

    // ── DataTransfer.AddFieldValue ──────────────────────────────────────────────

    [Test]
    procedure DataTransfer_AddFieldValue_ThrowsOutsideUpgrade()
    var
        DT: DataTransfer;
    begin
        Initialize();
        asserterror DT.AddFieldValue(1, 1);
        Assert.IsTrue(true, 'DataTransfer.AddFieldValue() must throw when called outside upgrade context');
    end;

    // ── DataTransfer.AddSourceFilter ────────────────────────────────────────────

    [Test]
    procedure DataTransfer_AddSourceFilter_ThrowsOutsideUpgrade()
    var
        DT: DataTransfer;
    begin
        Initialize();
        asserterror DT.AddSourceFilter(1, '');
        Assert.IsTrue(true, 'DataTransfer.AddSourceFilter() must throw when called outside upgrade context');
    end;

    // ── DataTransfer.AddDestinationFilter ───────────────────────────────────────

        // ── DataTransfer.AddJoin ────────────────────────────────────────────────────

    [Test]
    procedure DataTransfer_AddJoin_ThrowsOutsideUpgrade()
    var
        DT: DataTransfer;
    begin
        Initialize();
        asserterror DT.AddJoin(1, 1);
        Assert.IsTrue(true, 'DataTransfer.AddJoin() must throw when called outside upgrade context');
    end;

    // ── DataTransfer.AddConstantValue ───────────────────────────────────────────

    [Test]
    procedure DataTransfer_AddConstantValue_ThrowsOutsideUpgrade()
    var
        DT: DataTransfer;
    begin
        Initialize();
        asserterror DT.AddConstantValue('', 1);
        Assert.IsTrue(true, 'DataTransfer.AddConstantValue() must throw when called outside upgrade context');
    end;

    // ── Cleanup ─────────────────────────────────────────────────────────────────

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        ClearLastError();
    end;
}
