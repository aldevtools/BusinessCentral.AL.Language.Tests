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
}

// local object: a second test codeunit in this file because these tests insert and delete rows of Tenant Report Layout and Report Selections,
// so rows roll back after each test (TestIsolation = Function), which codeunit 91312 above does not have.
codeunit 96181 "LT W5 Tenant Layout"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestIsolation = Function;

    // ---- cw-waldo5 (al-runner 6924, waldo): Insert into Tenant Report Layout for a report of ANOTHER app (Base Application's report 1306
    // "Standard Sales - Invoice", a dependency app's report), the way a test library adds a custom Word layout / e-mail body layout.
    // The Word stream is that of the corpus report "LT Y67 Lay Base" (an empty document body, valid for any report); the report's own default
    // Word layout carries an attachedTemplate reference that BC 27 and 28 refuse and BC 29 accepts (W5_..._ItsOwnWordLayoutStream). ----
    local procedure W5Dump(var L: Record "Tenant Report Layout") Result: Text
    var
        RR: RecordRef;
        FR: FieldRef;
        i: Integer;
    begin
        RR.GetTable(L);
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if (FR.Number() <= 13) and (FR.Number() <> 6) and not (FR.Type() in [FieldType::Media, FieldType::MediaSet, FieldType::Blob]) then
                Result += FR.Name() + '=' + Format(FR.Value()) + '; ';
        end;
    end;

    // Fields 14 (Layout Status, from BC 28) and 15 (Layout Subtype, from BC 29) exist only on newer versions.
    local procedure W5Extra(var L: Record "Tenant Report Layout") Result: Text
    var
        RR: RecordRef;
        FR: FieldRef;
        i: Integer;
    begin
        RR.GetTable(L);
        for i := 14 to 15 do
            if RR.FieldExist(i) then begin
                FR := RR.Field(i);
                Result += FR.Name() + '=' + Format(FR.Value()) + '; ';
            end;
    end;

    local procedure W5ExpectExtra(var Observer: Codeunit "Probe Observer"; Tag: Text)
    begin
#if BC29PLUS
        Observer.Expect(Tag + ' extra', 'Layout Status=Approved; Layout Subtype=Default; ');
#else
#if BC28PLUS
        Observer.Expect(Tag + ' extra', 'Layout Status=Approved; ');
#else
        Observer.Expect(Tag + ' extra', '');
