// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-caption-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own pages
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CurrPage.Caption read inside a page procedure called through a Page variable before the page runs, while it runs (TestPage.Caption in the handler) and after it closed; a page with a Caption property and a page without; a caption assigned before the run and read back, before, during and after the run.
// BC versions: 29 (27 and 28 by CI)

page 71470 "LT CapRead Static"
{
    PageType = Card;
    Caption = 'LT Static Caption';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(Dummy; DummyText) { ApplicationArea = All; }
            }
        }
    }

    var
        DummyText: Text;

    procedure ReadCaption(): Text
    begin
        exit(CurrPage.Caption);
    end;

    procedure WriteCaption(NewCaption: Text)
    begin
        CurrPage.Caption := NewCaption;
    end;
}

page 71471 "LT CapRead None"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(Dummy; DummyText) { ApplicationArea = All; }
            }
        }
    }

    var
        DummyText: Text;

    procedure ReadCaption(): Text
    begin
        exit(CurrPage.Caption);
    end;

    procedure WriteCaption(NewCaption: Text)
    begin
        CurrPage.Caption := NewCaption;
    end;
}

codeunit 71472 "LT CapRead Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerCaption: Text;

    [TryFunction]
    local procedure TryReadStatic(var Pg: Page "LT CapRead Static"; var Result: Text)
    begin
        Result := Pg.ReadCaption();
    end;

    [TryFunction]
    local procedure TryReadNone(var Pg: Page "LT CapRead None"; var Result: Text)
    begin
        Result := Pg.ReadCaption();
    end;

    [TryFunction]
    local procedure TryWriteStatic(var Pg: Page "LT CapRead Static"; NewCaption: Text)
    begin
        Pg.WriteCaption(NewCaption);
    end;

    [TryFunction]
    local procedure TryWriteNone(var Pg: Page "LT CapRead None"; NewCaption: Text)
    begin
        Pg.WriteCaption(NewCaption);
    end;

    local procedure ReadS(var Observer: Codeunit "Probe Observer"; Name: Text; var Pg: Page "LT CapRead Static")
    var
        Result: Text;
    begin
        if TryReadStatic(Pg, Result) then
            Observer.Observe(Name, '[' + Result + ']')
        else
            Observer.Observe(Name, 'error: ' + GetLastErrorText());
    end;

    local procedure ReadN(var Observer: Codeunit "Probe Observer"; Name: Text; var Pg: Page "LT CapRead None")
    var
        Result: Text;
    begin
        if TryReadNone(Pg, Result) then
            Observer.Observe(Name, '[' + Result + ']')
        else
            Observer.Observe(Name, 'error: ' + GetLastErrorText());
    end;

    local procedure WriteS(var Observer: Codeunit "Probe Observer"; Name: Text; var Pg: Page "LT CapRead Static"; NewCaption: Text)
    begin
        if TryWriteStatic(Pg, NewCaption) then
            Observer.Observe(Name, 'ok')
        else
            Observer.Observe(Name, 'error: ' + GetLastErrorText());
    end;

    local procedure WriteN(var Observer: Codeunit "Probe Observer"; Name: Text; var Pg: Page "LT CapRead None"; NewCaption: Text)
    begin
        if TryWriteNone(Pg, NewCaption) then
            Observer.Observe(Name, 'ok')
        else
            Observer.Observe(Name, 'error: ' + GetLastErrorText());
    end;

    [ModalPageHandler]
    procedure StaticModalHandler(var TP: TestPage "LT CapRead Static")
    begin
        HandlerCaption := TP.Caption();
    end;

    [ModalPageHandler]
    procedure NoneModalHandler(var TP: TestPage "LT CapRead None")
    begin
        HandlerCaption := TP.Caption();
    end;

    [PageHandler]
    procedure StaticPageHandler(var TP: TestPage "LT CapRead Static")
    begin
        HandlerCaption := TP.Caption();
    end;

    [Test]
    [HandlerFunctions('StaticModalHandler')]
    procedure P182b_Static_BeforeRunAfterRunModal()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT CapRead Static";
    begin
        ReadS(Observer, 'before-run', Pg);
        Pg.RunModal();
        Observer.Observe('during-run-testpage', '[' + HandlerCaption + ']');
        ReadS(Observer, 'after-close', Pg);
        Observer.Expect('before-run', '[LT Static Caption]');
        Observer.Expect('during-run-testpage', '[LT Static Caption]');
        Observer.Expect('after-close', '[LT Static Caption]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NoneModalHandler')]
    procedure P182b_NoCaption_BeforeRunAfterRunModal()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT CapRead None";
    begin
        ReadN(Observer, 'before-run', Pg);
        Pg.RunModal();
        Observer.Observe('during-run-testpage', '[' + HandlerCaption + ']');
        ReadN(Observer, 'after-close', Pg);
        Observer.Expect('before-run', '[LT CapRead None]');
        Observer.Expect('during-run-testpage', '[LT CapRead None]');
        Observer.Expect('after-close', '[LT CapRead None]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('StaticPageHandler')]
    procedure P182b_Static_BeforeRunAfterRun()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT CapRead Static";
    begin
        ReadS(Observer, 'before-run', Pg);
        Pg.Run();
        Observer.Observe('during-run-testpage', '[' + HandlerCaption + ']');
        ReadS(Observer, 'after-close', Pg);
        Observer.Expect('before-run', '[LT Static Caption]');
        Observer.Expect('during-run-testpage', '[LT Static Caption]');
        Observer.Expect('after-close', '[LT Static Caption]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('StaticModalHandler')]
    procedure P182b_Static_AssignBeforeRun()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT CapRead Static";
    begin
        WriteS(Observer, 'assign', Pg, 'Assigned Before Run');
        ReadS(Observer, 'read-back-before-run', Pg);
        Pg.RunModal();
        Observer.Observe('during-run-testpage', '[' + HandlerCaption + ']');
        ReadS(Observer, 'after-close', Pg);
        Observer.Expect('assign', 'ok');
        Observer.Expect('read-back-before-run', '[Assigned Before Run]');
        Observer.Expect('during-run-testpage', '[Assigned Before Run]');
        Observer.Expect('after-close', '[Assigned Before Run]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NoneModalHandler')]
    procedure P182b_NoCaption_AssignBeforeRun()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT CapRead None";
    begin
        WriteN(Observer, 'assign', Pg, 'Assigned Before Run');
        ReadN(Observer, 'read-back-before-run', Pg);
        Pg.RunModal();
        Observer.Observe('during-run-testpage', '[' + HandlerCaption + ']');
        ReadN(Observer, 'after-close', Pg);
        Observer.Expect('assign', 'ok');
        Observer.Expect('read-back-before-run', '[Assigned Before Run]');
        Observer.Expect('during-run-testpage', '[Assigned Before Run]');
        Observer.Expect('after-close', '[Assigned Before Run]');
        Observer.Verify();
    end;

    [Test]
    procedure P182b_Static_AssignEmptyBeforeRun_ReadBack()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT CapRead Static";
    begin
        WriteS(Observer, 'assign-empty', Pg, '');
        ReadS(Observer, 'read-back', Pg);
        WriteS(Observer, 'assign-long', Pg, PadStr('x', 300, 'y'));
        ReadS(Observer, 'read-back-length-marker', Pg);
        Observer.Expect('assign-empty', 'ok');
        Observer.Expect('read-back', '[]');
        Observer.Expect('assign-long', 'ok');
        Observer.Expect('read-back-length-marker', '[xyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy]');
        Observer.Verify();
    end;
}
