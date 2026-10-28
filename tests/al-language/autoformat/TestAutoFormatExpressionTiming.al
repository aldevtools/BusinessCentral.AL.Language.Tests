// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoformatexpression-property
//                    https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: Assert (60021), and the table, pages and codeunit declared below.
//
// WHEN does an error raised by a control's AutoFormatExpression or CaptionClass expression reach the
// test? Codeunit 67644 (autoformat/TestAutoFormatExpressionError.al) opens the page and reads the control
// inside ONE asserterror, so it cannot say. Measured here, identical on every cloud leg (and the Windows
// nightly): the page FAILS TO OPEN. The expression is evaluated when a row is populated, after the page's
// OnOpenPage and before its OnAfterGetRecord, for every control whatever its Visible, and for an empty
// view and a new record as well. So no read of any other control is ever reached, and the TestPage the
// failed open leaves behind answers "The TestPage is not open." to every call.
//
// A row-dependent expression raises when the row it fails for is populated: at open when that is the
// first row, and when the cursor moves onto it otherwise, where the move reads as "The TestPage is not
// open." and not as the expression's own error. On a LIST the page populates a window of rows at open
// (a failing row 20 of 120 fails the open, row 25 does not), and a later move that populates a new window
// raises the expression's own error. The list-window arms are the ones the runner does not model yet.
//
// A control that declares an AutoFormatType and no expression has nothing to raise, and reads.
//
// What is NOT pinned: how a TryFunction reports these. A CaptionClass failure and a row-dependent one
// surface as a Microsoft.Dynamics.Framework.UI.FormAbortException that a TryFunction does not catch,
// while an always-failing AutoFormatExpression is an ordinary AL error that it does. Asserting the
// exception type is not this file's claim; every arm here goes through asserterror.
//
// Written by agent stma-auto-7, an automated implementation agent acting on the account holder's
// behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4920.

table 69600 "AFT Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Amount; Decimal) { }
        field(3; Boom; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 69600 "AFT Always Card"
{
    PageType = Card;
    SourceTable = "AFT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(OkCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
                AutoFormatExpression = OkFormat();
            }
            field(FailingCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
                AutoFormatExpression = FailingFormat();
            }
        }
    }

    local procedure OkFormat(): Text
    begin
        exit('<Precision,3:3><Standard Format,0>');
    end;

    local procedure FailingFormat(): Text
    begin
        Error('AFT format expression failed');
    end;
}

page 69601 "AFT TypeOnly Card"
{
    PageType = Card;
    SourceTable = "AFT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(TypeOnlyCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
            }
            field(OkCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
                AutoFormatExpression = OkFormat();
            }
        }
    }

    local procedure OkFormat(): Text
    begin
        exit('<Precision,3:3><Standard Format,0>');
    end;
}

page 69602 "AFT Hidden Card"
{
    PageType = Card;
    SourceTable = "AFT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(OkCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
                AutoFormatExpression = OkFormat();
            }
            field(HiddenFailingCtl; Rec.Amount)
            {
                ApplicationArea = All;
                Visible = false;
                AutoFormatType = 10;
                AutoFormatExpression = FailingFormat();
            }
        }
    }

    local procedure OkFormat(): Text
    begin
        exit('<Precision,3:3><Standard Format,0>');
    end;

    local procedure FailingFormat(): Text
    begin
        Error('AFT format expression failed');
    end;
}

page 69603 "AFT Row Card"
{
    PageType = Card;
    SourceTable = "AFT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(RowCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
                AutoFormatExpression = RowFormat();
            }
        }
    }

    local procedure RowFormat(): Text
    begin
        if Rec.Boom then
            Error('AFT row format failed for %1', Rec."No.");
        exit('<Precision,3:3><Standard Format,0>');
    end;
}

page 69604 "AFT Row List"
{
    PageType = List;
    SourceTable = "AFT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(RowCtl; Rec.Amount)
                {
                    ApplicationArea = All;
                    AutoFormatType = 10;
                    AutoFormatExpression = RowFormat();
                }
            }
        }
    }

    local procedure RowFormat(): Text
    begin
        if Rec.Boom then
            Error('AFT row format failed for %1', Rec."No.");
        exit('<Precision,3:3><Standard Format,0>');
    end;
}

