// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: Assert (60021), ALT AllProfile Row (profile, no numeric ID),
//                Base Application page 9170 "Profile Card" over table 2000000178 "All Profile"
//
// CLAIM: a page CONTROL's own `trigger OnValidate()` can refuse a value with Error(), and that
// error reaches the caller of TestPage SetValue.
//
// TestPageOnValidate_Tests already pins the neighbouring halves of SetValue-is-a-validate: the
// TABLE field's OnValidate running, the CONTROL's OnValidate running for its side effects, and
// a TABLE field's OnValidate error propagating. The one combination it does not state is the
// one here — the CONTROL's OnValidate raising. That gap is not academic. A validate whose error
// is dropped is worse than no validate at all: SetValue reports success and the value the AL
// just refused is sitting in the row, so the test fails later, somewhere else, for a reason
// that looks like a data problem.
//
// This is pinned on a page that ships PRECOMPILED rather than on one this app declares, for the
// same reason TestPagePlatformPageSourceTable_Tests drives Base Application page 5: a control
// trigger reaching the caller must not depend on where the page's code came from, and only a
// page the test app does not itself compile can state that.
//
// Page 9170's ProfileIdField declares an OnValidate that refuses a Profile ID another
// published app already uses. The ID it is fed is this app's OWN profile fixture, declared a
// few files away in ALTProfileAllProfileRow.Profile.al, so the expected message cannot drift
// with a demo dataset. Nothing in the "All Profile" TABLE refuses that value — only the
// control does — so an error here can have come from nowhere else.
//
// The gating is in the arms. An implementation that swallowed the control's error fails
// ControlOnValidateError_ReachesTheCaller. One that turned every SetValue into a throw, or that
// ran the control's trigger and then discarded the write, fails
// ControlOnValidate_AcceptsAValueItDoesNotRefuse. One that surfaced *an* error but not the
// control's fails ControlOnValidateError_IsTheControlsOwnMessage, whose expected text is the
// whole message the page declares, not a substring of it.

using System.Environment.Configuration;

codeunit 60820 "TP Control OnValidate Error"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        // Declared by ALTProfileAllProfileRow.Profile.al under THIS app's id, so "a Profile ID
        // some other app already uses" is a fact about this repository, not about demo data.
        ExistingProfileIdTok: Label 'ALT AllProfile Row', Locked = true;
        UnusedProfileIdTok: Label 'ALTCTLOV UNUSED', Locked = true;
        UnusedProfileCaptionTok: Label 'ALTCTLOV UNUSED DISPLAY NAME', Locked = true;

    // Removes anything an earlier run of the accepting arm left behind, so the arms are
    // order-independent and a re-run starts from the same state.
    local procedure Initialize()
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange(Scope, AllProfile.Scope::Tenant);
        AllProfile.SetRange("Profile ID", UnusedProfileIdTok);
        AllProfile.DeleteAll();
        Commit();
    end;

    // THE CLAIM. The control refuses the value, and SetValue's caller finds out.
    [Test]
    procedure ControlOnValidateError_ReachesTheCaller()
    var
        ProfileCard: TestPage "Profile Card";
    begin
        Initialize();

        ProfileCard.OpenNew();
        asserterror ProfileCard.ProfileIdField.SetValue(ExistingProfileIdTok);

        Assert.ExpectedError('already exist, please provide another Profile ID');
    end;

    // The message is the CONTROL's own, whole. An implementation that reported some other
    // failure on the way — or a generic "an error was expected" — cannot pass this.
    [Test]
    procedure ControlOnValidateError_IsTheControlsOwnMessage()
    var
        ProfileCard: TestPage "Profile Card";
    begin
        Initialize();

        ProfileCard.OpenNew();
        asserterror ProfileCard.ProfileIdField.SetValue(ExistingProfileIdTok);

        // The id is interpolated from the row "All Profile" actually stores rather than from
        // the literal above, because "Profile ID" is a Code field and a Code field upper-cases
        // what is written to it — so the message names ALT ALLPROFILE ROW, not the mixed-case
        // spelling the profile object declares.
        Assert.ExpectedError(
            StrSubstNo(
                'A profile with Profile ID "%1" already exist, please provide another Profile ID.',
                StoredFixtureProfileId()));
    end;

    // The Profile ID exactly as "All Profile" holds it, which is what the control interpolates
    // into its message.
    local procedure StoredFixtureProfileId(): Code[30]
    var
        AllProfile: Record "All Profile";
        ThisModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);
        AllProfile.Get(AllProfile.Scope::Tenant, ThisModule.Id(), ExistingProfileIdTok);
        exit(AllProfile."Profile ID");
    end;

    // THE MIRROR. A value the control does NOT refuse must go through and be stored. Without
    // this, "make every SetValue throw" would satisfy the arms above.
    [Test]
    procedure ControlOnValidate_AcceptsAValueItDoesNotRefuse()
    var
        ProfileCard: TestPage "Profile Card";
    begin
        Initialize();

        ProfileCard.OpenNew();
        ProfileCard.ProfileIdField.SetValue(UnusedProfileIdTok);

        Assert.AreEqual(
            UnusedProfileIdTok, ProfileCard.ProfileIdField.Value(),
            'a Profile ID no other app uses must be accepted by the control and stored on the page');

        // Page 9170 is DelayedInsert, so Close() is what inserts the row, and "All Profile"
        // requires a Caption (CaptionField declares NotBlank and ShowMandatory). Leaving it
        // blank made Close() raise "Caption must have a value in All Profile", which is real BC
        // refusing an incomplete record and has nothing to do with the control under test --
        // the claim above is already proven by the assertion before this line. Fill the
        // mandatory sibling field so the page can close on a record BC considers valid.
        ProfileCard.CaptionField.SetValue(UnusedProfileCaptionTok);
        ProfileCard.Close();

        Initialize();
    end;
}
