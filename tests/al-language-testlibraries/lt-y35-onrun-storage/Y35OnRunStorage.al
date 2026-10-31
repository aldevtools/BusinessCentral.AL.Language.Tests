// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-data-type
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/numbersequence/numbersequence-data-type
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; Microsoft's Test Runner 130450 (Tests-TestLibraries job)
// Probe (gap cycle 3, C3-01): what later test codeunits see of isolated storage and number sequences that an earlier test
//   codeunit changed, in its OnRun trigger or in a test, under "Test Runner - Isol. Codeunit" (130450).
//   The neighbour for table rows is tests/al-language/codeunit/lt-qu-commit-isolation/RqIsolationModes.al (RQ_WF11, RQ_C11).
// Lever: every test of the 130450 group (A0, A1, B1, A2, B2) has [HandlerFunctions] and uses the handler, so on BC 28 and later the
//   Linux legs run these codeunits under 130450 and not through the TestRunnerHub (see RqIsolationModes.al). The pair A6/B6 has no
//   handler functions and TestPermissions = Disabled, so on BC 28 and later the hub runs it (RequiredTestIsolation = Codeunit); on
//   BC 27 every codeunit runs under 130450.
// Run order is by codeunit id: A0 81566 < A1 81567 < B1 81568 < A2 81569 < B2 81578 (< A6 81579 < B6 81586 on BC 27).
// Keys: prefix C301 (A1's OnRun writes), C302 (A2's test writes), C306 (A6's OnRun writes, hub). A0's OnRun deletes every key and
//   sequence first, so a rerun reads the same. Every storage call is in codeunit 81574, so the module is the same for all codeunits.
// Writes(P), in this order: set P-MOD-CM / P-COM-CM / P-USR-CM / P-CAU-CM (scopes Module, Company, User, CompanyAndUser); insert
//   sequence P-SEQ-CM (seed 100) and take Next twice; insert company-wide sequence P-SEQ-CW (seed 200) and take Next once; Next of
//   P-SEQ-OLD-N (made by A0); Commit; then, left open: set P-MOD-OPEN, insert P-SEQ-OPEN (seed 10) and take Next once, delete
//   P-MOD-DEL (stored by A0). P-SEQ-OLD-R (made by A0) is left alone: see Suspect_RestartInTestCodeunit.
// Linux suspect (not asserted, procedure Suspect_RestartInTestCodeunit in A1): NumberSequence.Restart of a sequence, in OnRun or in a
//   test of a codeunit run by 130450 (and by the hub), ends the session at the end of the codeunit with "An unexpected error occurred
//   after a database command was cancelled." (SQL: "Cannot roll back 4. No transaction or savepoint of that name was found.");
//   the codeunit gives no result. Seen on the Linux containers 27.5, 28.5, 29.0; to be checked on Windows.
// BC versions: 27.5, 28.5, 29.0

