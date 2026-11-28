namespace ALLanguage.IsolationProbe;

// Probe: a number sequence that existed when a test codeunit's tests began, after a test that restarted or deleted it
// and then failed (AL Runner issue 8972; the shape of Microsoft's Tests-SCM codeunit 137302, where the posting in
// InventoryValuationWIPReport restarts the existing Item Ledger Entry sequence). Extends SqCommitFail.al: B1-B4 there are
// the same steps with no table access. Shapes only; no Microsoft code.
//
// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/numbersequence/numbersequence-data-type
// Scope: NumberSequence.Restart / Delete / Insert / Next / Exists / Current of an existing sequence, Commit(), asserterror,
// a failed test, TestIsolation = Codeunit.
// Fixtures used: SqExistingRestartFixture.al ("LT SQE Row", "LT SQE Entry", "LT SQE Seq", "LT SQE Access", "LT SQE Poster").
// Each cell is one test codeunit. OnRun makes the cell's sequence when it is missing (Insert(Name, 1, 1), Next twice), so
// it exists before the tests begin; the name is fixed per cell. Test a notes the start state, deletes the rows of earlier
// cells, writes the INIT row and commits. Test b changes the sequence and fails on purpose (RN, RE4, RE5, DN and SN are
// controls in which b passes). Test c reads the state and asserts it in the same codeunit (no SingleInstance log, AL
// Runner issue 8520).
// Readings of test c: onrun = what OnRun of the measured run found ('found': the discovery pass made the sequence, so it
// existed before the run); initialized = the codeunit's globals survived; start = the state test a found; changed = the
// state right after test b's step (it proves the step ran; in the S cells it names the helper's branch: restart or
// insert); taken = the number test b took; name (and preview) = the state after the failed test; rows = keys of
// "LT SQE Row"; entries = Entry Nos. of "LT SQE Entry"; next = the number Next hands out then; name after = state after
// that. Every number is relative to S, the Current value test a found, because numbers taken with Next stay taken from
// run to run.
// Probe: written against BC 29.0 (the Linux container of the corpus CI), runners 130450 (Microsoft's Test Runner - Isol.
// Codeunit) and 61301 (TestIsolation = Codeunit): the same readings under both, and the same on a second run. BC 27.5,
// 28.5 and the Windows containers are measured by the Windows nightly only.
//
// What BC does:
// - A Restart or Delete of the existing sequence stays after the failed test when no table was read or written between
//   the last real commit and the failure: RA and DA (no access at all), RO (RecordRef Open and Close only), RC and DC
//   (the step, a write, Commit(), then a write: the step stays, the write after the Commit() is gone), RC3 and DC3 (no
//   access after the Commit()), RC5 (only a read after the Commit()), RP2 and DP2 (an earlier passing test made the step,
//   wrote a row and committed).
// - It is undone (the sequence is back at S, or there again at S) when the failed test read or wrote a table after the
//   last real commit: RB, RB2, DB, DB2 (a write after or before the step), RR, DR (a read), RC4, DC4 (the step after the
//   Commit()), RP, DP (the step in an earlier passing test with no Commit()), RW (CompanyWide sequence), DI (Delete, then
//   Insert with another start: back to the old sequence at S).
// - A Commit() with no table access since the previous commit does not make the step stay: RC2, DC2 (undone after the
//   write that follows).
// - asserterror after a write undoes the step at once, also in a test that passes: RE, DE, RE5 (control, test passes:
//   undone), RE2 (asserterror of a write that raises). asserterror with no write since the last commit keeps it: RE3, RE4.
// - Next is never undone: XN (the number taken in the failed test stays taken).
// - SCM shape (S cells): the helper calls NumberSequence as Sequence No. Mgt. does. An entry S + 5 written without the
//   sequence makes the helper restart both the sequence and 'Preview' + Name, hand out S + 6 and insert that entry. The
//   restart stays after a failure after the Commit() (SA reads, SC no access, SE a write: entries before the Commit()
//   stay, the write after it is gone), and after a Commit() inside Codeunit.Run of a posting codeunit (SD). Before any
//   Commit() the restart of both sequences and both entries are gone (SB).
// - Not measured: what a later test codeunit sees (SqCommitFail.al: Restart and Delete are undone at the end of the
//   codeunit), TestIsolation = Function (runner 61300; the nightly records it).

