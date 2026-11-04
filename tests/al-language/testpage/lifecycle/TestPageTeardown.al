// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-overview
// Scope: in-scope
// Fixtures used: Assert (60021), and the table, pages and codeunit declared below.
//
// WHAT A TESTPAGE DOES AFTER BC HAS TORN IT DOWN, AND WHAT A REOPEN IS. Measured as record-only probes
// (corpus PR 553), identical on every cloud leg, and agreeing with the Windows nightly.
//
// A page is torn down when an error escapes a row load: an OnAfterGetRecord error or a control
// expression error on a MOVE (the move reads as "The TestPage is not open."), or either at the OPEN
// (the open raises the error itself). From then on EVERY call on that variable raises "The TestPage
// is not open.": a control read for the first time, and a control that was read BEFORE the teardown
// alike (Value, AsInteger, Caption, Editable, Visible, Enabled, AssertEquals, SetValue, an action's
// Invoke and Enabled), and the page-level calls (Close, First, Next, GoToKey, Caption, Editable).
// A page handed to a [ModalPageHandler] answers the same after a teardown inside the handler, OK()
// included.
//
// OpenView, OpenEdit and OpenNew on that variable are NOT refused: the variable opens again. A page
// that is closed and opened again is a fresh page, which BC opens on the FIRST row of the view, not
// where the closed one stood. After a refused Close() the variable opens again as well.
//
// A repeater page populates a window of rows at open, so only a failing row beyond the window tears
// it down on a move; the open-time arms of the list are the runner's list-window gap and are not here.
//
// What is NOT pinned: a second OpenView over data that still fails raises a Microsoft.Dynamics.Framework.UI
// .FormAbortException that no AL error handling catches (the test dies as "Unexpected CLR exception"), so
// there is nothing to assert on it.
//
// Written by agent stma-auto-7, an automated implementation agent acting on the account holder's
// behalf, for AL Runner issues StefanMaron/BusinessCentral.AL.Runner#5388, #5390 and #5393.

table 69640 "TPT Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Qty; Integer) { }
        field(3; Amount; Decimal) { }
        field(4; Boom; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 69640 "TPT Expression Card"
{
    PageType = Card;
    SourceTable = "TPT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            field(AmtCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
                AutoFormatExpression = RowFormat();
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
                    Error('TPT action ran');
                end;
            }
        }
    }

    local procedure RowFormat(): Text
    begin
        if Rec.Boom then
            Error('TPT row format failed for %1', Rec."No.");
        exit('<Precision,3:3><Standard Format,0>');
    end;
}

page 69641 "TPT Expression List"
{
    PageType = List;
    SourceTable = "TPT Row";
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
                field(AmtCtl; Rec.Amount)
                {
                    ApplicationArea = All;
                    AutoFormatType = 10;
                    AutoFormatExpression = RowFormat();
                }
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
                    Error('TPT action ran');
                end;
            }
        }
    }

    local procedure RowFormat(): Text
    begin
        if Rec.Boom then
            Error('TPT row format failed for %1', Rec."No.");
        exit('<Precision,3:3><Standard Format,0>');
    end;
}

page 69642 "TPT Trigger Card"
{
    PageType = Card;
    SourceTable = "TPT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
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
                    Error('TPT action ran');
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec.Boom then
            Error('TPT AGR failed for %1', Rec."No.");
    end;
}

page 69643 "TPT Host Card"
{
    PageType = Card;
    SourceTable = "TPT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenFailing)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Row: Record "TPT Row";
                begin
                    Row.Get('B');
                    Page.RunModal(Page::"TPT Expression Card", Row);
                end;
            }
        }
    }
}

