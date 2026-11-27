// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/numbersequence/numbersequence-data-type
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-requiredtestisolation-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (AL Runner issue 8002): what a later test of the same test codeunit sees of a number sequence after an
// earlier, passing test took Next from it (or restarted or deleted it), under the TestRunnerHub's Function isolation
// (RequiredTestIsolation = Function). A neighbour of the isolation probe app's SqNextFunction.al, which asks the same seven cells
// under the test runner codeunit with TestIsolation = Function (61300); this file asks them where the PR legs can run them.
// Two kinds of sequence: one that existed when the tests began (E cells, made by OnRun when missing) and one created in the
// test codeunit's OnRun (O cells). Neighbours in this folder: SeqCarry.al (Restart and Delete under 130450, read by the later
// codeunits) and QuCommitIsolation.al / RqIsolationModes.al (rows under the hub's Function isolation).
//
// Harness (see QuCommitIsolation.al and RqIsolationModes.al): on BC 28 and later the Linux legs run a test codeunit without
// [HandlerFunctions], with TestPermissions = Disabled and without asserterror next to a NumberSequence call through the
// service tier's TestRunnerHub, which takes the isolation from RequiredTestIsolation. Every codeunit here has that shape, so
// the 28.5 and 29.0 legs run it under Function isolation. BC 27.5 has no TestRunnerHub: its legs run these codeunits under
// "Test Runner - Isol. Codeunit" (130450, TestIsolation = Codeunit), which takes no account of RequiredTestIsolation, so the
// 27.5 readings are those of Codeunit isolation (the control of SqNextFunction.al). A difference between 27.5 and 28.5+ is a
// difference of the test harness, not of the platform; the BC28PLUS guards below mark it.
//
// Each cell is one test codeunit with two tests. Test a changes the sequence and passes; test b reads the state, takes Next and
// observes. Observations of test b: onrun = what OnRun found or did ('found', 'created', 'recreated'); onrun_calls = how often
// OnRun ran on this instance; initialized = the codeunit's globals survived from test a; a_start = the state test a found;
// a_changed = the state right after test a's step; a_taken = the number test a took; b_start = the state test b finds; b_taken =
// the number Next hands out in test b; b_after = the state after that. Every number is relative to S, the Current value test a
// found ('cur=S', 'S+1', 'missing'), because the numbers Next hands out need not start at the seed.
//
// The expected values are the readings this pull request's own CI printed in its observe round (test b ended with
// Observer.Finish()), turned into Expect and Verify by convert.py per BC version, verbatim. 28.5 and 29.0 (the hub's Function
// isolation) gave the same readings; 27.5 (130450, the Codeunit control) differs in every cell, so each asserted cell had a
// BC28PLUS guard. Since the third fix below, E2, E3 and E1C read the same on every version and have no guard.
// Measured on the CI legs 27.5, 28.5 and 29.0 (Linux):
//   - Every cell: OnRun ran once on the instance (onrun_calls 1) and the codeunit's globals survived test a (initialized Yes),
//     under both runners.
//   - 28.5 and 29.0, the hub's Function isolation: OnRun created every sequence ('created'). Test a's Next stays taken in the
//     next test: E2 (CompanyWide = true) and E3 (Next, then Commit) read cur=S+1 and Next gives S+2; O1 and O2 (created in
//     OnRun) give S+1 in test b, after test a took S. Test a's Restart (E4) and Delete (E5) are undone: test b reads cur=S and
//     Next gives S+1. E1 (CompanyWide = false, Next) reads 'missing' in test b: the sequence OnRun created is gone. E1 was the
//     first codeunit the hub ran in both legs (only these codeunits and the leg's sentinel ran); E1C below measures that
//     position.
//   - E1 is not asserted: its reading may depend on the hub's run order (the maintainer's decision on al-runner 8002). Its
//     readings are still observed and ignored on every version (Observer.Ignore), so the test passes.
//   - E1C (73338): a copy of E1 with its own sequence ('LTSQHE1C'), the last codeunit of this file, so it runs after 73331.
//     It reads like E2 on every leg: test a takes S+1, test b reads cur=S+1 and Next gives S+2 (OnRun 'created' on 28.5 and
//     29.0, 'found' on 27.5, the only guarded reading). So E1's 'missing' on 28.5 and 29.0 is not a property of the shape of
//     al-runner issue 8002: it goes with E1's position as the first codeunit the hub ran. E1C passes only while it is not
//     the first codeunit the hub runs: today 73331 is always selected with it, and the shard boundaries keep 73331-73338
//     together, so whoever re-plans the shards or runs 73338 alone should know.
//   - 27.5, the Codeunit control: OnRun found every E sequence already there ('found') and recreated every O sequence
//     ('recreated'), with onrun_calls 1: something on that leg made them before this instance's OnRun (see the next
//     point). Test b sees every change of test a: the taken numbers (E1, E2, E3: cur=S+1, Next S+2; O1, O2: Next S+1),
//     the restart (E4: cur=S+1000, Next S+1000) and the delete (E5: missing).
//   - Why 27.5 finds them (source of Microsoft's Test Runner 27.5): that leg fills its suite through the Linux harness's
//     Test Runner Extension, which runs codeunit 130452 "Test Runner - Get Methods" on each test codeunit; its OnRun calls
//     CODEUNIT.Run on the test codeunit and its OnBeforeTestRun returns true for 'OnRun' (TestRunnerGetMethods.Codeunit.al,
//     lines 28 and 38-39), and 130452 sets no TestIsolation, so the test codeunit's OnRun makes the sequences outside any
//     isolation before the run.
// Run order (issue 1595): without the Commit() at the end of Prepare, the sequence OnRun made was sometimes gone in test b
// ('missing', E1 always when it ran first; E1C, E4 and E5 now and then on the 29.0 leg, depending on the shard order), so a
// cell's b_start depended on which codeunit the hub ran before it. Prepare commits the new sequence now, so every E cell
// starts from a committed sequence whatever ran before it; the isolation then undoes only test a's own changes.
// Second fix (E4b flaked on 28.5 after the Commit above: b_start was 'missing'): every E cell also commits in Initialize, at the
// start of test a, so the sequence is committed whichever way OnRun reached it (made or found). No expected value changed.
// Third fix (issue 1614; runs 45977641511 and 45980581207, BC 28.5 only): E2b and O1b still read b_start 'missing' now and
// then, although test a had read the sequence and E2 commits in Prepare and in Initialize. On the 28.5 hub, the rollback
// at the end of test a sometimes also undoes the sequence made during the run (in OnRun), Commit or not; the cells before
// the failing one passed in the same run, and no other file uses these names, so it is not the run order. So:
//   - E cells: install code (73339) makes their sequences when the app is installed, outside any test isolation, so they
//     exist when the tests begin and no test rollback can undo them. OnRun now finds them ('found') on every version.
//     Measured on a local BC 27.5 before this commit: every E cell read 'found' (that host's harness is not
//     the Linux legs', so its b readings are not used).
//     The onrun Expect is now 'found' without a version guard, and the CI legs check it.
//   - O cells: their shape is a sequence created in OnRun, so install code cannot help. On 28 and later, b_start, b_taken
//     and b_after are observed and not asserted (Observer.Ignore): the hub does not give one reading for them.
// Object ids 73330-73339.
// BC versions: 27.5, 28.5, 29.0

