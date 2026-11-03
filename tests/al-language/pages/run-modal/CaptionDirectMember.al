// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT CapRead Static (page 71470, file CaptionReadBeforeRun.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: reads and assigns the Caption member directly on a Page variable before the page runs.
// BC versions: 29 (27 and 28 by CI)

codeunit 71475 "LT CapRead Direct"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P182b_PageVariable_CaptionMember_BeforeRun()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT CapRead Static";
    begin
        Observer.Observe('direct-read', '[' + Pg.Caption + ']');
        Pg.Caption := 'Direct Assign';
        Observer.Observe('direct-read-after-assign', '[' + Pg.Caption + ']');
        Observer.Expect('direct-read', '[LT Static Caption]');
        Observer.Expect('direct-read-after-assign', '[Direct Assign]');
        Observer.Verify();
    end;
}
