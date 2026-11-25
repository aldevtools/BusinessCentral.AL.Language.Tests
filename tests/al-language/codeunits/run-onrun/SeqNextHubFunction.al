// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/numbersequence/numbersequence-data-type
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-requiredtestisolation-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (AL Runner issue 8002), observe round: what a later test of the same test codeunit sees of a number sequence after an
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
// difference of the test harness, not of the platform; the asserting commit guards it with BC28PLUS.
//
// Each cell is one test codeunit with two tests. Test a changes the sequence and passes; test b reads the state, takes Next and
// observes. Observations of test b: onrun = what OnRun found or did ('found', 'created', 'recreated'); onrun_calls = how often
// OnRun ran on this instance; initialized = the codeunit's globals survived from test a; a_start = the state test a found;
// a_changed = the state right after test a's step; a_taken = the number test a took; b_start = the state test b finds; b_taken =
// the number Next hands out in test b; b_after = the state after that. Every number is relative to S, the Current value test a
// found ('cur=S', 'S+1', 'missing'), because the numbers Next hands out need not start at the seed.
//
// Observe round: test b ends with Observer.Finish(), so it fails with 'OBSERVE:' and the readings, on every leg. Nothing is
// asserted yet. A later commit turns each Finish() into Expect and Verify with the values this pull request's own CI printed
// (convert.py), per BC version. Nothing here is a guess of BC's answer.
// Object ids 73330-73337.
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
