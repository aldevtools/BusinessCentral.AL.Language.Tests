// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runobject-property
// Scope: in-scope
// Fixtures used: TPARONH Row (60280), TPARONH Card Target (60281),
//                TPARONH Logging Target (60282), TPARONH Host (60283), TPARONH Log (60284),
//                TPARONH Open Probe (60286), TPARONH Dialog Target (page 60284), Assert (60021)
//
// What a page action's RunObject does when the test binds NO handler at all.
//
// Every other route BC offers for opening a page is refused when nothing is bound to answer
// it. The corpus pins two of them, and both pass on all eight BC versions this corpus runs:
// TestPageRunHandler_Tests.NonModalPageRunWithoutAHandlerIsRefused calls Page.Run straight
// from the test, and TestPageModalHandler_Tests.ModalPageWithoutAHandlerIsRefused invokes a
// page ACTION whose OnAction trigger calls Page.RunModal. Controls 2 and 3 below repeat both
// shapes on this codeunit's own fixtures, and they pass here too.
//
// The RunObject route does not behave that way. Measured on BC 27.0, 27.3, 27.5, 28.0, 28.1,
// 28.2, 28.3 and 28.4, identically on every one:
//
//   * Invoking the action raises nothing AL can see. An asserterror around the invoke fails
//     with "An error was expected inside an ASSERTERROR statement".
//   * The target page opens anyway. It runs its own OnOpenPage trigger, with nobody bound to
//     answer it.
//
// So the invoke is not dropped and the page is not refused. The page really opens; AL is
// simply never told. That is what arm 1 records, and it is the opposite of what this file
// asserted when it was first written.
//
// ---------------------------------------------------------------------------------------
// THE MECHANISM
//
// Read out of Microsoft's shipped assemblies -- Microsoft.Dynamics.Nav.Ncl.dll and
// Microsoft.Dynamics.Nav.Types.dll from BC 27.5. Nothing below is inferred from documentation
// or from a name; it is what Microsoft's own IL says, and it can be re-read there.
//
// One method decides whether an unattended page is refused. NavTestExecution.FindHandler:
//
//     private MethodInfo FindHandler(NavHandlerType handlerType,
//                                    NavApplicationObjectBase appObject,
//                                    bool throwIfNotFound = true,
//                                    string handlerDescription = null)
//     {
//         MethodInfo methodInfo = FindHandler(ha => ha.HandlerType == handlerType, appObject);
//         if (methodInfo == null && throwIfNotFound
//             && executingTestRunner != null && executingTestMethod != null)
//             throw new NavNCLMissingUIHandlerException(...);
//         return methodInfo;
//     }
//
// Both places that look a page handler up call the TWO-argument form, so both take the
// throwIfNotFound = true default, and both remaining guards hold for every test in this corpus
// -- a test method is executing, under a test runner:
//
//     NavTestExecution.TestHandleForm  -- its only caller in Ncl.dll is NavForm.RunAsync
//                                        (compiled as NavForm.<RunAsync>d__19), which is what
//                                        AL's own Page.Run / Page.RunModal await.
//     NavTestExecution.ShowForm       -- Ncl.dll contains NO caller for it; it is reached from
//                                        the client-callback layer above Ncl.
//
// Each of the two has a "no handler found" branch of its own, and NEITHER can be reached while
// a test is running, because the FindHandler call above it has already thrown:
//
//     TestHandleForm:  if (methodInfo == null) return false;
//     ShowForm:        if (methodInfo == null)
//                          throw NavTestPageInvokedWithoutHandlerException.Create(...);
//
// The two exception types are not interchangeable, and that is where the routes part
// (hierarchy verified in Microsoft.Dynamics.Nav.Types.dll):
//
//     NavNCLMissingUIHandlerException
//         -> NavNCLException -> NavException -> NavBaseException
//     NavTestPageInvokedWithoutHandlerException
//         -> NavTestBaseException -> NavNCLException -> NavException -> NavBaseException
//
// Only the second is a NavTestBaseException. A NavBaseException that is not a
// NavTestBaseException is handled by the form-showing path as an ordinary UI error -- shown,
// with the form force-closed -- instead of being rethrown into AL. The type Microsoft actually
// throws here is therefore the one AL cannot see.
//
// Why that matters on one route and not the other, and why the page still opens:
//
//   * Page.Run / Page.RunModal (controls 2 and 3): FindHandler throws from TestHandleForm
//     while NavForm.RunAsync is still on AL's own call stack, so the error surfaces to AL as
//     an ordinary runtime error -- "Unhandled UI". TestHandleForm also calls
//     Company.RegisterForm(form) only AFTER the handler lookup has succeeded, so on this route
//     a handler-less form is never registered and never opens. Nothing runs its OnOpenPage.
//     That is exactly what controls 2 and 3 measure.
//
//   * The RunObject action: Ncl.dll has no code that runs an action's RunObject at all -- its
//     only RunObject members are metadata and permission helpers -- so the target is opened by
//     the client-services layer above it. ShowForm, the handler lookup on that side, opens with
//     Company.GetRegisteredForm(handle): the form already EXISTS and is already REGISTERED
//     before any handler is looked for. So the page has been built and its OnOpenPage has
//     already run by the time BC discovers nobody is bound, and the throw then happens off
//     AL's call stack. Both halves of the measurement follow: the OnOpenPage row is there, and
//     AL sees nothing.
//
// This looks like a defect in Microsoft's code rather than a decision. Microsoft wrote
// NavTestPageInvokedWithoutHandlerException -- a NavTestBaseException, the kind that WOULD
// have reached AL -- for precisely this case, and their own throwIfNotFound = true default
// preempts it with a type that does not, leaving that throw statement unreachable. That
// reading explains the measurement; it is NOT what this codeunit asserts. What it asserts is
// only what eight service tiers did.
//
// Provenance, so a later reader can check this without its authors: the mechanism above is
// read from Microsoft's shipped IL and can be re-read from any BC 27.x or 28.x install. Every
// runtime number is from this corpus's CI, which runs a Linux BC image. That image is patched,
// so a stock Windows service tier could in principle differ -- but the exception hierarchy and
// the throwIfNotFound default are Microsoft's own, unpatched, and they predict what was
// measured.
// ---------------------------------------------------------------------------------------
//
// The six arms are one experiment, and the controls are what make arm 1 mean anything:
//
//   1. RunObjectActionWithoutAHandlerOpensItsTargetUnattended -- the answer, and the only arm
//      with a positive observable. It invokes the RunObject action aimed at the target that
//      records its own OnOpenPage, with nothing bound. The invoke is deliberately NOT wrapped
//      in asserterror: the claim is that nothing is raised, so a refusal fails the test on the
//      invoke line itself. The host is left on its SECOND row, so an open that did not carry
//      the host's record would report 'Alpha' instead of 'Bravo'.
//   2. ControlPageRunOnTheSameTargetWithoutAHandlerIsRefused -- the same target page, opened by
//      a plain AL Page.Run with no host page in the picture at all. It IS refused, which rules
//      out the target page and the fixture set. Passes.
//   3. ControlTriggerActionOpeningTheSameTargetWithoutAHandlerIsRefused -- same host, same
//      invoke, same target, same row; the action's effect is an OnAction trigger calling
//      Page.Run instead of a RunObject property. Rules out the action-invoke path. Passes.
//      With 2 and 3 passing, the RunObject DECLARATION is the only thing left that differs.
//   4. RunObjectActionOnTheControlsTargetWithoutAHandler_NoThrow -- the same action 2 and 3
//      mirror, aimed at the CLEAN Card target rather than the logging one, so the comparison
//      has a RunObject side on exactly the page those two controls refuse. Its whole claim is
//      that the statement completes, which is why its name says so: the clean target records
//      nothing by design, so there is nothing further here to assert.
//   5. ProbeControlTheLoggingTargetRecordsItsOwnOpening -- proves the probe arm 1 rests on.
//      With a handler bound, the logging target really does write its OPENED row and set its
//      in-memory probe, and the test really can read both -- so the row arm 1 finds means the
//      page opened, and the unset probe arm 6 finds means it did not. Passes.
//   6. ControlPageRunOnTheLoggingTargetWithoutAHandlerIsRefusedAndOpensNothing -- arm 1's
//      direct counterpart. Same logging target, same absent handler, reached by Page.Run
//      instead of RunObject. Asserts both that it IS refused and that nothing opened. It is
//      the one arm that does NOT read the log table: the refusal rolls the uncommitted rows
//      back, measured, so it reads an in-memory probe instead. Arm 5 controls that probe.
//      See the note on the arm for what was measured and why the shape changed.
//
// Arms 7-9 ask the same question of a DIALOG target (PageType = StandardDialog), which every
// arm above leaves open because both targets above are Cards. See the note above arm 7.
//
// Held out of the eight-test RunObject suite (TestPageActionRunObject_Tests, codeunit 60455)
// while this question was open, so that suite could merge; it stays silent on the no-handler
// case and points here. Tracked as AL Runner issue 2975, which was filed when the RunObject
// route appeared to open nothing at all on this tier. That premise no longer holds: codeunit
// 60455 is green on all eight versions, so the route does open its target and does reach a
// bound [PageHandler] -- and this codeunit settles the remaining arm, which is that it opens
// the target with no handler bound too.
//
// Written by an agent (impl-1 built the experiment; impl-5 settled it and rewrote this note;
// stma-auto2-5 added the dialog arms 7-9).

