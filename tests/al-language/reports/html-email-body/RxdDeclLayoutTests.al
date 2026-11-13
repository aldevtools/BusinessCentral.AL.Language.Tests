// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); RXD Row, RXD Decl Word and RXD Decl Helper of RxdDeclFixtures.al (80040 - 80042); test codeunit 80043
// Probe (al-runner issue 6924): Report.SaveAs as Html, Word and Pdf into a Temp Blob for a report declared as the reporter's report is
//   (WordLayout and RDLCLayout, DefaultLayout = Word, no rendering section, one data item, no triggers, no request page), with two rows.
//   Stored state: no Report Layout Selection row; an RDLC (built-in) row of the company; an RDLC (built-in) row with an empty Company
//   Name; both; a Word (built-in) row of the company (Custom Report Layout Code empty in every row). Each state alone, with a temporary
//   selection of a GUID-named Tenant Report Layout (SetTempLayoutSelectedName), and with SetTempLayoutSelected(''). The temporary
//   selection is set again before each call. Asked: the answer used (TryFunction result, return value, error text and code, length > 0,
//   HasValue, which layout's marker the output holds, the first bytes) and the statement form (completed, error, length, marker), and the
//   temporary layout name after the call.
// BC versions: 27 - 29

codeunit 80043 "RXD Decl Layout Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "RXD Decl Helper";

    local procedure Setup(State: Integer; Mode: Integer)
    begin
        Helper.Cleanup();
        Helper.Rows(2);
        Helper.StoreState(State);
        if Mode = 1 then
            Helper.InsertTenantLayout();
    end;

    local procedure OutputFacts(var Observer: Codeunit "Probe Observer"; Name: Text; Fmt: ReportFormat; var TempBlob: Codeunit "Temp Blob")
    var
        Content: Text;
    begin
        Observer.Observe(Name + ' length > 0', Format(TempBlob.Length() > 0));
        Observer.Observe(Name + ' has value', Format(TempBlob.HasValue()));
        case Fmt of
            ReportFormat::Html:
                begin
                    Content := Helper.BodyText(TempBlob);
                    Observer.Observe(Name + ' starts <html', Format(LowerCase(CopyStr(Content, 1, 5)) = '<html'));
                    Observer.Observe(Name + ' has RXDROW1', Format(StrPos(Content, 'RXDROW1') > 0));
                end;
            ReportFormat::Word:
                begin
                    Observer.Observe(Name + ' first bytes', Helper.FirstBytes(TempBlob));
                    Content := Helper.WordDocumentText(TempBlob);
                    Observer.Observe(Name + ' has RXDROW1', Format(StrPos(Content, 'RXDROW1') > 0));
                end;
            ReportFormat::Pdf:
                Observer.Observe(Name + ' first bytes', Helper.FirstBytes(TempBlob));
        end;
        if Fmt <> ReportFormat::Pdf then
            Observer.Observe(Name + ' marker', Helper.Markers(Content));
    end;

    local procedure UsedFacts(var Observer: Codeunit "Probe Observer"; Fmt: ReportFormat; Mode: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        Completed: Boolean;
        Ok: Boolean;
    begin
        Helper.SetTemp(Mode);
        ClearLastError();
        Completed := Helper.TrySave(Fmt, TempBlob, Ok);
        Observer.Observe('used completed', Format(Completed));
        Observer.Observe('used returned', Format(Ok));
        Observer.ObserveError('used err');
        OutputFacts(Observer, 'used', Fmt, TempBlob);
        Observer.Observe('used temp name after', Helper.TempNameAfter());
    end;

    local procedure StatementFacts(var Observer: Codeunit "Probe Observer"; Fmt: ReportFormat; Mode: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        Completed: Boolean;
    begin
        Helper.SetTemp(Mode);
        ClearLastError();
        Completed := Helper.TrySaveStatement(Fmt, TempBlob);
        Observer.Observe('stmt completed', Format(Completed));
        Observer.ObserveError('stmt err');
        Observer.Observe('stmt length > 0', Format(TempBlob.Length() > 0));
        if Fmt <> ReportFormat::Pdf then
            if Fmt = ReportFormat::Html then
                Observer.Observe('stmt marker', Helper.Markers(Helper.BodyText(TempBlob)))
            else
                Observer.Observe('stmt marker', Helper.Markers(Helper.WordDocumentText(TempBlob)));
    end;

    [Test]
    procedure SaveAs_NoRow_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 0);
        UsedFacts(Observer, ReportFormat::Html, 0);
        StatementFacts(Observer, ReportFormat::Html, 0);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_NoRow_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 0);
        UsedFacts(Observer, ReportFormat::Word, 0);
        StatementFacts(Observer, ReportFormat::Word, 0);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_NoRow_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 0);
        UsedFacts(Observer, ReportFormat::Pdf, 0);
        StatementFacts(Observer, ReportFormat::Pdf, 0);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_NoRow_TempGuid_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 1);
        UsedFacts(Observer, ReportFormat::Html, 1);
        StatementFacts(Observer, ReportFormat::Html, 1);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_NoRow_TempGuid_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 1);
        UsedFacts(Observer, ReportFormat::Word, 1);
        StatementFacts(Observer, ReportFormat::Word, 1);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_NoRow_TempGuid_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 1);
        UsedFacts(Observer, ReportFormat::Pdf, 1);
        StatementFacts(Observer, ReportFormat::Pdf, 1);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_NoRow_TempEmpty_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 2);
        UsedFacts(Observer, ReportFormat::Html, 2);
        StatementFacts(Observer, ReportFormat::Html, 2);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_NoRow_TempEmpty_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 2);
        UsedFacts(Observer, ReportFormat::Word, 2);
        StatementFacts(Observer, ReportFormat::Word, 2);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_NoRow_TempEmpty_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 2);
        UsedFacts(Observer, ReportFormat::Pdf, 2);
        StatementFacts(Observer, ReportFormat::Pdf, 2);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcCompany_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 0);
        UsedFacts(Observer, ReportFormat::Html, 0);
        StatementFacts(Observer, ReportFormat::Html, 0);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcCompany_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 0);
        UsedFacts(Observer, ReportFormat::Word, 0);
        StatementFacts(Observer, ReportFormat::Word, 0);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcCompany_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 0);
        UsedFacts(Observer, ReportFormat::Pdf, 0);
        StatementFacts(Observer, ReportFormat::Pdf, 0);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcCompany_TempGuid_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 1);
        UsedFacts(Observer, ReportFormat::Html, 1);
        StatementFacts(Observer, ReportFormat::Html, 1);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcCompany_TempGuid_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 1);
        UsedFacts(Observer, ReportFormat::Word, 1);
        StatementFacts(Observer, ReportFormat::Word, 1);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcCompany_TempGuid_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 1);
        UsedFacts(Observer, ReportFormat::Pdf, 1);
        StatementFacts(Observer, ReportFormat::Pdf, 1);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcCompany_TempEmpty_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 2);
        UsedFacts(Observer, ReportFormat::Html, 2);
        StatementFacts(Observer, ReportFormat::Html, 2);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcCompany_TempEmpty_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 2);
        UsedFacts(Observer, ReportFormat::Word, 2);
        StatementFacts(Observer, ReportFormat::Word, 2);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcCompany_TempEmpty_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 2);
        UsedFacts(Observer, ReportFormat::Pdf, 2);
        StatementFacts(Observer, ReportFormat::Pdf, 2);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcEmptyCompany_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(2, 0);
        UsedFacts(Observer, ReportFormat::Html, 0);
        StatementFacts(Observer, ReportFormat::Html, 0);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcEmptyCompany_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(2, 0);
        UsedFacts(Observer, ReportFormat::Word, 0);
        StatementFacts(Observer, ReportFormat::Word, 0);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcEmptyCompany_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(2, 0);
        UsedFacts(Observer, ReportFormat::Pdf, 0);
        StatementFacts(Observer, ReportFormat::Pdf, 0);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcEmptyCompany_TempGuid_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(2, 1);
        UsedFacts(Observer, ReportFormat::Html, 1);
        StatementFacts(Observer, ReportFormat::Html, 1);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcEmptyCompany_TempGuid_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(2, 1);
        UsedFacts(Observer, ReportFormat::Word, 1);
        StatementFacts(Observer, ReportFormat::Word, 1);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcEmptyCompany_TempGuid_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(2, 1);
        UsedFacts(Observer, ReportFormat::Pdf, 1);
        StatementFacts(Observer, ReportFormat::Pdf, 1);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcEmptyCompany_TempEmpty_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(2, 2);
        UsedFacts(Observer, ReportFormat::Html, 2);
        StatementFacts(Observer, ReportFormat::Html, 2);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcEmptyCompany_TempEmpty_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(2, 2);
        UsedFacts(Observer, ReportFormat::Word, 2);
        StatementFacts(Observer, ReportFormat::Word, 2);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcEmptyCompany_TempEmpty_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(2, 2);
        UsedFacts(Observer, ReportFormat::Pdf, 2);
        StatementFacts(Observer, ReportFormat::Pdf, 2);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcBoth_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(3, 0);
        UsedFacts(Observer, ReportFormat::Html, 0);
        StatementFacts(Observer, ReportFormat::Html, 0);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcBoth_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(3, 0);
        UsedFacts(Observer, ReportFormat::Word, 0);
        StatementFacts(Observer, ReportFormat::Word, 0);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcBoth_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(3, 0);
        UsedFacts(Observer, ReportFormat::Pdf, 0);
        StatementFacts(Observer, ReportFormat::Pdf, 0);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcBoth_TempGuid_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(3, 1);
        UsedFacts(Observer, ReportFormat::Html, 1);
        StatementFacts(Observer, ReportFormat::Html, 1);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcBoth_TempGuid_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(3, 1);
        UsedFacts(Observer, ReportFormat::Word, 1);
        StatementFacts(Observer, ReportFormat::Word, 1);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcBoth_TempGuid_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(3, 1);
        UsedFacts(Observer, ReportFormat::Pdf, 1);
        StatementFacts(Observer, ReportFormat::Pdf, 1);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcBoth_TempEmpty_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(3, 2);
        UsedFacts(Observer, ReportFormat::Html, 2);
        StatementFacts(Observer, ReportFormat::Html, 2);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcBoth_TempEmpty_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(3, 2);
        UsedFacts(Observer, ReportFormat::Word, 2);
        StatementFacts(Observer, ReportFormat::Word, 2);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_RdlcBoth_TempEmpty_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(3, 2);
        UsedFacts(Observer, ReportFormat::Pdf, 2);
        StatementFacts(Observer, ReportFormat::Pdf, 2);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_WordCompany_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(4, 0);
        UsedFacts(Observer, ReportFormat::Html, 0);
        StatementFacts(Observer, ReportFormat::Html, 0);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_WordCompany_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(4, 0);
        UsedFacts(Observer, ReportFormat::Word, 0);
        StatementFacts(Observer, ReportFormat::Word, 0);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_WordCompany_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(4, 0);
        UsedFacts(Observer, ReportFormat::Pdf, 0);
        StatementFacts(Observer, ReportFormat::Pdf, 0);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_WordCompany_TempGuid_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(4, 1);
        UsedFacts(Observer, ReportFormat::Html, 1);
        StatementFacts(Observer, ReportFormat::Html, 1);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_WordCompany_TempGuid_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(4, 1);
        UsedFacts(Observer, ReportFormat::Word, 1);
        StatementFacts(Observer, ReportFormat::Word, 1);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_WordCompany_TempGuid_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(4, 1);
        UsedFacts(Observer, ReportFormat::Pdf, 1);
        StatementFacts(Observer, ReportFormat::Pdf, 1);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_WordCompany_TempEmpty_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(4, 2);
        UsedFacts(Observer, ReportFormat::Html, 2);
        StatementFacts(Observer, ReportFormat::Html, 2);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_WordCompany_TempEmpty_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(4, 2);
        UsedFacts(Observer, ReportFormat::Word, 2);
        StatementFacts(Observer, ReportFormat::Word, 2);
        Helper.Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_WordCompany_TempEmpty_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(4, 2);
        UsedFacts(Observer, ReportFormat::Pdf, 2);
        StatementFacts(Observer, ReportFormat::Pdf, 2);
        Helper.Cleanup();
        Observer.Finish();
    end;
}
