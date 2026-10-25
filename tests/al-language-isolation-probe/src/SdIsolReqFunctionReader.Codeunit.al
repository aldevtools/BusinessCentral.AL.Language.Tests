namespace ALLanguage.IsolationProbe;

// What the NEXT test codeunit sees of the row "LT SD Isol Req Function" (61312, RequiredTestIsolation
// = Function) inserted (AL Runner issues 5607 and 5609). This codeunit sets no RequiredTestIsolation.
// N1 expects the reading of TestIsolation = Disabled (the row stays). A red row is the measurement.
codeunit 61313 "LT SD Isol Req Function Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure N1_NextCodeunitSeesRF1()
    var
        Row: Record "LT SD Isol Row";
    begin
        if not Row.Get('RF-1') then
            Error('N1 after RequiredTestIsolation = Function: expected RF-1=Yes, observed RF-1=No (rolled back at the end of codeunit 61312)');
    end;
}
