// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet) whose compile finds the BC service tier assemblies (ci.yml passes
//   assembly_probing_paths for this suite), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99221
// Probe: corpus issue 653 items 11-13, the platform helpers the System Application reaches through DotNet
//   (BCApps System Application: Environment Information/src/EnvironmentInformationImpl.Codeunit.al, TenantInformationImpl.Codeunit.al,
//   Azure AD Tenant/src/AzureADTenantImpl.Codeunit.al):
//   11. NavTenantSettingsHelper.GetEnvironmentApplicationSetting(Name) for three names that were never set;
//   12. NavTestExecution.IsInTestMode() inside OnRun of a test codeunit (before the first test method) and inside a test method.
//       The install-codeunit half of the item is not probed: the corpus apps may not carry install codeunits (check-install-triggers.py);
//   13. NavTenantSettingsHelper.TryGetStringTenantSetting(Name, Value) for TENANTID, DISPLAYNAME, AADTENANTID and an unknown name:
//       the Boolean and the out value.
//   Observed on the corpus CI matrix (single-tenant Linux container, tenant 'default'): an unset application setting reads as empty text,
//   also for an empty name; IsInTestMode is true in OnRun and in a test method; TENANTID = default, DISPLAYNAME = empty (found),
//   AADTENANTID = common, an unknown name gives false and clears the out value.
// BC versions: 27, 28, 29
dotnet
{
    assembly("Microsoft.Dynamics.Nav.NavUserAccount")
    {
        type("Microsoft.Dynamics.Nav.NavUserAccount.NavTenantSettingsHelper"; LtBbTenantSettings) { }
    }

    assembly("Microsoft.Dynamics.Nav.Ncl")
    {
        type("Microsoft.Dynamics.Nav.Runtime.NavTestExecution"; LtBbTestExecution) { }
    }
}

codeunit 99221 "LT BB Nav Helpers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        InOnRun: Text;

    // The test runner runs OnRun before the first test method, on the same instance (the globals of a test codeunit persist across its tests).
    trigger OnRun()
    begin
        if TryInTestMode(InOnRun) then;
        if InOnRun = '' then
            InOnRun := 'error: ' + GetLastErrorText();
    end;

    [TryFunction]
    local procedure TryInTestMode(var Shown: Text)
    var
        Execution: DotNet LtBbTestExecution;
    begin
        Shown := Format(Execution.IsInTestMode());
    end;

    [TryFunction]
    local procedure TryAppSetting(Name: Text; var Shown: Text)
    var
        Helper: DotNet LtBbTenantSettings;
        Value: Text;
    begin
        Value := Helper.GetEnvironmentApplicationSetting(Name);
        Shown := '[' + Value + ']';
    end;

    [TryFunction]
    local procedure TryTenantSetting(Name: Text; var Shown: Text)
    var
        Helper: DotNet LtBbTenantSettings;
        Value: Text;
        Found: Boolean;
    begin
        Value := 'unchanged';
        Found := Helper.TryGetStringTenantSetting(Name, Value);
        Shown := Format(Found) + '|[' + Value + ']';
    end;

    local procedure ObserveAppSetting(Name: Text)
    var
        Shown: Text;
    begin
        if TryAppSetting(Name, Shown) then
            Observer.Observe('app setting ' + Name, Shown)
        else
            Observer.ObserveError('app setting ' + Name);
    end;

    local procedure ObserveTenantSetting(Name: Text)
    var
        Shown: Text;
    begin
        if TryTenantSetting(Name, Shown) then
            Observer.Observe('tenant setting ' + Name, Shown)
        else
            Observer.ObserveError('tenant setting ' + Name);
    end;

    [Test]
    procedure TenantSettings_GetEnvironmentApplicationSettingUnset()
    begin
        ObserveAppSetting('LtBbNeverSet');
        ObserveAppSetting('LT BB NEVER SET 2');
        ObserveAppSetting('');
        Observer.Expect('app setting LtBbNeverSet', '[]');
        Observer.Expect('app setting LT BB NEVER SET 2', '[]');
        Observer.Expect('app setting ', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure TestExecution_IsInTestMode()
    var
        Shown: Text;
    begin
        if InOnRun = '' then
            InOnRun := 'OnRun did not run before this test';
        Observer.Observe('in OnRun', InOnRun);
        if TryInTestMode(Shown) then
            Observer.Observe('in test method', Shown)
        else
            Observer.ObserveError('in test method');
        Observer.Expect('in OnRun', 'Yes');
        Observer.Expect('in test method', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TenantSettings_TryGetStringTenantSetting()
    begin
        ObserveTenantSetting('TENANTID');
        ObserveTenantSetting('DISPLAYNAME');
        ObserveTenantSetting('AADTENANTID');
        ObserveTenantSetting('LTBBNOSUCHSETTING');
        // The out value of an unknown name is cleared: 'unchanged' before the call, empty after it.
        Observer.Expect('tenant setting TENANTID', 'Yes|[default]');
        Observer.Expect('tenant setting DISPLAYNAME', 'Yes|[]');
        Observer.Expect('tenant setting AADTENANTID', 'Yes|[common]');
        Observer.Expect('tenant setting LTBBNOSUCHSETTING', 'No|[]');
        Observer.Verify();
    end;
}
