// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-close-method
//   dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
// Scope: in-scope
// Fixtures used: MQC Trace (60271), MQC Row (60272), MQC Self Close Modal (60294),
//                MQC Self Close Persist (60295), Assert (60021)
//
// Sibling of TestPageModalQueryClose_Tests.al, which pins the close lifecycle of a page the
// PLATFORM closes for a handler. This file pins the other way a modal page ends: the page
// closes ITSELF. A footer action captioned OK calls CurrPage.Close() from its own OnAction,
// and the handler invokes that action by name -- Modal.CloseMe -- rather than the built-in
// OK() the platform synthesises. It is the ordinary shape for any page whose confirm button
// is a real action because it has work to do before closing.
//
// Two things make it worth pinning separately, and neither can be inferred from the
// platform-driven arms:
//
//   1. WHEN the close runs. CurrPage.Close() sits in the middle of an OnAction, with AL after
//      it. Whether the close triggers fire there and then, or are deferred until OnAction
//      returns, is observable and decides what any AL after the call is allowed to assume.
//      The fixture logs a marker on both sides of the call so the ORDER is asserted, not just
//      the membership.
//   2. HOW MANY TIMES. Two closing mechanisms are now in play for one page -- the page's own
//      CurrPage.Close() and whatever the platform does when the handler returns. An
//      implementation that runs both fires each trigger twice, and a page that persists from
//      OnQueryClosePage then does its work twice. That failure is invisible to a test
//      asserting only that a trigger ran, which is why the counting arms below exist.

codeunit 60296 "MQC Self Close Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Trace: Record "MQC Trace";
        Row: Record "MQC Row";
    begin
        Trace.DeleteAll();
        Row.DeleteAll();
    end;

    // (a) The base case: a plain modal closed by its own action. Pins the full ordered trace,
    // so both the CloseAction the trigger receives and the position of the close relative to
    // the rest of OnAction are asserted.
    [Test]
    [HandlerFunctions('SelfCloseHandler')]
    procedure SelfClosingAction_PlainModal_RunsEachCloseTriggerOnce()
    var
        Trace: Record "MQC Trace";
        Modal: Page "MQC Self Close Modal";
        Result: Action;
    begin
        Initialize();

        Result := Modal.RunModal();

        Assert.AreEqual('ACTION;QUERYCLOSE:OK;CLOSEPAGE;AFTER-CLOSE;', Trace.Events(),
            'CurrPage.Close() from an action must run OnQueryClosePage then OnClosePage, exactly once each');
        Assert.AreEqual(Format(Action::OK), Format(Result),
            'RunModal must report what the platform chose for a page that closed itself');
    end;

    // (b) The same page in lookup mode, and the answer is not the one symmetry suggests: the
    // trigger sees LookupCancel, not LookupOK. CurrPage.Close() is a plain close and carries no
    // confirmation, so lookup mode reads it as the user dismissing the lookup -- while the
    // NON-lookup arm above reads the identical call as OK. Neither value can be derived from
    // the other, or from the built-in arms in TestPageModalQueryClose_Tests.al.
    [Test]
    [HandlerFunctions('SelfCloseHandler')]
    procedure SelfClosingAction_LookupModal_RunsEachCloseTriggerOnce()
    var
        Trace: Record "MQC Trace";
        Modal: Page "MQC Self Close Modal";
        Result: Action;
    begin
        Initialize();

        Modal.LookupMode(true);
        Result := Modal.RunModal();

        Assert.AreEqual('ACTION;QUERYCLOSE:LookupCancel;CLOSEPAGE;AFTER-CLOSE;', Trace.Events(),
            'lookup mode changes the CloseAction a self-close reports, not how many times the triggers run');
        Assert.AreEqual(Format(Action::LookupCancel), Format(Result),
            'RunModal must report what the platform chose for a lookup page that closed itself');
    end;

    // (c) The page closes itself, and the handler then reaches for the built-in OK() anyway --
    // the mistake a test author makes when the two mechanisms look equivalent. The platform
    // REFUSES it by name: the page is gone, so there is no second close to run.
    //
    // Only the refusal is asserted. The trace is deliberately NOT, and the reason is worth
    // recording: the handler raises, so `asserterror` unwinds the write transaction around it,
    // and what survives in the table is whatever committed inside QueryCloseForm's own
    // transaction plus whatever the platform did while tearing down. Measured on 28.4 that
    // reads ACTION;QUERYCLOSE:LookupCancel;CLOSEPAGE;AFTER-CLOSE; -- LookupCancel on a page
    // explicitly run with LookupMode(false), which is a fact about rollback rather than about
    // the close lifecycle this file pins. Arms (a), (b) and (d) count the triggers on paths
    // that do not roll back.
    [Test]
    [HandlerFunctions('SelfCloseThenBuiltInHandler')]
    procedure SelfClosingActionThenBuiltInOk_IsRefusedAsNotOpen()
    begin
        Initialize();

        asserterror RunSelfCloseThenBuiltIn();

        Assert.ExpectedError('The TestPage is not open.');
    end;

    local procedure RunSelfCloseThenBuiltIn()
    var
        Modal: Page "MQC Self Close Modal";
        Result: Action;
    begin
        Modal.LookupMode(false);
        Result := Modal.RunModal();
        Error('MQC-NO-ERROR RunModal returned %1', Format(Result));
    end;

    // (d) The shape this file exists for: a page that persists from OnQueryClosePage and
    // closes itself. The counter is what makes running the trigger twice visible -- an
    // implementation that closes the page through both mechanisms writes 2 where BC writes 1,
    // and an assertion on a flag would read the same either way.
    [Test]
    [HandlerFunctions('SelfClosePersistHandler')]
    procedure SelfClosingAction_PersistingQueryClosePage_WritesExactlyOnce()
    var
        Row: Record "MQC Row";
        Modal: Page "MQC Self Close Persist";
    begin
        Initialize();
        Row.Init();
        Row."No." := 'D';
        Row."Set ID" := 0;
        Row.Insert();

        Modal.SetTarget(Row);
        Modal.RunModal();

        Row.Get('D');
        Assert.AreEqual(1, Row."Set ID",
            'OnQueryClosePage must run exactly once, so its increment reaches the table exactly once');
    end;

    [ModalPageHandler]
    procedure SelfCloseHandler(var Modal: TestPage "MQC Self Close Modal")
    begin
        Modal.CloseMe.Invoke();
    end;

    [ModalPageHandler]
    procedure SelfCloseThenBuiltInHandler(var Modal: TestPage "MQC Self Close Modal")
    begin
        Modal.CloseMe.Invoke();
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SelfClosePersistHandler(var Modal: TestPage "MQC Self Close Persist")
    begin
        Modal.CloseMe.Invoke();
    end;
}
