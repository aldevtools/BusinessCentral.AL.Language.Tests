namespace ALLanguage.IsolationProbe;

// Probe P4 (ADR-066 of al-runtime-rs): for this codeunit's methods the probe runners'
// OnBeforeTestRun and OnAfterTestRun insert "<tag>-BEFORE-<method>" and "<tag>-AFTER-<method>"
// into "LT RP Row" (61330), after Microsoft's bookkeeping, and raise an event whose subscriber
// inserts the same key with an "S" in front. Each method inserts "<tag>-BODY-<method>".
// For P4_Commit the triggers then also call Commit() and record that it returned.
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

    local procedure InsertBodyRow(FunctionName: Text)
    var
        Row: Record "LT RP Row";
        Log: Codeunit "LT RP Log";
    begin
        Row."Key" := CopyStr(Log.RunnerTag() + '-BODY-' + FunctionName, 1, MaxStrLen(Row."Key"));
        if Row.Insert() then;
    end;
}
