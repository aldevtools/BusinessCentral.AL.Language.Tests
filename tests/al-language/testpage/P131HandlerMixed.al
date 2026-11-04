// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), P131HandlerFixtures.al (table 73660, pages 73661, 73662), codeunit 73666
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: one [ModalPageHandler] with a TestPage parameter and one with a Page parameter in the same test, each for its own page: which one
//        BC binds to which page, the action RunModal returns, what the TestPage handler reads.
// BC versions: 29 (27 and 28 by CI)

codeunit 73666 "LT P131 Hdl Mixed"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Calls: Text;

    [ModalPageHandler]
    procedure CardTestPageHandler(var CardPage: TestPage "LT P131 Card")
    begin
        Calls += 'testpage=' + Format(CardPage.Name.Value) + ';';
    end;

    [ModalPageHandler]
    procedure ListPageHandler(var ListPage: Page "LT P131 List"; var Response: Action)
    begin
        Calls += 'page;';
        Response := Action::LookupOK;
    end;

    [Test]
    [HandlerFunctions('CardTestPageHandler,ListPageHandler')]
    procedure P131_ModalHandlers_TestPageAndPageParameter()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P131 HRow";
        Card: Page "LT P131 Card";
        List: Page "LT P131 List";
        A1: Action;
        A2: Action;
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Name := 'one';
        Rec.Insert();
        Card.SetRecord(Rec);
        A1 := Card.RunModal();
        Observer.Observe('card action', Format(A1));
        Observer.Observe('calls after card', Calls);
        A2 := List.RunModal();
        Observer.Observe('list action', Format(A2));
        Observer.Observe('calls after list', Calls);
        Observer.Expect('card action', 'OK');
        Observer.Expect('calls after card', 'testpage=one;');
        Observer.Expect('list action', 'LookupOK');
        Observer.Expect('calls after list', 'testpage=one;page;');
        Observer.Verify();
    end;
}
