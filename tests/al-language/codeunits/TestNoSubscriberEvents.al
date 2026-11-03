// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Fixtures used: ALT No Subscriber Table (60590), ALT Subscribed Table (60593),
//                ALT Subscribed Table Sub (60591), ALT Trigger Log (60003)
//
// What these pin: the platform decides per (table, event) whether an event has any
// subscriber, and an event with NONE fires nothing. Every arm is written as a PAIR against
// the same write sequence, because a single table cannot tell "subscribers fired" apart
// from "every table fires unconditionally" -- both produce a log entry for the subscribed
// table, and only the negative arm separates them.
//
// The distinction is observable in AL only through the subscriber's side effect, so the
// negative arm asserts a count of zero on a table nothing subscribes to. Adding an
// [EventSubscriber] for "ALT No Subscriber Table" anywhere in this app inverts that arm's
// meaning silently -- the fixture file says so too.
codeunit 60592 "Test No Subscriber Events"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    // -- Arm 1: a table with no subscriber logs nothing on Insert ----------------------

    [Test]
    procedure Record_Insert_TableWithNoEventSubscriber_FiresNothing()
    var
        NoSub: Record "ALT No Subscriber Table";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();

        NoSub.Init();
        NoSub."Entry No." := 1;
        NoSub.Value := 11;
        NoSub.Insert(true);

        Assert.AreEqual(
            0, TrigLog.Count(),
            'A table with no event subscriber must log nothing on Insert: the platform reports the event as unsubscribed.');
    end;

    // -- Arm 2: its twin, which HAS a subscriber, logs exactly one entry ---------------

    [Test]
    procedure Record_Insert_TableWithOneEventSubscriber_FiresOnce()
    var
        Sub: Record "ALT Subscribed Table";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();

        Sub.Init();
        Sub."Entry No." := 1;
        Sub.Value := 22;
        Sub.Insert(true);

        TrigLog.SetRange(TriggerName, 'SubscribedInsert');
        Assert.AreEqual(
            1, TrigLog.Count(),
            'OnAfterInsertEvent has exactly one subscriber for "ALT Subscribed Table", so exactly one entry must be logged.');
        Assert.IsTrue(TrigLog.FindFirst(), 'The logged entry must be retrievable.');
        Assert.AreEqual(
            22, TrigLog.NewIntegerValue,
            'The subscriber must observe the row it was called for: Value=22.');
    end;

    // -- Arm 3: the pair in ONE run -- the discriminating arm --------------------------

    [Test]
    procedure Record_Insert_SubscribedAndUnsubscribedInOneRun_OnlySubscribedFires()
    var
        NoSub: Record "ALT No Subscriber Table";
        Sub: Record "ALT Subscribed Table";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();

        NoSub.Init();
        NoSub."Entry No." := 1;
        NoSub.Value := 11;
        NoSub.Insert(true);

        Sub.Init();
        Sub."Entry No." := 1;
        Sub.Value := 22;
        Sub.Insert(true);

        // Both writes happened in one run against one log, so a platform that took the
        // trigger path for every table would show two entries here, not one.
        Assert.AreEqual(
            1, TrigLog.Count(),
            'Two inserts, one subscribed table and one unsubscribed: exactly one log entry must result.');

        TrigLog.SetRange(TriggerName, 'SubscribedInsert');
        Assert.AreEqual(
            1, TrigLog.Count(),
            'The single entry must be the subscribed table''s, not the unsubscribed one''s.');
        Assert.IsTrue(TrigLog.FindFirst(), 'The logged entry must be retrievable.');
        Assert.AreEqual(
            22, TrigLog.NewIntegerValue,
            'The logged entry must carry the subscribed table''s Value=22, not the unsubscribed table''s 11.');
    end;

    // -- Arm 4: an unsubscribed EVENT on a table that has a subscriber for another one --
    //
    // Arm 1 could pass on a platform that decided per TABLE rather than per (table,event).
    // "ALT Subscribed Table" is subscribed for OnAfterInsertEvent only, so a Modify must
    // still log nothing even though the table itself has a subscriber.

    [Test]
    procedure Record_Modify_EventWithNoSubscriberOnSubscribedTable_FiresNothing()
    var
        Sub: Record "ALT Subscribed Table";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();

        Sub.Init();
        Sub."Entry No." := 1;
        Sub.Value := 22;
        Sub.Insert(true);

        Assert.AreEqual(1, TrigLog.Count(), 'The Insert must have logged exactly one entry.');

        Sub.Value := 33;
        Sub.Modify(true);

        Assert.AreEqual(
            1, TrigLog.Count(),
            'OnAfterModifyEvent has no subscriber for this table, so Modify must add nothing: the platform decides per (table, event), not per table.');
    end;
}
