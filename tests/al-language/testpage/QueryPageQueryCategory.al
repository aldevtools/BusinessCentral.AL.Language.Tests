// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

query 72495 "LT P194 QueryCat Query"
{
    QueryType = Normal;
    QueryCategory = 'Cat1';

    elements
    {
        dataitem(Gen; "LT P194 Gen")
        {
            column(CodeCol; "Code") { }
            column(NameCol; Name) { }
        }
    }
}

page 72496 "LT P194 QueryCat List"
{
    PageType = List;
    SourceTable = "LT P194 Gen";
    ApplicationArea = All;
    UsageCategory = None;
    QueryCategory = 'Cat1';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeFld; Rec."Code") { ApplicationArea = All; }
                field(NameFld; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

// Writer BP (corpus issue 664, microsoft/AL issue 6418): QueryCategory longer than 30 characters (46 here). It compiles; the test pins
// that the app publishes and the page opens.
page 82559 "LT BP QueryCat Long List"
{
    PageType = List;
    SourceTable = "LT P194 Gen";
    ApplicationArea = All;
    UsageCategory = None;
    QueryCategory = 'Category Name That Is Longer Than Thirty Chars';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeFld; Rec."Code") { ApplicationArea = All; }
                field(NameFld; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}
codeunit 72497 "LT P194 QueryCat Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P194_Query_WithCategory_OpenRead()
    var
        Gen: Record "LT P194 Gen";
        Q: Query "LT P194 QueryCat Query";
        Rows: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Gen.DeleteAll();
        Gen."Code" := 'A';
        Gen.Name := 'one';
        Gen.Insert();
        Gen."Code" := 'B';
        Gen.Name := 'two';
        Gen.Insert();
        Observer.Observe('open', Format(Q.Open()));
        while Q.Read() do
            Rows += Q.CodeCol + ':' + Q.NameCol + ',';
        Q.Close();
        Observer.Observe('rows', Rows);
        Observer.Expect('open', 'Yes');
        Observer.Expect('rows', 'A:one,B:two,');
        Observer.Verify();
    end;

    [Test]
    procedure P194_Page_WithCategory_OpenView()
    var
        Gen: Record "LT P194 Gen";
        List: TestPage "LT P194 QueryCat List";
        Rows: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Gen.DeleteAll();
        Gen."Code" := 'A';
        Gen.Name := 'one';
        Gen.Insert();
        Gen."Code" := 'B';
        Gen.Name := 'two';
        Gen.Insert();
        List.OpenView();
        if List.First() then
            repeat
                Rows += List.CodeFld.Value() + ':' + List.NameFld.Value() + ',';
            until not List.Next();
        List.Close();
        Observer.Observe('rows', Rows);
        Observer.Expect('rows', 'A:one,B:two,');
        Observer.Verify();
    end;

    // Writer BP (corpus issue 664): a page with a QueryCategory of 46 characters opens and shows its rows.
    [Test]
    procedure BP_Page_WithLongQueryCategory_OpenView()
    var
        Gen: Record "LT P194 Gen";
        List: TestPage "LT BP QueryCat Long List";
        Rows: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Gen.DeleteAll();
        Gen."Code" := 'A';
        Gen.Name := 'one';
        Gen.Insert();
        List.OpenView();
        if List.First() then
            repeat
                Rows += List.CodeFld.Value() + ':' + List.NameFld.Value() + ',';
            until not List.Next();
        List.Close();
        Observer.Observe('rows', Rows);
        Observer.Observe('length', Format(StrLen('Category Name That Is Longer Than Thirty Chars')));
        Observer.Expect('rows', 'A:one,');
        Observer.Expect('length', '46');
        Observer.Verify();
    end;
}
