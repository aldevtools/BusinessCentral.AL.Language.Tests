// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet; "Azure AD Plan".TryGetAzureUserPlanRoleCenterId is Scope = OnPrem), AL compiler 18.0 or newer
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61494
// Probe (al-runner issue 7914, corpus bump 317272f1): the real Microsoft.Dynamics.Nav.AzureADGraphClient.GraphQuery (no mock) on a tier
//   without Microsoft Entra ID, reached the way System Application's "Azure AD Graph Impl." and "Azure AD Plan Impl." reach it
//   (GraphQuery := GraphQuery.GraphQuery(), then GetCurrentUser / GetUserByObjectId / GetUser / IsGroupMember / GetEnvironmentDirectoryGroup),
//   the members of a null UserInfo (ObjectId, AssignedPlans, Roles, Groups), and the public procedures on top of it:
//   "Azure AD Plan".TryGetAzureUserPlanRoleCenterId, "Conf./Personalization Mgt.".DefaultRoleCenterID and GetCurrentProfileNoError,
//   with the session state (GlobalLanguage, WorkDate, User Personalization row, User Property rows) read before and after.
// Related: PXAzureAdGraph.al and PZAzureAdUser.al (OnPrem app: the same calls through the System Application facades),
//   Y58MockGraphQuery.al (members of UserInfo / ServicePlanInfo / RoleInfo / GroupInfo on objects built in AL and on the mock).
// Facts: the constructor succeeds; GetCurrentUser answers null (twice); GetUserByObjectId (also with ''), GetUser and IsGroupMember raise
//   "A call to ...GraphQuery.<method> failed with this message: Object reference not set to an instance of an object." (DotNetInvoke:NullReference);
//   GetEnvironmentDirectoryGroup answers ''. Every member of a null UserInfo (ObjectId, AssignedPlans, Roles, Groups, also in foreach) raises
//   "A DotNet variable has not been instantiated. Attempting to call ...UserInfo.<member> in CodeUnit <name>: <procedure>" (DotNetVariableNotCreated),
//   so ServicePlanInfo / RoleInfo / GroupInfo members cannot be reached on this tier. IsSaaS and IsSandbox are Yes; TryGetAzureUserPlanRoleCenterId
//   answers Yes with role center 0 and no last error; DefaultRoleCenterID answers 9022; GetCurrentProfileNoError answers Yes / BUSINESS MANAGER / Tenant;
//   none of them changes GlobalLanguage, WorkDate, the User Personalization row or the User Property row count. Same on all three versions.
// Expected values: corpus CI (Linux containers) BC 27.5, 28.5 and 29.0, observe run 45879829162.
// BC versions: 27, 28, 29
dotnet
{
    assembly("Microsoft.Dynamics.Nav.AzureADGraphClient")
    {
        type("Microsoft.Dynamics.Nav.AzureADGraphClient.GraphQuery"; LtY93GraphQuery) { }
    }
    assembly("Microsoft.Dynamics.Nav.LicensingService.Model")
    {
        type("Microsoft.Dynamics.Nav.LicensingService.Model.UserInfo"; LtY93UserInfo) { }
        type("Microsoft.Dynamics.Nav.LicensingService.Model.ServicePlanInfo"; LtY93ServicePlanInfo) { }
        type("Microsoft.Dynamics.Nav.LicensingService.Model.RoleInfo"; LtY93RoleInfo) { }
        type("Microsoft.Dynamics.Nav.LicensingService.Model.GroupInfo"; LtY93GroupInfo) { }
    }
}

