// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/ai/ai-agent-overview
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (gap cycle 3, C3-02): the Agent API of the System Application (Microsoft caller) and the Cloud-scope agent task tables read and written
//   directly by this app, in a test session on the corpus container. Each call runs in a TryFunction: ok and what it returned, or the error
//   text and code. Neighbours: platform/lt-rh-agent-session/RhAgentSession.al (Get on Agent and IsEmpty on Agent Task through the API) and
//   tests/al-language-onprem/platform/lt-y35-agent-direct/Y35AgentDirect.al (direct access to Agent from this app).
// BC versions: 27.5, 28.5, 29.0. Enum "Agent Metadata Provider" has the value "Personal Agent" (1) on BC 29 only; on BC 27/28 Create gets
//   the default (0).

codeunit 92350 "LT Y35 Agent Api"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryCreate(var Shown: Text)
    var
        AgentApi: Codeunit Agent;
        TempAccess: Record "Agent Access Control" temporary;
        P: Enum "Agent Metadata Provider";
        UserName: Code[50];
    begin
        UserName := 'LTY35API';
#if BC29PLUS
        P := P::"Personal Agent";
#endif
        Shown := Format(not IsNullGuid(AgentApi.Create(P, UserName, 'LT Y35 Api', TempAccess))) + '|user name after=' + UserName;
    end;

    [TryFunction]
    local procedure TryActivate()
    var
        AgentApi: Codeunit Agent;
    begin
        AgentApi.Activate(CreateGuid());
    end;

    [TryFunction]
    local procedure TryTaskCreate(var Shown: Text)
    var
        Builder: Codeunit "Agent Task Builder";
        Task: Record "Agent Task";
    begin
        Task := Builder.Initialize(CreateGuid(), 'LT Y35').AddTaskMessage('from', 'text').Create();
        Shown := Format(Task.ID <> 0);
    end;

    [TryFunction]
    local procedure TryTaskFindSet(var Shown: Text)
    var
        Task: Record "Agent Task";
    begin
        Shown := Format(Task.FindSet());
    end;

    [TryFunction]
    local procedure TryTaskCount(var Shown: Text)
    var
        Task: Record "Agent Task";
    begin
        Shown := Format(Task.Count());
    end;

    [TryFunction]
    local procedure TryTaskGet(var Shown: Text)
    var
        Task: Record "Agent Task";
    begin
        Shown := Format(Task.Get(1));
    end;

    [TryFunction]
    local procedure TryTaskInsert(var Shown: Text)
    var
        Task: Record "Agent Task";
    begin
        Task.Init();
        Task."Agent User Security ID" := CreateGuid();
        Shown := Format(Task.Insert());
    end;

    [TryFunction]
    local procedure TryMessageFindSet(var Shown: Text)
    var
        Msg: Record "Agent Task Message";
    begin
        Shown := Format(Msg.FindSet());
    end;

    [TryFunction]
    local procedure TryMessageInsert(var Shown: Text)
    var
        Msg: Record "Agent Task Message";
    begin
        Msg.Init();
        Msg."Task ID" := 1;
        Msg.ID := CreateGuid();
        Shown := Format(Msg.Insert());
    end;

    [TryFunction]
    local procedure TryAccessFindSet(var Shown: Text)
    var
        Access: Record "Agent Access Control";
    begin
        Shown := Format(Access.FindSet());
    end;

    local procedure Run(Op: Text; Ok: Boolean; Shown: Text)
    begin
        if Ok then
            Observer.Observe(Op, 'ok|' + Shown)
        else
            Observer.ObserveError(Op);
        Observer.Observe(Op + '|in_write_transaction', Format(Database.IsInWriteTransaction()));
    end;

    [Test]
    procedure C302_AgentApi_Create()
    var
        Shown: Text;
    begin
        Run('create', TryCreate(Shown), Shown);
        Observer.Finish();
    end;

    [Test]
    procedure C302_AgentApi_Activate()
    begin
        Run('activate', TryActivate(), '');
        Observer.Finish();
    end;

    [Test]
    procedure C302_AgentApi_TaskCreate()
    var
        Shown: Text;
    begin
        Run('task_create', TryTaskCreate(Shown), Shown);
        Observer.Finish();
    end;

    [Test]
    procedure C302_AgentTaskDirect_Reads()
    var
        Shown: Text;
    begin
        Run('task_findset', TryTaskFindSet(Shown), Shown);
        Run('task_count', TryTaskCount(Shown), Shown);
        Run('task_get', TryTaskGet(Shown), Shown);
        Run('message_findset', TryMessageFindSet(Shown), Shown);
        Run('access_findset', TryAccessFindSet(Shown), Shown);
        Observer.Finish();
    end;

    [Test]
    procedure C302_AgentTaskDirect_Inserts()
    var
        Shown: Text;
    begin
        Run('task_insert', TryTaskInsert(Shown), Shown);
        Run('message_insert', TryMessageInsert(Shown), Shown);
        Observer.Finish();
    end;
}
