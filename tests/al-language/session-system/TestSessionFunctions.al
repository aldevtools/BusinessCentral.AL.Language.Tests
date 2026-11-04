// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-data-type
// Scope: in-scope

codeunit 60111 "Test Session Functions"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Session Global Functions ─────────────────────────────────────────────────

    [Test]
    procedure Session_UserId_ReturnsNonEmpty()
    begin
        Initialize();
        Assert.AreNotEqual('', UserId(), 'UserId() must return non-empty string');
    end;

    [Test]
    procedure Session_CompanyName_ReturnsNonEmpty()
    begin
        Initialize();
        Assert.AreNotEqual('', CompanyName(), 'CompanyName() must return non-empty string');
    end;

    [Test]
    procedure Session_Today_ReturnsCurrentDate()
    begin
        Initialize();
        Assert.AreNotEqual(0D, Today(), 'Today() must return non-zero date');
    end;

    [Test]
    procedure Session_Time_ReturnsCurrentTime()
    begin
        Initialize();
        Assert.AreNotEqual(0T, Time(), 'Time() must return non-zero time');
    end;

    [Test]
    procedure Session_CurrentDateTime_ReturnsNonEmpty()
    begin
        Initialize();
        Assert.AreNotEqual(0DT, CurrentDateTime(), 'CurrentDateTime() must return non-zero datetime');
    end;

    [Test]
    procedure Session_WorkDate_ReturnsDate()
    begin
        Initialize();
        Assert.AreNotEqual(0D, WorkDate(), 'WorkDate() must return a non-zero date');
    end;

    [Test]
    procedure Session_SetWorkDate_ChangesWorkDate()
    var
        OldDate: Date;
    begin
        Initialize();
        OldDate := WorkDate();
        WorkDate(20240101D);
        Assert.AreEqual(20240101D, WorkDate(), 'SetWorkDate() must change the work date');
        WorkDate(OldDate);
    end;

    [Test]
    procedure Session_UserIdConsistent_ReturnsSameValue()
    var
        UserId1: Text;
        UserId2: Text;
    begin
        Initialize();
        UserId1 := UserId();
        UserId2 := UserId();
        Assert.AreEqual(UserId1, UserId2, 'UserId() must return consistent value within same session');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