// The sequence calls of the cells. The name is fixed per cell, so a sequence made by an earlier run is found again ('found').
codeunit 73330 "LT SQH Seq"
{
    // OnRun of an E cell: makes the sequence when it is missing. Returns 'found' or 'created'.
    procedure Prepare(Name: Text; CompanyWide: Boolean): Text
    begin
        if NumberSequence.Exists(Name, CompanyWide) then
            exit('found');
        NumberSequence.Insert(Name, 1, 1, CompanyWide);
        if NumberSequence.Next(Name, CompanyWide) = 0 then;
        if NumberSequence.Next(Name, CompanyWide) = 0 then;
        // Commit the new sequence, so it exists before test a on every run order (issue 1595).
        Commit();
        exit('created');
    end;

    // OnRun of an O cell: deletes the sequence when it exists and inserts it again. Returns 'recreated' or 'created'.
    procedure Fresh(Name: Text; CompanyWide: Boolean): Text
    var
        Result: Text;
    begin
        Result := 'created';
        if NumberSequence.Exists(Name, CompanyWide) then begin
            NumberSequence.Delete(Name, CompanyWide);
            Result := 'recreated';
        end;
        NumberSequence.Insert(Name, 1, 1, CompanyWide);
        exit(Result);
    end;

    procedure RestartTo(Name: Text; CompanyWide: Boolean; Value: BigInteger)
    begin
        if NumberSequence.Exists(Name, CompanyWide) then
            NumberSequence.Restart(Name, Value, CompanyWide);
    end;

    procedure DeleteIfExists(Name: Text; CompanyWide: Boolean)
    begin
        if NumberSequence.Exists(Name, CompanyWide) then
            NumberSequence.Delete(Name, CompanyWide);
    end;

    procedure CurrentOrZero(Name: Text; CompanyWide: Boolean): BigInteger
    begin
        if NumberSequence.Exists(Name, CompanyWide) then
            exit(NumberSequence.Current(Name, CompanyWide));
        exit(0);
    end;

    // 'missing', or 'cur=' and the Current value relative to Base ('cur=S', 'cur=S+1').
    procedure Rel(Name: Text; CompanyWide: Boolean; Base: BigInteger): Text
    begin
        if not NumberSequence.Exists(Name, CompanyWide) then
            exit('missing');
        exit('cur=' + Offset(NumberSequence.Current(Name, CompanyWide), Base));
    end;

    // 'missing', or what Next returns, relative to Base.
    procedure RelNext(Name: Text; CompanyWide: Boolean; Base: BigInteger): Text
    begin
        if not NumberSequence.Exists(Name, CompanyWide) then
            exit('missing');
        exit(Offset(NumberSequence.Next(Name, CompanyWide), Base));
    end;

    procedure Offset(Value: BigInteger; Base: BigInteger): Text
    begin
        if Value = Base then
            exit('S');
        if Value > Base then
            exit('S+' + Format(Value - Base));
        exit('S-' + Format(Base - Value));
    end;
}

