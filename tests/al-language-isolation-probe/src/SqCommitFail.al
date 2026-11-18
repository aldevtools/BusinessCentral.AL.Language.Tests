namespace ALLanguage.IsolationProbe;

// HEADER-PLACEHOLDER

// C1 (spec P4): a test inserts a sequence, takes a number, calls Commit() and fails. The next test reads it.
codeunit 75885 "LT SQ C1 Commit Then Fail"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure C1a_InsertsCommitsFails()
    var
        Name: Text;
    begin
        Name := Log.Seq('C1');
        NumberSequence.Insert(Name, 1, 1);
        Log.Put('C1 first next', Format(NumberSequence.Next(Name)));
        Helper.InsertRow('C1-BEFORE');
        Commit();
        Helper.InsertRow('C1-AFTER');
        Error('C1a fails on purpose after Commit');
    end;

    [Test]
    procedure C1b_ReadsSequence()
    begin
        Log.Put('C1 rows', Helper.Rows('C1-BEFORE|C1-AFTER'));
        Helper.Read('C1 after', Log.Seq('C1'));
    end;
}

// C2 (spec P4): a passing test inserts a sequence, takes a number and calls Commit(); a later test fails without a
// Commit(); the test after it reads the sequence.
codeunit 75886 "LT SQ C2 Pass Commit Then Fail"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure C2a_InsertsCommitsPasses()
    var
        Name: Text;
    begin
        Name := Log.Seq('C2');
        NumberSequence.Insert(Name, 1, 1);
        Log.Put('C2 first next', Format(NumberSequence.Next(Name)));
        Commit();
    end;

    [Test]
    procedure C2b_Fails()
    begin
        Helper.InsertRow('C2-FAILED');
        Error('C2b fails on purpose');
    end;

    [Test]
    procedure C2c_ReadsSequence()
    begin
        Log.Put('C2 rows', Helper.Rows('C2-FAILED'));
        Helper.Read('C2 after', Log.Seq('C2'));
    end;
}

// C3 (spec P4): a test calls Commit() first, then inserts a sequence, takes a number and fails. The next test reads it.
codeunit 75887 "LT SQ C3 Commit Before Insert"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure C3a_CommitsInsertsFails()
    var
        Name: Text;
    begin
        Commit();
        Name := Log.Seq('C3');
        NumberSequence.Insert(Name, 1, 1);
        Log.Put('C3 first next', Format(NumberSequence.Next(Name)));
        Error('C3a fails on purpose after Insert');
    end;

    [Test]
    procedure C3b_ReadsSequence()
    begin
        Helper.Read('C3 after', Log.Seq('C3'));
    end;
}

// C4 (AL Runner issue 8152, the reporter's repro of 2026-11-18): rows take their key from a number sequence in OnInsert;
// the first test commits two rows and fails, the second inserts one more row.
codeunit 75888 "LT SQ C4 Keyed Rows Fail"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure C4a_CommitTwiceThenFail()
    var
        Entry: Record "LT SQ Entry";
    begin
        Log.SetEntrySequence('C4');
        Entry.DeleteAll();
        InsertEntry('committed 1');
        Commit();
        InsertEntry('committed 2');
        Commit();
        Error('C4a fails on purpose after two commits');
    end;

    [Test]
    procedure C4b_InsertAfterFailedTest()
    begin
        Log.SetEntrySequence('C4');
        Log.Put('C4 rows before', EntryNos());
        Log.Put('C4 inserted', Format(InsertEntry('after the failed test')));
        Log.Put('C4 rows after', EntryNos());
    end;

    local procedure InsertEntry(Description: Text[50]): Integer
    var
        Entry: Record "LT SQ Entry";
    begin
        Entry.Init();
        Entry.Description := Description;
        Entry.Insert(true);
        exit(Entry."Entry No.");
    end;

    local procedure EntryNos(): Text
    var
        Entry: Record "LT SQ Entry";
        Result: Text;
    begin
        if Entry.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Format(Entry."Entry No.");
            until Entry.Next() = 0;
        if Result = '' then
            exit('none');
        exit(Result);
    end;
}

