// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modalpagehandler-attribute
// Scope: in-scope
// Fixtures used: P130Fixtures.al (table 73536, log 73538, pages 73539 and 73540), Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: two handler functions of the SAME kind in one [HandlerFunctions] list, each for another page: which one answers which page, with TestPage parameters,
//   with Page parameters, mixed, for [ModalPageHandler] and for [PageHandler]; each page is opened in both orders (so the order of the list or of the declaration cannot explain it)
// Settles issue 130 reasons 2, 10, 18, 26, 35 (two Page / ModalPage handlers: which one BC binds)
// BC versions: 29 (27 and 28 by CI)

codeunit 73544 "LT P130 Handler Pairs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // ---- ModalPageHandler, TestPage parameters ----

    [ModalPageHandler]
    procedure HandlerA_TestPage(var P: TestPage "LT P130 List A")
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('HA_TestPage');
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure HandlerB_TestPage(var P: TestPage "LT P130 List B")
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('HB_TestPage');
        P.OK().Invoke();
    end;

    // ---- ModalPageHandler, Page parameters ----

    [ModalPageHandler]
    procedure HandlerA_Page(var P: Page "LT P130 List A"; var Response: Action)
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('HA_Page');
        Response := Action::LookupOK;
    end;

    [ModalPageHandler]
    procedure HandlerB_Page(var P: Page "LT P130 List B"; var Response: Action)
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('HB_Page');
        Response := Action::LookupOK;
    end;

    // ---- PageHandler (not modal), Page parameters ----

    [PageHandler]
    procedure PlainA_Page(var P: Page "LT P130 List A")
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('PA_Page');
    end;

    [PageHandler]
    procedure PlainB_Page(var P: Page "LT P130 List B")
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('PB_Page');
    end;

    local procedure ModalA(): Text
    var
        PgA: Page "LT P130 List A";
    begin
        PgA.LookupMode(true);
        exit(Format(PgA.RunModal()));
    end;

    local procedure ModalB(): Text
    var
        PgB: Page "LT P130 List B";
    begin
        PgB.LookupMode(true);
        exit(Format(PgB.RunModal()));
    end;

    [Test]
    [HandlerFunctions('HandlerA_TestPage,HandlerB_TestPage')]
    procedure P130_Modal_TestPagePair_AThenB()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
    begin
        Log.Seed();
        Observer.Observe('result_a', ModalA());
        Observer.Observe('log_after_a', Log.Take());
        Observer.Observe('result_b', ModalB());
        Observer.Observe('log_after_b', Log.Take());
        Observer.Expect('result_a', 'LookupOK');
        Observer.Expect('log_after_a', 'HA_TestPage;');
        Observer.Expect('result_b', 'LookupOK');
        Observer.Expect('log_after_b', 'HB_TestPage;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerA_TestPage,HandlerB_TestPage')]
    procedure P130_Modal_TestPagePair_BThenA()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
    begin
        Log.Seed();
        Observer.Observe('result_b', ModalB());
        Observer.Observe('log_after_b', Log.Take());
        Observer.Observe('result_a', ModalA());
        Observer.Observe('log_after_a', Log.Take());
        Observer.Expect('result_b', 'LookupOK');
        Observer.Expect('log_after_b', 'HB_TestPage;');
        Observer.Expect('result_a', 'LookupOK');
        Observer.Expect('log_after_a', 'HA_TestPage;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerB_TestPage,HandlerA_TestPage')]
    procedure P130_Modal_TestPagePair_ListOrderReversed()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
    begin
        Log.Seed();
        Observer.Observe('result_a', ModalA());
        Observer.Observe('log_after_a', Log.Take());
        Observer.Observe('result_b', ModalB());
        Observer.Observe('log_after_b', Log.Take());
        Observer.Expect('result_a', 'LookupOK');
        Observer.Expect('log_after_a', 'HA_TestPage;');
        Observer.Expect('result_b', 'LookupOK');
        Observer.Expect('log_after_b', 'HB_TestPage;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerA_Page,HandlerB_Page')]
    procedure P130_Modal_PagePair_AThenB()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
    begin
        Log.Seed();
        Observer.Observe('result_a', ModalA());
        Observer.Observe('log_after_a', Log.Take());
        Observer.Observe('result_b', ModalB());
        Observer.Observe('log_after_b', Log.Take());
        Observer.Expect('result_a', 'LookupOK');
        Observer.Expect('log_after_a', 'HA_Page;');
        Observer.Expect('result_b', 'LookupOK');
        Observer.Expect('log_after_b', 'HB_Page;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerA_Page,HandlerB_Page')]
    procedure P130_Modal_PagePair_BThenA()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
    begin
        Log.Seed();
        Observer.Observe('result_b', ModalB());
        Observer.Observe('log_after_b', Log.Take());
        Observer.Observe('result_a', ModalA());
        Observer.Observe('log_after_a', Log.Take());
        Observer.Expect('result_b', 'LookupOK');
        Observer.Expect('log_after_b', 'HB_Page;');
        Observer.Expect('result_a', 'LookupOK');
        Observer.Expect('log_after_a', 'HA_Page;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerA_TestPage,HandlerB_Page')]
    procedure P130_Modal_Mixed_TestPageForA_PageForB()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
    begin
        Log.Seed();
        Observer.Observe('result_b', ModalB());
        Observer.Observe('log_after_b', Log.Take());
        Observer.Observe('result_a', ModalA());
        Observer.Observe('log_after_a', Log.Take());
        Observer.Expect('result_b', 'LookupOK');
        Observer.Expect('log_after_b', 'HB_Page;');
        Observer.Expect('result_a', 'LookupOK');
        Observer.Expect('log_after_a', 'HA_TestPage;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerA_Page,HandlerB_TestPage')]
    procedure P130_Modal_Mixed_PageForA_TestPageForB()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
    begin
        Log.Seed();
        Observer.Observe('result_a', ModalA());
        Observer.Observe('log_after_a', Log.Take());
        Observer.Observe('result_b', ModalB());
        Observer.Observe('log_after_b', Log.Take());
        Observer.Expect('result_a', 'LookupOK');
        Observer.Expect('log_after_a', 'HA_Page;');
        Observer.Expect('result_b', 'LookupOK');
        Observer.Expect('log_after_b', 'HB_TestPage;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PlainA_Page,PlainB_Page')]
    procedure P130_Plain_PagePair_AThenB()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
    begin
        Log.Seed();
        Page.Run(Page::"LT P130 List A");
        Observer.Observe('log_after_a', Log.Take());
        Page.Run(Page::"LT P130 List B");
        Observer.Observe('log_after_b', Log.Take());
        Observer.Expect('log_after_a', 'PA_Page;');
        Observer.Expect('log_after_b', 'PB_Page;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PlainA_Page,PlainB_Page')]
    procedure P130_Plain_PagePair_BThenA()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
    begin
        Log.Seed();
        Page.Run(Page::"LT P130 List B");
        Observer.Observe('log_after_b', Log.Take());
        Page.Run(Page::"LT P130 List A");
        Observer.Observe('log_after_a', Log.Take());
        Observer.Expect('log_after_b', 'PB_Page;');
        Observer.Expect('log_after_a', 'PA_Page;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PlainB_Page,PlainA_Page')]
    procedure P130_Plain_PagePair_ListOrderReversed_SamePageTwice()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
    begin
        Log.Seed();
        Page.Run(Page::"LT P130 List A");
        Page.Run(Page::"LT P130 List B");
        Observer.Observe('log_a_then_b', Log.Take());
        Page.Run(Page::"LT P130 List A");
        Observer.Observe('log_a_again', Log.Take());
        Observer.Expect('log_a_then_b', 'PA_Page;PB_Page;');
        Observer.Expect('log_a_again', 'PA_Page;');
        Observer.Verify();
    end;
}
