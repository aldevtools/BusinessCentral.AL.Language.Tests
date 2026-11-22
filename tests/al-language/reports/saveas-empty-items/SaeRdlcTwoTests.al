// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); SAE Helper and the reports named in the tests (SaeFixtures.al)
// Probe (al-runner issue 8668): the RDLC layout with two top-level data items, for contrast
// Facts per format (Pdf, Word, Html, Xml): whether SaveAs completed, what it returned, the error text and code, whether the stream holds bytes and its first bytes.
// BC versions: 27 - 29
// Results (BC 27.5, 28.5, 29.0 identical): an RDLC report with two empty items does not raise for Pdf and Word (bytes absent); Html raises ReportUnsupportedFormat in every row state; Xml succeeds.

codeunit 75473 "SAE Rdlc Two Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "SAE Helper";

    [Test]
    procedure Rdlc_EE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 0, 0);
        Helper.AllFormats(Observer, Report::"SAE Rdlc Two");
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf length > 0', 'No');
        Observer.Expect('pdf head', 'empty');
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('word length > 0', 'No');
        Observer.Expect('word head', 'empty');
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'No');
        Observer.Expect('html err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('html err|code', 'ReportUnsupportedFormat');
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
    procedure Rdlc_ER()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 1, 0);
        Helper.AllFormats(Observer, Report::"SAE Rdlc Two");
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
        Observer.Expect('html returned', 'No');
        Observer.Expect('html err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('html err|code', 'ReportUnsupportedFormat');
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
    procedure Rdlc_RE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(1, 0, 0);
        Helper.AllFormats(Observer, Report::"SAE Rdlc Two");
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
        Observer.Expect('html returned', 'No');
        Observer.Expect('html err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('html err|code', 'ReportUnsupportedFormat');
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
    procedure Rdlc_RR()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(1, 1, 0);
        Helper.AllFormats(Observer, Report::"SAE Rdlc Two");
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
        Observer.Expect('html returned', 'No');
        Observer.Expect('html err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('html err|code', 'ReportUnsupportedFormat');
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
}