// C4 control (the reporter's second codeunit): the same with a first test that passes.
codeunit 75889 "LT SQ C4 Keyed Rows Pass"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure C4c_CommitTwice()
    var
        Entry: Record "LT SQ Entry";
    begin
        Log.SetEntrySequence('C4P');
        Entry.DeleteAll();
        InsertEntry('committed 1');
        Commit();
        InsertEntry('committed 2');
        Commit();
    end;

    [Test]
    procedure C4d_InsertAfterPassedTest()
    begin
        Log.SetEntrySequence('C4P');
        Log.Put('C4P rows before', EntryNos());
        Log.Put('C4P inserted', Format(InsertEntry('after the passed test')));
    end;

    local procedure InsertEntry(Description: Text[50]): Integer
    var
        Entry: Record "LT SQ Entry";
    begin
        Entry.Init();
        Entry.Description := Description;
        Entry.Insert(true);
        exit(Entry."Entry No.");
    end;

    local procedure EntryNos(): Text
    var
        Entry: Record "LT SQ Entry";
        Result: Text;
    begin
        if Entry.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Format(Entry."Entry No.");
            until Entry.Next() = 0;
        if Result = '' then
            exit('none');
        exit(Result);
    end;
}

// C5 (review follow-up 2): the Commit() runs in a MessageHandler the test body triggers.
codeunit 75890 "LT SQ C5 Handler Commit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    [HandlerFunctions('MessageCommits')]
    procedure C5a_InsertsMessageFails()
    var
        Name: Text;
    begin
        Name := Log.Seq('C5');
        NumberSequence.Insert(Name, 1, 1);
        Log.Put('C5 first next', Format(NumberSequence.Next(Name)));
        Helper.InsertRow('C5-BEFORE');
        Message('C5 message');
        Log.Put('C5 write tx after handler', Format(Database.IsInWriteTransaction()));
        Error('C5a fails on purpose after the handler');
    end;

    [Test]
    procedure C5b_ReadsSequence()
    begin
        Log.Put('C5 rows', Helper.Rows('C5-BEFORE|C5-HANDLER'));
        Helper.Read('C5 after', Log.Seq('C5'));
    end;

    [MessageHandler]
    procedure MessageCommits(Msg: Text[1024])
    begin
        Log.Put('C5 handler ran', 'Yes');
        Helper.InsertRow('C5-HANDLER');
        Commit();
    end;
}

// C6 (review follow-up 2): a guarded Codeunit.Run in the test body (it runs in a transaction of its own), then the test fails.
codeunit 75891 "LT SQ C6 Guarded Run"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure C6a_InsertsRunsFails()
    var
        Name: Text;
    begin
        Name := Log.Seq('C6');
        NumberSequence.Insert(Name, 1, 1);
        Log.Put('C6 first next', Format(NumberSequence.Next(Name)));
        Log.Put('C6 write tx before run', Format(Database.IsInWriteTransaction()));
        Log.Put('C6 run', Format(Codeunit.Run(Codeunit::"LT SQ Helper")));
        Log.Put('C6 run error', GetLastErrorText());
        Error('C6a fails on purpose after Codeunit.Run');
    end;

    [Test]
    procedure C6b_ReadsSequence()
    begin
        Log.Put('C6 rows', Helper.Rows('C6-RUN'));
        Helper.Read('C6 after', Log.Seq('C6'));
    end;
}

