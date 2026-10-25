namespace ALLanguage.IsolationProbe;

// What the NEXT test codeunit sees of the row "LT SD Isol Req Disabled" (61314, RequiredTestIsolation
// = Disabled) inserted (AL Runner issues 5607 and 5609). This codeunit sets no RequiredTestIsolation.
// N1 expects the reading of TestIsolation = Disabled (the row stays). A red row is the measurement.
codeunit 61315 "LT SD Isol Req Disabled Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure N1_NextCodeunitSeesRD1()
    var
        Row: Record "LT SD Isol Row";
    begin
        if not Row.Get('RD-1') then
            Error('N1 after RequiredTestIsolation = Disabled: expected RD-1=Yes, observed RD-1=No (rolled back at the end of codeunit 61314)');
    end;
}
