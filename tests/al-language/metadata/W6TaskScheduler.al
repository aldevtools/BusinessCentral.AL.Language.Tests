// Batch 6, md:364 [TaskScheduler] CanCreateTask, TaskExists, SetTaskReady, CancelTask, and whether a created task runs while a test is running.
// session/TestTaskSchedulerCloudBehavior.al pins only a non-empty id. Observe-only; every call that may raise stands alone in its own test
// (no asserterror: if BC raises, the failure text is the observation). CreateTask writes, so nothing here is a TryFunction.
// The tasks created here are rolled back with the test.

table 67329 "W6 TS Marker"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67330 "W6 TS Task"
{
    trigger OnRun()
    var
        Marker: Record "W6 TS Marker";
    begin
        Marker.Txt := 'ran';
        Marker.Insert();
    end;
}

codeunit 67331 "W6 TaskScheduler Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean()
    var
        Marker: Record "W6 TS Marker";
    begin
        Marker.DeleteAll();
    end;

    [Test]
    procedure CreateTask_CanCreateTask_And_IdNullness()
    var
        TaskId: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('can_create_task', Format(TaskScheduler.CanCreateTask()));
        TaskId := TaskScheduler.CreateTask(Codeunit::"W6 TS Task", 0);
        Observer.Observe('task_id_null', Format(IsNullGuid(TaskId)));
        Observer.Expect('can_create_task', 'No');
        Observer.Expect('task_id_null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure CreateTask_TwoCalls_DifferentIds()
    var
        First: Guid;
        Second: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        First := TaskScheduler.CreateTask(Codeunit::"W6 TS Task", 0);
        Second := TaskScheduler.CreateTask(Codeunit::"W6 TS Task", 0);
        Observer.Observe('ids_differ', Format(First <> Second));
        Observer.Expect('ids_differ', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CreateTask_DoesTheTaskRun_AfterAPause()
    var
        Marker: Record "W6 TS Marker";
        TaskId: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        TaskId := TaskScheduler.CreateTask(Codeunit::"W6 TS Task", 0);
        Observer.Observe('markers_right_after_create', Format(Marker.Count()));
        Sleep(1500);
        Observer.Observe('markers_after_pause', Format(Marker.Count()));
        Observer.Expect('markers_right_after_create', '0');
        Observer.Expect('markers_after_pause', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TaskExists_AfterCreate()
    var
        TaskId: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        TaskId := TaskScheduler.CreateTask(Codeunit::"W6 TS Task", 0);
        Observer.Observe('task_exists_after_create', Format(TaskScheduler.TaskExists(TaskId)));
        Observer.Expect('task_exists_after_create', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TaskExists_UnknownGuid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('task_exists_unknown_guid', Format(TaskScheduler.TaskExists(CreateGuid())));
        Observer.Expect('task_exists_unknown_guid', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SetTaskReady_ForATaskCreatedNotReady()
    var
        TaskId: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        TaskId := TaskScheduler.CreateTask(Codeunit::"W6 TS Task", 0, false);
        Observer.Observe('task_exists_not_ready', Format(TaskScheduler.TaskExists(TaskId)));
        TaskScheduler.SetTaskReady(TaskId);
        Observer.Observe('task_exists_after_set_ready', Format(TaskScheduler.TaskExists(TaskId)));
        Observer.Expect('task_exists_not_ready', 'Yes');
        Observer.Expect('task_exists_after_set_ready', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SetTaskReady_UnknownGuid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TaskScheduler.SetTaskReady(CreateGuid());
        Observer.Observe('set_task_ready_unknown_guid', 'returned');
        Observer.Expect('set_task_ready_unknown_guid', 'returned');
        Observer.Verify();
    end;

    [Test]
    procedure CancelTask_AfterCreate()
    var
        TaskId: Guid;
        Cancelled: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        TaskId := TaskScheduler.CreateTask(Codeunit::"W6 TS Task", 0);
        Cancelled := TaskScheduler.CancelTask(TaskId);
        Observer.Observe('cancel_task_result', Format(Cancelled));
        Observer.Observe('task_exists_after_cancel', Format(TaskScheduler.TaskExists(TaskId)));
        Observer.Expect('cancel_task_result', 'Yes');
        Observer.Expect('task_exists_after_cancel', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure CancelTask_UnknownGuid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('cancel_task_unknown_guid_result', Format(TaskScheduler.CancelTask(CreateGuid())));
        Observer.Expect('cancel_task_unknown_guid_result', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure CreateTask_NotBefore_And_Company()
    var
        TaskId: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        TaskId := TaskScheduler.CreateTask(Codeunit::"W6 TS Task", 0, true, CompanyName(), CurrentDateTime() + 3600000);
        Observer.Observe('task_id_null', Format(IsNullGuid(TaskId)));
        Observer.Observe('task_exists', Format(TaskScheduler.TaskExists(TaskId)));
        Observer.Expect('task_id_null', 'No');
        Observer.Expect('task_exists', 'Yes');
        Observer.Verify();
    end;

}
