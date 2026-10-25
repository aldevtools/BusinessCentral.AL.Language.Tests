namespace ALLanguage.IsolationProbe;

// What the NEXT test codeunit sees of the row "LT SD Isol Req Codeunit" (61316, RequiredTestIsolation
// = Codeunit) inserted (AL Runner issues 5607 and 5609). This codeunit sets no RequiredTestIsolation.
// N1 expects the reading of TestIsolation = Disabled (the row stays). A red row is the measurement.
codeunit 61317 "LT SD Isol Req Codeunit Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure N1_NextCodeunitSeesRC1()
    var
        Row: Record "LT SD Isol Row";
    begin
        if not Row.Get('RC-1') then
            Error('N1 after RequiredTestIsolation = Codeunit: expected RC-1=Yes, observed RC-1=No (rolled back at the end of codeunit 61316)');
    end;
}
