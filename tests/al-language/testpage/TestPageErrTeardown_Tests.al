// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-close-method
// Scope: in-scope
// Fixtures used: TestPage ErrTeardown Row (60796), TestPage ErrTeardown Card (60797), Assert (60021)
//
// Measured against a real BC service tier (27.5 and 28.3) while investigating AL Runner#2656:
// an unhandled error raised inside the page's own record-POSITIONING trigger
// (OnAfterGetRecord), fired by a TestPage navigation call (GoToRecord) on an ALREADY-OPEN
// TestPage, tears down the TestPage's underlying client session. Every subsequent call on
// that same TestPage variable -- including the navigation call itself, Close(), and a plain
// field read -- then raises BC's own "The TestPage is not open.", not the trigger's own
// error text.
//
// This is NOT a blanket "any unhandled trigger error tears the page down" rule: an unhandled
// error from OnValidate (field validation) or OnAction (action invocation) propagates with
// its OWN error text and does NOT tear the page down -- Close() afterward succeeds normally.
// Only the record-positioning trigger does this.

codeunit 60795 "TestPage ErrTeardown Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TestPage ErrTeardown Row";
    begin
        Row.DeleteAll();
    end;

    local procedure Seed(No: Code[20]; FailOnGet: Boolean; FailOnValidate: Boolean)
    var
        Row: Record "TestPage ErrTeardown Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Name := 'Init';
        Row.FailOnGet := FailOnGet;
        Row.FailOnValidate := FailOnValidate;
        Row.Insert();
    end;

    // Positive: an unhandled error in OnAfterGetRecord, fired by GoToRecord on an already-open
    // TestPage, propagates out of GoToRecord itself -- but as BC's own teardown message, not the
    // trigger's own error text.
    [Test]
    procedure GoToRecordUnhandledPositioningError_TearsDownTestPage()
    var
        Row: Record "TestPage ErrTeardown Row";
        Card: TestPage "TestPage ErrTeardown Card";
    begin
        Initialize();
        Seed('A-OK', false, false);
        Seed('Z-FAILGET', true, false);
        Row.Get('Z-FAILGET');

        Card.OpenView();
        asserterror Card.GoToRecord(Row);
        Assert.ExpectedError('The TestPage is not open');
    end;

    // Positive: the teardown is not scoped to just the failing call -- Close() on the same,
    // now-torn-down TestPage variable also raises "The TestPage is not open.", not a normal
    // successful close.
    [Test]
    procedure TornDownTestPage_CloseAlsoRaisesNotOpen()
    var
        Row: Record "TestPage ErrTeardown Row";
        Card: TestPage "TestPage ErrTeardown Card";
    begin
        Initialize();
        Seed('A-OK', false, false);
        Seed('Z-FAILGET', true, false);
        Row.Get('Z-FAILGET');

        Card.OpenView();
        asserterror Card.GoToRecord(Row);

        asserterror Card.Close();
        Assert.ExpectedError('The TestPage is not open');
    end;

    // Positive: nor is it scoped to write-shaped calls -- a plain field read after the teardown
    // raises the same "The TestPage is not open.".
    [Test]
    procedure TornDownTestPage_FieldReadAlsoRaisesNotOpen()
    var
        Row: Record "TestPage ErrTeardown Row";
        Card: TestPage "TestPage ErrTeardown Card";
        Ignored: Text;
    begin
        Initialize();
        Seed('A-OK', false, false);
        Seed('Z-FAILGET', true, false);
        Row.Get('Z-FAILGET');

        Card.OpenView();
        asserterror Card.GoToRecord(Row);

        asserterror Ignored := Card.NoCtl.Value();
        Assert.ExpectedError('The TestPage is not open');
    end;

    // Negative: an unhandled error from OnValidate propagates with its OWN error text -- proves
    // the teardown above is specific to the record-positioning trigger, not a blanket rule for
    // any unhandled trigger error on a TestPage.
    [Test]
    procedure UnhandledOnValidateError_DoesNotTearDownTestPage()
    var
        Card: TestPage "TestPage ErrTeardown Card";
    begin
        Initialize();
        Seed('VAL-1', false, true);

        Card.OpenView();
        Card.GoToKey('VAL-1');
        asserterror Card.NameCtl.SetValue('New Name');
        Assert.ExpectedError('Deliberate OnValidate failure for VAL-1');

        // The page is still open: Close() must succeed normally, unlike the positioning-error case.
        Card.Close();
    end;

    // Negative: same shape for OnAction -- an unhandled action error propagates with its own
    // text and does not tear the TestPage down either.
    [Test]
    procedure UnhandledOnActionError_DoesNotTearDownTestPage()
    var
        Card: TestPage "TestPage ErrTeardown Card";
    begin
        Initialize();
        Seed('ACT-1', false, false);

        Card.OpenView();
        Card.GoToKey('ACT-1');
        asserterror Card.FailAction.Invoke();
        Assert.ExpectedError('Deliberate OnAction failure');

        Card.Close();
    end;
}
