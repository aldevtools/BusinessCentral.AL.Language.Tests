// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/report/devenv-oninitreport-report-trigger
// Scope: in-scope
// Fixtures used: Assert (60021), "OIR Log" (60005), reports 60005 / 60006 in
//                TestReportOnInitReportTimingFixtures.al; Base Application page 5094
//                "Marketing Setup" and report 5181 "Relocate Attachments"
//
// WHEN OnInitReport runs, and that it runs when Base Application code runs the report.
//
// Written for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4656, where a report run
// by BC's own report engine (precompiled REPORT.Run) never ran OnInitReport at all. Nothing
// here predicts the runner's answer.
//
// Claims:
//   1. Report.Run on a report variable runs OnInitReport exactly once, before the body.
//   2. OnInitReport runs when the report variable is first used, not when Run() is called:
//      a procedure call on the variable already counts one OnInitReport, and a value that
//      call writes survives into the body rather than being overwritten by OnInitReport.
//   3. The static Report.Run(id) runs it exactly once too.
//   4. CurrReport.Quit() in OnInitReport stops the run: neither OnPreReport nor the body runs.
//   5. REPORT.Run called from Base Application code runs the report's OnInitReport: page 5094's
//      SetAttachmentStorageType runs REPORT.Run(REPORT::"Relocate Attachments"), whose
//      OnInitReport is `if not Confirm(...) then CurrReport.Quit();` and whose only request
//      page has no fields (UseRequestPage = false). So the [ConfirmHandler] is called exactly
//      once, and answering No ends the run there.
codeunit 60006 "Test OnInitReport Timing"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Log: Codeunit "OIR Log";
        ConfirmCalls: Integer;
        ConfirmQuestion: Text;

    [Test]
    procedure ReportVarRun_OnInitReportRunsOnceBeforeTheBody()
    var
        Probe: Report "OIR Init Probe";
    begin
        Log.Reset();

        Probe.Run();

        Assert.AreEqual(1, Log.GetInitCount(), 'OnInitReport must run exactly once for one Report.Run');
        Assert.AreEqual(1, Log.GetBodyCount(), 'the one-row body must run once');
        Assert.AreEqual('from-oninitreport', Log.GetBodySaw(), 'the body must see the value OnInitReport set');
    end;

    [Test]
    procedure ReportVarFirstUse_RunsOnInitReport_BeforeRunIsCalled()
    var
        Probe: Report "OIR Init Probe";
    begin
        Log.Reset();

        Probe.SetSetting('from-caller');

        Assert.AreEqual(1, Log.GetInitCount(), 'the first call on the report variable must already have run OnInitReport');
        Assert.AreEqual(0, Log.GetBodyCount(), 'nothing has run the report yet');
    end;

    [Test]
    procedure ReportVarSetterBeforeRun_SurvivesOnInitReport()
    var
        Probe: Report "OIR Init Probe";
    begin
        Log.Reset();

        Probe.SetSetting('from-caller');
        Probe.Run();

        Assert.AreEqual('from-caller', Log.GetBodySaw(), 'a value the caller set before Run must not be overwritten by OnInitReport');
        Assert.AreEqual(1, Log.GetInitCount(), 'OnInitReport must run once for the setter and the Run together');
    end;

    [Test]
    procedure StaticReportRun_OnInitReportRunsOnce()
    begin
        Log.Reset();

        Report.Run(Report::"OIR Init Probe");

        Assert.AreEqual(1, Log.GetInitCount(), 'OnInitReport must run exactly once for the static Report.Run');
        Assert.AreEqual('from-oninitreport', Log.GetBodySaw(), 'the body must see the value OnInitReport set');
    end;

    [Test]
    procedure QuitInOnInitReport_StopsPreReportAndBody()
    var
        Probe: Report "OIR Quit Probe";
    begin
        Log.Reset();

        Probe.Run();

        Assert.AreEqual(1, Log.GetInitCount(), 'OnInitReport must run once');
        Assert.AreEqual(0, Log.GetBodyCount(), 'Quit in OnInitReport must stop OnPreReport and the body');
    end;

    [Test]
    [HandlerFunctions('RelocateConfirmNo')]
    procedure BaseAppReportRun_RunsOnInitReport_ConfirmReachesHandlerOnce()
    var
        MarketingSetup: Record "Marketing Setup";
        MarketingSetupPage: Page "Marketing Setup";
    begin
        if not MarketingSetup.Get() then
            MarketingSetup.Insert();
        MarketingSetup."Attachment Storage Type" := MarketingSetup."Attachment Storage Type"::Embedded;
        MarketingSetup.Modify();
        Commit();
        ConfirmCalls := 0;
        ConfirmQuestion := '';

        MarketingSetupPage.SetRecord(MarketingSetup);
        MarketingSetupPage.SetAttachmentStorageType();

        Assert.AreEqual(1, ConfirmCalls, 'report 5181''s OnInitReport Confirm must reach the handler exactly once');
        Assert.AreEqual('Do you want to relocate existing attachments?', ConfirmQuestion,
            'the Confirm the handler saw must be the one report 5181''s OnInitReport raises');
    end;

    [ConfirmHandler]
    procedure RelocateConfirmNo(Question: Text[1024]; var Reply: Boolean)
    begin
        ConfirmCalls += 1;
        ConfirmQuestion := Question;
        Reply := false;
    end;
}
