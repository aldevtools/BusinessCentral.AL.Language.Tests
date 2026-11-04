// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures used: Test Page Run Handler Row (60748), Test Page Run Target (60749), Assert (60021)
//
// How long a TestPage.Trap() lasts when nothing consumes it. A trap belongs to the TestPage
// variable that set it, so it must end when that variable goes out of scope — otherwise the
// next Page.Run of that page is captured into a variable nobody can read any more, and the
// [PageHandler] the test declared never runs.
//
//   1. Control: with no trap set, the [PageHandler] runs for a non-modal Page.Run.
//   2. A trap set on a LOCAL TestPage in a local procedure ends when that procedure returns:
//      the caller's Page.Run then reaches the [PageHandler].
//   3. The other side of that boundary: a trap set through a VAR parameter belongs to the
//      caller's variable, so it survives the callee's return and captures the page.
//   4. A trap whose page was assigned out of the local variable before it went out of scope
//      survives too, because another variable still holds the page.

codeunit 67150 "Test Page Trap Scope Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Test Page Run Handler Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();
    end;

    [Test]
    [HandlerFunctions('TrapScopePageHandler')]
    procedure HandlerRunsWhenNoTrapIsSet()
    var
        Row: Record "Test Page Run Handler Row";
        Stamp: Record "Test Page Run Handler Row";
    begin
        Initialize();

        Row.Get('A');
        Page.Run(Page::"Test Page Run Target", Row);

        Assert.IsTrue(Stamp.Get('HANDLER'), 'with no trap set, the [PageHandler] must run');
    end;

    [Test]
    [HandlerFunctions('TrapScopePageHandler')]
    procedure TrapOnALocalTestPageEndsWhenItsProcedureReturns()
    var
        Row: Record "Test Page Run Handler Row";
        Stamp: Record "Test Page Run Handler Row";
    begin
        Initialize();

        TrapOnALocalVariable();
        Row.Get('A');
        Page.Run(Page::"Test Page Run Target", Row);

        Assert.IsTrue(Stamp.Get('HANDLER'),
            'a trap set on a local TestPage must end with its procedure, so the [PageHandler] runs');
    end;

    [Test]
    procedure TrapSetThroughAVarParameterSurvivesTheCallee()
    var
        Row: Record "Test Page Run Handler Row";
        Stamp: Record "Test Page Run Handler Row";
        Target: TestPage "Test Page Run Target";
    begin
        Initialize();

        TrapThroughVar(Target);
        Row.Get('A');
        // No handler is declared: if the trap had ended, this Page.Run would be refused as unhandled UI.
        Page.Run(Page::"Test Page Run Target", Row);

        Assert.AreEqual('Alpha', Target.Descr.Value(),
            'the trap set through a var parameter must capture the page into the caller''s variable');
        Assert.IsFalse(Stamp.Get('HANDLER'), 'no handler may have run for a trapped page');
        Target.Close();
    end;

    [Test]
    procedure TrapAssignedOutOfALocalVariableSurvives()
    var
        Row: Record "Test Page Run Handler Row";
        Target: TestPage "Test Page Run Target";
    begin
        Initialize();

        TrapAndAssignOut(Target);
        Row.Get('A');
        // No handler is declared: if the trap had ended, this Page.Run would be refused as unhandled UI.
        Page.Run(Page::"Test Page Run Target", Row);

        Assert.AreEqual('Alpha', Target.Descr.Value(),
            'a trap whose page is still held by another variable must capture the page');
        Target.Close();
    end;

    local procedure TrapOnALocalVariable()
    var
        Target: TestPage "Test Page Run Target";
    begin
        Target.Trap();
    end;

    local procedure TrapThroughVar(var Target: TestPage "Test Page Run Target")
    begin
        Target.Trap();
    end;

    local procedure TrapAndAssignOut(var Out: TestPage "Test Page Run Target")
    var
        LocalPage: TestPage "Test Page Run Target";
    begin
        LocalPage.Trap();
        Out := LocalPage;
    end;

    [PageHandler]
    procedure TrapScopePageHandler(var Target: TestPage "Test Page Run Target")
    var
        Stamp: Record "Test Page Run Handler Row";
    begin
        Stamp.Init();
        Stamp."No." := 'HANDLER';
        Stamp.Descr := CopyStr(Target.Descr.Value(), 1, MaxStrLen(Stamp.Descr));
        if not Stamp.Insert() then
            Stamp.Modify();
    end;
}
