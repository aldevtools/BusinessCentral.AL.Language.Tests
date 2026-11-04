// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testaction/testaction-invoke-method
//                   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testaction/testaction-visible-method
//                   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testaction/testaction-enabled-method
// Scope: in-scope (Cloud-compatible) -- every member is driven from a [Test] with no client
// Fixtures used: TPAR Row (60581), TPAR Host (60582); shared Assert (60021)
// BC versions: 27.0+ (TestAction is runtime 1.0; every version in this matrix has it)
//
/// <summary>
/// CLAIM: what Visible and Enabled do to an action a test reaches through a TestPage. Two
/// results, and they are not the same result:
///
///   Visible = false  hides the action.  It stays on the page and Invoke() still runs
///                    its OnAction trigger. Only Visible() answers false.
///   Enabled = false  DISABLES the action. It stays on the page and stays visible, and
///                    Invoke() neither errors nor runs the trigger -- it does nothing.
///
/// Both were measured before they were written, on BC 28.4 (OnPrem w1 container), by a probe
/// whose every test failed on purpose so its failure text reported what really happened. The
/// second result is the surprising one: Invoke() on a disabled action is a SILENT NO-OP. It
/// does not raise, so a test that invokes a disabled action and then asserts the effect fails
/// one step later, complaining about the effect rather than about the action.
///
/// The first result is worth pinning because the neighbouring surfaces do NOT behave this
/// way. A page CONTROL, and a subpage PART, whose Visible is the compile-time literal false
/// are dead-code-eliminated: they are not on the runtime page at all, and reaching one raises
/// "not found on the page" (codeunit 60346 measures that for parts). An ACTION is not. Same
/// property, same spelling, different treatment -- so an implementation that generalises the
/// control rule to actions is wrong in a way nothing else here would catch.
///
/// The suite is written as PAIRS. An implementation that refused every hidden or disabled
/// action would pass a negative-only suite, and one that resolved and ran everything would
/// pass a positive-only suite, so each arm is paired against one differing in a single
/// property spelling:
///
///   Visible = false                 vs  Visible = a page variable that is false
///   inside a group Visible = false  vs  an action outside any group
///   Enabled = false                 vs  Enabled = a page variable that is false
///   a hidden action                 vs  the same page's plain action, after it
///
/// NOT EXPRESSIBLE HERE, and worth recording because it looks like it should be: there is no
/// TestPage.GetAction(Id) in AL. TestPage has a GetField(Id) taking a page control id
/// (deprecated, warning AL0667) and NO action counterpart -- the AL compiler's own builtin
/// member table for the TestPage type, in Microsoft.Dynamics.Nav.CodeAnalysis.dll 28.4, lists
/// 30 members including TestPage_GetField and TestPage_GetField_Id and nothing named
/// TestPage_GetAction, and the published TestPage method list agrees. An action is reachable
/// from AL only by NAME, which the compiler resolves to the action's id at compile time. So
/// "what does BC do with an action id outside the page's action id space" cannot be asked
/// from AL at all, and every question this file asks is about an action the page DECLARES.
/// </summary>

