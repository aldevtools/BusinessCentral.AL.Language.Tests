// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-assertequals-method
// Scope: in-scope
// Fixtures used: Assert (60021), and the table, page and codeunit declared below.
//
// CLAIM: a failed AssertEquals on a TestPage control bound to a PAGE VARIABLE names the
// control -- the AL identifier in field(<Name>; ...) -- and not the variable it shows or the
// control's Caption: "AssertEquals for Field: <control> Expected = '<expected>', Actual =
// '<actual>'". A matching value raises nothing.
//
// The control, the variable and the caption are spelled differently (VarCtl, MyVar,
// 'Var Caption'), so the message can only match one of them. TestPageFieldErrorNamesControl.al
// covers Rec-bound controls; its page-variable case (Item Tracing's TraceMethod) has a control
// and a variable of the same name, so it cannot tell the two apart.
//
// Written by agent stma-auto2-12, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4911.

table 67650 "PVN Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 67650 "PVN Card"
{
    PageType = Card;
    SourceTable = "PVN Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(VarCtl; MyVar)
            {
                ApplicationArea = All;
                Caption = 'Var Caption';
            }
        }
    }

    trigger OnOpenPage()
    begin
        MyVar := 'Gamma';
    end;

    var
        MyVar: Text[30];
}

codeunit 67650 "PVN Variable Control Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure OpenSeeded(var Card: TestPage "PVN Card")
    var
        Row: Record "PVN Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'PVN';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToRecord(Row);
    end;

    [Test]
    procedure PageVariableControl_AssertEquals_Mismatch_NamesTheControl()
    var
        Card: TestPage "PVN Card";
    begin
        OpenSeeded(Card);
        asserterror Card.VarCtl.AssertEquals('Wrong');
        Assert.ExpectedError('AssertEquals for Field: VarCtl Expected = ''Wrong'', Actual = ''Gamma''');
        Assert.IsFalse(StrPos(GetLastErrorText(), 'MyVar') > 0,
            'the AssertEquals error must not name the page variable; got: ' + GetLastErrorText());
        Assert.IsFalse(StrPos(GetLastErrorText(), 'Caption') > 0,
            'the AssertEquals error must not name the caption; got: ' + GetLastErrorText());
        Card.Close();
    end;

    [Test]
    procedure PageVariableControl_AssertEquals_Match_RaisesNothing()
    var
        Card: TestPage "PVN Card";
    begin
        OpenSeeded(Card);
        Card.VarCtl.AssertEquals('Gamma');
        Card.Close();
    end;
}
