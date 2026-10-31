// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.io.compression.ziparchive
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained objects 99495-99497
// Probe: gap cycle 4, spec G4-19. System.IO.Compression.ZipArchive in Create mode: several CreateEntry calls in a row, each entry written
//        with CopyStream(Entry.Open(), InStream) and the entry stream never closed in AL; the entry stream kept in a variable; Entries in
//        Create mode and after Dispose; CreateEntry, Entries and Dispose on a variable that holds no object; CreateEntry after Dispose.
//        The holder codeunit has its own ZipArchive variable, so an error names the holder's routine.
//        Already pinned nearby: lt-wd-dotnet/WdZipArchiveOverOutStream.al (one entry through CopyStream(ZipEntry.Open(), EntryIn)).
// BC versions: 27, 28, 29
dotnet
{
    assembly("netstandard")
    {
        type("System.IO.Compression.ZipArchive"; LtY44ZipArchive) { }
        type("System.IO.Compression.ZipArchiveMode"; LtY44ZipMode) { }
        type("System.IO.Compression.ZipArchiveEntry"; LtY44ZipEntry) { }
        type("System.IO.Stream"; LtY44Stream) { }
    }
}

table 99497 "LT Y44 Zip Blob"
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

codeunit 99496 "LT Y44 Zip Holder"
{
    var
        ZipArchive: DotNet LtY44ZipArchive;
        KeptStream: DotNet LtY44Stream;

    procedure Create(var OutS: OutStream)
    var
        Mode: DotNet LtY44ZipMode;
    begin
        ZipArchive := ZipArchive.ZipArchive(OutS, Mode.Create);
    end;

    procedure Add(InS: InStream; Path: Text)
    var
        ZipArchiveEntry: DotNet LtY44ZipEntry;
    begin
        ZipArchiveEntry := ZipArchive.CreateEntry(Path);
        CopyStream(ZipArchiveEntry.Open(), InS);
    end;

    procedure AddKeepOpen(InS: InStream; Path: Text)
    var
        ZipArchiveEntry: DotNet LtY44ZipEntry;
    begin
        ZipArchiveEntry := ZipArchive.CreateEntry(Path);
        KeptStream := ZipArchiveEntry.Open();
        CopyStream(KeptStream, InS);
    end;

    procedure AddWriteByte(Path: Text)
    var
        ZipArchiveEntry: DotNet LtY44ZipEntry;
    begin
        ZipArchiveEntry := ZipArchive.CreateEntry(Path);
        ZipArchiveEntry.Open().WriteByte(65);
    end;

    procedure CreateOnly(Path: Text)
    begin
        ZipArchive.CreateEntry(Path);
    end;

    procedure EntriesCount(): Integer
    begin
        exit(ZipArchive.Entries.Count);
    end;

    procedure List(var L: List of [Text])
    var
        ZipArchiveEntry: DotNet LtY44ZipEntry;
    begin
        foreach ZipArchiveEntry in ZipArchive.Entries() do
            L.Add(ZipArchiveEntry.FullName);
    end;

    procedure Close()
    begin
        ZipArchive.Dispose();
    end;
}

