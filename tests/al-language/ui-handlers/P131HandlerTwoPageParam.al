// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), P131HandlerFixtures.al (table 73660, pages 73661, 73662), codeunit 73664
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: two [ModalPageHandler] functions in one test whose first parameter is a Page (not a TestPage) of two different pages: which handler
//        BC binds to which page, what the handler is handed (GetRecord of the record passed with SetRecord, the page's own SetResult), the
//        action RunModal returns for Response set to OK / LookupOK, and what the caller's page variable holds afterwards.
// BC versions: 29 (27 and 28 by CI)

codeunit 73664 "LT P131 Hdl Two"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Calls: Text;

    local procedure Seed(var Rec: Record "LT P131 HRow")
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Name := 'one';
        Rec.Insert();
        Rec.Id := 2;
        Rec.Name := 'two';
        Rec.Insert();
    end;

    [ModalPageHandler]
    procedure CardHandler(var CardPage: Page "LT P131 Card"; var Response: Action)
    var
        Rec: Record "LT P131 HRow";
    begin
        Calls += 'card;';
        CardPage.GetRecord(Rec);
        Calls += 'rec=' + Rec.Name + ';';
        CardPage.SetResult(7);
        Response := Action::OK;
    end;

    [ModalPageHandler]
    procedure ListHandler(var ListPage: Page "LT P131 List"; var Response: Action)
    var
        Rec: Record "LT P131 HRow";
    begin
        Calls += 'list;';
        ListPage.GetRecord(Rec);
        Calls += 'rec=' + Rec.Name + ';';
        ListPage.SetResult(9);
        Response := Action::LookupOK;
    end;

    [Test]
    [HandlerFunctions('CardHandler,ListHandler')]
    procedure P131_TwoModalHandlers_PageParameters()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P131 HRow";
        Card: Page "LT P131 Card";
        List: Page "LT P131 List";
        A1: Action;
        A2: Action;
    begin
        Seed(Rec);
        Rec.Get(2);
        Card.SetRecord(Rec);
        A1 := Card.RunModal();
        Observer.Observe('card action', Format(A1));
        Observer.Observe('calls after card', Calls);
        Observer.Observe('card result', Format(Card.GetResult()));
        Observer.Observe('card opened', Format(Card.GetOpened()));
        Rec.Get(1);
        List.SetRecord(Rec);
        A2 := List.RunModal();
        Observer.Observe('list action', Format(A2));
        Observer.Observe('calls after list', Calls);
        Observer.Observe('list result', Format(List.GetResult()));
        Observer.Observe('list opened', Format(List.GetOpened()));
        Observer.Expect('card action', 'OK');
        Observer.Expect('calls after card', 'card;rec=two;');
        Observer.Expect('card result', '7');
        Observer.Expect('card opened', '0');
        Observer.Expect('list action', 'LookupOK');
        Observer.Expect('calls after list', 'card;rec=two;list;rec=one;');
        Observer.Expect('list result', '9');
        Observer.Expect('list opened', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler,ListHandler')]
    procedure P131_TwoModalHandlers_OpenedInTheOtherOrder_AndByStaticRun()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P131 HRow";
        A1: Action;
        A2: Action;
    begin
        Seed(Rec);
        Rec.Get(1);
        A1 := Page.RunModal(Page::"LT P131 List", Rec);
        Observer.Observe('list action', Format(A1));
        Observer.Observe('calls after list', Calls);
        Rec.Get(2);
        A2 := Page.RunModal(Page::"LT P131 Card", Rec);
        Observer.Observe('card action', Format(A2));
        Observer.Observe('calls after card', Calls);
        Observer.Expect('list action', 'LookupOK');
        Observer.Expect('calls after list', 'card;rec=two;list;rec=one;list;rec=one;');
        Observer.Expect('card action', 'OK');
        Observer.Expect('calls after card', 'card;rec=two;list;rec=one;list;rec=one;card;rec=two;');
        Observer.Verify();
    end;
}
