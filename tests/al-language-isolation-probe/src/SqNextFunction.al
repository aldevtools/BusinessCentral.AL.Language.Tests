namespace ALLanguage.IsolationProbe;

// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/numbersequence/numbersequence-data-type
//   https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-data-type
//   https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: NumberSequence.Next / Restart / Delete / Insert / Exists / Current and IsolatedStorage.Set / Delete / Contains / Get,
// read by the next test of the same test codeunit, under the test runner codeunit with TestIsolation = Function (61300),
// its TestIsolation = Codeunit control (61301) and Microsoft's Test Runner - Isol. Codeunit (130450).
// Fixtures used: none (the helper "LT SQN Seq" is in this file).
// Probe (AL Runner issue 8002, runner-codeunit shape): what a later test of the same test codeunit sees of a number
// sequence or an IsolatedStorage key after an earlier test changed it, when a test runner codeunit with
// TestIsolation = Function runs the tests (the shape of AL Runner's `--isolation test`). The neighbour
// tests/al-language/codeunits/run-onrun/SeqNextHubFunction.al asks the same E and O cells under the TestRunnerHub
// (RequiredTestIsolation = Function, no runner codeunit); its header points to this file for runner 61300.
// Cells: E1-E5 and O1, O2 as in SeqNextHubFunction.al; E6 (a new sequence inserted by the passing test); F1 and F4 (E1 and
// E4 with a failing test a); K1, K2 (IsolatedStorage Set and Delete of a key that existed) and K3 (K1 with a failing test a).
// Each cell is one test codeunit with two tests. Test a changes the sequence or key and passes (fails on purpose in F1, F4,
// K3). Test b reads the state and reports it in its failure message. Readings: onrun = what OnRun found or did ('found',
// 'created', 'recreated', 'absent', 'deleted', 'set'); onrun_calls = how often OnRun ran on this instance; initialized =
// the codeunit's globals survived from test a; a_start, a_changed = the state before and right after test a's step;
// a_taken = the number test a took; b_start = the state test b finds; b_taken = the number Next hands out in test b; b_after
// = the state after that. Sequence numbers are relative to S, the Current value test a found ('cur=S', 'cur=S+1',
// 'missing'); key states are 'v0', 'v1' or 'missing'.
// Observe round: every test b fails on purpose with 'OBSERVE ...'. The cells run only in the Windows nightly (ci.yml's
// Linux legs never compile this app, and observe.sh runs tests through the TestRunnerHub), so the readings come from the
// nightly's per-test rows. A follow-up turns them into assertions, per runner, verbatim.
// Object ids 79350-79363.
// BC versions: the Windows nightly's (28.4 today).

