// Probe: a Page variable constructs the page at first use (OnInit), a second run of the same variable, setters between runs, and Clear of Page and TestPage variables in every state.
// Settles: md:273 (second run, setter between runs, construct-on-first-call), md:274 (Clear of a closed, open and trapping variable; the part-page case cannot be written, see the manifest).
// Corpus issue 667 (writer CE): after Run() (not modal) the variable is a fresh page again (GetStep runs OnInit and reads 100), a second Run() runs OnInit again without error, SetTableView then RunModal a second time raises no error, LookupMode() of a fresh variable is false (and constructs the page).

codeunit 68674 "W2 Init Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 68673 "W2 Init Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Value Row";
    SourceTableTemporary = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(StepCtl; Step)
            {
                ApplicationArea = All;
            }
        }
    }

    var
        Step: Integer;

    procedure SetStep(NewStep: Integer)
    var
        Log: Codeunit "W2 Init Log";
    begin
        Log.Add('SetStep(' + Format(NewStep) + ')');
        Step := NewStep;
    end;

    procedure GetStep(): Integer
    var
        Log: Codeunit "W2 Init Log";
    begin
        Log.Add('GetStep');
        exit(Step);
    end;

    trigger OnInit()
    var
        Log: Codeunit "W2 Init Log";
    begin
        Log.Add('OnInit');
        Step := 100;
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "W2 Init Log";
    begin
        Log.Add('OnOpenPage(step=' + Format(Step) + ')');
    end;
}

