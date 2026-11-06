// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); report 91230 "LT SC Meta Report" (ScReportMetadataViews.al, RDLC layout FixtureLayout_19.rdlc); own test codeunit 91312
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: the platform table Tenant Report Layout: whether the tenant holds rows for an app's own report before anything is inserted (all
//   companies and the current one), and Insert of a row for that report whose Layout holds the report's own RDLC layout (Report.RdlcLayout):
//   the answer of Insert, the row count of the report after it, the stored fields read back by Get, and Delete. ScReportMetadataViews.al pins
//   Insert of a blank row and of a row with an empty RDLC layout.
// BC versions: 27, 28, 29
codeunit 91312 "LT Y6 Tenant Report Layout"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure FreshTenant_RowsOfOwnReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
    begin
        Layout.SetRange("Report ID", Report::"LT SC Meta Report");
        Observer.Observe('own report rows', Format(Layout.Count()));
        Layout.SetRange("Company Name", CompanyName());
        Observer.Observe('own report rows current company', Format(Layout.Count()));
        Layout.Reset();
        Layout.SetRange("Report ID", Report::"LT SC Meta Report");
        Observer.Observe('own report findfirst', Format(Layout.FindFirst()));
        Observer.Expect('own report rows', '0');
        Observer.Expect('own report rows current company', '0');
        Observer.Expect('own report findfirst', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_WithRdlcLayoutOfTheReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        ReadBack: Record "Tenant Report Layout";
        InS: InStream;
        Ok: Boolean;
    begin
        Layout.SetRange("Report ID", Report::"LT SC Meta Report");
        Layout.DeleteAll();
        Layout.Reset();
        Layout.Init();
        Layout."Report ID" := Report::"LT SC Meta Report";
        Layout.Name := 'LT Y6 Probe Layout';
        Layout."Layout Format" := Layout."Layout Format"::RDLC;
        Layout.Description := 'Y6 probe';
        Report.RdlcLayout(Report::"LT SC Meta Report", InS);
        Layout.Layout.ImportStream(InS, 'Y6 probe layout');
        Observer.Observe('layout has value before insert', Format(Layout.Layout.HasValue()));
        Ok := Layout.Insert();
        Observer.Observe('insert answer', Format(Ok));
        Layout.SetRange("Report ID", Report::"LT SC Meta Report");
        Observer.Observe('rows after insert', Format(Layout.Count()));
        if Layout.FindFirst() then
            Observer.Observe('stored', Layout.Name + '|' + Layout."Company Name" + '|' + Format(Layout."Layout Format") + '|' + Layout.Description + '|' + Layout."MIME Type" + '|' + Format(IsNullGuid(Layout."App ID")) + '|' + Format(Layout.Layout.HasValue()));
        ReadBack.SetRange("Report ID", Report::"LT SC Meta Report");
        ReadBack.SetRange(Name, 'LT Y6 Probe Layout');
        Observer.Observe('found by name', Format(ReadBack.FindFirst()));
        Ok := Layout.Insert();
        Observer.Observe('second insert answer', Format(Ok));
        Layout.DeleteAll();
        Observer.Observe('rows after delete', Format(Layout.Count()));
        Observer.Expect('layout has value before insert', 'Yes');
        Observer.Expect('insert answer', 'Yes');
        Observer.Expect('rows after insert', '1');
        Observer.Expect('stored', 'LT Y6 Probe Layout||RDLC|Y6 probe||Yes|Yes');
        Observer.Expect('found by name', 'Yes');
        Observer.Expect('second insert answer', 'No');
        Observer.Expect('rows after delete', '0');
        Observer.Verify();
    end;

    // ---- cw-waldo5 (al-runner 6924, waldo): Insert into Tenant Report Layout for a report of ANOTHER app (Base Application's report 1306
    // "Standard Sales - Invoice", a dependency app's report), the way a test library adds a custom Word layout / e-mail body layout ----
    local procedure W5Dump(var L: Record "Tenant Report Layout") Result: Text
    var
        RR: RecordRef;
        FR: FieldRef;
        i: Integer;
    begin
        RR.GetTable(L);
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if not (FR.Type() in [FieldType::Media, FieldType::MediaSet, FieldType::Blob]) then
                Result += Format(FR.Number()) + ' ' + FR.Name() + '=' + Format(FR.Value()) + '; ';
        end;
    end;


    local procedure W5WordRow(var L: Record "Tenant Report Layout"; ReportId: Integer; LayoutName: Text[250])
    var
        InS: InStream;
    begin
        L.Init();
        L."Report ID" := ReportId;
        L.Name := LayoutName;
        L."Layout Format" := L."Layout Format"::Word;
        L.Description := 'W5 custom body';
        Report.WordLayout(Report::"LT Y67 Lay Base", InS);
        L.Layout.ImportStream(InS, 'W5 word layout');
    end;

    local procedure W5Insert(var Observer: Codeunit "Probe Observer"; Tag: Text; var L: Record "Tenant Report Layout")
    var
        Reader: Record "Tenant Report Layout";
    begin
        Reader.SetRange("Report ID", L."Report ID");
        Observer.Observe(Tag + ' rows before', Format(Reader.Count()));
        Observer.Observe(Tag + ' insert', Format(L.Insert()));
        Observer.Observe(Tag + ' rows after', Format(Reader.Count()));
        Reader.SetRange(Name, L.Name);
        if Reader.FindFirst() then begin
            Observer.Observe(Tag + ' stored', W5Dump(Reader) + 'Layout.HasValue=' + Format(Reader.Layout.HasValue()));
        end else
            Observer.Observe(Tag + ' stored', 'no row');
    end;

    [Test]
    procedure W5_TenantReportLayout_AllFields()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
        RR: RecordRef;
        FR: FieldRef;
        i: Integer;
        Names: Text;
    begin
        RR.GetTable(L);
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            Names += Format(FR.Number()) + ':' + FR.Name() + ':' + Format(FR.Type()) + ',';
        end;
        Observer.Observe('table id', Format(RR.Number()));
        Observer.Observe('fields', Names);
        Observer.Finish();
    end;

    [Test]
    procedure W5_TenantReportLayout_MicrosoftReport_WordLayout()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
        List: Record "Report Layout List";
    begin
        List.SetRange("Report ID", Report::"Standard Sales - Invoice");
        Observer.Observe('list rows before', Format(List.Count()));
        W5WordRow(L, Report::"Standard Sales - Invoice", 'LT W5 Custom Body');
        W5Insert(Observer, 'ms word', L);
        List.SetRange(Name, 'LT W5 Custom Body');
        Observer.Observe('list row found', Format(List.FindFirst()));
        if List.FindFirst() then
            Observer.Observe('list row', Format(List."Layout Format") + '|' + List.Caption + '|' + Format(List."User Defined") + '|' + List."Layout Publisher" + '|' + List."Report Name" + '|' + Format(List."Application ID") + '|' + Format(List.ReportIsInstalled));
        List.SetRange(Name);
        Observer.Observe('list rows after', Format(List.Count()));
        L.SetRange("Report ID", Report::"Standard Sales - Invoice");
        L.DeleteAll();
        Observer.Observe('rows after delete', Format(L.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure W5_TenantReportLayout_MicrosoftReport_ItsOwnWordLayoutStream()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
        InS: InStream;
    begin
        L.Init();
        L."Report ID" := Report::"Standard Sales - Invoice";
        L.Name := 'LT W5 Own Stream';
        L."Layout Format" := L."Layout Format"::Word;
        Report.WordLayout(Report::"Standard Sales - Invoice", InS);
        L.Layout.ImportStream(InS, 'the report''s own word layout');
        W5Insert(Observer, 'standard invoice own word layout', L);
        Observer.Finish();
    end;

    [Test]
    procedure W5_TenantReportLayout_MicrosoftReport_CompanyNameSet()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
    begin
        W5WordRow(L, Report::"Standard Sales - Invoice", 'LT W5 Company');
        L."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(L."Company Name"));
        W5Insert(Observer, 'company set', L);
        Observer.Finish();
    end;

    [Test]
    procedure W5_TenantReportLayout_MicrosoftReport_AppIdOfBaseApplication()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
    begin
        W5WordRow(L, Report::"Standard Sales - Invoice", 'LT W5 BaseApp Id');
        L."App ID" := '{437DBF0E-84FF-417A-965D-ED2BB9650972}';
        W5Insert(Observer, 'base app id', L);
        Observer.Finish();
    end;

    [Test]
    procedure W5_TenantReportLayout_MicrosoftReport_AppIdOfCorpusApp()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
    begin
        W5WordRow(L, Report::"Standard Sales - Invoice", 'LT W5 Own Id');
        L."App ID" := '{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}';
        W5Insert(Observer, 'corpus app id', L);
        Observer.Finish();
    end;

    [Test]
    procedure W5_TenantReportLayout_MicrosoftReport_DuplicateInsert()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
    begin
        W5WordRow(L, Report::"Standard Sales - Invoice", 'LT W5 Dup');
        W5Insert(Observer, 'dup first', L);
        W5Insert(Observer, 'dup second', L);
        Observer.Finish();
    end;

    [Test]
    procedure W5_TenantReportLayout_MicrosoftReport_WordWithoutLayout()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
    begin
        L.Init();
        L."Report ID" := Report::"Standard Sales - Invoice";
        L.Name := 'LT W5 Empty Word';
        L."Layout Format" := L."Layout Format"::Word;
        W5Insert(Observer, 'word empty', L);
        Observer.Finish();
    end;

    [Test]
    procedure W5_TenantReportLayout_MicrosoftReport_RdlcFormatWithWordBytes()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
        InS: InStream;
    begin
        L.Init();
        L."Report ID" := Report::"Standard Sales - Invoice";
        L.Name := 'LT W5 Rdlc Format';
        L."Layout Format" := L."Layout Format"::RDLC;
        Report.WordLayout(Report::"Standard Sales - Invoice", InS);
        L.Layout.ImportStream(InS, 'word bytes as rdlc');
        W5Insert(Observer, 'rdlc format word bytes', L);
        Observer.Finish();
    end;

    [Test]
    procedure W5_TenantReportLayout_MicrosoftReport_ExcelFormatWithWordBytes()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
    begin
        W5WordRow(L, Report::"Standard Sales - Invoice", 'LT W5 Excel Format');
        L."Layout Format" := L."Layout Format"::Excel;
        W5Insert(Observer, 'excel format word bytes', L);
        Observer.Finish();
    end;

    [Test]
    procedure W5_TenantReportLayout_MicrosoftReport_EmptyName()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
    begin
        W5WordRow(L, Report::"Standard Sales - Invoice", '');
        W5Insert(Observer, 'empty name', L);
        Observer.Finish();
    end;

    [Test]
    procedure W5_TenantReportLayout_DependencyAppReport()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
    begin
        W5WordRow(L, 61352, 'LT W5 Dependency');
        W5Insert(Observer, 'xapp-a report', L);
        Observer.Finish();
    end;

    [Test]
    procedure W5_TenantReportLayout_UnknownReportId()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
    begin
        W5WordRow(L, 99999999, 'LT W5 Unknown');
        W5Insert(Observer, 'unknown report', L);
        Observer.Finish();
    end;

    [Test]
    procedure W5_TenantReportLayout_ReportIdZero()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
    begin
        W5WordRow(L, 0, 'LT W5 Zero');
        W5Insert(Observer, 'report zero', L);
        Observer.Finish();
    end;

    [Test]
    procedure W5_TenantReportLayout_OwnReportWordLayout()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
    begin
        W5WordRow(L, Report::"Probe RL Report", 'LT W5 Own Probe');
        W5Insert(Observer, 'own report word', L);
        Observer.Finish();
    end;

    [Test]
    procedure W5_TenantReportLayout_ReportSelection_EmailBody()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
        RS: Record "Report Selections";
    begin
        RS.SetRange(Usage, RS.Usage::"S.Invoice");
        Observer.Observe('existing S.Invoice selections', Format(RS.Count()));
        RS.DeleteAll();
        RS.Reset();
        RS.Init();
        RS.Usage := RS.Usage::"S.Invoice";
        RS.Sequence := 'W5';
        RS."Report ID" := Report::"Standard Sales - Invoice";
        RS."Use for Email Body" := true;
        Observer.Observe('selection insert', Format(RS.Insert(true)));
        asserterror RS.Validate("Email Body Layout Name", 'LT W5 Custom Body');
        Observer.ObserveError('validate name before layout exists');
        W5WordRow(L, Report::"Standard Sales - Invoice", 'LT W5 Custom Body');
        W5Insert(Observer, 'ms word', L);
        RS.Validate("Email Body Layout Name", 'LT W5 Custom Body');
        Observer.Observe('validate name after layout exists', 'ok');
        Observer.Observe('modify', Format(RS.Modify(true)));
        RS.Get(RS.Usage::"S.Invoice", 'W5');
        RS.CalcFields("Email Body Layout Publisher", "Email Body Layout Caption");
        Observer.Observe('selection', RS."Email Body Layout Name" + '|' + Format(RS."Email Body Layout AppID") + '|' + Format(RS."Email Body Layout Type") + '|' + RS."Email Body Layout Publisher" + '|' + RS."Email Body Layout Caption" + '|' + Format(RS."Use for Email Body"));
        Observer.Finish();
    end;
}
