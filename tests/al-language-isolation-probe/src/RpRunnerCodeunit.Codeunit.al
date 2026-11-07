// A top-level probe runner for ADR-066 of al-runtime-rs (probes P1-P8 of the test runner's
// triggers), with TestIsolation = Codeunit. "LT RP Runner Codeunit" (61330) and "LT RP Runner
// Function" (61331) are identical except for that property.
//
// The shape of Microsoft's "Test Runner - Isol. Codeunit" (130450), so Run-TestsInBcContainer
// -testRunnerCodeunitId drives it through the AL Test Tool and records a result per test
// method. Around Microsoft's bookkeeping it calls "LT RP Runner Logic" (61333), which records
// every trigger call in "LT RP Log" (61332) and does what each probe needs. Microsoft's
// bookkeeping is skipped for a test codeunit this runner runs on its own (P7 runs 61344 from
// the invocation of 61343): its lines are not in the selection, so Microsoft's runner would
// answer false for its methods.
//
// The Windows nightly runs it over 61330..61349 only. "LT RP Reader" (61346) has the highest
// id, so it runs last and asserts what the log and the table hold.
namespace ALLanguage.IsolationProbe;

using System.TestTools.TestRunner;

codeunit 61330 "LT RP Runner Codeunit"
{
    Subtype = TestRunner;
    TableNo = "Test Method Line";
    TestIsolation = Codeunit;
    Permissions = tabledata "AL Test Suite" = rimd,
                  tabledata "Test Method Line" = rimd;

    trigger OnRun()
    begin
        ALTestSuite.Get(Rec."Test Suite");
        CurrentTestMethodLine.Copy(Rec);
        Logic.RunTestCodeunit(Codeunit::"LT RP Runner Codeunit", Rec."Test Codeunit");
    end;

    trigger OnBeforeTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    var
        Proceed: Boolean;
    begin
        if not Logic.BeforeTestRun(CodeunitID, FunctionName, FunctionTestPermissions) then
            exit(false);
        Proceed := true;
        if CodeunitID = CurrentTestMethodLine."Test Codeunit" then
            Proceed :=
              TestRunnerMgt.PlatformBeforeTestRun(
                CodeunitID, CopyStr(CodeunitName, 1, 30), CopyStr(FunctionName, 1, 128), FunctionTestPermissions, ALTestSuite.Name, CurrentTestMethodLine.GetFilter("Line No."));
        Logic.TriggerWrites('BEFORE', CodeunitID, FunctionName);
        exit(Proceed);
    end;

    trigger OnAfterTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    begin
        Logic.AfterTestRun(CodeunitID, FunctionName, IsSuccess);
        if CodeunitID = CurrentTestMethodLine."Test Codeunit" then
            TestRunnerMgt.PlatformAfterTestRun(
              CodeunitID, CopyStr(CodeunitName, 1, 30), CopyStr(FunctionName, 1, 128), FunctionTestPermissions, IsSuccess, ALTestSuite.Name,
              CurrentTestMethodLine.GetFilter("Line No."));
        Logic.TriggerWrites('AFTER', CodeunitID, FunctionName);
    end;

    var
        ALTestSuite: Record "AL Test Suite";
        CurrentTestMethodLine: Record "Test Method Line";
        TestRunnerMgt: Codeunit "Test Runner - Mgt";
        Logic: Codeunit "LT RP Runner Logic";
}
