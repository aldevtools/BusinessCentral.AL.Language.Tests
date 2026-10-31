// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/ai/ai-agent-overview
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (gap cycle 3, C3-02): the Agent API of the System Application (Microsoft caller) and the Cloud-scope agent task tables read and written
//   directly by this app, in a test session on the corpus container. Each read runs in a TryFunction, each write in codeunit 92351 through
//   Codeunit.Run: ok and what it returned, or the error text and code. Neighbours: platform/lt-rh-agent-session/RhAgentSession.al (Get on Agent and IsEmpty on Agent Task through the API) and
//   tests/al-language-onprem/platform/lt-y35-agent-direct/Y35AgentDirect.al (direct access to Agent from this app).
// BC versions: 27.5, 28.5, 29.0. Enum "Agent Metadata Provider" has the value "Personal Agent" (1) on BC 29 only; on BC 27/28 Create gets
//   the default (0).
// Measured on the CI containers 27.5, 28.5 and 29.0: Create, Activate, Agent Task Builder Create, and every read and insert of Agent Task,
//   Agent Task Message and Agent Access Control fail with "Agents are temporarily unavailable. ..." (code DB:Ok), no write transaction left.
//   Not asserted (BC 29 SaaS sandbox with an agent service): Create "Inserting personal agents is not allowed." (DB:Ok); Activate and Task
//   Builder Create of an unknown agent "Agent does not exist." (Dialog); the task tables read as empty; Agent Task Insert "An Agent user with
//   ID '<guid>' could not be found." and Agent Task Message Insert "An Agent Task with ID '1' could not be found." (DB:Ok).

// Runs one write of the agent API or the agent task tables in its OnRun, called through Codeunit.Run (the containers refuse a write inside a
// TryFunction: "Call to the function 'INSERT' is not allowed inside the call to ... when it is used as a TryFunction.").
codeunit 92351 "LT Y35 Agent Api Runner"
{
    var
        Op: Text;
        Shown: Text;

    trigger OnRun()
    var
        AgentApi: Codeunit Agent;
        Builder: Codeunit "Agent Task Builder";
        TempAccess: Record "Agent Access Control" temporary;
        Task: Record "Agent Task";
        Msg: Record "Agent Task Message";
        P: Enum "Agent Metadata Provider";
        UserName: Code[50];
    begin
        Shown := '';
        case Op of
            'create':
                begin
                    UserName := 'LTY35API';
#if BC29PLUS
                    P := P::"Personal Agent";
#endif
                    Shown := Format(not IsNullGuid(AgentApi.Create(P, UserName, 'LT Y35 Api', TempAccess))) + '|user name after=' + UserName;
                end;
            'activate':
                AgentApi.Activate(CreateGuid());
            'task_create':
                begin
                    Task := Builder.Initialize(CreateGuid(), 'LT Y35').AddTaskMessage('from', 'text').Create();
                    Shown := Format(Task.ID <> 0);
                end;
            'task_insert':
                begin
                    Task.Init();
                    Task."Agent User Security ID" := CreateGuid();
                    Shown := Format(Task.Insert());
                end;
            'message_insert':
                begin
                    Msg.Init();
                    Msg."Task ID" := 1;
                    Msg.ID := CreateGuid();
                    Shown := Format(Msg.Insert());
                end;
        end;
    end;

    procedure SetOp(NewOp: Text)
    begin
        Op := NewOp;
    end;

    procedure GetShown(): Text
    begin
        exit(Shown);
    end;
}

codeunit 92350 "LT Y35 Agent Api"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";




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
    local procedure TryMessageFindSet(var Shown: Text)
    var
        Msg: Record "Agent Task Message";
    begin
        Shown := Format(Msg.FindSet());
    end;


    [TryFunction]
    local procedure TryAccessFindSet(var Shown: Text)
    var
        Access: Record "Agent Access Control";
    begin
        Shown := Format(Access.FindSet());
    end;

    local procedure RunWrite(Op: Text)
    var
        Runner: Codeunit "LT Y35 Agent Api Runner";
    begin
        Runner.SetOp(Op);
        Commit();
        if Runner.Run() then
            Observer.Observe(Op, 'ok|' + Runner.GetShown())
        else
            Observer.ObserveError(Op);
        Observer.Observe(Op + '|in_write_transaction', Format(Database.IsInWriteTransaction()));
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
    begin
        RunWrite('create');
#if BC28PLUS
        Observer.Expect('create|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('create|code', 'DB:Ok');
        Observer.Expect('create|in_write_transaction', 'No');
#else
        Observer.Expect('create|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('create|code', 'DB:Ok');
        Observer.Expect('create|in_write_transaction', 'No');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure C302_AgentApi_Activate()
    begin
        RunWrite('activate');
        Observer.Expect('activate|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('activate|code', 'DB:Ok');
        Observer.Expect('activate|in_write_transaction', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure C302_AgentApi_TaskCreate()
    begin
        RunWrite('task_create');
        Observer.Expect('task_create|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('task_create|code', 'DB:Ok');
        Observer.Expect('task_create|in_write_transaction', 'No');
        Observer.Verify();
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
        Observer.Expect('task_findset|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('task_findset|code', 'DB:Ok');
        Observer.Expect('task_findset|in_write_transaction', 'No');
        Observer.Expect('task_count|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('task_count|code', 'DB:Ok');
        Observer.Expect('task_count|in_write_transaction', 'No');
        Observer.Expect('task_get|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('task_get|code', 'DB:Ok');
        Observer.Expect('task_get|in_write_transaction', 'No');
        Observer.Expect('message_findset|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('message_findset|code', 'DB:Ok');
        Observer.Expect('message_findset|in_write_transaction', 'No');
        Observer.Expect('access_findset|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('access_findset|code', 'DB:Ok');
        Observer.Expect('access_findset|in_write_transaction', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure C302_AgentTaskDirect_Inserts()
    begin
        RunWrite('task_insert');
        RunWrite('message_insert');
        Observer.Expect('task_insert|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('task_insert|code', 'DB:Ok');
        Observer.Expect('task_insert|in_write_transaction', 'No');
        Observer.Expect('message_insert|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('message_insert|code', 'DB:Ok');
        Observer.Expect('message_insert|in_write_transaction', 'No');
        Observer.Verify();
    end;
}
