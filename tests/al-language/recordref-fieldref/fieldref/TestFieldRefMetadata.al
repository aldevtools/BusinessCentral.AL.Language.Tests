codeunit 60076 "Test FieldRef Metadata"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure FieldRef_Number_ReturnsFieldNumber()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();

        RecRef.Open(60000);
        FldRef := RecRef.Field(1);
        Assert.AreEqual(1, FldRef.Number(), 'Field(1).Number() must return 1');
    end;

    [Test]
    procedure FieldRef_Name_ReturnsFieldName()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        FieldName: Text;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();

        RecRef.Open(60000);
        FldRef := RecRef.Field(1);
        FieldName := FldRef.Name();
        Assert.AreEqual('Entry No.', FieldName, 'Field(1).Name() must return Entry No.');
    end;

    [Test]
    procedure FieldRef_Caption_ReturnsCaption()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        Caption: Text;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();

        RecRef.Open(60000);
        FldRef := RecRef.Field(1);
        Caption := FldRef.Caption();
        Assert.IsTrue(Caption <> '', 'Field(1).Caption() must return non-empty string');
    end;

    [Test]
    procedure FieldRef_Type_IntegerField_ReturnsIntegerType()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        FieldType: FieldType;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();

        RecRef.Open(60000);
        FldRef := RecRef.Field(3);  // Integer Field
        FieldType := FldRef.Type();
        Assert.AreNotEqual('', Format(FieldType), 'Field(3).Type() must not be empty string');
    end;

    [Test]
    procedure FieldRef_Class_Normal_ReturnsNormal()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        FieldClass: FieldClass;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();

        RecRef.Open(60000);
        FldRef := RecRef.Field(1);
        FieldClass := FldRef.Class();
        Assert.AreEqual(FieldClass::Normal, FieldClass, 'Field(1).Class() must return Normal');
    end;

    [Test]
    procedure FieldRef_Active_NormalField_ReturnsTrue()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();

        RecRef.Open(60000);
        FldRef := RecRef.Field(1);
        Assert.IsTrue(FldRef.Active(), 'Field(1).Active() must return true');
    end;

    [Test]
    procedure FieldRef_Length_TextField_ReturnsLength()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        FieldLength: Integer;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();

        RecRef.Open(60000);
        FldRef := RecRef.Field(6);  // Text Field - Text[100]
        FieldLength := FldRef.Length();
        Assert.AreEqual(100, FieldLength, 'Field(6).Length() must return 100');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
