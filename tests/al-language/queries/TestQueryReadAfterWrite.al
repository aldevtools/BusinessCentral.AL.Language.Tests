// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/queryinstance-read-method
// Scope: in-scope
// Fixtures used: QRW Entry (68530), QRW Entries Ordered (68530), QRW Entries Unordered (68531),
// QRW Amounts (68532);
// shared Assert (60021)
//
// A write to a table an open query reads, made between two Read() calls, invalidates the
// query's result set. Read() then re-reads, starting after the last row it returned in the
// query's OrderBy. Base Application relies on this: codeunit 5895 "Inventory Adjustment"
// modifies "Item Application Entry" inside a Read() loop over query 304, which is ordered.
//
// A query with no OrderBy resumes too: the platform orders every non-aggregated query by the
// primary key of its dataitems for uniqueness, even when the key is not one of its columns.
//
// Written for StefanMaron/BusinessCentral.AL.Runner#5133.
codeunit 68530 "QRW Query Read After Write"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure InsertEntries()
    var
        EntryNo: Integer;
    begin
        DeleteEntries();
        for EntryNo := 1 to 3 do
            InsertEntry(EntryNo);
    end;

    local procedure DeleteEntries()
    var
        Entry: Record "QRW Entry";
    begin
        Entry.DeleteAll();
    end;

    local procedure InsertEntry(EntryNo: Integer)
    var
        Entry: Record "QRW Entry";
    begin
        Entry.Init();
        Entry."Entry No." := EntryNo;
        Entry.Amount := EntryNo * 10;
        Entry.Insert();
    end;

    local procedure MarkProcessed(EntryNo: Integer)
    var
        Entry: Record "QRW Entry";
    begin
        Entry.Get(EntryNo);
        Entry.Processed := true;
        Entry.Modify();
    end;

    local procedure Append(Seen: Text; EntryNo: Integer): Text
    begin
        exit(AppendText(Seen, Format(EntryNo)));
    end;

    local procedure AppendText(Seen: Text; Value: Text): Text
    begin
        if Seen = '' then
            exit(Value);
        exit(Seen + ',' + Value);
    end;

    // Control: the loop with no write reads every row once.
    [Test]
    procedure OrderedQuery_NoWrite_ReadsEveryRow()
    var
        Entries: Query "QRW Entries Ordered";
        Seen: Text;
    begin
        InsertEntries();
        Entries.Open();
        while Entries.Read() do
            Seen := Append(Seen, Entries.EntryNo);
        Entries.Close();
        Assert.AreEqual('1,2,3', Seen, 'Read() without a write must return each row once');
    end;

    // Control: a write made before Open() leaves the result set valid.
    [Test]
    procedure OrderedQuery_ModifyBeforeOpen_ReadsEveryRow()
    var
        Entries: Query "QRW Entries Ordered";
        Seen: Text;
    begin
        InsertEntries();
        MarkProcessed(2);
        Entries.Open();
        while Entries.Read() do
            Seen := Append(Seen, Entries.EntryNo);
        Entries.Close();
        Assert.AreEqual('1,2,3', Seen, 'A write before Open() must not affect the rows read');
    end;

    // The Base Application shape: modify the row just read, then Read() again. The query
    // resumes after the last row and still returns every row exactly once.
    [Test]
    procedure OrderedQuery_ModifyEachRowInLoop_ResumesAfterLastRow()
    var
        Entries: Query "QRW Entries Ordered";
        Seen: Text;
    begin
        InsertEntries();
        Entries.Open();
        while Entries.Read() do begin
            Seen := Append(Seen, Entries.EntryNo);
            MarkProcessed(Entries.EntryNo);
        end;
        Entries.Close();
        Assert.AreEqual('1,2,3', Seen, 'Read() after a Modify must resume after the last row returned');
    end;

    // The re-read sees the table as it is now: a row inserted AFTER the current position is
    // returned, one inserted BEFORE it is not.
    [Test]
    procedure OrderedQuery_InsertInLoop_ReturnsOnlyRowsAfterThePosition()
    var
        Entries: Query "QRW Entries Ordered";
        Seen: Text;
    begin
        DeleteEntries();
        InsertEntry(2);
        InsertEntry(3);
        Entries.Open();
        while Entries.Read() do begin
            Seen := Append(Seen, Entries.EntryNo);
            if Entries.EntryNo = 2 then begin
                InsertEntry(1);
                InsertEntry(4);
            end;
        end;
        Entries.Close();
        Assert.AreEqual('2,3,4', Seen, 'Entry 4 (after the position) is read; entry 1 (before it) is not');
    end;

    // A row deleted after the current position is no longer returned.
    [Test]
    procedure OrderedQuery_DeleteInLoop_SkipsTheDeletedRow()
    var
        Entry: Record "QRW Entry";
        Entries: Query "QRW Entries Ordered";
        Seen: Text;
    begin
        InsertEntries();
        Entries.Open();
        while Entries.Read() do begin
            Seen := Append(Seen, Entries.EntryNo);
            if Entries.EntryNo = 1 then begin
                Entry.Get(2);
                Entry.Delete();
            end;
        end;
        Entries.Close();
        Assert.AreEqual('1,3', Seen, 'A row deleted after the position must not be read');
    end;

    // The column values of the row read after the re-read are that row's, not the last row's.
    [Test]
    procedure OrderedQuery_ModifyInLoop_NextRowCarriesItsOwnValues()
    var
        Entries: Query "QRW Entries Ordered";
    begin
        InsertEntries();
        Entries.Open();
        Assert.IsTrue(Entries.Read(), 'first Read()');
        Assert.AreEqual(1, Entries.EntryNo, 'first row');
        MarkProcessed(1);
        Assert.IsTrue(Entries.Read(), 'Read() after the Modify');
        Assert.AreEqual(2, Entries.EntryNo, 'the row after entry 1');
        Assert.AreEqual(20, Entries.Amount, 'entry 2''s own Amount');
        Entries.Close();
    end;

    // Control: a write to a temporary record of the same table is not a write to the
    // table the query reads, so the result set stays valid.
    [Test]
    procedure UnorderedQuery_WriteToTemporaryRecord_ReadsEveryRow()
    var
        TempEntry: Record "QRW Entry" temporary;
        Entries: Query "QRW Entries Unordered";
        RowsRead: Integer;
    begin
        InsertEntries();
        Entries.Open();
        while Entries.Read() do begin
            RowsRead += 1;
            TempEntry.Init();
            TempEntry."Entry No." := 100 + RowsRead;
            TempEntry.Insert();
        end;
        Entries.Close();
        Assert.AreEqual(3, RowsRead, 'A write to a temporary record must not affect the rows read');
    end;

    // Without an OrderBy the re-read still resumes after the last row: the primary key is the
    // implicit order.
    [Test]
    procedure UnorderedQuery_ModifyInLoop_ResumesAfterLastRow()
    var
        Entries: Query "QRW Entries Unordered";
        Seen: Text;
    begin
        InsertEntries();
        Entries.Open();
        while Entries.Read() do begin
            Seen := Append(Seen, Entries.EntryNo);
            MarkProcessed(Entries.EntryNo);
        end;
        Entries.Close();
        Assert.AreEqual('1,2,3', Seen, 'An unordered query must resume after the last row returned');
    end;

    // The same when the primary key is not a column of the query: the position is still the key.
    [Test]
    procedure KeylessQuery_ModifyInLoop_ResumesAfterLastRow()
    var
        Entry: Record "QRW Entry";
        Amounts: Query "QRW Amounts";
        Seen: Text;
    begin
        InsertEntries();
        Amounts.Open();
        while Amounts.Read() do begin
            Seen := AppendText(Seen, Format(Amounts.Amount));
            Entry.SetRange(Amount, Amounts.Amount);
            Entry.FindFirst();
            Entry.Processed := true;
            Entry.Modify();
        end;
        Amounts.Close();
        Assert.AreEqual('10,20,30', Seen, 'A query without its key as a column must resume after the last row');
    end;
}