// E1: a sequence that existed when the tests began.
// OnRun makes the sequence when it is missing (Insert(Name, 1, 1), Next twice), so it exists before test a begins.
// E1a: NumberSequence.Next; the test passes.
// E1b: reads the sequence, takes Next and observes every reading.
codeunit 73331 "LT SQH E1 Existing Next"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQH Seq";
        IsInitialized: Boolean;
        Base: BigInteger;
        OnRunCalls: Integer;
        OnRunState: Text;
        StartA: Text;
        ChangedA: Text;
        TakenA: Text;

    [Test]
    procedure E1a_ChangesAndPasses()
    begin
        Initialize();
        StartA := Seq.Rel(Name(), CompanyWide(), Base);
        TakenA := Seq.RelNext(Name(), CompanyWide(), Base);
        ChangedA := Seq.Rel(Name(), CompanyWide(), Base);
    end;

    [Test]
    procedure E1b_TakesNextAndObserves()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('onrun', OnRunState);
        Observer.Observe('onrun_calls', Format(OnRunCalls));
        Observer.Observe('initialized', Format(IsInitialized));
        Initialize();
        Observer.Observe('a_start', StartA);
        Observer.Observe('a_changed', ChangedA);
        Observer.Observe('a_taken', TakenA);
        Observer.Observe('b_start', Seq.Rel(Name(), CompanyWide(), Base));
        Observer.Observe('b_taken', Seq.RelNext(Name(), CompanyWide(), Base));
        Observer.Observe('b_after', Seq.Rel(Name(), CompanyWide(), Base));
        // Not asserted: E1's reading may depend on the hub's run order (see the header).
        Observer.Ignore('onrun');
        Observer.Ignore('onrun_calls');
        Observer.Ignore('initialized');
        Observer.Ignore('a_start');
        Observer.Ignore('a_changed');
        Observer.Ignore('a_taken');
        Observer.Ignore('b_start');
        Observer.Ignore('b_taken');
        Observer.Ignore('b_after');
        Observer.Verify();
    end;

    local procedure Name(): Text
    begin
        exit('LTSQHE1');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes Base, the Current value test a found; later calls do nothing.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        // Commit what OnRun made, before test a changes anything, so the isolation rolls back only test a (issue 1595, run 45767499284).
        Commit();
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        IsInitialized := true;
    end;
}

