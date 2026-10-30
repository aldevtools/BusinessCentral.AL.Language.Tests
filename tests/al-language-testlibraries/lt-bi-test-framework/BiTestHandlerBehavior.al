// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testhandlercontext/testhandlercontext-data-type
// Scope: in-scope
// Fixtures used: none (own log codeunit 81613); own objects 81613 - 81623
// Corpus issue (al-runner test framework probes, 2026-10-30): the behavior of TestHandlers callbacks that BiTestHandler.al does not pin:
// what the callbacks see (Success after asserterror), an error raised inside a callback, Skip in the callbacks where it has no effect,
// two handlers in one TestHandlers list (call order, one handler failing or skipping), and CodeunitName for a codeunit in a namespace.
// Each test codeunit logs the callbacks of its own tests under its own codeunit id; its last test checks the log (the check runs inside the
// last test, so its own callbacks are not in the checked text). Callbacks of the case kind are not called for plain tests (see BiTestHandler.al).
// Not asserted here (a test that fails, or a runner choice, would be needed): Success() is No in OnAfterTestProcedureRun of a failing test
// (observed on the BC 29 SaaS sandbox through the hub); database writes of a callback are kept between tests (hub, no isolation).
// Probe: observed values; every literal asserted below is what BC 29 produced.
// BC versions: 29
#if BC29PLUS

codeunit 81613 "LT BI TFB Log"
{
    SingleInstance = true;

    var
        Entries: Dictionary of [Integer, Text];

    procedure Add(CodeunitId: Integer; Entry: Text)
    var
        Text: Text;
    begin
        if Entries.Get(CodeunitId, Text) then;
        Entries.Set(CodeunitId, Text + Entry + ';');
    end;

    procedure Check(CodeunitId: Integer; Expected: Text)
    var
        Actual: Text;
    begin
        if Entries.Get(CodeunitId, Actual) then;
        Entries.Remove(CodeunitId);
        if Actual <> Expected then
            Error('LT BI TFB log of %1 differs. Expected: %2 Actual: %3', CodeunitId, Expected, Actual);
    end;
}

codeunit 81614 "LT BI TFB Common"
{
    procedure Handle(Prefix: Text; Callback: Text; Context: TestHandlerContext; WithSuccess: Boolean)
    var
        Log: Codeunit "LT BI TFB Log";
        Entry: Text;
        Proc: Text;
    begin
        Proc := Context.ProcedureName();
        Entry := Prefix + '.' + Callback + '(' + Proc;
        if Callback = 'bCU' then
            Entry += Context.CodeunitName();
        if WithSuccess then
            Entry += ',' + Format(Context.Success());
        Log.Add(Context.CodeunitId(), Entry + ')');
        case Context.CodeunitId() of
            81617: // errors
                if (Prefix = 'A') and (((Callback = 'bCU')) or ((Proc = 'BiTfb_T1') and ((Callback = 'bP') or (Callback = 'aP')))) then
                    Error('LT BI TFB error in %1', Callback);
            81618: // two handlers: A fails in bP of T1, A skips T2
                if Prefix = 'A' then begin
                    if (Callback = 'bP') and (Proc = 'BiTfb_T1') then
                        Error('LT BI TFB error in %1', Callback);
                    if (Callback = 'bP') and (Proc = 'BiTfb_T2') then
                        Context.Skip('LT BI TFB skip');
                end;
            81620: // late skips: bCU and aP have no effect
                if ((Callback = 'bCU') or ((Callback = 'aP') and (Proc = 'BiTfb_T1'))) then
                    Context.Skip('LT BI TFB late skip');
        end;
    end;
}

codeunit 81615 "LT BI TFB Handler A" implements ITestHandler
{
    procedure OnBeforeTestCodeunitRun(Context: TestHandlerContext)
    var
        C: Codeunit "LT BI TFB Common";
    begin
        C.Handle('A', 'bCU', Context, false);
    end;

    procedure OnAfterTestCodeunitRun(Context: TestHandlerContext)
    var
        C: Codeunit "LT BI TFB Common";
    begin
        C.Handle('A', 'aCU', Context, true);
    end;

    procedure OnBeforeTestProcedureRun(Context: TestHandlerContext)
    var
        C: Codeunit "LT BI TFB Common";
    begin
        C.Handle('A', 'bP', Context, false);
    end;

    procedure OnAfterTestProcedureRun(Context: TestHandlerContext)
    var
        C: Codeunit "LT BI TFB Common";
    begin
        C.Handle('A', 'aP', Context, true);
    end;

    procedure OnBeforeTestCaseRun(Context: TestHandlerContext)
    var
        C: Codeunit "LT BI TFB Common";
    begin
        C.Handle('A', 'bC', Context, false);
    end;

    procedure OnAfterTestCaseRun(Context: TestHandlerContext)
    var
        C: Codeunit "LT BI TFB Common";
    begin
        C.Handle('A', 'aC', Context, true);
    end;
}

codeunit 81616 "LT BI TFB Handler B" implements ITestHandler
{
    procedure OnBeforeTestCodeunitRun(Context: TestHandlerContext)
    var
        C: Codeunit "LT BI TFB Common";
    begin
        C.Handle('B', 'bCU', Context, false);
    end;

    procedure OnAfterTestCodeunitRun(Context: TestHandlerContext)
    var
        C: Codeunit "LT BI TFB Common";
    begin
        C.Handle('B', 'aCU', Context, true);
    end;

    procedure OnBeforeTestProcedureRun(Context: TestHandlerContext)
    var
        C: Codeunit "LT BI TFB Common";
    begin
        C.Handle('B', 'bP', Context, false);
    end;

    procedure OnAfterTestProcedureRun(Context: TestHandlerContext)
    var
        C: Codeunit "LT BI TFB Common";
    begin
        C.Handle('B', 'aP', Context, true);
    end;

    procedure OnBeforeTestCaseRun(Context: TestHandlerContext)
    var
        C: Codeunit "LT BI TFB Common";
    begin
        C.Handle('B', 'bC', Context, false);
    end;

    procedure OnAfterTestCaseRun(Context: TestHandlerContext)
    var
        C: Codeunit "LT BI TFB Common";
    begin
        C.Handle('B', 'aC', Context, true);
    end;
}

