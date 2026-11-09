namespace ALLanguage.IsolationProbe;

// Probe P4 (ADR-066 of al-runtime-rs): for this codeunit's methods the probe runners'
// OnBeforeTestRun and OnAfterTestRun insert "<tag>-BEFORE-<method>" and "<tag>-AFTER-<method>"
// into "LT RP Row" (61330), after Microsoft's bookkeeping, and raise an event whose subscriber
// inserts the same key with an "S" in front. Each method inserts "<tag>-BODY-<method>".
// For P4_Commit the triggers then also call Commit() and record that it returned. P4_Fails reads the
// trigger's row, inserts its body row and fails.
// "LT RP Reader" (61346), a later test codeunit, reads which of these rows are still there
// after the runner's isolation rollback (tag C: TestIsolation = Codeunit, F: Function).
codeunit 61339 "LT RP P4 Trigger Writes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P4_Plain()
    begin
        InsertBodyRow('P4_PLAIN');
    end;

    [Test]
    procedure P4_Commit()
    begin
        InsertBodyRow('P4_COMMIT');
    end;

    // Reads the row OnBeforeTestRun wrote (is it visible to the method, i.e. committed before it ran?),
    // writes its own row and then fails. "LT RP Reader" (61346) reads which rows are left.
    [Test]
    procedure P4_Fails()
    var
        Row: Record "LT RP Row";
        Log: Codeunit "LT RP Log";
    begin
        Log.Add(Codeunit::"LT RP P4 Trigger Writes", 'P4_Fails', 'X before row visible',
          Format(Row.Get(CopyStr(Log.RunnerTag() + '-BEFORE-P4_FAILS', 1, MaxStrLen(Row."Key")))));
        InsertBodyRow('P4_FAILS');
        Error('P4 fails on purpose');
    end;

    local procedure InsertBodyRow(FunctionName: Text)
    var
        Row: Record "LT RP Row";
        Log: Codeunit "LT RP Log";
    begin
        Row."Key" := CopyStr(Log.RunnerTag() + '-BODY-' + FunctionName, 1, MaxStrLen(Row."Key"));
        if Row.Insert() then;
    end;
}
