namespace ALLanguage.IsolationProbe;

// Probe: a number sequence after a failed test when the stretch between two transaction ends mixes access kinds, as the
// test bodies of Microsoft's SCM tests do (AL Runner issue 8972: Record writes, temporary Records, session builtins, Query,
// RecordRef calls, Page.Run, Report.SaveAs and a posting preview rollback in one stretch). Extends SqFailedSeq.al and
// SqExistingRestart.al, whose stretches hold one access kind each. Shapes only; no Microsoft code. The helper "LT SQM Seq"
// (SqMixedAccessFixture.al) makes the NumberSequence calls of Sequence No. Mgt. in the same order.
//
// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/numbersequence/numbersequence-data-type
// Scope: NumberSequence.Insert / Restart / Next / Exists / Current after a test that fails, Commit(), asserterror,
// Codeunit.Run with a return value, TestIsolation = Codeunit.
// Fixtures used: SqMixedAccessFixture.al ("LT SQM Row", "LT SQM Entry", "LT SQM Entry2", "LT SQM Row Card",
// "LT SQM Row Query", "LT SQM Row Report", "LT SQM Seq", "LT SQM Access", "LT SQM Preview").
// Each cell is one test codeunit: test a sets up, test b (and b2) fails on purpose (XP is a control in which b passes; in
// PN, b would pass but the guarded Codeunit.Run fails it), test c reads the state and asserts it in the same codeunit (no
// SingleInstance log, AL Runner issue 8520).
// M, N, P and F cells use a new sequence: its name carries a token made once per codeunit run. X cells (and FE) use a
// sequence that existed when the tests began (OnRun makes it when it is missing; the name is fixed per cell), and read
// every number relative to S, the Current value test a found, because numbers taken with Next stay taken from run to run.
// Readings of test c: onrun = what OnRun found (X cells); initialized = the codeunit's globals survived; start, changed,
// taken = the start state, the state right after the helper's step and the number test b took (X cells); pv = what the
// posting preview step returned ('run:' and nothing after it: the Codeunit.Run call raised; 'No:''': it returned false
// with an empty last error; 'asserterror:''': the asserterror caught an empty error; PT: 'run:asserterror:'<text>'
// code:'<code>'': GetLastErrorText and GetLastErrorCode after the asserterror); name and preview = state of the
// sequence Name and 'Preview' + Name ('missing' or cur=<Current>); name2, preview2, entries2 = the same for the second
// entry table (M2); rows = keys of "LT SQM Row"; entries = Entry Nos. of "LT SQM Entry"; next and preview next = what
// NumberSequence.Next returns then; name after = state after that.
// Measured on: BC 27.5 (27.5.54899.59044), 28.5 (28.5.54976.59048) and 29.0 (29.0.54011.59052), each on the Linux
// container setup of the corpus CI (bc-linux at the commit the corpus pins), run locally because this app has no Linux
// CI job; runners 130450 (Microsoft's Test Runner - Isol. Codeunit) and 61301 (TestIsolation = Codeunit), each runner
// twice in one container: the same readings and test outcomes in every run, on every version. The Windows containers and runner 61300 (TestIsolation = Function) are measured by the Windows
// nightly only.
//
// What BC does:
// - Cell 1 (one stretch mixes access kinds). A sequence the helper made before a Commit() survives the failed test. The
//   helper's own entry insert is already a table write in every M cell; the cells vary only what comes on top of it: MA
//   (Record write, temporary Record, session builtins, Query read, RecordRef calls), MW (a second Record write only), MT,
//   MB, MQ, MK, MP, MR (a Record write plus one more kind) and M2 (two tables and two sequences) all keep the sequence,
//   the entry and the row written before the Commit(); the row written after it is gone. Without
//   the Commit() (MN) the failed test undoes everything: sequence, preview sequence, entry and rows.
// - What counts as table access (raw NumberSequence.Insert and Next, no other table access before the Commit()): a
//   temporary Record (NT), session builtins (NB), RecordRef calls without a read (NK) and all three together (NA) do not
//   count: the sequence is gone. A Query read (NQ), Page.Run of a card (NP) and Report.SaveAs Xml (NR) count: the
//   sequence is kept (cur=0: the raw Next took 0, the first number of Insert(Name, 0, 1)).
// - Cell 2 (a guarded Codeunit.Run, return value used, as the posting preview runs). After a table write or a locking
//   read since the last commit, the Codeunit.Run call raises instead of returning a value: PA (engine ends with
//   Error('')), PF (engine ends normally), PG (engine ends with an error text), PC (no Commit), PD (engine takes no
//   number), XD (existing sequence), RW (helper, Commit(), a Record write, then the Run) and RL (helper, Commit(),
//   LockTable and FindFirst, then the Run). The failed test b reports "An error occurred and the transaction is stopped.
//   Contact your administrator or partner for further assistance." and everything since the last commit is gone. In the
//   control PN, in which test b would pass, the same error fails it. PT catches the raise with asserterror:
//   GetLastErrorText() is that text and GetLastErrorCode() is 'DB:Ok'; the helper's sequence insert and the row B1 before
//   it are undone, the sequence is missing.
// - With no table write and no lock since the last commit the guarded Codeunit.Run returns false with an empty last
//   error (pv=run:No:''). PH (helper, Commit(), then the Run): the number the engine took stays taken (cur=2); the
//   engine's row and entry are undone; the rest is kept. RR (PH plus a Record FindFirst before the Run) and RQ (PH plus
//   a Query read) give the same readings as PH: a plain read does not make the Run raise. XF (existing sequence: the
//   restart is committed, then the Run): the same, the restart is kept and the Run's number stays taken (cur=S+7). PI
//   (raw Insert and Next, then the Run, then mixed kinds, Commit(), write): the sequence is gone although the row B1
//   written after the Run is kept. PK (PI with an engine that takes no number) gives the same: the Run's rollback undoes
//   the Insert made before it in the same transaction, whether or not the engine used that sequence. PJ (PI without the
//   mixed kinds) and PE (engine takes no number, no mixed kinds): sequence and rows gone.
// - PB (asserterror of a plain call that writes a row, takes a number and ends with Error('')): the asserterror catches
//   an empty error and undoes the sequence insert of the helper before it together with the entry; the row B1 written
//   after it and committed is kept; the sequence is missing.
// - Cell 3 (existing sequence restarted by the helper). With a Commit() after the mixed stretch the restart is kept
//   (XA, XC with Page.Run and Report.SaveAs: cur=S+6, preview S-2000000003); without it the restart is undone (XB, XE:
//   cur=S). A raw Restart with only a temporary Record, builtins and RecordRef calls is kept (XN, cur=S+1000); a raw
//   Restart and a Query read is undone (XQ). Control XP: the test passes and row B2 stays.
// - Cell 4 (two failed tests in one codeunit). FA (both commit): cur=2, entries 1 and 2. FB (the second does not
//   commit): cur=2, its Next is not undone, entries 1. FC (the first does not commit, the second does): cur=1, the second
//   test made the sequence anew, entries 1. FD (the second only takes a number): cur=2. FE (existing sequence, the second
//   restarts again with no commit): the first restart is kept (cur=S+6), the second undone.

