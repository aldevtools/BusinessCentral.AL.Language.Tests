// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-codecoveragerefresh-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); codeunits 80201 (target), 80202 (a second test codeunit with a [Test] procedure of the same name), 80203 (tests)
// Probe: corpus issue 647 items 10 and 11 (writer AV). Risky: the Code Coverage tables are platform virtual tables (kept in a file of their own).
// Facts: Code Coverage rows of one object after a first CodeCoverageRefresh, more code run while still logging, and a second CodeCoverageRefresh;
//   the Code Coverage Tests Run rows (Method ID, Test ID) of two [Test] procedures with the same name in two codeunits.
//   The helper [Test] procedures (TwinMethod in both codeunits) observe nothing and end without Finish() by design: the recording test calls them.
// BC versions: 27, 28, 29
codeunit 80201 "LT AV CC Target"
{
    procedure First(Value: Integer): Integer
    begin
        if Value > 1 then
            exit(Value * 2);
        exit(Value);
    end;

    procedure Second(Value: Integer): Integer
    var
        i: Integer;
        Sum: Integer;
    begin
        for i := 1 to Value do
            Sum += i;
        exit(Sum);
    end;
}

codeunit 80202 "LT AV CC Twin"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TwinMethod()
    var
        X: Integer;
    begin
        X := 1;
    end;
}

codeunit 80203 "LT AV Code Coverage"
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

    local procedure TargetRows(): Integer
    var
        CodeCoverage: Record "Code Coverage";
    begin
        CodeCoverage.SetRange("Object Type", CodeCoverage."Object Type"::Codeunit);
        CodeCoverage.SetRange("Object ID", Codeunit::"LT AV CC Target");
        exit(CodeCoverage.Count());
    end;

    local procedure TargetHitLines(): Text
    var
        CodeCoverage: Record "Code Coverage";
        Result: Text;
    begin
        CodeCoverage.SetRange("Object Type", CodeCoverage."Object Type"::Codeunit);
        CodeCoverage.SetRange("Object ID", Codeunit::"LT AV CC Target");
        CodeCoverage.SetFilter("No. of Hits", '>0');
        if CodeCoverage.FindSet() then
            repeat
                Result += 'L' + Format(CodeCoverage."Line No.") + '=' + Format(CodeCoverage."No. of Hits") + ' ';
            until CodeCoverage.Next() = 0;
        exit(Result.TrimEnd());
    end;

    [Test]
    procedure CodeCoverageRefresh_Twice_WithCodeRunBetween()
    var
        Observer: Codeunit "Probe Observer";
        Target: Codeunit "LT AV CC Target";
        RowsBeforeRefresh: Integer;
        RowsAfterFirst: Integer;
        HitsAfterFirst: Text;
        RowsBeforeSecond: Integer;
        RowsAfterSecond: Integer;
        HitsAfterSecond: Text;
        Dummy: Integer;
    begin
        Initialize();
        CodeCoverageLog(true, false);
        Dummy := Target.First(3);
        RowsBeforeRefresh := TargetRows();
        CodeCoverageRefresh();
        RowsAfterFirst := TargetRows();
        HitsAfterFirst := TargetHitLines();
        Dummy := Target.First(1);
        Dummy := Target.Second(3);
        RowsBeforeSecond := TargetRows();
        CodeCoverageRefresh();
        RowsAfterSecond := TargetRows();
        HitsAfterSecond := TargetHitLines();
        CodeCoverageLog(false, false);
        Observer.Observe('rows before the first refresh', Format(RowsBeforeRefresh));
        Observer.Observe('rows after the first refresh', Format(RowsAfterFirst));
        Observer.Observe('hit lines after the first refresh', HitsAfterFirst);
        Observer.Observe('rows before the second refresh', Format(RowsBeforeSecond));
        Observer.Observe('rows after the second refresh', Format(RowsAfterSecond));
        Observer.Observe('hit lines after the second refresh', HitsAfterSecond);
        Observer.Observe('rows after logging stopped', Format(TargetRows()));
        Observer.Observe('hit lines after logging stopped', TargetHitLines());
        Observer.Expect('rows before the first refresh', '0');
        Observer.Expect('rows after the first refresh', '16');
        Observer.Expect('hit lines after the first refresh', 'L13=1 L14=1');
        Observer.Expect('rows before the second refresh', '16');
        Observer.Expect('rows after the second refresh', '16');
        Observer.Expect('hit lines after the second refresh', 'L13=2 L14=1 L15=1 L23=1 L24=3 L25=1');
        Observer.Expect('rows after logging stopped', '16');
        Observer.Expect('hit lines after logging stopped', 'L13=2 L14=1 L15=1 L23=1 L24=3 L25=1');
        Observer.Verify();
    end;

    [Test]
    procedure TwinMethod()
    var
        X: Integer;
    begin
        X := 1;
    end;

    [Test]
    procedure MethodId_SameTestNameInTwoCodeunits()
    var
        Observer: Codeunit "Probe Observer";
        Twin: Codeunit "LT AV CC Twin";
        TestsRun: Record "Code Coverage Tests Run";
        OwnId: Integer;
        TwinId: Integer;
        OwnTest: Integer;
        TwinTest: Integer;
    begin
        Initialize();
        CodeCoverageLog(true, false);
        TwinMethod();
        Twin.TwinMethod();
        CodeCoverageLog(false, false);
        TestsRun.SetRange("Method Name", 'TwinMethod');
        Observer.Observe('rows named TwinMethod', Format(TestsRun.Count()));
        TestsRun.SetRange("Object ID", Codeunit::"LT AV Code Coverage");
        Observer.Observe('own row', Format(TestsRun.FindFirst()));
        OwnId := TestsRun."Method ID";
        OwnTest := TestsRun."Test ID";
        TestsRun.SetRange("Object ID", Codeunit::"LT AV CC Twin");
        Observer.Observe('twin row', Format(TestsRun.FindFirst()));
        TwinId := TestsRun."Method ID";
        TwinTest := TestsRun."Test ID";
        Observer.Observe('method id equal', Format(OwnId = TwinId));
        Observer.Observe('method id zero', Format(OwnId = 0));
        Observer.Observe('test id twin minus own', Format(TwinTest - OwnTest));
        Observer.Expect('rows named TwinMethod', '2');
        Observer.Expect('own row', 'Yes');
        Observer.Expect('twin row', 'Yes');
        Observer.Expect('method id equal', 'Yes');
        Observer.Expect('method id zero', 'No');
        Observer.Expect('test id twin minus own', '0');
        Observer.Verify();
    end;
}