#endif
#endif
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

    // Insert that is expected to succeed (a failure ends the test with the error text): observes the row counts of the report, the answer, and the stored row.
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
            Observer.Observe(Tag + ' company is current', Format(Reader."Company Name" = CompanyName()));
            Observer.Observe(Tag + ' extra', W5Extra(Reader));
        end else
            Observer.Observe(Tag + ' stored', 'no row');
    end;

    // The first line of a message; BC 27 writes the line breaks of a multi-line message as a backslash pair, so a backslash ends the line as well.
    local procedure W5FirstLine(Msg: Text): Text
    var
        Lf: Text[1];
    begin
        Lf[1] := 10;
        Msg := Msg.Split(Lf).Get(1);
        if StrPos(Msg, '\') > 0 then
            Msg := CopyStr(Msg, 1, StrPos(Msg, '\') - 1);
        exit(Msg);
    end;

    // Insert that is expected to fail: the first line of the error text, the code, and the row count of the report afterwards.
    local procedure W5Fails(var Observer: Codeunit "Probe Observer"; Tag: Text; var L: Record "Tenant Report Layout")
    var
        Reader: Record "Tenant Report Layout";
        Msg: Text;
    begin
        Reader.SetRange("Report ID", L."Report ID");
        asserterror L.Insert();
        Msg := GetLastErrorText();
        // the text names the calling object and the emit version: neither is asserted
        if (StrPos(Msg, ' from the object ') > 0) and (StrPos(Msg, '. An object') > 0) then
            Msg := CopyStr(Msg, 1, StrPos(Msg, ' from the object ') - 1) + CopyStr(Msg, StrPos(Msg, '. An object'));
        if StrPos(Msg, ' compiled with') > 0 then
            Msg := CopyStr(Msg, 1, StrPos(Msg, ' compiled with') - 1);
        Observer.Observe(Tag + ' error', W5FirstLine(Msg));
        Observer.Observe(Tag + ' code', GetLastErrorCode());
        ClearLastError();
        Observer.Observe(Tag + ' rows after', Format(Reader.Count()));
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
        Observer.Expect('table id', '2000000232');
#if BC29PLUS
        Observer.Expect('fields', '1:Report ID:Integer,2:Name:Text,5:App ID:GUID,3:Caption:Text,4:CaptionML:Text,6:Company Name:Text,7:Layout:Media,8:Layout Format:Option,9:Custom Type:GUID,10:MIME Type:Text,11:Description:Text,12:IsObsolete:Boolean,13:ExcelLayoutMultipleDataSheets:Option,14:Layout Status:Option,15:Layout Subtype:Option,');
#else
#if BC28PLUS
        Observer.Expect('fields', '1:Report ID:Integer,2:Name:Text,5:App ID:GUID,3:Caption:Text,4:CaptionML:Text,6:Company Name:Text,7:Layout:Media,8:Layout Format:Option,9:Custom Type:GUID,10:MIME Type:Text,11:Description:Text,12:IsObsolete:Boolean,13:ExcelLayoutMultipleDataSheets:Option,14:Layout Status:Option,');
#else
        Observer.Expect('fields', '1:Report ID:Integer,2:Name:Text,5:App ID:GUID,3:Caption:Text,4:CaptionML:Text,6:Company Name:Text,7:Layout:Media,8:Layout Format:Option,9:Custom Type:GUID,10:MIME Type:Text,11:Description:Text,12:IsObsolete:Boolean,13:ExcelLayoutMultipleDataSheets:Option,');
#endif
#endif
        Observer.Verify();
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
        Observer.Expect('list rows before', '7');
        Observer.Expect('ms word rows before', '0');
        Observer.Expect('ms word insert', 'Yes');
        Observer.Expect('ms word rows after', '1');
        Observer.Expect('ms word stored', 'Report ID=1306; Name=LT W5 Custom Body; App ID={00000000-0000-0000-0000-000000000000}; Caption=; CaptionML=; Layout Format=Word; Custom Type={00000000-0000-0000-0000-000000000000}; MIME Type=; Description=W5 custom body; IsObsolete=No; ExcelLayoutMultipleDataSheets=Default; Layout.HasValue=Yes');
        Observer.Expect('ms word company is current', 'No');
        W5ExpectExtra(Observer, 'ms word');
        Observer.Expect('list row found', 'Yes');
        Observer.Expect('list row', 'Word|LT W5 Custom Body|Yes||Sales - Invoice|{00000000-0000-0000-0000-000000000000}|Yes');
        Observer.Expect('list rows after', '8');
        Observer.Expect('rows after delete', '0');
        Observer.Verify();
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
#if BC29PLUS
        // BC 29 accepts the report's own default Word layout (BC 27 and 28 refuse it, below).
        W5Insert(Observer, 'standard invoice own word layout', L);
        Observer.Expect('standard invoice own word layout rows before', '0');
        Observer.Expect('standard invoice own word layout insert', 'Yes');
        Observer.Expect('standard invoice own word layout rows after', '1');
        Observer.Expect('standard invoice own word layout stored', 'Report ID=1306; Name=LT W5 Own Stream; App ID={00000000-0000-0000-0000-000000000000}; Caption=; CaptionML=; Layout Format=Word; Custom Type={00000000-0000-0000-0000-000000000000}; MIME Type=; Description=; IsObsolete=No; ExcelLayoutMultipleDataSheets=Default; Layout.HasValue=Yes');
        Observer.Expect('standard invoice own word layout company is current', 'No');
        W5ExpectExtra(Observer, 'standard invoice own word layout');
        Observer.Verify();
#else
        W5Fails(Observer, 'standard invoice own word layout', L);
        Observer.Expect('standard invoice own word layout error', 'Errors were detected in the Word layout:');
        Observer.Expect('standard invoice own word layout code', 'ReportLayoutValidation:WordLayoutValidation');
        Observer.Expect('standard invoice own word layout rows after', '0');
        Observer.Verify();
#endif
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
        Observer.Expect('company set rows before', '0');
        Observer.Expect('company set insert', 'Yes');
        Observer.Expect('company set rows after', '1');
        Observer.Expect('company set stored', 'Report ID=1306; Name=LT W5 Company; App ID={00000000-0000-0000-0000-000000000000}; Caption=; CaptionML=; Layout Format=Word; Custom Type={00000000-0000-0000-0000-000000000000}; MIME Type=; Description=W5 custom body; IsObsolete=No; ExcelLayoutMultipleDataSheets=Default; Layout.HasValue=Yes');
        Observer.Expect('company set company is current', 'Yes');
        W5ExpectExtra(Observer, 'company set');
        Observer.Verify();
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
        Observer.Expect('base app id rows before', '0');
        Observer.Expect('base app id insert', 'Yes');
        Observer.Expect('base app id rows after', '1');
        Observer.Expect('base app id stored', 'Report ID=1306; Name=LT W5 BaseApp Id; App ID={437DBF0E-84FF-417A-965D-ED2BB9650972}; Caption=; CaptionML=; Layout Format=Word; Custom Type={00000000-0000-0000-0000-000000000000}; MIME Type=; Description=W5 custom body; IsObsolete=No; ExcelLayoutMultipleDataSheets=Default; Layout.HasValue=Yes');
        Observer.Expect('base app id company is current', 'No');
        W5ExpectExtra(Observer, 'base app id');
        Observer.Verify();
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
        Observer.Expect('corpus app id rows before', '0');
        Observer.Expect('corpus app id insert', 'Yes');
        Observer.Expect('corpus app id rows after', '1');
        Observer.Expect('corpus app id stored', 'Report ID=1306; Name=LT W5 Own Id; App ID={A1B2C3D4-E5F6-7890-ABCD-EF1234567890}; Caption=; CaptionML=; Layout Format=Word; Custom Type={00000000-0000-0000-0000-000000000000}; MIME Type=; Description=W5 custom body; IsObsolete=No; ExcelLayoutMultipleDataSheets=Default; Layout.HasValue=Yes');
        Observer.Expect('corpus app id company is current', 'No');
        W5ExpectExtra(Observer, 'corpus app id');
        Observer.Verify();
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
        Observer.Expect('dup first rows before', '0');
        Observer.Expect('dup first insert', 'Yes');
        Observer.Expect('dup first rows after', '1');
        Observer.Expect('dup first stored', 'Report ID=1306; Name=LT W5 Dup; App ID={00000000-0000-0000-0000-000000000000}; Caption=; CaptionML=; Layout Format=Word; Custom Type={00000000-0000-0000-0000-000000000000}; MIME Type=; Description=W5 custom body; IsObsolete=No; ExcelLayoutMultipleDataSheets=Default; Layout.HasValue=Yes');
        Observer.Expect('dup first company is current', 'No');
        W5ExpectExtra(Observer, 'dup first');
        Observer.Expect('dup second rows before', '1');
        Observer.Expect('dup second insert', 'No');
        Observer.Expect('dup second rows after', '1');
        Observer.Expect('dup second stored', 'Report ID=1306; Name=LT W5 Dup; App ID={00000000-0000-0000-0000-000000000000}; Caption=; CaptionML=; Layout Format=Word; Custom Type={00000000-0000-0000-0000-000000000000}; MIME Type=; Description=W5 custom body; IsObsolete=No; ExcelLayoutMultipleDataSheets=Default; Layout.HasValue=Yes');
        Observer.Expect('dup second company is current', 'No');
        W5ExpectExtra(Observer, 'dup second');
        Observer.Verify();
    end;

    [Test]
    procedure W5_TenantReportLayout_MicrosoftReport_EmptyName()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
    begin
        W5WordRow(L, Report::"Standard Sales - Invoice", '');
        W5Insert(Observer, 'empty name', L);
        Observer.Expect('empty name rows before', '0');
        Observer.Expect('empty name insert', 'Yes');
        Observer.Expect('empty name rows after', '1');
        Observer.Expect('empty name stored', 'Report ID=1306; Name=; App ID={00000000-0000-0000-0000-000000000000}; Caption=; CaptionML=; Layout Format=Word; Custom Type={00000000-0000-0000-0000-000000000000}; MIME Type=; Description=W5 custom body; IsObsolete=No; ExcelLayoutMultipleDataSheets=Default; Layout.HasValue=Yes');
        Observer.Expect('empty name company is current', 'No');
        W5ExpectExtra(Observer, 'empty name');
        Observer.Verify();
    end;

    [Test]
    procedure W5_TenantReportLayout_OwnReportWordLayout()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
    begin
        W5WordRow(L, Report::"Probe RL Report", 'LT W5 Own Probe');
        W5Insert(Observer, 'own report word', L);
        Observer.Expect('own report word rows before', '0');
        Observer.Expect('own report word insert', 'Yes');
        Observer.Expect('own report word rows after', '1');
        Observer.Expect('own report word stored', 'Report ID=69083; Name=LT W5 Own Probe; App ID={00000000-0000-0000-0000-000000000000}; Caption=; CaptionML=; Layout Format=Word; Custom Type={00000000-0000-0000-0000-000000000000}; MIME Type=; Description=W5 custom body; IsObsolete=No; ExcelLayoutMultipleDataSheets=Default; Layout.HasValue=Yes');
        Observer.Expect('own report word company is current', 'No');
        W5ExpectExtra(Observer, 'own report word');
        Observer.Verify();
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
        W5Fails(Observer, 'word empty', L);
        Observer.Expect('word empty error', 'The current operation cannot be performed on an empty report layout of type Word for report 1306.');
        Observer.Expect('word empty code', 'ReportLayoutValidation');
        Observer.Expect('word empty rows after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure W5_TenantReportLayout_DependencyAppReport()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
    begin
        W5WordRow(L, 61352, 'LT W5 Dependency');
        W5Fails(Observer, 'xapp-a report', L);
        Observer.Expect('xapp-a report error', 'Report 61352 is a processing-only report. It does not support report layouts.');
        Observer.Expect('xapp-a report code', 'InvalidOperation');
        Observer.Expect('xapp-a report rows after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure W5_TenantReportLayout_UnknownReportId()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
    begin
        W5WordRow(L, 99999999, 'LT W5 Unknown');
        W5Fails(Observer, 'unknown report', L);
        Observer.Expect('unknown report error', 'You tried to invoke the Report object with the ID 99999999. An object with that ID does not exist in the current application');
        Observer.Expect('unknown report code', 'AL:MetadataNotFound');
        Observer.Expect('unknown report rows after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure W5_TenantReportLayout_ReportIdZero()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
    begin
        W5WordRow(L, 0, 'LT W5 Zero');
        W5Fails(Observer, 'report zero', L);
        Observer.Expect('report zero error', 'You tried to invoke the Report object with the ID 0. An object with that ID does not exist in the current application');
        Observer.Expect('report zero code', 'AL:MetadataNotFound');
        Observer.Expect('report zero rows after', '0');
        Observer.Verify();
    end;

    local procedure W5SelectionRow(var RS: Record "Report Selections"; Seq: Code[10])
    begin
        RS.Init();
        RS.Usage := RS.Usage::"S.Invoice";
        RS.Sequence := Seq;
        RS."Report ID" := Report::"Standard Sales - Invoice";
        RS."Use for Email Body" := true;
    end;

    local procedure W5NoSelections()
    var
        RS: Record "Report Selections";
    begin
        RS.SetRange(Usage, RS.Usage::"S.Invoice");
        RS.DeleteAll();
    end;

    [Test]
    procedure W5_ReportSelection_SecondEmailBodyRow_Refused()
    var
        Observer: Codeunit "Probe Observer";
        RS: Record "Report Selections";
    begin
        W5NoSelections();
        W5SelectionRow(RS, '1');
        Observer.Observe('first insert', Format(RS.Insert(true)));
        W5SelectionRow(RS, '2');
        asserterror RS.Insert(true);
        Observer.ObserveError('second insert');
        Observer.Finish();
    end;

    [Test]
    procedure W5_ReportSelection_EmailBodyLayout_NameOfTenantRow()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "Tenant Report Layout";
        RS: Record "Report Selections";
    begin
        W5NoSelections();
        W5WordRow(L, Report::"Standard Sales - Invoice", 'LT W5 Custom Body');
        L.Insert();
        W5SelectionRow(RS, '1');
        RS.Insert(true);
        asserterror RS.Validate("Email Body Layout Name", 'LT W5 No Such Layout');
        Observer.ObserveError('validate unknown layout name');
        asserterror RS.Validate("Email Body Layout Name", 'LT W5 Custom Body');
        Observer.ObserveError('validate tenant layout name');
        RS."Email Body Layout Name" := 'LT W5 Custom Body';
        Observer.Observe('assigned name modify', Format(RS.Modify(true)));
        RS.Get(RS.Usage::"S.Invoice", '1');
        RS.CalcFields("Email Body Layout Publisher", "Email Body Layout Caption");
        Observer.Observe('selection', RS."Email Body Layout Name" + '|' + Format(RS."Email Body Layout AppID") + '|' + Format(RS."Email Body Layout Type") + '|' + RS."Email Body Layout Publisher" + '|' + RS."Email Body Layout Caption" + '|' + Format(RS."Use for Email Body"));
        Observer.Finish();
    end;

    [Test]
    procedure W5_ReportSelection_EmailBodyLayout_NameOfBuiltInLayout()
    var
        Observer: Codeunit "Probe Observer";
        List: Record "Report Layout List";
        RS: Record "Report Selections";
    begin
        W5NoSelections();
        List.SetRange("Report ID", Report::"Standard Sales - Invoice");
        List.FindFirst();
        W5SelectionRow(RS, '1');
        RS.Insert(true);
        RS.Validate("Email Body Layout Name", List.Name);
        Observer.Observe('validate built-in layout name', 'ok');
        Observer.Observe('modify', Format(RS.Modify(true)));
        Observer.Observe('name equals', Format(RS."Email Body Layout Name" = List.Name));
        Observer.Observe('app id equals', Format(RS."Email Body Layout AppID" = List."Application ID"));
        Observer.Finish();
    end;
}