// RA: Restart, then the test fails with no table access after the last transaction end.
// RAa: Initialize only (records the start state).
// RAb: NumberSequence.Restart(Name, S + 1000), then fails.
// RAc: reads the sequence and the tables and asserts them.
codeunit 79310 "LT SQE RA"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure RAa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RAb_FailsOnPurpose()
    begin
        Initialize();
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Error('RAb fails on purpose');
    end;

    [Test]
    procedure RAc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S+1000 | rows=INIT | next=S+1000 | name after=cur=S+1000' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERA');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RA';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RB: Restart, then a Record insert, then the test fails.
// RBa: Initialize only (records the start state).
// RBb: NumberSequence.Restart(Name, S + 1000), Record insert B1, then fails.
// RBc: reads the sequence and the tables and asserts them.
codeunit 79311 "LT SQE RB"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure RBa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RBb_FailsOnPurpose()
    begin
        Initialize();
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('B1');
        Error('RBb fails on purpose');
    end;

    [Test]
    procedure RBc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S | rows=INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERB');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RB';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RB2: Record insert, then Restart, then the test fails.
// RB2a: Initialize only (records the start state).
// RB2b: Record insert B1, NumberSequence.Restart(Name, S + 1000), then fails.
// RB2c: reads the sequence and the tables and asserts them.
codeunit 79312 "LT SQE RB2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure RB2a_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RB2b_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Error('RB2b fails on purpose');
    end;

    [Test]
    procedure RB2c_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S | rows=INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERB2');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RB2';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RR: Restart, then a Record read, then the test fails.
// RRa: Initialize only (records the start state).
// RRb: NumberSequence.Restart(Name, S + 1000), a Record FindFirst, then fails.
// RRc: reads the sequence and the tables and asserts them.
codeunit 79313 "LT SQE RR"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure RRa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RRb_FailsOnPurpose()
    begin
        Initialize();
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.PlainRead();
        Error('RRb fails on purpose');
    end;

    [Test]
    procedure RRc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S | rows=INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERR');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RR';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RO: Restart, then RecordRef Open and Close only, then the test fails.
// ROa: Initialize only (records the start state).
// ROb: NumberSequence.Restart(Name, S + 1000), RecordRef.Open and Close on the real table, nothing read, then fails.
// ROc: reads the sequence and the tables and asserts them.
codeunit 79314 "LT SQE RO"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure ROa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure ROb_FailsOnPurpose()
    begin
        Initialize();
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.RefOpenClose();
        Error('ROb fails on purpose');
    end;

    [Test]
    procedure ROc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S+1000 | rows=INIT | next=S+1000 | name after=cur=S+1000' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERO');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RO';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RC: Restart, Record insert, Commit, Record insert, then the test fails.
// RCa: Initialize only (records the start state).
// RCb: NumberSequence.Restart(Name, S + 1000), Record insert B1, Commit(), Record insert B2, then fails.
// RCc: reads the sequence and the tables and asserts them.
codeunit 79315 "LT SQE RC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure RCa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RCb_FailsOnPurpose()
    begin
        Initialize();
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('B1');
        Commit();
        Access.InsertRow('B2');
        Error('RCb fails on purpose');
    end;

    [Test]
    procedure RCc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S+1000 | rows=B1,INIT | next=S+1000 | name after=cur=S+1000' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERC');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RC';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RC2: Restart, Commit with no table access before it, Record insert, then the test fails.
// RC2a: Initialize only (records the start state).
// RC2b: NumberSequence.Restart(Name, S + 1000), Commit(), Record insert B2, then fails.
// RC2c: reads the sequence and the tables and asserts them.
codeunit 79316 "LT SQE RC2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure RC2a_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RC2b_FailsOnPurpose()
    begin
        Initialize();
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Commit();
        Access.InsertRow('B2');
        Error('RC2b fails on purpose');
    end;

    [Test]
    procedure RC2c_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S | rows=INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERC2');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RC2';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RC3: Restart, Record insert, Commit, then the test fails with no table access after the Commit.
