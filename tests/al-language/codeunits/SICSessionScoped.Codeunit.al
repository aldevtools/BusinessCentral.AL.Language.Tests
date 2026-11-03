// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: none
//
// SingleInstance fixture owned exclusively by "Test Codeunit SIC Leak" (60600), which
// asserts what the SingleInstance lifetime actually is. It is deliberately NOT shared with
// any other test codeunit: 60600's claim is about state crossing a codeunit boundary, so a
// fixture another test codeunit could also write would make the assertion depend on run
// order — the defect corpus #261 was filed for.
//
// Bumped rather than assigned, so the assertions can distinguish "the same instance was
// reused" from "a fresh instance happened to be handed the same value".

codeunit 60627 "SIC Session Scoped"
{
    SingleInstance = true;

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