// C7 (review follow-up 2): an isolated event (IntegrationEvent Isolated = true) whose subscriber writes a row, raised in
// the test body, then the test fails.
codeunit 75892 "LT SQ C7 Isolated Subscriber"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure C7a_InsertsRaisesFails()
    var
        Name: Text;
    begin
        Name := Log.Seq('C7');
        NumberSequence.Insert(Name, 1, 1);
        Log.Put('C7 first next', Format(NumberSequence.Next(Name)));
        Helper.RaiseIsolated();
        Log.Put('C7 write tx after event', Format(Database.IsInWriteTransaction()));
        Error('C7a fails on purpose after the isolated event');
    end;

    [Test]
    procedure C7b_ReadsSequence()
    begin
        Log.Put('C7 rows', Helper.Rows('C7-SUB'));
        Helper.Read('C7 after', Log.Seq('C7'));
    end;
}

// C8 (review follow-up 2): the test codeunit's OnRun writes a row and calls Commit(); a test inserts a sequence and fails;
// the next test reads it.
codeunit 75893 "LT SQ C8 OnRun Commit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        Row: Record "LT SQ Row";
    begin
        Row."Key" := 'C8-ONRUN';
        if Row.Insert() then;
        Commit();
    end;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure C8a_InsertsFails()
    var
        Name: Text;
    begin
        Name := Log.Seq('C8');
        NumberSequence.Insert(Name, 1, 1);
        Log.Put('C8 first next', Format(NumberSequence.Next(Name)));
        Error('C8a fails on purpose');
    end;

    [Test]
    procedure C8b_ReadsSequence()
    begin
        Helper.Read('C8 after', Log.Seq('C8'));
    end;
}

// C9 (review neighbor N3): a TransactionModel None test passes (the runner commits around it), then a test inserts a
// sequence and fails, then a test reads it.
codeunit 75894 "LT SQ C9 TxNone Then Fail"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure C9a_TxNonePasses()
    begin
    end;

    [Test]
    procedure C9b_InsertsFails()
    var
        Name: Text;
    begin
        Name := Log.Seq('C9');
        NumberSequence.Insert(Name, 1, 1);
        Log.Put('C9 first next', Format(NumberSequence.Next(Name)));
        Error('C9b fails on purpose');
    end;

    [Test]
    procedure C9c_ReadsSequence()
    begin
        Helper.Read('C9 after', Log.Seq('C9'));
    end;
}

// C10 (review neighbor N5): a test inserts a sequence and fails without a Commit(); a later test calls Commit(); then a
// test reads the sequence.
codeunit 75895 "LT SQ C10 Commit After Fail"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure C10a_InsertsFails()
    var
        Name: Text;
    begin
        Name := Log.Seq('C10');
        NumberSequence.Insert(Name, 1, 1);
        Log.Put('C10 first next', Format(NumberSequence.Next(Name)));
        Error('C10a fails on purpose');
    end;

    [Test]
    procedure C10b_Commits()
    begin
        Log.Put('C10 state before commit', Helper.State(Log.Seq('C10')));
        Helper.InsertRow('C10-COMMIT');
        Commit();
    end;

    [Test]
    procedure C10c_ReadsSequence()
    begin
        Helper.Read('C10 after', Log.Seq('C10'));
    end;
}

// C11, first codeunit (review neighbor N6): a Commit() only in an earlier test codeunit.
codeunit 75896 "LT SQ C11 Other Commits"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure C11a_Commits()
    begin
        Helper.InsertRow('C11-COMMIT');
        Commit();
    end;
}

// C11, second codeunit (review neighbor N6): no Commit() in this codeunit; a test inserts a sequence and fails, the next
// test reads it.
codeunit 75897 "LT SQ C11 Fresh Codeunit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure C11b_InsertsFails()
    var
        Name: Text;
    begin
        Name := Log.Seq('C11');
        NumberSequence.Insert(Name, 1, 1);
        Log.Put('C11 first next', Format(NumberSequence.Next(Name)));
        Error('C11b fails on purpose');
    end;

    [Test]
    procedure C11c_ReadsSequence()
    begin
        Helper.Read('C11 after', Log.Seq('C11'));
    end;
}

