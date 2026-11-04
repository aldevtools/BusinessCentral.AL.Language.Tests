// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-startsession-method
// Scope: in-scope
//
// A worker declared with TableNo, started through StartSession's record-carrying overload.
// Writes what it saw on Rec into "SS Worker Result" so the caller's session can read it back.
codeunit 60396 "SS Record Worker"
{
    TableNo = "SS Passed Record";

    trigger OnRun()
    var
        Result: Record "SS Worker Result";
    begin
        Result.Init();
        Result.Marker := 'RECORD';
        Result."Seen Value" := Rec."Value";
        Result.Insert();
    end;
}
