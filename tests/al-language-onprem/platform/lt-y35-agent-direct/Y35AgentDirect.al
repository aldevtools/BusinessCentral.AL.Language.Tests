// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/ai/ai-agent-overview
// Scope: in-scope (OnPrem app: table Agent (2000000260) has Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app
// Probe (gap cycle 3, C3-02): what each read and write of the platform table Agent does when this (non-Microsoft) app calls it directly in a
//   test session on the corpus container: the shape of System Application Test's LibraryMockAgent.DeleteAllAgents (SetFilter on
//   "Agent Metadata Provider" + FindSet) and GetOrCreateDefaultAgent (SetRange + SetFilter + FindFirst, then Insert(true)).
//   Each read runs in a TryFunction; each write runs in the OnRun of codeunit 98665 through Codeunit.Run (the containers refuse a write
//   inside a TryFunction: "Call to the function 'INSERT' is not allowed inside the call to ... when it is used as a TryFunction.").
//   Observed: ok and what it returned, or the error text and code.
//   The Microsoft-caller neighbour (Agent API of the System Application): tests/al-language/platform/lt-y35-agent-api/Y35AgentApi.al.
// BC versions: 27.5, 28.5, 29.0. Enum "Agent Metadata Provider" has the value "Personal Agent" (1) on BC 29 only; on BC 27/28 both filter
// Measured on the CI containers 27.5, 28.5 and 29.0: every read and write of Agent (FindSet with the filter, FindFirst, IsEmpty, Count,
//   FindLast, Get, Insert(true), Insert()) fails with "Agents are temporarily unavailable. ..." (code DB:Ok) and leaves no write transaction;
//   a temporary Agent record works. This is a property of the container's agent service (a BC 29 SaaS sandbox answers otherwise for the
//   API calls, see Y35AgentApi.al), so the values pin the corpus container.
//   values are the default (0).

codeunit 98665 "LT Y35 Agent Direct Runner"
{
    var
        RunTrigger: Boolean;
        Shown: Text;

    trigger OnRun()
    var
        Agent: Record Agent;
    begin
        Shown := '';
        Agent.Init();
        Agent."User Name" := 'LTY35';
        Agent."Display Name" := 'LT Y35';
        Shown := Format(Agent.Insert(RunTrigger));
    end;

    procedure SetRunTrigger(NewRunTrigger: Boolean)
    begin
        RunTrigger := NewRunTrigger;
    end;

    procedure GetShown(): Text
    begin
        exit(Shown);
    end;
}

codeunit 98664 "LT Y35 Agent Direct"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Provider1(var P: Enum "Agent Metadata Provider")
    begin
#if BC29PLUS
        P := P::"Personal Agent";
#endif
    end;

    [TryFunction]
    local procedure TryFindSetFiltered(var Shown: Text)
    var
        Agent: Record Agent;
        P0: Enum "Agent Metadata Provider";
        P1: Enum "Agent Metadata Provider";
    begin
        Provider1(P1);
        Agent.SetFilter("Agent Metadata Provider", '%1|%2', P0, P1);
        Shown := Format(Agent.FindSet());
    end;

    [TryFunction]
    local procedure TryFindFirstFiltered(var Shown: Text)
    var
        Agent: Record Agent;
        P1: Enum "Agent Metadata Provider";
    begin
        Provider1(P1);
        Agent.SetRange("Agent Metadata Provider", P1);
        Agent.SetFilter("User Name", 'X');
        Shown := Format(Agent.FindFirst());
    end;

    [TryFunction]
    local procedure TryIsEmpty(var Shown: Text)
    var
        Agent: Record Agent;
    begin
        Shown := Format(Agent.IsEmpty());
    end;

    [TryFunction]
    local procedure TryCount(var Shown: Text)
    var
        Agent: Record Agent;
    begin
        Shown := Format(Agent.Count());
    end;

    [TryFunction]
    local procedure TryFindLast(var Shown: Text)
    var
        Agent: Record Agent;
    begin
        Shown := Format(Agent.FindLast());
    end;

    [TryFunction]
    local procedure TryGet(var Shown: Text)
    var
        Agent: Record Agent;
    begin
        Shown := Format(Agent.Get(CreateGuid()));
    end;

    local procedure RunInsert(Op: Text; RunTrigger: Boolean)
    var
        Runner: Codeunit "LT Y35 Agent Direct Runner";
    begin
        Runner.SetRunTrigger(RunTrigger);
        Commit();
        if Runner.Run() then
            Observer.Observe(Op, 'ok|' + Runner.GetShown())
        else
            Observer.ObserveError(Op);
    end;

    [TryFunction]
    local procedure TryTemporary(var Shown: Text)
    var
        TempAgent: Record Agent temporary;
    begin
        TempAgent.Init();
        TempAgent."User Security ID" := CreateGuid();
        TempAgent."User Name" := 'LTY35';
        TempAgent.Insert();
        Shown := Format(TempAgent.FindFirst()) + '|' + TempAgent."User Name" + '|' + Format(TempAgent.Count());
    end;

    local procedure Run(Op: Text; Ok: Boolean; Shown: Text)
    begin
        if Ok then
            Observer.Observe(Op, 'ok|' + Shown)
        else
            Observer.ObserveError(Op);
    end;

    [Test]
    procedure C302_AgentDirect_FindSetFiltered()
    var
        Shown: Text;
    begin
        Run('findset_filtered', TryFindSetFiltered(Shown), Shown);
#if BC28PLUS
        Observer.Expect('findset_filtered|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('findset_filtered|code', 'DB:Ok');
#else
        Observer.Expect('findset_filtered|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('findset_filtered|code', 'DB:Ok');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure C302_AgentDirect_Reads()
    var
        Shown: Text;
    begin
        Run('findfirst_filtered', TryFindFirstFiltered(Shown), Shown);
        Run('isempty', TryIsEmpty(Shown), Shown);
        Run('count', TryCount(Shown), Shown);
        Run('findlast', TryFindLast(Shown), Shown);
        Run('get', TryGet(Shown), Shown);
        Observer.Expect('findfirst_filtered|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('findfirst_filtered|code', 'DB:Ok');
        Observer.Expect('isempty|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('isempty|code', 'DB:Ok');
        Observer.Expect('count|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('count|code', 'DB:Ok');
        Observer.Expect('findlast|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('findlast|code', 'DB:Ok');
        Observer.Expect('get|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('get|code', 'DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure C302_AgentDirect_Inserts()
    begin
        RunInsert('insert_true', true);
        Observer.Observe('in_write_transaction_1', Format(Database.IsInWriteTransaction()));
        RunInsert('insert_false', false);
        Observer.Observe('in_write_transaction_2', Format(Database.IsInWriteTransaction()));
        Observer.Expect('insert_true|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('insert_true|code', 'DB:Ok');
        Observer.Expect('in_write_transaction_1', 'No');
        Observer.Expect('insert_false|text', 'Agents are temporarily unavailable. Please try again later. You can check the Business Central Admin Center and Microsoft 365 Service Health dashboard for updates.');
        Observer.Expect('insert_false|code', 'DB:Ok');
        Observer.Expect('in_write_transaction_2', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure C302_AgentDirect_Temporary()
    var
        Shown: Text;
    begin
        Run('temporary', TryTemporary(Shown), Shown);
        Observer.Expect('temporary', 'ok|Yes|LTY35|1');
        Observer.Verify();
    end;
}
