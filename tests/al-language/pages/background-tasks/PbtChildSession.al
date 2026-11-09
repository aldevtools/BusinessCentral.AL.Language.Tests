// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-enqueuebackgroundtask-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-runpagebackgroundtask-method
// Scope: in-scope
// Fixtures used: Test Page BgTask Row (60790), Probe Observer (69160)
// Probe: AL Runner issue 7342. The worker of a page background task runs in a child session. What it shares with the test session and what it does not:
//   SessionId(), the state of a SingleInstance codeunit (what the test set before, what the task sets, whether a second task sees the first task's state),
//   a manual event subscriber the test bound with BindSubscription, an automatic subscriber, and what OnPageBackgroundTaskCompleted and
//   OnPageBackgroundTaskError receive when the task needs a manual binding the child session does not have.
// Pinned elsewhere, not repeated: the rows of the test (committed and uncommitted) the worker reads (testpage/TestPageBgTaskTx_Tests.al), the refused
//   writes of the worker (testpage/TestPageBgTask_Tests.al), the order of several tasks, task ids and ErrorCode (W2BackgroundTasks.al).
// BC versions: 27 - 29

// local object: the worker of a page background task runs in a child session, so its own objects (and a SingleInstance state) are the subject
codeunit 77300 "PBT Child State"
{
    SingleInstance = true;

    var
        Value: Text;
        Calls: Integer;

    procedure Set(NewValue: Text)
    begin
        Value := NewValue;
    end;

    procedure Get(): Text
    begin
        exit(Value);
    end;

    procedure Bump(): Integer
    begin
        Calls += 1;
        exit(Calls);
    end;

    procedure Reset()
    begin
        Value := '';
        Calls := 0;
    end;
}

codeunit 77301 "PBT Child Worker"
{
    trigger OnRun()
    var
        State: Codeunit "PBT Child State";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Mode: Text;
        Manual: Text;
        Auto: Text;
        SeenState: Text;
    begin
        Params := Page.GetBackgroundParameters();
        Params.Get('Mode', Mode);
        SeenState := State.Get();
        OnAskManual(Manual);
        OnAskAutomatic(Auto);
        if (Mode = 'NeedManual') and (Manual = '') then
            Error('the manual subscriber did not answer');
        Results.Add('Session', Format(SessionId()));
        Results.Add('State', SeenState);
        Results.Add('Manual', Manual);
        Results.Add('Auto', Auto);
        Results.Add('Calls', Format(State.Bump()));
        State.Set('set by the task');
        Page.SetBackgroundTaskResult(Results);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAskManual(var Answer: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAskAutomatic(var Answer: Text)
    begin
    end;
}

codeunit 77302 "PBT Child Manual Subscriber"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PBT Child Worker", 'OnAskManual', '', false, false)]
    local procedure AnswerManual(var Answer: Text)
    begin
        Answer := 'manual';
    end;
}

codeunit 77303 "PBT Child Auto Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PBT Child Worker", 'OnAskAutomatic', '', false, false)]
    local procedure AnswerAutomatic(var Answer: Text)
    begin
        Answer := 'automatic';
    end;
}