// E2: a sequence that existed when the tests began, CompanyWide = true.
// OnRun makes the sequence when it is missing (Insert(Name, 1, 1), Next twice), so it exists before test a begins.
// E2a: NumberSequence.Next (CompanyWide = true); the test passes.
// E2b: reads the sequence, takes Next and observes every reading.
codeunit 73332 "LT SQH E2 Existing CompanyWide"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQH Seq";
        IsInitialized: Boolean;
        Base: BigInteger;
        OnRunCalls: Integer;
        OnRunState: Text;
        StartA: Text;
        ChangedA: Text;
        TakenA: Text;

    [Test]
    procedure E2a_ChangesAndPasses()
    begin
        Initialize();
        StartA := Seq.Rel(Name(), CompanyWide(), Base);
        TakenA := Seq.RelNext(Name(), CompanyWide(), Base);
        ChangedA := Seq.Rel(Name(), CompanyWide(), Base);
    end;

    [Test]
    procedure E2b_TakesNextAndObserves()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('onrun', OnRunState);
        Observer.Observe('onrun_calls', Format(OnRunCalls));
        Observer.Observe('initialized', Format(IsInitialized));
        Initialize();
        Observer.Observe('a_start', StartA);
        Observer.Observe('a_changed', ChangedA);
        Observer.Observe('a_taken', TakenA);
        Observer.Observe('b_start', Seq.Rel(Name(), CompanyWide(), Base));
        Observer.Observe('b_taken', Seq.RelNext(Name(), CompanyWide(), Base));
        Observer.Observe('b_after', Seq.Rel(Name(), CompanyWide(), Base));
        Observer.Expect('onrun', 'found');
        Observer.Expect('onrun_calls', '1');
        Observer.Expect('initialized', 'Yes');
        Observer.Expect('a_start', 'cur=S');
        Observer.Expect('a_changed', 'cur=S+1');
        Observer.Expect('a_taken', 'S+1');
        Observer.Expect('b_start', 'cur=S+1');
        Observer.Expect('b_taken', 'S+2');
        Observer.Expect('b_after', 'cur=S+2');
        Observer.Verify();
    end;

    local procedure Name(): Text
    begin
        exit('LTSQHE2');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(true);
    end;

    // The first call notes Base, the Current value test a found; later calls do nothing.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        // Commit what OnRun made, before test a changes anything, so the isolation rolls back only test a (issue 1595, run 45767499284).
        Commit();
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        IsInitialized := true;
    end;
}