codeunit 69640 "TPT Teardown Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Mode: Text;
        ReadBefore: Boolean;
        NotOpenTxt: Label 'The TestPage is not open.', Locked = true;

    // A, B (fails), C. Committed, so that what a reopen shows does not depend on what an
    // asserterror rolls back.
    local procedure Seed()
    var
        Row: Record "TPT Row";
    begin
        Row.DeleteAll();
        Row.Init(); Row."No." := 'A'; Row.Qty := 1; Row.Insert();
        Row.Init(); Row."No." := 'B'; Row.Qty := 2; Row.Boom := true; Row.Insert();
        Row.Init(); Row."No." := 'C'; Row.Qty := 3; Row.Insert();
        Commit();
    end;

    // A, B, C (fails): the failing row is the last one.
    local procedure SeedBoomLast()
    var
        Row: Record "TPT Row";
    begin
        Seed();
        Row.Get('B');
        Row.Boom := false;
        Row.Modify();
        Row.Get('C');
        Row.Boom := true;
        Row.Modify();
        Commit();
    end;

    // A, B, C, none failing.
    local procedure SeedPlain()
    var
        Row: Record "TPT Row";
    begin
        Seed();
        Row.Get('B');
        Row.Boom := false;
        Row.Modify();
        Commit();
    end;

    // B (fails) first, then C.
    local procedure SeedBoomFirst()
    var
        Row: Record "TPT Row";
    begin
        Seed();
        Row.Get('A');
        Row.Delete();
        Commit();
    end;

    // The failing row beyond the first window of a list: 120 rows, row 120 fails.
    local procedure SeedLongList()
    var
        Row: Record "TPT Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 120 do begin
            Row.Init();
            Row."No." := 'R' + Format(1000 + i);
            Row.Qty := i;
            Row.Boom := i = 120;
            Row.Insert();
        end;
        Commit();
    end;

    // Only C is left, so the failing row is gone.
    local procedure FixData()
    var
        Row: Record "TPT Row";
    begin
        Row.DeleteAll();
        Row.Init(); Row."No." := 'C'; Row.Qty := 3; Row.Insert();
        Commit();
    end;

    // ---- 1. after a teardown no control answers, whether it was read before the teardown or not (#5390) ----

    [Test]
    procedure CardExpression_Value_ReadBeforeTheTeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror T := P.QtyCtl.Value();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_Value_NeverRead_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror T := P.QtyCtl.Value();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_AsInteger_ReadBeforeTheTeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        I := P.QtyCtl.AsInteger();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror I := P.QtyCtl.AsInteger();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_AsInteger_NeverRead_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror I := P.QtyCtl.AsInteger();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_Caption_ReadBeforeTheTeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Caption();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror T := P.QtyCtl.Caption();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_Caption_NeverRead_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror T := P.QtyCtl.Caption();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_Editable_ReadBeforeTheTeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        B := P.QtyCtl.Editable();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.QtyCtl.Editable();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_Editable_NeverRead_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.QtyCtl.Editable();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_Visible_ReadBeforeTheTeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        B := P.QtyCtl.Visible();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.QtyCtl.Visible();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_Visible_NeverRead_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.QtyCtl.Visible();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_Enabled_ReadBeforeTheTeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        B := P.QtyCtl.Enabled();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.QtyCtl.Enabled();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_Enabled_NeverRead_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.QtyCtl.Enabled();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_AssertEquals_ReadBeforeTheTeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.QtyCtl.AssertEquals(2);
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_AssertEquals_NeverRead_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.QtyCtl.AssertEquals(2);
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_SetValue_ReadBeforeTheTeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.QtyCtl.SetValue(9);
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_SetValue_NeverRead_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.QtyCtl.SetValue(9);
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_Invoke_ReadBeforeTheTeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        B := P.Act.Visible();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.Act.Invoke();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_Invoke_NeverRead_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.Act.Invoke();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_ActionEnabled_ReadBeforeTheTeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        B := P.Act.Enabled();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.Act.Enabled();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_ActionEnabled_NeverRead_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.Act.Enabled();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardTrigger_Value_ReadBeforeTheTeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror T := P.QtyCtl.Value();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardTrigger_Value_NeverRead_RaisesNotOpen()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror T := P.QtyCtl.Value();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardTrigger_AssertEquals_ReadBeforeTheTeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.QtyCtl.AssertEquals(2);
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardTrigger_SetValue_ReadBeforeTheTeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.QtyCtl.SetValue(9);
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardTrigger_Invoke_ReadBeforeTheTeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        B := P.Act.Visible();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.Act.Invoke();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure ListExpression_Value_ReadBeforeTheTeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedLongList();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.Last();
        
        asserterror T := P.QtyCtl.Value();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure ListExpression_Value_NeverRead_RaisesNotOpen()
    var
        P: TestPage "TPT Expression List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedLongList();
        P.OpenView();
        
        asserterror P.Last();
        
        asserterror T := P.QtyCtl.Value();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure ListExpression_AssertEquals_ReadBeforeTheTeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedLongList();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.Last();
        
        asserterror P.QtyCtl.AssertEquals(2);
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure ListExpression_SetValue_ReadBeforeTheTeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedLongList();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.Last();
        
        asserterror P.QtyCtl.SetValue(9);
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure ListExpression_Invoke_ReadBeforeTheTeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedLongList();
        P.OpenView();
        B := P.Act.Visible();
        asserterror P.Last();
        
        asserterror P.Act.Invoke();
        Assert.ExpectedError(NotOpenTxt);
    end;

    // ---- 2. the page-level calls on a torn-down page ----

    [Test]
    procedure CardExpression_PageClose_AfterATeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.Close();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_PageFirst_AfterATeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.First();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_PageNext_AfterATeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.Next();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_PageGoToKey_AfterATeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.GoToKey('A');
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_PagePageCaption_AfterATeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror T := P.Caption();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_PagePageEditable_AfterATeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror B := P.Editable();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardTrigger_PageClose_AfterATeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.Close();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardTrigger_PageFirst_AfterATeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.First();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure ListExpression_PageClose_AfterATeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedLongList();
        P.OpenView();
        asserterror P.Last();
        
        asserterror P.Close();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure ListExpression_PageFirst_AfterATeardown_RaisesNotOpen()
    var
        P: TestPage "TPT Expression List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedLongList();
        P.OpenView();
        asserterror P.Last();
        
        asserterror P.First();
        Assert.ExpectedError(NotOpenTxt);
    end;

    // ---- 3. a failed open leaves the page torn down too (#5388) ----

    [Test]
    procedure CardExpression_FailedOpen_Act_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT row format failed for B');
        asserterror P.Act.Invoke();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_FailedOpen_SetValue_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT row format failed for B');
        asserterror P.QtyCtl.SetValue(9);
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_FailedOpen_First_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT row format failed for B');
        asserterror P.First();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_FailedOpen_Next_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT row format failed for B');
        asserterror B := P.Next();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_FailedOpen_GoToKey_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT row format failed for B');
        asserterror P.GoToKey('A');
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_FailedOpen_PageCaption_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT row format failed for B');
        asserterror T := P.Caption();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardExpression_FailedOpen_PageEditable_RaisesNotOpen()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT row format failed for B');
        asserterror B := P.Editable();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardTrigger_FailedOpen_Value_RaisesNotOpen()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT AGR failed for B');
        asserterror T := P.QtyCtl.Value();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardTrigger_FailedOpen_Close_RaisesNotOpen()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT AGR failed for B');
        asserterror P.Close();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardTrigger_FailedOpen_Act_RaisesNotOpen()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT AGR failed for B');
        asserterror P.Act.Invoke();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardTrigger_FailedOpen_SetValue_RaisesNotOpen()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT AGR failed for B');
        asserterror P.QtyCtl.SetValue(9);
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardTrigger_FailedOpen_First_RaisesNotOpen()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT AGR failed for B');
        asserterror P.First();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardTrigger_FailedOpen_Next_RaisesNotOpen()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT AGR failed for B');
        asserterror B := P.Next();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardTrigger_FailedOpen_GoToKey_RaisesNotOpen()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT AGR failed for B');
        asserterror P.GoToKey('A');
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardTrigger_FailedOpen_PageCaption_RaisesNotOpen()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT AGR failed for B');
        asserterror T := P.Caption();
        Assert.ExpectedError(NotOpenTxt);
    end;

    [Test]
    procedure CardTrigger_FailedOpen_PageEditable_RaisesNotOpen()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT AGR failed for B');
        asserterror B := P.Editable();
        Assert.ExpectedError(NotOpenTxt);
    end;

    // ---- 4. the variable opens again after a teardown or a failed open, on the first row (#5388) ----

    [Test]
    procedure CardExpression_AfterATeardown_TheSameVariableOpensAgainOnTheFirstRow()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('A', T, 'a reopened page is a fresh page: it opens on the first row, not on the row that tore the old one down');
    end;

    [Test]
    procedure CardExpression_AfterATeardown_AControlReadBeforeItReadsTheNewPage()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        P.OpenView();
        T := P.QtyCtl.Value();
        P.Close();
        Assert.AreEqual('1', T, 'the control answers from the new page, not from the one that was torn down');
    end;

    [Test]
    procedure CardExpression_AfterATeardown_ARefusedCloseDoesNotKeepTheVariableFromOpeningAgain()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.Close();
        Assert.ExpectedError(NotOpenTxt);
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('A', T, 'the variable opens on the first row after the refused close');
    end;

    [Test]
    procedure CardExpression_AfterATeardown_AReopenedPageClosesAndOpensAgain()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        P.OpenView();
        P.Close();
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('A', T, 'the third open is a fresh page again');
    end;

    [Test]
    procedure CardExpression_AfterATeardown_AReopenedPageNavigates()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        P.OpenView();
        P.First();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('A', T, 'First() on the reopened page stands on the first row');
    end;

    [Test]
    procedure CardTrigger_AfterATeardown_TheSameVariableOpensAgainOnTheFirstRow()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('A', T, 'a reopened page is a fresh page: it opens on the first row, not on the row that tore the old one down');
    end;

    [Test]
    procedure CardTrigger_AfterATeardown_AControlReadBeforeItReadsTheNewPage()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        P.OpenView();
        T := P.QtyCtl.Value();
        P.Close();
        Assert.AreEqual('1', T, 'the control answers from the new page, not from the one that was torn down');
    end;

    [Test]
    procedure CardTrigger_AfterATeardown_ARefusedCloseDoesNotKeepTheVariableFromOpeningAgain()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.Close();
        Assert.ExpectedError(NotOpenTxt);
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('A', T, 'the variable opens on the first row after the refused close');
    end;

    [Test]
    procedure CardTrigger_AfterATeardown_AReopenedPageClosesAndOpensAgain()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        P.OpenView();
        P.Close();
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('A', T, 'the third open is a fresh page again');
    end;

    [Test]
    procedure CardTrigger_AfterATeardown_AReopenedPageNavigates()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        P.OpenView();
        P.First();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('A', T, 'First() on the reopened page stands on the first row');
    end;

    [Test]
    procedure ListExpression_AfterATeardown_TheSameVariableOpensAgainOnTheFirstRow()
    var
        P: TestPage "TPT Expression List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedLongList();
        P.OpenView();
        asserterror P.Last();
        
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('R1001', T, 'a reopened page is a fresh page: it opens on the first row, not on the row that tore the old one down');
    end;

    [Test]
    procedure ListExpression_AfterATeardown_AControlReadBeforeItReadsTheNewPage()
    var
        P: TestPage "TPT Expression List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedLongList();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.Last();
        
        P.OpenView();
        T := P.QtyCtl.Value();
        P.Close();
        Assert.AreEqual('1', T, 'the control answers from the new page, not from the one that was torn down');
    end;

    [Test]
    procedure ListExpression_AfterATeardown_ARefusedCloseDoesNotKeepTheVariableFromOpeningAgain()
    var
        P: TestPage "TPT Expression List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedLongList();
        P.OpenView();
        asserterror P.Last();
        
        asserterror P.Close();
        Assert.ExpectedError(NotOpenTxt);
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('R1001', T, 'the variable opens on the first row after the refused close');
    end;

    [Test]
    procedure ListExpression_AfterATeardown_AReopenedPageClosesAndOpensAgain()
    var
        P: TestPage "TPT Expression List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedLongList();
        P.OpenView();
        asserterror P.Last();
        
        P.OpenView();
        P.Close();
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('R1001', T, 'the third open is a fresh page again');
    end;

    [Test]
    procedure ListExpression_AfterATeardown_AReopenedPageNavigates()
    var
        P: TestPage "TPT Expression List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedLongList();
        P.OpenView();
        asserterror P.Last();
        
        P.OpenView();
        P.First();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('R1001', T, 'First() on the reopened page stands on the first row');
    end;

    [Test]
    procedure CardExpression_AfterATeardown_AnotherVariableOpensOnTheFirstRow()
    var
        P: TestPage "TPT Expression Card";
        Other: TestPage "TPT Expression Card";
        T: Text;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        Other.OpenView();
        T := Other.NoCtl.Value();
        Other.Close();
        Assert.AreEqual('A', T, 'a teardown does not touch what another TestPage variable opens');
    end;

    [Test]
    procedure CardExpression_AfterATeardown_TheDataGone_TheVariableOpensOnABlankRow()
    var
        P: TestPage "TPT Expression Card";
        Row: Record "TPT Row";
        T: Text;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        Row.DeleteAll();
        Commit();
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('', T, 'over a table with no rows the reopened page shows a blank row, not the row that tore the old page down');
    end;

    [Test]
    procedure CardExpression_FailingRowIsTheLastOne_AfterATeardown_TheVariableOpensOnTheFirstRow()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
    begin
        SeedBoomLast();
        P.OpenView();
        asserterror P.GoToKey('C');
        Assert.ExpectedError(NotOpenTxt);
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('A', T, 'the reopen stands on the first row, and the failing last row is not reached');
    end;

    [Test]
    procedure CardTrigger_FailingRowIsTheLastOne_AfterATeardown_TheVariableOpensOnTheFirstRow()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
    begin
        SeedBoomLast();
        P.OpenView();
        asserterror P.GoToKey('C');
        Assert.ExpectedError(NotOpenTxt);
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('A', T, 'the reopen stands on the first row, and the failing last row is not reached');
    end;

    [Test]
    procedure CardExpression_AfterAFailedOpen_TheDataFixed_TheSameVariableOpensAgain()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT row format failed for B');
        FixData();
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('C', T, 'a failed open does not keep the variable from opening again');
    end;

    [Test]
    procedure CardTrigger_AfterAFailedOpen_TheDataFixed_TheSameVariableOpensAgain()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT AGR failed for B');
        FixData();
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('C', T, 'a failed open does not keep the variable from opening again');
    end;

    [Test]
    procedure CardTrigger_AfterAFailedOpen_OpenEditOpensTheVariableAgainToo()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        Assert.ExpectedError('TPT AGR failed for B');
        FixData();
        P.OpenEdit();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('C', T, 'OpenEdit opens the variable again');
    end;

    // ---- 5. closed and opened again: a fresh page on the first row (#5393) ----

    [Test]
    procedure CardExpression_MovedClosedAndOpenedAgain_StandsOnTheFirstRow()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
    begin
        SeedPlain();
        P.OpenView();
        P.GoToKey('C');
        P.Close();
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('A', T, 'the reopened card stands on the first row');
    end;

    [Test]
    procedure CardExpression_MovedClosedAndOpenedAgainForEdit_StandsOnTheFirstRow()
    var
        P: TestPage "TPT Expression Card";
        T: Text;
    begin
        SeedPlain();
        P.OpenEdit();
        P.GoToKey('C');
        P.Close();
        P.OpenEdit();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('A', T, 'the reopened card stands on the first row');
    end;

    [Test]
    procedure CardTrigger_MovedClosedAndOpenedAgain_StandsOnTheFirstRow()
    var
        P: TestPage "TPT Trigger Card";
        T: Text;
    begin
        SeedPlain();
        P.OpenView();
        P.GoToKey('C');
        P.Close();
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('A', T, 'the reopened card stands on the first row');
    end;

    [Test]
    procedure List_MovedToTheLastRowClosedAndOpenedAgain_StandsOnTheFirstRow()
    var
        P: TestPage "TPT Expression List";
        T: Text;
    begin
        SeedPlain();
        P.OpenView();
        P.Last();
        P.Close();
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('A', T, 'the reopened list stands on the first row');
    end;

    [Test]
    procedure List_MovedToTheLastRowClosedAndOpenedAgainForEdit_StandsOnTheFirstRow()
    var
        P: TestPage "TPT Expression List";
        T: Text;
    begin
        SeedPlain();
        P.OpenEdit();
        P.Last();
        P.Close();
        P.OpenEdit();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('A', T, 'the reopened list stands on the first row');
    end;

    [Test]
    procedure CardExpression_ClosedAndOpenedAgainAfterTheFirstRowWasDeleted_StandsOnTheNewFirstRow()
    var
        P: TestPage "TPT Expression Card";
        Row: Record "TPT Row";
        T: Text;
    begin
        SeedPlain();
        P.OpenView();
        P.GoToKey('C');
        P.Close();
        Row.Get('A');
        Row.Delete();
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('B', T, 'the first row of the view, whichever it is now');
    end;

    // ---- 6. a page handed to a handler, torn down inside the handler ----
    //
    // Held (publisher, bump 32): all 20 tests of this codeunit that have [HandlerFunctions] (sections 6 and 7). They leave
    // session state that breaks later codeunits: after this codeunit ran, later tests that open a modal page fail with
    // 'Unexpected CLR exception thrown.: System.Reflection.TargetException: Object type ...Codeunit69640 does not match
    // target type ...'. The exception names this codeunit as the target of a handler call, and these are the only tests
    // here that bind a handler (section 6 tears the page down inside the ModalPageHandler; section 7 binds one that never
    // runs and leaves the host page open). Seen on Linux BC 27.5, 28.5 and 29.0 and on Windows BC 29.0 in a full
    // TestRunnerHub run (bc-linux #162). Which of the 20 leaves the state behind is not measured, so all are held under
    // LT_HELD_BCLINUX_162 on every version. The assertions do not change.

    [ModalPageHandler]
    procedure ExpressionHandler(var P: TestPage "TPT Expression Card")
    var
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        if ReadBefore then T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        HandlerAccess(P);
    end;

    local procedure HandlerAccess(var P: TestPage "TPT Expression Card")
    var
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        case Mode of
            'Value': asserterror T := P.QtyCtl.Value();
            'AsInteger': asserterror I := P.QtyCtl.AsInteger();
            'Editable': asserterror B := P.QtyCtl.Editable();
            'AssertEquals': asserterror P.QtyCtl.AssertEquals(2);
            'Close': asserterror P.Close();
            'OK': asserterror P.OK().Invoke();
            'PageCaption': asserterror T := P.Caption();
            'Next': asserterror B := P.Next();
            'Act': asserterror P.Act.Invoke();
        end;
        Assert.ExpectedError(NotOpenTxt);
    end;

    [ModalPageHandler]
    procedure TriggerHandler(var P: TestPage "TPT Trigger Card")
    var
        T: Text;
    begin
        if ReadBefore then T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        Assert.ExpectedError(NotOpenTxt);
        case Mode of
            'Value': asserterror T := P.QtyCtl.Value();
            'Close': asserterror P.Close();
            'Act': asserterror P.Act.Invoke();
        end;
        Assert.ExpectedError(NotOpenTxt);
    end;

    local procedure RunExpressionPage(WhatToCall: Text; WasRead: Boolean)
    var
        Row: Record "TPT Row";
    begin
        Seed();
        Row.Get('A');
        Mode := WhatToCall;
        ReadBefore := WasRead;
        Page.RunModal(Page::"TPT Expression Card", Row);
    end;

    local procedure RunTriggerPage(WhatToCall: Text; WasRead: Boolean)
    var
        Row: Record "TPT Row";
    begin
        Seed();
        Row.Get('A');
        Mode := WhatToCall;
        ReadBefore := WasRead;
        Page.RunModal(Page::"TPT Trigger Card", Row);
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('ExpressionHandler')]
#endif
    procedure Handler_CardExpression_Value_ReadBeforeTheTeardown_RaisesNotOpen()
    begin
        RunExpressionPage('Value', true);
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('ExpressionHandler')]
#endif
    procedure Handler_CardExpression_Value_NeverRead_RaisesNotOpen()
    begin
        RunExpressionPage('Value', false);
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('ExpressionHandler')]
#endif
    procedure Handler_CardExpression_AsInteger_ReadBeforeTheTeardown_RaisesNotOpen()
    begin
        RunExpressionPage('AsInteger', true);
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('ExpressionHandler')]
#endif
    procedure Handler_CardExpression_AsInteger_NeverRead_RaisesNotOpen()
    begin
        RunExpressionPage('AsInteger', false);
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('ExpressionHandler')]
#endif
    procedure Handler_CardExpression_Editable_ReadBeforeTheTeardown_RaisesNotOpen()
    begin
        RunExpressionPage('Editable', true);
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('ExpressionHandler')]
#endif
    procedure Handler_CardExpression_AssertEquals_ReadBeforeTheTeardown_RaisesNotOpen()
    begin
        RunExpressionPage('AssertEquals', true);
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('ExpressionHandler')]
#endif
    procedure Handler_CardExpression_AssertEquals_NeverRead_RaisesNotOpen()
    begin
        RunExpressionPage('AssertEquals', false);
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('ExpressionHandler')]
#endif
    procedure Handler_CardExpression_Close_NeverRead_RaisesNotOpen()
    begin
        RunExpressionPage('Close', false);
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('ExpressionHandler')]
#endif
    procedure Handler_CardExpression_OK_NeverRead_RaisesNotOpen()
    begin
        RunExpressionPage('OK', false);
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('ExpressionHandler')]
#endif
    procedure Handler_CardExpression_PageCaption_NeverRead_RaisesNotOpen()
    begin
        RunExpressionPage('PageCaption', false);
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('ExpressionHandler')]
#endif
    procedure Handler_CardExpression_Next_NeverRead_RaisesNotOpen()
    begin
        RunExpressionPage('Next', false);
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('ExpressionHandler')]
#endif
    procedure Handler_CardExpression_Act_ReadBeforeTheTeardown_RaisesNotOpen()
    begin
        RunExpressionPage('Act', true);
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('ExpressionHandler')]
#endif
    procedure Handler_CardExpression_Act_NeverRead_RaisesNotOpen()
    begin
        RunExpressionPage('Act', false);
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('TriggerHandler')]
#endif
    procedure Handler_CardTrigger_Value_ReadBeforeTheTeardown_RaisesNotOpen()
    begin
        RunTriggerPage('Value', true);
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('TriggerHandler')]
#endif
    procedure Handler_CardTrigger_Value_NeverRead_RaisesNotOpen()
    begin
        RunTriggerPage('Value', false);
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('TriggerHandler')]
#endif
    procedure Handler_CardTrigger_Close_NeverRead_RaisesNotOpen()
    begin
        RunTriggerPage('Close', false);
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('TriggerHandler')]
#endif
    procedure Handler_CardTrigger_Act_ReadBeforeTheTeardown_RaisesNotOpen()
    begin
        RunTriggerPage('Act', true);
    end;

    [ModalPageHandler]
    procedure SwallowingHandler(var P: TestPage "TPT Expression Card")
    begin
        asserterror P.GoToKey('B');
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('SwallowingHandler')]
#endif
    procedure Handler_ATeardownInsideTheHandler_RunModalReturnsLookupCancel()
    var
        Row: Record "TPT Row";
        Result: Action;
    begin
        Seed();
        Row.Get('A');
        Result := Page.RunModal(Page::"TPT Expression Card", Row);
        Assert.AreEqual(Action::LookupCancel, Result, 'a handler that leaves its page torn down closes it without OK');
    end;

    // ---- 7. a page that fails to open somewhere else leaves a TestPage that is open open ----
    // Held with section 6: see the note there.

    [ModalPageHandler]
    procedure NeverRunHandler(var P: TestPage "TPT Expression Card")
    begin
        Error('TPT handler ran');
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('NeverRunHandler')]
#endif
    procedure Host_ActionWhoseModalFailsToOpen_RaisesTheExpressionsError_AndTheHostStaysOpen()
    var
        P: TestPage "TPT Host Card";
        T: Text;
    begin
        Seed();
        P.OpenView();
        asserterror P.OpenFailing.Invoke();
        Assert.ExpectedError('TPT row format failed for B');
        T := P.NoCtl.Value();
        P.Close();
        Assert.AreEqual('A', T, 'an error raised by the modal page the action opens does not tear the host down');
    end;

#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('NeverRunHandler')]
#endif
    procedure Host_ActionWhoseModalFailsToOpen_TheHostIsStillOpen_SoOpeningItAgainIsRefused()
    var
        P: TestPage "TPT Host Card";
    begin
        Seed();
        P.OpenView();
        asserterror P.OpenFailing.Invoke();
        Assert.ExpectedError('TPT row format failed for B');
        asserterror P.OpenView();
        Assert.ExpectedError('The TestPage is already open.');
    end;

    // ---- 8. Trap and Page.Run of a page that fails to open ----

    [Test]
    procedure Trap_PageRunOfAFailingPage_TheTrappedPageIsNotOpen()
    var
        P: TestPage "TPT Expression Card";
        Row: Record "TPT Row";
        T: Text;
    begin
        Seed();
        Row.Get('B');
        P.Trap();
        asserterror Page.Run(Page::"TPT Expression Card", Row);
        Assert.ExpectedError('TPT row format failed for B');
        asserterror T := P.NoCtl.Value();
        Assert.ExpectedError(NotOpenTxt);
        asserterror P.Close();
        Assert.ExpectedError(NotOpenTxt);
    end;
}
