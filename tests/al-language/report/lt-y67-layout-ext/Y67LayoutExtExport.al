// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-exportstream-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 93540, report 93541, report extensions 93542-93543, codeunit 93544; layout files Y67*.docx/.rdl/.xlsx in this folder (copies of the Y17 layout files of report/lt-y17-layout-export/)
// Probe (gap cycle 6 follow-up): Media.ExportStream on the Layout column of a Report Layout List row whose layout is declared in the rendering
//   section of a REPORT EXTENSION (Word, RDLC, Excel; a layout name with a dot in it), of an own report and of Base Application's report 1306
//   "Standard Sales - Invoice": the rows the extension adds (Name, Layout Format, Caption, Report ID), the answer of ExportStream, the length,
//   the SHA-256 of the bytes, HasValue before and after. report/lt-y17-layout-export/Y17LayoutExportTests.al pins the layouts of a report's own
//   rendering section and the legacy properties.
// The bytes of the Base Application report's layout depend on the BC version (its data set), so their length and hash are observed but not asserted.
// BC versions: 27, 28, 29

table 93540 "LT Y67 Lay Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

report 93541 "LT Y67 Lay Base"
{
    DefaultRenderingLayout = BaseDoc;

    dataset
    {
        dataitem(D; "LT Y67 Lay Row")
        {
            column(No_; "No.") { }
            column(Name_; Name) { }
        }
    }

    rendering
    {
        layout(BaseDoc)
        {
            Type = Word;
            LayoutFile = './report/lt-y67-layout-ext/Y67BaseDoc.docx';
        }
    }
}

reportextension 93542 "LT Y67 Lay Base Ext" extends "LT Y67 Lay Base"
{
    rendering
    {
        layout(ExtDoc)
        {
            Type = Word;
            LayoutFile = './report/lt-y67-layout-ext/Y67ExtDoc.docx';
            Caption = 'Y67 ext word';
        }
        layout(ExtRdl)
        {
            Type = RDLC;
            LayoutFile = './report/lt-y67-layout-ext/Y67ExtRdl.rdl';
            Caption = 'Y67 ext rdlc';
        }
        layout(ExtXls)
        {
            Type = Excel;
            LayoutFile = './report/lt-y67-layout-ext/Y67ExtXls.xlsx';
            Caption = 'Y67 ext excel';
        }
        layout("Y67Dotted.docx")
        {
            Type = Word;
            LayoutFile = './report/lt-y67-layout-ext/Y67ExtDoc.docx';
        }
    }
}

reportextension 93543 "LT Y67 Lay Std Ext" extends "Standard Sales - Invoice"
{
    rendering
    {
        layout("Y67StdExt.docx")
        {
            Type = Word;
            LayoutFile = './report/lt-y67-layout-ext/Y67StdExt.docx';
            Caption = 'Y67 std ext word';
        }
    }
}

