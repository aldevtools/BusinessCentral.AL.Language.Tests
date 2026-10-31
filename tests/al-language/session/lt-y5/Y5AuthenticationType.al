// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/users-credential-types
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 90987 (writer Y5); System Application codeunits "Identity Management" (9801)
//   and "Environment Information" (457)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: al-runner issue 6380. Identity Management.IsUserNamePasswordAuthentication (the only one of the three credential-type
//   members that a Cloud app can call; IsWindowsAuthentication and IsAccessControlServiceAuthentication are Scope OnPrem, see
//   tests/al-language-onprem/lt-y5/Y5AuthenticationTypeOnPrem.al) answers the service tier's ClientServicesCredentialType.
//   The answer differs per environment. Asserted: the corpus CI containers (Linux, BC 29.0 leg): Yes. Measured on a BC 29 SaaS
//   sandbox (not asserted; the SaaS sandbox is not a CI leg): No. EnvironmentInformation.IsSaaS() is Yes on both, so it cannot
//   tell the two apart.
// Result: the CI containers use user name and password credentials (IsUserNamePasswordAuthentication = Yes, on every call).
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
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('username password', Format(IdentityManagement.IsUserNamePasswordAuthentication()));
        Observer.Observe('second call', Format(IdentityManagement.IsUserNamePasswordAuthentication()));
        Observer.Expect('username password', 'Yes');
        Observer.Expect('second call', 'Yes');
        Observer.Verify();
    end;
}
