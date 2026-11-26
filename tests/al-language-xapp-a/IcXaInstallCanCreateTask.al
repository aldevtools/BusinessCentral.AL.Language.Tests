// Install code of cross-app fixture A for al-runner issue 9123 (tests: tests/al-language/install-upgrade/IcInstallCanCreateTaskTests.al).
// The Subtype = Install codeunit reads TaskScheduler.CanCreateTask() in OnInstallAppPerCompany (once per company) and OnInstallAppPerDatabase, beside
// Session.GetExecutionContext(), Session.GetCurrentModuleExecutionContext() and Session.CurrentExecutionMode(). Then it does what install code
// of Microsoft's apps does: `if CanCreateTask then CreateTask(<codeunit>, 0) else Codeunit.Run(<codeunit>)`. The codeunit is "LT IC XA Seen"
// (IcXaCanCreateTask.al): its OnRun writes one row with the session id and client type, so the test can tell a task session from the install session.
// CreateTask runs in a TryFunction that writes nothing, so an error becomes a logged fact instead of a failed publish. Every write is
// `if Insert() then;` into the DataPerCompany = false table below (check-install-triggers.py).
// BC versions: 27 - 29

table 98496 "LT IC XA Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Kind; Text[40]) { }
        field(3; Company; Text[60]) { }
        field(4; "Session Id"; Integer) { }
        field(5; Facts; Text[250]) { }
        field(6; Branch; Text[250]) { }
        field(7; "Task Id"; Guid) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 98497 "LT IC XA Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        InstallStep('install per company');
    end;

    trigger OnInstallAppPerDatabase()
    begin
        InstallStep('install per database');
    end;

    local procedure InstallStep(Kind: Text)
    var
        Log: Record "LT IC XA Log";
        TaskId: Guid;
        Read: Text;
        Branch: Text;
        CanCreate: Boolean;
    begin
        CanCreate := TaskScheduler.CanCreateTask();
        Read := 'ctx=' + Format(Session.GetExecutionContext()) + ',mod=' + Format(Session.GetCurrentModuleExecutionContext()) +
            ',mode=' + Format(Session.CurrentExecutionMode()) + ',cct=' + Format(CanCreate);
        if CanCreate then begin
            if TryCreateTask(TaskId) then
                Branch := 'CreateTask'
            else
                Branch := 'CreateTask error: ' + GetLastErrorText();
        end else begin
            Codeunit.Run(Codeunit::"LT IC XA Seen");
            Branch := 'Codeunit.Run';
        end;
        Log.Init();
        Log.Kind := CopyStr(Kind, 1, MaxStrLen(Log.Kind));
        Log.Company := CopyStr(CompanyName(), 1, MaxStrLen(Log.Company));
        Log."Session Id" := SessionId();
        Log.Facts := CopyStr(Read, 1, MaxStrLen(Log.Facts));
        Log.Branch := CopyStr(Branch, 1, MaxStrLen(Log.Branch));
        Log."Task Id" := TaskId;
        if Log.Insert() then;
    end;

    [TryFunction]
    local procedure TryCreateTask(var TaskId: Guid)
    begin
        TaskId := TaskScheduler.CreateTask(Codeunit::"LT IC XA Seen", 0);
    end;
}
