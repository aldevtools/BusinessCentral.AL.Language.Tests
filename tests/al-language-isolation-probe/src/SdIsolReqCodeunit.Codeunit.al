namespace ALLanguage.IsolationProbe;

// A test codeunit with RequiredTestIsolation = Codeunit, run under every test runner of this app
// (Function 61300, Codeunit 61301, Disabled 61304, no property 61305) (AL Runner issues 5607 and
// 5609): does the codeunit's RequiredTestIsolation or the runner's TestIsolation decide what is
// rolled back? "LT SD Isol Req Codeunit Reader" (61317, the next id) reads the row afterwards.
//   Q1 replaces every RC- row by RC-1 and passes.
//   Q2 states whether RC-1 is still there in the next test.
// Q2 expects the reading of TestIsolation = Disabled and Codeunit (no rollback between the tests of a
// codeunit). A red row is the measurement: its message gives what Q2 saw.
codeunit 61316 "LT SD Isol Req Codeunit"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    [Test]
    procedure Q1_InsertsRC1()
    var
        Row: Record "LT SD Isol Row";
    begin
        Row.SetFilter("Key", 'RC-*');
        Row.DeleteAll();
        Row.Reset();
        Row."Key" := 'RC-1';
        Row.Insert();
    end;

    [Test]
    procedure Q2_NextTestSeesRC1()
    var
        Row: Record "LT SD Isol Row";
    begin
        if not Row.Get('RC-1') then
            Error('Q2 under RequiredTestIsolation = Codeunit: expected RC-1=Yes, observed RC-1=No (rolled back after Q1)');
    end;
}
