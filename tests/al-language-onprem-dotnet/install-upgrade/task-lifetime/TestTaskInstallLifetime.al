// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/taskscheduler/taskscheduler-data-type
// Scope: install completion -> new test session, for per-company/per-database creation.
// Matrix per context: implicit/explicit company, retained not-ready, future-ready,
// cancellation before install end, later commit, later rollback of cancellation, later cancellation.
// All task IDs are fixture-owned; no Scheduled Task DeleteAll or unrelated task cancellation.
// Ordinary-session counterparts: metadata/session-system/Y43TaskAfterCommit.al, PlTTaskScheduler.al.
// Failed-app-install rollback is excluded: it aborts deployment; this matrix measures later test rollback.
codeunit 99469 "INST Task Lifetime Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Saved: Record "INST Task Observation" temporary;
        Loaded: Boolean;
        Assert: Codeunit Assert;

    [Test]
    procedure InstallCompany_ImplicitCompany_SurvivesNewSession()
    begin
        Initialize();
        CheckRetained(CopyStr(CompanyName(), 1, 30), 'IMPLICIT');
    end;

    [Test]
    procedure InstallCompany_ExplicitCompany_SurvivesNewSession()
    begin
        Initialize();
        CheckRetained(CopyStr(CompanyName(), 1, 30), 'EXPLICIT');
    end;

    [Test]
    procedure InstallCompany_FutureReady_SurvivesNewSession()
    begin
        Initialize();
        CheckFuture(CopyStr(CompanyName(), 1, 30), 'FUTURE');
    end;

    [Test]
    procedure InstallCompany_CancelledDuringInstall_StaysAbsent()
    begin
        Initialize();
        CheckCancelled(CopyStr(CompanyName(), 1, 30), 'CANCEL-INSTALL');
    end;

    [Test]
    procedure InstallCompany_RetainedTask_SurvivesLaterCommit()
    begin
        Initialize();
        CheckCommit(CopyStr(CompanyName(), 1, 30), 'COMMIT-LATER');
    end;

    [Test]
    procedure InstallCompany_CancelRolledBack_RestoresInstalledTask()
    begin
        Initialize();
        CheckRollback(CopyStr(CompanyName(), 1, 30), 'ROLLBACK-LATER');
    end;

    [Test]
    procedure InstallCompany_CancelInNewSession_RemovesInstalledTask()
    begin
        Initialize();
        CheckCancelLater(CopyStr(CompanyName(), 1, 30), 'CANCEL-LATER');
    end;

    [Test]
    procedure InstallDatabase_ImplicitCompany_SurvivesNewSession()
    begin
        Initialize();
        CheckRetained('<database>', 'IMPLICIT');
    end;

    [Test]
    procedure InstallDatabase_ExplicitCompany_SurvivesNewSession()
    begin
        Initialize();
        CheckRetained('<database>', 'EXPLICIT');
    end;

    [Test]
    procedure InstallDatabase_FutureReady_SurvivesNewSession()
    begin
        Initialize();
        CheckFuture('<database>', 'FUTURE');
    end;

    [Test]
    procedure InstallDatabase_CancelledDuringInstall_StaysAbsent()
    begin
        Initialize();
        CheckCancelled('<database>', 'CANCEL-INSTALL');
    end;

    [Test]
    procedure InstallDatabase_RetainedTask_SurvivesLaterCommit()
    begin
        Initialize();
        CheckCommit('<database>', 'COMMIT-LATER');
    end;

    [Test]
    procedure InstallDatabase_CancelRolledBack_RestoresInstalledTask()
    begin
        Initialize();
        CheckRollback('<database>', 'ROLLBACK-LATER');
    end;

    [Test]
    procedure InstallDatabase_CancelInNewSession_RemovesInstalledTask()
    begin
        Initialize();
        CheckCancelLater('<database>', 'CANCEL-LATER');
    end;

    local procedure Installed(ScopeName: Text[30]; ScenarioName: Code[20]; var Observation: Record "INST Task Observation")
    begin
        Assert.IsTrue(Observation.Get(ScopeName, ScenarioName), 'The install observation must exist');
        Assert.IsFalse(IsNullGuid(Observation.TaskId), 'CreateTask must return a nonempty ID');
        Assert.IsTrue(Observation.Existed, 'The creator session must see its task');
    end;

    local procedure CheckRetained(ScopeName: Text[30]; ScenarioName: Code[20])
    var
        Observation: Record "INST Task Observation";
        Task: Record "Scheduled Task";
    begin
        Installed(ScopeName, ScenarioName, Observation);
        Assert.IsTrue(Observation.ExistsAtEnd, 'The creator left this task present');
        Assert.IsTrue(Task.Get(Observation.TaskId), 'The new session must see its scheduled row');
        Assert.IsTrue(TaskScheduler.TaskExists(Observation.TaskId), 'The new session must see the installed task');
        Assert.AreEqual(Codeunit::"INST Task Target", Task."Run Codeunit", 'The task target');
        Assert.IsFalse(Task."Is Ready", 'This task was created not ready');
        Assert.AreEqual(Observation.TargetCompany, Task.Company, 'Explicit or implicit task company');
    end;

    local procedure CheckFuture(ScopeName: Text[30]; ScenarioName: Code[20])
    var
        Observation: Record "INST Task Observation";
        Task: Record "Scheduled Task";
    begin
        Installed(ScopeName, ScenarioName, Observation);
        Assert.IsTrue(Task.Get(Observation.TaskId), 'The future task row survives installation');
        Assert.IsTrue(TaskScheduler.TaskExists(Observation.TaskId), 'Future task survives into the test session');
        Assert.IsTrue(Task."Is Ready", 'Explicit ready=true is retained');
        Assert.AreEqual(CreateDateTime(20990101D, 000000T), Task."Not Before", 'Future date prevents execution');
    end;

    local procedure CheckCancelled(ScopeName: Text[30]; ScenarioName: Code[20])
    var
        Observation: Record "INST Task Observation";
        Task: Record "Scheduled Task";
    begin
        Installed(ScopeName, ScenarioName, Observation);
        Assert.IsTrue(Observation.Cancelled, 'The creator cancelled its existing task');
        Assert.IsFalse(Observation.ExistsAtEnd, 'Cancellation removed the task in the creator session');
        Assert.IsFalse(TaskScheduler.TaskExists(Observation.TaskId), 'The cancelled task stays absent');
        Assert.IsFalse(Task.Get(Observation.TaskId), 'The cancelled row stays absent');
    end;

    local procedure CheckCommit(ScopeName: Text[30]; ScenarioName: Code[20])
    begin
        CheckRetained(ScopeName, ScenarioName);
        Commit();
        CheckRetained(ScopeName, ScenarioName);
    end;

    local procedure CheckRollback(ScopeName: Text[30]; ScenarioName: Code[20])
    var
        Observation: Record "INST Task Observation";
    begin
        CheckRetained(ScopeName, ScenarioName);
        Installed(ScopeName, ScenarioName, Observation);
        asserterror CancelThenFail(Observation.TaskId);
        Assert.ExpectedError('INST TASK ROLLBACK');
        CheckRetained(ScopeName, ScenarioName);
    end;

    local procedure CancelThenFail(TaskId: Guid)
    begin
        Assert.IsTrue(TaskScheduler.CancelTask(TaskId), 'Cancellation in the rollback transaction succeeds');
        Assert.IsFalse(TaskScheduler.TaskExists(TaskId), 'The task is absent before rollback');
        Error('INST TASK ROLLBACK');
    end;

    local procedure CheckCancelLater(ScopeName: Text[30]; ScenarioName: Code[20])
    var
        Observation: Record "INST Task Observation";
        Task: Record "Scheduled Task";
    begin
        CheckRetained(ScopeName, ScenarioName);
        Installed(ScopeName, ScenarioName, Observation);
        Assert.IsTrue(TaskScheduler.CancelTask(Observation.TaskId), 'A new session can cancel the installed task');
        Assert.IsFalse(TaskScheduler.TaskExists(Observation.TaskId), 'Task is removed from the scheduler');
        Assert.IsFalse(Task.Get(Observation.TaskId), 'Task row is removed');
    end;

    local procedure Initialize()
    var
        Observation: Record "INST Task Observation";
    begin
        if not Loaded then begin
            if Observation.FindSet() then
                repeat
                    Saved := Observation;
                    Saved.Insert(false);
                until Observation.Next() = 0;
            Loaded := true;
        end;
        Observation.DeleteAll();
        if Saved.FindSet() then
            repeat
                Observation := Saved;
                Observation.Insert(false);
            until Saved.Next() = 0;
    end;
}
