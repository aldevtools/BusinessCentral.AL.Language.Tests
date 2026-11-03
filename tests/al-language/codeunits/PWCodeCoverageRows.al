// Probe writer-c: "Code coverage rows" open points (docs/probes-needed.md), except the showMyCode app row.
// Observe-only. DumpRows() lists every Code Coverage row of the fixture as L<line>:<type>/<status>/<hits>.
// Fixtures: codeunits 69720 "PW CC Target", 69721 "PW CC Never Entered", 69722 tests.
// Line numbers in the dump are lines of THIS file; read them against the fixture source below.

codeunit 69720 "PW CC Target"
{
    var
        A: Integer;
        B: Integer;

    // a comment line

    procedure OneLineIf(X: Boolean)
    begin
        if X then A := A + 1;
    end;

    procedure LoopOneLine(N: Integer)
    var
        I: Integer;
    begin
        for I := 1 to N do A := A + I;
    end;

    procedure TwoStatements()
    begin
        A := 1; B := 2;
    end;

    procedure LoopMultiLine(N: Integer)
    var
        I: Integer;
    begin
        for I := 1 to N do
            A := A + 1;
    end;

    procedure Plain()
    begin
        A := 1;
    end;

    procedure NeverCalled()
    begin
        A := 2;
    end;
}

codeunit 69721 "PW CC Never Entered"
{
    procedure Work()
    begin
        Message('never called');
    end;
}

