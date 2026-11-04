// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-conditional-expressions
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own interface "LT QW Tern Compute", codeunits 87504 and 87505, table 87506, page 87507, test codeunit 87508;
// table 87500 of tests/al-language/report/lt-qw-ternary-columns/QwTernaryColumns.al
// Probe (corpus issue 685 sections 3 and 4): helper objects for the ternary tests of tests/al-language/types/TestTernaryContracts.al (interface and
// codeunit values as branches, Validate with a ternary), and a card page with ternary control expressions (test codeunit 87508). A ternary in a
// Visible or Editable property does not compile (AL0322, tests/must-not-compile/cases/2070).
// BC versions: 27.5+

interface "LT QW Tern Compute"
{
    procedure Compute(X: Integer): Integer;
}

codeunit 87504 "LT QW Tern Double" implements "LT QW Tern Compute"
{
    var
        Calls: Integer;

    procedure Compute(X: Integer): Integer
    begin
        Calls += 1;
        exit(2 * X);
    end;

    procedure CallCount(): Integer
    begin
        exit(Calls);
    end;
}

codeunit 87505 "LT QW Tern Square" implements "LT QW Tern Compute"
{
    procedure Compute(X: Integer): Integer
    begin
        exit(X * X);
    end;
}

table 87506 "LT QW Tern Val"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Val; Text[10])
        {
            trigger OnValidate()
            begin
                Trail += 'V(' + Val + ';old=' + xRec.Val + ')';
            end;
        }
        field(3; Trail; Text[250]) { }
        field(4; Num; Decimal)
        {
            trigger OnValidate()
            begin
                Trail += 'N(' + Format(Num, 0, 9) + ')';
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 87507 "LT QW Tern Card"
{
    PageType = Card;
    SourceTable = "LT QW Tern Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { }
            field(TernLabel; Rec.Flag ? LblA : Rec.Name) { Caption = 'Ternary label'; }
            field(TernEmptyLabel; Rec.Flag ? '' : LblA) { Caption = 'Ternary empty label'; }
            field(TernDec; Rec.Flag ? Rec.Amount : 0) { Caption = 'Ternary decimal'; }
            field(TernEnum; Rec.Flag ? Rec.E : Rec.E::Order) { Caption = 'Ternary enum'; }
        }
    }

    var
        LblA: Label 'Label A';
}

codeunit 87508 "LT QW Tern Page Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Flag: Boolean)
    var
        Row: Record "LT QW Tern Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Flag := Flag;
        Row.Name := 'Field name';
        Row.Amount := 12.5;
        Row.Qty := 3;
        Row.E := Row.E::Invoice;
        Row.Insert();
    end;

    local procedure Card(Flag: Boolean; var Observer: Codeunit "Probe Observer")
    var
        Row: Record "LT QW Tern Row";
        Card: TestPage "LT QW Tern Card";
    begin
        Seed(Flag);
        Row.Get(1);
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Observer.Observe('label', Card.TernLabel.Value());
        Observer.Observe('empty_label', '[' + Card.TernEmptyLabel.Value() + ']');
        Observer.Observe('decimal', Card.TernDec.Value());
        Observer.Observe('enum', Card.TernEnum.Value());
        Observer.Observe('label_editable', Format(Card.TernLabel.Editable()));
        Card.Close();
    end;

    [Test]
    procedure QW_TernaryPage_FlagTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Card(true, Observer);
        Observer.Expect('label', 'Label A');
        Observer.Expect('empty_label', '[]');
        Observer.Expect('decimal', '12.50');
        Observer.Expect('enum', 'Invoice');
        Observer.Expect('label_editable', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QW_TernaryPage_FlagFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Card(false, Observer);
        Observer.Expect('label', 'Field name');
        Observer.Expect('empty_label', '[Label A]');
        Observer.Expect('decimal', '0.00');
        Observer.Expect('enum', 'Order');
        Observer.Expect('label_editable', 'No');
        Observer.Verify();
    end;
}
