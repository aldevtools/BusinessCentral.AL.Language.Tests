// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: SIC Session Scoped (60627)
//
// A plain (non-test) codeunit, so a test can cross a real codeunit boundary on demand
// instead of depending on some other TEST codeunit having run first. Bumps only the
// SingleInstance fixture — see SIC Per Call Primer (60630) for the contrast case. Keeping
// the two primers apart means neither test's Codeunit.Run disturbs the fixture the other
// test asserts on, whatever order the [Test] methods run in.

codeunit 60628 "SIC Session Scoped Primer"
{
    trigger OnRun()
    var
        Single: Codeunit "SIC Session Scoped";
    begin
        Single.Bump();
    end;
}