// C12 (review neighbor N8): a Commit() under [CommitBehavior(CommitBehavior::Ignore)] in the test body, then the test fails.
codeunit 75898 "LT SQ C12 Ignored Commit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure C12a_InsertsIgnoredCommitFails()
    var
        Name: Text;
    begin
        Name := Log.Seq('C12');
        NumberSequence.Insert(Name, 1, 1);
        Log.Put('C12 first next', Format(NumberSequence.Next(Name)));
        Helper.IgnoredCommit();
        Log.Put('C12 write tx after ignored commit', Format(Database.IsInWriteTransaction()));
        Error('C12a fails on purpose after an ignored Commit');
    end;

    [Test]
    procedure C12b_ReadsSequence()
    begin
        Log.Put('C12 rows', Helper.Rows('C12-IGNORED'));
        Helper.Read('C12 after', Log.Seq('C12'));
    end;
}

// C13, the control without any Commit(): a test inserts a sequence and fails, the next test reads it.
codeunit 75899 "LT SQ C13 No Commit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure C13a_InsertsFails()
    var
        Name: Text;
    begin
        Name := Log.Seq('C13');
        NumberSequence.Insert(Name, 1, 1);
        Log.Put('C13 first next', Format(NumberSequence.Next(Name)));
        Error('C13a fails on purpose');
    end;

    [Test]
    procedure C13b_ReadsSequence()
    begin
        Helper.Read('C13 after', Log.Seq('C13'));
    end;
}

// C14 (ERM Intercompany shape, review of runner PR 8363): the first test's Initialize commits; a later passing test inserts the
// sequence; a later test fails; the test after it reads the sequence.
codeunit 75900 "LT SQ C14 ERM Insert Later"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    IsInitialized: Boolean;

    [Test]
    procedure C14a_InitializeCommits()
    begin
        Initialize();
    end;

    [Test]
    procedure C14b_TakesNumber()
    begin
        Initialize();
        Log.Put('C14 first no', Format(GetNextNo()));
    end;

    [Test]
    procedure C14c_Fails()
    begin
        Initialize();
        Helper.InsertRow('C14-FAILED');
        Error('C14c fails on purpose');
    end;

    [Test]
    procedure C14d_ReadsSequence()
    begin
        Initialize();
        Log.Put('C14 rows', Helper.Rows('C14-INIT|C14-FAILED'));
        Log.Put('C14 after state', Helper.State(Log.Seq('C14')));
        Log.Put('C14 after no', Format(GetNextNo()));
    end;

    // ERM Intercompany's Initialize (Tests-ERM codeunit 134151): every test calls it first; only the first call commits.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        Helper.InsertRow('C14-INIT');
        IsInitialized := true;
        Commit();
    end;

    // The sequence code of IC Inbox Outbox Mgt. (GetNextICTransactionNo): insert at seed 0 when missing, burn the seed,
    // then take the next number.
    local procedure GetNextNo(): BigInteger
    var
        Name: Text;
    begin
        Name := Log.Seq('C14');
        if not NumberSequence.Exists(Name) then begin
            NumberSequence.Insert(Name, 0, 1);
            if NumberSequence.Next(Name) = 0 then;
        end;
        exit(NumberSequence.Next(Name));
    end;
}

// C15 (ERM Intercompany shape): the first test's Initialize commits; a later test inserts the sequence, takes a number and
// fails; the test after it reads the sequence.
codeunit 75901 "LT SQ C15 ERM Insert Fails"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    IsInitialized: Boolean;

    [Test]
    procedure C15a_InitializeCommits()
    begin
        Initialize();
    end;

    [Test]
    procedure C15b_TakesNumberFails()
    begin
        Initialize();
        Log.Put('C15 first no', Format(GetNextNo()));
        Error('C15b fails on purpose');
    end;

    [Test]
    procedure C15c_ReadsSequence()
    begin
        Initialize();
        Log.Put('C15 after state', Helper.State(Log.Seq('C15')));
        Log.Put('C15 after no', Format(GetNextNo()));
    end;

    // ERM Intercompany's Initialize (Tests-ERM codeunit 134151): every test calls it first; only the first call commits.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        Helper.InsertRow('C15-INIT');
        IsInitialized := true;
        Commit();
    end;

    // The sequence code of IC Inbox Outbox Mgt. (GetNextICTransactionNo): insert at seed 0 when missing, burn the seed,
    // then take the next number.
    local procedure GetNextNo(): BigInteger
    var
        Name: Text;
    begin
        Name := Log.Seq('C15');
        if not NumberSequence.Exists(Name) then begin
            NumberSequence.Insert(Name, 0, 1);
            if NumberSequence.Next(Name) = 0 then;
        end;
        exit(NumberSequence.Next(Name));
    end;
}

