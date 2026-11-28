// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.io.compression.ziparchive.dispose
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; LT ZB Zip Helper (99022) and tables 99020, 99021; own dotnet alias LtZbfStreamReader
// Probe: written against al-runner issue 9318. A seed zip is in a Blob; AL calls CreateOutStream on the field again and
//        opens ZipArchive in Update mode over that fresh OutStream, adds b.txt, and then changes the Blob before Dispose.
//        Seed with one empty entry a.txt (108 bytes): an AL WriteText('x') into the same OutStream (after or before
//        CreateEntry, 4- and 2-argument constructor, temporary and stored record), Clear of the field, Clear plus a rewrite
//        with another zip (z.txt), and a .NET append through a StreamWriter over the same OutStream. Seed whose a.txt holds
//        'hello' (121 bytes): no change, an AL WriteText of 40 'x' (covers the a.txt local header and its data), and Clear.
//        Every cell compares the bytes after Dispose with the seed ("first change": 0-based offset and the next 3 bytes).
// Measured on BC 27.5.54899.59044, 28.5.54976.59048 and 29.0.54011.59052 (W1, BC on Linux, the CI leg setup); all three agree.
// Facts: no ZipArchive call and no Dispose raises an error. Empty seed: every Dispose leaves 194 bytes, entries a.txt and
//        b.txt in Read mode, last bytes 0,0,0. An AL WriteText('x') writes at offset 0 over the seed (first bytes
//        120,75,3; length stays 108), and these bytes are still there after Dispose (first change at offset 0), on the
//        stored record after Modify, Get and CalcFields too. A StreamWriter 'xyz' over the same OutStream also writes at
//        offset 0 (length stays 108) and stays after Dispose. Clear makes HasValue No and Length 0; after Dispose HasValue
//        is Yes and the bytes up to offset 36 equal the seed (first change at 37). Clear plus a rewrite with the z.txt zip:
//        after Dispose the first change is at offset 30, the name 'z.txt' of the rewrite (bytes 122,46,116). 'hello' seed:
//        without a change, Dispose leaves 207 bytes, a.txt reads 'hello', first change at offset 50. With 40 'x' written
//        by AL (length stays 121), Dispose succeeds and leaves 207 bytes with entries a.txt and b.txt, the 40 'x' are still
//        at offset 0, and opening a.txt fails with "A local file header is corrupt." before and after Dispose. With Clear,
//        Dispose leaves 207 bytes, first change at 50, a.txt reads 'hello'. So Dispose does not write the bytes in front of
//        those offsets: what is in the Blob there at Dispose stays (the AL write, the rewrite), and after Clear the seed
//        bytes are there again.
// BC versions: 27, 28, 29
dotnet
{
    assembly("netstandard")
    {
        type("System.IO.StreamReader"; LtZbfStreamReader) { }
    }
}