page 69605 "AFT Always List"
{
    PageType = List;
    SourceTable = "AFT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(AlwaysCtl; Rec.Amount)
                {
                    ApplicationArea = All;
                    AutoFormatType = 10;
                    AutoFormatExpression = FailingFormat();
                }
            }
        }
    }

    local procedure FailingFormat(): Text
    begin
        Error('AFT format expression failed');
    end;
}

page 69606 "AFT Type1 Card"
{
    PageType = Card;
    SourceTable = "AFT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(Type1Ctl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 1;
                AutoFormatExpression = FailingFormat();
            }
        }
    }

    local procedure FailingFormat(): Text
    begin
        Error('AFT format expression failed');
    end;
}

page 69607 "AFT Caption Card"
{
    PageType = Card;
    SourceTable = "AFT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(OkCaptionCtl; Rec.Amount)
            {
                ApplicationArea = All;
                CaptionClass = OkCaption();
            }
            field(FailingCaptionCtl; Rec.Amount)
            {
                ApplicationArea = All;
                CaptionClass = FailingCaption();
            }
        }
    }

    local procedure OkCaption(): Text
    begin
        exit('3,Ok Caption');
    end;

    local procedure FailingCaption(): Text
    begin
        Error('AFT caption class expression failed');
    end;
}

page 69608 "AFT Ready Card"
{
    PageType = Card;
    SourceTable = "AFT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(ReadyCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
                AutoFormatExpression = ReadyFormat();
            }
        }
    }

    trigger OnOpenPage()
    begin
        Ready := true;
    end;

    local procedure ReadyFormat(): Text
    begin
        if not Ready then
            Error('AFT page not ready: OnOpenPage has not run');
        exit('<Precision,3:3><Standard Format,0>');
    end;

    var
        Ready: Boolean;
}

page 69609 "AFT Seen Card"
{
    PageType = Card;
    SourceTable = "AFT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(SeenCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
                AutoFormatExpression = SeenFormat();
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        RowSeen := true;
    end;

    local procedure SeenFormat(): Text
    begin
        if not RowSeen then
            Error('AFT row not seen: OnAfterGetRecord has not run');
        exit('<Precision,3:3><Standard Format,0>');
    end;

    var
        RowSeen: Boolean;
}

page 69611 "AFT Hidden Caption Card"
{
    PageType = Card;
    SourceTable = "AFT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(HiddenCaptionCtl; Rec.Amount)
            {
                ApplicationArea = All;
                Visible = false;
                CaptionClass = FailingCaption();
            }
        }
    }

    local procedure FailingCaption(): Text
    begin
        Error('AFT hidden caption class expression failed');
    end;
}

page 69612 "AFT Working Caption Card"
{
    PageType = Card;
    SourceTable = "AFT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(OkCaptionCtl; Rec.Amount)
            {
                ApplicationArea = All;
                CaptionClass = OkCaption();
            }
        }
    }

    local procedure OkCaption(): Text
    begin
        exit('3,Ok Caption');
    end;
}

