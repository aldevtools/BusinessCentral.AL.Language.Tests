// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-security-filters-and-tabledata
// Scope: in-scope (OnPrem app: the User and Access Control platform tables are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61295
// Probe: written against a real BC 29.0 service tier (29.0.54011.55816). Other BC versions were not measured.
//
// Deleting a User row removes its Access Control rows (with and without RunTrigger). With IsSaaS true (the answer on this tier; the test library cannot turn it off, see PVEnvironmentTestability.al)
// and the session user as the only SUPER user, User.DeleteAll(true) raises "There should be at least one enabled 'SUPER' user." (code Dialog); the test removes the other SUPER rows first and
// the asserterror rolls every write of the test back. The IsSaaS false side of that check cannot be reached on this tier.
// BC versions: 29.0
codeunit 61295 "PZ User Delete"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure NewUser(var User: Record User)
    var
        Acl: Record "Access Control";
    begin
        User.Init();
        User."User Security ID" := CreateGuid();
        User."User Name" := 'PZ-PROBE-' + Format(Random(1000000));
        User."License Type" := User."License Type"::"Full User";
        User.State := User.State::Enabled;
        User.Insert();
        Acl.Init();
        Acl."User Security ID" := User."User Security ID";
        Acl."Role ID" := 'D365 BASIC';
        Acl."Company Name" := '';
        Acl.Scope := Acl.Scope::System;
        Acl.Insert();
    end;

    local procedure AclCount(UserSid: Guid): Integer
    var
        Acl: Record "Access Control";
    begin
        Acl.SetRange("User Security ID", UserSid);
        exit(Acl.Count());
    end;

    [Test]
    procedure DeleteUser_WithRunTrigger_RemovesItsAccessControlRows()
    var
        User: Record User;
        Sid: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        NewUser(User);
        Sid := User."User Security ID";
        Observer.Observe('rows_before', Format(AclCount(Sid)));
        User.Delete(true);
        Observer.Observe('user_exists_after', Format(User.Get(Sid)));
        Observer.Observe('rows_after', Format(AclCount(Sid)));
        Observer.Expect('rows_before', '1');
        Observer.Expect('user_exists_after', 'No');
        Observer.Expect('rows_after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteUser_WithoutRunTrigger_AccessControlRows()
    var
        User: Record User;
        Sid: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        NewUser(User);
        Sid := User."User Security ID";
        User.Delete(false);
        Observer.Observe('user_exists_after', Format(User.Get(Sid)));
        Observer.Observe('rows_after', Format(AclCount(Sid)));
        Observer.Expect('user_exists_after', 'No');
        Observer.Expect('rows_after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAllUsers_AsTheOnlySuperUser_IsRefused()
    var
        User: Record User;
        Acl: Record "Access Control";
        Others: Record "Access Control";
        Observer: Codeunit "Probe Observer";
    begin
        Others.SetRange("Role ID", 'SUPER');
        Others.SetRange("Company Name", '');
        Others.SetFilter("User Security ID", '<>%1', UserSecurityId());
        Others.DeleteAll(true);
        Acl.SetRange("Role ID", 'SUPER');
        Acl.SetRange("Company Name", '');
        Observer.Observe('super_rows_left', Format(Acl.Count()));
        Observer.Observe('current_user_is_super', Format(AclCount(UserSecurityId()) > 0));
        asserterror User.DeleteAll(true);
        Observer.ObserveError('delete_all');
        Observer.Expect('super_rows_left', '1');
        Observer.Expect('current_user_is_super', 'Yes');
        Observer.Expect('delete_all|text', 'There should be at least one enabled ''SUPER'' user.');
        Observer.Expect('delete_all|code', 'Dialog');
        Observer.Verify();
    end;
}
