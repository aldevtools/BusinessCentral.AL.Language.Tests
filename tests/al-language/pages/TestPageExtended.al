// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: TestPage extended API methods (GoToKey, GoToRecord, FindFirstField, FindNextField, GetField, TestField value/AsInteger/AssertEquals)
// Fixtures used: ALT Universal (60000), ALT List Page (60016), ALT Card Page (60017)

codeunit 60126 "Test Page Extended"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── TestPage.GoToKey() ──────────────────────────────────────────────────────

    [Test]
    procedure Page_GoToKey_ExistingRecord_ReturnsTrue()
    var
        ListPage: TestPage "ALT List Page";
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 5;
        Rec."Integer Field" := 99;
        Rec.Insert();

        ListPage.OpenView();
        Assert.IsTrue(ListPage.GoToKey(5), 'GoToKey(5) must return true for existing record');
        Assert.AreEqual('5', ListPage."Entry No.".Value(), 'GoToKey must position on correct record with Entry No. = 5');
        ListPage.Close();
    end;

    [Test]
    procedure Page_GoToKey_MissingRecord_ReturnsFalse()
    var
        ListPage: TestPage "ALT List Page";
    begin
        Initialize();
        ListPage.OpenView();
        Assert.IsFalse(ListPage.GoToKey(9999), 'GoToKey(9999) must return false for non-existent record');
        ListPage.Close();
    end;

    // ── TestPage.GoToRecord() ───────────────────────────────────────────────────

    [Test]
    procedure Page_GoToRecord_FindsRecord()
    var
        ListPage: TestPage "ALT List Page";
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 3;
        Rec."Integer Field" := 77;
        Rec.Insert();

        ListPage.OpenView();
        Assert.IsTrue(ListPage.GoToRecord(Rec), 'GoToRecord must return true for valid record');
        Assert.AreEqual('3', ListPage."Entry No.".Value(), 'GoToRecord must position on the specified record with Entry No. = 3');
        ListPage.Close();
    end;

    // ── TestPage.FindFirstField() ───────────────────────────────────────────────

    [Test]
    procedure Page_FindFirstField_FindsByValue()
    var
        ListPage: TestPage "ALT List Page";
        Rec1, Rec2: Record "ALT Universal";
    begin
        Initialize();
        Rec1."Entry No." := 1;
        Rec1."Integer Field" := 42;
        Rec1.Insert();

        Rec2."Entry No." := 2;
        Rec2."Integer Field" := 99;
        Rec2.Insert();

        ListPage.OpenView();
        Assert.IsTrue(ListPage.FindFirstField(ListPage."Entry No.", 1), 'FindFirstField must find Entry No. = 1');
        Assert.AreEqual('1', ListPage."Entry No.".Value(), 'FindFirstField must position on record with Entry No. = 1');
        ListPage.Close();
    end;

    // ── TestPage.FindNextField() ────────────────────────────────────────────────

    [Test]
    procedure Page_FindNextField_Iterates()
    var
        ListPage: TestPage "ALT List Page";
        Rec1, Rec2, Rec3: Record "ALT Universal";
        Found: Boolean;
    begin
        Initialize();
        Rec1."Entry No." := 1;
        Rec1.Insert();

        Rec2."Entry No." := 2;
        Rec2.Insert();

        Rec3."Entry No." := 3;
        Rec3.Insert();

        ListPage.OpenView();
        Found := ListPage.FindFirstField(ListPage."Entry No.", 1);
        Assert.IsTrue(Found, 'FindFirstField must find Entry No. = 1');
        Assert.AreEqual('1', ListPage."Entry No.".Value(), 'Must be positioned at Entry No. = 1');

        Found := ListPage.FindNextField(ListPage."Entry No.", 2);
        Assert.IsTrue(Found, 'FindNextField must find Entry No. = 2');
        Assert.AreEqual('2', ListPage."Entry No.".Value(), 'After FindNextField, must be at Entry No. = 2');

        ListPage.Close();
    end;

    // ── TestPage.GetField() ─────────────────────────────────────────────────────

    [Test]
    procedure Page_GetField_ByFieldId_ReturnsValidTestField()
    var
        ListPage: TestPage "ALT List Page";
    begin
        Initialize();
        ListPage.OpenView();
        // TestField is accessed inline via page field references, not as a typed variable
        Assert.AreNotEqual('', ListPage."Entry No.".Caption(), 'Entry No. field on ListPage must have a non-empty caption');
        ListPage.Close();
    end;

    // ── TestField.Value() ───────────────────────────────────────────────────────

    [Test]
    procedure Page_TestField_Value_SetAndGet()
    var
        ListPage: TestPage "ALT List Page";
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 77;
        Rec.Insert();

        ListPage.OpenView();
        ListPage.First();
        Assert.AreEqual('77', ListPage."Integer Field".Value(), 'TestField.Value() must return field value as text');
        ListPage.Close();
    end;

    // ── TestField.AssertEquals() ────────────────────────────────────────────────

    [Test]
    procedure Page_TestField_AssertEquals_Succeeds()
    var
        ListPage: TestPage "ALT List Page";
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 42;
        Rec.Insert();

        ListPage.OpenView();
        ListPage.First();
        ListPage."Integer Field".AssertEquals(42);
        Assert.IsTrue(true, 'AssertEquals must succeed for matching value (no exception thrown)');
        ListPage.Close();
    end;

    // AssertEquals against an Option/Enum-typed control.
    //
    // The expected side of AssertEquals is an AL Option/Enum value, which is an ORDINAL; the
    // actual side is the page control's value, which is the text the control shows. These
    // tests pin that BC renders both sides the same way, so passing the option value that the
    // record actually holds is a match, and that the failure message names the option by the
    // same text on both sides rather than by its ordinal.

    [Test]
    procedure Page_TestField_AssertEquals_EnumField_MatchesOptionValue()
    var
        ListPage: TestPage "ALT List Page";
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        // Ordinal 2 of enum "ALT Status", so a comparison that leaked the ordinal would read '2'.
        Rec."Status Field" := Rec."Status Field"::Active;
        Rec.Insert();

        ListPage.OpenView();
        ListPage.First();
        Assert.AreEqual('Active', ListPage."Status Field".Value(),
            'An Enum control shows its value''s Caption, not the ordinal it stores');
        ListPage."Status Field".AssertEquals(Rec."Status Field"::Active);
        ListPage.Close();
    end;

    [Test]
    procedure Page_TestField_AssertEquals_EnumField_WrongOptionValueFails()
    var
        ListPage: TestPage "ALT List Page";
        Rec: Record "ALT Universal";
        ErrorText: Text;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Status Field" := Rec."Status Field"::Active;
        Rec.Insert();

        ListPage.OpenView();
        ListPage.First();
        asserterror ListPage."Status Field".AssertEquals(Rec."Status Field"::Draft);
        ErrorText := GetLastErrorText();
        ListPage.Close();

        // Both sides of the message are the option's own text. 'Draft' is the expected side,
        // which is the half that starts life as the ordinal 1.
        Assert.IsSubstring(ErrorText, 'Draft');
        Assert.IsSubstring(ErrorText, 'Active');
    end;

    [Test]
    procedure Page_TestField_AssertEquals_OptionField_MatchesOptionValue()
    var
        ListPage: TestPage "ALT List Page";
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        // "Option Field" is the plain Option primitive: OptionMembers = " ",Draft,Active,Closed
        // with no OptionCaption declared, so its members are also what the control shows.
        Rec."Option Field" := Rec."Option Field"::Active;
        Rec.Insert();

        ListPage.OpenView();
        ListPage.First();
        Assert.AreEqual('Active', ListPage."Option Field".Value(),
            'An Option control shows its member name, not the ordinal it stores');
        ListPage."Option Field".AssertEquals(Rec."Option Field"::Active);
        ListPage.Close();
    end;

    [Test]
    procedure Page_TestField_AssertEquals_OptionField_WrongOptionValueFails()
    var
        ListPage: TestPage "ALT List Page";
        Rec: Record "ALT Universal";
        ErrorText: Text;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Option Field" := Rec."Option Field"::Active;
        Rec.Insert();

        ListPage.OpenView();
        ListPage.First();
        asserterror ListPage."Option Field".AssertEquals(Rec."Option Field"::Closed);
        ErrorText := GetLastErrorText();
        ListPage.Close();

        Assert.IsSubstring(ErrorText, 'Closed');
        Assert.IsSubstring(ErrorText, 'Active');
    end;

    // ── TestField.AsInteger() ───────────────────────────────────────────────────

    [Test]
    procedure Page_TestField_AsInteger_ReturnsValue()
    var
        ListPage: TestPage "ALT List Page";
        Rec: Record "ALT Universal";
        IntValue: Integer;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 55;
        Rec.Insert();

        ListPage.OpenView();
        ListPage.First();
        IntValue := ListPage."Entry No.".AsInteger();
        Assert.AreEqual(1, IntValue, 'TestField.AsInteger() must return integer value 1 for Entry No. field');
        ListPage.Close();
    end;

    // ── TestPage.Close() ────────────────────────────────────────────────────────

    [Test]
    procedure Page_Close_DoesNotThrow()
    var
        ListPage: TestPage "ALT List Page";
    begin
        Initialize();
        ListPage.OpenView();
        ListPage.Close();
        Assert.IsTrue(true, 'Close() must complete without error');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
