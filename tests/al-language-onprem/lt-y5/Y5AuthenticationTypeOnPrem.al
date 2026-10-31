// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/users-credential-types
// Scope: in-scope, but ONLY for a Target = OnPrem app (IsWindowsAuthentication and IsAccessControlServiceAuthentication of
//   codeunit "Identity Management" are Scope OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; own codeunit 98850 (writer Y5)
// Probe: written against the corpus CI containers (BC OnPrem legs); every literal asserted below is what that service tier produced.
// Facts: al-runner issue 6380. The three credential-type members of Identity Management (they call DotNet
//   NavUserAccountHelper.IsWindowsAuthentication, IsUserNamePasswordAuthentication, IsAccessControlServiceAuthentication)
//   answer the service tier's ClientServicesCredentialType. The values are those of the CI containers.
// Result: on the CI containers IsWindowsAuthentication = No, IsUserNamePasswordAuthentication = Yes,
//   IsAccessControlServiceAuthentication = No (credential type NavUserPassword). These members cannot be called from a Cloud
//   app, so the SaaS sandbox has no answer for the two Scope OnPrem members.
// Source: al-runner issue 6380.
// BC versions: 27, 28, 29

codeunit 98850 "LT Y5 Auth OnPrem Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Y5_AuthOnPrem_CredentialTypeMembers()
    var
        IdentityManagement: Codeunit "Identity Management";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('windows', Format(IdentityManagement.IsWindowsAuthentication()));
        Observer.Observe('username password', Format(IdentityManagement.IsUserNamePasswordAuthentication()));
        Observer.Observe('access control service', Format(IdentityManagement.IsAccessControlServiceAuthentication()));
        Observer.Expect('windows', 'No');
        Observer.Expect('username password', 'Yes');
        Observer.Expect('access control service', 'No');
        Observer.Verify();
    end;
}