codeunit 99026 "LT ZB Update Fresh Changed"
{
    Subtype = Test;
    TestPermissions = Disabled;

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

    local procedure ReadBytes(var InS: InStream; var Bytes: List of [Integer])
    var
        B: Byte;
    begin
        Clear(Bytes);
        while not InS.EOS() do begin
            InS.Read(B);
            Bytes.Add(B);
        end;
    end;

    // "<offset>:<b1>,<b2>,<b3>" at the first byte (0-based) where Now differs from Before; "shorter" or "same" otherwise.
    local procedure FirstChange(var Before: List of [Integer]; var Now: List of [Integer]): Text
    var
        I: Integer;
        J: Integer;
        Bytes: Text;
        Changed: Boolean;
    begin
        for I := 1 to Now.Count() do begin
            Changed := I > Before.Count();
            if not Changed then
                Changed := Now.Get(I) <> Before.Get(I);
            if Changed then begin
                for J := I to I + 2 do
                    if J <= Now.Count() then
                        Bytes += Format(Now.Get(J)) + ',';
                exit(Format(I - 1) + ':' + Bytes.TrimEnd(','));
            end;
        end;
        if Now.Count() < Before.Count() then
            exit('shorter');
        exit('same');
    end;

    local procedure BufferBytes(var Buffer: Record "LT ZB Zip File" temporary; var Bytes: List of [Integer])
    var
        InS: InStream;
    begin
        Buffer.Content.CreateInStream(InS);
        ReadBytes(InS, Bytes);
    end;

    local procedure StoredBytes(var Stored: Record "LT ZB Stored Zip File"; var Bytes: List of [Integer])
    var
        InS: InStream;
    begin
        Stored.Content.CreateInStream(InS);
        ReadBytes(InS, Bytes);
    end;

    [TryFunction]
    local procedure TryDispose(ZipArchive: DotNet LtZbZipArchive)
    begin
        ZipArchive.Dispose();
    end;

    [TryFunction]
    local procedure TryBufferEntries(var Buffer: Record "LT ZB Zip File" temporary; var Names: Text)
    var
        Helper: Codeunit "LT ZB Zip Helper";
    begin
        Names := Helper.BufferEntries(Buffer);
    end;

    [TryFunction]
    local procedure TryStoredEntries(var Stored: Record "LT ZB Stored Zip File"; var Names: Text)
    var
        Helper: Codeunit "LT ZB Zip Helper";
    begin
        Names := Helper.StoredEntries(Stored);
    end;

    local procedure ObserveDispose(var Observer: Codeunit "Probe Observer"; ZipArchive: DotNet LtZbZipArchive)
    begin
        if TryDispose(ZipArchive) then
            Observer.Observe('dispose error', 'none')
        else
            Observer.Observe('dispose error', GetLastErrorText());
        ClearLastError();
    end;

    local procedure ObserveBuffer(var Observer: Codeunit "Probe Observer"; var Buffer: Record "LT ZB Zip File" temporary)
    var
        Helper: Codeunit "LT ZB Zip Helper";
        Names: Text;
    begin
        Observer.Observe('has value', Format(Buffer.Content.HasValue()));
        Observer.Observe('length', Format(Buffer.Content.Length));
        Observer.Observe('last bytes', Helper.LastBytes(Buffer));
        if TryBufferEntries(Buffer, Names) then
            Observer.Observe('entries', Names)
        else
            Observer.Observe('entries error', GetLastErrorText());
        ClearLastError();
    end;

    // A zip with one entry a.txt that holds the text 'hello', copied into Buffer (as SeedBuffer does for the empty entry).
    local procedure SeedBufferHello(var Buffer: Record "LT ZB Zip File" temporary)
    var
        Seed: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        ZipEntry: DotNet LtZbZipEntry;
        EntryStream: DotNet LtZbStream;
        Writer: DotNet LtZbStreamWriter;
        SeedOut: OutStream;
        SeedIn: InStream;
        BufferOut: OutStream;
    begin
        Seed.Content.CreateOutStream(SeedOut);
        ZipArchive := ZipArchive.ZipArchive(SeedOut, Mode.Create);
        ZipEntry := ZipArchive.CreateEntry('a.txt');
        EntryStream := ZipEntry.Open();
        Writer := Writer.StreamWriter(EntryStream);
        Writer.Write('hello');
        Writer.Flush();
        Writer.Dispose();
        ZipArchive.Dispose();
        Seed.Content.CreateInStream(SeedIn);
        Buffer.Content.CreateOutStream(BufferOut);
        CopyStream(BufferOut, SeedIn);
    end;

    // The text of entry Name of the zip in Buffer (Read mode), or '<no entry>'.
    [TryFunction]
    local procedure TryEntryText(var Buffer: Record "LT ZB Zip File" temporary; Name: Text; var Content: Text)
    var
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        ZipEntry: DotNet LtZbZipEntry;
        Reader: DotNet LtZbfStreamReader;
        InS: InStream;
    begin
        Buffer.Content.CreateInStream(InS);
        ZipArchive := ZipArchive.ZipArchive(InS, Mode.Read);
        ZipEntry := ZipArchive.GetEntry(Name);
        if IsNull(ZipEntry) then begin
            Content := '<no entry>';
            exit;
        end;
        Reader := Reader.StreamReader(ZipEntry.Open());
        Content := Reader.ReadToEnd();
    end;

    local procedure ObserveEntryText(var Observer: Codeunit "Probe Observer"; var Buffer: Record "LT ZB Zip File" temporary; Name: Text; Phase: Text)
    var
        Content: Text;
    begin
        if TryEntryText(Buffer, Name, Content) then
            Observer.Observe(Name + ' content ' + Phase, Content)
        else
            Observer.Observe(Name + ' content error ' + Phase, GetLastErrorText());
        ClearLastError();
    end;

    [Test]
    procedure ZB_Fresh_Update4_EntryThenALWrite_Dispose()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        Enc: DotNet LtZbEncoding;
        BufferOut: OutStream;
        Before: List of [Integer];
        After: List of [Integer];
        AfterDispose: List of [Integer];
    begin
        SeedBuffer(Buffer);
        BufferBytes(Buffer, Before);
        Buffer.Content.CreateOutStream(BufferOut);
        ZipArchive := ZipArchive.ZipArchive(BufferOut, Mode.Update, false, Enc.UTF8());
        Observer.Observe('entries in archive', Format(ZipArchive.Entries.Count));
        Helper.AddEntry(ZipArchive, 'b.txt');
        BufferOut.WriteText('x');
        Observer.Observe('length after write', Format(Buffer.Content.Length));
        BufferBytes(Buffer, After);
        Observer.Observe('first change after write', FirstChange(Before, After));
        Observer.Observe('last bytes after write', Helper.LastBytes(Buffer));
        ObserveDispose(Observer, ZipArchive);
        ObserveBuffer(Observer, Buffer);
        BufferBytes(Buffer, AfterDispose);
        Observer.Observe('first change after Dispose', FirstChange(Before, AfterDispose));
        Observer.Expect('entries in archive', '1');
        Observer.Expect('length after write', '108');
        Observer.Expect('first change after write', '0:120,75,3');
        Observer.Expect('last bytes after write', '0,0,0');
        Observer.Expect('dispose error', 'none');
        Observer.Expect('has value', 'Yes');
        Observer.Expect('length', '194');
        Observer.Expect('last bytes', '0,0,0');
        Observer.Expect('entries', '2:a.txt;b.txt;');
        Observer.Expect('first change after Dispose', '0:120,75,3');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_Fresh_Update4_ALWriteThenEntry_Dispose()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        Enc: DotNet LtZbEncoding;
        BufferOut: OutStream;
        Before: List of [Integer];
        After: List of [Integer];
        AfterDispose: List of [Integer];
    begin
        SeedBuffer(Buffer);
        BufferBytes(Buffer, Before);
        Buffer.Content.CreateOutStream(BufferOut);
        ZipArchive := ZipArchive.ZipArchive(BufferOut, Mode.Update, false, Enc.UTF8());
        BufferOut.WriteText('x');
        Observer.Observe('length after write', Format(Buffer.Content.Length));
        BufferBytes(Buffer, After);
        Observer.Observe('first change after write', FirstChange(Before, After));
        Observer.Observe('last bytes after write', Helper.LastBytes(Buffer));
        Helper.AddEntry(ZipArchive, 'b.txt');
        ObserveDispose(Observer, ZipArchive);
        ObserveBuffer(Observer, Buffer);
        BufferBytes(Buffer, AfterDispose);
        Observer.Observe('first change after Dispose', FirstChange(Before, AfterDispose));
        Observer.Expect('length after write', '108');
        Observer.Expect('first change after write', '0:120,75,3');
        Observer.Expect('last bytes after write', '0,0,0');
        Observer.Expect('dispose error', 'none');
        Observer.Expect('has value', 'Yes');
        Observer.Expect('length', '194');
        Observer.Expect('last bytes', '0,0,0');
        Observer.Expect('entries', '2:a.txt;b.txt;');
        Observer.Expect('first change after Dispose', '0:120,75,3');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_Fresh_Update2_EntryThenALWrite_Dispose()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        BufferOut: OutStream;
        Before: List of [Integer];
        After: List of [Integer];
        AfterDispose: List of [Integer];
    begin
        SeedBuffer(Buffer);
        BufferBytes(Buffer, Before);
        Buffer.Content.CreateOutStream(BufferOut);
        ZipArchive := ZipArchive.ZipArchive(BufferOut, Mode.Update);
        Observer.Observe('entries in archive', Format(ZipArchive.Entries.Count));
        Helper.AddEntry(ZipArchive, 'b.txt');
        BufferOut.WriteText('x');
        Observer.Observe('length after write', Format(Buffer.Content.Length));
        BufferBytes(Buffer, After);
        Observer.Observe('first change after write', FirstChange(Before, After));
        ObserveDispose(Observer, ZipArchive);
        ObserveBuffer(Observer, Buffer);
        BufferBytes(Buffer, AfterDispose);
        Observer.Observe('first change after Dispose', FirstChange(Before, AfterDispose));
        Observer.Expect('entries in archive', '1');
        Observer.Expect('length after write', '108');
        Observer.Expect('first change after write', '0:120,75,3');
        Observer.Expect('dispose error', 'none');
        Observer.Expect('has value', 'Yes');
        Observer.Expect('length', '194');
        Observer.Expect('last bytes', '0,0,0');
        Observer.Expect('entries', '2:a.txt;b.txt;');
        Observer.Expect('first change after Dispose', '0:120,75,3');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_Fresh_Stored_Update4_EntryThenALWrite_Modify()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Stored: Record "LT ZB Stored Zip File";
        Seed: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        Enc: DotNet LtZbEncoding;
        SeedIn: InStream;
        StoredOut: OutStream;
        Names: Text;
        Before: List of [Integer];
        After: List of [Integer];
        AfterDispose: List of [Integer];
    begin
        Stored.DeleteAll();
        Helper.SeedIn(Seed, 'a.txt', SeedIn);
        Stored.Init();
        Stored."No." := 1;
        Stored.Content.CreateOutStream(StoredOut);
        CopyStream(StoredOut, SeedIn);
        Stored.Insert();
        Stored.Get(1);
        Stored.CalcFields(Content);
        StoredBytes(Stored, Before);
        Stored.Content.CreateOutStream(StoredOut);
        ZipArchive := ZipArchive.ZipArchive(StoredOut, Mode.Update, false, Enc.UTF8());
        Observer.Observe('entries in archive', Format(ZipArchive.Entries.Count));
        Helper.AddEntry(ZipArchive, 'b.txt');
        StoredOut.WriteText('x');
        Observer.Observe('length after write', Format(Stored.Content.Length));
        StoredBytes(Stored, After);
        Observer.Observe('first change after write', FirstChange(Before, After));
        ObserveDispose(Observer, ZipArchive);
        Observer.Observe('length after Dispose', Format(Stored.Content.Length));
        StoredBytes(Stored, AfterDispose);
        Observer.Observe('first change after Dispose', FirstChange(Before, AfterDispose));
        Stored.Modify();
        Stored.Get(1);
        Stored.CalcFields(Content);
        Observer.Observe('stored length', Format(Stored.Content.Length));
        StoredBytes(Stored, AfterDispose);
        Observer.Observe('stored first change', FirstChange(Before, AfterDispose));
        if TryStoredEntries(Stored, Names) then
            Observer.Observe('stored entries', Names)
        else
            Observer.Observe('stored entries error', GetLastErrorText());
        ClearLastError();
        Observer.Expect('entries in archive', '1');
        Observer.Expect('length after write', '108');
        Observer.Expect('first change after write', '0:120,75,3');
        Observer.Expect('dispose error', 'none');
        Observer.Expect('length after Dispose', '194');
        Observer.Expect('first change after Dispose', '0:120,75,3');
        Observer.Expect('stored length', '194');
        Observer.Expect('stored first change', '0:120,75,3');
        Observer.Expect('stored entries', '2:a.txt;b.txt;');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_Fresh_Update4_Clear_Dispose()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        Enc: DotNet LtZbEncoding;
        BufferOut: OutStream;
        Before: List of [Integer];
        AfterDispose: List of [Integer];
    begin
        SeedBuffer(Buffer);
        BufferBytes(Buffer, Before);
        Buffer.Content.CreateOutStream(BufferOut);
        ZipArchive := ZipArchive.ZipArchive(BufferOut, Mode.Update, false, Enc.UTF8());
        Helper.AddEntry(ZipArchive, 'b.txt');
        Clear(Buffer.Content);
        Observer.Observe('has value before Dispose', Format(Buffer.Content.HasValue()));
        Observer.Observe('length before Dispose', Format(Buffer.Content.Length));
        ObserveDispose(Observer, ZipArchive);
        ObserveBuffer(Observer, Buffer);
        BufferBytes(Buffer, AfterDispose);
        Observer.Observe('first change after Dispose', FirstChange(Before, AfterDispose));
        Observer.Expect('has value before Dispose', 'No');
        Observer.Expect('length before Dispose', '0');
        Observer.Expect('dispose error', 'none');
        Observer.Expect('has value', 'Yes');
        Observer.Expect('length', '194');
        Observer.Expect('last bytes', '0,0,0');
        Observer.Expect('entries', '2:a.txt;b.txt;');
        Observer.Expect('first change after Dispose', '37:3,4,20');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_Fresh_Update4_ClearAndRewrite_Dispose()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        Other: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        Enc: DotNet LtZbEncoding;
        OtherIn: InStream;
        BufferOut: OutStream;
        NewOut: OutStream;
        Before: List of [Integer];
        AfterDispose: List of [Integer];
    begin
        SeedBuffer(Buffer);
        BufferBytes(Buffer, Before);
        Buffer.Content.CreateOutStream(BufferOut);
        ZipArchive := ZipArchive.ZipArchive(BufferOut, Mode.Update, false, Enc.UTF8());
        Helper.AddEntry(ZipArchive, 'b.txt');
        Helper.SeedIn(Other, 'z.txt', OtherIn);
        Clear(Buffer.Content);
        Buffer.Content.CreateOutStream(NewOut);
        CopyStream(NewOut, OtherIn);
        Observer.Observe('length before Dispose', Format(Buffer.Content.Length));
        ObserveDispose(Observer, ZipArchive);
        ObserveBuffer(Observer, Buffer);
        BufferBytes(Buffer, AfterDispose);
        Observer.Observe('first change after Dispose', FirstChange(Before, AfterDispose));
        Observer.Expect('length before Dispose', '108');
        Observer.Expect('dispose error', 'none');
        Observer.Expect('has value', 'Yes');
        Observer.Expect('length', '194');
        Observer.Expect('last bytes', '0,0,0');
        Observer.Expect('entries', '2:a.txt;b.txt;');
        Observer.Expect('first change after Dispose', '30:122,46,116');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_Fresh_Update4_DotNetAppend_Dispose()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        Enc: DotNet LtZbEncoding;
        Writer: DotNet LtZbStreamWriter;
        BufferOut: OutStream;
        Before: List of [Integer];
        After: List of [Integer];
        AfterDispose: List of [Integer];
    begin
        SeedBuffer(Buffer);
        BufferBytes(Buffer, Before);
        Buffer.Content.CreateOutStream(BufferOut);
        ZipArchive := ZipArchive.ZipArchive(BufferOut, Mode.Update, false, Enc.UTF8());
        Helper.AddEntry(ZipArchive, 'b.txt');
        Writer := Writer.StreamWriter(BufferOut);
        Writer.Write('xyz');
        Writer.Flush();
        Observer.Observe('length after append', Format(Buffer.Content.Length));
        BufferBytes(Buffer, After);
        Observer.Observe('first change after append', FirstChange(Before, After));
        Observer.Observe('last bytes after append', Helper.LastBytes(Buffer));
        ObserveDispose(Observer, ZipArchive);
        ObserveBuffer(Observer, Buffer);
        BufferBytes(Buffer, AfterDispose);
        Observer.Observe('first change after Dispose', FirstChange(Before, AfterDispose));
        Observer.Expect('length after append', '108');
        Observer.Expect('first change after append', '0:120,121,122');
        Observer.Expect('last bytes after append', '0,0,0');
        Observer.Expect('dispose error', 'none');
        Observer.Expect('has value', 'Yes');
        Observer.Expect('length', '194');
        Observer.Expect('last bytes', '0,0,0');
        Observer.Expect('entries', '2:a.txt;b.txt;');
        Observer.Expect('first change after Dispose', '0:120,121,122');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_FreshHello_Update4_Entry_Dispose()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        Enc: DotNet LtZbEncoding;
        BufferOut: OutStream;
        Before: List of [Integer];
        AfterDispose: List of [Integer];
    begin
        SeedBufferHello(Buffer);
        Observer.Observe('seed length', Format(Buffer.Content.Length));
        ObserveEntryText(Observer, Buffer, 'a.txt', 'before Dispose');
        BufferBytes(Buffer, Before);
        Buffer.Content.CreateOutStream(BufferOut);
        ZipArchive := ZipArchive.ZipArchive(BufferOut, Mode.Update, false, Enc.UTF8());
        Observer.Observe('entries in archive', Format(ZipArchive.Entries.Count));
        Helper.AddEntry(ZipArchive, 'b.txt');
        ObserveDispose(Observer, ZipArchive);
        ObserveBuffer(Observer, Buffer);
        BufferBytes(Buffer, AfterDispose);
        Observer.Observe('first change after Dispose', FirstChange(Before, AfterDispose));
        ObserveEntryText(Observer, Buffer, 'a.txt', 'after Dispose');
        ObserveEntryText(Observer, Buffer, 'b.txt', 'after Dispose');
        Observer.Expect('seed length', '121');
        Observer.Expect('a.txt content before Dispose', 'hello');
        Observer.Expect('entries in archive', '1');
        Observer.Expect('dispose error', 'none');
        Observer.Expect('has value', 'Yes');
        Observer.Expect('length', '207');
        Observer.Expect('last bytes', '0,0,0');
        Observer.Expect('entries', '2:a.txt;b.txt;');
        Observer.Expect('first change after Dispose', '50:3,4,20');
        Observer.Expect('a.txt content after Dispose', 'hello');
        Observer.Expect('b.txt content after Dispose', '');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_FreshHello_Update4_EntryThenALWrite40_Dispose()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        Enc: DotNet LtZbEncoding;
        BufferOut: OutStream;
        Before: List of [Integer];
        After: List of [Integer];
        AfterDispose: List of [Integer];
    begin
        SeedBufferHello(Buffer);
        Observer.Observe('seed length', Format(Buffer.Content.Length));
        BufferBytes(Buffer, Before);
        Buffer.Content.CreateOutStream(BufferOut);
        ZipArchive := ZipArchive.ZipArchive(BufferOut, Mode.Update, false, Enc.UTF8());
        Observer.Observe('entries in archive', Format(ZipArchive.Entries.Count));
        Helper.AddEntry(ZipArchive, 'b.txt');
        BufferOut.WriteText(PadStr('', 40, 'x'));
        Observer.Observe('length after write', Format(Buffer.Content.Length));
        BufferBytes(Buffer, After);
        Observer.Observe('first change after write', FirstChange(Before, After));
        ObserveEntryText(Observer, Buffer, 'a.txt', 'before Dispose');
        ObserveDispose(Observer, ZipArchive);
        ObserveBuffer(Observer, Buffer);
        BufferBytes(Buffer, AfterDispose);
        Observer.Observe('first change after Dispose', FirstChange(Before, AfterDispose));
        ObserveEntryText(Observer, Buffer, 'a.txt', 'after Dispose');
        ObserveEntryText(Observer, Buffer, 'b.txt', 'after Dispose');
        Observer.Expect('seed length', '121');
        Observer.Expect('entries in archive', '1');
        Observer.Expect('length after write', '121');
        Observer.Expect('first change after write', '0:120,120,120');
        Observer.Expect('a.txt content error before Dispose', 'A call to System.IO.Compression.ZipArchiveEntry.Open failed with this message: A local file header is corrupt.');
        Observer.Expect('dispose error', 'none');
        Observer.Expect('has value', 'Yes');
        Observer.Expect('length', '207');
        Observer.Expect('last bytes', '0,0,0');
        Observer.Expect('entries', '2:a.txt;b.txt;');
        Observer.Expect('first change after Dispose', '0:120,120,120');
        Observer.Expect('a.txt content error after Dispose', 'A call to System.IO.Compression.ZipArchiveEntry.Open failed with this message: A local file header is corrupt.');
        Observer.Expect('b.txt content after Dispose', '');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_FreshHello_Update4_Clear_Dispose()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        ZipArchive: DotNet LtZbZipArchive;
        Mode: DotNet LtZbZipMode;
        Enc: DotNet LtZbEncoding;
        BufferOut: OutStream;
        Before: List of [Integer];
        AfterDispose: List of [Integer];
    begin
        SeedBufferHello(Buffer);
        BufferBytes(Buffer, Before);
        Buffer.Content.CreateOutStream(BufferOut);
        ZipArchive := ZipArchive.ZipArchive(BufferOut, Mode.Update, false, Enc.UTF8());
        Helper.AddEntry(ZipArchive, 'b.txt');
        Clear(Buffer.Content);
        Observer.Observe('length before Dispose', Format(Buffer.Content.Length));
        ObserveDispose(Observer, ZipArchive);
        ObserveBuffer(Observer, Buffer);
        BufferBytes(Buffer, AfterDispose);
        Observer.Observe('first change after Dispose', FirstChange(Before, AfterDispose));
        ObserveEntryText(Observer, Buffer, 'a.txt', 'after Dispose');
        Observer.Expect('length before Dispose', '0');
        Observer.Expect('dispose error', 'none');
        Observer.Expect('has value', 'Yes');
        Observer.Expect('length', '207');
        Observer.Expect('last bytes', '0,0,0');
        Observer.Expect('entries', '2:a.txt;b.txt;');
        Observer.Expect('first change after Dispose', '50:3,4,20');
        Observer.Expect('a.txt content after Dispose', 'hello');
        Observer.Verify();
    end;
}
