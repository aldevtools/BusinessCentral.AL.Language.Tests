// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
// Scope: in-scope
// local object: the Visible expressions a page extension sets with modify() on the controls and actions of pages 61821 and 61822 are what is under test
// Fixtures used: Probe Observer (codeunit 69160); own table 61820, pages 61821 and 61822, page extensions 61823 and 61824, test codeunit 61825
// Probe (al-runner issue 5195): TestPage.<control>.Visible() and <action>.Visible() when a page extension's modify() sets Visible to a variable
//   of the extension. Area: where the variable gets its value (the extension's OnOpenPage, its OnAfterGetCurrRecord, its OnAfterGetRecord,
//   an action of the extension with and without CurrPage.Update, never), the form (the variable, not the variable), what the base page
//   declares for the control (nothing, Visible = false, a base variable that is false, a base variable that is true), the element (a field
//   on a card, a group, an action, a repeater column) and how the page opens (OpenEdit, OpenView, OpenNew, moving to another row).
//   A snapshot lists every control as '<name>=<Yes or No>' or '<name>=error <error code>' when reading Visible() raises.
// Next to: pages/extensions/W2ExtModify.al (literal Visible = false and true of two extensions on one field: line 316 pins that the field
//   is then not found on the TestPage), pages/properties/P119PageExt.al:232 (literal Visible = false on an action: Visible() is false),
//   pages/extensions/TestPageExtensionModifyEditable_Tests.al (Editable and Enabled set to an expression). No test sets Visible to a
//   variable in modify().
// Observation form: every test ends in Finish(), so the run fails on purpose and the failure message carries what BC produced.
// BC versions: 27, 28, 29

table 61820 "PAG ExtVis Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; Flag; Boolean) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

page 61821 "PAG ExtVis Card"
{
    PageType = Card;
    SourceTable = "PAG ExtVis Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(CtlPlain; Rec.Name) { ApplicationArea = All; }
                field(CtlOpen; Rec.Name) { ApplicationArea = All; }
                field(CtlNever; Rec.Name) { ApplicationArea = All; }
                field(CtlNot; Rec.Name) { ApplicationArea = All; }
                field(CtlCurr; Rec.Name) { ApplicationArea = All; }
                field(CtlRow; Rec.Name) { ApplicationArea = All; }
                field(CtlToggled; Rec.Name) { ApplicationArea = All; }
                field(CtlBaseFalse; Rec.Name) { ApplicationArea = All; Visible = false; }
                field(CtlBaseVarFalse; Rec.Name) { ApplicationArea = All; Visible = BaseHidden; }
                field(CtlBaseVarTrue; Rec.Name) { ApplicationArea = All; Visible = BaseShown; }
            }
            group(GrpNever)
            {
                field(CtlInGroup; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActPlain) { ApplicationArea = All; trigger OnAction() begin end; }
            action(ActOpen) { ApplicationArea = All; trigger OnAction() begin end; }
            action(ActNever) { ApplicationArea = All; trigger OnAction() begin end; }
            action(ActCurr) { ApplicationArea = All; trigger OnAction() begin end; }
            action(ActToggled) { ApplicationArea = All; trigger OnAction() begin end; }
        }
    }

    var
        BaseHidden: Boolean;
        BaseShown: Boolean;

    trigger OnOpenPage()
    begin
        BaseShown := true;
    end;
}