// E3: a sequence that existed when the tests began.
// OnRun makes the sequence when it is missing (Insert(Name, 1, 1), Next twice), so it exists before test a begins.
// E3a: NumberSequence.Next, then Commit(); the test passes.
// E3b: reads the sequence, takes Next and observes every reading.
codeunit 73333 "LT SQH E3 Existing Next Commit"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQH Seq";
        IsInitialized: Boolean;
        Base: BigInteger;
        OnRunCalls: Integer;
        OnRunState: Text;
        StartA: Text;
        ChangedA: Text;
        TakenA: Text;

    [Test]
    procedure E3a_ChangesAndPasses()
    begin
        Initialize();
        StartA := Seq.Rel(Name(), CompanyWide(), Base);
        TakenA := Seq.RelNext(Name(), CompanyWide(), Base);
        Commit();
        ChangedA := Seq.Rel(Name(), CompanyWide(), Base);
    end;

    [Test]
    procedure E3b_TakesNextAndObserves()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('onrun', OnRunState);
        Observer.Observe('onrun_calls', Format(OnRunCalls));
        Observer.Observe('initialized', Format(IsInitialized));
        Initialize();
        Observer.Observe('a_start', StartA);
        Observer.Observe('a_changed', ChangedA);
        Observer.Observe('a_taken', TakenA);
        Observer.Observe('b_start', Seq.Rel(Name(), CompanyWide(), Base));
        Observer.Observe('b_taken', Seq.RelNext(Name(), CompanyWide(), Base));
        Observer.Observe('b_after', Seq.Rel(Name(), CompanyWide(), Base));
        Observer.Expect('onrun', 'found');
        Observer.Expect('onrun_calls', '1');
        Observer.Expect('initialized', 'Yes');
        Observer.Expect('a_start', 'cur=S');
        Observer.Expect('a_changed', 'cur=S+1');
        Observer.Expect('a_taken', 'S+1');
        Observer.Expect('b_start', 'cur=S+1');
        Observer.Expect('b_taken', 'S+2');
        Observer.Expect('b_after', 'cur=S+2');
        Observer.Verify();
    end;

    local procedure Name(): Text
    begin
        exit('LTSQHE3');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes Base, the Current value test a found; later calls do nothing.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        // Commit what OnRun made, before test a changes anything, so the isolation rolls back only test a (issue 1595, run 45767499284).
        Commit();
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        IsInitialized := true;
    end;
}

// E4: a sequence that existed when the tests began.
// OnRun makes the sequence when it is missing (Insert(Name, 1, 1), Next twice), so it exists before test a begins.
// E4a: NumberSequence.Restart(Name, S + 1000); the test passes.
// E4b: reads the sequence, takes Next and observes every reading.
codeunit 73334 "LT SQH E4 Existing Restart"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQH Seq";
        IsInitialized: Boolean;
        Base: BigInteger;
        OnRunCalls: Integer;
        OnRunState: Text;
        StartA: Text;
        ChangedA: Text;
        TakenA: Text;

    [Test]
    procedure E4a_ChangesAndPasses()
    begin
        Initialize();
        StartA := Seq.Rel(Name(), CompanyWide(), Base);
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedA := Seq.Rel(Name(), CompanyWide(), Base);
    end;

    [Test]
    procedure E4b_TakesNextAndObserves()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('onrun', OnRunState);
        Observer.Observe('onrun_calls', Format(OnRunCalls));
        Observer.Observe('initialized', Format(IsInitialized));
        Initialize();
        Observer.Observe('a_start', StartA);
        Observer.Observe('a_changed', ChangedA);
        Observer.Observe('a_taken', TakenA);
        Observer.Observe('b_start', Seq.Rel(Name(), CompanyWide(), Base));
        Observer.Observe('b_taken', Seq.RelNext(Name(), CompanyWide(), Base));
        Observer.Observe('b_after', Seq.Rel(Name(), CompanyWide(), Base));
        Observer.Expect('onrun', 'found');
        Observer.Expect('onrun_calls', '1');
        Observer.Expect('initialized', 'Yes');
        Observer.Expect('a_start', 'cur=S');
        Observer.Expect('a_changed', 'cur=S+1000');
        Observer.Expect('a_taken', '');
#if BC28PLUS
        Observer.Expect('b_start', 'cur=S');
        Observer.Expect('b_taken', 'S+1');
        Observer.Expect('b_after', 'cur=S+1');
#else
        Observer.Expect('b_start', 'cur=S+1000');
        Observer.Expect('b_taken', 'S+1000');
        Observer.Expect('b_after', 'cur=S+1000');
