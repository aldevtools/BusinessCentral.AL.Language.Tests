// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-data-type
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Keyed (60006)

codeunit 60132 "Test RecordRef Extended"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── RecordRef Extended Methods ──────────────────────────────────────────────

        [Test]
    procedure RecordRef_SystemCreatedAtNo_ReturnsPositiveFieldNo()
    var
        RecRef: RecordRef;
        FieldNo: Integer;
    begin
        Initialize();
        RecRef.Open(60000);
        FieldNo := RecRef.SystemCreatedAtNo();
        Assert.IsTrue(FieldNo > 0, 'SystemCreatedAtNo() must return positive field number');
    end;

    [Test]
    procedure RecordRef_SystemCreatedByNo_ReturnsPositiveFieldNo()
    var
        RecRef: RecordRef;
        FieldNo: Integer;
    begin
        Initialize();
        RecRef.Open(60000);
        FieldNo := RecRef.SystemCreatedByNo();
        Assert.IsTrue(FieldNo > 0, 'SystemCreatedByNo() must return positive field number');
    end;

    [Test]
    procedure RecordRef_SystemModifiedAtNo_ReturnsPositiveFieldNo()
    var
        RecRef: RecordRef;
        FieldNo: Integer;
    begin
        Initialize();
        RecRef.Open(60000);
        FieldNo := RecRef.SystemModifiedAtNo();
        Assert.IsTrue(FieldNo > 0, 'SystemModifiedAtNo() must return positive field number');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
