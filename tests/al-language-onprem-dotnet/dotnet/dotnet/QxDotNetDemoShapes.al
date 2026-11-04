// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.io.directoryinfo.getfiles
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; System Application (Web Service Management, DotNet alias
//   QueryMetadataReader), Base Application (codeunit ODataUtility); self-contained table 99400, query 99401, test codeunit 99402
// Probe (writer QX, Microsoft's DemoTool):
//   Create Data Exch. Column Def: DirectoryInfo := DirectoryInfo.DirectoryInfo(Path); if DirectoryInfo.Exists then
//   Enumerator := DirectoryInfo.GetFiles('*.xml').GetEnumerator(); while Enumerator.MoveNext() do FileInfo := Enumerator.Current; ...
//   (what AL sees: Exists, the files the pattern selects and their order, FullName and Name);
//   Create Web Services: ODataUtility.GetTenantWebServiceMetadata(TenantWebService, MetaData) and
//   WebServiceManagement.CreateTenantWebServiceColumnForQuery(..., MetaData): the Tenant Web Service Columns rows a query gives.
// Writer RD (DemoTool round 2, Export RapidStart Packages): static System.IO.Directory.Exists, File Management server folder and file methods,
//   ServerTempFileName, XmlDocument.Save to a server file, ServersideCompress / ServersideDecompress. AL File.Exists answers Yes for a file
//   deleted through DotNet on the Linux tier (DotNet File.Exists: No): a Linux suspect, those lines are Ignore'd.
// Writer RJ (DemoTool on BC 29, Create Web Services.CreateSegmentWebService): ODataUtility.GenerateSelectText, GenerateODataV3FilterText and
//   GenerateODataV4FilterText of the 'SegmentLines' query service with no Tenant Web Service Filter rows, and the rows the calls add.
// Listing order (Windows check 7, 2026-10-23): DirectoryInfo.GetFiles() lists in name order, case ignored (RJ_DirectoryInfo_GetFiles_ListingOrder).
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.IO.DirectoryInfo"; LtQxDirectoryInfo) { }
        type("System.IO.FileInfo"; LtQxFileInfo) { }
        type("System.IO.Directory"; LtQxDirectory) { }
        type("System.Collections.IEnumerator"; LtQxEnumerator) { }
    }
}

dotnet
{
    assembly("System.Xml")
    {
        type("System.Xml.XmlDocument"; LtRdXmlDocument) { }
    }
    assembly("mscorlib")
    {
        type("System.IO.File"; LtRdFile) { }
    }
}

table 99400 "LT QX DN Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

query 99401 "LT QX DN Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT QX DN Row")
        {
            column(Id; Id) { }
            column(RowName; Name) { }
            column(Amount; Amount) { }
        }
    }
}

