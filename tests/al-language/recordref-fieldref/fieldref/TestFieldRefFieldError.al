codeunit 60077 "Test FieldRef FieldError"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure FieldRef_FieldError_EmptyField_Throws()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        ErrorText: Text;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 0;
        Rec.Insert();

        RecRef.Open(60000);
        RecRef.FindFirst();
        FldRef := RecRef.Field(3);

        asserterror FldRef.FieldError();
        ErrorText := GetLastErrorText();
        Assert.IsTrue(ErrorText <> '', 'FieldError() must throw error with non-empty message');
    end;

    [Test]
    procedure FieldRef_FieldError_WithMessage_ThrowsWithMessage()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        ErrorText: Text;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();

        RecRef.Open(60000);
        RecRef.FindFirst();
        FldRef := RecRef.Field(3);

        asserterror FldRef.FieldError('Custom msg');
        ErrorText := GetLastErrorText();
        Assert.IsTrue(StrPos(ErrorText, 'Custom') > 0, 'FieldError(msg) must include custom message text');
    end;

    [Test]
    procedure FieldRef_TestField_NonZero_Succeeds()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 3;
        Rec."Integer Field" := 42;
        Rec.Insert();

        RecRef.Open(60000);
        RecRef.FindFirst();
        FldRef := RecRef.Field(3);
        FldRef.TestField();
        // If TestField succeeds, test passes; no error expected
        Assert.IsTrue(true, 'TestField() on non-zero field must not throw');
    end;

    [Test]
    procedure FieldRef_TestField_Zero_Throws()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        ErrorText: Text;
    begin
        Initialize();
        Rec."Entry No." := 4;
        Rec."Integer Field" := 0;
        Rec.Insert();

        RecRef.Open(60000);
        RecRef.FindFirst();
        FldRef := RecRef.Field(3);

        asserterror FldRef.TestField();
        ErrorText := GetLastErrorText();
        Assert.IsTrue(ErrorText <> '', 'TestField() on zero field must throw error');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
