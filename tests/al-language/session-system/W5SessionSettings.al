// Batch 5, md:11 (SessionSettings.RequestSessionUpdate handler answers, RequestSessionUpdate(true), no handler) and md:240 (SessionSettings.Init).
// Observe-only: every test ends in Observer.Finish().
// Fixtures used: self-contained (see the object ids below)

codeunit 67067 "W5 SessSettings Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerLog: Text;
        HandlerCalls: Integer;

    [SessionSettingsHandler]
    procedure HandlerAnswersFalse(var Settings: SessionSettings): Boolean
    begin
        HandlerCalls += 1;
        HandlerLog += 'lang=' + Format(Settings.LanguageId()) + ';';
        Settings.LanguageId(1031);
        exit(false);
    end;

    [SessionSettingsHandler]
    procedure HandlerAnswersTrue(var Settings: SessionSettings): Boolean
    begin
        HandlerCalls += 1;
        HandlerLog += 'lang=' + Format(Settings.LanguageId()) + ';';
        Settings.LanguageId(1031);
        exit(true);
    end;

    // md:11: the handler answers false; what does the sender see afterwards?
    [Test]
    [HandlerFunctions('HandlerAnswersFalse')]
    procedure SessionSettings_Update_HandlerAnswersFalse()
    var
        Observer: Codeunit "Probe Observer";
        Settings: SessionSettings;
    begin
        HandlerLog := '';
        HandlerCalls := 0;
        Settings.LanguageId(1033);
        Settings.RequestSessionUpdate(false);
        Observer.Observe('handler_calls', Format(HandlerCalls));
        Observer.Observe('handler_log', HandlerLog);
        Observer.Observe('sender_language_after', Format(Settings.LanguageId()));
        Observer.Expect('handler_calls', '1');
        Observer.Expect('handler_log', 'lang=1033;');
        Observer.Expect('sender_language_after', '1031');
        Observer.Verify();
    end;

    // md:11: the handler answers true; same questions.
    [Test]
    [HandlerFunctions('HandlerAnswersTrue')]
    procedure SessionSettings_Update_HandlerAnswersTrue()
    var
        Observer: Codeunit "Probe Observer";
        Settings: SessionSettings;
    begin
        HandlerLog := '';
        HandlerCalls := 0;
        Settings.LanguageId(1033);
        Settings.RequestSessionUpdate(false);
        Observer.Observe('handler_calls', Format(HandlerCalls));
        Observer.Observe('handler_log', HandlerLog);
        Observer.Observe('sender_language_after', Format(Settings.LanguageId()));
        Observer.Expect('handler_calls', '1');
        Observer.Expect('handler_log', 'lang=1033;');
        Observer.Expect('sender_language_after', '1031');
        Observer.Verify();
    end;

    // md:11: the handler runs once per call, also for a second call on the same variable (the second call sees the handler's change from the first).
    [Test]
    [HandlerFunctions('HandlerAnswersFalse')]
    procedure SessionSettings_Update_TwoCallsTwoHandlerRuns()
    var
        Observer: Codeunit "Probe Observer";
        Settings: SessionSettings;
    begin
        HandlerLog := '';
        HandlerCalls := 0;
        Settings.LanguageId(1033);
        Settings.RequestSessionUpdate(false);
        Settings.RequestSessionUpdate(false);
        Observer.Observe('handler_calls', Format(HandlerCalls));
        Observer.Observe('handler_log', HandlerLog);
        Observer.Expect('handler_calls', '2');
        Observer.Expect('handler_log', 'lang=1033;lang=1031;');
        Observer.Verify();
    end;

    // md:11: a call without a handler. Unsure whether it raises: Try wrapper.
    [Test]
    procedure SessionSettings_Update_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
        Settings: SessionSettings;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryRequest(Settings, false);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('no_handler');
        Observer.Expect('ok', 'No');
        Observer.Expect('no_handler|text', 'Unhandled UI: SessionSettings ');
        Observer.Expect('no_handler|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    // md:11: RequestSessionUpdate(true) with a handler. It may save User Personalization: the call sits in an asserterror so that a write is rolled back.
    [Test]
    [HandlerFunctions('HandlerAnswersTrue')]
    procedure SessionSettings_Update_SaveTrue_WithHandler()
    var
        Observer: Codeunit "Probe Observer";
        Settings: SessionSettings;
    begin
        HandlerLog := '';
        HandlerCalls := 0;
        Settings.LanguageId(1033);
        asserterror
        begin
            Settings.RequestSessionUpdate(true);
            Error('W5 stop after RequestSessionUpdate(true)');
        end;
        Observer.ObserveError('save_true');
        Observer.Observe('handler_calls', Format(HandlerCalls));
        Observer.Observe('handler_log', HandlerLog);
        Observer.Observe('sender_language_after', Format(Settings.LanguageId()));
        Observer.Expect('save_true|text', 'W5 stop after RequestSessionUpdate(true)');
        Observer.Expect('save_true|code', 'Dialog');
        Observer.Expect('handler_calls', '1');
        Observer.Expect('handler_log', 'lang=1033;');
        Observer.Expect('sender_language_after', '1031');
        Observer.Verify();
    end;

    // md:240: Init() against values set before it.
    [Test]
    procedure SessionSettings_Init_ReplacesEarlierValues()
    var
        Observer: Codeunit "Probe Observer";
        Settings: SessionSettings;
        NullGuid: Guid;
    begin
        Settings.LanguageId(1055);
        Settings.LocaleId(1055);
        Settings.TimeZone('Pacific Standard Time');
        Settings.Company('W5 Sentinel Company');
        Settings.ProfileId('W5 SENTINEL');
        Settings.Init();
        Observer.Observe('language_is_global_language', Format(Settings.LanguageId() = GlobalLanguage()));
        Observer.Observe('language_is_sentinel', Format(Settings.LanguageId() = 1055));
        Observer.Observe('locale_is_sentinel', Format(Settings.LocaleId() = 1055));
        Observer.Observe('locale_positive', Format(Settings.LocaleId() > 0));
        Observer.Observe('timezone_nonblank', Format(Settings.TimeZone() <> ''));
        Observer.Observe('timezone_is_sentinel', Format(Settings.TimeZone() = 'Pacific Standard Time'));
        Observer.Observe('company_blank', Format(Settings.Company() = ''));
        Observer.Observe('company_is_current', Format(Settings.Company() = CompanyName()));
        Observer.Observe('company_is_sentinel', Format(Settings.Company() = 'W5 Sentinel Company'));
        Observer.Observe('profile_id', '[' + Settings.ProfileId() + ']');
        Observer.Observe('profile_app_id_null', Format(Settings.ProfileAppId() = NullGuid));
        Observer.Expect('language_is_global_language', 'Yes');
        Observer.Expect('language_is_sentinel', 'No');
        Observer.Expect('locale_is_sentinel', 'No');
        Observer.Expect('locale_positive', 'Yes');
        Observer.Expect('timezone_nonblank', 'Yes');
        Observer.Expect('timezone_is_sentinel', 'No');
        Observer.Expect('company_blank', 'No');
        Observer.Expect('company_is_current', 'Yes');
        Observer.Expect('company_is_sentinel', 'No');
        Observer.Expect('profile_id', '[BUSINESS MANAGER]');
        Observer.Expect('profile_app_id_null', 'No');
        Observer.Verify();
    end;

    // md:240: Init() takes the language from the session's GlobalLanguage, not from a fixed value.
    [Test]
    procedure SessionSettings_Init_FollowsGlobalLanguage()
    var
        Observer: Codeunit "Probe Observer";
        Settings: SessionSettings;
        OldLanguage: Integer;
        LocaleBefore: Integer;
        Ok: Boolean;
    begin
        OldLanguage := GlobalLanguage();
        Settings.Init();
        LocaleBefore := Settings.LocaleId();
        Ok := TrySetGlobalLanguage(1031);
        Observer.Observe('set_global_language_ok', Format(Ok));
        if Ok then begin
            Settings.Init();
            Observer.Observe('language_after_init', Format(Settings.LanguageId()));
            Observer.Observe('locale_unchanged', Format(Settings.LocaleId() = LocaleBefore));
        end;
        TrySetGlobalLanguage(OldLanguage);
        Observer.Observe('language_restored', Format(GlobalLanguage() = OldLanguage));
        Observer.Expect('set_global_language_ok', 'Ja');
        Observer.Expect('language_after_init', '1033');
        Observer.Expect('locale_unchanged', 'Ja');
        Observer.Expect('language_restored', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRequest(var Settings: SessionSettings; SaveSettings: Boolean)
    begin
        Settings.RequestSessionUpdate(SaveSettings);
    end;

    [TryFunction]
    local procedure TrySetGlobalLanguage(LanguageId: Integer)
    begin
        GlobalLanguage(LanguageId);
    end;
}
