// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-datacaptionexpression-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Facts: al-runner issue 6320: TestPage.Caption of a page with DataCaptionExpression and no source table (expression read from a page procedure
//   that depends on page state), an expression returning an empty text, and a page with a source table and no row. The case with a source table
//   and a row is pinned in pages/lt-page-autoformat-lookups/P113DataCaption.al.

table 90630 "LT WB DC Row"
{
    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
    }
    keys { key(PK; "Code") { Clustered = true; } }
}

page 90630 "LT WB DC Editor"
{
    PageType = Card;
    Caption = 'Message Editor';
    DataCaptionExpression = GetCaption();
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(SubjectCtl; Subject) { ApplicationArea = All; }
        }
    }

    var
        Subject: Text;

    procedure SetSubject(NewSubject: Text)
    begin
        Subject := NewSubject;
    end;

    local procedure GetCaption(): Text
    begin
        if Subject <> '' then
            exit(Subject);
        exit('New message');
    end;
}

page 90631 "LT WB DC Empty Expr"
{
    PageType = Card;
    Caption = 'Empty Expr';
    DataCaptionExpression = '';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(SubjectCtl; Subject) { ApplicationArea = All; }
        }
    }

    var
        Subject: Text;
}

page 90632 "LT WB DC Src Expr"
{
    PageType = Card;
    SourceTable = "LT WB DC Row";
    Caption = 'Src Expr';
    DataCaptionExpression = 'EXPR-' + Rec.Name;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
        }
    }
}

codeunit 90630 "LT WB DC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    [HandlerFunctions('EditorHandler')]
    procedure DC_Expression_NoSourceTable_Procedure()
    var
        Editor: Page "LT WB DC Editor";
    begin
        Editor.SetSubject('Hello');
        Editor.RunModal();
        Observer.Expect('with subject', 'Message Editor - Hello');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('EditorHandler')]
    procedure DC_Expression_NoSourceTable_DefaultText()
    var
        Editor: Page "LT WB DC Editor";
    begin
        Editor.RunModal();
        Observer.Expect('with subject', 'Message Editor - New message');
        Observer.Verify();
    end;

    [Test]
    procedure DC_Expression_Empty()
    var
        Card: TestPage "LT WB DC Empty Expr";
    begin
        Card.OpenView();
        Observer.Observe('empty', Card.Caption());
        Card.Close();
        Observer.Expect('empty', 'Empty Expr');
        Observer.Verify();
    end;

    [Test]
    procedure DC_Expression_SourceTable_NoRow()
    var
        Row: Record "LT WB DC Row";
        Card: TestPage "LT WB DC Src Expr";
    begin
        Row.DeleteAll();
        Card.OpenView();
        Observer.Observe('norow', Card.Caption());
        Card.Close();
        Observer.Expect('norow', 'Src Expr');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure EditorHandler(var Editor: TestPage "LT WB DC Editor")
    begin
        Observer.Observe('with subject', Editor.Caption());
    end;
}
