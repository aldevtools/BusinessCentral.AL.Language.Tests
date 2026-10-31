// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe (writer Y20, al-runner issue 6483): measured on a BC 29 SaaS sandbox; 27 and 28 by the corpus CI matrix.
// Facts: a page extension that moves actions (moveafter, movebefore, movefirst, movelast of one action, of several actions,
//   of actionrefs into another promoted category, and of a promoted category group) and several controls in one move
//   (movefirst/moveafter with a list of controls): the page opens, every moved action runs its own trigger when a test page
//   invokes it by name, moved controls read and write their fields, and the Sequence that "Page Control Field" reports for
//   each control. One control move is in record/QzPageExtMoves.al.
// BC versions: 27, 28, 29

table 92105 "LT Y20 Move Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; K; Code[10]) { }
        field(2; A; Text[20]) { }
        field(3; B; Text[20]) { }
        field(4; C; Text[20]) { }
        field(5; D; Text[20]) { }
        field(6; E; Text[20]) { }
    }
    keys { key(PK; K) { Clustered = true; } }
}

page 92106 "LT Y20 Move Card"
{
    PageType = Card;
    SourceTable = "LT Y20 Move Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(KCtl; Rec.K) { ApplicationArea = All; }
                field(ACtl; Rec.A) { ApplicationArea = All; }
                field(BCtl; Rec.B) { ApplicationArea = All; }
            }
            group(Details)
            {
                field(CCtl; Rec.C) { ApplicationArea = All; }
                field(DCtl; Rec.D) { ApplicationArea = All; }
                field(ECtl; Rec.E) { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(First) { ApplicationArea = All; trigger OnAction() begin Error('First ran'); end; }
            action(Second) { ApplicationArea = All; trigger OnAction() begin Error('Second ran'); end; }
            action(Third) { ApplicationArea = All; trigger OnAction() begin Error('Third ran'); end; }
            group(More)
            {
                action(Fourth) { ApplicationArea = All; trigger OnAction() begin Error('Fourth ran'); end; }
                action(Fifth) { ApplicationArea = All; trigger OnAction() begin Error('Fifth ran'); end; }
            }
        }
        area(Navigation)
        {
            action(Sixth) { ApplicationArea = All; trigger OnAction() begin Error('Sixth ran'); end; }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(First_Promoted; First) { }
                actionref(Second_Promoted; Second) { }
                actionref(Third_Promoted; Third) { }
            }
            group(Category_Category4) { }
        }
    }
}

pageextension 92107 "LT Y20 Move Card Ext" extends "LT Y20 Move Card"
{
    layout
    {
        movefirst(Details; ACtl, BCtl)
        moveafter(KCtl; ECtl, DCtl)
    }
    actions
    {
        moveafter(Third; First)
        movebefore(Second; Fifth)
        movefirst(More; Third, Second)
        movelast(Processing; Fourth)
        movefirst(Category_Category4; Second_Promoted, Third_Promoted)
        moveafter(Category_Process; Category_Category4)
    }
}

codeunit 92108 "LT Y20 PageExt Moves"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Setup()
    var
        Row: Record "LT Y20 Move Row";
    begin
        Row.DeleteAll();
        Row.K := 'R1';
        Row.A := 'a';
        Row.B := 'b';
        Row.C := 'c';
        Row.D := 'd';
        Row.E := 'e';
        Row.Insert();
    end;

    [Test]
    procedure Y20_MovedActions_EachRunsItsTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y20 Move Card";
    begin
        Setup();
        Card.OpenEdit();
        asserterror Card.First.Invoke();
        Observer.Observe('first', GetLastErrorText());
        asserterror Card.Second.Invoke();
        Observer.Observe('second', GetLastErrorText());
        asserterror Card.Third.Invoke();
        Observer.Observe('third', GetLastErrorText());
        asserterror Card.Fourth.Invoke();
        Observer.Observe('fourth', GetLastErrorText());
        asserterror Card.Fifth.Invoke();
        Observer.Observe('fifth', GetLastErrorText());
        asserterror Card.Sixth.Invoke();
        Observer.Observe('sixth', GetLastErrorText());
        Observer.Observe('visible', Format(Card.First.Visible()) + Format(Card.Second.Visible()) + Format(Card.Third.Visible()) +
            Format(Card.Fourth.Visible()) + Format(Card.Fifth.Visible()));
        Observer.Observe('enabled', Format(Card.First.Enabled()) + Format(Card.Second.Enabled()) + Format(Card.Fifth.Enabled()));
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y20_SeveralControlsMoved_ReadAndWrite()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y20 Move Row";
        Card: TestPage "LT Y20 Move Card";
    begin
        Setup();
        Card.OpenEdit();
        Observer.Observe('values', Card.KCtl.Value() + '|' + Card.ACtl.Value() + '|' + Card.BCtl.Value() + '|' + Card.CCtl.Value() + '|' +
            Card.DCtl.Value() + '|' + Card.ECtl.Value());
        Card.ACtl.SetValue('a2');
        Card.BCtl.SetValue('b2');
        Card.DCtl.SetValue('d2');
        Card.ECtl.SetValue('e2');
        Card.Close();
        Row.Get('R1');
        Observer.Observe('stored', Row.A + '|' + Row.B + '|' + Row.C + '|' + Row.D + '|' + Row.E);
        Observer.Finish();
    end;

    [Test]
    procedure Y20_SeveralControlsMoved_PageControlFieldSequence()
    var
        Observer: Codeunit "Probe Observer";
        PageControlField: Record "Page Control Field";
        Rows: Text;
        Name: Text;
    begin
        // Sequence of each control (read by name: the rows come in ControlId order).
        PageControlField.SetRange(PageNo, Page::"LT Y20 Move Card");
        foreach Name in 'KCtl,ACtl,BCtl,CCtl,DCtl,ECtl'.Split(',') do begin
            PageControlField.SetRange(ControlName, Name);
            if PageControlField.FindFirst() then
                Rows += Name + '=' + Format(PageControlField.Sequence) + ';'
            else
                Rows += Name + '=no row;';
        end;
        Observer.Observe('rows', Rows);
        Observer.Finish();
    end;
}
