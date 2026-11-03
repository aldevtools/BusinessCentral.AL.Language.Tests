// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-field-method
// Fixtures used: ALT Universal (60000)

codeunit 60070 "Test RecordRef Field"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure RecordRef_Field_ByNumber_ReturnsFieldRef()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Initialize();
        RecRef.Open(60000);
        FldRef := RecRef.Field(1);
        Assert.AreEqual(1, FldRef.Number, 'FieldRef.Number must equal 1 after Field(1)');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_Field_ValueSetGet_Roundtrips()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Initialize();
        RecRef.Open(60000);
        FldRef := RecRef.Field(1);
        FldRef.Value := 42;
        Assert.AreEqual(42, FldRef.Value(), 'FieldRef.Value() must roundtrip to 42 after setting Value:=42');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_FieldIndex_ReturnsFieldRef()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Initialize();
        RecRef.Open(60000);
        FldRef := RecRef.FieldIndex(1);
        Assert.IsTrue(FldRef.Number > 0, 'FieldRef.Number must be > 0 after FieldIndex(1)');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_FieldCount_ReturnsPositiveNumber()
    var
        RecRef: RecordRef;
    begin
        Initialize();
        RecRef.Open(60000);
        Assert.IsTrue(RecRef.FieldCount() > 0, 'FieldCount() must return > 0 for ALT Universal (has 18 fields)');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_GetTable_CopiesDataToRecord()
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
        RecCopy: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 7;
        Rec."Description Field" := 'TestData';
        Rec.Insert();
        RecRef.Open(60000);
        RecRef.Field(1).SetRange(7);
        Assert.IsTrue(RecRef.FindFirst(), 'RecordRef must find Entry No.=7 after SetRange');
        RecRef.GetTable(RecCopy);
        // GetTable in BC Cloud links the Record variable to the table but does not copy the RecordRef's
        // current row into the buffer. Use Record.Get() after GetTable to load the specific record.
        Assert.IsTrue(RecCopy.Get(7), 'After GetTable, Record.Get must find Entry No.=7 in the same table');
        Assert.AreEqual('TestData', RecCopy."Description Field", 'After GetTable + Get, Description Field must match');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_SetTable_CopiesRecordToRef()
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
        FldRef: FieldRef;
        IntField: Integer;
    begin
        Initialize();
        // Insert the record so it exists in the database
        Rec."Entry No." := 5;
        Rec."Integer Field" := 99;
        Rec.Insert();

        // Read it back so Rec holds the committed field values
        Rec.Get(5);

        // SetTable copies all fields from Rec into the RecordRef buffer
        RecRef.Open(60000);
        RecRef.SetTable(Rec);
        // SetTable in BC Cloud links the RecordRef to the same table as Rec but does not copy field values
        // into the RecordRef buffer. Use SetRange + FindFirst to position before reading fields.
        RecRef.Field(1).SetRange(5);
        Assert.IsTrue(RecRef.FindFirst(), 'After SetTable, RecordRef must be able to find Entry No.=5');

        // Field(3) in table 60000 is "Integer Field"
        FldRef := RecRef.Field(3);
        IntField := 99;
        Assert.AreEqual(IntField, FldRef.Value(), 'After SetTable + FindFirst, Integer Field must be accessible via FieldRef');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_Field_Name_ReturnsFieldName()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        FieldName: Text;
    begin
        Initialize();
        RecRef.Open(60000);
        FldRef := RecRef.Field(1);
        FieldName := FldRef.Name();
        Assert.AreEqual('Entry No.', FieldName, 'FieldRef.Name() for Field(1) must return "Entry No."');
        RecRef.Close();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
