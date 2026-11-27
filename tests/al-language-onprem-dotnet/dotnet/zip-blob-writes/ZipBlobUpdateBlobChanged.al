// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.io.compression.ziparchive.dispose
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; LT ZB Zip Helper (99022) and table 99020
// Probe: written against al-runner issue 9291. A seed zip is copied into a temporary Blob through an OutStream, and
//        ZipArchive(OutStream, Update, false, UTF8) is opened over that same OutStream with one added entry. Before
//        Dispose, AL changes the Blob (Clear and a rewrite with another zip, Clear only), .NET appends through the
//        original OutStream, a second Update archive works on the same OutStream; and Dispose without parentheses.
// BC versions: 27, 28, 29
codeunit 99024 "LT ZB Update Blob Changed"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure OpenOnSeed(var Buffer: Record "LT ZB Zip File" temporary; var BufferOut: OutStream; var ZipArchive: DotNet LtZbZipArchive)
    var
        Helper: Codeunit "LT ZB Zip Helper";
        Seed: Record "LT ZB Zip File" temporary;
        Mode: DotNet LtZbZipMode;
        Enc: DotNet LtZbEncoding;
        SeedIn: InStream;
    begin
        Helper.SeedIn(Seed, 'a.txt', SeedIn);
        Buffer.Content.CreateOutStream(BufferOut);
        CopyStream(BufferOut, SeedIn);
        ZipArchive := ZipArchive.ZipArchive(BufferOut, Mode.Update, false, Enc.UTF8());
        Helper.AddEntry(ZipArchive, 'b.txt');
    end;

    local procedure RewriteWithOther(var Buffer: Record "LT ZB Zip File" temporary)
    var
        Helper: Codeunit "LT ZB Zip Helper";
        Other: Record "LT ZB Zip File" temporary;
        OtherIn: InStream;
        NewOut: OutStream;
    begin
        Helper.SeedIn(Other, 'z.txt', OtherIn);
        Clear(Buffer.Content);
        Buffer.Content.CreateOutStream(NewOut);
        CopyStream(NewOut, OtherIn);
    end;

    [Test]
    procedure ZB_ClearAndRewrite_Dispose()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        BufferOut: OutStream;
    begin
        OpenOnSeed(Buffer, BufferOut, ZipArchive);
        RewriteWithOther(Buffer);
        Observer.Observe('length before Dispose', Format(Buffer.Content.Length));
        ZipArchive.Dispose();
        Observer.Observe('length', Format(Buffer.Content.Length));
        Observer.Observe('entries', Helper.BufferEntries(Buffer));
        Observer.Finish();
    end;

    [Test]
    procedure ZB_ClearAndRewrite_AppendOriginal_Dispose()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        Writer: DotNet LtZbStreamWriter;
        BufferOut: OutStream;
    begin
        OpenOnSeed(Buffer, BufferOut, ZipArchive);
        RewriteWithOther(Buffer);
        Writer := Writer.StreamWriter(BufferOut);
        Writer.Write('xyz');
        Writer.Flush();
        Observer.Observe('length after append', Format(Buffer.Content.Length));
        Observer.Observe('last bytes after append', Helper.LastBytes(Buffer));
        ZipArchive.Dispose();
        Observer.Observe('length', Format(Buffer.Content.Length));
        Observer.Observe('last bytes', Helper.LastBytes(Buffer));
        Observer.Observe('entries', Helper.BufferEntries(Buffer));
        Observer.Finish();
    end;

    [Test]
    procedure ZB_ClearOnly_Dispose()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        BufferOut: OutStream;
    begin
        OpenOnSeed(Buffer, BufferOut, ZipArchive);
        Clear(Buffer.Content);
        ZipArchive.Dispose();
        Observer.Observe('has value', Format(Buffer.Content.HasValue()));
        Observer.Observe('length', Format(Buffer.Content.Length));
        Observer.Finish();
    end;

    [Test]
    procedure ZB_NoChange_DisposeNoParens()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        BufferOut: OutStream;
    begin
        OpenOnSeed(Buffer, BufferOut, ZipArchive);
        ZipArchive.Dispose;
        Observer.Observe('length', Format(Buffer.Content.Length));
        Observer.Observe('entries', Helper.BufferEntries(Buffer));
        Observer.Finish();
    end;

    [Test]
    procedure ZB_NoChange_DisposeParens()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        BufferOut: OutStream;
    begin
        OpenOnSeed(Buffer, BufferOut, ZipArchive);
        ZipArchive.Dispose();
        Observer.Observe('length', Format(Buffer.Content.Length));
        Observer.Observe('entries', Helper.BufferEntries(Buffer));
        Observer.Finish();
    end;

    [Test]
    procedure ZB_TwoArchives_SameOutStream()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Seed: Record "LT ZB Zip File" temporary;
        Buffer: Record "LT ZB Zip File" temporary;
        First: DotNet LtZbZipArchive;
        Second: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        Enc: DotNet LtZbEncoding;
        SeedIn: InStream;
        BufferOut: OutStream;
    begin
        Helper.SeedIn(Seed, 'a.txt', SeedIn);
        Buffer.Content.CreateOutStream(BufferOut);
        CopyStream(BufferOut, SeedIn);
        First := First.ZipArchive(BufferOut, Mode.Update, false, Enc.UTF8());
        Second := Second.ZipArchive(BufferOut, Mode.Update, false, Enc.UTF8());
        Helper.AddEntry(First, 'b.txt');
        Helper.AddEntry(Second, 'c.txt');
        First.Dispose();
        Observer.Observe('length after first Dispose', Format(Buffer.Content.Length));
        Second.Dispose();
        Observer.Observe('length', Format(Buffer.Content.Length));
        Observer.Observe('entries', Helper.BufferEntries(Buffer));
        Observer.Finish();
    end;
}
