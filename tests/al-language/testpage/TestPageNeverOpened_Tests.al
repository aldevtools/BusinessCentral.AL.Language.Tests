// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: TPNO Row (67040), TPNO Row Card (67040), TPNO Probe (67041),
//                TPNO Veto Card (67041), Assert (60021)
//
// Which TestPage variables are open, and when.
//
//   1. A TestPage variable the test never opened is not open: Close(), a field read and
//      GoToRecord raise "The TestPage is not open.".
//   2. A page BC attaches to the variable -- through Trap() and a Page.Run -- or hands to a
//      [PageHandler] is open, although the test never called OpenEdit/OpenView on it.
//   3. A variable whose Close() was refused by OnQueryClosePage -- a plain veto, or an error a
//      [MessageHandler] consumed -- can be opened again: codeunit 60419 shows it is not open
//      after that Close(), and this shows it is not stuck either.
//
// Every "raises" arm has an opened control beside it, so an implementation that treats every
// variable as open, or none, fails a named assertion.
//
// Filed from AlRunner#4722 and AlRunner#4729.
codeunit 67040 "TPNO Never Opened Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Probe: Codeunit "TPNO Probe";
        HandlerDescr: Text;
        HandlerCalls: Integer;
        MessageCalls: Integer;
        NotOpenErr: Label 'The TestPage is not open';

    local procedure Initialize(var Row: Record "TPNO Row")
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'R1';
        Row.Descr := 'First row';
        Row.Insert();
        HandlerDescr := '';
        HandlerCalls := 0;
        MessageCalls := 0;
    end;

    // CLAIM 1: Close() on a variable nobody opened raises.
    [Test]
    procedure NeverOpened_CloseRaisesNotOpen()
    var
        Row: Record "TPNO Row";
        Card: TestPage "TPNO Row Card";
    begin
        Initialize(Row);

        asserterror Card.Close();

        Assert.ExpectedError(NotOpenErr);
    end;

    // CLAIM 1, the field-read shape.
    [Test]
    procedure NeverOpened_FieldReadRaisesNotOpen()
    var
        Row: Record "TPNO Row";
        Card: TestPage "TPNO Row Card";
        Ignored: Text;
    begin
        Initialize(Row);

        asserterror Ignored := Card.Descr.Value();

        Assert.ExpectedError(NotOpenErr);
    end;

    // CLAIM 1, the navigation shape: GoToRecord needs an open page to move.
    [Test]
    procedure NeverOpened_GoToRecordRaisesNotOpen()
    var
        Row: Record "TPNO Row";
        Card: TestPage "TPNO Row Card";
    begin
        Initialize(Row);

        asserterror Card.GoToRecord(Row);

        Assert.ExpectedError(NotOpenErr);
    end;

    // CONTROL for CLAIM 1: the same variable, opened, answers all three.
    [Test]
    procedure Opened_FieldReadGoToRecordAndCloseWork()
    var
        Row: Record "TPNO Row";
        Card: TestPage "TPNO Row Card";
    begin
        Initialize(Row);

        Card.OpenView();
        Card.GoToRecord(Row);
        Assert.AreEqual('First row', Card.Descr.Value(), 'An opened TestPage must answer a field read.');
        Card.Close();
    end;

    // CLAIM 2, Trap(): the variable was never opened by the test, and a Page.Run attaches the
    // page to it; it is then open and readable, and Close() works.
    [Test]
    procedure Trapped_PageRunOpensTheVariable()
    var
        Row: Record "TPNO Row";
        Card: TestPage "TPNO Row Card";
    begin
        Initialize(Row);

        Card.Trap();
        Page.Run(Page::"TPNO Row Card", Row);

        Assert.AreEqual('First row', Card.Descr.Value(), 'A trapped TestPage must be open once the page runs.');
        Card.Close();
    end;

    // CLAIM 2, [PageHandler]: the page BC hands to the handler is open.
    [Test]
    [HandlerFunctions('TpnoRowCardHandler')]
    procedure PageHandler_ReceivesAnOpenPage()
    var
        Row: Record "TPNO Row";
    begin
        Initialize(Row);

        Page.Run(Page::"TPNO Row Card", Row);

        Assert.AreEqual(1, HandlerCalls, 'The [PageHandler] must run once.');
        Assert.AreEqual('First row', HandlerDescr, 'The page handed to a [PageHandler] must be open and readable.');
    end;

    // CLAIM 3: after a vetoed Close(), the same variable opens again.
    [Test]
    procedure VetoedClose_VariableOpensAgain()
    var
        Card: TestPage "TPNO Veto Card";
    begin
        Probe.Reset(Probe.ModeVeto());

        Card.OpenEdit();
        Card.Close();

        Probe.Reset(Probe.ModeAllow());
        Card.OpenView();
        Assert.AreEqual('OPENED', Card.Marker.Value(), 'A TestPage whose Close() was vetoed must open again.');
        Card.Close();
    end;

    // CLAIM 3, the error-consumed refusal.
    [Test]
    [HandlerFunctions('TpnoMessage')]
    procedure ErrorConsumedClose_VariableOpensAgain()
    var
        Card: TestPage "TPNO Veto Card";
    begin
        MessageCalls := 0;
        Probe.Reset(Probe.ModeError());

        Card.OpenEdit();
        Card.Close();
        Assert.AreEqual(1, MessageCalls, 'The close-time error must reach the [MessageHandler] once.');

        Probe.Reset(Probe.ModeAllow());
        Card.OpenView();
        Assert.AreEqual('OPENED', Card.Marker.Value(), 'A TestPage whose Close() was refused by an error must open again.');
        Card.Close();
    end;

    [PageHandler]
    procedure TpnoRowCardHandler(var Card: TestPage "TPNO Row Card")
    begin
        HandlerCalls += 1;
        HandlerDescr := Card.Descr.Value();
    end;

    [MessageHandler]
    procedure TpnoMessage(Msg: Text[1024])
    begin
        MessageCalls += 1;
    end;
}
