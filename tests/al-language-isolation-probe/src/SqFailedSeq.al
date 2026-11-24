namespace ALLanguage.IsolationProbe;

// Probe: a number sequence after a failed test, with the access shapes of Microsoft's SCM tests (AL Runner issue 8972:
// codeunits 137140, 137158, 137294 for S1, 137297 for S2) and the C2 cell of AL Runner issue 8524. Extends SqCommitFail.al
// and SqRecordRefFail.al. Shapes only; no Microsoft code. The helper "LT SQF Seq" (SqFailedSeqFixture.al) makes the
// NumberSequence calls of Sequence No. Mgt. in the same order.
//
// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/numbersequence/numbersequence-data-type
// Scope: NumberSequence.Exists / Insert / Restart / Next / Current after a test that fails, TestIsolation = Codeunit.
// Fixtures used: SqFailedSeqFixture.al ("LT SQF Row", "LT SQF Entry", "LT SQF Trigger Row", "LT SQF Row Card",
// "LT SQF Seq", "LT SQF Access", "LT SQF Poster").
// Each cell is one test codeunit: test a (and a2) set up, test b fails on purpose (the cells S1N and S2N are controls in
// which b passes), test c reads the state and asserts it in the same codeunit (no SingleInstance log, AL Runner issue 8520).
// Readings of test c: initialized = the codeunit's globals survived (the sequence name carries a token made once per codeunit
// run, so a reset would read a new name); name and preview = state of the sequence Name and 'Preview' + Name ('missing' or
// cur=<Current>), read before the helper is called again; rows = keys of "LT SQF Row"; init desc = Description of the row
// INIT (a TestPage and RecordRef.Modify change it); entries = Entry Nos. of "LT SQF Entry"; next = the number the helper
// hands out then; name after = state after that.
// Probe: written against BC 29.0 (the Linux container of the corpus CI), runners 130450 (Microsoft's Test Runner - Isol.
// Codeunit) and 61301 (TestIsolation = Codeunit): the same readings under both, and the same on a second run. BC 27.5,
// 28.5 and the Windows containers are measured by the Windows nightly only.
//
// What BC does:
// - A failed test rolls back to the last Commit() that had a table write in its transaction. A Commit() whose transaction
//   holds only number-sequence calls does not keep the sequence: S1R and S1S (the C2 cell of SqCommitFail.al, with and
//   without CompanyWide) and S2F read missing; S1T (the same with a Record write before the Commit) keeps it. S1Z, the C2
//   shape with the helper's entry insert before the Commit, keeps it.
// - An earlier test's sequence stays when the failed test commits after a table write (S1A, S1J) and when the earlier test
//   committed after a table write (S1A to S1Q). A sequence inserted with no commit is kept by a later commit in a passing
//   test (S1I) or in the failed test (S1J, S1K).
// - NumberSequence.Next is not rolled back: a number the failed test took after its last commit stays used (S1D, S1F, S1G,
//   S1H, S1P, S1K, S1I, S2B, S2C, S2D read cur=2 and hand out 3), while the entry inserted with it is gone.
// - The access kind in the failed test changes nothing: a temporary Record, a TestPage, session builtins, a temporary
//   RecordRef, RecordRef and FieldRef calls on a real table, and an insert whose table trigger calls IsolatedStorage
//   (probe-app code, not Microsoft-app code) give the readings of the Record-only cell.
// - A Commit() inside Codeunit.Run (no return value) or inside a method of a called codeunit counts as the test's commit
//   (S1H, S1P, S2C: the POST row and B1 stay).
// - The failed test's own insert through the helper before its last commit stays with both sequences and the entry
//   (S2A to S2D); one after its last commit is gone with both sequences and the entry (S2E).
// - Rows and changes after the last commit (B2, the TestPage and RecordRef.Modify change of INIT) are gone; rows before it
//   stay. The 'Preview' sequence is kept or gone together with the main one.
// - Not measured: what a later test codeunit sees, TestIsolation = Function (runner 61300; the nightly records it).

