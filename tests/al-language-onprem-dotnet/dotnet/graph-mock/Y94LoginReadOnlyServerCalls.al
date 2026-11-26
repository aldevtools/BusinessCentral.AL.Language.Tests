// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet; "Server Setting" and "Azure AD Graph" procedures are Scope = OnPrem), AL compiler 18.0 or newer
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61495
// Probe (al-runner issue 7914, corpus bump 317272f1): the read-only server and session calls the runner's login walk reaches, each
//   called directly and through the System Application procedure that reaches it, twice, with the session state
//   (GlobalLanguage, WorkDate, User Personalization row, User Property row count) read before and after:
//   GraphQuery.IsM365CollaborationEnabled() (AzureADGraphImpl.Codeunit.al:104) and "Azure AD Graph".IsM365CollaborationEnabled;
//   ALConfigSettings.Instance().EnableEntraGroupsOnPrem() (ServerSettingImpl.Codeunit.al:44) and "Server Setting".GetEnableEntraGroupsOnPrem;
//   ALConfigSettings.Instance().ApiServicesEnabled() (ServerSettingImpl.Codeunit.al:51) and "Server Setting".GetApiServicesEnabled;
//   NavUserAccountHelper.IsAzure() (EnvironmentInformationImpl.Codeunit.al:140) and "Environment Information".IsSaaSInfrastructure;
//   TaskScheduler.CanCreateTask() (value and second call already pinned by PlTTaskScheduler.al:26; here only the session state).
// Related: Y93GraphNoDirectory.al (GraphQuery without Microsoft Entra ID, same state snapshot), PVEnvironmentTestability.al
//   (default IsSaaSInfrastructure per version), PlTTaskScheduler.al.
// BC versions: 27, 28, 29
dotnet
{
    assembly("Microsoft.Dynamics.Nav.AzureADGraphClient")
    {
        type("Microsoft.Dynamics.Nav.AzureADGraphClient.GraphQuery"; LtY94GraphQuery) { }
    }
    assembly("Microsoft.Dynamics.Nav.Types")
    {
        Culture = 'neutral';
        PublicKeyToken = '31bf3856ad364e35';
        type("Microsoft.Dynamics.Nav.Types.ALConfigSettings"; LtY94ALConfigSettings) { }
    }
    assembly("Microsoft.Dynamics.Nav.NavUserAccount")
    {
        Culture = 'neutral';
        PublicKeyToken = '31bf3856ad364e35';
        type("Microsoft.Dynamics.Nav.NavUserAccount.NavUserAccountHelper"; LtY94NavUserAccountHelper) { }
    }
}

