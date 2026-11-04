// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-isolated
// Scope: in-scope
// Fixtures used: ISO Event Row (67100), ISO Event Publisher (67101),
//                ISO Event Subscribers (67102), shared Assert (60021)
// Note: an event declared Isolated = true runs each subscriber in its own transaction.
// When the caller holds no uncommitted write, a subscriber's error is caught and does not
// reach the publisher's caller, the failing subscriber's writes are rolled back, and the
// other subscribers still run and keep their writes. When the caller DOES hold an
// uncommitted write, the platform does not isolate, and the error propagates as it would
// for an ordinary event. A non-isolated event is the control: its subscriber's error
// always reaches the caller. AL Runner issue #4721.
// BC versions: 24+

codeunit 67103 "Test Isolated Event Sub Error"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "ISO Event Row";
    begin
        Row.DeleteAll();
        // DeleteAll opens a write transaction. Close it so the isolated event below is
        // raised with nothing pending, which is when the platform isolates subscribers.
        Commit();
    end;

    [Test]
    procedure IsolatedEvent_SubscriberError_DoesNotReachTheCaller()
    var
        Publisher: Codeunit "ISO Event Publisher";
        ReachedAfterPublish: Boolean;
    begin
        Initialize();

        Publisher.RaiseIsolated();
        ReachedAfterPublish := true;

        Assert.IsTrue(ReachedAfterPublish, 'RaiseIsolated must return normally when an isolated subscriber raises.');
    end;

    [Test]
    procedure IsolatedEvent_FailingSubscriber_WritesAreRolledBack()
    var
        Publisher: Codeunit "ISO Event Publisher";
        Row: Record "ISO Event Row";
    begin
        Initialize();

        Publisher.RaiseIsolated();

        Assert.IsFalse(Row.Get(1), 'The row written by the isolated subscriber that raised must be rolled back.');
    end;

    [Test]
    procedure IsolatedEvent_SucceedingSubscriber_StillRunsAndKeepsItsWrite()
    var
        Publisher: Codeunit "ISO Event Publisher";
        Row: Record "ISO Event Row";
    begin
        Initialize();

        Publisher.RaiseIsolated();

        Assert.IsTrue(Row.Get(2), 'The isolated subscriber that did not raise must have run and kept its row.');
        Assert.AreEqual('isolated-ok', Row.Source, 'Unexpected Source on the surviving isolated row.');
        Assert.AreEqual(1, Row.Count(), 'Only the non-failing isolated subscriber''s row may exist.');
    end;

    [Test]
    procedure IsolatedEvent_WithCallerWritePending_SubscriberErrorPropagates()
    var
        Publisher: Codeunit "ISO Event Publisher";
        Row: Record "ISO Event Row";
    begin
        Initialize();
        Row."Entry No." := 10;
        Row.Source := 'caller-pending';
        Row.Insert();

        asserterror Publisher.RaiseIsolated();

        Assert.ExpectedError('ISO-SUBSCRIBER-FAILED');
    end;

    [Test]
    procedure SharedEvent_SubscriberError_ReachesTheCaller()
    var
        Publisher: Codeunit "ISO Event Publisher";
    begin
        Initialize();

        asserterror Publisher.RaiseShared();

        Assert.ExpectedError('SHARED-SUBSCRIBER-FAILED');
    end;
}
