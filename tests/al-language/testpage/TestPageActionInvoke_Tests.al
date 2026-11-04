// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpageactiontestpage-invoke-method
// Scope: in-scope
// Fixtures used: Test Page Action Row (60682), Test Page Action List (60683), Assert (60021)
//
// Pins TestPage.<Action>.Invoke() to the page's OnAction trigger.
//
// A runner whose Invoke() is a literal no-op silently does nothing on every action a test
// invokes. That is the worst shape a gap can take: nothing throws, and the test fails one
// step later complaining about the effect ("the Clear Filter action did not remove the
// stored view") rather than about the action never having run.
//
// The negatives carry the weight. A swallowed Error turns a genuinely failing action into
// a green test, so one test asserts the error propagates. And an action lookup that
// matched loosely — by name prefix, or by taking the page's first OnAction method — would
// pass the positives while running the wrong trigger, so another invokes one action and
// asserts the other's did not run.

codeunit 60684 "Test Page Action Invoke Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Test Page Action Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRows()
    var
        Row: Record "Test Page Action Row";
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

    // Positive: the trigger runs at all.
    [Test]
    procedure ActionInvokeRunsTheOnActionTrigger()
    var
        Row: Record "Test Page Action Row";
        TpaList: TestPage "Test Page Action List";
    begin
        Initialize();
        SeedRows();

        TpaList.OpenEdit();
        TpaList.First();
        TpaList.StampRow.Invoke();
        TpaList.Close();

        Assert.IsTrue(Row.Get('STAMP'), 'Invoke() must have run the action''s OnAction trigger');
    end;

    // Positive: the trigger runs in the PAGE's context — it reads Rec, and must see the row
    // the page is positioned on. A trigger invoked against a detached record would stamp a
    // blank No. here, which is exactly the failure a "does not throw" test would miss.
    [Test]
    procedure ActionInvokeRunsAgainstThePagesCurrentRow()
    var
        Row: Record "Test Page Action Row";
        TpaList: TestPage "Test Page Action List";
    begin
        Initialize();
        SeedRows();

        TpaList.OpenEdit();
        TpaList.First();
        TpaList.Next();
        TpaList.StampRow.Invoke();
        TpaList.Close();

        Assert.IsTrue(Row.Get('STAMP'), 'the action must have run');
        Assert.AreEqual('B', Row.Descr,
            'the action''s OnAction must have seen the row the page is positioned on');
    end;

    // Negative: an Error raised inside OnAction must reach the test. Swallowing it would
    // make every failing action look like a passing one.
    [Test]
    procedure ActionInvokePropagatesAnErrorRaisedInsideOnAction()
    var
        TpaList: TestPage "Test Page Action List";
    begin
        Initialize();
        SeedRows();

        TpaList.OpenEdit();
        TpaList.First();
        asserterror TpaList.AlwaysFails.Invoke();
        Assert.ExpectedError('Test Page Action action refused deliberately');
    end;

    // Negative: invoking one action must not run another's trigger.
    [Test]
    procedure ActionInvokeRunsOnlyTheInvokedActionsTrigger()
    var
        Row: Record "Test Page Action Row";
        TpaList: TestPage "Test Page Action List";
    begin
        Initialize();
        SeedRows();

        TpaList.OpenEdit();
        TpaList.First();
        TpaList.StampRow.Invoke();
        TpaList.Close();

        Assert.IsTrue(Row.Get('STAMP'), 'the invoked action must have run');
        Assert.IsFalse(Row.Get('OTHER'),
            'invoking StampRow must not have run StampOther''s trigger');
    end;
}