codeunit 60285 "TPARONH Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        DialogHandlerCalls: Integer;
        DialogHandlerDescr: Text[50];

    local procedure Initialize()
    var
        Row: Record "TPARONH Row";
        Log: Record "TPARONH Log";
        Probe: Codeunit "TPARONH Open Probe";
    begin
        Row.DeleteAll();
        Log.DeleteAll();
        Probe.Reset();

        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();

        Row.Init();
        Row."No." := 'B';
        Row.Descr := 'Bravo';
        Row.Insert();
    end;

    // THE ANSWER. No [HandlerFunctions] at all, on an action whose effect is declared with
    // RunObject. Every other route BC offers refuses this; the RunObject route does not. The
    // invoke is NOT wrapped in asserterror -- the claim is that nothing is raised, so if BC
    // refused it the way controls 2 and 3 below are refused, this test fails on the invoke
    // line with an unhandled 'Unhandled UI' error rather than passing quietly.
    //
    // The target then reports its own opening: the host is parked on the SECOND row, so an
    // implementation that opened the target without the host's record reads 'Alpha' here, and
    // one that did not open it at all finds no row at all. Arm 5 proves the probe works.
    [Test]
    procedure RunObjectActionWithoutAHandlerOpensItsTargetUnattended()
    var
        Log: Record "TPARONH Log";
        Host: TestPage "TPARONH Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunLoggingCardOnRec.Invoke();

        Assert.IsTrue(Log.Get('OPENED'),
            'a RunObject action invoked with no handler bound still opens its target page');
        Assert.AreEqual('Bravo', Log.Detail,
            'the unattended target opens on the host page''s current row, as RunPageOnRec = true');
    end;

    // CONTROL 1, passes. The very page the action above names, opened by a plain AL Page.Run
    // with no handler bound and no host page in the picture at all. It IS refused, which rules
    // out the target page, the fixture set and the absence of handlers as explanations for arm
    // 1. If this ever fails, arm 1 says nothing about RunObject and the comparison has to be
    // rebuilt.
    //
    // The asserterror IS the whole assertion, deliberately. The Card Target is kept free of an
    // OnOpenPage on purpose (see the objects file), so it writes nothing whether it opens or
    // not, and there is no post-invoke observable this arm could read. A log assertion here
    // would be unfalsifiable, which is why there is none.
    [Test]
    procedure ControlPageRunOnTheSameTargetWithoutAHandlerIsRefused()
    var
        Row: Record "TPARONH Row";
    begin
        Initialize();
        Commit();

        Row.Get('B');
        asserterror Page.Run(Page::"TPARONH Card Target", Row);
        Assert.ExpectedError('Unhandled UI');
    end;

    // CONTROL 2, passes, and the one that narrows the difference to the declaration. Same host
    // page, same invoke, same target, same row, same absent handler -- the action's effect is
    // an OnAction trigger calling Page.Run instead of a RunObject property. It IS refused, so
    // the action-invoke path is not what differs, and neither is the target: the RunObject
    // declaration is.
    //
    // As with control 1, the asserterror is the whole assertion: this arm opens the same clean
    // Card Target, which records nothing either way.
    [Test]
    procedure ControlTriggerActionOpeningTheSameTargetWithoutAHandlerIsRefused()
    var
        Host: TestPage "TPARONH Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        asserterror Host.RunCardViaTrigger.Invoke();
        Assert.ExpectedError('Unhandled UI');
    end;

    // The RunObject side of the comparison the two controls above set up: the SAME target page
    // they open, reached the one way that is not refused. Arm 1 had to switch to the logging
    // target to observe the opening, so without this arm nothing exercises RunObject against
    // the exact page controls 1 and 2 refuse.
    //
    // The whole claim is that the statement completes -- hence the name. The Card target is
    // deliberately kept clean, with no OnOpenPage of its own, so that the two refusal controls
    // cannot be disturbed by a write happening before BC refuses; that leaves nothing further
    // for this arm to assert. If BC refused this invoke the way it refuses controls 1 and 2,
    // the unhandled error would fail the test here.
    [Test]
    procedure RunObjectActionOnTheControlsTargetWithoutAHandler_NoThrow()
    var
        Host: TestPage "TPARONH Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        Host.RunCardOnRec.Invoke();
    end;

    // PROBE CONTROL, passes, and without it neither arm 1 nor arm 6 could pass for the right
    // reason. It proves BOTH of the logging target's records of its own opening fire, and are
    // visible to the test, when the page really does open:
    //
    //   * the 'OPENED' log ROW, which arm 1 reads -- so the row arm 1 finds means the page
    //     opened rather than that the fixture writes that row regardless;
    //   * the in-memory PROBE, which arm 6 reads -- so the false arm 6 gets from GetOpened()
    //     means the page did not open rather than that MarkOpened() is never called at all.
    //
    // The second half is what makes arm 6's negative falsifiable. A probe that no one ever set
    // would report exactly what arm 6 expects to see, so arm 6 alone cannot tell a page that
    // stayed shut from a probe that does not work.
    [Test]
    [HandlerFunctions('LoggingTargetPageHandler')]
    procedure ProbeControlTheLoggingTargetRecordsItsOwnOpening()
    var
        Row: Record "TPARONH Row";
        Log: Record "TPARONH Log";
        Probe: Codeunit "TPARONH Open Probe";
    begin
        Initialize();

        Row.Get('B');
        Page.Run(Page::"TPARONH Logging Target", Row);

        Assert.IsTrue(Log.Get('OPENED'),
            'the logging target must record its own OnOpenPage when it really opens');
        Assert.AreEqual('Bravo', Log.Detail,
            'the logging target must have opened on the record it was handed');

        Assert.IsTrue(Probe.GetOpened(),
            'the in-memory probe must also record the opening, otherwise arm 6''s negative is unfalsifiable');
        Assert.AreEqual('Bravo', Probe.GetDescrSeen(),
            'the probe must have been marked on the record the page was handed');
    end;

    // ARM 6, and the direct counterpart to arm 1: the SAME logging target, with NO handler
    // bound, reached by a plain AL Page.Run instead of a RunObject declaration. Arm 1 measured
    // that the RunObject route opens the target unattended and tells AL nothing. This arm asks
    // whether the Page.Run route really does the opposite on the very same page -- refused, AND
    // nothing opened.
    //
    // Control 1 could not answer that. It opens the CLEAN Card Target, which has no OnOpenPage
    // and so records nothing whether it opens or not, and arm 4 depends on the Card Target
    // staying the page controls 1 and 2 refuse -- so this is a new arm rather than a change to
    // control 1.
    //
    // WHY THIS ARM DOES NOT READ THE LOG TABLE, which is the whole reason it looks different
    // from every other arm in this file. It was first written reading the 'OPENED' row, with an
    // uncommitted 'SENTINEL' row inserted before the refused call and read back after it to
    // prove the transaction had not rolled back. All eight cloud legs failed on the SENTINEL:
    //
    //     FAIL ControlPageRunOnTheLoggingTargetWithoutAHandlerIsRefusedAndOpensNothing
    //          - the refused Page.Run must not have rolled the transaction back
    //
    // So the refusal DOES discard the uncommitted rows of the transaction it unwinds, and a
    // missing 'OPENED' row here would have proved nothing -- it would be missing whether the
    // page opened or not. The guard did its job: it caught an unfalsifiable assertion before it
    // could ship green. (Codeunit 60170's Test04 pins that an uncommitted Insert is also
    // rolled back by a plain asserterror Error(), so the rollback is the general case and not
    // specific to a refused Page.Run; corpus issue 205.)
    //
    // The observable therefore has to be one a rollback cannot reach, so the logging target
    // also marks a SingleInstance codeunit, whose state is memory rather than database. Arm 5
    // is the control that proves that probe really is set when the page opens, without which
    // the negative below would be as unfalsifiable as the log row was.
    //
    // Both halves are asserted, because either alone is half the claim:
    //
    //   * REFUSED -- asserterror plus the specific 'Unhandled UI' message, not a bare
    //     asserterror. Per the mechanism note at the top of this file, TestHandleForm calls
    //     Company.RegisterForm only AFTER the handler lookup succeeds, so on this route a
    //     handler-less form should never be registered and never open.
    //   * NOTHING OPENED -- the probe was never marked.
    //
    // The sentinel survives, in memory rather than in a table: set before the refused call and
    // read after it, so that if the probe's own state were ever lost on the way out -- which
    // would look exactly like a page that never opened -- this arm fails loudly instead of
    // passing for the wrong reason.
    [Test]
    procedure ControlPageRunOnTheLoggingTargetWithoutAHandlerIsRefusedAndOpensNothing()
    var
        Row: Record "TPARONH Row";
        Probe: Codeunit "TPARONH Open Probe";
    begin
        Initialize();
        Commit();

        Probe.MarkSentinel();

        Row.Get('B');
        asserterror Page.Run(Page::"TPARONH Logging Target", Row);
        Assert.ExpectedError('Unhandled UI');

        Assert.IsTrue(Probe.GetSentinel(),
            'the probe''s own state must survive the refused Page.Run, otherwise the next assertion proves nothing');
        Assert.IsFalse(Probe.GetOpened(),
            'a refused Page.Run must not have opened the target: the logging target''s OnOpenPage must never have run');
    end;

    // ARMS 7-9: THE DIALOG TARGET (AL Runner issue 3223).
    //
    // A dialog target is looked up differently. Read from Microsoft.Dynamics.Nav.Ncl.dll (28.4),
    // NavTestExecution.ShowDialog asks FindHandler(ModalPage, form, throwIfNotFound: false) and,
    // when nothing is bound, throws NavTestPageInvokedWithoutHandlerException -- a
    // NavTestBaseException, whose resource text is "TestPages that are invoked from a RunObject
    // action must have a handler. Page No. = {0}". Unlike the Card route's
    // NavNCLMissingUIHandlerException, that type is one the form-showing path rethrows. That is
    // a reading, not a measurement; these arms are the measurement.

    // ARM 7: invoked with nothing bound, the dialog RunObject IS refused, and with the message
    // written for this case -- not the 'Unhandled UI' the Page.Run controls above get.
    // Held (publisher, bump 32): this test fails depending on the run, with the TargetException 'Object type
    // ...Codeunit69640 does not match target type' when "TPT Teardown Tests" (69640) ran earlier in the same session. The
    // master push run 39417479271 failed it on 27.5 and 29.0 (twice); the bump 30 pull request run passed it. Windows BC 29.0
    // shows the same exception in a full TestRunnerHub run (bc-linux #162). An outcome that changes between runs is not an
    // oracle: held under LT_HELD_BCLINUX_162 on every version, like CB 667.22. The assertions do not change.
