namespace ALLanguage.IsolationProbe;

// A test codeunit with RequiredTestIsolation = Function, run under every test runner of this app
// (Function 61300, Codeunit 61301, Disabled 61304, no property 61305) (AL Runner issues 5607 and
// 5609): does the codeunit's RequiredTestIsolation or the runner's TestIsolation decide what is
// rolled back? "LT SD Isol Req Function Reader" (61313, the next id) reads the row afterwards.
//   Q1 replaces every RF- row by RF-1 and passes.
//   Q2 states whether RF-1 is still there in the next test.
// Q2 expects the reading of TestIsolation = Disabled and Codeunit (no rollback between the tests of a
// codeunit). A red row is the measurement: its message gives what Q2 saw.
codeunit 61312 "LT SD Isol Req Function"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    [Test]
    procedure Q1_InsertsRF1()
    var
        Row: Record "LT SD Isol Row";
    begin
        Row.SetFilter("Key", 'RF-*');
        Row.DeleteAll();
        Row.Reset();
        Row."Key" := 'RF-1';
        Row.Insert();
    end;

    [Test]
    procedure Q2_NextTestSeesRF1()
    var
        Row: Record "LT SD Isol Row";
    begin
        if not Row.Get('RF-1') then
            Error('Q2 under RequiredTestIsolation = Function: expected RF-1=Yes, observed RF-1=No (rolled back after Q1)');
    end;
}
