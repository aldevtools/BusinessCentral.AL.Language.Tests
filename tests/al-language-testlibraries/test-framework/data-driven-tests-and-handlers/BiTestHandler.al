// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testhandlercontext/testhandlercontext-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 81580, 81583 - 81585
// Corpus issue 627 items 14-19 (BC 29 test framework): a test codeunit that names a test handler (codeunit property
// TestHandlers, an enum value of the system enum TestHandler that implements ITestHandler). Observed: which ITestHandler callbacks
// run and in which order, what TestHandlerContext.CodeunitId, CodeunitName, ProcedureName, TestCaseName and (in the After
// callbacks) Success return in each, and the effect of Skip(Reason) called in OnBeforeTestProcedureRun: the test is reported as
// skipped, its body does not run and OnAfterTestProcedureRun is not called for it. The types are declared by the BC 29 System app
// (namespaces System.Testability and System.Test). Data-driven tests ([TestDataSource]) are in BiTestDataSource.al (not run:
// they end the session on the Linux CI). Not covered: Success() after a failing test (it needs a test that fails), and
// OnAfterTestCodeunitRun (it runs after the last test, so no test of the codeunit can see it; a SingleInstance log read by a
// second test codeunit came back empty in run 39225437143).
// Probe: observed values; every literal asserted below is what the BC tier produced (corpus CI job test-testlibraries,
// run 39225437143 on BC 29.0).
// BC versions: 29
#if BC29PLUS

codeunit 81580 "LT BI TF Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

codeunit 81583 "LT BI TF Handler" implements ITestHandler
{
    procedure OnBeforeTestCodeunitRun(Context: TestHandlerContext)
    begin
        LogCall('beforeCodeunit', Context, false);
    end;

    procedure OnAfterTestCodeunitRun(Context: TestHandlerContext)
    begin
        LogCall('afterCodeunit', Context, true);
    end;

    procedure OnBeforeTestProcedureRun(Context: TestHandlerContext)
    begin
        LogCall('beforeProc', Context, false);
        if Context.ProcedureName() = 'BiTf_B_SkipMe' then
            Context.Skip('LT BI skip reason');
    end;

    procedure OnAfterTestProcedureRun(Context: TestHandlerContext)
    begin
        LogCall('afterProc', Context, true);
    end;

    procedure OnBeforeTestCaseRun(Context: TestHandlerContext)
    begin
        LogCall('beforeCase', Context, false);
    end;

    procedure OnAfterTestCaseRun(Context: TestHandlerContext)
    begin
        LogCall('afterCase', Context, true);
    end;

    local procedure LogCall(Callback: Text; Context: TestHandlerContext; WithSuccess: Boolean)
    var
        Log: Codeunit "LT BI TF Log";
        Entry: Text;
    begin
        Entry := Callback + '(cu=' + Format(Context.CodeunitId()) + ',name=' + Context.CodeunitName() + ',proc=' + Context.ProcedureName() + ',case=' + Context.TestCaseName();
        if WithSuccess then
            Entry += ',success=' + Format(Context.Success());
        Log.Add(Entry + ')');
    end;
}

enumextension 81584 "LT BI TF Handler" extends TestHandler
{
    value(81584; "LT BI TF Handler")
    {
        Implementation = ITestHandler = "LT BI TF Handler";
    }
}

codeunit 81585 "LT BI TF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHandlers = "LT BI TF Handler";

    [Test]
    procedure BiTf_A_Plain()
    var
        Log: Codeunit "LT BI TF Log";
    begin
        Log.Add('body A');
    end;

    [Test]
    procedure BiTf_B_SkipMe()
    var
        Log: Codeunit "LT BI TF Log";
    begin
        Log.Add('body B');
    end;

    // Runs last in this codeunit: everything logged so far, from the first callback on.
    [Test]
    procedure BiTf_D_Observe()
    var
        Log: Codeunit "LT BI TF Log";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', Log.Take());
        // BiTf_B_SkipMe: 'body B' is missing and no afterProc follows its beforeProc (JUnit reports it as skipped).
        Observer.Expect('log', 'beforeCodeunit(cu=81585,name=LT BI TF Tests,proc=,case=);beforeProc(cu=81585,name=LT BI TF Tests,proc=BiTf_A_Plain,case=);body A;afterProc(cu=81585,name=LT BI TF Tests,proc=BiTf_A_Plain,case=,success=Yes);beforeProc(cu=81585,name=LT BI TF Tests,proc=BiTf_B_SkipMe,case=);beforeProc(cu=81585,name=LT BI TF Tests,proc=BiTf_D_Observe,case=);');
        Observer.Verify();
    end;
}

#endif