page 61822 "PAG ExtVis List"
{
    PageType = List;
    SourceTable = "PAG ExtVis Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(ColPlain; Rec.Name) { ApplicationArea = All; }
                field(ColOpen; Rec.Name) { ApplicationArea = All; }
                field(ColNever; Rec.Name) { ApplicationArea = All; }
                field(ColCurr; Rec.Name) { ApplicationArea = All; }
                field(ColRec; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 61823 "PAG ExtVis Card Ext" extends "PAG ExtVis Card"
{
    layout
    {
        modify(CtlOpen) { Visible = SetInOpen; }
        modify(CtlNever) { Visible = NeverSet; }
        modify(CtlNot) { Visible = not NeverSet; }
        modify(CtlCurr) { Visible = SetInCurr; }
        modify(CtlRow) { Visible = FromRow; }
        modify(CtlToggled) { Visible = Toggled; }
        modify(CtlBaseFalse) { Visible = SetInOpen; }
        modify(CtlBaseVarFalse) { Visible = SetInOpen; }
        modify(CtlBaseVarTrue) { Visible = NeverSet; }
        modify(GrpNever) { Visible = NeverSet; }
    }

    actions
    {
        modify(ActOpen) { Visible = SetInOpen; }
        modify(ActNever) { Visible = NeverSet; }
        modify(ActCurr) { Visible = SetInCurr; }
        modify(ActToggled) { Visible = Toggled; }
        addlast(Processing)
        {
            action(ExtToggle)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Toggled := not Toggled;
                end;
            }
            action(ExtToggleAndUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Toggled := not Toggled;
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        SetInOpen: Boolean;
        NeverSet: Boolean;
        SetInCurr: Boolean;
        FromRow: Boolean;
        Toggled: Boolean;

    trigger OnOpenPage()
    begin
        SetInOpen := true;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetInCurr := true;
        FromRow := Rec.Flag;
    end;
}

pageextension 61824 "PAG ExtVis List Ext" extends "PAG ExtVis List"
{
    layout
    {
        modify(ColOpen) { Visible = SetInOpen; }
        modify(ColNever) { Visible = NeverSet; }
        modify(ColCurr) { Visible = SetInCurr; }
        modify(ColRec) { Visible = SetInRec; }
    }

    var
        SetInOpen: Boolean;
        NeverSet: Boolean;
        SetInCurr: Boolean;
        SetInRec: Boolean;

    trigger OnOpenPage()
    begin
        SetInOpen := true;
    end;

    trigger OnAfterGetRecord()
    begin
        SetInRec := true;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetInCurr := true;
    end;
}

codeunit 61825 "PAG ExtVis Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // R1 has Flag = true, R2 has Flag = false.
    local procedure Seed()
    var
        Row: Record "PAG ExtVis Row";
    begin
        Row.DeleteAll();
        Row."No." := 'R1';
        Row.Name := 'one';
        Row.Flag := true;
        Row.Insert();
        Row."No." := 'R2';
        Row.Name := 'two';
        Row.Flag := false;
        Row.Insert();
    end;

    local procedure Shown(Ok: Boolean; Result: Boolean): Text
    var
        Code: Text;
    begin
        if Ok then
            exit(Format(Result));
        Code := GetLastErrorCode();
        ClearLastError();
        exit('error ' + Code);
    end;

    [TryFunction]
    local procedure Card_CtlPlain(var P: TestPage "PAG ExtVis Card"; var Result: Boolean)
    begin
        Result := P.CtlPlain.Visible();
    end;

    [TryFunction]
    local procedure Card_CtlOpen(var P: TestPage "PAG ExtVis Card"; var Result: Boolean)
    begin
        Result := P.CtlOpen.Visible();
    end;

    [TryFunction]
    local procedure Card_CtlNever(var P: TestPage "PAG ExtVis Card"; var Result: Boolean)
    begin
        Result := P.CtlNever.Visible();
    end;

    [TryFunction]
    local procedure Card_CtlNot(var P: TestPage "PAG ExtVis Card"; var Result: Boolean)
    begin
        Result := P.CtlNot.Visible();
    end;

    [TryFunction]
    local procedure Card_CtlCurr(var P: TestPage "PAG ExtVis Card"; var Result: Boolean)
    begin
        Result := P.CtlCurr.Visible();
    end;

    [TryFunction]
    local procedure Card_CtlRow(var P: TestPage "PAG ExtVis Card"; var Result: Boolean)
    begin
        Result := P.CtlRow.Visible();
    end;

    [TryFunction]
    local procedure Card_CtlToggled(var P: TestPage "PAG ExtVis Card"; var Result: Boolean)
    begin
        Result := P.CtlToggled.Visible();
    end;

    [TryFunction]
    local procedure Card_CtlBaseFalse(var P: TestPage "PAG ExtVis Card"; var Result: Boolean)
    begin
        Result := P.CtlBaseFalse.Visible();
    end;

    [TryFunction]
    local procedure Card_CtlBaseVarFalse(var P: TestPage "PAG ExtVis Card"; var Result: Boolean)
    begin
        Result := P.CtlBaseVarFalse.Visible();
    end;

    [TryFunction]
    local procedure Card_CtlBaseVarTrue(var P: TestPage "PAG ExtVis Card"; var Result: Boolean)
    begin
        Result := P.CtlBaseVarTrue.Visible();
    end;

    [TryFunction]
    local procedure Card_CtlInGroup(var P: TestPage "PAG ExtVis Card"; var Result: Boolean)
    begin
        Result := P.CtlInGroup.Visible();
    end;

    [TryFunction]
    local procedure Card_ActPlain(var P: TestPage "PAG ExtVis Card"; var Result: Boolean)
    begin
        Result := P.ActPlain.Visible();
    end;

    [TryFunction]
    local procedure Card_ActOpen(var P: TestPage "PAG ExtVis Card"; var Result: Boolean)
    begin
        Result := P.ActOpen.Visible();
    end;

    [TryFunction]
    local procedure Card_ActNever(var P: TestPage "PAG ExtVis Card"; var Result: Boolean)
    begin
        Result := P.ActNever.Visible();
    end;

    [TryFunction]
    local procedure Card_ActCurr(var P: TestPage "PAG ExtVis Card"; var Result: Boolean)
    begin
        Result := P.ActCurr.Visible();
    end;

    [TryFunction]
    local procedure Card_ActToggled(var P: TestPage "PAG ExtVis Card"; var Result: Boolean)
    begin
        Result := P.ActToggled.Visible();
    end;

    [TryFunction]
    local procedure List_ColPlain(var P: TestPage "PAG ExtVis List"; var Result: Boolean)
    begin
        Result := P.ColPlain.Visible();
    end;

    [TryFunction]
    local procedure List_ColOpen(var P: TestPage "PAG ExtVis List"; var Result: Boolean)
    begin
        Result := P.ColOpen.Visible();
    end;

    [TryFunction]
    local procedure List_ColNever(var P: TestPage "PAG ExtVis List"; var Result: Boolean)
    begin
        Result := P.ColNever.Visible();
    end;

    [TryFunction]
    local procedure List_ColCurr(var P: TestPage "PAG ExtVis List"; var Result: Boolean)
    begin
        Result := P.ColCurr.Visible();
    end;

    [TryFunction]
    local procedure List_ColRec(var P: TestPage "PAG ExtVis List"; var Result: Boolean)
    begin
        Result := P.ColRec.Visible();
    end;

    local procedure CardFields(var P: TestPage "PAG ExtVis Card"): Text
    var
        R: Boolean;
        Result: Text;
    begin
        Result += 'CtlPlain=' + Shown(Card_CtlPlain(P, R), R) + ' ';
        Result += 'CtlOpen=' + Shown(Card_CtlOpen(P, R), R) + ' ';
        Result += 'CtlNever=' + Shown(Card_CtlNever(P, R), R) + ' ';
        Result += 'CtlNot=' + Shown(Card_CtlNot(P, R), R) + ' ';
        Result += 'CtlCurr=' + Shown(Card_CtlCurr(P, R), R) + ' ';
        Result += 'CtlRow=' + Shown(Card_CtlRow(P, R), R) + ' ';
        Result += 'CtlToggled=' + Shown(Card_CtlToggled(P, R), R) + ' ';
        Result += 'CtlBaseFalse=' + Shown(Card_CtlBaseFalse(P, R), R) + ' ';
        Result += 'CtlBaseVarFalse=' + Shown(Card_CtlBaseVarFalse(P, R), R) + ' ';
        Result += 'CtlBaseVarTrue=' + Shown(Card_CtlBaseVarTrue(P, R), R) + ' ';
        Result += 'CtlInGroup=' + Shown(Card_CtlInGroup(P, R), R) + ' ';
        exit(Result);
    end;

    local procedure CardActions(var P: TestPage "PAG ExtVis Card"): Text
    var
        R: Boolean;
        Result: Text;
    begin
        Result += 'ActPlain=' + Shown(Card_ActPlain(P, R), R) + ' ';
        Result += 'ActOpen=' + Shown(Card_ActOpen(P, R), R) + ' ';
        Result += 'ActNever=' + Shown(Card_ActNever(P, R), R) + ' ';
        Result += 'ActCurr=' + Shown(Card_ActCurr(P, R), R) + ' ';
        Result += 'ActToggled=' + Shown(Card_ActToggled(P, R), R) + ' ';
        exit(Result);
    end;

    local procedure ListColumns(var P: TestPage "PAG ExtVis List"): Text
    var
        R: Boolean;
        Result: Text;
    begin
        Result += 'ColPlain=' + Shown(List_ColPlain(P, R), R) + ' ';
        Result += 'ColOpen=' + Shown(List_ColOpen(P, R), R) + ' ';
        Result += 'ColNever=' + Shown(List_ColNever(P, R), R) + ' ';
        Result += 'ColCurr=' + Shown(List_ColCurr(P, R), R) + ' ';
        Result += 'ColRec=' + Shown(List_ColRec(P, R), R) + ' ';
        exit(Result);
    end;

    [Test]
    procedure Card_OpenEdit_FieldsAndActions()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "PAG ExtVis Card";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        Observer.Observe('fields on R1 (Flag true)', CardFields(P));
        Observer.Observe('actions on R1', CardActions(P));
        P.GoToKey('R2');
        Observer.Observe('fields on R2 (Flag false)', CardFields(P));
        P.GoToKey('R1');
        Observer.Observe('fields back on R1', CardFields(P));
        Observer.Finish();
    end;

    [Test]
    procedure Card_OpenView_FieldsAndActions()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "PAG ExtVis Card";
    begin
        Seed();
        P.OpenView();
        P.GoToKey('R1');
        Observer.Observe('fields on R1 (Flag true)', CardFields(P));
        Observer.Observe('actions on R1', CardActions(P));
        Observer.Finish();
    end;

    [Test]
    procedure Card_OpenEdit_NoMove_FirstRow()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "PAG ExtVis Card";
    begin
        Seed();
        P.OpenEdit();
        Observer.Observe('fields right after OpenEdit', CardFields(P));
        Observer.Observe('actions right after OpenEdit', CardActions(P));
        Observer.Finish();
    end;

    [Test]
    procedure Card_OpenNew_FieldsAndActions()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "PAG ExtVis Card";
    begin
        Seed();
        P.OpenNew();
        Observer.Observe('fields on the new record', CardFields(P));
        Observer.Observe('actions on the new record', CardActions(P));
        Observer.Finish();
    end;

    [Test]
    procedure Card_ExtensionActionChangesTheVariable()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "PAG ExtVis Card";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        P.ExtToggle.Invoke();
        Observer.Observe('fields after the action set the variable to true', CardFields(P));
        Observer.Observe('actions after the action set the variable to true', CardActions(P));
        P.ExtToggle.Invoke();
        Observer.Observe('fields after the action set it back to false', CardFields(P));
        Observer.Finish();
    end;

    [Test]
    procedure Card_ExtensionActionChangesTheVariable_WithUpdate()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "PAG ExtVis Card";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        P.ExtToggleAndUpdate.Invoke();
        Observer.Observe('fields after the action set the variable to true and ran CurrPage.Update(false)', CardFields(P));
        Observer.Observe('actions after the action', CardActions(P));
        P.ExtToggleAndUpdate.Invoke();
        Observer.Observe('fields after the action set it back to false', CardFields(P));
        Observer.Finish();
    end;

    [Test]
    procedure List_OpenEdit_Columns()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "PAG ExtVis List";
    begin
        Seed();
        P.OpenEdit();
        Observer.Observe('columns right after OpenEdit', ListColumns(P));
        P.GoToKey('R2');
        Observer.Observe('columns on R2', ListColumns(P));
        Observer.Finish();
    end;

    [Test]
    procedure List_OpenView_Columns()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "PAG ExtVis List";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('columns right after OpenView', ListColumns(P));
        P.Last();
        Observer.Observe('columns on the last row', ListColumns(P));
        Observer.Finish();
    end;
}
