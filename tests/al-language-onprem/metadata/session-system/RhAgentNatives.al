// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/ai/ai-agent-overview
// Scope: in-scope (OnPrem app only: the procedures of codeunits 2000000020 "Feature Access Management" and 2000000022 "Agent Utilities" are Scope OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app
// Probe: al-runner issues 5684, 5685 and 5686 (aldevtools/BusinessCentral.AL.Runner). What the [Native] procedures behind the System Application agent API answer
//   in a test session that is not an agent session, on the corpus CI container: Agent Utilities GetCurrentSessionAgentTaskId,
//   GetCurrentSessionAgentMetadataProviderType, IsAgentSession; Feature Access Management AgentTaskManagementPreviewEnabled, AgentManagementAllowed (BC 28+),
//   IsSandboxEnvironment, IsEnvironmentPositiveListed, IsSandboxEnvironmentOrFirstPartyCode, IsTestSession (BC 28+), each with ThrowError false and true
//   (an error is caught by a TryFunction and its text and code observed). Called from this (non-Microsoft) app the Feature Access Management checks raise
//   "Feature availability can only be checked by Microsoft applications." (InvalidOperation) whatever ThrowError says; called by the System Application
//   (al-language/platform/lt-rh-agent-session/RhAgentSession.al) the same access check passes without an error.
//   Not probed: Agent Utilities SetInstructions/GetInstructions. Issue 5684 reports that a reached SetInstructions stops the test with an uncatchable CLR exception
//   (No service for type 'IAgentInstructionsProvider'), which is not an AL error a test can assert.
// BC versions: 27, 28, 29. Object id 98200.

codeunit 98200 "LT RH Agent Natives"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryPreview(ThrowError: Boolean; var Answer: Boolean)
    var
        Fam: Codeunit "Feature Access Management";
    begin
        Answer := Fam.AgentTaskManagementPreviewEnabled(ThrowError);
    end;

    [TryFunction]
    local procedure TrySandboxOrFirstParty(ThrowError: Boolean; var Answer: Boolean)
    var
        Fam: Codeunit "Feature Access Management";
    begin
        Answer := Fam.IsSandboxEnvironmentOrFirstPartyCode(ThrowError);
    end;

#if BC28PLUS
    [TryFunction]
    local procedure TryAllowed(ThrowError: Boolean; var Answer: Boolean)
    var
        Fam: Codeunit "Feature Access Management";
    begin
        Answer := Fam.AgentManagementAllowed(ThrowError);
    end;
#endif

    [TryFunction]
    local procedure TryEnvironment(Which: Integer; var Answer: Boolean)
    var
        Fam: Codeunit "Feature Access Management";
    begin
        case Which of
            1:
                Answer := Fam.IsSandboxEnvironment();
            2:
                Answer := Fam.IsEnvironmentPositiveListed();
#if BC28PLUS
            3:
                Answer := Fam.IsTestSession();
#endif
        end;
    end;

    local procedure ObserveTry(Name: Text; Ok: Boolean; Answer: Boolean)
    begin
        Observer.Observe(Name, Format(Ok) + '|' + Format(Answer));
        Observer.ObserveError(Name + ' error');
    end;

    [Test]
    procedure RH_AgentUtilities_OutsideAgentSession()
    var
        AgentUtilities: Codeunit "Agent Utilities";
        Provider: Enum "Agent Metadata Provider";
    begin
        Observer.Observe('task id', Format(AgentUtilities.GetCurrentSessionAgentTaskId()));
        Observer.Observe('provider type', Format(AgentUtilities.GetCurrentSessionAgentMetadataProviderType()));
        Observer.Observe('is agent session', Format(AgentUtilities.IsAgentSession(Provider)));
        Observer.Observe('provider after', Format(Provider.AsInteger()));
        Observer.Expect('task id', '0');
        Observer.Expect('provider type', '-1');
        Observer.Expect('is agent session', 'No');
        Observer.Expect('provider after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure RH_FeatureAccess_AgentPreviewEnabled()
    var
        Answer: Boolean;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryPreview(false, Answer);
        ObserveTry('preview false', Ok, Answer);
        Answer := false;
        Ok := TryPreview(true, Answer);
        ObserveTry('preview true', Ok, Answer);
        Observer.Expect('preview false', 'No|No');
        Observer.Expect('preview false error|text', 'Feature availability can only be checked by Microsoft applications.');
        Observer.Expect('preview false error|code', 'InvalidOperation');
        Observer.Expect('preview true', 'No|No');
        Observer.Expect('preview true error|text', 'Feature availability can only be checked by Microsoft applications.');
        Observer.Expect('preview true error|code', 'InvalidOperation');
        Observer.Verify();
    end;

#if BC28PLUS
    [Test]
    procedure RH_FeatureAccess_AgentManagementAllowed()
    var
        Answer: Boolean;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryAllowed(false, Answer);
        ObserveTry('allowed false', Ok, Answer);
        Answer := false;
        Ok := TryAllowed(true, Answer);
        ObserveTry('allowed true', Ok, Answer);
        Observer.Expect('allowed false', 'No|No');
        Observer.Expect('allowed false error|text', 'Feature availability can only be checked by Microsoft applications.');
        Observer.Expect('allowed false error|code', 'InvalidOperation');
        Observer.Expect('allowed true', 'No|No');
        Observer.Expect('allowed true error|text', 'Feature availability can only be checked by Microsoft applications.');
        Observer.Expect('allowed true error|code', 'InvalidOperation');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure RH_FeatureAccess_Environment()
    var
        Answer: Boolean;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryEnvironment(1, Answer);
        ObserveTry('sandbox', Ok, Answer);
        Answer := false;
        Ok := TryEnvironment(2, Answer);
        ObserveTry('positive listed', Ok, Answer);
#if BC28PLUS
        Answer := false;
        Ok := TryEnvironment(3, Answer);
        ObserveTry('test session', Ok, Answer);
#endif
        Answer := false;
        Ok := TrySandboxOrFirstParty(false, Answer);
        ObserveTry('sandbox or first party false', Ok, Answer);
        Answer := false;
        Ok := TrySandboxOrFirstParty(true, Answer);
        ObserveTry('sandbox or first party true', Ok, Answer);
        Observer.Expect('sandbox', 'Yes|Yes');
        Observer.Expect('sandbox error|text', '');
        Observer.Expect('sandbox error|code', '');
        Observer.Expect('positive listed', 'No|No');
        Observer.Expect('positive listed error|text', 'Feature availability can only be checked by Microsoft applications.');
        Observer.Expect('positive listed error|code', 'InvalidOperation');
#if BC28PLUS
        Observer.Expect('test session', 'No|No');
        Observer.Expect('test session error|text', 'Feature availability can only be checked by Microsoft applications.');
        Observer.Expect('test session error|code', 'InvalidOperation');
#endif
        Observer.Expect('sandbox or first party false', 'No|No');
        Observer.Expect('sandbox or first party false error|text', 'Feature availability can only be checked by Microsoft applications.');
        Observer.Expect('sandbox or first party false error|code', 'InvalidOperation');
        Observer.Expect('sandbox or first party true', 'No|No');
        Observer.Expect('sandbox or first party true error|text', 'Feature availability can only be checked by Microsoft applications.');
        Observer.Expect('sandbox or first party true error|code', 'InvalidOperation');
        Observer.Verify();
    end;
}
