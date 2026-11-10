// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 97280 and 97281, codeunits 97280 and 97281
// local object: the tests must commit (Commit and Codeunit.Run with a return value) and need a secondary key on a Guid field.
// Probe: al-runner issue 6924 (reporter waldo, the shape behind 56 refused scanner posting tests). Observation form: every test ends with
// Observer.Finish(); the values come from the CI legs 27.5, 28.5 and 29.0.
// The sequence, on own table "REC Stale2C User" (PK Code, Guid "Session Key" with a secondary key, DateTime "Last Action", option
// "Post Mode", OnModify and OnValidate triggers that do nothing):
//   1. U (the test's variable): Init, Validate("Location Code"), Insert(true), Validate(Enabled, true), Modify(true).
//   2. A log row is inserted into another table, then Commit (commit A). Then `if Codeunit.Run(Login, Arg)`: the Login codeunit gets the
//      row by Code into its own variable U2, assigns a new "Session Key" and calls Modify(true). With the return value used, the Run runs
//      in its own transaction (commit B on success). Then U3: SetCurrentKey("Session Key"), SetRange on the key the Login codeunit wrote,
//      FindFirst, "Last Action" := a fixed DateTime, Modify(true). The log row is modified.
//   3. Back on U (its buffer predates commits A and B): "Post Mode" := Yes, Modify(true).
// Each test observes whether the final Modify raises (the _Plain test runs it bare, the _AssertError test runs it under asserterror and
// records GetLastErrorText and GetLastErrorCode), then the stored row and U's buffer as SessionKey|LastAction|PostMode|Enabled|Location.
// SessionKey: empty, login (the key the Login codeunit or the inline U2 wrote) or other. LastAction: blank, U3 (the value U3 wrote) or other.
// Variants: without commit A; without commit A with Codeunit.Run without return value and an explicit Commit after it; without the
// Codeunit.Run (U2 written inline, with and without a Commit after it); only U2 writes; only U3 writes; the final write with Modify(false);
// a Get on U before step 3 (contrast); whether Codeunit.Run with a return value commits U2's write (an asserterror Error after it).
// Already pinned elsewhere (this file measures only what they leave open):
//   - record/crud/Y27StaleOwnInsertMore.al WA_Stale_Waldo_* (waldo run 2): the same idea with Codeunit.Run WITHOUT a return value, one
//     explicit Commit before it (after a Get), the third variable found by its primary key, no log row: the final write is accepted and
//     writes U's whole buffer; with an explicit Commit after the Run and no third write it is refused with DB:RecordChanged.
//   - record/crud/Y27StaleOtherVarTests.al: 1 to 3 Commits after the Insert, the new transaction modified the row through another variable:
//     accepted, the stale buffer wins; nothing in the new transaction: DB:RecordChanged.
//   - record/crud/SbStaleOwnModify.al, record/crud/Y76StaleBuffers.al, record/TestRecordStaleBufferWrite.al: the rules for a buffer of its
//     own Insert and Modify, one Commit, other rows and other tables.
// New here: Codeunit.Run WITH a return value (its own transaction), a log row inserted before commit A and modified after U3, and U3
// found through a secondary key on the value U2 wrote.
// BC versions: 27+

table 97280 "REC Stale2C User"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Location Code"; Code[10])
        {
            trigger OnValidate()
            begin
            end;
        }
        field(3; Enabled; Boolean)
        {
            trigger OnValidate()
            begin
            end;
        }
        field(4; "Session Key"; Guid) { }
        field(5; "Last Action"; DateTime) { }
        field(6; "Post Mode"; Option)
        {
            OptionMembers = Blank,No,Yes;
        }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
        key(SessionKey; "Session Key") { }
    }

    trigger OnModify()
    begin
    end;
}

// The log table of the sequence; a temporary record of it is also the argument of the Login codeunit ("Write Key" in, "Session Key" out).
table 97281 "REC Stale2C Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; "User Code"; Code[20]) { }
        field(3; Step; Text[30]) { }
        field(4; "Write Key"; Boolean) { }
        field(5; "Session Key"; Guid) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

