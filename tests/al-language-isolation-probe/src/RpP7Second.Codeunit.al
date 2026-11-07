namespace ALLanguage.IsolationProbe;

// Probe P7 (ADR-066 of al-runtime-rs): records the mark and the rows "LT RP P7 First" (61343)
// left: "X mark" (the SingleInstance mark) and "X rows" ("<tag>-P7-COMMITTED=Yes/No
// <tag>-P7-OPEN=Yes/No"). The reader (61346) takes the first entry (run from 61343's runner
// invocation) and the second (its own invocation).
codeunit 61344 "LT RP P7 Second"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P7_ReadsState()
    var
        Row: Record "LT RP Row";
        State: Codeunit "LT RP P7 State";
        Log: Codeunit "LT RP Log";
        Tag: Text;
    begin
        Tag := Log.RunnerTag();
        Log.Add(Codeunit::"LT RP P7 Second", 'P7_ReadsState', 'X mark', Format(State.GetMark()));
        Log.Add(Codeunit::"LT RP P7 Second", 'P7_ReadsState', 'X rows',
          Tag + '-P7-COMMITTED=' + Format(Row.Get(Tag + '-P7-COMMITTED')) + ' ' +
          Tag + '-P7-OPEN=' + Format(Row.Get(Tag + '-P7-OPEN')));
    end;
}
