// @expect AL0223 | The Property 'TestHandlers' can only be used if the property 'Subtype' is set to 'Test'
// @from 29
// @appjson {"runtime": "18.0"}
// TestHandlers names a valid test handler on a codeunit that is not a test codeunit (no Subtype = Test).
// Runtime test for BC 29 with Subtype = Test: tests/al-language-testlibraries/lt-bi-test-framework/BiTestHandler.al.
codeunit 59310 "MNC TH Impl 2300" implements ITestHandler
{
    procedure OnBeforeTestCodeunitRun(Context: TestHandlerContext) begin end;
    procedure OnAfterTestCodeunitRun(Context: TestHandlerContext) begin end;
    procedure OnBeforeTestProcedureRun(Context: TestHandlerContext) begin end;
    procedure OnAfterTestProcedureRun(Context: TestHandlerContext) begin end;
    procedure OnBeforeTestCaseRun(Context: TestHandlerContext) begin end;
    procedure OnAfterTestCaseRun(Context: TestHandlerContext) begin end;
}

enumextension 59311 "MNC TH Ext 2300" extends TestHandler
{
    value(59311; "MNC TH Value 2300")
    {
        Implementation = ITestHandler = "MNC TH Impl 2300";
    }
}

codeunit 59312 "MNC TH Plain 2300"
{
    TestHandlers = "MNC TH Value 2300";
}
