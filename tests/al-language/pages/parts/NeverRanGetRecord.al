// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-part-control
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT NeverRan Host (71482), LT NeverRan Part (71481), LT NeverRan Line (71480) from NeverRanFixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CurrPage.GetRecord and CurrPage.Editable in a part procedure called through CurrPage.Lines.Page of a Page variable that never ran.
// BC versions: 29 (27 and 28 by CI)

codeunit 71486 "LT NeverRan GetRecord"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryPartGetRecord(var Host: Page "LT NeverRan Host"; var Result: Text)
    begin
        Result := Host.PartGetRecord();
    end;

    [TryFunction]
    local procedure TryPartEditable(var Host: Page "LT NeverRan Host"; var Result: Boolean)
    begin
        Result := Host.PartEditable();
    end;

    [Test]
    procedure P182b_HostNeverRan_PartGetRecord()
    var
        Observer: Codeunit "Probe Observer";
        Host: Page "LT NeverRan Host";
        Result: Text;
    begin
        if TryPartGetRecord(Host, Result) then
            Observer.Observe('part-get-record', Result)
        else
            Observer.ObserveError('part-get-record');
        Observer.Expect('part-get-record', 'id=0 name=');
        Observer.Verify();
    end;

    [Test]
    procedure P182b_HostNeverRan_PartEditable()
    var
        Observer: Codeunit "Probe Observer";
        Host: Page "LT NeverRan Host";
        Result: Boolean;
    begin
        if TryPartEditable(Host, Result) then
            Observer.Observe('part-editable', Format(Result))
        else
            Observer.ObserveError('part-editable');
        Observer.Expect('part-editable', 'Yes');
        Observer.Verify();
    end;
}
