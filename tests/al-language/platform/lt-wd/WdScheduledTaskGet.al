// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/taskscheduler/taskscheduler-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunits 90750-90751
// Probe: written against al-runner issue 6315 (Scheduled Task.Get after TaskScheduler.CreateTask, as Job Queue Entry.CancelTask does); every value asserted below is what the BC service tier produced.
// Facts: the Get-then-CancelTask sequence; Get of an id the session never created; Get, IsEmpty and Count by ID after CancelTask; a filter on ID alone.
//        The field values of the row are pinned in session/lt-cn-session-leads/CnSessionLeads.al (CreateTask_ScheduledTaskUser).
// BC versions: 27, 28, 29

codeunit 90750 "LT WD Task Noop"
{
    trigger OnRun()
    begin
    end;
}

codeunit 90751 "LT WD Scheduled Task Get"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure WD_ScheduledTask_GetThenCancel()
    var
        Observer: Codeunit "Probe Observer";
        Task: Record "Scheduled Task";
        TaskId: Guid;
    begin
        TaskId := TaskScheduler.CreateTask(Codeunit::"LT WD Task Noop", 0, false);
        Observer.Observe('Get after CreateTask', Format(Task.Get(TaskId)));
        Observer.Observe('CancelTask', Format(TaskScheduler.CancelTask(TaskId)));
        Clear(Task);
        Observer.Observe('Get after CancelTask', Format(Task.Get(TaskId)));
        Observer.Observe('CancelTask again', Format(TaskScheduler.CancelTask(TaskId)));
        Observer.Expect('Get after CreateTask', 'Yes');
        Observer.Expect('CancelTask', 'Yes');
        Observer.Expect('Get after CancelTask', 'No');
        Observer.Expect('CancelTask again', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure WD_ScheduledTask_GetUnknownId()
    var
        Observer: Codeunit "Probe Observer";
        Task: Record "Scheduled Task";
        NullGuid: Guid;
    begin
        Observer.Observe('Get of a new guid', Format(Task.Get(CreateGuid())));
        Observer.Observe('Get of the null guid', Format(Task.Get(NullGuid)));
        Observer.Expect('Get of a new guid', 'No');
        Observer.Expect('Get of the null guid', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure WD_ScheduledTask_FilterOnId()
    var
        Observer: Codeunit "Probe Observer";
        Task: Record "Scheduled Task";
        TaskId: Guid;
    begin
        TaskId := TaskScheduler.CreateTask(Codeunit::"LT WD Task Noop", 0, false);
        Task.SetRange(ID, TaskId);
        Observer.Observe('Count', Format(Task.Count()));
        Observer.Observe('IsEmpty', Format(Task.IsEmpty()));
        Observer.Observe('FindFirst', Format(Task.FindFirst()));
        TaskScheduler.CancelTask(TaskId);
        Observer.Observe('Count after CancelTask', Format(Task.Count()));
        Observer.Observe('IsEmpty after CancelTask', Format(Task.IsEmpty()));
        Observer.Expect('Count', '1');
        Observer.Expect('IsEmpty', 'No');
        Observer.Expect('FindFirst', 'Yes');
        Observer.Expect('Count after CancelTask', '0');
        Observer.Expect('IsEmpty after CancelTask', 'Yes');
        Observer.Verify();
    end;
}
