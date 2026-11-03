// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99101
// Probe: al-runtime-rs corpus topic 203 item 3 (corpus issue 632): Microsoft.Dynamics.Nav.NavUserAccount.NavUserAccountHelper IsDelegatedUser, IsUserDelegatedAdmin, IsUserDelegatedHelpdesk, called from a test session.
// BC versions: 27, 28, 29
dotnet
{
    assembly("Microsoft.Dynamics.Nav.NavUserAccount")
    {
        type("Microsoft.Dynamics.Nav.NavUserAccount.NavUserAccountHelper"; LtAlNavUserAccountHelper) { }
    }
}

codeunit 99101 "LT AL UserAccountHelper"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: DotNet LtAlNavUserAccountHelper;

    [TryFunction]
    local procedure TryDelegatedUser(var Result: Boolean)
    begin
        Result := Helper.IsDelegatedUser();
    end;

    [TryFunction]
    local procedure TryDelegatedAdmin(var Result: Boolean)
    begin
        Result := Helper.IsUserDelegatedAdmin();
    end;

    [TryFunction]
    local procedure TryDelegatedHelpdesk(var Result: Boolean)
    begin
        Result := Helper.IsUserDelegatedHelpdesk();
    end;

    [Test]
    procedure ALUserAccountHelper_Delegated()
    var
        Observer: Codeunit "Probe Observer";
        R: Boolean;
    begin
        ClearLastError();
        if TryDelegatedUser(R) then
            Observer.Observe('IsDelegatedUser', Format(R))
        else
            Observer.ObserveError('IsDelegatedUser');
        ClearLastError();
        if TryDelegatedAdmin(R) then
            Observer.Observe('IsUserDelegatedAdmin', Format(R))
        else
            Observer.ObserveError('IsUserDelegatedAdmin');
        ClearLastError();
        if TryDelegatedHelpdesk(R) then
            Observer.Observe('IsUserDelegatedHelpdesk', Format(R))
        else
            Observer.ObserveError('IsUserDelegatedHelpdesk');
        Observer.Expect('IsDelegatedUser', 'No');
        Observer.Expect('IsUserDelegatedAdmin', 'No');
        Observer.Expect('IsUserDelegatedHelpdesk', 'No');
        Observer.Verify();
    end;
}
