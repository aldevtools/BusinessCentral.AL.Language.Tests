// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-profile-object
// Scope: in-scope
// Fixtures used: ALT AllProfile Row (profile, no numeric ID), ALT Profile SameApp
//                (profile, no numeric ID), ALT Profile RC SameApp (60904)
//
// CLAIM: the "All Profile" system table (2000000178) answers with one row per profile
// declared by every published app, carrying that profile's declared Caption,
// ProfileDescription, RoleCenter page and Enabled/Promoted flags plus the declaring app's
// id and name -- and it is writable for tenant-owned profiles only.
//
// The rows are asserted against THIS app's own profile fixtures, not against Base
// Application demo content, so the expected values are declared a few files away in
// ALTProfileAllProfileRow.Profile.al and cannot drift with a demo dataset.
codeunit 60907 "Test All Profile Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        RowFixtureProfileIdTok: Label 'ALT AllProfile Row', Locked = true;
        LegacyDescriptionProfileIdTok: Label 'ALT Profile SameApp', Locked = true;

    [Test]
    procedure AllProfile_ThisAppsDeclaredProfile_IsPresentWithItsDeclaredMetadata()
    // CLAIM: the profile this app declares is a row of "All Profile", and every column the
    // profile object declares comes back verbatim -- caption, description, the RoleCenter
    // resolved to its page id, Enabled and Promoted -- under the declaring app's id and name.
    var
        AllProfile: Record "All Profile";
        ThisModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);

        AllProfile.Get(AllProfile.Scope::Tenant, ThisModule.Id(), RowFixtureProfileIdTok);

        Assert.AreEqual(
            'ALT AllProfile Row Fixture', AllProfile.Caption,
            'Caption must be the profile''s declared Caption');
        Assert.AreEqual(
            'Row fixture for the All Profile system table.', AllProfile.Description,
            'Description must be the profile''s declared ProfileDescription');
        Assert.AreEqual(
            Page::"ALT Profile RC SameApp", AllProfile."Role Center ID",
            'Role Center ID must be the page id of the profile''s declared RoleCenter');
        Assert.IsTrue(AllProfile.Enabled, 'The profile declares Enabled = true');
        Assert.IsTrue(AllProfile.Promoted, 'The profile declares Promoted = true');
        Assert.AreEqual(ThisModule.Name(), AllProfile."App Name", 'App Name must be the declaring app''s name');
    end;

    [Test]
    procedure AllProfile_ProfileDeclaringLegacyDescription_HasEmptyDescription()
    // CLAIM: Description and ProfileDescription are two different AL properties on a profile
    // object, and only ProfileDescription reaches "All Profile".Description. ALT Profile
    // SameApp declares Description = 'Coverage fixture: ...' and its row's Description is
    // empty, while ALT AllProfile Row's ProfileDescription comes through (test above).
    var
        AllProfile: Record "All Profile";
        ThisModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);

        AllProfile.Get(AllProfile.Scope::Tenant, ThisModule.Id(), LegacyDescriptionProfileIdTok);

        Assert.AreEqual(
            'ALT Profile SameApp', AllProfile.Caption,
            'The row is the right one: its Caption is the profile''s declared Caption');
        Assert.AreEqual(
            '', AllProfile.Description,
            'A profile declaring only Description (not ProfileDescription) has an empty row Description');
    end;

    [Test]
    procedure AllProfile_ScopeSystem_IsEmpty()
    // CLAIM: System-scope profiles are deprecated -- every row of "All Profile" is Tenant
    // scope, including the ones an installed app declares.
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange(Scope, AllProfile.Scope::System);
        Assert.RecordIsEmpty(AllProfile);

        AllProfile.Reset();
        AllProfile.SetRange(Scope, AllProfile.Scope::Tenant);
        Assert.RecordIsNotEmpty(AllProfile);
    end;

    [Test]
    procedure AllProfile_GetOnUndeclaredProfileId_Fails()
    // CLAIM: Get() on a profile no published app declares does not silently succeed.
    var
        AllProfile: Record "All Profile";
        ThisModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);
        Assert.IsFalse(
            AllProfile.Get(AllProfile.Scope::Tenant, ThisModule.Id(), 'ALT NO SUCH PROFILE'),
            'Get() must return false for a profile no app declares');
    end;

    [Test]
    procedure AllProfile_DeleteAppOwnedProfile_RaisesCannotDeleteFromInstalledApplication()
    // CLAIM: a profile owned by an installed app cannot be deleted through "All Profile" --
    // the platform refuses with a specific message naming the profile.
    var
        AllProfile: Record "All Profile";
        ThisModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);
        AllProfile.Get(AllProfile.Scope::Tenant, ThisModule.Id(), RowFixtureProfileIdTok);

        asserterror AllProfile.Delete();

        // The message names the profile by its stored "Profile ID" -- read it off the record
        // rather than restating the literal, so this asserts the platform's message and not
        // this test's idea of how a Code field stores the name.
        Assert.ExpectedError(
            StrSubstNo('Cannot delete ''%1'' profile from an Installed Application.', AllProfile."Profile ID"));
    end;

    [Test]
    procedure AllProfile_RenameAppOwnedProfile_IsRefused()
    // CLAIM: a profile owned by an installed app cannot be renamed through "All Profile" -- a
    // plain Rec.Rename is refused with the platform's message naming the key it was renamed TO,
    // and the row stays under its old key.
    var
        AllProfile: Record "All Profile";
        ThisModule: ModuleInfo;
        NewProfileIdTok: Label 'ALT RENAMED PROFILE', Locked = true;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);
        AllProfile.Get(AllProfile.Scope::Tenant, ThisModule.Id(), RowFixtureProfileIdTok);

        asserterror AllProfile.Rename(AllProfile.Scope::Tenant, ThisModule.Id(), NewProfileIdTok);

        Assert.ExpectedError(
            StrSubstNo('Cannot modify the Scope, Profile ID, or RoleCenter fields on the %1 profile because it is part of an installed app.', NewProfileIdTok));
        Clear(AllProfile);
        Assert.IsTrue(
            AllProfile.Get(AllProfile.Scope::Tenant, ThisModule.Id(), RowFixtureProfileIdTok),
            'A refused Rename must leave the profile under its old key');
        Assert.IsFalse(
            AllProfile.Get(AllProfile.Scope::Tenant, ThisModule.Id(), NewProfileIdTok),
            'A refused Rename must not create the new key');
    end;

    [Test]
    procedure AllProfile_RenameAppOwnedProfileToItsOwnKey_Succeeds()
    // CLAIM: the refusal above is about a KEY CHANGE. A Rename of an app-owned profile onto its
    // own App ID and Profile ID changes neither, so the platform does not refuse it.
    var
        AllProfile: Record "All Profile";
        ThisModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);
        AllProfile.Get(AllProfile.Scope::Tenant, ThisModule.Id(), RowFixtureProfileIdTok);

        AllProfile.Rename(AllProfile.Scope::Tenant, ThisModule.Id(), RowFixtureProfileIdTok);

        Clear(AllProfile);
        Assert.IsTrue(
            AllProfile.Get(AllProfile.Scope::Tenant, ThisModule.Id(), RowFixtureProfileIdTok),
            'A Rename onto the profile''s own key must leave it where it is');
    end;

    [Test]
    procedure AllProfile_RenameTenantProfileOntoAnInstalledAppId_IsRefused()
    // CLAIM: the platform judges the key a profile is renamed TO. A tenant-owned profile renamed
    // onto an installed app's App ID is refused with the same message, naming the Profile ID,
    // and stays tenant-owned under its old key.
    var
        AllProfile: Record "All Profile";
        ThisModule: ModuleInfo;
        EmptyGuid: Guid;
        ProfileIdTok: Label 'ALT TENANT RENAME PROFILE', Locked = true;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);
        if AllProfile.Get(AllProfile.Scope::Tenant, EmptyGuid, ProfileIdTok) then
            AllProfile.Delete();
        Clear(AllProfile);
        AllProfile.Init();
        AllProfile.Scope := AllProfile.Scope::Tenant;
        AllProfile."Profile ID" := ProfileIdTok;
        AllProfile.Description := 'Tenant-owned rename coverage profile.';
        AllProfile."Role Center ID" := Page::"ALT Profile RC SameApp";
        AllProfile.Enabled := false;
        AllProfile.Insert();
        // asserterror rolls back to the last commit point, which would take the Insert too.
        Commit();

        asserterror AllProfile.Rename(AllProfile.Scope::Tenant, ThisModule.Id(), ProfileIdTok);

        Assert.ExpectedError(
            StrSubstNo('Cannot modify the Scope, Profile ID, or RoleCenter fields on the %1 profile because it is part of an installed app.', ProfileIdTok));
        Clear(AllProfile);
        Assert.IsFalse(
            AllProfile.Get(AllProfile.Scope::Tenant, ThisModule.Id(), ProfileIdTok),
            'A refused Rename must not create the profile under the app''s App ID');
        Assert.IsTrue(
            AllProfile.Get(AllProfile.Scope::Tenant, EmptyGuid, ProfileIdTok),
            'A refused Rename must leave the tenant profile under its old key');
        AllProfile.Delete();
    end;

    [Test]
    procedure AllProfile_TenantOwnedProfile_CanBeInsertedReadBackAndDeleted()
    // CLAIM: "All Profile" is writable for a tenant-owned profile (App ID = the empty GUID).
    // The inserted row reads back with the values it was given, and Delete() removes it.
    //
    // The profile is deliberately left DISABLED: an enabled tenant profile is a role-centre
    // candidate, and creating one makes the platform re-resolve the session's default role
    // centre through Azure AD -- which a test container has no directory for. The claim under
    // test is the write round-trip, not role-centre selection.
    var
        AllProfile: Record "All Profile";
        ReadBack: Record "All Profile";
        EmptyGuid: Guid;
        ProfileIdTok: Label 'ALT TENANT PROFILE', Locked = true;
    begin
        if AllProfile.Get(AllProfile.Scope::Tenant, EmptyGuid, ProfileIdTok) then
            AllProfile.Delete();

        Clear(AllProfile);
        AllProfile.Init();
        AllProfile.Scope := AllProfile.Scope::Tenant;
        AllProfile."Profile ID" := ProfileIdTok;
        AllProfile.Description := 'Tenant-owned coverage profile.';
        AllProfile."Role Center ID" := Page::"ALT Profile RC SameApp";
        AllProfile.Enabled := false;
        AllProfile.Insert();

        Assert.IsTrue(
            ReadBack.Get(ReadBack.Scope::Tenant, EmptyGuid, ProfileIdTok),
            'A tenant-owned profile must be readable back after Insert');
        Assert.AreEqual('Tenant-owned coverage profile.', ReadBack.Description, 'Description must round-trip');
        Assert.AreEqual(
            Page::"ALT Profile RC SameApp", ReadBack."Role Center ID", 'Role Center ID must round-trip');
        Assert.AreEqual(EmptyGuid, ReadBack."App ID", 'A tenant-owned profile carries the empty App ID');
        Assert.IsFalse(ReadBack.Enabled, 'Enabled must round-trip');

        ReadBack.Delete();

        Clear(ReadBack);
        Assert.IsFalse(
            ReadBack.Get(ReadBack.Scope::Tenant, EmptyGuid, ProfileIdTok),
            'The tenant-owned profile must be gone after Delete');
    end;

    // ---------------------------------------------------------------------------------------
    // "Default Role Center" on a fresh corpus tenant (writer BX, 2026-10-19; CI runs 39236990456,
    // 39237024989, 39237057632 on BC 27.5, 28.5, 29.0, same values on all three), read directly
    // and through the path Conf./Personalization Mgt. GetDefaultProfileID takes: user plans
    // (none for the test user), then the row marked "Default Role Center" (no row is marked),
    // then DefaultRoleCenterID() (9022, Business Manager Role Center) with FindFirst on
    // "Role Center ID" = 9022, which is BUSINESS MANAGER (Base Application). The test user has
    // a User Personalization row on BUSINESS MANAGER. The experience-tier tests 60700 and
    // 60702 pass on BC through this path.
    // ---------------------------------------------------------------------------------------

    local procedure DescribeProfile(var AllProfile: Record "All Profile"): Text
    begin
        exit(Format(AllProfile.Scope) + '|' + AllProfile."App Name" + '|' + AllProfile."Profile ID" + '|' + Format(AllProfile."Role Center ID") + '|' + Format(AllProfile."Default Role Center") + '|' + AllProfile.Caption);
    end;

    [Test]
    procedure AllProfile_DefaultRoleCenter_FreshTenant_RowsMarkedDefault()
    var
        AllProfile: Record "All Profile";
        ThisModule: ModuleInfo;
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);

        AllProfile.SetRange("Default Role Center", true);
        Observer.Observe('default rows count', Format(AllProfile.Count()));
        if AllProfile.FindSet() then
            repeat
                Rows += DescribeProfile(AllProfile) + ';';
            until AllProfile.Next() = 0;
        Observer.Observe('default rows', Rows);

        AllProfile.Reset();
        AllProfile.Get(AllProfile.Scope::Tenant, ThisModule.Id(), RowFixtureProfileIdTok);
        Observer.Observe('fixture profile', DescribeProfile(AllProfile));

        AllProfile.Reset();
        AllProfile.SetRange("Role Center ID", 9022);
        Observer.Observe('role center 9022 count', Format(AllProfile.Count()));
        Rows := '';
        if AllProfile.FindSet() then
            repeat
                Rows += DescribeProfile(AllProfile) + ';';
            until AllProfile.Next() = 0;
        Observer.Observe('role center 9022 rows', Rows);
        Observer.Expect('default rows count', '0');
        Observer.Expect('default rows', '');
        Observer.Expect('fixture profile', 'Tenant|AL Language Coverage Tests|ALT ALLPROFILE ROW|60904|No|ALT AllProfile Row Fixture');
        Observer.Expect('role center 9022 count', '3');
        Observer.Expect('role center 9022 rows', 'Tenant|Base Application|BUSINESS MANAGER|9022|No|Business Manager;Tenant|Base Application|BUSINESS MANAGER EVALUATION|9022|No|Business Manager Evaluation;Tenant|Base Application|O365 SALES|9022|No|O365 Sales Activities;');
        Observer.Verify();
    end;

    [Test]
    procedure AllProfile_DefaultProfileForCurrentUser_IsTheRowGetDefaultProfileIDPicks()
    var
        AllProfile: Record "All Profile";
        CurrentProfile: Record "All Profile";
        UserPersonalization: Record "User Personalization";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        RoleCenterFromPlans: Query "Role Center from Plans";
        Observer: Codeunit "Probe Observer";
        Plans: Integer;
    begin
        RoleCenterFromPlans.SetRange(User_Security_ID, UserSecurityId());
        if RoleCenterFromPlans.Open() then
            while RoleCenterFromPlans.Read() do
                Plans += 1;
        Observer.Observe('plan role centers of user', Format(Plans));
        Observer.Observe('DefaultRoleCenterID', Format(ConfPersonalizationMgt.DefaultRoleCenterID()));
        if UserPersonalization.Get(UserSecurityId()) then
            Observer.Observe('user personalization', 'row|' + UserPersonalization."Profile ID" + '|' + Format(UserPersonalization.Scope))
        else
            Observer.Observe('user personalization', 'no row');

        Observer.Observe('try result', Format(ConfPersonalizationMgt.TryGetDefaultProfileForCurrentUser(AllProfile)));
        Observer.Observe('default profile', DescribeProfile(AllProfile));
        Observer.Observe('default profile filter Default Role Center', AllProfile.GetFilter("Default Role Center"));
        Observer.Observe('default profile filter Role Center ID', AllProfile.GetFilter("Role Center ID"));

        Observer.Observe('current profile found', Format(ConfPersonalizationMgt.GetCurrentProfileNoError(CurrentProfile)));
        Observer.Observe('current profile', DescribeProfile(CurrentProfile));
        Observer.Expect('plan role centers of user', '0');
        Observer.Expect('DefaultRoleCenterID', '9022');
        Observer.Expect('user personalization', 'row|BUSINESS MANAGER|Tenant');
        Observer.Expect('try result', 'Yes');
        Observer.Expect('default profile', 'Tenant|Base Application|BUSINESS MANAGER|9022|No|Business Manager');
        Observer.Expect('default profile filter Default Role Center', '');
        Observer.Expect('default profile filter Role Center ID', '9022');
        Observer.Expect('current profile found', 'Yes');
        Observer.Expect('current profile', 'Tenant|Base Application|BUSINESS MANAGER|9022|No|Business Manager');
        Observer.Verify();
    end;
}
