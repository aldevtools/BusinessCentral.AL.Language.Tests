// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-visible-method
// Scope: in-scope
// Fixtures used: TP Field Visible Row (60964), TP Field Visible Card (60959), Assert (60021)
//
// TestPage.<field>.Visible() must combine the control's OWN Visible with the Visible of EVERY
// group that wraps it, all the way up to the content area — not just its own declared value and
// not just its immediate parent's. This only applies to controls that are actually PRESENT on the
// runtime page: a control whose Visible property is a compile-time LITERAL `false` (on the
// control itself, or on any group that encloses it) is dead-code-eliminated by the AL compiler.
// It never exists on the runtime page object at all, so any TestPage access to it — not just
// .Visible(), the control reference itself — raises "The field with ID = ... is not found on the
// page." A `Visible = <variable-or-expression>` property is never eliminated this way, even if it
// currently evaluates to false: the control stays on the page and its Visible() is evaluated live,
// combining its own value with every ancestor's, on every call.
//
// FieldInNestedGroup is the case that tells apart "walks one level up" from "walks the whole
// chain": it sits inside InnerGroup, which declares no Visible of its own, wrapped by OuterGroup,
// whose Visible is the variable expression ShowOuter (never eliminated). A fix that only consulted
// the immediate parent (InnerGroup, always Visible) would pass every other test here and still
// report FieldInNestedGroup visible while OuterGroup is hidden.

