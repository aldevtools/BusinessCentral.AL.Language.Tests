namespace ALLanguage.IsolationProbe;

// What an explicit Commit() inside a test does under the runner's isolation (corpus issue
// 645, item 3). The question is asked of TestIsolation = Function (runner 61300); the other
// runners give the comparison.
//
// C1 inserts COMMIT with a fresh GUID, calls Commit(), then inserts AFTER with the same GUID.
// The GUID is kept in a global (the test codeunit instance is reused across its tests under
// Function: "Isol Probe Fixture" T2), so a row left by an earlier run never counts as C1's.
// Each assertion states the reading expected under Function: the whole test is rolled back,
// Commit() included. A red row is the measurement:
//   C1 fails             -> Commit() raised an error in a test (the message is BC's).
//   C2 found C1's COMMIT -> Commit() made the row survive the per-test rollback.
//   C3 found C1's AFTER  -> the row written after Commit() survived as well (no rollback at all).
codeunit 61308 "LT DJ Isol Commit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        C1Value: Guid;

    [Test]
    procedure C1_InsertsCommitsAndInsertsAgain()
    var
        CommitRow: Record "LT DJ Isol Commit Row";
    begin
        C1Value := CreateGuid();
        WriteRow('COMMIT');
        Commit();
        WriteRow('AFTER');
        if not CommitRow.Get('COMMIT') then
            Error('C1 could not read back COMMIT after Commit()');
    end;

    [Test]
    procedure C2_CommittedRowRolledBack()
    begin
        ExpectNoRowFromC1('COMMIT', 'Commit() made the row survive the per-test rollback');
    end;

    [Test]
    procedure C3_RowAfterCommitRolledBack()
    begin
        ExpectNoRowFromC1('AFTER', 'the row written after Commit() survived the per-test rollback');
    end;

    local procedure WriteRow(RowKey: Code[20])
    var
        CommitRow: Record "LT DJ Isol Commit Row";
    begin
        if CommitRow.Get(RowKey) then
            CommitRow.Delete();
        CommitRow."Key" := RowKey;
        CommitRow.Value := C1Value;
        CommitRow.Insert();
    end;

    local procedure ExpectNoRowFromC1(RowKey: Code[20]; Meaning: Text)
    var
        CommitRow: Record "LT DJ Isol Commit Row";
    begin
        if IsNullGuid(C1Value) then
            Error('C1''s GUID is not set on the instance %1 runs on (a fresh codeunit instance per test)', RowKey);
        if CommitRow.Get(RowKey) then
            if CommitRow.Value = C1Value then
                Error('Row %1 is still there with C1''s value: %2', RowKey, Meaning);
    end;
}