codeunit 93544 "LT Y67 Lay Ext Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(var Observer: Codeunit "Probe Observer"; Name: Text; ReportId: Integer; LayoutName: Text; WithRows: Boolean)
    var
        LayoutList: Record "Report Layout List";
        TempBlob: Codeunit "Temp Blob";
        CryptographyManagement: Codeunit "Cryptography Management";
        OutS: OutStream;
        InS: InStream;
        Returned: Boolean;
        HasBefore: Boolean;
    begin
        LayoutList.SetRange("Report ID", ReportId);
        if WithRows then begin
            if LayoutList.FindSet() then
                repeat
                    if LayoutList.Name.Contains('Y67') or LayoutList.Name.Contains('Base') or LayoutList.Name.Contains('Ext') then
                        Observer.Observe(Name + ' row ' + LayoutList.Name, Format(LayoutList."Layout Format") + '|' + LayoutList.Caption);
                until LayoutList.Next() = 0;
        end;
        LayoutList.SetRange(Name, LayoutName);
        Observer.Observe(Name + ' count', Format(LayoutList.Count()));
        if not LayoutList.FindFirst() then
            exit;
        Observer.Observe(Name + ' format', Format(LayoutList."Layout Format"));
        HasBefore := LayoutList.Layout.HasValue();
        Observer.Observe(Name + ' has value before', Format(HasBefore));
        TempBlob.CreateOutStream(OutS);
        Returned := LayoutList.Layout.ExportStream(OutS);
        Observer.Observe(Name + ' returned', Format(Returned));
        Observer.Observe(Name + ' length', Format(TempBlob.Length()));
        TempBlob.CreateInStream(InS);
        Observer.Observe(Name + ' sha256', CryptographyManagement.GenerateHash(InS, 2));
        Observer.Observe(Name + ' has value after', Format(LayoutList.Layout.HasValue()));
    end;

    [Test]
    procedure Export_ExtensionLayouts_OwnReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(Observer, 'word', Report::"LT Y67 Lay Base", 'ExtDoc', true);
        Describe(Observer, 'rdlc', Report::"LT Y67 Lay Base", 'ExtRdl', false);
        Describe(Observer, 'excel', Report::"LT Y67 Lay Base", 'ExtXls', false);
        Describe(Observer, 'dotted', Report::"LT Y67 Lay Base", 'Y67Dotted.docx', false);
        Describe(Observer, 'base', Report::"LT Y67 Lay Base", 'BaseDoc', false);
        Observer.Expect('word row BaseDoc', 'Word|BaseDoc');
        Observer.Expect('word row ExtDoc', 'Word|Y67 ext word');
        Observer.Expect('word row ExtRdl', 'RDLC|Y67 ext rdlc');
        Observer.Expect('word row ExtXls', 'Excel|Y67 ext excel');
        Observer.Expect('word row Y67Dotted.docx', 'Word|Y67Dotted.docx');
        Observer.Expect('word count', '1');
        Observer.Expect('word format', 'Word');
        Observer.Expect('word has value before', 'No');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word length', '5461');
        Observer.Expect('word sha256', '19F3A4D0ECA2621C6D4DE586DC6494E48E7087DDF3BF3668DF553A7ADD71E4CE');
        Observer.Expect('word has value after', 'No');
        Observer.Expect('rdlc count', '1');
        Observer.Expect('rdlc format', 'RDLC');
        Observer.Expect('rdlc has value before', 'No');
        Observer.Expect('rdlc returned', 'Yes');
        Observer.Expect('rdlc length', '2104');
        Observer.Expect('rdlc sha256', 'E28FAC5DB3F79B65DE60707DDBED8F5306BE7605DC4D9A71E1BF2597E440B5EF');
        Observer.Expect('rdlc has value after', 'No');
        Observer.Expect('excel count', '1');
        Observer.Expect('excel format', 'Excel');
        Observer.Expect('excel has value before', 'No');
        Observer.Expect('excel returned', 'Yes');
        Observer.Expect('excel length', '20314');
        Observer.Expect('excel sha256', 'B7748123A94313033D504A565EBB4C708BFD0B5CB9EBD95BB61223A80148BF0D');
        Observer.Expect('excel has value after', 'No');
        Observer.Expect('dotted count', '1');
        Observer.Expect('dotted format', 'Word');
        Observer.Expect('dotted has value before', 'No');
        Observer.Expect('dotted returned', 'Yes');
        Observer.Expect('dotted length', '5461');
        Observer.Expect('dotted sha256', '19F3A4D0ECA2621C6D4DE586DC6494E48E7087DDF3BF3668DF553A7ADD71E4CE');
        Observer.Expect('dotted has value after', 'No');
        Observer.Expect('base count', '1');
        Observer.Expect('base format', 'Word');
        Observer.Expect('base has value before', 'No');
        Observer.Expect('base returned', 'Yes');
        Observer.Expect('base length', '5460');
        Observer.Expect('base sha256', 'B82EAA8624E94F46A51BCD30DE051FD577C3FC6F4993F50AE70E215AAF6B3B1B');
        Observer.Expect('base has value after', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Export_ExtensionLayout_BaseApplicationReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(Observer, 'std', Report::"Standard Sales - Invoice", 'Y67StdExt.docx', false);
        Observer.Expect('std count', '1');
        Observer.Expect('std format', 'Word');
        Observer.Expect('std has value before', 'No');
        Observer.Expect('std returned', 'Yes');
        Observer.Ignore('std length');
        Observer.Ignore('std sha256');
        Observer.Expect('std has value after', 'No');
        Observer.Verify();
    end;
}