// S1a: earlier test inserts and commits; failed test: Record write, Commit, Record write.
// S1Aa: the helper takes a number and inserts an entry, Record insert A, Commit().
// S1Ab: Record insert B1, Commit(), Record insert B2, then fails.
// S1Ac: reads the sequences and the tables and asserts them.
codeunit 76450 "LT SQF S1A"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Aa_Earlier()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('A');
        Commit();
    end;

    [Test]
    procedure S1Ab_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Commit();
        Access.InsertRow('B2');
        Error('S1Ab fails on purpose');
    end;

    [Test]
    procedure S1Ac_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=A,B1,INIT | init desc='''' | entries=1 | next=2 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1A';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// S1a control: the same test B does not fail.
// S1Na: the helper takes a number and inserts an entry, Record insert A, Commit().
// S1Nb: Record insert B1, Commit(), Record insert B2.
// S1Nc: reads the sequences and the tables and asserts them.
codeunit 76451 "LT SQF S1N"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Na_Earlier()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('A');
        Commit();
    end;

    [Test]
    procedure S1Nb_Passes()
    begin
        Initialize();
        Access.InsertRow('B1');
        Commit();
        Access.InsertRow('B2');
    end;

    [Test]
    procedure S1Nc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=A,B1,B2,INIT | init desc='''' | entries=1 | next=2 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1N';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// C2 baseline (pinned by SqCommitFail.al): failed test writes a Record and runs no commit.
// S1Za: the helper takes a number and inserts an entry, Record insert A, Commit().
// S1Zb: Record insert B1, then fails.
// S1Zc: reads the sequences and the tables and asserts them.
codeunit 76452 "LT SQF S1Z"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Za_Earlier()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('A');
        Commit();
    end;

    [Test]
    procedure S1Zb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Error('S1Zb fails on purpose');
    end;

    [Test]
    procedure S1Zc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=A,INIT | init desc='''' | entries=1 | next=2 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1Z';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// S1b: S1a plus a temporary Record after the Commit.
// S1Ba: the helper takes a number and inserts an entry, Record insert A, Commit().
// S1Bb: Record insert B1, Commit(), a temporary Record (Insert, FindSet), Record insert B2, then fails.
// S1Bc: reads the sequences and the tables and asserts them.
codeunit 76453 "LT SQF S1B"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Ba_Earlier()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('A');
        Commit();
    end;

    [Test]
    procedure S1Bb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Commit();
        Access.TempRecord();
        Access.InsertRow('B2');
        Error('S1Bb fails on purpose');
    end;

    [Test]
    procedure S1Bc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=A,B1,INIT | init desc='''' | entries=1 | next=2 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1B';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// S1c: S1a plus a TestPage after the Commit.
// S1Ca: the helper takes a number and inserts an entry, Record insert A, Commit().
// S1Cb: Record insert B1, Commit(), a TestPage (OpenEdit, GoToRecord, SetValue, AssertEquals, Close, OpenView, Close), Record insert B2, then fails.
// S1Cc: reads the sequences and the tables and asserts them.
codeunit 76454 "LT SQF S1C"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Ca_Earlier()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('A');
        Commit();
    end;

    [Test]
    procedure S1Cb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Commit();
        TestPageCalls();
        Access.InsertRow('B2');
        Error('S1Cb fails on purpose');
    end;

    [Test]
    procedure S1Cc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=A,B1,INIT | init desc='''' | entries=1 | next=2 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    local procedure TestPageCalls()
    var
        Row: Record "LT SQF Row";
        RowCard: TestPage "LT SQF Row Card";
    begin
        Row.Get('INIT');
        RowCard.OpenEdit();
        RowCard.GoToRecord(Row);
        RowCard.Description.SetValue('PAGE');
        RowCard."Key".AssertEquals('INIT');
        RowCard.Close();
        RowCard.OpenView();
        RowCard.GoToRecord(Row);
        RowCard.Close();
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1C';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// S1d: S1a plus a number from the helper after the Commit.
// S1Da: the helper takes a number and inserts an entry, Record insert A, Commit().
// S1Db: Record insert B1, Commit(), the helper takes a number and inserts an entry, Record insert B2, then fails.
// S1Dc: reads the sequences and the tables and asserts them.
codeunit 76455 "LT SQF S1D"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Da_Earlier()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('A');
        Commit();
    end;

    [Test]
    procedure S1Db_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Commit();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B2');
        Error('S1Db fails on purpose');
    end;

    [Test]
    procedure S1Dc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=2 | preview=cur=-2000000001 | rows=A,B1,INIT | init desc='''' | entries=1 | next=3 | name after=cur=3' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1D';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// S1e: S1a plus session builtins and a temporary RecordRef after the Commit.
