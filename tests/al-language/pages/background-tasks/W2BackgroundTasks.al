// Probe: page background tasks under a TestPage. Order of several enqueued tasks, task ids, cancel on a row move, ErrorCode of a failing task, ErrorLevel, RunPageBackgroundTask with completion triggers, and what a worker can do (Delete, DeleteAll, ModifyAll, Commit, Codeunit.Run guarded and unguarded, IsInWriteTransaction).
// Writer QP (al-runtime-rs ask: the TaskId argument of OnPageBackgroundTaskCompleted against the page variable the enqueue filled):
//   page 87144 enqueues two tasks per row from OnAfterGetCurrRecord into the page variables TaskA and TaskB; the completion trigger logs
//   which variable equals its TaskId argument and whether the argument and the variables are nonzero (relations only, no task ids). QP_ tests.
// Settles: md:285 (all tasks run before the call returns and in which order, cancel on row move, task id numbering, ErrorCode, RunPageBackgroundTask(..., true) task id, ErrorLevel), md:286 (other writes, Commit, unguarded run, failing guarded run and the caller's pending rows).

table 68700 "W2 Bg Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Op; Text[30]) { }
        field(3; Level; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 68701 "W2 Bg Log"
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

codeunit 68705 "W2 Bg Noop"
{
    trigger OnRun()
    begin
    end;
}

codeunit 68706 "W2 Bg Failing"
{
    trigger OnRun()
    begin
        Error('W2 inner failure');
    end;
}

codeunit 68702 "W2 Bg Worker"
{
    trigger OnRun()
    var
        Row: Record "W2 Bg Row";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Op: Text;
        Tag: Text;
        Ok: Boolean;
    begin
        Params := Page.GetBackgroundParameters();
        Params.Get('Op', Op);
        Params.Get('Tag', Tag);
        Results.Add('Tag', Tag);
        case Op of
            'echo':
                ;
            'fail':
                Error('W2 worker failed for %1', Tag);
            'notfound':
                Row.Get('NO-SUCH-ROW');
            'delete':
                begin
                    Row."No." := 'PEND';
                    if Row.Delete() then
                        Results.Add('Deleted', 'true')
                    else
                        Results.Add('Deleted', 'false');
                end;
            'deleteall':
                Row.DeleteAll();
            'modifyall':
                Row.ModifyAll(Level, 99);
            'commit':
                Commit();
            'inwritetx':
                Results.Add('InWriteTx', Format(Database.IsInWriteTransaction()));
            'guardedok':
                begin
                    Ok := Codeunit.Run(Codeunit::"W2 Bg Noop");
                    Results.Add('GuardedRun', Format(Ok));
                end;
            'guardedfail':
                begin
                    Ok := Codeunit.Run(Codeunit::"W2 Bg Failing");
                    Results.Add('GuardedRun', Format(Ok));
                    Results.Add('GuardedError', GetLastErrorText());
                end;
            'unguardedok':
                Codeunit.Run(Codeunit::"W2 Bg Noop");
            'unguardedfail':
                Codeunit.Run(Codeunit::"W2 Bg Failing");
        end;
        Page.SetBackgroundTaskResult(Results);
    end;
}

page 68704 "W2 Bg Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Bg Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Op; Rec.Op) { ApplicationArea = All; }
            field(IdsCtl; Ids) { ApplicationArea = All; }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Params: Dictionary of [Text, Text];
        IdA: Integer;
        IdB: Integer;
    begin
        if Rec."No." = '' then
            exit;
        Clear(Params);
        Params.Add('Tag', 'A-' + Rec."No.");
        Params.Add('Op', GetOp());
        CurrPage.EnqueueBackgroundTask(IdA, Codeunit::"W2 Bg Worker", Params, 5000);
        Clear(Params);
        Params.Add('Tag', 'B-' + Rec."No.");
        Params.Add('Op', GetOp());
        CurrPage.EnqueueBackgroundTask(IdB, Codeunit::"W2 Bg Worker", Params, 5000);
        Ids := 'A=' + Format(IdA) + ',B=' + Format(IdB);
    end;

    local procedure GetOp(): Text
    begin
        if Rec.Op = '' then
            exit('echo');
        exit(Rec.Op);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        Log: Codeunit "W2 Bg Log";
        Tag: Text;
    begin
        if not Results.Get('Tag', Tag) then
            Tag := '<none>';
        Log.Add('done(id=' + 'n' + ',tag=' + Tag + ')');
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    var
        Log: Codeunit "W2 Bg Log";
    begin
        Log.Add('error(id=' + 'n' + ',code=' + ErrorCode + ',text=' + ErrorText + ')');
        IsHandled := true;
    end;

    var
        Ids: Text;
}

