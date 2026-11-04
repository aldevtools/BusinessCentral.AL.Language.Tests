// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-part-control
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT NeverRan Host (71482), LT NeverRan Part (71481), LT NeverRan Line (71480) from NeverRanFixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CurrPage.SetRecord in a part procedure called through CurrPage.Lines.Page of a Page variable that never ran, then CurrPage.GetRecord; ok, the value or the error text and code.
// BC versions: 29 (27 and 28 by CI)

codeunit 71485 "LT NeverRan SetRecord"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryPartSetRecord(var Host: Page "LT NeverRan Host"; LineId: Integer)
    begin
        Host.PartSetRecord(LineId);
    end;

    [TryFunction]
    local procedure TryPartGetRecord(var Host: Page "LT NeverRan Host"; var Result: Text)
    begin
        Result := Host.PartGetRecord();
    end;

    [Test]
    procedure P182b_HostNeverRan_PartSetRecord()
    var
        Observer: Codeunit "Probe Observer";
        Host: Page "LT NeverRan Host";
        Line: Record "LT NeverRan Line";
        Result: Text;
    begin
        Line.DeleteAll();
        Line.Id := 7;
        Line.Name := 'seven';
        Line.Insert();
        if TryPartSetRecord(Host, 7) then
            Observer.Observe('part-set-record', 'ok')
        else
            Observer.ObserveError('part-set-record');
        if TryPartGetRecord(Host, Result) then
            Observer.Observe('part-get-record-after-set', Result)
        else
            Observer.ObserveError('part-get-record-after-set');
        Observer.Expect('part-set-record', 'ok');
        Observer.Expect('part-get-record-after-set', 'id=7 name=seven');
        Observer.Verify();
    end;
}
