// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit-system-data-compression-data-compression
// Scope: in-scope (System Application "Data Compression": a zip kept in a Blob field, opened for update from the field's InStream and saved back into the same field)
// Fixtures used: Probe Observer (69160); own tables 75291, 75292 and codeunit 75293
// Probe: written against a local BC 27.5 service tier; every literal asserted below is what BC produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Data Compression OpenZipArchive(InStream of a Blob field, true) + AddEntry + Clear of the field + CreateOutStream of the same field + SaveZipArchive, repeated:
//   the field holds the zip with every entry added so far (1, 2 and 3 rounds, temporary table and stored table with Modify and CalcFields between rounds, also without Modify
//   between rounds); lengths 119 and 216 bytes after one and two rounds. Without Clear the result is the same. An update round without a change keeps the zip; RemoveEntry
//   removes; the same name added twice gives two entries (ExtractEntry by name reads the first). OpenZipArchive(Temp Blob, true) + SaveZipArchive(var Temp Blob) into the same
//   Temp Blob keeps both entries. AddEntry on an archive opened for read raises "A call to System.IO.Compression.ZipArchive.CreateEntry failed with this message: Cannot create
//   entries on an archive opened in read mode." (DotNetInvoke:NotSupported)
// BC versions: 27.5 measured on a local Windows BC 27.5 container (28.5 and 29.0 by the corpus CI matrix on BC on Linux)

table 75291 "GZZ Zip Holder Tmp"
{
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; "File Blob"; Blob) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }

    // Adds Content as entry Name to the zip held in "File Blob" (empty at first), in place: OpenZipArchive(InStream of the field, true),
    // AddEntry, Clear of the field when ClearFirst is true, CreateOutStream of the same field, SaveZipArchive.
    procedure AddToZip(Name: Text; Content: Text; ClearFirst: Boolean)
    var
        DataCompression: Codeunit "Data Compression";
        Src: Codeunit "Temp Blob";
        ReadStream: InStream;
        EntryIn: InStream;
        EntryOut: OutStream;
        WriteStream: OutStream;
    begin
        "File Blob".CreateInStream(ReadStream);
        DataCompression.OpenZipArchive(ReadStream, true);
        if Name <> '' then begin
            Src.CreateOutStream(EntryOut);
            EntryOut.WriteText(Content);
            Src.CreateInStream(EntryIn);
            DataCompression.AddEntry(EntryIn, Name);
        end;
        if ClearFirst then
            Clear("File Blob");
        "File Blob".CreateOutStream(WriteStream);
        DataCompression.SaveZipArchive(WriteStream);
    end;

    // Removes entry Name from the zip held in "File Blob", in place.
    procedure RemoveFromZip(Name: Text)
    var
        DataCompression: Codeunit "Data Compression";
        ReadStream: InStream;
        WriteStream: OutStream;
    begin
        "File Blob".CreateInStream(ReadStream);
        DataCompression.OpenZipArchive(ReadStream, true);
        DataCompression.RemoveEntry(Name);
        Clear("File Blob");
        "File Blob".CreateOutStream(WriteStream);
        DataCompression.SaveZipArchive(WriteStream);
    end;

    // The entry names of the zip held in "File Blob", comma-separated, each with the text of the entry in brackets.
    procedure Entries(): Text
    var
        DataCompression: Codeunit "Data Compression";
        Entry: Codeunit "Temp Blob";
        ReadStream: InStream;
        EntryIn: InStream;
        Names: List of [Text];
        Name: Text;
        Content: Text;
        Result: Text;
    begin
        "File Blob".CreateInStream(ReadStream);
        DataCompression.OpenZipArchive(ReadStream, false);
        DataCompression.GetEntryList(Names);
        foreach Name in Names do begin
            Clear(Entry);
            DataCompression.ExtractEntry(Name, Entry);
            Entry.CreateInStream(EntryIn);
            Content := '';
            EntryIn.ReadText(Content);
            Result += Name + '[' + Content + '],';
        end;
        DataCompression.CloseZipArchive();
        exit(Result);
    end;
}

