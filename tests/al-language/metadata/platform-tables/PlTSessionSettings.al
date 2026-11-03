// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessionsettings/sessionsettings-data-type
// Scope: in-scope
// Fixtures used: self-contained codeunit 74211
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// and the only RequestSessionUpdate call here passes false (no update); nothing session-wide changes, so nothing needs a restore.
// Members: SessionSettings.Init, Company, ProfileId, ProfileAppId, ProfileSystemScope, LanguageId, LocaleId, TimeZone, RequestSessionUpdate.
// BC versions: 29 (27 and 28 by CI)

codeunit 74211 "LT PlT SessionSettings"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(S: SessionSettings): Text
    begin
        exit(S.Company + '|' + S.ProfileId + '|' + Format(S.ProfileAppId) + '|' + Format(S.ProfileSystemScope) + '|' + Format(S.LanguageId) + '|' + Format(S.LocaleId) + '|' + S.TimeZone);
    end;

    [Test]
    procedure Init_Relations()
    var
        Observer: Codeunit "Probe Observer";
        A: SessionSettings;
        B: SessionSettings;
    begin
        A.Init();
        B.Init();
        Observer.Observe('two_inits_equal', Format(Describe(A) = Describe(B)));
        Observer.Observe('company_is_current', Format(A.Company = CompanyName()));
        Observer.Observe('language_positive', Format(A.LanguageId > 0));
        Observer.Observe('locale_positive', Format(A.LocaleId > 0));
        Observer.Observe('timezone_not_empty', Format(A.TimeZone <> ''));
        Observer.Observe('language_is_global', Format(A.LanguageId = GlobalLanguage()));
        Observer.Expect('two_inits_equal', 'Yes');
        Observer.Expect('company_is_current', 'Yes');
        Observer.Expect('language_positive', 'Yes');
        Observer.Expect('locale_positive', 'Yes');
        Observer.Expect('timezone_not_empty', 'Yes');
        Observer.Expect('language_is_global', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Uninitialized_Defaults()
    var
        Observer: Codeunit "Probe Observer";
        S: SessionSettings;
    begin
        Observer.Observe('company', S.Company);
        Observer.Observe('profile', S.ProfileId);
        Observer.Observe('profile_app', Format(S.ProfileAppId));
        Observer.Observe('system_scope', Format(S.ProfileSystemScope));
        Observer.Observe('language', Format(S.LanguageId));
        Observer.Observe('locale', Format(S.LocaleId));
        Observer.Observe('timezone', S.TimeZone);
        Observer.Expect('company', '');
        Observer.Expect('profile', '');
        Observer.Expect('profile_app', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('system_scope', 'No');
        Observer.Expect('language', '0');
        Observer.Expect('locale', '0');
        Observer.Expect('timezone', '');
        Observer.Verify();
    end;

    [Test]
    procedure Properties_SetAndReadBack()
    var
        Observer: Codeunit "Probe Observer";
        S: SessionSettings;
        Id: Guid;
    begin
        S.Init();
        S.Company := 'Some Company';
        S.ProfileId := 'SOME PROFILE';
        Id := CreateGuid();
        S.ProfileAppId := Id;
        S.ProfileSystemScope := true;
        S.LanguageId := 1031;
        S.LocaleId := 2057;
        S.TimeZone := 'UTC';
        Observer.Observe('company', S.Company);
        Observer.Observe('profile', S.ProfileId);
        Observer.Observe('profile_app_equal', Format(S.ProfileAppId = Id));
        Observer.Observe('system_scope', Format(S.ProfileSystemScope));
        Observer.Observe('language', Format(S.LanguageId));
        Observer.Observe('locale', Format(S.LocaleId));
        Observer.Observe('timezone', S.TimeZone);
        S.ProfileSystemScope := false;
        Observer.Observe('system_scope_off', Format(S.ProfileSystemScope));
        Observer.Expect('company', 'Some Company');
        Observer.Expect('profile', 'SOME PROFILE');
        Observer.Expect('profile_app_equal', 'Yes');
        Observer.Expect('system_scope', 'No');
        Observer.Expect('language', '1031');
        Observer.Expect('locale', '2057');
        Observer.Expect('timezone', 'UTC');
        Observer.Expect('system_scope_off', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Properties_EdgeValues()
    var
        Observer: Codeunit "Probe Observer";
        S: SessionSettings;
    begin
        S.Init();
        S.Company := '';
        S.ProfileId := '';
        S.LanguageId := 0;
        S.LocaleId := -1;
        S.TimeZone := '';
        Observer.Observe('empty_company', S.Company);
        Observer.Observe('empty_profile', S.ProfileId);
        Observer.Observe('language_zero', Format(S.LanguageId));
        Observer.Observe('locale_negative', Format(S.LocaleId));
        Observer.Observe('empty_timezone', S.TimeZone);
        S.Company := PadStr('', 100, 'c');
        Observer.Observe('long_company_len', Format(StrLen(S.Company)));
        S.ProfileId := PadStr('', 300, 'p');
        Observer.Observe('long_profile_len', Format(StrLen(S.ProfileId)));
        Observer.Expect('empty_company', '');
        Observer.Expect('empty_profile', '');
        Observer.Expect('language_zero', '0');
        Observer.Expect('locale_negative', '-1');
        Observer.Expect('empty_timezone', '');
        Observer.Expect('long_company_len', '100');
        Observer.Expect('long_profile_len', '300');
        Observer.Verify();
    end;

    [Test]
    procedure SettingsAreCopies()
    var
        Observer: Codeunit "Probe Observer";
        A: SessionSettings;
        B: SessionSettings;
    begin
        A.Init();
        B := A;
        B.LanguageId := 1031;
        Observer.Observe('copy_changed', Format(B.LanguageId));
        Observer.Observe('original_unchanged', Format(A.LanguageId = GlobalLanguage()));
        A.LanguageId := 1033;
        Observer.Observe('copy_keeps_own', Format(B.LanguageId));
        A.Init();
        Observer.Observe('init_resets', Format(A.LanguageId = GlobalLanguage()));
        Observer.Observe('session_untouched', Format(GlobalLanguage() > 0));
        Observer.Expect('copy_changed', '1031');
        Observer.Expect('original_unchanged', 'Yes');
        Observer.Expect('copy_keeps_own', '1031');
        Observer.Expect('init_resets', 'Yes');
        Observer.Expect('session_untouched', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RequestSessionUpdate_False()
    var
        Observer: Codeunit "Probe Observer";
        S: SessionSettings;
        Before: Text;
    begin
        S.Init();
        Before := Describe(S);
        asserterror S.RequestSessionUpdate(false);
        Observer.ObserveError('af134');
        Observer.Observe('no_error', 'no error');
        Observer.Observe('settings_same_after', Format(Describe(S) = Before));
        Observer.Observe('company_same', Format(CompanyName() = S.Company));
        Observer.Expect('af134|text', 'Unhandled UI: SessionSettings ');
        Observer.Expect('af134|code', 'MissingUIHandler');
        Observer.Expect('no_error', 'no error');
        Observer.Expect('settings_same_after', 'Yes');
        Observer.Expect('company_same', 'Yes');
        Observer.Verify();
    end;
}
