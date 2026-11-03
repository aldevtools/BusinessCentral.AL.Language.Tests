// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/numbersequence/numbersequence-data-type
// Scope: in-scope
// Fixtures used: shared Assert (60021)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins the texts and code of the NumberSequence errors, the defaults of Insert and Restart, that
// the numbers a rolled back transaction took are not given back, and the surprising result that
// an Insert of a name that already exists raises and leaves the sequence gone.
//
// The sequences are created and removed by the tests themselves with names of their own.
// BC versions: 27.5

codeunit 68162 "Probe Number Sequence"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Remove(SequenceName: Text)
    begin
        if NumberSequence.Exists(SequenceName) then
            NumberSequence.Delete(SequenceName);
        Commit();
    end;

    [Test]
    procedure NumberSequence_NextRestartRange_Values()
    // CLAIM: Insert(10, 5) then Next gives 10, 15; a Restart without a seed makes Current 0; Restart(100) makes Current 100 and the next Next 100; Range(3) takes three numbers.
    var
        Reserved: BigInteger;
    begin
        Remove('PROBE-NS-1');
        NumberSequence.Insert('PROBE-NS-1', 10, 5);
        Commit();

        Assert.AreEqual('10', Format(NumberSequence.Next('PROBE-NS-1')), 'first Next is the start value');
        Assert.AreEqual('15', Format(NumberSequence.Next('PROBE-NS-1')), 'second Next adds the increment');
        Assert.AreEqual('15', Format(NumberSequence.Current('PROBE-NS-1')), 'Current');

        NumberSequence.Restart('PROBE-NS-1');
        Assert.AreEqual('0', Format(NumberSequence.Current('PROBE-NS-1')), 'Restart without a seed');
        NumberSequence.Restart('PROBE-NS-1', 100);
        Assert.AreEqual('100', Format(NumberSequence.Current('PROBE-NS-1')), 'Restart with a seed');
        Assert.AreEqual('100', Format(NumberSequence.Next('PROBE-NS-1')), 'the first Next after Restart is the seed');

        Assert.AreEqual('105', Format(NumberSequence.Range('PROBE-NS-1', 3, Reserved)), 'Range returns the first number it reserved');
        Assert.AreEqual('120', Format(NumberSequence.Next('PROBE-NS-1')), 'three numbers (105, 110, 115) were taken');

        Remove('PROBE-NS-1');
    end;

    [Test]
    procedure NumberSequence_NextInsideARolledBackBlock_IsNotGivenBack()
    var
        Taken: BigInteger;
    begin
        Remove('PROBE-NS-2');
        NumberSequence.Insert('PROBE-NS-2', 10, 5);
        Commit();
        Assert.AreEqual('10', Format(NumberSequence.Next('PROBE-NS-2')), 'first');

        asserterror begin
            Taken := NumberSequence.Next('PROBE-NS-2');
            Error('rolled back');
        end;

        Assert.AreEqual('15', Format(NumberSequence.Current('PROBE-NS-2')), 'the number taken inside the rolled back block stays taken');
        Assert.AreEqual('20', Format(NumberSequence.Next('PROBE-NS-2')), 'and the next one follows it');

        Remove('PROBE-NS-2');
    end;

    [Test]
    procedure NumberSequence_Insert_WithoutArguments_StartsAtZeroAndStepsByOne()
    begin
        Remove('PROBE-NS-3');
        NumberSequence.Insert('PROBE-NS-3');

        Assert.AreEqual('0', Format(NumberSequence.Next('PROBE-NS-3')), 'first');
        Assert.AreEqual('1', Format(NumberSequence.Next('PROBE-NS-3')), 'second');

        Remove('PROBE-NS-3');
    end;

    [Test]
    procedure NumberSequence_MissingSequence_Texts()
    var
        Value: BigInteger;
    begin
        Remove('PROBE-NS-MISSING');

        asserterror Value := NumberSequence.Next('PROBE-NS-MISSING');
        Assert.AreEqual('The number sequence ''PROBE-NS-MISSING'' does not exist.', GetLastErrorText(), 'Next');
        Assert.AreEqual('AL', GetLastErrorCode(), 'code');

        asserterror Value := NumberSequence.Current('PROBE-NS-MISSING');
        Assert.AreEqual('The number sequence ''PROBE-NS-MISSING'' does not exist.', GetLastErrorText(), 'Current');

        asserterror NumberSequence.Restart('PROBE-NS-MISSING');
        Assert.AreEqual('The number sequence ''PROBE-NS-MISSING'' does not exist.', GetLastErrorText(), 'Restart');

        ClearLastError();
        NumberSequence.Delete('PROBE-NS-MISSING');
        Assert.AreEqual('', GetLastErrorText(), 'Delete of a sequence that does not exist raises nothing');
    end;

    [Test]
    procedure NumberSequence_Range_Zero_ThrowsSqlError()
    var
        Reserved: BigInteger;
        Value: BigInteger;
    begin
        Remove('PROBE-NS-4');
        NumberSequence.Insert('PROBE-NS-4', 1, 1);
        Commit();

        asserterror Value := NumberSequence.Range('PROBE-NS-4', 0, Reserved);

        Assert.AreEqual('An unexpected error occurred after a database command was cancelled.', GetLastErrorText(), 'text');
        Assert.AreEqual('Sql:Sql', GetLastErrorCode(), 'code');
        Remove('PROBE-NS-4');
    end;

    [Test]
    procedure NumberSequence_Insert_OfAnExistingName_RaisesAndLeavesTheSequenceGone()
    // CLAIM: the second Insert raises "...already exists."; afterwards Exists is false, in the same test and in the next one.
    begin
        Remove('PROBE-NS-5');
        NumberSequence.Insert('PROBE-NS-5', 10, 5);
        Commit();
        Assert.IsTrue(NumberSequence.Exists('PROBE-NS-5'), 'created');

        asserterror NumberSequence.Insert('PROBE-NS-5', 10, 5);

        Assert.AreEqual('The number sequence ''PROBE-NS-5'' already exists.', GetLastErrorText(), 'text');
        Assert.AreEqual('AL', GetLastErrorCode(), 'code');
        Assert.IsFalse(NumberSequence.Exists('PROBE-NS-5'), 'the sequence is gone');
    end;
}