// U2: gets the user by code into its own variable; when Rec."Write Key" is set, assigns a new "Session Key" and calls Modify(true).
// Returns the row's "Session Key" after its step in Rec."Session Key".
codeunit 97280 "REC Stale2C Login"
{
    TableNo = "REC Stale2C Log";

    trigger OnRun()
    var
        U2: Record "REC Stale2C User";
    begin
        U2.Get(Rec."User Code");
        if Rec."Write Key" then begin
            U2."Session Key" := CreateGuid();
            U2.Modify(true);
        end;
        Rec."Session Key" := U2."Session Key";
    end;
}

codeunit 97281 "REC Stale2C Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ArgKeyReturned: Boolean;

    // U2's step (Mode): 1 = `if Codeunit.Run(...)` (return value used), 2 = Codeunit.Run(...) as a statement, 3 = inline in this codeunit.
    local procedure UserCode(): Code[20]
    begin
        exit('U6924');
    end;

    local procedure U3Time(): DateTime
    begin
        exit(CreateDateTime(20260102D, 090000T));
    end;

    local procedure Reset()
    var
        Users: Record "REC Stale2C User";
        Logs: Record "REC Stale2C Log";
    begin
        Users.DeleteAll();
        Logs.DeleteAll();
        Commit();
    end;

    // Step 1 on the test's own variable.
    local procedure CreateUser(var U: Record "REC Stale2C User")
    begin
        U.Init();
        U."Code" := UserCode();
        U.Validate("Location Code", 'MAIN');
        U.Insert(true);
        U.Validate(Enabled, true);
        U.Modify(true);
    end;

    local procedure InsertLog(): Integer
    var
        Log: Record "REC Stale2C Log";
    begin
        Log.Init();
        Log."User Code" := UserCode();
        Log.Step := 'init';
        Log.Insert();
        exit(Log."Entry No.");
    end;

    local procedure UpdateLog(EntryNo: Integer)
    var
        Log: Record "REC Stale2C Log";
    begin
        Log.Get(EntryNo);
        Log.Step := 'final';
        Log.Modify();
    end;

    // U2's step. RunWithReturn: `if Codeunit.Run(...)`; RunNoReturn: Codeunit.Run(...) as a statement; Inline: the same Get and Modify(true)
    // in this codeunit. Returns the row's "Session Key" after the step; RunOk is the return value of Codeunit.Run (true otherwise).
    local procedure Login(Mode: Integer; WriteKey: Boolean; var KeyAfter: Guid) RunOk: Boolean
    var
        Arg: Record "REC Stale2C Log" temporary;
        U2: Record "REC Stale2C User";
    begin
        RunOk := true;
        case Mode of
            1:
                begin
                    Arg."User Code" := UserCode();
                    Arg."Write Key" := WriteKey;
                    if Codeunit.Run(Codeunit::"REC Stale2C Login", Arg) then
                        RunOk := true
                    else
                        RunOk := false;
                    KeyAfter := KeyFromArg(Arg, WriteKey);
                end;
            2:
                begin
                    Arg."User Code" := UserCode();
                    Arg."Write Key" := WriteKey;
                    Codeunit.Run(Codeunit::"REC Stale2C Login", Arg);
                    KeyAfter := KeyFromArg(Arg, WriteKey);
                end;
            3:
                begin
                    U2.Get(UserCode());
                    if WriteKey then begin
                        U2."Session Key" := CreateGuid();
                        U2.Modify(true);
                    end;
                    KeyAfter := U2."Session Key";
                end;
        end;
    end;

    // The key the Login codeunit returned in Arg. Should Arg come back without it after a write, the key is read from the stored row by another
    // variable (a Get only) so U3 can still find the row; 'argkey' records which happened.
    local procedure KeyFromArg(var Arg: Record "REC Stale2C Log" temporary; WriteKey: Boolean): Guid
    var
        Stored: Record "REC Stale2C User";
    begin
        if IsNullGuid(Arg."Session Key") and WriteKey then begin
            ArgKeyReturned := false;
            Stored.Get(UserCode());
            exit(Stored."Session Key");
        end;
        ArgKeyReturned := true;
        exit(Arg."Session Key");
    end;

    // U3's step: finds the row through the secondary key on the key U2 left, and (when Write) sets "Last Action" and calls Modify(true).
    local procedure Finalize(KeyAfter: Guid; Write: Boolean)
    var
        U3: Record "REC Stale2C User";
    begin
        U3.SetCurrentKey("Session Key");
        U3.SetRange("Session Key", KeyAfter);
        U3.FindFirst();
        if Write then begin
            U3."Last Action" := U3Time();
            U3.Modify(true);
        end;
    end;

    // Steps 1 and 2. CommitA: the Commit after the log row. CommitAfterLogin: an explicit Commit right after U2's step.
    local procedure Prepare(var U: Record "REC Stale2C User"; var KeyAfter: Guid; var Observer: Codeunit "Probe Observer"; CommitA: Boolean; Mode: Integer; U2Writes: Boolean; CommitAfterLogin: Boolean; U3Writes: Boolean)
    var
        EntryNo: Integer;
    begin
        Reset();
        CreateUser(U);
        EntryNo := InsertLog();
        if CommitA then
            Commit();
        ArgKeyReturned := true;
        Observer.Observe('run', Format(Login(Mode, U2Writes, KeyAfter)));
        Observer.Observe('argkey', Format(ArgKeyReturned));
        if CommitAfterLogin then
            Commit();
        Finalize(KeyAfter, U3Writes);
        UpdateLog(EntryNo);
    end;

    // Step 3 on the stale buffer.
    local procedure FinalWrite(var U: Record "REC Stale2C User"; RunTrigger: Boolean)
    begin
        U."Post Mode" := U."Post Mode"::Yes;
        U.Modify(RunTrigger);
    end;

    local procedure KeyText(Value: Guid; KeyAfter: Guid): Text
    begin
        if IsNullGuid(Value) then
            exit('empty');
        if Value = KeyAfter then
            exit('login');
        exit('other');
    end;

    local procedure TimeText(Value: DateTime): Text
    begin
        if Value = 0DT then
            exit('blank');
        if Value = U3Time() then
            exit('U3');
        exit('other');
    end;

    local procedure Describe(Row: Record "REC Stale2C User"; KeyAfter: Guid): Text
    begin
        exit(KeyText(Row."Session Key", KeyAfter) + '|' + TimeText(Row."Last Action") + '|' + Format(Row."Post Mode") + '|' +
            Format(Row.Enabled) + '|' + Row."Location Code");
    end;

    local procedure ObserveRow(var Observer: Codeunit "Probe Observer"; var U: Record "REC Stale2C User"; KeyAfter: Guid)
    var
        Stored: Record "REC Stale2C User";
    begin
        Observer.Observe('buffer', Describe(U, KeyAfter));
        if Stored.Get(UserCode()) then
            Observer.Observe('stored', Describe(Stored, KeyAfter))
        else
            Observer.Observe('stored', 'missing');
        Reset();
    end;

    local procedure RunPlain(CommitA: Boolean; Mode: Integer; U2Writes: Boolean; CommitAfterLogin: Boolean; U3Writes: Boolean; RunTrigger: Boolean)
    var
        U: Record "REC Stale2C User";
        Observer: Codeunit "Probe Observer";
        KeyAfter: Guid;
    begin
        Prepare(U, KeyAfter, Observer, CommitA, Mode, U2Writes, CommitAfterLogin, U3Writes);
        FinalWrite(U, RunTrigger);
        Observer.Observe('write', 'ok');
        ObserveRow(Observer, U, KeyAfter);
        Observer.Finish();
    end;

    local procedure RunAssertError(CommitA: Boolean; Mode: Integer; U2Writes: Boolean; CommitAfterLogin: Boolean; U3Writes: Boolean; RunTrigger: Boolean)
    var
        U: Record "REC Stale2C User";
        Observer: Codeunit "Probe Observer";
        KeyAfter: Guid;
    begin
        Prepare(U, KeyAfter, Observer, CommitA, Mode, U2Writes, CommitAfterLogin, U3Writes);
        asserterror FinalWrite(U, RunTrigger);
        Observer.ObserveError('write');
        ObserveRow(Observer, U, KeyAfter);
        Observer.Finish();
    end;

    // The reporter's full sequence.
    [Test]
    procedure Stale2C_Full_Plain()
    begin
        RunPlain(true, 1, true, false, true, true);
    end;

    [Test]
    procedure Stale2C_Full_AssertError()
    begin
        RunAssertError(true, 1, true, false, true, true);
    end;

    // Without commit A: `if Codeunit.Run` runs inside the open write transaction of step 1 and the log row.
    [Test]
    procedure Stale2C_NoCommitA_Plain()
    begin
        RunPlain(false, 1, true, false, true, true);
    end;

    [Test]
    procedure Stale2C_NoCommitA_AssertError()
    begin
        RunAssertError(false, 1, true, false, true, true);
    end;

    // Without commit A, Codeunit.Run without a return value, an explicit Commit after it (one Commit, between U2 and U3).
    [Test]
    procedure Stale2C_NoCommitA_RunNoReturnThenCommit_Plain()
    begin
        RunPlain(false, 2, true, true, true, true);
    end;

    [Test]
    procedure Stale2C_NoCommitA_RunNoReturnThenCommit_AssertError()
    begin
        RunAssertError(false, 2, true, true, true, true);
    end;

    // Without the Codeunit.Run: U2 written inline after commit A, no Commit after it (one Commit since the Insert).
    [Test]
    procedure Stale2C_InlineNoCommitB_Plain()
    begin
        RunPlain(true, 3, true, false, true, true);
    end;

    [Test]
    procedure Stale2C_InlineNoCommitB_AssertError()
    begin
        RunAssertError(true, 3, true, false, true, true);
    end;

    // Without the Codeunit.Run: U2 written inline after commit A, an explicit Commit after it (two Commits since the Insert).
    [Test]
    procedure Stale2C_InlineCommitB_Plain()
    begin
        RunPlain(true, 3, true, true, true, true);
    end;

    [Test]
    procedure Stale2C_InlineCommitB_AssertError()
    begin
        RunAssertError(true, 3, true, true, true, true);
    end;

    // Only U2 writes the row (U3 finds it and does not modify).
    [Test]
    procedure Stale2C_OnlyU2_Plain()
    begin
        RunPlain(true, 1, true, false, false, true);
    end;

    [Test]
    procedure Stale2C_OnlyU2_AssertError()
    begin
        RunAssertError(true, 1, true, false, false, true);
    end;

    // Only U3 writes the row (the Login codeunit only gets it; U3 finds it by the empty "Session Key").
    [Test]
    procedure Stale2C_OnlyU3_Plain()
    begin
        RunPlain(true, 1, false, false, true, true);
    end;

    [Test]
    procedure Stale2C_OnlyU3_AssertError()
    begin
        RunAssertError(true, 1, false, false, true, true);
    end;

    // The full sequence, the final write of U with Modify(false).
    [Test]
    procedure Stale2C_FinalModifyFalse_Plain()
    begin
        RunPlain(true, 1, true, false, true, false);
    end;

    [Test]
    procedure Stale2C_FinalModifyFalse_AssertError()
    begin
        RunAssertError(true, 1, true, false, true, false);
    end;

    // Contrast: the full sequence, then U.Get before step 3 (the buffer is fresh).
    [Test]
    procedure Stale2C_GetBeforeFinal_Plain()
    var
        U: Record "REC Stale2C User";
        Observer: Codeunit "Probe Observer";
        KeyAfter: Guid;
    begin
        Prepare(U, KeyAfter, Observer, true, 1, true, false, true);
        U.Get(U."Code");
        Observer.Observe('afterget', Describe(U, KeyAfter));
        FinalWrite(U, true);
        Observer.Observe('write', 'ok');
        ObserveRow(Observer, U, KeyAfter);
        Observer.Finish();
    end;

    // Does `if Codeunit.Run` commit U2's write? Commit A, the Run, then asserterror Error rolls back what is not committed.
    [Test]
    procedure Stale2C_RunWithReturnCommits()
    var
        U: Record "REC Stale2C User";
        Stored: Record "REC Stale2C User";
        Observer: Codeunit "Probe Observer";
        KeyAfter: Guid;
    begin
        Reset();
        CreateUser(U);
        InsertLog();
        Commit();
        Observer.Observe('run', Format(Login(1, true, KeyAfter)));
        asserterror Error('Roll back what is not committed');
        ClearLastError();
        if Stored.Get(UserCode()) then
            Observer.Observe('stored', Describe(Stored, KeyAfter))
        else
            Observer.Observe('stored', 'missing');
        Reset();
        Observer.Finish();
    end;
}
