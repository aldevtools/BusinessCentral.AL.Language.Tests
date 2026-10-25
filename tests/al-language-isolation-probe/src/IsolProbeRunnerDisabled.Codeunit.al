// A top-level test runner with TestIsolation = Disabled (corpus issue 645, item 2).
//
// The same shape as "Isol Probe Runner Function" (61300) with one property changed. The
// Windows nightly runs it LAST over the whole app (Run-TestsInBcContainer -testRunnerCodeunitId
// 61304), because nothing is rolled back under it and its rows stay in the database.
// Observables: "LT DJ Isol Writer" (61306) and "LT DJ Isol Reader" (61307) for what is kept
// between tests and test codeunits, plus every other fixture of the app.
namespace ALLanguage.IsolationProbe;

using System.TestTools.TestRunner;

codeunit 61304 "LT DJ Isol Runner Disabled"
{
    Subtype = TestRunner;
    TableNo = "Test Method Line";
    TestIsolation = Disabled;
    Permissions = tabledata "AL Test Suite" = rimd,
                  tabledata "Test Method Line" = rimd;

    trigger OnRun()
    begin
        ALTestSuite.Get(Rec."Test Suite");
        CurrentTestMethodLine.Copy(Rec);
        TestRunnerMgt.RunTests(Rec);
    end;

    trigger OnBeforeTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    begin
        exit(
          TestRunnerMgt.PlatformBeforeTestRun(
            CodeunitID, CopyStr(CodeunitName, 1, 30), CopyStr(FunctionName, 1, 128), FunctionTestPermissions, ALTestSuite.Name, CurrentTestMethodLine.GetFilter("Line No.")));
    end;

    trigger OnAfterTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    begin
        TestRunnerMgt.PlatformAfterTestRun(
          CodeunitID, CopyStr(CodeunitName, 1, 30), CopyStr(FunctionName, 1, 128), FunctionTestPermissions, IsSuccess, ALTestSuite.Name,
          CurrentTestMethodLine.GetFilter("Line No."));
    end;

    var
        ALTestSuite: Record "AL Test Suite";
        CurrentTestMethodLine: Record "Test Method Line";
        TestRunnerMgt: Codeunit "Test Runner - Mgt";
}
