// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modal-page-handler
// Scope: in-scope
// Fixtures used: Test Page Modal Handler Row (60702), Test Page Modal (60703),
//   Test Page Modal Host (60704), Test Page Modal Vars (60705), Test Page Modal NoSrc (60730),
//   Assert (60021)
//
// Pins [ModalPageHandler] dispatch: AL that opens a modal page must be answered by the test
// codeunit's handler, and the handler's OK/Cancel must reach the calling AL.
//
// The negatives carry real weight. A runner that routed to the handler but always reported OK
// would pass the positive; the Cancel test catches that. And a modal page with NO declared
// handler must raise BC's own missing-handler error — silently returning a default result is
// how an unhandled dialog turns a failing test green.

codeunit 60706 "Test Page Modal Handler Tests"
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

    // Positive: the handler runs at all, and is handed the modal page.
    [Test]
    [HandlerFunctions('OkHandler')]
    procedure ModalPageHandlerRuns()
    var
        Row: Record "Test Page Modal Handler Row";
        Host: TestPage "Test Page Modal Host";
    begin
        Initialize();
        SeedRows();

        Host.OpenEdit();
        Host.First();
        Host.PickIt.Invoke();
        Host.Close();

        Assert.IsTrue(Row.Get('HANDLER'), 'the [ModalPageHandler] must have run');
    end;

    // Positive: the handler's OK reaches the AL that called RunModal.
    [Test]
    [HandlerFunctions('OkHandler')]
    procedure ModalPageHandlerOkReachesTheCallingAl()
    var
        Row: Record "Test Page Modal Handler Row";
        Host: TestPage "Test Page Modal Host";
    begin
        Initialize();
        SeedRows();

        Host.OpenEdit();
        Host.First();
        Host.PickIt.Invoke();
        Host.Close();

        Assert.IsTrue(Row.Get('RESULT'), 'the calling AL must have recorded a RunModal result');
        Assert.AreEqual('OK', Row.Descr, 'RunModal must have returned OK when the handler invoked OK');
    end;

    // Negative: a cancelling handler must NOT read back as OK. A runner that dispatched to
    // the handler but always answered OK would pass the test above and fail this one.
    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure ModalPageHandlerCancelReachesTheCallingAl()
    var
        Row: Record "Test Page Modal Handler Row";
        Host: TestPage "Test Page Modal Host";
    begin
        Initialize();
        SeedRows();

        Host.OpenEdit();
        Host.First();
        Host.PickIt.Invoke();
        Host.Close();

        Assert.IsTrue(Row.Get('RESULT'), 'the calling AL must have recorded a RunModal result');
        Assert.AreEqual('Cancel', Row.Descr,
            'RunModal must have returned Cancel when the handler cancelled');
    end;

    // Negative: no [HandlerFunctions] at all. The modal page must be refused, and the AL that
    // called RunModal must never see a result — a modal page that quietly returned OK with no
    // handler would make an unattended dialog look like a confirmed one.
    [Test]
    procedure ModalPageWithoutAHandlerIsRefused()
    var
        Row: Record "Test Page Modal Handler Row";
        Host: TestPage "Test Page Modal Host";
    begin
        Initialize();
        SeedRows();
        // asserterror rolls back to the last commit; without this, that rollback also
        // undoes Initialize()'s DeleteAll (this codeunit has no TestIsolation = Function),
        // reverting to the 'RESULT' row an earlier OK/Cancel test in this shared
        // transaction left behind.
        Commit();

        Host.OpenEdit();
        Host.First();
        asserterror Host.PickIt.Invoke();
        Assert.ExpectedError('Unhandled UI');

        Assert.IsFalse(Row.Get('RESULT'),
            'a refused modal page must not have let the calling AL record a result');
    end;

    // Positive: a modal opened as a LOOKUP must close with LookupOK, so AL gated on
    // `RunModal() <> Action::LookupOK` takes the accept branch and the trigger's `var Text`
    // reaches the field.
    [Test]
    [HandlerFunctions('OkHandler')]
    procedure LookupModeModalClosesWithLookupOkAndValueReachesTheField()
    var
        Row: Record "Test Page Modal Handler Row";
        Host: TestPage "Test Page Modal Host";
    begin
        Initialize();
        SeedRows();

        Host.OpenEdit();
        Host.First();
        Host.Picked.Lookup();

        Assert.IsTrue(Row.Get('HANDLER'), 'the [ModalPageHandler] must have run for a lookup-mode modal');
        Assert.AreEqual('PICKED', Host.Picked.Value(),
            'the OnLookup trigger''s var Text must reach the field, which only happens when RunModal reported LookupOK');
        Host.Close();
    end;

    // Negative: a cancelling handler must NOT read back as LookupOK. Without this, mapping
    // every close to LookupOK would pass the test above — the mirror of the bug it fixes.
    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure LookupModeModalCancelLeavesTheFieldUnchanged()
    var
        Host: TestPage "Test Page Modal Host";
    begin
        Initialize();
        SeedRows();

        Host.OpenEdit();
        Host.First();
        Host.Picked.Lookup();

        Assert.AreEqual('', Host.Picked.Value(),
            'a cancelled lookup must leave the field untouched — the OnLookup returned false, so its var Text is discarded');
        Host.Close();
    end;

    // Positive: a handler can drive a control bound to the modal page's own VARIABLE.
    [Test]
    [HandlerFunctions('VarsHandler')]
    procedure ModalPageHandler_CanDriveAPageVariableControl()
    var
        Echo: Record "Test Page Modal Handler Row";
        Host: TestPage "Test Page Modal Host";
    begin
        Initialize();
        SeedRows();

        Host.OpenEdit();
        Host.First();
        Host.PickWithVars.Invoke();
        Host.Close();

        Assert.IsTrue(Echo.Get('MODE'),
            'the handler set the page-variable control, so the page''s OnValidate must have run');
        Assert.AreEqual('Blocks', Echo.Descr,
            'the OnValidate must see the value the handler wrote to the page variable');
    end;

    // Negative: the Rec-bound control on the same modal page must keep working. It resolves
    // through the record and never needed the binding table, so a fix aimed at page
    // variables must not disturb it.
    [Test]
    [HandlerFunctions('VarsHandler')]
    procedure ModalPageHandler_RecBoundControlOnTheSamePageStillResolves()
    var
        Echo: Record "Test Page Modal Handler Row";
        Host: TestPage "Test Page Modal Host";
    begin
        Initialize();
        SeedRows();

        Host.OpenEdit();
        Host.First();
        Host.PickWithVars.Invoke();
        Host.Close();

        Assert.IsTrue(Echo.Get('RECBOUND'),
            'the handler read the Rec-bound control on the modal page');
        Assert.AreEqual('Alpha', Echo.Descr,
            'the Rec-bound control must read the current row''s value');
    end;

    // Positive: a [ModalPageHandler] must be dispatched for a page with NO SourceTable at
    // all (issue #2007) — the ordinary StandardDialog picker/prompt shape, whose controls
    // are bound to page globals rather than a record. The field's own OnValidate running is
    // what proves the handler's SetValue reached the page's AL, not just a stashed value.
    [Test]
    [HandlerFunctions('NoSourceTableOkHandler')]
    procedure ModalPageHandler_DispatchesForAPageWithNoSourceTable()
    var
        Echo: Record "Test Page Modal Handler Row";
        Outcome: Record "Test Page Modal Handler Row";
        Host: TestPage "Test Page Modal Host";
    begin
        Initialize();
        SeedRows();

        Host.OpenEdit();
        Host.First();
        Host.PickWithNoSourceTable.Invoke();
        Host.Close();

        Assert.IsTrue(Echo.Get('NOSRC-MODE'),
            'the field''s OnValidate must have run for a page-variable control on a page with no SourceTable');
        Assert.AreEqual('Blocks', Echo.Descr,
            'the OnValidate must see the value the handler wrote to the page variable');

        Assert.IsTrue(Outcome.Get('NOSRC-RESULT'), 'the calling AL must have recorded a RunModal result');
        Assert.AreEqual('OK', Outcome.Descr,
            'RunModal must have returned OK when the handler invoked OK');
    end;

    // Negative: a cancelling handler on a no-SourceTable page must NOT read back as OK —
    // the mirror of the positive above, and the same shape as
    // ModalPageHandlerCancelReachesTheCallingAl for the Rec-bound page.
    [Test]
    [HandlerFunctions('NoSourceTableCancelHandler')]
    procedure ModalPageHandler_CancelForAPageWithNoSourceTableDoesNotReadBackAsOk()
    var
        Outcome: Record "Test Page Modal Handler Row";
        Host: TestPage "Test Page Modal Host";
    begin
        Initialize();
        SeedRows();

        Host.OpenEdit();
        Host.First();
        Host.PickWithNoSourceTable.Invoke();
        Host.Close();

        Assert.IsTrue(Outcome.Get('NOSRC-RESULT'), 'the calling AL must have recorded a RunModal result');
        Assert.AreEqual('Cancel', Outcome.Descr,
            'RunModal must have returned Cancel when the handler cancelled');
    end;

    [ModalPageHandler]
    procedure NoSourceTableOkHandler(var Modal: TestPage "Test Page Modal NoSrc")
    begin
        Modal.Mode.SetValue('Blocks');
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NoSourceTableCancelHandler(var Modal: TestPage "Test Page Modal NoSrc")
    begin
        Modal.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure VarsHandler(var Modal: TestPage "Test Page Modal Vars")
    var
        Stamp: Record "Test Page Modal Handler Row";
    begin
        Modal.Mode.SetValue('Blocks');

        Modal.First();
        Stamp.Init();
        Stamp."No." := 'RECBOUND';
        Stamp.Descr := CopyStr(Modal.Descr.Value(), 1, MaxStrLen(Stamp.Descr));
        if not Stamp.Insert() then
            Stamp.Modify();

        Modal.OK().Invoke();
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
