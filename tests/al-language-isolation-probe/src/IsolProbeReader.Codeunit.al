namespace ALLanguage.IsolationProbe;

// What the NEXT test codeunit sees of the rows "LT DJ Isol Writer" (61306) wrote (corpus
// issue 645, items 2 and 4). This codeunit has the higher id, so the runner runs it after the
// writer. Each assertion states the reading expected under TestIsolation = Disabled: the
// writer's rows are kept, except those of its failing test W2. A red row is the measurement:
//   R1 no W-ONRUN row -> the writer's OnRun writes were rolled back at the end of the writer
//                        (expected under Function and Codeunit).
//   R2 no W-PASS row  -> the writer's passing test's writes were rolled back.
//   R3 found W-FAIL   -> the writes of the writer's failing test were kept.
codeunit 61307 "LT DJ Isol Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure R1_WriterOnRunRowKept()
    var
        CrossRow: Record "LT DJ Isol Cross Row";
    begin
        if not CrossRow.Get('W-ONRUN') then
            Error('The row the writer''s OnRun inserted is gone in the next test codeunit (%1 rows in the table)', CrossRow.Count());
    end;

    [Test]
    procedure R2_WriterPassRowKept()
    var
        CrossRow: Record "LT DJ Isol Cross Row";
    begin
        if not CrossRow.Get('W-PASS') then
            Error('The row the writer''s W1 inserted is gone in the next test codeunit (%1 rows in the table)', CrossRow.Count());
    end;

    [Test]
    procedure R3_WriterFailRowGone()
    var
        CrossRow: Record "LT DJ Isol Cross Row";
    begin
        if CrossRow.Get('W-FAIL') then
            Error('The row the writer''s failing W2 inserted is still there in the next test codeunit');
    end;
}