codeunit 99495 "LT Y44 Zip Create Mode"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure TextIn(var Buf: Record "LT Y44 Zip Blob" temporary; No: Integer; Content: Text; var InS: InStream)
    var
        OutS: OutStream;
    begin
        Buf.Init();
        Buf."No." := No;
        Buf.Content.CreateOutStream(OutS);
        if Content <> '' then
            OutS.WriteText(Content);
        Buf.Insert();
        Buf.CalcFields(Content);
        Buf.Content.CreateInStream(InS);
    end;

    [TryFunction]
    local procedure TryAdd(var Holder: Codeunit "LT Y44 Zip Holder"; InS: InStream; Path: Text)
    begin
        Holder.Add(InS, Path);
    end;

    [TryFunction]
    local procedure TryAddKeepOpen(var Holder: Codeunit "LT Y44 Zip Holder"; InS: InStream; Path: Text)
    begin
        Holder.AddKeepOpen(InS, Path);
    end;

    [TryFunction]
    local procedure TryAddWriteByte(var Holder: Codeunit "LT Y44 Zip Holder"; Path: Text)
    begin
        Holder.AddWriteByte(Path);
    end;

    [TryFunction]
    local procedure TryCreateOnly(var Holder: Codeunit "LT Y44 Zip Holder"; Path: Text)
    begin
        Holder.CreateOnly(Path);
    end;

    [TryFunction]
    local procedure TryCount(var Holder: Codeunit "LT Y44 Zip Holder"; var N: Integer)
    begin
        N := Holder.EntriesCount();
    end;

    [TryFunction]
    local procedure TryList(var Holder: Codeunit "LT Y44 Zip Holder"; var L: List of [Text])
    begin
        Holder.List(L);
    end;

    [TryFunction]
    local procedure TryClose(var Holder: Codeunit "LT Y44 Zip Holder")
    begin
        Holder.Close();
    end;

    local procedure Outcome(Name: Text; Ok: Boolean)
    begin
        if Ok then
            Observer.Observe(Name, 'ok')
        else begin
            Observer.Observe('stack_' + Name, GetLastErrorCallStack());
            Observer.ObserveError(Name);
        end;
    end;

    local procedure ReadZip(var ZipFile: Record "LT Y44 Zip Blob" temporary)
    var
        Buf: Record "LT Y44 Zip Blob" temporary;
        ZipArchive: DotNet LtY44ZipArchive;
        Mode: DotNet LtY44ZipMode;
        ZipArchiveEntry: DotNet LtY44ZipEntry;
        ZipIn: InStream;
        EntryIn: InStream;
        BufOut: OutStream;
        T: Text;
        I: Integer;
    begin
        ZipFile.Content.CreateInStream(ZipIn);
        ZipArchive := ZipArchive.ZipArchive(ZipIn, Mode.Read);
        Observer.Observe('count', Format(ZipArchive.Entries.Count));
        foreach ZipArchiveEntry in ZipArchive.Entries() do begin
            I += 1;
            Observer.Observe('name_' + Format(I), ZipArchiveEntry.FullName);
            Buf.Init();
            Buf."No." := I;
            Buf.Content.CreateOutStream(BufOut);
            CopyStream(BufOut, ZipArchiveEntry.Open());
            Buf.Insert();
            Buf.CalcFields(Content);
            Buf.Content.CreateInStream(EntryIn);
            T := '';
            EntryIn.ReadText(T);
            Observer.Observe('content_' + Format(I), T);
        end;
        ZipArchive.Dispose();
    end;

    [Test]
    procedure Zip_TwoEntries_CopyStreamIntoOpen()
    var
        ZipFile: Record "LT Y44 Zip Blob" temporary;
        Buf: Record "LT Y44 Zip Blob" temporary;
        Holder: Codeunit "LT Y44 Zip Holder";
        ZipOut: OutStream;
        InS: InStream;
    begin
        ZipFile."No." := 1;
        ZipFile.Content.CreateOutStream(ZipOut);
        Holder.Create(ZipOut);
        TextIn(Buf, 1, 'hello', InS);
        ClearLastError();
        Outcome('add_a', TryAdd(Holder, InS, 'a.txt'));
        TextIn(Buf, 2, 'world', InS);
        Outcome('add_b', TryAdd(Holder, InS, 'b/c.txt'));
        TextIn(Buf, 3, '', InS);
        Outcome('add_d', TryAdd(Holder, InS, 'd.txt'));
        Outcome('close', TryClose(Holder));
        ZipFile.Insert();
        ZipFile.CalcFields(Content);
        Observer.Observe('ziplen>0', Format(ZipFile.Content.Length() > 0));
        ReadZip(ZipFile);
        Observer.Finish();
    end;

    [Test]
    procedure Zip_OpenKeptInVariable_SecondCreate()
    var
        ZipFile: Record "LT Y44 Zip Blob" temporary;
        Buf: Record "LT Y44 Zip Blob" temporary;
        Holder: Codeunit "LT Y44 Zip Holder";
        ZipOut: OutStream;
        InS: InStream;
    begin
        ZipFile.Content.CreateOutStream(ZipOut);
        Holder.Create(ZipOut);
        TextIn(Buf, 1, 'hello', InS);
        ClearLastError();
        Outcome('keep_first', TryAddKeepOpen(Holder, InS, 'a.txt'));
        Outcome('second_create', TryCreateOnly(Holder, 'b.txt'));
        Observer.Finish();
    end;

    [Test]
    procedure Zip_OpenTemporaryNoCopy_SecondCreate()
    var
        ZipFile: Record "LT Y44 Zip Blob" temporary;
        Holder: Codeunit "LT Y44 Zip Holder";
        ZipOut: OutStream;
    begin
        ZipFile.Content.CreateOutStream(ZipOut);
        Holder.Create(ZipOut);
        ClearLastError();
        Outcome('writebyte_first', TryAddWriteByte(Holder, 'a.txt'));
        Outcome('second_create', TryCreateOnly(Holder, 'b.txt'));
        Observer.Finish();
    end;

    [Test]
    procedure Zip_EntriesInCreateMode()
    var
        ZipFile: Record "LT Y44 Zip Blob" temporary;
        Buf: Record "LT Y44 Zip Blob" temporary;
        Holder: Codeunit "LT Y44 Zip Holder";
        L: List of [Text];
        ZipOut: OutStream;
        InS: InStream;
        N: Integer;
    begin
        ZipFile.Content.CreateOutStream(ZipOut);
        Holder.Create(ZipOut);
        TextIn(Buf, 1, 'hello', InS);
        Holder.Add(InS, 'a.txt');
        ClearLastError();
        Outcome('count_create', TryCount(Holder, N));
        Outcome('list_create', TryList(Holder, L));
        Holder.Close();
        Outcome('count_disposed', TryCount(Holder, N));
        Outcome('list_disposed', TryList(Holder, L));
        ClearLastError();
        asserterror Holder.List(L);
        Observer.Observe('stack_asserterror', GetLastErrorCallStack());
        Observer.ObserveError('asserterror_list_disposed');
        Observer.Finish();
    end;

    [Test]
    procedure Zip_CreateEntry_NoObject()
    var
        Buf: Record "LT Y44 Zip Blob" temporary;
        Holder: Codeunit "LT Y44 Zip Holder";
        InS: InStream;
        N: Integer;
    begin
        TextIn(Buf, 1, 'hello', InS);
        ClearLastError();
        Outcome('add_noobject', TryAdd(Holder, InS, 'x.txt'));
        Outcome('count_noobject', TryCount(Holder, N));
        Outcome('dispose_noobject', TryClose(Holder));
        ClearLastError();
        asserterror Holder.Add(InS, 'x.txt');
        Observer.ObserveError('asserterror_add_noobject');
        Observer.Finish();
    end;

    [Test]
    procedure Zip_CreateEntry_AfterDispose()
    var
        ZipFile: Record "LT Y44 Zip Blob" temporary;
        Buf: Record "LT Y44 Zip Blob" temporary;
        Holder: Codeunit "LT Y44 Zip Holder";
        ZipOut: OutStream;
        InS: InStream;
    begin
        ZipFile.Content.CreateOutStream(ZipOut);
        Holder.Create(ZipOut);
        TextIn(Buf, 1, 'hello', InS);
        Holder.Add(InS, 'a.txt');
        Holder.Close();
        TextIn(Buf, 2, 'world', InS);
        ClearLastError();
        Outcome('add_after_dispose', TryAdd(Holder, InS, 'b.txt'));
        Observer.Finish();
    end;
}
