// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet) whose compile finds the BC service tier assemblies (see BbNavHelpers.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99447
// Probe (values pinned): al-runner issue 7447. Base Application's page "User Card" calls NavTenantSettingsHelper.IsWSKeyAllowed() each time it
//   opens (SetWebServiceAccressKey, from OnOpenPage), so a test that opens the card reaches it. This probe reads it twice, as a value and as a
//   condition, on the corpus CI container.
// BC versions: 27, 28, 29
dotnet
{
    assembly("Microsoft.Dynamics.Nav.NavUserAccount")
    {
        type("Microsoft.Dynamics.Nav.NavUserAccount.NavTenantSettingsHelper"; LtWsTenantSettings) { }
    }
}

codeunit 99447 "LT WS Key Allowed"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure IsWSKeyAllowed_Value()
    var
        Observer: Codeunit "Probe Observer";
        Helper: DotNet LtWsTenantSettings;
        Answer: Text;
    begin
        Answer := Format(Helper.IsWSKeyAllowed());
        if Helper.IsWSKeyAllowed() then
            Answer += ' / condition true'
        else
            Answer += ' / condition false';
        Observer.Observe('result', Answer);
        Observer.Expect('result', 'Yes / condition true');
        Observer.Verify();
    end;
}
