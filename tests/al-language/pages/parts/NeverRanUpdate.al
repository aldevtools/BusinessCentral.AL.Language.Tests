// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-part-control
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT NeverRan Host (71482), LT NeverRan Part (71481), LT NeverRan Line (71480) from NeverRanFixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CurrPage.Update(false) and Update(true) inside a part procedure called through CurrPage.Lines.Page of a Page variable that never ran; ok or the error text and code.
// BC versions: 29 (27 and 28 by CI)

codeunit 71484 "LT NeverRan Update"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryPartUpdate(var Host: Page "LT NeverRan Host"; Save: Boolean)
    begin
        Host.PartUpdate(Save);
    end;

    [Test]
    procedure P182b_HostNeverRan_PartUpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
        Host: Page "LT NeverRan Host";
    begin
        if TryPartUpdate(Host, false) then
            Observer.Observe('part-update-false', 'ok')
        else
            Observer.ObserveError('part-update-false');
        Observer.Expect('part-update-false', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure P182b_HostNeverRan_PartUpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
        Host: Page "LT NeverRan Host";
    begin
        if TryPartUpdate(Host, true) then
            Observer.Observe('part-update-true', 'ok')
        else
            Observer.ObserveError('part-update-true');
        Observer.Expect('part-update-true', 'ok');
        Observer.Verify();
    end;
}
