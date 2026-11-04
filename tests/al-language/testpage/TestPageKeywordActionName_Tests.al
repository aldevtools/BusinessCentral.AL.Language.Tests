// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpageactiontestpage-invoke-method
// Scope: in-scope
// Fixtures used: Keyword Action Row (60267), Keyword Action List (60268), Assert (60021)
//
// Pins TestPage.<Action>.Invoke() for actions whose NAME is a C# reserved keyword
// (action(New), action(Delegate), action(Override)) or a name a .NET compiler treats as
// reserved (Finalize), alongside names that only look like keywords (Delete, Setup). In AL
// every one of these is an ordinary identifier; dispatch must not depend on the word.
//
// The in-file non-keyword arms (Delete, Setup) make the suite differential: if only the
// keyword arms fail, the word itself is the trigger. Each positive asserts a row only the
// named trigger writes; the negative asserts the trigger's OWN error text so a dispatcher
// that reached a different action, or none, cannot pass it.
//
// "Invoking X did not run Y's trigger" is asserted on the SUCCESSFUL invokes only, never
// after the asserterror. An error rolls the write transaction back to the last commit
// point (TestAssertErrorRollback.al, error-handling/, pins that), which undoes this test
// method's own Initialize()/SeedRow() and re-exposes the rows the previous test in this
// codeunit left behind — rows survive from one test to the next inside a codeunit under
// TestIsolation = Codeunit (TestIsolationRollbackScope.al pins that). So a post-error read
// of a stamp row reports the state before the test began, and cannot tell "the wrong
// trigger ran" from "no trigger ran": a wrong trigger's Insert would be rolled back too.
// The stamp cross-checks therefore live on the invokes that do not error, matching
// SpacedActionInvokeDoesNotRunTheUnspacedSiblingsTrigger in TestPageSpacedActionName_Tests.al.

codeunit 60269 "Keyword Action Name Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Keyword Action Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRow()
    var
        Row: Record "Keyword Action Row";
    begin
        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();
    end;

    // Control: a name that is not a C# keyword dispatches. If this fails the page itself
    // is broken; if only the keyword arms fail, the word is the trigger.
    [Test]
    procedure NonKeywordActionDeleteInvokeRunsItsTrigger()
    var
        Row: Record "Keyword Action Row";
        KeywordList: TestPage "Keyword Action List";
    begin
        Initialize();
        SeedRow();

        KeywordList.OpenEdit();
        KeywordList.First();
        KeywordList.Delete.Invoke();
        KeywordList.Close();

        Assert.IsTrue(Row.Get('DELETE'), 'action Delete''s OnAction must have run');
        Assert.AreEqual('A', Row.Descr, 'the trigger must run against the page''s current row');
        Assert.AreEqual(2, Row.Count(),
            'exactly one action trigger may have run: the seeded row plus one stamp');
    end;

    [Test]
    procedure NonKeywordActionSetupInvokeRunsItsTrigger()
    var
        Row: Record "Keyword Action Row";
        KeywordList: TestPage "Keyword Action List";
    begin
        Initialize();
        SeedRow();

        KeywordList.OpenEdit();
        KeywordList.First();
        KeywordList.Setup.Invoke();
        KeywordList.Close();

        Assert.IsTrue(Row.Get('SETUP'), 'action Setup''s OnAction must have run');
        Assert.AreEqual(2, Row.Count(),
            'exactly one action trigger may have run: the seeded row plus one stamp');
    end;

    // Positive: an action named New - a C# reserved keyword, and also the name of the
    // TestPage.New() method - dispatches to the page's own action.
    [Test]
    procedure KeywordActionNewInvokeRunsItsTrigger()
    var
        Row: Record "Keyword Action Row";
        KeywordList: TestPage "Keyword Action List";
    begin
        Initialize();
        SeedRow();

        KeywordList.OpenEdit();
        KeywordList.First();
        KeywordList.New.Invoke();
        KeywordList.Close();

        Assert.IsTrue(Row.Get('NEW'), 'action New''s OnAction must have run');
        Assert.AreEqual('A', Row.Descr, 'the trigger must run against the page''s current row');
        Assert.AreEqual(2, Row.Count(),
            'exactly one action trigger may have run: the seeded row plus one stamp');
        Assert.IsFalse(Row.Get('DELETE'),
            'invoking the keyword-named New must not have run a non-keyword action''s trigger');
    end;

    [Test]
    procedure KeywordActionDelegateInvokeRunsItsTrigger()
    var
        Row: Record "Keyword Action Row";
        KeywordList: TestPage "Keyword Action List";
    begin
        Initialize();
        SeedRow();

        KeywordList.OpenEdit();
        KeywordList.First();
        KeywordList.Delegate.Invoke();
        KeywordList.Close();

        Assert.IsTrue(Row.Get('DELEGATE'), 'action Delegate''s OnAction must have run');
        Assert.AreEqual(2, Row.Count(),
            'exactly one action trigger may have run: the seeded row plus one stamp');
    end;

    [Test]
    procedure ReservedMemberNameActionFinalizeInvokeRunsItsTrigger()
    var
        Row: Record "Keyword Action Row";
        KeywordList: TestPage "Keyword Action List";
    begin
        Initialize();
        SeedRow();

        KeywordList.OpenEdit();
        KeywordList.First();
        KeywordList.Finalize.Invoke();
        KeywordList.Close();

        Assert.IsTrue(Row.Get('FINALIZE'), 'action Finalize''s OnAction must have run');
        Assert.AreEqual(2, Row.Count(),
            'exactly one action trigger may have run: the seeded row plus one stamp');
    end;

    // Positive: the promoted actionref to a keyword-named target dispatches the target.
    [Test]
    procedure PromotedActionRefToKeywordActionInvokeRunsTheTarget()
    var
        Row: Record "Keyword Action Row";
        KeywordList: TestPage "Keyword Action List";
    begin
        Initialize();
        SeedRow();

        KeywordList.OpenEdit();
        KeywordList.First();
        KeywordList.New_Promoted.Invoke();
        KeywordList.Close();

        Assert.IsTrue(Row.Get('NEW'), 'actionref New_Promoted must run action New''s OnAction');
        Assert.AreEqual(2, Row.Count(),
            'exactly one action trigger may have run: the seeded row plus one stamp');
    end;

    // Negative: a keyword-named action whose trigger errors surfaces that trigger's own
    // error - proof the right trigger ran, not a different one and not none. The message is
    // raised by action Override's OnAction and by nothing else on this page, so reaching any
    // other action would either raise a different text or none at all, and the asserterror
    // would fail. No database assertion follows: see the rollback note in the file header.
    [Test]
    procedure KeywordActionOverrideInvokeSurfacesItsOwnError()
    var
        KeywordList: TestPage "Keyword Action List";
    begin
        Initialize();
        SeedRow();

        KeywordList.OpenEdit();
        KeywordList.First();
        asserterror KeywordList.Override.Invoke();
        Assert.ExpectedError('Keyword Action List action refused deliberately');
    end;
}
