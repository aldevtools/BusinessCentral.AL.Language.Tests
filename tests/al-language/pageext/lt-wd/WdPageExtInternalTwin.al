// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); cross-app fixtures A (page 61132, codeunit 61131) and B (page extension 61148); self-contained codeunit 90795
// Probe: written against al-runner issue 6294 (follow-up to 6043). A page extension in another app declares an internal procedure with the name and parameter types of
//        a public and of a protected procedure of the page it extends. Which procedure runs when the base page's code calls the name, when the extension's code calls it,
//        and through a page variable. Every value asserted below is what the BC service tier produced.
// BC versions: 27, 28, 29

codeunit 90795 "LT WD PageExt Internal Twin"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure WD_PageExtInternal_BaseCodeCallsTheName()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WD XA Log";
        ApplyPage: Page "LT WD XA Apply";
    begin
        Log.Reset();
        ApplyPage.CalcAmount();
        Observer.Observe('log', Log.Get());
        Observer.Finish();
    end;

    [Test]
    procedure WD_PageExtInternal_ExtensionCodeCallsTheName()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WD XA Log";
        ApplyPage: Page "LT WD XA Apply";
    begin
        Log.Reset();
        ApplyPage.CallFromExt();
        Observer.Observe('log', Log.Get());
        Observer.Finish();
    end;

    [Test]
    procedure WD_PageExtInternal_PageVariableCallsThePublicName()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WD XA Log";
        ApplyPage: Page "LT WD XA Apply";
    begin
        Log.Reset();
        ApplyPage.CheckRounding();
        Observer.Observe('log', Log.Get());
        Observer.Finish();
    end;
}