codeunit 60583 "TPAR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TPAR Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedOneRow()
    var
        Row: Record "TPAR Row";
    begin
        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();
    end;

    // The positive control. An action declaring neither Visible nor Enabled is present,
    // answers true to both, and its trigger runs. Without this row every negative below
    // would also pass against an implementation that did nothing for any action.
    [Test]
    procedure TPAR_PlainAction_IsPresentAnswersTrueAndItsTriggerRuns()
    var
        Row: Record "TPAR Row";
        Host: TestPage "TPAR Host";
    begin
        Initialize();
        SeedOneRow();

        Host.OpenEdit();
        Host.First();
        Assert.IsTrue(Host.Plain.Visible(), 'an action declaring no Visible must be visible');
        Assert.IsTrue(Host.Plain.Enabled(), 'an action declaring no Enabled must be enabled');
        Host.Plain.Invoke();
        Host.Close();

        Assert.IsTrue(Row.Get('PLAIN'), 'Invoke() must have run the action OnAction trigger');
        Assert.AreEqual('ran', Row.Descr, 'the trigger must have written its own stamp');
    end;

    // Visible = false, written as the compile-time literal -- the spelling that eliminates a
    // page control or a subpage part outright. An action is NOT eliminated: it is on the page,
    // answers false to Visible(), and its trigger still runs.
    [Test]
    procedure TPAR_ActionDeclaredVisibleFalse_IsHiddenButStillInvokable()
    var
        Row: Record "TPAR Row";
        Host: TestPage "TPAR Host";
    begin
        Initialize();
        SeedOneRow();

        Host.OpenEdit();
        Host.First();
        Assert.IsFalse(Host.HiddenLiteral.Visible(),
            'an action declaring Visible = false must answer false');
        Assert.IsTrue(Host.HiddenLiteral.Enabled(),
            'Visible = false must not disable the action');
        Host.HiddenLiteral.Invoke();
        Host.Close();

        Assert.IsTrue(Row.Get('HIDDENLIT'),
            'a hidden action must still run its OnAction trigger when invoked');
    end;

    // Visible = false inherited from an enclosing action group. The action itself declares no
    // Visible at all, so Visible() has to follow the ancestor chain to answer false -- and
    // Enabled(), which the group says nothing about, must stay true. That pairing is what
    // stops "read the action's own Visible and stop there" and "answer false for anything
    // under a hidden group" from both passing.
    [Test]
    procedure TPAR_ActionInsideAGroupDeclaredVisibleFalse_IsHiddenButStillInvokable()
    var
        Row: Record "TPAR Row";
        Host: TestPage "TPAR Host";
    begin
        Initialize();
        SeedOneRow();

        Host.OpenEdit();
        Host.First();
        Assert.IsFalse(Host.InHiddenGroup.Visible(),
            'an action inside a group declaring Visible = false must answer false');
        Assert.IsTrue(Host.InHiddenGroup.Enabled(),
            'a hidden group must not disable the actions inside it');
        Host.InHiddenGroup.Invoke();
        Host.Close();

        Assert.IsTrue(Row.Get('INGROUP'),
            'an action inside a hidden group must still run its OnAction trigger');
    end;

    // Visible bound to an expression that is currently false. Same answers as the literal
    // spelling, which is the point: for an action the two spellings are not distinguishable
    // from AL, where for a control they are.
    [Test]
    procedure TPAR_ActionWithVisibleBoundToAFalseExpression_IsHiddenButStillInvokable()
    var
        Row: Record "TPAR Row";
        Host: TestPage "TPAR Host";
    begin
        Initialize();
        SeedOneRow();

        Host.OpenEdit();
        Host.First();
        Assert.IsFalse(Host.HiddenByVar.Visible(),
            'an action whose Visible expression is false must answer false');
        Host.HiddenByVar.Invoke();
        Host.Close();

        Assert.IsTrue(Row.Get('HIDDENVAR'),
            'an action that is present but not visible must still be invokable');
    end;

    // Invoking a hidden action must not disturb the page. Paired with the plain action after
    // it so an implementation that quietly tore the page down on the first hidden invoke
    // would fail here rather than passing every arm above.
    [Test]
    procedure TPAR_InvokingAHiddenAction_LeavesThePageUsable()
    var
        Row: Record "TPAR Row";
        Host: TestPage "TPAR Host";
    begin
        Initialize();
        SeedOneRow();

        Host.OpenEdit();
        Host.First();
        Host.HiddenLiteral.Invoke();
        Host.Plain.Invoke();
        Host.Close();

        Assert.IsTrue(Row.Get('HIDDENLIT'), 'the hidden action must have run');
        Assert.IsTrue(Row.Get('PLAIN'),
            'the page must still be usable after a hidden action was invoked');
    end;

    // Enabled = false. The action stays on the page and stays VISIBLE -- Enabled and Visible
    // are independent, and an implementation collapsing them would fail this row.
    [Test]
    procedure TPAR_ActionDeclaredEnabledFalse_IsDisabledButStillVisible()
    var
        Host: TestPage "TPAR Host";
    begin
        Initialize();
        SeedOneRow();

        Host.OpenEdit();
        Host.First();
        Assert.IsFalse(Host.DisabledLiteral.Enabled(),
            'an action declaring Enabled = false must answer false');
        Assert.IsTrue(Host.DisabledLiteral.Visible(),
            'Enabled = false must not make the action invisible');
        Host.Close();
    end;

    // The behaviour underneath it, and the result this file exists for: Invoke() on a disabled
    // action is a SILENT NO-OP. It does not raise -- BC's TestActionProxy.Invoke checks only
    // that the form is open, and the platform carries no "this action is disabled" error text
    // -- and the OnAction trigger does not run.
    [Test]
    procedure TPAR_ActionDeclaredEnabledFalse_InvokeIsASilentNoOp()
    var
        Row: Record "TPAR Row";
        Host: TestPage "TPAR Host";
    begin
        Initialize();
        SeedOneRow();

        Host.OpenEdit();
        Host.First();
        Host.DisabledLiteral.Invoke();
        Host.Plain.Invoke();
        Host.Close();

        Assert.IsFalse(Row.Get('DISABLEDLIT'),
            'Invoke() on a disabled action must NOT have run the OnAction trigger');
        Assert.IsTrue(Row.Get('PLAIN'),
            'and it must not have raised or disturbed the page: the next action still runs');
    end;

    // The expression-bound half of the same pair, so neither arm can be satisfied by an
    // implementation that only ever reads the literal spelling.
    [Test]
    procedure TPAR_ActionWithEnabledBoundToAFalseExpression_InvokeIsASilentNoOp()
    var
        Row: Record "TPAR Row";
        Host: TestPage "TPAR Host";
    begin
        Initialize();
        SeedOneRow();

        Host.OpenEdit();
        Host.First();
        Assert.IsFalse(Host.DisabledByVar.Enabled(),
            'an action whose Enabled expression is false must answer false');
        Assert.IsTrue(Host.DisabledByVar.Visible(),
            'Enabled = a false expression must not make the action invisible');
        Host.DisabledByVar.Invoke();
        Host.Close();

        Assert.IsFalse(Row.Get('DISABLEDVAR'),
            'Invoke() on an action disabled by expression must NOT have run its trigger');
    end;
}
