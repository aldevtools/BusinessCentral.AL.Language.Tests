// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/ui-customize-profiles
// Scope: in-scope
// Fixtures used: ALT Profile Copy Source (profile, no numeric ID), ALT Profile RC SameApp (60904)
//
// CLAIM: "Conf./Personalization Mgt".CopyProfile copies a profile into a new TENANT-OWNED
// "All Profile" row (App ID = the empty GUID) under the new Profile ID and Caption, carrying
// the source's Role Center and Enabled flag -- and it refuses, with Base Application's own
// "could not be copied" error, when the target Profile ID already exists.
//
// Base Application does the copy through the platform's designer call
// NavDesignerALFunctions.CopyProfile, so this is the platform's copy being measured, not AL.
codeunit 60908 "Test Copy Profile"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        SourceProfileIdTok: Label 'ALT Profile Copy Source', Locked = true;
        CopiedProfileIdTok: Label 'ALT COPIED PROFILE', Locked = true;
        CopiedCaptionTok: Label 'ALT Copied Profile Caption', Locked = true;
        CouldNotCopyErr: Label 'The profile could not be copied.', Locked = true;

    [Test]
    procedure CopyProfile_NewId_CreatesTenantOwnedProfileWithNewCaptionAndSourceRoleCenter()
    // CLAIM: the copy is a new row readable under (Tenant, empty App ID, new Profile ID); the
    // VAR record CopyProfile hands back is that row; and it carries the new caption plus the
    // source's Role Center ID and Enabled flag. One row is added, not zero and not two.
    var
        Source: Record "All Profile";
        Copied: Record "All Profile";
        ReadBack: Record "All Profile";
        Counter: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        ThisModule: ModuleInfo;
        EmptyGuid: Guid;
        CountBefore: Integer;
    begin
        DeleteCopyIfPresent();
        NavApp.GetCurrentModuleInfo(ThisModule);
        Source.Get(Source.Scope::Tenant, ThisModule.Id(), SourceProfileIdTok);
        CountBefore := Counter.Count();

        ConfPersonalizationMgt.CopyProfile(Source, CopiedProfileIdTok, CopiedCaptionTok, Copied);

        Assert.AreEqual(CountBefore + 1, Counter.Count(), 'CopyProfile must add exactly one All Profile row');
        Assert.IsTrue(
            ReadBack.Get(ReadBack.Scope::Tenant, EmptyGuid, CopiedProfileIdTok),
            'The copy must be readable as a tenant-owned profile under the new Profile ID');
        Assert.AreEqual(CopiedProfileIdTok, Copied."Profile ID", 'The VAR record must be the copied row');
        Assert.AreEqual(EmptyGuid, ReadBack."App ID", 'A copied profile is tenant-owned: its App ID is the empty GUID');
        Assert.AreEqual(CopiedCaptionTok, ReadBack.Caption, 'The copy must carry the caption passed to CopyProfile');
        Assert.AreEqual(
            Page::"ALT Profile RC SameApp", ReadBack."Role Center ID",
            'The copy must carry the source profile''s Role Center ID');
        Assert.AreEqual(Source.Enabled, ReadBack.Enabled, 'The copy must carry the source profile''s Enabled flag');

        ReadBack.Delete();
    end;

    [Test]
    procedure CopyProfile_TargetIdAlreadyExists_RaisesCouldNotCopy()
    // CLAIM: copying onto a Profile ID that already names a tenant profile is refused with
    // Base Application's own error.
    //
    // It deliberately does NOT claim "does not overwrite". That is unobservable from here: the
    // refused copy's rollback removes the first copy's row too, so there is nothing left to
    // re-read afterwards and compare. Asserting it would mean committing the first copy, which
    // leaks a real profile into shared tier state for every later codeunit when a mid-test
    // failure skips the cleanup.
    //
    // WHAT THIS ARM DELIBERATELY NO LONGER ASSERTS, and why. It used to take a row count after
    // the first copy and re-read it after the refused second one, expecting no change. On a
    // real service tier that measured 49 then 48 -- the count went DOWN. The refused
    // CopyProfile fails inside `asserterror`, and the rollback that unwinds it takes the
    // enclosing write transaction with it, so the FIRST copy's row disappears too. Measured on
    // all eight cloud legs and, independently, on the Windows nightly (56 -> 55 there: a
    // different starting population, the same -1).
    //
    // A count spanning an `asserterror` therefore measures the rollback, not the refusal, and
    // "a refused copy must not add a row" cannot be asserted that way. The mechanism is pinned
    // independently in this corpus by error-handling/TestAssertErrorRollback.al (codeunit
    // 60943), which shows an uncommitted insert rolled back by an UNRELATED `asserterror`.
    //
    // What survives is the refusal itself, asserted below.
    var
        Source: Record "All Profile";
        Copied: Record "All Profile";
        ReadBack: Record "All Profile";
        SecondCopy: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        ThisModule: ModuleInfo;
        EmptyGuid: Guid;
    begin
        DeleteCopyIfPresent();
        NavApp.GetCurrentModuleInfo(ThisModule);
        Source.Get(Source.Scope::Tenant, ThisModule.Id(), SourceProfileIdTok);
        ConfPersonalizationMgt.CopyProfile(Source, CopiedProfileIdTok, CopiedCaptionTok, Copied);

        // Read the copy back through a SEPARATE record, and check the Get succeeded. Re-reading
        // into `Copied` would prove nothing: CopyProfile already populated it as a VAR
        // out-param, so the row would be there whether or not the database holds it. Same shape
        // as the sibling arm's ReadBack.
        Assert.IsTrue(
          ReadBack.Get(ReadBack.Scope::Tenant, EmptyGuid, CopiedProfileIdTok),
          'The first copy must be readable from the database before the refusal');
        Assert.AreEqual(CopiedCaptionTok, ReadBack.Caption, 'The first copy must carry the caption it was given');

        // The refusal itself: BC raises its own error rather than overwriting.
        asserterror ConfPersonalizationMgt.CopyProfile(Source, CopiedProfileIdTok, 'Second caption', SecondCopy);
        Assert.ExpectedError(CouldNotCopyErr);
    end;

    local procedure DeleteCopyIfPresent()
    var
        AllProfile: Record "All Profile";
        EmptyGuid: Guid;
    begin
        if AllProfile.Get(AllProfile.Scope::Tenant, EmptyGuid, CopiedProfileIdTok) then
            AllProfile.Delete();
    end;
}