// The sequence and key calls of the cells. Names are fixed per cell.
codeunit 79350 "LT SQN Seq"
{
    // OnRun of an E cell: inserts the sequence when it is missing (Insert(Name, 1, 1), Next twice) and commits.
    procedure Prepare(Name: Text; CompanyWide: Boolean): Text
    begin
        if NumberSequence.Exists(Name, CompanyWide) then
            exit('found');
        NumberSequence.Insert(Name, 1, 1, CompanyWide);
        if NumberSequence.Next(Name, CompanyWide) = 0 then;
        if NumberSequence.Next(Name, CompanyWide) = 0 then;
        Commit();
        exit('created');
    end;

    // OnRun of an O cell: deletes the sequence when it exists and inserts it again (no Commit).
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

    // OnRun of E6: deletes the sequence when it exists and commits, so it is missing when test a begins.
    procedure Absent(Name: Text; CompanyWide: Boolean): Text
    begin
        if not NumberSequence.Exists(Name, CompanyWide) then
            exit('absent');
        NumberSequence.Delete(Name, CompanyWide);
        Commit();
        exit('deleted');
    end;

    // OnRun of a K cell: sets the key to v0 when it is missing or holds another value, and commits.
    procedure PrepareKey(KeyName: Text): Text
    var
        Value: Text;
    begin
        if IsolatedStorage.Contains(KeyName, DataScope::Module) then
            if IsolatedStorage.Get(KeyName, DataScope::Module, Value) then
                if Value = 'v0' then
                    exit('found');
        IsolatedStorage.Set(KeyName, 'v0', DataScope::Module);
        Commit();
        exit('set');
    end;

    procedure RelKey(KeyName: Text): Text
    var
        Value: Text;
    begin
        if not IsolatedStorage.Contains(KeyName, DataScope::Module) then
            exit('missing');
        if not IsolatedStorage.Get(KeyName, DataScope::Module, Value) then
            exit('unreadable');
        exit(Value);
    end;

    procedure CurrentOrZero(Name: Text; CompanyWide: Boolean): BigInteger
    begin
        if NumberSequence.Exists(Name, CompanyWide) then
            exit(NumberSequence.Current(Name, CompanyWide));
        exit(0);
    end;

    procedure Rel(Name: Text; CompanyWide: Boolean; Base: BigInteger): Text
    begin
        if not NumberSequence.Exists(Name, CompanyWide) then
            exit('missing');
        exit('cur=' + Offset(NumberSequence.Current(Name, CompanyWide), Base));
    end;

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

// E1: a sequence that existed when the tests began. E1a: NumberSequence.Next; the test passes.
// E1b: reads the state and reports every reading in its failure message (observe round).
codeunit 79351 "LT SQN E1 Existing Next"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQN Seq";
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
    procedure E1b_ReadsAndReports()
    var
        Readings: Text;
    begin
        Readings := 'onrun=' + OnRunState + '; onrun_calls=' + Format(OnRunCalls) + '; initialized=' + Format(IsInitialized);
        Initialize();
        Error('OBSERVE %1; a_start=%2; a_changed=%3; a_taken=%4%5', Readings, StartA, ChangedA, TakenA,
            '; b_start=' + Seq.Rel(Name(), CompanyWide(), Base) +
            '; b_taken=' + Seq.RelNext(Name(), CompanyWide(), Base) +
            '; b_after=' + Seq.Rel(Name(), CompanyWide(), Base));
    end;

    local procedure Name(): Text
    begin
        exit('LTSQNE1');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes Base; except in the O cells (as in SeqNextHubFunction.al) it first commits what OnRun made.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        Commit();
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        IsInitialized := true;
    end;
}

// E2: as E1, CompanyWide = true. E2a: NumberSequence.Next; the test passes.
// E2b: reads the state and reports every reading in its failure message (observe round).
codeunit 79352 "LT SQN E2 CompanyWide Next"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQN Seq";
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
    procedure E2b_ReadsAndReports()
    var
        Readings: Text;
    begin
        Readings := 'onrun=' + OnRunState + '; onrun_calls=' + Format(OnRunCalls) + '; initialized=' + Format(IsInitialized);
        Initialize();
        Error('OBSERVE %1; a_start=%2; a_changed=%3; a_taken=%4%5', Readings, StartA, ChangedA, TakenA,
            '; b_start=' + Seq.Rel(Name(), CompanyWide(), Base) +
            '; b_taken=' + Seq.RelNext(Name(), CompanyWide(), Base) +
            '; b_after=' + Seq.Rel(Name(), CompanyWide(), Base));
    end;

    local procedure Name(): Text
    begin
        exit('LTSQNE2');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(true);
    end;

    // The first call notes Base; except in the O cells (as in SeqNextHubFunction.al) it first commits what OnRun made.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        Commit();
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        IsInitialized := true;
    end;
}

