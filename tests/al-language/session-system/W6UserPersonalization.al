// Batch 6, md:588 [User Personalization row of the session user], open part: whether SessionSettings.RequestSessionUpdate(true) creates (or touches) the row.
// The row of the session user already exists in the test session (session/TestUserPersonalizationRowContracts.al, PWPlatformTables.al), so "creates" is observed as
// what the row and its stamps look like before and after the call, and as the session settings compared with the row. A Get of a row that does not exist is observed too.
// RequestSessionUpdate can restart the client session: the two calls stand in a test codeunit of their own, last in the codeunit, and change no setting.
// Observe-only.

codeunit 67344 "W6 User Personalization"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Get_ForAUserWithNoRow()
    var
        UserPers: Record "User Personalization";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('get_unknown_user_sid', Format(UserPers.Get(CreateGuid())));
        UserPers.Reset();
        UserPers.SetRange("User SID", CreateGuid());
        Observer.Observe('count_unknown_user_sid', Format(UserPers.Count()));
        Observer.Expect('get_unknown_user_sid', 'No');
        Observer.Expect('count_unknown_user_sid', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SessionSettings_Init_ComparedWithTheRow()
    var
        UserPers: Record "User Personalization";
        Settings: SessionSettings;
        Observer: Codeunit "Probe Observer";
    begin
        UserPers.Get(UserSecurityId());
        Settings.Init();
        Observer.Observe('profile_id_equals_row', Format(Settings.ProfileId = UserPers."Profile ID"));
        Observer.Observe('language_id_equals_row', Format(Settings.LanguageId = UserPers."Language ID"));
        Observer.Observe('locale_id_equals_row', Format(Settings.LocaleId = UserPers."Locale ID"));
        Observer.Observe('company_equals_row', Format(Settings.Company = UserPers.Company));
        Observer.Observe('time_zone_equals_row', Format(Settings.TimeZone = UserPers."Time Zone"));
        Observer.Observe('row_company_blank', Format(UserPers.Company = ''));
        Observer.Observe('row_time_zone_blank', Format(UserPers."Time Zone" = ''));
        Observer.Observe('settings_company_is_session_company', Format(Settings.Company = CompanyName()));
        Observer.Expect('profile_id_equals_row', 'Yes');
        Observer.Expect('language_id_equals_row', 'Yes');
        Observer.Expect('locale_id_equals_row', 'Yes');
        Observer.Expect('company_equals_row', 'Yes');
        Observer.Expect('time_zone_equals_row', 'Yes');
        Observer.Expect('row_company_blank', 'No');
        Observer.Expect('row_time_zone_blank', 'No');
        Observer.Expect('settings_company_is_session_company', 'Yes');
        Observer.Verify();
    end;

    // Last on purpose: the update request may restart the client of the test session.
}
