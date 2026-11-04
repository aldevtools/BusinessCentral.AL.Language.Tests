// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: ALT Internal Codeunit (61000), ALT Internals Subscriber (60020), ALT Internals Fanout Subscriber (60017), ALT Trigger Log (60003)
// BC versions: 27.5+

codeunit 60209 "Test Integration Event Fanout"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure IntegrationEvent_Fanout_MultipleSubscribers_AllReceiveSinglePublish()
    var
        InternalCU: Codeunit "ALT Internal Codeunit";
    begin
        Initialize();

        InternalCU.ComputeAndPublish(5);

        AssertSubscriberLog('OnValueComputed', 5, '10');
        AssertSubscriberLog('OnValueComputedA', 5, '10');
        AssertSubscriberLog('OnValueComputedB', 5, '10');
    end;

    [Test]
    procedure IntegrationEvent_Fanout_MultiplePublishes_ReachesAllSubscribersEachTime()
    var
        InternalCU: Codeunit "ALT Internal Codeunit";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();

        InternalCU.ComputeAndPublish(2);
        InternalCU.ComputeAndPublish(4);

        TrigLog.SetRange("TriggerName", 'OnValueComputed');
        Assert.AreEqual(2, TrigLog.Count(), 'Primary subscriber must fire once per publish');

        TrigLog.SetRange("TriggerName", 'OnValueComputedA');
        Assert.AreEqual(2, TrigLog.Count(), 'Fanout subscriber A must fire once per publish');

        TrigLog.SetRange("TriggerName", 'OnValueComputedB');
        Assert.AreEqual(2, TrigLog.Count(), 'Fanout subscriber B must fire once per publish');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    local procedure AssertSubscriberLog(TriggerName: Code[30]; ExpectedValue: Integer; ExpectedResult: Text[100])
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.SetRange("TriggerName", TriggerName);
        Assert.IsTrue(TrigLog.FindFirst(), StrSubstNo('%1 subscriber must receive the publish', TriggerName));
        Assert.AreEqual(ExpectedValue, TrigLog."SourceEntryNo", StrSubstNo('%1 subscriber must see the published value', TriggerName));
        Assert.AreEqual(ExpectedResult, TrigLog."NewValue", StrSubstNo('%1 subscriber must see the published result', TriggerName));
    end;
}