// RC3a: Initialize only (records the start state).
// RC3b: NumberSequence.Restart(Name, S + 1000), Record insert B1, Commit(), then fails.
// RC3c: reads the sequence and the tables and asserts them.
codeunit 79317 "LT SQE RC3"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure RC3a_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RC3b_FailsOnPurpose()
    begin
        Initialize();
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('B1');
        Commit();
        Error('RC3b fails on purpose');
    end;

    [Test]
    procedure RC3c_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S+1000 | rows=B1,INIT | next=S+1000 | name after=cur=S+1000' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERC3');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RC3';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RC4: Record insert, Commit, Restart, Record insert, then the test fails (Restart after the last Commit).
// RC4a: Initialize only (records the start state).
// RC4b: Record insert B1, Commit(), NumberSequence.Restart(Name, S + 1000), Record insert B2, then fails.
// RC4c: reads the sequence and the tables and asserts them.
codeunit 79318 "LT SQE RC4"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure RC4a_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RC4b_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Commit();
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('B2');
        Error('RC4b fails on purpose');
    end;

    [Test]
    procedure RC4c_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S | rows=B1,INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERC4');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RC4';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RC5: Restart, Record insert, Commit, Record read, then the test fails.
// RC5a: Initialize only (records the start state).
// RC5b: NumberSequence.Restart(Name, S + 1000), Record insert B1, Commit(), a Record FindFirst, then fails.
// RC5c: reads the sequence and the tables and asserts them.
codeunit 79319 "LT SQE RC5"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure RC5a_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RC5b_FailsOnPurpose()
    begin
        Initialize();
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('B1');
        Commit();
        Access.PlainRead();
        Error('RC5b fails on purpose');
    end;

    [Test]
    procedure RC5c_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S+1000 | rows=B1,INIT | next=S+1000 | name after=cur=S+1000' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERC5');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RC5';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RE: Restart, Record insert, asserterror, then the test fails.
// REa: Initialize only (records the start state).
// REb: NumberSequence.Restart(Name, S + 1000), Record insert B1, asserterror of an Error() with no write inside, then fails.
// REc: reads the sequence and the tables and asserts them.
codeunit 79320 "LT SQE RE"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure REa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure REb_FailsOnPurpose()
    begin
        Initialize();
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('B1');
        asserterror Error('inner error');
        Error('REb fails on purpose');
    end;

    [Test]
    procedure REc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S | rows=INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERE');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RE';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RE2: Restart, asserterror of a Record insert that raises, then the test fails.
// RE2a: Initialize only (records the start state).
// RE2b: NumberSequence.Restart(Name, S + 1000), asserterror of a Record insert AE that then raises, then fails.
// RE2c: reads the sequence and the tables and asserts them.
codeunit 79321 "LT SQE RE2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure RE2a_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RE2b_FailsOnPurpose()
    begin
        Initialize();
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        asserterror Access.InsertRowThenError('AE');
        Error('RE2b fails on purpose');
    end;

    [Test]
    procedure RE2c_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S | rows=INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERE2');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RE2';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RE3: Restart, asserterror of an Error() with no write, then the test fails.
// RE3a: Initialize only (records the start state).
// RE3b: NumberSequence.Restart(Name, S + 1000), asserterror of an Error() with no write inside, then fails.
// RE3c: reads the sequence and the tables and asserts them.
codeunit 79322 "LT SQE RE3"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure RE3a_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RE3b_FailsOnPurpose()
    begin
        Initialize();
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        asserterror Error('inner error');
        Error('RE3b fails on purpose');
    end;

    [Test]
    procedure RE3c_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S+1000 | rows=INIT | next=S+1000 | name after=cur=S+1000' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERE3');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RE3';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RE4: Control: Restart, asserterror of an Error() with no write, and the test passes.
// RE4a: Initialize only (records the start state).
// RE4b: NumberSequence.Restart(Name, S + 1000), asserterror of an Error() with no write inside.
// RE4c: reads the sequence and the tables and asserts them.
codeunit 79323 "LT SQE RE4"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure RE4a_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RE4b_Passes()
    begin
        Initialize();
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        asserterror Error('inner error');
    end;

    [Test]
    procedure RE4c_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S+1000 | rows=INIT | next=S+1000 | name after=cur=S+1000' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERE4');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RE4';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RE5: Control: Restart, Record insert, asserterror of an Error() with no write, and the test passes.
