// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-orderby-property
// Scope: in-scope
// Fixtures used: QRO Entry (68534), QRO Group (68535), QRO Descending (68534), QRO By Amount
// (68535), QRO Joined Descending (68536); shared Assert (60021)
//
// A query returns its rows in its OrderBy, not in primary-key order, and a write
// to its table between two Read() calls resumes after the last row in that same order. Each
// shape is read once without a write and once with a Modify in the loop.
//
// Entries 1..4 carry Amount 10, 10, 30, 10, so an OrderBy on Amount has ties.
//
// Written for StefanMaron/BusinessCentral.AL.Runner#5160 and #5133.
codeunit 68534 "QRO Query Order After Write"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure InsertEntries()
    var
        Entry: Record "QRO Entry";
        Grp: Record "QRO Group";
    begin
        Grp.DeleteAll();
        Grp.Init();
        Grp.Code := 'G';
        Grp.Description := 'Group';
        Grp.Insert();
        Entry.DeleteAll();
        InsertEntry(1, 10);
        InsertEntry(2, 10);
        InsertEntry(3, 30);
        InsertEntry(4, 10);
    end;

    local procedure InsertEntry(EntryNo: Integer; EntryAmount: Decimal)
    var
        Entry: Record "QRO Entry";
    begin
        Entry.Init();
        Entry."Entry No." := EntryNo;
        Entry.Amount := EntryAmount;
        Entry."Group Code" := 'G';
        Entry.Insert();
    end;

    local procedure MarkProcessed(EntryNo: Integer)
    var
        Entry: Record "QRO Entry";
    begin
        Entry.Get(EntryNo);
        Entry.Processed := true;
        Entry.Modify();
    end;

    [Test]
    procedure Descending_NoWrite_ReadsInOrderByOrder()
    var
        Entries: Query "QRO Descending";
        Seen: Text;
    begin
        InsertEntries();
        Entries.Open();
        while Entries.Read() do
            Seen += Format(Entries.EntryNo) + ';';
        Entries.Close();
        Assert.AreEqual('4;3;2;1;', Seen, 'OrderBy = descending(EntryNo) must return the rows in descending order');
    end;

    [Test]
    procedure Descending_ModifyInLoop_ResumesInOrderByOrder()
    var
        Entries: Query "QRO Descending";
        Seen: Text;
    begin
        InsertEntries();
        Entries.Open();
        while Entries.Read() do begin
            Seen += Format(Entries.EntryNo) + ';';
            MarkProcessed(Entries.EntryNo);
        end;
        Entries.Close();
        Assert.AreEqual('4;3;2;1;', Seen, 'A Modify in the loop must resume after the last row in descending order');
    end;

    // Ties on Amount are broken by the primary key, ascending.
    [Test]
    procedure ByAmount_NoWrite_ReadsInOrderByOrder()
    var
        Entries: Query "QRO By Amount";
        Seen: Text;
    begin
        InsertEntries();
        Entries.Open();
        while Entries.Read() do
            Seen += Format(Entries.EntryNo) + ';';
        Entries.Close();
        Assert.AreEqual('1;2;4;3;', Seen, 'OrderBy = ascending(Amount) must return 10, 10, 10, 30, ties by key');
    end;

    [Test]
    procedure ByAmount_ModifyInLoop_ResumesInOrderByOrder()
    var
        Entries: Query "QRO By Amount";
        Seen: Text;
    begin
        InsertEntries();
        Entries.Open();
        while Entries.Read() do begin
            Seen += Format(Entries.EntryNo) + ';';
            MarkProcessed(Entries.EntryNo);
        end;
        Entries.Close();
        Assert.AreEqual('1;2;4;3;', Seen, 'A Modify in the loop must not lose a row that ties on Amount');
    end;

    // Control for the TOP case below.
    [Test]
    procedure Top2_NoWrite_ReadsTwoRows()
    var
        Entries: Query "QRO Descending";
        Seen: Text;
    begin
        InsertEntries();
        Entries.TopNumberOfRows(2);
        Entries.Open();
        while Entries.Read() do
            Seen += Format(Entries.EntryNo) + ';';
        Entries.Close();
        Assert.AreEqual('4;3;', Seen, 'TopNumberOfRows(2) must return the first two rows');
    end;

    // TOP caps the whole read, not each re-read: after a write the query returns only the
    // rows still owed, so the loop still ends after two rows.
    [Test]
    procedure Top2_ModifyInLoop_StillReadsTwoRows()
    var
        Entries: Query "QRO Descending";
        Seen: Text;
    begin
        InsertEntries();
        Entries.TopNumberOfRows(2);
        Entries.Open();
        while Entries.Read() do begin
            Seen += Format(Entries.EntryNo) + ';';
            MarkProcessed(Entries.EntryNo);
        end;
        Entries.Close();
        Assert.AreEqual('4;3;', Seen, 'A Modify in the loop must keep TopNumberOfRows(2) to two rows in total');
    end;

    // The same with two dataitems.
    [Test]
    procedure JoinedDescending_NoWrite_ReadsInOrderByOrder()
    var
        Entries: Query "QRO Joined Descending";
        Seen: Text;
    begin
        InsertEntries();
        Entries.Open();
        while Entries.Read() do
            Seen += Format(Entries.EntryNo) + ';';
        Entries.Close();
        Assert.AreEqual('4;3;2;1;', Seen, 'A joined query must return its rows in descending OrderBy order');
    end;

    [Test]
    procedure JoinedDescending_ModifyInLoop_ResumesInOrderByOrder()
    var
        Entries: Query "QRO Joined Descending";
        Seen: Text;
    begin
        InsertEntries();
        Entries.Open();
        while Entries.Read() do begin
            Seen += Format(Entries.EntryNo) + ';';
            MarkProcessed(Entries.EntryNo);
        end;
        Entries.Close();
        Assert.AreEqual('4;3;2;1;', Seen, 'A Modify in the loop must resume after the last row of a joined query');
    end;

    [Test]
    procedure JoinedTop2_ModifyInLoop_StillReadsTwoRows()
    var
        Entries: Query "QRO Joined Descending";
        Seen: Text;
    begin
        InsertEntries();
        Entries.TopNumberOfRows(2);
        Entries.Open();
        while Entries.Read() do begin
            Seen += Format(Entries.EntryNo) + ';';
            MarkProcessed(Entries.EntryNo);
        end;
        Entries.Close();
        Assert.AreEqual('4;3;', Seen, 'A Modify in the loop must keep a joined TopNumberOfRows(2) to two rows');
    end;
}
