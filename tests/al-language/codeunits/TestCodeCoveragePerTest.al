// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-codecoveragelog-method
// Scope: in-scope
// Fixtures used: none (tables 2000000288 "Code Coverage Test Lookup" and 2000000289
//                "Code Coverage Tests Run" are platform virtual tables)
// Note: the per-test companion to codeunits 60339 "Test Code Coverage Start Stop" and 60341
//       "Test Code Coverage Table". While recording, the platform notes every [Test] method
//       that STARTS: one "Code Coverage Tests Run" row per test, and one "Code Coverage Test
//       Lookup" row per method that ran inside that test.
//
//       A test that is already running when recording starts is not noted, so each arm starts
//       recording and then calls RecordedTest_RunsTripled, a [Test] procedure of this codeunit,
//       directly. That procedure also runs as a test on its own, where recording is off.
//
//       "Test ID" is a hash the platform computes per run, so it is only compared between the
//       two tables, never against a literal. "Method ID" is compiler-assigned, so it is only
//       compared between rows.
//
//       Written for AlRunner#4666, where both tables read empty after recording across a test
//       start. The trigger arm was added for AlRunner#4682: a trigger that runs inside a recorded
//       test is a method run inside it too, so it gets its own Test Lookup row.
// BC versions: 24+

codeunit 60925 "Test Code Coverage Per Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        CodeCoverage: Record "Code Coverage";
        TestLookup: Record "Code Coverage Test Lookup";
        TestsRun: Record "Code Coverage Tests Run";
    begin
        CodeCoverageLog(false, false);
        CodeCoverageLog(false, true);
        CodeCoverage.DeleteAll();
        TestLookup.DeleteAll();
        TestsRun.DeleteAll();
    end;

    local procedure Tripled(Value: Integer): Integer
    begin
        exit(Value * 3);
    end;

    [Test]
    procedure RecordedTest_RunsTripled()
    begin
        Assert.AreEqual(9, Tripled(3), 'Tripled(3) must answer 9.');
    end;

    local procedure RecordOneTest()
    begin
        Initialize();
        CodeCoverageLog(true, false);
        RecordedTest_RunsTripled();
        CodeCoverageLog(false, false);
    end;

    [Test]
    procedure RecordedTest_RunsTrigger()
    begin
        Codeunit.Run(Codeunit::"Test Code Coverage Trigger");
    end;

    [Test]
    procedure TestsRun_TestStartedWhileRecording_HasOneRowNamingIt()
    var
        TestsRun: Record "Code Coverage Tests Run";
    begin
        // [GIVEN] a [Test] procedure started and finished while recording
        RecordOneTest();

        // [THEN] Tests Run holds exactly one row for this codeunit, naming that test
        TestsRun.SetRange("Object ID", Codeunit::"Test Code Coverage Per Test");
        Assert.AreEqual(1, TestsRun.Count(), 'exactly one test of this codeunit started while recording.');
        TestsRun.FindFirst();
        Assert.AreEqual('RecordedTest_RunsTripled', TestsRun."Method Name", 'the row must name the test that started.');
    end;

    [Test]
    procedure TestsRun_TestStartedWhileRecording_NamesTheOwningApp()
    var
        TestsRun: Record "Code Coverage Tests Run";
        CurrentModule: ModuleInfo;
    begin
        // [GIVEN] a [Test] procedure started and finished while recording
        RecordOneTest();
        TestsRun.SetRange("Object ID", Codeunit::"Test Code Coverage Per Test");
        Assert.IsTrue(TestsRun.FindFirst(), 'the recorded test must have a Tests Run row.');

        // [THEN] the row names the app the test belongs to
        NavApp.GetCurrentModuleInfo(CurrentModule);
        Assert.AreEqual(CurrentModule.Id, TestsRun."Owning Application", 'the row must name the app the test belongs to.');
    end;

    [Test]
    procedure TestLookup_TestStartedWhileRecording_HasTheMethodItRan()
    var
        TestsRun: Record "Code Coverage Tests Run";
        TestLookup: Record "Code Coverage Test Lookup";
    begin
        // [GIVEN] a [Test] procedure that calls Tripled started and finished while recording
        RecordOneTest();
        TestsRun.SetRange("Object ID", Codeunit::"Test Code Coverage Per Test");
        Assert.IsTrue(TestsRun.FindFirst(), 'the recorded test must have a Tests Run row.');

        // [THEN] Test Lookup links exactly one method of this codeunit to that test: Tripled.
        // The test procedure itself is not a method run INSIDE the test, and the arm running
        // this code started before recording did.
        TestLookup.SetRange("Object Type", TestLookup."Object Type"::Codeunit);
        TestLookup.SetRange("Object ID", Codeunit::"Test Code Coverage Per Test");
        TestLookup.SetRange("Test ID", TestsRun."Test ID");
        Assert.AreEqual(1, TestLookup.Count(), 'exactly one method of this codeunit ran inside the recorded test.');

        // [THEN] that method is not the test procedure: the two carry different method ids
        TestLookup.FindFirst();
        Assert.AreNotEqual(TestsRun."Method ID", TestLookup."Method ID",
            'the method that ran inside the test must not carry the test procedure''s own method id.');
    end;

    [Test]
    procedure PerTestTables_NoTestStartedWhileRecording_AreEmptyForThisCodeunit()
    var
        TestsRun: Record "Code Coverage Tests Run";
        TestLookup: Record "Code Coverage Test Lookup";
    begin
        // [GIVEN] recording ran over a plain procedure call, with no test starting
        Initialize();
        CodeCoverageLog(true, false);
        Assert.AreEqual(12, Tripled(4), 'Tripled(4) must answer 12.');
        CodeCoverageLog(false, false);

        // [THEN] neither per-test table holds anything for this codeunit
        TestsRun.SetRange("Object ID", Codeunit::"Test Code Coverage Per Test");
        Assert.IsTrue(TestsRun.IsEmpty(), 'no test started while recording, so Tests Run must hold no row for this codeunit.');
        TestLookup.SetRange("Object Type", TestLookup."Object Type"::Codeunit);
        TestLookup.SetRange("Object ID", Codeunit::"Test Code Coverage Per Test");
        Assert.IsTrue(TestLookup.IsEmpty(), 'no test started while recording, so Test Lookup must hold no row for this codeunit.');
    end;

    [Test]
    procedure TestLookup_TriggerRunInsideRecordedTest_HasARow()
    var
        TestsRun: Record "Code Coverage Tests Run";
        TestLookup: Record "Code Coverage Test Lookup";
    begin
        // [GIVEN] a [Test] procedure that runs a codeunit's OnRun trigger started and finished while recording
        Initialize();
        CodeCoverageLog(true, false);
        RecordedTest_RunsTrigger();
        CodeCoverageLog(false, false);
        TestsRun.SetRange("Object ID", Codeunit::"Test Code Coverage Per Test");
        TestsRun.SetRange("Method Name", 'RecordedTest_RunsTrigger');
        Assert.IsTrue(TestsRun.FindFirst(), 'the recorded test must have a Tests Run row.');

        // [THEN] Test Lookup links the trigger's codeunit to that test, once
        TestLookup.SetRange("Object Type", TestLookup."Object Type"::Codeunit);
        TestLookup.SetRange("Object ID", Codeunit::"Test Code Coverage Trigger");
        TestLookup.SetRange("Test ID", TestsRun."Test ID");
        Assert.AreEqual(1, TestLookup.Count(), 'the OnRun trigger that ran inside the recorded test must have exactly one Test Lookup row.');
    end;
}

codeunit 60242 "Test Code Coverage Trigger"
{
    trigger OnRun()
    var
        Value: Integer;
    begin
        Value := 3;
        if Value <> 3 then
            Error('Value must be 3.');
    end;
}