// E3: as E1. E3a: NumberSequence.Next, then Commit(); the test passes.
// E3b: reads the state and reports every reading in its failure message (observe round).
codeunit 79353 "LT SQN E3 Next Commit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQN Seq";
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
    procedure E3b_ReadsAndReports()
    var
        Readings: Text;
    begin
        Readings := 'onrun=' + OnRunState + '; onrun_calls=' + Format(OnRunCalls) + '; initialized=' + Format(IsInitialized);
        Initialize();
        Error('OBSERVE %1; a_start=%2; a_changed=%3; a_taken=%4%5', Readings, StartA, ChangedA, TakenA,
            '; b_start=' + Seq.Rel(Name(), CompanyWide(), Base) +
            '; b_taken=' + Seq.RelNext(Name(), CompanyWide(), Base) +
            '; b_after=' + Seq.Rel(Name(), CompanyWide(), Base));
    end;

    local procedure Name(): Text
    begin
        exit('LTSQNE3');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes Base; except in the O cells (as in SeqNextHubFunction.al) it first commits what OnRun made.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        Commit();
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        IsInitialized := true;
    end;
}

// E4: as E1. E4a: NumberSequence.Restart(Name, S + 1000); the test passes.
// E4b: reads the state and reports every reading in its failure message (observe round).
codeunit 79354 "LT SQN E4 Existing Restart"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQN Seq";
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
        NumberSequence.Restart(Name(), Base + 1000, CompanyWide());
        ChangedA := Seq.Rel(Name(), CompanyWide(), Base);
    end;

    [Test]
    procedure E4b_ReadsAndReports()
    var
        Readings: Text;
    begin
        Readings := 'onrun=' + OnRunState + '; onrun_calls=' + Format(OnRunCalls) + '; initialized=' + Format(IsInitialized);
        Initialize();
        Error('OBSERVE %1; a_start=%2; a_changed=%3; a_taken=%4%5', Readings, StartA, ChangedA, TakenA,
            '; b_start=' + Seq.Rel(Name(), CompanyWide(), Base) +
            '; b_taken=' + Seq.RelNext(Name(), CompanyWide(), Base) +
            '; b_after=' + Seq.Rel(Name(), CompanyWide(), Base));
    end;

    local procedure Name(): Text
    begin
        exit('LTSQNE4');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes Base; except in the O cells (as in SeqNextHubFunction.al) it first commits what OnRun made.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        Commit();
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        IsInitialized := true;
    end;
}

// E5: as E1. E5a: NumberSequence.Delete; the test passes.
// E5b: reads the state and reports every reading in its failure message (observe round).
codeunit 79355 "LT SQN E5 Existing Delete"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQN Seq";
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
        NumberSequence.Delete(Name(), CompanyWide());
        ChangedA := Seq.Rel(Name(), CompanyWide(), Base);
    end;

    [Test]
    procedure E5b_ReadsAndReports()
    var
        Readings: Text;
    begin
        Readings := 'onrun=' + OnRunState + '; onrun_calls=' + Format(OnRunCalls) + '; initialized=' + Format(IsInitialized);
        Initialize();
        Error('OBSERVE %1; a_start=%2; a_changed=%3; a_taken=%4%5', Readings, StartA, ChangedA, TakenA,
            '; b_start=' + Seq.Rel(Name(), CompanyWide(), Base) +
            '; b_taken=' + Seq.RelNext(Name(), CompanyWide(), Base) +
            '; b_after=' + Seq.Rel(Name(), CompanyWide(), Base));
    end;

    local procedure Name(): Text
    begin
        exit('LTSQNE5');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes Base; except in the O cells (as in SeqNextHubFunction.al) it first commits what OnRun made.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        Commit();
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        IsInitialized := true;
    end;
}

