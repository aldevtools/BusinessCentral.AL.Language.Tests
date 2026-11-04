// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-part-control
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT NeverRan Host (71482), LT NeverRan Part (71481), LT NeverRan Line (71480) from NeverRanFixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: reading Rec of a part (Rec fields, Count, GetFilters) through CurrPage.Lines.Page of a Page variable that never ran, and after it ran and closed; the error text and code when it raises.
// BC versions: 29 (27 and 28 by CI)

codeunit 71483 "LT NeverRan ReadRec"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Line: Record "LT NeverRan Line";
    begin
        Line.DeleteAll();
        Line.Id := 1;
        Line.Name := 'one';
        Line.Insert();
        Line.Id := 2;
        Line.Name := 'two';
        Line.Insert();
    end;

    [TryFunction]
    local procedure TryPartReadRec(var Host: Page "LT NeverRan Host"; var Result: Text)
    begin
        Result := Host.PartReadRec();
    end;

    [TryFunction]
    local procedure TryPartReadCount(var Host: Page "LT NeverRan Host"; var Result: Integer)
    begin
        Result := Host.PartReadCount();
    end;

    [TryFunction]
    local procedure TryPartReadFilters(var Host: Page "LT NeverRan Host"; var Result: Text)
    begin
        Result := Host.PartReadFilters();
    end;

    [ModalPageHandler]
    procedure HostHandler(var TP: TestPage "LT NeverRan Host")
    begin
    end;

    [Test]
    procedure P182b_HostNeverRan_PartReadRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: Page "LT NeverRan Host";
        Result: Text;
    begin
        Seed();
        Observer.Observe('host-own-rec', Host.HostReadRec());
        if TryPartReadRec(Host, Result) then
            Observer.Observe('part-read-rec', Result)
        else
            Observer.ObserveError('part-read-rec');
        Observer.Expect('host-own-rec', 'id=0 name=');
        Observer.Expect('part-read-rec', 'id=0 name=');
        Observer.Verify();
    end;

    [Test]
    procedure P182b_HostNeverRan_PartReadCount()
    var
        Observer: Codeunit "Probe Observer";
        Host: Page "LT NeverRan Host";
        Result: Integer;
    begin
        Seed();
        if TryPartReadCount(Host, Result) then
            Observer.Observe('part-count', Format(Result))
        else
            Observer.ObserveError('part-count');
        Observer.Expect('part-count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P182b_HostNeverRan_PartReadFilters()
    var
        Observer: Codeunit "Probe Observer";
        Host: Page "LT NeverRan Host";
        Result: Text;
    begin
        Seed();
        if TryPartReadFilters(Host, Result) then
            Observer.Observe('part-filters', '[' + Result + ']')
        else
            Observer.ObserveError('part-filters');
        Observer.Expect('part-filters', '[]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HostHandler')]
    procedure P182b_HostRanAndClosed_PartReadRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: Page "LT NeverRan Host";
        Result: Text;
    begin
        Seed();
        Host.RunModal();
        if TryPartReadRec(Host, Result) then
            Observer.Observe('part-read-rec-after-close', Result)
        else
            Observer.ObserveError('part-read-rec-after-close');
        Observer.Expect('part-read-rec-after-close', 'id=1 name=one');
        Observer.Verify();
    end;
}
