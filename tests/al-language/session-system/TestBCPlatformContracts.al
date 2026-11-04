codeunit 60173 "Test BC Platform Contracts"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        // Mirror of tests/al-language/app.json "version". The manifest and this Label are the
        // same fact written twice, and AL cannot read app.json, so they must be updated
        // together. If the version test below fails, these two have drifted -- look here first.
        AppJsonVersionTok: Label '1.0.0.0', Locked = true;

    local procedure Initialize()
    begin
        Cleanup();
    end;

    local procedure Cleanup()
    begin
    end;

    [Test]
    procedure GuiAllowed_InTestContext_ReturnsTrue()
    begin
        Initialize();
        Assert.IsTrue(
            GuiAllowed(),
            'GuiAllowed() must return true when running in BC test context with test framework'
        );
    end;

    [Test]
    procedure IsServiceTier_InTestContext_ReturnsTrue()
    begin
        Initialize();
        Assert.IsTrue(
            IsServiceTier(),
            'IsServiceTier() must return true when running on BC application server'
        );
    end;

    [Test]
    procedure Session_GetExecutionContext_ReturnsValidEnum()
    var
        EC: ExecutionContext;
    begin
        Initialize();
        EC := Session.GetExecutionContext();
        Assert.IsTrue(
            true,
            'Session.GetExecutionContext() must return without error in test context'
        );
        Assert.AreNotEqual(
            '',
            Format(EC),
            'ExecutionContext must format to non-empty string'
        );
    end;

    [Test]
    procedure NavApp_IsInstalling_ReturnsFalse()
    begin
        Initialize();
        Assert.IsFalse(
            NavApp.IsInstalling(),
            'NavApp.IsInstalling() must return false during normal test execution (not install time)'
        );
    end;

    [Test]
    procedure Session_IsSessionActive_CurrentSession()
    begin
        Initialize();
        Assert.IsFalse(
            Session.IsSessionActive(99999),
            'Session 99999 must not be active'
        );
    end;

    [Test]
    procedure NavApp_GetCurrentModuleInfo_IdMatchesAppJson()
    var
        Info: ModuleInfo;
        ExpectedId: Guid;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        Evaluate(ExpectedId, '{a1b2c3d4-e5f6-7890-abcd-ef1234567890}');
        Assert.AreEqual(
            Format(ExpectedId),
            Format(Info.Id),
            'NavApp.GetCurrentModuleInfo().Id must match app.json "id" field'
        );
    end;

    [Test]
    procedure NavApp_GetCurrentModuleInfo_NameMatchesAppJson()
    var
        Info: ModuleInfo;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        Assert.AreEqual(
            'AL Language Coverage Tests',
            Info.Name,
            'Module name must match app.json "name" field'
        );
    end;

    // The expected version is no longer written into this test's name. It used to be
    // (IsOneOhOhOh), which made the identifier itself wrong the moment anyone bumped the
    // manifest and gave a reader no hint that app.json was the thing to change.
    //
    // The literal stays, because here it cannot be derived. The OnPrem app checks this same
    // claim by comparing two independent surfaces -- the "Published Application" row against
    // ModuleInfo -- but that table is Scope = OnPrem and a Target = Cloud app cannot name it.
    // In this app ModuleInfo is the only surface that reports the app's own version, so
    // deriving the expectation from it would compare it to itself and assert nothing. What
    // changed is that the value now lives in one named Label next to a comment naming
    // app.json, and the failure message says what to update.
    [Test]
    procedure NavApp_GetCurrentModuleInfo_AppVersion_MatchesAppJsonManifest()
    var
        Info: ModuleInfo;
        Ver: Version;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        Ver := Info.AppVersion();
        Assert.AreEqual(
            AppJsonVersionTok,
            Format(Ver),
            'AppVersion must match app.json "version" -- if the manifest was bumped, update AppJsonVersionTok to match'
        );
    end;

    [Test]
    procedure NavApp_GetCurrentModuleInfo_PackageId_NonNull()
    var
        Info: ModuleInfo;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        Assert.IsFalse(
            IsNullGuid(Info.PackageId()),
            'PackageId must be a non-null GUID (assigned by BC at deployment)'
        );
    end;

    [Test]
    procedure CompanyProperty_DisplayName_NonEmpty()
    begin
        Initialize();
        Assert.AreNotEqual(
            '',
            CompanyProperty.DisplayName(),
            'CompanyProperty.DisplayName() must return non-empty company name'
        );
    end;

    [Test]
    procedure CompanyProperty_UrlName_NonEmpty()
    begin
        Initialize();
        Assert.AreNotEqual(
            '',
            CompanyProperty.UrlName(),
            'CompanyProperty.UrlName() must return non-empty URL-safe company name'
        );
    end;

    [Test]
    procedure CompanyProperty_UrlName_IsUrlSafe()
    var
        UrlName: Text;
    begin
        Initialize();
        UrlName := CompanyProperty.UrlName();
        Assert.IsFalse(
            StrPos(UrlName, ' ') > 0,
            'CompanyProperty.UrlName() must not contain spaces (URL-safe format)'
        );
    end;

    [Test]
    procedure CompanyName_MatchesCurrentCompany()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Assert.AreEqual(
            CompanyName(),
            Rec.CurrentCompany(),
            'CompanyName() must equal Record.CurrentCompany() in current context'
        );
    end;

    [Test]
    procedure WindowsLanguage_ReturnsPositiveId()
    var
        LangId: Integer;
    begin
        Initialize();
        LangId := WindowsLanguage();
        Assert.IsTrue(
            LangId > 0,
            'WindowsLanguage() must return a positive language ID in server context'
        );
    end;
}
