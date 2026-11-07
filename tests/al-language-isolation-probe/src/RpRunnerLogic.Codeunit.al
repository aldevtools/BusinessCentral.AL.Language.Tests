namespace ALLanguage.IsolationProbe;

// What the two probe runners "LT RP Runner Codeunit" (61330) and "LT RP Runner Function"
// (61331) do besides Microsoft's bookkeeping (ADR-066 of al-runtime-rs, probes P1-P8). Both
// runners call this codeunit from OnRun, OnBeforeTestRun and OnAfterTestRun, so the two differ
// only in their TestIsolation property.
codeunit 61333 "LT RP Runner Logic"
{
    // OnRun of the runner. Most test codeunits run as Microsoft's "Test Runner - Mgt".RunTests
    // runs them: `Codeunit.Run(id)` without using the return value. The exceptions:
    //   P5 (61340, 61341): `Ok := Codeunit.Run(id)`, recorded as "RUN Yes/No" with the last error.
    //   P5b (61347): `asserterror Codeunit.Run(id)` with no return value, recorded as "ASSERT" with
    //   the last error text and code, then "X runner continued".
    //   P6 (61342): run twice in a row.
    //   P7 (61343): runs 61343 and then 61344 in this one runner invocation.
    procedure RunTestCodeunit(RunnerId: Integer; CodeunitId: Integer)
    var
        Ok: Boolean;
    begin
        Log.SetRunner(RunnerId);
        case CodeunitId of
            Codeunit::"LT RP P5 Failing", Codeunit::"LT RP P5 OnRun Raises":
                begin
                    // Only armed here, so that the discovery runner (130452) never sees the error.
                    Log.ArmOnRunError(CodeunitId = Codeunit::"LT RP P5 OnRun Raises");
                    Commit();
                    ClearLastError();
                    Ok := Codeunit.Run(CodeunitId);
                    Log.ArmOnRunError(false);
                    Log.Add(CodeunitId, '', 'RUN ' + Format(Ok), GetLastErrorText());
                end;
            Codeunit::"LT RP P5b OnRun Raises":
                begin
                    Log.ArmOnRunError(true);
                    Commit();
                    ClearLastError();
                    asserterror Codeunit.Run(CodeunitId);
                    Log.ArmOnRunError(false);
                    Log.Add(CodeunitId, '', 'ASSERT', GetLastErrorText() + ' code=' + GetLastErrorCode());
                    Log.Add(CodeunitId, '', 'X runner continued', '');
                end;
            Codeunit::"LT RP P6 Twice":
                begin
                    Codeunit.Run(CodeunitId);
                    Codeunit.Run(CodeunitId);
                end;
            Codeunit::"LT RP P7 First":
                begin
                    Codeunit.Run(Codeunit::"LT RP P7 First");
                    Codeunit.Run(Codeunit::"LT RP P7 Second");
                end;
            else
                Codeunit.Run(CodeunitId);
        end;
        Log.SetRunner(0);
    end;

    // OnBeforeTestRun, first thing. False means the runner answers false without asking
    // Microsoft's bookkeeping: P1 skips "LT RP P1 Skip".P1_Skipped this way.
    procedure BeforeTestRun(CodeunitId: Integer; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    begin
        Log.Add(CodeunitId, FunctionName, 'B', Format(FunctionTestPermissions));
        if (CodeunitId = Codeunit::"LT RP P1 Skip") and (UpperCase(FunctionName) = 'P1_SKIPPED') then
            exit(false);
        exit(true);
    end;

    // OnAfterTestRun, first thing, before Microsoft's bookkeeping clears the last error.
    procedure AfterTestRun(CodeunitId: Integer; FunctionName: Text; IsSuccess: Boolean)
    begin
        Log.Add(CodeunitId, FunctionName, 'A ' + Format(IsSuccess), GetLastErrorText());
    end;

    // P4, last thing in both triggers, after Microsoft's bookkeeping (whose OnAfterTestRun
    // commits): for "LT RP P4 Trigger Writes" (61339) insert "<tag>-<phase>-<function>" and raise
    // the event that "LT RP Subscriber" answers. For P4_Commit, then also Commit() and record
    // that it returned.
    procedure TriggerWrites(Phase: Text; CodeunitId: Integer; FunctionName: Text)
    var
        Row: Record "LT RP Row";
    begin
        if CodeunitId <> Codeunit::"LT RP P4 Trigger Writes" then
            exit;
        Row."Key" := CopyStr(Log.RunnerTag() + '-' + Phase + '-' + FunctionName, 1, MaxStrLen(Row."Key"));
        if Row.Insert() then;
        Log.RaiseTriggerWrite(Row."Key");
        if UpperCase(FunctionName) = 'P4_COMMIT' then begin
            Commit();
            Log.Add(CodeunitId, FunctionName, 'X commit returned in ' + Phase, '');
        end;
    end;

    var
        Log: Codeunit "LT RP Log";
}
