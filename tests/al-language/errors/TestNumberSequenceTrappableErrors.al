// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/numbersequence/numbersequence-data-type
// Scope: in-scope (Cloud-compatible)
// Fixtures used: Assert (60021)
// BC versions: 27.5+
//
// CLAIM OF THIS CODEUNIT: every NumberSequence failure raises an error an AL [TryFunction]
// can trap, so the caller gets `false` and keeps running.
//
// Codeunit 60995 "Test Number Sequence" already covers the seed / increment / scope
// semantics and proves that the failure cases error at all. This codeunit covers the
// separate question of what an AL [TryFunction] sees when they do, which is how the Base
// App actually uses the type: "Sequence No. Mgt." wraps Current, Next and Range in
// [TryFunction]s and CREATES the sequence when one of them returns false. A failure that
// could not be trapped would abort that caller instead.

codeunit 60640 "Test NumberSeq Trappable"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        SequenceNameLbl: Label 'ALTNumberSeqTrap60640', Locked = true;

    [Test]
    procedure NumberSequence_Current_Missing_TryFunction_ReturnsFalse()
    // CLAIM: Current on a missing sequence is trappable — the [TryFunction] returns false
    // and the caller reaches the next statement.
    var
        CurrentNo: BigInteger;
    begin
        Initialize();

        Assert.IsFalse(TryCurrent(CurrentNo),
            'A [TryFunction] calling Current on a missing sequence must return false, not abort.');
        Assert.IsSubstring(GetLastErrorText(), 'does not exist');
    end;

    [Test]
    procedure NumberSequence_Current_Present_TryFunction_ReturnsTrue()
    // CLAIM: the same [TryFunction] returns true, and the right value, when the sequence is
    // there. Without this the false above could just mean "always false".
    var
        CurrentNo: BigInteger;
        Expected: BigInteger;
    begin
        Initialize();
        NumberSequence.Insert(SequenceNameLbl, 100, 1, false);

        Assert.IsTrue(TryCurrent(CurrentNo),
            'A [TryFunction] calling Current on an existing sequence must return true.');
        Expected := 100;
        Assert.AreEqual(Expected, CurrentNo, 'Current must report the seed through the [TryFunction].');

        CleanupSequences();
    end;

    [Test]
    procedure NumberSequence_Next_Missing_TryFunction_ReturnsFalse()
    // CLAIM: Next on a missing sequence is trappable.
    var
        NextNo: BigInteger;
    begin
        Initialize();

        Assert.IsFalse(TryNext(NextNo),
            'A [TryFunction] calling Next on a missing sequence must return false, not abort.');
        Assert.IsSubstring(GetLastErrorText(), 'does not exist');
    end;

    [Test]
    procedure NumberSequence_Range_Missing_TryFunction_ReturnsFalse()
    // CLAIM: Range on a missing sequence is trappable.
    var
        FirstOfRange: BigInteger;
    begin
        Initialize();

        Assert.IsFalse(TryRange(3, FirstOfRange),
            'A [TryFunction] calling Range on a missing sequence must return false, not abort.');
        Assert.IsSubstring(GetLastErrorText(), 'does not exist');
    end;

    [Test]
    procedure NumberSequence_Restart_Missing_TryFunction_ReturnsFalse()
    // CLAIM: Restart on a missing sequence is trappable.
    begin
        Initialize();

        Assert.IsFalse(TryRestart(1),
            'A [TryFunction] calling Restart on a missing sequence must return false, not abort.');
        Assert.IsSubstring(GetLastErrorText(), 'does not exist');
    end;

    [Test]
    procedure NumberSequence_Insert_Duplicate_TryFunction_ReturnsFalse()
    // CLAIM: inserting a sequence that already exists is trappable.
    begin
        Initialize();
        NumberSequence.Insert(SequenceNameLbl, 100, 1, false);

        Assert.IsFalse(TryInsert(100, 1),
            'A [TryFunction] inserting a duplicate sequence must return false, not abort.');
        Assert.IsSubstring(GetLastErrorText(), 'already exists');

        CleanupSequences();
    end;

    [Test]
    procedure NumberSequence_Delete_Missing_TryFunction_ReturnsTrue()
    // CLAIM: deleting a sequence that does not exist is not a failure at all. There is
    // nothing for a [TryFunction] to trap, so it returns true.
    begin
        Initialize();

        Assert.IsTrue(TryDelete(),
            'Deleting a sequence that does not exist must succeed.');
        Assert.IsFalse(NumberSequence.Exists(SequenceNameLbl, false),
            'The sequence must still not exist afterwards.');
    end;

    [TryFunction]
    local procedure TryCurrent(var CurrentNo: BigInteger)
    begin
        CurrentNo := NumberSequence.Current(SequenceNameLbl, false);
    end;

    [TryFunction]
    local procedure TryNext(var NextNo: BigInteger)
    begin
        NextNo := NumberSequence.Next(SequenceNameLbl, false);
    end;

    [TryFunction]
    local procedure TryRange(RangeSize: Integer; var FirstOfRange: BigInteger)
    begin
        FirstOfRange := NumberSequence.Range(SequenceNameLbl, RangeSize, false);
    end;

    [TryFunction]
    local procedure TryRestart(Seed: BigInteger)
    begin
        NumberSequence.Restart(SequenceNameLbl, Seed, false);
    end;

    [TryFunction]
    local procedure TryInsert(Seed: BigInteger; Increment: BigInteger)
    begin
        NumberSequence.Insert(SequenceNameLbl, Seed, Increment, false);
    end;

    [TryFunction]
    local procedure TryDelete()
    begin
        NumberSequence.Delete(SequenceNameLbl, false);
    end;

    local procedure Initialize()
    begin
        CleanupSequences();
        ClearLastError();
    end;

    local procedure CleanupSequences()
    begin
        // Number sequences are database objects, not rows, so one created by a test
        // outlives that test unless it is dropped here.
        if NumberSequence.Exists(SequenceNameLbl, true) then
            NumberSequence.Delete(SequenceNameLbl, true);
        if NumberSequence.Exists(SequenceNameLbl, false) then
            NumberSequence.Delete(SequenceNameLbl, false);
    end;
}
