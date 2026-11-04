// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-close-method
// Scope: in-scope
// Fixtures used: QCV Probe (60439), QCV Veto Card (60484), Assert (60021)
//
// What a test observes when it calls TestPage.Close() on a page whose OnQueryClosePage answers
// false -- a plain veto, as opposed to the AL error 60677 and 60602 cover.
//
// The platform's close handler treats a veto as "close refused" and raises nothing. So the
// questions are the ones a test that closes such a page runs into:
//
//   1. does Close() return, or does the refusal reach AL as an error?
//   2. does OnClosePage run?
//   3. is the TestPage variable still open afterwards -- can the test close it again?
//   4. does the variable leaving scope ask OnQueryClosePage a second time?
//
// The veto is produced three ways -- exit(false), a Confirm the handler answers No (the shape
// the base app's User Card uses), and, for comparison, an AL error consumed by a
// [MessageHandler] -- and every arm is paired with the allowed close as its control, so an
// implementation that always refuses, or never refuses, fails a named assertion.
//
// Filed from AlRunner#4710.
codeunit 60419 "QCV Close Veto Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Probe: Codeunit "QCV Probe";
        ConfirmCalls: Integer;
        MessageCalls: Integer;
        NotOpenErr: Label 'The TestPage is not open';

    // CONTROL: the trigger allows the close. OnQueryClosePage runs once, OnClosePage runs once.
    [Test]
    procedure AllowedClose_RunsOnClosePage()
    var
        Card: TestPage "QCV Veto Card";
    begin
        Initialize(Probe.ModeAllow());

        Card.OpenEdit();
        Card.Close();

        Assert.AreEqual(1, Probe.QueryCloseCalls(), 'OnQueryClosePage must run once for an allowed close.');
        Assert.AreEqual(1, Probe.ClosePageCalls(), 'OnClosePage must run once when the close is allowed.');
    end;

    // CONTROL for arm 3: a closed TestPage is not open, so closing it again is an error and does
    // not reach the page's triggers.
    [Test]
    procedure AllowedClose_SecondCloseRaisesNotOpen()
    var
        Card: TestPage "QCV Veto Card";
    begin
        Initialize(Probe.ModeAllow());

        Card.OpenEdit();
        Card.Close();
        asserterror Card.Close();

        Assert.ExpectedError(NotOpenErr);
        Assert.AreEqual(1, Probe.QueryCloseCalls(), 'Closing a closed TestPage must not ask OnQueryClosePage again.');
    end;

    // CLAIM 1 + 2: a plain veto. Close() returns without an error -- reaching the assertions is
    // half the claim -- the trigger ran once, and OnClosePage did not run.
    [Test]
    procedure PlainVeto_CloseReturnsWithoutError()
    var
        Card: TestPage "QCV Veto Card";
    begin
        Initialize(Probe.ModeVeto());

        Card.OpenEdit();
        Card.Close();

        Assert.AreEqual(1, Probe.QueryCloseCalls(), 'OnQueryClosePage must run once for the vetoed close.');
        Assert.AreEqual(0, Probe.ClosePageCalls(), 'OnClosePage must not run when OnQueryClosePage vetoed the close.');
    end;

    // CLAIM 3: after a vetoed Close() the TestPage variable is no longer open. A second Close()
    // raises "The TestPage is not open." and does not ask the page again.
    [Test]
    procedure PlainVeto_SecondCloseRaisesNotOpen()
    var
        Card: TestPage "QCV Veto Card";
    begin
        Initialize(Probe.ModeVeto());

        Card.OpenEdit();
        Card.Close();
        asserterror Card.Close();

        Assert.ExpectedError(NotOpenErr);
        Assert.AreEqual(1, Probe.QueryCloseCalls(), 'A second Close() after a veto must not ask OnQueryClosePage again.');
        Assert.AreEqual(0, Probe.ClosePageCalls(), 'OnClosePage must not run on either Close().');
    end;

    // CLAIM 3, the field-read shape: reading a control after a vetoed Close() also raises
    // "The TestPage is not open.".
    [Test]
    procedure PlainVeto_FieldReadRaisesNotOpen()
    var
        Card: TestPage "QCV Veto Card";
        Ignored: Text;
    begin
        Initialize(Probe.ModeVeto());

        Card.OpenEdit();
        Assert.AreEqual('OPENED', Card.Marker.Value(), 'The page must be readable before the close.');
        Card.Close();
        asserterror Ignored := Card.Marker.Value();

        Assert.ExpectedError(NotOpenErr);
    end;

    // CLAIM 4: the TestPage variable leaving scope after a vetoed Close() does not ask
    // OnQueryClosePage a second time.
    [Test]
    procedure PlainVeto_ScopeExitDoesNotAskAgain()
    begin
        Initialize(Probe.ModeVeto());

        OpenAndCloseInOwnScope();

        Assert.AreEqual(1, Probe.QueryCloseCalls(), 'Disposing the TestPage variable after a vetoed Close() must not raise OnQueryClosePage again.');
        Assert.AreEqual(0, Probe.ClosePageCalls(), 'OnClosePage must not run when the variable leaves scope after a veto.');
    end;

    // The User Card shape: OnQueryClosePage returns the answer of a Confirm, and the test's
    // ConfirmHandler answers No. Close() returns, the question was asked exactly once, and
    // OnClosePage did not run.
    [Test]
    [HandlerFunctions('QcvConfirmNo')]
    procedure ConfirmNoVeto_CloseReturnsWithoutError()
    var
        Card: TestPage "QCV Veto Card";
    begin
        Initialize(Probe.ModeConfirm());

        Card.OpenEdit();
        Card.Close();

        Assert.AreEqual(1, ConfirmCalls, 'The Confirm in OnQueryClosePage must reach the ConfirmHandler exactly once.');
        Assert.AreEqual(1, Probe.QueryCloseCalls(), 'OnQueryClosePage must run once.');
        Assert.AreEqual(0, Probe.ClosePageCalls(), 'OnClosePage must not run when the Confirm was answered No.');
    end;

    // Control for the arm above: the same Confirm answered Yes closes the page.
    [Test]
    [HandlerFunctions('QcvConfirmYes')]
    procedure ConfirmYes_Closes()
    var
        Card: TestPage "QCV Veto Card";
    begin
        Initialize(Probe.ModeConfirm());

        Card.OpenEdit();
        Card.Close();

        Assert.AreEqual(1, ConfirmCalls, 'The Confirm in OnQueryClosePage must reach the ConfirmHandler exactly once.');
        Assert.AreEqual(1, Probe.ClosePageCalls(), 'OnClosePage must run when the Confirm was answered Yes.');
    end;

    // The error-consumed refusal (60602's TestPage arm) asked the same question as CLAIM 3: is the
    // TestPage variable still open after Close() returned?
    [Test]
    [HandlerFunctions('QcvMessage')]
    procedure ErrorConsumedByMessageHandler_SecondCloseRaisesNotOpen()
    var
        Card: TestPage "QCV Veto Card";
    begin
        Initialize(Probe.ModeError());

        Card.OpenEdit();
        Card.Close();
        Assert.AreEqual(1, MessageCalls, 'The close-time error must reach the [MessageHandler] once.');
        asserterror Card.Close();

        Assert.ExpectedError(NotOpenErr);
        Assert.AreEqual(1, Probe.QueryCloseCalls(), 'A second Close() after a refused close must not ask OnQueryClosePage again.');
        Assert.AreEqual(0, Probe.ClosePageCalls(), 'OnClosePage must not run after a refused close.');
    end;

    local procedure OpenAndCloseInOwnScope()
    var
        Card: TestPage "QCV Veto Card";
    begin
        Card.OpenEdit();
        Card.Close();
    end;

    local procedure Initialize(Mode: Integer)
    begin
        Probe.Reset(Mode);
        ConfirmCalls := 0;
        MessageCalls := 0;
    end;

    [ConfirmHandler]
    procedure QcvConfirmNo(Question: Text[1024]; var Reply: Boolean)
    begin
        ConfirmCalls += 1;
        Reply := false;
    end;

    [ConfirmHandler]
    procedure QcvConfirmYes(Question: Text[1024]; var Reply: Boolean)
    begin
        ConfirmCalls += 1;
        Reply := true;
    end;

    [MessageHandler]
    procedure QcvMessage(Msg: Text[1024])
    begin
        MessageCalls += 1;
    end;

    // Writer RP (al-runner issue 5769): what GetLastErrorText and GetLastErrorCode give after a vetoed TestPage.Close(), called
    // directly and inside a [TryFunction] (the reporter's shape), for OpenEdit / OpenView / OpenNew, for a Confirm answered No,
    // for a card with a source table, against the allowed close, and when an earlier error is still the last error.
    local procedure RpObserveClose(var Observer: Codeunit "Probe Observer"; Name: Text)
    begin
        Observer.Observe(Name + '_err', GetLastErrorText());
        Observer.Observe(Name + '_code', GetLastErrorCode());
        Observer.Observe(Name + '_calls', Format(Probe.QueryCloseCalls()) + '/' + Format(Probe.ClosePageCalls()));
    end;

    [TryFunction]
    local procedure RpTryClose(var Card: TestPage "QCV Veto Card")
    begin
        Card.Close();
    end;

    [TryFunction]
    local procedure RpTryCloseTable(var Card: TestPage "LT RP QCV Table Card")
    begin
        Card.Close();
    end;

    [Test]
    procedure RP_PlainVeto_LastErrorAfterClose()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "QCV Veto Card";
    begin
        Initialize(Probe.ModeVeto());
        Card.OpenEdit();
        ClearLastError();
        Card.Close();
        RpObserveClose(Observer, 'direct');
        Initialize(Probe.ModeVeto());
        Card.OpenEdit();
        ClearLastError();
        Observer.Observe('try_ok', Format(RpTryClose(Card)));
        RpObserveClose(Observer, 'try');
        Observer.Expect('direct_err', 'The page cannot be closed at this time.');
        Observer.Expect('direct_code', 'FormCloseNotAllowed');
        Observer.Expect('direct_calls', '1/0');
        Observer.Expect('try_ok', 'Yes');
        Observer.Expect('try_err', 'The page cannot be closed at this time.');
        Observer.Expect('try_code', 'FormCloseNotAllowed');
        Observer.Expect('try_calls', '1/0');
        Observer.Verify();
    end;

    [Test]
    procedure RP_PlainVeto_LastErrorPerOpenMode()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RP Veto Row";
        Card: TestPage "QCV Veto Card";
        TableCard: TestPage "LT RP QCV Table Card";
    begin
        Initialize(Probe.ModeVeto());
        Card.OpenView();
        ClearLastError();
        Card.Close();
        RpObserveClose(Observer, 'view');
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'Q1';
        Row.Insert();
        Initialize(Probe.ModeVeto());
        TableCard.OpenView();
        ClearLastError();
        TableCard.Close();
        RpObserveClose(Observer, 'table_view');
        Initialize(Probe.ModeVeto());
        TableCard.OpenNew();
        ClearLastError();
        TableCard.Close();
        RpObserveClose(Observer, 'table_new');
        Observer.Observe('table_rows', Format(Row.Count()));
        Observer.Expect('view_err', 'The page cannot be closed at this time.');
        Observer.Expect('view_code', 'FormCloseNotAllowed');
        Observer.Expect('view_calls', '1/0');
        Observer.Expect('table_view_err', 'The page cannot be closed at this time.');
        Observer.Expect('table_view_code', 'FormCloseNotAllowed');
        Observer.Expect('table_view_calls', '1/0');
        Observer.Expect('table_new_err', 'The page cannot be closed at this time.');
        Observer.Expect('table_new_code', 'FormCloseNotAllowed');
        Observer.Expect('table_new_calls', '1/0');
        Observer.Expect('table_rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure RP_Allowed_LastErrorAfterClose()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "QCV Veto Card";
    begin
        Initialize(Probe.ModeAllow());
        Card.OpenEdit();
        ClearLastError();
        Card.Close();
        RpObserveClose(Observer, 'allowed');
        Initialize(Probe.ModeAllow());
        Card.OpenEdit();
        asserterror Error('RP earlier error');
        Card.Close();
        RpObserveClose(Observer, 'allowed_earlier');
        Observer.Expect('allowed_err', '');
        Observer.Expect('allowed_code', '');
        Observer.Expect('allowed_calls', '1/1');
        Observer.Expect('allowed_earlier_err', 'RP earlier error');
        Observer.Expect('allowed_earlier_code', 'Dialog');
        Observer.Expect('allowed_earlier_calls', '1/1');
        Observer.Verify();
    end;

    [Test]
    procedure RP_PlainVeto_ReplacesAnEarlierLastError()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "QCV Veto Card";
    begin
        Initialize(Probe.ModeVeto());
        Card.OpenEdit();
        asserterror Error('RP earlier error');
        Card.Close();
        RpObserveClose(Observer, 'earlier');
        Observer.Expect('earlier_err', 'The page cannot be closed at this time.');
        Observer.Expect('earlier_code', 'FormCloseNotAllowed');
        Observer.Expect('earlier_calls', '1/0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QcvConfirmNo')]
    procedure RP_ConfirmNoVeto_LastErrorAfterClose()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "QCV Veto Card";
    begin
        Initialize(Probe.ModeConfirm());
        Card.OpenEdit();
        ClearLastError();
        Card.Close();
        RpObserveClose(Observer, 'confirm_no');
        Observer.Observe('confirm_calls', Format(ConfirmCalls));
        Observer.Expect('confirm_no_err', 'The page cannot be closed at this time.');
        Observer.Expect('confirm_no_code', 'FormCloseNotAllowed');
        Observer.Expect('confirm_no_calls', '1/0');
        Observer.Expect('confirm_calls', '1');
        Observer.Verify();
    end;

    [Test]
    procedure RP_PlainVeto_TableCard_LastErrorInTryFunction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RP Veto Row";
        Card: TestPage "LT RP QCV Table Card";
    begin
        Initialize(Probe.ModeVeto());
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'Q1';
        Row.Insert();
        Card.OpenEdit();
        ClearLastError();
        Observer.Observe('table_try_ok', Format(RpTryCloseTable(Card)));
        RpObserveClose(Observer, 'table_try');
        Observer.Expect('table_try_ok', 'Yes');
        Observer.Expect('table_try_err', 'The page cannot be closed at this time.');
        Observer.Expect('table_try_code', 'FormCloseNotAllowed');
        Observer.Expect('table_try_calls', '1/0');
        Observer.Verify();
    end;
}

// Writer RP (al-runner issue 5769): the reporter's shape, a Card with a source table whose OnQueryClosePage refuses. Used only by
// codeunit 60419 (it shares the SingleInstance "QCV Probe").
page 88398 "LT RP QCV Table Card"
{
    PageType = Card;
    SourceTable = "LT RP Veto Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
            }
        }
    }

    var
        Probe: Codeunit "QCV Probe";

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(Probe.AnswerQueryClose());
    end;

    trigger OnClosePage()
    begin
        Probe.NoteClosePage();
    end;
}
