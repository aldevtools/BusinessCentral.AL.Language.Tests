// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpageactiontestpage-invoke-method
// Scope: in-scope
// Fixtures used: TPX Row (60721), TPX List (60722), TPX List Ext (60723), Assert (60021)
//
// Companion to TestPageActionInvoke_Tests: pins TestPage.<Action>.Invoke() for an action a
// PAGEEXTENSION contributes to a page, exactly the same contract as an action declared
// directly on the page.

codeunit 60724 "TPX Action Invoke Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TPX Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRows()
    var
        Row: Record "TPX Row";
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

    // Positive: the pageextension's own OnAction trigger runs at all.
    [Test]
    procedure ExtActionInvokeRunsTheOnActionTrigger()
    var
        Row: Record "TPX Row";
        TpxList: TestPage "TPX List";
    begin
        Initialize();
        SeedRows();

        TpxList.OpenEdit();
        TpxList.First();
        TpxList.StampExt.Invoke();
        TpxList.Close();

        Assert.IsTrue(Row.Get('STAMPEXT'), 'Invoke() must have run the pageextension''s OnAction trigger');
    end;

    // Positive: the pageextension's trigger runs in the PAGE's context — it reads Rec, and
    // must see the row the page is positioned on, exactly like an own-page action does.
    [Test]
    procedure ExtActionInvokeRunsAgainstThePagesCurrentRow()
    var
        Row: Record "TPX Row";
        TpxList: TestPage "TPX List";
    begin
        Initialize();
        SeedRows();

        TpxList.OpenEdit();
        TpxList.First();
        TpxList.Next();
        TpxList.StampExt.Invoke();
        TpxList.Close();

        Assert.IsTrue(Row.Get('STAMPEXT'), 'the extension action must have run');
        Assert.AreEqual('B', Row.Descr,
            'the extension action''s OnAction must have seen the row the page is positioned on');
    end;

    // Negative: an Error raised inside the pageextension's OnAction must reach the test —
    // a swallowed Error would turn a genuinely failing extension action into a passing one.
    [Test]
    procedure ExtActionInvokePropagatesAnErrorRaisedInsideOnAction()
    var
        TpxList: TestPage "TPX List";
    begin
        Initialize();
        SeedRows();

        TpxList.OpenEdit();
        TpxList.First();
        asserterror TpxList.StampExtFails.Invoke();
        Assert.ExpectedError('TPX List Ext action refused deliberately');
    end;

    // Negative: invoking the pageextension's action must not run the base page's OWN
    // action's trigger, and vice versa — the two live on different compiled objects, and a
    // dispatcher that matched loosely (e.g. always the first OnAction it finds) would run
    // the wrong one while still passing the positives above.
    [Test]
    procedure ExtActionInvokeRunsOnlyItsOwnTrigger()
    var
        Row: Record "TPX Row";
        TpxList: TestPage "TPX List";
    begin
        Initialize();
        SeedRows();

        TpxList.OpenEdit();
        TpxList.First();
        TpxList.StampExt.Invoke();
        TpxList.Close();

        Assert.IsTrue(Row.Get('STAMPEXT'), 'the invoked extension action must have run');
        Assert.IsFalse(Row.Get('STAMP'),
            'invoking the extension action must not run the page''s own StampRow action');
    end;
}
