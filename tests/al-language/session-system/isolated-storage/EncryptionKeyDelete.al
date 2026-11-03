// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-deleteencryptionkey-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); codeunits 74792 (runner) and 74897 (tests)
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: DeleteEncryptionKey and the state it leaves: EncryptionEnabled() and EncryptionKeyExists() before and after, DeleteEncryptionKey with a key present, and a second
//   DeleteEncryptionKey with no key (does it raise, error text and code). The CI database has a key at the start (measured), so the test deletes it and creates a new one
//   at the end (CreateEncryptionKey), so the database ends with a key as it began. The codeunit has one of the highest ids, so the tests that run after it still find a key.
//   Nothing is encrypted by these tests.
// BC versions: all (CI)

codeunit 74792 "LT EKD Runner"
{
    trigger OnRun()
    begin
        DeleteEncryptionKey();
    end;
}

codeunit 74897 "LT Encryption Key Delete"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure State_AtStart()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('enabled', Format(EncryptionEnabled()));
        Observer.Observe('keyExists', Format(EncryptionKeyExists()));
        Observer.Expect('enabled', 'Yes');
        Observer.Expect('keyExists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Delete_WithKey_ThenWithout_ThenRestore()
    var
        Observer: Codeunit "Probe Observer";
        Runner: Codeunit "LT EKD Runner";
        Ran: Boolean;
    begin
        Observer.Observe('keyExistsAtStart', Format(EncryptionKeyExists()));
        if not EncryptionKeyExists() then
            CreateEncryptionKey();
        Ran := Runner.Run();
        Observer.Observe('deleteWithKeyRan', Format(Ran));
        if not Ran then
            Observer.ObserveError('deleteWithKeyErr');
        Observer.Observe('enabledAfterDelete', Format(EncryptionEnabled()));
        Observer.Observe('keyExistsAfterDelete', Format(EncryptionKeyExists()));
        Ran := Runner.Run();
        Observer.Observe('deleteWithoutKeyRan', Format(Ran));
        if not Ran then
            Observer.ObserveError('deleteWithoutKeyErr');
        Observer.Observe('enabledAfterSecond', Format(EncryptionEnabled()));
        Observer.Observe('keyExistsAfterSecond', Format(EncryptionKeyExists()));
        if not EncryptionKeyExists() then
            CreateEncryptionKey();
        Observer.Observe('keyExistsRestored', Format(EncryptionKeyExists()));
        Observer.Expect('keyExistsAtStart', 'Yes');
        Observer.Expect('deleteWithKeyRan', 'Yes');
        Observer.Expect('enabledAfterDelete', 'No');
        Observer.Expect('keyExistsAfterDelete', 'No');
        Observer.Expect('deleteWithoutKeyRan', 'Yes');
        Observer.Expect('enabledAfterSecond', 'No');
        Observer.Expect('keyExistsAfterSecond', 'No');
        Observer.Expect('keyExistsRestored', 'Yes');
        Observer.Verify();
    end;
}
