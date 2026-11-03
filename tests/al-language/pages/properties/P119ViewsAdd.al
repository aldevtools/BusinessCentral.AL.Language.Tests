// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: a page extension that adds a view with Visible = false (declared; only the rows of the list are observed).

page 71645 "LT P119 ViewsAdd List"
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
        view(First)
        {
            Caption = 'First View';
        }
    }
}

pageextension 71646 "LT P119 ViewsAdd Ext" extends "LT P119 ViewsAdd List"
{
    views
    {
        addlast
        {
            view(Added)
            {
                Caption = 'Added View';
                Visible = false;
                Filters = where(Id = filter(1));
            }
        }
    }
}

codeunit 71647 "LT P119 ViewsAdd Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_ListWithAddedHiddenView()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 ViewsAdd List";
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
