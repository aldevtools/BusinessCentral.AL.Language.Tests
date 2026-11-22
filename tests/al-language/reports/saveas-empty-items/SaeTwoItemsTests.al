// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); SAE Helper and the reports named in the tests (SaeFixtures.al)
// Probe (al-runner issue 8668): SaveAs of a Word layout report with two top-level data items, for every combination of empty and filled data items (E empty, R rows, in data item order)
// Facts per format (Pdf, Word, Html, Xml): whether SaveAs completed, what it returned, the error text and code, whether the stream holds bytes and its first bytes.
// BC versions: 27 - 29
// Results (BC 27.5, 28.5, 29.0 identical): both data items empty: Pdf, Word and Html raise ReportResultEmpty and return nothing; Xml succeeds with bytes. One or both items with rows: every format succeeds.

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
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'No');
        Observer.Expect('pdf err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('pdf err|code', 'ReportResultEmpty');
        Observer.Expect('pdf length > 0', 'No');
        Observer.Expect('pdf head', 'empty');
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'No');
        Observer.Expect('word err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('word err|code', 'ReportResultEmpty');
        Observer.Expect('word length > 0', 'No');
        Observer.Expect('word head', 'empty');
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'No');
        Observer.Expect('html err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('html err|code', 'ReportResultEmpty');
        Observer.Expect('html length > 0', 'No');
        Observer.Expect('html head', 'empty');
        Observer.Expect('xml completed', 'Yes');
        Observer.Expect('xml returned', 'Yes');
        Observer.Expect('xml err|text', '');
        Observer.Expect('xml err|code', '');
        Observer.Expect('xml length > 0', 'Yes');
        Observer.Expect('xml head', 'Ù,‹,,<,');
        Observer.Verify();
    end;

    [Test]
    procedure Word_ER()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 1, 0);
        Helper.AllFormats(Observer, Report::"SAE Word Two");
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf length > 0', 'Yes');
        Observer.Expect('pdf head', '%,P,D,F,');
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('word length > 0', 'Yes');
        Observer.Expect('word head', 'P,K,\u0003,\u0004,');
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'Yes');
        Observer.Expect('html err|text', '');
        Observer.Expect('html err|code', '');
        Observer.Expect('html length > 0', 'Yes');
        Observer.Expect('html head', '<,h,t,m,');
        Observer.Expect('xml completed', 'Yes');
        Observer.Expect('xml returned', 'Yes');
        Observer.Expect('xml err|text', '');
        Observer.Expect('xml err|code', '');
        Observer.Expect('xml length > 0', 'Yes');
        Observer.Expect('xml head', 'Ù,‹,,<,');
        Observer.Verify();
    end;

    [Test]
    procedure Word_RE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(1, 0, 0);
        Helper.AllFormats(Observer, Report::"SAE Word Two");
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf length > 0', 'Yes');
        Observer.Expect('pdf head', '%,P,D,F,');
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('word length > 0', 'Yes');
        Observer.Expect('word head', 'P,K,\u0003,\u0004,');
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'Yes');
        Observer.Expect('html err|text', '');
        Observer.Expect('html err|code', '');
        Observer.Expect('html length > 0', 'Yes');
        Observer.Expect('html head', '<,h,t,m,');
        Observer.Expect('xml completed', 'Yes');
        Observer.Expect('xml returned', 'Yes');
        Observer.Expect('xml err|text', '');
        Observer.Expect('xml err|code', '');
        Observer.Expect('xml length > 0', 'Yes');
        Observer.Expect('xml head', 'Ù,‹,,<,');
        Observer.Verify();
    end;

    [Test]
    procedure Word_RR()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(1, 1, 0);
        Helper.AllFormats(Observer, Report::"SAE Word Two");
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf length > 0', 'Yes');
        Observer.Expect('pdf head', '%,P,D,F,');
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('word length > 0', 'Yes');
        Observer.Expect('word head', 'P,K,\u0003,\u0004,');
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'Yes');
        Observer.Expect('html err|text', '');
        Observer.Expect('html err|code', '');
        Observer.Expect('html length > 0', 'Yes');
        Observer.Expect('html head', '<,h,t,m,');
        Observer.Expect('xml completed', 'Yes');
        Observer.Expect('xml returned', 'Yes');
        Observer.Expect('xml err|text', '');
        Observer.Expect('xml err|code', '');
        Observer.Expect('xml length > 0', 'Yes');
        Observer.Expect('xml head', 'Ù,‹,,<,');
        Observer.Verify();
    end;
}
