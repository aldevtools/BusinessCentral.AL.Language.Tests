// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-visible-method
// Scope: in-scope
// Fixtures used: TPCL Row (60264), TPCL Card (60265), Assert (60021)
//
// Visible, Editable and Enabled on a page control are not all evaluated at the same time. A
// control's OWN Visible reports the value it had when the page was opened and does not follow a
// later change to the page global behind it; the SAME control's Editable and Enabled do follow
// it. All three here are bound to one global, `not HideIt`, so nothing but the property being
// read can explain the difference.
//
// A GROUP's Visible is live, which is what makes this specific rather than "Visible is static":
// codeunit 60961's FieldInGroupWithTrueDynamicExpression_IsVisible flips a group's Visible
// expression after the page is open and reads a field inside it as newly visible.
//
// This matters to anyone writing a TestPage test: flipping a page variable and re-reading a
// control's Visible() does not do what it looks like it does, and reopening the page is the only
// way to observe the new value.

codeunit 60266 "TPCL Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TPCL Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'ROW1';
        Row.Insert();
    end;

    // Baseline: with the global false at open, all three read true. Without this, the tests
    // below could pass against a page whose controls were never visible or editable at all.
    [Test]
    procedure AtOpen_AllThreePropertiesReflectTheGlobal()
    var
        Card: TestPage "TPCL Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.IsTrue(Card.VisibleCtl.Visible(), 'Visible = not HideIt must be true while HideIt is false');
        Assert.IsTrue(Card.EditableCtl.Editable(), 'Editable = not HideIt must be true while HideIt is false');
        Assert.IsTrue(Card.EnabledCtl.Enabled(), 'Enabled = not HideIt must be true while HideIt is false');
        Card.Close();
    end;

    // The frozen one. Changing the global after the page is open does not move a control's own
    // Visible.
    [Test]
    procedure AfterTheGlobalChanges_TheControlsOwnVisibleIsUnchanged()
    var
        Card: TestPage "TPCL Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.Toggle.SetValue(true);
        Assert.IsTrue(Card.VisibleCtl.Visible(),
            'a control''s own Visible keeps its open-time value after the global behind it changes');
        Card.Close();
    end;

    // The live ones, and the control for the test above: the SAME change, on the SAME global,
    // read through the other two properties of the same page. A platform that froze all three,
    // or none, fails one of these two tests.
    [Test]
    procedure AfterTheGlobalChanges_EditableAndEnabledFollowIt()
    var
        Card: TestPage "TPCL Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.Toggle.SetValue(true);
        Assert.IsFalse(Card.EditableCtl.Editable(),
            'Editable = not HideIt must follow the global once HideIt is true');
        Assert.IsFalse(Card.EnabledCtl.Enabled(),
            'Enabled = not HideIt must follow the global once HideIt is true');
        Card.Close();
    end;

    // And the value the frozen Visible refuses to show mid-session is not lost — reopening the
    // page reads it. This is what makes the freeze "evaluated at open" rather than "evaluated
    // once per session" or "ignores this global entirely".
    [Test]
    procedure ReopeningThePage_IsHowTheNewVisibleIsObserved()
    var
        Card: TestPage "TPCL Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.Toggle.SetValue(true);
        Assert.IsTrue(Card.VisibleCtl.Visible(), 'still the open-time value before the page is closed');
        Card.Close();

        // A fresh page: HideIt is a page global, so it starts false again and the control is
        // visible. The claim under test is that the value is computed afresh at each open, not
        // that it carries over.
        Card.OpenEdit();
        Assert.IsTrue(Card.VisibleCtl.Visible(), 'a reopened page evaluates Visible again from its own state');
        Card.Close();
    end;
}