codeunit 61494 "LT Y93 Graph No Directory"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Graph: DotNet LtY93GraphQuery;

    local procedure Outcome(Ok: Boolean; Value: Text): Text
    begin
        if Ok then
            exit('ok:' + Value);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Describe(UserInfo: DotNet LtY93UserInfo): Text
    begin
        if IsNull(UserInfo) then
            exit('null');
        exit('object:' + Format(UserInfo.ObjectId));
    end;

    [TryFunction]
    local procedure TryNew()
    begin
        Graph := Graph.GraphQuery();
    end;

    [TryFunction]
    local procedure TryCurrentUser(var Result: Text)
    var
        UserInfo: DotNet LtY93UserInfo;
    begin
        UserInfo := Graph.GetCurrentUser();
        Result := Describe(UserInfo);
    end;

    [TryFunction]
    local procedure TryByObjectId(ObjectId: Text; var Result: Text)
    var
        UserInfo: DotNet LtY93UserInfo;
    begin
        UserInfo := Graph.GetUserByObjectId(ObjectId);
        Result := Describe(UserInfo);
    end;

    [TryFunction]
    local procedure TryUser(Upn: Text; var Result: Text)
    var
        UserInfo: DotNet LtY93UserInfo;
    begin
        UserInfo := Graph.GetUser(Upn);
        Result := Describe(UserInfo);
    end;

    [TryFunction]
    local procedure TryIsGroupMember(var Result: Boolean)
    begin
        Result := Graph.IsGroupMember('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002');
    end;

    [TryFunction]
    local procedure TryEnvGroup(var Result: Text)
    begin
        Result := Format(Graph.GetEnvironmentDirectoryGroup());
    end;

    [Test]
    procedure GraphQuery_Direct_WithoutDirectory()
    var
        T: Text;
        B: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('constructor', Outcome(TryNew(), Format(IsNull(Graph))));
        ClearLastError();
        Observer.Observe('get_current_user', Outcome(TryCurrentUser(T), T));
        ClearLastError();
        Observer.Observe('get_current_user_again', Outcome(TryCurrentUser(T), T));
        ClearLastError();
        Observer.Observe('get_user_by_object_id', Outcome(TryByObjectId('00000000-0000-0000-0000-000000000001', T), T));
        ClearLastError();
        Observer.Observe('get_user_by_object_id_empty', Outcome(TryByObjectId('', T), T));
        ClearLastError();
        Observer.Observe('get_user', Outcome(TryUser('nobody@example.com', T), T));
        ClearLastError();
        Observer.Observe('is_group_member', Outcome(TryIsGroupMember(B), Format(B)));
        ClearLastError();
        Observer.Observe('environment_directory_group', Outcome(TryEnvGroup(T), '[' + T + ']'));
        Observer.Expect('constructor', 'ok:No');
        Observer.Expect('get_current_user', 'ok:null');
        Observer.Expect('get_current_user_again', 'ok:null');
        Observer.Expect('get_user_by_object_id', 'error:A call to Microsoft.Dynamics.Nav.AzureADGraphClient.GraphQuery.GetUserByObjectId failed with this message: Object reference not set to an instance of an object.|DotNetInvoke:NullReference');
        Observer.Expect('get_user_by_object_id_empty', 'error:A call to Microsoft.Dynamics.Nav.AzureADGraphClient.GraphQuery.GetUserByObjectId failed with this message: Object reference not set to an instance of an object.|DotNetInvoke:NullReference');
        Observer.Expect('get_user', 'error:A call to Microsoft.Dynamics.Nav.AzureADGraphClient.GraphQuery.GetUser failed with this message: Object reference not set to an instance of an object.|DotNetInvoke:NullReference');
        Observer.Expect('is_group_member', 'error:A call to Microsoft.Dynamics.Nav.AzureADGraphClient.GraphQuery.IsGroupMember failed with this message: Object reference not set to an instance of an object.|DotNetInvoke:NullReference');
        Observer.Expect('environment_directory_group', 'ok:[]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryObjectId(UserInfo: DotNet LtY93UserInfo; var Result: Text)
    begin
        Result := Format(UserInfo.ObjectId());
    end;

    [TryFunction]
    local procedure TryPlansNull(UserInfo: DotNet LtY93UserInfo; var Result: Boolean)
    begin
        Result := IsNull(UserInfo.AssignedPlans());
    end;

    [TryFunction]
    local procedure TryRolesNull(UserInfo: DotNet LtY93UserInfo; var Result: Boolean)
    begin
        Result := IsNull(UserInfo.Roles());
    end;

    [TryFunction]
    local procedure TryGroupsNull(UserInfo: DotNet LtY93UserInfo; var Result: Boolean)
    begin
        Result := IsNull(UserInfo.Groups());
    end;

    [TryFunction]
    local procedure TryForeachPlans(UserInfo: DotNet LtY93UserInfo; var Result: Text)
    var
        Plan: DotNet LtY93ServicePlanInfo;
    begin
        foreach Plan in UserInfo.AssignedPlans() do
            Result += Format(Plan.ServicePlanId()) + '/' + Format(Plan.CapabilityStatus()) + '/' + Format(Plan.ServicePlanName()) + ';';
    end;

    [TryFunction]
    local procedure TryForeachRoles(UserInfo: DotNet LtY93UserInfo; var Result: Text)
    var
        Role: DotNet LtY93RoleInfo;
    begin
        foreach Role in UserInfo.Roles() do
            Result += Format(Role.RoleTemplateId()) + '/' + Format(Role.DisplayName()) + ';';
    end;

    [TryFunction]
    local procedure TryForeachGroups(UserInfo: DotNet LtY93UserInfo; var Result: Text)
    var
        Group: DotNet LtY93GroupInfo;
    begin
        foreach Group in UserInfo.Groups() do
            Result += Format(Group.DisplayName()) + ';';
    end;

    [Test]
    procedure UserInfo_FromGetCurrentUser_Members()
    var
        UserInfo: DotNet LtY93UserInfo;
        T: Text;
        B: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        if TryNew() then
            if TryCurrentUser(T) then;
        ClearLastError();
        // UserInfo := Graph.GetCurrentUser() outside a TryFunction, as AzureADGraphImpl does.
        UserInfo := Graph.GetCurrentUser();
        Observer.Observe('is_null', Format(IsNull(UserInfo)));
        Observer.Observe('object_id', Outcome(TryObjectId(UserInfo, T), '[' + T + ']'));
        ClearLastError();
        Observer.Observe('assigned_plans_is_null', Outcome(TryPlansNull(UserInfo, B), Format(B)));
        ClearLastError();
        Observer.Observe('roles_is_null', Outcome(TryRolesNull(UserInfo, B), Format(B)));
        ClearLastError();
        Observer.Observe('groups_is_null', Outcome(TryGroupsNull(UserInfo, B), Format(B)));
        ClearLastError();
        T := '';
        Observer.Observe('foreach_assigned_plans', Outcome(TryForeachPlans(UserInfo, T), '[' + T + ']'));
        ClearLastError();
        T := '';
        Observer.Observe('foreach_roles', Outcome(TryForeachRoles(UserInfo, T), '[' + T + ']'));
        ClearLastError();
        T := '';
        Observer.Observe('foreach_groups', Outcome(TryForeachGroups(UserInfo, T), '[' + T + ']'));
        Observer.Expect('is_null', 'Yes');
        Observer.Expect('object_id', 'error:A DotNet variable has not been instantiated. Attempting to call Microsoft.Dynamics.Nav.LicensingService.Model.UserInfo.ObjectId in CodeUnit LT Y93 Graph No Directory: TryObjectId|DotNetVariableNotCreated');
        Observer.Expect('assigned_plans_is_null', 'error:A DotNet variable has not been instantiated. Attempting to call Microsoft.Dynamics.Nav.LicensingService.Model.UserInfo.AssignedPlans in CodeUnit LT Y93 Graph No Directory: TryPlansNull|DotNetVariableNotCreated');
        Observer.Expect('roles_is_null', 'error:A DotNet variable has not been instantiated. Attempting to call Microsoft.Dynamics.Nav.LicensingService.Model.UserInfo.Roles in CodeUnit LT Y93 Graph No Directory: TryRolesNull|DotNetVariableNotCreated');
        Observer.Expect('groups_is_null', 'error:A DotNet variable has not been instantiated. Attempting to call Microsoft.Dynamics.Nav.LicensingService.Model.UserInfo.Groups in CodeUnit LT Y93 Graph No Directory: TryGroupsNull|DotNetVariableNotCreated');
        Observer.Expect('foreach_assigned_plans', 'error:A DotNet variable has not been instantiated. Attempting to call Microsoft.Dynamics.Nav.LicensingService.Model.UserInfo.AssignedPlans in CodeUnit LT Y93 Graph No Directory: TryForeachPlans|DotNetVariableNotCreated');
        Observer.Expect('foreach_roles', 'error:A DotNet variable has not been instantiated. Attempting to call Microsoft.Dynamics.Nav.LicensingService.Model.UserInfo.Roles in CodeUnit LT Y93 Graph No Directory: TryForeachRoles|DotNetVariableNotCreated');
        Observer.Expect('foreach_groups', 'error:A DotNet variable has not been instantiated. Attempting to call Microsoft.Dynamics.Nav.LicensingService.Model.UserInfo.Groups in CodeUnit LT Y93 Graph No Directory: TryForeachGroups|DotNetVariableNotCreated');
        Observer.Verify();
    end;

    [Test]
    procedure UserInfo_Unassigned_Members()
    var
        UserInfo: DotNet LtY93UserInfo;
        T: Text;
        B: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('is_null', Format(IsNull(UserInfo)));
        Observer.Observe('object_id', Outcome(TryObjectId(UserInfo, T), '[' + T + ']'));
        ClearLastError();
        Observer.Observe('assigned_plans_is_null', Outcome(TryPlansNull(UserInfo, B), Format(B)));
        ClearLastError();
        Observer.Observe('roles_is_null', Outcome(TryRolesNull(UserInfo, B), Format(B)));
        ClearLastError();
        Observer.Observe('groups_is_null', Outcome(TryGroupsNull(UserInfo, B), Format(B)));
        Observer.Expect('is_null', 'Yes');
        Observer.Expect('object_id', 'error:A DotNet variable has not been instantiated. Attempting to call Microsoft.Dynamics.Nav.LicensingService.Model.UserInfo.ObjectId in CodeUnit LT Y93 Graph No Directory: TryObjectId|DotNetVariableNotCreated');
        Observer.Expect('assigned_plans_is_null', 'error:A DotNet variable has not been instantiated. Attempting to call Microsoft.Dynamics.Nav.LicensingService.Model.UserInfo.AssignedPlans in CodeUnit LT Y93 Graph No Directory: TryPlansNull|DotNetVariableNotCreated');
        Observer.Expect('roles_is_null', 'error:A DotNet variable has not been instantiated. Attempting to call Microsoft.Dynamics.Nav.LicensingService.Model.UserInfo.Roles in CodeUnit LT Y93 Graph No Directory: TryRolesNull|DotNetVariableNotCreated');
        Observer.Expect('groups_is_null', 'error:A DotNet variable has not been instantiated. Attempting to call Microsoft.Dynamics.Nav.LicensingService.Model.UserInfo.Groups in CodeUnit LT Y93 Graph No Directory: TryGroupsNull|DotNetVariableNotCreated');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryPlanRoleCenter(var RoleCenterId: Integer; var Ok: Boolean)
    var
        AzureADPlan: Codeunit "Azure AD Plan";
    begin
        Ok := AzureADPlan.TryGetAzureUserPlanRoleCenterId(RoleCenterId, UserSecurityId());
    end;

    local procedure Snapshot(): Text
    var
        UserPersonalization: Record "User Personalization";
        UserProperty: Record "User Property";
        S: Text;
    begin
        S := 'lang=' + Format(GlobalLanguage()) + ';workdate=' + Format(WorkDate(), 0, 9);
        if UserPersonalization.Get(UserSecurityId()) then
            S += ';pers=' + UserPersonalization."Profile ID" + '/' + Format(UserPersonalization."Language ID") + '/' + Format(UserPersonalization.Scope)
        else
            S += ';pers=none';
        S += ';userprops=' + Format(UserProperty.Count());
        exit(S);
    end;

    [Test]
    procedure AzureAdPlan_RoleCenter_And_SessionState()
    var
        EnvInfo: Codeunit "Environment Information";
        ConfPersMgt: Codeunit "Conf./Personalization Mgt.";
        AllProfile: Record "All Profile";
        Before: Text;
        RoleCenterId: Integer;
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('is_saas', Format(EnvInfo.IsSaaS()));
        Observer.Observe('is_sandbox', Format(EnvInfo.IsSandbox()));
        Before := Snapshot();
        Observer.Observe('state_before', Before.Replace(Format(WorkDate(), 0, 9), '<workdate>'));
        RoleCenterId := -1;
        Observer.Observe('try_plan_role_center', Outcome(TryPlanRoleCenter(RoleCenterId, Ok), Format(Ok) + '/' + Format(RoleCenterId)));
        ClearLastError();
        Observer.Observe('last_error_after_try', '[' + GetLastErrorText() + ']');
        Observer.Observe('state_after_try_unchanged', Format(Snapshot() = Before));
        Observer.Observe('default_role_center_id', Format(ConfPersMgt.DefaultRoleCenterID()));
        Observer.Observe('state_after_default_unchanged', Format(Snapshot() = Before));
        Ok := ConfPersMgt.GetCurrentProfileNoError(AllProfile);
        Observer.Observe('current_profile_no_error', Format(Ok) + '/' + AllProfile."Profile ID" + '/' + Format(AllProfile.Scope));
        Observer.Observe('state_after_profile_unchanged', Format(Snapshot() = Before));
        Observer.Observe('is_saas_after', Format(EnvInfo.IsSaaS()));
        Observer.Observe('is_sandbox_after', Format(EnvInfo.IsSandbox()));
        Observer.Expect('is_saas', 'Yes');
        Observer.Expect('is_sandbox', 'Yes');
        Observer.Expect('state_before', 'lang=1033;workdate=<workdate>;pers=BUSINESS MANAGER/1033/Tenant;userprops=3');
        Observer.Expect('try_plan_role_center', 'ok:Yes/0');
        Observer.Expect('last_error_after_try', '[]');
        Observer.Expect('state_after_try_unchanged', 'Yes');
        Observer.Expect('default_role_center_id', '9022');
        Observer.Expect('state_after_default_unchanged', 'Yes');
        Observer.Expect('current_profile_no_error', 'Yes/BUSINESS MANAGER/Tenant');
        Observer.Expect('state_after_profile_unchanged', 'Yes');
        Observer.Expect('is_saas_after', 'Yes');
        Observer.Expect('is_sandbox_after', 'Yes');
        Observer.Verify();
    end;
}