codeunit 81574 "LT Y35 Probe Store"
{
    procedure SetStore(K: Text; V: Text; Scope: DataScope)
    begin
        if IsolatedStorage.Contains(K, Scope) then
            IsolatedStorage.Delete(K, Scope);
        IsolatedStorage.Set(K, V, Scope);
    end;

    procedure GetStore(K: Text; Scope: DataScope): Text
    var
        V: Text;
    begin
        if not IsolatedStorage.Contains(K, Scope) then
            exit('missing');
        if not IsolatedStorage.Get(K, Scope, V) then
            exit('contains, get false');
        exit('found/' + V);
    end;

    procedure DeleteStore(K: Text; Scope: DataScope)
    begin
        if IsolatedStorage.Contains(K, Scope) then
            IsolatedStorage.Delete(K, Scope);
    end;

    procedure SeqDelete(N: Text; CompanyWide: Boolean)
    begin
        if NumberSequence.Exists(N, CompanyWide) then
            NumberSequence.Delete(N, CompanyWide);
    end;

    procedure SeqCurrent(N: Text; CompanyWide: Boolean): Text
    begin
        if not NumberSequence.Exists(N, CompanyWide) then
            exit('missing');
        exit(Format(NumberSequence.Current(N, CompanyWide)));
    end;

    [TryFunction]
    procedure TrySeqInsert(N: Text; Seed: BigInteger; CompanyWide: Boolean)
    begin
        NumberSequence.Insert(N, Seed, 1, CompanyWide);
    end;

    [TryFunction]
    procedure TrySeqNext(N: Text; CompanyWide: Boolean; var Value: BigInteger)
    begin
        Value := NumberSequence.Next(N, CompanyWide);
    end;

    [TryFunction]
    procedure TrySeqRestart(N: Text; Seed: BigInteger)
    begin
        NumberSequence.Restart(N, Seed);
    end;

    [TryFunction]
    procedure TryDeleteStore(K: Text; Scope: DataScope)
    begin
        IsolatedStorage.Delete(K, Scope);
    end;

    // Deletes every key and sequence of prefix P.
    procedure Reset(P: Text)
    begin
        DeleteStore(P + '-MOD-CM', DataScope::Module);
        DeleteStore(P + '-COM-CM', DataScope::Company);
        DeleteStore(P + '-USR-CM', DataScope::User);
        DeleteStore(P + '-CAU-CM', DataScope::CompanyAndUser);
        DeleteStore(P + '-MOD-OPEN', DataScope::Module);
        DeleteStore(P + '-MOD-DEL', DataScope::Module);
        DeleteStore(P + '-B-OWN', DataScope::Module);
        SeqDelete(P + '-SEQ-CM', false);
        SeqDelete(P + '-SEQ-CW', true);
        SeqDelete(P + '-SEQ-OLD-R', false);
        SeqDelete(P + '-SEQ-OLD-N', false);
        SeqDelete(P + '-SEQ-OPEN', false);
    end;

    // The older state Writes(P) changes: a key it deletes and two sequences it restarts and moves on. Commits.
    procedure Prepare(P: Text): Text
    var
        Log: Text;
        V: BigInteger;
    begin
        SetStore(P + '-MOD-DEL', 'old', DataScope::Module);
        Log += Step('insert-old-r', TrySeqInsert(P + '-SEQ-OLD-R', 0, false));
        Log += Step('insert-old-n', TrySeqInsert(P + '-SEQ-OLD-N', 0, false));
        if TrySeqNext(P + '-SEQ-OLD-N', false, V) then
            Log += 'next-old-n=' + Format(V) + ';'
        else
            Log += Step('next-old-n', false);
        Commit();
        exit(Log);
    end;

    procedure Writes(P: Text): Text
    var
        Log: Text;
    begin
        SetStore(P + '-MOD-CM', 'committed', DataScope::Module);
        SetStore(P + '-COM-CM', 'committed', DataScope::Company);
        SetStore(P + '-USR-CM', 'committed', DataScope::User);
        SetStore(P + '-CAU-CM', 'committed', DataScope::CompanyAndUser);
        Log += Step('insert-cm', TrySeqInsert(P + '-SEQ-CM', 100, false));
        Log += NextStep('next-cm', P + '-SEQ-CM', false);
        Log += NextStep('next-cm', P + '-SEQ-CM', false);
        Log += Step('insert-cw', TrySeqInsert(P + '-SEQ-CW', 200, true));
        Log += NextStep('next-cw', P + '-SEQ-CW', true);
        Log += NextStep('next-old-n', P + '-SEQ-OLD-N', false);
        Commit();
        SetStore(P + '-MOD-OPEN', 'open', DataScope::Module);
        Log += Step('insert-open', TrySeqInsert(P + '-SEQ-OPEN', 10, false));
        Log += NextStep('next-open', P + '-SEQ-OPEN', false);
        Log += Step('delete-del', TryDeleteStore(P + '-MOD-DEL', DataScope::Module));
        exit(Log);
    end;

    local procedure Step(Name: Text; Ok: Boolean): Text
    begin
        if Ok then
            exit(Name + '=ok;');
        exit(Name + '=failed(' + GetLastErrorCode() + ': ' + GetLastErrorText() + ');');
    end;

    local procedure NextStep(Name: Text; N: Text; CompanyWide: Boolean): Text
    var
        V: BigInteger;
    begin
        if TrySeqNext(N, CompanyWide, V) then
            exit(Name + '=' + Format(V) + ';');
        exit(Step(Name, false));
    end;

    procedure ObserveStorage(var Observer: Codeunit "Probe Observer"; P: Text; Prefix: Text)
    begin
        Observer.Observe(Prefix + 'mod_cm', GetStore(P + '-MOD-CM', DataScope::Module));
        Observer.Observe(Prefix + 'com_cm', GetStore(P + '-COM-CM', DataScope::Company));
        Observer.Observe(Prefix + 'usr_cm', GetStore(P + '-USR-CM', DataScope::User));
        Observer.Observe(Prefix + 'cau_cm', GetStore(P + '-CAU-CM', DataScope::CompanyAndUser));
    end;

    // Takes Next of P-SEQ-CM and P-SEQ-OLD-R when they exist (a write).
    procedure ObserveSequences(var Observer: Codeunit "Probe Observer"; P: Text; Prefix: Text)
    begin
        Observer.Observe(Prefix + 'seq_cm_current', SeqCurrent(P + '-SEQ-CM', false));
        ObserveNext(Observer, P + '-SEQ-CM', Prefix + 'seq_cm_next');
        Observer.Observe(Prefix + 'seq_cw_current', SeqCurrent(P + '-SEQ-CW', true));
        Observer.Observe(Prefix + 'seq_old_r_current', SeqCurrent(P + '-SEQ-OLD-R', false));
        ObserveNext(Observer, P + '-SEQ-OLD-R', Prefix + 'seq_old_r_next');
        Observer.Observe(Prefix + 'seq_old_n_current', SeqCurrent(P + '-SEQ-OLD-N', false));
    end;

    procedure ObserveOpen(var Observer: Codeunit "Probe Observer"; P: Text; Prefix: Text)
    begin
        Observer.Observe(Prefix + 'mod_open', GetStore(P + '-MOD-OPEN', DataScope::Module));
        Observer.Observe(Prefix + 'seq_open_current', SeqCurrent(P + '-SEQ-OPEN', false));
        Observer.Observe(Prefix + 'mod_del', GetStore(P + '-MOD-DEL', DataScope::Module));
    end;

    local procedure ObserveNext(var Observer: Codeunit "Probe Observer"; N: Text; Name: Text)
    var
        V: BigInteger;
    begin
        if not NumberSequence.Exists(N) then
            Observer.Observe(Name, 'missing')
        else
            if TrySeqNext(N, false, V) then
                Observer.Observe(Name, Format(V))
            else
                Observer.ObserveError(Name);
    end;

    // A write of the reading codeunit itself, after the carry: set and read back a new key.
    procedure OwnWrite(P: Text): Text
    begin
        SetStore(P + '-B-OWN', 'b', DataScope::Module);
        exit(GetStore(P + '-B-OWN', DataScope::Module));
    end;
}

