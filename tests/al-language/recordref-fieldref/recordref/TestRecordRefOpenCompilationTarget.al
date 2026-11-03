// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-open-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000)
//
// CLAIM OF THIS CODEUNIT: RecordRef.Open is scope-checked against the app's compilation
// target. This app declares "target": "Cloud" in app.json, so the platform refuses an open
// on a system table it marks internal, and allows every other table. The refusal is not a
// compile error — RecordRef.Open takes an ID, so the AL0296 scope diagnostic that fires on
// `Record "Object Metadata"` in a Cloud app never sees it; the check happens at run time and
// names both the table and the target.
//
// The four procedures below are one claim seen from four sides, and each one is load-bearing:
// without the "opens" arms, a platform that refused every RecordRef.Open, or every system
// table, would satisfy the first test alone.

codeunit 60270 "Test RecordRef Open Target"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure RecordRef_Open_InternalSystemTable_ThrowsForCloudTarget()
    // CLAIM: table 2000000071 is an internal system table, so a Cloud-target app cannot
    // open a RecordRef on it. The error names the table ID and the target.
    var
        RecRef: RecordRef;
    begin
        Initialize();

        asserterror RecRef.Open(2000000071);

        Assert.ExpectedError('You cannot open record 2000000071 from a RecordRef data type when you are using target Cloud.');
    end;

    [Test]
    procedure RecordRef_Open_NonRestrictedSystemTable_Opens()
    // CLAIM: the refusal above is specific to restricted system tables, not to system
    // tables as a class. Table 2000000026 ("Integer") is a system table a Cloud app may
    // open, and Number reports it back.
    var
        RecRef: RecordRef;
    begin
        Initialize();

        RecRef.Open(2000000026);

        Assert.AreEqual(2000000026, RecRef.Number, 'RecordRef.Open(2000000026) must open for a Cloud-target app');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_Open_AllowedOnPremSystemTable_Opens()
    // CLAIM: tables 2000000187 and 2000000188 are on the platform's allow list for
    // RecordRef usage from a non-OnPrem target, so a Cloud app opens both.
    var
        RecRef: RecordRef;
    begin
        Initialize();

        RecRef.Open(2000000187);
        Assert.AreEqual(2000000187, RecRef.Number, 'RecordRef.Open(2000000187) must open for a Cloud-target app');
        RecRef.Close();

        Clear(RecRef);
        RecRef.Open(2000000188);
        Assert.AreEqual(2000000188, RecRef.Number, 'RecordRef.Open(2000000188) must open for a Cloud-target app');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_Open_ApplicationTable_Opens()
    // CLAIM: an ordinary application table is never subject to the target check.
    var
        RecRef: RecordRef;
    begin
        Initialize();

        RecRef.Open(60000);

        Assert.AreEqual(60000, RecRef.Number, 'RecordRef.Open(60000) must open for a Cloud-target app');
        RecRef.Close();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
