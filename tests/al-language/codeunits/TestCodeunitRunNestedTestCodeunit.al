// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
// Fixtures used: Assert (60021); self-contained codeunits 67565, 67567, 67568, 67574 and pages 67565, 67566
//
// Codeunit.Run on a Subtype = Test codeunit, from inside a running [Test], is refused: BC
// does not nest test codeunit runs. The refusal is an error even in the guarded form
// (`Ok := Codeunit.Run(...)`), and no test method of the inner codeunit runs.
//
// Platform source: NavTestCodeunit.DoRunAsync calls NavTestExecution.EnterTestCodeunit(this)
// first, which throws NavNCLTestCodeUnitNestedInvocationException whenever a test codeunit is
// already executing (body identical on BC 27.5 and 28.5). The override has no error trap of its
// own, unlike NavCodeunit.DoRunAsync, which is why the guarded form is expected to raise too.
//
// Independent of run order: the outer [Test] is always inside a running test codeunit, and the
// inner codeunit's own test passes whenever the harness runs it on its own. Whether the inner test
// body ran is observed through a MANUALLY bound event subscriber each test binds for itself, not a
// SingleInstance counter, so no state is shared between test codeunits (corpus issue #261).
//
// AL Runner issue: StefanMaron/BusinessCentral.AL.Runner#4827 (the runner ran the nested
// codeunit's OnRun and returned true).
// BC versions: 27.5+

codeunit 67565 "NTC Inner Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure InnerTest_RunByTheHarness_Runs()
    // CLAIM: the inner codeunit's test runs normally when the harness runs it on its own.
    var
        Publisher: Codeunit "NTC Inner Ran Publisher";
        Observer: Codeunit "NTC Inner Ran Observer";
    begin
        BindSubscription(Observer);
        Publisher.RaiseInnerRan();
        UnbindSubscription(Observer);
        Assert.AreEqual(1, Observer.GetCount(), 'the inner test body must run and raise its event once');
    end;
}

codeunit 67567 "NTC Inner Ran Publisher"
{
    procedure RaiseInnerRan()
    begin
        OnInnerRan();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInnerRan()
    begin
    end;
}

codeunit 67574 "NTC Inner Ran Observer"
{
    EventSubscriberInstance = Manual;

    var
        Count: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"NTC Inner Ran Publisher", 'OnInnerRan', '', false, false)]
    local procedure HandleInnerRan()
    begin
        Count += 1;
    end;

    procedure GetCount(): Integer
    begin
        exit(Count);
    end;
}

page 67565 "NTC Dialog"
{
    Caption = 'NTC Dialog';
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;
}

page 67566 "NTC Card"
{
    Caption = 'NTC Card';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
}

codeunit 67568 "NTC Plain Codeunit"
{
    trigger OnRun()
    begin
    end;
}

