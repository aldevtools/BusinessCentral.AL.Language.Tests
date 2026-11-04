// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (the "Azure AD Graph" codeunit methods are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61291
// Probe: written against a real BC 27.5 service tier on Linux without Entra ID (user and password authentication); every literal below is what that tier produced.
//
// What the System Application codeunit "Azure AD Graph" does on a container with no Microsoft Entra tenant. It builds its DotNet GraphQuery itself
// (GraphQuery := GraphQuery.GraphQuery(); IsNull is false afterwards), so creating the object does not fail. Then:
//  - IsM365CollaborationEnabled() answers false, GetEnvironmentSecurityGroupId() answers '' and IsEnvironmentSecurityGroupDefined() answers false, without an error;
//  - every call that needs the directory raises "A call to Microsoft.Dynamics.Nav.AzureADGraphClient.GraphQuery.<method> failed with this message: Object reference
//    not set to an instance of an object." with the code DotNetInvoke:NullReference: GetGroups (GetGroupPage), GetGroupName (GetGroupInfo), GetFirstGroupIdWithName
//    (FindFirstGroupInfoForDisplayName) and IsGraphUserAccountEnabled (GetUser).
// BC versions: 27.5
codeunit 61291 "PX Azure AD Graph"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryIsM365(var Result: Boolean)
    var
        Graph: Codeunit "Azure AD Graph";
    begin
        Result := Graph.IsM365CollaborationEnabled();
    end;

    [TryFunction]
    local procedure TryGroupId(var Result: Text)
    var
        Graph: Codeunit "Azure AD Graph";
    begin
        Result := Graph.GetEnvironmentSecurityGroupId();
    end;

    [TryFunction]
    local procedure TryGroupDefined(var Result: Boolean)
    var
        Graph: Codeunit "Azure AD Graph";
    begin
        Result := Graph.IsEnvironmentSecurityGroupDefined();
    end;

    [TryFunction]
    local procedure TryGroups(var Count: Integer)
    var
        Graph: Codeunit "Azure AD Graph";
        Groups: Dictionary of [Text, Text];
    begin
        Groups := Graph.GetGroups();
        Count := Groups.Count();
    end;

    [TryFunction]
    local procedure TryGroupName(var Result: Text)
    var
        Graph: Codeunit "Azure AD Graph";
    begin
        Result := Graph.GetGroupName('00000000-0000-0000-0000-000000000001');
    end;

    [TryFunction]
    local procedure TryFirstGroup(var Result: Text)
    var
        Graph: Codeunit "Azure AD Graph";
    begin
        Result := Graph.GetFirstGroupIdWithName('NoSuchGroup');
    end;

    [TryFunction]
    local procedure TryEnabled(var IsEnabled: Boolean)
    var
        Graph: Codeunit "Azure AD Graph";
    begin
        Graph.IsGraphUserAccountEnabled('nobody@example.com', IsEnabled);
    end;

    local procedure Outcome(Ok: Boolean; Value: Text): Text
    begin
        if Ok then
            exit('ok:' + Value);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure AzureAdGraph_Calls_WithoutDotNetVariables()
    var
        B: Boolean;
        T: Text;
        N: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('is_m365_collaboration_enabled', Outcome(TryIsM365(B), Format(B)));
        ClearLastError();
        Observer.Observe('environment_security_group_id', Outcome(TryGroupId(T), '[' + T + ']'));
        ClearLastError();
        Observer.Observe('environment_security_group_defined', Outcome(TryGroupDefined(B), Format(B)));
        ClearLastError();
        Observer.Observe('get_groups', Outcome(TryGroups(N), Format(N)));
        ClearLastError();
        Observer.Observe('get_group_name', Outcome(TryGroupName(T), '[' + T + ']'));
        ClearLastError();
        Observer.Observe('first_group_with_name', Outcome(TryFirstGroup(T), '[' + T + ']'));
        ClearLastError();
        Observer.Observe('is_user_account_enabled', Outcome(TryEnabled(B), Format(B)));
        Observer.Expect('is_m365_collaboration_enabled', 'ok:No');
        Observer.Expect('environment_security_group_id', 'ok:[]');
        Observer.Expect('environment_security_group_defined', 'ok:No');
        Observer.Expect('get_groups', 'error:A call to Microsoft.Dynamics.Nav.AzureADGraphClient.GraphQuery.GetGroupPage failed with this message: Object reference not set to an instance of an object.|DotNetInvoke:NullReference');
        Observer.Expect('get_group_name', 'error:A call to Microsoft.Dynamics.Nav.AzureADGraphClient.GraphQuery.GetGroupInfo failed with this message: Object reference not set to an instance of an object.|DotNetInvoke:NullReference');
        Observer.Expect('first_group_with_name', 'error:A call to Microsoft.Dynamics.Nav.AzureADGraphClient.GraphQuery.FindFirstGroupInfoForDisplayName failed with this message: Object reference not set to an instance of an object.|DotNetInvoke:NullReference');
        Observer.Expect('is_user_account_enabled', 'error:A call to Microsoft.Dynamics.Nav.AzureADGraphClient.GraphQuery.GetUser failed with this message: Object reference not set to an instance of an object.|DotNetInvoke:NullReference');
        Observer.Verify();
    end;
}
