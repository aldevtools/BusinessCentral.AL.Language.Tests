// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-application
// Scope: in-scope
// Fixtures used: ALT Universal (60000), Assert (60021)
//
// A test codeunit's own OnRun trigger runs ONCE, on the same codeunit instance, BEFORE its
// first [Test] method, and what it writes is committed. So a global it sets is visible to every
// test, a row it inserts is visible to every test, and that row survives a test's own rollback.
//
// Platform source: Microsoft.Dynamics.Nav.Runtime.NavTestCodeunit.DoRunAsync (BC 28.1) runs a
// DECLARED OnRun (onRunMethod.DeclaringType == GetType()) between BeforeTestRunAsync and
// AfterTestRunAsync, calls Commit(), and only then loops over the test methods on `this`.
// Microsoft's Test Runner - Mgt. (PlatformBeforeTestRun) answers true for FunctionName 'OnRun'
// whatever the test-method filter says.
//
// AL Runner issue: StefanMaron/BusinessCentral.AL.Runner#4694 (the runner never ran it).

codeunit 60002 "Test TestCU OnRun Runs First"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        OnRunValue: Integer;
        OnRunCalls: Integer;

    trigger OnRun()
    var
        Rec: Record "ALT Universal";
    begin
        // += rather than :=, so a second run on this instance reads 84, not 42.
        OnRunValue += 42;
        OnRunCalls += 1;

        Rec.DeleteAll();
        Rec.Init();
        Rec."Entry No." := 4694;
        Rec."Text Field" := 'written by OnRun';
        Rec.Insert();
    end;

    [Test]
    procedure TestCodeunitOnRun_GlobalSetInOnRun_IsVisibleToTest()
    // CLAIM: a global the test codeunit's OnRun assigns holds that value in a [Test] method.
    begin
        Assert.AreEqual(42, OnRunValue, 'the global OnRun set must be visible to the test method');
    end;

    [Test]
    procedure TestCodeunitOnRun_RunsExactlyOncePerCodeunit()
    // CLAIM: OnRun runs once for the codeunit, not once per test method.
    begin
        Assert.AreEqual(1, OnRunCalls, 'OnRun must have run exactly once on this codeunit instance');
    end;

    [Test]
    procedure TestCodeunitOnRun_RowInsertedInOnRun_IsVisibleToTest()
    // CLAIM: a row OnRun inserts is visible to a [Test] method of the same codeunit.
    var
        Rec: Record "ALT Universal";
    begin
        Assert.AreEqual(1, Rec.Count(), 'exactly the one row OnRun inserted must exist');
        Assert.IsTrue(Rec.Get(4694), 'the row OnRun inserted must be readable by its key');
        Assert.AreEqual('written by OnRun', Rec."Text Field", 'the row must carry the value OnRun wrote');
    end;

    [Test]
    procedure TestCodeunitOnRun_RowInsertedInOnRun_SurvivesTestRollback()
    // CLAIM: OnRun's write is committed, so an error rolled back inside a test undoes only the
    // test's own write, never OnRun's.
    var
        Rec: Record "ALT Universal";
    begin
        asserterror
        begin
            Rec.Init();
            Rec."Entry No." := 4695;
            Rec.Insert();
            Error('rolled back on purpose');
        end;
        Assert.ExpectedError('rolled back on purpose');

        Assert.IsFalse(Rec.Get(4695), 'the test''s own write must be rolled back');
        Assert.IsTrue(Rec.Get(4694), 'OnRun''s committed row must survive the test''s rollback');
    end;
}
