// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpageactiontestpage-invoke-method
// Scope: in-scope
// Fixtures used: Spaced Action Row (60242), Spaced Action List (60243), Spaced Action List Ext (60244), Spaced Action Base Ext (60245), Assert (60021)
//
// Pins TestPage.<Action>.Invoke() for actions whose NAME contains spaces
// (action("Spaced Stamp")), the exact same contract TestPageActionInvoke_Tests
// pins for unspaced names. A spaced name is only a quoting difference in AL —
// dispatch must be identical.
//
// The in-file unspaced control makes the suite differential: if the spaced arms
// fail while the control passes, the name is the trigger. The collision test
// carries extra weight — SpacedStamp and "Spaced Stamp" coexist on the page, so
// a dispatcher that normalized names (stripped spaces) would run the wrong
// trigger while still passing the positives.

codeunit 60246 "Spaced Action Name Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Spaced Action Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRows()
    var
        Row: Record "Spaced Action Row";
    begin
        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();

        Row.Init();
        Row."No." := 'B';
        Row.Descr := 'Bravo';
        Row.Insert();
    end;

    // Control: the unspaced sibling action on the same page dispatches. If this
    // fails the page itself is broken; if only the spaced arms fail, the space
    // in the name is the trigger.
    [Test]
    procedure UnspacedControlActionInvokeRunsItsTrigger()
    var
        Row: Record "Spaced Action Row";
        SpacedList: TestPage "Spaced Action List";
    begin
        Initialize();
        SeedRows();

        SpacedList.OpenEdit();
        SpacedList.First();
        SpacedList.SpacedStamp.Invoke();
        SpacedList.Close();

        Assert.IsTrue(Row.Get('UNSPACED'), 'the unspaced control action''s OnAction must have run');
    end;

    // Positive: a spaced-name action dispatches, and its trigger runs in the
    // page's context — it must see the row the page is positioned on.
    [Test]
    procedure SpacedActionInvokeRunsAgainstThePagesCurrentRow()
    var
        Row: Record "Spaced Action Row";
        SpacedList: TestPage "Spaced Action List";
    begin
        Initialize();
        SeedRows();

        SpacedList.OpenEdit();
        SpacedList.First();
        SpacedList.Next();
        SpacedList."Spaced Stamp".Invoke();
        SpacedList.Close();

        Assert.IsTrue(Row.Get('SPACED'), 'Invoke() must have run the spaced-name action''s OnAction trigger');
        Assert.AreEqual('B', Row.Descr,
            'the spaced-name action''s OnAction must have seen the row the page is positioned on');
    end;

    // Negative: an Error raised inside a spaced-name action's OnAction must reach
    // the test. A dispatcher that silently no-ops on spaced names would swallow it.
    [Test]
    procedure SpacedActionInvokePropagatesAnErrorRaisedInsideOnAction()
    var
        SpacedList: TestPage "Spaced Action List";
    begin
        Initialize();
        SeedRows();

        SpacedList.OpenEdit();
        SpacedList.First();
        asserterror SpacedList."Always Fails Spaced".Invoke();
        Assert.ExpectedError('Spaced Action List action refused deliberately');
    end;

    // Negative: SpacedStamp and "Spaced Stamp" are distinct actions that differ
    // only by the space. Invoking the spaced one must not run the unspaced one's
    // trigger — a name-normalizing dispatcher would collide them.
    [Test]
    procedure SpacedActionInvokeDoesNotRunTheUnspacedSiblingsTrigger()
    var
        Row: Record "Spaced Action Row";
        SpacedList: TestPage "Spaced Action List";
    begin
        Initialize();
        SeedRows();

        SpacedList.OpenEdit();
        SpacedList.First();
        SpacedList."Spaced Stamp".Invoke();
        SpacedList.Close();

        Assert.IsTrue(Row.Get('SPACED'), 'the invoked spaced-name action must have run');
        Assert.IsFalse(Row.Get('UNSPACED'),
            'invoking "Spaced Stamp" must not have run SpacedStamp''s trigger');
    end;

    // Positive: a spaced-name action a PAGEEXTENSION contributes to the page
    // dispatches exactly like one declared directly on the page.
    [Test]
    procedure SpacedExtActionInvokeRunsItsTrigger()
    var
        Row: Record "Spaced Action Row";
        SpacedList: TestPage "Spaced Action List";
    begin
        Initialize();
        SeedRows();

        SpacedList.OpenEdit();
        SpacedList.First();
        SpacedList."Ext Spaced Stamp".Invoke();
        SpacedList.Close();

        Assert.IsTrue(Row.Get('EXTSPACED'), 'the pageextension''s spaced-name action must have run');
        Assert.AreEqual('A', Row.Descr,
            'the extension action''s OnAction must have seen the page''s current row');
    end;

    // Positive: a spaced-name action a pageextension contributes to a precompiled
    // Base App page ("Item Attribute Values") dispatches too — the host page being
    // shipped compiled must make no difference.
    [Test]
    procedure SpacedExtActionOnBaseAppPageInvokeRunsItsTrigger()
    var
        Row: Record "Spaced Action Row";
        ValuesList: TestPage "Item Attribute Values";
    begin
        Initialize();

        ValuesList.OpenEdit();
        ValuesList."Base Spaced Stamp".Invoke();
        ValuesList.Close();

        Assert.IsTrue(Row.Get('BASESPACED'),
            'the pageextension''s spaced-name action on the Base App page must have run');
        Assert.AreEqual('base app page', Row.Descr, 'the trigger''s own write must be intact');
    end;
}
