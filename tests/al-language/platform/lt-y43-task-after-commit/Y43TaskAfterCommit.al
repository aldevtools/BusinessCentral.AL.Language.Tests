// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/taskscheduler/taskscheduler-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (tables 92848 and 92850, codeunits 92849, 92851, 92852)
// Probe (writer Y43, gap cycle 4, G4-14): the Scheduled Task table and the TaskScheduler calls AFTER the transaction that created a task was
//   committed (Commit() inside the test): Get by the id and the columns Is Ready, Run Codeunit, Not Before; the Is Ready + User ID count a job
//   queue enqueue makes; an exist() FlowField over the table; TaskExists, SetTaskReady and CancelTask; a task with a NotBefore in the future;
//   and, in the next test of the same codeunit, whether the task of the earlier test is still in the table. Each test also observes
//   CanCreateTask() and ends with CancelTask of its tasks. Counts are observed as differences, because other tasks of the tenant are in the table.
//   Test isolation: no RequiredTestIsolation property (the runner's default).
// Probe: values recorded on the BC 29 SaaS sandbox; other BC versions are checked by the corpus CI matrix.

table 92848 "LT Y43 TS Marker"
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

codeunit 92849 "LT Y43 TS Task"
{
    trigger OnRun()
    var
        Marker: Record "LT Y43 TS Marker";
    begin
        Marker.Txt := 'ran';
        Marker.Insert();
    end;
}