// Cancels the previous task before it enqueues a new one, the usual pattern.
page 68707 "W2 Bg Cancel Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Bg Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(IdCtl; TaskId) { ApplicationArea = All; }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "W2 Bg Log";
        Params: Dictionary of [Text, Text];
        Cancelled: Boolean;
    begin
        if Rec."No." = '' then
            exit;
        if TaskId <> 0 then begin
            Cancelled := CurrPage.CancelBackgroundTask(TaskId);
            Log.Add('cancel(id=' + 'n' + ')=' + Format(Cancelled));
        end;
        Params.Add('Tag', Rec."No.");
        Params.Add('Op', 'echo');
        CurrPage.EnqueueBackgroundTask(TaskId, Codeunit::"W2 Bg Worker", Params, 5000);
        Log.Add('enqueued(id=' + 'n' + ',for=' + Rec."No." + ')');
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        Log: Codeunit "W2 Bg Log";
        Tag: Text;
    begin
        Results.Get('Tag', Tag);
        Log.Add('done(id=' + 'n' + ',tag=' + Tag + ',current=' + Rec."No." + ')');
    end;

    var
        TaskId: Integer;
}

// The worker fails; the ErrorLevel of the enqueue comes from the row (0 Error, 1 Warning, 2 Ignore).
page 68708 "W2 Bg Level Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Bg Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Level; Rec.Level) { ApplicationArea = All; }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Params: Dictionary of [Text, Text];
        TaskId: Integer;
    begin
        if Rec."No." = '' then
            exit;
        Params.Add('Tag', Rec."No.");
        Params.Add('Op', 'fail');
        case Rec.Level of
            0:
                CurrPage.EnqueueBackgroundTask(TaskId, Codeunit::"W2 Bg Worker", Params, 5000, PageBackgroundTaskErrorLevel::Error);
            1:
                CurrPage.EnqueueBackgroundTask(TaskId, Codeunit::"W2 Bg Worker", Params, 5000, PageBackgroundTaskErrorLevel::Warning);
            2:
                CurrPage.EnqueueBackgroundTask(TaskId, Codeunit::"W2 Bg Worker", Params, 5000, PageBackgroundTaskErrorLevel::Ignore);
        end;
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        Log: Codeunit "W2 Bg Log";
    begin
        Log.Add('done(id=' + 'n' + ')');
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    var
        Log: Codeunit "W2 Bg Log";
    begin
        Log.Add('error(id=' + 'n' + ',row=' + Rec."No." + ',handled_in=false)');
    end;
}

page 87144 "LT QP Bg Id Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Bg Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "W2 Bg Log";
        Params: Dictionary of [Text, Text];
    begin
        if Rec."No." = '' then
            exit;
        Params.Add('Tag', 'A-' + Rec."No.");
        Params.Add('Op', 'echo');
        CurrPage.EnqueueBackgroundTask(TaskA, Codeunit::"W2 Bg Worker", Params, 5000);
        Clear(Params);
        Params.Add('Tag', 'B-' + Rec."No.");
        Params.Add('Op', 'echo');
        CurrPage.EnqueueBackgroundTask(TaskB, Codeunit::"W2 Bg Worker", Params, 5000);
        Log.Add('enqueued(' + Rec."No." + ',a_nonzero=' + Format(TaskA <> 0) + ',b_nonzero=' + Format(TaskB <> 0) + ',a_eq_b=' + Format(TaskA = TaskB) + ')');
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        Log: Codeunit "W2 Bg Log";
        Tag: Text;
        Match: Text;
    begin
        Results.Get('Tag', Tag);
        Match := 'none';
        if TaskId = TaskA then
            Match := 'TaskA';
        if TaskId = TaskB then
            Match += '+TaskB';
        Log.Add('done(tag=' + Tag + ',current=' + Rec."No." + ',arg_nonzero=' + Format(TaskId <> 0) + ',arg_equals=' + Match + ')');
    end;

    var
        TaskA: Integer;
        TaskB: Integer;
}