// RE5a: Initialize only (records the start state).
// RE5b: NumberSequence.Restart(Name, S + 1000), Record insert B1, asserterror of an Error() with no write inside.
// RE5c: reads the sequence and the tables and asserts them.
codeunit 79324 "LT SQE RE5"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure RE5a_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RE5b_Passes()
    begin
        Initialize();
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('B1');
        asserterror Error('inner error');
    end;

    [Test]
    procedure RE5c_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S | rows=INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERE5');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RE5';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RP: An earlier passing test restarts (no Commit); the failed test inserts a Record.
// RPa: Initialize only (records the start state).
// RPa2: NumberSequence.Restart(Name, S + 1000).
// RPb: Record insert B1, then fails.
// RPc: reads the sequence and the tables and asserts them.
codeunit 79325 "LT SQE RP"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure RPa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RPa2_EarlierChanges()
    begin
        Initialize();
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
    end;

    [Test]
    procedure RPb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Error('RPb fails on purpose');
    end;

    [Test]
    procedure RPc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S | rows=INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERP');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RP';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RP2: An earlier passing test restarts, inserts a Record and commits; the failed test inserts a Record.
// RP2a: Initialize only (records the start state).
// RP2a2: NumberSequence.Restart(Name, S + 1000), Record insert A2, Commit().
// RP2b: Record insert B1, then fails.
// RP2c: reads the sequence and the tables and asserts them.
codeunit 79326 "LT SQE RP2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure RP2a_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RP2a2_EarlierChanges()
    begin
        Initialize();
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('A2');
        Commit();
    end;

    [Test]
    procedure RP2b_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Error('RP2b fails on purpose');
    end;

    [Test]
    procedure RP2c_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S+1000 | rows=A2,INIT | next=S+1000 | name after=cur=S+1000' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERP2');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RP2';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RW: CompanyWide sequence: Restart, then a Record insert, then the test fails.
// RWa: Initialize only (records the start state).
// RWb: NumberSequence.Restart(Name, S + 1000), Record insert B1, then fails.
// RWc: reads the sequence and the tables and asserts them.
codeunit 79327 "LT SQE RW"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure RWa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RWb_FailsOnPurpose()
    begin
        Initialize();
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('B1');
        Error('RWb fails on purpose');
    end;

    [Test]
    procedure RWc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S | rows=INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERW');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(true);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RW';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RN: Control: Restart, then a Record insert, and the test passes.
// RNa: Initialize only (records the start state).
// RNb: NumberSequence.Restart(Name, S + 1000), Record insert B1.
// RNc: reads the sequence and the tables and asserts them.
codeunit 79328 "LT SQE RN"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure RNa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RNb_Passes()
    begin
        Initialize();
        Seq.RestartTo(Name(), CompanyWide(), Base + 1000);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('B1');
    end;

    [Test]
    procedure RNc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1000 | taken= | name=cur=S+1000 | rows=B1,INIT | next=S+1000 | name after=cur=S+1000' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQERN');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'RN';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XB: Control: the failed test inserts a Record and does not touch the sequence.
// XBa: Initialize only (records the start state).
// XBb: Record insert B1, then fails.
// XBc: reads the sequence and the tables and asserts them.
codeunit 79329 "LT SQE XB"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure XBa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure XBb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Error('XBb fails on purpose');
    end;

    [Test]
    procedure XBc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed= | taken= | name=cur=S | rows=INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQEXB');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XB';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XN: Next only (the sequence existed), then a Record insert, then the test fails.
// XNa: Initialize only (records the start state).
// XNb: NumberSequence.Next(Name), Record insert B1, then fails.
// XNc: reads the sequence and the tables and asserts them.
codeunit 79330 "LT SQE XN"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure XNa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure XNb_FailsOnPurpose()
    begin
        Initialize();
        TakenNext := Seq.RelNext(Name(), CompanyWide(), Base);
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('B1');
        Error('XNb fails on purpose');
    end;

    [Test]
    procedure XNc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+1 | taken=S+1 | name=cur=S+1 | rows=INIT | next=S+2 | name after=cur=S+2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQEXN');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XN';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// DA: Delete, then the test fails with no table access after the last transaction end.
