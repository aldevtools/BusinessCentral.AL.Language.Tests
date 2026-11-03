// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-data-type
// Scope: in-scope
// Fixtures used: ALT Universal (60000, field 15 = "Status Field" Enum "ALT Status"), ALT Status enum (values: ' ', Draft, Active, Closed, Archived)

codeunit 60131 "Test FieldRef Enum"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── FieldRef Enum Methods ───────────────────────────────────────────────────

    [Test]
    procedure FieldRef_EnumValueCount_ReturnsCount()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Initialize();
        RecRef.Open(60000);  // ALT Universal
        FldRef := RecRef.Field(15);  // "Status Field" = Enum "ALT Status"
        Assert.AreEqual(5, FldRef.EnumValueCount(), 'EnumValueCount() must return 5 for ALT Status enum');
    end;

    [Test]
    procedure FieldRef_GetEnumValueName_ByIndex_ReturnsName()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Name: Text;
    begin
        Initialize();
        RecRef.Open(60000);
        FldRef := RecRef.Field(15);
        // Index 1 (1-based) returns first enum value ' ' (space)
        Name := FldRef.GetEnumValueName(1);
        Assert.AreEqual(' ', Name, 'GetEnumValueName(1) must return first enum value (space)');
    end;

    [Test]
    procedure FieldRef_GetEnumValueName_Index3_ReturnsActive()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Name: Text;
    begin
        Initialize();
        RecRef.Open(60000);
        FldRef := RecRef.Field(15);
        // Index 3 (1-based) returns third enum value "Active"
        Name := FldRef.GetEnumValueName(3);
        Assert.AreEqual('Active', Name, 'GetEnumValueName(3) must return "Active"');
    end;

    [Test]
    procedure FieldRef_GetEnumValueCaption_ByIndex_ReturnsCaption()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Caption: Text;
    begin
        Initialize();
        RecRef.Open(60000);
        FldRef := RecRef.Field(15);
        // Index 1 (1-based) returns caption for first enum value (space)
        Caption := FldRef.GetEnumValueCaption(1);
        Assert.AreEqual(' ', Caption, 'GetEnumValueCaption(1) must return caption for first enum value');
    end;

    [Test]
    procedure FieldRef_GetEnumValueOrdinal_ByIndex_ReturnsOrdinal()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Ordinal: Integer;
    begin
        Initialize();
        RecRef.Open(60000);
        FldRef := RecRef.Field(15);
        // Index 1 (1-based) returns ordinal of first enum value (space) = 0
        Ordinal := FldRef.GetEnumValueOrdinal(1);
        Assert.AreEqual(0, Ordinal, 'GetEnumValueOrdinal(1) must return ordinal value 0');
    end;

    [Test]
    procedure FieldRef_GetEnumValueNameFromOrdinalValue_ReturnsName()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Name: Text;
    begin
        Initialize();
        RecRef.Open(60000);
        FldRef := RecRef.Field(15);
        // Ordinal 2 = Active enum value
        Name := FldRef.GetEnumValueNameFromOrdinalValue(2);
        Assert.AreEqual('Active', Name, 'GetEnumValueNameFromOrdinalValue(2) must map to "Active"');
    end;

    [Test]
    procedure FieldRef_GetEnumValueCaptionFromOrdinalValue_ReturnsCaption()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Caption: Text;
    begin
        Initialize();
        RecRef.Open(60000);
        FldRef := RecRef.Field(15);
        // Ordinal 1 = Draft enum value
        Caption := FldRef.GetEnumValueCaptionFromOrdinalValue(1);
        Assert.AreEqual('Draft', Caption, 'GetEnumValueCaptionFromOrdinalValue(1) must map to "Draft"');
    end;

    [Test]
    procedure FieldRef_IsEnum_EnumField_ReturnsTrue()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Initialize();
        RecRef.Open(60000);
        FldRef := RecRef.Field(15);  // "Status Field" is an enum field
        Assert.IsTrue(FldRef.IsEnum(), '"Status Field" is an enum field — IsEnum() must return true');
    end;

    [Test]
    procedure FieldRef_IsEnum_IntegerField_ReturnsFalse()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Initialize();
        RecRef.Open(60000);
        FldRef := RecRef.Field(3);  // "Integer Field" is not an enum
        Assert.IsFalse(FldRef.IsEnum(), '"Integer Field" is not an enum — IsEnum() must return false');
    end;

    [Test]
    procedure FieldRef_OptionCaption_ReturnsString()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        OptionCaptions: Text;
    begin
        Initialize();
        RecRef.Open(60000);
        FldRef := RecRef.Field(14);  // "Option Field" has OptionCaption
        OptionCaptions := FldRef.OptionCaption();
        Assert.AreNotEqual('', OptionCaptions, 'OptionCaption() must return non-empty string for option field');
    end;

    [Test]
    procedure FieldRef_IsOptimizedForTextSearch_Callable()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        IsOptimized: Boolean;
    begin
        Initialize();
        RecRef.Open(60000);
        FldRef := RecRef.Field(6);  // "Text Field"
        IsOptimized := FldRef.IsOptimizedForTextSearch();
        Assert.IsTrue(true, 'IsOptimizedForTextSearch() must be callable without error and return boolean');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
