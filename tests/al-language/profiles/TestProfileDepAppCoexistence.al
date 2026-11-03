// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-profile-object
// Scope: in-scope
// Fixtures used: ALT Profile RC DepApp (61002, dependency app), ALT Profile DepApp
//                (profile, no numeric ID), ALT Internal Codeunit (61000, dependency app)
// BC versions: 27.5+
//
// CLAIM: a profile whose RoleCenter page is declared in a DEPENDENCY app does not
// stop a codeunit declared alongside it -- in THIS app -- from compiling and
// running, including dispatch to a codeunit in that SAME dependency app. This is
// the shape that actually broke AL Runner's compile pipeline (issue #2238 in
// StefanMaron/BusinessCentral.AL.Runner): "ALT Profile RC DepApp" only exists in
// the dependency module, so resolving the profile's RoleCenter reference requires
// cross-module symbol lookup, and the runner's own resolution for that lookup
// differed from a service tier's. A profile whose page lives in the same app (see
// TestProfileSameAppCoexistence.al) would have passed even before that fix.
codeunit 60906 "Test Profile DepApp Coexist"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Profile_DepAppRoleCenter_Present_DependencyCodeunitDispatchStillWorks()
    // CLAIM: with "ALT Profile DepApp" published -- referencing a RoleCenter page
    // that lives ONLY in the dependency app -- a direct call into a
    // dependency-app codeunit still dispatches to its real body and returns the
    // real computed value, not a default.
    var
        InternalCU: Codeunit "ALT Internal Codeunit";
    begin
        Assert.AreEqual(42, InternalCU.Compute(21), 'DepCU dispatch: Compute(21) must return 42');
    end;

    [Test]
    procedure Profile_DepAppRoleCenter_Present_LocalArithmeticStillComputesCorrectly()
    // CLAIM: local (non-cross-app) logic in this codeunit is unaffected too.
    begin
        Assert.AreEqual(15, Add(7, 8), 'Add(7, 8) must return 15');
    end;

    [Test]
    procedure Profile_DepAppRoleCenter_Present_DivisionByZeroStillRaisesError()
    // CLAIM: error handling is unaffected by the dependency-app profile
    // reference.
    var
        Result: Integer;
    begin
        asserterror Result := Divide(10, 0);
        Assert.ExpectedError('Cannot divide by zero.');
    end;

    local procedure Add(A: Integer; B: Integer): Integer
    begin
        exit(A + B);
    end;

    local procedure Divide(A: Integer; B: Integer): Integer
    begin
        if B = 0 then
            Error('Cannot divide by zero.');
        exit(A div B);
    end;
}