codeunit 68675 "W2 Init Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // ---- md:273 ----

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure PageVariable_RunModalTwice()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Init Log";
        Pg: Page "W2 Init Card";
    begin
        Log.Take();
        Pg.RunModal();
        Observer.Observe('first_run', Log.Take());
        Pg.RunModal();
        Observer.Observe('second_run', Log.Take());
        Pg.RunModal();
        Observer.Observe('third_run', Log.Take());
        Observer.Expect('first_run', 'OnInit;OnOpenPage(step=100);Handler(step=100);');
        Observer.Expect('second_run', 'OnOpenPage(step=100);Handler(step=100);');
        Observer.Expect('third_run', 'OnOpenPage(step=100);Handler(step=100);');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure PageVariable_SetterBetweenRuns()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Init Log";
        Pg: Page "W2 Init Card";
    begin
        Log.Take();
        Pg.SetStep(5);
        Observer.Observe('setter_first', Log.Take());
        Pg.RunModal();
        Observer.Observe('first_run', Log.Take());
        Pg.SetStep(7);
        Observer.Observe('setter_second', Log.Take());
        Pg.RunModal();
        Observer.Observe('second_run', Log.Take());
        Observer.Observe('step_after', Format(Pg.GetStep()));
        Observer.Observe('getter', Log.Take());
        Observer.Expect('setter_first', 'OnInit;SetStep(5);');
        Observer.Expect('first_run', 'OnOpenPage(step=5);Handler(step=5);');
        Observer.Expect('setter_second', 'SetStep(7);');
        Observer.Expect('second_run', 'OnOpenPage(step=7);Handler(step=7);');
        Observer.Expect('step_after', '7');
        Observer.Expect('getter', 'GetStep;');
        Observer.Verify();
    end;

    [Test]
    procedure PageVariable_GetterConstructsTheInstance()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Init Log";
        Pg: Page "W2 Init Card";
    begin
        Log.Take();
        Observer.Observe('step_first_call', Format(Pg.GetStep()));
        Observer.Observe('first_call', Log.Take());
        Observer.Observe('step_second_call', Format(Pg.GetStep()));
        Observer.Observe('second_call', Log.Take());
        Observer.Expect('step_first_call', '100');
        Observer.Expect('first_call', 'OnInit;GetStep;');
        Observer.Expect('step_second_call', '100');
        Observer.Expect('second_call', 'GetStep;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure PageVariable_GetterBeforeRunModal()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Init Log";
        Pg: Page "W2 Init Card";
    begin
        Log.Take();
        Pg.SetStep(Pg.GetStep() + 1);
        Observer.Observe('before_run', Log.Take());
        Pg.RunModal();
        Observer.Observe('run', Log.Take());
        Observer.Expect('before_run', 'OnInit;GetStep;SetStep(101);');
        Observer.Expect('run', 'OnOpenPage(step=101);Handler(step=101);');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure PageVariable_ClearBetweenRuns()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Init Log";
        Pg: Page "W2 Init Card";
    begin
        Log.Take();
        Pg.SetStep(5);
        Pg.RunModal();
        Log.Take();
        Clear(Pg);
        Observer.Observe('after_clear', Log.Take());
        Observer.Observe('step_after_clear', Format(Pg.GetStep()));
        Observer.Observe('getter', Log.Take());
        Pg.RunModal();
        Observer.Observe('run_after_clear', Log.Take());
        Observer.Expect('after_clear', '');
        Observer.Expect('step_after_clear', '100');
        Observer.Expect('getter', 'OnInit;GetStep;');
        Observer.Expect('run_after_clear', 'OnOpenPage(step=100);Handler(step=100);');
        Observer.Verify();
    end;

    // ---- md:274 ----

    [Test]
    procedure Clear_ClosedTestPage_GivesAFreshClosedOne()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Init Log";
        Pg: TestPage "W2 Init Card";
        Ok: Boolean;
    begin
        Log.Take();
        Pg.OpenEdit();
        Observer.Observe('open', Log.Take());
        Pg.Close();
        Clear(Pg);
        Observer.Observe('after_clear', Log.Take());
        Ok := ReadStep(Pg);
        Observer.Observe('read_closed|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('read_closed');
        Pg.OpenEdit();
        Observer.Observe('open_again', Log.Take());
        Observer.Observe('read_open', Pg.StepCtl.Value());
        Pg.Close();
        Observer.Expect('open', 'OnInit;OnOpenPage(step=100);');
        Observer.Expect('after_clear', '');
        Observer.Expect('read_closed|ok', 'No');
        Observer.Expect('read_closed|text', 'The TestPage is not open.');
        Observer.Expect('read_closed|code', 'TestPageNotOpened');
        Observer.Expect('open_again', 'OnInit;OnOpenPage(step=100);');
        Observer.Expect('read_open', '100');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_OpenTestPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Init Log";
        Pg: TestPage "W2 Init Card";
        Ok: Boolean;
    begin
        Log.Take();
        Pg.OpenEdit();
        Log.Take();
        Clear(Pg);
        Observer.Observe('after_clear', Log.Take());
        Ok := ReadStep(Pg);
        Observer.Observe('read_after_clear|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('read_after_clear');
        Ok := ClosePage(Pg);
        Observer.Observe('close_after_clear|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('close_after_clear');
        Pg.OpenEdit();
        Observer.Observe('open_again', Log.Take());
        Pg.Close();
        Observer.Expect('after_clear', '');
        Observer.Expect('read_after_clear|ok', 'No');
        Observer.Expect('read_after_clear|text', 'The TestPage is not open.');
        Observer.Expect('read_after_clear|code', 'TestPageNotOpened');
        Observer.Expect('close_after_clear|ok', 'No');
        Observer.Expect('close_after_clear|text', 'The TestPage is not open.');
        Observer.Expect('close_after_clear|code', 'TestPageNotOpened');
        Observer.Expect('open_again', 'OnInit;OnOpenPage(step=100);');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_TrappingTestPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Init Log";
        Pg: TestPage "W2 Init Card";
        Ok: Boolean;
    begin
        Log.Take();
        Pg.Trap();
        Clear(Pg);
        Ok := RunPageNow();
        Observer.Observe('run_after_clear|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('run_after_clear');
        Observer.Observe('log', Log.Take());
        Ok := ReadStep(Pg);
        Observer.Observe('read_trapped|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('read_trapped');
        Observer.Expect('run_after_clear|ok', 'No');
        Observer.Expect('run_after_clear|text', 'Unhandled UI: Page 68673');
        Observer.Expect('run_after_clear|code', 'MissingUIHandler');
        Observer.Expect('log', 'OnInit;');
        Observer.Expect('read_trapped|ok', 'No');
        Observer.Expect('read_trapped|text', 'The TestPage is not open.');
        Observer.Expect('read_trapped|code', 'TestPageNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure Trap_ThenRun_WithoutClear()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Init Log";
        Pg: TestPage "W2 Init Card";
        Ok: Boolean;
    begin
        Log.Take();
        Pg.Trap();
        Ok := RunPageNow();
        Observer.Observe('run|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('run');
        Observer.Observe('log', Log.Take());
        Ok := ReadStep(Pg);
        Observer.Observe('read_trapped|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('read_trapped');
        Observer.Expect('run|ok', 'Yes');
        Observer.Expect('log', 'OnInit;OnOpenPage(step=100);');
        Observer.Expect('read_trapped|ok', 'Yes');
        Observer.Verify();
    end;

    // ---- corpus issue 667 (writer CE): Run against RunModal on the same Page variable ----

    [Test]
    [HandlerFunctions('CardPageHandler')]
    procedure PageVariable_RunThenGetter()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Init Log";
        Pg: Page "W2 Init Card";
    begin
        Log.Take();
        Pg.SetStep(5);
        Pg.Run();
        Observer.Observe('run', Log.Take());
        Observer.Observe('step_after', Format(Pg.GetStep()));
        Observer.Observe('getter', Log.Take());
        Observer.Expect('run', 'OnInit;SetStep(5);OnOpenPage(step=5);PageHandler(step=5);');
        Observer.Expect('step_after', '100');
        Observer.Expect('getter', 'OnInit;GetStep;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardPageHandler')]
    procedure PageVariable_RunTwice()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Init Log";
        Pg: Page "W2 Init Card";
        Ok: Boolean;
    begin
        Log.Take();
        Pg.Run();
        Observer.Observe('first_run', Log.Take());
        Ok := RunAgain(Pg);
        Observer.Observe('second_run|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('second_run');
        Observer.Observe('second_run', Log.Take());
        Observer.Expect('first_run', 'OnInit;OnOpenPage(step=100);PageHandler(step=100);');
        Observer.Expect('second_run|ok', 'Yes');
        Observer.Expect('second_run', 'OnInit;OnOpenPage(step=100);PageHandler(step=100);');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure PageVariable_SetTableViewBetweenRunModal()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Init Log";
        Row: Record "W2 Value Row";
        Pg: Page "W2 Init Card";
        Ok: Boolean;
    begin
        Log.Take();
        Row.SetRange(Id, 1);
        Pg.SetTableView(Row);
        Pg.RunModal();
        Observer.Observe('first_run', Log.Take());
        Row.SetRange(Id, 2);
        Ok := SetViewAndRunModal(Pg, Row);
        Observer.Observe('second_run|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('second_run');
        Observer.Observe('second_run', Log.Take());
        Observer.Expect('first_run', 'OnInit;OnOpenPage(step=100);Handler(step=100);');
        Observer.Expect('second_run|ok', 'Yes');
        Observer.Expect('second_run', 'OnOpenPage(step=100);Handler(step=100);');
        Observer.Verify();
    end;

    [Test]
    procedure PageVariable_LookupModeDefault()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Init Log";
        Pg: Page "W2 Init Card";
    begin
        Log.Take();
        Observer.Observe('default', Format(Pg.LookupMode()));
        Observer.Observe('log', Log.Take());
        Pg.LookupMode(true);
        Observer.Observe('after_set', Format(Pg.LookupMode()));
        Observer.Expect('default', 'No');
        Observer.Expect('log', 'OnInit;');
        Observer.Expect('after_set', 'Yes');
        Observer.Verify();
    end;

    [PageHandler]
    procedure CardPageHandler(var Pg: TestPage "W2 Init Card")
    var
        Log: Codeunit "W2 Init Log";
    begin
        Log.Add('PageHandler(step=' + Pg.StepCtl.Value() + ')');
    end;

    [TryFunction]
    local procedure RunAgain(var Pg: Page "W2 Init Card")
    begin
        Pg.Run();
    end;

    [TryFunction]
    local procedure SetViewAndRunModal(var Pg: Page "W2 Init Card"; var Row: Record "W2 Value Row")
    begin
        Pg.SetTableView(Row);
        Pg.RunModal();
    end;

    [ModalPageHandler]
    procedure CardHandler(var Pg: TestPage "W2 Init Card")
    var
        Log: Codeunit "W2 Init Log";
    begin
        Log.Add('Handler(step=' + Pg.StepCtl.Value() + ')');
    end;

    [TryFunction]
    local procedure ReadStep(var Pg: TestPage "W2 Init Card")
    var
        Dummy: Text;
    begin
        Dummy := Pg.StepCtl.Value();
    end;

    [TryFunction]
    local procedure ClosePage(var Pg: TestPage "W2 Init Card")
    begin
        Pg.Close();
    end;

    [TryFunction]
    local procedure RunPageNow()
    begin
        Page.Run(Page::"W2 Init Card");
    end;
}
