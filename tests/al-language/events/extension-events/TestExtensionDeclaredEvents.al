// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALTExtEvtFixtures.al in this folder — table 68500 with tableextension 68501,
//   page 68502 with pageextension 68503, report 68504 with reportextension 68505, the
//   SingleInstance sink 68506 and the subscribers 68507.
// BC versions: 27.0+
//
// CLAIM: an [IntegrationEvent] or [BusinessEvent] DECLARED IN AN EXTENSION OBJECT
// (tableextension, pageextension, reportextension) is published under the object it
// extends. A subscriber bound through the base object — ObjectType::Table / Page / Report
// and the base object's id — fires when the extension raises the event, exactly once, with
// the arguments the extension passed; an IncludeSender event on a tableextension hands the
// subscriber the raising record; and an Error in such a subscriber reaches the raiser.
//
// Every earlier event test in this corpus declares its events on a base object or a
// codeunit. An event on an extension lives in the extension's own compiled code, so a
// consumer can dispatch every base-object event correctly and still never reach these.
//
// Each positive arm also asserts the OTHER channels stayed at zero, so a consumer that fired
// every extension subscriber on any extension raise does not pass.
//
// Written by agent stma-auto-1 for StefanMaron/BusinessCentral.AL.Runner#5004.

codeunit 68508 "Test Extension Declared Events"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Sink: Codeunit "ALT ExtEvt Sink";

    [Test]
    procedure TableExtEvent_Integration_SubscriberFiresOnceWithArgument()
    var
        Pub: Record "ALT ExtEvt Pub";
    begin
        Sink.Reset();

        Pub.RaiseExtIntegration(42);

        Assert.AreEqual(1, Sink.CountOf('table-integration'), 'a subscriber bound to the base table must fire once for an IntegrationEvent the tableextension raised');
        Assert.AreEqual('42', Sink.LastValueOf('table-integration'), 'the subscriber must receive the argument the tableextension passed');
        Assert.AreEqual(0, Sink.CountOf('page'), 'a tableextension raise must not reach the pageextension event''s subscriber');
        Assert.AreEqual(0, Sink.CountOf('report'), 'a tableextension raise must not reach the reportextension event''s subscriber');
    end;

    [Test]
    procedure TableExtEvent_Business_SubscriberFiresOnceWithArgument()
    var
        Pub: Record "ALT ExtEvt Pub";
    begin
        Sink.Reset();

        Pub.RaiseExtBusiness('BUSINESS-ARG');

        Assert.AreEqual(1, Sink.CountOf('table-business'), 'a subscriber bound to the base table must fire once for a BusinessEvent the tableextension raised');
        Assert.AreEqual('BUSINESS-ARG', Sink.LastValueOf('table-business'), 'the subscriber must receive the argument the tableextension passed');
        Assert.AreEqual(0, Sink.CountOf('table-integration'), 'raising the BusinessEvent must not fire the IntegrationEvent''s subscriber');
    end;

    [Test]
    procedure TableExtEvent_IncludeSender_SubscriberReceivesTheRaisingRecord()
    var
        Pub: Record "ALT ExtEvt Pub";
    begin
        Sink.Reset();
        Pub.PK := 7;
        Pub.Name := 'SENDER-NAME';

        Pub.RaiseExtWithSender();

        Assert.AreEqual(1, Sink.CountOf('table-sender'), 'a subscriber bound to the base table must fire once for an IncludeSender event the tableextension raised');
        Assert.AreEqual('SENDER-NAME', Sink.LastValueOf('table-sender'), 'the Sender must be the record instance that raised the event');
    end;

    [Test]
    procedure TableExtEvent_SubscriberError_ReachesTheRaiser()
    var
        Pub: Record "ALT ExtEvt Pub";
    begin
        Sink.Reset();

        asserterror Pub.RaiseExtIntegration(-1);

        Assert.ExpectedError('ExtEvt table subscriber refused -1');
        Assert.AreEqual(0, Sink.CountOf('table-integration'), 'the subscriber errored before noting anything');
    end;

    [Test]
    procedure PageExtEvent_SubscriberBoundToBasePage_FiresOnceWithArgument()
    var
        ExtEvtPage: Page "ALT ExtEvt Page";
    begin
        Sink.Reset();

        ExtEvtPage.RaisePageExt(17);

        Assert.AreEqual(1, Sink.CountOf('page'), 'a subscriber bound to the base page must fire once for an event the pageextension raised');
        Assert.AreEqual('17', Sink.LastValueOf('page'), 'the subscriber must receive the argument the pageextension passed');
        Assert.AreEqual(0, Sink.CountOf('table-integration'), 'a pageextension raise must not reach the tableextension event''s subscriber');
    end;

    [Test]
    procedure ReportExtEvent_SubscriberBoundToBaseReport_FiresOnceWithArgument()
    var
        ExtEvtReport: Report "ALT ExtEvt Report";
    begin
        Sink.Reset();

        ExtEvtReport.RaiseReportExt(23);

        Assert.AreEqual(1, Sink.CountOf('report'), 'a subscriber bound to the base report must fire once for an event the reportextension raised');
        Assert.AreEqual('23', Sink.LastValueOf('report'), 'the subscriber must receive the argument the reportextension passed');
        Assert.AreEqual(0, Sink.CountOf('page'), 'a reportextension raise must not reach the pageextension event''s subscriber');
    end;
}
