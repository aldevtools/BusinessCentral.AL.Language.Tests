// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: none
//
// Contrast case for SIC Session Scoped (60627): identical shape, SingleInstance = false, so
// a bump applied inside another codeunit must NOT be visible through a caller's own
// variable. Without it, "state crosses the codeunit boundary" could be satisfied by a
// runtime that shared every codeunit, which is not the contract.

codeunit 60629 "SIC Per Call Probe"
{
    SingleInstance = false;

    var
        Bumps: Integer;

    procedure Bump()
    begin
        Bumps += 1;
    end;

    procedure GetBumps(): Integer
    begin
        exit(Bumps);
    end;
}
