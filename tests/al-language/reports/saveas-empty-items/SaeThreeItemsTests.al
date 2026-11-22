// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); SAE Helper and the reports named in the tests (SaeFixtures.al)
// Probe (al-runner issue 8668): the same with three top-level data items
// Facts per format (Pdf, Word, Html, Xml): whether SaveAs completed, what it returned, the error text and code, whether the stream holds bytes and its first bytes.
// BC versions: 27 - 29

codeunit 75472 "SAE Three Items Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "SAE Helper";

    [Test]
    procedure Word_EEE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 0, 0);
        Helper.AllFormats(Observer, Report::"SAE Word Three");
        Observer.Finish();
    end;

    [Test]
    procedure Word_REE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(1, 0, 0);
        Helper.AllFormats(Observer, Report::"SAE Word Three");
        Observer.Finish();
    end;

    [Test]
    procedure Word_ERE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 1, 0);
        Helper.AllFormats(Observer, Report::"SAE Word Three");
        Observer.Finish();
    end;

    [Test]
    procedure Word_EER()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 0, 1);
        Helper.AllFormats(Observer, Report::"SAE Word Three");
        Observer.Finish();
    end;

    [Test]
    procedure Word_RRR()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(1, 1, 1);
        Helper.AllFormats(Observer, Report::"SAE Word Three");
        Observer.Finish();
    end;
}
