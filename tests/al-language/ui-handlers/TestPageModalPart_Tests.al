// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subpages-overview
// Scope: in-scope
// Fixtures used: Test Page Modal Handler Row (60702), Test Page Modal PartList (60731),
//   Test Page Modal Part NoSrc (60732), Test Page Modal Part Bound (60733), Assert (60021)
//
// Pins TestPage access to a subpage part hosted by a modal page with NO SourceTable — the
// ordinary Worksheet-dialog shape whose header fields are bound to page globals while the
// rows live in a ListPart over its own table. The part declares no SubPageLink, so nothing
// about it depends on a parent record: a [ModalPageHandler] must be able to navigate the
// part and read its Rec-bound controls exactly as it can on a host that has a SourceTable.
//
// The value assertions carry the weight: a part whose rowset answered as empty, or whose
// controls answered defaults, would fail on 'Alpha'.

codeunit 60734 "Test Page Modal Part Tests"
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

    local procedure SeedRows()
    var
        Row: Record "Test Page Modal Handler Row";
    begin
        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();
    end;

    // Positive: a handler navigates and reads the part on a host with no SourceTable.
    [Test]
    [HandlerFunctions('PartReadNoSrcHandler')]
    procedure ModalPart_HostWithoutSourceTable_HandlerReadsThePartRow()
    var
        NoSrcHost: Page "Test Page Modal Part NoSrc";
        Result: Action;
    begin
        Initialize();
        SeedRows();

        Result := NoSrcHost.RunModal();

        Assert.IsTrue(Result = Action::OK, 'the handler invoked OK, so RunModal must return OK');
    end;

    // Positive: the host's own header field OnValidate reaches into the part page — the
    // Worksheet header-drives-lines pattern. Runs on the same no-SourceTable host, so it
    // also pins that in-page part access and test-client part access agree.
    [Test]
    [HandlerFunctions('HeaderSetNoSrcHandler')]
    procedure ModalPart_HostWithoutSourceTable_ParentFieldPushesIntoThePartPage()
    var
        Echo: Record "Test Page Modal Handler Row";
        NoSrcHost: Page "Test Page Modal Part NoSrc";
        Result: Action;
    begin
        Initialize();
        SeedRows();

        Result := NoSrcHost.RunModal();

        Assert.IsTrue(Result = Action::OK, 'the handler invoked OK, so RunModal must return OK');
        Assert.IsTrue(Echo.Get('PART-TAG'),
            'the header field''s OnValidate must have reached the part page''s procedure');
        Assert.AreEqual('FROM-VALIDATE', Echo.Descr,
            'the part page procedure must see the value the handler wrote to the header field');
    end;

    // Control: the identical part read on a host WITH a SourceTable. A fix aimed at the
    // no-SourceTable host must leave the bound host untouched.
    [Test]
    [HandlerFunctions('PartReadBoundHandler')]
    procedure ModalPart_HostWithSourceTable_HandlerReadsThePartRow()
    var
        BoundHost: Page "Test Page Modal Part Bound";
        Result: Action;
    begin
        Initialize();
        SeedRows();

        Result := BoundHost.RunModal();

        Assert.IsTrue(Result = Action::OK, 'the handler invoked OK, so RunModal must return OK');
    end;

    [ModalPageHandler]
    procedure PartReadNoSrcHandler(var Dlg: TestPage "Test Page Modal Part NoSrc")
    begin
        Assert.IsTrue(Dlg.Lines.First(), 'the part must land on the seeded row of its own source table');
        Assert.AreEqual('Alpha', Dlg.Lines.Descr.Value(),
            'the part''s Rec-bound control must read the seeded row');
        Dlg.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure HeaderSetNoSrcHandler(var Dlg: TestPage "Test Page Modal Part NoSrc")
    begin
        Dlg.Mode.SetValue('FROM-VALIDATE');
        Dlg.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PartReadBoundHandler(var Dlg: TestPage "Test Page Modal Part Bound")
    begin
        Assert.IsTrue(Dlg.Lines.First(), 'the part must land on the seeded row of its own source table');
        Assert.AreEqual('Alpha', Dlg.Lines.Descr.Value(),
            'the part''s Rec-bound control must read the seeded row');
        Dlg.OK().Invoke();
    end;
}