codeunit 68703 "W2 Bg Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Op: Text)
    var
        Row: Record "W2 Bg Row";
        Log: Codeunit "W2 Bg Log";
    begin
        Row.DeleteAll();
        AddRow('N1', Op, 0);
        AddRow('N2', Op, 0);
        AddRow('N3', Op, 0);
        Log.Take();
    end;

    local procedure AddRow(No: Code[20]; Op: Text[30]; Level: Integer)
    var
        Row: Record "W2 Bg Row";
    begin
        Row."No." := No;
        Row.Op := Op;
        Row.Level := Level;
        Row.Insert();
    end;

    // ---- md:285 ----

    [Test]
    procedure TwoTasks_OrderAndIds_AcrossRows()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Bg Log";
        Pg: TestPage "W2 Bg Card";
    begin
        Seed('echo');
        Pg.OpenView();
        Observer.Observe('open_log', Log.Take());
        Pg.GoToKey('N2');
        Observer.Observe('second_row_log', Log.Take());
        Pg.GoToKey('N3');
        Observer.Observe('third_row_log', Log.Take());
        Pg.Close();
        Observer.Expect('open_log', 'done(id=n,tag=A-N1);done(id=n,tag=B-N1);');
        Observer.Expect('second_row_log', 'done(id=n,tag=A-N1);done(id=n,tag=B-N1);done(id=n,tag=A-N2);done(id=n,tag=B-N2);');
        Observer.Expect('third_row_log', 'done(id=n,tag=A-N1);done(id=n,tag=B-N1);done(id=n,tag=A-N2);done(id=n,tag=B-N2);done(id=n,tag=A-N3);done(id=n,tag=B-N3);');
        Observer.Verify();
    end;

    [Test]
    procedure TwoTasks_NewPageVariableCountsFromOneAgain()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Bg Log";
        Pg: TestPage "W2 Bg Card";
        Second: TestPage "W2 Bg Card";
    begin
        Seed('echo');
        Pg.OpenView();
        Second.OpenView();
        Observer.Observe('log', Log.Take());
        Second.Close();
        Pg.Close();
        Observer.Expect('log', 'done(id=n,tag=A-N1);done(id=n,tag=B-N1);done(id=n,tag=A-N1);done(id=n,tag=B-N1);');
        Observer.Verify();
    end;

    [Test]
    procedure CancelPreviousTask_OnRowMove()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Bg Log";
        Pg: TestPage "W2 Bg Cancel Card";
    begin
        Seed('echo');
        Pg.OpenView();
        Observer.Observe('open_log', Log.Take());
        Pg.GoToKey('N2');
        Observer.Observe('second_row_log', Log.Take());
        Pg.GoToKey('N3');
        Observer.Observe('third_row_log', Log.Take());
        Pg.Close();
        Observer.Expect('open_log', 'done(id=n,tag=N1,current=N1);enqueued(id=n,for=N1);');
        Observer.Expect('second_row_log', 'cancel(id=n)=Yes;done(id=n,tag=N1,current=N1);enqueued(id=n,for=N1);cancel(id=n)=Yes;done(id=n,tag=N2,current=N2);enqueued(id=n,for=N2);');
        Observer.Expect('third_row_log', 'cancel(id=n)=Yes;done(id=n,tag=N1,current=N1);enqueued(id=n,for=N1);cancel(id=n)=Yes;done(id=n,tag=N2,current=N2);enqueued(id=n,for=N2);cancel(id=n)=Yes;done(id=n,tag=N3,current=N3);enqueued(id=n,for=N3);');
        Observer.Verify();
    end;

    [Test]
    procedure FailingTask_ErrorCodeAndText()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Bg Log";
        Pg: TestPage "W2 Bg Card";
    begin
        Seed('fail');
        Pg.OpenView();
        Observer.Observe('error_log', Log.Take());
        Pg.Close();
        Observer.Expect('error_log', 'error(id=n,code=Dialog,text=W2 worker failed for A-N1);error(id=n,code=Dialog,text=W2 worker failed for B-N1);');
        Observer.Verify();
    end;

    [Test]
    procedure FailingTask_DatabaseErrorCode()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Bg Log";
        Pg: TestPage "W2 Bg Card";
    begin
        Seed('notfound');
        Pg.OpenView();
        Observer.Observe('error_log', Log.Take());
        Pg.Close();
        Observer.Expect('error_log', 'error(id=n,code=DB:RecordNotFound,text=The W2 Bg Row does not exist. Identification fields and values: No.=''NO-SUCH-ROW'');error(id=n,code=DB:RecordNotFound,text=The W2 Bg Row does not exist. Identification fields and values: No.=''NO-SUCH-ROW'');');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorLevel_Ignore()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Bg Log";
        Row: Record "W2 Bg Row";
        Pg: TestPage "W2 Bg Level Card";
        Ok: Boolean;
    begin
        Row.DeleteAll();
        AddRow('L1', '', 2);
        Log.Take();
        Ok := OpenLevel(Pg);
        Observer.Observe('open|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Expect('open|ok', 'Yes');
        Observer.Expect('log', 'error(id=n,row=L1,handled_in=false);');
        Observer.Verify();
    end;

    [Test]
    procedure RunPageBackgroundTask_CompletionTriggerAndTaskId()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Bg Log";
        Pg: TestPage "W2 Bg Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Value: Text;
    begin
        Seed('echo');
        Pg.OpenView();
        Log.Take();
        Params.Add('Tag', 'direct');
        Params.Add('Op', 'echo');
        Results := Pg.RunPageBackgroundTask(Codeunit::"W2 Bg Worker", Params, true);
        Observer.Observe('with_completion|log', Log.Take());
        Results.Get('Tag', Value);
        Observer.Observe('with_completion|result', Value);
        Results := Pg.RunPageBackgroundTask(Codeunit::"W2 Bg Worker", Params, true);
        Observer.Observe('second_with_completion|log', Log.Take());
        Results := Pg.RunPageBackgroundTask(Codeunit::"W2 Bg Worker", Params, false);
        Observer.Observe('without_completion|log', Log.Take());
        Pg.Close();
        Observer.Expect('with_completion|log', 'done(id=n,tag=direct);');
        Observer.Expect('with_completion|result', 'direct');
        Observer.Expect('second_with_completion|log', 'done(id=n,tag=direct);');
        Observer.Expect('without_completion|log', '');
        Observer.Verify();
    end;

    [Test]
    procedure RunPageBackgroundTask_FailingWorker_WithCompletionTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Bg Log";
        Pg: TestPage "W2 Bg Card";
        Params: Dictionary of [Text, Text];
        Ok: Boolean;
    begin
        Seed('echo');
        Pg.OpenView();
        Log.Take();
        Params.Add('Tag', 'direct');
        Params.Add('Op', 'fail');
        Ok := RunDirect(Pg, Params, true);
        Observer.Observe('with_completion|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('with_completion');
        Observer.Observe('with_completion|log', Log.Take());
        Ok := RunDirect(Pg, Params, false);
        Observer.Observe('without_completion|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('without_completion');
        Observer.Observe('without_completion|log', Log.Take());
        Observer.Expect('with_completion|ok', 'Yes');
        Observer.Expect('with_completion|log', 'error(id=n,code=Dialog,text=W2 worker failed for direct);');
        Observer.Expect('without_completion|ok', 'No');
        Observer.Expect('without_completion|text', 'W2 worker failed for direct');
        Observer.Expect('without_completion|code', 'Dialog');
        Observer.Expect('without_completion|log', '');
        Observer.Verify();
    end;

    // ---- md:286 what a worker can do ----

    [Test]
    procedure Worker_Delete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WorkerOp(Observer, 'delete');
        Observer.Expect('caller_in_write_transaction_before', 'Yes');
        Observer.Expect('run|ok', 'No');
        Observer.Expect('run|text', 'Sorry, the current permissions prevented the action. (TableData 68700 W2 Bg Row Delete: AL Language Coverage Tests)');
        Observer.Expect('run|code', 'DB:ReadOnlySession');
        Observer.Expect('pending_row_exists', 'Yes');
        Observer.Expect('rows_after', '1');
        Observer.Expect('pending_level', '7');
        Observer.Expect('caller_in_write_transaction_after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Worker_Commit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WorkerOp(Observer, 'commit');
        Observer.Expect('caller_in_write_transaction_before', 'Yes');
        Observer.Expect('run|ok', 'Yes');
        Observer.Expect('result|Tag', 'w');
        Observer.Expect('pending_row_exists', 'Yes');
        Observer.Expect('rows_after', '1');
        Observer.Expect('pending_level', '7');
        Observer.Expect('caller_in_write_transaction_after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Worker_IsInWriteTransaction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WorkerOp(Observer, 'inwritetx');
        Observer.Expect('caller_in_write_transaction_before', 'Yes');
        Observer.Expect('run|ok', 'Yes');
        Observer.Expect('result|Tag', 'w');
        Observer.Expect('result|InWriteTx', 'No');
        Observer.Expect('pending_row_exists', 'Yes');
        Observer.Expect('rows_after', '1');
        Observer.Expect('pending_level', '7');
        Observer.Expect('caller_in_write_transaction_after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Worker_GuardedRunSucceeds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WorkerOp(Observer, 'guardedok');
        Observer.Expect('caller_in_write_transaction_before', 'Yes');
        Observer.Expect('run|ok', 'Yes');
        Observer.Expect('result|Tag', 'w');
        Observer.Expect('result|GuardedRun', 'Yes');
        Observer.Expect('pending_row_exists', 'Yes');
        Observer.Expect('rows_after', '1');
        Observer.Expect('pending_level', '7');
        Observer.Expect('caller_in_write_transaction_after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Worker_GuardedRunFails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WorkerOp(Observer, 'guardedfail');
        Observer.Expect('caller_in_write_transaction_before', 'Yes');
        Observer.Expect('run|ok', 'Yes');
        Observer.Expect('result|Tag', 'w');
        Observer.Expect('result|GuardedRun', 'No');
        Observer.Expect('result|GuardedError', 'W2 inner failure');
        Observer.Expect('pending_row_exists', 'Yes');
        Observer.Expect('rows_after', '1');
        Observer.Expect('pending_level', '7');
        Observer.Expect('caller_in_write_transaction_after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Worker_UnguardedRunSucceeds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WorkerOp(Observer, 'unguardedok');
        Observer.Expect('caller_in_write_transaction_before', 'Yes');
        Observer.Expect('run|ok', 'Yes');
        Observer.Expect('result|Tag', 'w');
        Observer.Expect('pending_row_exists', 'Yes');
        Observer.Expect('rows_after', '1');
        Observer.Expect('pending_level', '7');
        Observer.Expect('caller_in_write_transaction_after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Worker_UnguardedRunFails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WorkerOp(Observer, 'unguardedfail');
        Observer.Expect('caller_in_write_transaction_before', 'Yes');
        Observer.Expect('run|ok', 'No');
        Observer.Expect('run|text', 'W2 inner failure');
        Observer.Expect('run|code', 'Dialog');
        Observer.Expect('pending_row_exists', 'Yes');
        Observer.Expect('rows_after', '1');
        Observer.Expect('pending_level', '7');
        Observer.Expect('caller_in_write_transaction_after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Worker_PlainError_CallerRowsSurvive()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WorkerOp(Observer, 'fail');
        Observer.Expect('caller_in_write_transaction_before', 'Yes');
        Observer.Expect('run|ok', 'No');
        Observer.Expect('run|text', 'W2 worker failed for w');
        Observer.Expect('run|code', 'Dialog');
        Observer.Expect('pending_row_exists', 'Yes');
        Observer.Expect('rows_after', '1');
        Observer.Expect('pending_level', '7');
        Observer.Expect('caller_in_write_transaction_after', 'Yes');
        Observer.Verify();
    end;

    // The caller has an uncommitted row 'PEND' and a page open. The worker runs one operation through RunPageBackgroundTask (no completion triggers).
    local procedure WorkerOp(var Observer: Codeunit "Probe Observer"; Op: Text)
    var
        Row: Record "W2 Bg Row";
        Pg: TestPage "W2 Bg Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        ResultKey: Text;
        Value: Text;
        Ok: Boolean;
    begin
        Row.DeleteAll();
        AddRow('PEND', 'echo', 7);
        Observer.Observe('caller_in_write_transaction_before', Format(Database.IsInWriteTransaction()));
        Pg.OpenView();
        Params.Add('Tag', 'w');
        Params.Add('Op', Op);
        Ok := RunDirect(Pg, Params, false, Results);
        Observer.Observe('run|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('run');
        foreach ResultKey in Results.Keys() do begin
            Results.Get(ResultKey, Value);
            Observer.Observe('result|' + ResultKey, Value);
        end;
        Pg.Close();
        Observer.Observe('pending_row_exists', Format(Row.Get('PEND')));
        Observer.Observe('rows_after', Format(Row.Count()));
        if Row.Get('PEND') then
            Observer.Observe('pending_level', Format(Row.Level));
        Observer.Observe('caller_in_write_transaction_after', Format(Database.IsInWriteTransaction()));
    end;

    [TryFunction]
    local procedure RunDirect(var Pg: TestPage "W2 Bg Card"; Params: Dictionary of [Text, Text]; Completion: Boolean; var Results: Dictionary of [Text, Text])
    begin
        Results := Pg.RunPageBackgroundTask(Codeunit::"W2 Bg Worker", Params, Completion);
    end;

    [TryFunction]
    local procedure RunDirect(var Pg: TestPage "W2 Bg Card"; Params: Dictionary of [Text, Text]; Completion: Boolean)
    var
        Results: Dictionary of [Text, Text];
    begin
        Results := Pg.RunPageBackgroundTask(Codeunit::"W2 Bg Worker", Params, Completion);
    end;

    [TryFunction]
    local procedure OpenLevel(var Pg: TestPage "W2 Bg Level Card")
    begin
        Pg.OpenView();
    end;

    [Test]
    procedure QP_CompletedTaskId_AgainstPageVariable_OpenView()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Bg Log";
        Pg: TestPage "LT QP Bg Id Card";
    begin
        Seed('echo');
        Pg.OpenView();
        Observer.Observe('open_log', Log.Take());
        Pg.GoToKey('N2');
        Observer.Observe('second_row_log', Log.Take());
        Pg.Close();
        Observer.Expect('open_log', 'done(tag=A-N1,current=N1,arg_nonzero=Yes,arg_equals=TaskA);done(tag=B-N1,current=N1,arg_nonzero=Yes,arg_equals=none+TaskB);enqueued(N1,a_nonzero=Yes,b_nonzero=Yes,a_eq_b=No);');
        Observer.Expect('second_row_log', 'done(tag=A-N1,current=N1,arg_nonzero=Yes,arg_equals=TaskA);done(tag=B-N1,current=N1,arg_nonzero=Yes,arg_equals=none+TaskB);enqueued(N1,a_nonzero=Yes,b_nonzero=Yes,a_eq_b=No);done(tag=A-N2,current=N2,arg_nonzero=Yes,arg_equals=TaskA);done(tag=B-N2,current=N2,arg_nonzero=Yes,arg_equals=none+TaskB);enqueued(N2,a_nonzero=Yes,b_nonzero=Yes,a_eq_b=No);');
        Observer.Verify();
    end;
}