// A0: prepares the older state in OnRun (committed) and checks it in its test.
codeunit 81566 "LT Y35 A0 Prepare"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Store: Codeunit "LT Y35 Probe Store";
        OnRunLog: Text;

    trigger OnRun()
    begin
        Store.Reset('C301');
        Store.Reset('C302');
        OnRunLog := 'C301:' + Store.Prepare('C301') + ' C302:' + Store.Prepare('C302');
    end;

    [Test]
    [HandlerFunctions('Y35MsgHandler')]
    procedure C301_A0_Prepared()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('x');
        Observer.Observe('onrun_log', OnRunLog);
        Observer.Observe('c301_mod_del', Store.GetStore('C301-MOD-DEL', DataScope::Module));
        Observer.Observe('c301_seq_old_r_current', Store.SeqCurrent('C301-SEQ-OLD-R', false));
        Observer.Observe('c301_seq_old_n_current', Store.SeqCurrent('C301-SEQ-OLD-N', false));
        Observer.Observe('c302_mod_del', Store.GetStore('C302-MOD-DEL', DataScope::Module));
        Observer.Observe('c302_seq_old_r_current', Store.SeqCurrent('C302-SEQ-OLD-R', false));
        Observer.Observe('c302_seq_old_n_current', Store.SeqCurrent('C302-SEQ-OLD-N', false));
        Observer.Finish();
    end;

    [MessageHandler]
    procedure Y35MsgHandler(Msg: Text)
    begin
    end;
}

// A1: OnRun makes the C301 writes (committed and open); its test sees them (T5).
codeunit 81567 "LT Y35 A1 OnRun Writes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Store: Codeunit "LT Y35 Probe Store";
        OnRunLog: Text;

    trigger OnRun()
    begin
        OnRunLog := Store.Writes('C301');
    end;

    // Linux suspect (see the header): not a test. Called from OnRun before Writes it ended the session at the codeunit end.
    procedure Suspect_RestartInTestCodeunit(): Boolean
    begin
        exit(Store.TrySeqRestart('C301-SEQ-OLD-R', 500));
    end;

    [Test]
    [HandlerFunctions('Y35MsgHandler')]
    procedure C301_A1_SeesOwnOnRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('x');
        Observer.Observe('onrun_log', OnRunLog);
        Observer.Observe('in_write_transaction', Format(Database.IsInWriteTransaction()));
        Store.ObserveStorage(Observer, 'C301', '');
        Store.ObserveOpen(Observer, 'C301', '');
        Observer.Observe('seq_cm_current', Store.SeqCurrent('C301-SEQ-CM', false));
        Observer.Observe('seq_cw_current', Store.SeqCurrent('C301-SEQ-CW', true));
        Observer.Observe('seq_old_r_current', Store.SeqCurrent('C301-SEQ-OLD-R', false));
        Observer.Observe('seq_old_n_current', Store.SeqCurrent('C301-SEQ-OLD-N', false));
        Observer.Finish();
    end;

    [MessageHandler]
    procedure Y35MsgHandler(Msg: Text)
    begin
    end;
}

