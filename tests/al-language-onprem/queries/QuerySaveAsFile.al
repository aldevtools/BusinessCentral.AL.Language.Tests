// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-saveascsv-method
// Scope: in-scope (OnPrem app: the file forms of Query.SaveAsCsv and Query.SaveAsXml are Scope = OnPrem)
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 61287
// Probe: written against BC 29 (runtime 16); the values are measured on the corpus CI service tiers.
// Facts: Query.SaveAsCsv and Query.SaveAsXml into a file, as instance and by object number: return value, file text, Format and FormatArgument, errors
// BC versions: 27, 28, 29
codeunit 61287 "LT S Query SaveAs File"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P160 QRow";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Name := 'a,b;c "q" <x>';
        Row.Amt := 12.5;
        Row.D := DMY2Date(5, 3, 2024);
        Row.Flag := true;
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.Name := '';
        Row.Amt := 0;
        Row.Insert();
    end;

    local procedure TempName(Suffix: Text): Text
    begin
        exit(TemporaryPath() + 'ltsqfile' + DelChr(Format(CreateGuid()), '=', '{}-') + Suffix);
    end;

    local procedure ObserveFile(var Observer: Codeunit "Probe Observer"; Name: Text; Tag: Text; FromMarker: Text)
    var
        F: File;
        InS: InStream;
        Raw: Text;
        Len: Integer;
        B: Byte;
        First3: Text;
        i: Integer;
    begin
        Observer.Observe(Tag + ' exists', Format(File.Exists(Name)));
        if not File.Exists(Name) then
            exit;
        F.Open(Name);
        Len := F.Len();
        Observer.Observe(Tag + ' length', Format(Len));
        F.CreateInStream(InS);
        for i := 1 to 3 do
            if not InS.EOS() then begin
                InS.Read(B);
                First3 += Format(B) + ' ';
            end;
        Observer.Observe(Tag + ' first bytes', First3);
        F.Close();
        F.Open(Name);
        F.CreateInStream(InS);
        if Len > 0 then
            InS.Read(Raw, Len);
        F.Close();
        i := 1;
        if FromMarker <> '' then
            i := StrPos(Raw, FromMarker);
        if i = 0 then
            i := 1;
        Observer.Observe(Tag + ' text', CopyStr(Raw, i, 700));
        File.Erase(Name);
    end;

    [Test]
    procedure SaveAsCsv_File_Instance()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P160 QSave";
        Name: Text;
        Ok: Boolean;
    begin
        Seed();
        Name := TempName('.csv');
        Observer.Observe('default ok', Format(Q.SaveAsCsv(Name)));
        ObserveFile(Observer, Name, 'default', '');
        Ok := TrySaveCsvFormat(Name, 0);
        Observer.Observe('format0', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        ObserveFile(Observer, Name, 'format0', '');
        Ok := TrySaveCsvFormat(Name, 3);
        Observer.Observe('format3', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        ObserveFile(Observer, Name, 'format3', '');
        Observer.Observe('format1 semicolon ok', Format(Q.SaveAsCsv(Name, 1, ';')));
        ObserveFile(Observer, Name, 'format1 semicolon', '');
        Observer.Observe('format2 ok', Format(Q.SaveAsCsv(Name, 2, '')));
        ObserveFile(Observer, Name, 'format2', '');
        Q.SetFilter(Id, '2');
        Observer.Observe('filtered ok', Format(Q.SaveAsCsv(Name)));
        ObserveFile(Observer, Name, 'filtered', '');
        Observer.Expect('default ok', 'Yes');
        Observer.Expect('default exists', 'Yes');
        Observer.Expect('default length', '86');
        Observer.Expect('default first bytes', 'I d , ');
        Observer.Expect('default text', 'Id,Name,Amt,D,Flag\r\n1,"a,b;c ""q"" <x>",12.5,3/5/2024 12:00:00 AM,True\r\n2,,0,0,False\r\n');
        Observer.Expect('format0', 'No The query output cannot be saved. The following error occurred: Missing or invalid argument: Positions|QuerySaveAs');
        Observer.Expect('format0 exists', 'No');
        Observer.Expect('format3', 'Yes |');
        Observer.Expect('format3 exists', 'Yes');
        Observer.Expect('format3 length', '86');
        Observer.Expect('format3 first bytes', 'I d , ');
        Observer.Expect('format3 text', 'Id,Name,Amt,D,Flag\r\n1,"a,b;c ""q"" <x>",12.5,3/5/2024 12:00:00 AM,True\r\n2,,0,0,False\r\n');
        Observer.Expect('format1 semicolon ok', 'Yes');
        Observer.Expect('format1 semicolon exists', 'Yes');
        Observer.Expect('format1 semicolon length', '86');
        Observer.Expect('format1 semicolon first bytes', 'I d ; ');
        Observer.Expect('format1 semicolon text', 'Id;Name;Amt;D;Flag\r\n1;"a,b;c ""q"" <x>";12.5;3/5/2024 12:00:00 AM;True\r\n2;;0;0;False\r\n');
        Observer.Expect('format2 ok', 'Yes');
        Observer.Expect('format2 exists', 'Yes');
        Observer.Expect('format2 length', '86');
        Observer.Expect('format2 first bytes', 'I d , ');
        Observer.Expect('format2 text', 'Id,Name,Amt,D,Flag\r\n1,"a,b;c ""q"" <x>",12.5,3/5/2024 12:00:00 AM,True\r\n2,,0,0,False\r\n');
        Observer.Expect('filtered ok', 'Yes');
        Observer.Expect('filtered exists', 'Yes');
        Observer.Expect('filtered length', '34');
        Observer.Expect('filtered first bytes', 'I d , ');
        Observer.Expect('filtered text', 'Id,Name,Amt,D,Flag\r\n2,,0,0,False\r\n');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsCsv_File_ByNumber()
    var
        Observer: Codeunit "Probe Observer";
        Name: Text;
    begin
        Seed();
        Name := TempName('.csv');
        Observer.Observe('default ok', Format(Query.SaveAsCsv(71922, Name)));
        ObserveFile(Observer, Name, 'default', '');
        Observer.Observe('format1 semicolon ok', Format(Query.SaveAsCsv(71922, Name, 1, ';')));
        ObserveFile(Observer, Name, 'format1 semicolon', '');
        Observer.Expect('default ok', 'Yes');
        Observer.Expect('default exists', 'Yes');
        Observer.Expect('default length', '86');
        Observer.Expect('default first bytes', 'I d , ');
        Observer.Expect('default text', 'Id,Name,Amt,D,Flag\r\n1,"a,b;c ""q"" <x>",12.5,3/5/2024 12:00:00 AM,True\r\n2,,0,0,False\r\n');
        Observer.Expect('format1 semicolon ok', 'Yes');
        Observer.Expect('format1 semicolon exists', 'Yes');
        Observer.Expect('format1 semicolon length', '86');
        Observer.Expect('format1 semicolon first bytes', 'I d ; ');
        Observer.Expect('format1 semicolon text', 'Id;Name;Amt;D;Flag\r\n1;"a,b;c ""q"" <x>";12.5;3/5/2024 12:00:00 AM;True\r\n2;;0;0;False\r\n');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsXml_File_Instance_AndByNumber()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P160 QSave";
        Name: Text;
    begin
        Seed();
        Name := TempName('.xml');
        Observer.Observe('instance ok', Format(Q.SaveAsXml(Name)));
        ObserveFile(Observer, Name, 'instance', '<Result>');
        Observer.Observe('by number ok', Format(Query.SaveAsXml(71922, Name)));
        ObserveFile(Observer, Name, 'by number', '<Result>');
        Observer.Expect('instance ok', 'Yes');
        Observer.Expect('instance exists', 'Yes');
        Observer.Expect('instance length', '1326');
        Observer.Expect('instance first bytes', 'Ù ‹  ');
        Observer.Expect('instance text', '<Result>\r\n    <Id>1</Id>\r\n    <Name>a,b;c "q" &lt;x&gt;</Name>\r\n    <Amt>12.5</Amt>\r\n    <D>2024-03-05T00:00:00+00:00</D>\r\n    <Flag>true</Flag>\r\n  </Result>\r\n  <Result>\r\n    <Id>2</Id>\r\n    <Name />\r\n    <Amt>0</Amt>\r\n    <Flag>false</Flag>\r\n  </Result>\r\n</DataSet>');
        Observer.Expect('by number ok', 'Yes');
        Observer.Expect('by number exists', 'Yes');
        Observer.Expect('by number length', '1326');
        Observer.Expect('by number first bytes', 'Ù ‹  ');
        Observer.Expect('by number text', '<Result>\r\n    <Id>1</Id>\r\n    <Name>a,b;c "q" &lt;x&gt;</Name>\r\n    <Amt>12.5</Amt>\r\n    <D>2024-03-05T00:00:00+00:00</D>\r\n    <Flag>true</Flag>\r\n  </Result>\r\n  <Result>\r\n    <Id>2</Id>\r\n    <Name />\r\n    <Amt>0</Amt>\r\n    <Flag>false</Flag>\r\n  </Result>\r\n</DataSet>');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySaveCsvFormat(Name: Text; FormatKind: Integer)
    var
        Q: Query "LT P160 QSave";
    begin
        Q.SaveAsCsv(Name, FormatKind, '');
    end;

    [TryFunction]
    local procedure TrySaveCsv(Name: Text)
    var
        Q: Query "LT P160 QSave";
    begin
        Q.SaveAsCsv(Name);
    end;

    [TryFunction]
    local procedure TrySaveXml(Name: Text)
    var
        Q: Query "LT P160 QSave";
    begin
        Q.SaveAsXml(Name);
    end;

    [TryFunction]
    local procedure TrySaveByNumber(Number: Integer; Name: Text)
    begin
        Query.SaveAsCsv(Number, Name);
    end;

    [Test]
    procedure SaveAs_File_BadPaths()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Seed();
        Ok := TrySaveCsv('');
        Observer.Observe('csv empty name', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TrySaveCsv('/no/such/dir/out.csv');
        Observer.Observe('csv missing dir', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TrySaveXml('');
        Observer.Observe('xml empty name', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TrySaveXml('/no/such/dir/out.xml');
        Observer.Observe('xml missing dir', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TrySaveByNumber(61299, TempName('.csv'));
        Observer.Observe('unknown query number', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Observer.Expect('csv empty name', 'No The query output cannot be saved. The following error occurred: Empty file name|QuerySaveAs');
        Observer.Expect('csv missing dir', 'No The query output cannot be saved. The following error occurred: Could not find a part of the path ''/no/such/dir/out.csv''.|QuerySaveAs:DirectoryNotFound');
        Observer.Expect('xml empty name', 'No The query output cannot be saved. The following error occurred: Empty file name|QuerySaveAs');
        Observer.Expect('xml missing dir', 'No The query output cannot be saved. The following error occurred: Could not find a part of the path ''/no/such/dir/out.xml''.|QuerySaveAs:DirectoryNotFound');
        Observer.Expect('unknown query number', 'No You tried to invoke the Query object with the ID 61299 from the object LT S Query SaveAs File. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Verify();
    end;
}
