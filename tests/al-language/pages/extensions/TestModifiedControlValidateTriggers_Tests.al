// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-extension-object
// Scope: in-scope
// Fixtures used: MCV Row (60510), MCV Card (60511), MCV Card Ext (60512), MCV Other Ext (60513), Assert (60021)
//   writer TT: Probe Observer (69160), LT TT MCV Row/Card/Card Ext/Subs (90108-90111, TestModifiedControlValidateTriggers_TableValidate.al)
//
// What a pageextension's `modify(Control)` validation triggers do when the extended page is
// driven as a TestPage.
//
// The claim under test is an ORDER: OnBeforeValidate, then the base control's own
// OnValidate, then OnAfterValidate. Each trigger appends its own tag to Rec.Trace, so the
// assertion is on one concrete string and cannot be satisfied by a run that fired the right
// triggers in the wrong order, nor by one that fired only some of them.
//
// The suite also pins the FAILED path, as its own set of claims: what an Error() inside
// OnBeforeValidate leaves in the page's buffer. That is a statement about BC's page-write
// buffer rather than about modify() dispatch, so it carries its own arms and its own
// negatives -- see the four arms after the order ones.
//
// One of those four is split in a way worth knowing about before editing it. Closing the page
// after a refused write is NOT the same on every supported version: 28.0-28.4 close cleanly,
// 27.0/27.3/27.5 raise "The record that you tried to open is not available." once a
// SUCCESSFUL write has followed the refused one. Measured, corpus run 34328827788. The trace
// claim is green on all eight and is stated without a Close(); the closability claim is
// stated separately, on the case that is green on all eight. Do not merge them back together.
//
// The OnAssistEdit arms pin the third control-acting modify() trigger, and the base-page form
// of the same trigger. Both were entirely unstated: BC's ITestField.AssistEdit returns void,
// so "the trigger ran" and "nothing happened" are the same observable unless the trigger
// leaves a trace behind, which is why every assist-edit arm asserts on Rec.Trace.