table 75292 "GZZ Zip Holder"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; "File Blob"; Blob) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }

    // Adds Content as entry Name to the zip held in "File Blob" (empty at first), in place: OpenZipArchive(InStream of the field, true),
    // AddEntry, Clear of the field when ClearFirst is true, CreateOutStream of the same field, SaveZipArchive.
    procedure AddToZip(Name: Text; Content: Text; ClearFirst: Boolean)
    var
        DataCompression: Codeunit "Data Compression";
        Src: Codeunit "Temp Blob";
        ReadStream: InStream;
        EntryIn: InStream;
        EntryOut: OutStream;
        WriteStream: OutStream;
    begin
        "File Blob".CreateInStream(ReadStream);
        DataCompression.OpenZipArchive(ReadStream, true);
        if Name <> '' then begin
            Src.CreateOutStream(EntryOut);
            EntryOut.WriteText(Content);
            Src.CreateInStream(EntryIn);
            DataCompression.AddEntry(EntryIn, Name);
        end;
        if ClearFirst then
            Clear("File Blob");
        "File Blob".CreateOutStream(WriteStream);
        DataCompression.SaveZipArchive(WriteStream);
    end;

    // Removes entry Name from the zip held in "File Blob", in place.
    procedure RemoveFromZip(Name: Text)
    var
        DataCompression: Codeunit "Data Compression";
        ReadStream: InStream;
        WriteStream: OutStream;
    begin
        "File Blob".CreateInStream(ReadStream);
        DataCompression.OpenZipArchive(ReadStream, true);
        DataCompression.RemoveEntry(Name);
        Clear("File Blob");
        "File Blob".CreateOutStream(WriteStream);
        DataCompression.SaveZipArchive(WriteStream);
    end;

    // The entry names of the zip held in "File Blob", comma-separated, each with the text of the entry in brackets.
    procedure Entries(): Text
    var
        DataCompression: Codeunit "Data Compression";
        Entry: Codeunit "Temp Blob";
        ReadStream: InStream;
        EntryIn: InStream;
        Names: List of [Text];
        Name: Text;
        Content: Text;
        Result: Text;
    begin
        "File Blob".CreateInStream(ReadStream);
        DataCompression.OpenZipArchive(ReadStream, false);
        DataCompression.GetEntryList(Names);
        foreach Name in Names do begin
            Clear(Entry);
            DataCompression.ExtractEntry(Name, Entry);
            Entry.CreateInStream(EntryIn);
            Content := '';
            EntryIn.ReadText(Content);
            Result += Name + '[' + Content + '],';
        end;
        DataCompression.CloseZipArchive();
        exit(Result);
    end;
}