// E6: a sequence that is missing when the tests begin (OnRun deletes it). E6a: NumberSequence.Insert(Name, 1, 1), then Next; the test passes.
// E6b: reads the state and reports every reading in its failure message (observe round).
codeunit 79356 "LT SQN E6 New Insert"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.Absent(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQN Seq";
        IsInitialized: Boolean;
        Base: BigInteger;
        OnRunCalls: Integer;
        OnRunState: Text;
        StartA: Text;
        ChangedA: Text;
        TakenA: Text;

    [Test]
    procedure E6a_ChangesAndPasses()
    begin
        Initialize();
        StartA := Seq.Rel(Name(), CompanyWide(), Base);
        NumberSequence.Insert(Name(), 1, 1, CompanyWide());
        TakenA := Seq.RelNext(Name(), CompanyWide(), Base);
        ChangedA := Seq.Rel(Name(), CompanyWide(), Base);
    end;

    [Test]
    procedure E6b_ReadsAndReports()
    var
        Readings: Text;
    begin
        Readings := 'onrun=' + OnRunState + '; onrun_calls=' + Format(OnRunCalls) + '; initialized=' + Format(IsInitialized);
        Initialize();
        Error('OBSERVE %1; a_start=%2; a_changed=%3; a_taken=%4%5', Readings, StartA, ChangedA, TakenA,
            '; b_start=' + Seq.Rel(Name(), CompanyWide(), Base) +
            '; b_taken=' + Seq.RelNext(Name(), CompanyWide(), Base) +
            '; b_after=' + Seq.Rel(Name(), CompanyWide(), Base));
    end;

    local procedure Name(): Text
    begin
        exit('LTSQNE6');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes Base; except in the O cells (as in SeqNextHubFunction.al) it first commits what OnRun made.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        Commit();
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        IsInitialized := true;
    end;
}

// O1: a sequence created in OnRun (deleted and inserted again). O1a: NumberSequence.Next; the test passes.
// O1b: reads the state and reports every reading in its failure message (observe round).
codeunit 79357 "LT SQN O1 OnRun Next"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.Fresh(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQN Seq";
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
    procedure O1b_ReadsAndReports()
    var
        Readings: Text;
    begin
        Readings := 'onrun=' + OnRunState + '; onrun_calls=' + Format(OnRunCalls) + '; initialized=' + Format(IsInitialized);
        Initialize();
        Error('OBSERVE %1; a_start=%2; a_changed=%3; a_taken=%4%5', Readings, StartA, ChangedA, TakenA,
            '; b_start=' + Seq.Rel(Name(), CompanyWide(), Base) +
            '; b_taken=' + Seq.RelNext(Name(), CompanyWide(), Base) +
            '; b_after=' + Seq.Rel(Name(), CompanyWide(), Base));
    end;

    local procedure Name(): Text
    begin
        exit('LTSQNO1');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes Base; except in the O cells (as in SeqNextHubFunction.al) it first commits what OnRun made.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        IsInitialized := true;
    end;
}

// O2: as O1, CompanyWide = true. O2a: NumberSequence.Next; the test passes.
// O2b: reads the state and reports every reading in its failure message (observe round).
codeunit 79358 "LT SQN O2 OnRun CompanyWide"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.Fresh(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQN Seq";
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
    procedure O2b_ReadsAndReports()
    var
        Readings: Text;
    begin
        Readings := 'onrun=' + OnRunState + '; onrun_calls=' + Format(OnRunCalls) + '; initialized=' + Format(IsInitialized);
        Initialize();
        Error('OBSERVE %1; a_start=%2; a_changed=%3; a_taken=%4%5', Readings, StartA, ChangedA, TakenA,
            '; b_start=' + Seq.Rel(Name(), CompanyWide(), Base) +
            '; b_taken=' + Seq.RelNext(Name(), CompanyWide(), Base) +
            '; b_after=' + Seq.Rel(Name(), CompanyWide(), Base));
    end;

    local procedure Name(): Text
    begin
        exit('LTSQNO2');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(true);
    end;

    // The first call notes Base; except in the O cells (as in SeqNextHubFunction.al) it first commits what OnRun made.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        IsInitialized := true;
    end;
}

