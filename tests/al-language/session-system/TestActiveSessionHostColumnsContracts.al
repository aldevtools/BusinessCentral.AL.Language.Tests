// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained codeunit 68955
// Probe: written against a real BC 27.5 service tier started by bc-linux (the tests run through the websocket client
// runner); every literal below is what that tier produced. Other BC versions and hosts were not measured.
//
// Pins the "Active Session" row of the running session (Get(ServiceInstanceId(), SessionId())): it exists, "Server Instance
// Name" and "Server Computer Name" are not blank, and "User ID" is the session user.
// "Client Computer Name" is the runner's: blank on the websocket runner of 27.5, VSCodeTestClient on the 28.5 altool runner, so it is not pinned.
// The values of the first two are the host's (this tier: instance BC, computer name = the container host name), so only their
// shape is pinned.
// BC versions: 27.5

codeunit 68955 "Probe Active Session Host"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure ActiveSession_OfTheRunningSession_HasHostColumns()
    var
        ActiveSessionRec: Record "Active Session";
    begin
        Assert.IsTrue(ActiveSessionRec.Get(ServiceInstanceId(), SessionId()), 'Get');

        Assert.AreNotEqual('', ActiveSessionRec."Server Instance Name", 'Server Instance Name');
        Assert.AreNotEqual('', ActiveSessionRec."Server Computer Name", 'Server Computer Name');
        Assert.AreEqual(UserId(), ActiveSessionRec."User ID", 'User ID');
    end;
}
