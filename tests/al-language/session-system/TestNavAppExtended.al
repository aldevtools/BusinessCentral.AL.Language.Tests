// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/navapp/navapp-data-type
// Scope: in-scope

codeunit 60136 "Test NavApp Extended"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure NavApp_GetCallerModuleInfo_IsCallable()
    var
        Info: ModuleInfo;
        B: Boolean;
    begin
        Initialize();
        B := NavApp.GetCallerModuleInfo(Info);
        Assert.IsTrue(true, 'GetCallerModuleInfo must be callable without throwing');
    end;

    [Test]
    procedure NavApp_IsInstalling_ReturnsFalse()
    begin
        Initialize();
        Assert.IsFalse(NavApp.IsInstalling(), 'NavApp must not be in installing state during test run');
    end;

    [Test]
    procedure NavApp_IsEntitled_IsCallable()
    var
        B: Boolean;
    begin
        Initialize();
        B := NavApp.IsEntitled('unknown-feature-id');
        Assert.IsTrue(true, 'IsEntitled must be callable and return Boolean');
    end;

    [Test]
    procedure NavApp_GetResourceAsText_NonexistentResource_Throws()
    var
        T: Text;
    begin
        Initialize();
        asserterror T := NavApp.GetResourceAsText('nonexistent.txt');
        Assert.IsTrue(true, 'GetResourceAsText must throw for nonexistent resource');
    end;

    [Test]
    procedure NavApp_GetCurrentModuleInfo_PopulatesName()
    var
        Info: ModuleInfo;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        Assert.AreNotEqual('', Info.Name, 'GetCurrentModuleInfo must populate a non-empty module name');
    end;

    [Test]
    procedure NavApp_GetCurrentModuleInfo_AppVersion_IsCallable()
    var
        Info: ModuleInfo;
        Ver: Version;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        Ver := Info.AppVersion();
        Assert.IsTrue(true, 'ModuleInfo.AppVersion() must be callable');
    end;

    [Test]
    procedure NavApp_GetCurrentModuleInfo_Dependencies_IsCallable()
    var
        Info: ModuleInfo;
        Deps: List of [ModuleDependencyInfo];
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        Deps := Info.Dependencies();
        Assert.IsTrue(true, 'ModuleInfo.Dependencies() must be callable');
    end;

    [Test]
    procedure NavApp_GetCurrentModuleInfo_PackageId_NonNull()
    var
        Info: ModuleInfo;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        Assert.IsFalse(IsNullGuid(Info.PackageId()), 'PackageId must not be null Guid');
    end;

    [Test]
    procedure NavApp_GetModuleInfo_CurrentApp_MatchesCurrentModuleInfo()
    var
        Info: ModuleInfo;
        Info2: ModuleInfo;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        NavApp.GetModuleInfo(Info.Id, Info2);
        Assert.AreEqual(Info.Name, Info2.Name, 'GetModuleInfo by Id must return same module name');
    end;

    [Test]
    procedure NavApp_GetModuleInfo_CurrentApp_BooleanForm_ReturnsTrue()
    var
        Info: ModuleInfo;
        Info2: ModuleInfo;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        Assert.IsTrue(NavApp.GetModuleInfo(Info.Id, Info2), 'GetModuleInfo boolean form must return true for an installed app id');
        Assert.AreEqual(Info.Name, Info2.Name, 'GetModuleInfo boolean form must populate the module name');
    end;

    // The unknown id must not be the null GUID: BC answers GetModuleInfo(Guid.Empty) with
    // true and a synthesized Microsoft module, so a null id would invert these tests.
    [Test]
    procedure NavApp_GetModuleInfo_UnknownId_StatementForm_RaisesNamingTheId()
    var
        Info: ModuleInfo;
    begin
        Initialize();
        asserterror NavApp.GetModuleInfo('00000000-dead-beef-0000-000000000002', Info);
        Assert.ExpectedError('00000000-dead-beef-0000-000000000002');
    end;

    [Test]
    procedure NavApp_GetModuleInfo_UnknownId_StatementForm_RaisesNotInstalledMessage()
    var
        Info: ModuleInfo;
    begin
        Initialize();
        asserterror NavApp.GetModuleInfo('00000000-dead-beef-0000-000000000003', Info);
        Assert.ExpectedError('No installed extension was found with ID');
    end;

    [Test]
    procedure NavApp_GetModuleInfo_UnknownId_BooleanForm_ReturnsFalseWithoutRaising()
    var
        Info: ModuleInfo;
    begin
        Initialize();
        ClearLastError();
        Assert.IsFalse(NavApp.GetModuleInfo('00000000-dead-beef-0000-000000000004', Info), 'GetModuleInfo boolean form must return false for an id that is not installed');
        Assert.AreEqual('', GetLastErrorText(), 'GetModuleInfo boolean form must not raise for an id that is not installed');
    end;

    [Test]
    procedure NavApp_GetCurrentModuleInfo_Id_NonNull()
    var
        Info: ModuleInfo;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        Assert.IsFalse(IsNullGuid(Info.Id), 'Module Id must not be null Guid');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