// Enqueues one task per row from OnAfterGetCurrRecord (the row's Name is the worker's Mode) and exposes what the two trigger kinds received as controls.
page 77304 "PBT Child Card"
{
    PageType = Card;
    SourceTable = "Test Page BgTask Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(TaskSessionCtl; TaskSession) { ApplicationArea = All; Caption = 'Task Session'; }
            field(CompletedSessionCtl; CompletedSession) { ApplicationArea = All; Caption = 'Completed Session'; }
            field(TaskStateCtl; TaskState) { ApplicationArea = All; Caption = 'Task State'; }
            field(ManualCtl; ManualAnswer) { ApplicationArea = All; Caption = 'Manual'; }
            field(AutoCtl; AutoAnswer) { ApplicationArea = All; Caption = 'Auto'; }
            field(CallsCtl; CallsHistory) { ApplicationArea = All; Caption = 'Calls'; }
            field(CompletedCountCtl; CompletedCount) { ApplicationArea = All; Caption = 'Completed Count'; }
            field(ErrorCountCtl; ErrorCount) { ApplicationArea = All; Caption = 'Error Count'; }
            field(ErrorCodeCtl; LastErrorCode) { ApplicationArea = All; Caption = 'Error Code'; }
            field(ErrorTextCtl; LastErrorText) { ApplicationArea = All; Caption = 'Error Text'; }
            field(ErrorSessionCtl; ErrorSession) { ApplicationArea = All; Caption = 'Error Session'; }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Args: Dictionary of [Text, Text];
    begin
        Clear(Args);
        Args.Add('Mode', Rec.Name);
        CurrPage.EnqueueBackgroundTask(TaskId, Codeunit::"PBT Child Worker", Args, 5000);
    end;

    trigger OnPageBackgroundTaskCompleted(CompletedTaskId: Integer; Results: Dictionary of [Text, Text])
    var
        Calls: Text;
    begin
        CompletedCount += 1;
        CompletedSession := Format(SessionId());
        Results.Get('Session', TaskSession);
        Results.Get('State', TaskState);
        Results.Get('Manual', ManualAnswer);
        Results.Get('Auto', AutoAnswer);
        Results.Get('Calls', Calls);
        CallsHistory += Calls + ';';
    end;

    trigger OnPageBackgroundTaskError(ErrorTaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    begin
        ErrorCount += 1;
        ErrorSession := Format(SessionId());
        LastErrorCode := ErrorCode;
        LastErrorText := ErrorText;
        IsHandled := true;
    end;

    var
        TaskId: Integer;
        TaskSession: Text;
        CompletedSession: Text;
        TaskState: Text;
        ManualAnswer: Text;
        AutoAnswer: Text;
        CallsHistory: Text;
        CompletedCount: Integer;
        ErrorCount: Integer;
        LastErrorCode: Text;
        LastErrorText: Text;
        ErrorSession: Text;
}

codeunit 77305 "PBT Child Session Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        State: Codeunit "PBT Child State";

    local procedure Initialize()
    var
        Row: Record "Test Page BgTask Row";
    begin
        Row.DeleteAll();
        State.Reset();
    end;

    local procedure SeedRow(No: Code[20]; Mode: Text[50])
    var
        Row: Record "Test Page BgTask Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Name := Mode;
        Row.Insert();
    end;

    [Test]
    procedure EnqueueBackgroundTask_Worker_RunsInOtherSessionThanTest()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PBT Child Card";
    begin
        Initialize();
        SeedRow('PBT-1', '');

        Card.OpenView();
        Observer.Observe('completed once', Format(Card.CompletedCountCtl.AsInteger()));
        Observer.Observe('task session is not the test session', Format(Card.TaskSessionCtl.Value() <> Format(SessionId())));
        Observer.Observe('task session is not empty', Format(Card.TaskSessionCtl.Value() <> ''));
        Observer.Observe('completed trigger runs in the test session', Format(Card.CompletedSessionCtl.Value() = Format(SessionId())));
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EnqueueBackgroundTask_Worker_DoesNotSeeSingleInstanceStateOfTest()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PBT Child Card";
    begin
        Initialize();
        SeedRow('PBT-1', '');
        State.Set('set by the test');

        Card.OpenView();
        Observer.Observe('state the task saw', Card.TaskStateCtl.Value());
        Observer.Observe('state of the test after the task', State.Get());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EnqueueBackgroundTask_SecondTask_SingleInstanceCounter()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PBT Child Card";
    begin
        Initialize();
        SeedRow('PBT-1', '');
        SeedRow('PBT-2', '');

        Card.OpenView();
        Card.GoToKey('PBT-2');
        Observer.Observe('calls the tasks counted', Card.CallsCtl.Value());
        Observer.Observe('state the second task saw', Card.TaskStateCtl.Value());
        Observer.Observe('counter in the test session', Format(State.Bump()));
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EnqueueBackgroundTask_Worker_ManualBindingOfTestNotApplied()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "PBT Child Manual Subscriber";
        Card: TestPage "PBT Child Card";
    begin
        Initialize();
        SeedRow('PBT-1', '');
        BindSubscription(Subscriber);

        Card.OpenView();
        Observer.Observe('manual answer in the task', Card.ManualCtl.Value());
        UnbindSubscription(Subscriber);
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EnqueueBackgroundTask_Worker_AutomaticSubscriberAnswers()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PBT Child Card";
    begin
        Initialize();
        SeedRow('PBT-1', '');

        Card.OpenView();
        Observer.Observe('automatic answer in the task', Card.AutoCtl.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EnqueueBackgroundTask_WorkerNeedingManualBinding_RaisesErrorTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "PBT Child Manual Subscriber";
        Card: TestPage "PBT Child Card";
    begin
        Initialize();
        SeedRow('PBT-1', 'NeedManual');
        BindSubscription(Subscriber);

        Card.OpenView();
        Observer.Observe('completed count', Format(Card.CompletedCountCtl.AsInteger()));
        Observer.Observe('error count', Format(Card.ErrorCountCtl.AsInteger()));
        Observer.Observe('error text', Card.ErrorTextCtl.Value());
        Observer.Observe('error code', Card.ErrorCodeCtl.Value());
        Observer.Observe('error trigger runs in the test session', Format(Card.ErrorSessionCtl.Value() = Format(SessionId())));
        UnbindSubscription(Subscriber);
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RunPageBackgroundTask_Worker_ChildSessionFacts()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "PBT Child Manual Subscriber";
        Card: TestPage "PBT Child Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Value: Text;
    begin
        Initialize();
        SeedRow('PBT-1', '');
        State.Set('set by the test');
        BindSubscription(Subscriber);

        Card.OpenView();
        Params.Add('Mode', '');
        Results := Card.RunPageBackgroundTask(Codeunit::"PBT Child Worker", Params, false);
        Results.Get('Session', Value);
        Observer.Observe('task session is not the test session', Format(Value <> Format(SessionId())));
        Results.Get('State', Value);
        Observer.Observe('state the task saw', Value);
        Results.Get('Manual', Value);
        Observer.Observe('manual answer in the task', Value);
        Results.Get('Auto', Value);
        Observer.Observe('automatic answer in the task', Value);
        UnbindSubscription(Subscriber);
        Card.Close();
        Observer.Finish();
    end;
}
