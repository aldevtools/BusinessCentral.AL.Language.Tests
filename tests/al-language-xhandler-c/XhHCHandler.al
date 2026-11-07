// Fixture of the cross-app DefaultTestHandler probes (al-runner 7181): a default test handler declared in an app that holds no test codeunit.
// It logs every callback as <tag>.<callback>(procedure|case|n=<its call count>[|Success]) into "XH Log", keyed by the test codeunit id.
#if BC29PLUS
codeunit 97840 "XH Handler C" implements ITestHandler
{
    var
        Counter: Integer;

    procedure OnBeforeTestCodeunitRun(Context: TestHandlerContext)
    begin
        Handle('bCU', Context, false);
    end;

    procedure OnAfterTestCodeunitRun(Context: TestHandlerContext)
    begin
        Handle('aCU', Context, true);
    end;

    procedure OnBeforeTestProcedureRun(Context: TestHandlerContext)
    begin
        Handle('bP', Context, false);
    end;

    procedure OnAfterTestProcedureRun(Context: TestHandlerContext)
    begin
        Handle('aP', Context, true);
    end;

    procedure OnBeforeTestCaseRun(Context: TestHandlerContext)
    begin
        Handle('bC', Context, false);
    end;

    procedure OnAfterTestCaseRun(Context: TestHandlerContext)
    begin
        Handle('aC', Context, true);
    end;

    local procedure Handle(Callback: Text; Context: TestHandlerContext; WithSuccess: Boolean)
    var
        Log: Codeunit "XH Log";
        Entry: Text;
    begin
        Counter += 1;
        Entry := 'HC.' + Callback + '(' + Context.ProcedureName() + '|' + Context.TestCaseName() + '|n=' + Format(Counter);
        if WithSuccess then
            Entry += '|' + Format(Context.Success());
        Log.Add(Context.CodeunitId(), Entry + ')');
    end;
}

enumextension 97841 "XH Handler C" extends DefaultTestHandler
{
    value(97841; "XH Handler C")
    {
        Implementation = ITestHandler = "XH Handler C";
    }
}
#endif
