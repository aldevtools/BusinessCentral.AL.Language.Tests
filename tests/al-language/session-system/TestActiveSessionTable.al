// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system/table/system.environment.active-session
// Scope: in-scope
// Fixtures used: Assert only. The subject is the platform's Active Session table (2000000110)
//                and the session doing the reading; nothing is created or written.
//
// CLAIM: the session running this test has a row in Active Session, keyed by
// (ServiceInstanceId(), SessionId()), and that row carries the same identity the platform's
// own surfaces report -- UserId(), UserSecurityId() -- and the same user the Session virtual
// table (2000000009) reports for this session.
//
// Active Session is Scope = Cloud, so a Target = Cloud app can name it directly.
//
// EVERY ASSERTION IS ABOUT SHAPE OR ABOUT AGREEMENT, NEVER ABOUT A LITERAL. Instance ids,
// session ids, user names, machine names and login instants are properties of the environment
// this runs in. Comparing the row against the platform functions is the stronger claim: a value
// invented by a host that keeps session identity only in memory cannot satisfy it.
codeunit 60976 "Test Active Session Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure ActiveSession_GetByInstanceAndSessionId_FindsTheReadingSession()
    // CLAIM: the primary key is (Server Instance ID, Session ID), and the reading session is
    // reachable through it with the values the platform functions report.
    var
        ActiveSession: Record "Active Session";
    begin
        Assert.IsTrue(ActiveSession.Get(ServiceInstanceId(), SessionId()),
            'Active Session must hold a row for (ServiceInstanceId(), SessionId())');
        Assert.AreEqual(ServiceInstanceId(), ActiveSession."Server Instance ID",
            'the row''s Server Instance ID must be what ServiceInstanceId() reports');
        Assert.AreEqual(SessionId(), ActiveSession."Session ID",
            'the row''s Session ID must be what SessionId() reports');
    end;

    [Test]
    procedure ActiveSession_FilterOnSessionId_IsNotEmpty()
    // CLAIM: the row is visible to an ordinary filtered read, not only to Get.
    var
        ActiveSession: Record "Active Session";
    begin
        ActiveSession.SetRange("Server Instance ID", ServiceInstanceId());
        ActiveSession.SetRange("Session ID", SessionId());
        Assert.AreEqual(1, ActiveSession.Count(),
            'exactly one Active Session row must match this instance and session id');
    end;

    [Test]
    procedure ActiveSession_ReadingSessionRow_UserIdIsWhatUserIdReturns()
    // CLAIM: the row's user is the session's user. AreNotEqual('') first, so a blank column
    // cannot satisfy the comparison on a host where UserId() is also blank.
    var
        ActiveSession: Record "Active Session";
    begin
        ActiveSession.Get(ServiceInstanceId(), SessionId());
        Assert.AreNotEqual('', ActiveSession."User ID", 'Active Session."User ID" must not be blank');
        Assert.AreEqual(UserId(), ActiveSession."User ID",
            'Active Session."User ID" must be the user UserId() reports');
    end;

    [Test]
    procedure ActiveSession_ReadingSessionRow_UserSidIsWhatUserSecurityIdReturns()
    // CLAIM: the same agreement for the security id.
    var
        ActiveSession: Record "Active Session";
    begin
        ActiveSession.Get(ServiceInstanceId(), SessionId());
        Assert.IsFalse(IsNullGuid(ActiveSession."User SID"), 'Active Session."User SID" must not be the null GUID');
        Assert.AreEqual(UserSecurityId(), ActiveSession."User SID",
            'Active Session."User SID" must be the id UserSecurityId() reports');
    end;

    [Test]
    procedure ActiveSession_ReadingSessionRow_CarriesALoginDatetimeAndAUniqueId()
    // CLAIM: the row is more than its key and its user. Shape only -- the instant and the
    // GUID are properties of the environment.
    var
        ActiveSession: Record "Active Session";
    begin
        ActiveSession.Get(ServiceInstanceId(), SessionId());
        Assert.AreNotEqual(0DT, ActiveSession."Login Datetime", 'Active Session."Login Datetime" must be answered');
        Assert.IsFalse(IsNullGuid(ActiveSession."Session Unique ID"),
            'Active Session."Session Unique ID" must not be the null GUID');
    end;

    [Test]
    procedure ActiveSession_AgreesWithTheSessionVirtualTableOnTheUser()
    // CLAIM: Session (2000000009) and Active Session describe the same reading session, so
    // they name the same user. The two tables are separate objects AL can read independently;
    // a host that populates one and not the other fails this.
    var
        ActiveSession: Record "Active Session";
        Sess: Record Session;
    begin
        Assert.IsTrue(ActiveSession.Get(ServiceInstanceId(), SessionId()), 'Active Session must hold the reading session');
        Assert.IsTrue(Sess.Get(SessionId()), 'Session must hold the reading session');
        Assert.AreEqual(Sess."User ID", ActiveSession."User ID",
            'Session and Active Session must name the same user for the reading session');
    end;

    [Test]
    procedure ActiveSession_GetOnASessionIdThatIsNoSession_ReturnsFalse()
    // NEGATIVE. Session ids the platform hands out are not negative, so no concurrently running
    // session can make this one resolve. Fails if the table answers a row for anything asked.
    var
        ActiveSession: Record "Active Session";
    begin
        Assert.IsFalse(ActiveSession.Get(ServiceInstanceId(), -987654),
            'a session id belonging to no session must not resolve to a row');
    end;
}
