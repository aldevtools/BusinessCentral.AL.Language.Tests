// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-field-control
// Scope: in-scope
// Fixtures used: own objects 55250-55265 (LT Cnt tables and pages), 55266 (LT Rec Count Control)
// Probe: from al-runner issue 7875 (a page control whose source is `Rec.Count`, a Record method written without parentheses).
// Area: a control whose SourceExpr is a Record method call on Rec, on a list page over a table with 3 rows (ids 1 to 3).
//   - `Rec.Count`, `Rec.CountApprox`, `Rec.GetFilters`, `Rec.IsEmpty`, `Rec.TableCaption`, `Rec.TableName` without parentheses,
//     and `Rec.Count()` with parentheses: do they compile, and the value of the control;
//   - a bare `Count` (no Rec) as the source;
//   - a table with a field named Count: does `Rec.Count` and `Rec.Count()` name the field or the method;
//   - the value on the first, second and last row, with a TestPage filter set after the open, and on a page whose SourceTableView
//     filters the rows (the page's Count follows the filter or not);
//   - the control inside a repeater, in a group outside the repeater, and on a card page.
// Compile errors (not tests): `Rec.FieldCount` on a page over a table (Record has no FieldCount) is in tests/must-not-compile/cases.
// Observation form: every test ends in Finish(); the values are what BC produced.
// BC versions: 27.5, 28.5, 29.0 (measured by the corpus CI)

table 55250 "LT Cnt Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 55251 "LT Cnt Field Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Count; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 55252 "LT Cnt Count"
{
    PageType = List;
    SourceTable = "LT Cnt Row";
    ApplicationArea = All;

    layout
    {
            area(Content)
            {
                repeater(Rows)
                {
                    field(Id; Rec.Id) { }
                    field(Total; Rec.Count) { }
                }
            }
    }
}

page 55253 "LT Cnt Count Outside"
{
    PageType = List;
    SourceTable = "LT Cnt Row";
    ApplicationArea = All;

    layout
    {
            area(Content)
            {
                group(Summary)
                {
                    field(Total; Rec.Count) { }
                }
                repeater(Rows)
                {
                    field(Id; Rec.Id) { }
                }
            }
    }
}

page 55254 "LT Cnt CountApprox"
{
    PageType = List;
    SourceTable = "LT Cnt Row";
    ApplicationArea = All;

    layout
    {
            area(Content)
            {
                repeater(Rows)
                {
                    field(Id; Rec.Id) { }
                    field(Total; Rec.CountApprox) { }
                }
            }
    }
}

page 55255 "LT Cnt GetFilters"
{
    PageType = List;
    SourceTable = "LT Cnt Row";
    ApplicationArea = All;

    layout
    {
            area(Content)
            {
                repeater(Rows)
                {
                    field(Id; Rec.Id) { }
                    field(Total; Rec.GetFilters) { }
                }
            }
    }
}

page 55256 "LT Cnt Count Parens"
{
    PageType = List;
    SourceTable = "LT Cnt Row";
    ApplicationArea = All;

    layout
    {
            area(Content)
            {
                repeater(Rows)
                {
                    field(Id; Rec.Id) { }
                    field(Total; Rec.Count()) { }
                }
            }
    }
}

page 55257 "LT Cnt IsEmpty"
{
    PageType = List;
    SourceTable = "LT Cnt Row";
    ApplicationArea = All;

    layout
    {
            area(Content)
            {
                repeater(Rows)
                {
                    field(Id; Rec.Id) { }
                    field(Total; Rec.IsEmpty) { }
                }
            }
    }
}

page 55258 "LT Cnt TableCaption"
{
    PageType = List;
    SourceTable = "LT Cnt Row";
    ApplicationArea = All;

    layout
    {
            area(Content)
            {
                repeater(Rows)
                {
                    field(Id; Rec.Id) { }
                    field(Total; Rec.TableCaption) { }
                }
            }
    }
}

page 55259 "LT Cnt TableName"
{
    PageType = List;
    SourceTable = "LT Cnt Row";
    ApplicationArea = All;

    layout
    {
            area(Content)
            {
                repeater(Rows)
                {
                    field(Id; Rec.Id) { }
                    field(Total; Rec.TableName) { }
                }
            }
    }
}

page 55260 "LT Cnt Bare Count"
{
    PageType = List;
    SourceTable = "LT Cnt Row";
    ApplicationArea = All;

    layout
    {
            area(Content)
            {
                repeater(Rows)
                {
                    field(Id; Rec.Id) { }
                    field(Total; Count) { }
                }
            }
    }
}

page 55261 "LT Cnt Count SourceView"
{
    PageType = List;
    SourceTable = "LT Cnt Row";
    ApplicationArea = All;
        SourceTableView = where(Id = filter(2..3));

    layout
    {
            area(Content)
            {
                repeater(Rows)
                {
                    field(Id; Rec.Id) { }
                    field(Total; Rec.Count) { }
                }
            }
    }
}

page 55262 "LT Cnt Field Count"
{
    PageType = List;
    SourceTable = "LT Cnt Field Row";
    ApplicationArea = All;

    layout
    {
            area(Content)
            {
                repeater(Rows)
                {
                    field(Id; Rec.Id) { }
                    field(Total; Rec.Count) { }
                }
            }
    }
}

