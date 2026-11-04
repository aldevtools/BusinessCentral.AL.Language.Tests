// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-type-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-securityfiltering-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), shared Assert (60021)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins the ordinals of SecurityFilter (read with Format(x, 0, 2) and Evaluate from a number), the text of
// FieldRef.Type for each field type of ALT Universal (an Enum field reports Option; Format of FieldType
// prints names, never ordinals, and ordinals of FieldType cannot be read from AL), and the answers of
// RecordLevelLocking, ReadPermission and WritePermission.
// BC versions: 27.5

codeunit 68270 "Probe Platform Options"
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
    procedure SecurityFilter_Ordinals()
    var
        Filter: SecurityFilter;
    begin
        Initialize();

        Assert.AreEqual('0', Format(SecurityFilter::Validated, 0, 2), 'Validated');
        Assert.AreEqual('1', Format(SecurityFilter::Filtered, 0, 2), 'Filtered');
        Assert.AreEqual('2', Format(SecurityFilter::Ignored, 0, 2), 'Ignored');
        Assert.AreEqual('3', Format(SecurityFilter::Disallowed, 0, 2), 'Disallowed');
        Assert.AreEqual('Filtered', Format(SecurityFilter::Filtered, 0, 0), 'format 0 prints the name');

        Assert.IsTrue(Evaluate(Filter, '3'), 'Evaluate from an ordinal');
        Assert.AreEqual('Disallowed', Format(Filter), 'ordinal 3');
    end;

    [Test]
    procedure FieldRef_Type_TextForEachFieldTypeOfALTUniversal()
    var
        RecRef: RecordRef;
        FieldRefValue: FieldRef;
        FieldNo: Integer;
        Types: Text;
    begin
        Initialize();
        RecRef.Open(Database::"ALT Universal");

        for FieldNo := 1 to 18 do begin
            FieldRefValue := RecRef.Field(FieldNo);
            Types += Format(FieldNo) + '=' + Format(FieldRefValue.Type) + ' ';
        end;

        Assert.AreEqual('1=Integer 2=Boolean 3=Integer 4=BigInteger 5=Decimal 6=Text 7=Code 8=Date 9=Time 10=DateTime 11=Duration 12=GUID 13=BLOB 14=Option 15=Option 16=Decimal 17=Text 18=Text ', Types, 'FieldRef.Type');
        RecRef.Close();
    end;

    [Test]
    procedure FieldType_Names_PrintAsTheTypeNames()
    begin
        Initialize();

        Assert.AreEqual('BLOB', Format(FieldType::BLOB), 'BLOB');
        Assert.AreEqual('GUID', Format(FieldType::GUID), 'GUID');
        Assert.AreEqual('RecordID', Format(FieldType::RecordID), 'RecordID');
        Assert.AreEqual('TableFilter', Format(FieldType::TableFilter), 'TableFilter');
        Assert.AreEqual('DateFormula', Format(FieldType::DateFormula), 'DateFormula');
        Assert.AreEqual('MediaSet', Format(FieldType::MediaSet), 'MediaSet');
        Assert.AreEqual('BLOB', Format(FieldType::BLOB, 0, 2), 'format 2 prints the name too, not an ordinal');
    end;

    [Test]
    procedure Record_Locking_And_Permissions()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        Initialize();

        Assert.IsTrue(ALTUniversal.RecordLevelLocking(), 'RecordLevelLocking');
        Assert.IsTrue(ALTUniversal.ReadPermission(), 'ReadPermission');
        Assert.IsTrue(ALTUniversal.WritePermission(), 'WritePermission');
        Assert.IsFalse(ALTUniversal.ReadConsistency(), 'ReadConsistency');
    end;
}
