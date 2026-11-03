// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-profile-object
// Scope: in-scope
// Fixtures used: ALT Profile RC SameApp (60904), ALT Profile SameApp (profile, no numeric ID)
//
// CLAIM: a profile declared alongside a test codeunit, whose RoleCenter page lives
// in the SAME app, does not stop that codeunit from compiling and its [Test]
// procedures from running. A profile declares no executable AL -- this is the
// baseline case, not the interesting one. See TestProfileDepAppCoexistence.al for
// the shape that actually broke a real compiler: RoleCenter page in a DEPENDENCY
// app.
codeunit 60905 "Test Profile SameApp Coexist"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Profile_SameAppRoleCenter_Present_ArithmeticStillComputesCorrectly()
    // CLAIM: with "ALT Profile SameApp" published alongside this codeunit, ordinary
    // AL logic still executes and returns the real computed value -- not a default,
    // and not a value the profile's own presence could account for.
    begin
        Assert.AreEqual(56, Multiply(7, 8), 'Multiply(7, 8) must return 56');
    end;

    [Test]
    procedure Profile_SameAppRoleCenter_Present_DivisionByZeroStillRaisesError()
    // CLAIM: error handling in the codeunit is unaffected by the profile's
    // presence.
    var
        Result: Integer;
    begin
        asserterror Result := Divide(10, 0);
        Assert.ExpectedError('Cannot divide by zero.');
    end;

    local procedure Multiply(A: Integer; B: Integer): Integer
    begin
        exit(A * B);
    end;

    local procedure Divide(A: Integer; B: Integer): Integer
    begin
        if B = 0 then
            Error('Cannot divide by zero.');
        exit(A div B);
    end;
}
