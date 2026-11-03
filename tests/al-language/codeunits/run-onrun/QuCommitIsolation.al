// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-requiredtestisolation-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-commit-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (AL Runner issue 5607): what Commit() inside a test method does under each test isolation, read from inside the test
// (Database.IsInWriteTransaction, whether a guarded Codeunit.Run is allowed, GetLastErrorText) and from the NEXT test and the
// NEXT test codeunit (which rows are still there). Hypothesis under test, not assumed: test isolation is an outer transaction;
// Commit() inside a test behaves like a commit inside it, and the isolation rolls everything back at its boundary anyway.
//
// Lever: RequiredTestIsolation on the test codeunit. On BC 28 and later the Linux legs run a test codeunit without
// [HandlerFunctions] through the service tier's TestRunnerHub (`al runtests`, the VS Code Test Explorer path), which runs
// no AL test runner codeunit and takes the isolation from RequiredTestIsolation. On BC 27 the legs run every codeunit under
// "Test Runner - Isol. Codeunit" (130450, TestIsolation = Codeunit). A custom TestRunner codeunit cannot be started from a
// test (TestCodeUnitNestedInvocation, events/lt-trigger-pins/PTestRunnerTriggers.al), so this is the only way to reach
// Function and Disabled isolation on the Linux legs.
//
// One pair of test codeunits per isolation: A (writes, then reads in a later test) and B (the next codeunit id, reads what A
// left). Codeunits run in ascending id order, the order record/TestIsolationRollbackScope.al and
// codeunit/TestEventManualBindingCrossCodeunit.al rely on. Each isolation has its own key prefix: C (Codeunit), F (Function),
// D (Disabled), N (no property). Every A test that writes without observing never fails, so a failure elsewhere cannot change
// what the readers see.
// Not asked here: a test that fails after Commit() (a red test cannot be part of the corpus).
//
// Measured on BC 27.5, 28.5 and 29.0 (Linux legs):
//   - Inside a test, Commit() acts as a real commit of the inner transaction under every isolation: IsInWriteTransaction is
//     No after it (X05), a guarded Codeunit.Run is refused while a write is open ("the transaction is stopped", DB:Ok) and
//     allowed after Commit() (X06), and an error trapped by asserterror undoes only the writes since the last Commit() (X07).
//   - Commit() inside a TryFunction fails with TryFunctionWrite under every isolation (X08).
//   - A test-method boundary never leaves a write transaction open (tx_at_start = No in X04, X09, X11).
//   - Codeunit isolation (and no property): every row survives into the later tests of the codeunit, committed or not (C04,
//     C09), and NOTHING survives into the next test codeunit, Commit() included (C11, N11): the isolation is an outer
//     transaction a Commit() inside the test does not end.
//   - Function isolation, BC 28+: nothing survives into the next test, Commit() and a committing Codeunit.Run included (F04,
//     F09); BC 27: as Codeunit isolation.
//   - Disabled isolation, BC 28+: everything survives into the next codeunit, including the write still open when a test ended
//     (D11 cb): the boundary commits it; BC 27: as Codeunit isolation.
// The BC28PLUS guards mark a difference of the test HARNESS, not of the platform version: BC 27 legs run every codeunit under
// 130450 (TestIsolation = Codeunit), which takes no account of RequiredTestIsolation; BC 28+ legs run these codeunits (no
// [HandlerFunctions]) through the TestRunnerHub, which takes the isolation from RequiredTestIsolation.
// Object ids 87440-87450.
// BC versions: 27.5, 28.5, 29.0

table 87440 "LT QU Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[20]) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}

// Run with a record: inserts the record it was given.
codeunit 87441 "LT QU Inserter"
{
    TableNo = "LT QU Row";

    trigger OnRun()
    begin
        Rec.Insert();
    end;
}