codeunit 60514 "MCV Validate Trigger Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "MCV Row";
    begin
        Row.DeleteAll();
    end;

    // The whole claim, in one value: before, base, after — in that order, each exactly once.
    //
    // Reading the trace back through the page's own Trace control rather than from the table
    // keeps the assertion about what the page committed, and an implementation that ran no
    // extension trigger at all answers 'page;' here, which is what this suite's absence
    // allowed to ship.
    [Test]
    procedure ModifiedControlBeforeAndAfterValidateWrapTheBaseControlsOwnOnValidate()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(1);
        Card.Name.SetValue('value');

        Assert.AreEqual('before;page;after;', Card.Trace.Value(),
          'a modify() block''s OnBeforeValidate must run before the base control''s OnValidate and its OnAfterValidate after it');

        Card.Close();
    end;

    // Negative on ORDER specifically: the base control's own OnValidate is not replaced by
    // the extension's triggers, and it runs BETWEEN them rather than before or after both.
    // Without this arm an implementation appending 'before;after;page;' passes nothing here
    // that the arm above would not already have caught, but stating it separately is what
    // makes the middle position an asserted property rather than an incidental one.
    [Test]
    procedure TheBaseControlsOwnOnValidateStillRunsAndRunsBetweenTheTwo()
    var
        Card: TestPage "MCV Card";
        Trace: Text;
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(2);
        Card.Name.SetValue('value');
        Trace := Card.Trace.Value();
        Card.Close();

        Assert.AreEqual(1, StrPos(Trace, 'before;'),
          'OnBeforeValidate must be the first trigger to append');
        Assert.AreEqual(StrPos(Trace, 'before;') + StrLen('before;'), StrPos(Trace, 'page;'),
          'the base control''s OnValidate must append immediately after OnBeforeValidate');
        Assert.AreEqual(StrPos(Trace, 'page;') + StrLen('page;'), StrPos(Trace, 'after;'),
          'OnAfterValidate must append immediately after the base control''s OnValidate');
    end;

    // The claim the arms above deliberately left out, now stated in the direction real BC
    // answered it. An Error() raised inside OnBeforeValidate DISCARDS the in-memory Rec
    // mutation that same trigger made before raising: the still-open page reads '' for Trace,
    // not the 'before;' the trigger appended one statement earlier.
    //
    // This was measured before it was written. An arm asserting the opposite was in this suite
    // when it was first opened and all eight cloud legs failed it, unanimously and
    // deterministically -- Expected:<before;>, Actual:<> -- so the assertion below is what the
    // tier said, not what any implementation makes convenient.
    //
    // Why the page is read rather than the table: the row was never written, so the table
    // cannot distinguish "the mutation was discarded" from "nothing was ever stored". The
    // page's own Trace control is the only place a surviving partial write would be visible,
    // which is exactly the observable under test.
    [Test]
    procedure AnErrorInOnBeforeValidateDiscardsThatTriggersOwnRecMutation()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(3);
        asserterror Card.Name.SetValue('stop');

        Assert.AreEqual('', Card.Trace.Value(),
          'a SetValue that raises must leave none of its triggers'' Rec mutations visible on the page');

        Card.Close();
    end;

    // Negative complement, and the arm that stops the one above from being satisfied by an
    // implementation that simply never runs OnBeforeValidate at all. The trigger DID run --
    // it is what raised -- so the error must be the one it raised, by its own message.
    //
    // Without this, "Trace is empty after a failed write" is equally true of a platform that
    // dispatched no extension trigger whatsoever, which is the state this whole suite exists
    // to tell apart from a working one.
    [Test]
    procedure TheRaisingTriggerDidRunEvenThoughItsMutationIsDiscarded()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(9);
        asserterror Card.Name.SetValue('stop');

        Assert.ExpectedError('MCV stopped in OnBeforeValidate');

        Card.Close();
    end;

    // Third claim, on the OTHER side of the discard: the buffer is RESTORED, not torn down,
    // so a subsequent successful write on the same page traces exactly one clean sequence. An
    // implementation that discarded the mutation by abandoning the buffer answers something
    // other than 'before;page;after;' here while passing both arms above.
    //
    // The page is deliberately NOT closed. That is not tidiness -- it is what the tier
    // measured, and the reason this arm and the one below it are two arms rather than one.
    //
    // MEASURED, corpus run 34328827788 on this suite's first eight-leg run. An earlier version
    // of this arm ended in Card.Close(), and it failed on 27.0, 27.3 and 27.5 -- all three,
    // identically -- while passing on 28.0 through 28.4:
    //
    //     FAIL AWriteAfterARefusedOneTracesFromTheRestoredBuffer
    //          Unhandled UI: Message  The record that you tried to open is not available.
    //                                 The page will close or show the next record.
    //
    // The failing statement was the Close(), not the assertion: the stack frame is RunTests
    // with no Assert frame, and the two arms above ALSO do asserterror-then-Close() and pass
    // on those same three legs. So the trace claim below is green on all eight; what differs
    // by version is only what closing the page does afterwards, which the next arm states on
    // its own.
    [Test]
    procedure AWriteAfterARefusedOneTracesFromTheRestoredBuffer()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(10);
        asserterror Card.Name.SetValue('stop');
        Card.Name.SetValue('value');

        Assert.AreEqual('before;page;after;', Card.Trace.Value(),
          'a successful write after a refused one must trace exactly one full sequence, from the restored buffer');
    end;

    // The half that splitting the arm above separated out, and the reason it is separate: what
    // CLOSING the page does after a refused write followed by a successful one is not the same
    // on every supported version, so pinning it together with the trace claim made a green
    // claim unstatable on three legs.
    //
    // 28.0-28.4 close cleanly. 27.0/27.3/27.5 raise an unhandled UI message -- "The record
    // that you tried to open is not available." -- from the Close() itself. Both are stated
    // here as what the tier answered, and neither is asserted as the correct one: this arm
    // pins that the page is closable WITHOUT the second write, which is true on all eight,
    // and leaves the version-split case to the comment above rather than encoding one
    // version's answer as the rule.
    //
    // Why not just assert the split with a version branch: the corpus states what AL and BC
    // do, and a test that branches on the platform version to pick an expected value asserts
    // nothing about either -- it records the split instead of testing it. The split is
    // recorded above, where a reader looking for it will find the run id.
    [Test]
    procedure APageIsStillClosableAfterARefusedWrite()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(11);
        asserterror Card.Name.SetValue('stop');

        // Read BEFORE closing -- a closed TestPage has no control to read -- so the arm is
        // ordered: observe, then close. The Close() is the assertion here: reaching the end of
        // this test without an unhandled UI message is what "still closable" means, and it is
        // what the three 27.x legs refused when a second successful write preceded it.
        Assert.AreEqual('', Card.Trace.Value(),
          'the refused write''s mutation must still be discarded on the arm that closes the page');

        // The claim: a refused write ON ITS OWN leaves the page in a state Close() accepts.
        // Green on all eight legs -- it is the SECOND, successful write that 27.x objects to,
        // not the refusal, which is what the two arms above already demonstrate by closing
        // successfully on every leg after their own asserterror.
        Card.Close();
    end;

    // Negative: a modify() block targeting a DIFFERENT control is not raised for this one.
    // "MCV Other Ext" (60513) modifies Other, never Name, so validating Name must produce
    // none of its tags — an implementation raising every modify() trigger on the page fails
    // here while passing every arm above.
    [Test]
    procedure AModifyBlockOnAnotherControlIsNotRaisedForThisOne()
    var
        Card: TestPage "MCV Card";
        Trace: Text;
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(4);
        Card.Name.SetValue('value');
        Trace := Card.Trace.Value();
        Card.Close();

        Assert.AreEqual(0, StrPos(Trace, 'otherbefore;'),
          'the modify() block on the Other control must not be raised when Name is validated');
        Assert.AreEqual(0, StrPos(Trace, 'otherafter;'),
          'the modify() block on the Other control must not be raised when Name is validated');
    end;

    // Positive complement of the arm above: validating Other DOES raise its own extension's
    // triggers, around its own base OnValidate. Without this, "not raised for Name" would be
    // satisfied by an implementation that never raises that block at all.
    [Test]
    procedure TheOtherControlsOwnModifyBlockWrapsItsOwnBaseTrigger()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(5);
        Card.Other.SetValue('value');

        Assert.AreEqual('otherbefore;otherpage;otherafter;', Card.Trace.Value(),
          'the Other control''s own modify() block must wrap the Other control''s own OnValidate');

        Card.Close();
    end;

    // Positive: a modify() block's OnDrillDown runs. Its absence has a LOUD answer on real
    // BC -- TestPage DrillDown() on a control with no trigger raises "The NavDrilldownAction
    // method is not supported." -- so this arm distinguishes "the extension's trigger ran"
    // from "nothing ran and the platform refused", which a silent no-op could not.
    [Test]
    procedure AModifyBlocksOnDrillDownRunsForTheModifiedControl()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(7);
        Card.Extra.DrillDown();

        Assert.AreEqual('extdrill;', Card.Trace.Value(),
          'a modify() block''s OnDrillDown must run for the control it modifies');

        Card.Close();
    end;

    // Positive: a modify() block's OnLookup runs. Same argument as the drilldown arm -- a
    // control with no OnLookup trigger falls back to its TableRelation, so "the trigger ran"
    // and "nothing ran" are distinguishable observables here rather than both being silence.
    [Test]
    procedure AModifyBlocksOnLookupRunsForTheModifiedControl()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(8);
        Card.Extra.Lookup();

        Assert.AreEqual('extlookup;', Card.Trace.Value(),
          'a modify() block''s OnLookup must run for the control it modifies');

        Card.Close();
    end;

    // Positive: a BASE-page control's own OnAssistEdit runs when the TestPage drives
    // AssistEdit(). Nothing in the corpus stated that it runs at all, and the observable is
    // silence either way -- BC's ITestField.AssistEdit returns void and an implementation
    // that does nothing is indistinguishable from one that dispatched, except through the
    // trigger's own effect. Hence the trace tag rather than a return value.
    [Test]
    procedure ABaseControlsOwnOnAssistEditRuns()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(9);
        Card.Name.AssistEdit();

        Assert.AreEqual('baseassist;', Card.Trace.Value(),
          'a control''s own OnAssistEdit must run when the TestPage calls AssistEdit()');

        Card.Close();
    end;

    // Positive: a modify() block's OnAssistEdit runs for the control it modifies. Extra
    // declares no OnAssistEdit on the base page, so the extension's block is the only
    // possible source of this tag -- which is what makes this arm about the EXTENSION route
    // rather than a second reading of the arm above.
    [Test]
    procedure AModifyBlocksOnAssistEditRunsForTheModifiedControl()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(10);
        Card.Extra.AssistEdit();

        Assert.AreEqual('extassist;', Card.Trace.Value(),
          'a modify() block''s OnAssistEdit must run for the control it modifies');

        Card.Close();
    end;

    // Negative on TARGETING: assist-editing Name must not raise the extension's block on
    // Extra, and assist-editing Extra must not raise Name's own trigger. An implementation
    // that raises every OnAssistEdit it can find on the page passes both arms above and
    // fails here.
    [Test]
    procedure OnAssistEditIsRaisedOnlyForTheControlItWasCalledOn()
    var
        Card: TestPage "MCV Card";
        AfterName: Text;
        AfterExtra: Text;
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(11);
        Card.Name.AssistEdit();
        AfterName := Card.Trace.Value();
        Card.Extra.AssistEdit();
        AfterExtra := Card.Trace.Value();
        Card.Close();

        Assert.AreEqual(0, StrPos(AfterName, 'extassist;'),
          'assist-editing Name must not raise the modify() block on Extra');
        Assert.AreEqual('baseassist;extassist;', AfterExtra,
          'each AssistEdit() must raise exactly its own control''s trigger, in call order');
    end;

    // Positive: OnAssistEdit runs once per call, not once per page. An implementation that
    // latches after the first dispatch, or raises at page open, fails here and passes the
    // arms above.
    [Test]
    procedure OnAssistEditRunsOncePerCall()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(12);
        Card.Name.AssistEdit();
        Card.Name.AssistEdit();

        Assert.AreEqual('baseassist;baseassist;', Card.Trace.Value(),
          'each AssistEdit() call must run the trigger again');

        Card.Close();
    end;

    // Positive: the triggers run once per validate, not once per page. A second write to the
    // same control appends a second complete sequence — an implementation raising them once
    // at page open, or latching after the first write, fails here and passes arm one.
    [Test]
    procedure TheSequenceRunsOncePerValidateNotOncePerPage()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(6);
        Card.Name.SetValue('first');
        Card.Name.SetValue('second');

        Assert.AreEqual('before;page;after;before;page;after;', Card.Trace.Value(),
          'each SetValue must run the full before/base/after sequence, so two writes produce two sequences');

        Card.Close();
    end;

    // Writer TT: the same order question when the TABLE field has its own OnValidate (fixtures in
    // TestModifiedControlValidateTriggers_TableValidate.al): Name has a table and a page OnValidate, Other a table OnValidate only.
    [Test]
    procedure TT_TableOnValidate_Order()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TT MCV Row";
        Card: TestPage "LT TT MCV Card";
    begin
        Row.DeleteAll();
        Card.OpenNew();
        Card.Id.SetValue(1);
        Card.Name.SetValue('value');
        Observer.Observe('name', Card.Trace.Value());
        Card.Other.SetValue('x');
        Observer.Observe('name then other', Card.Trace.Value());
        Card.Close();
        Observer.Expect('name', 'table;before;page;after;');
        Observer.Expect('name then other', 'table;before;page;after;othertable;otherbefore;otherafter;');
        Observer.Verify();
    end;

    [Test]
    procedure TT_TableOnValidate_Order_WithEvents()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TT MCV Row";
        Subs: Codeunit "LT TT MCV Subs";
        Card: TestPage "LT TT MCV Card";
    begin
        Row.DeleteAll();
        BindSubscription(Subs);
        Card.OpenNew();
        Card.Id.SetValue(2);
        Card.Name.SetValue('value');
        Observer.Observe('name', Card.Trace.Value());
        Card.Other.SetValue('x');
        Observer.Observe('name then other', Card.Trace.Value());
        Card.Close();
        Row.Init();
        Row.Id := 3;
        Row.Validate(Name, 'code');
        Row.Validate(Other, 'code');
        Observer.Observe('validate from code', Row.Trace);
        UnbindSubscription(Subs);
        Observer.Expect('name', 'tbefore;table;tafter;pbefore;before;page;after;pafter;');
        Observer.Expect('name then other', 'tbefore;table;tafter;pbefore;before;page;after;pafter;othertbefore;othertable;othertafter;otherpbefore;otherbefore;otherafter;otherpafter;');
        Observer.Expect('validate from code', 'tbefore;table;tafter;othertbefore;othertable;othertafter;');
        Observer.Verify();
    end;
}
