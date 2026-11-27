// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.io.compression.ziparchive
// Scope: fixture of the zip-blob-writes probes (tables and helper codeunit, no tests)
// Fixtures used: none; own objects 99020-99022
// Probe: written against al-runner issues 9246, 9291 and 7947. The helper makes a seed zip (one empty entry) with
//        ZipArchive(OutStream, Create) + CreateEntry + Dispose and reads entry names, Blob length and bytes back.
// BC versions: 27, 28, 29
dotnet
{
    assembly("netstandard")
    {
        type("System.IO.Compression.ZipArchive"; LtZbZipArchive) { }
        type("System.IO.Compression.ZipArchiveMode"; LtZbZipMode) { }
        type("System.IO.Compression.ZipArchiveEntry"; LtZbZipEntry) { }
        type("System.Text.Encoding"; LtZbEncoding) { }
        type("System.IO.StreamWriter"; LtZbStreamWriter) { }
        type("System.IO.Stream"; LtZbStream) { }
    }
}

table 99020 "LT ZB Zip File"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Content; Blob) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 99021 "LT ZB Stored Zip File"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Content; Blob) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 99022 "LT ZB Zip Helper"
{
    procedure MakeZip(var ZipFile: Record "LT ZB Zip File" temporary; Name: Text)
    var
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        ZipEntry: DotNet LtZbZipEntry;
        ZipOut: OutStream;
    begin
        ZipFile.Content.CreateOutStream(ZipOut);
        ZipArchive := ZipArchive.ZipArchive(ZipOut, Mode.Create);
        ZipEntry := ZipArchive.CreateEntry(Name);
        ZipArchive.Dispose();
    end;

    procedure SeedIn(var ZipFile: Record "LT ZB Zip File" temporary; Name: Text; var ZipIn: InStream)
    begin
        MakeZip(ZipFile, Name);
        ZipFile.Content.CreateInStream(ZipIn);
    end;

    procedure AddEntry(ZipArchive: DotNet LtZbZipArchive; Name: Text)
    var
        ZipEntry: DotNet LtZbZipEntry;
    begin
        ZipEntry := ZipArchive.CreateEntry(Name);
    end;

    // "<count>:<name>;<name>;" of the zip read from InS in Read mode.
    procedure Entries(var InS: InStream): Text
    var
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        ZipEntry: DotNet LtZbZipEntry;
        Names: Text;
    begin
        ZipArchive := ZipArchive.ZipArchive(InS, Mode.Read);
        foreach ZipEntry in ZipArchive.Entries do
            Names += ZipEntry.FullName + ';';
        exit(Format(ZipArchive.Entries.Count) + ':' + Names);
    end;

    procedure BufferEntries(var ZipFile: Record "LT ZB Zip File" temporary): Text
    var
        InS: InStream;
    begin
        ZipFile.Content.CreateInStream(InS);
        exit(Entries(InS));
    end;

    procedure StoredEntries(var ZipFile: Record "LT ZB Stored Zip File"): Text
    var
        InS: InStream;
    begin
        ZipFile.Content.CreateInStream(InS);
        exit(Entries(InS));
    end;

    // The last three bytes of the Blob as decimal numbers, "b1,b2,b3".
    procedure LastBytes(var ZipFile: Record "LT ZB Zip File" temporary): Text
    var
        InS: InStream;
        B: Byte;
        B1: Integer;
        B2: Integer;
        B3: Integer;
    begin
        ZipFile.Content.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.Read(B);
            B1 := B2;
            B2 := B3;
            B3 := B;
        end;
        exit(StrSubstNo('%1,%2,%3', B1, B2, B3));
    end;

    procedure BlobText(var ZipFile: Record "LT ZB Zip File" temporary): Text
    var
        InS: InStream;
        T: Text;
    begin
        ZipFile.Content.CreateInStream(InS);
        InS.ReadText(T);
        exit(T);
    end;

    procedure StoredText(var ZipFile: Record "LT ZB Stored Zip File"): Text
    var
        InS: InStream;
        T: Text;
    begin
        ZipFile.Content.CreateInStream(InS);
        InS.ReadText(T);
        exit(T);
    end;
}
