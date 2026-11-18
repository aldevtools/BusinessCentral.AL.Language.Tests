// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); RX Row and RX Html Body of RxHtmlBodyFixtures.al (80012, 80016); RX Sel Word, RX Sel Log of
//   RxLayoutSelFixtures.al (80020, 80022); RX Legacy Word (80025); RX Rdlc (80015); test codeunit 80023
// Probe (al-runner issue 6924): Report.SaveAs as Html, Pdf, Word and Excel into a Temp Blob while a STORED layout selection names a
//   layout of the report: a Report Layout Selection row (table 9651) of the report and the company, alone or with a Tenant Report Layout
//   Selection row (the two rows the Report Layouts page writes when a user sets a default layout), for the report's built-in Word and RDLC
//   layouts, a second built-in Word layout, and a Tenant Report Layout row copied from a built-in layout and named by a GUID or by a short
//   name. Each Word layout has a marker text, so the Html says which layout was used. And Report.SaveAs of the Word layout report when
//   the run wrote no dataset row, for every format, with the answer used and as a statement; the same for the RDLC report (Pdf, Word) and
//   for the legacy DefaultLayout = Word report (Html, Pdf).
// Also the attachment form of Report Selections: a stored RDLC (built-in) row with an empty Company Name and with the company,
//   SetTempLayoutSelected(''), then Report.SaveAs(Id, '', Format, OutStream, RecordRef) for Html, Pdf, Xml, Word and Excel.
// Results (corpus CI, identical on 27.5, 28.5 and 29.0):
//   - The stored selection decides the layout: RDLC (built-in) of the company makes Html fail (ReportUnsupportedFormat) while Pdf, Word,
//     Excel and Xml render; a Tenant Report Layout Selection row wins over the Report Layout Selection type (marker 'tenant', also with
//     RDLC (built-in)); Custom Layout with a tenant code renders that layout; Custom Layout with an unknown code fails every format
//     (ReportNoLayout); a row of another company or with an empty Company Name is ignored (default Word layout, marker 'main').
//     SetTempLayoutSelected('') before the five-argument SaveAs does not override the stored RDLC (built-in) row of the company.
//   - Excel fails on every Word layout (ReportUnsupportedFormat, no trigger runs).
//   - No dataset row: the Word layout returns false with ReportResultEmpty for Pdf, Word and Html (OnPreReport and OnPreRendering ran;
//     the statement form raises the same error); the RDLC report returns true with an empty stream and no trigger; the legacy
//     DefaultLayout = Word report returns false with ReportResultEmpty and no trigger.
// Not asked: the Reporting Triggers events (a subscriber of a platform publisher makes the corpus CI run every test).
// BC versions: 27 - 29

