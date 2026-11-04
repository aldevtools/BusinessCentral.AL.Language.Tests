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
        Observer.Expect('rdlc rows', '1');
        Observer.Expect('rdlc layout name', 'Rdl1');
        Observer.Expect('rdlc returned', 'Yes');
        Observer.Expect('rdlc length', '2104');
        Observer.Expect('rdlc has value after', 'No');
        Observer.Expect('rdlc sha256', 'E28FAC5DB3F79B65DE60707DDBED8F5306BE7605DC4D9A71E1BF2597E440B5EF');
        Observer.Expect('rdlc starts', '<?xml version="1.0" encoding="utf-8"?>|<Report xmlns="http:/');
        Observer.Expect('rdlc datasets', '<DataSets>|    <DataSet Name="DataSet_Result">|      <Fields>|        <Field Name="No_">|          <DataField>No_</DataField>|        </Field>|        <Field Name="Name_">|          <DataField>Name_</DataField>|        </Field>|      </Fields>|      <Query>|        <DataSourceName>DataSource</DataSourceName>|        <CommandText />|      </Query>|    </DataSet>|  </DataSets>');
        Observer.Verify();
    end;

    [Test]
    procedure Export_Word_RenderingSection()
    var
        LayoutList: Record "Report Layout List";
        Observer: Codeunit "Probe Observer";
    begin
        Describe(Observer, 'word', Report::"LT Y17 Lay R1", LayoutList."Layout Format"::Word, false, true);
        Observer.Expect('word rows', '1');
        Observer.Expect('word layout name', 'Doc1');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word length', '5451');
        Observer.Expect('word has value after', 'No');
        Observer.Expect('word sha256', '25B756A06026DA7354BB7B74594C2D18B14B1EB15B644949A5EB46D969B5804E');
        Observer.Expect('word entries', 'word/document.xml;docProps/app.xml;word/settings.xml;customXml/item.xml;customXml/item2.xml;_rels/.rels;word/_rels/document.xml.rels;[Content_Types].xml;');
        Observer.Verify();
    end;

    [Test]
    procedure Export_LegacyProperties()
    var
        LayoutList: Record "Report Layout List";
        Observer: Codeunit "Probe Observer";
    begin
        Describe(Observer, 'rdlc', Report::"LT Y17 Lay R2", LayoutList."Layout Format"::RDLC, false, false);
        Describe(Observer, 'word', Report::"LT Y17 Lay R2", LayoutList."Layout Format"::Word, false, true);
        Observer.Expect('rdlc rows', '1');
        Observer.Expect('rdlc layout name', './report/lt-y17-layout-export/Y17LayR2.rdl');
        Observer.Expect('rdlc returned', 'Yes');
        Observer.Expect('rdlc length', '2104');
        Observer.Expect('rdlc has value after', 'No');
        Observer.Expect('rdlc sha256', 'E28FAC5DB3F79B65DE60707DDBED8F5306BE7605DC4D9A71E1BF2597E440B5EF');
        Observer.Expect('word rows', '1');
        Observer.Expect('word layout name', './report/lt-y17-layout-export/Y17LayR2.docx');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word length', '5452');
        Observer.Expect('word has value after', 'No');
        Observer.Expect('word sha256', '0777380211152B718E6968A572C6AC17A2A709965B1C43F4EEC5A90F3D1A11B9');
        Observer.Expect('word entries', 'word/document.xml;docProps/app.xml;word/settings.xml;customXml/item.xml;customXml/item2.xml;_rels/.rels;word/_rels/document.xml.rels;[Content_Types].xml;');
        Observer.Verify();
    end;

    [Test]
    procedure Export_Excel()
    var
        LayoutList: Record "Report Layout List";
        Observer: Codeunit "Probe Observer";
    begin
        Describe(Observer, 'excel', Report::"LT Y17 Lay R4", LayoutList."Layout Format"::Excel, false, true);
        Observer.Expect('excel rows', '1');
        Observer.Expect('excel layout name', 'Xls4');
        Observer.Expect('excel returned', 'Yes');
        Observer.Expect('excel length', '20314');
        Observer.Expect('excel has value after', 'No');
        Observer.Expect('excel sha256', 'B7748123A94313033D504A565EBB4C708BFD0B5CB9EBD95BB61223A80148BF0D');
        Observer.Expect('excel entries', '[Content_Types].xml;_rels/.rels;xl/workbook.xml;xl/_rels/workbook.xml.rels;xl/worksheets/sheet1.xml;xl/worksheets/sheet2.xml;xl/worksheets/sheet3.xml;xl/worksheets/sheet4.xml;xl/theme/theme1.xml;xl/styles.xml;xl/sharedStrings.xml;xl/worksheets/_rels/sheet1.xml.rels;xl/worksheets/_rels/sheet2.xml.rels;xl/worksheets/_rels/sheet3.xml.rels;xl/worksheets/_rels/sheet4.xml.rels;xl/tables/table1.xml;xl/tables/table2.xml;xl/tables/table3.xml;xl/tables/table4.xml;xl/tables/table5.xml;xl/tables/table6.xml;xl/tables/table7.xml;docMetadata/LabelInfo.xml;docProps/core.xml;docProps/app.xml;');
        Observer.Verify();
    end;

    [Test]
    procedure Export_Twice()
    var
        LayoutList: Record "Report Layout List";
        Observer: Codeunit "Probe Observer";
    begin
        Describe(Observer, 'first', Report::"LT Y17 Lay R1", LayoutList."Layout Format"::RDLC, false, false);
        Describe(Observer, 'second', Report::"LT Y17 Lay R1", LayoutList."Layout Format"::RDLC, false, false);
        Observer.Expect('first rows', '1');
        Observer.Expect('first layout name', 'Rdl1');
        Observer.Expect('first returned', 'Yes');
        Observer.Expect('first length', '2104');
        Observer.Expect('first has value after', 'No');
        Observer.Expect('first sha256', 'E28FAC5DB3F79B65DE60707DDBED8F5306BE7605DC4D9A71E1BF2597E440B5EF');
        Observer.Expect('second rows', '1');
        Observer.Expect('second layout name', 'Rdl1');
        Observer.Expect('second returned', 'Yes');
        Observer.Expect('second length', '2104');
        Observer.Expect('second has value after', 'No');
        Observer.Expect('second sha256', 'E28FAC5DB3F79B65DE60707DDBED8F5306BE7605DC4D9A71E1BF2597E440B5EF');
        Observer.Verify();
    end;
}