// F1: as E1, but test a fails after its Next (Error).
// F1b: reads the state and reports every reading in its failure message (observe round).
codeunit 79359 "LT SQN F1 Next Fails"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQN Seq";
        IsInitialized: Boolean;
        Base: BigInteger;
        OnRunCalls: Integer;
        OnRunState: Text;
        StartA: Text;
        ChangedA: Text;
        TakenA: Text;

    [Test]
    procedure F1a_ChangesAndFails()
    begin
        Initialize();
        StartA := Seq.Rel(Name(), CompanyWide(), Base);
        TakenA := Seq.RelNext(Name(), CompanyWide(), Base);
        ChangedA := Seq.Rel(Name(), CompanyWide(), Base);
        Error('F1a fails on purpose');
    end;

    [Test]
    procedure F1b_ReadsAndReports()
    var
        Readings: Text;
    begin
        Readings := 'onrun=' + OnRunState + '; onrun_calls=' + Format(OnRunCalls) + '; initialized=' + Format(IsInitialized);
        Initialize();
        Error('OBSERVE %1; a_start=%2; a_changed=%3; a_taken=%4%5', Readings, StartA, ChangedA, TakenA,
            '; b_start=' + Seq.Rel(Name(), CompanyWide(), Base) +
            '; b_taken=' + Seq.RelNext(Name(), CompanyWide(), Base) +
            '; b_after=' + Seq.Rel(Name(), CompanyWide(), Base));
    end;

    local procedure Name(): Text
    begin
        exit('LTSQNF1');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes Base; except in the O cells (as in SeqNextHubFunction.al) it first commits what OnRun made.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        Commit();
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        IsInitialized := true;
    end;
}

// F4: as E4, but test a fails after its Restart (Error).
// F4b: reads the state and reports every reading in its failure message (observe round).
codeunit 79360 "LT SQN F4 Restart Fails"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQN Seq";
        IsInitialized: Boolean;
        Base: BigInteger;
        OnRunCalls: Integer;
        OnRunState: Text;
        StartA: Text;
        ChangedA: Text;
        TakenA: Text;

    [Test]
    procedure F4a_ChangesAndFails()
    begin
        Initialize();
        StartA := Seq.Rel(Name(), CompanyWide(), Base);
        NumberSequence.Restart(Name(), Base + 1000, CompanyWide());
        ChangedA := Seq.Rel(Name(), CompanyWide(), Base);
        Error('F4a fails on purpose');
    end;

    [Test]
    procedure F4b_ReadsAndReports()
    var
        Readings: Text;
    begin
        Readings := 'onrun=' + OnRunState + '; onrun_calls=' + Format(OnRunCalls) + '; initialized=' + Format(IsInitialized);
        Initialize();
        Error('OBSERVE %1; a_start=%2; a_changed=%3; a_taken=%4%5', Readings, StartA, ChangedA, TakenA,
            '; b_start=' + Seq.Rel(Name(), CompanyWide(), Base) +
            '; b_taken=' + Seq.RelNext(Name(), CompanyWide(), Base) +
            '; b_after=' + Seq.Rel(Name(), CompanyWide(), Base));
    end;

    local procedure Name(): Text
    begin
        exit('LTSQNF4');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes Base; except in the O cells (as in SeqNextHubFunction.al) it first commits what OnRun made.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        Commit();
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        IsInitialized := true;
    end;
}

// K1: an IsolatedStorage key (DataScope Module) that existed when the tests began, value v0. K1a: IsolatedStorage.Set(Key, v1); the test passes.
// K1b: reads the state and reports every reading in its failure message (observe round).
codeunit 79361 "LT SQN K1 Key Set"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.PrepareKey(KeyName());
    end;

    var
        Seq: Codeunit "LT SQN Seq";
        IsInitialized: Boolean;
        Base: BigInteger;
        OnRunCalls: Integer;
        OnRunState: Text;
        StartA: Text;
        ChangedA: Text;
        TakenA: Text;

    [Test]
    procedure K1a_ChangesAndPasses()
    begin
        Initialize();
        StartA := Seq.RelKey(KeyName());
        IsolatedStorage.Set(KeyName(), 'v1', DataScope::Module);
        ChangedA := Seq.RelKey(KeyName());
    end;

    [Test]
    procedure K1b_ReadsAndReports()
    var
        Readings: Text;
    begin
        Readings := 'onrun=' + OnRunState + '; onrun_calls=' + Format(OnRunCalls) + '; initialized=' + Format(IsInitialized);
        Initialize();
        Error('OBSERVE %1; a_start=%2; a_changed=%3; a_taken=%4%5', Readings, StartA, ChangedA, TakenA,
            '; b_start=' + Seq.RelKey(KeyName()));
    end;

    local procedure KeyName(): Text
    begin
        exit('LTSQNK1');
    end;

    // The first call notes Base; except in the O cells (as in SeqNextHubFunction.al) it first commits what OnRun made.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        Commit();
        IsInitialized := true;
    end;
}