codeunit 80023 "RX Layout Selection Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Html: Codeunit "RX Html Body";
        SelLog: Codeunit "RX Sel Log";
        TenantGuidNameTxt: Label '{8E3B1F64-2C7A-4D95-B0E1-5F6A7C8D9E21}', Locked = true;
        TenantShortNameTxt: Label 'RXSELT', Locked = true;
        OtherCompanyTxt: Label 'RX Other Company', Locked = true;

    local procedure Cleanup()
    var
        Selection: Record "Report Layout Selection";
        TenantSelection: Record "Tenant Report Layout Selection";
        TenantLayout: Record "Tenant Report Layout";
    begin
        Selection.SetRange("Report ID", Report::"RX Sel Word");
        Selection.DeleteAll();
        TenantSelection.SetRange("Report ID", Report::"RX Sel Word");
        TenantSelection.DeleteAll();
        TenantLayout.SetRange("Report ID", Report::"RX Sel Word");
        TenantLayout.DeleteAll();
        Selection.ClearTempLayoutSelected();
    end;

    local procedure StoreSelection(Company: Text[30]; TypeValue: Integer; LayoutCode: Code[20])
    var
        Selection: Record "Report Layout Selection";
    begin
        Selection.Init();
        Selection."Report ID" := Report::"RX Sel Word";
        Selection."Company Name" := Company;
        Selection.Type := TypeValue;
        Selection."Custom Report Layout Code" := LayoutCode;
        Selection.Insert();
    end;

    local procedure StoreTenantSelection(LayoutName: Text[250]; AppId: Guid)
    var
        TenantSelection: Record "Tenant Report Layout Selection";
    begin
        TenantSelection.Init();
        TenantSelection."Report ID" := Report::"RX Sel Word";
        TenantSelection."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TenantSelection."Company Name"));
        TenantSelection."Layout Name" := LayoutName;
        TenantSelection."App ID" := AppId;
        TenantSelection.Insert();
    end;

    // Copies the built-in layout RxSelTenant into a Tenant Report Layout row, as the Report Layouts page's copy action does.
    local procedure CopyTenantLayout(NewName: Text[250])
    var
        LayoutList: Record "Report Layout List";
        TenantLayout: Record "Tenant Report Layout";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        LayoutList.SetRange("Report ID", Report::"RX Sel Word");
        LayoutList.SetRange(Name, 'RxSelTenant');
        LayoutList.FindFirst();
        TempBlob.CreateOutStream(OutS);
        LayoutList.Layout.ExportStream(OutS);
        TempBlob.CreateInStream(InS);
        TenantLayout.Init();
        TenantLayout."Report ID" := Report::"RX Sel Word";
        TenantLayout.Name := NewName;
        TenantLayout."Layout Format" := TenantLayout."Layout Format"::Word;
        TenantLayout.Description := 'RX tenant copy';
        TenantLayout.Layout.ImportStream(InS, 'RX tenant copy');
        TenantLayout.Insert();
    end;

    local procedure OwnAppId(): Guid
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        exit(Info.Id());
    end;

    [TryFunction]
    local procedure TrySave(ReportId: Integer; Fmt: ReportFormat; var TempBlob: Codeunit "Temp Blob"; var Ok: Boolean)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Ok := Report.SaveAs(ReportId, '', Fmt, OutS);
    end;

    [TryFunction]
    local procedure TrySaveStatement(ReportId: Integer; Fmt: ReportFormat; var TempBlob: Codeunit "Temp Blob")
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Report.SaveAs(ReportId, '', Fmt, OutS);
    end;

    // The first four bytes of the saved document as numbers ('37 80 68 70' is %PDF, '80 75 3 4' a zip package).
    local procedure FirstBytes(var TempBlob: Codeunit "Temp Blob") Result: Text
    var
        InS: InStream;
        B: Byte;
        I: Integer;
    begin
        if TempBlob.Length() = 0 then
            exit('');
        TempBlob.CreateInStream(InS);
        for I := 1 to 4 do
            if not InS.EOS() then begin
                InS.Read(B);
                if Result <> '' then
                    Result += ' ';
                Result += Format(B);
            end;
    end;

    local procedure Markers(var TempBlob: Codeunit "Temp Blob") Result: Text
    var
        InS: InStream;
        Body: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        InS.Read(Body);
        if StrPos(Body, 'RXSELMAIN') > 0 then
            Result += 'main;';
        if StrPos(Body, 'RXSELOTHER') > 0 then
            Result += 'other;';
        if StrPos(Body, 'RXSELTENANT') > 0 then
            Result += 'tenant;';
        if Result = '' then
            Result := 'none';
    end;

    local procedure FormatFacts(var Observer: Codeunit "Probe Observer"; Name: Text; ReportId: Integer; Fmt: ReportFormat)
    var
        TempBlob: Codeunit "Temp Blob";
        Completed: Boolean;
        Ok: Boolean;
    begin
        SelLog.Start();
        ClearLastError();
        Completed := TrySave(ReportId, Fmt, TempBlob, Ok);
        Observer.Observe(Name + ' completed', Format(Completed));
        Observer.Observe(Name + ' returned', Format(Ok));
        Observer.ObserveError(Name + ' err');
        Observer.Observe(Name + ' length > 0', Format(TempBlob.Length() > 0));
        Observer.Observe(Name + ' first bytes', FirstBytes(TempBlob));
        Observer.Observe(Name + ' log', SelLog.Take());
        if Fmt = ReportFormat::Html then
            Observer.Observe(Name + ' layout marker', Markers(TempBlob));
    end;

    [TryFunction]
    local procedure TrySaveWithRecord(ReportId: Integer; Fmt: ReportFormat; var TempBlob: Codeunit "Temp Blob"; RecRef: RecordRef; var Ok: Boolean)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Ok := Report.SaveAs(ReportId, '', Fmt, OutS, RecRef);
    end;

    // The attachment form of Report Selections: SetTempLayoutSelected(''), then the five-argument SaveAs with the source record.
    local procedure RecordFormatFacts(var Observer: Codeunit "Probe Observer"; Name: Text; Fmt: ReportFormat)
    var
        Selection: Record "Report Layout Selection";
        Row: Record "RX Row";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        Completed: Boolean;
        Ok: Boolean;
    begin
        Selection.SetTempLayoutSelected('');
        Row.SetRange(Id, 1);
        RecRef.GetTable(Row);
        SelLog.Start();
        ClearLastError();
        Completed := TrySaveWithRecord(Report::"RX Sel Word", Fmt, TempBlob, RecRef, Ok);
        Observer.Observe(Name + ' completed', Format(Completed));
        Observer.Observe(Name + ' returned', Format(Ok));
        Observer.ObserveError(Name + ' err');
        Observer.Observe(Name + ' length > 0', Format(TempBlob.Length() > 0));
        // The Xml output starts with bytes that Format(Byte) turns into non-printable characters; only its length is checked.
        if Fmt <> ReportFormat::Xml then
            Observer.Observe(Name + ' first bytes', FirstBytes(TempBlob));
        Observer.Observe(Name + ' log', SelLog.Take());
        if Fmt = ReportFormat::Html then
            Observer.Observe(Name + ' layout marker', Markers(TempBlob));
    end;

    local procedure SetupRdlcEmptyCompany()
    var
        Selection: Record "Report Layout Selection";
    begin
        Cleanup();
        Html.Rows(2);
        StoreSelection('', Selection.Type::"RDLC (built-in)", '');
    end;

    local procedure StatementFacts(var Observer: Codeunit "Probe Observer"; Name: Text; ReportId: Integer; Fmt: ReportFormat)
    var
        TempBlob: Codeunit "Temp Blob";
        Completed: Boolean;
    begin
        SelLog.Start();
        ClearLastError();
        Completed := TrySaveStatement(ReportId, Fmt, TempBlob);
        Observer.Observe(Name + ' completed', Format(Completed));
        Observer.ObserveError(Name + ' err');
        Observer.Observe(Name + ' length > 0', Format(TempBlob.Length() > 0));
        Observer.Observe(Name + ' log', SelLog.Take());
    end;

    local procedure HtmlAndPdf(var Observer: Codeunit "Probe Observer")
    begin
        FormatFacts(Observer, 'html', Report::"RX Sel Word", ReportFormat::Html);
        FormatFacts(Observer, 'pdf', Report::"RX Sel Word", ReportFormat::Pdf);
        Cleanup();
    end;

    local procedure WordAndExcel(var Observer: Codeunit "Probe Observer")
    begin
        FormatFacts(Observer, 'word', Report::"RX Sel Word", ReportFormat::Word);
        FormatFacts(Observer, 'excel', Report::"RX Sel Word", ReportFormat::Excel);
        Cleanup();
    end;

    local procedure SetupNoSelection()
    begin
        Cleanup();
        Html.Rows(2);
    end;

    local procedure SetupWordBuiltin()
    var
        Selection: Record "Report Layout Selection";
    begin
        Cleanup();
        Html.Rows(2);
        StoreSelection(CopyStr(CompanyName(), 1, 30), Selection.Type::"Word (built-in)", '');
    end;

    local procedure SetupRdlcBuiltin()
    var
        Selection: Record "Report Layout Selection";
    begin
        Cleanup();
        Html.Rows(2);
        StoreSelection(CopyStr(CompanyName(), 1, 30), Selection.Type::"RDLC (built-in)", '');
    end;

    local procedure SetupWordBuiltinOtherByName()
    var
        Selection: Record "Report Layout Selection";
    begin
        Cleanup();
        Html.Rows(2);
        StoreSelection(CopyStr(CompanyName(), 1, 30), Selection.Type::"Word (built-in)", '');
        StoreTenantSelection('RxSelOther', OwnAppId());
    end;

    local procedure SetupWordBuiltinTenantGuid()
    var
        Selection: Record "Report Layout Selection";
        NullGuid: Guid;
    begin
        Cleanup();
        Html.Rows(2);
        CopyTenantLayout(TenantGuidNameTxt);
        StoreSelection(CopyStr(CompanyName(), 1, 30), Selection.Type::"Word (built-in)", '');
        StoreTenantSelection(TenantGuidNameTxt, NullGuid);
    end;

    local procedure SetupTenantGuidOnly()
    var
        NullGuid: Guid;
    begin
        Cleanup();
        Html.Rows(2);
        CopyTenantLayout(TenantGuidNameTxt);
        StoreTenantSelection(TenantGuidNameTxt, NullGuid);
    end;

    local procedure SetupRdlcBuiltinTenantGuid()
    var
        Selection: Record "Report Layout Selection";
        NullGuid: Guid;
    begin
        Cleanup();
        Html.Rows(2);
        CopyTenantLayout(TenantGuidNameTxt);
        StoreSelection(CopyStr(CompanyName(), 1, 30), Selection.Type::"RDLC (built-in)", '');
        StoreTenantSelection(TenantGuidNameTxt, NullGuid);
    end;

    local procedure SetupCustomLayoutTenantCode()
    var
        Selection: Record "Report Layout Selection";
    begin
        Cleanup();
        Html.Rows(2);
        CopyTenantLayout(TenantShortNameTxt);
        StoreSelection(CopyStr(CompanyName(), 1, 30), Selection.Type::"Custom Layout", TenantShortNameTxt);
    end;

    local procedure SetupCustomLayoutUnknownCode()
    var
        Selection: Record "Report Layout Selection";
    begin
        Cleanup();
        Html.Rows(2);
        StoreSelection(CopyStr(CompanyName(), 1, 30), Selection.Type::"Custom Layout", 'RXNOSUCHLAYOUT');
    end;

    local procedure SetupRdlcOtherCompany()
    var
        Selection: Record "Report Layout Selection";
    begin
        Cleanup();
        Html.Rows(2);
        StoreSelection(OtherCompanyTxt, Selection.Type::"RDLC (built-in)", '');
    end;

    [Test]
    procedure NoSelection_HtmlPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupNoSelection();
        HtmlAndPdf(Observer);
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'Yes');
        Observer.Expect('html err|text', '');
        Observer.Expect('html err|code', '');
        Observer.Expect('html length > 0', 'Yes');
        Observer.Expect('html first bytes', '< h t m');
        Observer.Expect('html log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('html layout marker', 'main;');
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf length > 0', 'Yes');
        Observer.Expect('pdf first bytes', '% P D F');
        Observer.Expect('pdf log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSelection_WordExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupNoSelection();
        WordAndExcel(Observer);
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('word length > 0', 'Yes');
        Observer.Expect('word first bytes', 'P K \u0003 \u0004');
        Observer.Expect('word log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('excel completed', 'Yes');
        Observer.Expect('excel returned', 'No');
        Observer.Expect('excel err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('excel err|code', 'ReportUnsupportedFormat');
        Observer.Expect('excel length > 0', 'No');
        Observer.Expect('excel first bytes', '');
        Observer.Expect('excel log', '');
        Observer.Verify();
    end;

    [Test]
    procedure StoredWordBuiltin_HtmlPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupWordBuiltin();
        HtmlAndPdf(Observer);
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'Yes');
        Observer.Expect('html err|text', '');
        Observer.Expect('html err|code', '');
        Observer.Expect('html length > 0', 'Yes');
        Observer.Expect('html first bytes', '< h t m');
        Observer.Expect('html log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('html layout marker', 'main;');
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf length > 0', 'Yes');
        Observer.Expect('pdf first bytes', '% P D F');
        Observer.Expect('pdf log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredWordBuiltin_WordExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupWordBuiltin();
        WordAndExcel(Observer);
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('word length > 0', 'Yes');
        Observer.Expect('word first bytes', 'P K \u0003 \u0004');
        Observer.Expect('word log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('excel completed', 'Yes');
        Observer.Expect('excel returned', 'No');
        Observer.Expect('excel err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('excel err|code', 'ReportUnsupportedFormat');
        Observer.Expect('excel length > 0', 'No');
        Observer.Expect('excel first bytes', '');
        Observer.Expect('excel log', '');
        Observer.Verify();
    end;

    [Test]
    procedure StoredRdlcBuiltin_HtmlPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupRdlcBuiltin();
        HtmlAndPdf(Observer);
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'No');
        Observer.Expect('html err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('html err|code', 'ReportUnsupportedFormat');
        Observer.Expect('html length > 0', 'No');
        Observer.Expect('html first bytes', '');
        Observer.Expect('html log', '');
        Observer.Expect('html layout marker', 'none');
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf length > 0', 'Yes');
        Observer.Expect('pdf first bytes', '% P D F');
        Observer.Expect('pdf log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredRdlcBuiltin_WordExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupRdlcBuiltin();
        WordAndExcel(Observer);
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('word length > 0', 'Yes');
        Observer.Expect('word first bytes', 'P K \u0003 \u0004');
        Observer.Expect('word log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('excel completed', 'Yes');
        Observer.Expect('excel returned', 'Yes');
        Observer.Expect('excel err|text', '');
        Observer.Expect('excel err|code', '');
        Observer.Expect('excel length > 0', 'Yes');
        Observer.Expect('excel first bytes', 'P K \u0003 \u0004');
        Observer.Expect('excel log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredWordBuiltinOtherByName_HtmlPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupWordBuiltinOtherByName();
        HtmlAndPdf(Observer);
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'Yes');
        Observer.Expect('html err|text', '');
        Observer.Expect('html err|code', '');
        Observer.Expect('html length > 0', 'Yes');
        Observer.Expect('html first bytes', '< h t m');
        Observer.Expect('html log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('html layout marker', 'other;');
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf length > 0', 'Yes');
        Observer.Expect('pdf first bytes', '% P D F');
        Observer.Expect('pdf log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredWordBuiltinOtherByName_WordExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupWordBuiltinOtherByName();
        WordAndExcel(Observer);
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('word length > 0', 'Yes');
        Observer.Expect('word first bytes', 'P K \u0003 \u0004');
        Observer.Expect('word log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('excel completed', 'Yes');
        Observer.Expect('excel returned', 'No');
        Observer.Expect('excel err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('excel err|code', 'ReportUnsupportedFormat');
        Observer.Expect('excel length > 0', 'No');
        Observer.Expect('excel first bytes', '');
        Observer.Expect('excel log', '');
        Observer.Verify();
    end;

    [Test]
    procedure StoredWordBuiltinTenantGuid_HtmlPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupWordBuiltinTenantGuid();
        HtmlAndPdf(Observer);
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'Yes');
        Observer.Expect('html err|text', '');
        Observer.Expect('html err|code', '');
        Observer.Expect('html length > 0', 'Yes');
        Observer.Expect('html first bytes', '< h t m');
        Observer.Expect('html log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('html layout marker', 'tenant;');
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf length > 0', 'Yes');
        Observer.Expect('pdf first bytes', '% P D F');
        Observer.Expect('pdf log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredWordBuiltinTenantGuid_WordExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupWordBuiltinTenantGuid();
        WordAndExcel(Observer);
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('word length > 0', 'Yes');
        Observer.Expect('word first bytes', 'P K \u0003 \u0004');
        Observer.Expect('word log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('excel completed', 'Yes');
        Observer.Expect('excel returned', 'No');
        Observer.Expect('excel err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('excel err|code', 'ReportUnsupportedFormat');
        Observer.Expect('excel length > 0', 'No');
        Observer.Expect('excel first bytes', '');
        Observer.Expect('excel log', '');
        Observer.Verify();
    end;

    [Test]
    procedure StoredTenantGuidOnly_HtmlPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupTenantGuidOnly();
        HtmlAndPdf(Observer);
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'Yes');
        Observer.Expect('html err|text', '');
        Observer.Expect('html err|code', '');
        Observer.Expect('html length > 0', 'Yes');
        Observer.Expect('html first bytes', '< h t m');
        Observer.Expect('html log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('html layout marker', 'tenant;');
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf length > 0', 'Yes');
        Observer.Expect('pdf first bytes', '% P D F');
        Observer.Expect('pdf log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredTenantGuidOnly_WordExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupTenantGuidOnly();
        WordAndExcel(Observer);
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('word length > 0', 'Yes');
        Observer.Expect('word first bytes', 'P K \u0003 \u0004');
        Observer.Expect('word log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('excel completed', 'Yes');
        Observer.Expect('excel returned', 'No');
        Observer.Expect('excel err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('excel err|code', 'ReportUnsupportedFormat');
        Observer.Expect('excel length > 0', 'No');
        Observer.Expect('excel first bytes', '');
        Observer.Expect('excel log', '');
        Observer.Verify();
    end;

    [Test]
    procedure StoredRdlcBuiltinTenantGuid_HtmlPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupRdlcBuiltinTenantGuid();
        HtmlAndPdf(Observer);
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'Yes');
        Observer.Expect('html err|text', '');
        Observer.Expect('html err|code', '');
        Observer.Expect('html length > 0', 'Yes');
        Observer.Expect('html first bytes', '< h t m');
        Observer.Expect('html log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('html layout marker', 'tenant;');
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf length > 0', 'Yes');
        Observer.Expect('pdf first bytes', '% P D F');
        Observer.Expect('pdf log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredRdlcBuiltinTenantGuid_WordExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupRdlcBuiltinTenantGuid();
        WordAndExcel(Observer);
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('word length > 0', 'Yes');
        Observer.Expect('word first bytes', 'P K \u0003 \u0004');
        Observer.Expect('word log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('excel completed', 'Yes');
        Observer.Expect('excel returned', 'No');
        Observer.Expect('excel err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('excel err|code', 'ReportUnsupportedFormat');
        Observer.Expect('excel length > 0', 'No');
        Observer.Expect('excel first bytes', '');
        Observer.Expect('excel log', '');
        Observer.Verify();
    end;

    [Test]
    procedure StoredCustomLayoutTenantCode_HtmlPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupCustomLayoutTenantCode();
        HtmlAndPdf(Observer);
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'Yes');
        Observer.Expect('html err|text', '');
        Observer.Expect('html err|code', '');
        Observer.Expect('html length > 0', 'Yes');
        Observer.Expect('html first bytes', '< h t m');
        Observer.Expect('html log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('html layout marker', 'tenant;');
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf length > 0', 'Yes');
        Observer.Expect('pdf first bytes', '% P D F');
        Observer.Expect('pdf log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredCustomLayoutTenantCode_WordExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupCustomLayoutTenantCode();
        WordAndExcel(Observer);
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('word length > 0', 'Yes');
        Observer.Expect('word first bytes', 'P K \u0003 \u0004');
        Observer.Expect('word log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('excel completed', 'Yes');
        Observer.Expect('excel returned', 'No');
        Observer.Expect('excel err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('excel err|code', 'ReportUnsupportedFormat');
        Observer.Expect('excel length > 0', 'No');
        Observer.Expect('excel first bytes', '');
        Observer.Expect('excel log', '');
        Observer.Verify();
    end;

    [Test]
    procedure StoredCustomLayoutUnknownCode_HtmlPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupCustomLayoutUnknownCode();
        HtmlAndPdf(Observer);
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'No');
        Observer.Expect('html err|text', 'Report 80020 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('html err|code', 'ReportNoLayout');
        Observer.Expect('html length > 0', 'No');
        Observer.Expect('html first bytes', '');
        Observer.Expect('html log', '');
        Observer.Expect('html layout marker', 'none');
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'No');
        Observer.Expect('pdf err|text', 'Report 80020 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('pdf err|code', 'ReportNoLayout');
        Observer.Expect('pdf length > 0', 'No');
        Observer.Expect('pdf first bytes', '');
        Observer.Expect('pdf log', '');
        Observer.Verify();
    end;

    [Test]
    procedure StoredCustomLayoutUnknownCode_WordExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupCustomLayoutUnknownCode();
        WordAndExcel(Observer);
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'No');
        Observer.Expect('word err|text', 'Report 80020 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('word err|code', 'ReportNoLayout');
        Observer.Expect('word length > 0', 'No');
        Observer.Expect('word first bytes', '');
        Observer.Expect('word log', '');
        Observer.Expect('excel completed', 'Yes');
        Observer.Expect('excel returned', 'No');
        Observer.Expect('excel err|text', 'Report 80020 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('excel err|code', 'ReportNoLayout');
        Observer.Expect('excel length > 0', 'No');
        Observer.Expect('excel first bytes', '');
        Observer.Expect('excel log', '');
        Observer.Verify();
    end;

    [Test]
    procedure StoredRdlcOtherCompany_HtmlPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupRdlcOtherCompany();
        HtmlAndPdf(Observer);
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'Yes');
        Observer.Expect('html err|text', '');
        Observer.Expect('html err|code', '');
        Observer.Expect('html length > 0', 'Yes');
        Observer.Expect('html first bytes', '< h t m');
        Observer.Expect('html log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('html layout marker', 'main;');
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf length > 0', 'Yes');
        Observer.Expect('pdf first bytes', '% P D F');
        Observer.Expect('pdf log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredRdlcOtherCompany_WordExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupRdlcOtherCompany();
        WordAndExcel(Observer);
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('word length > 0', 'Yes');
        Observer.Expect('word first bytes', 'P K \u0003 \u0004');
        Observer.Expect('word log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('excel completed', 'Yes');
        Observer.Expect('excel returned', 'No');
        Observer.Expect('excel err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('excel err|code', 'ReportUnsupportedFormat');
        Observer.Expect('excel length > 0', 'No');
        Observer.Expect('excel first bytes', '');
        Observer.Expect('excel log', '');
        Observer.Verify();
    end;

    local procedure NoRowFacts(var Observer: Codeunit "Probe Observer"; ReportId: Integer; Fmt: ReportFormat)
    begin
        Cleanup();
        Html.Rows(0);
        FormatFacts(Observer, 'used', ReportId, Fmt);
        StatementFacts(Observer, 'statement', ReportId, Fmt);
    end;

    [Test]
    procedure NoRow_WordLayout_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NoRowFacts(Observer, Report::"RX Sel Word", ReportFormat::Pdf);
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('used err|code', 'ReportResultEmpty');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used log', 'OnPreReport;OnPreRendering;');
        Observer.Expect('statement completed', 'No');
        Observer.Expect('statement err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('statement err|code', 'ReportResultEmpty');
        Observer.Expect('statement length > 0', 'No');
        Observer.Expect('statement log', 'OnPreReport;OnPreRendering;');
        Observer.Verify();
    end;

    [Test]
    procedure NoRow_WordLayout_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NoRowFacts(Observer, Report::"RX Sel Word", ReportFormat::Word);
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('used err|code', 'ReportResultEmpty');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used log', 'OnPreReport;OnPreRendering;');
        Observer.Expect('statement completed', 'No');
        Observer.Expect('statement err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('statement err|code', 'ReportResultEmpty');
        Observer.Expect('statement length > 0', 'No');
        Observer.Expect('statement log', 'OnPreReport;OnPreRendering;');
        Observer.Verify();
    end;

    [Test]
    procedure NoRow_WordLayout_Excel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NoRowFacts(Observer, Report::"RX Sel Word", ReportFormat::Excel);
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('used err|code', 'ReportUnsupportedFormat');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used log', '');
        Observer.Expect('statement completed', 'No');
        Observer.Expect('statement err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('statement err|code', 'ReportUnsupportedFormat');
        Observer.Expect('statement length > 0', 'No');
        Observer.Expect('statement log', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoRow_WordLayout_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NoRowFacts(Observer, Report::"RX Sel Word", ReportFormat::Html);
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('used err|code', 'ReportResultEmpty');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used log', 'OnPreReport;OnPreRendering;');
        Observer.Expect('used layout marker', 'none');
        Observer.Expect('statement completed', 'No');
        Observer.Expect('statement err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('statement err|code', 'ReportResultEmpty');
        Observer.Expect('statement length > 0', 'No');
        Observer.Expect('statement log', 'OnPreReport;OnPreRendering;');
        Observer.Verify();
    end;

    [Test]
    procedure NoRow_RdlcLayout_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NoRowFacts(Observer, Report::"RX Rdlc", ReportFormat::Pdf);
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used log', '');
        Observer.Expect('statement completed', 'Yes');
        Observer.Expect('statement err|text', '');
        Observer.Expect('statement err|code', '');
        Observer.Expect('statement length > 0', 'No');
        Observer.Expect('statement log', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoRow_RdlcLayout_Word()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NoRowFacts(Observer, Report::"RX Rdlc", ReportFormat::Word);
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'Yes');
        Observer.Expect('used err|text', '');
        Observer.Expect('used err|code', '');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used log', '');
        Observer.Expect('statement completed', 'Yes');
        Observer.Expect('statement err|text', '');
        Observer.Expect('statement err|code', '');
        Observer.Expect('statement length > 0', 'No');
        Observer.Expect('statement log', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoRow_LegacyWordLayout_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NoRowFacts(Observer, Report::"RX Legacy Word", ReportFormat::Html);
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('used err|code', 'ReportResultEmpty');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used log', '');
        Observer.Expect('used layout marker', 'none');
        Observer.Expect('statement completed', 'No');
        Observer.Expect('statement err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('statement err|code', 'ReportResultEmpty');
        Observer.Expect('statement length > 0', 'No');
        Observer.Expect('statement log', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoRow_LegacyWordLayout_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NoRowFacts(Observer, Report::"RX Legacy Word", ReportFormat::Pdf);
        Observer.Expect('used completed', 'Yes');
        Observer.Expect('used returned', 'No');
        Observer.Expect('used err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('used err|code', 'ReportResultEmpty');
        Observer.Expect('used length > 0', 'No');
        Observer.Expect('used first bytes', '');
        Observer.Expect('used log', '');
        Observer.Expect('statement completed', 'No');
        Observer.Expect('statement err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('statement err|code', 'ReportResultEmpty');
        Observer.Expect('statement length > 0', 'No');
        Observer.Expect('statement log', '');
        Observer.Verify();
    end;

    [Test]
    procedure StoredRdlcEmptyCompany_WithRecord_HtmlPdfXml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupRdlcEmptyCompany();
        RecordFormatFacts(Observer, 'html', ReportFormat::Html);
        RecordFormatFacts(Observer, 'pdf', ReportFormat::Pdf);
        RecordFormatFacts(Observer, 'xml', ReportFormat::Xml);
        Cleanup();
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'Yes');
        Observer.Expect('html err|text', '');
        Observer.Expect('html err|code', '');
        Observer.Expect('html length > 0', 'Yes');
        Observer.Expect('html first bytes', '< h t m');
        Observer.Expect('html log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('html layout marker', 'main;');
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf length > 0', 'Yes');
        Observer.Expect('pdf first bytes', '% P D F');
        Observer.Expect('pdf log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('xml completed', 'Yes');
        Observer.Expect('xml returned', 'Yes');
        Observer.Expect('xml err|text', '');
        Observer.Expect('xml err|code', '');
        Observer.Expect('xml length > 0', 'Yes');
        Observer.Expect('xml log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredRdlcEmptyCompany_WithRecord_WordExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupRdlcEmptyCompany();
        RecordFormatFacts(Observer, 'word', ReportFormat::Word);
        RecordFormatFacts(Observer, 'excel', ReportFormat::Excel);
        Cleanup();
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('word length > 0', 'Yes');
        Observer.Expect('word first bytes', 'P K \u0003 \u0004');
        Observer.Expect('word log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('excel completed', 'Yes');
        Observer.Expect('excel returned', 'No');
        Observer.Expect('excel err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('excel err|code', 'ReportUnsupportedFormat');
        Observer.Expect('excel length > 0', 'No');
        Observer.Expect('excel first bytes', '');
        Observer.Expect('excel log', '');
        Observer.Verify();
    end;

    [Test]
    procedure StoredRdlcCompany_WithRecord_HtmlPdfXml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupRdlcBuiltin();
        RecordFormatFacts(Observer, 'html', ReportFormat::Html);
        RecordFormatFacts(Observer, 'pdf', ReportFormat::Pdf);
        RecordFormatFacts(Observer, 'xml', ReportFormat::Xml);
        Cleanup();
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'No');
        Observer.Expect('html err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('html err|code', 'ReportUnsupportedFormat');
        Observer.Expect('html length > 0', 'No');
        Observer.Expect('html first bytes', '');
        Observer.Expect('html log', '');
        Observer.Expect('html layout marker', 'none');
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf length > 0', 'Yes');
        Observer.Expect('pdf first bytes', '% P D F');
        Observer.Expect('pdf log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('xml completed', 'Yes');
        Observer.Expect('xml returned', 'Yes');
        Observer.Expect('xml err|text', '');
        Observer.Expect('xml err|code', '');
        Observer.Expect('xml length > 0', 'Yes');
        Observer.Expect('xml log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredRdlcCompany_WithRecord_WordExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupRdlcBuiltin();
        RecordFormatFacts(Observer, 'word', ReportFormat::Word);
        RecordFormatFacts(Observer, 'excel', ReportFormat::Excel);
        Cleanup();
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('word length > 0', 'Yes');
        Observer.Expect('word first bytes', 'P K \u0003 \u0004');
        Observer.Expect('word log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('excel completed', 'Yes');
        Observer.Expect('excel returned', 'Yes');
        Observer.Expect('excel err|text', '');
        Observer.Expect('excel err|code', '');
        Observer.Expect('excel length > 0', 'Yes');
        Observer.Expect('excel first bytes', 'P K \u0003 \u0004');
        Observer.Expect('excel log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSelection_WithRecord_HtmlPdfXml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetupNoSelection();
        RecordFormatFacts(Observer, 'html', ReportFormat::Html);
        RecordFormatFacts(Observer, 'pdf', ReportFormat::Pdf);
        RecordFormatFacts(Observer, 'xml', ReportFormat::Xml);
        Cleanup();
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'Yes');
        Observer.Expect('html err|text', '');
        Observer.Expect('html err|code', '');
        Observer.Expect('html length > 0', 'Yes');
        Observer.Expect('html first bytes', '< h t m');
        Observer.Expect('html log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('html layout marker', 'main;');
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf length > 0', 'Yes');
        Observer.Expect('pdf first bytes', '% P D F');
        Observer.Expect('pdf log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Expect('xml completed', 'Yes');
        Observer.Expect('xml returned', 'Yes');
        Observer.Expect('xml err|text', '');
        Observer.Expect('xml err|code', '');
        Observer.Expect('xml length > 0', 'Yes');
        Observer.Expect('xml log', 'OnPreReport;OnPreRendering;OnPostReport;');
        Observer.Verify();
    end;
}
