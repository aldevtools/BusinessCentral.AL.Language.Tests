// @expect AL0383 | The option value 'No Such Handler' is not defined on field 'TestHandler'.
// @from 29
// @appjson {"runtime": "18.0"}
// TestHandlers names an enum value that the system enum TestHandler does not have.
codeunit 59313 "MNC TH Unknown 2301"
{
    Subtype = Test;
    TestHandlers = "No Such Handler";
}