// DAa: Initialize only (records the start state).
// DAb: NumberSequence.Delete(Name), then fails.
// DAc: reads the sequence and the tables and asserts them.
codeunit 79331 "LT SQE DA"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure DAa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure DAb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Delete(Name(), CompanyWide());
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Error('DAb fails on purpose');
    end;

    [Test]
    procedure DAc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=missing | taken= | name=missing | rows=INIT | next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQEDA');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'DA';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// DB: Delete, then a Record insert, then the test fails.
// DBa: Initialize only (records the start state).
// DBb: NumberSequence.Delete(Name), Record insert B1, then fails.
// DBc: reads the sequence and the tables and asserts them.
codeunit 79332 "LT SQE DB"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure DBa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure DBb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Delete(Name(), CompanyWide());
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('B1');
        Error('DBb fails on purpose');
    end;

    [Test]
    procedure DBc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=missing | taken= | name=cur=S | rows=INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQEDB');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'DB';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// DB2: Record insert, then Delete, then the test fails.
// DB2a: Initialize only (records the start state).
// DB2b: Record insert B1, NumberSequence.Delete(Name), then fails.
// DB2c: reads the sequence and the tables and asserts them.
codeunit 79333 "LT SQE DB2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure DB2a_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure DB2b_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        NumberSequence.Delete(Name(), CompanyWide());
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Error('DB2b fails on purpose');
    end;

    [Test]
    procedure DB2c_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=missing | taken= | name=cur=S | rows=INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQEDB2');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'DB2';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// DR: Delete, then a Record read, then the test fails.
// DRa: Initialize only (records the start state).
// DRb: NumberSequence.Delete(Name), a Record FindFirst, then fails.
// DRc: reads the sequence and the tables and asserts them.
codeunit 79334 "LT SQE DR"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure DRa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure DRb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Delete(Name(), CompanyWide());
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.PlainRead();
        Error('DRb fails on purpose');
    end;

    [Test]
    procedure DRc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=missing | taken= | name=cur=S | rows=INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQEDR');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'DR';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// DC: Delete, Record insert, Commit, Record insert, then the test fails.
// DCa: Initialize only (records the start state).
// DCb: NumberSequence.Delete(Name), Record insert B1, Commit(), Record insert B2, then fails.
// DCc: reads the sequence and the tables and asserts them.
codeunit 79335 "LT SQE DC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure DCa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure DCb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Delete(Name(), CompanyWide());
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('B1');
        Commit();
        Access.InsertRow('B2');
        Error('DCb fails on purpose');
    end;

    [Test]
    procedure DCc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=missing | taken= | name=missing | rows=B1,INIT | next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQEDC');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'DC';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// DC2: Delete, Commit with no table access before it, Record insert, then the test fails.
// DC2a: Initialize only (records the start state).
// DC2b: NumberSequence.Delete(Name), Commit(), Record insert B2, then fails.
// DC2c: reads the sequence and the tables and asserts them.
codeunit 79336 "LT SQE DC2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure DC2a_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure DC2b_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Delete(Name(), CompanyWide());
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Commit();
        Access.InsertRow('B2');
        Error('DC2b fails on purpose');
    end;

    [Test]
    procedure DC2c_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=missing | taken= | name=cur=S | rows=INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQEDC2');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'DC2';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// DC3: Delete, Record insert, Commit, then the test fails with no table access after the Commit.
// DC3a: Initialize only (records the start state).
// DC3b: NumberSequence.Delete(Name), Record insert B1, Commit(), then fails.
// DC3c: reads the sequence and the tables and asserts them.
codeunit 79337 "LT SQE DC3"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure DC3a_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure DC3b_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Delete(Name(), CompanyWide());
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('B1');
        Commit();
        Error('DC3b fails on purpose');
    end;

    [Test]
    procedure DC3c_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=missing | taken= | name=missing | rows=B1,INIT | next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQEDC3');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'DC3';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// DC4: Record insert, Commit, Delete, Record insert, then the test fails (Delete after the last Commit).
