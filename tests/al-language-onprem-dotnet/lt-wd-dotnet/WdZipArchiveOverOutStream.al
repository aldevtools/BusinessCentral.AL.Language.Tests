// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.io.compression.ziparchive
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained objects 99346-99348
// Probe: written against al-runner issue 6317. The shape of System Application "Data Compression Impl.".OpenZipArchive: a zip is copied into a Blob through its OutStream,
//        and System.IO.Compression.ZipArchive is opened in Read mode over that same OutStream. Compared with opening it over an InStream of the Blob.
//        Every value asserted below is what the BC service tier produced.
// BC versions: 27, 28, 29
dotnet
{
    assembly("netstandard")
    {
        type("System.IO.Compression.ZipArchive"; LtWdZipArchive) { }
        type("System.IO.Compression.ZipArchiveMode"; LtWdZipMode) { }
        type("System.IO.Compression.ZipArchiveEntry"; LtWdZipEntry) { }
    }
}

table 99346 "LT WD Zip File"
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

codeunit 99347 "LT WD Zip Over OutStream"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure MakeZip(var ZipFile: Record "LT WD Zip File" temporary)
    var
        Entry: Record "LT WD Zip File" temporary;
        ZipArchive: DotNet LtWdZipArchive;
        Mode: DotNet LtWdZipMode;
        ZipEntry: DotNet LtWdZipEntry;
        EntryIn: InStream;
        EntryOut: OutStream;
        ZipOut: OutStream;
    begin
        Entry.Content.CreateOutStream(EntryOut);
        EntryOut.WriteText('hello');
        Entry.Content.CreateInStream(EntryIn);
        ZipFile.Content.CreateOutStream(ZipOut);
        ZipArchive := ZipArchive.ZipArchive(ZipOut, Mode.Create);
        ZipEntry := ZipArchive.CreateEntry('a.txt');
        CopyStream(ZipEntry.Open(), EntryIn);
        ZipArchive.Dispose();
    end;

    [Test]
    procedure WD_Zip_ReadThroughAnInStream()
    var
        Observer: Codeunit "Probe Observer";
        ZipFile: Record "LT WD Zip File" temporary;
        ZipArchive: DotNet LtWdZipArchive;
        Mode: DotNet LtWdZipMode;
        ZipIn: InStream;
    begin
        MakeZip(ZipFile);
        ZipFile.Content.CreateInStream(ZipIn);
        ZipArchive := ZipArchive.ZipArchive(ZipIn, Mode.Read);
        Observer.Observe('entries', Format(ZipArchive.Entries.Count));
        Observer.Expect('entries', '1');
        Observer.Verify();
    end;

    [Test]
    procedure WD_Zip_ReadThroughAnOutStream()
    var
        Observer: Codeunit "Probe Observer";
        ZipFile: Record "LT WD Zip File" temporary;
        Buffer: Record "LT WD Zip File" temporary;
        ZipArchive: DotNet LtWdZipArchive;
        Mode: DotNet LtWdZipMode;
        ZipIn: InStream;
        BufferOut: OutStream;
    begin
        MakeZip(ZipFile);
        ZipFile.Content.CreateInStream(ZipIn);
        Buffer.Content.CreateOutStream(BufferOut);
        CopyStream(BufferOut, ZipIn);
        ZipArchive := ZipArchive.ZipArchive(BufferOut, Mode.Read);
        Observer.Observe('entries', Format(ZipArchive.Entries.Count));
        Observer.Expect('entries', '1');
        Observer.Verify();
    end;
}
