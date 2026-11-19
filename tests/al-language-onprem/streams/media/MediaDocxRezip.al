// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-importfile-method
// Scope: in-scope (OnPrem app: Media.ImportFile, MediaSet.ImportFile and Media.ExportFile are Scope = OnPrem; the ImportStream cells sit here
//   next to them so that one codeunit compares every import path)
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 98050 and test codeunit 98051. The .docx is the 911-byte package of
//   media/MediaFiles.al (RdDocxBase64, three deflated parts); the other packages are built from its parts in AL with Data Compression.
// Probe: written against Windows BC 27.5, 28.5 and 29.0 (sandbox containers, measured 2026-11-19). What BC stores in Tenant Media and
//   exports for an imported .docx: stored and exported length, whether the package parts (names, order, uncompressed content) are those
//   of the source, and whether the bytes are the same on a second import. Neighbors: other import paths, mime types and extensions.
// Facts (Windows BC 27.5, 28.5 and 29.0 agree except for the length):
// - A Word package is re-zipped when its mime type is a Word one: Media.ImportFile with .docx, .DOCX, .dotx or .docm, Media.ImportStream
//   and MediaSet.ImportStream with the .docx mime type (also in upper case, with or without a file name), MediaSet.ImportFile with .docx.
//   The stored Tenant Media content is then not the source file: 911 bytes on Windows 27.5 and 28.5 (same length as the source, other
//   bytes), 919 bytes on 29.0. The Linux CI tier stores 919 bytes on 27.5 and 28.5 too (CI 2026-11-19): the 27 and 28 length is
//   observed, not asserted. ExportStream and ExportFile give the stored content.
// - The re-zipped package has the same parts as the source: same names, same order, same uncompressed bytes, deflated, and the first
//   entry keeps the source's DOS time and date.
// - Stable: a second import of the same file (2.5 s later) stores the same bytes; the stored package imported again is kept as it is.
// - A package written by Data Compression (the same parts, or the parts plus a part no relationship names) is stored as it is.
// - Not re-zipped (stored as the file): ImportStream without a mime type (mime application/octet-stream), with application/zip, and
//   ImportFile with .zip (application/x-zip-compressed), .xlsx and .pptx.
// - Plain text in a file named .docx, or in a stream with the .docx mime type: no error, the returned Guid is null, no Tenant Media row,
//   HasValue false, ExportStream writes nothing.
// BC versions: 27, 28, 29
table 98050 "LT S Docx Media Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Pic; Media) { }
        field(3; Set; MediaSet) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 98051 "LT S Media Docx Rezip"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        DocxMimeTxt: Label 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', Locked = true;

    local procedure DocxBase64(): Text
    begin
        exit('UEsDBBQAAAAIAAAAIVx5bjPX6AAAAK0BAAATAAAAW0NvbnRlbnRfVHlwZXNdLnhtbH1QyU7DMBD9FWuuKHHggBCK0wPLETiUDxjZk8SqN3nc0v49Tlt6QIXjzFv1+tXeO7GjzDYGBbdt' +
            'B4KCjsaGScHn+rV5AMEFg0EXAyk4EMNq6NeHRCyqNrCCuZT0KCXrmTxyGxOFiowxeyz1zJNMqDc4kbzrunupYygUSlMWDxj6Zxpx64p42df3qUcmxyCeTsQlSwGm5KzGUnG5C+ZXSnNO' +
            'aKvyyOHZJr6pBJBXExbk74Cz7r0Ok60h8YG5vKGvLPkVs5Em6q2vyvZ/mys94zhaTRf94pZy1MRcF/euvSAebfjpL49zD99QSwMEFAAAAAgAAAAhXJv9N+qtAAAAKQEAAAsAAABfcmVs' +
            'cy8ucmVsc43POw7CMAwG4KtE3mlaBoRQ0y4IqSsqB7ASN61oHkrCo7cnAwNFDIy2f3+W6/ZpZnanECdnBVRFCYysdGqyWsClP232wGJCq3B2lgQsFKFt6jPNmPJKHCcfWTZsFDCm5A+c' +
            'RzmSwVg4TzZPBhcMplwGzT3KK2ri27Lc8fBpwNpknRIQOlUB6xdP/9huGCZJRydvhmz6ceIrkWUMmpKAhwuKq3e7yCzwpuarF5sXUEsDBBQAAAAIAAAAIVzXDGLpogAAANcAAAARAAAA' +
            'd29yZC9kb2N1bWVudC54bWxFjkEOwiAQRa9C2FuqC2Oa0m6MK1emHgBhbJvADAG09vZCXbh5PzOT/zJt/3GWvSHEmVDyfVVzBqjJzDhKfh8uuxNnMSk0yhKC5CtE3nft0hjSLweYWBZg' +
            'bBbJp5R8I0TUEzgVK/KA+fak4FTKYxjFQsH4QBpizH5nxaGuj8KpGXlRPsisJX1BKEjddWC3M0vgvFUJWlF2hWGj3/jrif9P3RdQSwECFAMUAAAACAAAACFceW4z1+gAAACtAQAAEwAA' +
            'AAAAAAAAAAAAgAEAAAAAW0NvbnRlbnRfVHlwZXNdLnhtbFBLAQIUAxQAAAAIAAAAIVyb/TfqrQAAACkBAAALAAAAAAAAAAAAAACAARkBAABfcmVscy8ucmVsc1BLAQIUAxQAAAAIAAAA' +
            'IVzXDGLpogAAANcAAAARAAAAAAAAAAAAAACAAe8BAAB3b3JkL2RvY3VtZW50LnhtbFBLBQYAAAAAAwADALkAAADAAgAAAAA=');
    end;

    local procedure Reset()
    var
        Row: Record "LT S Docx Media Row";
    begin
        Row.DeleteAll();
    end;

    local procedure TempName(Suffix: Text): Text
    begin
        exit(TemporaryPath() + 'ltsdocx' + DelChr(Format(CreateGuid()), '=', '{}-') + Suffix);
    end;

    local procedure WriteFile(Name: Text; B64: Text)
    var
        F: File;
        OutS: OutStream;
        Base64: Codeunit "Base64 Convert";
    begin
        F.Create(Name);
        F.CreateOutStream(OutS);
        Base64.FromBase64(B64, OutS);
        F.Close();
    end;

    local procedure ReadFile(Name: Text): Text
    var
        F: File;
        InS: InStream;
        Base64: Codeunit "Base64 Convert";
        B64: Text;
    begin
        F.Open(Name);
        F.CreateInStream(InS);
        B64 := Base64.ToBase64(InS);
        F.Close();
        exit(B64);
    end;

    local procedure Cleanup(Name: Text)
    begin
        if File.Exists(Name) then
            File.Erase(Name);
    end;

    local procedure ToBlob(B64: Text; var TempBlob: Codeunit "Temp Blob")
    var
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        Base64.FromBase64(B64, OutS);
    end;

    local procedure LenOf(B64: Text): Integer
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        ToBlob(B64, TempBlob);
        exit(TempBlob.Length());
    end;

    local procedure Stored(Id: Guid): Text
    var
        Tenant: Record "Tenant Media";
        Base64: Codeunit "Base64 Convert";
        InS: InStream;
    begin
        if not Tenant.Get(Id) then
            exit('no tenant media row');
        Tenant.CalcFields(Content);
        Tenant.Content.CreateInStream(InS);
        exit(Base64.ToBase64(InS));
    end;

    local procedure Mime(Id: Guid): Text
    var
        Tenant: Record "Tenant Media";
    begin
        if not Tenant.Get(Id) then
            exit('no tenant media row');
        exit(Tenant."Mime Type");
    end;

    local procedure Exported(Code: Code[10]): Text
    var
        Row: Record "LT S Docx Media Row";
        TempBlob: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
        InS: InStream;
    begin
        Row.Get(Code);
        TempBlob.CreateOutStream(OutS);
        Row.Pic.ExportStream(OutS);
        TempBlob.CreateInStream(InS);
        exit(Base64.ToBase64(InS));
    end;

    // The part names of a package in archive order, each with its uncompressed length: 'name:len|name:len'.
    local procedure Parts(B64: Text): Text
    var
        DataCompression: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        EntryBlob: Codeunit "Temp Blob";
        Names: List of [Text];
        Name: Text;
        InS: InStream;
        EntryOut: OutStream;
        Length: Integer;
        Result: Text;
    begin
        ToBlob(B64, TempBlob);
        TempBlob.CreateInStream(InS);
        DataCompression.OpenZipArchive(InS, false);
        DataCompression.GetEntryList(Names);
        foreach Name in Names do begin
            Clear(EntryBlob);
            EntryBlob.CreateOutStream(EntryOut);
            DataCompression.ExtractEntry(Name, EntryOut, Length);
            if Result <> '' then
                Result += '|';
            Result += Name + ':' + Format(EntryBlob.Length());
        end;
        DataCompression.CloseZipArchive();
        exit(Result);
    end;

    local procedure PartContent(B64: Text; PartName: Text): Text
    var
        DataCompression: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        EntryBlob: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        Names: List of [Text];
        InS: InStream;
        EntryOut: OutStream;
        EntryIn: InStream;
        Length: Integer;
        Result: Text;
    begin
        ToBlob(B64, TempBlob);
        TempBlob.CreateInStream(InS);
        DataCompression.OpenZipArchive(InS, false);
        DataCompression.GetEntryList(Names);
        if Names.Contains(PartName) then begin
            EntryBlob.CreateOutStream(EntryOut);
            DataCompression.ExtractEntry(PartName, EntryOut, Length);
            EntryBlob.CreateInStream(EntryIn);
            Result := Base64.ToBase64(EntryIn);
        end else
            Result := '<missing>';
        DataCompression.CloseZipArchive();
        exit(Result);
    end;

    // 'Yes' when both packages have the same part names (any order) with the same uncompressed bytes; else the first difference.
    local procedure SameParts(A: Text; B: Text): Text
    var
        DataCompression: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        NamesA: List of [Text];
        NamesB: List of [Text];
        Name: Text;
        InS: InStream;
    begin
        ToBlob(A, TempBlob);
        TempBlob.CreateInStream(InS);
        DataCompression.OpenZipArchive(InS, false);
        DataCompression.GetEntryList(NamesA);
        DataCompression.CloseZipArchive();
        ToBlob(B, TempBlob);
        TempBlob.CreateInStream(InS);
        DataCompression.OpenZipArchive(InS, false);
        DataCompression.GetEntryList(NamesB);
        DataCompression.CloseZipArchive();
        if NamesA.Count() <> NamesB.Count() then
            exit('part count ' + Format(NamesA.Count()) + ' vs ' + Format(NamesB.Count()));
        foreach Name in NamesA do begin
            if not NamesB.Contains(Name) then
                exit('missing part ' + Name);
            if PartContent(A, Name) <> PartContent(B, Name) then
                exit('other content in ' + Name);
        end;
        exit('Yes');
    end;

    // Compression method, DOS time and DOS date of the first local file header.
    local procedure FirstHeader(B64: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        B: Byte;
        I: Integer;
        Bytes: array[14] of Integer;
    begin
        ToBlob(B64, TempBlob);
        TempBlob.CreateInStream(InS);
        for I := 1 to 14 do begin
            InS.Read(B);
            Bytes[I] := B;
        end;
        exit('sig=' + Format(Bytes[1]) + ',' + Format(Bytes[2]) + ' method=' + Format(Bytes[9] + 256 * Bytes[10]) +
            ' time=' + Format(Bytes[11] + 256 * Bytes[12]) + ' date=' + Format(Bytes[13] + 256 * Bytes[14]));
    end;

    local procedure FirstMethod(B64: Text): Text
    var
        H: Text;
    begin
        H := FirstHeader(B64);
        exit(CopyStr(H, StrPos(H, 'method='), StrPos(H, ' time=') - StrPos(H, 'method=')));
    end;

    local procedure FirstStamp(B64: Text): Text
    var
        H: Text;
    begin
        H := FirstHeader(B64);
        exit(CopyStr(H, StrPos(H, 'time=')));
    end;

    // A new package with the parts of Src, written by Data Compression in the order given; Extra adds a part word/extra.xml.
    local procedure Rebuild(Src: Text; Extra: Boolean): Text
    var
        Reader: Codeunit "Data Compression";
        Writer: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        PartBlob: Codeunit "Temp Blob";
        OutBlob: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        Names: List of [Text];
        Name: Text;
        InS: InStream;
        PartOut: OutStream;
        PartIn: InStream;
        OutS: OutStream;
        Length: Integer;
    begin
        ToBlob(Src, TempBlob);
        TempBlob.CreateInStream(InS);
        Reader.OpenZipArchive(InS, false);
        Reader.GetEntryList(Names);
        Writer.CreateZipArchive();
        foreach Name in Names do begin
            Clear(PartBlob);
            PartBlob.CreateOutStream(PartOut);
            Reader.ExtractEntry(Name, PartOut, Length);
            PartBlob.CreateInStream(PartIn);
            Writer.AddEntry(PartIn, Name);
        end;
        Reader.CloseZipArchive();
        if Extra then begin
            Clear(PartBlob);
            PartBlob.CreateOutStream(PartOut, TextEncoding::UTF8);
            PartOut.WriteText('<?xml version="1.0" encoding="UTF-8"?><extra>probe</extra>');
            PartBlob.CreateInStream(PartIn);
            Writer.AddEntry(PartIn, 'word/extra.xml');
        end;
        OutBlob.CreateOutStream(OutS);
        Writer.SaveZipArchive(OutS);
        Writer.CloseZipArchive();
        OutBlob.CreateInStream(InS);
        exit(Base64.ToBase64(InS));
    end;

    local procedure ImportFileAs(Code: Code[10]; Src: Text; Suffix: Text): Guid
    var
        Row: Record "LT S Docx Media Row";
        Path: Text;
        Id: Guid;
    begin
        Path := TempName(Suffix);
        WriteFile(Path, Src);
        Row.Code := Code;
        Id := Row.Pic.ImportFile(Path, 'Template');
        Row.Insert();
        Cleanup(Path);
        exit(Id);
    end;

    local procedure Describe(var Observer: Codeunit "Probe Observer"; Id: Guid; Code: Code[10]; Src: Text)
    begin
        Describe(Observer, Id, Code, Src, true);
    end;

    // WithLength = false for a source written by Data Compression: its length is that of the Data Compression output, which is not the
    // fact asked here (the relation 'stored is the file' is).
    local procedure Describe(var Observer: Codeunit "Probe Observer"; Id: Guid; Code: Code[10]; Src: Text; WithLength: Boolean)
    var
        S: Text;
        E: Text;
    begin
        S := Stored(Id);
        E := Exported(Code);
        Observer.Observe('mime', Mime(Id));
        if WithLength then
            Observer.Observe('stored length', Format(LenOf(S)));
        Observer.Observe('stored is the file', Format(S = Src));
        if WithLength then
            Observer.Observe('export length', Format(LenOf(E)));
        Observer.Observe('export is the stored content', Format(E = S));
        Observer.Observe('stored parts', Parts(S));
        Observer.Observe('stored part order is the source order', Format(Parts(S) = Parts(Src)));
        Observer.Observe('stored parts are the source parts', SameParts(S, Src));
        Observer.Observe('stored first entry', FirstMethod(S));
        Observer.Observe('stored first entry stamp is the source stamp', Format(FirstStamp(S) = FirstStamp(Src)));
    end;

    [Test]
    procedure Docx_Source_Package()
    var
        Observer: Codeunit "Probe Observer";
        Src: Text;
    begin
        // The source package itself, read by the same helpers (the reference for the other tests).
        Src := DocxBase64();
        Observer.Observe('length', Format(LenOf(Src)));
        Observer.Observe('parts', Parts(Src));
        Observer.Observe('first entry', FirstMethod(Src));
        Observer.Observe('rebuilt parts are the source parts', SameParts(Rebuild(Src, false), Src));
        Observer.Observe('rebuilt is the file', Format(Rebuild(Src, false) = Src));
        Observer.Observe('rebuilt with extra parts', Parts(Rebuild(Src, true)));
        Observer.Expect('length', '911');
        Observer.Expect('parts', '[Content_Types].xml:429|_rels/.rels:297|word/document.xml:215');
        Observer.Expect('first entry', 'method=8');
        Observer.Expect('rebuilt parts are the source parts', 'Yes');
        Observer.Expect('rebuilt is the file', 'No');
        Observer.Expect('rebuilt with extra parts', '[Content_Types].xml:429|_rels/.rels:297|word/document.xml:215|word/extra.xml:58');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportFile_Stored()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
    begin
        Reset();
        Id := ImportFileAs('F1', DocxBase64(), '.docx');
        Describe(Observer, Id, 'F1', DocxBase64());
        Reset();
        Observer.Expect('mime', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
#if BC29PLUS
        Observer.Expect('stored length', '919');
#else
        // Windows BC 27.5 and 28.5: 911; the Linux CI tier (27.5 and 28.5 on .NET 10): 919. The re-zip is done by the platform's runtime, so
        // the length differs per host; the parts and the relations above are the same on both.
        Observer.Ignore('stored length');
#endif
        Observer.Expect('stored is the file', 'No');
#if BC29PLUS
        Observer.Expect('export length', '919');
#else
        // Windows BC 27.5 and 28.5: 911; the Linux CI tier (27.5 and 28.5 on .NET 10): 919. The re-zip is done by the platform's runtime, so
        // the length differs per host; the parts and the relations above are the same on both.
        Observer.Ignore('export length');
#endif
        Observer.Expect('export is the stored content', 'Yes');
        Observer.Expect('stored parts', '[Content_Types].xml:429|_rels/.rels:297|word/document.xml:215');
        Observer.Expect('stored part order is the source order', 'Yes');
        Observer.Expect('stored parts are the source parts', 'Yes');
        Observer.Expect('stored first entry', 'method=8');
        Observer.Expect('stored first entry stamp is the source stamp', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportFile_ExportFile()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT S Docx Media Row";
        Id: Guid;
        Out: Text;
    begin
        Reset();
        Id := ImportFileAs('F1', DocxBase64(), '.docx');
        Row.Get('F1');
        Out := TempName('.docx');
        Row.Pic.ExportFile(Out);
        Observer.Observe('export file length', Format(LenOf(ReadFile(Out))));
        Observer.Observe('export file is the stored content', Format(ReadFile(Out) = Stored(Id)));
        Observer.Observe('export file is the source', Format(ReadFile(Out) = DocxBase64()));
        Cleanup(Out);
        Reset();
#if BC29PLUS
        Observer.Expect('export file length', '919');
#else
        // Windows BC 27.5 and 28.5: 911; the Linux CI tier (27.5 and 28.5 on .NET 10): 919. The re-zip is done by the platform's runtime, so
        // the length differs per host; the parts and the relations above are the same on both.
        Observer.Ignore('export file length');
#endif
        Observer.Expect('export file is the stored content', 'Yes');
        Observer.Expect('export file is the source', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportFile_TwiceSameBytes()
    var
        Observer: Codeunit "Probe Observer";
        Id1: Guid;
        Id2: Guid;
    begin
        // Two imports of the same file into two rows, more than two seconds apart (a zip entry stamp has two-second steps).
        Reset();
        Id1 := ImportFileAs('F1', DocxBase64(), '.docx');
        Sleep(2500);
        Id2 := ImportFileAs('F2', DocxBase64(), '.docx');
        Observer.Observe('two tenant media rows', Format(Id1 <> Id2));
        Observer.Observe('second stored is the first stored', Format(Stored(Id1) = Stored(Id2)));
        Observer.Observe('second export is the first export', Format(Exported('F1') = Exported('F2')));
        Observer.Observe('second stamp is the first stamp', Format(FirstStamp(Stored(Id1)) = FirstStamp(Stored(Id2))));
        Reset();
        Observer.Expect('two tenant media rows', 'Yes');
        Observer.Expect('second stored is the first stored', 'Yes');
        Observer.Expect('second export is the first export', 'Yes');
        Observer.Expect('second stamp is the first stamp', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportFile_StoredReimported()
    var
        Observer: Codeunit "Probe Observer";
        Id1: Guid;
        Id2: Guid;
        First: Text;
    begin
        // The stored package imported again as a .docx: is BC's output kept as it is the second time?
        Reset();
        Id1 := ImportFileAs('F1', DocxBase64(), '.docx');
        First := Stored(Id1);
        Sleep(2500);
        Id2 := ImportFileAs('F2', First, '.docx');
        Observer.Observe('second stored is the first stored', Format(Stored(Id2) = First));
        Observer.Observe('second stored length', Format(LenOf(Stored(Id2))));
        Observer.Observe('second stored parts are the source parts', SameParts(Stored(Id2), DocxBase64()));
        Reset();
        Observer.Expect('second stored is the first stored', 'Yes');
#if BC29PLUS
        Observer.Expect('second stored length', '919');
#else
        // Windows BC 27.5 and 28.5: 911; the Linux CI tier (27.5 and 28.5 on .NET 10): 919. The re-zip is done by the platform's runtime, so
        // the length differs per host; the parts and the relations above are the same on both.
        Observer.Ignore('second stored length');
#endif
        Observer.Expect('second stored parts are the source parts', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportFile_RebuiltPackage()
    var
        Observer: Codeunit "Probe Observer";
        Id1: Guid;
        Id2: Guid;
        Rebuilt: Text;
    begin
        // The same parts in another zip layout (written by Data Compression): does BC store the same bytes as for the source?
        Reset();
        Rebuilt := Rebuild(DocxBase64(), false);
        Id1 := ImportFileAs('F1', DocxBase64(), '.docx');
        Id2 := ImportFileAs('F2', Rebuilt, '.docx');
        Describe(Observer, Id2, 'F2', Rebuilt, false);
        Observer.Observe('stored is the stored of the source', Format(Stored(Id2) = Stored(Id1)));
        Reset();
        Observer.Expect('mime', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
        Observer.Expect('stored is the file', 'Yes');
        Observer.Expect('export is the stored content', 'Yes');
        Observer.Expect('stored parts', '[Content_Types].xml:429|_rels/.rels:297|word/document.xml:215');
        Observer.Expect('stored part order is the source order', 'Yes');
        Observer.Expect('stored parts are the source parts', 'Yes');
        Observer.Expect('stored first entry', 'method=8');
        Observer.Expect('stored first entry stamp is the source stamp', 'Yes');
        Observer.Expect('stored is the stored of the source', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportFile_ExtraPart()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
        Src: Text;
    begin
        // A part that no relationship names (word/extra.xml): kept or dropped?
        Reset();
        Src := Rebuild(DocxBase64(), true);
        Id := ImportFileAs('F1', Src, '.docx');
        Describe(Observer, Id, 'F1', Src, false);
        Reset();
        Observer.Expect('mime', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
        Observer.Expect('stored is the file', 'Yes');
        Observer.Expect('export is the stored content', 'Yes');
        Observer.Expect('stored parts', '[Content_Types].xml:429|_rels/.rels:297|word/document.xml:215|word/extra.xml:58');
        Observer.Expect('stored part order is the source order', 'Yes');
        Observer.Expect('stored parts are the source parts', 'Yes');
        Observer.Expect('stored first entry', 'method=8');
        Observer.Expect('stored first entry stamp is the source stamp', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportStream_NoMime()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT S Docx Media Row";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Id: Guid;
    begin
        Reset();
        ToBlob(DocxBase64(), TempBlob);
        TempBlob.CreateInStream(InS);
        Row.Code := 'S1';
        Id := Row.Pic.ImportStream(InS, 'Template');
        Row.Insert();
        Describe(Observer, Id, 'S1', DocxBase64());
        Reset();
        Observer.Expect('mime', 'application/octet-stream');
        Observer.Expect('stored length', '911');
        Observer.Expect('stored is the file', 'Yes');
        Observer.Expect('export length', '911');
        Observer.Expect('export is the stored content', 'Yes');
        Observer.Expect('stored parts', '[Content_Types].xml:429|_rels/.rels:297|word/document.xml:215');
        Observer.Expect('stored part order is the source order', 'Yes');
        Observer.Expect('stored parts are the source parts', 'Yes');
        Observer.Expect('stored first entry', 'method=8');
        Observer.Expect('stored first entry stamp is the source stamp', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportStream_DocxMime()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT S Docx Media Row";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Id: Guid;
    begin
        Reset();
        ToBlob(DocxBase64(), TempBlob);
        TempBlob.CreateInStream(InS);
        Row.Code := 'S1';
        Id := Row.Pic.ImportStream(InS, 'Template', DocxMimeTxt);
        Row.Insert();
        Describe(Observer, Id, 'S1', DocxBase64());
        Reset();
        Observer.Expect('mime', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
#if BC29PLUS
        Observer.Expect('stored length', '919');
#else
        // Windows BC 27.5 and 28.5: 911; the Linux CI tier (27.5 and 28.5 on .NET 10): 919. The re-zip is done by the platform's runtime, so
        // the length differs per host; the parts and the relations above are the same on both.
        Observer.Ignore('stored length');
#endif
        Observer.Expect('stored is the file', 'No');
#if BC29PLUS
        Observer.Expect('export length', '919');
#else
        // Windows BC 27.5 and 28.5: 911; the Linux CI tier (27.5 and 28.5 on .NET 10): 919. The re-zip is done by the platform's runtime, so
        // the length differs per host; the parts and the relations above are the same on both.
        Observer.Ignore('export length');
#endif
        Observer.Expect('export is the stored content', 'Yes');
        Observer.Expect('stored parts', '[Content_Types].xml:429|_rels/.rels:297|word/document.xml:215');
        Observer.Expect('stored part order is the source order', 'Yes');
        Observer.Expect('stored parts are the source parts', 'Yes');
        Observer.Expect('stored first entry', 'method=8');
        Observer.Expect('stored first entry stamp is the source stamp', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportStream_DocxFileName()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT S Docx Media Row";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Id: Guid;
    begin
        Reset();
        ToBlob(DocxBase64(), TempBlob);
        TempBlob.CreateInStream(InS);
        Row.Code := 'S1';
        Id := Row.Pic.ImportStream(InS, 'Template', DocxMimeTxt, 'template.docx');
        Row.Insert();
        Describe(Observer, Id, 'S1', DocxBase64());
        Reset();
        Observer.Expect('mime', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
#if BC29PLUS
        Observer.Expect('stored length', '919');
#else
        // Windows BC 27.5 and 28.5: 911; the Linux CI tier (27.5 and 28.5 on .NET 10): 919. The re-zip is done by the platform's runtime, so
        // the length differs per host; the parts and the relations above are the same on both.
        Observer.Ignore('stored length');
#endif
        Observer.Expect('stored is the file', 'No');
#if BC29PLUS
        Observer.Expect('export length', '919');
#else
        // Windows BC 27.5 and 28.5: 911; the Linux CI tier (27.5 and 28.5 on .NET 10): 919. The re-zip is done by the platform's runtime, so
        // the length differs per host; the parts and the relations above are the same on both.
        Observer.Ignore('export length');
#endif
        Observer.Expect('export is the stored content', 'Yes');
        Observer.Expect('stored parts', '[Content_Types].xml:429|_rels/.rels:297|word/document.xml:215');
        Observer.Expect('stored part order is the source order', 'Yes');
        Observer.Expect('stored parts are the source parts', 'Yes');
        Observer.Expect('stored first entry', 'method=8');
        Observer.Expect('stored first entry stamp is the source stamp', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportStream_ZipMime()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT S Docx Media Row";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Id: Guid;
    begin
        // The .docx bytes declared as a plain zip.
        Reset();
        ToBlob(DocxBase64(), TempBlob);
        TempBlob.CreateInStream(InS);
        Row.Code := 'S1';
        Id := Row.Pic.ImportStream(InS, 'Template', 'application/zip');
        Row.Insert();
        Describe(Observer, Id, 'S1', DocxBase64());
        Reset();
        Observer.Expect('mime', 'application/zip');
        Observer.Expect('stored length', '911');
        Observer.Expect('stored is the file', 'Yes');
        Observer.Expect('export length', '911');
        Observer.Expect('export is the stored content', 'Yes');
        Observer.Expect('stored parts', '[Content_Types].xml:429|_rels/.rels:297|word/document.xml:215');
        Observer.Expect('stored part order is the source order', 'Yes');
        Observer.Expect('stored parts are the source parts', 'Yes');
        Observer.Expect('stored first entry', 'method=8');
        Observer.Expect('stored first entry stamp is the source stamp', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportFile_ZipExtension()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
    begin
        Reset();
        Id := ImportFileAs('F1', DocxBase64(), '.zip');
        Describe(Observer, Id, 'F1', DocxBase64());
        Reset();
        Observer.Expect('mime', 'application/x-zip-compressed');
        Observer.Expect('stored length', '911');
        Observer.Expect('stored is the file', 'Yes');
        Observer.Expect('export length', '911');
        Observer.Expect('export is the stored content', 'Yes');
        Observer.Expect('stored parts', '[Content_Types].xml:429|_rels/.rels:297|word/document.xml:215');
        Observer.Expect('stored part order is the source order', 'Yes');
        Observer.Expect('stored parts are the source parts', 'Yes');
        Observer.Expect('stored first entry', 'method=8');
        Observer.Expect('stored first entry stamp is the source stamp', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportFile_XlsxExtension()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
    begin
        Reset();
        Id := ImportFileAs('F1', DocxBase64(), '.xlsx');
        Describe(Observer, Id, 'F1', DocxBase64());
        Reset();
        Observer.Expect('mime', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        Observer.Expect('stored length', '911');
        Observer.Expect('stored is the file', 'Yes');
        Observer.Expect('export length', '911');
        Observer.Expect('export is the stored content', 'Yes');
        Observer.Expect('stored parts', '[Content_Types].xml:429|_rels/.rels:297|word/document.xml:215');
        Observer.Expect('stored part order is the source order', 'Yes');
        Observer.Expect('stored parts are the source parts', 'Yes');
        Observer.Expect('stored first entry', 'method=8');
        Observer.Expect('stored first entry stamp is the source stamp', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportFile_UpperCaseExtension()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
    begin
        Reset();
        Id := ImportFileAs('F1', DocxBase64(), '.DOCX');
        Describe(Observer, Id, 'F1', DocxBase64());
        Reset();
        Observer.Expect('mime', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
#if BC29PLUS
        Observer.Expect('stored length', '919');
#else
        // Windows BC 27.5 and 28.5: 911; the Linux CI tier (27.5 and 28.5 on .NET 10): 919. The re-zip is done by the platform's runtime, so
        // the length differs per host; the parts and the relations above are the same on both.
        Observer.Ignore('stored length');
#endif
        Observer.Expect('stored is the file', 'No');
#if BC29PLUS
        Observer.Expect('export length', '919');
#else
        // Windows BC 27.5 and 28.5: 911; the Linux CI tier (27.5 and 28.5 on .NET 10): 919. The re-zip is done by the platform's runtime, so
        // the length differs per host; the parts and the relations above are the same on both.
        Observer.Ignore('export length');
#endif
        Observer.Expect('export is the stored content', 'Yes');
        Observer.Expect('stored parts', '[Content_Types].xml:429|_rels/.rels:297|word/document.xml:215');
        Observer.Expect('stored part order is the source order', 'Yes');
        Observer.Expect('stored parts are the source parts', 'Yes');
        Observer.Expect('stored first entry', 'method=8');
        Observer.Expect('stored first entry stamp is the source stamp', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportFile_NotAPackage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT S Docx Media Row";
        Tenant: Record "Tenant Media";
        Id: Guid;
        Src: Text;
    begin
        // A file named .docx that holds plain text (not a zip).
        Reset();
        Clear(Tenant);
        Src := 'aGVsbG8gZG9jeA==';
        Id := ImportFileAs('F1', Src, '.docx');
        Row.Get('F1');
        Observer.Observe('returned id is null', Format(IsNullGuid(Id)));
        Observer.Observe('media id is null', Format(IsNullGuid(Row.Pic.MediaId())));
        Observer.Observe('hasvalue', Format(Row.Pic.HasValue()));
        Observer.Observe('tenant media row', Format(Tenant.Get(Id)));
        Observer.Observe('export is the file', Format(Exported('F1') = Src));
        Observer.Observe('export length', Format(LenOf(Exported('F1'))));
        Reset();
        Observer.Expect('returned id is null', 'Yes');
        Observer.Expect('media id is null', 'Yes');
        Observer.Expect('hasvalue', 'No');
        Observer.Expect('tenant media row', 'No');
        Observer.Expect('export is the file', 'No');
        Observer.Expect('export length', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportFile_DotxExtension()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
    begin
        // The same bytes named as a Word template (.dotx).
        Reset();
        Id := ImportFileAs('F1', DocxBase64(), '.dotx');
        Describe(Observer, Id, 'F1', DocxBase64());
        Reset();
        Observer.Expect('mime', 'application/vnd.openxmlformats-officedocument.wordprocessingml.template');
#if BC29PLUS
        Observer.Expect('stored length', '919');
#else
        // Windows BC 27.5 and 28.5: 911; the Linux CI tier (27.5 and 28.5 on .NET 10): 919. The re-zip is done by the platform's runtime, so
        // the length differs per host; the parts and the relations above are the same on both.
        Observer.Ignore('stored length');
#endif
        Observer.Expect('stored is the file', 'No');
#if BC29PLUS
        Observer.Expect('export length', '919');
#else
        // Windows BC 27.5 and 28.5: 911; the Linux CI tier (27.5 and 28.5 on .NET 10): 919. The re-zip is done by the platform's runtime, so
        // the length differs per host; the parts and the relations above are the same on both.
        Observer.Ignore('export length');
#endif
        Observer.Expect('export is the stored content', 'Yes');
        Observer.Expect('stored parts', '[Content_Types].xml:429|_rels/.rels:297|word/document.xml:215');
        Observer.Expect('stored part order is the source order', 'Yes');
        Observer.Expect('stored parts are the source parts', 'Yes');
        Observer.Expect('stored first entry', 'method=8');
        Observer.Expect('stored first entry stamp is the source stamp', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportFile_DocmExtension()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
    begin
        // The same bytes named as a macro-enabled Word document (.docm).
        Reset();
        Id := ImportFileAs('F1', DocxBase64(), '.docm');
        Describe(Observer, Id, 'F1', DocxBase64());
        Reset();
        Observer.Expect('mime', 'application/vnd.ms-word.document.macroEnabled.12');
#if BC29PLUS
        Observer.Expect('stored length', '919');
#else
        // Windows BC 27.5 and 28.5: 911; the Linux CI tier (27.5 and 28.5 on .NET 10): 919. The re-zip is done by the platform's runtime, so
        // the length differs per host; the parts and the relations above are the same on both.
        Observer.Ignore('stored length');
#endif
        Observer.Expect('stored is the file', 'No');
#if BC29PLUS
        Observer.Expect('export length', '919');
#else
        // Windows BC 27.5 and 28.5: 911; the Linux CI tier (27.5 and 28.5 on .NET 10): 919. The re-zip is done by the platform's runtime, so
        // the length differs per host; the parts and the relations above are the same on both.
        Observer.Ignore('export length');
#endif
        Observer.Expect('export is the stored content', 'Yes');
        Observer.Expect('stored parts', '[Content_Types].xml:429|_rels/.rels:297|word/document.xml:215');
        Observer.Expect('stored part order is the source order', 'Yes');
        Observer.Expect('stored parts are the source parts', 'Yes');
        Observer.Expect('stored first entry', 'method=8');
        Observer.Expect('stored first entry stamp is the source stamp', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportFile_PptxExtension()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
    begin
        // The same bytes named as a PowerPoint package (.pptx).
        Reset();
        Id := ImportFileAs('F1', DocxBase64(), '.pptx');
        Describe(Observer, Id, 'F1', DocxBase64());
        Reset();
        Observer.Expect('mime', 'application/vnd.openxmlformats-officedocument.presentationml.presentation');
        Observer.Expect('stored length', '911');
        Observer.Expect('stored is the file', 'Yes');
        Observer.Expect('export length', '911');
        Observer.Expect('export is the stored content', 'Yes');
        Observer.Expect('stored parts', '[Content_Types].xml:429|_rels/.rels:297|word/document.xml:215');
        Observer.Expect('stored part order is the source order', 'Yes');
        Observer.Expect('stored parts are the source parts', 'Yes');
        Observer.Expect('stored first entry', 'method=8');
        Observer.Expect('stored first entry stamp is the source stamp', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportStream_UpperCaseDocxMime()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT S Docx Media Row";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Id: Guid;
    begin
        // The Word mime type in upper case.
        Reset();
        ToBlob(DocxBase64(), TempBlob);
        TempBlob.CreateInStream(InS);
        Row.Code := 'S1';
        Id := Row.Pic.ImportStream(InS, 'Template', 'APPLICATION/VND.OPENXMLFORMATS-OFFICEDOCUMENT.WORDPROCESSINGML.DOCUMENT');
        Row.Insert();
        Describe(Observer, Id, 'S1', DocxBase64());
        Reset();
        Observer.Expect('mime', 'APPLICATION/VND.OPENXMLFORMATS-OFFICEDOCUMENT.WORDPROCESSINGML.DOCUMENT');
#if BC29PLUS
        Observer.Expect('stored length', '919');
#else
        // Windows BC 27.5 and 28.5: 911; the Linux CI tier (27.5 and 28.5 on .NET 10): 919. The re-zip is done by the platform's runtime, so
        // the length differs per host; the parts and the relations above are the same on both.
        Observer.Ignore('stored length');
#endif
        Observer.Expect('stored is the file', 'No');
#if BC29PLUS
        Observer.Expect('export length', '919');
#else
        // Windows BC 27.5 and 28.5: 911; the Linux CI tier (27.5 and 28.5 on .NET 10): 919. The re-zip is done by the platform's runtime, so
        // the length differs per host; the parts and the relations above are the same on both.
        Observer.Ignore('export length');
#endif
        Observer.Expect('export is the stored content', 'Yes');
        Observer.Expect('stored parts', '[Content_Types].xml:429|_rels/.rels:297|word/document.xml:215');
        Observer.Expect('stored part order is the source order', 'Yes');
        Observer.Expect('stored parts are the source parts', 'Yes');
        Observer.Expect('stored first entry', 'method=8');
        Observer.Expect('stored first entry stamp is the source stamp', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaImportStream_NotAPackageDocxMime()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT S Docx Media Row";
        Tenant: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Id: Guid;
        Src: Text;
    begin
        // Plain text (not a zip) through ImportStream with the Word mime type.
        Reset();
        Src := 'aGVsbG8gZG9jeA==';
        ToBlob(Src, TempBlob);
        TempBlob.CreateInStream(InS);
        Row.Code := 'S1';
        Id := Row.Pic.ImportStream(InS, 'Template', DocxMimeTxt);
        Row.Insert();
        Row.Get('S1');
        Observer.Observe('returned id is null', Format(IsNullGuid(Id)));
        Observer.Observe('media id is null', Format(IsNullGuid(Row.Pic.MediaId())));
        Observer.Observe('hasvalue', Format(Row.Pic.HasValue()));
        Observer.Observe('tenant media row', Format(Tenant.Get(Id)));
        Observer.Observe('export is the file', Format(Exported('S1') = Src));
        Observer.Observe('export length', Format(LenOf(Exported('S1'))));
        Reset();
        Observer.Expect('returned id is null', 'Yes');
        Observer.Expect('media id is null', 'Yes');
        Observer.Expect('hasvalue', 'No');
        Observer.Expect('tenant media row', 'No');
        Observer.Expect('export is the file', 'No');
        Observer.Expect('export length', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaSetImportFile_Stored()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT S Docx Media Row";
        Path: Text;
        Id: Guid;
        S: Text;
    begin
        Reset();
        Path := TempName('.docx');
        WriteFile(Path, DocxBase64());
        Row.Code := 'M1';
        Id := Row.Set.ImportFile(Path, 'Template');
        Row.Insert();
        Cleanup(Path);
        S := Stored(Row.Set.Item(1));
        Observer.Observe('count', Format(Row.Set.Count()));
        Observer.Observe('mime', Mime(Row.Set.Item(1)));
        Observer.Observe('stored length', Format(LenOf(S)));
        Observer.Observe('stored is the file', Format(S = DocxBase64()));
        Observer.Observe('stored parts are the source parts', SameParts(S, DocxBase64()));
        Observer.Observe('stored part order is the source order', Format(Parts(S) = Parts(DocxBase64())));
        Reset();
        Observer.Expect('count', '1');
        Observer.Expect('mime', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
#if BC29PLUS
        Observer.Expect('stored length', '919');
#else
        // Windows BC 27.5 and 28.5: 911; the Linux CI tier (27.5 and 28.5 on .NET 10): 919. The re-zip is done by the platform's runtime, so
        // the length differs per host; the parts and the relations above are the same on both.
        Observer.Ignore('stored length');
#endif
        Observer.Expect('stored is the file', 'No');
        Observer.Expect('stored parts are the source parts', 'Yes');
        Observer.Expect('stored part order is the source order', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Docx_MediaSetImportStream_Stored()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT S Docx Media Row";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        S: Text;
    begin
        Reset();
        ToBlob(DocxBase64(), TempBlob);
        TempBlob.CreateInStream(InS);
        Row.Code := 'M1';
        Row.Set.ImportStream(InS, 'Template', DocxMimeTxt);
        Row.Insert();
        S := Stored(Row.Set.Item(1));
        Observer.Observe('count', Format(Row.Set.Count()));
        Observer.Observe('mime', Mime(Row.Set.Item(1)));
        Observer.Observe('stored length', Format(LenOf(S)));
        Observer.Observe('stored is the file', Format(S = DocxBase64()));
        Observer.Observe('stored parts are the source parts', SameParts(S, DocxBase64()));
        Observer.Observe('stored part order is the source order', Format(Parts(S) = Parts(DocxBase64())));
        Reset();
        Observer.Expect('count', '1');
        Observer.Expect('mime', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
#if BC29PLUS
        Observer.Expect('stored length', '919');
#else
        // Windows BC 27.5 and 28.5: 911; the Linux CI tier (27.5 and 28.5 on .NET 10): 919. The re-zip is done by the platform's runtime, so
        // the length differs per host; the parts and the relations above are the same on both.
        Observer.Ignore('stored length');
#endif
        Observer.Expect('stored is the file', 'No');
        Observer.Expect('stored parts are the source parts', 'Yes');
        Observer.Expect('stored part order is the source order', 'Yes');
        Observer.Verify();
    end;
}
