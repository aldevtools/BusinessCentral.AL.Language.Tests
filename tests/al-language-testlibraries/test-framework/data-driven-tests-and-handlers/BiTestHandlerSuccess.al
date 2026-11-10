// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testhandlercontext/testhandlercontext-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT BI DD Source (81602) and LT BI DD Case Data (81601) from BiDataDriven.al; own objects 81599, 81696 - 81698
// Corpus issue (al-runner 7181): what TestHandlerContext.Success() returns in every Before and After callback.
// Observed on BC 29.0 (CI run 42641553497): every Before callback (OnBeforeTestCodeunitRun, OnBeforeTestProcedureRun,
// OnBeforeTestCaseRun) gives false; OnAfterTestProcedureRun and OnAfterTestCaseRun give true after a passing procedure or case.
// A failing test cannot stay in CI, so these values were observed on a probe run and are not asserted: a codeunit with a
// failing procedure, a passing procedure and a data-driven procedure whose case 'beta' fails logged
//   O.bCU(||No);O.bP(BiTs_A_Fail||No);O.aP(BiTs_A_Fail||No);O.bP(BiTs_B_Pass||No);O.aP(BiTs_B_Pass||Yes);O.bP(BiTs_Z_Rows||No);
//   O.bC(BiTs_Z_Rows|alpha|No);O.aC(BiTs_Z_Rows|alpha|Yes);O.bC(BiTs_Z_Rows|beta|No);O.aC(BiTs_Z_Rows|beta|No);O.bC(BiTs_Z_Rows|gamma|No);
// so OnAfterTestProcedureRun and OnAfterTestCaseRun give false after a failing procedure or case.
// Not observed: OnAfterTestCodeunitRun (it runs after the last test of the codeunit, so no test in the codeunit can read it),
// and the Default handler's values.
// BC versions: 29 (the TestHandler enum, ITestHandler and TestHandlerContext need runtime 18.0, so BC 27.5 and 28.5 cannot compile them; see must-not-compile case 0996)
#if BC29PLUS
codeunit 81696 "LT BI HS Log"
{
    SingleInstance = true;

    var
        Entries: Dictionary of [Integer, Text];

    procedure Add(CodeunitId: Integer; Entry: Text)
    var
        Existing: Text;
    begin
        if Entries.Get(CodeunitId, Existing) then;
        Entries.Set(CodeunitId, Existing + Entry + ';');
    end;

    procedure Take(CodeunitId: Integer): Text
    var
        Existing: Text;
    begin
        if Entries.Get(CodeunitId, Existing) then;
        exit(Existing);
    end;
}

codeunit 81697 "LT BI HS Handler" implements ITestHandler
{
    procedure OnBeforeTestCodeunitRun(Context: TestHandlerContext)
    begin
        Handle('bCU', Context);
    end;

    procedure OnAfterTestCodeunitRun(Context: TestHandlerContext)
    begin
        Handle('aCU', Context);
    end;

    procedure OnBeforeTestProcedureRun(Context: TestHandlerContext)
    begin
        Handle('bP', Context);
    end;

    procedure OnAfterTestProcedureRun(Context: TestHandlerContext)
    begin
        Handle('aP', Context);
    end;

    procedure OnBeforeTestCaseRun(Context: TestHandlerContext)
    begin
        Handle('bC', Context);
    end;

    procedure OnAfterTestCaseRun(Context: TestHandlerContext)
    begin
        Handle('aC', Context);
    end;

    local procedure Handle(Callback: Text; Context: TestHandlerContext)
    var
        Log: Codeunit "LT BI HS Log";
    begin
        Log.Add(Context.CodeunitId(), 'O.' + Callback + '(' + Context.ProcedureName() + '|' + Context.TestCaseName() + '|' + Format(Context.Success()) + ')');
    end;
}

enumextension 81698 "LT BI HS Handler" extends TestHandler
{
    value(81698; "LT BI HS Handler")
    {
        Implementation = ITestHandler = "LT BI HS Handler";
    }
}

// Tests that pass: plain procedures, one with asserterror, and a data-driven procedure whose cases pass.
codeunit 81599 "LT BI HS Pass"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHandlers = "LT BI HS Handler";

    [Test]
    procedure BiTs_A_Plain()
    begin
    end;

    [Test]
    procedure BiTs_B_AssertError()
    begin
        asserterror Error('LT BI HS expected');
    end;

    [TestDataSource(81602, 'Set1')]
    procedure BiTs_Z_Rows(Context: Interface ITestContext)
    var
        Log: Codeunit "LT BI HS Log";
        Observer: Codeunit "Probe Observer";
        CaseData: Interface "LT BI DD Case Data";
    begin
        CaseData := Context as "LT BI DD Case Data";
        if CaseData.CaseText() = 'gamma' then begin
            Observer.Observe('log', Log.Take(81599));
            Observer.Expect('log', 'O.bCU(||No);O.bP(BiTs_A_Plain||No);O.aP(BiTs_A_Plain||Yes);O.bP(BiTs_B_AssertError||No);O.aP(BiTs_B_AssertError||Yes);O.bP(BiTs_Z_Rows||No);O.bC(BiTs_Z_Rows|alpha|No);O.aC(BiTs_Z_Rows|alpha|Yes);O.bC(BiTs_Z_Rows|beta|No);O.aC(BiTs_Z_Rows|beta|Yes);O.bC(BiTs_Z_Rows|gamma|No);');
            Observer.Verify();
        end;
    end;
}

#endif
