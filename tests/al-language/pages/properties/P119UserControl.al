// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: usercontrol with Visible = false hosting an own control add-in. A usercontrol is no TestPage member (TestPageLabelControlContracts.al): declared only, not observable;
// a field of the page is observed. RISKY: a controladdin without Scripts may not compile (its own file).

controladdin "LT P119 Addin"
{
    RequestedHeight = 50;
    RequestedWidth = 50;

}

page 71669 "LT P119 UserCtl Card"
{
    PageType = Card;
    SourceTable = "LT P119 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(NameF; Rec.Name) { ApplicationArea = All; }
            usercontrol(Ctl; "LT P119 Addin")
            {
                ApplicationArea = All;
                Visible = false;
            }
        }
    }
}

codeunit 71670 "LT P119 UserCtl Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_NeighbourOfUserControl()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 UserCtl Card";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'Ctl';
        Row.Insert();
        TP.OpenView();
        Observer.Observe('name-value', TP.NameF.Value());
        TP.Close();
        Observer.Expect('name-value', 'Ctl');
        Observer.Verify();
    end;
}
