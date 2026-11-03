// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; LT BB Install NavHelper Obs (99222), written by the
//   install codeunit LT BB Install NavHelper Probe (99223) in BbNavHelpersInstall.al; self-contained codeunit 99224
// Probe: corpus issue 653 item 12, install half: reads back what NavTestExecution.IsInTestMode() and
//   NavTenantSettingsHelper.TryGetStringTenantSetting('TENANTID') returned inside OnInstallAppPerCompany while the app was published.
//   Observed on the corpus CI matrix: IsInTestMode is false there (true in OnRun and in a test method, BbNavHelpers.al); TENANTID = default.
// BC versions: 27, 28, 29
codeunit 99224 "LT BB Install NavHelper Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure InstallTrigger_NavHelpers()
    var
        Observation: Record "LT BB Install NavHelper Obs";
    begin
        if Observation.Get('NAVHELPERS') then begin
            Observer.Observe('in test mode', Observation."In Test Mode");
            Observer.Observe('tenant id setting', Observation."Tenant Id Setting");
            Observer.Observe('row written', 'Yes');
        end else
            Observer.Observe('row written', 'No');
        // Observed on 27.5, 28.5 and 29.0: the install trigger is not in test mode (a test method is: BbNavHelpers.al).
        Observer.Expect('in test mode', 'No');
        Observer.Expect('tenant id setting', 'Yes|[default]');
        Observer.Expect('row written', 'Yes');
        Observer.Verify();
    end;
}
