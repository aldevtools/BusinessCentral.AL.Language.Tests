// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (the Azure AD Graph User methods used here are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61296
// Probe: written against a real BC 29.0 service tier (29.0.54011.55816) on Linux without Entra ID (user and password authentication). Other BC versions were not measured.
//
// What System Application code that needs the Entra user of the session does on such a tier. Behind it, AzureADGraphUserImpl.InitializeGraphUser asks GraphQuery.GetCurrentUser for the session
// user; that call returns nothing and raises nothing (GetUser, in contrast, raises NullReference, see PXAzureAdGraph.al), so the code falls back to the User Property row of the user:
//  - Azure AD Graph User: IsUserDelegatedAdmin, IsUserDelegatedHelpdesk and IsUserDelegated answer No; GetUser(object id, User) answers No; GetUserAuthenticationObjectId(session user) answers an empty text;
//    GetObjectId(session user) raises "A Microsoft Entra user with the object ID  was not found." and GetObjectId(unknown user) raises "The user with the security ID <id> does not have a valid object ID in
//    Microsoft Entra." (both code Dialog);
//  - Azure AD User Management: IsUserTenantAdmin and IsUserDelegated(session user) answer No.
// BC versions: 29.0
codeunit 61296 "PZ Azure AD User"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryDelegatedAdmin(var Result: Boolean)
    var
        GraphUser: Codeunit "Azure AD Graph User";
    begin
        Result := GraphUser.IsUserDelegatedAdmin();
    end;

    [TryFunction]
    local procedure TryDelegatedHelpdesk(var Result: Boolean)
    var
        GraphUser: Codeunit "Azure AD Graph User";
    begin
        Result := GraphUser.IsUserDelegatedHelpdesk();
    end;

    [TryFunction]
    local procedure TryDelegated(var Result: Boolean)
    var
        GraphUser: Codeunit "Azure AD Graph User";
    begin
        Result := GraphUser.IsUserDelegated();
    end;

    [TryFunction]
    local procedure TryObjectId(Sid: Guid; var Result: Text)
    var
        GraphUser: Codeunit "Azure AD Graph User";
    begin
        Result := GraphUser.GetObjectId(Sid);
    end;

    [TryFunction]
    local procedure TryAuthObjectId(Sid: Guid; var Result: Text)
    var
        GraphUser: Codeunit "Azure AD Graph User";
    begin
        Result := GraphUser.GetUserAuthenticationObjectId(Sid);
    end;

    [TryFunction]
    local procedure TryUserByObjectId(ObjectId: Text; var Found: Boolean)
    var
        GraphUser: Codeunit "Azure AD Graph User";
        User: Record User;
    begin
        Found := GraphUser.GetUser(ObjectId, User);
    end;

    [TryFunction]
    local procedure TryTenantAdmin(var Result: Boolean)
    var
        UserMgmt: Codeunit "Azure AD User Management";
    begin
        Result := UserMgmt.IsUserTenantAdmin();
    end;

    [TryFunction]
    local procedure TryUserMgmtDelegated(Sid: Guid; var Result: Boolean)
    var
        UserMgmt: Codeunit "Azure AD User Management";
    begin
        Result := UserMgmt.IsUserDelegated(Sid);
    end;

    local procedure Outcome(Ok: Boolean; Value: Text): Text
    begin
        if Ok then
            exit('ok:' + Value);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Scrub(Text: Text; Sid: Guid): Text
    begin
        exit(Text.Replace(Format(Sid), '<sid>'));
    end;

    [Test]
    procedure AzureAdGraphUser_WithoutDirectory_OnTheTier()
    var
        B: Boolean;
        T: Text;
        Unknown: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        Unknown := CreateGuid();
        Observer.Observe('delegated_admin', Outcome(TryDelegatedAdmin(B), Format(B)));
        ClearLastError();
        Observer.Observe('delegated_helpdesk', Outcome(TryDelegatedHelpdesk(B), Format(B)));
        ClearLastError();
        Observer.Observe('delegated', Outcome(TryDelegated(B), Format(B)));
        ClearLastError();
        Observer.Observe('object_id_of_session_user', Outcome(TryObjectId(UserSecurityId(), T), '[' + T + ']'));
        ClearLastError();
        Observer.Observe('object_id_of_unknown_user', Scrub(Outcome(TryObjectId(Unknown, T), '[' + T + ']'), Unknown));
        ClearLastError();
        Observer.Observe('authentication_object_id_of_session_user', Outcome(TryAuthObjectId(UserSecurityId(), T), '[' + T + ']'));
        ClearLastError();
        Observer.Observe('user_by_object_id', Outcome(TryUserByObjectId('00000000-0000-0000-0000-000000000001', B), Format(B)));
        ClearLastError();
        Observer.Observe('tenant_admin', Outcome(TryTenantAdmin(B), Format(B)));
        ClearLastError();
        Observer.Observe('user_mgmt_delegated_session_user', Outcome(TryUserMgmtDelegated(UserSecurityId(), B), Format(B)));
        Observer.Expect('delegated_admin', 'ok:No');
        Observer.Expect('delegated_helpdesk', 'ok:No');
        Observer.Expect('delegated', 'ok:No');
        Observer.Expect('object_id_of_session_user', 'error:A Microsoft Entra user with the object ID  was not found.|Dialog');
        Observer.Expect('object_id_of_unknown_user', 'error:The user with the security ID <sid> does not have a valid object ID in Microsoft Entra.|Dialog');
        Observer.Expect('authentication_object_id_of_session_user', 'ok:[]');
        Observer.Expect('user_by_object_id', 'ok:No');
        Observer.Expect('tenant_admin', 'ok:No');
        Observer.Expect('user_mgmt_delegated_session_user', 'ok:No');
        Observer.Verify();
    end;
}
