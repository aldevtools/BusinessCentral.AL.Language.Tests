// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); SAE Helper and the reports named in the tests (SaeFixtures.al)
// Probe (al-runner issue 8668): SaveAs of a Word layout report with two top-level data items, for every combination of empty and filled data items (E empty, R rows, in data item order)
// Facts per format (Pdf, Word, Html, Xml): whether SaveAs completed, what it returned, the error text and code, whether the stream holds bytes and its first bytes.
// BC versions: 27 - 29

codeunit 75471 "SAE Two Items Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "SAE Helper";

    [Test]
    procedure Word_EE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 0, 0);
        Helper.AllFormats(Observer, Report::"SAE Word Two");
        Observer.Finish();
    end;

    [Test]
    procedure Word_ER()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 1, 0);
        Helper.AllFormats(Observer, Report::"SAE Word Two");
        Observer.Finish();
    end;

    [Test]
    procedure Word_RE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(1, 0, 0);
        Helper.AllFormats(Observer, Report::"SAE Word Two");
        Observer.Finish();
    end;

    [Test]
    procedure Word_RR()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(1, 1, 0);
        Helper.AllFormats(Observer, Report::"SAE Word Two");
        Observer.Finish();
    end;
}
