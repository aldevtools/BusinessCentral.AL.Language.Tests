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
//   temporary layout name after the call. Excel in every state. The five-argument form Report.SaveAs(Id, '', Format, OutStream, RecordRef)
//   (the Report Selections attachment call, RXD Row filtered to Id 1) for the company RDLC row and for no row, both with
//   SetTempLayoutSelected('').
// Results (local observation on BC 27.5, 28.5 and 29.0; identical on all three):
//   - Which layout runs: a temporary GUID tenant selection always wins (marker tenant), over every stored row. Otherwise a stored
//     RDLC (built-in) row of the CURRENT company makes the RDLC layout run (also when the empty-company row exists too);
//     SetTempLayoutSelected('') does not change that. An RDLC (built-in) row with an empty Company Name alone is ignored (Word layout).
//     A Word (built-in) row of the company and no row run the Word layout.
//   - Word layout: Html, Word and Pdf return true with output; Excel returns false with ReportUnsupportedFormat ('The Excel output format
//     is not supported by the current report layout format.'), empty output; its statement form raises the same error.
//   - RDLC layout: Html returns false with ReportUnsupportedFormat ('The Html output format is not supported by the current report layout
//     format.'), empty output, statement form raises; Word, Pdf and Excel return true with output (Word holds the RDLC text box).
//   - The five-argument form gives the same answers as the four-argument form in the same state.
//   - GetTempSelectedLayoutName is empty after every call.
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
            ReportFormat::Excel:
                begin
                    Observer.Observe(Name + ' first bytes', Helper.FirstBytes(TempBlob));
                    Content := Helper.ExcelStringsText(TempBlob);
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

    local procedure RecordFacts(var Observer: Codeunit "Probe Observer"; Fmt: ReportFormat; Mode: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        Completed: Boolean;
        Ok: Boolean;
    begin
        Helper.SetTemp(Mode);
        ClearLastError();
        Completed := Helper.TrySaveWithRecord(Fmt, TempBlob, Ok);
        Observer.Observe('rec completed', Format(Completed));
        Observer.Observe('rec returned', Format(Ok));
        Observer.ObserveError('rec err');
        OutputFacts(Observer, 'rec', Fmt, TempBlob);
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
            case Fmt of
                ReportFormat::Html:
                    Observer.Observe('stmt marker', Helper.Markers(Helper.BodyText(TempBlob)));
                ReportFormat::Word:
                    Observer.Observe('stmt marker', Helper.Markers(Helper.WordDocumentText(TempBlob)));
                ReportFormat::Excel:
                    Observer.Observe('stmt marker', Helper.Markers(Helper.ExcelStringsText(TempBlob)));
            end;
    end;

    [Test]
    procedure SaveAs_RdlcCompany_TempEmpty_Excel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 2);
        UsedFacts(Observer, ReportFormat::Excel, 2);
        StatementFacts(Observer, ReportFormat::Excel, 2);
        Helper.Cleanup();
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsRecord_RdlcCompany_TempEmpty_Excel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 2);
        RecordFacts(Observer, ReportFormat::Excel, 2);
        Helper.Cleanup();
        Observer.Expect('rec completed', 'Yes');
        Observer.Expect('rec returned', 'Yes');
        Observer.Expect('rec err|text', '');
        Observer.Expect('rec err|code', '');
        Observer.Expect('rec length > 0', 'Yes');
        Observer.Expect('rec has value', 'Yes');
        Observer.Expect('rec first bytes', 'P K \u0003 \u0004');
        Observer.Expect('rec has RXDROW1', 'No');
        Observer.Expect('rec marker', 'none');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', '% P D F');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsRecord_RdlcCompany_TempEmpty_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 2);
        RecordFacts(Observer, ReportFormat::Pdf, 2);
        Helper.Cleanup();
        Observer.Expect('rec completed', 'Yes');
        Observer.Expect('rec returned', 'Yes');
        Observer.Expect('rec err|text', '');
        Observer.Expect('rec err|code', '');
        Observer.Expect('rec length > 0', 'Yes');
        Observer.Expect('rec has value', 'Yes');
        Observer.Expect('rec first bytes', '% P D F');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'rdlc;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'rdlc;');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsRecord_RdlcCompany_TempEmpty_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 2);
        RecordFacts(Observer, ReportFormat::Word, 2);
        Helper.Cleanup();
        Observer.Expect('rec completed', 'Yes');
        Observer.Expect('rec returned', 'Yes');
        Observer.Expect('rec err|text', '');
        Observer.Expect('rec err|code', '');
        Observer.Expect('rec length > 0', 'Yes');
        Observer.Expect('rec has value', 'Yes');
        Observer.Expect('rec first bytes', 'P K \u0003 \u0004');
        Observer.Expect('rec has RXDROW1', 'No');
        Observer.Expect('rec marker', 'rdlc;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('used err|code', 'ReportUnsupportedFormat');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used has value', 'No');
        Observer.Expect('used starts <html', 'No');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'No');
        Observer.Expect('stmt err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('stmt err|code', 'ReportUnsupportedFormat');
        Observer.Expect('stmt length > 0', 'No');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsRecord_RdlcCompany_TempEmpty_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 2);
        RecordFacts(Observer, ReportFormat::Html, 2);
        Helper.Cleanup();
        Observer.Expect('rec completed', 'Yes');
        Observer.Expect('rec returned', 'No');
        Observer.Expect('rec err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('rec err|code', 'ReportUnsupportedFormat');
        Observer.Expect('rec length > 0', 'No');
        Observer.Expect('rec has value', 'No');
        Observer.Expect('rec starts <html', 'No');
        Observer.Expect('rec has RXDROW1', 'No');
        Observer.Expect('rec marker', 'none');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used starts <html', 'Yes');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'tenant;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'tenant;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'tenant;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'tenant;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', '% P D F');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_NoRow_TempGuid_Excel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 1);
        UsedFacts(Observer, ReportFormat::Excel, 1);
        StatementFacts(Observer, ReportFormat::Excel, 1);
        Helper.Cleanup();
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('used err|code', 'ReportUnsupportedFormat');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used has value', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'No');
        Observer.Expect('stmt err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('stmt err|code', 'ReportUnsupportedFormat');
        Observer.Expect('stmt length > 0', 'No');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsRecord_NoRow_TempEmpty_Excel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 2);
        RecordFacts(Observer, ReportFormat::Excel, 2);
        Helper.Cleanup();
        Observer.Expect('rec completed', 'Yes');
        Observer.Expect('rec returned', 'No');
        Observer.Expect('rec err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('rec err|code', 'ReportUnsupportedFormat');
        Observer.Expect('rec length > 0', 'No');
        Observer.Expect('rec has value', 'No');
        Observer.Expect('rec first bytes', '');
        Observer.Expect('rec has RXDROW1', 'No');
        Observer.Expect('rec marker', 'none');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsRecord_NoRow_TempEmpty_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 2);
        RecordFacts(Observer, ReportFormat::Pdf, 2);
        Helper.Cleanup();
        Observer.Expect('rec completed', 'Yes');
        Observer.Expect('rec returned', 'Yes');
        Observer.Expect('rec err|text', '');
        Observer.Expect('rec err|code', '');
        Observer.Expect('rec length > 0', 'Yes');
        Observer.Expect('rec has value', 'Yes');
        Observer.Expect('rec first bytes', '% P D F');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsRecord_NoRow_TempEmpty_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 2);
        RecordFacts(Observer, ReportFormat::Word, 2);
        Helper.Cleanup();
        Observer.Expect('rec completed', 'Yes');
        Observer.Expect('rec returned', 'Yes');
        Observer.Expect('rec err|text', '');
        Observer.Expect('rec err|code', '');
        Observer.Expect('rec length > 0', 'Yes');
        Observer.Expect('rec has value', 'Yes');
        Observer.Expect('rec first bytes', 'P K \u0003 \u0004');
        Observer.Expect('rec has RXDROW1', 'Yes');
        Observer.Expect('rec marker', 'word;');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsRecord_NoRow_TempEmpty_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 2);
        RecordFacts(Observer, ReportFormat::Html, 2);
        Helper.Cleanup();
        Observer.Expect('rec completed', 'Yes');
        Observer.Expect('rec returned', 'Yes');
        Observer.Expect('rec err|text', '');
        Observer.Expect('rec err|code', '');
        Observer.Expect('rec length > 0', 'Yes');
        Observer.Expect('rec has value', 'Yes');
        Observer.Expect('rec starts <html', 'Yes');
        Observer.Expect('rec has RXDROW1', 'Yes');
        Observer.Expect('rec marker', 'word;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used starts <html', 'Yes');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'word;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'word;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'word;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'word;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', '% P D F');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_NoRow_Excel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 0);
        UsedFacts(Observer, ReportFormat::Excel, 0);
        StatementFacts(Observer, ReportFormat::Excel, 0);
        Helper.Cleanup();
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('used err|code', 'ReportUnsupportedFormat');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used has value', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'No');
        Observer.Expect('stmt err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('stmt err|code', 'ReportUnsupportedFormat');
        Observer.Expect('stmt length > 0', 'No');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used starts <html', 'Yes');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'word;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'word;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'word;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'word;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', '% P D F');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_NoRow_TempEmpty_Excel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 2);
        UsedFacts(Observer, ReportFormat::Excel, 2);
        StatementFacts(Observer, ReportFormat::Excel, 2);
        Helper.Cleanup();
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('used err|code', 'ReportUnsupportedFormat');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used has value', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'No');
        Observer.Expect('stmt err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('stmt err|code', 'ReportUnsupportedFormat');
        Observer.Expect('stmt length > 0', 'No');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('used err|code', 'ReportUnsupportedFormat');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used has value', 'No');
        Observer.Expect('used starts <html', 'No');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'No');
        Observer.Expect('stmt err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('stmt err|code', 'ReportUnsupportedFormat');
        Observer.Expect('stmt length > 0', 'No');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'rdlc;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'rdlc;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', '% P D F');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_RdlcCompany_Excel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 0);
        UsedFacts(Observer, ReportFormat::Excel, 0);
        StatementFacts(Observer, ReportFormat::Excel, 0);
        Helper.Cleanup();
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used starts <html', 'Yes');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'tenant;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'tenant;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'tenant;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'tenant;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', '% P D F');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_RdlcCompany_TempGuid_Excel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 1);
        UsedFacts(Observer, ReportFormat::Excel, 1);
        StatementFacts(Observer, ReportFormat::Excel, 1);
        Helper.Cleanup();
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('used err|code', 'ReportUnsupportedFormat');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used has value', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'No');
        Observer.Expect('stmt err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('stmt err|code', 'ReportUnsupportedFormat');
        Observer.Expect('stmt length > 0', 'No');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used starts <html', 'Yes');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'word;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'word;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'word;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'word;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', '% P D F');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_RdlcEmptyCompany_Excel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(2, 0);
        UsedFacts(Observer, ReportFormat::Excel, 0);
        StatementFacts(Observer, ReportFormat::Excel, 0);
        Helper.Cleanup();
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('used err|code', 'ReportUnsupportedFormat');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used has value', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'No');
        Observer.Expect('stmt err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('stmt err|code', 'ReportUnsupportedFormat');
        Observer.Expect('stmt length > 0', 'No');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used starts <html', 'Yes');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'tenant;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'tenant;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'tenant;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'tenant;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', '% P D F');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_RdlcEmptyCompany_TempGuid_Excel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(2, 1);
        UsedFacts(Observer, ReportFormat::Excel, 1);
        StatementFacts(Observer, ReportFormat::Excel, 1);
        Helper.Cleanup();
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('used err|code', 'ReportUnsupportedFormat');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used has value', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'No');
        Observer.Expect('stmt err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('stmt err|code', 'ReportUnsupportedFormat');
        Observer.Expect('stmt length > 0', 'No');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used starts <html', 'Yes');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'word;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'word;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'word;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'word;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', '% P D F');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_RdlcEmptyCompany_TempEmpty_Excel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(2, 2);
        UsedFacts(Observer, ReportFormat::Excel, 2);
        StatementFacts(Observer, ReportFormat::Excel, 2);
        Helper.Cleanup();
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('used err|code', 'ReportUnsupportedFormat');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used has value', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'No');
        Observer.Expect('stmt err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('stmt err|code', 'ReportUnsupportedFormat');
        Observer.Expect('stmt length > 0', 'No');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('used err|code', 'ReportUnsupportedFormat');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used has value', 'No');
        Observer.Expect('used starts <html', 'No');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'No');
        Observer.Expect('stmt err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('stmt err|code', 'ReportUnsupportedFormat');
        Observer.Expect('stmt length > 0', 'No');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'rdlc;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'rdlc;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', '% P D F');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_RdlcBoth_Excel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(3, 0);
        UsedFacts(Observer, ReportFormat::Excel, 0);
        StatementFacts(Observer, ReportFormat::Excel, 0);
        Helper.Cleanup();
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used starts <html', 'Yes');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'tenant;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'tenant;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'tenant;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'tenant;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', '% P D F');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_RdlcBoth_TempGuid_Excel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(3, 1);
        UsedFacts(Observer, ReportFormat::Excel, 1);
        StatementFacts(Observer, ReportFormat::Excel, 1);
        Helper.Cleanup();
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('used err|code', 'ReportUnsupportedFormat');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used has value', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'No');
        Observer.Expect('stmt err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('stmt err|code', 'ReportUnsupportedFormat');
        Observer.Expect('stmt length > 0', 'No');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('used err|code', 'ReportUnsupportedFormat');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used has value', 'No');
        Observer.Expect('used starts <html', 'No');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'No');
        Observer.Expect('stmt err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('stmt err|code', 'ReportUnsupportedFormat');
        Observer.Expect('stmt length > 0', 'No');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'rdlc;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'rdlc;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', '% P D F');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_RdlcBoth_TempEmpty_Excel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(3, 2);
        UsedFacts(Observer, ReportFormat::Excel, 2);
        StatementFacts(Observer, ReportFormat::Excel, 2);
        Helper.Cleanup();
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used starts <html', 'Yes');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'word;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'word;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'word;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'word;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', '% P D F');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_WordCompany_Excel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(4, 0);
        UsedFacts(Observer, ReportFormat::Excel, 0);
        StatementFacts(Observer, ReportFormat::Excel, 0);
        Helper.Cleanup();
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('used err|code', 'ReportUnsupportedFormat');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used has value', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'No');
        Observer.Expect('stmt err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('stmt err|code', 'ReportUnsupportedFormat');
        Observer.Expect('stmt length > 0', 'No');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used starts <html', 'Yes');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'tenant;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'tenant;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'tenant;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'tenant;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', '% P D F');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_WordCompany_TempGuid_Excel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(4, 1);
        UsedFacts(Observer, ReportFormat::Excel, 1);
        StatementFacts(Observer, ReportFormat::Excel, 1);
        Helper.Cleanup();
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('used err|code', 'ReportUnsupportedFormat');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used has value', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'No');
        Observer.Expect('stmt err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('stmt err|code', 'ReportUnsupportedFormat');
        Observer.Expect('stmt length > 0', 'No');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used starts <html', 'Yes');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'word;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'word;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', 'P K \u0003 \u0004');
        Observer.Expect('used has RXDROW1', 'Yes');
        Observer.Expect('used marker', 'word;');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Expect('stmt marker', 'word;');
        Observer.Verify();
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
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'Yes');
        Observer.Expect('used has value', 'Yes');
        Observer.Expect('used first bytes', '% P D F');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'Yes');
        Observer.Expect('stmt err|text', '');
        Observer.Expect('stmt err|code', '');
        Observer.Expect('stmt length > 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_WordCompany_TempEmpty_Excel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(4, 2);
        UsedFacts(Observer, ReportFormat::Excel, 2);
        StatementFacts(Observer, ReportFormat::Excel, 2);
        Helper.Cleanup();
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('used err|code', 'ReportUnsupportedFormat');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used has value', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used has RXDROW1', 'No');
        Observer.Expect('used marker', 'none');
        Observer.Expect('used temp name after', '');
        Observer.Expect('stmt completed', 'No');
        Observer.Expect('stmt err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('stmt err|code', 'ReportUnsupportedFormat');
        Observer.Expect('stmt length > 0', 'No');
        Observer.Expect('stmt marker', 'none');
        Observer.Verify();
    end;
}
