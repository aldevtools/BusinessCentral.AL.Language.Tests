// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures used: Test Page Run Handler Row (60748), Test Page Run Target (60749), Assert (60021)
//
// How long an unconsumed TestPage.Trap() lasts when SEVERAL local TestPage variables share the
// page (B := A). Codeunit 67150 covers one local; here no single variable is the page's last
// reference, so the trap must end only when all of them go out of scope together — and must
// survive when any one of them was assigned out to the caller first.
//
//   1. Control: with no trap set, the [PageHandler] runs for a non-modal Page.Run.
//   2. Two locals share the trapped page; both end with the procedure, so the trap ends and the
//      caller's Page.Run reaches the [PageHandler].
//   3. The same with three locals.
//   4. Two locals share the trapped page and one is assigned out to a var parameter before the
//      procedure returns: the caller's variable still holds the page, so the trap survives and
//      captures the page.

codeunit 67151 "Test Page Trap Shared Scope"
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
    [HandlerFunctions('TrapSharedScopePageHandler')]
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
    [HandlerFunctions('TrapSharedScopePageHandler')]
    procedure TrapSharedByTwoLocalsEndsWhenTheirProcedureReturns()
    var
        Row: Record "Test Page Run Handler Row";
        Stamp: Record "Test Page Run Handler Row";
    begin
        Initialize();

        TrapOnTwoLocals();
        Row.Get('A');
        Page.Run(Page::"Test Page Run Target", Row);

        Assert.IsTrue(Stamp.Get('HANDLER'),
            'a trap shared by two local TestPage variables must end with their procedure, so the [PageHandler] runs');
    end;

    [Test]
    [HandlerFunctions('TrapSharedScopePageHandler')]
    procedure TrapSharedByThreeLocalsEndsWhenTheirProcedureReturns()
    var
        Row: Record "Test Page Run Handler Row";
        Stamp: Record "Test Page Run Handler Row";
    begin
        Initialize();

        TrapOnThreeLocals();
        Row.Get('A');
        Page.Run(Page::"Test Page Run Target", Row);

        Assert.IsTrue(Stamp.Get('HANDLER'),
            'a trap shared by three local TestPage variables must end with their procedure, so the [PageHandler] runs');
    end;

    [Test]
    procedure TrapSharedByTwoLocalsSurvivesWhenOneIsAssignedOut()
    var
        Row: Record "Test Page Run Handler Row";
        Stamp: Record "Test Page Run Handler Row";
        Target: TestPage "Test Page Run Target";
    begin
        Initialize();

        TrapOnTwoLocalsAndAssignOut(Target);
        Row.Get('A');
        // No handler is declared: if the trap had ended, this Page.Run would be refused as unhandled UI.
        Page.Run(Page::"Test Page Run Target", Row);

        Assert.AreEqual('Alpha', Target.Descr.Value(),
            'a trap whose page is still held by the caller''s variable must capture the page');
        Assert.IsFalse(Stamp.Get('HANDLER'), 'no handler may have run for a trapped page');
        Target.Close();
    end;

    local procedure TrapOnTwoLocals()
    var
        First: TestPage "Test Page Run Target";
        Second: TestPage "Test Page Run Target";
    begin
        First.Trap();
        Second := First;
    end;

    local procedure TrapOnThreeLocals()
    var
        First: TestPage "Test Page Run Target";
        Second: TestPage "Test Page Run Target";
        Third: TestPage "Test Page Run Target";
    begin
        First.Trap();
        Second := First;
        Third := Second;
    end;

    local procedure TrapOnTwoLocalsAndAssignOut(var Out: TestPage "Test Page Run Target")
    var
        First: TestPage "Test Page Run Target";
        Second: TestPage "Test Page Run Target";
    begin
        First.Trap();
        Second := First;
        Out := Second;
    end;

    [PageHandler]
    procedure TrapSharedScopePageHandler(var Target: TestPage "Test Page Run Target")
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
