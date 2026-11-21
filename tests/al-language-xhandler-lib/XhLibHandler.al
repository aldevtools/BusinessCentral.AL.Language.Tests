// Fixture of the default-handler Success probe (al-runner 7181): a default test handler in the XHandler Lib app that logs
// TestHandlerContext.Success() in every callback, Before callbacks included, of test codeunit 81599 (and only that one) into
// "XH Lib Log", read by BiTestHandlerSuccess.al BiTs_Zz_DefaultHandlerSuccess. The XHandler A, C and D handlers do not read
// Success in their Before callbacks, so they cannot answer it.
// Ids: the app's name sorts after the names of XHandler A, C and D and its enum value id is above theirs, so the order of the
// default handlers by app name and by id stays the same (BiTestHandlerCrossApp.al).
// singleinstance-shared-on-purpose: "XH Lib Log" is written by this handler while codeunit 81599 runs and read back by that codeunit's last test.
#if BC29PLUS
codeunit 97848 "XH Lib Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    begin
        exit(Entries);
    end;
}

codeunit 97847 "XH Handler Lib" implements ITestHandler
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
        Log: Codeunit "XH Lib Log";
    begin
        if Context.CodeunitId() <> 81599 then
            exit;
        Log.Add('L.' + Callback + '(' + Context.ProcedureName() + '|' + Context.TestCaseName() + '|' + Format(Context.Success()) + ')');
    end;
}

enumextension 97849 "XH Handler Lib" extends DefaultTestHandler
{
    value(97849; "XH Handler Lib")
    {
        Implementation = ITestHandler = "XH Handler Lib";
    }
}
#endif
