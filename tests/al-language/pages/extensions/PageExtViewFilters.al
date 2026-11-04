// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: shared table 72313, page 72376, pageextension 72377, codeunit 72378
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

page 72376 "LT P123 ViewExt Base"
{
    PageType = List;
    SourceTable = "LT P123 PRow";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 72377 "LT P123 ViewExt Ext" extends "LT P123 ViewExt Base"
{
    views
    {
        addlast
        {
            view(ExtView)
            {
                Caption = 'Ext view';
                Filters = where(Amount = filter(>10));
            }
        }
    }
}

codeunit 72378 "LT P123 ViewExt Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P123_ExtensionViewDeclaredOnly()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P123 PRow";
        P: TestPage "LT P123 ViewExt Base";
        Count: Integer;
    begin
        R.DeleteAll();
        R.Init(); R.Id := 1; R.Name := 'One'; R.Amount := 5; R.Insert();
        R.Init(); R.Id := 2; R.Name := 'Two'; R.Amount := 15; R.Insert();
        P.OpenView();
        if P.First() then
            repeat
                Count += 1;
            until not P.Next();
        Observer.Observe('rows', Format(Count));
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;
}
