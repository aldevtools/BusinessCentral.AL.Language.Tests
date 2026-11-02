// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunits 61455, 61456
// Probe: the server test class Microsoft.Dynamics.Nav.AzureADGraphClient.MockGraphQuery (the in-memory Graph that Microsoft's
//   "MockGraphQuery Test Library" fills), read directly, through Microsoft.Dynamics.Nav.AzureADGraphClient.GraphQuery wrapped
//   around it, and through the System Application codeunit "Azure AD Graph" with "Azure AD Graph Test Library" bound.
//   Users (all fields, by object id, principal name, authentication email, a missing user), the current user, assigned plans,
//   roles, groups, subscribed SKUs, M365 collaboration flag, environment security group, tenant detail.
// Facts: lookups by object id and by principal name ignore case; the mock keeps the UserInfo instance it was given (a later change
//   shows on the next read); a missing user raises "Sequence contains no matching element" (DotNetInvoke:InvalidOperation) from
//   GetUserByObjectId and GetUser, while TryGetUserByObjectId returns false, and GetUserByAuthorizationEmail and GetCurrentUser return
//   null; a second AddUser with the same object id is accepted and the lookup by object id returns the first; the current user is
//   kept apart from the user list. Same on all three versions.
// Expected values: corpus CI (Linux containers) BC 27.5, 28.5 and 29.0, batch runs 41332956805, 41336116625, 41336138376.
// BC versions: 27, 28, 29
dotnet
{
    assembly("Microsoft.Dynamics.Nav.AzureADGraphClient")
    {
        type("Microsoft.Dynamics.Nav.AzureADGraphClient.MockGraphQuery"; LtY58MockGraphQuery) { }
        type("Microsoft.Dynamics.Nav.AzureADGraphClient.GraphQuery"; LtY58GraphQuery) { }
    }
    assembly("Microsoft.Dynamics.Nav.LicensingService.Model")
    {
        type("Microsoft.Dynamics.Nav.LicensingService.Model.UserInfo"; LtY58UserInfo) { }
        type("Microsoft.Dynamics.Nav.LicensingService.Model.GroupInfo"; LtY58GroupInfo) { }
        type("Microsoft.Dynamics.Nav.LicensingService.Model.RoleInfo"; LtY58RoleInfo) { }
        type("Microsoft.Dynamics.Nav.LicensingService.Model.ServicePlanInfo"; LtY58ServicePlanInfo) { }
        type("Microsoft.Dynamics.Nav.LicensingService.Model.SkuInfo"; LtY58SkuInfo) { }
        type("Microsoft.Dynamics.Nav.LicensingService.Model.TenantInfo"; LtY58TenantInfo) { }
    }
}