// S1Ea: the helper takes a number and inserts an entry, Record insert A, Commit().
// S1Eb: Record insert B1, Commit(), session builtins, a temporary RecordRef (Open, Field, SetRange), Record insert B2, then fails.
// S1Ec: reads the sequences and the tables and asserts them.
codeunit 76456 "LT SQF S1E"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Ea_Earlier()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('A');
        Commit();
    end;

    [Test]
    procedure S1Eb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Commit();
        Access.Builtins();
        Access.TempRecordRef();
        Access.InsertRow('B2');
        Error('S1Eb fails on purpose');
    end;

    [Test]
    procedure S1Ec_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=A,B1,INIT | init desc='''' | entries=1 | next=2 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1E';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// S1a plus RecordRef and FieldRef calls on the real table after the Commit.
// S1La: the helper takes a number and inserts an entry, Record insert A, Commit().
// S1Lb: Record insert B1, Commit(), RecordRef and FieldRef calls on the real table, ending with RecordRef.Modify, Record insert B2, then fails.
// S1Lc: reads the sequences and the tables and asserts them.
codeunit 76457 "LT SQF S1L"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1La_Earlier()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('A');
        Commit();
    end;

    [Test]
    procedure S1Lb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Commit();
        Access.RecordRefCalls();
        Access.InsertRow('B2');
        Error('S1Lb fails on purpose');
    end;

    [Test]
    procedure S1Lc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=A,B1,INIT | init desc='''' | entries=1 | next=2 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1L';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// S1f: S1a plus every access kind of S1b-S1e and the RecordRef calls (the Microsoft shape).
