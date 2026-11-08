namespace ALLanguage.IsolationProbe;

// Probe P6 (ADR-066 of al-runtime-rs): what a second run of a test codeunit sees of the first
// run's OnRun writes. OnRun records which "P6-" rows exist ("X sees", comma-separated keys, or
// '' for none) and then inserts "P6-<tag>-<n>" ("X inserted"). The tag is C or F for the probe
// runners and D otherwise: the AL Test Tool builds the suite with "Test Runner - Get Methods"
// (130452), which runs OnRun too, just before the probe runner runs this codeunit. The probe
// runners run this codeunit twice in one invocation. The method records what it sees as well.
codeunit 61342 "LT RP P6 Twice"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        Row: Record "LT RP Row";
    begin
        Log.Add(Codeunit::"LT RP P6 Twice", 'OnRun', 'X sees', P6Keys());
        Row."Key" := CopyStr('P6-' + Log.RunnerTag() + '-' + Format(Log.NextSeq()), 1, MaxStrLen(Row."Key"));
        if Row.Insert() then;
        Log.Add(Codeunit::"LT RP P6 Twice", 'OnRun', 'X inserted', Row."Key");
    end;

    [Test]
    procedure P6_MethodSees()
    begin
        Log.Add(Codeunit::"LT RP P6 Twice", 'P6_MethodSees', 'X sees', P6Keys());
    end;

    local procedure P6Keys(): Text
    var
        Row: Record "LT RP Row";
        Result: Text;
    begin
        Row.SetFilter("Key", 'P6-*');
        if Row.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Row."Key";
            until Row.Next() = 0;
        exit(Result);
    end;

    var
        Log: Codeunit "LT RP Log";
}
