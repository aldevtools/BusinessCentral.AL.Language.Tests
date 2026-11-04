// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-editable-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 88283 - 88286 (writer RM)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: TestPage Editable() of the page and of its controls on a page whose property Editable = false: a control over a table field, a
//   control over a global variable without an Editable property, a control over a global variable with Editable = true, and a control over a
//   global variable in a group outside the repeater. A List (repeater) and a Card; opened with OpenEdit, OpenView, Page.Run and
//   Page.RunModal. Compare handlers/TestPageReadOnlySetValue.al:365 (an editable Card opened with OpenView: its variable control stays editable).
// Result (BC 27.5, 28.5, 29.0 alike): on a page with Editable = false every control answers Editable() = No: the table field, the global
//   variable without Editable, the global variable with Editable = true, and the variable in a group outside the repeater; on a List and a
//   Card, with OpenEdit, OpenView, Page.Run and Page.RunModal, and on an empty List.
// Source: al-runner issue 5755.
// BC versions: 27, 28, 29

table 88283 "LT RM Ro Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 88284 "LT RM Ro List"
{
    PageType = List;
    SourceTable = "LT RM Ro Row";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(HeaderText; HeaderText) { Caption = 'Header Text'; }
            }
            repeater(Rows)
            {
                field(Name; Rec.Name) { }
                field(NameText; NameText) { Caption = 'Name Text'; }
                field(NameTextEditable; NameText2)
                {
                    Caption = 'Name Text Editable';
                    Editable = true;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameText := Rec.Name;
        NameText2 := Rec.Name;
    end;

    var
        HeaderText: Text;
        NameText: Text;
        NameText2: Text;
}

page 88285 "LT RM Ro Card"
{
    PageType = Card;
    SourceTable = "LT RM Ro Row";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Name; Rec.Name) { }
                field(NameText; NameText) { Caption = 'Name Text'; }
                field(NameTextEditable; NameText2)
                {
                    Caption = 'Name Text Editable';
                    Editable = true;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameText := Rec.Name;
        NameText2 := Rec.Name;
    end;

    var
        NameText: Text;
        NameText2: Text;
}

codeunit 88286 "LT RM Ro Var Control Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure InsertRow()
    var
        Row: Record "LT RM Ro Row";
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row.Name := 'Row A';
        Row.Insert();
    end;

    local procedure ObserveList(var List: TestPage "LT RM Ro List")
    begin
        Observer.Observe('page', Format(List.Editable()));
        Observer.Observe('field', Format(List.Name.Editable()));
        Observer.Observe('var', Format(List.NameText.Editable()));
        Observer.Observe('var editable true', Format(List.NameTextEditable.Editable()));
        Observer.Observe('header var', Format(List.HeaderText.Editable()));
        Observer.Observe('var value', List.NameText.Value());
    end;

    local procedure ObserveCard(var Card: TestPage "LT RM Ro Card")
    begin
        Observer.Observe('page', Format(Card.Editable()));
        Observer.Observe('field', Format(Card.Name.Editable()));
        Observer.Observe('var', Format(Card.NameText.Editable()));
        Observer.Observe('var editable true', Format(Card.NameTextEditable.Editable()));
        Observer.Observe('var value', Card.NameText.Value());
    end;

    [Test]
    procedure RM_List_OpenEdit()
    var
        List: TestPage "LT RM Ro List";
    begin
        InsertRow();
        List.OpenEdit();
        List.First();
        ObserveList(List);
        List.Close();
        Observer.Expect('page', 'No');
        Observer.Expect('field', 'No');
        Observer.Expect('var', 'No');
        Observer.Expect('var editable true', 'No');
        Observer.Expect('header var', 'No');
        Observer.Expect('var value', 'Row A');
        Observer.Verify();
    end;

    [Test]
    procedure RM_List_OpenView()
    var
        List: TestPage "LT RM Ro List";
    begin
        InsertRow();
        List.OpenView();
        List.First();
        ObserveList(List);
        List.Close();
        Observer.Expect('page', 'No');
        Observer.Expect('field', 'No');
        Observer.Expect('var', 'No');
        Observer.Expect('var editable true', 'No');
        Observer.Expect('header var', 'No');
        Observer.Expect('var value', 'Row A');
        Observer.Verify();
    end;

    [Test]
    procedure RM_List_PageRun()
    var
        List: TestPage "LT RM Ro List";
    begin
        InsertRow();
        List.Trap();
        Page.Run(Page::"LT RM Ro List");
        ObserveList(List);
        List.Close();
        Observer.Expect('page', 'No');
        Observer.Expect('field', 'No');
        Observer.Expect('var', 'No');
        Observer.Expect('var editable true', 'No');
        Observer.Expect('header var', 'No');
        Observer.Expect('var value', 'Row A');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListModalHandler')]
    procedure RM_List_RunModal()
    begin
        InsertRow();
        Page.RunModal(Page::"LT RM Ro List");
        Observer.Expect('page', 'No');
        Observer.Expect('field', 'No');
        Observer.Expect('var', 'No');
        Observer.Expect('var editable true', 'No');
        Observer.Expect('header var', 'No');
        Observer.Expect('var value', 'Row A');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure ListModalHandler(var List: TestPage "LT RM Ro List")
    begin
        ObserveList(List);
    end;

    [Test]
    procedure RM_List_EmptyTable_OpenEdit()
    var
        Row: Record "LT RM Ro Row";
        List: TestPage "LT RM Ro List";
    begin
        Row.DeleteAll();
        List.OpenEdit();
        Observer.Observe('page', Format(List.Editable()));
        Observer.Observe('var', Format(List.NameText.Editable()));
        Observer.Observe('header var', Format(List.HeaderText.Editable()));
        List.Close();
        Observer.Expect('page', 'No');
        Observer.Expect('var', 'No');
        Observer.Expect('header var', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure RM_Card_OpenEdit()
    var
        Card: TestPage "LT RM Ro Card";
    begin
        InsertRow();
        Card.OpenEdit();
        ObserveCard(Card);
        Card.Close();
        Observer.Expect('page', 'No');
        Observer.Expect('field', 'No');
        Observer.Expect('var', 'No');
        Observer.Expect('var editable true', 'No');
        Observer.Expect('var value', 'Row A');
        Observer.Verify();
    end;

    [Test]
    procedure RM_Card_OpenView()
    var
        Card: TestPage "LT RM Ro Card";
    begin
        InsertRow();
        Card.OpenView();
        ObserveCard(Card);
        Card.Close();
        Observer.Expect('page', 'No');
        Observer.Expect('field', 'No');
        Observer.Expect('var', 'No');
        Observer.Expect('var editable true', 'No');
        Observer.Expect('var value', 'Row A');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardModalHandler')]
    procedure RM_Card_RunModal()
    begin
        InsertRow();
        Page.RunModal(Page::"LT RM Ro Card");
        Observer.Expect('page', 'No');
        Observer.Expect('field', 'No');
        Observer.Expect('var', 'No');
        Observer.Expect('var editable true', 'No');
        Observer.Expect('var value', 'Row A');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure CardModalHandler(var Card: TestPage "LT RM Ro Card")
    begin
        ObserveCard(Card);
    end;
}
