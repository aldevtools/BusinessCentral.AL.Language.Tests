// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: a page extension that modifies a view with Visible = false (declared; a TestPage opens the list in the same way, only the rows are observed).

page 71642 "LT P119 Views List"
{
    PageType = List;
    SourceTable = "LT P119 Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    views
    {
        view(BigIds)
        {
            Caption = 'Big Ids';
            Filters = where(Id = filter(> 1));
        }
        view(AllRows)
        {
            Caption = 'All Rows';
        }
    }
}

pageextension 71643 "LT P119 Views Ext" extends "LT P119 Views List"
{
    views
    {
        modify(AllRows)
        {
            Visible = false;
        }
    }
}

codeunit 71644 "LT P119 Views Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_ListWithHiddenView()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Views List";
        Row: Record "LT P119 Row";
        Count: Integer;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'One';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'Two';
        Row.Insert();
        TP.OpenView();
        if TP.First() then
            repeat
                Count += 1;
            until not TP.Next();
        Observer.Observe('rows', Format(Count));
        TP.Close();
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;
}