#endif
        Observer.Verify();
    end;

    local procedure Name(): Text
    begin
        exit('LTSQHE4');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes Base, the Current value test a found; later calls do nothing.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        // Commit what OnRun made, before test a changes anything, so the isolation rolls back only test a (issue 1595, run 45767499284).
        Commit();
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        IsInitialized := true;
    end;
}

// E5: a sequence that existed when the tests began.
// OnRun makes the sequence when it is missing (Insert(Name, 1, 1), Next twice), so it exists before test a begins.
// E5a: NumberSequence.Delete; the test passes.
// E5b: reads the sequence, takes Next and observes every reading.
codeunit 73335 "LT SQH E5 Existing Delete"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQH Seq";
        IsInitialized: Boolean;
        Base: BigInteger;
        OnRunCalls: Integer;
        OnRunState: Text;
        StartA: Text;
        ChangedA: Text;
        TakenA: Text;

    [Test]
    procedure E5a_ChangesAndPasses()
    begin
        Initialize();
        StartA := Seq.Rel(Name(), CompanyWide(), Base);
        Seq.DeleteIfExists(Name(), CompanyWide());
        ChangedA := Seq.Rel(Name(), CompanyWide(), Base);
    end;

    [Test]
    procedure E5b_TakesNextAndObserves()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('onrun', OnRunState);
        Observer.Observe('onrun_calls', Format(OnRunCalls));
        Observer.Observe('initialized', Format(IsInitialized));
        Initialize();
        Observer.Observe('a_start', StartA);
        Observer.Observe('a_changed', ChangedA);
        Observer.Observe('a_taken', TakenA);
        Observer.Observe('b_start', Seq.Rel(Name(), CompanyWide(), Base));
        Observer.Observe('b_taken', Seq.RelNext(Name(), CompanyWide(), Base));
        Observer.Observe('b_after', Seq.Rel(Name(), CompanyWide(), Base));
        Observer.Expect('onrun', 'found');
        Observer.Expect('onrun_calls', '1');
        Observer.Expect('initialized', 'Yes');
        Observer.Expect('a_start', 'cur=S');
        Observer.Expect('a_changed', 'missing');
        Observer.Expect('a_taken', '');
#if BC28PLUS
        Observer.Expect('b_start', 'cur=S');
        Observer.Expect('b_taken', 'S+1');
        Observer.Expect('b_after', 'cur=S+1');
#else
        Observer.Expect('b_start', 'missing');
        Observer.Expect('b_taken', 'missing');
        Observer.Expect('b_after', 'missing');
#endif
        Observer.Verify();
    end;

    local procedure Name(): Text
    begin
        exit('LTSQHE5');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes Base, the Current value test a found; later calls do nothing.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        // Commit what OnRun made, before test a changes anything, so the isolation rolls back only test a (issue 1595, run 45767499284).
        Commit();
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        IsInitialized := true;
    end;
}

