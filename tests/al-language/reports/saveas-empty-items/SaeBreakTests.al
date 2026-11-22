// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); SAE Helper and the reports named in the tests (SaeFixtures.al)
// Probe (al-runner issue 8668): the issue shape: Word layout, two top-level data items over Integer that stop in OnPreDataItem with CurrReport.Break()
// Facts per format (Pdf, Word, Html, Xml): whether SaveAs completed, what it returned, the error text and code, whether the stream holds bytes and its first bytes.
// BC versions: 27 - 29

codeunit 75474 "SAE Break Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "SAE Helper";

    [Test]
    procedure Word_BreakBoth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.AllFormats(Observer, Report::"SAE Word Break");
        Observer.Finish();
    end;

    [Test]
    procedure Word_BreakFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.AllFormats(Observer, Report::"SAE Word Break First");
        Observer.Finish();
    end;

    [Test]
    procedure Word_BreakSecond()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.AllFormats(Observer, Report::"SAE Word Break Second");
        Observer.Finish();
    end;
}
