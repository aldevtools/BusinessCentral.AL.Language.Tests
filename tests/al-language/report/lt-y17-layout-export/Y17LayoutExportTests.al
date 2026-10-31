// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-exportstream-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); objects and layout files of Y17LayoutExportObjects.al
// Probe: gap cycle 1, G7 (corpus writer Y17). The bytes Media.ExportStream writes for the Layout column of a Report Layout List row of an own
// report (RDLC and Word from a rendering section, RDLC and Word from the legacy properties, Excel): the answer, the length, the SHA-256 of the
// bytes, the text of an RDLC, the zip entry names of a docx/xlsx, HasValue, and a second export. The package holds these bytes (alc 30.0.44):
//   Y17LayR1.rdl 2104 E28FAC5DB3F79B65DE60707DDBED8F5306BE7605DC4D9A71E1BF2597E440B5EF (Y17LayR2.rdl the same bytes)
//   Y17LayR1.docx 5451 25B756A06026DA7354BB7B74594C2D18B14B1EB15B644949A5EB46D969B5804E
//   Y17LayR2.docx 5452 0777380211152B718E6968A572C6AC17A2A709965B1C43F4EEC5A90F3D1A11B9
//   Y17LayR4.xlsx 20314 B7748123A94313033D504A565EBB4C708BFD0B5CB9EBD95BB61223A80148BF0D
// BC versions: 27-29

codeunit 91855 "LT Y17 Layout Export Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(var Observer: Codeunit "Probe Observer"; Name: Text; ReportId: Integer; LayoutFormat: Option; WithText: Boolean; WithZip: Boolean)
    var
        LayoutList: Record "Report Layout List";
        TempBlob: Codeunit "Temp Blob";
        CryptographyManagement: Codeunit "Cryptography Management";
        DataCompression: Codeunit "Data Compression";
        OutS: OutStream;
        InS: InStream;
        Entries: List of [Text];
        Entry: Text;
        Line: Text;
        Content: Text;
        Returned: Boolean;
    begin
        LayoutList.SetRange("Report ID", ReportId);
        LayoutList.SetRange("Layout Format", LayoutFormat);
        Observer.Observe(Name + ' rows', Format(LayoutList.Count()));
        if not LayoutList.FindFirst() then
            exit;
        Observer.Observe(Name + ' layout name', LayoutList.Name);
        TempBlob.CreateOutStream(OutS);
        Returned := LayoutList.Layout.ExportStream(OutS);
        Observer.Observe(Name + ' returned', Format(Returned));
        Observer.Observe(Name + ' length', Format(TempBlob.Length()));
        Observer.Observe(Name + ' has value after', Format(LayoutList.Layout.HasValue()));
        TempBlob.CreateInStream(InS);
        Observer.Observe(Name + ' sha256', CryptographyManagement.GenerateHash(InS, 2));
        if WithText then begin
            TempBlob.CreateInStream(InS, TextEncoding::UTF8);
            while not InS.EOS() do begin
                InS.ReadText(Line);
                Content += Line + '|';
            end;
            Observer.Observe(Name + ' starts', CopyStr(Content, 1, 60));
            if StrPos(Content, '<DataSets>') > 0 then
                Observer.Observe(Name + ' datasets', CopyStr(Content, StrPos(Content, '<DataSets>'), StrPos(Content, '</DataSets>') - StrPos(Content, '<DataSets>') + 11))
            else
                Observer.Observe(Name + ' datasets', 'none');
        end;
        if WithZip then begin
            TempBlob.CreateInStream(InS);
            ClearLastError();
            DataCompression.OpenZipArchive(InS, false);
            DataCompression.GetEntryList(Entries);
            foreach Entry in Entries do
                Content += Entry + ';';
            DataCompression.CloseZipArchive();
            Observer.Observe(Name + ' entries', Content);
        end;
    end;

    [Test]
    procedure Export_Rdlc_RenderingSection()
    var
        LayoutList: Record "Report Layout List";
        Observer: Codeunit "Probe Observer";
    begin
        Describe(Observer, 'rdlc', Report::"LT Y17 Lay R1", LayoutList."Layout Format"::RDLC, true, false);
        Observer.Finish();
    end;

    [Test]
    procedure Export_Word_RenderingSection()
    var
        LayoutList: Record "Report Layout List";
        Observer: Codeunit "Probe Observer";
    begin
        Describe(Observer, 'word', Report::"LT Y17 Lay R1", LayoutList."Layout Format"::Word, false, true);
        Observer.Finish();
    end;

    [Test]
    procedure Export_LegacyProperties()
    var
        LayoutList: Record "Report Layout List";
        Observer: Codeunit "Probe Observer";
    begin
        Describe(Observer, 'rdlc', Report::"LT Y17 Lay R2", LayoutList."Layout Format"::RDLC, false, false);
        Describe(Observer, 'word', Report::"LT Y17 Lay R2", LayoutList."Layout Format"::Word, false, true);
        Observer.Finish();
    end;

    [Test]
    procedure Export_Excel()
    var
        LayoutList: Record "Report Layout List";
        Observer: Codeunit "Probe Observer";
    begin
        Describe(Observer, 'excel', Report::"LT Y17 Lay R4", LayoutList."Layout Format"::Excel, false, true);
        Observer.Finish();
    end;

    [Test]
    procedure Export_Twice()
    var
        LayoutList: Record "Report Layout List";
        Observer: Codeunit "Probe Observer";
    begin
        Describe(Observer, 'first', Report::"LT Y17 Lay R1", LayoutList."Layout Format"::RDLC, false, false);
        Describe(Observer, 'second', Report::"LT Y17 Lay R1", LayoutList."Layout Format"::RDLC, false, false);
        Observer.Finish();
    end;
}