// S1Fa: the helper takes a number and inserts an entry, Record insert A, Commit().
// S1Fb: Record insert B1, Commit(), a temporary Record (Insert, FindSet), a TestPage (OpenEdit, GoToRecord, SetValue, AssertEquals, Close, OpenView, Close), the helper takes a number and inserts an entry, session builtins, a temporary RecordRef (Open, Field, SetRange), RecordRef and FieldRef calls on the real table, ending with RecordRef.Modify, Record insert B2, then fails.
// S1Fc: reads the sequences and the tables and asserts them.
codeunit 76458 "LT SQF S1F"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Fa_Earlier()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('A');
        Commit();
    end;

    [Test]
    procedure S1Fb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Commit();
        Access.TempRecord();
        TestPageCalls();
        Seq.InsertEntry(Name(), Cell);
        Access.Builtins();
        Access.TempRecordRef();
        Access.RecordRefCalls();
        Access.InsertRow('B2');
        Error('S1Fb fails on purpose');
    end;

    [Test]
    procedure S1Fc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=2 | preview=cur=-2000000001 | rows=A,B1,INIT | init desc='''' | entries=1 | next=3 | name after=cur=3' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    local procedure TestPageCalls()
    var
        Row: Record "LT SQF Row";
        RowCard: TestPage "LT SQF Row Card";
    begin
        Row.Get('INIT');
        RowCard.OpenEdit();
        RowCard.GoToRecord(Row);
        RowCard.Description.SetValue('PAGE');
        RowCard."Key".AssertEquals('INIT');
        RowCard.Close();
        RowCard.OpenView();
        RowCard.GoToRecord(Row);
        RowCard.Close();
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1F';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// S1g: S1f with no Commit in the failed test.
// S1Ga: the helper takes a number and inserts an entry, Record insert A, Commit().
// S1Gb: Record insert B1, a temporary Record (Insert, FindSet), a TestPage (OpenEdit, GoToRecord, SetValue, AssertEquals, Close, OpenView, Close), the helper takes a number and inserts an entry, session builtins, a temporary RecordRef (Open, Field, SetRange), RecordRef and FieldRef calls on the real table, ending with RecordRef.Modify, Record insert B2, then fails.
// S1Gc: reads the sequences and the tables and asserts them.
codeunit 76459 "LT SQF S1G"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Ga_Earlier()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('A');
        Commit();
    end;

    [Test]
    procedure S1Gb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Access.TempRecord();
        TestPageCalls();
        Seq.InsertEntry(Name(), Cell);
        Access.Builtins();
        Access.TempRecordRef();
        Access.RecordRefCalls();
        Access.InsertRow('B2');
        Error('S1Gb fails on purpose');
    end;

    [Test]
    procedure S1Gc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=2 | preview=cur=-2000000001 | rows=A,INIT | init desc='''' | entries=1 | next=3 | name after=cur=3' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    local procedure TestPageCalls()
    var
        Row: Record "LT SQF Row";
        RowCard: TestPage "LT SQF Row Card";
    begin
        Row.Get('INIT');
        RowCard.OpenEdit();
        RowCard.GoToRecord(Row);
        RowCard.Description.SetValue('PAGE');
        RowCard."Key".AssertEquals('INIT');
        RowCard.Close();
        RowCard.OpenView();
        RowCard.GoToRecord(Row);
        RowCard.Close();
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1G';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// S1h: S1f with the Commit inside Codeunit.Run of a posting codeunit.
// S1Ha: the helper takes a number and inserts an entry, Record insert A, Commit().
// S1Hb: Record insert B1, Codeunit.Run (no return value) of a codeunit that writes a row and commits at its end, a temporary Record (Insert, FindSet), a TestPage (OpenEdit, GoToRecord, SetValue, AssertEquals, Close, OpenView, Close), the helper takes a number and inserts an entry, session builtins, a temporary RecordRef (Open, Field, SetRange), RecordRef and FieldRef calls on the real table, ending with RecordRef.Modify, Record insert B2, then fails.
// S1Hc: reads the sequences and the tables and asserts them.
codeunit 76460 "LT SQF S1H"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Ha_Earlier()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('A');
        Commit();
    end;

    [Test]
    procedure S1Hb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Codeunit.Run(Codeunit::"LT SQF Poster");
        Access.TempRecord();
        TestPageCalls();
        Seq.InsertEntry(Name(), Cell);
        Access.Builtins();
        Access.TempRecordRef();
        Access.RecordRefCalls();
        Access.InsertRow('B2');
        Error('S1Hb fails on purpose');
    end;

    [Test]
    procedure S1Hc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=2 | preview=cur=-2000000001 | rows=A,B1,INIT,POST | init desc='''' | entries=1 | next=3 | name after=cur=3' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    local procedure TestPageCalls()
    var
        Row: Record "LT SQF Row";
        RowCard: TestPage "LT SQF Row Card";
    begin
        Row.Get('INIT');
        RowCard.OpenEdit();
        RowCard.GoToRecord(Row);
        RowCard.Description.SetValue('PAGE');
        RowCard."Key".AssertEquals('INIT');
        RowCard.Close();
        RowCard.OpenView();
        RowCard.GoToRecord(Row);
        RowCard.Close();
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1H';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// S1h with the Commit inside a method call of a posting codeunit.
// S1Pa: the helper takes a number and inserts an entry, Record insert A, Commit().
// S1Pb: Record insert B1, a method call to a codeunit that writes a row and commits at its end, a temporary Record (Insert, FindSet), a TestPage (OpenEdit, GoToRecord, SetValue, AssertEquals, Close, OpenView, Close), the helper takes a number and inserts an entry, session builtins, a temporary RecordRef (Open, Field, SetRange), RecordRef and FieldRef calls on the real table, ending with RecordRef.Modify, Record insert B2, then fails.
// S1Pc: reads the sequences and the tables and asserts them.
codeunit 76461 "LT SQF S1P"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        Poster: Codeunit "LT SQF Poster";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Pa_Earlier()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('A');
        Commit();
    end;

    [Test]
    procedure S1Pb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Poster.Post();
        Access.TempRecord();
        TestPageCalls();
        Seq.InsertEntry(Name(), Cell);
        Access.Builtins();
        Access.TempRecordRef();
        Access.RecordRefCalls();
        Access.InsertRow('B2');
        Error('S1Pb fails on purpose');
    end;

    [Test]
    procedure S1Pc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=2 | preview=cur=-2000000001 | rows=A,B1,INIT,POST | init desc='''' | entries=1 | next=3 | name after=cur=3' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    local procedure TestPageCalls()
    var
        Row: Record "LT SQF Row";
        RowCard: TestPage "LT SQF Row Card";
    begin
        Row.Get('INIT');
        RowCard.OpenEdit();
        RowCard.GoToRecord(Row);
        RowCard.Description.SetValue('PAGE');
        RowCard."Key".AssertEquals('INIT');
        RowCard.Close();
        RowCard.OpenView();
        RowCard.GoToRecord(Row);
        RowCard.Close();
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1P';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// S1i: earlier test inserts with no commit; a later passing test commits; failed test as S1f.
// S1Ia: the helper takes a number and inserts an entry, Record insert A.
// S1Ia2: Record insert A2, Commit().
// S1Ib: Record insert B1, Commit(), a temporary Record (Insert, FindSet), a TestPage (OpenEdit, GoToRecord, SetValue, AssertEquals, Close, OpenView, Close), the helper takes a number and inserts an entry, session builtins, a temporary RecordRef (Open, Field, SetRange), RecordRef and FieldRef calls on the real table, ending with RecordRef.Modify, Record insert B2, then fails.
// S1Ic: reads the sequences and the tables and asserts them.
codeunit 76462 "LT SQF S1I"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Ia_EarlierNoCommit()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('A');
    end;

    [Test]
    procedure S1Ia2_LaterCommits()
    begin
        Initialize();
        Access.InsertRow('A2');
        Commit();
    end;

    [Test]
    procedure S1Ib_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Commit();
        Access.TempRecord();
        TestPageCalls();
        Seq.InsertEntry(Name(), Cell);
        Access.Builtins();
        Access.TempRecordRef();
        Access.RecordRefCalls();
        Access.InsertRow('B2');
        Error('S1Ib fails on purpose');
    end;

    [Test]
    procedure S1Ic_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=2 | preview=cur=-2000000001 | rows=A,A2,B1,INIT | init desc='''' | entries=1 | next=3 | name after=cur=3' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    local procedure TestPageCalls()
    var
        Row: Record "LT SQF Row";
        RowCard: TestPage "LT SQF Row Card";
    begin
        Row.Get('INIT');
        RowCard.OpenEdit();
        RowCard.GoToRecord(Row);
        RowCard.Description.SetValue('PAGE');
        RowCard."Key".AssertEquals('INIT');
        RowCard.Close();
        RowCard.OpenView();
        RowCard.GoToRecord(Row);
        RowCard.Close();
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1I';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// earlier test inserts with no commit; failed test: Record write, Commit, Record write.
// S1Ja: the helper takes a number and inserts an entry, Record insert A.
// S1Jb: Record insert B1, Commit(), Record insert B2, then fails.
// S1Jc: reads the sequences and the tables and asserts them.
codeunit 76463 "LT SQF S1J"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Ja_EarlierNoCommit()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('A');
    end;

    [Test]
    procedure S1Jb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Commit();
        Access.InsertRow('B2');
        Error('S1Jb fails on purpose');
    end;

    [Test]
    procedure S1Jc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=A,B1,INIT | init desc='''' | entries=1 | next=2 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1J';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// earlier test inserts with no commit; failed test as S1f.
