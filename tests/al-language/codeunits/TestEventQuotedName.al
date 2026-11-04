// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope (Cloud-compatible)
// Fixtures used: QEvt Publisher (67042), QEvt Publisher Table (67043),
//                QEvt Subscriber (67044), QEvt Iso Subscriber (67045),
//                QEvt Iso Witness (67047)
// BC versions: 27.5+
//
// An event whose name is a quoted identifier is an ordinary event: a bound subscriber that
// names it receives it, whether the name holds spaces, punctuation or a non-ASCII letter, and
// whether a codeunit or a table publishes it. Unbound, nothing runs; a subscriber's error
// reaches the caller; and when the quoted event is declared Isolated = true, a subscriber's
// error does not. Written for AL Runner issue #5167, where the runner never delivered an
// event whose quoted name had to be rewritten to become a .NET identifier.

codeunit 67046 "Test Event Quoted Name"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure SpacedName_Bound_ReachesItsSubscriber()
    var
        Publisher: Codeunit "QEvt Publisher";
        Subscriber: Codeunit "QEvt Subscriber";
        Log: Text;
        Handled: Boolean;
    begin
        BindSubscription(Subscriber);
        Handled := Publisher.RaiseSpaced(Log);
        UnbindSubscription(Subscriber);
        Assert.IsTrue(Handled, 'The bound subscriber of "On Before Quoted" must set Handled');
        Assert.AreEqual('Spaced;', Log, 'Only the "On Before Quoted" subscriber must run');
    end;

    [Test]
    procedure SpacedName_Unbound_DoesNotFire()
    var
        Publisher: Codeunit "QEvt Publisher";
        Log: Text;
        Handled: Boolean;
    begin
        Handled := Publisher.RaiseSpaced(Log);
        Assert.IsFalse(Handled, 'An unbound manual subscriber must not receive "On Before Quoted"');
        Assert.AreEqual('', Log, 'No subscriber must run while unbound');
    end;

    [Test]
    procedure PunctuatedName_ReachesItsSubscriber()
    var
        Publisher: Codeunit "QEvt Publisher";
        Subscriber: Codeunit "QEvt Subscriber";
        Log: Text;
    begin
        BindSubscription(Subscriber);
        Publisher.RaisePunctuated(Log);
        UnbindSubscription(Subscriber);
        Assert.AreEqual('Punctuated;', Log, 'The "On-Check.Value (Qty) & Amt" subscriber must run, and only it');
    end;

    [Test]
    procedure NonAsciiSpacedName_ReachesItsSubscriber()
    var
        Publisher: Codeunit "QEvt Publisher";
        Subscriber: Codeunit "QEvt Subscriber";
        Log: Text;
    begin
        BindSubscription(Subscriber);
        Publisher.RaiseUmlaut(Log);
        UnbindSubscription(Subscriber);
        Assert.AreEqual('Umlaut;', Log, 'The "On Bestätigt Evt" subscriber must run, and only it');
    end;

    [Test]
    procedure QuotedNameNeedingNoQuotes_ReachesItsSubscriber()
    var
        Publisher: Codeunit "QEvt Publisher";
        Subscriber: Codeunit "QEvt Subscriber";
        Log: Text;
    begin
        BindSubscription(Subscriber);
        Publisher.RaiseQuotedPlain(Log);
        UnbindSubscription(Subscriber);
        Assert.AreEqual('QuotedPlain;', Log, 'The "OnQuotedPlain" subscriber must run, and only it');
    end;

    [Test]
    procedure TablePublishedSpacedName_ReachesItsSubscriber()
    var
        PublisherTable: Record "QEvt Publisher Table";
        Subscriber: Codeunit "QEvt Subscriber";
        Log: Text;
    begin
        BindSubscription(Subscriber);
        PublisherTable.RaiseTableSpaced(Log);
        UnbindSubscription(Subscriber);
        Assert.AreEqual('Table;', Log, 'The "On Table Quoted" subscriber must run, and only it');
    end;

    [Test]
    procedure SpacedName_SubscriberError_Propagates()
    var
        Publisher: Codeunit "QEvt Publisher";
        Subscriber: Codeunit "QEvt Subscriber";
    begin
        BindSubscription(Subscriber);
        asserterror Publisher.RaiseStrict(7);
        UnbindSubscription(Subscriber);
        Assert.ExpectedError('Quoted strict subscriber rejected 7');
    end;

    [Test]
    procedure IsolatedSpacedName_SubscriberError_DoesNotReachTheCaller()
    var
        Publisher: Codeunit "QEvt Publisher";
        Witness: Codeunit "QEvt Iso Witness";
        CallsBefore: Integer;
        ReachedAfterPublish: Boolean;
    begin
        // An isolated event isolates its subscribers only when the caller holds no
        // uncommitted write (see codeunit 67103), so close any transaction first.
        Commit();
        CallsBefore := Witness.Count();
        Publisher.RaiseIsolated();
        ReachedAfterPublish := true;
        Assert.IsTrue(ReachedAfterPublish, 'RaiseIsolated must return normally when the isolated subscriber raises');
        // The subscriber must actually have run; otherwise returning normally proves nothing.
        Assert.AreEqual(CallsBefore + 1, Witness.Count(), 'The isolated subscriber of "On Isolated Quoted" must run exactly once');
    end;
}
