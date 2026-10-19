// A top-level test runner that sets NO TestIsolation property (corpus issue 645, item 4).
//
// The same shape as "Isol Probe Runner Function" (61300) with the TestIsolation line removed.
// Microsoft's documentation gives Disabled as the default. The Windows nightly runs it over
// the whole app after the Function and Codeunit runners and before the Disabled runner, so its
// rows can be compared with the three runners that set the property.
namespace ALLanguage.IsolationProbe;

using System.TestTools.TestRunner;

codeunit 61305 "LT DJ Isol Runner No Property"
{
    Subtype = TestRunner;
    TableNo = "Test Method Line";
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