// MA: new sequence: helper and every mixed kind, Commit, Record write, then the test fails.
// MAa: Initialize only.
// MAb: the helper takes a number and inserts an entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// MAc: reads the sequences and the tables and asserts them.
codeunit 79530 "LT SQM MA"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure MAa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure MAb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('MAb fails on purpose');
    end;

    [Test]
    procedure MAc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=B1,INIT | entries=1 | next=2 | preview next=-2000000000 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'MA';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// MW: new sequence: helper and a Record write only, Commit, Record write, then the test fails (control of MA).
// MWa: Initialize only.
// MWb: the helper takes a number and inserts an entry, Record insert B1, Commit(), Record insert B2, then fails.
// MWc: reads the sequences and the tables and asserts them.
codeunit 79531 "LT SQM MW"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure MWa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure MWb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Commit();
        Access.InsertRow('B2');
        Error('MWb fails on purpose');
    end;

    [Test]
    procedure MWc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=B1,INIT | entries=1 | next=2 | preview next=-2000000000 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'MW';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// MT: new sequence: helper, Record write, a temporary Record, Commit, Record write, then the test fails.
// MTa: Initialize only.
// MTb: the helper takes a number and inserts an entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), Commit(), Record insert B2, then fails.
// MTc: reads the sequences and the tables and asserts them.
codeunit 79532 "LT SQM MT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure MTa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure MTb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.TempRecord();
        Commit();
        Access.InsertRow('B2');
        Error('MTb fails on purpose');
    end;

    [Test]
    procedure MTc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=B1,INIT | entries=1 | next=2 | preview next=-2000000000 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'MT';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// MB: new sequence: helper, Record write, session builtins, Commit, Record write, then the test fails.
// MBa: Initialize only.
// MBb: the helper takes a number and inserts an entry, Record insert B1, session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), Commit(), Record insert B2, then fails.
// MBc: reads the sequences and the tables and asserts them.
codeunit 79533 "LT SQM MB"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure MBa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure MBb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.Builtins();
        Commit();
        Access.InsertRow('B2');
        Error('MBb fails on purpose');
    end;

    [Test]
    procedure MBc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=B1,INIT | entries=1 | next=2 | preview next=-2000000000 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'MB';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// MQ: new sequence: helper, Record write, a Query read, Commit, Record write, then the test fails.
// MQa: Initialize only.
// MQb: the helper takes a number and inserts an entry, Record insert B1, a Query Open, Read, Close, Commit(), Record insert B2, then fails.
// MQc: reads the sequences and the tables and asserts them.
codeunit 79534 "LT SQM MQ"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure MQa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure MQb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.QueryRead();
        Commit();
        Access.InsertRow('B2');
        Error('MQb fails on purpose');
    end;

    [Test]
    procedure MQc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=B1,INIT | entries=1 | next=2 | preview next=-2000000000 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'MQ';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// MK: new sequence: helper, Record write, RecordRef calls the helper does not make, Commit, Record write, then the test fails.
// MKa: Initialize only.
// MKb: the helper takes a number and inserts an entry, Record insert B1, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// MKc: reads the sequences and the tables and asserts them.
codeunit 79535 "LT SQM MK"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure MKa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure MKb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('MKb fails on purpose');
    end;

    [Test]
    procedure MKc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=B1,INIT | entries=1 | next=2 | preview next=-2000000000 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'MK';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// MP: new sequence: helper, Record write, Page.Run with a PageHandler, Commit, Record write, then the test fails.