// Writer BP (corpus issue 664, microsoft/AL issues 5356 and 4242): a field whose OWN Visible is a page variable that changes after
// OnOpenPage, by an action without CurrPage.Update, by an action with CurrPage.Update(false), and in OnAfterGetCurrRecord.
page 82558 "LT BP Field Visible Card"
{
    PageType = Card;
    SourceTable = "TP Field Visible Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(PK; Rec.PK) { ApplicationArea = All; }
            field(OwnVisible; Rec.Value)
            {
                ApplicationArea = All;
                Visible = ShowOwn;
            }
            field(SetInOpen; Rec.Value)
            {
                ApplicationArea = All;
                Visible = ShowSetInOpen;
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ShowNoUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    ShowOwn := true;
                    ShowSetInOpen := false;
                end;
            }
            action(HideWithUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    ShowOwn := false;
                    ShowSetInOpen := true;
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ShowSetInOpen := true;
    end;

    var
        ShowOwn: Boolean;
        ShowSetInOpen: Boolean;
}
codeunit 60961 "Test Page Field Visible Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TP Field Visible Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'ROW1';
        Row.Value := 'Some Value';
        Row.Insert();
    end;

    // Positive/baseline: a control that is not inside any group at all is unaffected by this
    // whole mechanism, and must stay visible.
    [Test]
    procedure FieldNotInAnyGroup_IsVisible()
    var
        Card: TestPage "TP Field Visible Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.IsTrue(Card.RecValue.Visible(), 'a field outside any group must be visible by default');
        Card.Close();
    end;

    // Negative, and NOT a "combine with the group" case: the enclosing group's Visible is the
    // compile-time LITERAL `false`, so the whole group subtree — including this field, which
    // declares no Visible of its own — is dead-code-eliminated by the AL compiler. The control
    // never exists on the runtime page, so even referencing it on the TestPage (before any call to
    // .Visible()) raises "field ... is not found on the page", not a false Visible() result.
    [Test]
    procedure FieldInGroupWithLiteralFalseVisible_IsNotOnThePage()
    var
        Card: TestPage "TP Field Visible Card";
        Dummy: Boolean;
    begin
        Initialize();

        Card.OpenEdit();
        asserterror Dummy := Card.FieldInStaticHiddenGroup.Visible();
        Assert.ExpectedError('is not found on the page');
        Card.Close();
    end;

    // Negative: the enclosing group's Visible is a page-variable expression currently false.
    [Test]
    procedure FieldInGroupWithFalseDynamicExpression_IsHidden()
    var
        Card: TestPage "TP Field Visible Card";
    begin
        Initialize();

        Card.OpenEdit();
        // ShowDynamic defaults to false, so DynamicGroup starts hidden.
        Assert.IsFalse(Card.FieldInDynamicGroup.Visible(),
            'a field inside a group whose Visible expression is currently false must be hidden');
        Card.Close();
    end;

    // Positive: flipping the SAME page-variable expression to true must flip the field visible
    // too — proves the group's Visible is evaluated live, not cached from OnOpenPage.
    [Test]
    procedure FieldInGroupWithTrueDynamicExpression_IsVisible()
    var
        Card: TestPage "TP Field Visible Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.ToggleDynamic.SetValue(true);
        Assert.IsTrue(Card.FieldInDynamicGroup.Visible(),
            'a field inside a group whose Visible expression is now true must be visible');
        Card.Close();
    end;

    // Negative, same compile-time-elimination story, this time on the control's OWN Visible
    // rather than a group's: OwnHiddenFieldInVisibleGroup declares a literal `Visible = false`
    // directly, so it is eliminated regardless of the enclosing (visible, variable-driven) group.
    // The control never exists on the runtime page.
    [Test]
    procedure FieldWithOwnLiteralFalseVisible_IsNotOnThePageEvenInsideAVisibleGroup()
    var
        Card: TestPage "TP Field Visible Card";
        Dummy: Boolean;
    begin
        Initialize();

        Card.OpenEdit();
        Card.ToggleDynamic.SetValue(true);
        Assert.IsTrue(Card.FieldInDynamicGroup.Visible(), 'sanity: the group must actually be visible now');
        asserterror Dummy := Card.OwnHiddenFieldInVisibleGroup.Visible();
        Assert.ExpectedError('is not found on the page');
        Card.Close();
    end;

    // Negative, and the load-bearing case: FieldInNestedGroup sits inside InnerGroup (declares
    // no Visible), which sits inside OuterGroup (Visible = ShowOuter, false by default). Only
    // walking the FULL ancestor chain — not just the immediate parent InnerGroup — reports this
    // field hidden.
    [Test]
    procedure FieldInNestedGroupIsHiddenWhenTheOuterGroupIsHidden()
    var
        Card: TestPage "TP Field Visible Card";
    begin
        Initialize();

        Card.OpenEdit();
        // ShowOuter defaults to false, so OuterGroup starts hidden; InnerGroup itself declares
        // no Visible at all.
        Assert.IsFalse(Card.FieldInNestedGroup.Visible(),
            'a field two groups deep must be hidden when the OUTER group is hidden, even though the immediate parent group declares no Visible of its own');
        Card.Close();
    end;

    // Positive counterpart: once the outer group becomes visible, the nested field follows.
    [Test]
    procedure FieldInNestedGroupIsVisibleWhenTheOuterGroupIsVisible()
    var
        Card: TestPage "TP Field Visible Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.ToggleOuter.SetValue(true);
        Assert.IsTrue(Card.FieldInNestedGroup.Visible(),
            'a field two groups deep must become visible once the outer group does, even though the immediate parent group declares no Visible of its own');
        Card.Close();
    end;

    // Writer BP (corpus issue 664): what TestPage.<field>.Visible() reads for a field whose own Visible expression changes after OnOpenPage.
    [Test]
    procedure FieldOwnVisibleExpression_ChangedAfterOpenPage_BP()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT BP Field Visible Card";
    begin
        Initialize();
        Card.OpenEdit();
        Observer.Observe('open own', Format(Card.OwnVisible.Visible()));
        Observer.Observe('open set in OnOpenPage', Format(Card.SetInOpen.Visible()));
        Card.ShowNoUpdate.Invoke();
        Observer.Observe('action without update own', Format(Card.OwnVisible.Visible()));
        Observer.Observe('action without update set in OnOpenPage', Format(Card.SetInOpen.Visible()));
        Card.HideWithUpdate.Invoke();
        Observer.Observe('action with update own', Format(Card.OwnVisible.Visible()));
        Observer.Observe('action with update set in OnOpenPage', Format(Card.SetInOpen.Visible()));
        Card.Close();
        Observer.Expect('open own', 'No');
        Observer.Expect('open set in OnOpenPage', 'Yes');
        Observer.Expect('action without update own', 'No');
        Observer.Expect('action without update set in OnOpenPage', 'Yes');
        Observer.Expect('action with update own', 'No');
        Observer.Expect('action with update set in OnOpenPage', 'Yes');
        Observer.Verify();
    end;
}
