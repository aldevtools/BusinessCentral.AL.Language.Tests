// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subpages-overview
// Scope: in-scope
// Fixtures used: Test Page Modal Handler Row (60702), Test Page NoSrc CardPart (60800),
//   Test Page NoSrc Part Bound (60801), Test Page NoSrc Part NoSrc (60802), Assert (60021)
//
// Pins TestPage access to a subpage part whose OWN page declares no SourceTable — a CardPart
// bound to page globals, the "info box" shape. Codeunits 60734 and 60763 pin the mirror
// axis, a part WITH a source table on a host without one; this one moves the missing source
// table onto the part itself.
//
// The claim: a part page having no source table is not a reason for the part to be
// unreachable. Its globals-bound controls read and write, its OnOpenPage runs, its field
// OnValidate fires, and the host's own AL can reach into it through CurrPage.<part>.Page.
//
// The gating is in the arms. An implementation that stood the part up as an inert shell
// answering defaults fails the very first assertion ('Hello' is not ''); one that let reads
// through but dropped writes fails PartControlAcceptsAWrite and PartControlWriteRunsOnValidate;
// one that swallowed errors raised inside the part fails PartControlValidateErrorSurfaces;
// one that only handled a wholly record-less page tree fails the BoundHost arms.

codeunit 60803 "Test Page NoSrc Part Tests"
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

    local procedure SeedHostRow()
    var
        Row: Record "Test Page Modal Handler Row";
    begin
        Row.Init();
        Row."No." := 'H';
        Row.Descr := 'Host row';
        Row.Insert();
    end;

    // THE CLAIM, direct-open half: a CardPart with no SourceTable on a host that HAS one.
    // 'Hello' comes from the part page's own OnOpenPage, so a default-answering shell fails.
    [Test]
    procedure DirectOpen_BoundHost_NoSourceTablePartControlReads()
    var
        Host: TestPage "Test Page NoSrc Part Bound";
    begin
        Initialize();
        SeedHostRow();

        Host.OpenEdit();

        Assert.AreEqual('Hello', Host.Info.Tag.Value(),
            'the no-SourceTable part''s globals-bound control must read what its OnOpenPage set');
        Host.Close();
    end;

    // The same read on a host that ALSO has no SourceTable — the whole-tree-record-less case.
    [Test]
    procedure DirectOpen_NoSrcHost_NoSourceTablePartControlReads()
    var
        Host: TestPage "Test Page NoSrc Part NoSrc";
    begin
        Initialize();

        Host.OpenEdit();

        Assert.AreEqual('Hello', Host.Info.Tag.Value(),
            'the part''s control must read its OnOpenPage value on a record-less host too');
        Host.Close();
    end;

    // Writes reach the part's page global: read-back must show the written value, not the
    // OnOpenPage seed. Separates "reads work" from "the control is live in both directions".
    [Test]
    procedure DirectOpen_BoundHost_PartControlAcceptsAWrite()
    var
        Host: TestPage "Test Page NoSrc Part Bound";
    begin
        Initialize();
        SeedHostRow();

        Host.OpenEdit();
        Host.Info.Tag.SetValue('Written');

        Assert.AreEqual('Written', Host.Info.Tag.Value(),
            'writing the part''s globals-bound control must change what it reads back');
        Host.Close();
    end;

    // Durable proof the part page's own AL ran: the control's OnValidate writes a row.
    [Test]
    procedure DirectOpen_BoundHost_PartControlWriteRunsOnValidate()
    var
        Echo: Record "Test Page Modal Handler Row";
        Host: TestPage "Test Page NoSrc Part Bound";
    begin
        Initialize();
        SeedHostRow();

        Host.OpenEdit();
        Host.Info.Tag.SetValue('Validated');
        Host.Close();

        Assert.IsTrue(Echo.Get('NOSRC-PART'),
            'the part control''s OnValidate must have run and written its row');
        Assert.AreEqual('Validated', Echo.Descr,
            'the part''s OnValidate must see the value written through the part control');
    end;

    // Negative direction: an error raised inside the part page's OnValidate must surface to
    // the test, not be swallowed by the part wrapper.
    [Test]
    procedure DirectOpen_BoundHost_PartControlValidateErrorSurfaces()
    var
        Host: TestPage "Test Page NoSrc Part Bound";
    begin
        Initialize();
        SeedHostRow();

        Host.OpenEdit();
        asserterror Host.Info.Guard.SetValue('BAD');

        Assert.ExpectedError('Guard rejected the value BAD');
    end;

    // The host's own AL reaches into the part page through CurrPage.<part>.Page — the
    // Worksheet header-drives-lines pattern, here with a part that has no source table of its
    // own. The write-through to a table is the durable proof the call landed in a live part
    // page object rather than in nothing.
    [Test]
    procedure DirectOpen_NoSrcHost_HostFieldReachesTheNoSourceTablePartPage()
    var
        Echo: Record "Test Page Modal Handler Row";
        Host: TestPage "Test Page NoSrc Part NoSrc";
    begin
        Initialize();

        Host.OpenEdit();
        Host.Mode.SetValue('FROM-HOST');
        Host.Close();

        Assert.IsTrue(Echo.Get('NOSRC-VIA-HOST'),
            'the header field''s OnValidate must have reached the part page''s procedure');
        Assert.AreEqual('FROM-HOST', Echo.Descr,
            'the part page procedure must see the value the host passed it');
    end;

    // Issue #2201 (AL Runner): TestPage.<part> and the host's OWN CurrPage.<part>.Page must
    // be the SAME part page instance. Invisible for a Rec-bound part, since its state lives
    // in the shared record — but this part's controls are page globals, so an implementation
    // that built a second, disconnected instance for TestPage.Info would see 'Hello' here
    // (whatever that second instance's own OnOpenPage set) instead of 'FROM-HOST' (what the
    // host's AL actually wrote through the object it drives). Real BC: one instance, shared.
    [Test]
    procedure DirectOpen_NoSrcHost_HostWriteIsVisibleThroughTheSameInstance()
    var
        Host: TestPage "Test Page NoSrc Part NoSrc";
    begin
        Initialize();

        Host.OpenEdit();
        Host.Mode.SetValue('FROM-HOST');

        Assert.AreEqual('FROM-HOST', Host.Info.Tag.Value(),
            'TestPage.Info must be the SAME part page instance the host''s own AL just wrote through');
        Host.Close();
    end;

    // The same claim under a [ModalPageHandler]: the handler's own TestPage.Info must be the
    // instance the host's OnValidate already wrote through, not a second one seeded only by
    // the part's own OnOpenPage.
    [Test]
    [HandlerFunctions('NoSrcPartNoSrcHostWriteHandler')]
    procedure Modal_NoSrcHost_HostWriteIsVisibleThroughTheSameInstance()
    var
        NoSrcHost: Page "Test Page NoSrc Part NoSrc";
        Result: Action;
    begin
        Initialize();

        Result := NoSrcHost.RunModal();

        Assert.IsTrue(Result = Action::OK, 'the handler invoked OK, so RunModal must return OK');
    end;

    [ModalPageHandler]
    procedure NoSrcPartNoSrcHostWriteHandler(var Dlg: TestPage "Test Page NoSrc Part NoSrc")
    begin
        Dlg.Mode.SetValue('FROM-HANDLER');
        Assert.AreEqual('FROM-HANDLER', Dlg.Info.Tag.Value(),
            'under a handler too, TestPage.Info must be the SAME instance the host''s own AL wrote through');
        Dlg.OK().Invoke();
    end;

    // THE CLAIM, modal half: the same part read from inside a [ModalPageHandler].
    [Test]
    [HandlerFunctions('NoSrcPartBoundHandler')]
    procedure Modal_BoundHost_HandlerReadsTheNoSourceTablePart()
    var
        BoundHost: Page "Test Page NoSrc Part Bound";
        Result: Action;
    begin
        Initialize();
        SeedHostRow();

        Result := BoundHost.RunModal();

        Assert.IsTrue(Result = Action::OK, 'the handler invoked OK, so RunModal must return OK');
    end;

    [Test]
    [HandlerFunctions('NoSrcPartNoSrcHandler')]
    procedure Modal_NoSrcHost_HandlerReadsTheNoSourceTablePart()
    var
        NoSrcHost: Page "Test Page NoSrc Part NoSrc";
        Result: Action;
    begin
        Initialize();

        Result := NoSrcHost.RunModal();

        Assert.IsTrue(Result = Action::OK, 'the handler invoked OK, so RunModal must return OK');
    end;

    [ModalPageHandler]
    procedure NoSrcPartBoundHandler(var Dlg: TestPage "Test Page NoSrc Part Bound")
    begin
        Assert.AreEqual('Hello', Dlg.Info.Tag.Value(),
            'the part''s globals-bound control must read its OnOpenPage value under a handler');
        Dlg.Info.Tag.SetValue('FromHandler');
        Assert.AreEqual('FromHandler', Dlg.Info.Tag.Value(),
            'a write through the part control must be visible under a handler too');
        Dlg.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NoSrcPartNoSrcHandler(var Dlg: TestPage "Test Page NoSrc Part NoSrc")
    begin
        Assert.AreEqual('Hello', Dlg.Info.Tag.Value(),
            'the part''s control must read its OnOpenPage value on a record-less host under a handler');
        Dlg.OK().Invoke();
    end;
}
