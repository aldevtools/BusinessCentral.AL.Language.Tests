// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-oninit-page-trigger
//                   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testaction/testaction-enabled-method
// Scope: in-scope (Cloud-compatible) -- every member is driven from a [Test] with no client
// Fixtures used: POI Row (60486), POI Wizard (60487), POI Refusing Page (60489); shared Assert (60021)
// BC versions: 27.0+
//
/// <summary>
/// CLAIM: a page's OnInit trigger runs once per page INSTANCE, when the instance is constructed
/// -- so before OnOpenPage, before any procedure AL calls on a Page variable, and again for the
/// fresh instance every TestPage open gets -- and a page global it assigns is what the controls
/// and the actions' Enabled read afterwards, unless something that ran after OnInit changed it.
///
/// Every arm reads a value only OnInit writes, so an implementation that never runs OnInit
/// fails all of them: Trace stays '' instead of 'IO', and NextAction (Enabled = NextEnabled,
/// set true only by OnInit) answers false and ignores Invoke().
///
/// The pairs are there so "answer true for every action" cannot pass either: BackAction is
/// bound to a global OnInit sets FALSE, so it must answer false and Invoke() must do nothing
/// -- silently, the result codeunit 60583 "TPAR Tests" measured for a disabled action.
/// </summary>