// S1Ka: the helper takes a number and inserts an entry, Record insert A.
// S1Kb: Record insert B1, Commit(), a temporary Record (Insert, FindSet), a TestPage (OpenEdit, GoToRecord, SetValue, AssertEquals, Close, OpenView, Close), the helper takes a number and inserts an entry, session builtins, a temporary RecordRef (Open, Field, SetRange), RecordRef and FieldRef calls on the real table, ending with RecordRef.Modify, Record insert B2, then fails.
// S1Kc: reads the sequences and the tables and asserts them.
codeunit 76464 "LT SQF S1K"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Ka_EarlierNoCommit()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('A');
    end;

    [Test]
    procedure S1Kb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Commit();
        Access.TempRecord();
        TestPageCalls();
        Seq.InsertEntry(Name(), Cell);
        Access.Builtins();
        Access.TempRecordRef();
        Access.RecordRefCalls();
        Access.InsertRow('B2');
        Error('S1Kb fails on purpose');
    end;

    [Test]
    procedure S1Kc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=2 | preview=cur=-2000000001 | rows=A,B1,INIT | init desc='''' | entries=1 | next=3 | name after=cur=3' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    local procedure TestPageCalls()
    var
        Row: Record "LT SQF Row";
        RowCard: TestPage "LT SQF Row Card";
    begin
        Row.Get('INIT');
        RowCard.OpenEdit();
        RowCard.GoToRecord(Row);
        RowCard.Description.SetValue('PAGE');
        RowCard."Key".AssertEquals('INIT');
        RowCard.Close();
        RowCard.OpenView();
        RowCard.GoToRecord(Row);
        RowCard.Close();
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1K';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// issue 8524 (C2 shape): failed test inserts a row whose insert trigger calls IsolatedStorage, no commit.
// S1Ma: the helper takes a number and inserts an entry, Record insert A, Commit().
// S1Mb: an insert whose table trigger calls IsolatedStorage.Contains, CurrentDateTime and CompanyName, then fails.
// S1Mc: reads the sequences and the tables and asserts them.
codeunit 76465 "LT SQF S1M"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Ma_Earlier()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('A');
        Commit();
    end;

    [Test]
    procedure S1Mb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertTriggerRow('ISO');
        Error('S1Mb fails on purpose');
    end;

    [Test]
    procedure S1Mc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=A,INIT | init desc='''' | entries=1 | next=2 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1M';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// issue 8524 shape with a Commit before the trigger insert.
