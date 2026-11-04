// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.io.compression.ziparchive
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained objects 99495-99497
// Probe: gap cycle 4, spec G4-19. System.IO.Compression.ZipArchive in Create mode: several CreateEntry calls in a row, each entry written
//        with CopyStream(Entry.Open(), InStream) and the entry stream never closed in AL; the entry stream kept in a variable; Entries in
//        Create mode and after Dispose; CreateEntry, Entries and Dispose on a variable that holds no object; CreateEntry after Dispose.
//        The holder codeunit has its own ZipArchive variable, so an error names the holder's routine.
//        Already pinned nearby: lt-wd-dotnet/WdZipArchiveOverOutStream.al (one entry through CopyStream(ZipEntry.Open(), EntryIn)).
//        Every value asserted is what BC 27.5, 28.5, 29.0 (Linux CI containers) produced, all the same. The temporary stream that Entry.Open()
//        returns is closed at the end of the statement (a second CreateEntry works); a stream kept in a variable stays open (CopyStream does not
//        close it). Only the innermost call stack frame is observed: on 27.5 GetLastErrorCallStack also lists the test runner frames.
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

    // the innermost frame of the error's call stack (the routine that raised)
    local procedure TopFrame(): Text
    var
        Stack: Text;
    begin
        Stack := GetLastErrorCallStack();
        if Stack.IndexOf('\') > 0 then
            exit(Stack.Substring(1, Stack.IndexOf('\') - 1));
        exit(Stack);
    end;

    local procedure Outcome(Name: Text; Ok: Boolean)
    begin
        if Ok then
            Observer.Observe(Name, 'ok')
        else begin
            Observer.Observe('stack_' + Name, TopFrame());
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
        Observer.Expect('add_a', 'ok');
        Observer.Expect('add_b', 'ok');
        Observer.Expect('add_d', 'ok');
        Observer.Expect('close', 'ok');
        Observer.Expect('ziplen>0', 'Yes');
        Observer.Expect('count', '3');
        Observer.Expect('name_1', 'a.txt');
        Observer.Expect('content_1', 'hello');
        Observer.Expect('name_2', 'b/c.txt');
        Observer.Expect('content_2', 'world');
        Observer.Expect('name_3', 'd.txt');
        Observer.Expect('content_3', '');
        Observer.Verify();
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
        Observer.Expect('keep_first', 'ok');
        Observer.Expect('stack_second_create', '"LT Y44 Zip Holder"(CodeUnit 99496).CreateOnly line 2 - AL Language Coverage Tests (OnPrem DotNet) by AL Language version 1.0.0.0');
        Observer.Expect('second_create|text', 'A call to System.IO.Compression.ZipArchive.CreateEntry failed with this message: Entries cannot be created while previously created entries are still open.');
        Observer.Expect('second_create|code', 'DotNetInvoke:IO');
        Observer.Verify();
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
        Observer.Expect('writebyte_first', 'ok');
        Observer.Expect('second_create', 'ok');
        Observer.Verify();
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
        Observer.Observe('stack_asserterror', TopFrame());
        Observer.ObserveError('asserterror_list_disposed');
        Observer.Expect('stack_count_create', '"LT Y44 Zip Holder"(CodeUnit 99496).EntriesCount line 2 - AL Language Coverage Tests (OnPrem DotNet) by AL Language version 1.0.0.0');
        Observer.Expect('count_create|text', 'A call to System.IO.Compression.ZipArchive.Entries failed with this message: Cannot access entries in Create mode.');
        Observer.Expect('count_create|code', 'DotNetInvoke:NotSupported');
        Observer.Expect('stack_list_create', '"LT Y44 Zip Holder"(CodeUnit 99496).List line 5 - AL Language Coverage Tests (OnPrem DotNet) by AL Language version 1.0.0.0');
        Observer.Expect('list_create|text', 'A call to System.IO.Compression.ZipArchive.Entries failed with this message: Cannot access entries in Create mode.');
        Observer.Expect('list_create|code', 'DotNetInvoke:NotSupported');
        Observer.Expect('stack_count_disposed', '"LT Y44 Zip Holder"(CodeUnit 99496).EntriesCount line 2 - AL Language Coverage Tests (OnPrem DotNet) by AL Language version 1.0.0.0');
        Observer.Expect('count_disposed|text', 'A call to System.IO.Compression.ZipArchive.Entries failed with this message: Cannot access entries in Create mode.');
        Observer.Expect('count_disposed|code', 'DotNetInvoke:NotSupported');
        Observer.Expect('stack_list_disposed', '"LT Y44 Zip Holder"(CodeUnit 99496).List line 5 - AL Language Coverage Tests (OnPrem DotNet) by AL Language version 1.0.0.0');
        Observer.Expect('list_disposed|text', 'A call to System.IO.Compression.ZipArchive.Entries failed with this message: Cannot access entries in Create mode.');
        Observer.Expect('list_disposed|code', 'DotNetInvoke:NotSupported');
        Observer.Expect('stack_asserterror', '"LT Y44 Zip Holder"(CodeUnit 99496).List line 5 - AL Language Coverage Tests (OnPrem DotNet) by AL Language version 1.0.0.0');
        Observer.Expect('asserterror_list_disposed|text', 'A call to System.IO.Compression.ZipArchive.Entries failed with this message: Cannot access entries in Create mode.');
        Observer.Expect('asserterror_list_disposed|code', 'DotNetInvoke:NotSupported');
        Observer.Verify();
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
        Observer.Expect('stack_add_noobject', '"LT Y44 Zip Holder"(CodeUnit 99496).Add line 4 - AL Language Coverage Tests (OnPrem DotNet) by AL Language version 1.0.0.0');
        Observer.Expect('add_noobject|text', 'A DotNet variable has not been instantiated. Attempting to call System.IO.Compression.ZipArchive.CreateEntry in CodeUnit LT Y44 Zip Holder: Add');
        Observer.Expect('add_noobject|code', 'DotNetVariableNotCreated');
        Observer.Expect('stack_count_noobject', '"LT Y44 Zip Holder"(CodeUnit 99496).EntriesCount line 2 - AL Language Coverage Tests (OnPrem DotNet) by AL Language version 1.0.0.0');
        Observer.Expect('count_noobject|text', 'A DotNet variable has not been instantiated. Attempting to call System.IO.Compression.ZipArchive.Entries in CodeUnit LT Y44 Zip Holder: EntriesCount');
        Observer.Expect('count_noobject|code', 'DotNetVariableNotCreated');
        Observer.Expect('stack_dispose_noobject', '"LT Y44 Zip Holder"(CodeUnit 99496).Close line 2 - AL Language Coverage Tests (OnPrem DotNet) by AL Language version 1.0.0.0');
        Observer.Expect('dispose_noobject|text', 'A DotNet variable has not been instantiated. Attempting to call System.IO.Compression.ZipArchive.Dispose in CodeUnit LT Y44 Zip Holder: Close');
        Observer.Expect('dispose_noobject|code', 'DotNetVariableNotCreated');
        Observer.Expect('asserterror_add_noobject|text', 'A DotNet variable has not been instantiated. Attempting to call System.IO.Compression.ZipArchive.CreateEntry in CodeUnit LT Y44 Zip Holder: Add');
        Observer.Expect('asserterror_add_noobject|code', 'DotNetVariableNotCreated');
        Observer.Verify();
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
        Observer.Expect('stack_add_after_dispose', '"LT Y44 Zip Holder"(CodeUnit 99496).Add line 4 - AL Language Coverage Tests (OnPrem DotNet) by AL Language version 1.0.0.0');
        Observer.Expect('add_after_dispose|text', 'A call to System.IO.Compression.ZipArchive.CreateEntry failed with this message: Cannot access a disposed object.\nObject name: ''System.IO.Compression.ZipArchive''.');
        Observer.Expect('add_after_dispose|code', 'DotNetInvoke:ObjectDisposed');
        Observer.Verify();
    end;
}
