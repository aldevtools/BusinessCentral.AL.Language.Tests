// Fixture for "Test External Business Event" (68611): raises an external business
// event from OnRun, so a test can run it through a guarded Codeunit.Run.
codeunit 68612 "EBE Run Target"
{
    trigger OnRun()
    var
        Publisher: Codeunit "EBE Publisher";
    begin
        Publisher.RaiseBetweenSteps();
        if Publisher.Steps() <> 2 then
            Error('EBE run target: expected 2 steps, got %1', Publisher.Steps());
    end;
}
