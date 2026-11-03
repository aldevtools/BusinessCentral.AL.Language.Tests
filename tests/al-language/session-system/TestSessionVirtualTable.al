// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-types#virtual-tables
// Scope: in-scope
// Fixtures used: Assert only. The subject is a platform virtual table (Session,
//                2000000009) and the session doing the reading; nothing is created,
//                nothing is written, and no fixture object is involved.
//
// CLAIM: the Session virtual table is a view of the session doing the reading. The
// platform's identity surfaces -- SessionId(), UserId() -- and the row in this table are
// the same facts, so they cannot disagree; and there is a row at all, which is the half a
// host that keeps session identity only in memory can silently fail.
//
// Session is Scope = Cloud and is NOT one of the platform's internal tables, so a
// Target = Cloud app can name it directly. No RecordRef escape hatch is needed and none is
// used.
//
// EVERY ASSERTION IS ABOUT SHAPE OR ABOUT AGREEMENT, NEVER ABOUT A LITERAL. The connection
// id, the user name, the host name and the login instant are properties of the environment
// this runs in, so pinning any of them would fail for reasons that are configuration rather
// than platform behavior. Comparing the table against SessionId() / UserId() instead is the
// stronger claim anyway: it is the one a value invented by the host cannot satisfy.
codeunit 60340 "Test Session Virtual Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure SessionTable_HasARowForTheReadingSession()
    // CLAIM: the table is not empty, and exactly one row is flagged as this session.
    // "Exactly one" rather than "at least one": "My Session" is the platform's own answer to
    // "is this me", and two rows claiming it would make the flag useless.
    var
        Sess: Record Session;
    begin
        Assert.IsTrue(Sess.FindSet(), 'Session must answer at least one row');

        Sess.SetRange("My Session", true);
        Assert.AreEqual(1, Sess.Count(), 'exactly one row must be flagged as the reading session');
    end;

    [Test]
    procedure SessionTable_MySessionRow_ConnectionIdIsWhatSessionIdReturns()
    // CLAIM: the row's primary key IS the id SessionId() reports. This is what makes the
    // table a view of the session rather than a separate list that happens to look similar.
    var
        Sess: Record Session;
    begin
        Sess.SetRange("My Session", true);
        Assert.IsTrue(Sess.FindFirst(), 'the reading session must be a row');
        Assert.AreEqual(SessionId(), Sess."Connection ID",
            'Session."Connection ID" must be the id SessionId() reports');
    end;

    [Test]
    procedure SessionTable_MySessionRow_UserIdIsWhatUserIdReturns()
    // CLAIM: the same agreement for the user. AreNotEqual('') first, so a blank column
    // cannot satisfy the comparison by accident on a host where UserId() is also blank.
    var
        Sess: Record Session;
    begin
        Sess.SetRange("My Session", true);
        Assert.IsTrue(Sess.FindFirst(), 'the reading session must be a row');
        Assert.AreNotEqual('', Sess."User ID", 'Session."User ID" must not be blank');
        Assert.AreEqual(UserId(), Sess."User ID",
            'Session."User ID" must be the user UserId() reports');
    end;

    [Test]
    procedure SessionTable_GetByConnectionId_ReachesTheSameRowAsFindFirst()
    // CLAIM: Get() reaches the row by primary key. A table whose key columns disagreed with
    // the row's own "Connection ID" would still satisfy FindFirst and fail this.
    var
        ByGet: Record Session;
        ByFind: Record Session;
    begin
        Assert.IsTrue(ByGet.Get(SessionId()), 'Get(SessionId()) must find the reading session');
        Assert.IsTrue(ByGet."My Session", 'the row Get returns must be flagged as this session');

        ByFind.SetRange("My Session", true);
        ByFind.FindFirst();
        Assert.AreEqual(ByFind."Connection ID", ByGet."Connection ID",
            'Get and FindFirst must reach the same row');
        Assert.AreEqual(ByFind."User ID", ByGet."User ID",
            'Get and FindFirst must reach the same row');
    end;

    [Test]
    procedure SessionTable_MySessionRow_CarriesALoginDateTimeAndAHostName()
    // CLAIM: the row is more than a key. A host that inserted one row and left every
    // non-key column at its type default satisfies every assertion above and fails this.
    // Shape only -- the date, the time and the name are properties of the environment.
    var
        Sess: Record Session;
    begin
        Sess.SetRange("My Session", true);
        Sess.FindFirst();
        Assert.AreNotEqual(0D, Sess."Login Date", 'Session."Login Date" must be answered');
        Assert.AreNotEqual(0T, Sess."Login Time", 'Session."Login Time" must be answered');
        Assert.AreNotEqual('', Sess."Host Name", 'Session."Host Name" must be answered');
    end;

    [Test]
    procedure SessionTable_HoldsOnlyTheReadingSession()
    // THE OPEN QUESTION IN THIS FILE, and it is asked deliberately rather than assumed.
    //
    // The name suggests "every session connected to this server", and older documentation
    // reads that way. What the shipped platform actually does is narrower: the provider
    // behind this table builds ONE record buffer, for NavCurrentThread.Session, with
    // "My Session" a hardcoded true, and returns a one-element array. Read that way, the
    // table answers "who am I" and never "who else is here".
    //
    // That is a reading of shipped code, which is exactly the kind of claim that has to be
    // put to a running server rather than believed. If this fails, the answer is that the
    // table is wider than the reading suggests, and it is the assertion that should change.
    var
        Sess: Record Session;
    begin
        Assert.AreEqual(1, Sess.Count(),
            'Session must hold exactly one row -- the session doing the reading');
    end;

    [Test]
    procedure SessionTable_GetOnAConnectionIdThatIsNoSession_ReturnsFalse()
    // NEGATIVE. A deliberately impossible connection id: session ids the platform hands out
    // are positive, so no concurrently running session can make this one resolve. This is
    // the assertion that fails if the table answers a row for anything asked of it.
    var
        Sess: Record Session;
    begin
        Assert.IsFalse(Sess.Get(-987654),
            'a connection id belonging to no session must not resolve to a row');
    end;

    [Test]
    procedure SessionTable_FilterOnMySessionFalse_SelectsNothingOrOnlyOtherSessions()
    // NEGATIVE, and it discriminates in the direction that matters: no row may claim to be
    // this session and also claim not to be. Deliberately NOT "IsEmpty": on a server with
    // other users connected there may legitimately be rows here, and what is asserted is
    // that none of them is this session's -- which is the claim, rather than a statement
    // about how busy the server is.
    var
        Sess: Record Session;
    begin
        Sess.SetRange("My Session", false);
        if Sess.FindSet() then
            repeat
                Assert.AreNotEqual(SessionId(), Sess."Connection ID",
                    'the reading session must not also appear as a row flagged "not my session"');
            until Sess.Next() = 0;
    end;
    [Test]
    procedure SessionTable_MySessionRow_ApplicationNameIsActiveSessionsClientType()
    // AGREEMENT: "Application Name" is the reading session's Active Session "Client Type",
    // as text -- the platform projects one from the other. The client type itself depends on
    // how the tier runs tests, so no literal is asserted.
    var
        Sess: Record Session;
        ActiveSession: Record "Active Session";
    begin
        Sess.SetRange("My Session", true);
        Assert.IsTrue(Sess.FindFirst(), 'the reading session must be a row of Session');
        Assert.IsTrue(ActiveSession.Get(ServiceInstanceId(), SessionId()),
            'the reading session must be a row of Active Session');
        Assert.AreEqual(Format(ActiveSession."Client Type"), Sess."Application Name",
            'Session."Application Name" must be the reading session''s Active Session "Client Type", as text');
    end;

    [Test]
    procedure SessionTable_MySessionRow_DatabaseNameIsActiveSessionsDatabaseName()
    // AGREEMENT: "Database Name" is the reading session's Active Session "Database Name".
    // The name is a property of the environment, so no literal is asserted.
    var
        Sess: Record Session;
        ActiveSession: Record "Active Session";
    begin
        Sess.SetRange("My Session", true);
        Assert.IsTrue(Sess.FindFirst(), 'the reading session must be a row of Session');
        Assert.IsTrue(ActiveSession.Get(ServiceInstanceId(), SessionId()),
            'the reading session must be a row of Active Session');
        Assert.AreEqual(ActiveSession."Database Name", Sess."Database Name",
            'Session."Database Name" must be the reading session''s Active Session "Database Name"');
    end;
}
