// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
// Fixtures used: ALTFixtureCleanup (60019)
//
// CLAIM OF THIS CODEUNIT: Codeunit.Run on a codeunit id no installed app declares raises an AL
// error, not a CLR exception, so asserterror catches it and GetLastErrorText reads BC's own
// "object does not exist" text. The guarded spelling (the Boolean result consumed) raises it too
// instead of returning false: the object is resolved before the run begins, outside the try
// whose catch traps a guarded run's own errors. Measured on the service tier by this codeunit's
// own CI run (every cloud leg), not assumed.
//
// The text also names the calling object ("from the object ...") and an emit version, and both
// differ per host and per BC version, so the assertions below read the two stable halves.
// Id 99990 is outside both app ranges and every Microsoft app, so no installed app declares it.

codeunit 69901 "Test Codeunit Run Missing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure CodeunitRun_MissingId_BareAsserterror_IsCaught()
    // CLAIM: a bare asserterror around the run passes, i.e. the failure is an AL error.
    begin
        Initialize();

        asserterror Codeunit.Run(99990);

        Assert.AreNotEqual('', GetLastErrorText(), 'asserterror must have caught an error from Codeunit.Run of a missing codeunit');
    end;

    [Test]
    procedure CodeunitRun_MissingId_RaisesObjectDoesNotExist()
    // CLAIM: the error names the object type "CodeUnit" and the missing id, and says no such object exists.
    begin
        Initialize();

        asserterror Codeunit.Run(99990);

        Assert.ExpectedError('You tried to invoke the CodeUnit object with the ID 99990 from the object');
        Assert.ExpectedError('An object with that ID does not exist in the current application');
    end;

    [Test]
    procedure CodeunitRun_MissingId_Guarded_RaisesInsteadOfReturningFalse()
    // CLAIM: consuming the Boolean result does not trap the error: the run never began.
    var
        Ok: Boolean;
    begin
        Initialize();

        asserterror Ok := Codeunit.Run(99990);

        Assert.ExpectedError('You tried to invoke the CodeUnit object with the ID 99990 from the object');
        Assert.ExpectedError('An object with that ID does not exist in the current application');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