// S1Qa: the helper takes a number and inserts an entry, Record insert A, Commit().
// S1Qb: Record insert B1, Commit(), an insert whose table trigger calls IsolatedStorage.Contains, CurrentDateTime and CompanyName, then fails.
// S1Qc: reads the sequences and the tables and asserts them.
codeunit 76466 "LT SQF S1Q"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Qa_Earlier()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('A');
        Commit();
    end;

    [Test]
    procedure S1Qb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Commit();
        Access.InsertTriggerRow('ISO');
        Error('S1Qb fails on purpose');
    end;

    [Test]
    procedure S1Qc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=A,B1,INIT | init desc='''' | entries=1 | next=2 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1Q';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// C2 replica: earlier test inserts a sequence (no CompanyWide), takes a number, commits with no table write; failed test writes a Record, no commit.
// S1Ra: NumberSequence.Insert(Name, 1, 1) and Next, no table write, Commit().
// S1Rb: Record insert B1, then fails.
// S1Rc: reads the sequences and the tables and asserts them.
codeunit 76467 "LT SQF S1R"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Ra_EarlierNoWrite()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 1, 1);
        if NumberSequence.Next(Name()) = 0 then;
        Commit();
    end;

    [Test]
    procedure S1Rb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Error('S1Rb fails on purpose');
    end;

    [Test]
    procedure S1Rc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=missing | preview=missing | rows=INIT | init desc='''' | entries=none | next=1 | name after=cur=1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1R';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// S1R with NumberSequence.Insert(..., true).
// S1Sa: NumberSequence.Insert(Name, 1, 1, true) and Next, no table write, Commit().
// S1Sb: Record insert B1, then fails.
// S1Sc: reads the sequences and the tables and asserts them.
codeunit 76468 "LT SQF S1S"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Sa_EarlierNoWrite()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 1, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        Commit();
    end;

    [Test]
    procedure S1Sb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Error('S1Sb fails on purpose');
    end;

    [Test]
    procedure S1Sc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=missing | preview=missing | rows=INIT | init desc='''' | entries=none | next=1 | name after=cur=1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1S';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// S1R with a Record write before the Commit of the earlier test.
// S1Ta: NumberSequence.Insert(Name, 1, 1) and Next, no table write, Record insert A, Commit().
// S1Tb: Record insert B1, then fails.
// S1Tc: reads the sequences and the tables and asserts them.
codeunit 76469 "LT SQF S1T"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S1Ta_EarlierWrite()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 1, 1);
        if NumberSequence.Next(Name()) = 0 then;
        Access.InsertRow('A');
        Commit();
    end;

    [Test]
    procedure S1Tb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B1');
        Error('S1Tb fails on purpose');
    end;

    [Test]
    procedure S1Tc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=missing | rows=A,INIT | init desc='''' | entries=none | next=2 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S1T';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// S2a: failed test: helper inserts the sequence and an entry, Commit, Record write.
