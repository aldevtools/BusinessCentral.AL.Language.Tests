// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-visible-method
// Scope: in-scope
// Fixtures used: TPCE Row (60257), TPCE Card (60258), TPCE State (60260), Assert (60021)
//
// Visible, Editable and Enabled on a page control take an AL client expression. These tests read
// each shape of that grammar in both input states, opening a fresh page for each state with the
// page globals seeded before the page exists.
//
// Every expression here is over page globals. Two things measured on all 8 BC versions are
// deliberately left to their own tests: an expression referencing a source-table field evaluates
// as if the field held its type default, and a control's Visible is not re-evaluated after the
// page is open while its Editable and Enabled are.

codeunit 60259 "TPCE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        State: Codeunit "TPCE State";

    // Seeds the two page globals through the SingleInstance codeunit the page reads in
    // OnOpenPage, then gives the card a row to open on. The row's contents do not matter: every
    // expression in this suite is over page globals.
    local procedure Initialize(Hide: Boolean; Second: Boolean)
    var
        Row: Record "TPCE Row";
    begin
        State.SetHide(Hide);
        State.SetSecond(Second);

        Row.DeleteAll();
        Row.Init();
        Row.PK := 'ROW1';
        Row.Insert();
    end;

    // ---- a bare page global: the baseline -----------------------------------------------------

    [Test]
    procedure PlainGlobal_IsHiddenWhenTheGlobalIsFalse()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(false, false);
        Card.OpenEdit();
        Assert.IsFalse(Card.PlainGlobal.Visible(), 'Visible = HideIt must be false while HideIt is false');
        Card.Close();
    end;

    [Test]
    procedure PlainGlobal_IsVisibleWhenTheGlobalIsTrue()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(true, false);
        Card.OpenEdit();
        Assert.IsTrue(Card.PlainGlobal.Visible(), 'Visible = HideIt must be true while HideIt is true');
        Card.Close();
    end;

    // ---- not ----------------------------------------------------------------------------------

    [Test]
    procedure NotGlobal_IsVisibleWhenTheGlobalIsFalse()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(false, false);
        Card.OpenEdit();
        Assert.IsTrue(Card.NotGlobal.Visible(), 'Visible = not HideIt must be true while HideIt is false');
        Card.Close();
    end;

    [Test]
    procedure NotGlobal_IsHiddenWhenTheGlobalIsTrue()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(true, false);
        Card.OpenEdit();
        Assert.IsFalse(Card.NotGlobal.Visible(), 'Visible = not HideIt must be false while HideIt is true');
        Card.Close();
    end;

    // ---- and: three of the four input combinations are false ----------------------------------

    [Test]
    procedure AndGlobals_AreHiddenWhenOnlyOneOperandIsTrue()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(true, false);
        Card.OpenEdit();
        Assert.IsFalse(Card.AndGlobals.Visible(), 'HideIt and SecondFlag must be false while only HideIt is true');
        Card.Close();
    end;

    [Test]
    procedure AndGlobals_AreVisibleWhenBothOperandsAreTrue()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(true, true);
        Card.OpenEdit();
        Assert.IsTrue(Card.AndGlobals.Visible(), 'HideIt and SecondFlag must be true while both are true');
        Card.Close();
    end;

    // ---- or: read in the SAME two states as and, and disagreeing in one of them ---------------

    [Test]
    procedure OrGlobals_AreVisibleWhenOnlyOneOperandIsTrue()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(true, false);
        Card.OpenEdit();
        Assert.IsTrue(Card.OrGlobals.Visible(), 'HideIt or SecondFlag must be true while HideIt is true');
        Card.Close();
    end;

    [Test]
    procedure OrGlobals_AreHiddenWhenBothOperandsAreFalse()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(false, false);
        Card.OpenEdit();
        Assert.IsFalse(Card.OrGlobals.Visible(), 'HideIt or SecondFlag must be false while both are false');
        Card.Close();
    end;

    // ---- not over a parenthesized group -------------------------------------------------------

    [Test]
    procedure NotParenthesized_IsVisibleWhenBothOperandsAreFalse()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(false, false);
        Card.OpenEdit();
        Assert.IsTrue(Card.NotParenthesized.Visible(), 'not (HideIt or SecondFlag) must be true while both are false');
        Card.Close();
    end;

    [Test]
    procedure NotParenthesized_IsHiddenWhenOneOperandIsTrue()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(false, true);
        Card.OpenEdit();
        Assert.IsFalse(Card.NotParenthesized.Visible(), 'not (HideIt or SecondFlag) must be false once SecondFlag is true');
        Card.Close();
    end;

    // ---- the same grammar on Editable and Enabled ---------------------------------------------

    [Test]
    procedure NotGlobal_GovernsEditable()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(false, false);
        Card.OpenEdit();
        Assert.IsTrue(Card.NotEditable.Editable(), 'Editable = not HideIt must be true while HideIt is false');
        Card.Close();

        Initialize(true, false);
        Card.OpenEdit();
        Assert.IsFalse(Card.NotEditable.Editable(), 'Editable = not HideIt must be false while HideIt is true');
        Card.Close();
    end;

    [Test]
    procedure NotGlobal_GovernsEnabled()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(false, false);
        Card.OpenEdit();
        Assert.IsTrue(Card.NotEnabled.Enabled(), 'Enabled = not HideIt must be true while HideIt is false');
        Card.Close();

        Initialize(true, false);
        Card.OpenEdit();
        Assert.IsFalse(Card.NotEnabled.Enabled(), 'Enabled = not HideIt must be false while HideIt is true');
        Card.Close();
    end;
}
