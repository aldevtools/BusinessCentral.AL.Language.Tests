// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: Assert (60021), and the table, pages, report and codeunits declared below.
//
// WHAT A TESTPAGE VARIABLE IS AFTER ITS BUILT-IN CLOSING ACTION. Measured as record-only probes
// (corpus PR 555), identical on every cloud leg, and agreeing with the Windows nightly.
//
// The built-in OK and Cancel actions CLOSE the page, on the variable the test opened and on the page
// BC hands a [ModalPageHandler], [PageHandler] or [RequestPageHandler] alike. Closing raises
// OnQueryClosePage with the action's result and then OnClosePage, once each, and from then on EVERY
// call on that variable raises "The TestPage is not open.": a control read, a SetValue, an action,
// the page-level calls, a second OK or Cancel, Close. An Open* call on the variable opens it again
// and shows a fresh page on the FIRST row of the view.
//
// A value typed on the page is saved by OK, and the typed row of an OpenNew is inserted by it. A
// page that declares SaveValues shows what OK stored when it opens again, and shows nothing after
// Cancel. A card or a list offers no Cancel action, so Cancel().Invoke() raises "The built-in action
// = Cancel is not found on the page." and the variable stays open: opening it again raises "The
// TestPage is already open." A StandardDialog offers Cancel, and it closes the page like OK does.
//
// An OK that does NOT close the page leaves the variable open and usable:
//   * OnQueryClosePage returning false refuses the close; a later OK attempts it again.
//   * a save the table refuses (a duplicate key on a DelayedInsert page, an OnInsert error) raises
//     nothing at OK(), counts one validation error, raises no close trigger, and keeps the row the
//     page shows readable.
//
// The page a handler receives closes the same way. RunModal then reports the result the action chose:
// LookupOK / LookupCancel for a card and for a list run with LookupMode, OK for a plain list, and the
// close trigger sees the same value. A plain list offers no Cancel.
//
// A request page closes at its first OK or Cancel: a second one raises "not open" and cannot change
// what RunRequestPage returns.
//
// Written by agent stma-auto-7, an automated implementation agent acting on the account holder's
// behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#5400.

table 69650 "TPC Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Qty; Integer) { }
        field(3; Note; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        if Note = 'FAIL' then
            Error('TPC insert refused');
    end;
}

// Records what the close triggers did, in order, so a test reads the sequence rather than a count.
codeunit 69650 "TPC Log"
{
    SingleInstance = true;

    var
        LogText: Text;
        VetoClose: Boolean;

    procedure Reset()
    begin
        LogText := '';
        VetoClose := false;
    end;

    procedure Add(Txt: Text)
    begin
        LogText += Txt + ',';
    end;

    procedure Text(): Text
    begin
        exit(LogText);
    end;

    procedure SetVeto(NewValue: Boolean)
    begin
        VetoClose := NewValue;
    end;

    procedure Veto(): Boolean
    begin
        exit(VetoClose);
    end;
}

page 69650 "TPC Card"
{
    PageType = Card;
    SourceTable = "TPC Row";
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            field(NoteCtl; Rec.Note) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Act)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    TPCLog.Add('act');
                end;
            }
        }
    }

    var
        TPCLog: Codeunit "TPC Log";

    trigger OnOpenPage()
    begin
        TPCLog.Add('open');
    end;

    trigger OnClosePage()
    begin
        TPCLog.Add('close');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        TPCLog.Add('qcp:' + Format(CloseAction));
        exit(not TPCLog.Veto());
    end;
}

page 69651 "TPC List"
{
    PageType = List;
    SourceTable = "TPC Row";
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
                field(NoteCtl; Rec.Note) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Act)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    TPCLog.Add('act');
                end;
            }
        }
    }

    var
        TPCLog: Codeunit "TPC Log";

    trigger OnOpenPage()
    begin
        TPCLog.Add('open');
    end;

    trigger OnClosePage()
    begin
        TPCLog.Add('close');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        TPCLog.Add('qcp:' + Format(CloseAction));
        exit(not TPCLog.Veto());
    end;
}

// A dialog over no table, whose fields are page variables.
page 69652 "TPC Dialog"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; NoVar) { ApplicationArea = All; }
            field(QtyCtl; QtyVar) { ApplicationArea = All; }
        }
    }

    var
        NoVar: Code[20];
        QtyVar: Integer;
        TPCLog: Codeunit "TPC Log";

    trigger OnOpenPage()
    begin
        TPCLog.Add('open');
    end;

    trigger OnClosePage()
    begin
        TPCLog.Add('close');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        TPCLog.Add('qcp:' + Format(CloseAction));
        exit(true);
    end;
}

page 69653 "TPC Saved Dialog"
{
    PageType = StandardDialog;
    SaveValues = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Remembered; RememberedVar) { ApplicationArea = All; }
        }
    }

    var
        RememberedVar: Text[50];
}

