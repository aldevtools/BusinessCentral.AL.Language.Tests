// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-handler
// Scope: in-scope
// Fixtures used: Test Page Run Handler Row (60748), Test Page Run Target (60749), Assert (60021)
//
// Pins the NON-modal half of page dispatch from a test: Page.Run, not RunModal. The corpus
// already covers [ModalPageHandler] thoroughly; the two are separate platform methods that
// end differently, so covering only the modal one leaves the ordinary "open a card from a
// test" shape — the one most Microsoft test codeunits use — unpinned. TestMiscComplete.al
// even carries a placeholder saying TestPage.Trap() is "covered separately", and it is not.
//
// Three claims, each with a negative that a plausible wrong implementation fails:
//   1. A [PageHandler] is dispatched, and is handed the record the AL passed to Page.Run.
//      The record assertion uses the SECOND row on purpose: a page opened without the
//      caller's record reads the first one and fails.
//   2. The same page with NO handler declared must be refused with BC's own unhandled-UI
//      error, not opened silently — a page that quietly succeeds unattended turns a failing
//      test green.
//   3. TestPage.Trap() takes the page instead of any handler, and the page is still open
//      afterwards for the test to read.

codeunit 60750 "Test Page Run Handler Tests"
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
    end;

    local procedure SeedRows()
    var
        Row: Record "Test Page Run Handler Row";
    begin
        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();

        Row.Init();
        Row."No." := 'B';
        Row.Descr := 'Beta';
        Row.Insert();
    end;

    // Positive: a non-modal Page.Run from a test reaches the declared [PageHandler] at all.
    [Test]
    [HandlerFunctions('TargetPageHandler')]
    procedure PageHandlerRunsForANonModalPageRun()
    var
        Row: Record "Test Page Run Handler Row";
        Stamp: Record "Test Page Run Handler Row";
    begin
        Initialize();
        SeedRows();

        Row.Get('A');
        Page.Run(Page::"Test Page Run Target", Row);

        Assert.IsTrue(Stamp.Get('HANDLER'), 'the [PageHandler] must have run for a non-modal Page.Run');
    end;

    // Positive: the handler is handed the record the AL passed to Page.Run — not a blank page
    // and not whatever row happens to sort first. 'Beta' is deliberately the SECOND row, so a
    // page opened without the caller's record would read 'Alpha' and fail here.
    [Test]
    [HandlerFunctions('TargetPageHandler')]
    procedure PageHandlerReceivesTheRecordPassedToPageRun()
    var
        Row: Record "Test Page Run Handler Row";
        Stamp: Record "Test Page Run Handler Row";
    begin
        Initialize();
        SeedRows();

        Row.Get('B');
        Page.Run(Page::"Test Page Run Target", Row);

        Assert.IsTrue(Stamp.Get('HANDLER'), 'the [PageHandler] must have run');
        Assert.AreEqual('Beta', Stamp.Descr,
            'the [PageHandler] must be handed the record the AL passed to Page.Run');
    end;

    // Negative: no [HandlerFunctions] at all. The page must be refused with BC's own
    // unhandled-UI error. A runner that opened the page and carried on would pass every
    // positive above and fail only here.
    [Test]
    procedure NonModalPageRunWithoutAHandlerIsRefused()
    var
        Row: Record "Test Page Run Handler Row";
        Stamp: Record "Test Page Run Handler Row";
    begin
        Initialize();
        SeedRows();
        // asserterror rolls back to the last commit; without this, that rollback also undoes
        // Initialize()'s DeleteAll and SeedRows, reverting to whatever an earlier test in this
        // shared transaction left behind.
        Commit();

        Row.Get('A');
        asserterror Page.Run(Page::"Test Page Run Target", Row);
        Assert.ExpectedError('Unhandled UI');

        Assert.IsFalse(Stamp.Get('HANDLER'),
            'a refused page must not have reached any handler');
    end;

    // Positive: TestPage.Trap() takes precedence over handler lookup — the page opened by a
    // non-modal Page.Run is handed to the TEST's own TestPage variable, and is still open
    // afterwards for the test to read. This is the shape most Microsoft "show the document"
    // tests use.
    [Test]
    procedure TrapReceivesTheNonModalPageAndItStaysOpen()
    var
        Row: Record "Test Page Run Handler Row";
        Target: TestPage "Test Page Run Target";
    begin
        Initialize();
        SeedRows();

        Row.Get('B');
        Target.Trap();
        Page.Run(Page::"Test Page Run Target", Row);

        Assert.AreEqual('B', Target."No.".Value(),
            'the trapped page must still be open and positioned on the record Page.Run was given');
        Assert.AreEqual('Beta', Target.Descr.Value(),
            'the trapped page must expose the record the AL passed to Page.Run');
        Target.Close();
    end;

    [PageHandler]
    procedure TargetPageHandler(var Target: TestPage "Test Page Run Target")
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
