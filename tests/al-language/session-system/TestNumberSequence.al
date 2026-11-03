// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/numbersequence/numbersequence-data-type
// Scope: in-scope (Cloud-compatible)
// Fixtures used: Assert (60021)
// BC versions: 27.5+

codeunit 60995 "Test Number Sequence"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        SequenceNameLbl: Label 'ALTNumberSequence60995', Locked = true;

    [Test]
    procedure NumberSequence_Next_DefaultScopeHonorsSeedAndIncrement()
    // CLAIM: the default company-specific sequence starts at its seed and advances by its increment.
    begin
        Initialize();

        NumberSequence.Insert(SequenceNameLbl, 5, 2);

        Assert.IsTrue(NumberSequence.Exists(SequenceNameLbl, true),
            'The overload without CompanySpecific must create a company-specific sequence.');
        Assert.IsFalse(NumberSequence.Exists(SequenceNameLbl, false),
            'The overload without CompanySpecific must not create a global sequence.');
        AssertBigIntegerEquals(5, NumberSequence.Next(SequenceNameLbl),
            'The first value from a default-scope sequence must equal its seed.');
        AssertBigIntegerEquals(7, NumberSequence.Next(SequenceNameLbl),
            'The second value from a default-scope sequence must apply its increment.');

        CleanupSequences();
    end;

    [Test]
    procedure NumberSequence_Next_GlobalScopeHonorsSeedAndIncrement()
    // CLAIM: a non-company-specific sequence starts at its seed and advances by its increment.
    begin
        Initialize();

        NumberSequence.Insert(SequenceNameLbl, 10, 3, false);

        AssertBigIntegerEquals(10, NumberSequence.Next(SequenceNameLbl, false),
            'The first value from a global sequence must equal its seed.');
        AssertBigIntegerEquals(13, NumberSequence.Next(SequenceNameLbl, false),
            'The second value from a global sequence must apply its increment.');

        CleanupSequences();
    end;

    [Test]
    procedure NumberSequence_Exists_CompanyScopesAreIndependent()
    // CLAIM: company-specific and global sequences with the same name keep independent state.
    begin
        Initialize();

        NumberSequence.Insert(SequenceNameLbl, 1, 1, true);
        NumberSequence.Insert(SequenceNameLbl, 100, 10, false);

        Assert.IsTrue(NumberSequence.Exists(SequenceNameLbl, true),
            'Exists must find the company-specific sequence.');
        Assert.IsTrue(NumberSequence.Exists(SequenceNameLbl, false),
            'Exists must find the global sequence.');
        AssertBigIntegerEquals(1, NumberSequence.Next(SequenceNameLbl, true),
            'The company-specific sequence must retain its own seed.');
        AssertBigIntegerEquals(100, NumberSequence.Next(SequenceNameLbl, false),
            'The global sequence must retain its own seed.');

        CleanupSequences();
    end;

    [Test]
    procedure NumberSequence_Current_AfterInsertReturnsSeed()
    // CLAIM: before any allocation, Current returns the configured seed.
    begin
        Initialize();

        NumberSequence.Insert(SequenceNameLbl, 10, 3, false);

        AssertBigIntegerEquals(10, NumberSequence.Current(SequenceNameLbl, false),
            'Current must expose the configured seed before the first allocation.');

        CleanupSequences();
    end;

    [Test]
    procedure NumberSequence_Restart_SetsNextValueAndPreservesIncrement()
    // CLAIM: Restart replaces the next value without changing the sequence increment.
    begin
        Initialize();
        NumberSequence.Insert(SequenceNameLbl, 10, 3, false);
        AssertBigIntegerEquals(10, NumberSequence.Next(SequenceNameLbl, false),
            'The sequence must allocate its original seed before Restart.');

        NumberSequence.Restart(SequenceNameLbl, 50, false);

        AssertBigIntegerEquals(50, NumberSequence.Next(SequenceNameLbl, false),
            'The first value after Restart must equal the new seed.');
        AssertBigIntegerEquals(53, NumberSequence.Next(SequenceNameLbl, false),
            'Restart must preserve the configured increment.');

        CleanupSequences();
    end;

    [Test]
    procedure NumberSequence_Delete_RemovesSequence()
    // CLAIM: Delete removes the selected sequence.
    begin
        Initialize();
        NumberSequence.Insert(SequenceNameLbl, 1, 1, false);
        Assert.IsTrue(NumberSequence.Exists(SequenceNameLbl, false),
            'The sequence must exist before Delete.');

        NumberSequence.Delete(SequenceNameLbl, false);

        Assert.IsFalse(NumberSequence.Exists(SequenceNameLbl, false),
            'Exists must return false after Delete.');
    end;

    [Test]
    procedure NumberSequence_Range_ReservesRequestedValues()
    // CLAIM: Range returns the first reserved value, leaves Current at the last, and advances Next past the range.
    var
        RangeStart: BigInteger;
    begin
        Initialize();
        NumberSequence.Insert(SequenceNameLbl, 10, 3, false);

        RangeStart := NumberSequence.Range(SequenceNameLbl, 4, false);

        AssertBigIntegerEquals(10, RangeStart,
            'Range must return the first reserved value.');
        AssertBigIntegerEquals(19, NumberSequence.Current(SequenceNameLbl, false),
            'Range must reserve exactly four values using the configured increment.');
        AssertBigIntegerEquals(22, NumberSequence.Next(SequenceNameLbl, false),
            'The next allocation must follow the reserved range.');

        CleanupSequences();
    end;

    [Test]
    procedure NumberSequence_Range_ByRefReportsIncrement()
    // CLAIM: the ByRef Range overload returns the sequence increment with the reserved range.
    var
        Increment: BigInteger;
        RangeStart: BigInteger;
    begin
        Initialize();
        NumberSequence.Insert(SequenceNameLbl, 10, 3, false);

        RangeStart := NumberSequence.Range(SequenceNameLbl, 4, Increment, false);

        AssertBigIntegerEquals(10, RangeStart,
            'The ByRef Range overload must return the first reserved value.');
        AssertBigIntegerEquals(3, Increment,
            'The ByRef Range overload must report the configured increment.');
        AssertBigIntegerEquals(19, NumberSequence.Current(SequenceNameLbl, false),
            'The ByRef Range overload must reserve the requested values.');

        CleanupSequences();
    end;

    [Test]
    procedure NumberSequence_Insert_DuplicateNameThrows()
    // CLAIM: inserting an existing sequence throws.
    begin
        Initialize();
        NumberSequence.Insert(SequenceNameLbl, 1, 1, false);

        asserterror NumberSequence.Insert(SequenceNameLbl, 100, 10, false);

        Assert.ExpectedError('already exists');

        CleanupSequences();
    end;

    [Test]
    procedure NumberSequence_Next_MissingSequenceThrowsWithoutCreatingIt()
    // CLAIM: requesting the next value of a missing sequence throws and does not create it.
    var
        Value: BigInteger;
    begin
        Initialize();

        asserterror Value := NumberSequence.Next(SequenceNameLbl, false);

        Assert.ExpectedError('does not exist');
        Assert.IsFalse(NumberSequence.Exists(SequenceNameLbl, false),
            'A failed Next call must not create the missing sequence.');
    end;

    local procedure Initialize()
    begin
        CleanupSequences();
        ClearLastError();
    end;

    local procedure CleanupSequences()
    begin
        DeleteIfExists(true);
        DeleteIfExists(false);
    end;

    local procedure DeleteIfExists(CompanySpecific: Boolean)
    begin
        if NumberSequence.Exists(SequenceNameLbl, CompanySpecific) then
            NumberSequence.Delete(SequenceNameLbl, CompanySpecific);
    end;

    local procedure AssertBigIntegerEquals(Expected: BigInteger; Actual: BigInteger; FailureMessage: Text)
    begin
        Assert.AreEqual(Expected, Actual, FailureMessage);
    end;
}
