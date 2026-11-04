// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessionsettings/sessionsettings-requestsessionupdate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained test codeunit 80205
// Probe: corpus issue 647 item 8 (writer AV), the open part of W6UserPersonalization.al. RISKY (own codeunit, one test): the test deletes the User Personalization
//   row of the session user, calls RequestSessionUpdate(true) under a [SessionSettingsHandler], and puts the original row back at the end.
// Facts: whether RequestSessionUpdate(true) creates the User Personalization row of the session user, and what the new row holds compared with the settings.
// BC versions: 27, 28, 29
codeunit 80205 "LT AV Request Session Update"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerCalls: Integer;
        RowInHandler: Boolean;

    [Test]
    [HandlerFunctions('SettingsHandler')]
    procedure RequestSessionUpdate_True_WithoutARow()
    var
        Observer: Codeunit "Probe Observer";
        UserPers: Record "User Personalization";
        Saved: Record "User Personalization";
        Settings: SessionSettings;
        HadRow: Boolean;
    begin
        HadRow := Saved.Get(UserSecurityId());
        Observer.Observe('row at start', Format(HadRow));
        if HadRow then
            UserPers.Get(UserSecurityId());
        if HadRow then
            UserPers.Delete();
        Observer.Observe('row after delete', Format(UserPers.Get(UserSecurityId())));
        Settings.Init();
        Observer.Observe('settings company is the session company', Format(Settings.Company() = CompanyName()));
        Settings.RequestSessionUpdate(true);
        Observer.Observe('handler calls', Format(HandlerCalls));
        Observer.Observe('row inside the handler', Format(RowInHandler));
        Clear(UserPers);
        Observer.Observe('row after the request', Format(UserPers.Get(UserSecurityId())));
        if UserPers.Get(UserSecurityId()) then begin
            Observer.Observe('row company equals settings', Format(UserPers.Company = Settings.Company()));
            Observer.Observe('row profile equals settings', Format(UserPers."Profile ID" = Settings.ProfileId()));
            Observer.Observe('row language equals settings', Format(UserPers."Language ID" = Settings.LanguageId()));
            Observer.Observe('row locale equals settings', Format(UserPers."Locale ID" = Settings.LocaleId()));
            Observer.Observe('row time zone equals settings', Format(UserPers."Time Zone" = Settings.TimeZone()));
            UserPers.Delete();
        end;
        if HadRow then
            Saved.Insert();
        Observer.Observe('row restored', Format(UserPers.Get(UserSecurityId()) = HadRow));
        Observer.Expect('row at start', 'Yes');
        Observer.Expect('row after delete', 'No');
        Observer.Expect('settings company is the session company', 'Yes');
        Observer.Expect('handler calls', '1');
        Observer.Expect('row inside the handler', 'Yes');
        Observer.Expect('row after the request', 'Yes');
        Observer.Expect('row company equals settings', 'Yes');
        Observer.Expect('row profile equals settings', 'Yes');
        Observer.Expect('row language equals settings', 'Yes');
        Observer.Expect('row locale equals settings', 'Yes');
        Observer.Expect('row time zone equals settings', 'Yes');
        Observer.Expect('row restored', 'Yes');
        Observer.Verify();
    end;

    [SessionSettingsHandler]
    procedure SettingsHandler(var TestSessionSettings: SessionSettings): Boolean
    var
        UserPers: Record "User Personalization";
    begin
        HandlerCalls += 1;
        RowInHandler := UserPers.Get(UserSecurityId());
        exit(false);
    end;
}