// K2: as K1. K2a: IsolatedStorage.Delete(Key); the test passes.
// K2b: reads the state and reports every reading in its failure message (observe round).
codeunit 79362 "LT SQN K2 Key Delete"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.PrepareKey(KeyName());
    end;

    var
        Seq: Codeunit "LT SQN Seq";
        IsInitialized: Boolean;
        Base: BigInteger;
        OnRunCalls: Integer;
        OnRunState: Text;
        StartA: Text;
        ChangedA: Text;
        TakenA: Text;

    [Test]
    procedure K2a_ChangesAndPasses()
    begin
        Initialize();
        StartA := Seq.RelKey(KeyName());
        if IsolatedStorage.Delete(KeyName(), DataScope::Module) then;
        ChangedA := Seq.RelKey(KeyName());
    end;

    [Test]
    procedure K2b_ReadsAndReports()
    var
        Readings: Text;
    begin
        Readings := 'onrun=' + OnRunState + '; onrun_calls=' + Format(OnRunCalls) + '; initialized=' + Format(IsInitialized);
        Initialize();
        Error('OBSERVE %1; a_start=%2; a_changed=%3; a_taken=%4%5', Readings, StartA, ChangedA, TakenA,
            '; b_start=' + Seq.RelKey(KeyName()));
    end;

    local procedure KeyName(): Text
    begin
        exit('LTSQNK2');
    end;

    // The first call notes Base; except in the O cells (as in SeqNextHubFunction.al) it first commits what OnRun made.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        Commit();
        IsInitialized := true;
    end;
}

// K3: as K1, but test a fails after its Set (Error).
// K3b: reads the state and reports every reading in its failure message (observe round).
codeunit 79363 "LT SQN K3 Key Set Fails"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        OnRunCalls += 1;
        OnRunState := Seq.PrepareKey(KeyName());
    end;

    var
        Seq: Codeunit "LT SQN Seq";
        IsInitialized: Boolean;
        Base: BigInteger;
        OnRunCalls: Integer;
        OnRunState: Text;
        StartA: Text;
        ChangedA: Text;
        TakenA: Text;

    [Test]
    procedure K3a_ChangesAndFails()
    begin
        Initialize();
        StartA := Seq.RelKey(KeyName());
        IsolatedStorage.Set(KeyName(), 'v1', DataScope::Module);
        ChangedA := Seq.RelKey(KeyName());
        Error('K3a fails on purpose');
    end;

    [Test]
    procedure K3b_ReadsAndReports()
    var
        Readings: Text;
    begin
        Readings := 'onrun=' + OnRunState + '; onrun_calls=' + Format(OnRunCalls) + '; initialized=' + Format(IsInitialized);
        Initialize();
        Error('OBSERVE %1; a_start=%2; a_changed=%3; a_taken=%4%5', Readings, StartA, ChangedA, TakenA,
            '; b_start=' + Seq.RelKey(KeyName()));
    end;

    local procedure KeyName(): Text
    begin
        exit('LTSQNK3');
    end;

    // The first call notes Base; except in the O cells (as in SeqNextHubFunction.al) it first commits what OnRun made.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        Commit();
        IsInitialized := true;
    end;
}