#if LT_HELD_BCLINUX_162
    [Test]
#endif
    procedure RunObjectActionOnADialogTargetWithoutAHandlerIsRefused()
    var
        Host: TestPage "TPARONH Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        Host.Next();
        asserterror Host.RunDialogOnRec.Invoke();
        Assert.ExpectedError('TestPages that are invoked from a RunObject action must have a handler');
    end;

    // ARM 8: whether the refused dialog target had already OPENED -- its OnOpenPage ran, on the
    // host's current row -- before BC found nobody bound. Kept apart from arm 7 so the error and
    // the opening are measured independently. Reads the in-memory probe, since the refusal rolls
    // uncommitted rows back; the sentinel proves the probe survived the error.
    // Held (publisher, bump 32): this test fails depending on the run, with the TargetException 'Object type
    // ...Codeunit69640 does not match target type' when "TPT Teardown Tests" (69640) ran earlier in the same session. The
    // master push run 39417479271 failed it on 27.5 and 29.0 (twice); the bump 30 pull request run passed it. Windows BC 29.0
    // shows the same exception in a full TestRunnerHub run (bc-linux #162). An outcome that changes between runs is not an
    // oracle: held under LT_HELD_BCLINUX_162 on every version, like CB 667.22. The assertions do not change.
#if LT_HELD_BCLINUX_162
    [Test]
