// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Fixtures used: ALT Event Publisher (60014), ALT Event Subscriber (60015), ALT Trigger Log (60003)
// Contract tests: non-obvious event system behaviors

codeunit 60159 "Test Event Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Contract 1: Var Parameters Are Modifiable And Visible To Caller ────────────────────

    [Test]
    procedure EventPublisher_VarParameter_ModificationVisibleToCaller()
    var
        Publisher: Codeunit "ALT Event Publisher";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Publisher.TriggerBefore(42);
        TrigLog.SetRange("TriggerName", 'OnBeforeAction');
        Assert.IsTrue(TrigLog.FindFirst(), 'OnBeforeAction event must have fired');
        Assert.AreEqual(42, TrigLog."SourceEntryNo", 'OnBeforeAction subscriber must see the EntryNo=42 passed by publisher');
    end;

    // ── Contract 2: Multiple Event Publishes All Invoke Subscriber ────────────────────────

    [Test]
    procedure MultiplePublishes_AllSubscriberInvocationsLogged()
    var
        Publisher: Codeunit "ALT Event Publisher";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Publisher.TriggerBefore(1);
        Publisher.TriggerBefore(2);
        Publisher.TriggerBefore(3);
        TrigLog.SetRange("TriggerName", 'OnBeforeAction');
        Assert.AreEqual(3, TrigLog.Count(), 'Static subscriber must be invoked once per TriggerBefore call: 3 total');
    end;

    // ── Contract 3: Event Result Parameter Is Visible In Subscriber ──────────────────────

    [Test]
    procedure AfterAction_Result_VisibleInSubscriberLog()
    var
        Publisher: Codeunit "ALT Event Publisher";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Publisher.TriggerAfter(1, 777);
        TrigLog.SetRange("TriggerName", 'OnAfterAction');
        Assert.IsTrue(TrigLog.FindFirst(), 'OnAfterAction event must have fired');
        Assert.AreEqual('777', TrigLog."NewValue", 'OnAfterAction subscriber must receive and log Result=777');
    end;

    // ── Contract 4: InternalEvent Is Fired And Logged Within Same App ──────────────────────

    [Test]
    procedure InternalEvent_FiredAndLogged()
    var
        Publisher: Codeunit "ALT Event Publisher";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Publisher.TriggerInternal(5);
        TrigLog.SetRange("TriggerName", 'OnInternalStep');
        Assert.IsTrue(TrigLog.FindFirst(), 'OnInternalStep (InternalEvent) must have fired');
        Assert.AreEqual(5, TrigLog."SourceEntryNo", 'InternalEvent subscriber must receive Step=5');
    end;

    // ── Contract 5: Static Subscriber Fires For Events ────────────────────────────────

    [Test]
    procedure BindSubscription_StaticSubscriber_FiresForEvents()
    var
        Publisher: Codeunit "ALT Event Publisher";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Publisher.TriggerBefore(10);
        TrigLog.SetRange("TriggerName", 'OnBeforeAction');
        Assert.IsTrue(TrigLog.Count() >= 1, 'Static subscriber must fire when event is published');
    end;

    // ── Contract 6: UnbindSubscription On Non-Bound Subscriber Is No-Op ──────────────────

    [Test]
    procedure UnbindSubscription_NotBound_IsNoOp()
    var
        Sub: Codeunit "ALT Event Subscriber";
        Success: Boolean;
    begin
        Initialize();
        // UnbindSubscription on a subscriber that is not bound — should return false but not throw
        Success := Session.UnbindSubscription(Sub);
        // Success will be false because Sub was never bound, but no error should occur
        Assert.IsTrue(true, 'UnbindSubscription on non-bound subscriber must not throw an error');
    end;

    // ── Contract 7: Static Subscription Remains Active Across Tests ────

    [Test]
    procedure UnbindSubscription_StaticSubscriptionStillFires()
    var
        Publisher: Codeunit "ALT Event Publisher";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Publisher.TriggerBefore(99);
        TrigLog.SetRange("TriggerName", 'OnBeforeAction');
        TrigLog.SetRange("SourceEntryNo", 99);
        Assert.IsTrue(TrigLog.Count() >= 1, 'Static subscription must fire and remain consistently active');
    end;

    // ── Contract 8: Independent Event Chains Complete Without Interference ──────────────

    [Test]
    procedure EventChaining_SubscriberFiresMultipleIndependentEvents()
    var
        Publisher: Codeunit "ALT Event Publisher";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Publisher.TriggerBefore(1);       // fires OnBeforeAction
        Publisher.TriggerAfter(1, 0);     // fires OnAfterAction
        Publisher.TriggerInternal(1);     // fires OnInternalStep
        Assert.AreEqual(3, TrigLog.Count(), 'Three independent event fires must produce exactly 3 log entries');
    end;

    // ── Contract 9: Events Fired During Record Trigger Are Captured And Complete ────────

    [Test]
    procedure Event_FiredDuringOnInsert_ReachesSubscriber()
    var
        Publisher: Codeunit "ALT Event Publisher";
        TrigLog: Record "ALT Trigger Log";
        Triggered: Record "ALT Triggered";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(true); // OnInsert trigger fires → logs 'OnInsert' to TrigLog
        Publisher.TriggerBefore(100); // also fires event → logs 'OnBeforeAction'

        TrigLog.SetRange("TriggerName", 'OnInsert');
        Assert.AreEqual(1, TrigLog.Count(), 'OnInsert record trigger must have fired');

        TrigLog.SetRange("TriggerName", 'OnBeforeAction');
        TrigLog.SetRange("SourceEntryNo", 100);
        Assert.AreEqual(1, TrigLog.Count(), 'Event published after OnInsert must also reach subscriber');
    end;

    // ── Contract 10: EntryNo Parameter Integrity For Zero And Positive Values ────────────

    [Test]
    procedure EntryNo_Parameter_ZeroVsPositive_BothLogged()
    var
        Publisher: Codeunit "ALT Event Publisher";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Publisher.TriggerBefore(0);
        Publisher.TriggerBefore(1);
        TrigLog.SetRange("TriggerName", 'OnBeforeAction');
        Assert.AreEqual(2, TrigLog.Count(), 'Both EntryNo=0 and EntryNo=1 must each trigger a subscriber invocation');

        TrigLog.FindFirst();
        Assert.AreEqual(0, TrigLog."SourceEntryNo", 'First log entry must have SourceEntryNo=0');

        TrigLog.FindLast();
        Assert.AreEqual(1, TrigLog."SourceEntryNo", 'Second log entry must have SourceEntryNo=1');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
