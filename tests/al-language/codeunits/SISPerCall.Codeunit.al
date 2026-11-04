// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: none
//
// The control for the SingleInstance tests: identical shape, but per-call, so it must NOT
// share state between scopes.

codeunit 60609 "SIS Per Call"
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
