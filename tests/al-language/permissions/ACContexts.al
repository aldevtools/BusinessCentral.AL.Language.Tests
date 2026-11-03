// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-overview
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: DataSourceContext (AppId, CodeunitId) and TestHandlerContext (CodeunitId, CodeunitName, ProcedureName, TestCaseName, Success, Skip) used on a variable outside any handler (BC 29 and later; BC 27 and 28 reject the types, see must-not-compile cases 0961 and 0962). The types are only handed to a handler by the test framework (the symbols that declare the handler enum and ITestContext are not public); this pins the result of every member on a variable of the type that is not inside a handler.
//   Settles #626 items 9, 10, 17 and #627 items 14 to 19 as far as they are reachable from AL.
// BC versions: 29
//   DataSourceContext.AppId() is not probed: a test that calls it ends the test session.
//   Each member is probed in a codeunit of its own: a member that ends the test session would otherwise hide the others.

#if BC29PLUS
codeunit 77506 "LT AC Contexts DsCodeunit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_DataSourceContext_CodeunitId()
    var
        Observer: Codeunit "Probe Observer";
        Ctx: DataSourceContext;
    begin
        if not TryRead(Ctx, Observer) then
            Observer.ObserveError('codeunitid_err');
        Observer.Expect('codeunitid_err|text', 'The expression System.Func`1[System.Int32] cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavValue value.');
        Observer.Expect('codeunitid_err|code', 'TypeConversion');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRead(var Ctx: DataSourceContext; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('codeunitid', Format(Ctx.CodeunitId()));
    end;
}

codeunit 77541 "LT AC Contexts ThCodeunitId"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_TestHandlerContext_CodeunitId()
    var
        Observer: Codeunit "Probe Observer";
        Ctx: TestHandlerContext;
    begin
        if not TryRead(Ctx, Observer) then
            Observer.ObserveError('codeunitid_err');
        Observer.Expect('codeunitid', '0');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRead(var Ctx: TestHandlerContext; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('codeunitid', Format(Ctx.CodeunitId()));
    end;
}

codeunit 77543 "LT AC Contexts ThCodeunitName"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_TestHandlerContext_CodeunitName()
    var
        Observer: Codeunit "Probe Observer";
        Ctx: TestHandlerContext;
    begin
        if not TryRead(Ctx, Observer) then
            Observer.ObserveError('codeunitname_err');
        Observer.Expect('codeunitname', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRead(var Ctx: TestHandlerContext; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('codeunitname', Ctx.CodeunitName());
    end;
}

codeunit 77544 "LT AC Contexts ThProcName"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_TestHandlerContext_ProcedureName()
    var
        Observer: Codeunit "Probe Observer";
        Ctx: TestHandlerContext;
    begin
        if not TryRead(Ctx, Observer) then
            Observer.ObserveError('procedurename_err');
        Observer.Expect('procedurename', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRead(var Ctx: TestHandlerContext; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('procedurename', Ctx.ProcedureName());
    end;
}

codeunit 77545 "LT AC Contexts ThCaseName"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_TestHandlerContext_TestCaseName()
    var
        Observer: Codeunit "Probe Observer";
        Ctx: TestHandlerContext;
    begin
        if not TryRead(Ctx, Observer) then
            Observer.ObserveError('testcasename_err');
        Observer.Expect('testcasename', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRead(var Ctx: TestHandlerContext; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('testcasename', Ctx.TestCaseName());
    end;
}

codeunit 77546 "LT AC Contexts ThSuccess"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_TestHandlerContext_Success()
    var
        Observer: Codeunit "Probe Observer";
        Ctx: TestHandlerContext;
    begin
        if not TryRead(Ctx, Observer) then
            Observer.ObserveError('success_err');
        Observer.Expect('success', 'No');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRead(var Ctx: TestHandlerContext; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('success', Format(Ctx.Success()));
    end;
}

codeunit 77542 "LT AC Contexts Skip"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_TestHandlerContext_Skip_Outside()
    var
        Observer: Codeunit "Probe Observer";
        Ctx: TestHandlerContext;
    begin
        if not TrySkip(Ctx) then
            Observer.ObserveError('skip_err')
        else
            Observer.Observe('skip_returned', 'yes');
        Observer.Expect('skip_returned', 'yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySkip(var Ctx: TestHandlerContext)
    begin
        Ctx.Skip('probe');
    end;
}
#endif
