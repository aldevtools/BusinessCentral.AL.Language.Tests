// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/taskscheduler/taskscheduler-createtask-method
// Scope: in-scope
// Fixtures used: tables 72694, Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TaskScheduler.CreateTask 7-argument overload with Timeout; every task is created with a far-future NotBefore and cancelled at once
// BC versions: 29 (27 and 28 by CI)

codeunit 72704 "LT P107 CreateTask"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P107_CreateTaskTimeout()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
        RecId: RecordId;
        NotBefore: DateTime;
        Timeout: Duration;
    begin
        NotBefore := CreateDateTime(DMY2Date(1, 1, 2099), 120000T);
        Timeout := 60000;
        Id := TaskScheduler.CreateTask(72712, 0, false, CompanyName(), NotBefore, RecId, Timeout);
        Observer.Observe('guid_null', Format(IsNullGuid(Id)));
        Observer.Observe('exists', Format(TaskScheduler.TaskExists(Id)));
        TaskScheduler.CancelTask(Id);
        Observer.Observe('exists_after_cancel', Format(TaskScheduler.TaskExists(Id)));
        Observer.Expect('guid_null', 'No');
        Observer.Expect('exists', 'Yes');
        Observer.Expect('exists_after_cancel', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P107_CreateTaskTimeoutValues()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
        RecId: RecordId;
        NotBefore: DateTime;
        Timeout: Duration;
    begin
        NotBefore := CreateDateTime(DMY2Date(1, 1, 2099), 120000T);
        Timeout := 0;
        Id := TaskScheduler.CreateTask(72712, 0, false, CompanyName(), NotBefore, RecId, Timeout);
        Observer.Observe('zero_null', Format(IsNullGuid(Id)));
        TaskScheduler.CancelTask(Id);
        Timeout := -1;
        Id := TaskScheduler.CreateTask(72712, 0, false, CompanyName(), NotBefore, RecId, Timeout);
        Observer.Observe('negative', 'no error');
        Timeout := 86400000;
        Id := TaskScheduler.CreateTask(72712, 0, false, CompanyName(), NotBefore, RecId, Timeout);
        Observer.Observe('long_null', Format(IsNullGuid(Id)));
        TaskScheduler.CancelTask(Id);
        Observer.Expect('zero_null', 'No');
        Observer.Expect('negative', 'no error');
        Observer.Expect('long_null', 'No');
        Observer.Verify();
    end;
}

codeunit 72712 "LT P107 Task Target"
{
    trigger OnRun()
    begin
    end;
}
