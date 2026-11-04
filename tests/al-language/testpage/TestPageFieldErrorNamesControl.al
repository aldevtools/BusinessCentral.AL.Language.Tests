// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-assertequals-method
// Scope: in-scope
// Fixtures used: Assert (60021), Base Application pages "Item Tracing" and "Allocation Account
// List" (table "Allocation Account"), and the table, page and codeunit declared below.
//
// CLAIM: the errors a TestPage field raises name the page CONTROL, the AL identifier in
// field(<Name>; ...), and not the control's Caption or the source field's name or caption.
//   1. A failed AssertEquals reads "AssertEquals for Field: <control> Expected = '<expected>',
//      Actual = '<actual>'".
//   2. A refused SetValue is wrapped in "Validation error for Field: <control>,".
//   3. The same holds for a control a pageextension adds (ExtNameCtl), and on a precompiled
//      page: for a control bound to a page variable
//      (Item Tracing's TraceMethod) and for one bound to a Rec field whose Caption differs
//      from its name (Allocation Account List's AccountType, Caption 'Account Type').
//
// The fixture gives every name a different spelling: the field is "Cust Name" with Caption
// 'Field Caption', and the control is CustNameCtl with Caption 'Control Caption'.
//
// Written by agent stma-auto2-13, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#3458.

table 67630 "FEN Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Cust Name"; Text[30]) { Caption = 'Field Caption'; }
        field(3; "Cust Count"; Integer) { Caption = 'Count Field Caption'; }
        field(4; "Ext Name"; Text[30]) { Caption = 'Ext Field Caption'; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 67630 "FEN Card"
{
    PageType = Card;
    SourceTable = "FEN Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(CustNameCtl; Rec."Cust Name")
            {
                ApplicationArea = All;
                Caption = 'Control Caption';
            }
            field(CustCountCtl; Rec."Cust Count")
            {
                ApplicationArea = All;
                Caption = 'Count Control Caption';
            }
        }
    }
}

pageextension 67630 "FEN Card Ext" extends "FEN Card"
{
    layout
    {
        addlast(Content)
        {
            field(ExtNameCtl; Rec."Ext Name")
            {
                ApplicationArea = All;
                Caption = 'Ext Control Caption';
            }
        }
    }
}

codeunit 67630 "FEN Field Error Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure OpenSeeded(var Card: TestPage "FEN Card")
    var
        Row: Record "FEN Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'FEN';
        Row."Cust Name" := 'Alpha';
        Row."Cust Count" := 7;
        Row."Ext Name" := 'Beta';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToRecord(Row);
    end;

    [Test]
    procedure AssertEquals_Mismatch_NamesTheControl()
    var
        Card: TestPage "FEN Card";
    begin
        OpenSeeded(Card);
        asserterror Card.CustNameCtl.AssertEquals('Wrong');
        Assert.ExpectedError('AssertEquals for Field: CustNameCtl Expected = ''Wrong'', Actual = ''Alpha''');
        Assert.IsFalse(StrPos(GetLastErrorText(), 'Caption') > 0,
            'the AssertEquals error must not name a caption; got: ' + GetLastErrorText());
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Match_RaisesNothing()
    var
        Card: TestPage "FEN Card";
    begin
        OpenSeeded(Card);
        Card.CustNameCtl.AssertEquals('Alpha');
        Card.CustCountCtl.AssertEquals(7);
        Card.Close();
    end;

    [Test]
    procedure SetValue_Refused_NamesTheControl()
    var
        Card: TestPage "FEN Card";
    begin
        OpenSeeded(Card);
        asserterror Card.CustCountCtl.SetValue('not a number');
        Assert.ExpectedError('Validation error for Field: CustCountCtl,');
        Card.Close();
    end;

    [Test]
    procedure PageExtensionControl_AssertEquals_Mismatch_NamesTheControl()
    var
        Card: TestPage "FEN Card";
    begin
        OpenSeeded(Card);
        asserterror Card.ExtNameCtl.AssertEquals('Wrong');
        Assert.ExpectedError('AssertEquals for Field: ExtNameCtl Expected = ''Wrong'', Actual = ''Beta''');
        Assert.IsFalse(StrPos(GetLastErrorText(), 'Caption') > 0,
            'the AssertEquals error must not name a caption; got: ' + GetLastErrorText());
        Card.Close();
    end;

    [Test]
    procedure PrecompiledPage_AssertEquals_Mismatch_NamesTheControl()
    var
        ItemTracing: TestPage "Item Tracing";
    begin
        ItemTracing.OpenEdit();
        asserterror ItemTracing.TraceMethod.AssertEquals('Wrong');
        Assert.ExpectedError('AssertEquals for Field: TraceMethod Expected = ''Wrong'', Actual = ''Usage -> Origin''');
        ItemTracing.Close();
    end;

    [Test]
    procedure PrecompiledPage_RecBoundControl_AssertEquals_Mismatch_NamesTheControl()
    var
        AllocationAccount: Record "Allocation Account";
        AccountList: TestPage "Allocation Account List";
    begin
        AllocationAccount.SetRange("No.", 'FEN');
        AllocationAccount.DeleteAll();
        AllocationAccount.Init();
        AllocationAccount."No." := 'FEN';
        AllocationAccount.Insert();

        AccountList.OpenView();
        AccountList.GoToRecord(AllocationAccount);
        asserterror AccountList.AccountType.AssertEquals('Wrong');
        Assert.ExpectedError('AssertEquals for Field: AccountType Expected = ''Wrong''');
        Assert.IsFalse(StrPos(GetLastErrorText(), 'Account Type') > 0,
            'the AssertEquals error must not name the control''s caption; got: ' + GetLastErrorText());
        AccountList.Close();
    end;
}
