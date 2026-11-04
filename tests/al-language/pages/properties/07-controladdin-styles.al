// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: addin/ files next to the page (copy into the app folder)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

controladdin "LT P121 AddIn Styles"
{
    Scripts = 'controladdins/lt-p121.js';
    StyleSheets = 'controladdins/lt-p121.css';

    event Ready();
    procedure Ping(Value: Text);
}

page 72179 "LT P121 AddIn Styles Page"
{
    PageType = Card;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            usercontrol(Ctl; "LT P121 AddIn Styles")
            {
                ApplicationArea = All;
            }
        }
    }
}

codeunit 72180 "LT P121 AddIn Styles Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P121_OpenPageWithControl()
    var
        Pg: TestPage "LT P121 AddIn Styles Page";
        Observer: Codeunit "Probe Observer";
    begin
        Pg.OpenView();
        Observer.Observe('opened', 'yes');
        Pg.Close();
        Observer.Expect('opened', 'yes');
        Observer.Verify();
    end;
}
