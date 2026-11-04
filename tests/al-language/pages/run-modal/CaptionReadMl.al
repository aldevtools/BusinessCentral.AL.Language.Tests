// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionml-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own page
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CurrPage.Caption read through a Page variable before the page runs, while it runs and after it closed, for a page with CaptionML only, and after an assignment before the run.
// BC versions: 29 (27 and 28 by CI)

page 71473 "LT CapRead ML"
{
    PageType = Card;
    CaptionML = ENU = 'LT ML Caption';
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

codeunit 71474 "LT CapRead ML Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerCaption: Text;

    [TryFunction]
    local procedure TryRead(var Pg: Page "LT CapRead ML"; var Result: Text)
    begin
        Result := Pg.ReadCaption();
    end;

    [TryFunction]
    local procedure TryWrite(var Pg: Page "LT CapRead ML"; NewCaption: Text)
    begin
        Pg.WriteCaption(NewCaption);
    end;

    local procedure ReadIt(var Observer: Codeunit "Probe Observer"; Name: Text; var Pg: Page "LT CapRead ML")
    var
        Result: Text;
    begin
        if TryRead(Pg, Result) then
            Observer.Observe(Name, '[' + Result + ']')
        else
            Observer.Observe(Name, 'error: ' + GetLastErrorText());
    end;

    [ModalPageHandler]
    procedure MlModalHandler(var TP: TestPage "LT CapRead ML")
    begin
        HandlerCaption := TP.Caption();
    end;

    [Test]
    [HandlerFunctions('MlModalHandler')]
    procedure P182b_Ml_BeforeRunAfterRunModal()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT CapRead ML";
    begin
        ReadIt(Observer, 'before-run', Pg);
        Pg.RunModal();
        Observer.Observe('during-run-testpage', '[' + HandlerCaption + ']');
        ReadIt(Observer, 'after-close', Pg);
        Observer.Expect('before-run', '[LT ML Caption]');
        Observer.Expect('during-run-testpage', '[LT ML Caption]');
        Observer.Expect('after-close', '[LT ML Caption]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MlModalHandler')]
    procedure P182b_Ml_AssignBeforeRun()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT CapRead ML";
    begin
        if TryWrite(Pg, 'Assigned Before Run') then
            Observer.Observe('assign', 'ok')
        else
            Observer.Observe('assign', 'error: ' + GetLastErrorText());
        ReadIt(Observer, 'read-back-before-run', Pg);
        Pg.RunModal();
        Observer.Observe('during-run-testpage', '[' + HandlerCaption + ']');
        ReadIt(Observer, 'after-close', Pg);
        Observer.Expect('assign', 'ok');
        Observer.Expect('read-back-before-run', '[Assigned Before Run]');
        Observer.Expect('during-run-testpage', '[Assigned Before Run]');
        Observer.Expect('after-close', '[Assigned Before Run]');
        Observer.Verify();
    end;
}
