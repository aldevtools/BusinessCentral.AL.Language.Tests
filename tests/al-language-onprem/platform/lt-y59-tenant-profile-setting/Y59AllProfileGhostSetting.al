// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope (OnPrem app: Tenant Profile Setting has Scope = OnPrem)
// Fixtures used: Probe Observer (69160) and profile "ALT Profile SameApp" (main app a1b2c3d4-e5f6-7890-abcd-ef1234567890), from the AL
//   Language Coverage Tests app
// Probe (gap cycle 6, G6-04c): does a Tenant Profile Setting (2000000083) row whose Profile ID names no profile make a row in All Profile? Settings for a profile id that does not exist, with a random App ID and with the App ID of
//   an app that has profiles, with Default Role Center true and false; All Profile read by Profile ID and by the filter the System
//   Application uses for the default profile (Default Role Center = true, Enabled = true, FindFirst); and after the setting is deleted.
//   Neighbour (the setting of an existing profile): lt-y35-stored-tables/Y35StoredTables.al C303_TenantProfileSetting_AllProfileLink.
// Measured on the CI containers 27.5, 28.5, 29.0 (same values): a Tenant Profile Setting for a profile id that does not exist inserts
//   fine but adds no row to All Profile (with a random App ID or the App ID of an app that has profiles, Default Role Center true or
//   false); with every setting deleted, no profile has Default Role Center = true and Enabled = true.
// BC versions: 27.5, 28.5, 29.0.

codeunit 98693 "LT Y59 All Profile Ghost"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        MainAppTok: Label 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', Locked = true;
        GhostAppTok: Label '59a59a59-5959-4959-8959-595959595959', Locked = true;

    local procedure InsertSetting(AppId: Guid; ProfileId: Code[30]; DefaultRoleCenter: Boolean): Text
    var
        Setting: Record "Tenant Profile Setting";
    begin
        Setting.Init();
        Setting."App ID" := AppId;
        Setting."Profile ID" := ProfileId;
        Setting."Default Role Center" := DefaultRoleCenter;
        exit(Format(Setting.Insert()));
    end;

    local procedure AppText(AppId: Guid): Text
    begin
        if AppId = MainAppTok then
            exit('main');
        if AppId = GhostAppTok then
            exit('ghost');
        if IsNullGuid(AppId) then
            exit('null');
        exit('other');
    end;

    local procedure ProfileRows(ProfileId: Code[30]): Text
    var
        AllProfile: Record "All Profile";
        Result: Text;
    begin
        AllProfile.SetRange("Profile ID", ProfileId);
        if AllProfile.FindSet() then
            repeat
                Result += '[' + Format(AllProfile.Scope) + ';' + AppText(AllProfile."App ID") + ';' + AllProfile."Profile ID" + ';Enabled=' + Format(AllProfile.Enabled) +
                    ';Default=' + Format(AllProfile."Default Role Center") + ';Caption=' + AllProfile.Caption + ';RoleCenter=' + Format(AllProfile."Role Center ID") + ']';
            until AllProfile.Next() = 0;
        exit(Format(AllProfile.Count()) + '|' + Result);
    end;

    local procedure DefaultProfile(): Text
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange("Default Role Center", true);
        AllProfile.SetRange(Enabled, true);
        if not AllProfile.FindFirst() then
            exit('none');
        exit(Format(AllProfile.Scope) + ';' + AppText(AllProfile."App ID") + ';' + AllProfile."Profile ID");
    end;

    [Test]
    procedure Y59_AllProfile_SettingWithoutProfile()
    var
        Setting: Record "Tenant Profile Setting";
        Observer: Codeunit "Probe Observer";
    begin
        Setting.DeleteAll();
        Observer.Observe('default_before', DefaultProfile());
        Observer.Observe('insert_ghost', InsertSetting(GhostAppTok, 'LT Y59 GHOST', true));
        Observer.Observe('ghost_rows', ProfileRows('LT Y59 GHOST'));
        Observer.Observe('default_after', DefaultProfile());
        Setting.DeleteAll();
        Observer.Expect('default_before', 'none');
        Observer.Expect('insert_ghost', 'Yes');
        Observer.Expect('ghost_rows', '0|');
        Observer.Expect('default_after', 'none');
        Observer.Verify();
    end;

    [Test]
    procedure Y59_AllProfile_SettingWithoutProfile_AppWithProfiles()
    var
        Setting: Record "Tenant Profile Setting";
        Observer: Codeunit "Probe Observer";
    begin
        Setting.DeleteAll();
        Observer.Observe('insert_ghost_main_app', InsertSetting(MainAppTok, 'LT Y59 GHOST MAIN', true));
        Observer.Observe('ghost_main_rows', ProfileRows('LT Y59 GHOST MAIN'));
        Observer.Observe('default_after', DefaultProfile());
        Setting.DeleteAll();
        Observer.Expect('insert_ghost_main_app', 'Yes');
        Observer.Expect('ghost_main_rows', '0|');
        Observer.Expect('default_after', 'none');
        Observer.Verify();
    end;

    [Test]
    procedure Y59_AllProfile_SettingWithoutProfile_NotDefault()
    var
        Setting: Record "Tenant Profile Setting";
        Observer: Codeunit "Probe Observer";
    begin
        Setting.DeleteAll();
        Observer.Observe('insert_ghost_not_default', InsertSetting(GhostAppTok, 'LT Y59 GHOST ND', false));
        Observer.Observe('ghost_not_default_rows', ProfileRows('LT Y59 GHOST ND'));
        Observer.Observe('default_after', DefaultProfile());
        Setting.DeleteAll();
        Observer.Expect('insert_ghost_not_default', 'Yes');
        Observer.Expect('ghost_not_default_rows', '0|');
        Observer.Expect('default_after', 'none');
        Observer.Verify();
    end;

    [Test]
    procedure Y59_AllProfile_SettingGhost_AfterDelete()
    var
        Setting: Record "Tenant Profile Setting";
        Observer: Codeunit "Probe Observer";
    begin
        Setting.DeleteAll();
        InsertSetting(GhostAppTok, 'LT Y59 GHOST DEL', true);
        Observer.Observe('rows_with_setting', ProfileRows('LT Y59 GHOST DEL'));
        Setting.Get(GhostAppTok, 'LT Y59 GHOST DEL');
        Observer.Observe('delete', Format(Setting.Delete()));
        Observer.Observe('rows_after_delete', ProfileRows('LT Y59 GHOST DEL'));
        Observer.Observe('default_after_delete', DefaultProfile());
        Observer.Expect('rows_with_setting', '0|');
        Observer.Expect('delete', 'Yes');
        Observer.Expect('rows_after_delete', '0|');
        Observer.Expect('default_after_delete', 'none');
        Observer.Verify();
    end;
}
