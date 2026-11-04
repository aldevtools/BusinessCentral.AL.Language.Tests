// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-serviceinstanceid-method
// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-sessionid-method
// Scope: in-scope
// Fixtures used: Assert only. The subject is the identity the platform hands the session running
//                this test; nothing is created or written.
//
// CLAIM: on a service tier, ServiceInstanceId() and SessionId() are strictly positive for the
// session running a test, and the Active Session row keyed by them carries the same positive
// values. TestFinalCoverage asserts only ">= 0" and TestActiveSessionTable only agreement, so
// neither says whether zero is an identity the platform ever hands out. Application code treats
// a non-positive server instance id as "no owner" (AL Runner issue #5144), which is only sound if
// a live session never reports one.
//
// No literal is asserted: which positive numbers a session receives is a property of the tier.
codeunit 60023 "Test Session Identity Values"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure ServiceInstanceId_ForTheTestSession_IsPositive()
    var
        Id: Integer;
    begin
        Id := ServiceInstanceId();
        Assert.IsTrue(Id > 0, StrSubstNo('ServiceInstanceId() must be positive for a live session, got %1', Id));
    end;

    [Test]
    procedure ServiceInstanceId_WithDatabasePrefix_IsPositiveAndAgrees()
    var
        Id: Integer;
    begin
        Id := Database.ServiceInstanceId();
        Assert.IsTrue(Id > 0, StrSubstNo('Database.ServiceInstanceId() must be positive for a live session, got %1', Id));
        Assert.AreEqual(ServiceInstanceId(), Id, 'Database.ServiceInstanceId() must agree with ServiceInstanceId()');
    end;

    [Test]
    procedure SessionId_ForTheTestSession_IsPositive()
    var
        Id: Integer;
    begin
        Id := SessionId();
        Assert.IsTrue(Id > 0, StrSubstNo('SessionId() must be positive for a live session, got %1', Id));
    end;

    [Test]
    procedure SessionId_WithDatabasePrefix_IsPositiveAndAgrees()
    var
        Id: Integer;
    begin
        Id := Database.SessionId();
        Assert.IsTrue(Id > 0, StrSubstNo('Database.SessionId() must be positive for a live session, got %1', Id));
        Assert.AreEqual(SessionId(), Id, 'Database.SessionId() must agree with SessionId()');
    end;

    [Test]
    procedure ActiveSession_ReadingSessionRow_CarriesThePositiveIds()
    // CLAIM: the row the platform keeps for this session is keyed by the same positive pair,
    // so an ownership check of the shape "ServerId > 0 and Active Session.Get(ServerId,
    // SessionId)" recognises the session that is running it.
    var
        ActiveSession: Record "Active Session";
    begin
        Assert.IsTrue(ActiveSession.Get(ServiceInstanceId(), SessionId()),
            'Active Session must hold a row for (ServiceInstanceId(), SessionId())');
        Assert.IsTrue(ActiveSession."Server Instance ID" > 0,
            StrSubstNo('Active Session."Server Instance ID" must be positive, got %1', ActiveSession."Server Instance ID"));
        Assert.IsTrue(ActiveSession."Session ID" > 0,
            StrSubstNo('Active Session."Session ID" must be positive, got %1', ActiveSession."Session ID"));
    end;

    [Test]
    procedure ActiveSession_ZeroServerInstanceId_HoldsNoRowForThisSession()
    // NEGATIVE. With the instance id positive, (0, SessionId()) names no live session; fails if
    // the table answers a row for an instance id the platform does not hand out.
    var
        ActiveSession: Record "Active Session";
    begin
        Assert.IsFalse(ActiveSession.Get(0, SessionId()),
            'Active Session must hold no row for server instance id 0');
    end;
}
