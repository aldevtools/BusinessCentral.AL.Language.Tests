// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setcurrentkey-method
// Scope: in-scope
// Fixtures used: ALT Keyed (60006)
// Area: a read in a sort, a Modify of a field of that sort, then FindFirst / FindLast / FindSet with a range and Count,
// with 63, 64 and 200 rows in the table (al-runner issue 7575: a runner kept a read order from 64 rows on).
// Sorts: Name, Amount (not a key of ALT Keyed: Key1 is Name, Code), Amount (Key2), Name, Code (Key1).

codeunit 69870 "REC Sort Modify Window Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure NonKeySort_ModifySortField_63Rows_FindsRow()
    // CLAIM: after a read in the sort Name, Amount (not a key), a Modify of Amount is seen by FindFirst, FindLast and Count (63 rows).
    begin
        Initialize();
        CheckNonKey(63);
    end;

    [Test]
    procedure NonKeySort_ModifySortField_64Rows_FindsRow()
    // CLAIM: the same with 64 rows, where a runner's read order starts.
    begin
        Initialize();
        CheckNonKey(64);
    end;

    [Test]
    procedure NonKeySort_ModifySortField_200Rows_FindsRow()
    // CLAIM: the same with 200 rows.
    begin
        Initialize();
        CheckNonKey(200);
    end;

    [Test]
    procedure KeySort_ModifySortField_64Rows_FindsRow()
    // CLAIM: after a read in the key Amount (Key2), a Modify of Amount is seen by FindFirst and Count (64 rows).
    begin
        Initialize();
        CheckKey(64);
    end;

    [Test]
    procedure KeySort_ModifySortField_200Rows_FindsRow()
    // CLAIM: the same with 200 rows.
    begin
        Initialize();
        CheckKey(200);
    end;

    [Test]
    procedure NonKeySort_ModifySortField_64Rows_FindSetIteratesRow()
    // CLAIM: FindSet in the non-key sort lists the modified row once (64 rows).
    var
        Keyed: Record "ALT Keyed";
        Seen: Integer;
    begin
        Initialize();
        Fill(64);
        Assert.IsTrue(Read(0), 'row with Amount 0 before the Modify');
        ModifyAmount(64, 7);
        Keyed.SetCurrentKey("Name", "Amount");
        Keyed.SetRange("Name", 'X');
        Keyed.SetRange("Amount", 7);
        if Keyed.FindSet() then
            repeat
                Seen += 1;
                Assert.AreEqual(64, Keyed."Entry No.", 'the modified row');
            until Keyed.Next() = 0;
        Assert.AreEqual(1, Seen, 'FindSet rows with Amount 7');
    end;

    local procedure CheckNonKey(Rows: Integer)
    var
        Keyed: Record "ALT Keyed";
    begin
        Fill(Rows);
        Assert.IsTrue(Read(0), 'row with Amount 0 before the Modify');
        ModifyAmount(Rows, 7);
        Keyed.SetCurrentKey("Name", "Amount");
        Keyed.SetRange("Name", 'X');
        Keyed.SetRange("Amount", 7);
        Assert.AreEqual(1, Keyed.Count(), 'Count with Amount 7');
        Assert.IsTrue(Keyed.FindFirst(), 'FindFirst with Amount 7');
        Assert.AreEqual(Rows, Keyed."Entry No.", 'FindFirst row');
        Assert.IsTrue(Keyed.FindLast(), 'FindLast with Amount 7');
        Assert.AreEqual(Rows, Keyed."Entry No.", 'FindLast row');
        Keyed.SetRange("Amount", 0);
        Assert.AreEqual(Rows - 1, Keyed.Count(), 'Count with Amount 0');
    end;

    local procedure CheckKey(Rows: Integer)
    var
        Keyed: Record "ALT Keyed";
    begin
        Fill(Rows);
        Keyed.SetCurrentKey("Amount");
        Keyed.SetRange("Amount", 0);
        Assert.IsTrue(Keyed.FindFirst(), 'row with Amount 0 before the Modify');
        ModifyAmount(Rows, 7);
        Keyed.SetRange("Amount", 7);
        Assert.AreEqual(1, Keyed.Count(), 'Count with Amount 7');
        Assert.IsTrue(Keyed.FindFirst(), 'FindFirst with Amount 7');
        Assert.AreEqual(Rows, Keyed."Entry No.", 'FindFirst row');
    end;

    local procedure Fill(Rows: Integer)
    var
        Keyed: Record "ALT Keyed";
        i: Integer;
    begin
        for i := 1 to Rows do begin
            Keyed.Init();
            Keyed."Entry No." := i;
            Keyed."Name" := 'X';
            Keyed.Insert();
        end;
    end;

    local procedure Read(AmountValue: Integer): Boolean
    var
        Keyed: Record "ALT Keyed";
    begin
        Keyed.SetCurrentKey("Name", "Amount");
        Keyed.SetRange("Name", 'X');
        Keyed.SetRange("Amount", AmountValue);
        exit(Keyed.FindFirst());
    end;

    local procedure ModifyAmount(EntryNo: Integer; NewAmount: Integer)
    var
        Keyed: Record "ALT Keyed";
    begin
        Keyed.Get(EntryNo);
        Keyed."Amount" := NewAmount;
        Keyed.Modify();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