// MPa: Initialize only.
// MPb: the helper takes a number and inserts an entry, Record insert B1, Page.Run of a card (PageHandler closes it), Commit(), Record insert B2, then fails.
// MPc: reads the sequences and the tables and asserts them.
codeunit 79536 "LT SQM MP"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure MPa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    [HandlerFunctions('RowCardHandler')]
    procedure MPb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.RunPage();
        Commit();
        Access.InsertRow('B2');
        Error('MPb fails on purpose');
    end;

    [Test]
    procedure MPc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=B1,INIT | entries=1 | next=2 | preview next=-2000000000 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    [PageHandler]
    procedure RowCardHandler(var RowCard: TestPage "LT SQM Row Card")
    begin
        RowCard.Close();
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'MP';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// MR: new sequence: helper, Record write, Report.SaveAs Xml, Commit, Record write, then the test fails.
// MRa: Initialize only.
// MRb: the helper takes a number and inserts an entry, Record insert B1, Report.SaveAs in Xml format, Commit(), Record insert B2, then fails.
// MRc: reads the sequences and the tables and asserts them.
codeunit 79537 "LT SQM MR"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure MRa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure MRb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.ReportXml();
        Commit();
        Access.InsertRow('B2');
        Error('MRb fails on purpose');
    end;

    [Test]
    procedure MRc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=B1,INIT | entries=1 | next=2 | preview next=-2000000000 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'MR';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// M2: new sequences: the helper on two entry tables (two RecordRef loads of different tables), mixed kinds, Commit, Record write, then the test fails.
