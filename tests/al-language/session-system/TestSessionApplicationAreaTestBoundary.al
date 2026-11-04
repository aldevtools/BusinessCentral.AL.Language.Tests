// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-applicationarea-method
// Scope: in-scope
// Fixtures used: Assert (60021)
//
// CLAIM: application areas a test sets do not reach the next test. Two mechanisms produce that,
// and these codeunits pin each one where it applies:
//
// 1. The platform. NavTestCodeunit.DoRunAsync (identical on BC 27.0 and 28.4) reads
//    activeSession.ApplicationAreas once, before OnRun, and assigns it back after every test
//    method and when the codeunit ends. 67550 and 67551 pin what holds with or without
//    Microsoft's Test Runner in the loop.
// 2. Microsoft's Test Runner app. Codeunit 130453 "ALTestRunner Reset Environment" calls
//    ApplicationArea('') on "Test Runner - Mgt".OnBeforeTestMethodRun, before OnRun and before
//    every test method. So under the AL test runner, which is how BC runs tests, every test starts
//    with every area enabled, and what OnRun set is already gone in the first test. 67552 pins
//    that. It deliberately omits TestPermissions = Disabled, so the corpus harness routes it
//    through the AL test runner on every leg.
//
// What the FIRST test sees after OnRun set an area is exactly where the two differ. Measured on
// corpus PR #467's run 36282176991: the probe was visible on the 28.x legs, where 67551 ran
// without the AL test runner, and gone on the 27.x legs, where it ran with it. So 67551 asserts
// only what both agree on, and 67552 pins the Test Runner answer.
//
// 67550 and 67551 compare against values read inside the codeunit, never a literal baseline,
// because the session a harness opens starts with different areas on different builds.
//
// Written by agent stma-auto2-12, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issues StefanMaron/BusinessCentral.AL.Runner#3575 and #4813.

codeunit 67550 "Test AppArea Test Boundary"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        AreasAtFirstTest: Text;
        FirstTestRan: Boolean;

    [Test]
    procedure A_AreasSetInATest_AreVisibleForTheRestOfThatTest()
    begin
        AreasAtFirstTest := ApplicationArea();
        FirstTestRan := true;

        ApplicationArea('#Basic,#ALRBoundaryProbe');

        Assert.AreEqual('#Basic,#ALRBoundaryProbe', ApplicationArea(),
          'the areas a test sets must read back for the rest of that test');
    end;

    [Test]
    procedure B_NextTest_SeesTheAreasTheCodeunitStartedWith()
    begin
        Assert.IsTrue(FirstTestRan, 'the previous test must have run first, on this codeunit instance');
        Assert.AreEqual(AreasAtFirstTest, ApplicationArea(),
          'the areas the previous test set must be put back before the next test starts');
        Assert.AreEqual(0, StrPos(ApplicationArea(), '#ALRBoundaryProbe'),
          'the previous test''s area must not be visible to the next test');
    end;
}

codeunit 67551 "Test AppArea OnRun Boundary"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        AreasBeforeOnRun: Text;
        OnRunRan: Boolean;

    trigger OnRun()
    begin
        AreasBeforeOnRun := ApplicationArea();
        OnRunRan := true;
        ApplicationArea('#Basic,#ALROnRunProbe');
    end;

    [Test]
    procedure A_FirstTest_RunsAfterOnRun()
    begin
        // Whether this test still sees OnRun's area depends on whether the AL test runner is in
        // the loop (see the header), so it is not asserted here; 67552 pins that case.
        Assert.IsTrue(OnRunRan, 'the codeunit''s OnRun trigger must have run before the first test');
    end;

    [Test]
    procedure B_SecondTest_SeesTheAreasFromBeforeOnRun()
    begin
        Assert.AreEqual(AreasBeforeOnRun, ApplicationArea(),
          'after the first test method the areas return to what they were before OnRun');
        Assert.AreEqual(0, StrPos(ApplicationArea(), '#ALROnRunProbe'),
          'the area OnRun set must not be visible to the second test');
    end;
}

codeunit 67552 "Test AppArea Test Runner Reset"
{
    // No TestPermissions = Disabled on purpose: this routes the codeunit through Microsoft's AL
    // test runner on every harness leg, which is the path this codeunit pins.
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        OnRunRan: Boolean;

    trigger OnRun()
    begin
        OnRunRan := true;
        ApplicationArea('#Basic,#ALRRunnerProbe');
    end;

    [Test]
    procedure A_FirstTest_StartsWithEveryAreaEnabled_EvenAfterOnRunSetOne()
    begin
        Assert.IsTrue(OnRunRan, 'the codeunit''s OnRun trigger must have run before the first test');
        Assert.AreEqual('', ApplicationArea(),
          'the AL test runner enables every area before each test method, over what OnRun set');
    end;

    [Test]
    procedure B_AreasSetInATest_AreVisibleForTheRestOfThatTest()
    begin
        ApplicationArea('#Basic,#ALRRunnerProbe2');
        Assert.AreEqual('#Basic,#ALRRunnerProbe2', ApplicationArea(),
          'the areas a test sets must read back for the rest of that test');
    end;

    [Test]
    procedure C_NextTest_StartsWithEveryAreaEnabled()
    begin
        Assert.AreEqual('', ApplicationArea(),
          'the next test starts with every area enabled again');
    end;
}
