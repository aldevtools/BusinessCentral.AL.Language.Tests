// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-confirm-method
// Scope: in-scope
// Fixtures used: CNH Row (60362), CNH Confirm True (60363), CNH Confirm False (60364), Assert (60021)
//
// CLAIM: inside a [Test] that declares no [ConfirmHandler] for it, Confirm(Question, Default)
// is REFUSED with the platform's own unhandled-UI error. It does NOT quietly answer Default,
// and it does not answer false. That holds whether the Confirm is raised straight from the
// test method body or from a page trigger the test reached through TestPage.OpenNew().
//
// WHY THIS IS WORTH PINNING. "A Confirm with a default answer and no handler returns the
// default" is a reasonable-sounding belief, and it is what a Microsoft test such as
// Codeunit 139460's CannotAddNewUserSaaS looks like it depends on: page 9807's
// ManageUsersIsAllowed raises Confirm(Qst, TRUE) and that test declares no handler for it.
// The corpus already pins the same refusal for a handler-less PAGE
// (NonModalPageRunWithoutAHandlerIsRefused in TestPageRunHandler_Tests.al) and for a
// handler-less page ACTION (TestPageActionRunObjectNoHandler_Tests.al). Confirm was not
// covered, so nothing said whether dialogs follow pages here or diverge from them.
//
// Each refusal arm carries its own negative: the trigger the Confirm sits in reports what it
// saw by RAISING an error, so a Confirm that answered instead of being refused produces a
// different, fully readable message ('CNH OUTCOME GuiAllowed=... Reply=...') rather than a
// silent pass. Asserting that this message is ABSENT is what makes the refusal arms unable to
// pass against an implementation that answers the default.
//
// The bound-handler arms are the positive control. They use the same pages and the same
// Confirm calls, so a failure there says the fixture is broken, not that the refusal claim is
// wrong -- and their assertions pin two further facts: a bound handler's reply beats the
// default in BOTH directions, and GuiAllowed() answers Yes inside a page trigger reached from
// a test, not only in the test method body (which session/TestBCPlatformContracts.al covers).

