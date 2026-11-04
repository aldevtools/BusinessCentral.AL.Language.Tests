// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Fixtures used: ALT Event Publisher (60014), ALT Trigger Log (60003)

codeunit 60081 "Test Codeunit Subscriber"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Event Subscriber Behavior ────────────────────────────────────────────

    [Test]
    procedure Subscriber_OnBeforeAction_HandledFlagAccessible()
    var
        Publisher: Codeunit "ALT Event Publisher";
        TrigLog: Record "ALT Trigger Log";
        SourceEntry: Integer;
    begin
        Initialize();
        Publisher.TriggerBefore(10);
        TrigLog.SetRange("TriggerName", 'OnBeforeAction');
        TrigLog.FindFirst();
        SourceEntry := TrigLog."SourceEntryNo";
        Assert.AreEqual(10, SourceEntry, 'EntryNo (10) must be recorded in SourceEntryNo');
    end;

    [Test]
    procedure Subscriber_OnAfterAction_ResultAccessible()
    var
        Publisher: Codeunit "ALT Event Publisher";
        TrigLog: Record "ALT Trigger Log";
        ResultValue: Text[100];
    begin
        Initialize();
        Publisher.TriggerAfter(5, 777);
        TrigLog.SetRange("TriggerName", 'OnAfterAction');
        TrigLog.FindFirst();
        ResultValue := TrigLog.NewValue;
        Assert.AreEqual('777', ResultValue, 'Result (777) must be accessible in NewValue field');
    end;

    [Test]
    procedure Subscriber_MultipleEvents_AllCaptured()
    var
        Publisher: Codeunit "ALT Event Publisher";
        TrigLog: Record "ALT Trigger Log";
        Count: Integer;
    begin
        Initialize();
        Publisher.TriggerBefore(1);
        Publisher.TriggerAfter(2, 0);
        Publisher.TriggerInternal(3);
        TrigLog.Reset();
        Count := TrigLog.Count();
        Assert.AreEqual(3, Count, 'All 3 events (Before, After, Internal) must be logged');
    end;

    [Test]
    procedure Subscriber_AfterInitialize_LogIsEmpty()
    var
        TrigLog: Record "ALT Trigger Log";
        Count: Integer;
    begin
        Initialize();
        TrigLog.Reset();
        Count := TrigLog.Count();
        Assert.AreEqual(0, Count, 'Log must be empty after Initialize()');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
