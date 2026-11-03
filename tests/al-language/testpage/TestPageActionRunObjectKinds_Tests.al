// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runobject-property
// Scope: in-scope
// Fixtures used: TPAROK Row (60550), TPAROK Log (60551), TPAROK Probe (60552),
//                TPAROK Host (60553), TPAROK Report (60554), TPAROK Silent Report (60555),
//                TPAROK Runner (60556), TPAROK XmlPort (60557), TPAROK Query (60558),
//                Assert (60021)
//
// What a page action's RunObject does when it names something that is NOT a page.
//
// RunObject accepts five kinds. The corpus pins the page kind twice already -- codeunit 60455
// for the handler case and codeunit 60285 for the no-handler case. This codeunit is the other
// four: Report, Codeunit, XmlPort and Query. They are not variations on the page case. BC's
// action builder (ActionBuilder.CreateRunObject, Microsoft.Dynamics.Nav.Client.Builder.dll)
// switches on ActionDefinition.RunObjectType and produces a DIFFERENT action object for each:
//
//     Page      -> CreateNavOpenTaskPageAction(...)
//     Codeunit  -> new InvokeCodeUnitAction(actionDef.TargetID)
//     Report    -> new RunReportAction(actionDef.TargetID)
//     XMLport   -> new RunXmlPortAction(actionDef.TargetID)
//     Query     -> CreateNavOpenTaskPageAction(..., DataSourceType.Query)
//
// That is read from Microsoft's shipped IL and is why the four kinds are four questions rather
// than one. What the IL does NOT settle is what each of those action objects does in a TEST
// session, where there is no client to render anything and handler binding decides what an
// unattended UI event becomes. That is what this codeunit measures, and only a service tier can
// answer it.
//
// THE QUESTIONS, one per kind, taken from AL Runner issue 2943 -- and THE ANSWERS the eight
// cloud legs gave when this file first ran (run 34150170570). The answers are recorded here
// because three of the four came out the OPPOSITE way to what the shipped IL above suggests,
// and a reader who only sees the corrected assertions has no way to know that:
//
//   * Report   -- does the action open the report's REQUEST PAGE or run the body directly, and
//                 does UseRequestPage = false change it?
//                 ANSWER: neither. The TestPage surface REFUSES the route outright, with
//                 "The method RunReport is not supported for TestPages." UseRequestPage does
//                 not change it: both the request-page report and the silent one are refused
//                 identically, so the property is not consulted before the refusal.
//   * Codeunit -- does Codeunit.Run happen at all, which record is it given, and does
//                 RunPageOnRec mean anything on a non-page target?
//                 ANSWER: it RUNS -- the one kind of the four that does -- and it is handed the
//                 host page's CURRENT ROW. RunPageOnRec makes NO observable difference: the
//                 with- and without- arms both measure 'Bravo'. That last point is the one this
//                 file got wrong on its first run, having assumed the property was load-bearing
//                 for a codeunit the way it is for a page.
//   * XmlPort  -- does it run, and is a request page involved?
//                 ANSWER: refused, "The method RunXmlPort is not supported for TestPages.",
//                 before any request-page question arises.
//   * Query    -- what is "opening a query" in a test session at all?
//                 ANSWER: refused ONE STEP EARLIER than the other two, with "The method
//                 GetQueryTableMetadata is not supported for TestPages." The other refusals
//                 name a run method; this one never reaches a run method, because building the
//                 generated page over the query needs the query's metadata first. So the IL's
//                 "Query routes through CreateNavOpenTaskPageAction like a Page" is true and
//                 still does not make a query target behave like a page target -- the page kind
//                 opens unattended (codeunit 60285), the query kind cannot even be resolved.
//
// The through-line: of the five RunObject kinds, a TestPage session performs exactly two --
// Page (opens unattended) and Codeunit (runs, on the host's row). The other three are refused
// by the TestPage surface itself, not by the action builder, which is why the IL's per-kind
// dispatch does not predict the outcome.
//
// HOW THE ARMS ARE BUILT, and why they look the way they do.
//
// Every arm is an honest experiment rather than a restatement of an expectation, because when
// this file was written NONE of the four answers was known. Two consequences shape the code:
//
//   1. Where the outcome could legitimately be either "it runs" or "it is refused", the arm
//      states the observable it found and asserts THAT -- with a message naming what a
//      different outcome would have meant. An arm that guessed would have had to be rewritten
//      after the first CI run anyway, and the rewrite is where a wrong guess quietly becomes an
//      assertion nobody re-checked. Three of the four arms WERE rewritten after that first run,
//      which is this mechanism working as intended rather than a failure of it: the guesses
//      were falsified by a service tier before they ever entered the corpus, and each rewrite
//      asserts the exact message the tier produced instead of a weaker "something was raised".
//      A refused arm asserts the message text precisely because the three refusals differ from
//      each other, and a bare asserterror could not tell them apart.
//   2. Where an arm invokes inside asserterror, it reads the SingleInstance probe rather than
//      the log table. A refusal discards the uncommitted rows of the transaction it unwinds --
//      measured on all eight cloud legs while building codeunit 60285 -- so a missing log row
//      on such an arm is missing whether the target ran or not. The probe is memory; no
//      rollback reaches it. Arm PROBE proves the probe really is set when a target does run,
//      without which every negative here would be unfalsifiable.
//
// Written by agent stma-auto-32, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue 2943. Corrected against run 34150170570's verdict by
// agent stma-auto-2, likewise automated and acting on the account holder's behalf.

