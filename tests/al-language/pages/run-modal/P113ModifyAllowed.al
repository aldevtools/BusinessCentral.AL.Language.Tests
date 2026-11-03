// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-modifyallowed-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (P113 MA)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: page ModifyAllowed = false (Editable, SetValue, insert still allowed), action Scope = Repeater / Page / unset: which actions a TestPage sees, their Visible/Enabled and that Invoke runs the OnAction
// BC versions: 29 (27 and 28 by CI)

table 73097 "LT P113 Mod"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 73098 "LT P113 Mod Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Entry; Text[100]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

page 73099 "LT P113 NoMod Card"
{
    PageType = Card;
    SourceTable = "LT P113 Mod";
    ApplicationArea = All;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }
}

page 73100 "LT P113 NoMod List"
{
    PageType = List;
    SourceTable = "LT P113 Mod";
    ApplicationArea = All;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }
}

page 73101 "LT P113 Mod List"
{
    PageType = List;
    SourceTable = "LT P113 Mod";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActRepeater)
            {
                ApplicationArea = All;
                Caption = 'Repeater action';
                Scope = Repeater;

                trigger OnAction()
                begin
                    LogIt('repeater:' + Rec."Code");
                end;
            }
            action(ActPage)
            {
                ApplicationArea = All;
                Caption = 'Page action';
                Scope = Page;

                trigger OnAction()
                begin
                    LogIt('page:' + Rec."Code");
                end;
            }
            action(ActDefault)
            {
                ApplicationArea = All;
                Caption = 'Default action';

                trigger OnAction()
                begin
                    LogIt('default:' + Rec."Code");
                end;
            }
        }
    }

    local procedure LogIt(Txt: Text)
    var
        Log: Record "LT P113 Mod Log";
        NextNo: Integer;
    begin
        if Log.FindLast() then
            NextNo := Log."Entry No.";
        Log.Init();
        Log."Entry No." := NextNo + 1;
        Log.Entry := CopyStr(Txt, 1, 100);
        Log.Insert();
    end;
}

