// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/users-credential-types
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 90987 (writer Y5); System Application codeunits "Identity Management" (9801)
//   and "Environment Information" (457)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: al-runner issue 6380. Identity Management.IsUserNamePasswordAuthentication (the only one of the three credential-type
//   members that a Cloud app can call; IsWindowsAuthentication and IsAccessControlServiceAuthentication are Scope OnPrem, see
//   tests/al-language-onprem/lt-y5/Y5AuthenticationTypeOnPrem.al) answers the service tier's ClientServicesCredentialType.
//   The answer differs per environment, so the test asserts it per environment (IsSaaS).
// Result: OBSERVED_RESULT
// Source: al-runner issue 6380.
// BC versions: 27, 28, 29

codeunit 90987 "LT Y5 Auth Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Y5_Auth_IsUserNamePasswordAuthentication()
    var
        IdentityManagement: Codeunit "Identity Management";
        EnvironmentInformation: Codeunit "Environment Information";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('saas', Format(EnvironmentInformation.IsSaaS()));
        Observer.Observe('username password', Format(IdentityManagement.IsUserNamePasswordAuthentication()));
        Observer.Observe('second call', Format(IdentityManagement.IsUserNamePasswordAuthentication()));
        Observer.Finish();
    end;
}
