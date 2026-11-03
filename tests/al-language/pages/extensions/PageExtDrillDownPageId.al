// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: shared table 72313, pages 72371 72372 72375, pageextension 72373, codeunit 72374
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

page 72375 "LT P123 Drill Target"
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

page 72371 "LT P123 Drill Base"
{
    PageType = Card;
    SourceTable = "LT P123 PRow";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }
}

pageextension 72373 "LT P123 Drill Ext" extends "LT P123 Drill Base"
{
    layout
    {
        modify(Name)
        {
            DrillDownPageId = "LT P123 Drill Target";
        }
    }
}

codeunit 72374 "LT P123 DrillPage Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [PageHandler]
    procedure TargetHandler(var T: TestPage "LT P123 Drill Target")
    begin
        T.First();
    end;

    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure P123_DrillDownPageIdFromExtension()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P123 PRow";
        P: TestPage "LT P123 Drill Base";
    begin
        R.DeleteAll();
        R.Init(); R.Id := 1; R.Name := 'One'; R.Insert();
        P.OpenView();
        P.Name.Drilldown();
        Observer.Observe('name', P.Name.Value());
        Observer.Expect('name', 'One');
        Observer.Verify();
    end;
}