// S2Aa: Initialize only.
// S2Ab: the helper takes a number and inserts an entry, Commit(), Record insert B2, then fails.
// S2Ac: reads the sequences and the tables and asserts them.
codeunit 76470 "LT SQF S2A"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S2Aa_InitializeCommits()
    begin
        Initialize();
    end;

    [Test]
    procedure S2Ab_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Commit();
        Access.InsertRow('B2');
        Error('S2Ab fails on purpose');
    end;

    [Test]
    procedure S2Ac_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=INIT | init desc='''' | entries=1 | next=2 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S2A';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// S2b: S2a plus every access kind of S1f after the Commit.
// S2Ba: Initialize only.
// S2Bb: the helper takes a number and inserts an entry, Commit(), a temporary Record (Insert, FindSet), a TestPage (OpenEdit, GoToRecord, SetValue, AssertEquals, Close, OpenView, Close), the helper takes a number and inserts an entry, session builtins, a temporary RecordRef (Open, Field, SetRange), RecordRef and FieldRef calls on the real table, ending with RecordRef.Modify, Record insert B2, then fails.
// S2Bc: reads the sequences and the tables and asserts them.
codeunit 76471 "LT SQF S2B"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S2Ba_InitializeCommits()
    begin
        Initialize();
    end;

    [Test]
    procedure S2Bb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Commit();
        Access.TempRecord();
        TestPageCalls();
        Seq.InsertEntry(Name(), Cell);
        Access.Builtins();
        Access.TempRecordRef();
        Access.RecordRefCalls();
        Access.InsertRow('B2');
        Error('S2Bb fails on purpose');
    end;

    [Test]
    procedure S2Bc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=2 | preview=cur=-2000000001 | rows=INIT | init desc='''' | entries=1 | next=3 | name after=cur=3' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    local procedure TestPageCalls()
    var
        Row: Record "LT SQF Row";
        RowCard: TestPage "LT SQF Row Card";
    begin
        Row.Get('INIT');
        RowCard.OpenEdit();
        RowCard.GoToRecord(Row);
        RowCard.Description.SetValue('PAGE');
        RowCard."Key".AssertEquals('INIT');
        RowCard.Close();
        RowCard.OpenView();
        RowCard.GoToRecord(Row);
        RowCard.Close();
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S2B';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// S2b control: the same test B does not fail.
// S2Na: Initialize only.
// S2Nb: the helper takes a number and inserts an entry, Commit(), a temporary Record (Insert, FindSet), a TestPage (OpenEdit, GoToRecord, SetValue, AssertEquals, Close, OpenView, Close), the helper takes a number and inserts an entry, session builtins, a temporary RecordRef (Open, Field, SetRange), RecordRef and FieldRef calls on the real table, ending with RecordRef.Modify, Record insert B2.
// S2Nc: reads the sequences and the tables and asserts them.
codeunit 76472 "LT SQF S2N"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S2Na_InitializeCommits()
    begin
        Initialize();
    end;

    [Test]
    procedure S2Nb_Passes()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Commit();
        Access.TempRecord();
        TestPageCalls();
        Seq.InsertEntry(Name(), Cell);
        Access.Builtins();
        Access.TempRecordRef();
        Access.RecordRefCalls();
        Access.InsertRow('B2');
    end;

    [Test]
    procedure S2Nc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=2 | preview=cur=-2000000001 | rows=B2,INIT | init desc=''REF'' | entries=1,2 | next=3 | name after=cur=3' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    local procedure TestPageCalls()
    var
        Row: Record "LT SQF Row";
        RowCard: TestPage "LT SQF Row Card";
    begin
        Row.Get('INIT');
        RowCard.OpenEdit();
        RowCard.GoToRecord(Row);
        RowCard.Description.SetValue('PAGE');
        RowCard."Key".AssertEquals('INIT');
        RowCard.Close();
        RowCard.OpenView();
        RowCard.GoToRecord(Row);
        RowCard.Close();
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S2N';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// S2c: S2b with the Commit inside Codeunit.Run of a posting codeunit.
// S2Ca: Initialize only.
// S2Cb: the helper takes a number and inserts an entry, Codeunit.Run (no return value) of a codeunit that writes a row and commits at its end, a temporary Record (Insert, FindSet), a TestPage (OpenEdit, GoToRecord, SetValue, AssertEquals, Close, OpenView, Close), the helper takes a number and inserts an entry, session builtins, a temporary RecordRef (Open, Field, SetRange), RecordRef and FieldRef calls on the real table, ending with RecordRef.Modify, Record insert B2, then fails.
// S2Cc: reads the sequences and the tables and asserts them.
codeunit 76473 "LT SQF S2C"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S2Ca_InitializeCommits()
    begin
        Initialize();
    end;

    [Test]
    procedure S2Cb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Codeunit.Run(Codeunit::"LT SQF Poster");
        Access.TempRecord();
        TestPageCalls();
        Seq.InsertEntry(Name(), Cell);
        Access.Builtins();
        Access.TempRecordRef();
        Access.RecordRefCalls();
        Access.InsertRow('B2');
        Error('S2Cb fails on purpose');
    end;

    [Test]
    procedure S2Cc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=2 | preview=cur=-2000000001 | rows=INIT,POST | init desc='''' | entries=1 | next=3 | name after=cur=3' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    local procedure TestPageCalls()
    var
        Row: Record "LT SQF Row";
        RowCard: TestPage "LT SQF Row Card";
    begin
        Row.Get('INIT');
        RowCard.OpenEdit();
        RowCard.GoToRecord(Row);
        RowCard.Description.SetValue('PAGE');
        RowCard."Key".AssertEquals('INIT');
        RowCard.Close();
        RowCard.OpenView();
        RowCard.GoToRecord(Row);
        RowCard.Close();
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S2C';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// S2d: S2b with a Commit before the insert too.
// S2Da: Initialize only.
// S2Db: Record insert B0, Commit(), the helper takes a number and inserts an entry, Commit(), a temporary Record (Insert, FindSet), a TestPage (OpenEdit, GoToRecord, SetValue, AssertEquals, Close, OpenView, Close), the helper takes a number and inserts an entry, session builtins, a temporary RecordRef (Open, Field, SetRange), RecordRef and FieldRef calls on the real table, ending with RecordRef.Modify, Record insert B2, then fails.
// S2Dc: reads the sequences and the tables and asserts them.
codeunit 76474 "LT SQF S2D"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S2Da_InitializeCommits()
    begin
        Initialize();
    end;

    [Test]
    procedure S2Db_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertRow('B0');
        Commit();
        Seq.InsertEntry(Name(), Cell);
        Commit();
        Access.TempRecord();
        TestPageCalls();
        Seq.InsertEntry(Name(), Cell);
        Access.Builtins();
        Access.TempRecordRef();
        Access.RecordRefCalls();
        Access.InsertRow('B2');
        Error('S2Db fails on purpose');
    end;

    [Test]
    procedure S2Dc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=2 | preview=cur=-2000000001 | rows=B0,INIT | init desc='''' | entries=1 | next=3 | name after=cur=3' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    local procedure TestPageCalls()
    var
        Row: Record "LT SQF Row";
        RowCard: TestPage "LT SQF Row Card";
    begin
        Row.Get('INIT');
        RowCard.OpenEdit();
        RowCard.GoToRecord(Row);
        RowCard.Description.SetValue('PAGE');
        RowCard."Key".AssertEquals('INIT');
        RowCard.Close();
        RowCard.OpenView();
        RowCard.GoToRecord(Row);
        RowCard.Close();
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S2D';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// failed test: Commit, then the helper inserts the sequence and an entry (no commit after the insert).
// S2Ea: Initialize only.
// S2Eb: Commit(), the helper takes a number and inserts an entry, Record insert B2, then fails.
// S2Ec: reads the sequences and the tables and asserts them.
codeunit 76475 "LT SQF S2E"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S2Ea_InitializeCommits()
    begin
        Initialize();
    end;

    [Test]
    procedure S2Eb_FailsOnPurpose()
    begin
        Initialize();
        Commit();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B2');
        Error('S2Eb fails on purpose');
    end;

    [Test]
    procedure S2Ec_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=missing | preview=missing | rows=INIT | init desc='''' | entries=none | next=1 | name after=cur=1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S2E';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// failed test: NumberSequence.Insert and Next with no table write, Commit, Record write.
// S2Fa: Initialize only.
// S2Fb: NumberSequence.Insert(Name, 1, 1) and Next, no table write, Commit(), Record insert B2, then fails.
// S2Fc: reads the sequences and the tables and asserts them.
codeunit 76476 "LT SQF S2F"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQF Seq";
        Access: Codeunit "LT SQF Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure S2Fa_InitializeCommits()
    begin
        Initialize();
    end;

    [Test]
    procedure S2Fb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 1, 1);
        if NumberSequence.Next(Name()) = 0 then;
        Commit();
        Access.InsertRow('B2');
        Error('S2Fb fails on purpose');
    end;

    [Test]
    procedure S2Fc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | init desc=' + Access.InitDescription() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Format(Seq.GetNextSeqNo(Name())) + ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=missing | preview=missing | rows=INIT | init desc='''' | entries=none | next=1 | name after=cur=1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQF' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'S2F';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}
