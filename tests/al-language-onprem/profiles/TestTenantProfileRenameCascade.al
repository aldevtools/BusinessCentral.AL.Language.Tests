// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method
// Scope: in-scope, but ONLY for a Target = OnPrem app - see the header note below
// Fixtures used: Assert (60021) and ALT Profile RC SameApp (60904), from the AL Language
//                Coverage Tests app
// BC versions: 27.0+
//
// WHY THIS FILE IS IN THE ONPREM APP AND NOT THE CLOUD ONE
//   "Tenant Profile Page Metadata" (2000000187) is Scope = OnPrem in System.app, so a
//   Target = Cloud app cannot name it (AL0296). "User Personalization" (2000000073) and
//   "All Profile" (2000000178) are nameable from either app; they sit here so both halves of
//   one rename are asserted in one test.
//
// CLAIM: renaming a TENANT-owned profile through "All Profile" carries the rows that key off
// it along with it:
//   - "User Personalization"."Profile ID" relates to "All Profile", so the platform's rename
//     propagation updates it from the All Profile rename itself;
//   - "Tenant Profile Page Metadata"."Profile ID" relates to "Tenant Profile" (2000000177),
//     not to "All Profile". It follows because the platform services an All Profile key change
//     by renaming the underlying Tenant Profile row, whose own propagation then runs.
// Both are the shape Microsoft's "ERM User Personalization".RenameProfile (134912) asserts.
//
// Every positive arm has a control: a row of each table pointing at a DIFFERENT tenant
// profile must stay where it is, so a propagation that rewrote every row would fail.
//
// Rows are created under throwaway ids (a fresh user SID, dedicated profile ids) and removed
// again, so no tenant state the rest of the corpus reads is touched.
codeunit 61207 "Test Tenant Profile Rename"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        OldProfileIdTok: Label 'ALT RENAME OLD', Locked = true;
        NewProfileIdTok: Label 'ALT RENAME NEW', Locked = true;
        OtherProfileIdTok: Label 'ALT RENAME OTHER', Locked = true;

    [Test]
    procedure AllProfileRename_TenantProfile_CarriesUserPersonalizationWithIt()
    // CLAIM: a User Personalization row naming the renamed profile names the new id afterwards,
    // and one naming another tenant profile is left alone.
    var
        AllProfile: Record "All Profile";
        UserPersonalization: Record "User Personalization";
        EmptyGuid: Guid;
        RenamedUserSid: Guid;
        SecondRenamedUserSid: Guid;
        ControlUserSid: Guid;
    begin
        Cleanup();
        InsertTenantProfile(OldProfileIdTok);
        InsertTenantProfile(OtherProfileIdTok);
        RenamedUserSid := CreateGuid();
        SecondRenamedUserSid := CreateGuid();
        ControlUserSid := CreateGuid();
        // Two users on the renamed profile: both must follow, not just the first.
        InsertUserPersonalization(RenamedUserSid, OldProfileIdTok);
        InsertUserPersonalization(SecondRenamedUserSid, OldProfileIdTok);
        InsertUserPersonalization(ControlUserSid, OtherProfileIdTok);

        AllProfile.Get(AllProfile.Scope::Tenant, EmptyGuid, OldProfileIdTok);
        AllProfile.Rename(AllProfile.Scope::Tenant, EmptyGuid, NewProfileIdTok);

        UserPersonalization.Get(RenamedUserSid);
        Assert.AreEqual(
            NewProfileIdTok, UserPersonalization."Profile ID",
            'A User Personalization row naming the renamed profile must follow the rename');
        UserPersonalization.Get(SecondRenamedUserSid);
        Assert.AreEqual(
            NewProfileIdTok, UserPersonalization."Profile ID",
            'Every User Personalization row naming the renamed profile must follow the rename');
        UserPersonalization.Reset();
        UserPersonalization.SetRange("Profile ID", OldProfileIdTok);
        Assert.AreEqual(0, UserPersonalization.Count(), 'No User Personalization row may be left on the old profile id');
        UserPersonalization.Reset();
        UserPersonalization.Get(ControlUserSid);
        Assert.AreEqual(
            OtherProfileIdTok, UserPersonalization."Profile ID",
            'A User Personalization row naming another profile must not be touched by the rename');

        Cleanup();
    end;

    [Test]
    procedure AllProfileRename_TenantProfile_CarriesTenantProfilePageMetadataWithIt()
    // CLAIM: the Tenant Profile Page Metadata row of the renamed profile is found under the new
    // id and no longer under the old one; the row of another tenant profile does not move.
    var
        AllProfile: Record "All Profile";
        TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
        EmptyGuid: Guid;
    begin
        Cleanup();
        InsertTenantProfile(OldProfileIdTok);
        InsertTenantProfile(OtherProfileIdTok);
        InsertPageMetadata(OldProfileIdTok);
        InsertPageMetadata(OtherProfileIdTok);

        AllProfile.Get(AllProfile.Scope::Tenant, EmptyGuid, OldProfileIdTok);
        AllProfile.Rename(AllProfile.Scope::Tenant, EmptyGuid, NewProfileIdTok);

        TenantProfilePageMetadata.SetRange("App ID", EmptyGuid);
        TenantProfilePageMetadata.SetRange("Profile ID", NewProfileIdTok);
        Assert.AreEqual(
            1, TenantProfilePageMetadata.Count(),
            'The renamed profile''s page metadata must be found under the new profile id');
        TenantProfilePageMetadata.SetRange("Profile ID", OldProfileIdTok);
        Assert.AreEqual(
            0, TenantProfilePageMetadata.Count(),
            'No page metadata may be left behind under the old profile id');
        TenantProfilePageMetadata.SetRange("Profile ID", OtherProfileIdTok);
        Assert.AreEqual(
            1, TenantProfilePageMetadata.Count(),
            'Page metadata of another profile must not be touched by the rename');

        Cleanup();
    end;

    local procedure InsertTenantProfile(ProfileId: Code[30])
    var
        AllProfile: Record "All Profile";
    begin
        // Left DISABLED, as in "Test All Profile Table": an enabled tenant profile makes the
        // platform re-resolve the session's role centre, which is not what is under test.
        AllProfile.Init();
        AllProfile.Scope := AllProfile.Scope::Tenant;
        AllProfile."Profile ID" := ProfileId;
        AllProfile.Description := 'Rename cascade coverage profile.';
        AllProfile."Role Center ID" := Page::"ALT Profile RC SameApp";
        AllProfile.Enabled := false;
        AllProfile.Insert();
    end;

    local procedure InsertUserPersonalization(UserSid: Guid; ProfileId: Code[30])
    var
        UserPersonalization: Record "User Personalization";
        EmptyGuid: Guid;
    begin
        UserPersonalization.Init();
        UserPersonalization."User SID" := UserSid;
        UserPersonalization.Scope := UserPersonalization.Scope::Tenant;
        UserPersonalization."App ID" := EmptyGuid;
        UserPersonalization."Profile ID" := ProfileId;
        UserPersonalization.Insert();
    end;

    local procedure InsertPageMetadata(ProfileId: Code[30])
    var
        TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
        EmptyGuid: Guid;
    begin
        TenantProfilePageMetadata.Init();
        TenantProfilePageMetadata."App ID" := EmptyGuid;
        TenantProfilePageMetadata."Profile ID" := ProfileId;
        TenantProfilePageMetadata.Owner := TenantProfilePageMetadata.Owner::Tenant;
        TenantProfilePageMetadata."Page ID" := Page::"ALT Profile RC SameApp";
        TenantProfilePageMetadata.Insert();
    end;

    local procedure Cleanup()
    var
        AllProfile: Record "All Profile";
        UserPersonalization: Record "User Personalization";
        TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
        EmptyGuid: Guid;
    begin
        UserPersonalization.SetFilter("Profile ID", '%1|%2|%3', OldProfileIdTok, NewProfileIdTok, OtherProfileIdTok);
        UserPersonalization.DeleteAll();
        TenantProfilePageMetadata.SetRange("App ID", EmptyGuid);
        TenantProfilePageMetadata.SetFilter("Profile ID", '%1|%2|%3', OldProfileIdTok, NewProfileIdTok, OtherProfileIdTok);
        TenantProfilePageMetadata.DeleteAll();
        AllProfile.SetRange(Scope, AllProfile.Scope::Tenant);
        AllProfile.SetRange("App ID", EmptyGuid);
        AllProfile.SetFilter("Profile ID", '%1|%2|%3', OldProfileIdTok, NewProfileIdTok, OtherProfileIdTok);
        // Row by row, as Microsoft's own profile tests clean up "All Profile".
        if AllProfile.FindSet() then
            repeat
                AllProfile.Delete();
            until AllProfile.Next() = 0;
    end;
}
