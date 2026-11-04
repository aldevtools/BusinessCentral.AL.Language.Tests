// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet) whose compile finds the BC service tier assemblies (ci.yml passes
//   assembly_probing_paths for this suite), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: none (the test that reads the observation back is BbNavHelpersInstall_Tests.al, codeunit 99224)
// Probe: corpus issue 653 item 12, install half: what NavTestExecution.IsInTestMode() returns inside OnInstallAppPerCompany of an install
//   codeunit while the app is published. For comparison the codeunit also records NavTenantSettingsHelper.TryGetStringTenantSetting('TENANTID').
//   The test-codeunit half of the item is BbNavHelpers.al (99221).
// Safety (check-install-triggers.py): every DotNet call runs inside a TryFunction that only fills a Text, so a failing call is recorded as
//   'error: <text>' and never leaves the trigger; the row is written with Get before Insert (else Modify), so a second install in the same
//   company does not raise. Per company, like "Install Env Observation": OnInstallAppPerCompany fires once per existing company.
// BC versions: 27, 28, 29
dotnet
{
    assembly("Microsoft.Dynamics.Nav.NavUserAccount")
    {
        type("Microsoft.Dynamics.Nav.NavUserAccount.NavTenantSettingsHelper"; LtBbInstTenantSettings) { }
    }

    assembly("Microsoft.Dynamics.Nav.Ncl")
    {
        type("Microsoft.Dynamics.Nav.Runtime.NavTestExecution"; LtBbInstTestExecution) { }
    }
}

table 99222 "LT BB Install NavHelper Obs"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "In Test Mode"; Text[250]) { }
        field(3; "Tenant Id Setting"; Text[250]) { }
        field(4; "Install Runs"; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 99223 "LT BB Install NavHelper Probe"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Observation: Record "LT BB Install NavHelper Obs";
        InTestMode: Text;
        TenantId: Text;
    begin
        if not TryInTestMode(InTestMode) then
            InTestMode := CopyStr('error: ' + GetLastErrorText(), 1, 250);
        ClearLastError();
        if not TryTenantId(TenantId) then
            TenantId := CopyStr('error: ' + GetLastErrorText(), 1, 250);
        ClearLastError();

        if not Observation.Get('NAVHELPERS') then begin
            Observation.Init();
            Observation."Code" := 'NAVHELPERS';
            Observation.Insert();
        end;
        Observation."In Test Mode" := CopyStr(InTestMode, 1, MaxStrLen(Observation."In Test Mode"));
        Observation."Tenant Id Setting" := CopyStr(TenantId, 1, MaxStrLen(Observation."Tenant Id Setting"));
        Observation."Install Runs" += 1;
        Observation.Modify();
    end;

    [TryFunction]
    local procedure TryInTestMode(var Shown: Text)
    var
        Execution: DotNet LtBbInstTestExecution;
    begin
        Shown := Format(Execution.IsInTestMode());
    end;

    [TryFunction]
    local procedure TryTenantId(var Shown: Text)
    var
        Helper: DotNet LtBbInstTenantSettings;
        Value: Text;
        Found: Boolean;
    begin
        Value := 'unchanged';
        Found := Helper.TryGetStringTenantSetting('TENANTID', Value);
        Shown := Format(Found) + '|[' + Value + ']';
    end;
}