codeunit 75293 "GZZ Zip Blob Update"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ZipInBlob_TempTable_OneRound()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Record "GZZ Zip Holder Tmp";
    begin
        Holder.AddToZip('a.txt', 'Content A', true);
        Observer.Observe('entries', Holder.Entries());
        Observer.Observe('length', Format(Holder."File Blob".Length));
        Observer.Expect('entries', 'a.txt[Content A],');
        Observer.Expect('length', '119');
        Observer.Verify();
    end;

    [Test]
    procedure ZipInBlob_TempTable_TwoRounds()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Record "GZZ Zip Holder Tmp";
        Len1: Integer;
    begin
        Holder.AddToZip('a.txt', 'Content A', true);
        Len1 := Holder."File Blob".Length;
        Holder.AddToZip('b.txt', 'Content B', true);
        Observer.Observe('entries', Holder.Entries());
        Observer.Observe('length_round1', Format(Len1));
        Observer.Observe('length_round2', Format(Holder."File Blob".Length));
        Observer.Expect('entries', 'a.txt[Content A],b.txt[Content B],');
        Observer.Expect('length_round1', '119');
        Observer.Expect('length_round2', '216');
        Observer.Verify();
    end;

    [Test]
    procedure ZipInBlob_TempTable_ThreeRounds()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Record "GZZ Zip Holder Tmp";
    begin
        Holder.AddToZip('a.txt', 'Content A', true);
        Holder.AddToZip('b.txt', 'Content B', true);
        Holder.AddToZip('dir/c.txt', 'Content C', true);
        Observer.Observe('entries', Holder.Entries());
        Observer.Observe('length', Format(Holder."File Blob".Length));
        Observer.Expect('entries', 'a.txt[Content A],b.txt[Content B],dir/c.txt[Content C],');
        Observer.Expect('length', '321');
        Observer.Verify();
    end;

    [Test]
    procedure ZipInBlob_TempTable_TwoRounds_NoClear()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Record "GZZ Zip Holder Tmp";
        Len1: Integer;
    begin
        Holder.AddToZip('a.txt', 'Content A', false);
        Len1 := Holder."File Blob".Length;
        Holder.AddToZip('b.txt', 'Content B', false);
        Observer.Observe('entries', Holder.Entries());
        Observer.Observe('length_round1', Format(Len1));
        Observer.Observe('length_round2', Format(Holder."File Blob".Length));
        Observer.Expect('entries', 'a.txt[Content A],b.txt[Content B],');
        Observer.Expect('length_round1', '119');
        Observer.Expect('length_round2', '216');
        Observer.Verify();
    end;

    [Test]
    procedure ZipInBlob_TempTable_UpdateWithoutChange()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Record "GZZ Zip Holder Tmp";
        Len1: Integer;
    begin
        Holder.AddToZip('a.txt', 'Content A', true);
        Len1 := Holder."File Blob".Length;
        Holder.AddToZip('', '', true);
        Observer.Observe('entries', Holder.Entries());
        Observer.Observe('length_round1', Format(Len1));
        Observer.Observe('length_round2', Format(Holder."File Blob".Length));
        Observer.Expect('entries', 'a.txt[Content A],');
        Observer.Expect('length_round1', '119');
        Observer.Expect('length_round2', '119');
        Observer.Verify();
    end;

    [Test]
    procedure ZipInBlob_TempTable_SameNameTwice()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Record "GZZ Zip Holder Tmp";
    begin
        Holder.AddToZip('a.txt', 'Content A', true);
        Holder.AddToZip('a.txt', 'Second A', true);
        Observer.Observe('entries', Holder.Entries());
        Observer.Expect('entries', 'a.txt[Content A],a.txt[Content A],');
        Observer.Verify();
    end;

    [Test]
    procedure ZipInBlob_TempTable_RemoveEntry()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Record "GZZ Zip Holder Tmp";
    begin
        Holder.AddToZip('a.txt', 'Content A', true);
        Holder.AddToZip('b.txt', 'Content B', true);
        Holder.RemoveFromZip('a.txt');
        Observer.Observe('entries', Holder.Entries());
        Observer.Expect('entries', 'b.txt[Content B],');
        Observer.Verify();
    end;

    [Test]
    procedure ZipInBlob_Table_TwoRounds_Persisted()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Record "GZZ Zip Holder";
        Len1: Integer;
    begin
        Holder.DeleteAll();
        Holder.Code := 'Z';
        Holder.Insert();
        Holder.AddToZip('a.txt', 'Content A', true);
        Holder.Modify();
        Clear(Holder);
        Holder.Get('Z');
        Holder.CalcFields("File Blob");
        Len1 := Holder."File Blob".Length;
        Observer.Observe('entries_round1', Holder.Entries());
        Holder.AddToZip('b.txt', 'Content B', true);
        Holder.Modify();
        Clear(Holder);
        Holder.Get('Z');
        Holder.CalcFields("File Blob");
        Observer.Observe('entries_round2', Holder.Entries());
        Observer.Observe('length_round1', Format(Len1));
        Observer.Observe('length_round2', Format(Holder."File Blob".Length));
        Observer.Expect('entries_round1', 'a.txt[Content A],');
        Observer.Expect('entries_round2', 'a.txt[Content A],b.txt[Content B],');
        Observer.Expect('length_round1', '119');
        Observer.Expect('length_round2', '216');
        Observer.Verify();
    end;

    [Test]
    procedure ZipInBlob_Table_TwoRounds_NoModifyBetween()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Record "GZZ Zip Holder";
    begin
        Holder.DeleteAll();
        Holder.Code := 'Z';
        Holder.Insert();
        Holder.AddToZip('a.txt', 'Content A', true);
        Holder.AddToZip('b.txt', 'Content B', true);
        Observer.Observe('entries_in_memory', Holder.Entries());
        Holder.Modify();
        Clear(Holder);
        Holder.Get('Z');
        Holder.CalcFields("File Blob");
        Observer.Observe('entries_stored', Holder.Entries());
        Observer.Expect('entries_in_memory', 'a.txt[Content A],b.txt[Content B],');
        Observer.Expect('entries_stored', 'a.txt[Content A],b.txt[Content B],');
        Observer.Verify();
    end;

    [Test]
    procedure ZipInTempBlob_SameTempBlob_TwoRounds()
    var
        Observer: Codeunit "Probe Observer";
        Zip: Codeunit "Temp Blob";
        R: Integer;
        Len1: Integer;
    begin
        for R := 1 to 2 do begin
            AddToTempBlobZip(Zip, 'e' + Format(R) + '.txt', 'Content ' + Format(R));
            if R = 1 then
                Len1 := Zip.Length();
        end;
        Observer.Observe('entries', TempBlobEntries(Zip));
        Observer.Observe('length_round1', Format(Len1));
        Observer.Observe('length_round2', Format(Zip.Length()));
        Observer.Expect('entries', 'e1.txt,e2.txt,');
        Observer.Expect('length_round1', '121');
        Observer.Expect('length_round2', '220');
        Observer.Verify();
    end;

    // OpenZipArchive(Temp Blob, true), AddEntry, SaveZipArchive(var Temp Blob) into the same Temp Blob.
    local procedure AddToTempBlobZip(var Zip: Codeunit "Temp Blob"; Name: Text; Content: Text)
    var
        DataCompression: Codeunit "Data Compression";
        Src: Codeunit "Temp Blob";
        EntryIn: InStream;
        EntryOut: OutStream;
    begin
        DataCompression.OpenZipArchive(Zip, true);
        Src.CreateOutStream(EntryOut);
        EntryOut.WriteText(Content);
        Src.CreateInStream(EntryIn);
        DataCompression.AddEntry(EntryIn, Name);
        DataCompression.SaveZipArchive(Zip);
    end;

    local procedure TempBlobEntries(Zip: Codeunit "Temp Blob"): Text
    var
        DataCompression: Codeunit "Data Compression";
        Names: List of [Text];
        Name: Text;
        Result: Text;
    begin
        DataCompression.OpenZipArchive(Zip, false);
        DataCompression.GetEntryList(Names);
        foreach Name in Names do
            Result += Name + ',';
        DataCompression.CloseZipArchive();
        exit(Result);
    end;

    [Test]
    procedure ZipInBlob_OpenedForRead_AddEntry_Error()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Record "GZZ Zip Holder Tmp";
        DataCompression: Codeunit "Data Compression";
        Src: Codeunit "Temp Blob";
        ReadStream: InStream;
        EntryIn: InStream;
        EntryOut: OutStream;
    begin
        Holder.AddToZip('a.txt', 'Content A', true);
        Holder."File Blob".CreateInStream(ReadStream);
        DataCompression.OpenZipArchive(ReadStream, false);
        Src.CreateOutStream(EntryOut);
        EntryOut.WriteText('Content B');
        Src.CreateInStream(EntryIn);
        asserterror DataCompression.AddEntry(EntryIn, 'b.txt');
        Observer.ObserveError('add_in_read_mode');
        Observer.Observe('entries_after', Holder.Entries());
        Observer.Expect('add_in_read_mode|text', 'A call to System.IO.Compression.ZipArchive.CreateEntry failed with this message: Cannot create entries on an archive opened in read mode.');
        Observer.Expect('add_in_read_mode|code', 'DotNetInvoke:NotSupported');
        Observer.Expect('entries_after', 'a.txt[Content A],');
        Observer.Verify();
    end;
}