table 92850 "LT Y43 TS Holder"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; TaskId; Guid) { }
        field(3; Scheduled; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("Scheduled Task" where(ID = field(TaskId)));
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 92851 "LT Y43 TS State"
{
    SingleInstance = true;

    var
        LastId: Guid;

    procedure SetLast(Id: Guid)
    begin
        LastId := Id;
    end;

    procedure GetLast(): Guid
    begin
        exit(LastId);
    end;
}

codeunit 92852 "LT Y43 TS After Commit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCancel(Id: Guid; var Answer: Boolean)
    begin
        Answer := TaskScheduler.CancelTask(Id);
    end;

    local procedure Cancel(Id: Guid): Text
    var
        Answer: Boolean;
    begin
        ClearLastError();
        if TryCancel(Id, Answer) then
            exit(Format(Answer));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ReadTask(Id: Guid): Text
    var
        Task: Record "Scheduled Task";
    begin
        if not Task.Get(Id) then
            exit('No');
        exit('Yes ready=' + Format(Task."Is Ready") + ' cu=' + Format(Task."Run Codeunit") + ' notBeforeBlank=' + Format(Task."Not Before" = 0DT));
    end;

    local procedure ReadyCount(ForUser: Boolean): Integer
    var
        Task: Record "Scheduled Task";
    begin
        Task.SetRange("Is Ready", true);
        if ForUser then
            Task.SetRange("User ID", UserSecurityId());
        exit(Task.Count());
    end;

    local procedure Markers(): Integer
    var
        Marker: Record "LT Y43 TS Marker";
    begin
        exit(Marker.Count());
    end;

    local procedure Clean()
    var
        Marker: Record "LT Y43 TS Marker";
        Holder: Record "LT Y43 TS Holder";
    begin
        Marker.DeleteAll();
        Holder.DeleteAll();
        Commit();
    end;

    [Test]
    procedure Y43_G414_Get_AfterCommit_Ready()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "LT Y43 TS State";
        Id: Guid;
    begin
        Clean();
        Observer.Observe('canCreateTask', Format(TaskScheduler.CanCreateTask()));
        Id := TaskScheduler.CreateTask(Codeunit::"LT Y43 TS Task", 0);
        State.SetLast(Id);
        Observer.Observe('beforeCommit', ReadTask(Id));
        Commit();
        Observer.Observe('afterCommit', ReadTask(Id));
        Observer.Observe('markersAfterCommit', Format(Markers()));
        Sleep(2000);
        Observer.Observe('afterPause', ReadTask(Id));
        Observer.Observe('markersAfterPause', Format(Markers()));
        Observer.Finish();
    end;

    [Test]
    procedure Y43_G414_Get_NextTest_TaskOfEarlierTest()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "LT Y43 TS State";
    begin
        Observer.Observe('earlierTask', ReadTask(State.GetLast()));
        Observer.Observe('taskExists', Format(TaskScheduler.TaskExists(State.GetLast())));
        Observer.Observe('markers', Format(Markers()));
        Observer.Observe('cancel', Cancel(State.GetLast()));
        Observer.Finish();
    end;

    [Test]
    procedure Y43_G414_Get_AfterCommit_NotReady()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
    begin
        Clean();
        Observer.Observe('canCreateTask', Format(TaskScheduler.CanCreateTask()));
        Id := TaskScheduler.CreateTask(Codeunit::"LT Y43 TS Task", 0, false);
        Commit();
        Observer.Observe('afterCommit', ReadTask(Id));
        Sleep(2000);
        Observer.Observe('afterPause', ReadTask(Id));
        Observer.Observe('markersAfterPause', Format(Markers()));
        Observer.Observe('cancel', Cancel(Id));
        Observer.Finish();
    end;

    [Test]
    procedure Y43_G414_Count_IsReady_User_AfterCommit()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
        UserBefore: Integer;
        AllBefore: Integer;
    begin
        Clean();
        Observer.Observe('canCreateTask', Format(TaskScheduler.CanCreateTask()));
        UserBefore := ReadyCount(true);
        AllBefore := ReadyCount(false);
        Id := TaskScheduler.CreateTask(Codeunit::"LT Y43 TS Task", 0);
        Observer.Observe('userDeltaAfterCreate', Format(ReadyCount(true) - UserBefore));
        Observer.Observe('allDeltaAfterCreate', Format(ReadyCount(false) - AllBefore));
        Commit();
        Observer.Observe('userDeltaAfterCommit', Format(ReadyCount(true) - UserBefore));
        Observer.Observe('allDeltaAfterCommit', Format(ReadyCount(false) - AllBefore));
        Observer.Observe('cancel', Cancel(Id));
        Observer.Observe('userDeltaAfterCancel', Format(ReadyCount(true) - UserBefore));
        Observer.Finish();
    end;

    [Test]
    procedure Y43_G414_FlowField_AfterCommit()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Record "LT Y43 TS Holder";
        Id: Guid;
    begin
        Clean();
        Observer.Observe('canCreateTask', Format(TaskScheduler.CanCreateTask()));
        Id := TaskScheduler.CreateTask(Codeunit::"LT Y43 TS Task", 0, false);
        Holder.Id := 1;
        Holder.TaskId := Id;
        Holder.Insert();
        Holder.Id := 2;
        Holder.TaskId := CreateGuid();
        Holder.Insert();
        Commit();
        Holder.Get(1);
        Holder.CalcFields(Scheduled);
        Observer.Observe('calcFields1', Format(Holder.Scheduled));
        Holder.Get(2);
        Holder.CalcFields(Scheduled);
        Observer.Observe('calcFields2', Format(Holder.Scheduled));
        Holder.Reset();
        Holder.SetAutoCalcFields(Scheduled);
        Holder.SetRange(Id, 1);
        Holder.FindFirst();
        Observer.Observe('autoCalc1', Format(Holder.Scheduled));
        Observer.Observe('cancel', Cancel(Id));
        Holder.FindFirst();
        Observer.Observe('autoCalc1AfterCancel', Format(Holder.Scheduled));
        Observer.Finish();
    end;

    [Test]
    procedure Y43_G414_TaskScheduler_AfterCommit()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
    begin
        Clean();
        Observer.Observe('canCreateTask', Format(TaskScheduler.CanCreateTask()));
        Id := TaskScheduler.CreateTask(Codeunit::"LT Y43 TS Task", 0, false);
        Commit();
        Observer.Observe('taskExists', Format(TaskScheduler.TaskExists(Id)));
        Observer.Observe('setTaskReady', Format(TaskScheduler.SetTaskReady(Id)));
        Observer.Observe('afterSetReady', ReadTask(Id));
        Observer.Observe('cancel', Cancel(Id));
        Observer.Observe('afterCancel', ReadTask(Id));
        Observer.Observe('taskExistsAfterCancel', Format(TaskScheduler.TaskExists(Id)));
        Observer.Observe('cancelAgain', Cancel(Id));
        Observer.Finish();
    end;

    [Test]
    procedure Y43_G414_NotBefore_Future_AfterCommit()
    var
        Observer: Codeunit "Probe Observer";
        Task: Record "Scheduled Task";
        Id: Guid;
        NotBefore: DateTime;
    begin
        Clean();
        Observer.Observe('canCreateTask', Format(TaskScheduler.CanCreateTask()));
        NotBefore := CreateDateTime(Today() + 30, 0T);
        Id := TaskScheduler.CreateTask(Codeunit::"LT Y43 TS Task", 0, true, CompanyName(), NotBefore);
        Commit();
        Observer.Observe('afterCommit', ReadTask(Id));
        if Task.Get(Id) then
            Observer.Observe('notBeforeEqual', Format(Task."Not Before" = NotBefore));
        Sleep(2000);
        Observer.Observe('afterPause', ReadTask(Id));
        Observer.Observe('markersAfterPause', Format(Markers()));
        Observer.Observe('cancel', Cancel(Id));
        Observer.Finish();
    end;
}
