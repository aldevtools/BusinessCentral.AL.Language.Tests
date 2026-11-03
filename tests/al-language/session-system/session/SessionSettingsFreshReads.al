// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessionsettings/sessionsettings-data-type
// Scope: in-scope
// Fixtures used: none
//
// A SessionSettings variable nobody called Init() on: what LanguageId, LocaleId, TimeZone, ProfileId,
// ProfileAppId, Company and the scope flags read, in relation to the session (GlobalLanguage, CompanyName),
// and the text Format gives. Then Init() and Clear(). Values that depend on the runner are observed as
// comparisons, not literals.
//
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 72717 "LT P161 Session Settings"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P161_FreshInstance_DefaultReads()
    var
        Observer: Codeunit "Probe Observer";
        S: SessionSettings;
        NullGuid: Guid;
    begin
        Observer.Observe('language', Format(S.LanguageId()));
        Observer.Observe('languageIsGlobal', Format(S.LanguageId() = GlobalLanguage()));
        Observer.Observe('locale', Format(S.LocaleId()));
        Observer.Observe('timeZone', S.TimeZone());
        Observer.Observe('company', S.Company());
        Observer.Observe('companyIsCurrent', Format(S.Company() = CompanyName()));
        Observer.Observe('profileId', S.ProfileId());
        Observer.Observe('profileAppIdNull', Format(S.ProfileAppId() = NullGuid));
        Observer.Observe('profileSystemScope', Format(S.ProfileSystemScope()));
        Observer.Expect('language', '0');
        Observer.Expect('languageIsGlobal', 'No');
        Observer.Expect('locale', '0');
        Observer.Expect('timeZone', '');
        Observer.Expect('company', '');
        Observer.Expect('companyIsCurrent', 'No');
        Observer.Expect('profileId', '');
        Observer.Expect('profileAppIdNull', 'Yes');
        Observer.Expect('profileSystemScope', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P161_FreshInstance_FormatText()
    var
        Observer: Codeunit "Probe Observer";
        S: SessionSettings;
        T: Text;
    begin
        T := Format(S);
        Observer.Observe('format', T);
        Observer.Observe('startsWithCompany', Format(T.StartsWith('Company=')));
        Observer.Observe('hasLanguageId', Format(T.Contains('LanguageId=')));
        Observer.Expect('format', 'Company=, ProfileId=, LanguageId=0, LocaleId=0, TimeZone=, ProfileAppId={00000000-0000-0000-0000-000000000000}, ProfileSystemScope=False');
        Observer.Expect('startsWithCompany', 'Yes');
        Observer.Expect('hasLanguageId', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P161_Init_ThenClear()
    var
        Observer: Codeunit "Probe Observer";
        S: SessionSettings;
        Fresh: SessionSettings;
    begin
        S.Init();
        Observer.Observe('init.languageIsGlobal', Format(S.LanguageId() = GlobalLanguage()));
        Observer.Observe('init.locale', Format(S.LocaleId()));
        Observer.Observe('init.timeZone', S.TimeZone());
        Observer.Observe('init.company', S.Company());
        Observer.Observe('init.companyIsCurrent', Format(S.Company() = CompanyName()));
        Observer.Observe('init.profileId', S.ProfileId());
        Observer.Observe('init.formatEqualsFresh', Format(Format(S) = Format(Fresh)));
        Clear(S);
        Observer.Observe('clear.formatEqualsFresh', Format(Format(S) = Format(Fresh)));
        Observer.Expect('init.languageIsGlobal', 'Yes');
        Observer.Expect('init.locale', '1033');
        Observer.Expect('init.timeZone', 'UTC');
        Observer.Expect('init.company', '<Company>');
        Observer.Expect('init.companyIsCurrent', 'Yes');
        Observer.Expect('init.profileId', 'BUSINESS MANAGER');
        Observer.Expect('init.formatEqualsFresh', 'No');
        Observer.Expect('clear.formatEqualsFresh', 'Yes');
        Observer.Verify();
    end;
}