// C16 (ERM Intercompany shape): the first test's Initialize commits and the same test then inserts the sequence and takes a
// number; a later test fails; the test after it reads the sequence.
codeunit 75902 "LT SQ C16 ERM Same Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    IsInitialized: Boolean;

    [Test]
    procedure C16a_InitializeTakesNumber()
    begin
        Initialize();
        Log.Put('C16 first no', Format(GetNextNo()));
    end;

    [Test]
    procedure C16b_Fails()
    begin
        Initialize();
        Error('C16b fails on purpose');
    end;

    [Test]
    procedure C16c_ReadsSequence()
    begin
        Initialize();
        Log.Put('C16 after state', Helper.State(Log.Seq('C16')));
        Log.Put('C16 after no', Format(GetNextNo()));
    end;

    // ERM Intercompany's Initialize (Tests-ERM codeunit 134151): every test calls it first; only the first call commits.
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        Helper.InsertRow('C16-INIT');
        IsInitialized := true;
        Commit();
    end;

    // The sequence code of IC Inbox Outbox Mgt. (GetNextICTransactionNo): insert at seed 0 when missing, burn the seed,
    // then take the next number.
    local procedure GetNextNo(): BigInteger
    var
        Name: Text;
    begin
        Name := Log.Seq('C16');
        if not NumberSequence.Exists(Name) then begin
            NumberSequence.Insert(Name, 0, 1);
            if NumberSequence.Next(Name) = 0 then;
        end;
        exit(NumberSequence.Next(Name));
    end;
}

// D1: a passing test writes a row without a Commit(); a later passing test inserts a sequence; a later test fails without a
// write; the test after it reads the sequence and the row.
codeunit 75914 "LT SQ D1 Row Earlier Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure D1a_WritesRow()
    begin
        Helper.InsertRow('D1-ROW');
    end;

    [Test]
    procedure D1b_InsertsSequence()
    var
        Name: Text;
    begin
        Log.Put('D1 write tx at start', Format(Database.IsInWriteTransaction()));
        Name := Log.Seq('D1');
        NumberSequence.Insert(Name, 1, 1);
        Log.Put('D1 first next', Format(NumberSequence.Next(Name)));
    end;

    [Test]
    procedure D1c_Fails()
    begin
        Error('D1c fails on purpose');
    end;

    [Test]
    procedure D1d_ReadsSequence()
    begin
        Log.Put('D1 rows', Helper.Rows('D1-ROW'));
        Helper.Read('D1 after', Log.Seq('D1'));
    end;
}

// D2: a passing test writes a row and calls Commit(); a later passing test inserts a sequence; a later test fails without a
// write; the test after it reads the sequence and the row.
codeunit 75915 "LT SQ D2 Row Commit Earlier"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure D2a_WritesRowCommits()
    begin
        Helper.InsertRow('D2-ROW');
        Commit();
    end;

    [Test]
    procedure D2b_InsertsSequence()
    var
        Name: Text;
    begin
        Name := Log.Seq('D2');
        NumberSequence.Insert(Name, 1, 1);
        Log.Put('D2 first next', Format(NumberSequence.Next(Name)));
    end;

    [Test]
    procedure D2c_Fails()
    begin
        Error('D2c fails on purpose');
    end;

    [Test]
    procedure D2d_ReadsSequence()
    begin
        Log.Put('D2 rows', Helper.Rows('D2-ROW'));
        Helper.Read('D2 after', Log.Seq('D2'));
    end;
}

