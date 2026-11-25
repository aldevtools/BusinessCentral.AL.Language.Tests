namespace ALLanguage.IsolationProbe;

// Probe (AL Runner issue 8002): what a later test of the same test codeunit sees of a number sequence after an earlier,
// passing test took Next from it (or restarted or deleted it), under TestIsolation = Function (runner 61300), with
// TestIsolation = Codeunit (runner 61301) and Microsoft's Test Runner (130450) as the controls. Two kinds of sequence: one
// that existed when the tests began (E cells) and one created in the test codeunit's OnRun (O cells). Extends
// SqCommitFail.al (B5 and B6: Next of an existing sequence in a test that then fails, read in the next test) and
// IsolProbeAfterRollback.Codeunit.al (a NumberSequence.Insert under Function isolation). Shapes only; no Microsoft code.
//
// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/numbersequence/numbersequence-data-type
//   https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: NumberSequence.Insert / Exists / Current / Next / Restart / Delete, Commit(), TestIsolation = Function and Codeunit.
// Fixtures used: "LT SQN Seq" (76079, below). No SingleInstance codeunit: each cell codeunit reports its own readings in its
// test b (AL Runner issue 8520).
// Each cell is one test codeunit with two tests. Test a changes the sequence and passes; test b reads the state, takes
// Next and reports. Readings of test b: onrun = what OnRun found or did ('found', 'created'); onrun calls = how often OnRun
// ran on this instance; initialized = the codeunit's globals survived from test a; a start = the state test a found;
// a changed = the state right after test a's step; a taken = the number test a took; b start = the state test b finds;
// b taken = the number Next hands out in test b; b after = the state after that. Every number is relative to S, the
// Current value test a found ('S', 'S+1', 'missing'), because the numbers Next hands out stay taken from run to run.
//
// Observe round: test b always fails with 'OBSERVE <cell>: <readings>', under every runner. The expected readings are not
// in this file yet. They come from the nightly's run of this app on real BC (the per-test rows of the three runners), and a
// later commit asserts them as they are printed there. Nothing here is a guess of BC's answer.
//
// What is known so far, and not asserted here: with TestIsolation = Codeunit (runners 61301 and 130450), the numbers Next
// took from a sequence that existed before the codeunit stay taken, also after a failed test and after the end of the
// codeunit (SqCommitFail.al, B5 and B6). Under TestIsolation = Function this is what the cells below measure.