codeunit 61455 "LT Y58 MockGraphQuery"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mock: DotNet LtY58MockGraphQuery;
        Graph: DotNet LtY58GraphQuery;

    local procedure NewMock()
    begin
        Mock := Mock.MockGraphQuery();
        Graph := Graph.GraphQuery(Mock);
    end;

    local procedure NewUser(var UserInfo: DotNet LtY58UserInfo; ObjectId: Text; GivenName: Text; Surname: Text; Mail: Text)
    begin
        UserInfo := UserInfo.UserInfo();
        UserInfo.ObjectId := ObjectId;
        UserInfo.UserPrincipalName := Mail;
        UserInfo.Mail := Mail;
        UserInfo.GivenName := GivenName;
        UserInfo.Surname := Surname;
        UserInfo.AccountEnabled := true;
        UserInfo.DisplayName := GivenName + ' ' + Surname;
    end;

    local procedure Describe(UserInfo: DotNet LtY58UserInfo): Text
    begin
        if IsNull(UserInfo) then
            exit('null');
        exit(Format(UserInfo.ObjectId) + '|' + Format(UserInfo.DisplayName) + '|' + Format(UserInfo.GivenName) + '|' + Format(UserInfo.Surname) + '|' +
            Format(UserInfo.Mail) + '|' + Format(UserInfo.UserPrincipalName) + '|' + Format(UserInfo.PreferredLanguage) + '|' + Format(UserInfo.AccountEnabled));
    end;

    [TryFunction]
    local procedure TryMockByObjectId(ObjectId: Text; var Result: Text)
    var
        UserInfo: DotNet LtY58UserInfo;
    begin
        UserInfo := Mock.GetUserByObjectId(ObjectId);
        Result := Describe(UserInfo);
    end;

    [TryFunction]
    local procedure TryGraphByObjectId(ObjectId: Text; var Result: Text)
    var
        UserInfo: DotNet LtY58UserInfo;
    begin
        UserInfo := Graph.GetUserByObjectId(ObjectId);
        Result := Describe(UserInfo);
    end;

    [TryFunction]
    local procedure TryGraphTryByObjectId(ObjectId: Text; var Result: Text)
    var
        UserInfo: DotNet LtY58UserInfo;
        Found: Boolean;
    begin
        Found := Graph.TryGetUserByObjectId(ObjectId, UserInfo);
        Result := Format(Found) + '/' + Describe(UserInfo);
    end;

    [TryFunction]
    local procedure TryGraphByPrincipal(Upn: Text; var Result: Text)
    var
        UserInfo: DotNet LtY58UserInfo;
    begin
        UserInfo := Graph.GetUser(Upn);
        Result := Describe(UserInfo);
    end;

    [TryFunction]
    local procedure TryGraphByAuthEmail(Email: Text; var Result: Text)
    var
        UserInfo: DotNet LtY58UserInfo;
    begin
        UserInfo := Graph.GetUserByAuthorizationEmail(Email);
        Result := Describe(UserInfo);
    end;

    [TryFunction]
    local procedure TryGraphCurrent(var Result: Text)
    var
        UserInfo: DotNet LtY58UserInfo;
    begin
        UserInfo := Graph.GetCurrentUser();
        Result := Describe(UserInfo);
    end;

    local procedure ObserveTry(Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean; Result: Text)
    begin
        if Ok then
            Observer.Observe(Name, Result)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure MockGraph_AddUser_ReadBack()
    var
        Observer: Codeunit "Probe Observer";
        UserInfo: DotNet LtY58UserInfo;
        Fresh: DotNet LtY58UserInfo;
        Result: Text;
    begin
        NewMock();
        Fresh := Fresh.UserInfo();
        Observer.Observe('fresh userinfo', Describe(Fresh));
        NewUser(UserInfo, 'obj-1', 'Ann', 'Lee', 'ann@contoso.com');
        UserInfo.PreferredLanguage := 'da-DK';
        Mock.AddUser(UserInfo);
        ObserveTry(Observer, 'mock by object id', TryMockByObjectId('obj-1', Result), Result);
        ObserveTry(Observer, 'graph by object id', TryGraphByObjectId('obj-1', Result), Result);
        ObserveTry(Observer, 'graph by object id other case', TryGraphByObjectId('OBJ-1', Result), Result);
        ObserveTry(Observer, 'graph try by object id', TryGraphTryByObjectId('obj-1', Result), Result);
        ObserveTry(Observer, 'graph by principal', TryGraphByPrincipal('ann@contoso.com', Result), Result);
        ObserveTry(Observer, 'graph by principal other case', TryGraphByPrincipal('ANN@contoso.com', Result), Result);
        ObserveTry(Observer, 'graph by auth email', TryGraphByAuthEmail('ann@contoso.com', Result), Result);
        // the stored object is the same instance: a later change shows on the read
        UserInfo.DisplayName := 'Changed';
        ObserveTry(Observer, 'graph by object id after change', TryGraphByObjectId('obj-1', Result), Result);
        Observer.Expect('fresh userinfo', '|||||||No');
        Observer.Expect('mock by object id', 'obj-1|Ann Lee|Ann|Lee|ann@contoso.com|ann@contoso.com|da-DK|Yes');
        Observer.Expect('graph by object id', 'obj-1|Ann Lee|Ann|Lee|ann@contoso.com|ann@contoso.com|da-DK|Yes');
        Observer.Expect('graph by object id other case', 'obj-1|Ann Lee|Ann|Lee|ann@contoso.com|ann@contoso.com|da-DK|Yes');
        Observer.Expect('graph try by object id', 'Yes/obj-1|Ann Lee|Ann|Lee|ann@contoso.com|ann@contoso.com|da-DK|Yes');
        Observer.Expect('graph by principal', 'obj-1|Ann Lee|Ann|Lee|ann@contoso.com|ann@contoso.com|da-DK|Yes');
        Observer.Expect('graph by principal other case', 'obj-1|Ann Lee|Ann|Lee|ann@contoso.com|ann@contoso.com|da-DK|Yes');
        Observer.Expect('graph by auth email', 'obj-1|Ann Lee|Ann|Lee|ann@contoso.com|ann@contoso.com|da-DK|Yes');
        Observer.Expect('graph by object id after change', 'obj-1|Changed|Ann|Lee|ann@contoso.com|ann@contoso.com|da-DK|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MockGraph_MissingUser()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        NewMock();
        ObserveTry(Observer, 'empty mock by object id', TryMockByObjectId('nobody', Result), Result);
        ObserveTry(Observer, 'empty graph by object id', TryGraphByObjectId('nobody', Result), Result);
        ObserveTry(Observer, 'empty graph try by object id', TryGraphTryByObjectId('nobody', Result), Result);
        ObserveTry(Observer, 'empty graph by principal', TryGraphByPrincipal('nobody@contoso.com', Result), Result);
        ObserveTry(Observer, 'empty graph by auth email', TryGraphByAuthEmail('nobody@contoso.com', Result), Result);
        ObserveTry(Observer, 'empty graph current user', TryGraphCurrent(Result), Result);
        Observer.Expect('empty mock by object id|text', 'A call to Microsoft.Dynamics.Nav.AzureADGraphClient.MockGraphQuery.GetUserByObjectId failed with this message: Sequence contains no matching element');
        Observer.Expect('empty mock by object id|code', 'DotNetInvoke:InvalidOperation');
        Observer.Expect('empty graph by object id|text', 'A call to Microsoft.Dynamics.Nav.AzureADGraphClient.GraphQuery.GetUserByObjectId failed with this message: Sequence contains no matching element');
        Observer.Expect('empty graph by object id|code', 'DotNetInvoke:InvalidOperation');
        Observer.Expect('empty graph try by object id', 'No/null');
        Observer.Expect('empty graph by principal|text', 'A call to Microsoft.Dynamics.Nav.AzureADGraphClient.GraphQuery.GetUser failed with this message: Sequence contains no matching element');
        Observer.Expect('empty graph by principal|code', 'DotNetInvoke:InvalidOperation');
        Observer.Expect('empty graph by auth email', 'null');
        Observer.Expect('empty graph current user', 'null');
        Observer.Verify();
    end;

    [Test]
    procedure MockGraph_DuplicateObjectId()
    var
        Observer: Codeunit "Probe Observer";
        First: DotNet LtY58UserInfo;
        Second: DotNet LtY58UserInfo;
        Result: Text;
    begin
        NewMock();
        NewUser(First, 'dup', 'First', 'User', 'first@contoso.com');
        NewUser(Second, 'dup', 'Second', 'User', 'second@contoso.com');
        Mock.AddUser(First);
        if TryAddUser(Second) then
            Observer.Observe('second add', 'ok')
        else
            Observer.ObserveError('second add');
        ObserveTry(Observer, 'graph by object id', TryGraphByObjectId('dup', Result), Result);
        ObserveTry(Observer, 'graph by first principal', TryGraphByPrincipal('first@contoso.com', Result), Result);
        ObserveTry(Observer, 'graph by second principal', TryGraphByPrincipal('second@contoso.com', Result), Result);
        Observer.Expect('second add', 'ok');
        Observer.Expect('graph by object id', 'dup|First User|First|User|first@contoso.com|first@contoso.com||Yes');
        Observer.Expect('graph by first principal', 'dup|First User|First|User|first@contoso.com|first@contoso.com||Yes');
        Observer.Expect('graph by second principal', 'dup|Second User|Second|User|second@contoso.com|second@contoso.com||Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryAddUser(UserInfo: DotNet LtY58UserInfo)
    begin
        Mock.AddUser(UserInfo);
    end;

    [Test]
    procedure MockGraph_CurrentUser()
    var
        Observer: Codeunit "Probe Observer";
        UserInfo: DotNet LtY58UserInfo;
        Other: DotNet LtY58UserInfo;
        Result: Text;
    begin
        NewMock();
        NewUser(UserInfo, 'me', 'Cur', 'Rent', 'me@contoso.com');
        Mock.CurrentUserUserObject := UserInfo;
        ObserveTry(Observer, 'current user', TryGraphCurrent(Result), Result);
        ObserveTry(Observer, 'current user by object id (not added)', TryGraphByObjectId('me', Result), Result);
        NewUser(Other, 'other', 'Oth', 'Er', 'other@contoso.com');
        Mock.AddUser(Other);
        ObserveTry(Observer, 'current user after AddUser of another', TryGraphCurrent(Result), Result);
        Observer.Expect('current user', 'me|Cur Rent|Cur|Rent|me@contoso.com|me@contoso.com||Yes');
        Observer.Expect('current user by object id (not added)|text', 'A call to Microsoft.Dynamics.Nav.AzureADGraphClient.GraphQuery.GetUserByObjectId failed with this message: Sequence contains no matching element');
        Observer.Expect('current user by object id (not added)|code', 'DotNetInvoke:InvalidOperation');
        Observer.Expect('current user after AddUser of another', 'me|Cur Rent|Cur|Rent|me@contoso.com|me@contoso.com||Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MockGraph_AssignedPlans()
    var
        Observer: Codeunit "Probe Observer";
        UserInfo: DotNet LtY58UserInfo;
        Plan: DotNet LtY58ServicePlanInfo;
        Plan2: DotNet LtY58ServicePlanInfo;
        Item: DotNet LtY58ServicePlanInfo;
        PlanId: Guid;
        N: Integer;
        Line: Text;
    begin
        NewMock();
        NewUser(UserInfo, 'p1', 'Plan', 'User', 'plan@contoso.com');
        Mock.AddUser(UserInfo);
        N := 0;
        foreach Item in UserInfo.AssignedPlans do
            N += 1;
        Observer.Observe('plans before', Format(N));
        Plan := Plan.ServicePlanInfo();
        Evaluate(PlanId, '{11111111-0000-0000-0000-000000000001}');
        Plan.ServicePlanId := PlanId;
        Plan.ServicePlanName := 'Plan One';
        Plan.CapabilityStatus := 'Enabled';
        Mock.AddAssignedPlanToUser(UserInfo, Plan);
        Plan2 := Plan2.ServicePlanInfo();
        Evaluate(PlanId, '{11111111-0000-0000-0000-000000000002}');
        Plan2.ServicePlanId := PlanId;
        Plan2.ServicePlanName := 'Plan Two';
        Plan2.CapabilityStatus := 'Suspended';
        Mock.AddAssignedPlanToUser(UserInfo, Plan2);
        N := 0;
        foreach Item in UserInfo.AssignedPlans do
            N += 1;
        Observer.Observe('plans on userinfo', Format(N));
        foreach Item in Graph.GetUserAssignedPlans(UserInfo) do
            Line += Format(Item.ServicePlanId) + '/' + Format(Item.ServicePlanName) + '/' + Format(Item.CapabilityStatus) + ';';
        Observer.Observe('graph plans', Line);
        Observer.Expect('plans before', '0');
        Observer.Expect('plans on userinfo', '2');
        Observer.Expect('graph plans', '{11111111-0000-0000-0000-000000000001}/Plan One/Enabled;{11111111-0000-0000-0000-000000000002}/Plan Two/Suspended;');
        Observer.Verify();
    end;

    [Test]
    procedure MockGraph_Roles()
    var
        Observer: Codeunit "Probe Observer";
        UserInfo: DotNet LtY58UserInfo;
        Role: DotNet LtY58RoleInfo;
        Item: DotNet LtY58RoleInfo;
        BoolVar: Variant;
        Line: Text;
    begin
        NewMock();
        NewUser(UserInfo, 'r1', 'Role', 'User', 'role@contoso.com');
        Mock.AddUser(UserInfo);
        Role := Role.RoleInfo();
        Role.RoleTemplateId := 'tmpl-1';
        Role.DisplayName := 'Role One';
        Role.Description := 'First role';
        BoolVar := true;
        Role.IsSystem := BoolVar;
        Mock.AddUserRole(UserInfo, Role);
        foreach Item in UserInfo.Roles do
            Line += Format(Item.RoleTemplateId) + '/' + Format(Item.DisplayName) + '/' + Format(Item.Description) + '/' + Format(Item.IsSystem) + ';';
        Observer.Observe('user roles on userinfo', Line);
        Line := '';
        foreach Item in Graph.GetDirectoryRoles() do
            Line += Format(Item.RoleTemplateId) + ';';
        Observer.Observe('directory roles after AddUserRole', Line);
        Mock.AddDirectoryRole(Role);
        Line := '';
        foreach Item in Graph.GetDirectoryRoles() do
            Line += Format(Item.RoleTemplateId) + '/' + Format(Item.DisplayName) + ';';
        Observer.Observe('directory roles after AddDirectoryRole', Line);
        Observer.Expect('user roles on userinfo', 'tmpl-1/Role One/First role/Yes;');
        Observer.Expect('directory roles after AddUserRole', '');
        Observer.Expect('directory roles after AddDirectoryRole', 'tmpl-1/Role One;');
        Observer.Verify();
    end;

    [Test]
    procedure MockGraph_Groups()
    var
        Observer: Codeunit "Probe Observer";
        UserInfo: DotNet LtY58UserInfo;
        Outsider: DotNet LtY58UserInfo;
        Group: DotNet LtY58GroupInfo;
        Group2: DotNet LtY58GroupInfo;
        Member: DotNet LtY58UserInfo;
        Line: Text;
    begin
        NewMock();
        NewUser(UserInfo, 'g1', 'Group', 'User', 'group@contoso.com');
        NewUser(Outsider, 'g2', 'Out', 'Sider', 'out@contoso.com');
        Mock.AddUser(UserInfo);
        Mock.AddUser(Outsider);
        Group := Group.GroupInfo();
        Group.DisplayName := 'Team A';
        Group.ObjectId := 'grp-a';
        Mock.AddGroup(Group);
        Mock.AddUserGroup(UserInfo, Group);
        Observer.Observe('member is in group', Format(Graph.IsGroupMember('g1', 'grp-a')));
        Observer.Observe('outsider is in group', Format(Graph.IsGroupMember('g2', 'grp-a')));
        Observer.Observe('member in unknown group', Format(Graph.IsGroupMember('g1', 'grp-zzz')));
        foreach Group2 in UserInfo.Groups do
            Line += Format(Group2.ObjectId) + '/' + Format(Group2.DisplayName) + ';';
        Observer.Observe('groups on userinfo', Line);
        Line := '';
        foreach Member in Graph.GetGroupMembers('Team A') do
            Line += Format(Member.ObjectId) + ';';
        Observer.Observe('group members by display name', Line);
        Observer.Observe('group info display name', Format(Graph.GetGroupInfo('grp-a').DisplayName));
        Observer.Observe('find first group by display name', Format(Graph.FindFirstGroupInfoForDisplayName('Team A').ObjectId));
        Observer.Expect('member is in group', 'Yes');
        Observer.Expect('outsider is in group', 'No');
        Observer.Expect('member in unknown group', 'No');
        Observer.Expect('groups on userinfo', 'grp-a/Team A;');
        Observer.Expect('group members by display name', 'g1;');
        Observer.Expect('group info display name', 'Team A');
        Observer.Expect('find first group by display name', 'grp-a');
        Observer.Verify();
    end;

    [Test]
    procedure MockGraph_SubscribedSkus()
    var
        Observer: Codeunit "Probe Observer";
        Sku: DotNet LtY58SkuInfo;
        Item: DotNet LtY58SkuInfo;
        PlanInfo: DotNet LtY58ServicePlanInfo;
        PlanItem: DotNet LtY58ServicePlanInfo;
        Line: Text;
    begin
        NewMock();
        foreach Item in Mock.GetDirectorySubscribedSkus() do
            Line += 'sku;';
        Observer.Observe('skus empty mock', Line);
        Line := '';
        PlanInfo := PlanInfo.ServicePlanInfo();
        PlanInfo.ServicePlanName := 'Sku Plan';
        Sku := Sku.SkuInfo();
        Sku.ServicePlans().Add(PlanInfo);
        Mock.AddDirectorySubscribedSku(Sku);
        foreach Item in Graph.GetDirectorySubscribedSkus() do begin
            Line += 'sku:';
            foreach PlanItem in Item.ServicePlans() do
                Line += Format(PlanItem.ServicePlanName) + ',';
            Line += ';';
        end;
        Observer.Observe('skus through graph', Line);
        Line := '';
        foreach Item in Mock.GetDirectorySubscribedSkus() do
            Line += 'sku;';
        Observer.Observe('skus through mock', Line);
        Observer.Expect('skus empty mock', '');
        Observer.Expect('skus through graph', 'sku:Sku Plan,;');
        Observer.Expect('skus through mock', 'sku;');
        Observer.Verify();
    end;

    [Test]
    procedure MockGraph_TenantFlags()
    var
        Observer: Codeunit "Probe Observer";
        Group: DotNet LtY58GroupInfo;
        Tenant: DotNet LtY58TenantInfo;
    begin
        NewMock();
        Observer.Observe('m365 default', Format(Mock.IsM365CollaborationEnabled()));
        Observer.Observe('m365 default through graph', Format(Graph.IsM365CollaborationEnabled()));
        Mock.M365CollaborationEnabled := true;
        Observer.Observe('m365 after set', Format(Graph.IsM365CollaborationEnabled()));
        Observer.Observe('environment group default', Format(Mock.GetEnvironmentDirectoryGroup()));
        Group := Group.GroupInfo();
        Group.DisplayName := 'Env Group';
        Group.ObjectId := 'Env Group Object ID';
        Mock.AddGroup(Group);
        Mock.CurrentEnvironmentSecurityGroup := Group;
        Observer.Observe('environment group after set', Format(Mock.GetEnvironmentDirectoryGroup()));
        Observer.Observe('environment group through graph', Format(Graph.GetEnvironmentDirectoryGroup()));
        Tenant := Graph.GetTenantDetail();
        Observer.Observe('tenant detail is null', Format(IsNull(Tenant)));
        Observer.Expect('m365 default', 'No');
        Observer.Expect('m365 default through graph', 'No');
        Observer.Expect('m365 after set', 'Yes');
        Observer.Expect('environment group default', '');
        Observer.Expect('environment group after set', 'Env Group Object ID');
        Observer.Expect('environment group through graph', 'Env Group Object ID');
        Observer.Expect('tenant detail is null', 'No');
        Observer.Verify();
    end;
}

codeunit 61456 "LT Y58 AAD Graph With Mock"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(UserInfo: DotNet LtY58UserInfo): Text
    begin
        if IsNull(UserInfo) then
            exit('null');
        exit(Format(UserInfo.ObjectId) + '|' + Format(UserInfo.DisplayName) + '|' + Format(UserInfo.Mail));
    end;

    // Held (not a test): without SaaS testability "Azure AD Graph" still read the mock on every Linux CI container (27.5, 28.5,
    // 29.0). The System Application only queries Graph when IsSaaS() or the server setting EnableEntraGroupsOnPrem is on, so the
    // value may depend on the container's server settings. Values below are those of the Linux CI containers; to be checked on the
    // Windows containers before it is a test.
    procedure Suspect_AadGraph_Mock_NotSaaS()
    var
        Observer: Codeunit "Probe Observer";
        AzureADGraph: Codeunit "Azure AD Graph";
        GraphTestLibrary: Codeunit "Azure AD Graph Test Library";
        MockLibrary: Codeunit "MockGraphQuery Test Library";
        UserInfo: DotNet LtY58UserInfo;
    begin
        MockLibrary.SetupMockGraphQuery();
        MockLibrary.AddGraphUser('aad-1', 'Aad', 'User', 'aad@contoso.com');
        GraphTestLibrary.SetMockGraphQuery(MockLibrary);
        BindSubscription(GraphTestLibrary);
        AzureADGraph.GetUserByObjectId('aad-1', UserInfo);
        Observer.Observe('not saas: by object id', Describe(UserInfo));
        Observer.Observe('not saas: try by object id', Format(AzureADGraph.TryGetUserByObjectId('aad-1', UserInfo)));
        UnbindSubscription(GraphTestLibrary);
        Observer.Expect('not saas: by object id', 'aad-1|Aad User|aad@contoso.com');
        Observer.Expect('not saas: try by object id', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AadGraph_Mock_SaaS_ReadsMock()
    var
        Observer: Codeunit "Probe Observer";
        AzureADGraph: Codeunit "Azure AD Graph";
        GraphTestLibrary: Codeunit "Azure AD Graph Test Library";
        MockLibrary: Codeunit "MockGraphQuery Test Library";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        UserInfo: DotNet LtY58UserInfo;
        Missing: DotNet LtY58UserInfo;
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        MockLibrary.SetupMockGraphQuery();
        MockLibrary.AddGraphUser('aad-2', 'Saas', 'User', 'saas@contoso.com');
        MockLibrary.SetCurrentUser('Current', 'current@contoso.com');
        GraphTestLibrary.SetMockGraphQuery(MockLibrary);
        BindSubscription(GraphTestLibrary);
        AzureADGraph.GetUserByObjectId('aad-2', UserInfo);
        Observer.Observe('saas: by object id', Describe(UserInfo));
        AzureADGraph.GetUser('saas@contoso.com', UserInfo);
        Observer.Observe('saas: by principal', Describe(UserInfo));
        Observer.Observe('saas: try missing', Format(AzureADGraph.TryGetUserByObjectId('aad-missing', Missing)));
        Observer.Observe('saas: try missing user', Describe(Missing));
        AzureADGraph.GetCurrentUser(UserInfo);
        Observer.Observe('saas: current user display name', Format(UserInfo.DisplayName));
        Observer.Observe('saas: current user mail', Format(UserInfo.Mail));
        Observer.Observe('saas: current user object id is session user security id', Format(LowerCase(DelChr(Format(UserInfo.ObjectId), '=', '{}')) = LowerCase(DelChr(Format(UserSecurityId()), '=', '{}'))));
        UnbindSubscription(GraphTestLibrary);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        Observer.Expect('saas: by object id', 'aad-2|Saas User|saas@contoso.com');
        Observer.Expect('saas: by principal', 'aad-2|Saas User|saas@contoso.com');
        Observer.Expect('saas: try missing', 'No');
        Observer.Expect('saas: try missing user', 'null');
        Observer.Expect('saas: current user display name', 'Current ');
        Observer.Expect('saas: current user mail', 'current@contoso.com');
        Observer.Expect('saas: current user object id is session user security id', 'Yes');
        Observer.Verify();
    end;
}
