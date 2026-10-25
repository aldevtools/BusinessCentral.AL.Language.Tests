namespace ALLanguage.IsolationProbe;

// A test codeunit with RequiredTestIsolation = Disabled, run under every test runner of this app
// (Function 61300, Codeunit 61301, Disabled 61304, no property 61305) (AL Runner issues 5607 and
// 5609): does the codeunit's RequiredTestIsolation or the runner's TestIsolation decide what is
// rolled back? "LT SD Isol Req Disabled Reader" (61315, the next id) reads the row afterwards.
//   Q1 replaces every RD- row by RD-1 and passes.
//   Q2 states whether RD-1 is still there in the next test.
// Q2 expects the reading of TestIsolation = Disabled and Codeunit (no rollback between the tests of a
// codeunit). A red row is the measurement: its message gives what Q2 saw.
codeunit 61314 "LT SD Isol Req Disabled"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    [Test]
    procedure Q1_InsertsRD1()
    var
        Row: Record "LT SD Isol Row";
    begin
        Row.SetFilter("Key", 'RD-*');
        Row.DeleteAll();
        Row.Reset();
        Row."Key" := 'RD-1';
        Row.Insert();
    end;

    [Test]
    procedure Q2_NextTestSeesRD1()
    var
        Row: Record "LT SD Isol Row";
    begin
        if not Row.Get('RD-1') then
            Error('Q2 under RequiredTestIsolation = Disabled: expected RD-1=Yes, observed RD-1=No (rolled back after Q1)');
    end;
}
