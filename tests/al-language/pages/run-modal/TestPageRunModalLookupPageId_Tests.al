// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Test RunModal LookupPage Row (60995), Test RunModal LookupPage List (60996),
//   ALT Universal (60000), Assert (60021)
//
// Pins the static Page.RunModal(0, Record) overload: passing object id 0 together with a
// record resolves the page to open from that RECORD's own table metadata — specifically the
// table's declared LookupPageId — exactly as Page.RunModal(Page::"X", Record) does when the id
// is given explicitly, just resolved from the table instead of spelled out at the call site.
//
// The negative carries the real weight. A record whose table declares NO LookupPageId must
// still refuse the call rather than silently opening some other page (the first page found, or
// whatever page id happens to be 0 in this session) — a fix that made every id-0 static
// RunModal succeed regardless of the record's own table metadata would pass the positive test
// below and hide the same bug in reverse.

codeunit 60997 "Test RunModal ById0 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    var
        Row: Record "Test RunModal LookupPage Row";
    begin
        Cleanup.Initialize();
        Row.DeleteAll();
    end;

    // Positive: Page.RunModal(0, Record) resolves the page to open from the record's own
    // table's LookupPageId, reaches the [ModalPageHandler], and the handler's OK reaches the
    // calling AL as LookupOK — the same lookup-mode result the 2-arg (id, Record) overload
    // returns when the id is given explicitly.
    [Test]
    [HandlerFunctions('LookupListHandler')]
    procedure RunModal_ById0_ResolvesPageFromTheRecordsTableLookupPageId()
    var
        Row: Record "Test RunModal LookupPage Row";
        Marker: Record "Test RunModal LookupPage Row";
        Result: Action;
    begin
        Initialize();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();

        Result := Page.RunModal(0, Row);

        Assert.IsTrue(Marker.Get('HANDLER'), 'the [ModalPageHandler] for the LookupPageId-resolved page must have run');
        Assert.AreEqual(Format(Action::LookupOK), Format(Result),
            'Page.RunModal(0, Record) must resolve the page via LookupPageId and return LookupOK');
    end;

    // Negative: a table declaring NO LookupPageId must still refuse Page.RunModal(0, Record)
    // rather than silently opening a page. Real BC's NavForm.RunModalAsync leaves formId at 0
    // when the record's table declares no lookup page, taking exactly the same "no such Page
    // 0" path as Page.RunModal(0, Record) on an explicit, nonexistent id 0.
    [Test]
    procedure RunModal_ById0_TableWithNoLookupPageId_IsRefused()
    var
        Universal: Record "ALT Universal";
    begin
        Initialize();
        Universal."Entry No." := 1;
        Universal.Insert();

        asserterror Page.RunModal(0, Universal);
        Assert.ExpectedError('You tried to invoke the Page object with the ID 0');
    end;

    [ModalPageHandler]
    procedure LookupListHandler(var Modal: TestPage "Test RunModal LookupPage List")
    var
        Stamp: Record "Test RunModal LookupPage Row";
    begin
        Stamp.Init();
        Stamp."No." := 'HANDLER';
        Stamp.Descr := 'ran';
        if not Stamp.Insert() then
            Stamp.Modify();
        Modal.OK().Invoke();
    end;
}
