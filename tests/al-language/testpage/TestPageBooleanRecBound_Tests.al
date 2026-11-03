// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: TP Boolean Rec Bound Row (60994), TP Boolean Rec Bound Card (60993), Assert (60021)
//
// TestPage.<field>.SetValue(Boolean) on a control bound directly to a Boolean source-table
// field (field(RecFlag; Rec.Flag)) — as opposed to a page-variable-bound Boolean control, which
// TestPageFieldVisibleGroup_Tests.al's ToggleDynamic/ToggleOuter already cover. The two look
// identical in AL but round-trip through different plumbing, so real-BC coverage of one is not
// evidence about the other.

codeunit 60998 "TP Boolean Rec Bound Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TP Boolean Rec Bound Row";
    begin
        Row.DeleteAll();
    end;

    local procedure Seed(Flag: Boolean)
    var
        Row: Record "TP Boolean Rec Bound Row";
    begin
        Row.Init();
        Row.PK := 'ROW1';
        Row.Value := 'Some Value';
        Row.Flag := Flag;
        Row.Insert();
    end;

    // Positive: SetValue(true) on a Rec-bound Boolean control is readable back through the
    // control itself, immediately, without closing the page.
    [Test]
    procedure SetValueTrue_RecBoundBooleanControl_ReadsBackTrueImmediately()
    var
        Card: TestPage "TP Boolean Rec Bound Card";
    begin
        Initialize();
        Seed(false);

        Card.OpenEdit();
        Card.First();
        Card.RecFlag.SetValue(true);
        Assert.IsTrue(Card.RecFlag.AsBoolean(),
            'the control must read back true immediately after SetValue(true)');
        Card.Close();
    end;

    // Positive, and the load-bearing case for this issue: the write must actually reach the
    // underlying table field, not just the control's own in-memory copy — proven by re-reading
    // the row from OUTSIDE the page, after Close(), through a fresh Record variable.
    [Test]
    procedure SetValueTrue_RecBoundBooleanControl_PersistsToTheUnderlyingRecord()
    var
        Row: Record "TP Boolean Rec Bound Row";
        Card: TestPage "TP Boolean Rec Bound Card";
    begin
        Initialize();
        Seed(false);

        Card.OpenEdit();
        Card.First();
        Card.RecFlag.SetValue(true);
        Card.Close();

        Row.Get('ROW1');
        Assert.IsTrue(Row.Flag, 'SetValue(true) on the Rec-bound control must persist Flag = true to the row');
    end;

    // Positive, the other direction: SetValue(false) on a field that started true must clear
    // it, both on the control and in the persisted row — proves the round trip is not a
    // one-way "true always works" coincidence.
    [Test]
    procedure SetValueFalse_RecBoundBooleanControl_ClearsAPreviouslyTrueField()
    var
        Row: Record "TP Boolean Rec Bound Row";
        Card: TestPage "TP Boolean Rec Bound Card";
    begin
        Initialize();
        Seed(true);

        Card.OpenEdit();
        Card.First();
        Assert.IsTrue(Card.RecFlag.AsBoolean(), 'sanity: the seeded row must start with Flag = true');
        Card.RecFlag.SetValue(false);
        Assert.IsFalse(Card.RecFlag.AsBoolean(), 'the control must read back false immediately after SetValue(false)');
        Card.Close();

        Row.Get('ROW1');
        Assert.IsFalse(Row.Flag, 'SetValue(false) on the Rec-bound control must persist Flag = false to the row');
    end;

    // Positive: writing the Boolean control must not disturb an unrelated field on the same
    // row — the same "did this corrupt a sibling field" shape of proof TestPageOnValidate_Tests
    // and TestPageVariableControl_Tests use elsewhere in this suite.
    [Test]
    procedure SetValueTrue_RecBoundBooleanControl_DoesNotDisturbASiblingField()
    var
        Row: Record "TP Boolean Rec Bound Row";
        Card: TestPage "TP Boolean Rec Bound Card";
    begin
        Initialize();
        Seed(false);

        Card.OpenEdit();
        Card.First();
        Card.RecFlag.SetValue(true);
        Card.Close();

        Row.Get('ROW1');
        Assert.AreEqual('Some Value', Row.Value, 'writing the Boolean control must not touch the sibling Value field');
    end;

    // Negative: a value that cannot be evaluated into a Boolean must be refused, not silently
    // coerced to some default — and must not have reached the row at all.
    [Test]
    procedure SetValue_TextThatIsNotABooleanSpelling_IsRejectedAndNotPersisted()
    var
        Row: Record "TP Boolean Rec Bound Row";
        Card: TestPage "TP Boolean Rec Bound Card";
    begin
        Initialize();
        Seed(false);
        // asserterror rolls back to the last commit; without this, that rollback also undoes
        // Initialize()'s DeleteAll/Seed above, same reasoning as the other asserterror tests in
        // this suite's siblings (TestPageOnValidate_Tests.al, TestPageVariableControl_Tests.al).
        Commit();

        Card.OpenEdit();
        Card.First();
        asserterror Card.RecFlag.SetValue('Maybe');
        Assert.ExpectedError('Maybe');
        Card.Close();

        Row.Get('ROW1');
        Assert.IsFalse(Row.Flag, 'a rejected value must not have been persisted to the row');
    end;
}
