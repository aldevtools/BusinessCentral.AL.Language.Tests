// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Also: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: Cloud-compatible; BC 27.5+. Fixtures used: Probe Observer (69160), ALT Universal, ALT Status, ALTFixtureCleanup; own tables 96910, pages 96911 and 96912, test codeunit 96913
// Probe: (al-runner issue 7189 follow-up) enum-qualified lists and ranges in `filter(...)` of CalcFormula and SourceTableView: `filter(E::A | E::B)` and `filter(E::A .. E::B)`.
// Single `const(E::A)` and `filter(E::A)` are pinned in record/qualified-enum-filters/TestQualifiedEnumFilters.al.
// Facts: the sums the FlowFields give and the entry numbers the two pages list, for rows with the status blank, Draft, Active and Closed.
// BC versions: 27.5, 28.5, 29.0
table 96910 "LT EL Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { DataClassification = SystemMetadata; }
        field(2; "List Total"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("ALT Universal"."Decimal Field" where("Status Field" = filter("ALT Status"::Draft | "ALT Status"::Active)));
        }
        field(3; "Range Total"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("ALT Universal"."Decimal Field" where("Status Field" = filter("ALT Status"::Draft .. "ALT Status"::Active)));
        }
        field(4; "List Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("ALT Universal" where("Status Field" = filter("ALT Status"::Active | "ALT Status"::Closed)));
        }
        field(5; "Range Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("ALT Universal" where("Status Field" = filter("ALT Status"::Active .. "ALT Status"::Closed)));
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 96911 "LT EL List Page"
{
    PageType = List;
    SourceTable = "ALT Universal";
    SourceTableView = where("Status Field" = filter("ALT Status"::Draft | "ALT Status"::Closed));
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(EntryNo; Rec."Entry No.") { ApplicationArea = All; }
            }
        }
    }
}

page 96912 "LT EL Range Page"
{
    PageType = List;
    SourceTable = "ALT Universal";
    SourceTableView = where("Status Field" = filter("ALT Status"::Draft .. "ALT Status"::Active));
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(EntryNo; Rec."Entry No.") { ApplicationArea = All; }
            }
        }
    }
}

codeunit 96913 "LT EL Enum Lists Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CalcFormula_QualifiedEnumList_And_Range()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "LT EL Header";
    begin
        Initialize();
        Header.Get(1);
        Header.CalcFields("List Total", "Range Total", "List Count", "Range Count");
        Observer.Observe('list total', Format(Header."List Total"));
        Observer.Observe('range total', Format(Header."Range Total"));
        Observer.Observe('list count', Format(Header."List Count"));
        Observer.Observe('range count', Format(Header."Range Count"));
        Observer.Finish();
    end;

    [Test]
    procedure SourceTableView_QualifiedEnumList()
    var
        Observer: Codeunit "Probe Observer";
        View: TestPage "LT EL List Page";
        Keys: Text;
    begin
        Initialize();
        View.OpenView();
        if View.First() then
            repeat
                if Keys <> '' then
                    Keys += ',';
                Keys += Format(View.EntryNo.AsInteger());
            until not View.Next();
        View.Close();
        Observer.Observe('list keys', Keys);
        Observer.Finish();
    end;

    [Test]
    procedure SourceTableView_QualifiedEnumRange()
    var
        Observer: Codeunit "Probe Observer";
        View: TestPage "LT EL Range Page";
        Keys: Text;
    begin
        Initialize();
        View.OpenView();
        if View.First() then
            repeat
                if Keys <> '' then
                    Keys += ',';
                Keys += Format(View.EntryNo.AsInteger());
            until not View.Next();
        View.Close();
        Observer.Observe('range keys', Keys);
        Observer.Finish();
    end;

    local procedure Initialize()
    var
        Cleanup: Codeunit ALTFixtureCleanup;
        Header: Record "LT EL Header";
        Row: Record "ALT Universal";
    begin
        Cleanup.Initialize();
        Header.DeleteAll(false);
        Header.Id := 1;
        Header.Insert(false);
        Row."Entry No." := 101;
        Row."Status Field" := Row."Status Field"::" ";
        Row."Decimal Field" := 1000;
        Row.Insert(false);
        Row."Entry No." := 202;
        Row."Status Field" := Row."Status Field"::Draft;
        Row."Decimal Field" := 9.25;
        Row.Insert(false);
        Row."Entry No." := 303;
        Row."Status Field" := Row."Status Field"::Active;
        Row."Decimal Field" := 42.5;
        Row.Insert(false);
        Row."Entry No." := 404;
        Row."Status Field" := Row."Status Field"::Closed;
        Row."Decimal Field" := 100;
        Row.Insert(false);
    end;
}
