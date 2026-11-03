// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
// Scope: in-scope
// Fixtures used: QCE Row (60675), QCE Error Modal (60676), QCE Error Card (60678),
//                QCM Witness (60601), Assert (60021)
//
// The arm "QCE Query Close Error Tests" (60677) deliberately left out, named in its own header:
// the same failing OnQueryClosePage, but with a [MessageHandler] DECLARED.
//
// Why it is a separate question. Closing a page is a client round trip, and the platform's close
// handler classifies what the trigger raised. An AL Error() is none of its named cases, so it
// reaches the general one, which shows the text as a MESSAGE and then refuses the close. With no
// [MessageHandler] declared that refusal is invisible, because showing the message is itself what
// fails -- the framework raises its own "Unhandled UI: Message ..." from inside the show call and
// nothing after it runs. That is what 60677 pins.
//
// Declare a [MessageHandler] and the show call SUCCEEDS. The handler consumes the text, control
// returns to the close handler, and only now does the "refuse the close" half become reachable at
// all. So this suite asks the three things nobody has measured:
//
//   1. does the caller get control back, or does the refusal surface as an error?
//   2. if it returns, what does RunModal() report?
//   3. what became of the page, and of the writes it made?
//
// Run order is deliberate. The negative control is first, and every assertion below is written so
// that "the handler never ran" and "the handler ran and the close was refused" cannot produce the
// same verdict -- an implementation that simply swallows the close-time error, or one that never
// dispatches the handler, fails a named assertion rather than passing quietly.
//
// Filed from AlRunner#3179, split out of AlRunner#3057.
codeunit 60602 "QCM Query Close Msg Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        // Which page the round trip currently under way belongs to. The [MessageHandler] is one
        // procedure serving both shapes, so it stamps the row with this rather than guessing from
        // the text -- the modal arms and the TestPage arm must not be able to read each other's row.
        ActiveTag: Code[20];
        LastModalResult: Action;
        CloseRefusedTxt: Label 'QCE close refused by OnQueryClosePage';
        ModalTag: Label 'MODAL', Locked = true;
        CardTag: Label 'CARD', Locked = true;

    // NEGATIVE CONTROL, first on purpose. Same page, same [ModalPageHandler], only the trigger
    // does not fail -- so the close succeeds and the page's write survives. Everything the arms
    // below observe must NOT happen here, which is what stops "always refuse the close" or
    // "always discard the page's write" from passing the suite.
    //
    // No [MessageHandler] is declared, and that is deliberate rather than an omission: the
    // framework treats a declared handler that never fires as a test failure
    // ("The following UI handlers were not executed"), so a control whose whole point is that no
    // message is sent CANNOT declare one. The claim "a successful close sends no message" is
    // therefore carried by 60677's own negative control plus the arms below, which show the
    // message appearing only once the trigger fails.
    [Test]
    [HandlerFunctions('QcmOkHandler')]
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
            'The row OnOpenPage inserted must survive a close that succeeded.');
        Assert.AreEqual(42, Row."Set ID",
            'The surviving row must carry the value OnOpenPage wrote, not a default.');
        Assert.AreEqual(2, Row.Count(),
            'Exactly the seeded row and the row OnOpenPage inserted must be present.');
    end;

    // CLAIM 1: with a [MessageHandler] declared, the AL error raised in OnQueryClosePage is
    // delivered to that handler as a MESSAGE -- the same channel an AL Message() statement
    // reaches -- carrying the trigger's own text.
    //
    // This is the half AlRunner#3057 already reproduces. It is asserted here as well because
    // claims 2 and 3 are only meaningful if the handler actually consumed the text: without this
    // assertion, a platform that never dispatched the handler at all could satisfy them by
    // accident.
    [Test]
    [HandlerFunctions('QcmOkHandler,QcmMessageHandler')]
    procedure ErrorInQueryClosePage_MessageHandlerReceivesTheTriggersText()
    var
        Witness: Record "QCM Witness";
    begin
        Initialize();

        RunFailingModal();

        Assert.IsTrue(Witness.Get(ModalTag),
            'An error raised in OnQueryClosePage must reach a declared [MessageHandler] -- it is shown as a message, not propagated raw.');
        Assert.AreEqual(2, Witness."Seen Count",
            'The RunModal route must deliver the close-time message twice. Corpus 60276 pins that this OK().Invoke() shape runs OnQueryClosePage exactly once when the trigger allows the close -- its trigger exits true -- so the second delivery here arrives only once the close is refused. What 60276 does not settle is what a refusal does next; that the TestPage arm below sees exactly one is the corroboration, not proof.');
        Assert.IsTrue(StrPos(Witness."Last Text", CloseRefusedTxt) > 0,
            StrSubstNo('The [MessageHandler] must receive the AL error text the trigger raised; got "%1".', Witness."Last Text"));
    end;

    // CLAIM 2: what the CALLER observes once the handler has consumed the text.
    //
    // This is the question AlRunner#3179 exists to settle and the reason the suite was written.
    // The platform's close handler returns "close refused" after showing the message, so either
    // the caller regains control -- and RunModal reports something -- or the refusal reaches AL
    // as an error. Measured: the first. Control returns, and RunModal reports None rather than
    // the OK the [ModalPageHandler] chose, because a refused close completed no action. Contrast
    // the negative control above, where the same handler chooses OK, the close succeeds, and
    // RunModal does report OK -- so None here is the refusal being reported, not an action lost.
    //
    // Deliberately NOT written with [TryFunction]. A TryFunction turns every outcome into a
    // boolean, and an implementation that raises an out-of-scope signal here would be absorbed by
    // it and read as "the platform refused the close" -- the two answers this arm exists to tell
    // apart would become the same observation. Calling RunModal directly means a platform that
    // does NOT return control fails this arm with its own text, which is the information a reader
    // needs -- and a platform that does return control has to produce the right Action to pass.
    //
    // 60677's ErrorInQueryClosePage_ArrivesAsAnUnhandledMessage is the companion: same page, same
    // failing trigger, no [MessageHandler]. That one asserts the error DOES arrive. Together the
    // two pin that declaring a [MessageHandler] is what changes the outcome, not the trigger.
    [Test]
    [HandlerFunctions('QcmOkHandler,QcmMessageHandler')]
    procedure ErrorInQueryClosePage_MessageConsumed_CallerRegainsControl()
    var
        Witness: Record "QCM Witness";
        Modal: Page "QCE Error Modal";
        Result: Action;
    begin
        Initialize();

        Modal.SetFail(true);
        Result := Modal.RunModal();

        // Reaching this line at all is half the claim: the close-time error did NOT propagate,
        // because a [MessageHandler] consumed it.
        Assert.IsTrue(Witness.Get(ModalTag),
            'The [MessageHandler] must have consumed the close-time message before the caller regains control.');
        Assert.AreEqual(2, Witness."Seen Count",
            'The RunModal route must deliver the close-time message twice. Corpus 60276 pins that this OK().Invoke() shape runs OnQueryClosePage exactly once when the trigger allows the close -- its trigger exits true -- so the second delivery here arrives only once the close is refused. What 60276 does not settle is what a refusal does next; that the TestPage arm below sees exactly one is the corroboration, not proof.');
        Assert.AreEqual(Format(Action::None), Format(Result),
            'RunModal must report None, NOT the action the [ModalPageHandler] chose. The handler picked OK, but a refused close means no action completed, so the caller cannot be told one did. This is what makes the refusal observable to the caller at all -- the consumed message left nothing else for it to see.');
    end;

    // CLAIM 3: what became of the page's own uncommitted write.
    //
    // 60677 pins that WITHOUT a [MessageHandler] the failing close discards the page's
    // uncommitted write and stops at the last Commit(). Measured here, consuming the message
    // changes it: the write SURVIVES. 60677 takes its measurement behind asserterror, so what
    // rolls the write back there is the framework unwinding a PROPAGATED error -- and a consumed
    // message propagates nothing, so nothing unwinds. The rollback belongs to the error escaping,
    // not to the close failing.
    //
    // Asserting the surviving row's value and the count together means neither "everything was
    // rolled back" nor "a row reappeared empty from somewhere else" can pass as the measured
    // answer.
    [Test]
    [HandlerFunctions('QcmOkHandler,QcmMessageHandler')]
    procedure ErrorInQueryClosePage_MessageConsumed_SettlesThePagesUncommittedWrite()
    var
        Row: Record "QCE Row";
        Witness: Record "QCM Witness";
    begin
        Initialize();

        RunFailingModal();

        Assert.IsTrue(Witness.Get(ModalTag),
            'The [MessageHandler] must have consumed the close-time message for this arm to be about the write at all.');
        Assert.IsTrue(Row.Get('SEEDED'),
            'The row committed before the page opened must survive -- any rollback stops at the last Commit().');
        Assert.AreEqual(7, Row."Set ID",
            'The committed row must keep the value it was committed with.');
        Assert.IsTrue(Row.Get('OPENED'),
            'The row OnOpenPage inserted without committing must SURVIVE here. 60677 measures the rollback behind asserterror, where the framework unwinds a propagated error; a consumed message propagates nothing, so nothing unwinds. The rollback belongs to the error escaping, not to the close failing.');
        Assert.AreEqual(42, Row."Set ID",
            'The surviving uncommitted row must carry the value OnOpenPage wrote, not a default -- so a row resurrected empty by anything else cannot satisfy the assertion above.');
        Assert.AreEqual(2, Row.Count(),
            'Both rows must remain: the committed one and the uncommitted one the consumed message left in place.');
    end;

    // The TestPage twin: a page the test opens and closes ITSELF, with a [MessageHandler]
    // declared. Same close handler underneath (TestPageProxy.InternalClose -> LogicalForm.Close),
    // so the envelope must agree with the modal arm -- and this is the shape where "the page is
    // still open afterwards" is directly observable, because the test still holds the TestPage
    // variable.
    [Test]
    [HandlerFunctions('QcmMessageHandler')]
    procedure ErrorInQueryClosePage_TestPageClose_MessageConsumed_CallerRegainsControl()
    var
        Card: TestPage "QCE Error Card";
        Witness: Record "QCM Witness";
    begin
        Initialize();
        ActiveTag := CardTag;

        Card.OpenEdit();
        Card.Close();

        Assert.IsTrue(Witness.Get(CardTag),
            'Closing a TestPage whose OnQueryClosePage errors must deliver the text to a declared [MessageHandler].');
        Assert.AreEqual(1, Witness."Seen Count",
            'The TestPage route must deliver the close-time message once. It differs from the RunModal arms above deliberately: this shape has no [ModalPageHandler] closing the page underneath the caller, so there is one close attempt rather than two.');
        Assert.IsTrue(StrPos(Witness."Last Text", CloseRefusedTxt) > 0,
            StrSubstNo('The [MessageHandler] must receive the trigger''s own error text; got "%1".', Witness."Last Text"));
    end;

    // A plain call, not a [TryFunction]. If the platform lets control return, these arms carry on
    // and read the witness back; if it does not, they fail with the platform's own text, which is
    // exactly the information a reader needs. Wrapping it would convert both into "false".
    local procedure RunFailingModal()
    var
        Modal: Page "QCE Error Modal";
    begin
        Modal.SetFail(true);
        LastModalResult := Modal.RunModal();
    end;

    local procedure Initialize()
    var
        Row: Record "QCE Row";
        Witness: Record "QCM Witness";
    begin
        Row.DeleteAll();
        Witness.DeleteAll();
        // Default to the modal shape; the TestPage arm re-stamps it before opening its page.
        ActiveTag := ModalTag;
        // Reset so a value left by an earlier [Test] cannot satisfy the RunModal assertion below.
        Clear(LastModalResult);
        Row.Init();
        Row."No." := 'SEEDED';
        Row."Set ID" := 7;
        Row.Insert();
        // Commit the setup itself. TestIsolation = Codeunit does not reset table state between
        // [Test] methods, and the arms here roll back to the last Commit() -- without this the
        // cleanup above would be rolled back too and an earlier test's rows would reappear.
        Commit();
    end;

    local procedure NoteMessage(Tag: Code[20]; Msg: Text)
    var
        Witness: Record "QCM Witness";
    begin
        if not Witness.Get(Tag) then begin
            Witness.Init();
            Witness."Tag" := Tag;
            Witness."Seen Count" := 0;
            Witness.Insert();
        end;
        Witness."Seen Count" := Witness."Seen Count" + 1;
        Witness."Last Text" := CopyStr(Msg, 1, MaxStrLen(Witness."Last Text"));
        Witness.Modify();
        // The witness must outlive whatever the close does to the transaction. The arms above read
        // it back after a round trip that may unwind: 60677 shows an uncommitted write discarded
        // when the close-time error PROPAGATES, and this suite only avoids that because the
        // handler consumes it. Committing here keeps the witness readable either way, so a failure
        // can never be the ambiguous "the handler never ran".
        Commit();
    end;

    [ModalPageHandler]
    procedure QcmOkHandler(var Modal: TestPage "QCE Error Modal")
    begin
        Modal.OK().Invoke();
    end;

    // Deliberately records rather than asserts -- see the QCM Witness header. The tag is chosen by
    // which page raised it, so the modal arms and the TestPage arm cannot read each other's row.
    [MessageHandler]
    procedure QcmMessageHandler(Msg: Text[1024])
    begin
        if StrPos(Msg, CloseRefusedTxt) > 0 then
            NoteMessage(ActiveTag, Msg)
        else
            NoteMessage('OTHER', Msg);
    end;

}