codeunit 69600 "AFT Expression Timing Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        HandlerRan: Boolean;

    local procedure Seed()
    var
        Row: Record "AFT Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'A';
        Row.Amount := 7;
        Row.Insert();
        Row.Init();
        Row."No." := 'B';
        Row.Amount := 8;
        Row.Boom := true;
        Row.Insert();
        Row.Init();
        Row."No." := 'C';
        Row.Amount := 9;
        Row.Insert();
    end;

    local procedure SeedMany(Count: Integer; FailAt: Integer)
    var
        Row: Record "AFT Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to Count do begin
            Row.Init();
            Row."No." := 'R' + Format(1000 + i);
            Row.Amount := i;
            Row.Boom := i = FailAt;
            Row.Insert();
        end;
    end;

    local procedure ReadNo(var P: TestPage "AFT Always Card"): Text
    begin
        exit(P.NoCtl.Value());
    end;

    // ---- an always-failing AutoFormatExpression fails the open, whatever the page shows ----

    [Test]
    procedure FailingFormat_OpenViewRaisesTheExpressionError()
    var
        P: TestPage "AFT Always Card";
    begin
        Seed();
        asserterror P.OpenView();
        Assert.ExpectedError('AFT format expression failed');
    end;

    [Test]
    procedure FailingFormat_OpenEditRaisesTheExpressionError()
    var
        P: TestPage "AFT Always Card";
    begin
        Seed();
        asserterror P.OpenEdit();
        Assert.ExpectedError('AFT format expression failed');
    end;

    [Test]
    procedure FailingFormat_OpenNewRaisesTheExpressionError()
    var
        P: TestPage "AFT Always Card";
    begin
        Seed();
        asserterror P.OpenNew();
        Assert.ExpectedError('AFT format expression failed');
    end;

    [Test]
    procedure FailingFormat_EmptyTable_StillRaisesAtOpen()
    var
        P: TestPage "AFT Always Card";
        Row: Record "AFT Row";
    begin
        Row.DeleteAll();
        asserterror P.OpenView();
        Assert.ExpectedError('AFT format expression failed');
    end;

    [Test]
    procedure FailingFormat_HiddenControl_StillRaisesAtOpen()
    var
        P: TestPage "AFT Hidden Card";
    begin
        Seed();
        asserterror P.OpenView();
        Assert.ExpectedError('AFT format expression failed');
    end;

    [Test]
    procedure FailingFormat_AutoFormatType1_RaisesAtOpen()
    var
        P: TestPage "AFT Type1 Card";
    begin
        Seed();
        asserterror P.OpenView();
        Assert.ExpectedError('AFT format expression failed');
    end;

    [Test]
    procedure FailingFormat_ListWithRows_RaisesAtOpen()
    var
        P: TestPage "AFT Always List";
    begin
        Seed();
        asserterror P.OpenView();
        Assert.ExpectedError('AFT format expression failed');
    end;

    [Test]
    procedure FailingFormat_EmptyList_RaisesAtOpen()
    var
        P: TestPage "AFT Always List";
        Row: Record "AFT Row";
    begin
        Row.DeleteAll();
        asserterror P.OpenView();
        Assert.ExpectedError('AFT format expression failed');
    end;

    [Test]
    procedure FailingFormat_FailedOpen_LeavesThePageNotOpen()
    var
        P: TestPage "AFT Always Card";
        Shown: Text;
    begin
        Seed();
        asserterror P.OpenView();
        Assert.ExpectedError('AFT format expression failed');
        asserterror Shown := ReadNo(P);
        Assert.ExpectedError('The TestPage is not open.');
        asserterror P.Close();
        Assert.ExpectedError('The TestPage is not open.');
    end;

    [ModalPageHandler]
    procedure NeverRunHandler(var P: TestPage "AFT Always Card")
    begin
        HandlerRan := true;
    end;

    [Test]
    // No [HandlerFunctions]: the page never opens, so a bound handler is never consumed and
    // BC 28.5/29.0 then offers it to a later test's modal page (TargetException, DialogCreate_ModalHandler_*).
    procedure FailingFormat_RunModal_RaisesBeforeAnyHandler()
    var
        Row: Record "AFT Row";
    begin
        Seed();
        Row.Get('A');
        HandlerRan := false;
        asserterror Page.RunModal(Page::"AFT Always Card", Row);
        Assert.ExpectedError('AFT format expression failed');
        Assert.IsFalse(HandlerRan, 'the page failed to open, so the handler is never handed it');
    end;

    [Test]
    // No [HandlerFunctions]: the page never opens, so a bound handler is never consumed and
    // BC 28.5/29.0 then offers it to a later test's modal page (TargetException, DialogCreate_ModalHandler_*).
    procedure FailingFormat_RunModalOnAnEmptyTable_RaisesBeforeAnyHandler()
    var
        Row: Record "AFT Row";
    begin
        Row.DeleteAll();
        HandlerRan := false;
        asserterror Page.RunModal(Page::"AFT Always Card", Row);
        Assert.ExpectedError('AFT format expression failed');
        Assert.IsFalse(HandlerRan, 'the page failed to open, so the handler is never handed it');
    end;

    // ---- the controls that have nothing to raise ----

    [Test]
    procedure AutoFormatType_WithoutAnExpression_OpensAndReads()
    var
        P: TestPage "AFT TypeOnly Card";
        TypeOnlyShown: Text;
        WithExpressionShown: Text;
    begin
        Seed();
        P.OpenView();
        TypeOnlyShown := P.TypeOnlyCtl.Value();
        WithExpressionShown := P.OkCtl.Value();
        P.Close();
        Assert.AreEqual('7.00', TypeOnlyShown, 'a type with no expression reads the default two decimals');
        Assert.AreEqual('7.000', WithExpressionShown, 'a working expression is still honoured');
    end;

    // ---- when in the open the expression runs ----

    [Test]
    procedure FormatExpression_RunsAfterOnOpenPage()
    var
        P: TestPage "AFT Ready Card";
        Shown: Text;
    begin
        Seed();
        P.OpenView();
        Shown := P.ReadyCtl.Value();
        P.Close();
        Assert.AreEqual('7.000', Shown, 'a global OnOpenPage sets is already set when the expression runs');
    end;

    [Test]
    procedure FormatExpression_RunsBeforeOnAfterGetRecord()
    var
        P: TestPage "AFT Seen Card";
    begin
        Seed();
        asserterror P.OpenView();
        Assert.ExpectedError('AFT row not seen: OnAfterGetRecord has not run');
    end;

    // ---- a row-dependent expression raises when its row is populated ----

    [Test]
    procedure RowFormat_OpenAtTheFailingRow_RaisesAndLeavesThePageNotOpen()
    var
        P: TestPage "AFT Row Card";
        Row: Record "AFT Row";
        Shown: Text;
    begin
        Seed();
        Row.Get('A');
        Row.Delete();
        asserterror P.OpenView();
        Assert.ExpectedError('AFT row format failed for B');
        asserterror Shown := P.NoCtl.Value();
        Assert.ExpectedError('The TestPage is not open.');
    end;

    [Test]
    procedure RowFormat_MovingOntoTheFailingRow_ReadsAsTheTestPageNotOpen()
    var
        P: TestPage "AFT Row Card";
        Shown: Text;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError('The TestPage is not open.');
        asserterror Shown := P.NoCtl.Value();
        Assert.ExpectedError('The TestPage is not open.');
    end;

    [Test]
    procedure RowFormat_GoToKeyPastTheFailingRow_ReadsAsTheTestPageNotOpen()
    var
        P: TestPage "AFT Row Card";
        Shown: Text;
    begin
        // The search for C walks through B, and B's expression raises, so C is never reached.
        Seed();
        P.OpenView();
        asserterror P.GoToKey('C');
        Assert.ExpectedError('The TestPage is not open.');
        asserterror Shown := P.NoCtl.Value();
        Assert.ExpectedError('The TestPage is not open.');
    end;

    [Test]
    procedure RowFormat_MovingOntoARowThatDoesNotFail_Reads()
    var
        P: TestPage "AFT Row Card";
        Row: Record "AFT Row";
        Shown: Text;
    begin
        Seed();
        Row.Get('B');
        Row.Delete();
        P.OpenView();
        P.GoToKey('C');
        Shown := P.RowCtl.Value();
        P.Close();
        Assert.AreEqual('9.000', Shown, 'the row that does not fail reads in the format its expression answers');
    end;

    [Test]
    procedure RowFormat_AfterAFailedOpen_TheSamePageVariableOpensAgain()
    var
        P: TestPage "AFT Row Card";
        Row: Record "AFT Row";
        Shown: Text;
    begin
        Seed();
        Row.Get('A');
        Row.Delete();
        asserterror P.OpenView();
        Assert.ExpectedError('AFT row format failed for B');
        // Written again rather than edited: whether the failed open rolled the seed back is not
        // this test's claim.
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'C';
        Row.Amount := 9;
        Row.Insert();
        P.OpenView();
        Shown := P.RowCtl.Value();
        P.Close();
        Assert.AreEqual('9.000', Shown, 'a new open is a new page: the failed one does not carry over');
    end;

    [Test]
    procedure RowFormat_List_OnlyRowFails_RaisesAtOpen()
    var
        P: TestPage "AFT Row List";
        Row: Record "AFT Row";
    begin
        Seed();
        Row.Get('A');
        Row.Delete();
        Row.Get('C');
        Row.Delete();
        asserterror P.OpenView();
        Assert.ExpectedError('AFT row format failed for B');
    end;

    [Test]
    procedure RowFormat_List_NoFailingRow_OpensAndReads()
    var
        P: TestPage "AFT Row List";
        Row: Record "AFT Row";
        Shown: Text;
    begin
        Seed();
        Row.Get('B');
        Row.Delete();
        P.OpenView();
        Shown := P.RowCtl.Value();
        P.Close();
        Assert.AreEqual('7.000', Shown, 'a list whose rows do not fail opens and reads in the expression format');
    end;

    // ---- the list window: BC populates a window of rows at open, the runner only the current one ----

    [Test]
    procedure RowFormat_List_FailingSecondRow_RaisesAtOpen()
    var
        P: TestPage "AFT Row List";
    begin
        Seed();
        asserterror P.OpenView();
        Assert.ExpectedError('AFT row format failed for B');
    end;

    [Test]
    procedure RowFormat_List_FailingRow20Of120_RaisesAtOpen()
    var
        P: TestPage "AFT Row List";
    begin
        SeedMany(120, 20);
        asserterror P.OpenView();
        Assert.ExpectedError('AFT row format failed for R1020');
    end;

    [Test]
    procedure RowFormat_List_FailingRow30Of120_OpensAndReadsTheFirstRow()
    var
        P: TestPage "AFT Row List";
        Shown: Text;
    begin
        SeedMany(120, 30);
        P.OpenView();
        Shown := P.RowCtl.Value();
        P.Close();
        Assert.AreEqual('1.000', Shown, 'a failing row beyond the opening window does not fail the open');
    end;

    [Test]
    procedure RowFormat_List_LastOntoAFailingRowBeyondTheWindow_RaisesItsOwnError()
    var
        P: TestPage "AFT Row List";
        Shown: Text;
    begin
        SeedMany(120, 120);
        P.OpenView();
        asserterror P.Last();
        Assert.ExpectedError('AFT row format failed for R1120');
        asserterror Shown := P.NoCtl.Value();
        Assert.ExpectedError('The TestPage is not open.');
    end;

    // ---- CaptionClass ----

    [Test]
    procedure FailingCaptionClass_OpenRaisesTheExpressionError()
    var
        P: TestPage "AFT Caption Card";
    begin
        Seed();
        asserterror P.OpenView();
        Assert.ExpectedError('AFT caption class expression failed');
    end;

    [Test]
    procedure FailingCaptionClass_EmptyTable_StillRaisesAtOpen()
    var
        P: TestPage "AFT Caption Card";
        Row: Record "AFT Row";
    begin
        Row.DeleteAll();
        asserterror P.OpenView();
        Assert.ExpectedError('AFT caption class expression failed');
    end;

    [Test]
    procedure FailingCaptionClass_HiddenControl_StillRaisesAtOpen()
    var
        P: TestPage "AFT Hidden Caption Card";
    begin
        Seed();
        asserterror P.OpenView();
        Assert.ExpectedError('AFT hidden caption class expression failed');
    end;

    [Test]
    procedure WorkingCaptionClass_OpensAndReadsItsCaption()
    var
        P: TestPage "AFT Working Caption Card";
        Shown: Text;
    begin
        Seed();
        P.OpenView();
        Shown := P.OkCaptionCtl.Caption();
        P.Close();
        Assert.AreEqual('Ok Caption', Shown, 'a CaptionClass expression that answers reads its resolved caption');
    end;
}