codeunit 73102 "LT P113 ModifyAllowed"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Rec1: Record "LT P113 Mod";
        Log: Record "LT P113 Mod Log";
    begin
        Rec1.DeleteAll();
        Log.DeleteAll();
        Rec1.Code := 'M1';
        Rec1.Name := 'One';
        Rec1.Qty := 1;
        Rec1.Insert();
        Rec1.Code := 'M2';
        Rec1.Name := 'Two';
        Rec1.Qty := 2;
        Rec1.Insert();
    end;

    [Test]
    procedure P113_MA_CardEditable()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 NoMod Card";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('page-editable', Format(Card.Editable()));
        Observer.Observe('code-editable', Format(Card.CodeCtl.Editable()));
        Observer.Observe('name-editable', Format(Card.NameCtl.Editable()));
        Observer.Observe('qty-editable', Format(Card.QtyCtl.Editable()));
        Card.Close();
        Observer.Expect('page-editable', 'Yes');
        Observer.Expect('code-editable', 'No');
        Observer.Expect('name-editable', 'No');
        Observer.Expect('qty-editable', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P113_MA_CardViewMode()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 NoMod Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('page-editable', Format(Card.Editable()));
        Observer.Observe('name-editable', Format(Card.NameCtl.Editable()));
        Observer.Observe('name', Card.NameCtl.Value());
        Card.Close();
        Observer.Expect('page-editable', 'No');
        Observer.Expect('name-editable', 'No');
        Observer.Expect('name', 'One');
        Observer.Verify();
    end;

    [Test]
    procedure P113_MA_ListNavigationStillWorks()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P113 NoMod List";
    begin
        Seed();
        List.OpenEdit();
        Observer.Observe('first', Format(List.First()));
        Observer.Observe('code1', List.CodeCtl.Value());
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('code2', List.CodeCtl.Value());
        Observer.Observe('next-end', Format(List.Next()));
        Observer.Observe('goto', Format(List.GoToKey('M1')));
        Observer.Observe('qty', List.QtyCtl.Value());
        List.Close();
        Observer.Expect('first', 'Yes');
        Observer.Expect('code1', 'M1');
        Observer.Expect('next', 'Yes');
        Observer.Expect('code2', 'M2');
        Observer.Expect('next-end', 'Yes');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('qty', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P113_MA_DefaultListEditable()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P113 Mod List";
        Rec1: Record "LT P113 Mod";
    begin
        Seed();
        List.OpenEdit();
        List.First();
        Observer.Observe('page-editable', Format(List.Editable()));
        Observer.Observe('name-editable', Format(List.NameCtl.Editable()));
        List.NameCtl.SetValue('Changed');
        List.Close();
        Rec1.Get('M1');
        Observer.Observe('name', Rec1.Name);
        Observer.Expect('page-editable', 'Yes');
        Observer.Expect('name-editable', 'Yes');
        Observer.Expect('name', 'Changed');
        Observer.Verify();
    end;

    [Test]
    procedure P113_MA_ActionsAreVisible()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P113 Mod List";
    begin
        Seed();
        List.OpenView();
        List.First();
        Observer.Observe('rep-visible', Format(List.ActRepeater.Visible()));
        Observer.Observe('rep-enabled', Format(List.ActRepeater.Enabled()));
        Observer.Observe('page-visible', Format(List.ActPage.Visible()));
        Observer.Observe('page-enabled', Format(List.ActPage.Enabled()));
        Observer.Observe('def-visible', Format(List.ActDefault.Visible()));
        Observer.Observe('def-enabled', Format(List.ActDefault.Enabled()));
        List.Close();
        Observer.Expect('rep-visible', 'Yes');
        Observer.Expect('rep-enabled', 'Yes');
        Observer.Expect('page-visible', 'Yes');
        Observer.Expect('page-enabled', 'Yes');
        Observer.Expect('def-visible', 'Yes');
        Observer.Expect('def-enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P113_MA_ActionsInvoke()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P113 Mod List";
        Log: Record "LT P113 Mod Log";
    begin
        Seed();
        List.OpenView();
        List.GoToKey('M2');
        List.ActRepeater.Invoke();
        List.ActPage.Invoke();
        List.ActDefault.Invoke();
        List.Close();
        Observer.Observe('log-count', Format(Log.Count()));
        if Log.FindSet() then
            repeat
                Observer.Observe('log-' + Format(Log."Entry No."), Log.Entry);
            until Log.Next() = 0;
        Observer.Expect('log-count', '3');
        Observer.Expect('log-1', 'repeater:M2');
        Observer.Expect('log-2', 'page:M2');
        Observer.Expect('log-3', 'default:M2');
        Observer.Verify();
    end;

    [Test]
    procedure P113_MA_ActionsWithoutSelectedRow()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P113 Mod List";
        Rec1: Record "LT P113 Mod";
        Log: Record "LT P113 Mod Log";
    begin
        Seed();
        Rec1.DeleteAll();
        List.OpenView();
        Observer.Observe('rep-enabled', Format(List.ActRepeater.Enabled()));
        Observer.Observe('page-enabled', Format(List.ActPage.Enabled()));
        List.ActPage.Invoke();
        List.ActRepeater.Invoke();
        Observer.Observe('rep-no-row', 'no error');
        List.Close();
        Observer.Observe('log-count', Format(Log.Count()));
        if Log.FindFirst() then
            Observer.Observe('log-1', Log.Entry);
        Observer.Expect('rep-enabled', 'Yes');
        Observer.Expect('page-enabled', 'Yes');
        Observer.Expect('rep-no-row', 'no error');
        Observer.Expect('log-count', '2');
        Observer.Expect('log-1', 'page:');
        Observer.Verify();
    end;
}
