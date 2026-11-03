// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-editable-method
// Scope: in-scope
// Fixtures used: TPSF Row (60261), TPSF Card (60262), Assert (60021)
//
// Two page controls over the same source-table field must stay individually addressable on a
// TestPage: each reports its OWN Editable, not the first one's.
//
// Both controls are read in the same test as well as separately, because the failure this guards
// against is not "one control answers wrongly" but "two references answer as the same control",
// and only reading both in one place states that directly.

codeunit 60263 "TPSF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TPSF Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'ROW1';
        Row.Shared := 'Shared Value';
        Row.Other := 'Other Value';
        Row.Insert();
    end;

    // Positive: the control that declares no Editable is editable.
    [Test]
    procedure FirstControlOverASharedField_IsEditable()
    var
        Card: TestPage "TPSF Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.IsTrue(Card.FirstOverShared.Editable(),
            'a control declaring no Editable of its own must be editable');
        Card.Close();
    end;

    // Negative: the SECOND control over that same field declares Editable = false, and must
    // report it. This is the assertion that fails if the two references resolve to one control.
    [Test]
    procedure SecondControlOverASharedField_ReportsItsOwnEditable()
    var
        Card: TestPage "TPSF Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.IsFalse(Card.SecondOverShared.Editable(),
            'the second control over a shared source field must report its own Editable = false');
        Card.Close();
    end;

    // The two together. Reading both in one place states the claim directly: they are two
    // controls, not one, so they cannot answer the same.
    [Test]
    procedure TwoControlsOverOneField_AnswerIndependently()
    var
        Card: TestPage "TPSF Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.IsTrue(Card.FirstOverShared.Editable(), 'the first control over the shared field is editable');
        Assert.IsFalse(Card.SecondOverShared.Editable(), 'the second control over the shared field is not');
        Card.Close();
    end;

    // A control over its own field, carrying the same Editable = false, so a failure that
    // collapses every control onto the first is distinguishable from one that collapses only
    // controls sharing a source field.
    [Test]
    procedure ControlOverItsOwnField_ReportsItsOwnEditable()
    var
        Card: TestPage "TPSF Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.IsFalse(Card.ThirdOverOwnField.Editable(),
            'a control over its own source field must report its own Editable = false');
        Card.Close();
    end;

    // Both controls read the same underlying field, so the value they show must be the record's.
    // This separates "the two controls are distinct" from "the second control is bound to
    // something else".
    [Test]
    procedure BothControlsOverOneField_ShowTheSameValue()
    var
        Card: TestPage "TPSF Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.AreEqual('Shared Value', Card.FirstOverShared.Value(), 'the first control shows the field');
        Assert.AreEqual('Shared Value', Card.SecondOverShared.Value(), 'the second control shows the same field');
        Card.Close();
    end;
}