// D3: a passing test writes a row without a Commit(); the next test inserts a sequence and fails without a write of its
// own; the test after it reads the sequence and the row.
codeunit 75916 "LT SQ D3 Row Then Insert Fail"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure D3a_WritesRow()
    begin
        Helper.InsertRow('D3-ROW');
    end;

    [Test]
    procedure D3b_InsertsFails()
    var
        Name: Text;
    begin
        Name := Log.Seq('D3');
        NumberSequence.Insert(Name, 1, 1);
        Log.Put('D3 first next', Format(NumberSequence.Next(Name)));
        Error('D3b fails on purpose');
    end;

    [Test]
    procedure D3c_ReadsSequence()
    begin
        Log.Put('D3 rows', Helper.Rows('D3-ROW'));
        Helper.Read('D3 after', Log.Seq('D3'));
    end;
}

// B1 (spec P4b): Restart(500) of a sequence that existed when the tests began, Commit(), then the test fails.
codeunit 75903 "LT SQ B1 Restart Commit Fail"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists when the tests begin: OnRun makes it (once per session) and takes two numbers (Current 2).
    trigger OnRun()
    var
        Name: Text;
    begin
        Name := Log.Seq('B1');
        if not NumberSequence.Exists(Name) then begin
            NumberSequence.Insert(Name, 1, 1);
            if NumberSequence.Next(Name) = 0 then;
            if NumberSequence.Next(Name) = 0 then;
        end;
        Log.Put('B1 onrun state', Helper.State(Name));
    end;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure B1a_ChangesThenFails()
    var
        Name: Text;
    begin
        Name := Log.Seq('B1');
        Log.Put('B1 start state', Helper.State(Name));
        NumberSequence.Restart(Name, 500);
        Log.Put('B1 changed state', Helper.State(Name));
        Commit();
        Error('B1a fails on purpose');
    end;

    [Test]
    procedure B1b_ReadsSequence()
    begin
        Helper.Read('B1 after', Log.Seq('B1'));
    end;
}

// B2 (spec P4b): Delete of a sequence that existed when the tests began, Commit(), then the test fails.
codeunit 75904 "LT SQ B2 Delete Commit Fail"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists when the tests begin: OnRun makes it (once per session) and takes two numbers (Current 2).
    trigger OnRun()
    var
        Name: Text;
    begin
        Name := Log.Seq('B2');
        if not NumberSequence.Exists(Name) then begin
            NumberSequence.Insert(Name, 1, 1);
            if NumberSequence.Next(Name) = 0 then;
            if NumberSequence.Next(Name) = 0 then;
        end;
        Log.Put('B2 onrun state', Helper.State(Name));
    end;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure B2a_ChangesThenFails()
    var
        Name: Text;
    begin
        Name := Log.Seq('B2');
        Log.Put('B2 start state', Helper.State(Name));
        NumberSequence.Delete(Name);
        Log.Put('B2 changed state', Helper.State(Name));
        Commit();
        Error('B2a fails on purpose');
    end;

    [Test]
    procedure B2b_ReadsSequence()
    begin
        Helper.Read('B2 after', Log.Seq('B2'));
    end;
}

// B3 (spec P4b): Restart(500) of a sequence that existed when the tests began, then the test fails without a Commit().
codeunit 75905 "LT SQ B3 Restart Fail"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists when the tests begin: OnRun makes it (once per session) and takes two numbers (Current 2).
    trigger OnRun()
    var
        Name: Text;
    begin
        Name := Log.Seq('B3');
        if not NumberSequence.Exists(Name) then begin
            NumberSequence.Insert(Name, 1, 1);
            if NumberSequence.Next(Name) = 0 then;
            if NumberSequence.Next(Name) = 0 then;
        end;
        Log.Put('B3 onrun state', Helper.State(Name));
    end;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure B3a_ChangesThenFails()
    var
        Name: Text;
    begin
        Name := Log.Seq('B3');
        Log.Put('B3 start state', Helper.State(Name));
        NumberSequence.Restart(Name, 500);
        Log.Put('B3 changed state', Helper.State(Name));
        Error('B3a fails on purpose');
    end;

    [Test]
    procedure B3b_ReadsSequence()
    begin
        Helper.Read('B3 after', Log.Seq('B3'));
    end;
}

