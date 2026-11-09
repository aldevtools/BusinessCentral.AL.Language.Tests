namespace ALLanguage.IsolationProbe;

// What the probe runners 61330 and 61331 recorded for probe P5b of ADR-066 of al-runtime-rs:
// `asserterror Codeunit.Run(test codeunit)` without a return value, when the test codeunit's
// OnRun raises an error ("LT RP P5b OnRun Raises", 61347). It is a second reader because the
// P5b test codeunit has a higher id than "LT RP Reader" (61346), so it runs after it; this
// codeunit (61349) runs after the P5b test codeunit and reads "LT RP Log" (61332).
//
// Like "LT RP Reader", the test states the expected reading and fails with "expected [...],
// observed [...]"; a red row is the measurement. Notation: B = OnBeforeTestRun called, A No =
// OnAfterTestRun called with IsSuccess false, X ... = recorded by a test body, an OnRun or the
// runner, ASSERT = the last error text and code after the asserterror line. Under any other
// runner the test fails with "not run under a probe runner".
codeunit 61349 "LT RP Reader B"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // P5b: which triggers ran, what the last error is after the asserterror line, and whether
    // the runner went on to the line after it.
    [Test]
    procedure P5b_AsserterrorRunWithOnRunError()
    begin
        // Codeunit.Run raises nothing, so the asserterror line itself fails and ends the runner's OnRun: no ASSERT entry.
        Expect('P5b OnRun raises under asserterror',
          ':B ; OnRun:B ; OnRun:X body ; OnRun:A No ' + AfterOfCodeunitAfterFailedOnRun() + 'text=[<no entry>]',
          Log.Seq(Runner(), Codeunit::"LT RP P5b OnRun Raises", '') +
          ' ; text=[' + Log.DataOf(Runner(), Codeunit::"LT RP P5b OnRun Raises", '', 'ASSERT', 1) + ']');
    end;

    // P8b: the attribute of a method against the property of its codeunit (Disabled).
    [Test]
    procedure P8b_AttributeOverCodeunitProperty()
    begin
        Expect('P8b attribute over property', 'NonRestrictive',
          Log.DataOf(Runner(), Codeunit::"LT RP P8b Override", 'P8b_AttributeOverCodeunitProperty', 'B', 1));
    end;

    // BC 27.5, 28.4 and 28.5 call OnAfterTestRun for the codeunit itself ('') after a failed OnRun; BC 29.0 does not
    // (the BC 29.0 value of this probe is read from the run that adds this line).
    local procedure AfterOfCodeunitAfterFailedOnRun(): Text
    begin
#if BC29PLUS
        exit('; ');
#else
        exit('; :A No ; ');
#endif
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

    local procedure Expect(Probe: Text; Expected: Text; Observed: Text)
    begin
        if Observed <> Expected then
            Error('%1: expected [%2], observed [%3]', Probe, Expected, Observed);
    end;

    var
        Log: Codeunit "LT RP Log";
}