codeunit 60488 "POI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        SeenTrace: Text;
        SeenNextEnabled: Boolean;
        SeenBackEnabled: Boolean;
        SeenStep: Text;

    local procedure Initialize()
    var
        Row: Record "POI Row";
    begin
        Row.DeleteAll();
        SeenTrace := '?';
        SeenNextEnabled := false;
        SeenBackEnabled := true;
        SeenStep := '?';
    end;

    local procedure HitsOf(No: Code[20]): Integer
    var
        Row: Record "POI Row";
    begin
        if Row.Get(No) then
            exit(Row.Hits);
        exit(0);
    end;

    // OnInit runs before OnOpenPage, and the control bound to the global it wrote shows it.
    [Test]
    procedure POI_OpenEdit_RunsOnInitBeforeOnOpenPage()
    var
        Wizard: TestPage "POI Wizard";
    begin
        Initialize();

        Wizard.OpenEdit();
        Assert.AreEqual('IO', Wizard.TraceText.Value(),
            'OnInit must run once, and before OnOpenPage');
        Assert.AreEqual('0', Wizard.StepNo.Value(), 'OnInit must have set the first step');
        Wizard.Close();
    end;

    // The issue shape: Enabled bound to a global OnInit sets true answers true, and Invoke()
    // runs the OnAction trigger.
    [Test]
    procedure POI_ActionEnabledByAGlobalSetInOnInit_IsEnabledAndInvokeRuns()
    var
        Wizard: TestPage "POI Wizard";
    begin
        Initialize();

        Wizard.OpenEdit();
        Assert.IsTrue(Wizard.NextAction.Enabled(),
            'an action bound to a global OnInit set true must be enabled');
        Wizard.NextAction.Invoke();
        Assert.AreEqual('1', Wizard.StepNo.Value(), 'Invoke() must have advanced the step');
        Wizard.Close();

        Assert.AreEqual(1, HitsOf('NEXT'), 'the Next OnAction trigger must have run once');
    end;

    // The negative pair: Enabled bound to a global OnInit set false answers false, and
    // Invoke() neither errors nor runs the trigger.
    [Test]
    procedure POI_ActionDisabledByAGlobalSetInOnInit_IsDisabledAndInvokeDoesNothing()
    var
        Wizard: TestPage "POI Wizard";
    begin
        Initialize();

        Wizard.OpenEdit();
        Assert.IsFalse(Wizard.BackAction.Enabled(),
            'an action bound to a global OnInit set false must be disabled');
        Wizard.BackAction.Invoke();
        Assert.AreEqual('0', Wizard.StepNo.Value(), 'a disabled action must not change the step');
        Wizard.Close();

        Assert.AreEqual(0, HitsOf('BACK'), 'a disabled action''s OnAction trigger must not run');
    end;

    // After OnInit, the actions follow the globals their own triggers recompute: two Nexts
    // reach the last step, which disables Next, so a third Invoke() does nothing, and Back
    // is enabled from the first step on.
    [Test]
    procedure POI_EnabledFollowsTheGlobalsAsTheWizardAdvances()
    var
        Wizard: TestPage "POI Wizard";
    begin
        Initialize();

        Wizard.OpenEdit();
        Wizard.NextAction.Invoke();
        Assert.IsTrue(Wizard.BackAction.Enabled(), 'Back must be enabled on step 1');
        Assert.IsTrue(Wizard.NextAction.Enabled(), 'Next must be enabled on step 1');
        Wizard.NextAction.Invoke();
        Assert.IsFalse(Wizard.NextAction.Enabled(), 'Next must be disabled on the last step');
        Wizard.NextAction.Invoke();
        Assert.AreEqual('2', Wizard.StepNo.Value(), 'a disabled Next must not pass the last step');
        Wizard.BackAction.Invoke();
        Assert.AreEqual('1', Wizard.StepNo.Value(), 'Back must step back');
        Wizard.Close();

        Assert.AreEqual(2, HitsOf('NEXT'), 'Next must have run exactly twice');
        Assert.AreEqual(1, HitsOf('BACK'), 'Back must have run exactly once');
    end;

    // A reopened page runs OnInit again: the step reset and the trace are OnInit's, not left
    // over from the first open.
    [Test]
    procedure POI_Reopen_RunsOnInitAgain()
    var
        Wizard: TestPage "POI Wizard";
    begin
        Initialize();

        Wizard.OpenEdit();
        Wizard.NextAction.Invoke();
        Wizard.Close();

        Wizard.OpenEdit();
        Assert.AreEqual('IO', Wizard.TraceText.Value(), 'a reopen must run OnInit and OnOpenPage once each');
        Assert.AreEqual('0', Wizard.StepNo.Value(), 'a reopen must start from OnInit''s step');
        Assert.IsFalse(Wizard.BackAction.Enabled(), 'a reopen must disable Back again');
        Wizard.Close();
    end;

    // A page AL opens itself with RunModal runs OnInit too, before the handler sees it.
    [Test]
    [HandlerFunctions('WizardModalHandler')]
    procedure POI_RunModal_RunsOnInitBeforeTheHandler()
    var
        Wizard: Page "POI Wizard";
    begin
        Initialize();

        Wizard.RunModal();

        Assert.AreEqual('IO', SeenTrace, 'RunModal must run OnInit and then OnOpenPage');
        Assert.IsTrue(SeenNextEnabled, 'Next must be enabled in the modal handler');
        Assert.IsFalse(SeenBackEnabled, 'Back must be disabled in the modal handler');
    end;

    // The non-modal twin.
    [Test]
    [HandlerFunctions('WizardPageHandler')]
    procedure POI_PageRun_RunsOnInitBeforeTheHandler()
    begin
        Initialize();

        Page.Run(Page::"POI Wizard");

        Assert.AreEqual('IO', SeenTrace, 'Page.Run must run OnInit and then OnOpenPage');
        Assert.IsTrue(SeenNextEnabled, 'Next must be enabled in the page handler');
    end;

    // OnInit runs when the page instance is CONSTRUCTED, not when it is opened. A procedure
    // called on a Page variable before RunModal therefore runs after OnInit, and what it sets
    // must survive: the trace reads I (OnInit), S (SetStep), O (OnOpenPage), and the step and
    // both actions show the setter's step 2, not OnInit's step 0.
    [Test]
    [HandlerFunctions('WizardModalHandler')]
    procedure POI_SetterBeforeRunModal_RunsAfterOnInitAndSurvives()
    var
        Wizard: Page "POI Wizard";
    begin
        Initialize();

        Wizard.SetStep(2);
        Wizard.RunModal();

        Assert.AreEqual('ISO', SeenTrace, 'OnInit must run once, before the setter, and OnOpenPage after both');
        Assert.AreEqual('2', SeenStep, 'the step the setter chose must survive into the opened page');
        Assert.IsFalse(SeenNextEnabled, 'Next must follow the setter''s last step, not OnInit''s first');
        Assert.IsTrue(SeenBackEnabled, 'Back must follow the setter''s last step, not OnInit''s first');
    end;

    // The non-modal twin, reached through Page.Run on the same variable.
    [Test]
    [HandlerFunctions('WizardPageHandler')]
    procedure POI_SetterBeforeRun_RunsAfterOnInitAndSurvives()
    var
        Wizard: Page "POI Wizard";
    begin
        Initialize();

        Wizard.SetStep(1);
        Wizard.Run();

        Assert.AreEqual('ISO', SeenTrace, 'OnInit must run once, before the setter, and OnOpenPage after both');
        Assert.AreEqual('1', SeenStep, 'the step the setter chose must survive into the opened page');
    end;

    // A TestPage cannot call a page procedure before it opens, so the TestPage side of the order
    // is reached through Trap: the test traps the page, sets it up through the Page variable,
    // runs it, and reads the trapped TestPage.
    [Test]
    procedure POI_SetterBeforeTrappedRun_RunsAfterOnInitAndSurvives()
    var
        Wizard: Page "POI Wizard";
        Trapped: TestPage "POI Wizard";
    begin
        Initialize();

        Trapped.Trap();
        Wizard.SetStep(1);
        Wizard.Run();

        Assert.AreEqual('ISO', Trapped.TraceText.Value(), 'OnInit must run once, before the setter, and OnOpenPage after both');
        Assert.AreEqual('1', Trapped.StepNo.Value(), 'the step the setter chose must survive into the trapped page');
        Assert.IsTrue(Trapped.BackAction.Enabled(), 'Back must follow the setter''s step');
        Trapped.Close();
    end;

    // An Error() raised in OnInit is the caller's error, with its own text, whichever way the
    // page is opened. Three routes, because they construct the page differently: a TestPage open,
    // RunModal on a Page variable, and the static Page.RunModal. No handler is declared: the page
    // never gets as far as being shown.
    [Test]
    procedure POI_ErrorInOnInit_ReachesTestPageOpenWithItsOwnText()
    var
        Refusing: TestPage "POI Refusing Page";
    begin
        Initialize();

        asserterror Refusing.OpenView();

        Assert.ExpectedError('POI OnInit refused to open the page');
        Assert.AreEqual('POI OnInit refused to open the page', GetLastErrorText(),
            'the error text must be OnInit''s own, not a wrapper around it');
    end;

    [Test]
    procedure POI_ErrorInOnInit_ReachesPageVariableRunModalWithItsOwnText()
    var
        Refusing: Page "POI Refusing Page";
    begin
        Initialize();

        asserterror Refusing.RunModal();

        Assert.ExpectedError('POI OnInit refused to open the page');
        Assert.AreEqual('POI OnInit refused to open the page', GetLastErrorText(),
            'the error text must be OnInit''s own, not a wrapper around it');
    end;

    [Test]
    procedure POI_ErrorInOnInit_ReachesStaticPageRunModalWithItsOwnText()
    begin
        Initialize();

        asserterror Page.RunModal(Page::"POI Refusing Page");

        Assert.ExpectedError('POI OnInit refused to open the page');
        Assert.AreEqual('POI OnInit refused to open the page', GetLastErrorText(),
            'the error text must be OnInit''s own, not a wrapper around it');
    end;

    [ModalPageHandler]
    procedure WizardModalHandler(var Wizard: TestPage "POI Wizard")
    begin
        SeenTrace := Wizard.TraceText.Value();
        SeenStep := Wizard.StepNo.Value();
        SeenNextEnabled := Wizard.NextAction.Enabled();
        SeenBackEnabled := Wizard.BackAction.Enabled();
    end;

    [PageHandler]
    procedure WizardPageHandler(var Wizard: TestPage "POI Wizard")
    begin
        SeenTrace := Wizard.TraceText.Value();
        SeenStep := Wizard.StepNo.Value();
        SeenNextEnabled := Wizard.NextAction.Enabled();
    end;
}
