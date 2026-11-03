// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-hyperlink-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC Log (71071)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed rows: Hyperlink (fixes-7) "what a test run does with it (nothing, an error, a handler)"; TaskScheduler "CreateTask returns a new id and the task does not run; TaskExists, SetTaskReady, CancelTask"
// BC versions: 29 (27 and 28 by CI)

codeunit 71146 "LT PnC Log 7"
{
    SingleInstance = true;

    var
        Items: List of [Text];

    procedure Add(Value: Text)
    begin
        Items.Add(Value);
    end;

    procedure Reset()
    begin
        Clear(Items);
    end;

    procedure Joined(): Text
    var
        Result: Text;
        Item: Text;
    begin
        foreach Item in Items do begin
            if Result <> '' then
                Result += '|';
            Result += Item;
        end;
        exit(Result);
    end;

    procedure Count(): Integer
    begin
        exit(Items.Count());
    end;
}

codeunit 71129 "LT PnC Task Target"
{
    trigger OnRun()
    var
        Log: Codeunit "LT PnC Log 7";
    begin
        Log.Add('task ran');
    end;
}

codeunit 71130 "LT PnC Hyperlink Task"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Hyperlink_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Hyperlink('https://example.org');
        Observer.ObserveError('https');
        asserterror Hyperlink('');
        Observer.ObserveError('empty');
        Observer.Expect('https|text', 'Unhandled UI: Hyperlink https://example.org');
        Observer.Expect('https|code', 'MissingUIHandler');
        Observer.Expect('empty|text', 'Unhandled UI: Hyperlink ');
        Observer.Expect('empty|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LinkHandler')]
    procedure Hyperlink_WithHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Hyperlink('https://example.org/x');
        Observer.Observe('withHandler', 'no error');
        Observer.Expect('withHandler', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure TaskScheduler_Basics()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 7";
        TaskId: Guid;
        Other: Guid;
    begin
        Log.Reset();
        Observer.Observe('canCreateTask', Format(TaskScheduler.CanCreateTask()));
        TaskId := TaskScheduler.CreateTask(Codeunit::"LT PnC Task Target", 0);
        Observer.Observe('id.isNull', Format(IsNullGuid(TaskId)));
        Observer.Observe('exists', Format(TaskScheduler.TaskExists(TaskId)));
        Other := TaskScheduler.CreateTask(Codeunit::"LT PnC Task Target", 0);
        Observer.Observe('second.differs', Format(TaskId <> Other));
        Observer.Observe('log', '[' + Log.Joined() + ']');
        TaskScheduler.SetTaskReady(TaskId);
        Observer.Observe('setTaskReady', 'no error');
        TaskScheduler.CancelTask(TaskId);
        Observer.Observe('exists.afterCancel', Format(TaskScheduler.TaskExists(TaskId)));
        TaskScheduler.CancelTask(Other);
        Observer.Observe('cancel.again', Format(TaskScheduler.TaskExists(Other)));
        Observer.Expect('canCreateTask', 'No');
        Observer.Expect('id.isNull', 'No');
        Observer.Expect('exists', 'Yes');
        Observer.Expect('second.differs', 'Yes');
        Observer.Expect('log', '[]');
        Observer.Expect('setTaskReady', 'no error');
        Observer.Expect('exists.afterCancel', 'No');
        Observer.Expect('cancel.again', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TaskScheduler_UnknownTask()
    var
        Observer: Codeunit "Probe Observer";
        Unknown: Guid;
    begin
        Unknown := CreateGuid();
        Observer.Observe('exists', Format(TaskScheduler.TaskExists(Unknown)));
        TaskScheduler.CancelTask(Unknown);
        Observer.Observe('cancel', 'no error');
        TaskScheduler.SetTaskReady(Unknown);
        Observer.Observe('setReady', 'no error');
        TaskScheduler.CancelTask(Unknown);
        Observer.Observe('cancelAgain', 'no error');
        Observer.Expect('exists', 'No');
        Observer.Expect('cancel', 'no error');
        Observer.Expect('setReady', 'no error');
        Observer.Expect('cancelAgain', 'no error');
        Observer.Verify();
    end;

    [HyperlinkHandler]
    procedure LinkHandler(Url: Text)
    begin
    end;
}
