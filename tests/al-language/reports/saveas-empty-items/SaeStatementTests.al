// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); SAE Stmt Helper and the reports named in the tests (SaeStatementFixtures.al, SaeFixtures.al)
// Probe (al-runner issue 8668): Report.SaveAs called as a statement (no return value used) on reports with several top-level data items and no row. The first probe measured the used form.
// Facts per format: whether the statement completed or raised, the error text and code, whether the stream holds bytes and its first bytes.
// BC versions: 27 - 29

codeunit 75481 "SAE Statement Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "SAE Helper";
        Stmt: Codeunit "SAE Stmt Helper";

    [Test]
    procedure Word_EE_Statement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 0, 0);
        Stmt.StatementAllFormats(Observer, Report::"SAE Word Two");
        Observer.Finish();
    end;

    [Test]
    procedure Word_EEE_Statement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 0, 0);
        Stmt.StatementAllFormats(Observer, Report::"SAE Word Three");
        Observer.Finish();
    end;

    [Test]
    procedure Word_ER_Statement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 1, 0);
        Stmt.StatementAllFormats(Observer, Report::"SAE Word Two");
        Observer.Finish();
    end;

    [Test]
    procedure Word_BreakBoth_Statement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Stmt.StatementAllFormats(Observer, Report::"SAE Word Break");
        Observer.Finish();
    end;

    [Test]
    procedure Word_BreakFirst_Statement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Stmt.StatementAllFormats(Observer, Report::"SAE Word Break First");
        Observer.Finish();
    end;

    [Test]
    procedure Word_EE_Asserterror_Pdf()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Helper.Fill(0, 0, 0);
        TempBlob.CreateOutStream(OutS);
        asserterror Report.SaveAs(Report::"SAE Word Two", '', ReportFormat::Pdf, OutS);
        Observer.ObserveError('pdf');
        Observer.Observe('length', Format(TempBlob.Length()));
        Observer.Finish();
    end;

    [Test]
    procedure Labels_EE_Pdf_Used()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 0, 0);
        Stmt.UsedFacts(Observer, 'pdf', Report::"SAE Word Labels", ReportFormat::Pdf);
        Observer.Finish();
    end;

    [Test]
    procedure Labels_EE_Pdf_Statement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 0, 0);
        Stmt.StatementFacts(Observer, 'pdf', Report::"SAE Word Labels", ReportFormat::Pdf);
        Observer.Finish();
    end;

    [Test]
    procedure ReqPage_EE_Pdf_Used()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 0, 0);
        Stmt.UsedFacts(Observer, 'pdf', Report::"SAE Word ReqPage", ReportFormat::Pdf);
        Observer.Finish();
    end;

    [Test]
    procedure ReqPage_EE_Pdf_Statement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 0, 0);
        Stmt.StatementFacts(Observer, 'pdf', Report::"SAE Word ReqPage", ReportFormat::Pdf);
        Observer.Finish();
    end;
}
