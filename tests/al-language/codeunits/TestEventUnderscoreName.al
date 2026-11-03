// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope (Cloud-compatible)
// Fixtures used: UndEvt Publisher (67022), UndEvt Subscriber (67023)
// BC versions: 27.5+
//
// An event whose name contains underscores is an ordinary event: a bound subscriber to
// OnBeforeHandle_State receives it, var arguments come back, and an event named with a
// shorter prefix (OnBeforeHandle) keeps its own subscribers. Names that contain or end in
// "_Scope" dispatch the same way. Written for AL Runner issue #5142, where dispatch cut
// the event name at its first underscore.

codeunit 67024 "Test Event Underscore Name"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure UnderscoredEvent_Bound_ReachesItsSubscriber()
    var
        Publisher: Codeunit "UndEvt Publisher";
        Subscriber: Codeunit "UndEvt Subscriber";
        Log: Text;
        Handled: Boolean;
    begin
        BindSubscription(Subscriber);
        Handled := Publisher.RaiseUnderscored(Log);
        UnbindSubscription(Subscriber);
        Assert.IsTrue(Handled, 'The bound subscriber of OnBeforeHandle_State must set Handled');
        Assert.AreEqual('State;', Log, 'Only the OnBeforeHandle_State subscriber must run');
    end;

    [Test]
    procedure UnderscoredEvent_Unbound_DoesNotFire()
    var
        Publisher: Codeunit "UndEvt Publisher";
        Log: Text;
        Handled: Boolean;
    begin
        Handled := Publisher.RaiseUnderscored(Log);
        Assert.IsFalse(Handled, 'An unbound manual subscriber must not receive OnBeforeHandle_State');
        Assert.AreEqual('', Log, 'No subscriber must run while unbound');
    end;

    [Test]
    procedure PrefixNamedEvent_ReachesOnlyItsOwnSubscriber()
    var
        Publisher: Codeunit "UndEvt Publisher";
        Subscriber: Codeunit "UndEvt Subscriber";
        Log: Text;
        Handled: Boolean;
    begin
        BindSubscription(Subscriber);
        Handled := Publisher.RaisePlain(Log);
        UnbindSubscription(Subscriber);
        Assert.IsTrue(Handled, 'The bound subscriber of OnBeforeHandle must set Handled');
        Assert.AreEqual('Plain;', Log, 'Only the OnBeforeHandle subscriber must run');
    end;

    [Test]
    procedure EventNameContainingScope_ReachesItsSubscriber()
    var
        Publisher: Codeunit "UndEvt Publisher";
        Subscriber: Codeunit "UndEvt Subscriber";
        Log: Text;
    begin
        BindSubscription(Subscriber);
        Publisher.RaiseScopeLooking(Log);
        UnbindSubscription(Subscriber);
        Assert.AreEqual('ScopeValue;', Log, 'The OnCheck_Scope_Value subscriber must run, and only it');
    end;

    [Test]
    procedure EventNameEndingInScope_ReachesItsSubscriber()
    var
        Publisher: Codeunit "UndEvt Publisher";
        Subscriber: Codeunit "UndEvt Subscriber";
        Log: Text;
    begin
        BindSubscription(Subscriber);
        Publisher.RaiseEndsWithScope(Log);
        UnbindSubscription(Subscriber);
        Assert.AreEqual('Scope;', Log, 'The OnCheck_Scope subscriber must run, and only it');
    end;

    [Test]
    procedure UnderscoredEvent_SubscriberError_Propagates()
    var
        Publisher: Codeunit "UndEvt Publisher";
        Subscriber: Codeunit "UndEvt Subscriber";
    begin
        BindSubscription(Subscriber);
        asserterror Publisher.RaiseStrict(5);
        UnbindSubscription(Subscriber);
        Assert.ExpectedError('Strict subscriber rejected 5');
    end;

    [Test]
    procedure UnderscoredEvent_RaisedFromSubscriber_ReachesItsSubscriber()
    var
        Publisher: Codeunit "UndEvt Publisher";
        Subscriber: Codeunit "UndEvt Subscriber";
        Log: Text;
    begin
        BindSubscription(Subscriber);
        Publisher.RaiseRelayOuter(Log);
        UnbindSubscription(Subscriber);
        Assert.AreEqual('Outer;Inner;', Log, 'OnRelay_Inner raised from the OnRelay_Outer subscriber must reach its subscriber');
    end;
}
