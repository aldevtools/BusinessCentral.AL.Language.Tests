// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
// Scope: in-scope
// Fixtures used: QCE Row (60675), QCE Error Modal (60676), QCE Error Card (60678), Assert (60021)
//
// TestPageModalQueryClose_Tests (60276) pins that OnQueryClosePage RUNS on a handler-driven
// close and with which CloseAction. This suite pins what happens when that trigger FAILS:
// the envelope the AL error arrives in, and what becomes of the writes the page already made.
//
// Closing a page is a client round trip, so the error does not simply propagate the way an
// error from a directly-called AL procedure does. The platform's close handler classifies it:
// a veto (OnQueryClosePage returning false) is NavFormCloseNotAllowedException and silently
// prevents the close, while an AL error raised inside the trigger falls through to the general
// case, which SHOWS IT AS A MESSAGE and refuses the close. In a test session a message with no
// [MessageHandler] declared is the framework's "Unhandled UI" refusal, so that — not the raw
// AL error — is what reaches the caller.
//
// Deliberately NOT covered here: the same page closed with a [MessageHandler] declared. The
// close handler refuses the close after showing the message, so the page is still open when the
// handler returns, and what the test framework does next is a second question this suite does
// not ask.
//
// Filed from AlRunner#3057, where the runner surfaced the raw AL exception instead.
codeunit 60677 "QCE Query Close Error Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CloseRefusedTxt: Label 'QCE close refused by OnQueryClosePage';

    // NEGATIVE CONTROL, and deliberately first: the same page, the same handler, the same
    // OnOpenPage write — only the trigger does not fail. Everything the two arms below assert
    // must NOT happen here, so an implementation that always refuses a close, or always
    // discards a page's writes, fails this test.
    [Test]
    [HandlerFunctions('QceOkHandler')]
    procedure NoErrorInQueryClosePage_ClosesNormallyAndKeepsThePagesWrite()
    var
        Row: Record "QCE Row";
        Modal: Page "QCE Error Modal";
        Result: Action;
    begin
        Initialize();

        Modal.SetFail(false);
        Result := Modal.RunModal();

        Assert.AreEqual(Format(Action::OK), Format(Result),
            'A modal the handler closes with OK must report OK when OnQueryClosePage allows the close.');
        Assert.IsTrue(Row.Get('OPENED'),
            'The row OnOpenPage inserted must still be there after a close that succeeded.');
        Assert.AreEqual(42, Row."Set ID",
            'The surviving row must carry the value OnOpenPage wrote, not a default.');
        Assert.AreEqual(2, Row.Count(),
            'Exactly the seeded row and the row OnOpenPage inserted must be present.');
    end;

    // CLAIM: an Error() raised in OnQueryClosePage reaches the caller as the platform's
    // unhandled-message refusal carrying the AL error text — not as the raw AL error.
    [Test]
    [HandlerFunctions('QceOkHandler')]
    procedure ErrorInQueryClosePage_ArrivesAsAnUnhandledMessage()
    var
        ErrText: Text;
    begin
        Initialize();

        asserterror RunFailingModal();
        ErrText := GetLastErrorText();

        Assert.IsTrue(StrPos(ErrText, CloseRefusedTxt) > 0,
            StrSubstNo('The AL error text raised in OnQueryClosePage must survive into what the caller sees; got "%1".', ErrText));
        Assert.IsTrue(StrPos(ErrText, 'Unhandled UI') > 0,
            StrSubstNo('An error raised in OnQueryClosePage must be shown as UI the test did not handle, not propagated raw; got "%1".', ErrText));
        Assert.IsTrue(StrPos(ErrText, 'Message') > 0,
            StrSubstNo('The unhandled UI must be a Message — that is how the platform''s close handler reports an error from OnQueryClosePage; got "%1".', ErrText));
    end;

    // CLAIM: the failing close takes the page's own uncommitted write with it, and stops at the
    // last Commit() — the row seeded and committed by Initialize() must survive.
    [Test]
    [HandlerFunctions('QceOkHandler')]
    procedure ErrorInQueryClosePage_RollsBackThePagesUncommittedWrite()
    var
        Row: Record "QCE Row";
    begin
        Initialize();

        asserterror RunFailingModal();

        Assert.IsFalse(Row.Get('OPENED'),
            'The row OnOpenPage inserted without committing must not survive the failed close.');
        Assert.IsTrue(Row.Get('SEEDED'),
            'The row Initialize() committed before the page opened must survive — the rollback stops at the last Commit().');
        Assert.AreEqual(7, Row."Set ID",
            'The committed row must keep the value it was committed with.');
        Assert.AreEqual(1, Row.Count(),
            'Only the committed row may remain after the failed close.');
    end;

    // The same claim on the shape a test drives itself: TestPage.Close() goes through the same
    // platform close handler as a handler-driven modal close (TestPageProxy.InternalClose ->
    // LogicalForm.Close -> the close handler), so the envelope must be the same one.
    [Test]
    procedure ErrorInQueryClosePage_TestPageClose_ArrivesAsAnUnhandledMessage()
    var
        Card: TestPage "QCE Error Card";
        ErrText: Text;
    begin
        Initialize();

        Card.OpenEdit();
        asserterror Card.Close();
        ErrText := GetLastErrorText();

        Assert.IsTrue(StrPos(ErrText, CloseRefusedTxt) > 0,
            StrSubstNo('The AL error text raised in OnQueryClosePage must survive into what the caller sees; got "%1".', ErrText));
        Assert.IsTrue(StrPos(ErrText, 'Unhandled UI') > 0,
            StrSubstNo('Closing a TestPage whose OnQueryClosePage errors must report unhandled UI, not the raw AL error; got "%1".', ErrText));
        Assert.IsTrue(StrPos(ErrText, 'Message') > 0,
            StrSubstNo('The unhandled UI must be a Message, the same envelope the handler-driven close produces; got "%1".', ErrText));
    end;

    local procedure RunFailingModal()
    var
        Modal: Page "QCE Error Modal";
    begin
        Modal.SetFail(true);
        Modal.RunModal();
    end;

    local procedure Initialize()
    var
        Row: Record "QCE Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'SEEDED';
        Row."Set ID" := 7;
        Row.Insert();
        // Commit the setup itself. TestIsolation = Codeunit does not reset table state between
        // [Test] methods, and the arms below roll back to the last Commit() — without this the
        // cleanup above would be rolled back too and an earlier test's row would reappear.
        Commit();
    end;

    [ModalPageHandler]
    procedure QceOkHandler(var Modal: TestPage "QCE Error Modal")
    begin
        Modal.OK().Invoke();
    end;
}
