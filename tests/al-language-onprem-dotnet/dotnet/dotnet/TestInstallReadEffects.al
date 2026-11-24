// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// Scope: install versus test session reads; fourteen per-company/per-database observations, across BC27.5/28.5/29.0.
// Fixtures: INST Read Observation (99464), INST Read Capture (99465), Assert (60021).
// Existing ordinary-session coverage: AeUserAccountHelper.al, TestServerSettingContracts.al,
// DateFuncs.al, TestDateVirtualTableFlowField.al, BaFeatureKeyTexts.al and PlTTaskScheduler.al.
// New claim: the recorded values originate in the install context, not the test context.
codeunit 99466 "INST Read Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Saved: Record "INST Read Observation" temporary;
        Loaded: Boolean;
        Assert: Codeunit Assert;

    [Test]
    procedure Install_DelegatedPredicates_AreFalse()
    begin
        Initialize();
        Assert.AreEqual('false|false', Seen(1), 'Delegated identity in install context');
    end;

    [Test]
    procedure Install_EntraGroupsSetting_IsDisabled()
    begin
        Initialize();
        Assert.AreEqual('false', Seen(2), 'Entra groups are disabled in this CI configuration');
    end;

    [Test]
    procedure Install_CalendarExplicitParts_PreserveLeapDay()
    begin
        Initialize();
        Assert.AreEqual('2024-02-29|29|2|2024', Seen(3), 'Explicit date arguments');
    end;

    [Test]
    procedure Install_VirtualDate_ContainsLeapDay()
    begin
        Initialize();
        Assert.AreEqual('1|2024-02-29', Seen(4), 'Filtered virtual date row');
    end;

    [Test]
    procedure Install_FeatureKey_ContainsNamedMetadata()
    begin
        Initialize();
        Assert.AreEqual('SalesPrices|1|true', Seen(5), 'Named feature row and description');
    end;

    [Test]
    procedure Install_TaskCapability_IsDistinctFromTestContext()
    begin
        Initialize();
        Assert.AreEqual('true', Seen(6), 'Capability while installing');
        Assert.IsFalse(TaskScheduler.CanCreateTask(), 'Capability in isolated test context');
    end;

    [Test]
    procedure Install_CalendarOmittedParts_UseToday()
    begin
        Initialize();
        Assert.AreEqual('true|true', Seen(7), 'Omitted parts use Today, despite a different WorkDate');
    end;

    local procedure Seen(Kind: Integer): Text
    var
        Observation: Record "INST Read Observation";
    begin
        Assert.IsTrue(Observation.Get(CopyStr(CompanyName(), 1, 30), Format(Kind)), 'Install observation must exist');
        Assert.AreEqual('', Observation.Failure, 'Install probe must complete');
        exit(Observation.Result);
    end;

    local procedure SeenFrom(ScopeCompany: Text[30]; Kind: Integer): Text
    var
        Observation: Record "INST Read Observation";
    begin
        Assert.IsTrue(Observation.Get(ScopeCompany, Format(Kind)), 'Install observation must exist');
        Assert.AreEqual('', Observation.Failure, 'Install probe must complete');
        exit(Observation.Result);
    end;

    local procedure Initialize()
    var
        Observation: Record "INST Read Observation";
    begin
        if not Loaded then begin
            if Observation.FindSet() then
                repeat
                    Saved := Observation;
                    Saved.Insert(false);
                until Observation.Next() = 0;
            Loaded := true;
        end;
        Observation.DeleteAll();
        if Saved.FindSet() then
            repeat
                Observation := Saved;
                Observation.Insert(false);
            until Saved.Next() = 0;
    end;

    [Test]
    procedure InstallDatabase_DelegatedPredicates_AreFalse()
    begin
        Initialize();
        Assert.AreEqual('false|false', SeenFrom('<database>', 1), 'Per-database installation observation');
    end;

    [Test]
    procedure InstallDatabase_EntraGroupsSetting_IsDisabled()
    begin
        Initialize();
        Assert.AreEqual('false', SeenFrom('<database>', 2), 'Per-database installation observation');
    end;

    [Test]
    procedure InstallDatabase_CalendarExplicitParts_PreserveLeapDay()
    begin
        Initialize();
        Assert.AreEqual('2024-02-29|29|2|2024', SeenFrom('<database>', 3), 'Per-database installation observation');
    end;

    [Test]
    procedure InstallDatabase_VirtualDate_ContainsLeapDay()
    begin
        Initialize();
        Assert.AreEqual('1|2024-02-29', SeenFrom('<database>', 4), 'Per-database installation observation');
    end;

    [Test]
    procedure InstallDatabase_FeatureKey_ContainsNamedMetadata()
    begin
        Initialize();
        Assert.AreEqual('SalesPrices|1|true', SeenFrom('<database>', 5), 'Per-database installation observation');
    end;

    [Test]
    procedure InstallDatabase_TaskCapability_IsAvailable()
    begin
        Initialize();
        Assert.AreEqual('true', SeenFrom('<database>', 6), 'Per-database installation observation');
    end;

    [Test]
    procedure InstallDatabase_CalendarOmittedParts_UseToday()
    begin
        Initialize();
        Assert.AreEqual('true|true', SeenFrom('<database>', 7), 'Per-database installation observation');
    end;
}
