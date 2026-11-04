// @expect AL0261 | The identifier 'MNC TH Value 2305' can only be specified in the list once.
// @from 29
// @appjson {"runtime": "18.0"}
// TestHandlers lists the same enum value twice. (Two different values are accepted: see tests/al-language-testlibraries/lt-bi-test-framework/BiTestHandlerBehavior.al.)
codeunit 59320 "MNC TH Impl 2305" implements ITestHandler
{
    procedure OnBeforeTestCodeunitRun(Context: TestHandlerContext) begin end;
    procedure OnAfterTestCodeunitRun(Context: TestHandlerContext) begin end;
    procedure OnBeforeTestProcedureRun(Context: TestHandlerContext) begin end;
    procedure OnAfterTestProcedureRun(Context: TestHandlerContext) begin end;
    procedure OnBeforeTestCaseRun(Context: TestHandlerContext) begin end;
    procedure OnAfterTestCaseRun(Context: TestHandlerContext) begin end;
}

enumextension 59321 "MNC TH Ext 2305" extends TestHandler
{
    value(59321; "MNC TH Value 2305")
    {
        Implementation = ITestHandler = "MNC TH Impl 2305";
    }
}

codeunit 59322 "MNC TH Twice 2305"
{
    Subtype = Test;
    TestHandlers = "MNC TH Value 2305", "MNC TH Value 2305";
}