page 55263 "LT Cnt Field Count Parens"
{
    PageType = List;
    SourceTable = "LT Cnt Field Row";
    ApplicationArea = All;

    layout
    {
            area(Content)
            {
                repeater(Rows)
                {
                    field(Id; Rec.Id) { }
                    field(Total; Rec.Count()) { }
                }
            }
    }
}

page 55264 "LT Cnt Count Card"
{
    PageType = Card;
    SourceTable = "LT Cnt Row";
    ApplicationArea = All;

    layout
    {
            area(Content)
            {
                group(General)
                {
                    field(Id; Rec.Id) { }
                    field(Total; Rec.Count) { }
                }
            }
    }
}

codeunit 55266 "LT Rec Count Control"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT Cnt Row";
    begin
        Row.DeleteAll();
        Row.Init(); Row.Id := 1; Row.Name := 'a'; Row.Insert();
        Row.Init(); Row.Id := 2; Row.Name := 'b'; Row.Insert();
        Row.Init(); Row.Id := 3; Row.Name := 'c'; Row.Insert();
    end;

    local procedure SeedField()
    var
        Row: Record "LT Cnt Field Row";
    begin
        Row.DeleteAll();
        Row.Init(); Row.Id := 1; Row.Count := 10; Row.Insert();
        Row.Init(); Row.Id := 2; Row.Count := 20; Row.Insert();
        Row.Init(); Row.Id := 3; Row.Count := 30; Row.Insert();
    end;

    [Test]
    procedure Count_List_Repeater()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Cnt Count";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('first', Format(TP.Total.Value()));
        TP.Next();
        Observer.Observe('second', Format(TP.Total.Value()));
        TP.Last();
        Observer.Observe('last', Format(TP.Total.Value()));
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Count_List_AfterTestPageFilter()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Cnt Count";
    begin
        Seed();
        TP.OpenView();
        TP.Filter.SetFilter(Id, '2..3');
        TP.First();
        Observer.Observe('first', Format(TP.Total.Value()));
        TP.Next();
        Observer.Observe('second', Format(TP.Total.Value()));
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Count_List_SourceTableView()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Cnt Count SourceView";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('first', Format(TP.Total.Value()));
        TP.Next();
        Observer.Observe('second', Format(TP.Total.Value()));
        TP.Last();
        Observer.Observe('last', Format(TP.Total.Value()));
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Count_List_OutsideRepeater()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Cnt Count Outside";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('first', Format(TP.Total.Value()));
        TP.Next();
        Observer.Observe('second', Format(TP.Total.Value()));
        TP.Last();
        Observer.Observe('last', Format(TP.Total.Value()));
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure CountApprox_List()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Cnt CountApprox";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('first', Format(TP.Total.Value()));
        TP.Next();
        Observer.Observe('second', Format(TP.Total.Value()));
        TP.Last();
        Observer.Observe('last', Format(TP.Total.Value()));
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure GetFilters_List_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Cnt GetFilters";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('first', Format(TP.Total.Value()));
        TP.Next();
        Observer.Observe('second', Format(TP.Total.Value()));
        TP.Last();
        Observer.Observe('last', Format(TP.Total.Value()));
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure GetFilters_List_AfterTestPageFilter()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Cnt GetFilters";
    begin
        Seed();
        TP.OpenView();
        TP.Filter.SetFilter(Id, '2..3');
        TP.First();
        Observer.Observe('first', Format(TP.Total.Value()));
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure CountParens_List()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Cnt Count Parens";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('first', Format(TP.Total.Value()));
        TP.Next();
        Observer.Observe('second', Format(TP.Total.Value()));
        TP.Last();
        Observer.Observe('last', Format(TP.Total.Value()));
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure IsEmpty_List()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Cnt IsEmpty";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('first', Format(TP.Total.Value()));
        TP.Next();
        Observer.Observe('second', Format(TP.Total.Value()));
        TP.Last();
        Observer.Observe('last', Format(TP.Total.Value()));
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TableCaption_List()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Cnt TableCaption";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('first', Format(TP.Total.Value()));
        TP.Next();
        Observer.Observe('second', Format(TP.Total.Value()));
        TP.Last();
        Observer.Observe('last', Format(TP.Total.Value()));
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TableName_List()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Cnt TableName";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('first', Format(TP.Total.Value()));
        TP.Next();
        Observer.Observe('second', Format(TP.Total.Value()));
        TP.Last();
        Observer.Observe('last', Format(TP.Total.Value()));
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure BareCount_List()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Cnt Bare Count";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('first', Format(TP.Total.Value()));
        TP.Next();
        Observer.Observe('second', Format(TP.Total.Value()));
        TP.Last();
        Observer.Observe('last', Format(TP.Total.Value()));
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure CountField_TableHasFieldNamedCount()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Cnt Field Count";
    begin
        SeedField();
        TP.OpenView();
        Observer.Observe('first', Format(TP.Total.Value()));
        TP.Next();
        Observer.Observe('second', Format(TP.Total.Value()));
        TP.Last();
        Observer.Observe('last', Format(TP.Total.Value()));
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure CountFieldParens_TableHasFieldNamedCount()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Cnt Field Count Parens";
    begin
        SeedField();
        TP.OpenView();
        Observer.Observe('first', Format(TP.Total.Value()));
        TP.Next();
        Observer.Observe('second', Format(TP.Total.Value()));
        TP.Last();
        Observer.Observe('last', Format(TP.Total.Value()));
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Count_Card()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Cnt Count Card";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('first', Format(TP.Total.Value()));
        TP.Close();
        Observer.Finish();
    end;

}
