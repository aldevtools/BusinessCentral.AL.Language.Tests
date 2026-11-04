// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessionsettings/sessionsettings-data-type
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained codeunit 68860
// Probe: written against a real BC 27.5 service tier started by bc-linux (user BCRUNNER, the test runs through the
// client-style websocket runner); every literal below is what that tier produced. Other BC versions were not measured.
//
// Pins the "User Personalization" row of the session user. The platform creates it when a user signs in
// to a client, and the test runner's own client session is that sign-in, so the row is there when a test
// runs: Get(UserSecurityId()) finds exactly one row, scope Tenant, owned by Base Application (App ID
// 437dbf0e-84ff-417a-965d-ed2bb9650972), language and locale 1033, a profile id that is not blank.
// What the profile id, the time zone and the company hold is tenant data and is not pinned
// (session/TestSessionSettings.al:402-407 records that SessionSettings.Company differed between images).
// BC versions: 27.5

codeunit 68860 "Probe User Personalization"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure UserPersonalization_RowOfTheSessionUser_Exists()
    var
        UserPers: Record "User Personalization";
    begin
        UserPers.SetRange("User SID", UserSecurityId());
        Assert.AreEqual(1, UserPers.Count(), 'one row for the session user');

        Assert.IsTrue(UserPers.Get(UserSecurityId()), 'Get');
        Assert.AreEqual(UserPers.Scope::Tenant, UserPers.Scope, 'Scope');
        Assert.AreEqual('{437DBF0E-84FF-417A-965D-ED2BB9650972}', Format(UserPers."App ID"), 'App ID is Base Application');
        Assert.AreEqual(1033, UserPers."Language ID", 'Language ID');
        Assert.AreEqual(1033, UserPers."Locale ID", 'Locale ID');
        Assert.AreNotEqual('', UserPers."Profile ID", 'Profile ID');
    end;
}
