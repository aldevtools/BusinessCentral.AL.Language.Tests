// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.io.compression.ziparchive.-ctor
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; LT ZB Zip Helper (99022) and tables 99020, 99021
// Probe: written against al-runner issue 9246. A Blob field holds a zip; AL calls CreateOutStream on the field again
//        and opens System.IO.Compression.ZipArchive in Update mode over that fresh OutStream, adds an entry and disposes.
//        Stored table (with and without CalcFields before CreateOutStream, with and without Modify), temporary table,
//        the 2-, 3- and 4-argument constructors, and an empty Blob as the control.
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
