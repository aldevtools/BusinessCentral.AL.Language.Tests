/// <summary>
/// Helper codeunit used by the AL call stack tests to produce a two-frame AL stack:
/// "AL Call Stack Helper(CodeUnit 60212).RaiseError" on top of the test frame.
/// </summary>
codeunit 60212 "AL Call Stack Helper"
{
    procedure RaiseError()
    begin
        Error('AL call stack test error');
    end;
}

/// <summary>
/// Helper codeunit whose OnRun TRIGGER raises the error, so the AL call stack carries a
/// trigger frame. Its counterpart above raises from an ordinary procedure — the pair is what
/// lets a test assert that BC marks one and not the other.
/// </summary>
codeunit 60228 "AL Call Stack Trigger Helper"
{
    trigger OnRun()
    begin
        Error('AL call stack trigger test error');
    end;
}
