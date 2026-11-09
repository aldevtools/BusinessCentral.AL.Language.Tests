namespace ALLanguage.IsolationProbe;

// What the probe runners 61330 (TestIsolation = Codeunit) and 61331 (Function) recorded for
// probes P1-P8 of ADR-066 of al-runtime-rs. This codeunit has the highest id of 61330..61349,
// so the runner runs it last; it only reads "LT RP Log" (61332) and "LT RP Row" (61330).
//
// Each test states the reading expected (the platform behavior ADR-066 assumes; for P1, P6 and
// P8 a guess) and fails with "expected [...], observed [...]". A red row is the measurement:
// its message carries the observed value. Notation of the log: B = OnBeforeTestRun called,
// A Yes / A No = OnAfterTestRun called with IsSuccess true / false, X ... = recorded by a test
// body, an OnRun or a trigger, RUN Yes / RUN No = what `Ok := Codeunit.Run(...)` returned.
// Under any other runner every test fails with "not run under a probe runner".
codeunit 61346 "LT RP Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // P1: the runner answers false for P1_Skipped. Is its body skipped, is OnAfterTestRun called,
    // with which IsSuccess?
    [Test]
    procedure P1_FalseFromOnBeforeTestRun()
    begin
        Expect('P1 P1_Skipped', 'B', Log.Seq(Runner(), Codeunit::"LT RP P1 Skip", 'P1_Skipped'));
    end;

    // P1 control: the runner answers true for P1_Runs.
    [Test]
    procedure P1_TrueFromOnBeforeTestRun()
    begin
        Expect('P1 P1_Runs', 'B ; X body ; A Yes', Log.Seq(Runner(), Codeunit::"LT RP P1 Skip", 'P1_Runs'));
    end;

    // P2: IsSuccess in OnAfterTestRun for a pass, a failure and an error caught by asserterror.
    [Test]
    procedure P2_IsSuccess()
    begin
        Expect('P2 IsSuccess',
          'P2_Passes: B ; A Yes | P2_Fails: B ; A No | P2_Caught: B ; A Yes',
          'P2_Passes: ' + Log.Seq(Runner(), Codeunit::"LT RP P2 Outcomes", 'P2_Passes') +
          ' | P2_Fails: ' + Log.Seq(Runner(), Codeunit::"LT RP P2 Outcomes", 'P2_Fails') +
          ' | P2_Caught: ' + Log.Seq(Runner(), Codeunit::"LT RP P2 Outcomes", 'P2_Caught'));
    end;

    // P2: GetLastErrorText() inside OnAfterTestRun, before Microsoft's bookkeeping clears it.
    [Test]
    procedure P2_LastErrorInOnAfterTestRun()
    begin
        Expect('P2 GetLastErrorText',
          'P2_Passes=[] P2_Fails=[P2 fails on purpose] P2_Caught=[P2 error caught by asserterror]',
          'P2_Passes=[' + AfterData(Codeunit::"LT RP P2 Outcomes", 'P2_Passes') +
          '] P2_Fails=[' + AfterData(Codeunit::"LT RP P2 Outcomes", 'P2_Fails') +
          '] P2_Caught=[' + AfterData(Codeunit::"LT RP P2 Outcomes", 'P2_Caught') + ']');
    end;

    // P3: every trigger call for a test codeunit that declares OnRun, in order.
    [Test]
    procedure P3_DeclaredOnRun()
    begin
        Expect('P3 OnRun declared',
          ':B ; OnRun:B ; OnRun:X body ; OnRun:A Yes ; P2_Passes:B ; P2_Passes:A Yes ; P2_Fails:B ; P2_Fails:A No ; P2_Caught:B ; P2_Caught:A Yes ; :A No',
          Log.Seq(Runner(), Codeunit::"LT RP P2 Outcomes", ''));
    end;

    // P3: every trigger call for a test codeunit without an OnRun trigger.
    [Test]
    procedure P3_NoOnRun()
    begin
        Expect('P3 no OnRun', ':B ; P3_Passes:B ; P3_Passes:A Yes ; :A Yes', Log.Seq(Runner(), Codeunit::"LT RP P3 No OnRun", ''));
    end;

    // P4: which rows of P4_Plain survive the isolation rollback: the triggers' rows, the
    // subscriber's rows, the test body's row.
    [Test]
    procedure P4_TriggerWritesSurvive()
    begin
        Expect('P4 P4_Plain rows', RowsExpected('P4_PLAIN'), Rows('P4_PLAIN'));
    end;

    // P4: the same with Commit() called in both triggers after their writes.
    [Test]
    procedure P4_TriggerWritesWithCommitSurvive()
    begin
        Expect('P4 P4_Commit rows', RowsExpected('P4_COMMIT'), Rows('P4_COMMIT'));
    end;

    // P4: the same for a method that fails after it wrote its row, and whether that method saw the row
    // OnBeforeTestRun wrote.
    [Test]
    procedure P4_TriggerWritesSurviveAFailingTest()
    begin
        Expect('P4 P4_Fails rows', RowsExpected('P4_FAILS'), Rows('P4_FAILS'));
    end;

    [Test]
    procedure P4_MethodSeesRowOfOnBeforeTestRun()
    begin
        Expect('P4 P4_Fails sees', 'Yes', Log.DataOf(Runner(), Codeunit::"LT RP P4 Trigger Writes", 'P4_Fails', 'X before row visible', 1));
    end;

    // P4: Commit() in OnBeforeTestRun and OnAfterTestRun returns, and the test still runs.
    [Test]
    procedure P4_CommitInTriggersReturns()
    begin
        Expect('P4 P4_Commit events',
          'B ; X commit returned in BEFORE ; A Yes ; X commit returned in AFTER',
          Log.Seq(Runner(), Codeunit::"LT RP P4 Trigger Writes", 'P4_Commit'));
    end;

    // P5: `Ok := Codeunit.Run(test codeunit)` when one of its tests fails.
    [Test]
    procedure P5_RunWithFailingTest()
    begin
        Expect('P5 failing test',
          ':B ; P5_Passes:B ; P5_Passes:X body ; P5_Passes:A Yes ; P5_Fails:B ; P5_Fails:X body ; P5_Fails:A No ; :A No ; :RUN No err=[]',
          Log.Seq(Runner(), Codeunit::"LT RP P5 Failing", '') + ' err=[' + RunData(Codeunit::"LT RP P5 Failing") + ']');
    end;

    // P5: `Ok := Codeunit.Run(test codeunit)` when its OnRun raises an error.
    [Test]
    procedure P5_RunWithOnRunError()
    begin
        Expect('P5 OnRun raises',
          ':B ; OnRun:B ; OnRun:X body ; OnRun:A No ; :A No ; :RUN No err=[P5 OnRun fails on purpose]',
          Log.Seq(Runner(), Codeunit::"LT RP P5 OnRun Raises", '') + ' err=[' + RunData(Codeunit::"LT RP P5 OnRun Raises") + ']');
    end;

    // P6: the probe runner's first OnRun of "LT RP P6 Twice" sees the row the discovery runner's
    // OnRun inserted just before (the last entry recorded with no probe runner running).
    [Test]
    procedure P6_RunSeesDiscoveryOnRunRow()
    var
        DiscoveryKey: Text;
        FirstSees: Text;
    begin
        DiscoveryKey := Log.DataOf(0, Codeunit::"LT RP P6 Twice", 'OnRun', 'X inserted', -1);
        FirstSees := Log.DataOf(Runner(), Codeunit::"LT RP P6 Twice", 'OnRun', 'X sees', 1);
        ExpectDetailed('P6 discovery row', 'discovery row seen by first run=Yes',
          'discovery row seen by first run=' + Format(Contains(FirstSees, DiscoveryKey)),
          'discovery inserted [' + DiscoveryKey + '], first run sees [' + FirstSees + ']');
    end;

    // P6: the second run of "LT RP P6 Twice" in the same runner invocation sees the row the first
    // run's OnRun inserted.
    [Test]
    procedure P6_SecondRunSeesFirstOnRunRow()
    var
        FirstKey: Text;
        SecondSees: Text;
    begin
        FirstKey := Log.DataOf(Runner(), Codeunit::"LT RP P6 Twice", 'OnRun', 'X inserted', 1);
        SecondSees := Log.DataOf(Runner(), Codeunit::"LT RP P6 Twice", 'OnRun', 'X sees', 2);
        ExpectDetailed('P6 second run', 'first run row seen by second run=No',
          'first run row seen by second run=' + Format(Contains(SecondSees, FirstKey)),
          'first run inserted [' + FirstKey + '], second run sees [' + SecondSees + '], methods see [' +
          Log.DataOf(Runner(), Codeunit::"LT RP P6 Twice", 'P6_MethodSees', 'X sees', 1) + '] and [' +
          Log.DataOf(Runner(), Codeunit::"LT RP P6 Twice", 'P6_MethodSees', 'X sees', 2) + ']');
    end;

    // P7: what "LT RP P7 Second" sees when the runner runs it right after "LT RP P7 First" in
    // the same runner invocation.
    [Test]
    procedure P7_StateInOneRunnerInvocation()
    begin
        Expect('P7 one invocation', P7Expected(), P7Observed(1));
    end;

    // P7: what "LT RP P7 Second" sees in its own, later runner invocation.
    [Test]
    procedure P7_StateInNextRunnerInvocation()
    begin
        Expect('P7 next invocation', P7Expected(), P7Observed(2));
    end;

    // P8: FunctionTestPermissions in OnBeforeTestRun when neither the method nor the codeunit
    // sets TestPermissions, with two attributes as controls.
    [Test]
    procedure P8_DefaultTestPermissions()
    begin
        Expect('P8 FunctionTestPermissions',
          'P8_NoAttribute=Restrictive P8_Restrictive=Restrictive P8_NonRestrictive=NonRestrictive',
          'P8_NoAttribute=' + Log.DataOf(Runner(), Codeunit::"LT RP P8 Permissions", 'P8_NoAttribute', 'B', 1) +
          ' P8_Restrictive=' + Log.DataOf(Runner(), Codeunit::"LT RP P8 Permissions", 'P8_Restrictive', 'B', 1) +
          ' P8_NonRestrictive=' + Log.DataOf(Runner(), Codeunit::"LT RP P8 Permissions", 'P8_NonRestrictive', 'B', 1));
    end;

    // P8 control: a codeunit with TestPermissions = Disabled.
    [Test]
    procedure P8_CodeunitPropertyDisabled()
    begin
        Expect('P8 control', 'Disabled', Log.DataOf(Runner(), Codeunit::"LT RP P3 No OnRun", 'P3_Passes', 'B', 1));
    end;

    local procedure Runner(): Integer
    var
        RunnerId: Integer;
    begin
        RunnerId := Log.CurrentRunner();
        if not (RunnerId in [61330, 61331]) then
            Error('not run under a probe runner (61330 or 61331): the current runner id is %1', RunnerId);
        exit(RunnerId);
    end;

    local procedure AfterData(CodeunitId: Integer; FunctionName: Text): Text
    var
        Data: Text;
    begin
        Data := Log.DataOf(Runner(), CodeunitId, FunctionName, 'A Yes', 1);
        if Data = '<no entry>' then
            Data := Log.DataOf(Runner(), CodeunitId, FunctionName, 'A No', 1);
        exit(Data);
    end;

    local procedure RunData(CodeunitId: Integer): Text
    var
        Data: Text;
    begin
        Data := Log.DataOf(Runner(), CodeunitId, '', 'RUN Yes', 1);
        if Data = '<no entry>' then
            Data := Log.DataOf(Runner(), CodeunitId, '', 'RUN No', 1);
        exit(Data);
    end;

    local procedure RowsExpected(FunctionName: Text): Text
    var
        Tag: Text;
    begin
        Tag := Log.RunnerTag();
        exit(
          Tag + '-BEFORE-' + FunctionName + '=Yes S' + Tag + '-BEFORE-' + FunctionName + '=Yes ' +
          Tag + '-AFTER-' + FunctionName + '=Yes S' + Tag + '-AFTER-' + FunctionName + '=Yes ' +
          Tag + '-BODY-' + FunctionName + '=No');
    end;

    local procedure Rows(FunctionName: Text): Text
    var
        Tag: Text;
    begin
        Tag := Log.RunnerTag();
        exit(
          RowState(Tag + '-BEFORE-' + FunctionName) + ' ' + RowState('S' + Tag + '-BEFORE-' + FunctionName) + ' ' +
          RowState(Tag + '-AFTER-' + FunctionName) + ' ' + RowState('S' + Tag + '-AFTER-' + FunctionName) + ' ' +
          RowState(Tag + '-BODY-' + FunctionName));
    end;

    local procedure RowState(RowKey: Text): Text
    var
        Row: Record "LT RP Row";
    begin
        exit(RowKey + '=' + Format(Row.Get(CopyStr(RowKey, 1, MaxStrLen(Row."Key")))));
    end;

    local procedure P7Expected(): Text
    var
        Tag: Text;
    begin
        Tag := Log.RunnerTag();
        exit('mark=' + Format(Runner()) + ' rows=' + Tag + '-P7-COMMITTED=No ' + Tag + '-P7-OPEN=No');
    end;

    local procedure P7Observed(Occurrence: Integer): Text
    begin
        exit(
          'mark=' + Log.DataOf(Runner(), Codeunit::"LT RP P7 Second", 'P7_ReadsState', 'X mark', Occurrence) +
          ' rows=' + Log.DataOf(Runner(), Codeunit::"LT RP P7 Second", 'P7_ReadsState', 'X rows', Occurrence));
    end;

    local procedure Contains(List: Text; Item: Text): Boolean
    begin
        if (Item = '') or (Item = '<no entry>') then
            exit(false);
        exit((',' + List + ',').Contains(',' + Item + ','));
    end;

    local procedure Expect(Probe: Text; Expected: Text; Observed: Text)
    begin
        ExpectDetailed(Probe, Expected, Observed, Observed);
    end;

    // The compared reading is Observed; Detail (row keys, which carry the runner's tag) only goes into the message.
    local procedure ExpectDetailed(Probe: Text; Expected: Text; Observed: Text; Detail: Text)
    begin
        if Observed <> Expected then
            Error('%1: expected [%2], observed [%3] (%4)', Probe, Expected, Observed, Detail);
    end;

    var
        Log: Codeunit "LT RP Log";
}