// The writers and readers every pair of test codeunits shares.
codeunit 87450 "LT QU Probe"
{
    procedure Put(RowKey: Text)
    var
        Row: Record "LT QU Row";
    begin
        if Row.Get(RowKey) then
            Row.Delete();
        Row."Key" := CopyStr(RowKey, 1, MaxStrLen(Row."Key"));
        Row.Insert();
    end;

    procedure Has(RowKey: Text): Text
    var
        Row: Record "LT QU Row";
    begin
        exit(Format(Row.Get(RowKey)));
    end;

    local procedure Tx(): Text
    begin
        exit(Format(Database.IsInWriteTransaction()));
    end;

    // A test that inserts a row and ends without a Commit (the instrument: what the isolation does with plain writes).
    procedure InsertNoCommit(P: Text)
    begin
        Put(P + '-NC');
    end;

    // A test that inserts a row, commits and ends.
    procedure InsertCommit(P: Text)
    begin
        Put(P + '-CM');
        Commit();
    end;

    // A test that inserts, commits, inserts again and ends with that write open.
    procedure InsertCommitInsert(P: Text)
    begin
        Put(P + '-CA');
        Commit();
        Put(P + '-CB');
    end;

    // What a later test of the same codeunit sees.
    procedure ObserveEarlierTests(P: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('tx_at_start', Tx());
        Observer.Observe('no_commit_row', Has(P + '-NC'));
        Observer.Observe('committed_row', Has(P + '-CM'));
        Observer.Observe('committed_before_tail', Has(P + '-CA'));
        Observer.Observe('tail_after_commit', Has(P + '-CB'));
    end;

    // Database.IsInWriteTransaction around a Commit inside the test.
    procedure ObserveWriteTx(P: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('start', Tx());
        Put(P + '-W1');
        Observer.Observe('after_insert', Tx());
        Commit();
        Observer.Observe('after_commit', Tx());
        Observer.Observe('row_after_commit', Has(P + '-W1'));
        Put(P + '-W2');
        Observer.Observe('after_second_insert', Tx());
        Commit();
        Observer.Observe('after_second_commit', Tx());
    end;

    // A guarded Codeunit.Run with an open write, then the same after Commit().
    procedure ObserveCodeunitRun(P: Text; var Observer: Codeunit "Probe Observer")
    var
        Row: Record "LT QU Row";
        Ok: Boolean;
    begin
        Commit();
        Put(P + '-R0');
        Row."Key" := CopyStr(P + '-R1', 1, MaxStrLen(Row."Key"));
        ClearLastError();
        asserterror Ok := Codeunit.Run(Codeunit::"LT QU Inserter", Row);
        Observer.ObserveError('open_write_run');
        Observer.Observe('open_write_r0', Has(P + '-R0'));
        Observer.Observe('open_write_r1', Has(P + '-R1'));

        Put(P + '-R2');
        Commit();
        Observer.Observe('tx_before_run', Tx());
        Row."Key" := CopyStr(P + '-R3', 1, MaxStrLen(Row."Key"));
        ClearLastError();
        Ok := Codeunit.Run(Codeunit::"LT QU Inserter", Row);
        Observer.Observe('after_commit_run_ok', Format(Ok));
        Observer.Observe('after_commit_run_lasterror', GetLastErrorText());
        Observer.Observe('tx_after_run', Tx());
        Observer.Observe('r2', Has(P + '-R2'));
        Observer.Observe('r3', Has(P + '-R3'));

        Row."Key" := CopyStr(P + '-R3', 1, MaxStrLen(Row."Key"));
        ClearLastError();
        Ok := Codeunit.Run(Codeunit::"LT QU Inserter", Row);
        Observer.Observe('duplicate_run_ok', Format(Ok));
        Observer.Observe('duplicate_run_lasterror_code', GetLastErrorCode());
        Observer.Observe('tx_after_failed_run', Tx());
    end;

    // asserterror around a block that commits and then fails.
    procedure ObserveAssertErrorCommit(P: Text; var Observer: Codeunit "Probe Observer")
    begin
        Commit();
        Put(P + '-E0');
        asserterror begin
            Put(P + '-E1');
            Commit();
            Put(P + '-E2');
            Error('LT QU error after commit');
        end;
        Observer.Observe('error', GetLastErrorText());
        Observer.Observe('tx_after', Tx());
        Observer.Observe('before_block', Has(P + '-E0'));
        Observer.Observe('in_block_before_commit', Has(P + '-E1'));
        Observer.Observe('in_block_after_commit', Has(P + '-E2'));
    end;

    // Commit inside a TryFunction (the same shape as misc/lt-cu-odd-leads/CuCommitTests.al Commit_InTryFunction, asked per isolation),
    // with a committed row before it and an uncommitted row open when the try starts.
    procedure ObserveTryCommit(P: Text; var Observer: Codeunit "Probe Observer")
    var
        Ok: Boolean;
    begin
        Put(P + '-T0');
        Commit();
        Put(P + '-T1');
        ClearLastError();
        asserterror Ok := TryCommit();
        Observer.ObserveError('try');
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('tx_after', Tx());
        Observer.Observe('committed_before_try', Has(P + '-T0'));
        Observer.Observe('open_when_try_started', Has(P + '-T1'));
    end;

    [TryFunction]
    local procedure TryCommit()
    begin
        Commit();
    end;

    // What a later test of the same codeunit sees of the rows the tests above committed: by Commit() (W1, W2), before and by
    // a Codeunit.Run (R2, R3), and inside an asserterror block (E0, E1).
    procedure ObserveCommittedByEarlierTests(P: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('tx_at_start', Tx());
        Observer.Observe('w1', Has(P + '-W1'));
        Observer.Observe('w2', Has(P + '-W2'));
        Observer.Observe('r2', Has(P + '-R2'));
        Observer.Observe('r3', Has(P + '-R3'));
        Observer.Observe('e0', Has(P + '-E0'));
        Observer.Observe('e1', Has(P + '-E1'));
        Observer.Observe('t0', Has(P + '-T0'));
    end;

    // What the next test codeunit sees of everything codeunit A wrote.
    procedure ObserveEarlierCodeunit(P: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('tx_at_start', Tx());
        Observer.Observe('nc', Has(P + '-NC'));
        Observer.Observe('cm', Has(P + '-CM'));
        Observer.Observe('ca', Has(P + '-CA'));
        Observer.Observe('cb', Has(P + '-CB'));
        Observer.Observe('w1', Has(P + '-W1'));
        Observer.Observe('w2', Has(P + '-W2'));
        Observer.Observe('r0', Has(P + '-R0'));
        Observer.Observe('r2', Has(P + '-R2'));
        Observer.Observe('r3', Has(P + '-R3'));
        Observer.Observe('e0', Has(P + '-E0'));
        Observer.Observe('e1', Has(P + '-E1'));
        Observer.Observe('e2', Has(P + '-E2'));
        Observer.Observe('t0', Has(P + '-T0'));
        Observer.Observe('t1', Has(P + '-T1'));
    end;
}

codeunit 87442 "LT QU Codeunit A"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Probe: Codeunit "LT QU Probe";

    [Test]
    procedure QU_C01_InsertNoCommit()
    begin
        Probe.InsertNoCommit('C');
    end;

    [Test]
    procedure QU_C02_InsertCommit()
    begin
        Probe.InsertCommit('C');
    end;

    [Test]
    procedure QU_C03_InsertCommitInsert()
    begin
        Probe.InsertCommitInsert('C');
    end;

    [Test]
    procedure QU_C04_NextTestSees()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveEarlierTests('C', Observer);
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('no_commit_row', 'Yes');
        Observer.Expect('committed_row', 'Yes');
        Observer.Expect('committed_before_tail', 'Yes');
        Observer.Expect('tail_after_commit', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QU_C05_WriteTxAroundCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveWriteTx('C', Observer);
        Observer.Expect('start', 'No');
        Observer.Expect('after_insert', 'Yes');
        Observer.Expect('after_commit', 'No');
        Observer.Expect('row_after_commit', 'Yes');
        Observer.Expect('after_second_insert', 'Yes');
        Observer.Expect('after_second_commit', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QU_C06_CodeunitRunAfterCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCodeunitRun('C', Observer);
        Observer.Expect('open_write_run|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('open_write_run|code', 'DB:Ok');
        Observer.Expect('open_write_r0', 'No');
        Observer.Expect('open_write_r1', 'No');
        Observer.Expect('tx_before_run', 'No');
        Observer.Expect('after_commit_run_ok', 'Yes');
        Observer.Expect('after_commit_run_lasterror', '');
        Observer.Expect('tx_after_run', 'No');
        Observer.Expect('r2', 'Yes');
        Observer.Expect('r3', 'Yes');
        Observer.Expect('duplicate_run_ok', 'No');
        Observer.Expect('duplicate_run_lasterror_code', 'DB:RecordExists');
        Observer.Expect('tx_after_failed_run', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QU_C07_AssertErrorAroundCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveAssertErrorCommit('C', Observer);
        Observer.Expect('error', 'LT QU error after commit');
        Observer.Expect('tx_after', 'No');
        Observer.Expect('before_block', 'Yes');
        Observer.Expect('in_block_before_commit', 'Yes');
        Observer.Expect('in_block_after_commit', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QU_C08_CommitInTryFunction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveTryCommit('C', Observer);
        Observer.Expect('try|text', 'Call to the function ''COMMIT'' is not allowed inside the call to ''QU_C08_CommitInTryFunction'' when it is used as a TryFunction.');
        Observer.Expect('try|code', 'TryFunctionWrite');
        Observer.Expect('ok', 'No');
        Observer.Expect('tx_after', 'No');
        Observer.Expect('committed_before_try', 'Yes');
        Observer.Expect('open_when_try_started', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QU_C09_LaterTestSeesCommittedRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCommittedByEarlierTests('C', Observer);
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('w1', 'Yes');
        Observer.Expect('w2', 'Yes');
        Observer.Expect('r2', 'Yes');
        Observer.Expect('r3', 'Yes');
        Observer.Expect('e0', 'Yes');
        Observer.Expect('e1', 'Yes');
        Observer.Expect('t0', 'Yes');
        Observer.Verify();
    end;
}

codeunit 87443 "LT QU Codeunit B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    [Test]
    procedure QU_C11_NextCodeunitSees()
    var
        Probe: Codeunit "LT QU Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveEarlierCodeunit('C', Observer);
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('nc', 'No');
        Observer.Expect('cm', 'No');
        Observer.Expect('ca', 'No');
        Observer.Expect('cb', 'No');
        Observer.Expect('w1', 'No');
        Observer.Expect('w2', 'No');
        Observer.Expect('r0', 'No');
        Observer.Expect('r2', 'No');
        Observer.Expect('r3', 'No');
        Observer.Expect('e0', 'No');
        Observer.Expect('e1', 'No');
        Observer.Expect('e2', 'No');
        Observer.Expect('t0', 'No');
        Observer.Expect('t1', 'No');
        Observer.Verify();
    end;
}

codeunit 87444 "LT QU Function A"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    var
        Probe: Codeunit "LT QU Probe";

    [Test]
    procedure QU_F01_InsertNoCommit()
    begin
        Probe.InsertNoCommit('F');
    end;

    [Test]
    procedure QU_F02_InsertCommit()
    begin
        Probe.InsertCommit('F');
    end;

    [Test]
    procedure QU_F03_InsertCommitInsert()
    begin
        Probe.InsertCommitInsert('F');
    end;

    [Test]
    procedure QU_F04_NextTestSees()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveEarlierTests('F', Observer);
#if BC28PLUS
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('no_commit_row', 'No');
        Observer.Expect('committed_row', 'No');
        Observer.Expect('committed_before_tail', 'No');
        Observer.Expect('tail_after_commit', 'No');
#else
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('no_commit_row', 'Yes');
        Observer.Expect('committed_row', 'Yes');
        Observer.Expect('committed_before_tail', 'Yes');
        Observer.Expect('tail_after_commit', 'Yes');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure QU_F05_WriteTxAroundCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveWriteTx('F', Observer);
        Observer.Expect('start', 'No');
        Observer.Expect('after_insert', 'Yes');
        Observer.Expect('after_commit', 'No');
        Observer.Expect('row_after_commit', 'Yes');
        Observer.Expect('after_second_insert', 'Yes');
        Observer.Expect('after_second_commit', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QU_F06_CodeunitRunAfterCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCodeunitRun('F', Observer);
        Observer.Expect('open_write_run|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('open_write_run|code', 'DB:Ok');
        Observer.Expect('open_write_r0', 'No');
        Observer.Expect('open_write_r1', 'No');
        Observer.Expect('tx_before_run', 'No');
        Observer.Expect('after_commit_run_ok', 'Yes');
        Observer.Expect('after_commit_run_lasterror', '');
        Observer.Expect('tx_after_run', 'No');
        Observer.Expect('r2', 'Yes');
        Observer.Expect('r3', 'Yes');
        Observer.Expect('duplicate_run_ok', 'No');
        Observer.Expect('duplicate_run_lasterror_code', 'DB:RecordExists');
        Observer.Expect('tx_after_failed_run', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QU_F07_AssertErrorAroundCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveAssertErrorCommit('F', Observer);
        Observer.Expect('error', 'LT QU error after commit');
        Observer.Expect('tx_after', 'No');
        Observer.Expect('before_block', 'Yes');
        Observer.Expect('in_block_before_commit', 'Yes');
        Observer.Expect('in_block_after_commit', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QU_F08_CommitInTryFunction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveTryCommit('F', Observer);
        Observer.Expect('try|text', 'Call to the function ''COMMIT'' is not allowed inside the call to ''QU_F08_CommitInTryFunction'' when it is used as a TryFunction.');
        Observer.Expect('try|code', 'TryFunctionWrite');
        Observer.Expect('ok', 'No');
        Observer.Expect('tx_after', 'No');
        Observer.Expect('committed_before_try', 'Yes');
        Observer.Expect('open_when_try_started', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QU_F09_LaterTestSeesCommittedRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCommittedByEarlierTests('F', Observer);
#if BC28PLUS
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('w1', 'No');
        Observer.Expect('w2', 'No');
        Observer.Expect('r2', 'No');
        Observer.Expect('r3', 'No');
        Observer.Expect('e0', 'No');
        Observer.Expect('e1', 'No');
        Observer.Expect('t0', 'No');
#else
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('w1', 'Yes');
        Observer.Expect('w2', 'Yes');
        Observer.Expect('r2', 'Yes');
        Observer.Expect('r3', 'Yes');
        Observer.Expect('e0', 'Yes');
        Observer.Expect('e1', 'Yes');
        Observer.Expect('t0', 'Yes');
#endif
        Observer.Verify();
    end;
}

codeunit 87445 "LT QU Function B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    [Test]
    procedure QU_F11_NextCodeunitSees()
    var
        Probe: Codeunit "LT QU Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveEarlierCodeunit('F', Observer);
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('nc', 'No');
        Observer.Expect('cm', 'No');
        Observer.Expect('ca', 'No');
        Observer.Expect('cb', 'No');
        Observer.Expect('w1', 'No');
        Observer.Expect('w2', 'No');
        Observer.Expect('r0', 'No');
        Observer.Expect('r2', 'No');
        Observer.Expect('r3', 'No');
        Observer.Expect('e0', 'No');
        Observer.Expect('e1', 'No');
        Observer.Expect('e2', 'No');
        Observer.Expect('t0', 'No');
        Observer.Expect('t1', 'No');
        Observer.Verify();
    end;
}

codeunit 87446 "LT QU Disabled A"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    var
        Probe: Codeunit "LT QU Probe";

    [Test]
    procedure QU_D01_InsertNoCommit()
    begin
        Probe.InsertNoCommit('D');
    end;

    [Test]
    procedure QU_D02_InsertCommit()
    begin
        Probe.InsertCommit('D');
    end;

    [Test]
    procedure QU_D03_InsertCommitInsert()
    begin
        Probe.InsertCommitInsert('D');
    end;

    [Test]
    procedure QU_D04_NextTestSees()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveEarlierTests('D', Observer);
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('no_commit_row', 'Yes');
        Observer.Expect('committed_row', 'Yes');
        Observer.Expect('committed_before_tail', 'Yes');
        Observer.Expect('tail_after_commit', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QU_D05_WriteTxAroundCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveWriteTx('D', Observer);
        Observer.Expect('start', 'No');
        Observer.Expect('after_insert', 'Yes');
        Observer.Expect('after_commit', 'No');
        Observer.Expect('row_after_commit', 'Yes');
        Observer.Expect('after_second_insert', 'Yes');
        Observer.Expect('after_second_commit', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QU_D06_CodeunitRunAfterCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCodeunitRun('D', Observer);
        Observer.Expect('open_write_run|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('open_write_run|code', 'DB:Ok');
        Observer.Expect('open_write_r0', 'No');
        Observer.Expect('open_write_r1', 'No');
        Observer.Expect('tx_before_run', 'No');
        Observer.Expect('after_commit_run_ok', 'Yes');
        Observer.Expect('after_commit_run_lasterror', '');
        Observer.Expect('tx_after_run', 'No');
        Observer.Expect('r2', 'Yes');
        Observer.Expect('r3', 'Yes');
        Observer.Expect('duplicate_run_ok', 'No');
        Observer.Expect('duplicate_run_lasterror_code', 'DB:RecordExists');
        Observer.Expect('tx_after_failed_run', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QU_D07_AssertErrorAroundCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveAssertErrorCommit('D', Observer);
        Observer.Expect('error', 'LT QU error after commit');
        Observer.Expect('tx_after', 'No');
        Observer.Expect('before_block', 'Yes');
        Observer.Expect('in_block_before_commit', 'Yes');
        Observer.Expect('in_block_after_commit', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QU_D08_CommitInTryFunction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveTryCommit('D', Observer);
        Observer.Expect('try|text', 'Call to the function ''COMMIT'' is not allowed inside the call to ''QU_D08_CommitInTryFunction'' when it is used as a TryFunction.');
        Observer.Expect('try|code', 'TryFunctionWrite');
        Observer.Expect('ok', 'No');
        Observer.Expect('tx_after', 'No');
        Observer.Expect('committed_before_try', 'Yes');
        Observer.Expect('open_when_try_started', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QU_D09_LaterTestSeesCommittedRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCommittedByEarlierTests('D', Observer);
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('w1', 'Yes');
        Observer.Expect('w2', 'Yes');
        Observer.Expect('r2', 'Yes');
        Observer.Expect('r3', 'Yes');
        Observer.Expect('e0', 'Yes');
        Observer.Expect('e1', 'Yes');
        Observer.Expect('t0', 'Yes');
        Observer.Verify();
    end;
}

codeunit 87447 "LT QU Disabled B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    [Test]
    procedure QU_D11_NextCodeunitSees()
    var
        Probe: Codeunit "LT QU Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveEarlierCodeunit('D', Observer);
#if BC28PLUS
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('nc', 'Yes');
        Observer.Expect('cm', 'Yes');
        Observer.Expect('ca', 'Yes');
        Observer.Expect('cb', 'Yes');
        Observer.Expect('w1', 'Yes');
        Observer.Expect('w2', 'Yes');
        Observer.Expect('r0', 'No');
        Observer.Expect('r2', 'Yes');
        Observer.Expect('r3', 'Yes');
        Observer.Expect('e0', 'Yes');
        Observer.Expect('e1', 'Yes');
        Observer.Expect('e2', 'No');
        Observer.Expect('t0', 'Yes');
        Observer.Expect('t1', 'No');
#else
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('nc', 'No');
        Observer.Expect('cm', 'No');
        Observer.Expect('ca', 'No');
        Observer.Expect('cb', 'No');
        Observer.Expect('w1', 'No');
        Observer.Expect('w2', 'No');
        Observer.Expect('r0', 'No');
        Observer.Expect('r2', 'No');
        Observer.Expect('r3', 'No');
        Observer.Expect('e0', 'No');
        Observer.Expect('e1', 'No');
        Observer.Expect('e2', 'No');
        Observer.Expect('t0', 'No');
        Observer.Expect('t1', 'No');
#endif
        Observer.Verify();
    end;
}

codeunit 87448 "LT QU NoProperty A"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Probe: Codeunit "LT QU Probe";

    [Test]
    procedure QU_N01_InsertNoCommit()
    begin
        Probe.InsertNoCommit('N');
    end;

    [Test]
    procedure QU_N02_InsertCommit()
    begin
        Probe.InsertCommit('N');
    end;

    [Test]
    procedure QU_N03_InsertCommitInsert()
    begin
        Probe.InsertCommitInsert('N');
    end;

    [Test]
    procedure QU_N04_NextTestSees()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveEarlierTests('N', Observer);
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('no_commit_row', 'Yes');
        Observer.Expect('committed_row', 'Yes');
        Observer.Expect('committed_before_tail', 'Yes');
        Observer.Expect('tail_after_commit', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QU_N05_WriteTxAroundCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveWriteTx('N', Observer);
        Observer.Expect('start', 'No');
        Observer.Expect('after_insert', 'Yes');
        Observer.Expect('after_commit', 'No');
        Observer.Expect('row_after_commit', 'Yes');
        Observer.Expect('after_second_insert', 'Yes');
        Observer.Expect('after_second_commit', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QU_N06_CodeunitRunAfterCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCodeunitRun('N', Observer);
        Observer.Expect('open_write_run|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('open_write_run|code', 'DB:Ok');
        Observer.Expect('open_write_r0', 'No');
        Observer.Expect('open_write_r1', 'No');
        Observer.Expect('tx_before_run', 'No');
        Observer.Expect('after_commit_run_ok', 'Yes');
        Observer.Expect('after_commit_run_lasterror', '');
        Observer.Expect('tx_after_run', 'No');
        Observer.Expect('r2', 'Yes');
        Observer.Expect('r3', 'Yes');
        Observer.Expect('duplicate_run_ok', 'No');
        Observer.Expect('duplicate_run_lasterror_code', 'DB:RecordExists');
        Observer.Expect('tx_after_failed_run', 'No');
        Observer.Verify();
    end;
}

codeunit 87449 "LT QU NoProperty B"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure QU_N11_NextCodeunitSees()
    var
        Probe: Codeunit "LT QU Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveEarlierCodeunit('N', Observer);
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('nc', 'No');
        Observer.Expect('cm', 'No');
        Observer.Expect('ca', 'No');
        Observer.Expect('cb', 'No');
        Observer.Expect('w1', 'No');
        Observer.Expect('w2', 'No');
        Observer.Expect('r0', 'No');
        Observer.Expect('r2', 'No');
        Observer.Expect('r3', 'No');
        Observer.Expect('e0', 'No');
        Observer.Expect('e1', 'No');
        Observer.Expect('e2', 'No');
        Observer.Expect('t0', 'No');
        Observer.Expect('t1', 'No');
        Observer.Verify();
    end;
}