page 69654 "TPC Saved Card"
{
    PageType = Card;
    SaveValues = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Remembered; RememberedVar) { ApplicationArea = All; }
        }
    }

    var
        RememberedVar: Text[50];
}

report 69650 "TPC Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "TPC Row")
        {
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(QtyOpt; QtyOption)
                {
                    ApplicationArea = All;
                }
            }
        }

        trigger OnOpenPage()
        begin
            TPCLog.Add('open');
        end;

        trigger OnClosePage()
        begin
            TPCLog.Add('close');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            TPCLog.Add('qcp:' + Format(CloseAction));
            exit(true);
        end;
    }

    var
        QtyOption: Integer;
        TPCLog: Codeunit "TPC Log";
}

codeunit 69651 "TPC Closing Action Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        TPCLog: Codeunit "TPC Log";
        NotOpenTxt: Label 'The TestPage is not open.', Locked = true;
        AlreadyOpenTxt: Label 'The TestPage is already open.', Locked = true;
        CancelNotFoundTxt: Label 'The built-in action = Cancel is not found on the page.', Locked = true;
        HandlerResult: Text;
        HandlerReadError: Text;
        HandlerSecondCloseError: Text;
        HandlerCancelError: Text;
        HandlerValue: Text;

    // A, B, C. Committed, so that what an asserterror rolls back does not touch them.
    local procedure Seed()
    var
        Row: Record "TPC Row";
    begin
        Row.DeleteAll();
        Row.Init(); Row."No." := 'A'; Row.Qty := 1; Row.Insert();
        Row.Init(); Row."No." := 'B'; Row.Qty := 2; Row.Insert();
        Row.Init(); Row."No." := 'C'; Row.Qty := 3; Row.Insert();
        Commit();
        TPCLog.Reset();
    end;

    local procedure AssertContains(Actual: Text; Expected: Text; Msg: Text)
    begin
        Assert.IsTrue(StrPos(Actual, Expected) > 0, StrSubstNo('%1 (got "%2")', Msg, Actual));
    end;

    // ---- Card the test opened ----

    local procedure AssertEveryCallRaisesNotOpenCard(var P: TestPage "TPC Card")
    var
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        asserterror T := P.NoCtl.Value();
        Assert.ExpectedError(NotOpenTxt);
        asserterror I := P.QtyCtl.AsInteger();
        Assert.ExpectedError(NotOpenTxt);
        asserterror T := P.Caption();
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.Editable();
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.QtyCtl.Editable();
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.First();
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.Last();
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.Next();
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.Previous();
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror I := P.ValidationErrorCount();
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.QtyCtl.SetValue(77);
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.NoCtl.AssertEquals('A');
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.Act.Invoke();
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.Act.Enabled();
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.Close();
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.OK().Invoke();
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.Cancel().Invoke();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure Card_OK_RaisesTheCloseTriggersOnce()
    var
        P: TestPage "TPC Card";
    begin
        Seed();
        P.OpenEdit();
        P.OK().Invoke();

        Assert.AreEqual('open,qcp:OK,close,', TPCLog.Text(), 'OK closes the page: OnQueryClosePage with OK, then OnClosePage, once each');
    end;

    [Test]
    procedure Card_OK_EveryLaterCallRaisesNotOpen()
    var
        P: TestPage "TPC Card";
    begin
        Seed();
        P.OpenEdit();
        P.OK().Invoke();

        AssertEveryCallRaisesNotOpenCard(P);
    end;

    [Test]
    procedure Card_OK_ThenEveryOpenModeOpensTheVariableAgain()
    var
        Edit: TestPage "TPC Card";
        View: TestPage "TPC Card";
        NewRow: TestPage "TPC Card";
    begin
        Seed();
        Edit.OpenEdit();
        Edit.GoToKey('B');
        Edit.OK().Invoke();
        Edit.OpenEdit();
        Assert.AreEqual('A', Edit.NoCtl.Value(), 'a reopened variable shows a fresh page, on the first row and not where the closed one stood');
        Assert.AreEqual(1, Edit.QtyCtl.AsInteger(), 'the first row is shown whole');
        asserterror Edit.OpenEdit();
        Assert.ExpectedError(AlreadyOpenTxt);

        View.OpenEdit();
        View.OK().Invoke();
        View.OpenView();
        Assert.AreEqual('A', View.NoCtl.Value(), 'OpenView opens the variable again after OK');

        NewRow.OpenEdit();
        NewRow.OK().Invoke();
        NewRow.OpenNew();
        Assert.AreEqual('', NewRow.NoCtl.Value(), 'OpenNew opens the variable again after OK, on a blank row');
    end;

    [Test]
    procedure Card_OK_SavesTheTypedValue_AndTheReopenedPageShowsIt()
    var
        P: TestPage "TPC Card";
        Row: Record "TPC Row";
    begin
        Seed();
        P.OpenEdit();
        P.QtyCtl.SetValue(5);
        P.OK().Invoke();

        Row.Get('A');
        Assert.AreEqual(5, Row.Qty, 'OK saves the value typed on the page');
        P.OpenEdit();
        Assert.AreEqual(5, P.QtyCtl.AsInteger(), 'the reopened page shows the saved value');
    end;

    [Test]
    procedure Card_OpenNew_OK_InsertsTheRow_AndTheReopenedNewPageIsBlank()
    var
        P: TestPage "TPC Card";
        Row: Record "TPC Row";
    begin
        Seed();
        P.OpenNew();
        P.NoCtl.SetValue('N1');
        P.QtyCtl.SetValue(9);
        P.OK().Invoke();

        Row.Get('N1');
        Assert.AreEqual(9, Row.Qty, 'OK inserts the row the page started');
        Assert.AreEqual(4, Row.Count(), 'exactly one row was added');
        Assert.AreEqual('open,qcp:OK,close,', TPCLog.Text(), 'OK closes the page that started the row');
        P.OpenNew();
        Assert.AreEqual('', P.NoCtl.Value(), 'the reopened new page does not carry the row the closed one inserted');
    end;

    [Test]
    procedure Card_NotClosed_OpenAgainRaisesAlreadyOpen()
    var
        P: TestPage "TPC Card";
    begin
        Seed();
        P.OpenEdit();

        asserterror P.OpenEdit();
        Assert.ExpectedError(AlreadyOpenTxt);
        Assert.AreEqual('A', P.NoCtl.Value(), 'a page that was not closed stays usable');
    end;

    [Test]
    procedure Card_Cancel_IsNotOffered_AndTheVariableStaysOpen()
    var
        P: TestPage "TPC Card";
    begin
        Seed();
        P.OpenEdit();

        asserterror P.Cancel().Invoke();
        Assert.ExpectedError(CancelNotFoundTxt);
        Assert.AreEqual('open,', TPCLog.Text(), 'no close trigger ran');
        Assert.AreEqual('A', P.NoCtl.Value(), 'the page is still open and shows its row');
        asserterror P.OpenEdit();
        Assert.ExpectedError(AlreadyOpenTxt);
    end;

    [Test]
    procedure Card_OK_RefusedByOnQueryClosePage_KeepsThePageOpen_AndASecondOKClosesIt()
    var
        P: TestPage "TPC Card";
        T: Text;
    begin
        Seed();
        TPCLog.SetVeto(true);
        P.OpenEdit();
        P.OK().Invoke();

        Assert.AreEqual('open,qcp:OK,', TPCLog.Text(), 'the close was attempted and refused, so no OnClosePage');
        Assert.AreEqual('A', P.NoCtl.Value(), 'a refused close leaves the variable usable');
        asserterror P.OpenEdit();
        Assert.ExpectedError(AlreadyOpenTxt);

        TPCLog.SetVeto(false);
        P.OK().Invoke();
        Assert.AreEqual('open,qcp:OK,qcp:OK,close,', TPCLog.Text(), 'the second OK attempts the close again and succeeds');
        asserterror T := P.NoCtl.Value();
        Assert.ExpectedError(NotOpenTxt);
        P.OpenEdit();
        Assert.AreEqual('A', P.NoCtl.Value(), 'the closed variable opens again');
    end;

    [Test]
    procedure Card_TwoVariablesOfOnePageType_CloseIndependently()
    var
        First: TestPage "TPC Card";
        Second: TestPage "TPC Card";
        T: Text;
    begin
        Seed();
        First.OpenEdit();
        Second.OpenEdit();
        First.OK().Invoke();

        Assert.AreEqual('A', Second.NoCtl.Value(), 'the other variable is still open');
        asserterror T := First.NoCtl.Value();
        Assert.ExpectedError(NotOpenTxt);
        First.OpenEdit();
        Second.OK().Invoke();
        Assert.AreEqual('A', First.NoCtl.Value(), 'closing the second leaves the reopened first open');
        asserterror T := Second.NoCtl.Value();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure Card_OK_AfterATableRefusedDuplicateKey_RaisesNothing_AndKeepsThePageOpen()
    var
        P: TestPage "TPC Card";
        Row: Record "TPC Row";
    begin
        Seed();
        P.OpenNew();
        P.NoCtl.SetValue('A');
        P.QtyCtl.SetValue(9);
        P.OK().Invoke();

        Assert.AreEqual(1, P.ValidationErrorCount(), 'the refused save is the page''s one validation error, and OK raised nothing');
        Assert.AreEqual('A', P.NoCtl.Value(), 'the page is still open and shows the row it could not save');
        Assert.AreEqual('open,', TPCLog.Text(), 'a refused save raises no close trigger');
        Row.Get('A');
        Assert.AreEqual(1, Row.Qty, 'the existing row is untouched');
        asserterror P.OpenEdit();
        Assert.ExpectedError(AlreadyOpenTxt);
    end;

    [Test]
    procedure Card_OK_AfterAnOnInsertError_RaisesNothing_AndKeepsThePageOpen()
    var
        P: TestPage "TPC Card";
        Row: Record "TPC Row";
    begin
        Seed();
        P.OpenNew();
        P.NoCtl.SetValue('N2');
        P.NoteCtl.SetValue('FAIL');
        P.OK().Invoke();

        Assert.AreEqual(1, P.ValidationErrorCount(), 'the table''s OnInsert refusal is the page''s one validation error, and OK raised nothing');
        Assert.AreEqual('N2', P.NoCtl.Value(), 'the page is still open and shows the row it could not save');
        Assert.AreEqual('open,', TPCLog.Text(), 'a refused save raises no close trigger');
        Assert.IsFalse(Row.Get('N2'), 'the refused row was not inserted');
        asserterror P.OpenEdit();
        Assert.ExpectedError(AlreadyOpenTxt);
    end;

    // ---- List the test opened ----

    local procedure AssertEveryCallRaisesNotOpenList(var P: TestPage "TPC List")
    var
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        asserterror T := P.NoCtl.Value();
        Assert.ExpectedError(NotOpenTxt);
        asserterror I := P.QtyCtl.AsInteger();
        Assert.ExpectedError(NotOpenTxt);
        asserterror T := P.Caption();
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.Editable();
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.QtyCtl.Editable();
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.First();
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.Last();
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.Next();
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.Previous();
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror I := P.ValidationErrorCount();
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.QtyCtl.SetValue(77);
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.NoCtl.AssertEquals('A');
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.Act.Invoke();
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.Act.Enabled();
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.Close();
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.OK().Invoke();
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.Cancel().Invoke();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure List_OK_RaisesTheCloseTriggersOnce()
    var
        P: TestPage "TPC List";
    begin
        Seed();
        P.OpenEdit();
        P.OK().Invoke();

        Assert.AreEqual('open,qcp:OK,close,', TPCLog.Text(), 'OK closes the page: OnQueryClosePage with OK, then OnClosePage, once each');
    end;

    [Test]
    procedure List_OK_EveryLaterCallRaisesNotOpen()
    var
        P: TestPage "TPC List";
    begin
        Seed();
        P.OpenEdit();
        P.OK().Invoke();

        AssertEveryCallRaisesNotOpenList(P);
    end;

    [Test]
    procedure List_OK_ThenEveryOpenModeOpensTheVariableAgain()
    var
        Edit: TestPage "TPC List";
        View: TestPage "TPC List";
        NewRow: TestPage "TPC List";
    begin
        Seed();
        Edit.OpenEdit();
        Edit.GoToKey('B');
        Edit.OK().Invoke();
        Edit.OpenEdit();
        Assert.AreEqual('A', Edit.NoCtl.Value(), 'a reopened variable shows a fresh page, on the first row and not where the closed one stood');
        Assert.AreEqual(1, Edit.QtyCtl.AsInteger(), 'the first row is shown whole');
        asserterror Edit.OpenEdit();
        Assert.ExpectedError(AlreadyOpenTxt);

        View.OpenEdit();
        View.OK().Invoke();
        View.OpenView();
        Assert.AreEqual('A', View.NoCtl.Value(), 'OpenView opens the variable again after OK');

        NewRow.OpenEdit();
        NewRow.OK().Invoke();
        NewRow.OpenNew();
        Assert.AreEqual('', NewRow.NoCtl.Value(), 'OpenNew opens the variable again after OK, on a blank row');
    end;

    [Test]
    procedure List_OK_SavesTheTypedValue_AndTheReopenedPageShowsIt()
    var
        P: TestPage "TPC List";
        Row: Record "TPC Row";
    begin
        Seed();
        P.OpenEdit();
        P.QtyCtl.SetValue(5);
        P.OK().Invoke();

        Row.Get('A');
        Assert.AreEqual(5, Row.Qty, 'OK saves the value typed on the page');
        P.OpenEdit();
        Assert.AreEqual(5, P.QtyCtl.AsInteger(), 'the reopened page shows the saved value');
    end;

    [Test]
    procedure List_OpenNew_OK_InsertsTheRow_AndTheReopenedNewPageIsBlank()
    var
        P: TestPage "TPC List";
        Row: Record "TPC Row";
    begin
        Seed();
        P.OpenNew();
        P.NoCtl.SetValue('N1');
        P.QtyCtl.SetValue(9);
        P.OK().Invoke();

        Row.Get('N1');
        Assert.AreEqual(9, Row.Qty, 'OK inserts the row the page started');
        Assert.AreEqual(4, Row.Count(), 'exactly one row was added');
        Assert.AreEqual('open,qcp:OK,close,', TPCLog.Text(), 'OK closes the page that started the row');
        P.OpenNew();
        Assert.AreEqual('', P.NoCtl.Value(), 'the reopened new page does not carry the row the closed one inserted');
    end;

    [Test]
    procedure List_NotClosed_OpenAgainRaisesAlreadyOpen()
    var
        P: TestPage "TPC List";
    begin
        Seed();
        P.OpenEdit();

        asserterror P.OpenEdit();
        Assert.ExpectedError(AlreadyOpenTxt);
        Assert.AreEqual('A', P.NoCtl.Value(), 'a page that was not closed stays usable');
    end;

    [Test]
    procedure List_Cancel_IsNotOffered_AndTheVariableStaysOpen()
    var
        P: TestPage "TPC List";
    begin
        Seed();
        P.OpenEdit();

        asserterror P.Cancel().Invoke();
        Assert.ExpectedError(CancelNotFoundTxt);
        Assert.AreEqual('open,', TPCLog.Text(), 'no close trigger ran');
        Assert.AreEqual('A', P.NoCtl.Value(), 'the page is still open and shows its row');
        asserterror P.OpenEdit();
        Assert.ExpectedError(AlreadyOpenTxt);
    end;

    [Test]
    procedure List_OK_RefusedByOnQueryClosePage_KeepsThePageOpen_AndASecondOKClosesIt()
    var
        P: TestPage "TPC List";
        T: Text;
    begin
        Seed();
        TPCLog.SetVeto(true);
        P.OpenEdit();
        P.OK().Invoke();

        Assert.AreEqual('open,qcp:OK,', TPCLog.Text(), 'the close was attempted and refused, so no OnClosePage');
        Assert.AreEqual('A', P.NoCtl.Value(), 'a refused close leaves the variable usable');
        asserterror P.OpenEdit();
        Assert.ExpectedError(AlreadyOpenTxt);

        TPCLog.SetVeto(false);
        P.OK().Invoke();
        Assert.AreEqual('open,qcp:OK,qcp:OK,close,', TPCLog.Text(), 'the second OK attempts the close again and succeeds');
        asserterror T := P.NoCtl.Value();
        Assert.ExpectedError(NotOpenTxt);
        P.OpenEdit();
        Assert.AreEqual('A', P.NoCtl.Value(), 'the closed variable opens again');
    end;

    [Test]
    procedure List_TwoVariablesOfOnePageType_CloseIndependently()
    var
        First: TestPage "TPC List";
        Second: TestPage "TPC List";
        T: Text;
    begin
        Seed();
        First.OpenEdit();
        Second.OpenEdit();
        First.OK().Invoke();

        Assert.AreEqual('A', Second.NoCtl.Value(), 'the other variable is still open');
        asserterror T := First.NoCtl.Value();
        Assert.ExpectedError(NotOpenTxt);
        First.OpenEdit();
        Second.OK().Invoke();
        Assert.AreEqual('A', First.NoCtl.Value(), 'closing the second leaves the reopened first open');
        asserterror T := Second.NoCtl.Value();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure List_OK_AfterATableRefusedDuplicateKey_RaisesNothing_AndKeepsThePageOpen()
    var
        P: TestPage "TPC List";
        Row: Record "TPC Row";
    begin
        Seed();
        P.OpenNew();
        P.NoCtl.SetValue('A');
        P.QtyCtl.SetValue(9);
        P.OK().Invoke();

        Assert.AreEqual(1, P.ValidationErrorCount(), 'the refused save is the page''s one validation error, and OK raised nothing');
        Assert.AreEqual('A', P.NoCtl.Value(), 'the page is still open and shows the row it could not save');
        Assert.AreEqual('open,', TPCLog.Text(), 'a refused save raises no close trigger');
        Row.Get('A');
        Assert.AreEqual(1, Row.Qty, 'the existing row is untouched');
        asserterror P.OpenEdit();
        Assert.ExpectedError(AlreadyOpenTxt);
    end;

    [Test]
    procedure List_OK_AfterAnOnInsertError_RaisesNothing_AndKeepsThePageOpen()
    var
        P: TestPage "TPC List";
        Row: Record "TPC Row";
    begin
        Seed();
        P.OpenNew();
        P.NoCtl.SetValue('N2');
        P.NoteCtl.SetValue('FAIL');
        P.OK().Invoke();

        Assert.AreEqual(1, P.ValidationErrorCount(), 'the table''s OnInsert refusal is the page''s one validation error, and OK raised nothing');
        Assert.AreEqual('N2', P.NoCtl.Value(), 'the page is still open and shows the row it could not save');
        Assert.AreEqual('open,', TPCLog.Text(), 'a refused save raises no close trigger');
        Assert.IsFalse(Row.Get('N2'), 'the refused row was not inserted');
        asserterror P.OpenEdit();
        Assert.ExpectedError(AlreadyOpenTxt);
    end;

    // ---- a StandardDialog the test opened: it offers Cancel, and Cancel closes it like OK ----

    local procedure AssertEveryCallRaisesNotOpenDialog(var P: TestPage "TPC Dialog")
    var
        T: Text;
        I: Integer;
    begin
        asserterror T := P.NoCtl.Value();
        Assert.ExpectedError(NotOpenTxt);
        asserterror I := P.QtyCtl.AsInteger();
        Assert.ExpectedError(NotOpenTxt);
        asserterror T := P.Caption();
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.QtyCtl.SetValue(77);
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.Close();
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.OK().Invoke();
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.Cancel().Invoke();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure Dialog_OK_ClosesThePage_AndTheVariableOpensAgain()
    var
        P: TestPage "TPC Dialog";
    begin
        TPCLog.Reset();
        P.OpenEdit();
        P.OK().Invoke();

        Assert.AreEqual('open,qcp:OK,close,', TPCLog.Text(), 'OK closes the dialog');
        AssertEveryCallRaisesNotOpenDialog(P);
        P.OpenEdit();
        Assert.AreEqual(0, P.QtyCtl.AsInteger(), 'the variable opens again');
    end;

    [Test]
    procedure Dialog_OK_ThenReopen_ThenClose_ReportsCancelAsOnAFreshPage()
    var
        P: TestPage "TPC Dialog";
    begin
        P.OpenEdit();
        P.OK().Invoke();
        TPCLog.Reset();

        P.OpenEdit();
        P.Close();

        Assert.AreEqual('open,qcp:Cancel,close,', TPCLog.Text(), 'the reopened dialog is a fresh page, so closing it reports Cancel and nothing remembers the earlier OK');
    end;

    [Test]
    procedure Dialog_Cancel_ClosesThePage_AndTheVariableOpensAgain()
    var
        P: TestPage "TPC Dialog";
    begin
        TPCLog.Reset();
        P.OpenEdit();
        P.Cancel().Invoke();

        Assert.AreEqual('open,qcp:Cancel,close,', TPCLog.Text(), 'Cancel closes the dialog, and OnQueryClosePage sees Cancel');
        AssertEveryCallRaisesNotOpenDialog(P);
        P.OpenEdit();
        Assert.AreEqual(0, P.QtyCtl.AsInteger(), 'the variable opens again');
    end;

    [Test]
    procedure SaveValuesDialog_OK_StoresWhatWasTyped_AndTheReopenedPageShowsIt()
    var
        P: TestPage "TPC Saved Dialog";
    begin
        P.OpenEdit();
        P.Remembered.SetValue('dialog-ok');
        P.OK().Invoke();

        P.OpenEdit();
        Assert.AreEqual('dialog-ok', P.Remembered.Value(), 'OK stores the value a SaveValues page shows when it opens again');
    end;

    // The store belongs to the user, not to the test, so the value another test stored may still be
    // shown: what Cancel must not do is store what was typed.
    [Test]
    procedure SaveValuesDialog_Cancel_StoresNothing()
    var
        P: TestPage "TPC Saved Dialog";
    begin
        P.OpenEdit();
        P.Remembered.SetValue('dialog-cancel');
        P.Cancel().Invoke();

        P.OpenEdit();
        Assert.AreNotEqual('dialog-cancel', P.Remembered.Value(), 'Cancel stores nothing');
    end;

    [Test]
    procedure SaveValuesCard_OK_StoresWhatWasTyped_AndTheReopenedPageShowsIt()
    var
        P: TestPage "TPC Saved Card";
    begin
        P.OpenEdit();
        P.Remembered.SetValue('card-ok');
        P.OK().Invoke();

        P.OpenEdit();
        Assert.AreEqual('card-ok', P.Remembered.Value(), 'OK stores the value a SaveValues page shows when it opens again');
    end;

    // ---- the Card page a handler receives ----

    [TryFunction]
    local procedure TryRunCard(var Result: Action)
    var
        Row: Record "TPC Row";
    begin
        Row.FindFirst();
        Result := Page.RunModal(Page::"TPC Card", Row);
    end;

    [ModalPageHandler]
    procedure CardOkHandler(var P: TestPage "TPC Card")
    var
        T: Text;
        B: Boolean;
    begin
        P.OK().Invoke();
        asserterror T := P.NoCtl.Value();
        HandlerReadError := GetLastErrorText();
        asserterror B := P.First();
        HandlerSecondCloseError := GetLastErrorText();
    end;

    [Test]
    [HandlerFunctions('CardOkHandler')]
    procedure HandlerCard_OK_ClosesThePage_AndRunModalReportsTheResult()
    var
        Result: Action;
    begin
        Seed();
        HandlerReadError := '';
        HandlerSecondCloseError := '';
        Assert.IsTrue(TryRunCard(Result), 'RunModal returns');

        AssertContains(HandlerReadError, NotOpenTxt, 'a read after OK raises not open inside the handler');
        AssertContains(HandlerSecondCloseError, NotOpenTxt, 'so does a move');
        Assert.AreEqual('LookupOK', Format(Result), 'RunModal reports the action the handler chose');
        Assert.AreEqual('open,qcp:LookupOK,close,', TPCLog.Text(), 'OnQueryClosePage sees the same value, and the triggers ran once each');
    end;

    [ModalPageHandler]
    procedure CardCancelHandler(var P: TestPage "TPC Card")
    var
        T: Text;
    begin
        P.Cancel().Invoke();
        asserterror T := P.NoCtl.Value();
        HandlerReadError := GetLastErrorText();
        asserterror P.OK().Invoke();
        HandlerSecondCloseError := GetLastErrorText();
    end;

    [Test]
    [HandlerFunctions('CardCancelHandler')]
    procedure HandlerCard_Cancel_ClosesThePage_AndRunModalReportsTheResult()
    var
        Result: Action;
    begin
        Seed();
        HandlerReadError := '';
        HandlerSecondCloseError := '';
        Assert.IsTrue(TryRunCard(Result), 'RunModal returns');

        AssertContains(HandlerReadError, NotOpenTxt, 'a read after Cancel raises not open inside the handler');
        AssertContains(HandlerSecondCloseError, NotOpenTxt, 'a second closing action raises not open too');
        Assert.AreEqual('LookupCancel', Format(Result), 'RunModal reports Cancel, and the second action cannot change it');
        Assert.AreEqual('open,qcp:LookupCancel,close,', TPCLog.Text(), 'OnQueryClosePage sees the same value, and the triggers ran once each');
    end;

    // ---- the List page a handler receives ----

    [TryFunction]
    local procedure TryRunList(var Result: Action)
    var
        ListPage: Page "TPC List";
    begin
        Result := ListPage.RunModal();
    end;

    [ModalPageHandler]
    procedure ListOkHandler(var P: TestPage "TPC List")
    var
        T: Text;
        B: Boolean;
    begin
        P.OK().Invoke();
        asserterror T := P.NoCtl.Value();
        HandlerReadError := GetLastErrorText();
        asserterror B := P.First();
        HandlerSecondCloseError := GetLastErrorText();
    end;

    [Test]
    [HandlerFunctions('ListOkHandler')]
    procedure HandlerList_OK_ClosesThePage_AndRunModalReportsTheResult()
    var
        Result: Action;
    begin
        Seed();
        HandlerReadError := '';
        HandlerSecondCloseError := '';
        Assert.IsTrue(TryRunList(Result), 'RunModal returns');

        AssertContains(HandlerReadError, NotOpenTxt, 'a read after OK raises not open inside the handler');
        AssertContains(HandlerSecondCloseError, NotOpenTxt, 'so does a move');
        Assert.AreEqual('OK', Format(Result), 'RunModal reports the action the handler chose');
        Assert.AreEqual('open,qcp:OK,close,', TPCLog.Text(), 'OnQueryClosePage sees the same value, and the triggers ran once each');
    end;

    [ModalPageHandler]
    procedure ListCancelHandler(var P: TestPage "TPC List")
    begin
        asserterror P.Cancel().Invoke();
        HandlerCancelError := GetLastErrorText();
        HandlerValue := P.NoCtl.Value();
    end;

    [Test]
    [HandlerFunctions('ListCancelHandler')]
    procedure HandlerList_Cancel_IsNotOffered_AndTheHandlerReturnWithoutClosingAnswersOK()
    var
        Result: Action;
    begin
        Seed();
        HandlerCancelError := '';
        HandlerValue := '';
        Assert.IsTrue(TryRunList(Result), 'RunModal returns');

        AssertContains(HandlerCancelError, CancelNotFoundTxt, 'a plain list offers no Cancel');
        Assert.AreEqual('A', HandlerValue, 'the page is still open after the refused Cancel');
        Assert.AreEqual('OK', Format(Result), 'a handler that closes nothing answers OK for a plain list');
        Assert.AreEqual('open,qcp:OK,close,', TPCLog.Text(), 'the round trip closed the page');
    end;

    // ---- the Lookup page a handler receives ----

    [TryFunction]
    local procedure TryRunLookup(var Result: Action)
    var
        ListPage: Page "TPC List";
    begin
        ListPage.LookupMode(true);
        Result := ListPage.RunModal();
    end;

    [ModalPageHandler]
    procedure LookupOkHandler(var P: TestPage "TPC List")
    var
        T: Text;
        B: Boolean;
    begin
        P.OK().Invoke();
        asserterror T := P.NoCtl.Value();
        HandlerReadError := GetLastErrorText();
        asserterror B := P.First();
        HandlerSecondCloseError := GetLastErrorText();
    end;

    [Test]
    [HandlerFunctions('LookupOkHandler')]
    procedure HandlerLookup_OK_ClosesThePage_AndRunModalReportsTheResult()
    var
        Result: Action;
    begin
        Seed();
        HandlerReadError := '';
        HandlerSecondCloseError := '';
        Assert.IsTrue(TryRunLookup(Result), 'RunModal returns');

        AssertContains(HandlerReadError, NotOpenTxt, 'a read after OK raises not open inside the handler');
        AssertContains(HandlerSecondCloseError, NotOpenTxt, 'so does a move');
        Assert.AreEqual('LookupOK', Format(Result), 'RunModal reports the action the handler chose');
        Assert.AreEqual('open,qcp:LookupOK,close,', TPCLog.Text(), 'OnQueryClosePage sees the same value, and the triggers ran once each');
    end;

    [ModalPageHandler]
    procedure LookupCancelHandler(var P: TestPage "TPC List")
    var
        T: Text;
    begin
        P.Cancel().Invoke();
        asserterror T := P.NoCtl.Value();
        HandlerReadError := GetLastErrorText();
        asserterror P.OK().Invoke();
        HandlerSecondCloseError := GetLastErrorText();
    end;

    [Test]
    [HandlerFunctions('LookupCancelHandler')]
    procedure HandlerLookup_Cancel_ClosesThePage_AndRunModalReportsTheResult()
    var
        Result: Action;
    begin
        Seed();
        HandlerReadError := '';
        HandlerSecondCloseError := '';
        Assert.IsTrue(TryRunLookup(Result), 'RunModal returns');

        AssertContains(HandlerReadError, NotOpenTxt, 'a read after Cancel raises not open inside the handler');
        AssertContains(HandlerSecondCloseError, NotOpenTxt, 'a second closing action raises not open too');
        Assert.AreEqual('LookupCancel', Format(Result), 'RunModal reports Cancel, and the second action cannot change it');
        Assert.AreEqual('open,qcp:LookupCancel,close,', TPCLog.Text(), 'OnQueryClosePage sees the same value, and the triggers ran once each');
    end;

    // ---- a request page ----

    [RequestPageHandler]
    procedure RequestOkHandler(var R: TestRequestPage "TPC Report")
    var
        T: Text;
    begin
        R.OK().Invoke();
        asserterror T := R.QtyOpt.Value();
        HandlerReadError := GetLastErrorText();
        asserterror R.Cancel().Invoke();
        HandlerSecondCloseError := GetLastErrorText();
    end;

    [RequestPageHandler]
    procedure RequestCancelHandler(var R: TestRequestPage "TPC Report")
    var
        T: Text;
    begin
        R.Cancel().Invoke();
        asserterror T := R.QtyOpt.Value();
        HandlerReadError := GetLastErrorText();
        asserterror R.OK().Invoke();
        HandlerSecondCloseError := GetLastErrorText();
    end;

    [Test]
    [HandlerFunctions('RequestOkHandler')]
    procedure RequestPage_OK_ClosesThePage_AndASecondActionCannotChangeTheResult()
    var
        Params: Text;
    begin
        TPCLog.Reset();
        HandlerReadError := '';
        HandlerSecondCloseError := '';
        Params := Report.RunRequestPage(Report::"TPC Report");

        AssertContains(HandlerReadError, NotOpenTxt, 'a read after OK raises not open');
        AssertContains(HandlerSecondCloseError, NotOpenTxt, 'a Cancel after OK raises not open');
        Assert.IsTrue(StrLen(Params) > 0, 'the request page was confirmed, so the parameters come back');
        Assert.AreEqual('open,qcp:OK,close,', TPCLog.Text(), 'OnQueryClosePage sees OK, once');
    end;

    [Test]
    [HandlerFunctions('RequestCancelHandler')]
    procedure RequestPage_Cancel_ClosesThePage_AndASecondActionCannotChangeTheResult()
    var
        Params: Text;
    begin
        TPCLog.Reset();
        HandlerReadError := '';
        HandlerSecondCloseError := '';
        Params := Report.RunRequestPage(Report::"TPC Report");

        AssertContains(HandlerReadError, NotOpenTxt, 'a read after Cancel raises not open');
        AssertContains(HandlerSecondCloseError, NotOpenTxt, 'an OK after Cancel raises not open');
        Assert.AreEqual('', Params, 'the request page was cancelled, so no parameters come back');
        Assert.AreEqual('open,qcp:Cancel,close,', TPCLog.Text(), 'OnQueryClosePage sees Cancel, once');
    end;
}