// The sequence calls of the cells. The name is fixed per cell, so a sequence made by an earlier run or a discovery pass is
// found again ('found'). Readings are relative to Base, the Current value test a found.
codeunit 76079 "LT SQN Seq"
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
// OnRun makes the sequence when it is missing (Insert(Name, 1, 1), Next twice), so it exists
// before the tests begin: a discovery pass or an earlier run made it.
// E1a: NumberSequence.Next; the test passes.
// E1b: reads the sequence, takes Next and reports every reading.
codeunit 76082 "LT SQN E1 Existing Next"
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
    procedure E1b_TakesNextAndReports()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | onrun calls=' + Format(OnRunCalls) + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | a start=' + StartA + ' | a changed=' + ChangedA + ' | a taken=' + TakenA;
        Actual += ' | b start=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | b taken=' + Seq.RelNext(Name(), CompanyWide(), Base);
        Actual += ' | b after=' + Seq.Rel(Name(), CompanyWide(), Base);
        // Observe round: the readings are not asserted yet; the failure message carries them.
        Error('OBSERVE %1: %2', 'E1', Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQNE1');
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
// OnRun makes the sequence when it is missing (Insert(Name, 1, 1), Next twice), so it exists
// before the tests begin: a discovery pass or an earlier run made it.
// E2a: NumberSequence.Next (CompanyWide = true); the test passes.
// E2b: reads the sequence, takes Next and reports every reading.
codeunit 76083 "LT SQN E2 Existing CompanyWide"
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
    procedure E2b_TakesNextAndReports()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | onrun calls=' + Format(OnRunCalls) + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | a start=' + StartA + ' | a changed=' + ChangedA + ' | a taken=' + TakenA;
        Actual += ' | b start=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | b taken=' + Seq.RelNext(Name(), CompanyWide(), Base);
        Actual += ' | b after=' + Seq.Rel(Name(), CompanyWide(), Base);
        // Observe round: the readings are not asserted yet; the failure message carries them.
        Error('OBSERVE %1: %2', 'E2', Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQNE2');
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
// OnRun makes the sequence when it is missing (Insert(Name, 1, 1), Next twice), so it exists
// before the tests begin: a discovery pass or an earlier run made it.
// E3a: NumberSequence.Next, then Commit(); the test passes.
// E3b: reads the sequence, takes Next and reports every reading.
codeunit 76084 "LT SQN E3 Existing Next Commit"
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
    procedure E3b_TakesNextAndReports()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | onrun calls=' + Format(OnRunCalls) + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | a start=' + StartA + ' | a changed=' + ChangedA + ' | a taken=' + TakenA;
        Actual += ' | b start=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | b taken=' + Seq.RelNext(Name(), CompanyWide(), Base);
        Actual += ' | b after=' + Seq.Rel(Name(), CompanyWide(), Base);
        // Observe round: the readings are not asserted yet; the failure message carries them.
        Error('OBSERVE %1: %2', 'E3', Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQNE3');
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
// OnRun makes the sequence when it is missing (Insert(Name, 1, 1), Next twice), so it exists
// before the tests begin: a discovery pass or an earlier run made it.
// E4a: NumberSequence.Restart(Name, S + 1000); the test passes.
// E4b: reads the sequence, takes Next and reports every reading.
codeunit 76085 "LT SQN E4 Existing Restart"
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
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedA := Seq.Rel(Name(), CompanyWide(), Base);
    end;

    [Test]
    procedure E4b_TakesNextAndReports()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | onrun calls=' + Format(OnRunCalls) + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | a start=' + StartA + ' | a changed=' + ChangedA + ' | a taken=' + TakenA;
        Actual += ' | b start=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | b taken=' + Seq.RelNext(Name(), CompanyWide(), Base);
        Actual += ' | b after=' + Seq.Rel(Name(), CompanyWide(), Base);
        // Observe round: the readings are not asserted yet; the failure message carries them.
        Error('OBSERVE %1: %2', 'E4', Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQNE4');
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
// OnRun makes the sequence when it is missing (Insert(Name, 1, 1), Next twice), so it exists
// before the tests begin: a discovery pass or an earlier run made it.
// E5a: NumberSequence.Delete; the test passes.
// E5b: reads the sequence, takes Next and reports every reading.
codeunit 76086 "LT SQN E5 Existing Delete"
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
        Seq.DeleteIfExists(Name(), CompanyWide());
        ChangedA := Seq.Rel(Name(), CompanyWide(), Base);
    end;

    [Test]
    procedure E5b_TakesNextAndReports()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | onrun calls=' + Format(OnRunCalls) + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | a start=' + StartA + ' | a changed=' + ChangedA + ' | a taken=' + TakenA;
        Actual += ' | b start=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | b taken=' + Seq.RelNext(Name(), CompanyWide(), Base);
        Actual += ' | b after=' + Seq.Rel(Name(), CompanyWide(), Base);
        // Observe round: the readings are not asserted yet; the failure message carries them.
        Error('OBSERVE %1: %2', 'E5', Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQNE5');
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
// OnRun deletes the sequence when it exists and inserts it again (Insert(Name, 1, 1)): it is
// created in OnRun of the run.
// O1a: NumberSequence.Next; the test passes.
// O1b: reads the sequence, takes Next and reports every reading.
codeunit 76087 "LT SQN O1 OnRun Next"
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
    procedure O1b_TakesNextAndReports()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | onrun calls=' + Format(OnRunCalls) + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | a start=' + StartA + ' | a changed=' + ChangedA + ' | a taken=' + TakenA;
        Actual += ' | b start=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | b taken=' + Seq.RelNext(Name(), CompanyWide(), Base);
        Actual += ' | b after=' + Seq.Rel(Name(), CompanyWide(), Base);
        // Observe round: the readings are not asserted yet; the failure message carries them.
        Error('OBSERVE %1: %2', 'O1', Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQNO1');
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
// OnRun deletes the sequence when it exists and inserts it again (Insert(Name, 1, 1)): it is
// created in OnRun of the run.
// O2a: NumberSequence.Next (CompanyWide = true); the test passes.
// O2b: reads the sequence, takes Next and reports every reading.
codeunit 76088 "LT SQN O2 OnRun CompanyWide"
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
    procedure O2b_TakesNextAndReports()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | onrun calls=' + Format(OnRunCalls) + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | a start=' + StartA + ' | a changed=' + ChangedA + ' | a taken=' + TakenA;
        Actual += ' | b start=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | b taken=' + Seq.RelNext(Name(), CompanyWide(), Base);
        Actual += ' | b after=' + Seq.Rel(Name(), CompanyWide(), Base);
        // Observe round: the readings are not asserted yet; the failure message carries them.
        Error('OBSERVE %1: %2', 'O2', Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQNO2');
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
