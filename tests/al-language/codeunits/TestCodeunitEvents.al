// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Fixtures used: ALT Event Publisher (60014), ALT Trigger Log (60003)
// Note: ALT Event Subscriber (60015) is permanently subscribed and logs events to ALT Trigger Log

codeunit 60080 "Test Codeunit Events"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Event Publishing and Subscription ────────────────────────────────────

    [Test]
    procedure Event_TriggerBefore_LogsOnBeforeAction()
    var
        Publisher: Codeunit "ALT Event Publisher";
        TrigLog: Record "ALT Trigger Log";
        Count: Integer;
    begin
        Initialize();
        Publisher.TriggerBefore(1);
        TrigLog.SetRange("TriggerName", 'OnBeforeAction');
        Count := TrigLog.Count();
        Assert.AreEqual(1, Count, 'OnBeforeAction must be logged exactly once');
    end;

    [Test]
    procedure Event_TriggerAfter_LogsOnAfterAction()
    var
        Publisher: Codeunit "ALT Event Publisher";
        TrigLog: Record "ALT Trigger Log";
        Count: Integer;
    begin
        Initialize();
        Publisher.TriggerAfter(1, 42);
        TrigLog.SetRange("TriggerName", 'OnAfterAction');
        Count := TrigLog.Count();
        Assert.AreEqual(1, Count, 'OnAfterAction must be logged exactly once');
    end;

    [Test]
    procedure Event_TriggerInternal_LogsOnInternalStep()
    var
        Publisher: Codeunit "ALT Event Publisher";
        TrigLog: Record "ALT Trigger Log";
        Count: Integer;
    begin
        Initialize();
        Publisher.TriggerInternal(5);
        TrigLog.SetRange("TriggerName", 'OnInternalStep');
        Count := TrigLog.Count();
        Assert.AreEqual(1, Count, 'OnInternalStep must be logged exactly once');
    end;

    [Test]
    procedure Event_MultiplePublishes_AllLogged()
    var
        Publisher: Codeunit "ALT Event Publisher";
        TrigLog: Record "ALT Trigger Log";
        Count: Integer;
    begin
        Initialize();
        Publisher.TriggerBefore(1);
        Publisher.TriggerBefore(2);
        Publisher.TriggerBefore(3);
        TrigLog.SetRange("TriggerName", 'OnBeforeAction');
        Count := TrigLog.Count();
        Assert.AreEqual(3, Count, 'All three OnBeforeAction events must be logged');
    end;

    [Test]
    procedure Event_TriggerAfter_ResultInLog()
    var
        Publisher: Codeunit "ALT Event Publisher";
        TrigLog: Record "ALT Trigger Log";
        NewValue: Text[100];
    begin
        Initialize();
        Publisher.TriggerAfter(1, 99);
        TrigLog.SetRange("TriggerName", 'OnAfterAction');
        TrigLog.FindFirst();
        NewValue := TrigLog.NewValue;
        Assert.AreEqual('99', NewValue, 'Result value (99) must be formatted and stored in NewValue');
    end;

    [Test]
    procedure Event_TriggerInternal_StepInLog()
    var
        Publisher: Codeunit "ALT Event Publisher";
        TrigLog: Record "ALT Trigger Log";
        SourceEntry: Integer;
    begin
        Initialize();
        Publisher.TriggerInternal(7);
        TrigLog.SetRange("TriggerName", 'OnInternalStep');
        TrigLog.FindFirst();
        SourceEntry := TrigLog.SourceEntryNo;
        Assert.AreEqual(7, SourceEntry, 'Step value (7) must be recorded in SourceEntryNo');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