// DC4a: Initialize only (records the start state).
// DC4b: Record insert B1, Commit(), NumberSequence.Delete(Name), Record insert B2, then fails.
// DC4c: reads the sequence and the tables and asserts them.
codeunit 79338 "LT SQE DC4"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure DC4a_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure DC4b_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Commit();
        NumberSequence.Delete(Name(), CompanyWide());
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('B2');
        Error('DC4b fails on purpose');
    end;

    [Test]
    procedure DC4c_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=missing | taken= | name=cur=S | rows=B1,INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQEDC4');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'DC4';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// DE: Delete, Record insert, asserterror of an Error() with no write, then the test fails.
// DEa: Initialize only (records the start state).
// DEb: NumberSequence.Delete(Name), Record insert B1, asserterror of an Error() with no write inside, then fails.
// DEc: reads the sequence and the tables and asserts them.
codeunit 79339 "LT SQE DE"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure DEa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure DEb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Delete(Name(), CompanyWide());
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('B1');
        asserterror Error('inner error');
        Error('DEb fails on purpose');
    end;

    [Test]
    procedure DEc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=missing | taken= | name=cur=S | rows=INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQEDE');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'DE';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// DP: An earlier passing test deletes (no Commit); the failed test inserts a Record.
// DPa: Initialize only (records the start state).
// DPa2: NumberSequence.Delete(Name).
// DPb: Record insert B1, then fails.
// DPc: reads the sequence and the tables and asserts them.
codeunit 79340 "LT SQE DP"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure DPa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure DPa2_EarlierChanges()
    begin
        Initialize();
        NumberSequence.Delete(Name(), CompanyWide());
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
    end;

    [Test]
    procedure DPb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Error('DPb fails on purpose');
    end;

    [Test]
    procedure DPc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=missing | taken= | name=cur=S | rows=INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQEDP');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'DP';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// DP2: An earlier passing test deletes, inserts a Record and commits; the failed test inserts a Record.
// DP2a: Initialize only (records the start state).
// DP2a2: NumberSequence.Delete(Name), Record insert A2, Commit().
// DP2b: Record insert B1, then fails.
// DP2c: reads the sequence and the tables and asserts them.
codeunit 79341 "LT SQE DP2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure DP2a_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure DP2a2_EarlierChanges()
    begin
        Initialize();
        NumberSequence.Delete(Name(), CompanyWide());
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('A2');
        Commit();
    end;

    [Test]
    procedure DP2b_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Error('DP2b fails on purpose');
    end;

    [Test]
    procedure DP2c_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=missing | taken= | name=missing | rows=A2,INIT | next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQEDP2');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'DP2';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// DI: Delete, Insert again with another start, Record insert, then the test fails.
// DIa: Initialize only (records the start state).
// DIb: NumberSequence.Delete(Name), NumberSequence.Insert(Name, S + 2000, 1), Record insert B1, then fails.
// DIc: reads the sequence and the tables and asserts them.
codeunit 79342 "LT SQE DI"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure DIa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure DIb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Delete(Name(), CompanyWide());
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        NumberSequence.Insert(Name(), Base + 2000, 1, CompanyWide());
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('B1');
        Error('DIb fails on purpose');
    end;

    [Test]
    procedure DIc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=cur=S+2000 | taken= | name=cur=S | rows=INIT | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQEDI');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'DI';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// DN: Control: Delete, then a Record insert, and the test passes.
// DNa: Initialize only (records the start state).
// DNb: NumberSequence.Delete(Name), Record insert B1.
// DNc: reads the sequence and the tables and asserts them.
codeunit 79343 "LT SQE DN"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), CompanyWide());
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure DNa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure DNb_Passes()
    begin
        Initialize();
        NumberSequence.Delete(Name(), CompanyWide());
        ChangedState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.InsertRow('B1');
    end;

    [Test]
    procedure DNc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), CompanyWide(), Base) + ' | rows=' + Access.Rows();
        Actual += ' | next=' + Seq.RelNext(Name(), CompanyWide(), Base) + ' | name after=' + Seq.Rel(Name(), CompanyWide(), Base);
        if Actual <> 'onrun=found | initialized=Yes | start=cur=S | changed=missing | taken= | name=missing | rows=B1,INIT | next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQEDN');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'DN';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name(), CompanyWide());
        StartState := Seq.Rel(Name(), CompanyWide(), Base);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// SA: SCM shape: direct entry, helper restarts and inserts, Commit, reads, then the test fails.