codeunit 60559 "TPAROK Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        RequestPageHandlerRan: Boolean;

    local procedure Initialize()
    var
        Row: Record "TPAROK Row";
        Log: Record "TPAROK Log";
        Probe: Codeunit "TPAROK Probe";
    begin
        Row.DeleteAll();
        Log.DeleteAll();
        Probe.Reset();
        RequestPageHandlerRan := false;

        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();

        Row.Init();
        Row."No." := 'B';
        Row.Descr := 'Bravo';
        Row.Insert();
    end;

    // PROBE CONTROL. Without this arm every negative below is unfalsifiable: a probe nobody
    // ever sets reports exactly what "the target never ran" reports. This proves each of the
    // three recordable targets really does mark the probe, and really does write its log row,
    // when it is run by an ordinary AL call with nothing to do with an action.
    //
    // It is deliberately the only arm that reaches the targets without a host page, so a
    // failure here means the FIXTURES are broken rather than that RunObject is.
    [Test]
    [HandlerFunctions('ConfirmingRequestPageHandler')]
    procedure ProbeControlEachTargetRecordsItsOwnExecution()
    var
        Row: Record "TPAROK Row";
        Log: Record "TPAROK Log";
        Probe: Codeunit "TPAROK Probe";
        SilentReport: Report "TPAROK Silent Report";
        TheXmlPort: XmlPort "TPAROK XmlPort";
        TempBlob: Codeunit "Temp Blob";
        Outbound: OutStream;
    begin
        Initialize();
        Commit();

        // The codeunit, handed a specific row, so the "which record" assertions later have a
        // known-good comparison.
        Row.Get('B');
        Codeunit.Run(Codeunit::"TPAROK Runner", Row);
        Assert.IsTrue(Probe.GetCodeunitRan(), 'the codeunit target must record its own OnRun when it really runs');
        Assert.AreEqual('Bravo', Probe.GetCodeunitRecSeen(),
            'the codeunit target must record the record it was handed, otherwise the RunObject arms cannot tell which record BC gave it');
        Assert.IsTrue(Log.Get('CODEUNIT'), 'the codeunit target must write its log row when it really runs');

        // The silent report: no request page, so nothing has to be bound for it to run.
        Probe.Reset();
        Clear(SilentReport);
        SilentReport.Run();
        Assert.IsTrue(Probe.GetReportRan(), 'the silent report must record its own OnPreReport when it really runs');
        Assert.AreEqual(2, Probe.GetReportRowCount(),
            'the silent report must iterate both seeded rows, otherwise a row count elsewhere means nothing');

        // The report WITH a request page, confirmed by a bound handler. This also establishes
        // that the request-page probe fires, which is what the report RunObject arms read to
        // tell "refused" from "ran quietly".
        //
        // Commit() first, and it is load-bearing. The codeunit and the silent report above each
        // inserted a log row that is still uncommitted here, and opening a report's request page
        // with writes pending raises "An error occurred and the transaction is stopped". Corpus
        // 60933 runs a report with a bound [RequestPageHandler] and passes -- it commits in its
        // own Initialize() -- so what matters is the pending write, not which call form is used.
        Probe.Reset();
        Commit();
        Report.Run(Report::"TPAROK Report");
        Assert.IsTrue(RequestPageHandlerRan, 'the bound [RequestPageHandler] must run when the report is run by AL');
        Assert.IsTrue(Probe.GetRequestPageOpened(), 'the report''s request page must record its own OnOpenPage when it really opens');
        Assert.IsTrue(Probe.GetReportRan(), 'a confirmed request page must let the report body run');
        Assert.AreEqual(2, Probe.GetReportRowCount(), 'the confirmed report must iterate both seeded rows');

        // The xmlport, exported into a temp blob so nothing waits on a file. Direction =
        // Export with UseRequestPage = false, so no handler is needed and nothing negotiates.
        Probe.Reset();
        Clear(TheXmlPort);
        TempBlob.CreateOutStream(Outbound);
        TheXmlPort.SetDestination(Outbound);
        TheXmlPort.Export();
        Assert.IsTrue(Probe.GetXmlPortRan(),
            'the xmlport target must record its own OnPreXmlPort when it really runs, otherwise the RunObject arm''s negative is unfalsifiable');
        Assert.IsTrue(Log.Get('XMLPORT'), 'the xmlport target must write its log row when it really runs');
    end;

    // REPORT, the kind that is 1,037 of the 1,210 non-page RunObject targets in Base
    // Application 28.1 -- so whatever this arm measures is the practical whole of the question.
    //
    // NO [RequestPageHandler] is bound, and that is the measured shape rather than an omission.
    // One was bound while the answer was unknown, to tell "opens the request page, handler runs,
    // body then runs" from "runs the body directly, handler never called". The tier produced a
    // third answer neither allowed for -- the route is refused before the request page -- and at
    // that point the binding became unusable in both directions: the framework fails a test whose
    // declared handler never fires, so the arm could not pass, and its own
    // Assert.IsFalse(RequestPageHandlerRan) could never be reached to fail either.
    //
    // The probe carries the claim instead. GetRequestPageOpened() is written by the request
    // page's own OnOpenPage, so "the refusal preceded the request page" is asserted by something
    // the refusal cannot fake, and the arm stays falsifiable without binding a handler that
    // cannot run.
    //
    // The invoke IS wrapped in asserterror, which it was not when this file was first written.
    // Then, an unwrapped invoke was the honest shape: the answer was unknown and a refusal
    // should fail loudly on the invoke line rather than be pre-absorbed by an asserterror that
    // assumed one. It failed exactly that way on all eight cloud legs, which is how the answer
    // was obtained, and asserterror is now the honest shape for the answer that came back.
    [Test]
    procedure RunObjectNamingAReportIsRefusedByTheTestPageSurface()
    var
        Probe: Codeunit "TPAROK Probe";
        Host: TestPage "TPAROK Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        asserterror Host.RunTheReport.Invoke();

        Assert.ExpectedError('The method RunReport is not supported for TestPages.');
        Assert.IsFalse(Probe.GetReportRan(),
            'a refused report RunObject must not have run the report body anyway');
        Assert.IsFalse(Probe.GetRequestPageOpened(),
            'the refusal must precede the request page -- no [RequestPageHandler] is bound here, because a bound handler that never fires is itself a test failure and would mask this');
    end;

    // REPORT with UseRequestPage = false, which the issue calls out as possibly different. No
    // handler is bound and none can be: there is no request page to hand to one.
    //
    // The answer is that the property makes no difference: this arm and the one above are
    // refused with the SAME message, so the TestPage surface declines the report route before
    // it consults UseRequestPage at all. Keeping the arm is what establishes that -- one
    // refused report would leave open whether the request page was the thing being refused.
    [Test]
    procedure RunObjectNamingAReportWithNoRequestPageIsRefusedTheSameWay()
    var
        Probe: Codeunit "TPAROK Probe";
        Host: TestPage "TPAROK Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        asserterror Host.RunTheSilentReport.Invoke();

        Assert.ExpectedError('The method RunReport is not supported for TestPages.');
        Assert.IsFalse(Probe.GetReportRan(),
            'a refused report RunObject must not have run the report body, UseRequestPage = false or not');
    end;

    // CONTROL for both report arms: the SAME report target, same host, same invoke, reached by
    // an OnAction trigger calling Report.Run instead of by a RunObject declaration.
    //
    // This is the arm that makes the two refusals above mean something. It PASSES -- the report
    // runs, its request page opens, the bound handler is reached -- from an OnAction trigger on
    // the very same TestPage, in the very same session. So what the TestPage surface refuses is
    // specifically the RunObject ROUTE to a report, not reports, not this report, and not
    // running a report from a TestPage at all. Without this control, "RunReport is not
    // supported for TestPages" would read as the far broader claim its wording suggests.
    [Test]
    [HandlerFunctions('ConfirmingRequestPageHandler')]
    procedure ControlTriggerActionRunningTheSameReportBehavesTheSameWay()
    var
        Probe: Codeunit "TPAROK Probe";
        Host: TestPage "TPAROK Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        Host.RunTheReportViaTrigger.Invoke();

        Assert.IsTrue(Probe.GetReportRan(), 'the control''s Report.Run must run the report body');
        Assert.AreEqual(2, Probe.GetReportRowCount(), 'the control must iterate both seeded rows');
        Assert.IsTrue(Probe.GetRequestPageOpened(), 'the control''s Report.Run must open the request page');
        Assert.IsTrue(RequestPageHandlerRan, 'the control''s request page must reach the bound handler');
    end;

    // CODEUNIT, 155 of the non-page targets, and the ONLY one of the four kinds a TestPage
    // session actually performs. Two questions in one arm: does it run at all, and which record
    // does its OnRun see? The host is parked on the SECOND row, so a codeunit handed the host's
    // current record reports 'Bravo' and one handed a fresh, unpositioned record reports the
    // empty string -- two outcomes this arm can tell apart, which is what makes 'Bravo' below a
    // measurement rather than a restatement.
    //
    // This action does NOT declare RunPageOnRec, and the next arm is the same target WITH it.
    // The pair is how the issue's "does RunPageOnRec mean anything for a codeunit" question got
    // an answer rather than an opinion, and the answer is NO: both arms measure 'Bravo', so the
    // property changes nothing observable on a codeunit target. This arm originally asserted ''
    // here on the assumption that RunPageOnRec is what hands over the row, as it is for a page;
    // eight service tiers falsified that in run 34150170570 and it now asserts what they said.
    //
    // Keeping BOTH arms after learning they agree is deliberate. They now assert the same
    // value, which looks redundant and is not: the pair is the only thing that would catch a
    // future BC version making RunPageOnRec start to matter here, and that is exactly the
    // change most likely to go unnoticed.
    [Test]
    procedure RunObjectNamingACodeunitRunsItOnTheHostsRow()
    var
        Probe: Codeunit "TPAROK Probe";
        Host: TestPage "TPAROK Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunTheCodeunit.Invoke();

        Assert.IsTrue(Probe.GetCodeunitRan(),
            'a RunObject action naming a codeunit must run it: OnRun never fired');
        Assert.AreEqual('Bravo', Probe.GetCodeunitRecSeen(),
            'a codeunit target is handed the host page''s current row even WITHOUT RunPageOnRec');
    end;

    // CODEUNIT with RunPageOnRec = true. Same target, same host, same row; the declaration is
    // the only difference from the arm above, so the pair isolates what RunPageOnRec does on a
    // non-page target. The host is on the second row, so 'Bravo' means the host's record was
    // passed and '' means it was not.
    [Test]
    procedure RunObjectNamingACodeunitWithRunPageOnRecIsHandedTheHostsRow()
    var
        Probe: Codeunit "TPAROK Probe";
        Host: TestPage "TPAROK Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunTheCodeunitOnRec.Invoke();

        Assert.IsTrue(Probe.GetCodeunitRan(),
            'a RunObject action naming a codeunit with RunPageOnRec must run it');
        Assert.AreEqual('Bravo', Probe.GetCodeunitRecSeen(),
            'RunPageOnRec on a codeunit target must hand the codeunit the host page''s current row');
    end;

    // XMLPORT, 7 of the non-page targets. Direction = Export, UseRequestPage = false, so
    // nothing waits on a stream a test session cannot supply -- an arrangement that removes
    // every reason the route COULD have been refused for, which is what makes the refusal the
    // tier reported a fact about the TestPage surface rather than about this fixture.
    [Test]
    procedure RunObjectNamingAnXmlPortIsRefusedByTheTestPageSurface()
    var
        Probe: Codeunit "TPAROK Probe";
        Host: TestPage "TPAROK Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        asserterror Host.RunTheXmlPort.Invoke();

        Assert.ExpectedError('The method RunXmlPort is not supported for TestPages.');
        Assert.IsFalse(Probe.GetXmlPortRan(),
            'a refused xmlport RunObject must not have run OnPreXmlPort anyway');
    end;

    // QUERY, 11 of the non-page targets, and the kind with no AL surface of its own: a query
    // has no trigger, so nothing inside it can record that it ran.
    //
    // BC's builder routes a query target through the same CreateNavOpenTaskPageAction as a
    // page, with DataSourceType.Query -- so the shipped IL suggested a query target would
    // behave like the page kind, which OPENS unattended (codeunit 60285 arm 1). Eight service
    // tiers say otherwise: it is refused, and refused ONE STEP EARLIER than the report and
    // xmlport kinds. Those two name the run method they declined (RunReport, RunXmlPort);
    // the query kind never reaches a run method at all, because building the generated page
    // over the query needs GetQueryTableMetadata first, and THAT is what the TestPage surface
    // refuses.
    //
    // That distinction is the reason this arm asserts the exact message rather than merely
    // that something was raised: "refused" and "refused before it could even resolve the
    // query's shape" are different facts, and only the message tells them apart.
    [Test]
    procedure RunObjectNamingAQueryIsRefusedBeforeItsMetadataIsResolved()
    var
        Host: TestPage "TPAROK Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        asserterror Host.RunTheQuery.Invoke();

        Assert.ExpectedError('The method GetQueryTableMetadata is not supported for TestPages.');
    end;

    [RequestPageHandler]
    procedure ConfirmingRequestPageHandler(var RequestPage: TestRequestPage "TPAROK Report")
    begin
        RequestPageHandlerRan := true;
        RequestPage.OK().Invoke();
    end;
}
