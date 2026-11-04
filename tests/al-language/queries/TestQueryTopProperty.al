// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-topnumberofrows-property
// Scope: in-scope
// Fixtures used: QRO Entry (68534), QRO Group (68535), QTP Top Two (68650),
// QTP Top Two Unordered (68651), QTP Joined Top Two (68652); shared Assert (60021)
//
// The TopNumberOfRows PROPERTY caps a query's rows the way the TopNumberOfRows() method
// does, and the method replaces the property's value in either direction. Entries 1..4 are
// inserted, so a cap of 2 is observable.
//
// Written for StefanMaron/BusinessCentral.AL.Runner#5164.
codeunit 68650 "QTP Query Top Property"
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
        InsertEntry(1);
        InsertEntry(2);
        InsertEntry(3);
        InsertEntry(4);
    end;

    local procedure InsertEntry(EntryNo: Integer)
    var
        Entry: Record "QRO Entry";
    begin
        Entry.Init();
        Entry."Entry No." := EntryNo;
        Entry.Amount := 10;
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
    procedure Property_IsTheInitialTopNumberOfRows()
    var
        Entries: Query "QTP Top Two";
    begin
        Assert.AreEqual(2, Entries.TopNumberOfRows(), 'TopNumberOfRows() must report the property value before any call sets it');
    end;

    [Test]
    procedure Property_NoWrite_ReadsTwoRows()
    var
        Entries: Query "QTP Top Two";
        Seen: Text;
    begin
        InsertEntries();
        Entries.Open();
        while Entries.Read() do
            Seen += Format(Entries.EntryNo) + ';';
        Entries.Close();
        Assert.AreEqual('4;3;', Seen, 'TopNumberOfRows = 2 must return the first two rows');
    end;

    [Test]
    procedure Property_Unordered_NoWrite_ReadsTwoRows()
    var
        Entries: Query "QTP Top Two Unordered";
        Count: Integer;
    begin
        InsertEntries();
        Entries.Open();
        while Entries.Read() do
            Count += 1;
        Entries.Close();
        Assert.AreEqual(2, Count, 'TopNumberOfRows = 2 must cap a query with no OrderBy to two rows');
    end;

    // The property caps the whole read, as the method does: a re-read after a write returns
    // only the rows still owed.
    [Test]
    procedure Property_ModifyInLoop_StillReadsTwoRows()
    var
        Entries: Query "QTP Top Two";
        Seen: Text;
    begin
        InsertEntries();
        Entries.Open();
        while Entries.Read() do begin
            Seen += Format(Entries.EntryNo) + ';';
            MarkProcessed(Entries.EntryNo);
        end;
        Entries.Close();
        Assert.AreEqual('4;3;', Seen, 'A Modify in the loop must keep TopNumberOfRows = 2 to two rows in total');
    end;

    [Test]
    procedure MethodLarger_OverridesProperty()
    var
        Entries: Query "QTP Top Two";
        Seen: Text;
    begin
        InsertEntries();
        Entries.TopNumberOfRows(3);
        Assert.AreEqual(3, Entries.TopNumberOfRows(), 'TopNumberOfRows(3) must replace the property value');
        Entries.Open();
        while Entries.Read() do
            Seen += Format(Entries.EntryNo) + ';';
        Entries.Close();
        Assert.AreEqual('4;3;2;', Seen, 'TopNumberOfRows(3) must raise the property cap of 2 to three rows');
    end;

    [Test]
    procedure MethodSmaller_OverridesProperty()
    var
        Entries: Query "QTP Top Two";
        Seen: Text;
    begin
        InsertEntries();
        Entries.TopNumberOfRows(1);
        Entries.Open();
        while Entries.Read() do
            Seen += Format(Entries.EntryNo) + ';';
        Entries.Close();
        Assert.AreEqual('4;', Seen, 'TopNumberOfRows(1) must lower the property cap of 2 to one row');
    end;

    [Test]
    procedure MethodZero_RemovesPropertyCap()
    var
        Entries: Query "QTP Top Two";
        Seen: Text;
    begin
        InsertEntries();
        Entries.TopNumberOfRows(0);
        Entries.Open();
        while Entries.Read() do
            Seen += Format(Entries.EntryNo) + ';';
        Entries.Close();
        Assert.AreEqual('4;3;2;1;', Seen, 'TopNumberOfRows(0) must remove the property cap');
    end;

    [Test]
    procedure MethodLarger_ModifyInLoop_ReadsThreeRows()
    var
        Entries: Query "QTP Top Two";
        Seen: Text;
    begin
        InsertEntries();
        Entries.TopNumberOfRows(3);
        Entries.Open();
        while Entries.Read() do begin
            Seen += Format(Entries.EntryNo) + ';';
            MarkProcessed(Entries.EntryNo);
        end;
        Entries.Close();
        Assert.AreEqual('4;3;2;', Seen, 'A Modify in the loop must keep TopNumberOfRows(3) to three rows in total');
    end;

    [Test]
    procedure MethodNegative_Errors()
    var
        Entries: Query "QTP Top Two";
    begin
        asserterror Entries.TopNumberOfRows(-1);
        Assert.ExpectedError('Top number of rows cannot be negative');
        Assert.AreEqual(2, Entries.TopNumberOfRows(), 'A rejected negative value must leave the property value in place');
    end;

    // The same with two dataitems.
    [Test]
    procedure JoinedProperty_NoWrite_ReadsTwoRows()
    var
        Entries: Query "QTP Joined Top Two";
        Seen: Text;
    begin
        InsertEntries();
        Entries.Open();
        while Entries.Read() do
            Seen += Format(Entries.EntryNo) + ';';
        Entries.Close();
        Assert.AreEqual('4;3;', Seen, 'TopNumberOfRows = 2 must cap a joined query to two rows');
    end;

    [Test]
    procedure JoinedProperty_ModifyInLoop_StillReadsTwoRows()
    var
        Entries: Query "QTP Joined Top Two";
        Seen: Text;
    begin
        InsertEntries();
        Entries.Open();
        while Entries.Read() do begin
            Seen += Format(Entries.EntryNo) + ';';
            MarkProcessed(Entries.EntryNo);
        end;
        Entries.Close();
        Assert.AreEqual('4;3;', Seen, 'A Modify in the loop must keep a joined TopNumberOfRows = 2 to two rows');
    end;
}
