// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// local object: capture task creation in each install context; fixture writes are guarded.
// All task targets are valid. No task is ready now: ready tasks are dated 2099-01-01.
codeunit 99468 "INST Task Capture"
{
    Subtype = Install;
    trigger OnInstallAppPerCompany()
    begin
        CaptureAll(CopyStr(CompanyName(), 1, 30), CopyStr(CompanyName(), 1, 30));
    end;

    trigger OnInstallAppPerDatabase()
    var
        Companies: Record Company;
    begin
        if Companies.FindFirst() then
            CaptureAll('<database>', Companies.Name);
    end;

    local procedure CaptureAll(ScopeName: Text[30]; TargetCompany: Text[30])
    begin
        Capture(ScopeName, 'IMPLICIT', TargetCompany);
        Capture(ScopeName, 'EXPLICIT', TargetCompany);
        Capture(ScopeName, 'FUTURE', TargetCompany);
        Capture(ScopeName, 'CANCEL-INSTALL', TargetCompany);
        Capture(ScopeName, 'COMMIT-LATER', TargetCompany);
        Capture(ScopeName, 'ROLLBACK-LATER', TargetCompany);
        Capture(ScopeName, 'CANCEL-LATER', TargetCompany);
    end;

    local procedure Capture(ScopeName: Text[30]; ScenarioName: Code[20]; TargetCompany: Text[30])
    var
        Observation: Record "INST Task Observation";
        Task: Record "Scheduled Task";
        TaskId: Guid;
    begin
        case ScenarioName of
            'IMPLICIT': TaskId := TaskScheduler.CreateTask(Codeunit::"INST Task Target", 0, false);
            'FUTURE': TaskId := TaskScheduler.CreateTask(Codeunit::"INST Task Target", 0, true, TargetCompany, CreateDateTime(20990101D, 000000T));
            else TaskId := TaskScheduler.CreateTask(Codeunit::"INST Task Target", 0, false, TargetCompany);
        end;
        Observation.Scope := ScopeName;
        Observation.Scenario := ScenarioName;
        Observation.TaskId := TaskId;
        Observation.TargetCompany := TargetCompany;
        if ScenarioName = 'IMPLICIT' then
            if ScopeName = '<database>' then
                Observation.TargetCompany := '';
        Observation.Existed := TaskScheduler.TaskExists(TaskId);
        Observation.RowExisted := Task.Get(TaskId);
        if ScenarioName = 'CANCEL-INSTALL' then
            Observation.Cancelled := TaskScheduler.CancelTask(TaskId);
        Observation.ExistsAtEnd := TaskScheduler.TaskExists(TaskId);
        if Observation.Insert(false) then;
    end;
}
