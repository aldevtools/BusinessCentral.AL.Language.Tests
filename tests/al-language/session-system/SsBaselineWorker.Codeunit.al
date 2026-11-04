// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-startsession-method
// Scope: in-scope
//
// A worker with no TableNo, started with StartSession's parameterless-object overload.
// Establishes whether StartSession dispatches from inside an ordinary [Test] codeunit AT ALL
// before TestStartSessionRecord.al asks a harder question about what a record-carrying
// worker sees.
codeunit 60395 "SS Baseline Worker"
{
    trigger OnRun()
    var
        Result: Record "SS Worker Result";
    begin
        Result.Init();
        Result.Marker := 'BASELINE';
        Result."Seen Value" := 'ran';
        Result.Insert();
    end;
}