enumextension 81623 "LT BI TFB Handlers" extends TestHandler
{
    value(81623; "LT BI TFB A")
    {
        Implementation = ITestHandler = "LT BI TFB Handler A";
    }
    value(81624; "LT BI TFB B")
    {
        Implementation = ITestHandler = "LT BI TFB Handler B";
    }
}

// Success() after asserterror, and the callbacks around plain tests of one handler.
codeunit 81622 "LT BI TFB Outcome"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHandlers = "LT BI TFB A";

    [Test]
    procedure BiTfb_T1()
    begin
        asserterror Error('LT BI TFB expected');
    end;

    [Test]
    procedure BiTfb_T2()
    begin
    end;

    [Test]
    procedure BiTfb_Z_Verify()
    var
        Log: Codeunit "LT BI TFB Log";
    begin
        Log.Check(81622, 'A.bCU(LT BI TFB Outcome);A.bP(BiTfb_T1);A.aP(BiTfb_T1,Yes);A.bP(BiTfb_T2);A.aP(BiTfb_T2,Yes);A.bP(BiTfb_Z_Verify);');
    end;
}

// An error raised inside a callback (OnBeforeTestCodeunitRun, OnBeforeTestProcedureRun and OnAfterTestProcedureRun of the first test).
codeunit 81617 "LT BI TFB Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHandlers = "LT BI TFB A";

    [Test]
    procedure BiTfb_T1()
    var
        Log: Codeunit "LT BI TFB Log";
    begin
        Log.Add(81617, 'bodyT1');
    end;

    [Test]
    procedure BiTfb_T2()
    begin
    end;

    [Test]
    procedure BiTfb_Z_Verify()
    var
        Log: Codeunit "LT BI TFB Log";
    begin
        Log.Check(81617, 'A.bCU(LT BI TFB Errors);A.bP(BiTfb_T1);bodyT1;A.aP(BiTfb_T1,Yes);A.bP(BiTfb_T2);A.aP(BiTfb_T2,Yes);A.bP(BiTfb_Z_Verify);');
    end;
}

// Two handlers in one TestHandlers list.
codeunit 81618 "LT BI TFB Two"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHandlers = "LT BI TFB A", "LT BI TFB B";

    [Test]
    procedure BiTfb_T1()
    var
        Log: Codeunit "LT BI TFB Log";
    begin
        Log.Add(81618, 'bodyT1');
    end;

    [Test]
    procedure BiTfb_T2()
    var
        Log: Codeunit "LT BI TFB Log";
    begin
        Log.Add(81618, 'bodyT2');
    end;

    [Test]
    procedure BiTfb_T3()
    var
        Log: Codeunit "LT BI TFB Log";
    begin
        Log.Add(81618, 'bodyT3');
    end;

    [Test]
    procedure BiTfb_Z_Verify()
    var
        Log: Codeunit "LT BI TFB Log";
    begin
        Log.Check(81618, 'A.bCU(LT BI TFB Two);B.bCU(LT BI TFB Two);A.bP(BiTfb_T1);B.bP(BiTfb_T1);bodyT1;A.aP(BiTfb_T1,Yes);B.aP(BiTfb_T1,Yes);A.bP(BiTfb_T2);B.bP(BiTfb_T2);A.bP(BiTfb_T3);B.bP(BiTfb_T3);bodyT3;A.aP(BiTfb_T3,Yes);B.aP(BiTfb_T3,Yes);A.bP(BiTfb_Z_Verify);B.bP(BiTfb_Z_Verify);');
    end;
}

// The same two handlers in the other order.
codeunit 81619 "LT BI TFB Reverse"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHandlers = "LT BI TFB B", "LT BI TFB A";

    [Test]
    procedure BiTfb_T1()
    begin
    end;

    [Test]
    procedure BiTfb_Z_Verify()
    var
        Log: Codeunit "LT BI TFB Log";
    begin
        Log.Check(81619, 'B.bCU(LT BI TFB Reverse);A.bCU(LT BI TFB Reverse);B.bP(BiTfb_T1);A.bP(BiTfb_T1);B.aP(BiTfb_T1,Yes);A.aP(BiTfb_T1,Yes);B.bP(BiTfb_Z_Verify);A.bP(BiTfb_Z_Verify);');
    end;
}

// Skip in OnBeforeTestCodeunitRun and in OnAfterTestProcedureRun.
codeunit 81620 "LT BI TFB Late Skip"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHandlers = "LT BI TFB A";

    [Test]
    procedure BiTfb_T1()
    var
        Log: Codeunit "LT BI TFB Log";
    begin
        Log.Add(81620, 'bodyT1');
    end;

    [Test]
    procedure BiTfb_Z_Verify()
    var
        Log: Codeunit "LT BI TFB Log";
    begin
        Log.Check(81620, 'A.bCU(LT BI TFB Late Skip);A.bP(BiTfb_T1);bodyT1;A.aP(BiTfb_T1,Yes);A.bP(BiTfb_Z_Verify);');
    end;
}

#endif