codeunit 67566 "NTC Nested Run Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        // Unconfirmed until the corpus CI prints it: read from BC 28.5's
        // NavNCLTestCodeUnitNestedInvocationException.Create resource text.
        NestedErr: Label 'You cannot nest the execution of test codeunits.', Locked = true;
        NestedCodeunitErr: Label 'Test codeunit 67565 NTC Inner Tests was called from another test codeunit.', Locked = true;
        DialogHandled: Boolean;
        CardHandled: Boolean;

    [Test]
    procedure CodeunitRun_TestCodeunitFromTest_Unguarded_Throws()
    // CLAIM: Codeunit.Run of a test codeunit from a running test raises BC's nested-run error.
    begin
        asserterror Codeunit.Run(Codeunit::"NTC Inner Tests");
        Assert.ExpectedError(NestedErr);
        Assert.ExpectedError(NestedCodeunitErr);
    end;

    [Test]
    procedure CodeunitRun_TestCodeunitFromTest_Guarded_StillThrows()
    // CLAIM: consuming the Boolean result does not trap the nested-run error.
    var
        Ok: Boolean;
    begin
        Ok := true;
        asserterror Ok := Codeunit.Run(Codeunit::"NTC Inner Tests");
        Assert.ExpectedError(NestedErr);
        Assert.IsTrue(Ok, 'the guarded Run must not have returned a value, false or otherwise');
    end;

    [Test]
    procedure CodeunitRun_TestCodeunitVariableFromTest_Throws()
    // CLAIM: the instance form (a codeunit variable's own Run) is refused the same way.
    var
        Inner: Codeunit "NTC Inner Tests";
    begin
        asserterror Inner.Run();
        Assert.ExpectedError(NestedErr);
        Assert.ExpectedError(NestedCodeunitErr);
    end;

    [Test]
    procedure InnerRanObserver_Bound_SeesTheInnerEvent()
    // CLAIM (control for the next test): a bound observer counts the event the inner test body raises.
    var
        Publisher: Codeunit "NTC Inner Ran Publisher";
        Observer: Codeunit "NTC Inner Ran Observer";
    begin
        BindSubscription(Observer);
        Publisher.RaiseInnerRan();
        UnbindSubscription(Observer);
        Assert.AreEqual(1, Observer.GetCount(), 'the bound observer must count the raised event');
    end;

    [Test]
    procedure CodeunitRun_TestCodeunitFromTest_RunsNoInnerTest()
    // CLAIM: the refused run executes none of the inner codeunit's test methods.
    var
        Observer: Codeunit "NTC Inner Ran Observer";
    begin
        BindSubscription(Observer);
        asserterror Codeunit.Run(Codeunit::"NTC Inner Tests");
        UnbindSubscription(Observer);
        Assert.ExpectedError(NestedErr);
        Assert.AreEqual(0, Observer.GetCount(), 'no inner test method may run when the nested run is refused');
    end;

    [Test]
    [HandlerFunctions('NtcDialogHandler')]
    procedure CodeunitRun_RefusedNestedRun_LaterModalPageReachesItsHandler()
    // CLAIM: after a refused nested run, a modal page opened in the same test still reaches its
    // [ModalPageHandler]. The refused DoRunAsync releases the test page client in its finally;
    // the next modal dispatch must get a working one back.
    begin
        DialogHandled := false;
        asserterror Codeunit.Run(Codeunit::"NTC Inner Tests");
        Assert.ExpectedError(NestedErr);
        Page.RunModal(Page::"NTC Dialog");
        Assert.IsTrue(DialogHandled, 'the modal page handler must run after the refused nested run');
    end;

    [ModalPageHandler]
    procedure NtcDialogHandler(var Dialog: TestPage "NTC Dialog")
    begin
        DialogHandled := true;
    end;

    [Test]
    [HandlerFunctions('NtcCardHandler')]
    procedure CodeunitRun_RefusedNestedRun_LaterPageRunReachesItsHandler()
    // CLAIM: after a refused nested run, a non-modal Page.Run in the same test still reaches its
    // [PageHandler].
    begin
        CardHandled := false;
        asserterror Codeunit.Run(Codeunit::"NTC Inner Tests");
        Assert.ExpectedError(NestedErr);
        Page.Run(Page::"NTC Card");
        Assert.IsTrue(CardHandled, 'the page handler must run after the refused nested run');
    end;

    [PageHandler]
    procedure NtcCardHandler(var Card: TestPage "NTC Card")
    begin
        CardHandled := true;
    end;

    [Test]
    procedure CodeunitRun_PlainCodeunitFromTest_ReturnsTrue()
    // CLAIM: the refusal is specific to test codeunits; a plain codeunit still runs from a test.
    var
        Ok: Boolean;
    begin
        Ok := Codeunit.Run(Codeunit::"NTC Plain Codeunit");
        Assert.IsTrue(Ok, 'Codeunit.Run of a plain codeunit from a test must succeed');
    end;
}
