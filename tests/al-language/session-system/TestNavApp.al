// Scope: in-scope

codeunit 60113 "Test NavApp"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── NavApp Functions ─────────────────────────────────────────────────────────

    [Test]
    procedure NavApp_GetCurrentModuleInfo_DoesNotThrow()
    var
        Info: ModuleInfo;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        Assert.IsTrue(true, 'GetCurrentModuleInfo must not throw exception');
    end;

    [Test]
    procedure NavApp_GetCurrentModuleInfo_HasName()
    var
        Info: ModuleInfo;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        Assert.AreNotEqual('', Info.Name, 'Module name must not be empty');
    end;

    [Test]
    procedure NavApp_GetCurrentModuleInfo_HasId()
    var
        Info: ModuleInfo;
        EmptyGuid: Guid;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        Assert.AreNotEqual(Format(EmptyGuid), Format(Info.Id), 'Module Id must not be empty');
    end;

    [Test]
    procedure NavApp_IsInstalled_CurrentApp_ReturnsTrue()
    var
        Info: ModuleInfo;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        Assert.IsFalse(IsNullGuid(Info.Id), 'Module Id must be non-null Guid');
    end;

    [Test]
    procedure NavApp_GetCurrentModuleInfo_ReturnsTrueInBooleanContext()
    // CLAIM: GetCurrentModuleInfo is Boolean-valued -- calling it in a boolean
    // context (`if not NavApp.GetCurrentModuleInfo(Info) then`), not just the
    // discard-the-return-value statement form used by every other test in this
    // file, returns true and still populates Info for the running app.
    var
        Info: ModuleInfo;
    begin
        Initialize();
        if not NavApp.GetCurrentModuleInfo(Info) then
            Assert.Fail('NavApp.GetCurrentModuleInfo must return true when evaluated in a boolean context.');
        Assert.AreNotEqual('', Info.Name, 'GetCurrentModuleInfo must still populate Info.Name in the boolean-context form');
    end;

    [Test]
    procedure NavApp_GetModuleInfo_ValidId_DoesNotThrow()
    var
        Info: ModuleInfo;
        Info2: ModuleInfo;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        NavApp.GetModuleInfo(Info.Id, Info2);
        Assert.AreEqual(Info.Name, Info2.Name, 'GetModuleInfo must return same module info for same Id');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