// O1: a sequence created in OnRun.
// OnRun deletes the sequence when it exists and inserts it again (Insert(Name, 1, 1)): it is created in OnRun of the run.
// O1a: NumberSequence.Next; the test passes.
// O1b: reads the sequence, takes Next and observes every reading.
codeunit 73336 "LT SQH O1 OnRun Next"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.Fresh(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQH Seq";
        IsInitialized: Boolean;
        Base: BigInteger;
        OnRunCalls: Integer;
        OnRunState: Text;
        StartA: Text;
        ChangedA: Text;
        TakenA: Text;

    [Test]
    procedure O1a_ChangesAndPasses()
    begin
        Initialize();
        StartA := Seq.Rel(Name(), CompanyWide(), Base);
        TakenA := Seq.RelNext(Name(), CompanyWide(), Base);
        ChangedA := Seq.Rel(Name(), CompanyWide(), Base);
    end;

    [Test]
    procedure O1b_TakesNextAndObserves()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('onrun', OnRunState);
        Observer.Observe('onrun_calls', Format(OnRunCalls));
        Observer.Observe('initialized', Format(IsInitialized));
        Initialize();
        Observer.Observe('a_start', StartA);
        Observer.Observe('a_changed', ChangedA);
        Observer.Observe('a_taken', TakenA);
        Observer.Observe('b_start', Seq.Rel(Name(), CompanyWide(), Base));
        Observer.Observe('b_taken', Seq.RelNext(Name(), CompanyWide(), Base));
        Observer.Observe('b_after', Seq.Rel(Name(), CompanyWide(), Base));
#if BC28PLUS
        Observer.Expect('onrun', 'created');
#else
        Observer.Expect('onrun', 'recreated');
#endif
        Observer.Expect('onrun_calls', '1');
        Observer.Expect('initialized', 'Yes');
        Observer.Expect('a_start', 'cur=S');
        Observer.Expect('a_changed', 'cur=S');
        Observer.Expect('a_taken', 'S');
#if BC28PLUS
        // Not asserted on 28+: the hub's Function isolation sometimes also rolls back the sequence OnRun created (see the header).
        Observer.Ignore('b_start');
        Observer.Ignore('b_taken');
        Observer.Ignore('b_after');
#else
        Observer.Expect('b_start', 'cur=S');
        Observer.Expect('b_taken', 'S+1');
        Observer.Expect('b_after', 'cur=S+1');
#endif
        Observer.Verify();
    end;

    local procedure Name(): Text
    begin
        exit('LTSQHO1');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes Base, the Current value test a found; later calls do nothing.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        IsInitialized := true;
    end;
}

// O2: a sequence created in OnRun, CompanyWide = true.
// OnRun deletes the sequence when it exists and inserts it again (Insert(Name, 1, 1)): it is created in OnRun of the run.
// O2a: NumberSequence.Next (CompanyWide = true); the test passes.
// O2b: reads the sequence, takes Next and observes every reading.
codeunit 73337 "LT SQH O2 OnRun CompanyWide"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.Fresh(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQH Seq";
        IsInitialized: Boolean;
        Base: BigInteger;
        OnRunCalls: Integer;
        OnRunState: Text;
        StartA: Text;
        ChangedA: Text;
        TakenA: Text;

    [Test]
    procedure O2a_ChangesAndPasses()
    begin
        Initialize();
        StartA := Seq.Rel(Name(), CompanyWide(), Base);
        TakenA := Seq.RelNext(Name(), CompanyWide(), Base);
        ChangedA := Seq.Rel(Name(), CompanyWide(), Base);
    end;

    [Test]
    procedure O2b_TakesNextAndObserves()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('onrun', OnRunState);
        Observer.Observe('onrun_calls', Format(OnRunCalls));
        Observer.Observe('initialized', Format(IsInitialized));
        Initialize();
        Observer.Observe('a_start', StartA);
        Observer.Observe('a_changed', ChangedA);
        Observer.Observe('a_taken', TakenA);
        Observer.Observe('b_start', Seq.Rel(Name(), CompanyWide(), Base));
        Observer.Observe('b_taken', Seq.RelNext(Name(), CompanyWide(), Base));
        Observer.Observe('b_after', Seq.Rel(Name(), CompanyWide(), Base));
#if BC28PLUS
        Observer.Expect('onrun', 'created');
#else
        Observer.Expect('onrun', 'recreated');
#endif
        Observer.Expect('onrun_calls', '1');
        Observer.Expect('initialized', 'Yes');
        Observer.Expect('a_start', 'cur=S');
        Observer.Expect('a_changed', 'cur=S');
        Observer.Expect('a_taken', 'S');
#if BC28PLUS
        // Not asserted on 28+: the hub's Function isolation sometimes also rolls back the sequence OnRun created (see the header).
        Observer.Ignore('b_start');
        Observer.Ignore('b_taken');
        Observer.Ignore('b_after');
#else
        Observer.Expect('b_start', 'cur=S');
        Observer.Expect('b_taken', 'S+1');
        Observer.Expect('b_after', 'cur=S+1');
#endif
        Observer.Verify();
    end;

    local procedure Name(): Text
    begin
        exit('LTSQHO2');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(true);
    end;

    // The first call notes Base, the Current value test a found; later calls do nothing.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        IsInitialized := true;
    end;
}

