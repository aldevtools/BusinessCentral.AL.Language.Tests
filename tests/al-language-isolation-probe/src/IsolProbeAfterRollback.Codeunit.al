namespace ALLanguage.IsolationProbe;

// What the next test sees, after a test's rollback, of state that is not a table row
// (corpus issue 645, item 5): an AutoIncrement counter, SystemRowVersion, an IsolatedStorage
// value and a NumberSequence. Asked of TestIsolation = Function (runner 61300).
//
// S1-S3 each change one thing and keep what they saw in a global (the instance is reused
// across tests under Function: "Isol Probe Fixture" T2); S4-S9 read it back. All checks are
// relative to this run's own values, so what earlier runs left does not matter.
// Each assertion states one reading: the rollback restores table rows only. A red row is
// the measurement (the message carries both values):
//   S4 found S1's row          -> the database was not rolled back after S1.
//   S5 Entry No. not S1's + 1  -> the AutoIncrement counter was reset by the rollback.
//   S6 row version not higher  -> the row version counter went back.
//   S7 another or no value     -> the IsolatedStorage.Set of S2 was rolled back.
//   S8 sequence missing        -> the NumberSequence.Insert of S3 was rolled back.
//   S9 Next not S3's + 1       -> the NumberSequence.Next of S3 was rolled back.
codeunit 61309 "LT DJ Isol After Rollback"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        S1EntryNo: Integer;
        S1RowVersion: BigInteger;
        S2Value: Text;
        S3Next: BigInteger;
        S3Inserted: Boolean;
        StorageKeyTok: Label 'LTDJIsolProbe', Locked = true;
        SequenceTok: Label 'LTDJIsolProbe', Locked = true;

    [Test]
    procedure S1_InsertsCounterRow()
    var
        CounterRow: Record "LT DJ Isol Counter Row";
    begin
        CounterRow.Note := 'S1';
        CounterRow.Insert();
        S1EntryNo := CounterRow."Entry No.";
        S1RowVersion := CounterRow.SystemRowVersion;
        if S1EntryNo <= 0 then
            Error('S1: AutoIncrement gave Entry No. %1', S1EntryNo);
    end;

    [Test]
    procedure S2_SetsIsolatedStorage()
    var
        ReadBack: Text;
    begin
        S2Value := Format(CreateGuid());
        IsolatedStorage.Set(StorageKeyTok, S2Value, DataScope::Module);
        if not IsolatedStorage.Get(StorageKeyTok, DataScope::Module, ReadBack) then
            Error('S2 could not read back the IsolatedStorage value it set');
        if ReadBack <> S2Value then
            Error('S2 read back %1 instead of %2', ReadBack, S2Value);
    end;

    [Test]
    procedure S3_NextOnNumberSequence()
    begin
        if not NumberSequence.Exists(SequenceTok) then begin
            NumberSequence.Insert(SequenceTok, 1, 1);
            S3Inserted := true;
        end;
        S3Next := NumberSequence.Next(SequenceTok);
    end;

    [Test]
    procedure S4_CounterRowRolledBack()
    var
        CounterRow: Record "LT DJ Isol Counter Row";
    begin
        RequireSet(S1EntryNo <> 0, 'S1');
        if CounterRow.Get(S1EntryNo) then
            Error('S1''s row %1 is still there in S4: the database was not rolled back after S1', S1EntryNo);
    end;

    [Test]
    procedure S5_AutoIncrementNotReset()
    var
        CounterRow: Record "LT DJ Isol Counter Row";
    begin
        RequireSet(S1EntryNo <> 0, 'S1');
        CounterRow.Note := 'S5';
        CounterRow.Insert();
        if CounterRow."Entry No." <> S1EntryNo + 1 then
            Error('AutoIncrement after the rollback of S1: expected %1 (S1 got %2), observed %3', S1EntryNo + 1, S1EntryNo, CounterRow."Entry No.");
    end;

    [Test]
    procedure S6_RowVersionNotReset()
    var
        CounterRow: Record "LT DJ Isol Counter Row";
    begin
        RequireSet(S1EntryNo <> 0, 'S1');
        CounterRow.Note := 'S6';
        CounterRow.Insert();
        if CounterRow.SystemRowVersion <= S1RowVersion then
            Error('SystemRowVersion after the rollback of S1: expected more than %1 (S1''s row), observed %2', S1RowVersion, CounterRow.SystemRowVersion);
    end;

    [Test]
    procedure S7_IsolatedStorageKept()
    var
        Observed: Text;
    begin
        RequireSet(S2Value <> '', 'S2');
        if not IsolatedStorage.Get(StorageKeyTok, DataScope::Module, Observed) then
            Error('IsolatedStorage value set by S2 is gone in S7 (Get returned false): the rollback undid IsolatedStorage.Set');
        if Observed <> S2Value then
            Error('IsolatedStorage after the rollback of S2: expected %1 (S2''s value), observed %2', S2Value, Observed);
    end;

    [Test]
    procedure S8_NumberSequenceStillExists()
    begin
        RequireSet(S3Next <> 0, 'S3');
        if not NumberSequence.Exists(SequenceTok) then
            Error('NumberSequence is gone in S8 (S3 inserted it: %1): the rollback undid NumberSequence.Insert', S3Inserted);
    end;

    [Test]
    procedure S9_NumberSequenceNotReset()
    var
        Observed: BigInteger;
    begin
        RequireSet(S3Next <> 0, 'S3');
        Observed := NumberSequence.Next(SequenceTok);
        if Observed <> S3Next + 1 then
            Error('NumberSequence.Next after the rollback of S3: expected %1 (S3 got %2), observed %3', S3Next + 1, S3Next, Observed);
    end;

    local procedure RequireSet(IsSet: Boolean; Setter: Text)
    begin
        if not IsSet then
            Error('The global %1 sets is not set on this instance (%1 failed, or a fresh codeunit instance per test)', Setter);
    end;
}
