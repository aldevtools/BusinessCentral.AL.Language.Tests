// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: SIS Per Call (60609)
//
// The opposite direction from the SingleInstance scope-survival tests, and the reason this
// pair exists: making a SingleInstance codeunit survive scope exit must NOT turn every
// codeunit into a shared one. A plain (SingleInstance=false) codeunit gets a fresh instance
// per AL variable, so a nested scope's increments must be invisible to the caller's own
// variable.

codeunit 60616 "Test SIS Per Call Isolation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    local procedure Initialize()
    begin
    end;

    local procedure BumpInNestedScope()
    var
        PerCall: Codeunit "SIS Per Call";
    begin
        PerCall.Bump();
    end;

    [Test]
    procedure TestCodeunit_NonSingleInstance_DoesNotShareStateAcrossScopes()
    var
        PerCall: Codeunit "SIS Per Call";
    begin
        Initialize();

        // Without this control, "make it survive scope exit" could be satisfied by caching
        // everything, which would silently fuse unrelated callers' state.
        BumpInNestedScope();
        BumpInNestedScope();

        if PerCall.GetBumps() <> 0 then
            Error('A non-SingleInstance codeunit leaked state across scopes: expected 0 bumps in a ' +
                'fresh instance, got %1.', PerCall.GetBumps());

        PerCall.Bump();
        if PerCall.GetBumps() <> 1 then
            Error('A non-SingleInstance codeunit did not keep its OWN state: expected 1, got %1.',
                PerCall.GetBumps());
    end;
}