// E1C: a copy of E1 (the shape of al-runner issue 8002) with its own sequence, the last codeunit of this file, so the hub runs
// it after E1 to O2.
// OnRun makes the sequence when it is missing (Insert(Name, 1, 1), Next twice), so it exists before test a begins.
// E1Ca: NumberSequence.Next; the test passes.
// E1Cb: reads the sequence, takes Next and observes every reading.
codeunit 73338 "LT SQH E1C Existing Next Late"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQH Seq";
        IsInitialized: Boolean;
        Base: BigInteger;
        OnRunCalls: Integer;
        OnRunState: Text;
        StartA: Text;
        ChangedA: Text;
        TakenA: Text;

    [Test]
    procedure E1Ca_ChangesAndPasses()
    begin
        Initialize();
        StartA := Seq.Rel(Name(), CompanyWide(), Base);
        TakenA := Seq.RelNext(Name(), CompanyWide(), Base);
        ChangedA := Seq.Rel(Name(), CompanyWide(), Base);
    end;

    [Test]
    procedure E1Cb_TakesNextAndObserves()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('onrun', OnRunState);
        Observer.Observe('onrun_calls', Format(OnRunCalls));
        Observer.Observe('initialized', Format(IsInitialized));
        Initialize();
        Observer.Observe('a_start', StartA);
        Observer.Observe('a_changed', ChangedA);
        Observer.Observe('a_taken', TakenA);
        Observer.Observe('b_start', Seq.Rel(Name(), CompanyWide(), Base));
        Observer.Observe('b_taken', Seq.RelNext(Name(), CompanyWide(), Base));
        Observer.Observe('b_after', Seq.Rel(Name(), CompanyWide(), Base));
        Observer.Expect('onrun', 'found');
        Observer.Expect('onrun_calls', '1');
        Observer.Expect('initialized', 'Yes');
        Observer.Expect('a_start', 'cur=S');
        Observer.Expect('a_changed', 'cur=S+1');
        Observer.Expect('a_taken', 'S+1');
        Observer.Expect('b_start', 'cur=S+1');
        Observer.Expect('b_taken', 'S+2');
        Observer.Expect('b_after', 'cur=S+2');
        Observer.Verify();
    end;

    local procedure Name(): Text
    begin
        exit('LTSQHE1C');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes Base, the Current value test a found; later calls do nothing.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        // Commit what OnRun made, before test a changes anything, so the isolation rolls back only test a (issue 1595, run 45767499284).
        Commit();
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        IsInitialized := true;
    end;
}

// Install code (issue 1614): makes the E cells' sequences when the app is installed, outside any test isolation, so a
// test rollback cannot undo them. Same state as Prepare (Insert(Name, 1, 1), Next twice). Each one runs only when
// NumberSequence.Exists says it is missing, so Insert cannot meet an existing name. No TryFunction: the first local
// observe of the TryFunction form hung at the app install on two backends.
codeunit 73339 "LT SQH Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        Make('LTSQHE1', false);
        Make('LTSQHE2', true);
        Make('LTSQHE3', false);
        Make('LTSQHE4', false);
        Make('LTSQHE5', false);
        Make('LTSQHE1C', false);
    end;

    local procedure Make(Name: Text; CompanyWide: Boolean)
    begin
        if NumberSequence.Exists(Name, CompanyWide) then
            exit;
        NumberSequence.Insert(Name, 1, 1, CompanyWide);
        if NumberSequence.Next(Name, CompanyWide) = 0 then;
        if NumberSequence.Next(Name, CompanyWide) = 0 then;
    end;
}
