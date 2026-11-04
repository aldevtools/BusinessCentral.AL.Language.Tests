// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessionsettings/sessionsettings-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row 10 (SessionSettings): what a pristine (never assigned) TimeZone(), LanguageId(), LocaleId(), Company(), ProfileId() read, plain and inside a [SessionSettingsHandler]
// Facts: pristine reads of every property, before and after Init(), compared with the running session; the same reads inside the handler
// BC versions: 29 (27 and 28 by CI)

codeunit 70170 "LT PnG Session Settings"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerCalls: Integer;
        SawLanguage: Integer;
        SawLocale: Integer;
        SawTimeZone: Text;
        SawCompany: Text;
        SawProfile: Text;
        SawProfileScope: Text;
        SawProfileApp: Text;

    [Test]
    procedure PristineReadsWithoutInit()
    var
        Observer: Codeunit "Probe Observer";
        Settings: SessionSettings;
    begin
        Observer.Observe('language-is-zero', Format(Settings.LanguageId() = 0));
        Observer.Observe('locale-is-zero', Format(Settings.LocaleId() = 0));
        Observer.Observe('timezone-length', Format(StrLen(Settings.TimeZone())));
        Observer.Observe('timezone-is-empty', Format(Settings.TimeZone() = ''));
        Observer.Observe('company-length', Format(StrLen(Settings.Company())));
        Observer.Observe('company-is-empty', Format(Settings.Company() = ''));
        Observer.Observe('profile-length', Format(StrLen(Settings.ProfileId())));
        Observer.Observe('profile-is-empty', Format(Settings.ProfileId() = ''));
        Observer.Observe('profile-app-length', Format(StrLen(Format(Settings.ProfileAppId()))));
        Observer.Observe('profile-scope', Format(Settings.ProfileSystemScope()));
        Observer.Expect('language-is-zero', 'Yes');
        Observer.Expect('locale-is-zero', 'Yes');
        Observer.Expect('timezone-length', '0');
        Observer.Expect('timezone-is-empty', 'Yes');
        Observer.Expect('company-length', '0');
        Observer.Expect('company-is-empty', 'Yes');
        Observer.Expect('profile-length', '0');
        Observer.Expect('profile-is-empty', 'Yes');
        Observer.Expect('profile-app-length', '38');
        Observer.Expect('profile-scope', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure PristineReadsEqualRunningSession()
    var
        Observer: Codeunit "Probe Observer";
        Settings: SessionSettings;
    begin
        Observer.Observe('language-eq-global', Format(Settings.LanguageId() = GlobalLanguage()));
        Observer.Observe('company-eq-current', Format(Settings.Company() = CompanyName()));
        Observer.Observe('language-raw', Format(Settings.LanguageId()));
        Observer.Observe('locale-raw', Format(Settings.LocaleId()));
        Observer.Observe('timezone-raw', Settings.TimeZone());
        Observer.Observe('company-raw-eq-current', Format(Settings.Company() = CompanyName()));
        Observer.Expect('language-eq-global', 'No');
        Observer.Expect('company-eq-current', 'No');
        Observer.Expect('language-raw', '0');
        Observer.Expect('locale-raw', '0');
        Observer.Expect('timezone-raw', '');
        Observer.Expect('company-raw-eq-current', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ReadsAfterInit()
    var
        Observer: Codeunit "Probe Observer";
        Settings: SessionSettings;
    begin
        Settings.Init();
        Observer.Observe('init-language-eq-global', Format(Settings.LanguageId() = GlobalLanguage()));
        Observer.Observe('init-language-raw', Format(Settings.LanguageId()));
        Observer.Observe('init-locale-raw', Format(Settings.LocaleId()));
        Observer.Observe('init-timezone-length', Format(StrLen(Settings.TimeZone())));
        Observer.Observe('init-timezone-raw', Settings.TimeZone());
        Observer.Observe('init-company-eq-current', Format(Settings.Company() = CompanyName()));
        Observer.Observe('init-profile-length', Format(StrLen(Settings.ProfileId())));
        Observer.Observe('init-profile-scope', Format(Settings.ProfileSystemScope()));
        Observer.Expect('init-language-eq-global', 'Yes');
        Observer.Expect('init-language-raw', '1033');
        Observer.Expect('init-locale-raw', '1033');
        Observer.Expect('init-timezone-length', '3');
        Observer.Expect('init-timezone-raw', 'UTC');
        Observer.Expect('init-company-eq-current', 'Yes');
        Observer.Expect('init-profile-length', '16');
        Observer.Expect('init-profile-scope', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure AssignedThenReadBack()
    var
        Observer: Codeunit "Probe Observer";
        Settings: SessionSettings;
    begin
        Settings.TimeZone('Pacific Standard Time');
        Observer.Observe('tz-assigned', Settings.TimeZone());
        Observer.Observe('language-after-tz-eq-global', Format(Settings.LanguageId() = GlobalLanguage()));
        Observer.Observe('company-after-tz-length', Format(StrLen(Settings.Company())));
        Settings.LanguageId(1030);
        Observer.Observe('language-assigned', Format(Settings.LanguageId()));
        Observer.Observe('locale-after-language', Format(Settings.LocaleId()));
        Observer.Observe('tz-kept-after-language', Settings.TimeZone());
        Settings.LocaleId(1033);
        Observer.Observe('locale-assigned', Format(Settings.LocaleId()));
        Observer.Observe('language-kept-after-locale', Format(Settings.LanguageId()));
        Observer.Expect('tz-assigned', 'Pacific Standard Time');
        Observer.Expect('language-after-tz-eq-global', 'No');
        Observer.Expect('company-after-tz-length', '0');
        Observer.Expect('language-assigned', '1030');
        Observer.Expect('locale-after-language', '0');
        Observer.Expect('tz-kept-after-language', 'Pacific Standard Time');
        Observer.Expect('locale-assigned', '1033');
        Observer.Expect('language-kept-after-locale', '1030');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PristineHandler')]
    procedure HandlerSeesPristineSettings()
    var
        Observer: Codeunit "Probe Observer";
        Settings: SessionSettings;
    begin
        HandlerCalls := 0;
        Settings.RequestSessionUpdate(false);
        Observer.Observe('handler-calls', Format(HandlerCalls));
        Observer.Observe('handler-language-eq-global', Format(SawLanguage = GlobalLanguage()));
        Observer.Observe('handler-language-is-zero', Format(SawLanguage = 0));
        Observer.Observe('handler-locale-is-zero', Format(SawLocale = 0));
        Observer.Observe('handler-timezone-length', Format(StrLen(SawTimeZone)));
        Observer.Observe('handler-timezone-is-empty', Format(SawTimeZone = ''));
        Observer.Observe('handler-company-eq-current', Format(SawCompany = CompanyName()));
        Observer.Observe('handler-company-is-empty', Format(SawCompany = ''));
        Observer.Observe('handler-profile-length', Format(StrLen(SawProfile)));
        Observer.Observe('handler-profile-app-length', Format(StrLen(SawProfileApp)));
        Observer.Observe('handler-profile-scope', SawProfileScope);
        Observer.Observe('global-language-unchanged', Format(GlobalLanguage() = SawLanguage));
        Observer.Expect('handler-calls', '1');
        Observer.Expect('handler-language-eq-global', 'No');
        Observer.Expect('handler-language-is-zero', 'Yes');
        Observer.Expect('handler-locale-is-zero', 'Yes');
        Observer.Expect('handler-timezone-length', '0');
        Observer.Expect('handler-timezone-is-empty', 'Yes');
        Observer.Expect('handler-company-eq-current', 'No');
        Observer.Expect('handler-company-is-empty', 'Yes');
        Observer.Expect('handler-profile-length', '0');
        Observer.Expect('handler-profile-app-length', '38');
        Observer.Expect('handler-profile-scope', 'No');
        Observer.Expect('global-language-unchanged', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PristineHandler')]
    procedure HandlerSeesInitSettings()
    var
        Observer: Codeunit "Probe Observer";
        Settings: SessionSettings;
    begin
        HandlerCalls := 0;
        Settings.Init();
        Settings.RequestSessionUpdate(false);
        Observer.Observe('init-handler-calls', Format(HandlerCalls));
        Observer.Observe('init-handler-language-eq-global', Format(SawLanguage = GlobalLanguage()));
        Observer.Observe('init-handler-timezone-length', Format(StrLen(SawTimeZone)));
        Observer.Observe('init-handler-company-eq-current', Format(SawCompany = CompanyName()));
        Observer.Expect('init-handler-calls', '1');
        Observer.Expect('init-handler-language-eq-global', 'Yes');
        Observer.Expect('init-handler-timezone-length', '3');
        Observer.Expect('init-handler-company-eq-current', 'Yes');
        Observer.Verify();
    end;

    [SessionSettingsHandler]
    procedure PristineHandler(var TheSettings: SessionSettings): Boolean
    begin
        HandlerCalls += 1;
        SawLanguage := TheSettings.LanguageId();
        SawLocale := TheSettings.LocaleId();
        SawTimeZone := TheSettings.TimeZone();
        SawCompany := TheSettings.Company();
        SawProfile := TheSettings.ProfileId();
        SawProfileApp := Format(TheSettings.ProfileAppId());
        SawProfileScope := Format(TheSettings.ProfileSystemScope());
        exit(false);
    end;
}