// M2a: Initialize only.
// M2b: the helper takes a number and inserts an entry, the helper takes a number of the second entry table and inserts an entry there, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// M2c: reads the sequences and the tables and asserts them.
codeunit 79538 "LT SQM M2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure M2a_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure M2b_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Seq.InsertEntry2(Name2(), Cell);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('M2b fails on purpose');
    end;

    [Test]
    procedure M2c_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | name2=' + Seq.State(Name2()) + ' | preview2=' + Seq.State(Seq.PreviewName(Name2())) + ' | entries2=' + Seq.Entries2();
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | name2=cur=1 | preview2=cur=-2000000001 | entries2=1 | rows=B1,INIT | entries=1 | next=2 | preview next=-2000000000 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    local procedure Name2(): Text
    begin
        exit('LTSQM2' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'M2';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// MN: new sequence: MA with no Commit in the failed test.
// MNa: Initialize only.
// MNb: the helper takes a number and inserts an entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Record insert B2, then fails.
// MNc: reads the sequences and the tables and asserts them.
codeunit 79539 "LT SQM MN"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure MNa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure MNb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Access.InsertRow('B2');
        Error('MNb fails on purpose');
    end;

    [Test]
    procedure MNc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=missing | preview=missing | rows=INIT | entries=none | next=missing | preview next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'MN';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// NT: raw insert and a temporary Record only, Commit, Record write, then the test fails.
// NTa: Initialize only.
// NTb: NumberSequence.Insert(Name, 0, 1, true) and Next, a temporary Record (Insert, FindSet, Modify, DeleteAll), Commit(), Record insert B2, then fails.
// NTc: reads the sequences and the tables and asserts them.
codeunit 79540 "LT SQM NT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure NTa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure NTb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        Access.TempRecord();
        Commit();
        Access.InsertRow('B2');
        Error('NTb fails on purpose');
    end;

    [Test]
    procedure NTc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=missing | preview=missing | rows=INIT | entries=none | next=missing | preview next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'NT';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// NB: raw insert and session builtins only, Commit, Record write, then the test fails.
// NBa: Initialize only.
// NBb: NumberSequence.Insert(Name, 0, 1, true) and Next, session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), Commit(), Record insert B2, then fails.
// NBc: reads the sequences and the tables and asserts them.
codeunit 79541 "LT SQM NB"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure NBa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure NBb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        Access.Builtins();
        Commit();
        Access.InsertRow('B2');
        Error('NBb fails on purpose');
    end;

    [Test]
    procedure NBc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=missing | preview=missing | rows=INIT | entries=none | next=missing | preview next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'NB';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// NQ: raw insert and a Query read only, Commit, Record write, then the test fails.
// NQa: Initialize only.
// NQb: NumberSequence.Insert(Name, 0, 1, true) and Next, a Query Open, Read, Close, Commit(), Record insert B2, then fails.
// NQc: reads the sequences and the tables and asserts them.
codeunit 79542 "LT SQM NQ"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure NQa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure NQb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        Access.QueryRead();
        Commit();
        Access.InsertRow('B2');
        Error('NQb fails on purpose');
    end;

    [Test]
    procedure NQc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=0 | preview=missing | rows=INIT | entries=none | next=1 | preview next=missing | name after=cur=1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'NQ';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// NK: raw insert and RecordRef calls with no read only, Commit, Record write, then the test fails.
// NKa: Initialize only.
// NKb: NumberSequence.Insert(Name, 0, 1, true) and Next, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// NKc: reads the sequences and the tables and asserts them.
codeunit 79543 "LT SQM NK"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure NKa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure NKb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('NKb fails on purpose');
    end;

    [Test]
    procedure NKc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=missing | preview=missing | rows=INIT | entries=none | next=missing | preview next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'NK';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// NP: raw insert and Page.Run with a PageHandler only, Commit, Record write, then the test fails.
// NPa: Initialize only.
// NPb: NumberSequence.Insert(Name, 0, 1, true) and Next, Page.Run of a card (PageHandler closes it), Commit(), Record insert B2, then fails.
// NPc: reads the sequences and the tables and asserts them.
codeunit 79544 "LT SQM NP"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure NPa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    [HandlerFunctions('RowCardHandler')]
    procedure NPb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        Access.RunPage();
        Commit();
        Access.InsertRow('B2');
        Error('NPb fails on purpose');
    end;

    [Test]
    procedure NPc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=0 | preview=missing | rows=INIT | entries=none | next=1 | preview next=missing | name after=cur=1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    [PageHandler]
    procedure RowCardHandler(var RowCard: TestPage "LT SQM Row Card")
    begin
        RowCard.Close();
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'NP';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// NR: raw insert and Report.SaveAs Xml only, Commit, Record write, then the test fails.
// NRa: Initialize only.
// NRb: NumberSequence.Insert(Name, 0, 1, true) and Next, Report.SaveAs in Xml format, Commit(), Record insert B2, then fails.
// NRc: reads the sequences and the tables and asserts them.
codeunit 79545 "LT SQM NR"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure NRa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure NRb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        Access.ReportXml();
        Commit();
        Access.InsertRow('B2');
        Error('NRb fails on purpose');
    end;

    [Test]
    procedure NRc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=0 | preview=missing | rows=INIT | entries=none | next=1 | preview next=missing | name after=cur=1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'NR';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// NA: raw insert with the temporary Record, builtins and RecordRef calls (no table read or write), Commit, Record write, then the test fails.
// NAa: Initialize only.
// NAb: NumberSequence.Insert(Name, 0, 1, true) and Next, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// NAc: reads the sequences and the tables and asserts them.
codeunit 79546 "LT SQM NA"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure NAa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure NAb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        Access.TempRecord();
        Access.Builtins();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('NAb fails on purpose');
    end;

    [Test]
    procedure NAc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=missing | preview=missing | rows=INIT | entries=none | next=missing | preview next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'NA';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PA: new sequence: helper, guarded Codeunit.Run of a preview engine (Error('')), mixed kinds, Commit, Record write, then the test fails.
// PAa: Initialize only.
// PAb: the helper takes a number and inserts an entry, Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// PAc: reads the sequences and the tables and asserts them.
codeunit 79547 "LT SQM PA"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PAa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PAb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('PAb fails on purpose');
    end;

    [Test]
    procedure PAc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | pv=run: | name=missing | preview=missing | rows=INIT | entries=none | next=missing | preview next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PA';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PB: new sequence: helper, asserterror of a preview call (Error('')), mixed kinds, Commit, Record write, then the test fails.
// PBa: Initialize only.
// PBb: the helper takes a number and inserts an entry, asserterror of a call that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// PBc: reads the sequences and the tables and asserts them.
codeunit 79548 "LT SQM PB"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PBa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PBb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        asserterror Access.PreviewInline(Name());
        PreviewResult += 'asserterror:''' + GetLastErrorText() + '''';
        ClearLastError();
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('PBb fails on purpose');
    end;

    [Test]
    procedure PBc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | pv=asserterror:'''' | name=missing | preview=missing | rows=B1,INIT | entries=none | next=missing | preview next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PB';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PC: new sequence: PA with no Commit in the failed test.
// PCa: Initialize only.
// PCb: the helper takes a number and inserts an entry, Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Record insert B2, then fails.
// PCc: reads the sequences and the tables and asserts them.
codeunit 79549 "LT SQM PC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PCa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PCb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Access.InsertRow('B2');
        Error('PCb fails on purpose');
    end;

    [Test]
    procedure PCc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | pv=run: | name=missing | preview=missing | rows=INIT | entries=none | next=missing | preview next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PC';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PD: new sequence: helper, guarded Codeunit.Run of a preview engine that writes a row only, mixed kinds, Commit, Record write, then the test fails.
// PDa: Initialize only.
// PDb: the helper takes a number and inserts an entry, Codeunit.Run (return value used) of a preview engine that writes a row and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// PDc: reads the sequences and the tables and asserts them.
codeunit 79550 "LT SQM PD"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PDa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PDb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview('', 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('PDb fails on purpose');
    end;

    [Test]
    procedure PDc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | pv=run: | name=missing | preview=missing | rows=INIT | entries=none | next=missing | preview next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PD';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PE: raw insert, guarded Codeunit.Run of a preview engine that writes a row only, Commit, Record write, then the test fails.
// PEa: Initialize only.
// PEb: NumberSequence.Insert(Name, 0, 1, true) and Next, Codeunit.Run (return value used) of a preview engine that writes a row and ends with Error(''), Commit(), Record insert B2, then fails.
// PEc: reads the sequences and the tables and asserts them.
codeunit 79551 "LT SQM PE"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PEa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PEb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview('', 0);
        Commit();
        Access.InsertRow('B2');
        Error('PEb fails on purpose');
    end;

    [Test]
    procedure PEc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | pv=run:No:'''' | name=missing | preview=missing | rows=INIT | entries=none | next=missing | preview next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PE';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PN: new sequence: PA and the test passes (control).
// PNa: Initialize only.
// PNb: the helper takes a number and inserts an entry, Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2 (passes).
// PNc: reads the sequences and the tables and asserts them.
codeunit 79552 "LT SQM PN"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PNa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PNb_Passes()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
    end;

    [Test]
    procedure PNc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | pv=run: | name=missing | preview=missing | rows=INIT | entries=none | next=missing | preview next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PN';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XA: existing sequence: direct entry, helper restarts, mixed kinds, Commit, Record write, then the test fails.
// XAa: Initialize only (records the start state).
// XAb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// XAc: reads the sequences and the tables and asserts them.
codeunit 79553 "LT SQM XA"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure XAa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure XAb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.Rel(Name(), Base);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('XAb fails on purpose');
    end;

    [Test]
    procedure XAc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'onrun=found,found | initialized=Yes | start=cur=S,cur=S | changed=restart cur=S+6 | taken=S+6 | name=cur=S+6 | preview=cur=S-2000000003 | rows=B1,INIT | entries=S+5,S+6 | next=S+7 | preview next=S-2000000002 | name after=cur=S+7' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMXA');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XA';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XB: existing sequence: XA with no Commit in the failed test.
// XBa: Initialize only (records the start state).
// XBb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Record insert B2, then fails.
// XBc: reads the sequences and the tables and asserts them.
codeunit 79554 "LT SQM XB"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
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
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.Rel(Name(), Base);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Access.InsertRow('B2');
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
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'onrun=found,found | initialized=Yes | start=cur=S,cur=S | changed=restart cur=S+6 | taken=S+6 | name=cur=S | preview=cur=S | rows=INIT | entries=none | next=S+1 | preview next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMXB');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XB';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XC: existing sequence: XA plus Page.Run and Report.SaveAs Xml.
// XCa: Initialize only (records the start state).
// XCb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Page.Run of a card (PageHandler closes it), Report.SaveAs in Xml format, Commit(), Record insert B2, then fails.
// XCc: reads the sequences and the tables and asserts them.
codeunit 79555 "LT SQM XC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure XCa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    [HandlerFunctions('RowCardHandler')]
    procedure XCb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.Rel(Name(), Base);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Access.RunPage();
        Access.ReportXml();
        Commit();
        Access.InsertRow('B2');
        Error('XCb fails on purpose');
    end;

    [Test]
    procedure XCc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'onrun=found,found | initialized=Yes | start=cur=S,cur=S | changed=restart cur=S+6 | taken=S+6 | name=cur=S+6 | preview=cur=S-2000000003 | rows=B1,INIT | entries=S+5,S+6 | next=S+7 | preview next=S-2000000002 | name after=cur=S+7' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    [PageHandler]
    procedure RowCardHandler(var RowCard: TestPage "LT SQM Row Card")
    begin
        RowCard.Close();
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMXC');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XC';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XD: existing sequence: XA with a guarded Codeunit.Run of a preview engine after the restart.
// XDa: Initialize only (records the start state).
// XDb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// XDc: reads the sequences and the tables and asserts them.
codeunit 79556 "LT SQM XD"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure XDa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure XDb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.Rel(Name(), Base);
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('XDb fails on purpose');
    end;

    [Test]
    procedure XDc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'onrun=found,found | initialized=Yes | start=cur=S,cur=S | changed=restart cur=S+6 | taken=S+6 | pv=run: | name=cur=S | preview=cur=S | rows=INIT | entries=none | next=S+1 | preview next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMXD');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XD';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XE: existing sequence: XC with no Commit in the failed test.
// XEa: Initialize only (records the start state).
// XEb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Page.Run of a card (PageHandler closes it), Report.SaveAs in Xml format, Record insert B2, then fails.
// XEc: reads the sequences and the tables and asserts them.
codeunit 79557 "LT SQM XE"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure XEa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    [HandlerFunctions('RowCardHandler')]
    procedure XEb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.Rel(Name(), Base);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Access.RunPage();
        Access.ReportXml();
        Access.InsertRow('B2');
        Error('XEb fails on purpose');
    end;

    [Test]
    procedure XEc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'onrun=found,found | initialized=Yes | start=cur=S,cur=S | changed=restart cur=S+6 | taken=S+6 | name=cur=S | preview=cur=S | rows=INIT | entries=none | next=S+1 | preview next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    [PageHandler]
    procedure RowCardHandler(var RowCard: TestPage "LT SQM Row Card")
    begin
        RowCard.Close();
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMXE');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XE';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XN: existing sequence: raw Restart with a temporary Record, builtins and RecordRef calls (no table read or write), then the test fails.
// XNa: Initialize only (records the start state).
// XNb: NumberSequence.Restart(Name, S + 1000), a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), then fails.
// XNc: reads the sequences and the tables and asserts them.
codeunit 79558 "LT SQM XN"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
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
        NumberSequence.Restart(Name(), Base + 1000);
        ChangedState := Seq.Rel(Name(), Base);
        Access.TempRecord();
        Access.Builtins();
        Access.RecordRefExtra();
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
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'onrun=found,found | initialized=Yes | start=cur=S,cur=S | changed=cur=S+1000 | taken= | name=cur=S+1000 | preview=cur=S | rows=INIT | entries=none | next=S+1000 | preview next=S+1 | name after=cur=S+1000' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMXN');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XN';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XQ: existing sequence: raw Restart and a Query read, then the test fails.
// XQa: Initialize only (records the start state).
// XQb: NumberSequence.Restart(Name, S + 1000), a Query Open, Read, Close, then fails.
// XQc: reads the sequences and the tables and asserts them.
codeunit 79559 "LT SQM XQ"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure XQa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure XQb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Restart(Name(), Base + 1000);
        ChangedState := Seq.Rel(Name(), Base);
        Access.QueryRead();
        Error('XQb fails on purpose');
    end;

    [Test]
    procedure XQc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'onrun=found,found | initialized=Yes | start=cur=S,cur=S | changed=cur=S+1000 | taken= | name=cur=S | preview=cur=S | rows=INIT | entries=none | next=S+1 | preview next=S+1 | name after=cur=S+1' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMXQ');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XQ';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XP: existing sequence: XA and the test passes (control).
// XPa: Initialize only (records the start state).
// XPb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2 (passes).
// XPc: reads the sequences and the tables and asserts them.
codeunit 79560 "LT SQM XP"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure XPa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure XPb_Passes()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.Rel(Name(), Base);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
    end;

    [Test]
    procedure XPc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'onrun=found,found | initialized=Yes | start=cur=S,cur=S | changed=restart cur=S+6 | taken=S+6 | name=cur=S+6 | preview=cur=S-2000000003 | rows=B1,B2,INIT | entries=S+5,S+6 | next=S+7 | preview next=S-2000000002 | name after=cur=S+7' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMXP');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XP';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// FA: two failed tests: both commit after mixed access.
// FAa: Initialize only.
// FAb: the helper takes a number and inserts an entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// FAb2: the helper takes a number and inserts an entry, Record insert C1, a temporary Record (Insert, FindSet, Modify, DeleteAll), a Query Open, Read, Close, Commit(), Record insert C2, then fails.
// FAc: reads the sequences and the tables and asserts them.
codeunit 79561 "LT SQM FA"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure FAa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure FAb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('FAb fails on purpose');
    end;

    [Test]
    procedure FAb2_FailsAgain()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('C1');
        Access.TempRecord();
        Access.QueryRead();
        Commit();
        Access.InsertRow('C2');
        Error('FAb2 fails on purpose');
    end;

    [Test]
    procedure FAc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=2 | preview=cur=-2000000001 | rows=B1,C1,INIT | entries=1,2 | next=3 | preview next=-2000000000 | name after=cur=3' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'FA';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// FB: two failed tests: the first commits after mixed access, the second does not commit.
// FBa: Initialize only.
// FBb: the helper takes a number and inserts an entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// FBb2: the helper takes a number and inserts an entry, Record insert C1, a temporary Record (Insert, FindSet, Modify, DeleteAll), a Query Open, Read, Close, Record insert C2, then fails.
// FBc: reads the sequences and the tables and asserts them.
codeunit 79562 "LT SQM FB"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure FBa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure FBb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('FBb fails on purpose');
    end;

    [Test]
    procedure FBb2_FailsAgain()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('C1');
        Access.TempRecord();
        Access.QueryRead();
        Access.InsertRow('C2');
        Error('FBb2 fails on purpose');
    end;

    [Test]
    procedure FBc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=2 | preview=cur=-2000000001 | rows=B1,INIT | entries=1 | next=3 | preview next=-2000000000 | name after=cur=3' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'FB';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// FC: two failed tests: the first does not commit, the second commits after mixed access.
// FCa: Initialize only.
// FCb: the helper takes a number and inserts an entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Record insert B2, then fails.
// FCb2: the helper takes a number and inserts an entry, Record insert C1, a temporary Record (Insert, FindSet, Modify, DeleteAll), a Query Open, Read, Close, Commit(), Record insert C2, then fails.
// FCc: reads the sequences and the tables and asserts them.
codeunit 79563 "LT SQM FC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure FCa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure FCb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Access.InsertRow('B2');
        Error('FCb fails on purpose');
    end;

    [Test]
    procedure FCb2_FailsAgain()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('C1');
        Access.TempRecord();
        Access.QueryRead();
        Commit();
        Access.InsertRow('C2');
        Error('FCb2 fails on purpose');
    end;

    [Test]
    procedure FCc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=1 | preview=cur=-2000000001 | rows=C1,INIT | entries=1 | next=2 | preview next=-2000000000 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'FC';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// FD: two failed tests: the first commits after mixed access, the second only takes a number.
// FDa: Initialize only.
// FDb: the helper takes a number and inserts an entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// FDb2: NumberSequence.Next, then fails.
// FDc: reads the sequences and the tables and asserts them.
codeunit 79564 "LT SQM FD"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure FDa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure FDb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('FDb fails on purpose');
    end;

    [Test]
    procedure FDb2_FailsAgain()
    begin
        Initialize();
        if NumberSequence.Next(Name()) = 0 then;
        Error('FDb2 fails on purpose');
    end;

    [Test]
    procedure FDc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | name=cur=2 | preview=cur=-2000000001 | rows=B1,INIT | entries=1 | next=3 | preview next=-2000000000 | name after=cur=3' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'FD';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// FE: two failed tests, existing sequence: the first restarts and commits, the second restarts again with no commit.
// FEa: Initialize only (records the start state).
// FEb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// FEb2: an entry S + 20 inserted without the sequence, the helper takes a number (a second restart) and inserts the entry, Record insert C1, a temporary Record (Insert, FindSet, Modify, DeleteAll), a Query Open, Read, Close, Record insert C2, then fails.
// FEc: reads the sequences and the tables and asserts them.
codeunit 79565 "LT SQM FE"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure FEa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure FEb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.Rel(Name(), Base);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('FEb fails on purpose');
    end;

    [Test]
    procedure FEb2_FailsAgain()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 20, Cell);
        TakenNext += ',' + Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState += ',' + Seq.LastCreate() + ' ' + Seq.Rel(Name(), Base);
        Access.InsertRow('C1');
        Access.TempRecord();
        Access.QueryRead();
        Access.InsertRow('C2');
        Error('FEb2 fails on purpose');
    end;

    [Test]
    procedure FEc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'onrun=found,found | initialized=Yes | start=cur=S,cur=S | changed=restart cur=S+6,restart cur=S+21 | taken=S+6,S+21 | name=cur=S+6 | preview=cur=S-2000000003 | rows=B1,INIT | entries=S+5,S+6 | next=S+7 | preview next=S-2000000002 | name after=cur=S+7' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMFE');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'FE';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PF: new sequence: helper, guarded Codeunit.Run of an engine that ends normally, mixed kinds, Commit, Record write, then the test fails.
// PFa: Initialize only.
// PFb: the helper takes a number and inserts an entry, Codeunit.Run (return value used) of an engine that writes a row, takes a number through the helper and ends normally, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// PFc: reads the sequences and the tables and asserts them.
codeunit 79566 "LT SQM PF"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PFa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PFb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 1);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('PFb fails on purpose');
    end;

    [Test]
    procedure PFc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | pv=run: | name=missing | preview=missing | rows=INIT | entries=none | next=missing | preview next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PF';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PG: new sequence: helper, guarded Codeunit.Run of an engine that ends with an error text, mixed kinds, Commit, Record write, then the test fails.
// PGa: Initialize only.
// PGb: the helper takes a number and inserts an entry, Codeunit.Run (return value used) of an engine that writes a row, takes a number through the helper and ends with Error('preview engine error'), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// PGc: reads the sequences and the tables and asserts them.
codeunit 79567 "LT SQM PG"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PGa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PGb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 2);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('PGb fails on purpose');
    end;

    [Test]
    procedure PGc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | pv=run: | name=missing | preview=missing | rows=INIT | entries=none | next=missing | preview next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PG';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PH: new sequence: helper, Commit, guarded Codeunit.Run of a preview engine (Error('')), mixed kinds, Commit, Record write, then the test fails.
// PHa: Initialize only.
// PHb: the helper takes a number and inserts an entry, Commit(), Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// PHc: reads the sequences and the tables and asserts them.
codeunit 79568 "LT SQM PH"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PHa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PHb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Commit();
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('PHb fails on purpose');
    end;

    [Test]
    procedure PHc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | pv=run:No:'''' | name=cur=2 | preview=cur=-2000000001 | rows=B1,INIT | entries=1 | next=3 | preview next=-2000000000 | name after=cur=3' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PH';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PI: raw insert, guarded Codeunit.Run of a preview engine that takes a number (Error('')), mixed kinds, Commit, Record write, then the test fails.
// PIa: Initialize only.
// PIb: NumberSequence.Insert(Name, 0, 1, true) and Next, Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// PIc: reads the sequences and the tables and asserts them.
codeunit 79569 "LT SQM PI"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PIa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PIb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('PIb fails on purpose');
    end;

    [Test]
    procedure PIc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | pv=run:No:'''' | name=missing | preview=missing | rows=B1,INIT | entries=none | next=missing | preview next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PI';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PJ: raw insert, guarded Codeunit.Run of a preview engine that takes a number (Error('')), Commit, Record write, then the test fails.
// PJa: Initialize only.
// PJb: NumberSequence.Insert(Name, 0, 1, true) and Next, Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Commit(), Record insert B2, then fails.
// PJc: reads the sequences and the tables and asserts them.
codeunit 79570 "LT SQM PJ"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PJa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PJb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Commit();
        Access.InsertRow('B2');
        Error('PJb fails on purpose');
    end;

    [Test]
    procedure PJc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | pv=run:No:'''' | name=missing | preview=missing | rows=INIT | entries=none | next=missing | preview next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PJ';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XF: existing sequence: helper restarts, Commit, guarded Codeunit.Run of a preview engine that takes a number, mixed kinds, Commit, Record write, then the test fails.
// XFa: Initialize only (records the start state).
// XFb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Commit(), Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// XFc: reads the sequences and the tables and asserts them.
codeunit 79571 "LT SQM XF"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure XFa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure XFb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.Rel(Name(), Base);
        Commit();
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('XFb fails on purpose');
    end;

    [Test]
    procedure XFc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'onrun=found,found | initialized=Yes | start=cur=S,cur=S | changed=restart cur=S+6 | taken=S+6 | pv=run:No:'''' | name=cur=S+7 | preview=cur=S-2000000003 | rows=B1,INIT | entries=S+5,S+6 | next=S+8 | preview next=S-2000000002 | name after=cur=S+8' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMXF');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XF';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RR: new sequence: helper, Commit, a Record read, guarded Codeunit.Run of a preview engine (Error('')), mixed kinds, Commit, Record write, then the test fails (PH plus a read).
// RRa: Initialize only.
// RRb: the helper takes a number and inserts an entry, Commit(), a Record read (FindFirst on "LT SQM Row"), Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// RRc: reads the sequences and the tables and asserts them.
codeunit 79572 "LT SQM RR"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
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
        Seq.InsertEntry(Name(), Cell);
        Commit();
        Access.ReadRow();
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('RRb fails on purpose');
    end;

    [Test]
    procedure RRc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | pv=run:No:'''' | name=cur=2 | preview=cur=-2000000001 | rows=B1,INIT | entries=1 | next=3 | preview next=-2000000000 | name after=cur=3' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'RR';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RQ: new sequence: helper, Commit, a Query read, guarded Codeunit.Run of a preview engine (Error('')), mixed kinds, Commit, Record write, then the test fails (PH plus a Query read).
// RQa: Initialize only.
// RQb: the helper takes a number and inserts an entry, Commit(), a Query Open, Read, Close, Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// RQc: reads the sequences and the tables and asserts them.
codeunit 79573 "LT SQM RQ"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure RQa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RQb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Commit();
        Access.QueryRead();
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('RQb fails on purpose');
    end;

    [Test]
    procedure RQc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | pv=run:No:'''' | name=cur=2 | preview=cur=-2000000001 | rows=B1,INIT | entries=1 | next=3 | preview next=-2000000000 | name after=cur=3' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'RQ';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RL: new sequence: helper, Commit, a locking Record read, guarded Codeunit.Run of a preview engine (Error('')), mixed kinds, Commit, Record write, then the test fails (PH plus a locking read).
// RLa: Initialize only.
// RLb: the helper takes a number and inserts an entry, Commit(), a locking Record read (LockTable, then FindFirst on "LT SQM Row"), Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// RLc: reads the sequences and the tables and asserts them.
codeunit 79574 "LT SQM RL"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure RLa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure RLb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Commit();
        Access.ReadRowLocked();
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('RLb fails on purpose');
    end;

    [Test]
    procedure RLc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | pv=run: | name=cur=1 | preview=cur=-2000000001 | rows=INIT | entries=1 | next=2 | preview next=-2000000000 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'RL';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// RW: new sequence: helper, Commit, a Record write, guarded Codeunit.Run of a preview engine (Error('')), mixed kinds, Commit, Record write, then the test fails (PH plus a write).
// RWa: Initialize only.
// RWb: the helper takes a number and inserts an entry, Commit(), Record insert B0, Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// RWc: reads the sequences and the tables and asserts them.
codeunit 79575 "LT SQM RW"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
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
        Seq.InsertEntry(Name(), Cell);
        Commit();
        Access.InsertRow('B0');
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('RWb fails on purpose');
    end;

    [Test]
    procedure RWc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | pv=run: | name=cur=1 | preview=cur=-2000000001 | rows=INIT | entries=1 | next=2 | preview next=-2000000000 | name after=cur=2' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'RW';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PK: raw insert, guarded Codeunit.Run of a preview engine that takes no number (Error('')), mixed kinds, Commit, Record write, then the test fails (PI with an engine that takes no number).
// PKa: Initialize only.
// PKb: NumberSequence.Insert(Name, 0, 1, true) and Next, Codeunit.Run (return value used) of a preview engine that writes a row and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// PKc: reads the sequences and the tables and asserts them.
codeunit 79576 "LT SQM PK"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PKa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PKb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview('', 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('PKb fails on purpose');
    end;

    [Test]
    procedure PKc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | pv=run:No:'''' | name=missing | preview=missing | rows=B1,INIT | entries=none | next=missing | preview next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PK';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PT: new sequence: helper, Record write, asserterror of the guarded Codeunit.Run of an engine that ends normally, Commit, Record write, then the test fails.
// PTa: Initialize only.
// PTb: the helper takes a number and inserts an entry, Record insert B1, asserterror of Codeunit.Run (return value used) of an engine that writes a row and ends normally, Commit(), Record insert B2, then fails.
// PTc: reads the sequences and the tables and asserts them.
codeunit 79577 "LT SQM PT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PTa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PTb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        PreviewResult += 'run:';
        asserterror Access.RunPreview('', 1);
        PreviewResult += 'asserterror:''' + GetLastErrorText() + ''' code:''' + GetLastErrorCode() + '''';
        ClearLastError();
        Commit();
        Access.InsertRow('B2');
        Error('PTb fails on purpose');
    end;

    [Test]
    procedure PTc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'initialized=Yes | pv=run:asserterror:''An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.'' code:''DB:Ok'' | name=missing | preview=missing | rows=INIT | entries=none | next=missing | preview next=missing | name after=missing' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PT';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}
