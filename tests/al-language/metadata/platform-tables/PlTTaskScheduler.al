// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/taskscheduler/taskscheduler-data-type
// Scope: in-scope
// Fixtures used: codeunits 74215 and 74220 (PlTTaskTarget.Codeunit.al), self-contained codeunit 74214
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Members: TaskScheduler.CanCreateTask, TaskExists, CreateTask, CancelTask.
// BC versions: 29 (27 and 28 by CI)

codeunit 74214 "LT PlT TaskScheduler"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ScrubCaller(Value: Text): Text
    var
        StartPos: Integer;
        EndPos: Integer;
    begin
        StartPos := StrPos(Value, ' from the object ');
        EndPos := StrPos(Value, '. An object with that ID');
        if (StartPos = 0) or (EndPos < StartPos) then
            exit(Value);
        exit(CopyStr(Value, 1, StartPos - 1) + ' from the object <caller>' + CopyStr(Value, EndPos));
    end;

    [Test]
    procedure CanCreateTask_Twice()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('value', Format(TaskScheduler.CanCreateTask()));
        Observer.Observe('twice_equal', Format(TaskScheduler.CanCreateTask() = TaskScheduler.CanCreateTask()));
        Observer.Expect('value', 'No');
        Observer.Expect('twice_equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TaskExists_UnknownIds()
    var
        Observer: Codeunit "Probe Observer";
        Empty: Guid;
    begin
        Observer.Observe('random', Format(TaskScheduler.TaskExists(CreateGuid())));
        Observer.Observe('null', Format(TaskScheduler.TaskExists(Empty)));
        Observer.Expect('random', 'No');
        Observer.Expect('null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure CancelTask_UnknownIds()
    var
        Observer: Codeunit "Probe Observer";
        Empty: Guid;
    begin
        Observer.Observe('random', Format(TaskScheduler.CancelTask(CreateGuid())));
        Observer.Observe('null', Format(TaskScheduler.CancelTask(Empty)));
        Observer.Expect('random', 'No');
        Observer.Expect('null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure CreateTask_NotReady_ThenCancel()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
        Id2: Guid;
    begin
        Id := TaskScheduler.CreateTask(Codeunit::"LT PlT Task Target", 0, false);
        Observer.Observe('id_null', Format(IsNullGuid(Id)));
        Observer.Observe('exists', Format(TaskScheduler.TaskExists(Id)));
        Id2 := TaskScheduler.CreateTask(Codeunit::"LT PlT Task Target", 0, false);
        Observer.Observe('second_differs', Format(Id <> Id2));
        Observer.Observe('second_exists', Format(TaskScheduler.TaskExists(Id2)));
        Observer.Observe('cancel_first', Format(TaskScheduler.CancelTask(Id)));
        Observer.Observe('first_gone', Format(TaskScheduler.TaskExists(Id)));
        Observer.Observe('second_still', Format(TaskScheduler.TaskExists(Id2)));
        Observer.Observe('cancel_first_again', Format(TaskScheduler.CancelTask(Id)));
        Observer.Observe('cancel_second', Format(TaskScheduler.CancelTask(Id2)));
        Observer.Expect('id_null', 'No');
        Observer.Expect('exists', 'Yes');
        Observer.Expect('second_differs', 'Yes');
        Observer.Expect('second_exists', 'Yes');
        Observer.Expect('cancel_first', 'Yes');
        Observer.Expect('first_gone', 'No');
        Observer.Expect('second_still', 'Yes');
        Observer.Expect('cancel_first_again', 'No');
        Observer.Expect('cancel_second', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CreateTask_WithFailureCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
    begin
        Id := TaskScheduler.CreateTask(Codeunit::"LT PlT Task Target", Codeunit::"LT PlT Task Failure", false);
        Observer.Observe('id_null', Format(IsNullGuid(Id)));
        Observer.Observe('exists', Format(TaskScheduler.TaskExists(Id)));
        Observer.Observe('cancel', Format(TaskScheduler.CancelTask(Id)));
        Observer.Expect('id_null', 'No');
        Observer.Expect('exists', 'Yes');
        Observer.Expect('cancel', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CreateTask_WithCompanyAndStartTime()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
        Id2: Guid;
    begin
        Id := TaskScheduler.CreateTask(Codeunit::"LT PlT Task Target", 0, false, CompanyName());
        Observer.Observe('company_exists', Format(TaskScheduler.TaskExists(Id)));
        Id2 := TaskScheduler.CreateTask(Codeunit::"LT PlT Task Target", 0, false, CompanyName(), CurrentDateTime() + 86400000);
        Observer.Observe('start_exists', Format(TaskScheduler.TaskExists(Id2)));
        Observer.Observe('cancel_company', Format(TaskScheduler.CancelTask(Id)));
        Observer.Observe('cancel_start', Format(TaskScheduler.CancelTask(Id2)));
        Observer.Expect('company_exists', 'Yes');
        Observer.Expect('start_exists', 'Yes');
        Observer.Expect('cancel_company', 'Yes');
        Observer.Expect('cancel_start', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CreateTask_WithRecordId()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PlT Row";
        Id: Guid;
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 1;
        Row.Insert();
        Id := TaskScheduler.CreateTask(Codeunit::"LT PlT Task Target", 0, false, CompanyName(), CurrentDateTime() + 86400000, Row.RecordId());
        Observer.Observe('exists', Format(TaskScheduler.TaskExists(Id)));
        Observer.Observe('cancel', Format(TaskScheduler.CancelTask(Id)));
        Row.DeleteAll();
        Observer.Expect('exists', 'Yes');
        Observer.Expect('cancel', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CreateTask_ErrorUnknownCodeunit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror TaskScheduler.CreateTask(99999999, 0, false);
        Observer.Observe('unknown_codeunit|text', ScrubCaller(GetLastErrorText()));
        Observer.Observe('unknown_codeunit|code', GetLastErrorCode());
        ClearLastError();
        Observer.Expect('unknown_codeunit|text', 'You tried to invoke the CodeUnit object with the ID 99999999 from the object <caller>. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('unknown_codeunit|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure CreateTask_ErrorZeroCodeunit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TaskScheduler.CreateTask(0, 0, false);
        Observer.Observe('zero_codeunit', 'no error');
        Observer.Expect('zero_codeunit', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure CreateTask_ErrorUnknownFailureCodeunit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror TaskScheduler.CreateTask(Codeunit::"LT PlT Task Target", 99999999, false);
        Observer.Observe('unknown_failure_codeunit|text', ScrubCaller(GetLastErrorText()));
        Observer.Observe('unknown_failure_codeunit|code', GetLastErrorCode());
        ClearLastError();
        Observer.Expect('unknown_failure_codeunit|text', 'You tried to invoke the CodeUnit object with the ID 99999999 from the object <caller>. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('unknown_failure_codeunit|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure CreateTask_ErrorUnknownCompany()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TaskScheduler.CreateTask(Codeunit::"LT PlT Task Target", 0, false, 'No Such Company For Probe');
        Observer.Observe('unknown_company', 'no error');
        Observer.Expect('unknown_company', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure CreateTask_RolledBackWithTransaction()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
    begin
        asserterror
        begin
            Id := TaskScheduler.CreateTask(Codeunit::"LT PlT Task Target", 0, false);
            Error('boom');
        end;
        Observer.ObserveError('err');
        Observer.Observe('exists_after_rollback', Format(TaskScheduler.TaskExists(Id)));
        Observer.Expect('err|text', 'boom');
        Observer.Expect('err|code', 'Dialog');
        Observer.Expect('exists_after_rollback', 'No');
        Observer.Verify();
    end;
}
