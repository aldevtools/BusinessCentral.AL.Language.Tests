// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-publisher-subscriber
// Scope: in-scope
// Fixtures used: ALT Manual PageEvent Pub (60977), ALT Manual ReportEvent Pub (60978),
//                 ALT Manual QueryEvent Pub (60981), ALT Manual XmlPortEvent Pub (60982),
//                 ALT ManualObjEvt Ctrl Sub (60985), ALT Trigger Log (60003)
//
// Sibling coverage to TestManualTableIntegrationEvent.al (table- and codeunit-published
// manual [IntegrationEvent]s). This suite proves the same claim for the remaining publisher
// object kinds — Page, Report, Query and XmlPort: a manually-declared [IntegrationEvent]
// raised from inside one of THESE object kinds' own code must also reach its subscriber.
codeunit 60986 "Test Manual ObjectEvent"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure PageEvent_ManualIntegrationEvent_Subscriber_Fires()
    var
        Pub: Page "ALT Manual PageEvent Pub";
        TrigLog: Record "ALT Trigger Log";
    begin
        // [GIVEN] a page instance publishing a manually-declared IntegrationEvent
        Initialize();

        // [WHEN] the page's own code raises the event
        Pub.RaiseManualPageEvent(11);

        // [THEN] the publishing code itself ran, reaching the raise statement
        TrigLog.SetRange(TriggerName, 'ManualPagePubRan');
        TrigLog.SetRange(SourceEntryNo, 11);
        Assert.IsTrue(TrigLog.FindFirst(), 'control: the page publisher code did not run');

        // [THEN] the subscriber to the manually-declared page-published IntegrationEvent fired
        TrigLog.SetRange(TriggerName, 'ManualPageEventFired');
        TrigLog.SetRange(SourceEntryNo, 11);
        Assert.IsTrue(TrigLog.FindFirst(), 'manually-declared page-published IntegrationEvent subscriber must fire');
    end;

    [Test]
    procedure ReportEvent_ManualIntegrationEvent_Subscriber_Fires()
    var
        Pub: Report "ALT Manual ReportEvent Pub";
        TrigLog: Record "ALT Trigger Log";
    begin
        // [GIVEN] a report instance publishing a manually-declared IntegrationEvent from its
        // dataitem's OnPreDataItem trigger
        Initialize();
        Pub.SetSourceEntryNo(12);

        // [WHEN] the report runs
        Pub.RunModal();

        // [THEN] the publishing code itself ran, reaching the raise statement
        TrigLog.SetRange(TriggerName, 'ManualReportPubRan');
        TrigLog.SetRange(SourceEntryNo, 12);
        Assert.IsTrue(TrigLog.FindFirst(), 'control: the report publisher code did not run');

        // [THEN] the subscriber to the manually-declared report-published IntegrationEvent fired
        TrigLog.SetRange(TriggerName, 'ManualReportEventFired');
        TrigLog.SetRange(SourceEntryNo, 12);
        Assert.IsTrue(TrigLog.FindFirst(), 'manually-declared report-published IntegrationEvent subscriber must fire');
    end;

    [Test]
    procedure QueryEvent_ManualIntegrationEvent_Subscriber_Fires()
    var
        Pub: Query "ALT Manual QueryEvent Pub";
        TrigLog: Record "ALT Trigger Log";
    begin
        // [GIVEN] a query instance publishing a manually-declared IntegrationEvent
        Initialize();

        // [WHEN] the query's own code raises the event
        Pub.RaiseManualQueryEvent(13);

        // [THEN] the publishing code itself ran, reaching the raise statement
        TrigLog.SetRange(TriggerName, 'ManualQueryPubRan');
        TrigLog.SetRange(SourceEntryNo, 13);
        Assert.IsTrue(TrigLog.FindFirst(), 'control: the query publisher code did not run');

        // [THEN] the subscriber to the manually-declared query-published IntegrationEvent fired
        TrigLog.SetRange(TriggerName, 'ManualQueryEventFired');
        TrigLog.SetRange(SourceEntryNo, 13);
        Assert.IsTrue(TrigLog.FindFirst(), 'manually-declared query-published IntegrationEvent subscriber must fire');
    end;

    [Test]
    procedure XmlPortEvent_ManualIntegrationEvent_Subscriber_Fires()
    var
        Pub: XmlPort "ALT Manual XmlPortEvent Pub";
        TrigLog: Record "ALT Trigger Log";
    begin
        // [GIVEN] an xmlport instance publishing a manually-declared IntegrationEvent
        Initialize();

        // [WHEN] the xmlport's own code raises the event
        Pub.RaiseManualXmlPortEvent(14);

        // [THEN] the publishing code itself ran, reaching the raise statement
        TrigLog.SetRange(TriggerName, 'ManualXmlPortPubRan');
        TrigLog.SetRange(SourceEntryNo, 14);
        Assert.IsTrue(TrigLog.FindFirst(), 'control: the xmlport publisher code did not run');

        // [THEN] the subscriber to the manually-declared xmlport-published IntegrationEvent fired
        TrigLog.SetRange(TriggerName, 'ManualXmlPortEventFired');
        TrigLog.SetRange(SourceEntryNo, 14);
        Assert.IsTrue(TrigLog.FindFirst(), 'manually-declared xmlport-published IntegrationEvent subscriber must fire');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
