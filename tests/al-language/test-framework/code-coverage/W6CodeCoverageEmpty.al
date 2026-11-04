// Batch 6, md:361 [Code Coverage tables] "empty until recording starts; after it every read is refused until an unfiltered DeleteAll": what the three tables show before any recording,
// while recording is still on, after it is stopped, and after a filtered and an unfiltered DeleteAll. The rows of one recorded procedure are measured by codeunit/PWCodeCoverageRows.al.
// Observe-only. Recording is switched on only inside a test and always off before Finish().

codeunit 67373 "W6 CC Target"
{
    procedure Work(): Integer
    var
        i: Integer;
        Total: Integer;
    begin
        for i := 1 to 3 do
            Total += i;
        exit(Total);
    end;
}

codeunit 67374 "W6 Code Coverage Empty"
{
    Subtype = Test;
    TestPermissions = Disabled;

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

    local procedure Counts(): Text
    var
        CodeCoverage: Record "Code Coverage";
        TestLookup: Record "Code Coverage Test Lookup";
        TestsRun: Record "Code Coverage Tests Run";
    begin
        exit('coverage=' + Format(CodeCoverage.Count()) + ' lookup=' + Format(TestLookup.Count()) + ' tests_run=' + Format(TestsRun.Count()));
    end;

    local procedure TargetRows(): Integer
    var
        CodeCoverage: Record "Code Coverage";
    begin
        CodeCoverage.SetRange("Object Type", CodeCoverage."Object Type"::Codeunit);
        CodeCoverage.SetRange("Object ID", Codeunit::"W6 CC Target");
        exit(CodeCoverage.Count());
    end;

    [Test]
    procedure Tables_BeforeAnyRecording_AreEmpty()
    var
        Target: Codeunit "W6 CC Target";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('after_delete_all', Counts());
        Target.Work();
        Observer.Observe('after_a_call_with_recording_off', Counts());
        Observer.Observe('target_rows_with_recording_off', Format(TargetRows()));
        Observer.Observe('recording_flag', Format(CodeCoverageLog()));
        Observer.Expect('after_delete_all', 'coverage=0 lookup=0 tests_run=0');
        Observer.Expect('after_a_call_with_recording_off', 'coverage=0 lookup=0 tests_run=0');
        Observer.Expect('target_rows_with_recording_off', '0');
        Observer.Expect('recording_flag', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Tables_WhileRecordingIsStillOn_And_AfterStop()
    var
        Target: Codeunit "W6 CC Target";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        Target.Work();
        Observer.Observe('recording_flag_on', Format(CodeCoverageLog()));
        Observer.Observe('target_rows_while_on', Format(TargetRows()));
        CodeCoverageLog(false, false);
        Observer.Observe('recording_flag_after_stop', Format(CodeCoverageLog()));
        Observer.Observe('target_rows_after_stop', Format(TargetRows()));
        Observer.Observe('target_rows_after_stop_again', Format(TargetRows()));
        Observer.Expect('recording_flag_on', 'Yes');
        Observer.Expect('target_rows_while_on', '0');
        Observer.Expect('recording_flag_after_stop', 'No');
        Observer.Expect('target_rows_after_stop', '10');
        Observer.Expect('target_rows_after_stop_again', '10');
        Observer.Verify();
    end;

    [Test]
    procedure Tables_FilteredDeleteAll_ThenUnfilteredDeleteAll()
    var
        CodeCoverage: Record "Code Coverage";
        Target: Codeunit "W6 CC Target";
        RowsBefore: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        Target.Work();
        CodeCoverageLog(false, false);
        RowsBefore := TargetRows();
        Observer.Observe('rows_before_delete', Format(RowsBefore > 0));
        CodeCoverage.SetRange("Object Type", CodeCoverage."Object Type"::Codeunit);
        CodeCoverage.SetRange("Object ID", Codeunit::"W6 CC Target");
        CodeCoverage.DeleteAll();
        Observer.Observe('target_rows_after_filtered_delete_all', Format(TargetRows()));
        Observer.Observe('read_after_filtered_delete_all_ok', Format(CodeCoverage.Count() >= 0));
        CodeCoverage.Reset();
        CodeCoverage.DeleteAll();
        Observer.Observe('counts_after_unfiltered_delete_all', Counts());
        Observer.Expect('rows_before_delete', 'Yes');
        Observer.Expect('target_rows_after_filtered_delete_all', '0');
        Observer.Expect('read_after_filtered_delete_all_ok', 'Yes');
        Observer.Expect('counts_after_unfiltered_delete_all', 'coverage=0 lookup=0 tests_run=0');
        Observer.Verify();
    end;

}
