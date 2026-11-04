// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-datacaptionfields-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (P113 DC)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: table DataCaptionFields and the caption a TestPage shows (card and list, view/edit/new, after moving), page DataCaptionFields and DataCaptionExpression for comparison
// BC versions: 29 (27 and 28 by CI)

table 73103 "LT P113 Cap"
{
    DataClassification = CustomerContent;
    DataCaptionFields = "Code", Name;

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

page 73104 "LT P113 Cap Card"
{
    PageType = Card;
    SourceTable = "LT P113 Cap";
    ApplicationArea = All;
    Caption = 'P113 Card';

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
        }
    }
}

page 73105 "LT P113 Cap List"
{
    PageType = List;
    SourceTable = "LT P113 Cap";
    ApplicationArea = All;
    Caption = 'P113 List';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 73106 "LT P113 Cap Card Name"
{
    PageType = Card;
    SourceTable = "LT P113 Cap";
    ApplicationArea = All;
    Caption = 'P113 NameOnly';
    DataCaptionFields = Name;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
        }
    }
}

page 73107 "LT P113 Cap Card Expr"
{
    PageType = Card;
    SourceTable = "LT P113 Cap";
    ApplicationArea = All;
    Caption = 'P113 Expr';
    DataCaptionExpression = 'EXPR-' + Rec.Name;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
        }
    }
}

page 73108 "LT P113 Cap Card None"
{
    PageType = Card;
    SourceTable = "LT P113 Cap";
    ApplicationArea = All;
    Caption = 'P113 None';
    DataCaptionFields = ;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
        }
    }
}

codeunit 73109 "LT P113 DataCaption"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Cap: Record "LT P113 Cap";
    begin
        Cap.DeleteAll();
        Cap.Code := 'C1';
        Cap.Name := 'Alpha';
        Cap.Insert();
        Cap.Code := 'C2';
        Cap.Name := 'Beta';
        Cap.Insert();
    end;

    [Test]
    procedure P113_DC_CardCaption()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 Cap Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('view', Card.Caption());
        Card.Close();
        Card.OpenEdit();
        Observer.Observe('edit', Card.Caption());
        Card.Close();
        Observer.Expect('view', 'P113 Card - C1 ∙ Alpha');
        Observer.Expect('edit', 'P113 Card - C1 ∙ Alpha');
        Observer.Verify();
    end;

    [Test]
    procedure P113_DC_CardCaptionFollowsRecord()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 Cap Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('first', Card.Caption());
        Card.GoToKey('C2');
        Observer.Observe('c2', Card.Caption());
        Card.Close();
        Observer.Expect('first', 'P113 Card - C1 ∙ Alpha');
        Observer.Expect('c2', 'P113 Card - C2 ∙ Beta');
        Observer.Verify();
    end;

    [Test]
    procedure P113_DC_CardNewRecord()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 Cap Card";
    begin
        Seed();
        Card.OpenNew();
        Observer.Observe('new-empty', Card.Caption());
        Card.CodeCtl.SetValue('C3');
        Observer.Observe('new-code', Card.Caption());
        Card.NameCtl.SetValue('Gamma');
        Observer.Observe('new-name', Card.Caption());
        Card.Close();
        Observer.Expect('new-empty', 'New - P113 Card');
        Observer.Expect('new-code', 'New - P113 Card - C3');
        Observer.Expect('new-name', 'New - P113 Card - C3 ∙ Gamma');
        Observer.Verify();
    end;

    [Test]
    procedure P113_DC_CardCaptionAfterEdit()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 Cap Card";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('before', Card.Caption());
        Card.NameCtl.SetValue('Renamed');
        Observer.Observe('after', Card.Caption());
        Card.Close();
        Observer.Expect('before', 'P113 Card - C1 ∙ Alpha');
        Observer.Expect('after', 'P113 Card - C1 ∙ Renamed');
        Observer.Verify();
    end;

    [Test]
    procedure P113_DC_ListCaption()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P113 Cap List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('open', List.Caption());
        List.First();
        Observer.Observe('first', List.Caption());
        List.GoToKey('C2');
        Observer.Observe('c2', List.Caption());
        List.Close();
        Observer.Expect('open', 'P113 List');
        Observer.Expect('first', 'P113 List');
        Observer.Expect('c2', 'P113 List');
        Observer.Verify();
    end;

    [Test]
    procedure P113_DC_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 Cap Card";
        List: TestPage "LT P113 Cap List";
        Cap: Record "LT P113 Cap";
    begin
        Cap.DeleteAll();
        List.OpenView();
        Observer.Observe('list-empty', List.Caption());
        List.Close();
        Card.OpenView();
        Observer.Observe('card-empty', Card.Caption());
        Card.Close();
        Observer.Expect('list-empty', 'P113 List');
        Observer.Expect('card-empty', 'P113 Card');
        Observer.Verify();
    end;

    [Test]
    procedure P113_DC_PageLevelDataCaptionFields()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 Cap Card Name";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('first', Card.Caption());
        Card.GoToKey('C2');
        Observer.Observe('c2', Card.Caption());
        Card.Close();
        Observer.Expect('first', 'P113 NameOnly - C1 ∙ Alpha');
        Observer.Expect('c2', 'P113 NameOnly - C2 ∙ Beta');
        Observer.Verify();
    end;

    [Test]
    procedure P113_DC_DataCaptionExpression()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 Cap Card Expr";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('first', Card.Caption());
        Card.GoToKey('C2');
        Observer.Observe('c2', Card.Caption());
        Card.Close();
        Observer.Expect('first', 'P113 Expr - EXPR-Alpha');
        Observer.Expect('c2', 'P113 Expr - EXPR-Beta');
        Observer.Verify();
    end;

    [Test]
    procedure P113_DC_EmptyDataCaptionFields()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 Cap Card None";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('first', Card.Caption());
        Card.Close();
        Observer.Expect('first', 'P113 None - C1 ∙ Alpha');
        Observer.Verify();
    end;
}
