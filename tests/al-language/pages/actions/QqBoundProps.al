// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in QqBoundObjects.al
// Probe: AL Runner issue 3762. An action or an action group whose Visible or Enabled is a procedure call (warning AL0573): what the TestPage
// action answers for Visible() and Enabled(), what Invoke() does, and whether the procedure runs. On BC 27.5, 28.5 and 29.0 the property
// reads No whatever the procedure returns and the procedure never runs; Invoke runs OnAction when Visible reads No and skips it when Enabled reads No. Actions bound to a Boolean variable and an
// action with no property are the comparison.
// BC versions: 27+

codeunit 87203 "LT QQ Bound Props"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT QQ Bound Log";

    local procedure Setup()
    var
        Row: Record "LT QQ Bound Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Log.Clear();
    end;

    [Test]
    procedure QQ_ProcBound_VisibleEnabled()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QQ Bound Card";
    begin
        // BC 27.5, 28.5 and 29.0: a property bound to a procedure call reads No whatever the procedure returns, also on an action inside
        // a group bound that way, and the procedure never runs (the log holds only OnOpenPage).
        Setup();
        Card.OpenView();
        Observer.Observe('log after open', Log.Read());
        Observer.Observe('VisibleTrueProc visible', Format(Card.VisibleTrueProc.Visible()));
        Observer.Observe('VisibleTrueProc enabled', Format(Card.VisibleTrueProc.Enabled()));
        Observer.Observe('VisibleFalseProc visible', Format(Card.VisibleFalseProc.Visible()));
        Observer.Observe('VisibleFalseProc enabled', Format(Card.VisibleFalseProc.Enabled()));
        Observer.Observe('EnabledTrueProc visible', Format(Card.EnabledTrueProc.Visible()));
        Observer.Observe('EnabledTrueProc enabled', Format(Card.EnabledTrueProc.Enabled()));
        Observer.Observe('EnabledFalseProc visible', Format(Card.EnabledFalseProc.Visible()));
        Observer.Observe('EnabledFalseProc enabled', Format(Card.EnabledFalseProc.Enabled()));
        Observer.Observe('VisibleVariable visible', Format(Card.VisibleVariable.Visible()));
        Observer.Observe('EnabledVariable enabled', Format(Card.EnabledVariable.Enabled()));
        Observer.Observe('NoProperty visible', Format(Card.NoProperty.Visible()));
        Observer.Observe('NoProperty enabled', Format(Card.NoProperty.Enabled()));
        Observer.Observe('InGroupVisibleProc visible', Format(Card.InGroupVisibleProc.Visible()));
        Observer.Observe('InGroupVisibleProc enabled', Format(Card.InGroupVisibleProc.Enabled()));
        Observer.Observe('InGroupVisibleVariable visible', Format(Card.InGroupVisibleVariable.Visible()));
        Observer.Observe('log after reads', Log.Read());
        Card.Close();
        Observer.Expect('log after open', 'OnOpenPage');
        Observer.Expect('VisibleTrueProc visible', 'No');
        Observer.Expect('VisibleTrueProc enabled', 'Yes');
        Observer.Expect('VisibleFalseProc visible', 'No');
        Observer.Expect('VisibleFalseProc enabled', 'Yes');
        Observer.Expect('EnabledTrueProc visible', 'Yes');
        Observer.Expect('EnabledTrueProc enabled', 'No');
        Observer.Expect('EnabledFalseProc visible', 'Yes');
        Observer.Expect('EnabledFalseProc enabled', 'No');
        Observer.Expect('VisibleVariable visible', 'Yes');
        Observer.Expect('EnabledVariable enabled', 'Yes');
        Observer.Expect('NoProperty visible', 'Yes');
        Observer.Expect('NoProperty enabled', 'Yes');
        Observer.Expect('InGroupVisibleProc visible', 'No');
        Observer.Expect('InGroupVisibleProc enabled', 'Yes');
        Observer.Expect('InGroupVisibleVariable visible', 'Yes');
        Observer.Expect('log after reads', 'OnOpenPage');
        Observer.Verify();
    end;

    [Test]
    procedure QQ_Invoke_VisibleTrueProc()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QQ Bound Card";
    begin
        // An error in asserterror closes the test page, so every Invoke has a test of its own. Invoke raises no error of its own on any of
        // these actions (the error is the Error('') after it): OnAction runs on an action that reads Visible = No, and is skipped without
        // an error on one that reads Enabled = No.
        Setup();
        Card.OpenView();
        Log.Clear();
        asserterror begin
            Card.VisibleTrueProc.Invoke();
            Error('');
        end;
        Observer.ObserveError('invoke');
        Observer.Observe('log', Log.Read());
        Observer.Expect('invoke|text', '');
        Observer.Expect('invoke|code', 'Dialog');
        Observer.Expect('log', 'action VisibleTrueProc');
        Observer.Verify();
    end;

    [Test]
    procedure QQ_Invoke_VisibleFalseProc()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QQ Bound Card";
    begin
        // An error in asserterror closes the test page, so every Invoke has a test of its own.
        Setup();
        Card.OpenView();
        Log.Clear();
        asserterror begin
            Card.VisibleFalseProc.Invoke();
            Error('');
        end;
        Observer.ObserveError('invoke');
        Observer.Observe('log', Log.Read());
        Observer.Expect('invoke|text', '');
        Observer.Expect('invoke|code', 'Dialog');
        Observer.Expect('log', 'action VisibleFalseProc');
        Observer.Verify();
    end;

    [Test]
    procedure QQ_Invoke_EnabledTrueProc()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QQ Bound Card";
    begin
        // An error in asserterror closes the test page, so every Invoke has a test of its own.
        Setup();
        Card.OpenView();
        Log.Clear();
        asserterror begin
            Card.EnabledTrueProc.Invoke();
            Error('');
        end;
        Observer.ObserveError('invoke');
        Observer.Observe('log', Log.Read());
        Observer.Expect('invoke|text', '');
        Observer.Expect('invoke|code', 'Dialog');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure QQ_Invoke_EnabledFalseProc()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QQ Bound Card";
    begin
        // An error in asserterror closes the test page, so every Invoke has a test of its own.
        Setup();
        Card.OpenView();
        Log.Clear();
        asserterror begin
            Card.EnabledFalseProc.Invoke();
            Error('');
        end;
        Observer.ObserveError('invoke');
        Observer.Observe('log', Log.Read());
        Observer.Expect('invoke|text', '');
        Observer.Expect('invoke|code', 'Dialog');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure QQ_Invoke_InGroupVisibleProc()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QQ Bound Card";
    begin
        // An error in asserterror closes the test page, so every Invoke has a test of its own.
        Setup();
        Card.OpenView();
        Log.Clear();
        asserterror begin
            Card.InGroupVisibleProc.Invoke();
            Error('');
        end;
        Observer.ObserveError('invoke');
        Observer.Observe('log', Log.Read());
        Observer.Expect('invoke|text', '');
        Observer.Expect('invoke|code', 'Dialog');
        Observer.Expect('log', 'action InGroupVisibleProc');
        Observer.Verify();
    end;

    [Test]
    procedure QQ_Invoke_NoProperty()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QQ Bound Card";
    begin
        // An error in asserterror closes the test page, so every Invoke has a test of its own.
        Setup();
        Card.OpenView();
        Log.Clear();
        asserterror begin
            Card.NoProperty.Invoke();
            Error('');
        end;
        Observer.ObserveError('invoke');
        Observer.Observe('log', Log.Read());
        Observer.Expect('invoke|text', '');
        Observer.Expect('invoke|code', 'Dialog');
        Observer.Expect('log', 'action NoProperty');
        Observer.Verify();
    end;

    [Test]
    procedure QQ_ProcBound_EditMode()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QQ Bound Card";
    begin
        // The same reads on a page opened for edit, after a move to the row.
        Setup();
        Card.OpenEdit();
        Card.GoToKey(1);
        Observer.Observe('VisibleTrueProc visible', Format(Card.VisibleTrueProc.Visible()));
        Observer.Observe('VisibleFalseProc visible', Format(Card.VisibleFalseProc.Visible()));
        Observer.Observe('EnabledTrueProc enabled', Format(Card.EnabledTrueProc.Enabled()));
        Observer.Observe('EnabledFalseProc enabled', Format(Card.EnabledFalseProc.Enabled()));
        Observer.Observe('InGroupVisibleProc visible', Format(Card.InGroupVisibleProc.Visible()));
        Observer.Observe('log', Log.Read());
        Card.Close();
        Observer.Expect('VisibleTrueProc visible', 'No');
        Observer.Expect('VisibleFalseProc visible', 'No');
        Observer.Expect('EnabledTrueProc enabled', 'No');
        Observer.Expect('EnabledFalseProc enabled', 'No');
        Observer.Expect('InGroupVisibleProc visible', 'No');
        Observer.Expect('log', 'OnOpenPage');
        Observer.Verify();
    end;
}
