// Batch 6, md:420 [Test ID, Method ID] (the "Code coverage rows" section; the other rows of that section -- objects never entered, several statements on a line,
// nested [Test] procedures, rows after a rollback, a recording that outlives its test -- are measured by codeunit/PWCodeCoverageRows.al, see MANIFEST).
// Observe-only. Method IDs are generated numbers (real BC: 469735107 in Tests Run, 31658110 in Test Lookup for the same procedure) and are never printed:
// only equalities, orderings and the small Test ID counter are observed.
// The helper [Test] procedures (MethodA, MethodB, MethodAA, MethodOther) observe nothing and end WITHOUT Finish() by design: the recording tests call them while recording.

codeunit 67334 "W6 Code Coverage Ids"
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

    // helper tests: same body, names differ in one letter / one appended letter
    [Test]
    procedure MethodA()
    begin
        if StrLen('x') = 0 then
            Error('unreachable');
    end;

    [Test]
    procedure MethodB()
    begin
        if StrLen('x') = 0 then
            Error('unreachable');
    end;

    [Test]
    procedure MethodAA()
    begin
        if StrLen('x') = 0 then
            Error('unreachable');
    end;

    [Test]
    procedure MethodOther()
    begin
        if StrLen('xyz') = 0 then
            Error('unreachable');
    end;

    local procedure RunRowText(MethodName: Text; var TestsRun: Record "Code Coverage Tests Run"): Boolean
    begin
        TestsRun.Reset();
        TestsRun.SetRange("Object ID", Codeunit::"W6 Code Coverage Ids");
        TestsRun.SetRange("Method Name", MethodName);
        exit(TestsRun.FindFirst());
    end;

    [Test]
    procedure MethodId_SameBody_DifferentNames_TestsRunRows()
    var
        TestsRun: Record "Code Coverage Tests Run";
        IdA: Integer;
        IdB: Integer;
        IdAA: Integer;
        IdOther: Integer;
        TestA: Integer;
        TestB: Integer;
        TestAA: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        MethodA();
        MethodB();
        MethodAA();
        MethodOther();
        CodeCoverageLog(false, false);
        Observer.Observe('row_A', Format(RunRowText('MethodA', TestsRun)));
        IdA := TestsRun."Method ID";
        TestA := TestsRun."Test ID";
        Observer.Observe('row_B', Format(RunRowText('MethodB', TestsRun)));
        IdB := TestsRun."Method ID";
        TestB := TestsRun."Test ID";
        Observer.Observe('row_AA', Format(RunRowText('MethodAA', TestsRun)));
        IdAA := TestsRun."Method ID";
        TestAA := TestsRun."Test ID";
        Observer.Observe('row_Other', Format(RunRowText('MethodOther', TestsRun)));
        IdOther := TestsRun."Method ID";
        Observer.Observe('A_equals_B', Format(IdA = IdB));
        Observer.Observe('A_equals_AA', Format(IdA = IdAA));
        Observer.Observe('A_equals_Other', Format(IdA = IdOther));
        Observer.Observe('A_less_than_B', Format(IdA < IdB));
        Observer.Observe('B_less_than_AA', Format(IdB < IdAA));
        Observer.Observe('all_four_distinct', Format((IdA <> IdB) and (IdA <> IdAA) and (IdA <> IdOther) and (IdB <> IdAA) and (IdB <> IdOther) and (IdAA <> IdOther)));
        Observer.Observe('test_id_B_minus_A', Format(TestB - TestA));
        Observer.Observe('test_id_AA_minus_B', Format(TestAA - TestB));
        Observer.Expect('row_A', 'Yes');
        Observer.Expect('row_B', 'Yes');
        Observer.Expect('row_AA', 'Yes');
        Observer.Expect('row_Other', 'Yes');
        Observer.Expect('A_equals_B', 'Yes');
        Observer.Expect('A_equals_AA', 'Yes');
        Observer.Expect('A_equals_Other', 'Yes');
        Observer.Expect('A_less_than_B', 'No');
        Observer.Expect('B_less_than_AA', 'No');
        Observer.Expect('all_four_distinct', 'No');
        Observer.Expect('test_id_B_minus_A', '0');
        Observer.Expect('test_id_AA_minus_B', '0');
        Observer.Verify();
    end;

    [Test]
    procedure MethodId_TestsRunVersusTestLookup()
    var
        TestsRun: Record "Code Coverage Tests Run";
        TestLookup: Record "Code Coverage Test Lookup";
        RunId: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        MethodA();
        CodeCoverageLog(false, false);
        Observer.Observe('tests_run_row', Format(RunRowText('MethodA', TestsRun)));
        RunId := TestsRun."Method ID";
        TestLookup.SetRange("Test ID", TestsRun."Test ID");
        Observer.Observe('lookup_row_count_for_the_test', Format(TestLookup.Count()));
        if TestLookup.FindFirst() then begin
            Observer.Observe('lookup_method_id_equals_tests_run_method_id', Format(TestLookup."Method ID" = RunId));
            Observer.Observe('lookup_method_id_below_1000', Format(TestLookup."Method ID" < 1000));
        end;
        Observer.Observe('tests_run_method_id_below_1000', Format(RunId < 1000));
        Observer.Expect('tests_run_row', 'Yes');
        Observer.Expect('lookup_row_count_for_the_test', '0');
        Observer.Expect('tests_run_method_id_below_1000', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure MethodId_SameProcedure_TwoRecordings()
    var
        TestsRun: Record "Code Coverage Tests Run";
        FirstId: Integer;
        FirstTest: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        MethodA();
        CodeCoverageLog(false, false);
        RunRowText('MethodA', TestsRun);
        FirstId := TestsRun."Method ID";
        FirstTest := TestsRun."Test ID";

        Initialize();
        CodeCoverageLog(true, false);
        MethodA();
        CodeCoverageLog(false, false);
        Observer.Observe('second_recording_row', Format(RunRowText('MethodA', TestsRun)));
        Observer.Observe('method_id_same_in_both_recordings', Format(TestsRun."Method ID" = FirstId));
        Observer.Observe('test_id_second_minus_first', Format(TestsRun."Test ID" - FirstTest));
        Observer.Observe('test_id_second_is_1', Format(TestsRun."Test ID" = 1));
        Observer.Expect('second_recording_row', 'Yes');
        Observer.Expect('method_id_same_in_both_recordings', 'Yes');
        Observer.Expect('test_id_second_minus_first', '0');
        Observer.Expect('test_id_second_is_1', 'No');
        Observer.Verify();
    end;

    local procedure ColumnList(TableId: Integer): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Result: Text;
        i: Integer;
    begin
        RecRef.Open(TableId);
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            Result += Format(FldRef.Number()) + '=' + FldRef.Name() + ';';
        end;
        exit(Result);
    end;

    [Test]
    procedure ColumnNames_CodeCoverageTables()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('code_coverage_columns', ColumnList(Database::"Code Coverage"));
        Observer.Observe('tests_run_columns', ColumnList(Database::"Code Coverage Tests Run"));
        Observer.Observe('test_lookup_columns', ColumnList(Database::"Code Coverage Test Lookup"));
        Observer.Expect('code_coverage_columns', '1=Object Type;2=Object ID;3=Line No.;4=Line Type;5=Line;6=No. of Hits;7=Code Coverage Status;8=Method Id;');
        Observer.Expect('tests_run_columns', '1=Test ID;2=Object ID;3=Method ID;4=Method Name;5=Owning Application;');
        Observer.Expect('test_lookup_columns', '1=Object Type;2=Object ID;3=Method ID;4=Test ID;');
        Observer.Verify();
    end;
}