codeunit 69722 "PW Code Coverage Rows Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

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

    local procedure DumpRows(ObjectId: Integer): Text
    var
        CodeCoverage: Record "Code Coverage";
        Result: Text;
    begin
        CodeCoverage.SetRange("Object Type", CodeCoverage."Object Type"::Codeunit);
        CodeCoverage.SetRange("Object ID", ObjectId);
        if CodeCoverage.FindSet() then
            repeat
                Result += StrSubstNo('L%1:%2/%3/%4 ', CodeCoverage."Line No.", CodeCoverage."Line Type", CodeCoverage."Code Coverage Status", CodeCoverage."No. of Hits");
            until CodeCoverage.Next() = 0;
        exit(Result + '(count=' + Format(CodeCoverage.Count()) + ')');
    end;

    local procedure RowCount(ObjectId: Integer): Integer
    var
        CodeCoverage: Record "Code Coverage";
    begin
        CodeCoverage.SetRange("Object Type", CodeCoverage."Object Type"::Codeunit);
        CodeCoverage.SetRange("Object ID", ObjectId);
        exit(CodeCoverage.Count());
    end;

    [Test]
    procedure Rows_AllLinesOfSmallCodeunit_OneProcedureRun()
    var
        Target: Codeunit "PW CC Target";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        Target.Plain();
        CodeCoverageLog(false, false);
        Observer.Observe('rows', DumpRows(Codeunit::"PW CC Target"));
        Observer.Expect('rows', 'L0:Object/Non Applicable/0 L14:Trigger/Function/Non Applicable/0 L15:Empty/Non Applicable/0 L16:Code/Not Covered/0 L17:Empty/Non Applicable/0 L19:Trigger/Function/Non Applicable/0 L20:Empty/Non Applicable/0 L21:Empty/Non Applicable/0 L22:Empty/Non Applicable/0 L23:Code/Not Covered/0 L24:Empty/Non Applicable/0 L26:Trigger/Function/Non Applicable/0 L27:Empty/Non Applicable/0 L28:Code/Not Covered/0 L29:Empty/Non Applicable/0 L31:Trigger/Function/Non Applicable/0 L32:Empty/Non Applicable/0 L33:Empty/Non Applicable/0 L34:Empty/Non Applicable/0 L35:Code/Not Covered/0 L36:Code/Not Covered/0 L37:Empty/Non Applicable/0 L39:Trigger/Function/Non Applicable/0 L40:Empty/Non Applicable/0 L41:Code/Covered/1 L42:Empty/Non Applicable/0 L44:Trigger/Function/Non Applicable/0 L45:Empty/Non Applicable/0 L46:Code/Not Covered/0 L47:Empty/Non Applicable/0 (count=30)');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_ObjectNeverEntered_WhileRecording()
    var
        Target: Codeunit "PW CC Target";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        Target.Plain();
        CodeCoverageLog(false, false);
        Observer.Observe('never_entered_row_count', Format(RowCount(Codeunit::"PW CC Never Entered")));
        Observer.Observe('never_entered_rows', DumpRows(Codeunit::"PW CC Never Entered"));
        Observer.Expect('never_entered_row_count', '0');
        Observer.Expect('never_entered_rows', '(count=0)');
        Observer.Verify();
    end;

    [Test]
    procedure Hits_OneLineIf_ConditionTrue()
    var
        Target: Codeunit "PW CC Target";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        Target.OneLineIf(true);
        CodeCoverageLog(false, false);
        Observer.Observe('rows', DumpRows(Codeunit::"PW CC Target"));
        Observer.Expect('rows', 'L0:Object/Non Applicable/0 L14:Trigger/Function/Non Applicable/0 L15:Empty/Non Applicable/0 L16:Code/Covered/1 L17:Empty/Non Applicable/0 L19:Trigger/Function/Non Applicable/0 L20:Empty/Non Applicable/0 L21:Empty/Non Applicable/0 L22:Empty/Non Applicable/0 L23:Code/Not Covered/0 L24:Empty/Non Applicable/0 L26:Trigger/Function/Non Applicable/0 L27:Empty/Non Applicable/0 L28:Code/Not Covered/0 L29:Empty/Non Applicable/0 L31:Trigger/Function/Non Applicable/0 L32:Empty/Non Applicable/0 L33:Empty/Non Applicable/0 L34:Empty/Non Applicable/0 L35:Code/Not Covered/0 L36:Code/Not Covered/0 L37:Empty/Non Applicable/0 L39:Trigger/Function/Non Applicable/0 L40:Empty/Non Applicable/0 L41:Code/Not Covered/0 L42:Empty/Non Applicable/0 L44:Trigger/Function/Non Applicable/0 L45:Empty/Non Applicable/0 L46:Code/Not Covered/0 L47:Empty/Non Applicable/0 (count=30)');
        Observer.Verify();
    end;

    [Test]
    procedure Hits_OneLineIf_ConditionFalse()
    var
        Target: Codeunit "PW CC Target";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        Target.OneLineIf(false);
        CodeCoverageLog(false, false);
        Observer.Observe('rows', DumpRows(Codeunit::"PW CC Target"));
        Observer.Expect('rows', 'L0:Object/Non Applicable/0 L14:Trigger/Function/Non Applicable/0 L15:Empty/Non Applicable/0 L16:Code/Partially Covered/1 L17:Empty/Non Applicable/0 L19:Trigger/Function/Non Applicable/0 L20:Empty/Non Applicable/0 L21:Empty/Non Applicable/0 L22:Empty/Non Applicable/0 L23:Code/Not Covered/0 L24:Empty/Non Applicable/0 L26:Trigger/Function/Non Applicable/0 L27:Empty/Non Applicable/0 L28:Code/Not Covered/0 L29:Empty/Non Applicable/0 L31:Trigger/Function/Non Applicable/0 L32:Empty/Non Applicable/0 L33:Empty/Non Applicable/0 L34:Empty/Non Applicable/0 L35:Code/Not Covered/0 L36:Code/Not Covered/0 L37:Empty/Non Applicable/0 L39:Trigger/Function/Non Applicable/0 L40:Empty/Non Applicable/0 L41:Code/Not Covered/0 L42:Empty/Non Applicable/0 L44:Trigger/Function/Non Applicable/0 L45:Empty/Non Applicable/0 L46:Code/Not Covered/0 L47:Empty/Non Applicable/0 (count=30)');
        Observer.Verify();
    end;

    [Test]
    procedure Hits_OneLineIf_TrueThenFalseThenTrue()
    var
        Target: Codeunit "PW CC Target";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        Target.OneLineIf(true);
        Target.OneLineIf(false);
        Target.OneLineIf(true);
        CodeCoverageLog(false, false);
        Observer.Observe('rows', DumpRows(Codeunit::"PW CC Target"));
        Observer.Expect('rows', 'L0:Object/Non Applicable/0 L14:Trigger/Function/Non Applicable/0 L15:Empty/Non Applicable/0 L16:Code/Covered/3 L17:Empty/Non Applicable/0 L19:Trigger/Function/Non Applicable/0 L20:Empty/Non Applicable/0 L21:Empty/Non Applicable/0 L22:Empty/Non Applicable/0 L23:Code/Not Covered/0 L24:Empty/Non Applicable/0 L26:Trigger/Function/Non Applicable/0 L27:Empty/Non Applicable/0 L28:Code/Not Covered/0 L29:Empty/Non Applicable/0 L31:Trigger/Function/Non Applicable/0 L32:Empty/Non Applicable/0 L33:Empty/Non Applicable/0 L34:Empty/Non Applicable/0 L35:Code/Not Covered/0 L36:Code/Not Covered/0 L37:Empty/Non Applicable/0 L39:Trigger/Function/Non Applicable/0 L40:Empty/Non Applicable/0 L41:Code/Not Covered/0 L42:Empty/Non Applicable/0 L44:Trigger/Function/Non Applicable/0 L45:Empty/Non Applicable/0 L46:Code/Not Covered/0 L47:Empty/Non Applicable/0 (count=30)');
        Observer.Verify();
    end;

    [Test]
    procedure Hits_LoopOneLine_ThreeIterations()
    var
        Target: Codeunit "PW CC Target";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        Target.LoopOneLine(3);
        CodeCoverageLog(false, false);
        Observer.Observe('rows', DumpRows(Codeunit::"PW CC Target"));
        Observer.Expect('rows', 'L0:Object/Non Applicable/0 L14:Trigger/Function/Non Applicable/0 L15:Empty/Non Applicable/0 L16:Code/Not Covered/0 L17:Empty/Non Applicable/0 L19:Trigger/Function/Non Applicable/0 L20:Empty/Non Applicable/0 L21:Empty/Non Applicable/0 L22:Empty/Non Applicable/0 L23:Code/Covered/3 L24:Empty/Non Applicable/0 L26:Trigger/Function/Non Applicable/0 L27:Empty/Non Applicable/0 L28:Code/Not Covered/0 L29:Empty/Non Applicable/0 L31:Trigger/Function/Non Applicable/0 L32:Empty/Non Applicable/0 L33:Empty/Non Applicable/0 L34:Empty/Non Applicable/0 L35:Code/Not Covered/0 L36:Code/Not Covered/0 L37:Empty/Non Applicable/0 L39:Trigger/Function/Non Applicable/0 L40:Empty/Non Applicable/0 L41:Code/Not Covered/0 L42:Empty/Non Applicable/0 L44:Trigger/Function/Non Applicable/0 L45:Empty/Non Applicable/0 L46:Code/Not Covered/0 L47:Empty/Non Applicable/0 (count=30)');
        Observer.Verify();
    end;

    [Test]
    procedure Hits_LoopOneLine_ZeroIterations()
    var
        Target: Codeunit "PW CC Target";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        Target.LoopOneLine(0);
        CodeCoverageLog(false, false);
        Observer.Observe('rows', DumpRows(Codeunit::"PW CC Target"));
        Observer.Expect('rows', 'L0:Object/Non Applicable/0 L14:Trigger/Function/Non Applicable/0 L15:Empty/Non Applicable/0 L16:Code/Not Covered/0 L17:Empty/Non Applicable/0 L19:Trigger/Function/Non Applicable/0 L20:Empty/Non Applicable/0 L21:Empty/Non Applicable/0 L22:Empty/Non Applicable/0 L23:Code/Partially Covered/1 L24:Empty/Non Applicable/0 L26:Trigger/Function/Non Applicable/0 L27:Empty/Non Applicable/0 L28:Code/Not Covered/0 L29:Empty/Non Applicable/0 L31:Trigger/Function/Non Applicable/0 L32:Empty/Non Applicable/0 L33:Empty/Non Applicable/0 L34:Empty/Non Applicable/0 L35:Code/Not Covered/0 L36:Code/Not Covered/0 L37:Empty/Non Applicable/0 L39:Trigger/Function/Non Applicable/0 L40:Empty/Non Applicable/0 L41:Code/Not Covered/0 L42:Empty/Non Applicable/0 L44:Trigger/Function/Non Applicable/0 L45:Empty/Non Applicable/0 L46:Code/Not Covered/0 L47:Empty/Non Applicable/0 (count=30)');
        Observer.Verify();
    end;

    [Test]
    procedure Hits_LoopMultiLine_FiveIterations()
    var
        Target: Codeunit "PW CC Target";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        Target.LoopMultiLine(5);
        CodeCoverageLog(false, false);
        Observer.Observe('rows', DumpRows(Codeunit::"PW CC Target"));
        Observer.Expect('rows', 'L0:Object/Non Applicable/0 L14:Trigger/Function/Non Applicable/0 L15:Empty/Non Applicable/0 L16:Code/Not Covered/0 L17:Empty/Non Applicable/0 L19:Trigger/Function/Non Applicable/0 L20:Empty/Non Applicable/0 L21:Empty/Non Applicable/0 L22:Empty/Non Applicable/0 L23:Code/Not Covered/0 L24:Empty/Non Applicable/0 L26:Trigger/Function/Non Applicable/0 L27:Empty/Non Applicable/0 L28:Code/Not Covered/0 L29:Empty/Non Applicable/0 L31:Trigger/Function/Non Applicable/0 L32:Empty/Non Applicable/0 L33:Empty/Non Applicable/0 L34:Empty/Non Applicable/0 L35:Code/Covered/1 L36:Code/Covered/5 L37:Empty/Non Applicable/0 L39:Trigger/Function/Non Applicable/0 L40:Empty/Non Applicable/0 L41:Code/Not Covered/0 L42:Empty/Non Applicable/0 L44:Trigger/Function/Non Applicable/0 L45:Empty/Non Applicable/0 L46:Code/Not Covered/0 L47:Empty/Non Applicable/0 (count=30)');
        Observer.Verify();
    end;

    [Test]
    procedure Hits_TwoStatementsOnOneLine()
    var
        Target: Codeunit "PW CC Target";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        Target.TwoStatements();
        CodeCoverageLog(false, false);
        Observer.Observe('rows', DumpRows(Codeunit::"PW CC Target"));
        Observer.Expect('rows', 'L0:Object/Non Applicable/0 L14:Trigger/Function/Non Applicable/0 L15:Empty/Non Applicable/0 L16:Code/Not Covered/0 L17:Empty/Non Applicable/0 L19:Trigger/Function/Non Applicable/0 L20:Empty/Non Applicable/0 L21:Empty/Non Applicable/0 L22:Empty/Non Applicable/0 L23:Code/Not Covered/0 L24:Empty/Non Applicable/0 L26:Trigger/Function/Non Applicable/0 L27:Empty/Non Applicable/0 L28:Code/Covered/1 L29:Empty/Non Applicable/0 L31:Trigger/Function/Non Applicable/0 L32:Empty/Non Applicable/0 L33:Empty/Non Applicable/0 L34:Empty/Non Applicable/0 L35:Code/Not Covered/0 L36:Code/Not Covered/0 L37:Empty/Non Applicable/0 L39:Trigger/Function/Non Applicable/0 L40:Empty/Non Applicable/0 L41:Code/Not Covered/0 L42:Empty/Non Applicable/0 L44:Trigger/Function/Non Applicable/0 L45:Empty/Non Applicable/0 L46:Code/Not Covered/0 L47:Empty/Non Applicable/0 (count=30)');
        Observer.Verify();
    end;

    [Test]
    procedure Hits_TriggerFunctionRow_CalledThreeTimes()
    var
        Target: Codeunit "PW CC Target";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        Target.Plain();
        Target.Plain();
        Target.Plain();
        CodeCoverageLog(false, false);
        Observer.Observe('rows', DumpRows(Codeunit::"PW CC Target"));
        Observer.Expect('rows', 'L0:Object/Non Applicable/0 L14:Trigger/Function/Non Applicable/0 L15:Empty/Non Applicable/0 L16:Code/Not Covered/0 L17:Empty/Non Applicable/0 L19:Trigger/Function/Non Applicable/0 L20:Empty/Non Applicable/0 L21:Empty/Non Applicable/0 L22:Empty/Non Applicable/0 L23:Code/Not Covered/0 L24:Empty/Non Applicable/0 L26:Trigger/Function/Non Applicable/0 L27:Empty/Non Applicable/0 L28:Code/Not Covered/0 L29:Empty/Non Applicable/0 L31:Trigger/Function/Non Applicable/0 L32:Empty/Non Applicable/0 L33:Empty/Non Applicable/0 L34:Empty/Non Applicable/0 L35:Code/Not Covered/0 L36:Code/Not Covered/0 L37:Empty/Non Applicable/0 L39:Trigger/Function/Non Applicable/0 L40:Empty/Non Applicable/0 L41:Code/Covered/3 L42:Empty/Non Applicable/0 L44:Trigger/Function/Non Applicable/0 L45:Empty/Non Applicable/0 L46:Code/Not Covered/0 L47:Empty/Non Applicable/0 (count=30)');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_TestCodeunitItself_VarAndCommentLines()
    begin
        Initialize();
        CodeCoverageLog(true, false);
        CodeCoverageLog(false, false);
        Observer.Observe('rows_of_the_test_codeunit_itself', DumpRows(Codeunit::"PW Code Coverage Rows Probe"));
        Observer.Discard(); // tier dependent: recorded in the manifest, not asserted
    end;









    local procedure InnerRecordedTest(): Integer
    begin
        exit(1);
    end;

    [Test]
    procedure RecordedInner()
    begin
        if InnerRecordedTest() = 0 then
            Error('unreachable');
    end;

    [Test]
    procedure RecordedOuter()
    begin
        RecordedInner();
    end;

    [Test]
    procedure NestedTest_TestsRunAndLookupRows()
    var
        TestsRun: Record "Code Coverage Tests Run";
        TestLookup: Record "Code Coverage Test Lookup";
        Runs: Text;
        Lookups: Text;
    begin
        Initialize();
        CodeCoverageLog(true, false);
        RecordedOuter();
        CodeCoverageLog(false, false);
        TestsRun.SetRange("Object ID", Codeunit::"PW Code Coverage Rows Probe");
        if TestsRun.FindSet() then
            repeat
                Runs += StrSubstNo('[%1 methodid=%2] ', TestsRun."Method Name", TestsRun."Method ID");
                TestLookup.SetRange("Test ID", TestsRun."Test ID");
                if TestLookup.FindSet() then
                    repeat
                        Lookups += StrSubstNo('(test %1 ran method %2) ', TestsRun."Method Name", TestLookup."Method ID");
                    until TestLookup.Next() = 0;
            until TestsRun.Next() = 0;
        Observer.Observe('tests_run', Runs);
        Observer.Observe('lookups', Lookups);
        Observer.Expect('tests_run', '[RecordedOuter methodid=469735107] ');
        Observer.Expect('lookups', '(test RecordedOuter ran method 31658110) ');
        Observer.Verify();
    end;

    local procedure ReadRowsThenFail()
    begin
        Observer.Observe('count_inside_failing_scope', Format(RowCount(Codeunit::"PW CC Target")));
        Error('rollback probe');
    end;

    [Test]
    procedure Rollback_RowsReadBeforeAnAsserterror()
    var
        Target: Codeunit "PW CC Target";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        Target.Plain();
        CodeCoverageLog(false, false);
        Observer.Observe('count_before', Format(RowCount(Codeunit::"PW CC Target")));
        asserterror Error('x');
        Observer.Observe('count_after_asserterror', Format(RowCount(Codeunit::"PW CC Target")));
        Observer.Expect('count_before', '30');
        Observer.Expect('count_after_asserterror', '30');
        Observer.Verify();
    end;

    [Test]
    procedure Rollback_RowsFirstReadInsideFailingScope()
    var
        Target: Codeunit "PW CC Target";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        Target.Plain();
        CodeCoverageLog(false, false);
        asserterror ReadRowsThenFail();
        Observer.Observe('count_after_asserterror', Format(RowCount(Codeunit::"PW CC Target")));
        Observer.Expect('count_inside_failing_scope', '30');
        Observer.Expect('count_after_asserterror', '30');
        Observer.Verify();
    end;

    // The next two tests are order dependent: the first leaves recording ON and the second looks at what it left.
    // The second stops recording at its end.
    [Test]
    procedure Outlives_1_StartRecordingAndLeaveItOn()
    begin
        Initialize();
        CodeCoverageLog(true, false);
        Observer.Observe('recording_on_at_end_of_test', Format(CodeCoverageLog()));
        Observer.Expect('recording_on_at_end_of_test', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Outlives_2_LooksAtWhatTheEarlierTestLeft()
    var
        TestsRun: Record "Code Coverage Tests Run";
        Names: Text;
    begin
        Observer.Observe('recording_on_at_start', Format(CodeCoverageLog()));
        if TestsRun.FindSet() then
            repeat
                Names += TestsRun."Method Name" + ' ';
            until TestsRun.Next() = 0;
        Observer.Observe('tests_run_rows', Names);
        CodeCoverageLog(false, false);
        Observer.Observe('recording_on_after_stop', Format(CodeCoverageLog()));
        Observer.Expect('recording_on_at_start', 'Yes');
        Observer.Expect('tests_run_rows', '');
        Observer.Expect('recording_on_after_stop', 'No');
        Observer.Verify();
    end;
}
