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
//   14. NavTenantSettingsHelper.GetRingName(), which "Environment Information Impl.".IsPreview / IsEarlyPreview compare with
//       'PREVIEW', 'EARLYPREVIEW' and 'EARLYPREV' (AL Runner issue 6675: the role-center pages "SO Processor Activities" and
//       "O365 Activities" reach it in OnOpenPage through ShowEarlyPreviewNotification).
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

    [TryFunction]
    local procedure TryRingName(var Shown: Text)
    var
        Helper: DotNet LtBbTenantSettings;
        Value: Text;
    begin
        Value := Helper.GetRingName();
        Shown := '[' + Value + ']';
    end;

    [Test]
    procedure TenantSettings_GetRingName()
    var
        Shown: Text;
    begin
        if TryRingName(Shown) then
            Observer.Observe('ring name', Shown)
        else
            Observer.ObserveError('ring name');
        // Measured on BC 28.5 and 29.0 OnPrem (corpus PR 1211 CI): GetRingName returns an empty text.
        Observer.Expect('ring name', '[]');
        Observer.Verify();
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

    // al-runner issue 6925: TryGetStringTenantSetting for the setting names of a tenant (the Mount-NAVTenant settings and the
    // names System Application reads), in three spellings for DatabaseServer. The value is tier data: only whether the call
    // finds the name, whether the out value is empty, and whether two spellings give the same value are observed.
    [TryFunction]
    local procedure TryTenantSettingRaw(Name: Text; var Found: Boolean; var Value: Text)
    var
        Helper: DotNet LtBbTenantSettings;
    begin
        Found := Helper.TryGetStringTenantSetting(Name, Value);
    end;

    local procedure ObserveTenantSettingShape(Name: Text)
    var
        Value: Text;
        Found: Boolean;
        Shape: Text;
    begin
        Value := 'unchanged';
        if not TryTenantSettingRaw(Name, Found, Value) then begin
            Observer.Observe('shape ' + Name, 'error: ' + GetLastErrorText());
            exit;
        end;
        case Value of
            '':
                Shape := 'empty';
            'unchanged':
                Shape := 'unchanged';
            else
                Shape := 'non-empty';
        end;
        Observer.Observe('shape ' + Name, Format(Found) + '|' + Shape);
    end;

    local procedure TenantSettingValue(Name: Text): Text
    var
        Value: Text;
        Found: Boolean;
    begin
        if not TryTenantSettingRaw(Name, Found, Value) then
            exit('error');
        exit(Value);
    end;

    [Test]
    procedure TenantSettings_TryGetStringTenantSetting_SettingNames()
    begin
        ObserveTenantSettingShape('DatabaseServer');
        ObserveTenantSettingShape('DATABASESERVER');
        ObserveTenantSettingShape('databaseserver');
        ObserveTenantSettingShape('DatabaseName');
        ObserveTenantSettingShape('DatabaseInstance');
        ObserveTenantSettingShape('DefaultCompany');
        ObserveTenantSettingShape('DefaultTimeZone');
        ObserveTenantSettingShape('AlternateId');
        ObserveTenantSettingShape('AllowAppDatabaseWrite');
        ObserveTenantSettingShape('NasServicesEnabled');
        ObserveTenantSettingShape('EnvironmentName');
        ObserveTenantSettingShape('EnvironmentType');
        ObserveTenantSettingShape('ApplicationFamily');
        ObserveTenantSettingShape('ApplicationVersion');
        ObserveTenantSettingShape('TenantType');
        ObserveTenantSettingShape('State');
        ObserveTenantSettingShape('AadTenantId');
        ObserveTenantSettingShape('TenantId');
        ObserveTenantSettingShape('DisplayName');
        ObserveTenantSettingShape('');
        Observer.Observe('DatabaseServer spellings equal', Format((TenantSettingValue('DatabaseServer') = TenantSettingValue('DATABASESERVER')) and (TenantSettingValue('DatabaseServer') = TenantSettingValue('databaseserver'))));
        Observer.Expect('shape DatabaseServer', 'No|empty');
        Observer.Expect('shape DATABASESERVER', 'No|empty');
        Observer.Expect('shape databaseserver', 'No|empty');
        Observer.Expect('shape DatabaseName', 'No|empty');
        Observer.Expect('shape DatabaseInstance', 'No|empty');
        Observer.Expect('shape DefaultCompany', 'No|empty');
        Observer.Expect('shape DefaultTimeZone', 'No|empty');
        Observer.Expect('shape AlternateId', 'No|empty');
        Observer.Expect('shape AllowAppDatabaseWrite', 'No|empty');
        Observer.Expect('shape NasServicesEnabled', 'No|empty');
        Observer.Expect('shape EnvironmentName', 'No|empty');
        Observer.Expect('shape EnvironmentType', 'No|empty');
        Observer.Expect('shape ApplicationFamily', 'No|empty');
        Observer.Expect('shape ApplicationVersion', 'No|empty');
        Observer.Expect('shape TenantType', 'No|empty');
        Observer.Expect('shape State', 'No|empty');
        Observer.Expect('shape AadTenantId', 'Yes|non-empty');
        Observer.Expect('shape TenantId', 'Yes|non-empty');
        Observer.Expect('shape DisplayName', 'Yes|empty');
        Observer.Expect('shape ', 'No|empty');
        Observer.Expect('DatabaseServer spellings equal', 'Yes');
        Observer.Verify();
    end;
}
