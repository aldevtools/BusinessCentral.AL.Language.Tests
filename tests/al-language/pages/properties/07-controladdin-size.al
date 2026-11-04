// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: none
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

controladdin "LT P121 AddIn Size"
{
    RequestedHeight = 200;
    RequestedWidth = 300;
    MinimumHeight = 100;
    MinimumWidth = 150;
    HorizontalStretch = true;
    VerticalStretch = true;
    HorizontalShrink = true;
    VerticalShrink = true;

    event Ready();
    procedure Ping(Value: Text);
}

page 72177 "LT P121 AddIn Size Page"
{
    PageType = Card;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            usercontrol(Ctl; "LT P121 AddIn Size")
            {
                ApplicationArea = All;
            }
        }
    }
}

codeunit 72178 "LT P121 AddIn Size Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P121_OpenPageWithControl()
    var
        Pg: TestPage "LT P121 AddIn Size Page";
        Observer: Codeunit "Probe Observer";
    begin
        Pg.OpenView();
        Observer.Observe('opened', 'yes');
        Pg.Close();
        Observer.Expect('opened', 'yes');
        Observer.Verify();
    end;
}
