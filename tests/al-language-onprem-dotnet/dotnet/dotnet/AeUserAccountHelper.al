// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99000
// Probe: al-runtime-rs corpus topic 203 item 3 (corpus issue 632): the System Application codeunit "Azure AD Graph User" (IsUserDelegatedAdmin, IsUserDelegatedHelpdesk), which
//   calls the DotNet class Microsoft.Dynamics.Nav.NavUserAccount.NavUserAccountHelper, called from a test session. The class itself cannot be declared here:
//   the CI compile finds no assembly named Microsoft.Dynamics.Nav.NavUserAccount in its probing paths (AL0451).
// BC versions: 27, 28, 29
codeunit 99000 "LT AE UserAccountHelper"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure Codeunit_AzureADGraphUser_Delegated()
    var
        GraphUser: Codeunit "Azure AD Graph User";
    begin
        Observer.Observe('graph delegated admin', Format(GraphUser.IsUserDelegatedAdmin()));
        Observer.Observe('graph delegated helpdesk', Format(GraphUser.IsUserDelegatedHelpdesk()));
        Observer.Expect('graph delegated admin', 'No');
        Observer.Expect('graph delegated helpdesk', 'No');
        Observer.Verify();
    end;
}
