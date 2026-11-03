// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/user/user-table
// Scope: in-scope (Target = OnPrem: Environment Info Test Library.SetTestabilitySoftwareAsAService has Scope OnPrem)
// Fixtures used: Probe Observer (69160), Environment Info Test Library (System Application Test Library)
// RISKY (data): the test takes the SUPER assignments of other users away and puts them back; the attempts on the test user are expected to fail before anything changes. The environment is switched to "SaaS" only for the attempts.
//
// 'There should be at least one enabled 'SUPER' user.': raised when the last user that holds SUPER directly is disabled, or loses the SUPER assignment, while the environment is SaaS.
// BC versions: 27, 28, 29
codeunit 61289 "LT P Super User Last"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SuperFilters(var AccessControl: Record "Access Control")
    begin
        AccessControl.SetRange("Role ID", 'SUPER');
        AccessControl.SetRange(Scope, AccessControl.Scope::System);
        AccessControl.SetFilter("Company Name", '''''');
    end;

    // Takes the SUPER assignments of every other user away (SaaS checks off) and keeps them to put back.
    local procedure KeepOnlyCurrentUserSuper(var Saved: Record "Access Control" temporary)
    var
        AccessControl: Record "Access Control";
    begin
        SuperFilters(AccessControl);
        AccessControl.SetFilter("User Security ID", '<>%1', UserSecurityId());
        if AccessControl.FindSet() then
            repeat
                Saved := AccessControl;
                Saved.Insert();
            until AccessControl.Next() = 0;
        AccessControl.DeleteAll(false);
    end;

    local procedure PutBack(var Saved: Record "Access Control" temporary)
    var
        AccessControl: Record "Access Control";
    begin
        if Saved.FindSet() then
            repeat
                AccessControl := Saved;
                if AccessControl.Insert(false) then;
            until Saved.Next() = 0;
        Saved.DeleteAll();
    end;

    [Test]
    procedure PSuperUser_DisableLastSuper()
    var
        Observer: Codeunit "Probe Observer";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        User: Record User;
        AccessControl: Record "Access Control";
        Saved: Record "Access Control" temporary;
    begin
        SuperFilters(AccessControl);
        AccessControl.SetRange("User Security ID", UserSecurityId());
        Observer.Observe('current_user_has_super', Format(not AccessControl.IsEmpty()));
        Observer.Observe('user_found', Format(User.Get(UserSecurityId())));
        KeepOnlyCurrentUserSuper(Saved);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        ClearLastError();
        User.State := User.State::Disabled;
        asserterror User.Modify(true);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        Observer.ObserveError('disable_error');
        PutBack(Saved);
        User.Get(UserSecurityId());
        Observer.Observe('state_after', Format(User.State));
        Observer.Expect('current_user_has_super', 'Yes');
        Observer.Expect('user_found', 'Yes');
        Observer.Expect('disable_error|text', 'There should be at least one enabled ''SUPER'' user.');
        Observer.Expect('disable_error|code', 'Dialog');
        Observer.Expect('state_after', 'Enabled');
        Observer.Verify();
    end;

    [Test]
    procedure PSuperUser_RemoveLastSuperAssignment()
    var
        Observer: Codeunit "Probe Observer";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        AccessControl: Record "Access Control";
        Saved: Record "Access Control" temporary;
    begin
        KeepOnlyCurrentUserSuper(Saved);
        SuperFilters(AccessControl);
        AccessControl.SetRange("User Security ID", UserSecurityId());
        Observer.Observe('assignment_found', Format(AccessControl.FindFirst()));
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        ClearLastError();
        asserterror AccessControl.Delete(true);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        Observer.ObserveError('remove_error');
        PutBack(Saved);
        Observer.Expect('assignment_found', 'Yes');
        Observer.Expect('remove_error|text', 'There should be at least one enabled ''SUPER'' user.');
        Observer.Expect('remove_error|code', 'Dialog');
        Observer.Verify();
    end;
}
