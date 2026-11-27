// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.io.compression.ziparchive.-ctor
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; LT ZB Zip Helper (99022) and tables 99020, 99021
// Probe: written against al-runner issue 9246. A Blob field holds a zip; AL calls CreateOutStream on the field again
//        and opens System.IO.Compression.ZipArchive in Update mode over that fresh OutStream, adds an entry and disposes.
//        Stored table (with and without CalcFields before CreateOutStream, with and without Modify), temporary table,
//        the 2-, 3- and 4-argument constructors, and an empty Blob as the control.
// Facts (same on BC 27.5, 28.5, 29.0; local BC on Linux): a fresh CreateOutStream does not truncate the Blob for
//        .NET. Update mode reads the existing zip (1 entry) when the Blob value is loaded (CalcFields on a stored record,
//        or a temporary record); Dispose then writes the whole archive back (108 -> 194 bytes, 2 entries). Without
//        CalcFields the archive sees 0 entries and the stored zip ends with only the new entry (the seed entry is lost).
//        Without Modify the variable has the new zip and the database keeps the old one. The 2-, 3- and 4-argument
//        constructors behave the same. No cell raises an error.
// BC versions: 27, 28, 29
codeunit 99023 "LT ZB Update Fresh Out"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedStored(var Stored: Record "LT ZB Stored Zip File")
    var
        Helper: Codeunit "LT ZB Zip Helper";
        Seed: Record "LT ZB Zip File" temporary;
        SeedIn: InStream;
        StoredOut: OutStream;
    begin
        Stored.DeleteAll();
        Helper.SeedIn(Seed, 'a.txt', SeedIn);
        Stored.Init();
        Stored."No." := 1;
        Stored.Content.CreateOutStream(StoredOut);
        CopyStream(StoredOut, SeedIn);
        Stored.Insert();
    end;

    local procedure SeedBuffer(var Buffer: Record "LT ZB Zip File" temporary)
    var
        Helper: Codeunit "LT ZB Zip Helper";
        Seed: Record "LT ZB Zip File" temporary;
        SeedIn: InStream;
        BufferOut: OutStream;
    begin
        Helper.SeedIn(Seed, 'a.txt', SeedIn);
        Buffer.Content.CreateOutStream(BufferOut);
        CopyStream(BufferOut, SeedIn);
    end;

    [Test]
    procedure ZB_StoredCalcFields_Update4_Modify()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Stored: Record "LT ZB Stored Zip File";
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        Enc: DotNet LtZbEncoding;
        StoredOut: OutStream;
    begin
        SeedStored(Stored);
        Stored.Get(1);
        Stored.CalcFields(Content);
        Observer.Observe('seed length', Format(Stored.Content.Length));
        Stored.Content.CreateOutStream(StoredOut);
        Observer.Observe('length after CreateOutStream', Format(Stored.Content.Length));
        ZipArchive := ZipArchive.ZipArchive(StoredOut, Mode.Update, false, Enc.UTF8());
        Observer.Observe('entries in archive', Format(ZipArchive.Entries.Count));
        Helper.AddEntry(ZipArchive, 'b.txt');
        ZipArchive.Dispose();
        Observer.Observe('length after Dispose', Format(Stored.Content.Length));
        Stored.Modify();
        Stored.Get(1);
        Stored.CalcFields(Content);
        Observer.Observe('stored length', Format(Stored.Content.Length));
        Observer.Observe('stored entries', Helper.StoredEntries(Stored));
        Observer.Expect('seed length', '108');
        Observer.Expect('length after CreateOutStream', '108');
        Observer.Expect('entries in archive', '1');
        Observer.Expect('length after Dispose', '194');
        Observer.Expect('stored length', '194');
        Observer.Expect('stored entries', '2:a.txt;b.txt;');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_StoredNoCalcFields_Update4_Modify()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Stored: Record "LT ZB Stored Zip File";
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        Enc: DotNet LtZbEncoding;
        StoredOut: OutStream;
    begin
        SeedStored(Stored);
        Stored.Get(1);
        Stored.Content.CreateOutStream(StoredOut);
        ZipArchive := ZipArchive.ZipArchive(StoredOut, Mode.Update, false, Enc.UTF8());
        Observer.Observe('entries in archive', Format(ZipArchive.Entries.Count));
        Helper.AddEntry(ZipArchive, 'b.txt');
        ZipArchive.Dispose();
        Observer.Observe('length after Dispose', Format(Stored.Content.Length));
        Stored.Modify();
        Stored.Get(1);
        Stored.CalcFields(Content);
        Observer.Observe('stored length', Format(Stored.Content.Length));
        Observer.Observe('stored entries', Helper.StoredEntries(Stored));
        Observer.Expect('entries in archive', '0');
        Observer.Expect('length after Dispose', '108');
        Observer.Expect('stored length', '108');
        Observer.Expect('stored entries', '1:b.txt;');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_StoredCalcFields_Update4_NoModify()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Stored: Record "LT ZB Stored Zip File";
        Again: Record "LT ZB Stored Zip File";
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        Enc: DotNet LtZbEncoding;
        StoredOut: OutStream;
    begin
        SeedStored(Stored);
        Stored.Get(1);
        Stored.CalcFields(Content);
        Stored.Content.CreateOutStream(StoredOut);
        ZipArchive := ZipArchive.ZipArchive(StoredOut, Mode.Update, false, Enc.UTF8());
        Helper.AddEntry(ZipArchive, 'b.txt');
        ZipArchive.Dispose();
        Observer.Observe('length after Dispose', Format(Stored.Content.Length));
        Observer.Observe('entries of the variable', Helper.StoredEntries(Stored));
        Again.Get(1);
        Again.CalcFields(Content);
        Observer.Observe('length in the database', Format(Again.Content.Length));
        Observer.Expect('length after Dispose', '194');
        Observer.Expect('entries of the variable', '2:a.txt;b.txt;');
        Observer.Expect('length in the database', '108');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_Temp_Update4()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        Enc: DotNet LtZbEncoding;
        BufferOut: OutStream;
    begin
        SeedBuffer(Buffer);
        Observer.Observe('seed length', Format(Buffer.Content.Length));
        Buffer.Content.CreateOutStream(BufferOut);
        Observer.Observe('length after CreateOutStream', Format(Buffer.Content.Length));
        ZipArchive := ZipArchive.ZipArchive(BufferOut, Mode.Update, false, Enc.UTF8());
        Observer.Observe('entries in archive', Format(ZipArchive.Entries.Count));
        Helper.AddEntry(ZipArchive, 'b.txt');
        ZipArchive.Dispose();
        Observer.Observe('length', Format(Buffer.Content.Length));
        Observer.Observe('entries', Helper.BufferEntries(Buffer));
        Observer.Expect('seed length', '108');
        Observer.Expect('length after CreateOutStream', '108');
        Observer.Expect('entries in archive', '1');
        Observer.Expect('length', '194');
        Observer.Expect('entries', '2:a.txt;b.txt;');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_Temp_Update2()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        BufferOut: OutStream;
    begin
        SeedBuffer(Buffer);
        Buffer.Content.CreateOutStream(BufferOut);
        ZipArchive := ZipArchive.ZipArchive(BufferOut, Mode.Update);
        Observer.Observe('entries in archive', Format(ZipArchive.Entries.Count));
        Helper.AddEntry(ZipArchive, 'b.txt');
        ZipArchive.Dispose();
        Observer.Observe('length', Format(Buffer.Content.Length));
        Observer.Observe('entries', Helper.BufferEntries(Buffer));
        Observer.Expect('entries in archive', '1');
        Observer.Expect('length', '194');
        Observer.Expect('entries', '2:a.txt;b.txt;');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_Temp_Update3()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        BufferOut: OutStream;
    begin
        SeedBuffer(Buffer);
        Buffer.Content.CreateOutStream(BufferOut);
        ZipArchive := ZipArchive.ZipArchive(BufferOut, Mode.Update, false);
        Observer.Observe('entries in archive', Format(ZipArchive.Entries.Count));
        Helper.AddEntry(ZipArchive, 'b.txt');
        ZipArchive.Dispose();
        Observer.Observe('length', Format(Buffer.Content.Length));
        Observer.Observe('entries', Helper.BufferEntries(Buffer));
        Observer.Expect('entries in archive', '1');
        Observer.Expect('length', '194');
        Observer.Expect('entries', '2:a.txt;b.txt;');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_TempEmpty_Update4()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        Enc: DotNet LtZbEncoding;
        BufferOut: OutStream;
    begin
        Buffer.Content.CreateOutStream(BufferOut);
        ZipArchive := ZipArchive.ZipArchive(BufferOut, Mode.Update, false, Enc.UTF8());
        Observer.Observe('entries in archive', Format(ZipArchive.Entries.Count));
        Helper.AddEntry(ZipArchive, 'b.txt');
        ZipArchive.Dispose();
        Observer.Observe('length', Format(Buffer.Content.Length));
        Observer.Observe('entries', Helper.BufferEntries(Buffer));
        Observer.Expect('entries in archive', '0');
        Observer.Expect('length', '108');
        Observer.Expect('entries', '1:b.txt;');
        Observer.Verify();
    end;
}
