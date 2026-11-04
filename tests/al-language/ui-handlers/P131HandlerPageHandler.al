// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), P131HandlerFixtures.al (table 73660, page 73663), codeunit 73667
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a [PageHandler] function whose parameter is a Page (no Response): when Page.Run / Run on the instance reaches it, what it is handed
//        (GetRecord of the record passed with SetRecord, the page's own SetResult and the caller's variable afterwards), and the OnOpenPage count.
// BC versions: 29 (27 and 28 by CI)

codeunit 73667 "LT P131 Hdl PageHandler"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Calls: Text;

    [PageHandler]
    procedure NavHandler(var NavPage: Page "LT P131 Nav")
    var
        Rec: Record "LT P131 HRow";
    begin
        Calls += 'nav;';
        NavPage.GetRecord(Rec);
        Calls += 'rec=' + Rec.Name + ';';
        NavPage.SetResult(5);
    end;

    [Test]
    [HandlerFunctions('NavHandler')]
    procedure P131_PageHandler_PageParam_InstanceRun()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P131 HRow";
        Nav: Page "LT P131 Nav";
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Name := 'one';
        Rec.Insert();
        Nav.SetRecord(Rec);
        Nav.Run();
        Observer.Observe('calls', Calls);
        Observer.Observe('result', Format(Nav.GetResult()));
        Observer.Observe('opened', Format(Nav.GetOpened()));
        Observer.Expect('calls', 'nav;rec=one;');
        Observer.Expect('result', '0');
        Observer.Expect('opened', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NavHandler')]
    procedure P131_PageHandler_PageParam_StaticRun()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P131 HRow";
    begin
        Rec.DeleteAll();
        Rec.Id := 2;
        Rec.Name := 'two';
        Rec.Insert();
        Page.Run(Page::"LT P131 Nav", Rec);
        Observer.Observe('calls', Calls);
        Observer.Expect('calls', 'nav;rec=one;nav;rec=two;');
        Observer.Verify();
    end;
}
