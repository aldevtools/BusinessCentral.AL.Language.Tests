// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-data-type
// Scope: in-scope
// Fixtures used: ALT Universal (60000) with its table extension "ALT Universal Validated" (one extra
//                field, 60250), ALTFixtureCleanup (60019), shared Assert (60021)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins RecordRef.Open of a missing table (text and code), FieldCount and FieldIndex (the count
// leaves out the system fields, FieldIndex past the count reaches them), KeyRef/FieldRef Active, the
// enum metadata calls on enum, option and other fields, that GetTable and SetTable copy filters,
// key and direction, and that Duplicate is independent.
// BC versions: 27.5

codeunit 68163 "Probe RecordRef Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    [Test]
    procedure RecordRef_Open_MissingTable_FullTextShapeAndCode()
    // CLAIM: "You tried to invoke the Table object with the ID 99999 from the object <caller>. An object with that ID does not exist in the current application compiled with emit version <n>." with code AL:MetadataNotFound (the caller and the emit version differ by host and BC version).
    var
        RecRef: RecordRef;
        Text: Text;
        Version: Integer;
    begin
        Initialize();

        asserterror RecRef.Open(99999);

        Text := GetLastErrorText();
        Assert.IsTrue(Text.StartsWith('You tried to invoke the Table object with the ID 99999 from the object '), 'prefix: ' + Text);
        Assert.IsTrue(Text.Contains('. An object with that ID does not exist in the current application compiled with emit version '), 'glue: ' + Text);
        Assert.IsTrue(Text.EndsWith('.'), 'full stop: ' + Text);
        Assert.IsTrue(Evaluate(Version, Text.Substring(Text.IndexOf('emit version ') + StrLen('emit version ')).TrimEnd('.')), 'the emit version is a number: ' + Text);
        Assert.AreEqual('AL:MetadataNotFound', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure RecordRef_FieldCount_ExcludesSystemFields_ButFieldIndexPastTheCountReachesThem()
    var
        RecRef: RecordRef;
    begin
        Initialize();
        RecRef.Open(Database::"ALT Universal");

        Assert.AreEqual(19, RecRef.FieldCount(), '18 fields of the table and 1 of the table extension');
        Assert.AreEqual(1, RecRef.FieldIndex(1).Number(), 'first field');
        Assert.AreEqual(18, RecRef.FieldIndex(18).Number(), 'the last field of the table');
        Assert.AreEqual(60250, RecRef.FieldIndex(19).Number(), 'the extension field follows in number order');
        Assert.AreEqual(2000000000, RecRef.FieldIndex(20).Number(), '$systemId');
        Assert.AreEqual(2000000001, RecRef.FieldIndex(21).Number(), 'SystemCreatedAt');
        Assert.AreEqual(2000000002, RecRef.FieldIndex(22).Number(), 'SystemCreatedBy');
        Assert.AreEqual(2000000003, RecRef.FieldIndex(23).Number(), 'SystemModifiedAt');
        Assert.AreEqual(2000000004, RecRef.FieldIndex(24).Number(), 'SystemModifiedBy');
        RecRef.Close();
    end;

    [Test]
    procedure KeyRefAndFieldRef_Active_AreTrue_KeyCount()
    var
        RecRef: RecordRef;
        KeyRefValue: KeyRef;
        FieldRefValue: FieldRef;
    begin
        Initialize();
        RecRef.Open(Database::"ALT Universal");

        KeyRefValue := RecRef.KeyIndex(1);
        FieldRefValue := RecRef.Field(1);

        Assert.IsTrue(KeyRefValue.Active(), 'KeyRef.Active');
        Assert.IsTrue(FieldRefValue.Active(), 'FieldRef.Active');
        Assert.AreEqual(2, RecRef.KeyCount(), 'the primary key and one more');
        RecRef.Close();
    end;

    [Test]
    procedure FieldRef_EnumMetadata_OnEnumOptionAndOtherFields()
    var
        RecRef: RecordRef;
        FieldRefValue: FieldRef;
    begin
        Initialize();
        RecRef.Open(Database::"ALT Universal");

        FieldRefValue := RecRef.Field(15);
        Assert.IsTrue(FieldRefValue.IsEnum(), 'enum field');
        Assert.AreEqual(5, FieldRefValue.EnumValueCount(), 'enum value count');

        FieldRefValue := RecRef.Field(14);
        Assert.IsFalse(FieldRefValue.IsEnum(), 'option field is not an enum');
        Assert.AreEqual(4, FieldRefValue.EnumValueCount(), 'but it counts its members');
        Assert.AreEqual(' ,Draft,Active,Closed', FieldRefValue.OptionCaption(), 'option caption');
        Assert.AreEqual(' ,Draft,Active,Closed', FieldRefValue.OptionMembers(), 'option members');

        FieldRefValue := RecRef.Field(3);
        Assert.IsFalse(FieldRefValue.IsEnum(), 'integer field');
        Assert.AreEqual(0, FieldRefValue.EnumValueCount(), 'no members');
        Assert.AreEqual('', FieldRefValue.OptionCaption(), 'OptionCaption of an integer field is empty, not an error');
        Assert.AreEqual('', FieldRefValue.OptionMembers(), 'OptionMembers likewise');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_GetTableAndSetTable_CopyFiltersKeyAndDirection()
    var
        ALTUniversal: Record "ALT Universal";
        Copy: Record "ALT Universal";
        RecRef: RecordRef;
    begin
        Initialize();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 2;
        ALTUniversal.Insert();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal.Insert();
        Commit();

        ALTUniversal.SetRange("Entry No.", 2);
        ALTUniversal.SetCurrentKey("Text Field");
        ALTUniversal.Ascending(false);
        RecRef.GetTable(ALTUniversal);

        Assert.AreEqual('Entry No.: 2', RecRef.GetFilters(), 'GetTable copies the filters');
        Assert.AreEqual(1, RecRef.Count(), 'and they apply');

        RecRef.SetTable(Copy);
        Assert.AreEqual('Entry No.: 2', Copy.GetFilters(), 'SetTable copies the filters back');
        Assert.AreEqual('Text Field', Copy.CurrentKey(), 'and the key');
        Assert.IsFalse(Copy.Ascending(), 'and the direction');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_Duplicate_IsIndependent()
    var
        RecRef: RecordRef;
        Duplicated: RecordRef;
    begin
        Initialize();
        RecRef.Open(Database::"ALT Universal");
        Duplicated := RecRef.Duplicate();

        RecRef.Field(1).SetRange(1);

        Assert.AreEqual('Entry No.: 1', RecRef.GetFilters(), 'the original');
        Assert.AreEqual('', Duplicated.GetFilters(), 'the duplicate does not see the later filter');
        RecRef.Close();
        Duplicated.Close();
    end;
}
