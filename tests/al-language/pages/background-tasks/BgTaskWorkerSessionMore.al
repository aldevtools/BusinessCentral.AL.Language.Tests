// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-runpagebackgroundtask-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-triggers
// Scope: in-scope
// local object: what a page background task's worker's own catches and its own collecting scope do is what is under test
// Fixtures used: Assert (60021); table 97390 "LEW Host" and page 97392 "LEW Hosts" (BgTaskWorkerLastError.al), worker
//   codeunit 97376 "LWS Reader" (BgTaskWorkerSessionShapes.al), the CEM fixtures of pages/close-errors/CemFixtures.al
//   (objects 99500..99512); codeunits 97379 (worker) and 97380 (tests)
// Probe (al-runner issue 8697, next to BgTaskWorkerSessionShapes.al): the worker runs in a session of its own, also for the
//   errors it catches and the errors it collects.
// Cells:
//   - a ModalPageHandler of Page.RunModal of the CEM document runs a task whose worker catches an error of its own, then
//     raises: the document closes as the pinned cell of a handler that caught nothing (:105, as CemDocumentTests.al
//     DocumentStaticRunModal_HandlerError_NoError);
//   - a PageHandler of the CEM card run from a Page variable runs such a task, then invokes OK: the card closes as the pinned
//     cell (:124, as CemPageHandlerTests.al CardVariableRun_HandlerOk_NoError);
//   - a test session that collects errors runs a task whose worker collects a collectible TestField in a collecting scope
//     of its own: the worker collects it, the task succeeds, and the test session collects nothing (:142).
// BC versions: 29.1 (local W1 container).

// A worker that collects its own errors.
codeunit 97379 "LWN Collecting Worker"
{
    trigger OnRun()
    var
        Results: Dictionary of [Text, Text];
    begin
        Results.Add('Count', Format(CollectTestField()));
        Page.SetBackgroundTaskResult(Results);
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectTestField(): Integer
    var
        Host: Record "LEW Host";
        FieldError: ErrorInfo;
        Collected: Integer;
    begin
        Host.FindFirst();
        FieldError.Collectible(true);
        Host.TestField("No.", 'OTHER', FieldError);
        Collected := GetCollectedErrors().Count();
        ClearCollectedErrors();
        exit(Collected);
    end;
}

codeunit 97380 "LWN Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cfg: Codeunit "CEM Cfg";
        Help: Codeunit "CEM Help";
        Runner: Codeunit "CEM Runner";
        Seen: Text;

    // One row of LEW Host, committed.
    local procedure Initialize()
    var
        Host: Record "LEW Host";
    begin
        Host.DeleteAll();
        Host."No." := 'H';
        Host.Insert();
        Commit();
    end;

    local procedure Run(Worker: Integer; Mode: Text; var Results: Dictionary of [Text, Text])
    var
        Hosts: TestPage "LEW Hosts";
        Parameters: Dictionary of [Text, Text];
    begin
        Parameters.Add('Mode', Mode);
        Hosts.OpenView();
        Results := Hosts.RunPageBackgroundTask(Worker, Parameters, false);
        Hosts.Close();
    end;

    local procedure WorkerCatches()
    var
        Results: Dictionary of [Text, Text];
    begin
        Run(Codeunit::"LWS Reader", 'catch', Results);
    end;

    [ModalPageHandler]
    procedure DocWithWorker(var P: TestPage "CEM Doc")
    begin
        WorkerCatches();
        Error('CEM handler error');
    end;

    [PageHandler]
    procedure CardWithWorker(var P: TestPage "CEM Card")
    begin
        WorkerCatches();
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('DocWithWorker')]
    procedure DocumentStaticRunModal_WorkerCaughtItsError_HandlerError_NoError()
    var
        Row: Record "CEM Row";
        Res: Action;
    begin
        Initialize();
        Help.Setup('none', 'doc', 7);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            Error('CEM_NO_ERROR');
        end;
        Seen := GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Cfg.Take();
        Cfg.Quiet();
        Assert.AreEqual('CEM handler error|Dialog|Q-doc LookupCancel; C-doc; ', Seen, 'the end of the run and the triggers that ran');
    end;

    [Test]
    [HandlerFunctions('CardWithWorker')]
    procedure CardVariableRun_WorkerCaughtItsError_HandlerOk_NoError()
    var
        Row: Record "CEM Row";
    begin
        Initialize();
        Help.Setup('none', 'card', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardVariable(Row);
            Error('CEM_NO_ERROR');
        end;
        Seen := GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Cfg.Take();
        Cfg.Quiet();
        Assert.AreEqual('CEM_NO_ERROR|Dialog|Q-card OK; C-card; ', Seen, 'the end of the run and the triggers that ran');
    end;

    [Test]
    procedure TestSessionCollects_WorkerCollectsItsOwnTestField_TheTaskSucceeds()
    begin
        Initialize();
        Seen := '';
        RunWhileCollecting();
        Assert.AreEqual('1', Seen, 'the number of errors the worker collected');
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure RunWhileCollecting()
    var
        Results: Dictionary of [Text, Text];
    begin
        Run(Codeunit::"LWN Collecting Worker", '', Results);
        Results.Get('Count', Seen);
        Assert.AreEqual(false, HasCollectedErrors() and (GetCollectedErrors().Count() > 0), 'the test session collected an error');
    end;
}
