// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-minvalue-property
// Scope: in-scope
// Fixtures used: Test Page MinMax Row (60908), Test Page MinMax Card (60909), Assert
//
// A field's MinValue/MaxValue is enforced on a TestPage control write, but NOT on Rec.Validate
// or on a plain field assignment — these four surfaces are exercised on the identical bound
// field so the asymmetry itself is the thing under test, not just "SetValue refuses somehow".
// Covers both a Decimal field (bound text and value render with decimal places) and an Integer
// field (neither does), and confirms an in-range write still succeeds.

codeunit 60934 "Test Page Field MinMaxValue"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Seed(No: Code[20]; var Row: Record "Test Page MinMax Row")
    begin
        if Row.Get(No) then
            Row.Delete();
        Row.Init();
        Row."No." := No;
        Row.Insert();
    end;

    [Test]
    procedure SetValue_BelowMinDecimal_Refuses()
    var
        Row: Record "Test Page MinMax Row";
        Card: TestPage "Test Page MinMax Card";
    begin
        Seed('T1', Row);
        Commit();

        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror Card.Completion.SetValue(-1);
        Assert.ExpectedError('The value must be greater than or equal to 0');
        Card.Close();

        Row.Get('T1');
        Assert.AreEqual(0, Row.Completion, 'a refused SetValue must not have persisted');
    end;

    [Test]
    procedure SetValue_AboveMaxDecimal_Refuses()
    var
        Row: Record "Test Page MinMax Row";
        Card: TestPage "Test Page MinMax Card";
    begin
        Seed('T2', Row);
        Commit();

        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror Card.Completion.SetValue(101);
        Assert.ExpectedError('The value must be less than or equal to 100');
        Card.Close();

        Row.Get('T2');
        Assert.AreEqual(0, Row.Completion, 'a refused SetValue must not have persisted');
    end;

    [Test]
    procedure SetValue_BelowMinInteger_Refuses()
    var
        Row: Record "Test Page MinMax Row";
        Card: TestPage "Test Page MinMax Card";
    begin
        Seed('T3', Row);
        Commit();

        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror Card.Score.SetValue(-1);
        Assert.ExpectedError('The value must be greater than or equal to 0');
        Card.Close();
    end;

    [Test]
    procedure SetValue_AboveMaxInteger_Refuses()
    var
        Row: Record "Test Page MinMax Row";
        Card: TestPage "Test Page MinMax Card";
    begin
        Seed('T4', Row);
        Commit();

        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror Card.Score.SetValue(11);
        Assert.ExpectedError('The value must be less than or equal to 10');
        Card.Close();
    end;

    [Test]
    procedure SetValue_WithinBounds_Succeeds()
    var
        Row: Record "Test Page MinMax Row";
        Card: TestPage "Test Page MinMax Card";
    begin
        Seed('T5', Row);
        Commit();

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Completion.SetValue(50);
        Card.Close();

        Row.Get('T5');
        Assert.AreEqual(50, Row.Completion, 'an in-range SetValue must persist');
    end;

    [Test]
    procedure Validate_BelowMinDecimal_DoesNotRaise()
    var
        Row: Record "Test Page MinMax Row";
    begin
        Row.Init();
        Row."No." := 'T6';
        Row.Validate(Completion, -1);
        Row.Insert();

        Row.Get('T6');
        Assert.AreEqual(-1, Row.Completion, 'Rec.Validate must not enforce MinValue');
    end;

    [Test]
    procedure DirectAssignment_BelowMinDecimal_DoesNotRaise()
    var
        Row: Record "Test Page MinMax Row";
    begin
        Row.Init();
        Row."No." := 'T7';
        Row.Completion := -1;
        Row.Insert();

        Row.Get('T7');
        Assert.AreEqual(-1, Row.Completion, 'a plain field assignment must not enforce MinValue');
    end;
}