// B1: the next codeunit after A1 reads what A1's OnRun left (T1, T2, T3).
codeunit 81568 "LT Y35 B1 Reads OnRun"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Store: Codeunit "LT Y35 Probe Store";

    [Test]
    [HandlerFunctions('Y35MsgHandler')]
    procedure C301_B1_OnRunCommittedStorage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('x');
        Store.ObserveStorage(Observer, 'C301', '');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('Y35MsgHandler')]
    procedure C301_B1_OnRunSequences()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('x');
        Store.ObserveSequences(Observer, 'C301', '');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('Y35MsgHandler')]
    procedure C301_B1_OnRunOpenWrites()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('x');
        Store.ObserveOpen(Observer, 'C301', '');
        Observer.Observe('own_write', Store.OwnWrite('C301'));
        Observer.Finish();
    end;

    [MessageHandler]
    procedure Y35MsgHandler(Msg: Text)
    begin
    end;
}

// A2: a TEST (not OnRun) makes the C302 writes (committed and open).
codeunit 81569 "LT Y35 A2 Test Writes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Store: Codeunit "LT Y35 Probe Store";

    [Test]
    [HandlerFunctions('Y35MsgHandler')]
    procedure C302_A2_TestWrites()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('x');
        Observer.Observe('log', Store.Writes('C302'));
        Store.ObserveStorage(Observer, 'C302', '');
        Store.ObserveOpen(Observer, 'C302', '');
        Observer.Finish();
    end;

    [MessageHandler]
    procedure Y35MsgHandler(Msg: Text)
    begin
    end;
}

// B2: the next codeunit after A2 reads what A2's test left (T4).
codeunit 81578 "LT Y35 B2 Reads Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Store: Codeunit "LT Y35 Probe Store";

    [Test]
    [HandlerFunctions('Y35MsgHandler')]
    procedure C302_B2_TestWritesStorage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('x');
        Store.ObserveStorage(Observer, 'C302', 't_');
        Store.ObserveOpen(Observer, 'C302', 't_');
        Observer.Observe('t_seq_cm_current', Store.SeqCurrent('C302-SEQ-CM', false));
        Observer.Observe('t_seq_cw_current', Store.SeqCurrent('C302-SEQ-CW', true));
        Observer.Observe('t_seq_old_r_current', Store.SeqCurrent('C302-SEQ-OLD-R', false));
        Observer.Observe('t_seq_old_n_current', Store.SeqCurrent('C302-SEQ-OLD-N', false));
        Observer.Finish();
    end;

    [MessageHandler]
    procedure Y35MsgHandler(Msg: Text)
    begin
    end;
}

// A6 (T6): the same OnRun writes (prefix C306) in a codeunit the BC 28+ hub runs (no handler functions, TestPermissions = Disabled,
// RequiredTestIsolation = Codeunit). OnRun prepares its own older state first: the hub leg runs before A0.
codeunit 81579 "LT Y35 A6 Hub OnRun"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Store: Codeunit "LT Y35 Probe Store";
        OnRunLog: Text;

    trigger OnRun()
    begin
        Store.Reset('C306');
        OnRunLog := Store.Prepare('C306') + Store.Writes('C306');
    end;

    [Test]
    procedure C306_A6_SeesOwnOnRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('onrun_log', OnRunLog);
        Store.ObserveStorage(Observer, 'C306', '');
        Store.ObserveOpen(Observer, 'C306', '');
        Observer.Finish();
    end;
}

codeunit 81586 "LT Y35 B6 Hub Reads"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Store: Codeunit "LT Y35 Probe Store";

    [Test]
    procedure C306_B6_OnRunStorage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Store.ObserveStorage(Observer, 'C306', '');
        Store.ObserveOpen(Observer, 'C306', '');
        Observer.Finish();
    end;

    [Test]
    procedure C306_B6_OnRunSequences()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Store.ObserveSequences(Observer, 'C306', '');
        Observer.Finish();
    end;
}
