// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-open-method
// Scope: in-scope
// Fixtures used: ALTFixtureCleanup (60019)
//
// CLAIM OF THIS CODEUNIT: RecordRef.Open on a table id no installed app declares raises an AL
// error, not a CLR exception, so asserterror catches it and GetLastErrorText reads BC's own
// "object does not exist" text. Measured on the service tier by this codeunit's own CI run
// (every cloud leg), not assumed: the text names the object type "Table" and the id.
//
// The text also names the calling object ("from the object ...") and an emit version, and both
// differ per host and per BC version, so the assertions below read the two stable halves.
// Id 99991 is outside both app ranges and every Microsoft app, so no installed app declares it.

codeunit 69900 "Test RecordRef Open Missing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure RecordRef_Open_MissingTable_BareAsserterror_IsCaught()
    // CLAIM: a bare asserterror around the open passes, i.e. the failure is an AL error.
    var
        RecRef: RecordRef;
    begin
        Initialize();

        asserterror RecRef.Open(99991);

        Assert.AreNotEqual('', GetLastErrorText(), 'asserterror must have caught an error from RecordRef.Open of a missing table');
    end;

    [Test]
    procedure RecordRef_Open_MissingTable_RaisesObjectDoesNotExist()
    // CLAIM: the error names the object type "Table" and the missing id, and says no such object exists.
    var
        RecRef: RecordRef;
    begin
        Initialize();

        asserterror RecRef.Open(99991);

        Assert.ExpectedError('You tried to invoke the Table object with the ID 99991 from the object');
        Assert.ExpectedError('An object with that ID does not exist in the current application');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
