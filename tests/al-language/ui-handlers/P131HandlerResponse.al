// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), P131HandlerFixtures.al (table 73660, pages 73661, 73662, 73663), codeunit 73665
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the action RunModal returns when a [ModalPageHandler] with a Page parameter leaves Response untouched, sets it to Yes, or Cancel
//        (Yes is what Microsoft's handlers use); the caller's page variable afterwards.
// BC versions: 29 (27 and 28 by CI)

codeunit 73665 "LT P131 Hdl Resp"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Calls: Text;

    [ModalPageHandler]
    procedure YesHandler(var CardPage: Page "LT P131 Card"; var Response: Action)
    begin
        Calls += 'yes;';
        Response := Action::Yes;
    end;

    [ModalPageHandler]
    procedure UntouchedHandler(var ListPage: Page "LT P131 List"; var Response: Action)
    begin
        Calls += 'untouched;';
    end;

    [ModalPageHandler]
    procedure CancelHandler(var NavPage: Page "LT P131 Nav"; var Response: Action)
    begin
        Calls += 'cancel;';
        Response := Action::Cancel;
    end;

    [Test]
    [HandlerFunctions('YesHandler,UntouchedHandler,CancelHandler')]
    procedure P131_ModalPageHandler_PageParam_ResponseValues()
    var
        Observer: Codeunit "Probe Observer";
        Card: Page "LT P131 Card";
        List: Page "LT P131 List";
        Nav: Page "LT P131 Nav";
    begin
        Observer.Observe('yes', Format(Card.RunModal()));
        Observer.Observe('untouched', Format(List.RunModal()));
        Observer.Observe('cancel', Format(Nav.RunModal()));
        Observer.Observe('calls', Calls);
        Observer.Observe('card opened', Format(Card.GetOpened()));
        Observer.Observe('list opened', Format(List.GetOpened()));
        Observer.Observe('nav opened', Format(Nav.GetOpened()));
        Observer.Expect('yes', 'Yes');
        Observer.Expect('untouched', 'None');
        Observer.Expect('cancel', 'Cancel');
        Observer.Expect('calls', 'yes;untouched;cancel;');
        Observer.Expect('card opened', '0');
        Observer.Expect('list opened', '0');
        Observer.Expect('nav opened', '0');
        Observer.Verify();
    end;
}