#endif
    procedure RunObjectActionOnADialogTargetWithoutAHandlerOpensItBeforeRefusing()
    var
        Host: TestPage "TPARONH Host";
        Probe: Codeunit "TPARONH Open Probe";
    begin
        Initialize();
        Commit();

        Probe.MarkSentinel();

        Host.OpenEdit();
        Host.First();
        Host.Next();
        asserterror Host.RunDialogOnRec.Invoke();

        Assert.IsTrue(Probe.GetSentinel(),
            'the probe''s own state must survive the refused invoke, otherwise the next assertions prove nothing');
        Assert.IsTrue(Probe.GetOpened(),
            'the dialog target opens (runs its OnOpenPage) before BC finds no [ModalPageHandler] bound');
        Assert.AreEqual('Bravo', Probe.GetDescrSeen(),
            'the dialog target opens on the host page''s current row, as RunPageOnRec = true');
    end;

    // ARM 9, the control for 7 and 8: with a [ModalPageHandler] bound, the same invoke reaches it,
    // raises nothing, and the dialog target's probe records the opening on the host's row. So the
    // action does open this target modally, and the probe arm 8 reads really is set when it opens.
    [Test]
    [HandlerFunctions('DialogTargetModalHandler')]
    procedure ProbeControlTheDialogTargetIsAnsweredByABoundModalHandler()
    var
        Host: TestPage "TPARONH Host";
        Probe: Codeunit "TPARONH Open Probe";
    begin
        Initialize();
        DialogHandlerCalls := 0;
        DialogHandlerDescr := '';

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunDialogOnRec.Invoke();
        Host.Close();

        Assert.AreEqual(1, DialogHandlerCalls,
            'a dialog RunObject target must be answered by the bound [ModalPageHandler] exactly once');
        Assert.AreEqual('Bravo', DialogHandlerDescr,
            'the modal handler must see the dialog target on the host page''s current row');
        Assert.IsTrue(Probe.GetOpened(),
            'the dialog target must record its own OnOpenPage when it really opens');
        Assert.AreEqual('Bravo', Probe.GetDescrSeen(),
            'the probe must have been marked on the record the dialog was opened on');
    end;

    [ModalPageHandler]
    procedure DialogTargetModalHandler(var Target: TestPage "TPARONH Dialog Target")
    begin
        DialogHandlerCalls += 1;
        DialogHandlerDescr := CopyStr(Target.Descr.Value(), 1, MaxStrLen(DialogHandlerDescr));
        Target.OK().Invoke();
    end;

    [PageHandler]
    procedure LoggingTargetPageHandler(var Target: TestPage "TPARONH Logging Target")
    begin
        Target.Close();
    end;
}
