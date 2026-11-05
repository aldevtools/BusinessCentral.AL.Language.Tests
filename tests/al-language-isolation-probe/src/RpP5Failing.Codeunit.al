namespace ALLanguage.IsolationProbe;

// Probe P5 (ADR-066 of al-runtime-rs): the probe runners run this codeunit with
// `Ok := Codeunit.Run(...)` and record Ok and GetLastErrorText(). P5_Fails FAILS ON PURPOSE
// with the fixed text below, under both probe runners. Microsoft's bookkeeping in
// OnAfterTestRun calls ClearLastError(), so the error text recorded after the run says what was
// left after that.
codeunit 61340 "LT RP P5 Failing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P5_Passes()
    begin
        Log.Add(Codeunit::"LT RP P5 Failing", 'P5_Passes', 'X body', '');
    end;

    [Test]
    procedure P5_Fails()
    begin
        Log.Add(Codeunit::"LT RP P5 Failing", 'P5_Fails', 'X body', '');
        Error('P5 test fails on purpose');
    end;

    var
        Log: Codeunit "LT RP Log";
}