codeunit 60365 "Confirm No Handler Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CnhQst: Label 'CNH question. Do you want to go there now?';
        HandlerFireCount: Integer;
        LastQuestion: Text;

    local procedure Initialize()
    begin
        HandlerFireCount := 0;
        LastQuestion := '';
    end;

    // -- Refusal, raised from a page trigger ------------------------------------------

    [Test]
    procedure Confirm_NoHandler_PageTriggerDefaultTrue_IsRefused()
    var
        Card: TestPage "CNH Confirm True";
        ErrText: Text;
    begin
        Initialize();

        asserterror Card.OpenNew();

        ErrText := GetLastErrorText();
        Assert.IsTrue(StrPos(ErrText, 'Unhandled UI') > 0,
            'a Confirm raised from a page trigger with no [ConfirmHandler] must be refused with the unhandled-UI error, got: ' + ErrText);
        Assert.IsTrue(StrPos(ErrText, 'Confirm') > 0,
            'the refusal must name the Confirm handler type, got: ' + ErrText);
        Assert.IsTrue(StrPos(ErrText, 'CNH question') > 0,
            'the refusal must quote the question that went unanswered, got: ' + ErrText);
        Assert.AreEqual(0, StrPos(ErrText, 'CNH OUTCOME'),
            'the Confirm must not have returned at all -- reaching the trigger''s own outcome error means the default was answered: ' + ErrText);
    end;

    [Test]
    procedure Confirm_NoHandler_PageTriggerDefaultFalse_IsRefused()
    var
        Card: TestPage "CNH Confirm False";
        ErrText: Text;
    begin
        Initialize();

        asserterror Card.OpenNew();

        ErrText := GetLastErrorText();
        Assert.IsTrue(StrPos(ErrText, 'Unhandled UI') > 0,
            'a Confirm with default FALSE and no [ConfirmHandler] must be refused too, not answered false, got: ' + ErrText);
        Assert.AreEqual(0, StrPos(ErrText, 'CNH OUTCOME'),
            'the Confirm must not have returned at all -- the trigger reached its own outcome error: ' + ErrText);
    end;

    // -- Refusal, raised straight from the test method body ---------------------------

    [Test]
    procedure Confirm_NoHandler_TestBody_IsRefused()
    var
        Reply: Boolean;
        ErrText: Text;
    begin
        Initialize();

        // Poisoned on purpose: if the platform answered the default, Reply would end up TRUE,
        // so the IsFalse below fails rather than passing for the wrong reason.
        Reply := false;
        asserterror Reply := Confirm(CnhQst, true);
        ErrText := GetLastErrorText();
        Assert.IsTrue(StrPos(ErrText, 'Unhandled UI') > 0,
            'Confirm(Question, TRUE) with no [ConfirmHandler] must be refused in the test body, got: ' + ErrText);
        Assert.IsFalse(Reply,
            'a refused Confirm must not have assigned the default TRUE to its target');

        Reply := true;
        asserterror Reply := Confirm(CnhQst, false);
        ErrText := GetLastErrorText();
        Assert.IsTrue(StrPos(ErrText, 'Unhandled UI') > 0,
            'Confirm(Question, FALSE) with no [ConfirmHandler] must be refused as well, got: ' + ErrText);
        Assert.IsTrue(Reply,
            'a refused Confirm must not have assigned the default FALSE to its target');

        Assert.AreEqual(0, HandlerFireCount,
            'no [ConfirmHandler] is bound to this test, so none may have run');
    end;

    // -- Positive controls: a bound handler answers, and beats the default both ways ---

    [Test]
    [HandlerFunctions('ReplyNoHandler')]
    procedure Confirm_BoundHandler_PageTrigger_ReplyBeatsDefaultTrue()
    var
        Card: TestPage "CNH Confirm True";
        ErrText: Text;
    begin
        Initialize();

        asserterror Card.OpenNew();

        ErrText := GetLastErrorText();
        Assert.IsTrue(StrPos(ErrText, 'CNH OUTCOME GuiAllowed=Yes Reply=No') > 0,
            'a bound [ConfirmHandler] answering No must reach the page trigger and beat the TRUE default, and GuiAllowed() must be Yes inside the trigger, got: ' + ErrText);
        Assert.AreEqual(0, StrPos(ErrText, 'Unhandled UI'),
            'with a handler bound there must be no unhandled-UI refusal: ' + ErrText);
    end;

    [Test]
    [HandlerFunctions('ReplyNoHandler')]
    procedure Confirm_BoundHandler_TestBody_ReplyBeatsDefaultTrue()
    var
        Reply: Boolean;
    begin
        Initialize();

        Reply := Confirm(CnhQst, true);

        Assert.IsFalse(Reply, 'the bound handler answered No, so the TRUE default must not win');
        Assert.AreEqual(1, HandlerFireCount, 'the bound [ConfirmHandler] must have fired exactly once');
        Assert.AreEqual(CnhQst, LastQuestion, 'the handler must receive the question that was asked');
    end;

    [Test]
    [HandlerFunctions('ReplyYesHandler')]
    procedure Confirm_BoundHandler_TestBody_ReplyBeatsDefaultFalse()
    var
        Reply: Boolean;
    begin
        Initialize();

        Reply := Confirm(CnhQst, false);

        Assert.IsTrue(Reply, 'the bound handler answered Yes, so the FALSE default must not win');
        Assert.AreEqual(1, HandlerFireCount, 'the bound [ConfirmHandler] must have fired exactly once');
    end;

    [ConfirmHandler]
    procedure ReplyNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        HandlerFireCount += 1;
        LastQuestion := Question;
        Reply := false;
    end;

    [ConfirmHandler]
    procedure ReplyYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        HandlerFireCount += 1;
        LastQuestion := Question;
        Reply := true;
    end;
}