codeunit 61495 "LT Y94 Login ReadOnly Calls"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Outcome(Ok: Boolean; Value: Boolean): Text
    begin
        if Ok then
            exit('ok:' + Format(Value));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
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

    [TryFunction]
    local procedure TryGraphM365(var Result: Boolean)
    var
        Graph: DotNet LtY94GraphQuery;
    begin
        Graph := Graph.GraphQuery();
        Result := Graph.IsM365CollaborationEnabled();
    end;

    [TryFunction]
    local procedure TryFacadeM365(var Result: Boolean)
    var
        AzureADGraph: Codeunit "Azure AD Graph";
    begin
        Result := AzureADGraph.IsM365CollaborationEnabled();
    end;

    [TryFunction]
    local procedure TryConfigEntraGroups(var Result: Boolean)
    var
        Config: DotNet LtY94ALConfigSettings;
    begin
        Config := Config.Instance();
        Result := Config.EnableEntraGroupsOnPrem();
    end;

    [TryFunction]
    local procedure TryFacadeEntraGroups(var Result: Boolean)
    var
        ServerSetting: Codeunit "Server Setting";
    begin
        Result := ServerSetting.GetEnableEntraGroupsOnPrem();
    end;

    [TryFunction]
    local procedure TryConfigApiServices(var Result: Boolean)
    var
        Config: DotNet LtY94ALConfigSettings;
    begin
        Config := Config.Instance();
        Result := Config.ApiServicesEnabled();
    end;

    [TryFunction]
    local procedure TryFacadeApiServices(var Result: Boolean)
    var
        ServerSetting: Codeunit "Server Setting";
    begin
        Result := ServerSetting.GetApiServicesEnabled();
    end;

    [TryFunction]
    local procedure TryIsAzure(var Result: Boolean)
    var
        Helper: DotNet LtY94NavUserAccountHelper;
    begin
        Result := Helper.IsAzure();
    end;

    [TryFunction]
    local procedure TryFacadeSaaSInfrastructure(var Result: Boolean)
    var
        EnvInfo: Codeunit "Environment Information";
    begin
        Result := EnvInfo.IsSaaSInfrastructure();
    end;

    [Test]
    procedure M365Collaboration_DirectAndFacade()
    var
        Observer: Codeunit "Probe Observer";
        Before: Text;
        B: Boolean;
    begin
        Before := Snapshot();
        Observer.Observe('state_before', Before.Replace(Format(WorkDate(), 0, 9), '<workdate>'));
        ClearLastError();
        Observer.Observe('direct', Outcome(TryGraphM365(B), B));
        ClearLastError();
        Observer.Observe('direct_again', Outcome(TryGraphM365(B), B));
        Observer.Observe('state_after_direct_unchanged', Format(Snapshot() = Before));
        ClearLastError();
        Observer.Observe('facade', Outcome(TryFacadeM365(B), B));
        ClearLastError();
        Observer.Observe('facade_again', Outcome(TryFacadeM365(B), B));
        Observer.Observe('last_error_after_facade', '[' + GetLastErrorText() + ']');
        Observer.Observe('state_after_facade_unchanged', Format(Snapshot() = Before));
        Observer.Finish();
    end;

    [Test]
    procedure EntraGroupsOnPrem_DirectAndFacade()
    var
        Observer: Codeunit "Probe Observer";
        Before: Text;
        B: Boolean;
    begin
        Before := Snapshot();
        ClearLastError();
        Observer.Observe('direct', Outcome(TryConfigEntraGroups(B), B));
        ClearLastError();
        Observer.Observe('direct_again', Outcome(TryConfigEntraGroups(B), B));
        Observer.Observe('state_after_direct_unchanged', Format(Snapshot() = Before));
        ClearLastError();
        Observer.Observe('facade', Outcome(TryFacadeEntraGroups(B), B));
        ClearLastError();
        Observer.Observe('facade_again', Outcome(TryFacadeEntraGroups(B), B));
        Observer.Observe('state_after_facade_unchanged', Format(Snapshot() = Before));
        Observer.Finish();
    end;

    [Test]
    procedure ApiServicesEnabled_DirectAndFacade()
    var
        Observer: Codeunit "Probe Observer";
        Before: Text;
        B: Boolean;
    begin
        Before := Snapshot();
        ClearLastError();
        Observer.Observe('direct', Outcome(TryConfigApiServices(B), B));
        ClearLastError();
        Observer.Observe('direct_again', Outcome(TryConfigApiServices(B), B));
        Observer.Observe('state_after_direct_unchanged', Format(Snapshot() = Before));
        ClearLastError();
        Observer.Observe('facade', Outcome(TryFacadeApiServices(B), B));
        ClearLastError();
        Observer.Observe('facade_again', Outcome(TryFacadeApiServices(B), B));
        Observer.Observe('state_after_facade_unchanged', Format(Snapshot() = Before));
        Observer.Finish();
    end;

    [Test]
    procedure IsAzure_DirectAndSaaSInfrastructure()
    var
        EnvInfo: Codeunit "Environment Information";
        Observer: Codeunit "Probe Observer";
        Before: Text;
        B: Boolean;
    begin
        Before := Snapshot();
        Observer.Observe('is_saas', Format(EnvInfo.IsSaaS()));
        ClearLastError();
        Observer.Observe('direct', Outcome(TryIsAzure(B), B));
        ClearLastError();
        Observer.Observe('direct_again', Outcome(TryIsAzure(B), B));
        Observer.Observe('state_after_direct_unchanged', Format(Snapshot() = Before));
        ClearLastError();
        Observer.Observe('facade', Outcome(TryFacadeSaaSInfrastructure(B), B));
        ClearLastError();
        Observer.Observe('facade_again', Outcome(TryFacadeSaaSInfrastructure(B), B));
        Observer.Observe('state_after_facade_unchanged', Format(Snapshot() = Before));
        Observer.Finish();
    end;

    [Test]
    procedure CanCreateTask_SessionState()
    var
        Observer: Codeunit "Probe Observer";
        Before: Text;
    begin
        Before := Snapshot();
        Observer.Observe('value', Format(TaskScheduler.CanCreateTask()));
        Observer.Observe('again', Format(TaskScheduler.CanCreateTask()));
        Observer.Observe('state_after_unchanged', Format(Snapshot() = Before));
        Observer.Finish();
    end;
}