// B4 (spec P4b): Delete of a sequence that existed when the tests began, then the test fails without a Commit().
codeunit 75906 "LT SQ B4 Delete Fail"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists when the tests begin: OnRun makes it (once per session) and takes two numbers (Current 2).
    trigger OnRun()
    var
        Name: Text;
    begin
        Name := Log.Seq('B4');
        if not NumberSequence.Exists(Name) then begin
            NumberSequence.Insert(Name, 1, 1);
            if NumberSequence.Next(Name) = 0 then;
            if NumberSequence.Next(Name) = 0 then;
        end;
        Log.Put('B4 onrun state', Helper.State(Name));
    end;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure B4a_ChangesThenFails()
    var
        Name: Text;
    begin
        Name := Log.Seq('B4');
        Log.Put('B4 start state', Helper.State(Name));
        NumberSequence.Delete(Name);
        Log.Put('B4 changed state', Helper.State(Name));
        Error('B4a fails on purpose');
    end;

    [Test]
    procedure B4b_ReadsSequence()
    begin
        Helper.Read('B4 after', Log.Seq('B4'));
    end;
}

// B5 (spec P4b): Next of a sequence that existed when the tests began, Commit(), then the test fails.
codeunit 75907 "LT SQ B5 Next Commit Fail"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists when the tests begin: OnRun makes it (once per session) and takes two numbers (Current 2).
    trigger OnRun()
    var
        Name: Text;
    begin
        Name := Log.Seq('B5');
        if not NumberSequence.Exists(Name) then begin
            NumberSequence.Insert(Name, 1, 1);
            if NumberSequence.Next(Name) = 0 then;
            if NumberSequence.Next(Name) = 0 then;
        end;
        Log.Put('B5 onrun state', Helper.State(Name));
    end;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure B5a_ChangesThenFails()
    var
        Name: Text;
    begin
        Name := Log.Seq('B5');
        Log.Put('B5 start state', Helper.State(Name));
        Log.Put('B5 taken', Format(NumberSequence.Next(Name)));
        Log.Put('B5 changed state', Helper.State(Name));
        Commit();
        Error('B5a fails on purpose');
    end;

    [Test]
    procedure B5b_ReadsSequence()
    begin
        Helper.Read('B5 after', Log.Seq('B5'));
    end;
}

// B6 (spec P4b): Next of a sequence that existed when the tests began, then the test fails without a Commit().
codeunit 75908 "LT SQ B6 Next Fail"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists when the tests begin: OnRun makes it (once per session) and takes two numbers (Current 2).
    trigger OnRun()
    var
        Name: Text;
    begin
        Name := Log.Seq('B6');
        if not NumberSequence.Exists(Name) then begin
            NumberSequence.Insert(Name, 1, 1);
            if NumberSequence.Next(Name) = 0 then;
            if NumberSequence.Next(Name) = 0 then;
        end;
        Log.Put('B6 onrun state', Helper.State(Name));
    end;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    [Test]
    procedure B6a_ChangesThenFails()
    var
        Name: Text;
    begin
        Name := Log.Seq('B6');
        Log.Put('B6 start state', Helper.State(Name));
        Log.Put('B6 taken', Format(NumberSequence.Next(Name)));
        Log.Put('B6 changed state', Helper.State(Name));
        Error('B6a fails on purpose');
    end;

    [Test]
    procedure B6b_ReadsSequence()
    begin
        Helper.Read('B6 after', Log.Seq('B6'));
    end;
}
