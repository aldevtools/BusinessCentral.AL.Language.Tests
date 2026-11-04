// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Test Page Modal Handler Row (60702), Test Page Modal (60703), Assert (60021)
//
// Sibling of TestPageModalHandler_Tests.al, which pins the AL-page-VARIABLE form of
// RunModal (`P: Page "X"; P.SetRecord(Rec); P.RunModal();`, reached through the host page's
// action). This file pins the STATIC-by-id form instead: `Page.RunModal(<id>, Record)`,
// called directly from AL — with no page variable, host page, or action involved at all.
// Both forms must reach the same [ModalPageHandler].
//
// The 2-arg (PageId, Record) overload runs the page in LOOKUP mode (verified against real
// BC): OK/Cancel from the [ModalPageHandler] read back as LookupOK/LookupCancel, not
// OK/Cancel. The negative matters as much as the positive here: a cancelling handler must
// not read back as LookupOK, so a runner (or any implementation) that dispatched to the
// handler but always reported success would pass the first test and fail the second.

codeunit 60717 "Test Page Modal Handler Static"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Test Page Modal Handler Row";
    begin
        Row.DeleteAll();
    end;

    // Positive: the STATIC Page.RunModal(id, Record) form reaches the [ModalPageHandler],
    // and the handler's OK reaches the calling AL as LookupOK (this overload runs the page
    // in lookup mode — verified against real BC).
    [Test]
    [HandlerFunctions('OkHandler')]
    procedure StaticRunModal_ExplicitId_HandlerRunsAndOkReachesCallingAl()
    var
        Row: Record "Test Page Modal Handler Row";
        Result: Action;
    begin
        Initialize();
        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();

        Result := Page.RunModal(Page::"Test Page Modal", Row);

        Assert.IsTrue(Row.Get('HANDLER'), 'the [ModalPageHandler] must have run for the static Page.RunModal(id, Record) form');
        Assert.AreEqual(Format(Action::LookupOK), Format(Result), 'Page.RunModal(id, Record) must return the handler''s OK as LookupOK (lookup-mode overload)');
    end;

    // Negative: a cancelling handler must NOT read back as LookupOK. Without this, mapping
    // every close to LookupOK would pass the test above and hide the same bug in reverse.
    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure StaticRunModal_ExplicitId_CancelReachesCallingAl()
    var
        Row: Record "Test Page Modal Handler Row";
        Result: Action;
    begin
        Initialize();
        Row.Init();
        Row."No." := 'B';
        Row.Descr := 'Bravo';
        Row.Insert();

        Result := Page.RunModal(Page::"Test Page Modal", Row);

        Assert.IsTrue(Row.Get('HANDLER'), 'the [ModalPageHandler] must have run for the static Page.RunModal(id, Record) form');
        Assert.AreEqual(Format(Action::LookupCancel), Format(Result), 'Page.RunModal(id, Record) must return the handler''s Cancel as LookupCancel, not LookupOK');
    end;

    [ModalPageHandler]
    procedure OkHandler(var Modal: TestPage "Test Page Modal")
    var
        Stamp: Record "Test Page Modal Handler Row";
    begin
        Stamp.Init();
        Stamp."No." := 'HANDLER';
        Stamp.Descr := 'ran';
        if not Stamp.Insert() then
            Stamp.Modify();
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CancelHandler(var Modal: TestPage "Test Page Modal")
    var
        Stamp: Record "Test Page Modal Handler Row";
    begin
        Stamp.Init();
        Stamp."No." := 'HANDLER';
        Stamp.Descr := 'ran';
        if not Stamp.Insert() then
            Stamp.Modify();
        Modal.Cancel().Invoke();
    end;
}