// SAa: Initialize only (records the start state).
// SAb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Commit(), a Record FindSet over the entries, then fails.
// SAc: reads the sequence and the tables and asserts them.
codeunit 79344 "LT SQE SA"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), true) + ',' + Seq.Prepare(Seq.PreviewName(Name()), true);
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure SAa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure SAb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.RelDefault(Name(), Base);
        Commit();
        if Seq.Entries(Base) = '' then;
        Error('SAb fails on purpose');
    end;

    [Test]
    procedure SAc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.RelDefault(Name(), Base) + ' | preview=' + Seq.RelDefault(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries(Base);
        Actual += ' | next=' + Seq.Offset(Seq.GetNextSeqNo(Name()), Base) + ' | name after=' + Seq.RelDefault(Name(), Base);
        if Actual <> 'onrun=found,found | initialized=Yes | start=cur=S,cur=S | changed=restart cur=S+6 | taken=S+6 | name=cur=S+6 | preview=cur=S-2000000003 | rows=INIT | entries=S+5,S+6 | next=S+7 | name after=cur=S+7' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQESA');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'SA';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZeroDefault(Name());
        PreviewBase := Seq.CurrentOrZeroDefault(Seq.PreviewName(Name()));
        StartState := Seq.RelDefault(Name(), Base) + ',' + Seq.RelDefault(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// SB: SCM shape: direct entry, helper restarts and inserts, then the test fails before any Commit.
// SBa: Initialize only (records the start state).
// SBb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, then fails.
// SBc: reads the sequence and the tables and asserts them.
codeunit 79345 "LT SQE SB"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), true) + ',' + Seq.Prepare(Seq.PreviewName(Name()), true);
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure SBa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure SBb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.RelDefault(Name(), Base);
        Error('SBb fails on purpose');
    end;

    [Test]
    procedure SBc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.RelDefault(Name(), Base) + ' | preview=' + Seq.RelDefault(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries(Base);
        Actual += ' | next=' + Seq.Offset(Seq.GetNextSeqNo(Name()), Base) + ' | name after=' + Seq.RelDefault(Name(), Base);
        if Actual <> 'onrun=found,found | initialized=Yes | start=cur=S,cur=S | changed=restart cur=S+6 | taken=S+6 | name=cur=S | preview=cur=S | rows=INIT | entries=none | next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQESB');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'SB';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZeroDefault(Name());
        PreviewBase := Seq.CurrentOrZeroDefault(Seq.PreviewName(Name()));
        StartState := Seq.RelDefault(Name(), Base) + ',' + Seq.RelDefault(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// SC: SCM shape: direct entry, helper restarts and inserts, Commit, then the test fails with no table access.
// SCa: Initialize only (records the start state).
// SCb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Commit(), then fails.
// SCc: reads the sequence and the tables and asserts them.
codeunit 79346 "LT SQE SC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), true) + ',' + Seq.Prepare(Seq.PreviewName(Name()), true);
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure SCa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure SCb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.RelDefault(Name(), Base);
        Commit();
        Error('SCb fails on purpose');
    end;

    [Test]
    procedure SCc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.RelDefault(Name(), Base) + ' | preview=' + Seq.RelDefault(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries(Base);
        Actual += ' | next=' + Seq.Offset(Seq.GetNextSeqNo(Name()), Base) + ' | name after=' + Seq.RelDefault(Name(), Base);
        if Actual <> 'onrun=found,found | initialized=Yes | start=cur=S,cur=S | changed=restart cur=S+6 | taken=S+6 | name=cur=S+6 | preview=cur=S-2000000003 | rows=INIT | entries=S+5,S+6 | next=S+7 | name after=cur=S+7' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQESC');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'SC';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZeroDefault(Name());
        PreviewBase := Seq.CurrentOrZeroDefault(Seq.PreviewName(Name()));
        StartState := Seq.RelDefault(Name(), Base) + ',' + Seq.RelDefault(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// SD: SCM shape: direct entry, Codeunit.Run of a poster that restarts, inserts and commits, reads, then the test fails.
// SDa: Initialize only (records the start state).
// SDb: an entry S + 5 inserted without the sequence, Codeunit.Run of a posting codeunit that takes a number through the helper, inserts the entry and commits, a Record FindSet over the entries, then fails.
// SDc: reads the sequence and the tables and asserts them.
codeunit 79347 "LT SQE SD"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), true) + ',' + Seq.Prepare(Seq.PreviewName(Name()), true);
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        Poster: Codeunit "LT SQE Poster";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure SDa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure SDb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        Poster.SetName(Name());
        Poster.Run();
        ChangedState := Seq.RelDefault(Name(), Base);
        if Seq.Entries(Base) = '' then;
        Error('SDb fails on purpose');
    end;

    [Test]
    procedure SDc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.RelDefault(Name(), Base) + ' | preview=' + Seq.RelDefault(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries(Base);
        Actual += ' | next=' + Seq.Offset(Seq.GetNextSeqNo(Name()), Base) + ' | name after=' + Seq.RelDefault(Name(), Base);
        if Actual <> 'onrun=found,found | initialized=Yes | start=cur=S,cur=S | changed=cur=S+6 | taken= | name=cur=S+6 | preview=cur=S-2000000003 | rows=INIT | entries=S+5,S+6 | next=S+7 | name after=cur=S+7' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQESD');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'SD';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZeroDefault(Name());
        PreviewBase := Seq.CurrentOrZeroDefault(Seq.PreviewName(Name()));
        StartState := Seq.RelDefault(Name(), Base) + ',' + Seq.RelDefault(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// SE: SCM shape: direct entry, helper restarts and inserts, Commit, Record insert, then the test fails.
// SEa: Initialize only (records the start state).
// SEb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Commit(), Record insert B2, then fails.
// SEc: reads the sequence and the tables and asserts them.
codeunit 79348 "LT SQE SE"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), true) + ',' + Seq.Prepare(Seq.PreviewName(Name()), true);
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure SEa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure SEb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.RelDefault(Name(), Base);
        Commit();
        Access.InsertRow('B2');
        Error('SEb fails on purpose');
    end;

    [Test]
    procedure SEc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.RelDefault(Name(), Base) + ' | preview=' + Seq.RelDefault(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries(Base);
        Actual += ' | next=' + Seq.Offset(Seq.GetNextSeqNo(Name()), Base) + ' | name after=' + Seq.RelDefault(Name(), Base);
        if Actual <> 'onrun=found,found | initialized=Yes | start=cur=S,cur=S | changed=restart cur=S+6 | taken=S+6 | name=cur=S+6 | preview=cur=S-2000000003 | rows=INIT | entries=S+5,S+6 | next=S+7 | name after=cur=S+7' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQESE');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'SE';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZeroDefault(Name());
        PreviewBase := Seq.CurrentOrZeroDefault(Seq.PreviewName(Name()));
        StartState := Seq.RelDefault(Name(), Base) + ',' + Seq.RelDefault(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// SN: SCM control: direct entry, helper restarts and inserts, Commit, reads, and the test passes.
// SNa: Initialize only (records the start state).
// SNb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Commit(), a Record FindSet over the entries.
// SNc: reads the sequence and the tables and asserts them.
codeunit 79349 "LT SQE SN"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name(), true) + ',' + Seq.Prepare(Seq.PreviewName(Name()), true);
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        Access: Codeunit "LT SQE Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure SNa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure SNb_Passes()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.RelDefault(Name(), Base);
        Commit();
        if Seq.Entries(Base) = '' then;
    end;

    [Test]
    procedure SNc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.RelDefault(Name(), Base) + ' | preview=' + Seq.RelDefault(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries(Base);
        Actual += ' | next=' + Seq.Offset(Seq.GetNextSeqNo(Name()), Base) + ' | name after=' + Seq.RelDefault(Name(), Base);
        if Actual <> 'onrun=found,found | initialized=Yes | start=cur=S,cur=S | changed=restart cur=S+6 | taken=S+6 | name=cur=S+6 | preview=cur=S-2000000003 | rows=INIT | entries=S+5,S+6 | next=S+7 | name after=cur=S+7' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQESN');
    end;

    local procedure CompanyWide(): Boolean
    begin
        exit(false);
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'SN';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZeroDefault(Name());
        PreviewBase := Seq.CurrentOrZeroDefault(Seq.PreviewName(Name()));
        StartState := Seq.RelDefault(Name(), Base) + ',' + Seq.RelDefault(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}
