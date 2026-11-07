namespace ALLanguage.IsolationProbe;

// Probe P7 (ADR-066 of al-runtime-rs): state handed from one test codeunit to the next. The
// method sets the SingleInstance mark of "LT RP P7 State" (61335) to the runner id, inserts
// "<tag>-P7-COMMITTED", calls Commit() and inserts "<tag>-P7-OPEN". "LT RP P7 Second" (61344)
// reads both, twice: once run by the probe runner from this codeunit's own invocation, and once
// in its own invocation afterwards.
codeunit 61343 "LT RP P7 First"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P7_SetsState()
    var
        Row: Record "LT RP Row";
        State: Codeunit "LT RP P7 State";
        Log: Codeunit "LT RP Log";
    begin
        State.SetMark(Log.CurrentRunner());
        Row."Key" := CopyStr(Log.RunnerTag() + '-P7-COMMITTED', 1, MaxStrLen(Row."Key"));
        if Row.Insert() then;
        Commit();
        Row."Key" := CopyStr(Log.RunnerTag() + '-P7-OPEN', 1, MaxStrLen(Row."Key"));
        if Row.Insert() then;
    end;
}
