// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Also: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: Cloud-compatible; BC 27.5+. Shared fixtures: ALT Universal, ALT Status and ALTFixtureCleanup.
// local object: the enum-qualified CalcFormula definitions are under test.
table 69476 "REC Enum Const Header"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; "Plain Total"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("ALT Universal"."Decimal Field" where("Status Field" = const(Active)));
        }
        field(3; "Qualified Total"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("ALT Universal"."Decimal Field" where("Status Field" = const("ALT Status"::Active)));
        }
        field(4; "Filtered Total"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("ALT Universal"."Decimal Field" where("Status Field" = filter("ALT Status"::Active)));
        }
        field(5; "Qualified Exists"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("ALT Universal" where("Status Field" = const("ALT Status"::Active)));
        }
        field(6; "Qualified Text"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("ALT Universal"."Text Field" where("Status Field" = const("ALT Status"::Active)));
        }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

// local object: the enum-qualified SourceTableView is under test.
page 69477 "REC Enum Const List"
{
    PageType = List;
    SourceTable = "ALT Universal";
    SourceTableView = where("Status Field" = const("ALT Status"::Active));
    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(EntryNo; Rec."Entry No.") { ApplicationArea = All; }
                field(Value; Rec."Text Field") { ApplicationArea = All; }
            }
        }
    }
}

codeunit 69478 "REC Enum Const Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CalcFormula_PlainEnumConst_SelectsActiveAmount()
    var
        Header: Record "REC Enum Const Header";
    begin
        Initialize();
        Header.Get(1);
        Header.CalcFields("Plain Total");
        if Header."Plain Total" <> 42.5 then
            Error('Expected plain enum total 42.5; actual %1.', Header."Plain Total");
    end;

    [Test]
    procedure CalcFormula_QualifiedEnumConst_SelectsActiveAmount()
    var
        Header: Record "REC Enum Const Header";
    begin
        Initialize();
        Header.Get(1);
        Header.CalcFields("Qualified Total");
        if Header."Qualified Total" <> 42.5 then
            Error('Expected qualified enum total 42.5; actual %1.', Header."Qualified Total");
    end;

    [Test]
    procedure CalcFormula_QualifiedEnumFilter_SelectsActiveAmount()
    var
        Header: Record "REC Enum Const Header";
    begin
        Initialize();
        Header.Get(1);
        Header.CalcFields("Filtered Total");
        if Header."Filtered Total" <> 42.5 then
            Error('Expected qualified filter total 42.5; actual %1.', Header."Filtered Total");
    end;

    [Test]
    procedure CalcFormula_QualifiedEnumExist_FindsActiveRow()
    var
        Header: Record "REC Enum Const Header";
    begin
        Initialize();
        Header.Get(1);
        Header.CalcFields("Qualified Exists");
        if not Header."Qualified Exists" then
            Error('Expected existence of the active row.');
    end;

    [Test]
    procedure CalcFormula_QualifiedEnumLookup_ReturnsActiveText()
    var
        Header: Record "REC Enum Const Header";
    begin
        Initialize();
        Header.Get(1);
        Header.CalcFields("Qualified Text");
        if Header."Qualified Text" <> 'QUALIFIED-42' then
            Error('Expected QUALIFIED-42; actual %1.', Header."Qualified Text");
    end;

    [Test]
    procedure SourceTableView_QualifiedEnumConst_OpensActiveRow()
    var
        View: TestPage "REC Enum Const List";
    begin
        Initialize();
        View.OpenView();
        View.EntryNo.AssertEquals(202);
        View.Value.AssertEquals('QUALIFIED-42');
        View.Close();
    end;

    local procedure Initialize()
    var
        Cleanup: Codeunit ALTFixtureCleanup;
        Header: Record "REC Enum Const Header";
        Row: Record "ALT Universal";
    begin
        Cleanup.Initialize();
        Header.DeleteAll(false);
        Header.Id := 1;
        Header.Insert(false);
        Row."Entry No." := 101;
        Row."Status Field" := Row."Status Field"::Draft;
        Row."Decimal Field" := 9.25;
        Row."Text Field" := 'DROP-9';
        Row.Insert(false);
        Row."Entry No." := 202;
        Row."Status Field" := Row."Status Field"::Active;
        Row."Decimal Field" := 42.5;
        Row."Text Field" := 'QUALIFIED-42';
        Row.Insert(false);
    end;

    [Test]
    procedure SubPageView_QualifiedEnumConst_OpensActiveRow()
    var
        View: TestPage "REC Enum Const Host";
    begin
        Initialize();
        View.OpenView();
        View.Lines.First();
        View.Lines.EntryNo.AssertEquals(202);
        View.Lines.Value.AssertEquals('QUALIFIED-42');
        if View.Lines.Next() then
            Error('Expected just the active row.');
        View.Close();
    end;
}

// local object: the qualified SubPageView property is declared on the host.
page 69996 "REC Enum Const Host"
{
    PageType = Card;
    SourceTable = "ALT Universal";
    layout
    {
        area(Content)
        {
            part(Lines; "REC Enum Const Part")
            {
                ApplicationArea = All;
                SubPageView = where("Status Field" = const("ALT Status"::Active));
            }
        }
    }
}

// local object: the part leaves its view unrestricted so the host property supplies the filter.
page 69997 "REC Enum Const Part"
{
    PageType = ListPart;
    SourceTable = "ALT Universal";
    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(EntryNo; Rec."Entry No.") { ApplicationArea = All; }
                field(Value; Rec."Text Field") { ApplicationArea = All; }
            }
        }
    }
}
