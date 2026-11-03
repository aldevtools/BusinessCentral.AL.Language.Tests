// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-keyindex-method
// Fixtures used: ALT Universal (60000), ALT Composite (60001)

codeunit 60071 "Test RecordRef Keys"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure RecordRef_KeyCount_ALTUniversal_PositiveCount()
    var
        RecRef: RecordRef;
    begin
        Initialize();
        RecRef.Open(60000);
        Assert.IsTrue(RecRef.KeyCount() >= 1, 'KeyCount() for ALT Universal must return >= 1 (has primary key)');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_KeyIndex_FirstKey_ReturnsKeyRef()
    var
        RecRef: RecordRef;
        KeyRef: KeyRef;
    begin
        Initialize();
        RecRef.Open(60000);
        KeyRef := RecRef.KeyIndex(1);
        Assert.IsTrue(KeyRef.Active(), 'KeyRef.Active() for KeyIndex(1) must return true (primary key is active)');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_Get_ByPrimaryKey_FindsRecord()
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Initialize();
        Rec."Entry No." := 42;
        Rec."Description Field" := 'GetTest';
        Rec.Insert();
        RecRef.Open(60000);
        RecRef.Get(Rec.RecordId());
        FldRef := RecRef.Field(1);
        Assert.AreEqual(42, FldRef.Value(), 'Get(RecordId) must retrieve record with Entry No.=42');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_AddLink_HasLinks_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
    begin
        Initialize();
        Rec."Entry No." := 10;
        Rec.Insert();
        RecRef.Open(60000);
        RecRef.FindFirst();
        RecRef.AddLink('https://example.com');
        Assert.IsTrue(RecRef.HasLinks(), 'HasLinks() must return true after AddLink()');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_DeleteLinks_HasLinks_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
    begin
        Initialize();
        Rec."Entry No." := 11;
        Rec.Insert();
        RecRef.Open(60000);
        RecRef.FindFirst();
        RecRef.AddLink('https://example.com');
        RecRef.DeleteLinks();
        Assert.IsFalse(RecRef.HasLinks(), 'HasLinks() must return false after DeleteLinks()');
        RecRef.Close();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