codeunit 99402 "LT QX DotNet Demo Shapes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure WriteFile(Name: Text)
    var
        F: File;
    begin
        F.Create(Name);
        F.Write('x');
        F.Close();
    end;

    [Test]
    procedure QX_DirectoryInfo_GetFiles()
    var
        DirectoryInfo: DotNet LtQxDirectoryInfo;
        FileInfo: DotNet LtQxFileInfo;
        Directory: DotNet LtQxDirectory;
        Enumerator: DotNet LtQxEnumerator;
        Path: Text;
        Names: List of [Text];
        Visited: Text;
        Sorted: Text;
        FullNameOk: Boolean;
        FullNameBackslashOk: Boolean;
        Count: Integer;
        Name: Text;
    begin
        Path := TemporaryPath() + 'ltqx' + DelChr(Format(CreateGuid()), '=', '{}-');
        DirectoryInfo := DirectoryInfo.DirectoryInfo(Path);
        Observer.Observe('missing exists', Format(DirectoryInfo.Exists));
        Directory.CreateDirectory(Path);
        WriteFile(Path + '/c.xml');
        WriteFile(Path + '/a.xml');
        WriteFile(Path + '/b.XML');
        WriteFile(Path + '/d.txt');
        WriteFile(Path + '/e.xml.bak');
        DirectoryInfo := DirectoryInfo.DirectoryInfo(Path);
        Observer.Observe('created exists', Format(DirectoryInfo.Exists));
        FullNameOk := true;
        FullNameBackslashOk := true;
        Enumerator := DirectoryInfo.GetFiles('*.xml').GetEnumerator();
        while Enumerator.MoveNext() do begin
            FileInfo := Enumerator.Current;
            Count += 1;
            Names.Add(FileInfo.Name);
            if FileInfo.FullName <> Path + '/' + FileInfo.Name then
                FullNameOk := false;
            if FileInfo.FullName <> Path + '\' + FileInfo.Name then
                FullNameBackslashOk := false;
        end;
        Observer.Observe('count', Format(Count));
        Observer.Observe('fullname is path + / + name', Format(FullNameOk));
        Observer.Observe('fullname is path + \ + name', Format(FullNameBackslashOk));
        foreach Name in Names do
            if Name = 'a.xml' then
                Sorted += 'a.xml,';
        foreach Name in Names do
            if Name = 'b.XML' then
                Sorted += 'b.XML,';
        foreach Name in Names do
            if Name = 'c.xml' then
                Sorted += 'c.xml,';
        foreach Name in Names do
            if not (Name in ['a.xml', 'b.XML', 'c.xml']) then
                Sorted += Name + ',';
        Observer.Observe('names (fixed order)', Sorted);
        foreach Name in Names do
            Visited += Name + ',';
        Observer.Observe('enumeration order', Visited);
        Directory.Delete(Path, true);
        Observer.Expect('missing exists', 'No');
        Observer.Expect('created exists', 'Yes');
        // Windows BC 27.5, 28.5 and 29.0 (windows-check QX item 14, 2026-10-22) and bc-linux dc007079 (bc-linux #175, #183): the pattern
        // matches case-insensitively (b.XML; not e.xml.bak or d.txt), the files come in name order, and FullName joins with a backslash.
        // The older Linux image listed no file.
        Observer.Expect('count', '3');
        Observer.Expect('fullname is path + / + name', 'No');
        Observer.Expect('fullname is path + \ + name', 'Yes');
        Observer.Expect('names (fixed order)', 'a.xml,b.XML,c.xml,');
        Observer.Expect('enumeration order', 'a.xml,b.XML,c.xml,');
        Observer.Verify();
    end;

    [Test]
    procedure QX_QueryMetadataReader_TenantWebServiceColumns()
    var
        TenantWebService: Record "Tenant Web Service";
        Columns: Record "Tenant Web Service Columns";
        WebServiceManagement: Codeunit "Web Service Management";
        ODataUtility: Codeunit ODataUtility;
        MetaData: DotNet QueryMetadataReader;
        Result: Text;
    begin
        TenantWebService.SetFilter("Service Name", 'LTQX*');
        TenantWebService.DeleteAll(true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Query, Query::"LT QX DN Query", 'LTQXQuery', true);
        Observer.Observe('get', Format(TenantWebService.Get(TenantWebService."Object Type"::Query, 'LTQXQuery')));
        ODataUtility.GetTenantWebServiceMetadata(TenantWebService, MetaData);
        Observer.Observe('metadata is null', Format(IsNull(MetaData)));
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 1, Database::"LT QX DN Row", MetaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 2, Database::"LT QX DN Row", MetaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 3, Database::"LT QX DN Row", MetaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 9, Database::"LT QX DN Row", MetaData);
        Columns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        if Columns.FindSet() then
            repeat
                Result += '[' + Format(Columns."Data Item") + '|' + Format(Columns."Field Number") + '|' + Columns."Field Name" + '|' + Format(Columns.Include) + ']';
            until Columns.Next() = 0;
        Observer.Observe('columns', Result);
        Columns.DeleteAll();
        TenantWebService.Delete(true);
        Observer.Expect('get', 'Yes');
        Observer.Expect('metadata is null', 'No');
        Observer.Expect('columns', '[99400|1|Id|Yes][99400|2|RowName|Yes][99400|3|Amount|Yes][99400|9||Yes]');
        Observer.Verify();
    end;

    // ---- Writer RD (Microsoft's DemoTool, round 2: Export RapidStart Packages and Config. XML Exchange.ExportPackageXML on the server:
    // FileManagement.ServerDirectoryExists / ServerRemoveDirectory(Path, true) / ServerCreateDirectory (InitializeMediaTempFolder),
    // ServerTempFileName(''), DotNet XmlDocument.Save(ServerFile), ConfigPckgCompressionMgt.ServersideCompress(Src, Dst),
    // ServerFileExists, DeleteServerFile): what AL sees of each step under TemporaryPath, and the static DotNet System.IO.Directory.Exists. ----

    local procedure RdMask(Value: Text): Text
    var
        Index: Integer;
        Result: Text;
    begin
        for Index := 1 to StrLen(Value) do
            if Value[Index] in ['0' .. '9', 'a' .. 'z', 'A' .. 'Z'] then
                Result += 'x'
            else
                Result += Format(Value[Index]);
        exit(Result);
    end;

    local procedure RdTempNameShape(Name: Text): Text
    begin
        if not Name.StartsWith(TemporaryPath()) then
            exit('not under TemporaryPath: ' + RdMask(Name));
        exit('<tmp>' + RdMask(CopyStr(Name, StrLen(TemporaryPath()) + 1)));
    end;

    local procedure RdFileLength(Name: Text): Integer
    var
        F: File;
        L: Integer;
    begin
        if not File.Exists(Name) then
            exit(-1);
        F.Open(Name);
        L := F.Len();
        F.Close();
        exit(L);
    end;

    local procedure RdFirstBytes(Name: Text; Count: Integer): Text
    var
        F: File;
        InS: InStream;
        B: Byte;
        Value: Integer;
        Index: Integer;
        Result: Text;
    begin
        F.Open(Name);
        F.CreateInStream(InS);
        for Index := 1 to Count do
            if not InS.EOS() then begin
                InS.Read(B);
                Value := B;
                Result += Format(Value) + ' ';
            end;
        F.Close();
        exit(Result);
    end;

    local procedure RdReadText(Name: Text): Text
    var
        F: File;
        TempBlob: Codeunit "Temp Blob";
        FileIn: InStream;
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        F.Open(Name);
        F.CreateInStream(FileIn);
        TempBlob.CreateOutStream(OutS);
        CopyStream(OutS, FileIn);
        F.Close();
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    [Test]
    procedure RD_DirectoryExists_Static()
    var
        Directory: DotNet LtQxDirectory;
        Path: Text;
    begin
        Path := TemporaryPath() + 'ltrd' + DelChr(Format(CreateGuid()), '=', '{}-');
        Observer.Observe('missing', Format(Directory.Exists(Path)));
        Directory.CreateDirectory(Path);
        Observer.Observe('created', Format(Directory.Exists(Path)));
        Observer.Observe('created with trailing slash', Format(Directory.Exists(Path + '/')));
        WriteFile(Path + '/f.txt');
        Observer.Observe('a file path', Format(Directory.Exists(Path + '/f.txt')));
        Observer.Observe('empty text', Format(Directory.Exists('')));
        Observer.Observe('TemporaryPath', Format(Directory.Exists(TemporaryPath())));
        Directory.Delete(Path, true);
        Observer.Observe('deleted', Format(Directory.Exists(Path)));
        Observer.Expect('missing', 'No');
        Observer.Expect('created', 'Yes');
        Observer.Expect('created with trailing slash', 'Yes');
        Observer.Expect('a file path', 'No');
        Observer.Expect('empty text', 'No');
        Observer.Expect('TemporaryPath', 'Yes');
        Observer.Expect('deleted', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure RD_FileManagement_ServerFolderOperations()
    var
        FileManagement: Codeunit "File Management";
        DotNetFile: DotNet LtRdFile;
        Path: Text;
        Media: Text;
    begin
        Path := TemporaryPath() + 'ltrd' + DelChr(Format(CreateGuid()), '=', '{}-');
        Media := Path + '/Media';
        Observer.Observe('exists missing', Format(FileManagement.ServerDirectoryExists(Media)));
        FileManagement.ServerRemoveDirectory(Media, true);
        Observer.Observe('remove missing: no error, exists', Format(FileManagement.ServerDirectoryExists(Media)));
        FileManagement.ServerCreateDirectory(Media);
        Observer.Observe('create nested: exists', Format(FileManagement.ServerDirectoryExists(Media)));
        FileManagement.ServerCreateDirectory(Media);
        Observer.Observe('create again: exists', Format(FileManagement.ServerDirectoryExists(Media)));
        WriteFile(Media + '/a.txt');
        WriteFile(Media + '/b.txt');
        Observer.Observe('file exists', Format(FileManagement.ServerFileExists(Media + '/a.txt')));
        Observer.Observe('delete file', Format(FileManagement.DeleteServerFile(Media + '/a.txt')));
        Observer.Observe('file exists after delete', Format(FileManagement.ServerFileExists(Media + '/a.txt')));
        Observer.Observe('AL File.Exists after delete', Format(File.Exists(Media + '/a.txt')));
        Observer.Observe('DotNet File.Exists after delete', Format(DotNetFile.Exists(Media + '/a.txt')));
        Observer.Observe('delete missing file', Format(FileManagement.DeleteServerFile(Media + '/a.txt')));
        FileManagement.ServerRemoveDirectory(Media, true);
        Observer.Observe('remove recursive with a file: exists', Format(FileManagement.ServerDirectoryExists(Media)));
        Observer.Observe('remove recursive: file exists', Format(FileManagement.ServerFileExists(Media + '/b.txt')));
        Observer.Observe('remove recursive: AL File.Exists', Format(File.Exists(Media + '/b.txt')));
        Observer.Observe('remove recursive: DotNet File.Exists', Format(DotNetFile.Exists(Media + '/b.txt')));
        Observer.Observe('never created: AL File.Exists', Format(File.Exists(Media + '/never.txt')));
        Observer.Observe('parent exists', Format(FileManagement.ServerDirectoryExists(Path)));
        FileManagement.ServerRemoveDirectory(Path, false);
        Observer.Observe('remove empty non-recursive: exists', Format(FileManagement.ServerDirectoryExists(Path)));
        Observer.Expect('exists missing', 'No');
        Observer.Expect('remove missing: no error, exists', 'No');
        Observer.Expect('create nested: exists', 'Yes');
        Observer.Expect('create again: exists', 'Yes');
        Observer.Expect('file exists', 'Yes');
        Observer.Expect('delete file', 'Yes');
        Observer.Ignore('file exists after delete');
        Observer.Ignore('AL File.Exists after delete');
        Observer.Expect('DotNet File.Exists after delete', 'No');
        Observer.Ignore('delete missing file');
        Observer.Expect('remove recursive with a file: exists', 'No');
        Observer.Ignore('remove recursive: file exists');
        Observer.Ignore('remove recursive: AL File.Exists');
        Observer.Expect('remove recursive: DotNet File.Exists', 'No');
        Observer.Expect('never created: AL File.Exists', 'No');
        Observer.Expect('parent exists', 'Yes');
        Observer.Expect('remove empty non-recursive: exists', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure RD_ServerTempFileName_XmlSave_Compress()
    var
        FileManagement: Codeunit "File Management";
        ConfigPckgCompressionMgt: Codeunit "Config. Pckg. Compression Mgt.";
        DataCompression: Codeunit "Data Compression";
        PackageXml: DotNet LtRdXmlDocument;
        F: File;
        InS: InStream;
        XmlFile: Text;
        GzFile: Text;
        BackFile: Text;
        SecondName: Text;
    begin
        XmlFile := FileManagement.ServerTempFileName('');
        Observer.Observe('temp name shape', RdTempNameShape(XmlFile));
        Observer.Observe('temp name exists', Format(File.Exists(XmlFile)));
        SecondName := FileManagement.ServerTempFileName('xml');
        Observer.Observe('temp name xml shape', RdTempNameShape(SecondName));
        Observer.Observe('two names differ', Format(SecondName <> XmlFile));
        Observer.Observe('directory of temp name is TemporaryPath', Format(FileManagement.GetDirectoryName(XmlFile) + '/' = TemporaryPath()));
        PackageXml := PackageXml.XmlDocument();
        PackageXml.LoadXml('<DataList><Row Id="1">one</Row></DataList>');
        PackageXml.Save(XmlFile);
        Observer.Observe('saved exists', Format(File.Exists(XmlFile)));
        Observer.Observe('saved length', Format(RdFileLength(XmlFile)));
        Observer.Observe('saved first bytes', RdFirstBytes(XmlFile, 4));
        Observer.Observe('saved text', RdReadText(XmlFile));
        PackageXml := PackageXml.XmlDocument();
        PackageXml.LoadXml('<?xml version="1.0" encoding="UTF-16" standalone="yes"?><DataList><Row Id="1">one</Row></DataList>');
        PackageXml.Save(SecondName);
        Observer.Observe('utf-16 declaration: length', Format(RdFileLength(SecondName)));
        Observer.Observe('utf-16 declaration: first bytes', RdFirstBytes(SecondName, 4));
        GzFile := FileManagement.ServerTempFileName('');
        ConfigPckgCompressionMgt.ServersideCompress(XmlFile, GzFile);
        Observer.Observe('compressed exists', Format(File.Exists(GzFile)));
        Observer.Observe('compressed length > 0', Format(RdFileLength(GzFile) > 0));
        Observer.Observe('compressed first bytes', RdFirstBytes(GzFile, 3));
        F.Open(GzFile);
        F.CreateInStream(InS);
        Observer.Observe('IsGZip compressed', Format(DataCompression.IsGZip(InS)));
        F.Close();
        F.Open(XmlFile);
        F.CreateInStream(InS);
        Observer.Observe('IsGZip plain', Format(DataCompression.IsGZip(InS)));
        F.Close();
        BackFile := FileManagement.ServerTempFileName('');
        Observer.Observe('decompress', Format(ConfigPckgCompressionMgt.ServersideDecompress(GzFile, BackFile)));
        Observer.Observe('decompressed text', RdReadText(BackFile));
        Observer.Observe('decompress a plain file', Format(ConfigPckgCompressionMgt.ServersideDecompress(XmlFile, FileManagement.ServerTempFileName(''))));
        asserterror ConfigPckgCompressionMgt.ServersideCompress(XmlFile, GzFile);
        Observer.Observe('compress onto an existing file: error has the name', Format(StrPos(GetLastErrorText(), GzFile) > 0));
        Observer.Observe('compress onto an existing file: error', GetLastErrorText().Replace(GzFile, '<dst>'));
        Observer.Observe('delete', Format(FileManagement.DeleteServerFile(XmlFile)) + Format(FileManagement.DeleteServerFile(SecondName)) + Format(FileManagement.DeleteServerFile(GzFile)) + Format(FileManagement.DeleteServerFile(BackFile)));
        Observer.Ignore('temp name shape');
        Observer.Expect('temp name exists', 'No');
        Observer.Ignore('temp name xml shape');
        Observer.Expect('two names differ', 'Yes');
        Observer.Ignore('directory of temp name is TemporaryPath');
        Observer.Expect('saved exists', 'Yes');
        Observer.Ignore('saved length');
        Observer.Expect('saved first bytes', '60 68 97 116 ');
        Observer.Expect('saved text', '<DataList>|  <Row Id="1">one</Row>|</DataList>|');
        Observer.Ignore('utf-16 declaration: length');
        Observer.Expect('utf-16 declaration: first bytes', '255 254 60 0 ');
        Observer.Expect('compressed exists', 'Yes');
        Observer.Expect('compressed length > 0', 'Yes');
        Observer.Expect('compressed first bytes', '31 139 8 ');
        Observer.Expect('IsGZip compressed', 'Yes');
        Observer.Expect('IsGZip plain', 'No');
        Observer.Expect('decompress', 'Yes');
        Observer.Expect('decompressed text', '<DataList>|  <Row Id="1">one</Row>|</DataList>|');
        Observer.Expect('decompress a plain file', 'No');
        Observer.Expect('compress onto an existing file: error has the name', 'Yes');
        Observer.Expect('compress onto an existing file: error', 'The file name <dst> already exists.');
        Observer.Expect('delete', 'YesYesYesYes');
        Observer.Verify();
    end;

    // ---- Writer RJ (Microsoft's DemoTool, Create Web Services.CreateSegmentWebService, CreateWebServices.Codeunit.al:89-123): the same calls in
    // the same order on query 106 "Segment Lines" as 'SegmentLines' (CreateTenantWebService, GetTenantWebServiceMetadata, eight
    // CreateTenantWebServiceColumnForQuery calls, a Tenant Web Service OData row, GenerateSelectText, GenerateODataV3FilterText,
    // GenerateODataV4FilterText with no Tenant Web Service Filter rows, the three Set...Clause calls, Modify): what each TryFunction returns,
    // the texts, the clauses read back, and the rows of Tenant Web Service, Columns, OData and Filter after the calls. The test then removes
    // the rows it added. ----

    local procedure RjCounts(): Text
    var
        TenantWebService: Record "Tenant Web Service";
        Columns: Record "Tenant Web Service Columns";
        OData: Record "Tenant Web Service OData";
        Filters: Record "Tenant Web Service Filter";
    begin
        exit(Format(TenantWebService.Count()) + '|' + Format(Columns.Count()) + '|' + Format(OData.Count()) + '|' + Format(Filters.Count()));
    end;

    local procedure RjFindOData(var OData: Record "Tenant Web Service OData"; Id: RecordId): Boolean
    begin
        OData.Reset();
        OData.SetRange(TenantWebServiceID, Id);
        exit(OData.FindFirst());
    end;

    local procedure RjRowsOf(Id: RecordId; FromEntry: Integer): Text
    var
        Columns: Record "Tenant Web Service Columns";
        OData: Record "Tenant Web Service OData";
        Filters: Record "Tenant Web Service Filter";
        Result: Text;
    begin
        Columns.SetRange(TenantWebServiceID, Id);
        Result := 'columns ' + Format(Columns.Count());
        Columns.SetFilter("Entry ID", '>%1', FromEntry);
        Result += ' new ' + Format(Columns.Count()) + ':';
        if Columns.FindSet() then
            repeat
                Result += '[' + Format(Columns."Data Item") + '|' + Format(Columns."Field Number") + '|' + Columns."Field Name" + '|' + Format(Columns.Include) + ']';
            until Columns.Next() = 0;
        OData.SetRange(TenantWebServiceID, Id);
        Filters.SetRange(TenantWebServiceID, Id);
        exit(Result + ' odata ' + Format(OData.Count()) + ' filters ' + Format(Filters.Count()));
    end;

    [Test]
    procedure RJ_CreateSegmentWebService_FilterTexts()
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceOData: Record "Tenant Web Service OData";
        Columns: Record "Tenant Web Service Columns";
        Filters: Record "Tenant Web Service Filter";
        WebServiceManagement: Codeunit "Web Service Management";
        ODataUtility: Codeunit ODataUtility;
        metaData: DotNet QueryMetadataReader;
        SelectText: Text;
        ODataV3FilterText: Text;
        ODataV4FilterText: Text;
        Existed: Boolean;
        Ok: Boolean;
        MaxEntry: Integer;
    begin
        Columns.SetCurrentKey("Entry ID");
        if Columns.FindLast() then
            MaxEntry := Columns."Entry ID";
        Existed := TenantWebService.Get(TenantWebService."Object Type"::Query, 'SegmentLines');
        Observer.Observe('row before', Format(Existed));
        Observer.Observe('counts before', RjCounts());
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Query, QUERY::"Segment Lines", 'SegmentLines', true);

        TenantWebService.Get(TenantWebService."Object Type"::Query, 'SegmentLines');
        Observer.Observe('row', Format(TenantWebService."Object Type") + '|' + TenantWebService."Service Name" + '|' + Format(TenantWebService."Object ID") + '|' + Format(TenantWebService.Published));
        Observer.Observe('rows before columns', RjRowsOf(TenantWebService.RecordId, MaxEntry));
        ODataUtility.GetTenantWebServiceMetadata(TenantWebService, metaData);
        Observer.Observe('metadata is null', Format(IsNull(metaData)));
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 1, DATABASE::"Segment Line", metaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 3, DATABASE::"Segment Line", metaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 5, DATABASE::"Segment Line", metaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 6, DATABASE::"Segment Line", metaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 12, DATABASE::"Segment Line", metaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 18, DATABASE::"Segment Line", metaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 19, DATABASE::"Segment Line", metaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 27, DATABASE::"Segment Line", metaData);

        TenantWebServiceOData.Init();
        TenantWebServiceOData.TenantWebServiceID := TenantWebService.RecordId;
        Observer.Observe('odata insert', Format(TenantWebServiceOData.Insert()));
        Ok := ODataUtility.GenerateSelectText(TenantWebService."Service Name", TenantWebService."Object Type", SelectText);
        Observer.Observe('select ok', Format(Ok));
        Ok := ODataUtility.GenerateODataV3FilterText(TenantWebService."Service Name", TenantWebService."Object Type", ODataV3FilterText);
        Observer.Observe('v3 ok', Format(Ok));
        if not Ok then
            Observer.Observe('v3 error', GetLastErrorText());
        Ok := ODataUtility.GenerateODataV4FilterText(TenantWebService."Service Name", TenantWebService."Object Type", ODataV4FilterText);
        Observer.Observe('v4 ok', Format(Ok));
        if not Ok then
            Observer.Observe('v4 error', GetLastErrorText());
        Observer.Observe('select text', '[' + SelectText + ']');
        Observer.Observe('v3 text', '[' + ODataV3FilterText + ']');
        Observer.Observe('v4 text', '[' + ODataV4FilterText + ']');
        WebServiceManagement.SetODataSelectClause(TenantWebServiceOData, SelectText);
        WebServiceManagement.SetODataFilterClause(TenantWebServiceOData, ODataV3FilterText);
        WebServiceManagement.SetODataV4FilterClause(TenantWebServiceOData, ODataV4FilterText);
        TenantWebServiceOData.Modify();

        RjFindOData(TenantWebServiceOData, TenantWebService.RecordId);
        Observer.Observe('clauses read back', '[' + WebServiceManagement.GetODataSelectClause(TenantWebServiceOData) + '][' +
          WebServiceManagement.GetODataFilterClause(TenantWebServiceOData) + '][' + WebServiceManagement.GetODataV4FilterClause(TenantWebServiceOData) + ']');
        Observer.Observe('rows after', RjRowsOf(TenantWebService.RecordId, MaxEntry));
        Observer.Observe('counts after', RjCounts());

        Columns.Reset();
        Columns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        Columns.SetFilter("Entry ID", '>%1', MaxEntry);
        Columns.DeleteAll();
        if not Existed then begin
            TenantWebServiceOData.SetRange(TenantWebServiceID, TenantWebService.RecordId);
            TenantWebServiceOData.DeleteAll();
            Filters.SetRange(TenantWebServiceID, TenantWebService.RecordId);
            Filters.DeleteAll();
            TenantWebService.Delete();
        end;
        Observer.Observe('counts restored', RjCounts());
        // The fresh tenant already has 'SegmentLines' (16 columns: the eight fields twice, an OData row, no filter rows): the calls add eight
        // columns named by the query metadata, the OData Insert fails, and both filter texts of a query service without filter rows are empty;
        // the three TryFunctions return true.
        Observer.Expect('row before', 'Yes');
        Observer.Expect('counts before', '64|402|29|0');
        Observer.Expect('row', 'Query|SegmentLines|106|Yes');
        Observer.Expect('rows before columns', 'columns 16 new 0: odata 1 filters 0');
        Observer.Expect('metadata is null', 'No');
        Observer.Expect('odata insert', 'No');
        Observer.Expect('select ok', 'Yes');
        Observer.Expect('v3 ok', 'Yes');
        Observer.Expect('v4 ok', 'Yes');
        Observer.Expect('select text', '[$select=Segment_No,Contact_No,Salesperson_Code,Correspondence_Type,Contact_Name,Contact_Company_Name,Language_Code,Contact_Company_No,Segment_No,Contact_No,Salesperson_Code,Correspondence_Type,Contact_Name,Contact_Company_Name,Language_Code,Contact_Company_No,Segment_No,Contact_No,Salesperson_Code,Correspondence_Type,Contact_Name,Contact_Company_Name,Language_Code,Contact_Company_No]');
        Observer.Expect('v3 text', '[]');
        Observer.Expect('v4 text', '[]');
        Observer.Expect('clauses read back', '[$select=Segment_No,Contact_No,Salesperson_Code,Correspondence_Type,Contact_Name,Contact_Company_Name,Language_Code,Contact_Company_No,Segment_No,Contact_No,Salesperson_Code,Correspondence_Type,Contact_Name,Contact_Company_Name,Language_Code,Contact_Company_No,Segment_No,Contact_No,Salesperson_Code,Correspondence_Type,Contact_Name,Contact_Company_Name,Language_Code,Contact_Company_No][][]');
        Observer.Expect('rows after', 'columns 24 new 8:[5077|1|Segment_No|Yes][5077|3|Contact_No|Yes][5077|5|Salesperson_Code|Yes][5077|6|Correspondence_Type|Yes][5077|12|Contact_Name|Yes][5077|18|Contact_Company_Name|Yes][5077|19|Language_Code|Yes][5077|27|Contact_Company_No|Yes] odata 1 filters 0');
        Observer.Expect('counts after', '64|410|29|0');
        Observer.Expect('counts restored', '64|402|29|0');
        Observer.Verify();
    end;

    // ---- Listing order through DotNet (Windows check 7, 2026-10-23, BC 29.0): DirectoryInfo.GetFiles() lists a folder in NAME order, case
    // ignored, never in creation order (the same order as File Management.GetServerDirectoryFilesList: MediaFiles.al,
    // RJ_GetServerDirectoryFilesList_ListingOrder, which also covers MediaSet.ExportFile names). ----

    local procedure RjLoNewDir(Tag: Text): Text
    var
        FileManagement: Codeunit "File Management";
        Dir: Text;
    begin
        Dir := TemporaryPath() + 'ltlo' + Tag + CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 8);
        FileManagement.ServerCreateDirectory(Dir);
        exit(Dir);
    end;

    local procedure RjLoWrite(Name: Text)
    begin
        WriteFile(Name);
        Sleep(30);
    end;

    local procedure RjLoList(Dir: Text): Text
    var
        DirectoryInfo: DotNet LtQxDirectoryInfo;
        FileInfo: DotNet LtQxFileInfo;
        Enumerator: DotNet LtQxEnumerator;
        FileManagement: Codeunit "File Management";
        Result: Text;
    begin
        DirectoryInfo := DirectoryInfo.DirectoryInfo(Dir);
        Enumerator := DirectoryInfo.GetFiles().GetEnumerator();
        while Enumerator.MoveNext() do begin
            FileInfo := Enumerator.Current;
            Result += FileInfo.Name + ',';
        end;
        FileManagement.ServerRemoveDirectory(Dir, true);
        exit(Result);
    end;

    [Test]
    procedure RJ_DirectoryInfo_GetFiles_ListingOrder()
    var
        LoObserver: Codeunit "Probe Observer";
        FileManagement: Codeunit "File Management";
        Dir: Text;
    begin
        Dir := RjLoNewDir('a');
        RjLoWrite(FileManagement.CombinePath(Dir, 'c.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'b.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'a.txt'));
        LoObserver.Observe('a written c,b,a', RjLoList(Dir));
        Dir := RjLoNewDir('b2');
        RjLoWrite(FileManagement.CombinePath(Dir, '{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}-1'));
        RjLoWrite(FileManagement.CombinePath(Dir, '{00000000-0000-0000-0000-000000000000}-1'));
        LoObserver.Observe('b2 written FFFF then 0000', RjLoList(Dir));
        Dir := RjLoNewDir('c');
        RjLoWrite(FileManagement.CombinePath(Dir, 'B.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'a.txt'));
        LoObserver.Observe('c written B,a', RjLoList(Dir));
        Dir := RjLoNewDir('c2');
        RjLoWrite(FileManagement.CombinePath(Dir, 'a.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'C.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'b.txt'));
        LoObserver.Observe('c2 written a,C,b', RjLoList(Dir));
        Dir := RjLoNewDir('d');
        RjLoWrite(FileManagement.CombinePath(Dir, 'f07.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'f02.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'f09.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'f01.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'f10.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'f05.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'f03.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'f08.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'f04.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'f06.txt'));
        LoObserver.Observe('d written 07,02,09,01,10,05,03,08,04,06', RjLoList(Dir));
        // Windows BC 29.0 (windows-check 7, 2026-10-23); bc-linux dc007079 lists in the same order (bc-linux #183).
        LoObserver.Expect('a written c,b,a', 'a.txt,b.txt,c.txt,');
        LoObserver.Expect('b2 written FFFF then 0000', '{00000000-0000-0000-0000-000000000000}-1,{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}-1,');
        LoObserver.Expect('c written B,a', 'a.txt,B.txt,');
        LoObserver.Expect('c2 written a,C,b', 'a.txt,b.txt,C.txt,');
        LoObserver.Expect('d written 07,02,09,01,10,05,03,08,04,06', 'f01.txt,f02.txt,f03.txt,f04.txt,f05.txt,f06.txt,f07.txt,f08.txt,f09.txt,f10.txt,');
        LoObserver.Verify();
    end;
}
