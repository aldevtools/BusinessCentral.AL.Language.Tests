// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/table/system.globalization.windows-language
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/codeunit/codeunit-company-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT WLI Log, LT WLI State, LT WLI Subs (WlInstallWindowsLanguage.al).
// Probe: al-runner issue 9046 (provider table 2000000045 "Windows Language", one of the reasons that tie the install order of an app that reads it
//   on the codeunit 151 "System Initialization Impl." path). The claim: the install session reads the same rows in OnInstallAppPerDatabase,
//   OnInstallAppPerCompany and the "Company Triggers" OnCompanyOpen subscriber of the install session as the test session does, so the install
//   order cannot change what the table returns.
// The read (LT WLI Subs.ReadWindowsLanguage): Count(); Get of 1033, 1031, 1049 and 1067 (Armenian, a language with no OEM code page) with
//   Name, Primary CodePage and Language Tag; FindSet over SetRange("Globally Enabled", true) with the rows iterated and the sum of their Language ID.
// Observer.Verify compares in order: the Expect calls follow the order of the Observe calls.
// Install-session rows are the rows with the session id of the install per database row. The test session is the control.
//   Companies are numbered C1, C2, ... in the order of their first row (no names: the company order differs between hosts).
// Expected values: the rows of record/table-properties/Y39WindowsLanguageTable.al (248 rows, all Globally Enabled, Language ID sum 1091889);
//   Primary CodePage of 1067 is '1' on every major (corpus PR 1607).
// No Initialize() with DeleteAll: the tests read the rows the install session wrote; deleting them would remove what is measured.
// Not measured: upgrade sessions (CI installs fresh, an upgrade trigger never runs here; the OnCompanyOpen subscriber also writes rows for an
//   Upgrade context, so a later upgrade job reads them without a fixture change). A second company beyond the ones CI creates.
// BC versions: 27 - 29
codeunit 96003 "LT WLI Install Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ExpectedRead(): Text
    begin
        exit('count=248,' +
            '1033=Yes|English (United States)|437|en-US,' +
            '1031=Yes|German (Germany)|850|de-DE,' +
            '1049=Yes|Russian (Russia)|866|ru-RU,' +
            '1067=Yes|Armenian (Armenia)|1|hy-AM,' +
            'globally enabled findset=248|1091889');
    end;

    local procedure CompanyNo(var Companies: List of [Text]; Company: Text): Text
    begin
        if Company = '' then
            exit('blank');
        if not Companies.Contains(Company) then
            Companies.Add(Company);
        exit('C' + Format(Companies.IndexOf(Company)));
    end;

    local procedure InstallSessionId(): Integer
    var
        Log: Record "LT WLI Log";
    begin
        Log.SetRange(Kind, 'install per database');
        if Log.FindFirst() then
            exit(Log."Session Id");
        exit(-1);
    end;

    [Test]
    procedure InstallSession_WindowsLanguage_ReadsInEveryInstallStep()
    // CLAIM: OnInstallAppPerDatabase, OnInstallAppPerCompany and OnCompanyOpen of the install session run in one session, in this order per
    //   company, and each reads the 248 rows and the four fixed rows of Windows Language.
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT WLI Log";
        Companies: List of [Text];
        Sequence: Text;
        InstallId: Integer;
    begin
        InstallId := InstallSessionId();
        Observer.Observe('install per database row', Format(InstallId <> -1));
        Log.SetCurrentKey(Id);
        Log.SetRange("Session Id", InstallId);
        if Log.FindSet() then
            repeat
                Sequence += Log.Kind + '|' + CompanyNo(Companies, Log.Company) + '|' + Log.Context + ';';
                Observer.Observe(Log.Kind + ' ' + CompanyNo(Companies, Log.Company), Log."Read");
            until Log.Next() = 0;
        Observer.Observe('install session', Sequence);
        Log.SetFilter("Session Id", '<>%1', InstallId);
        Observer.Observe('rows of other sessions', Format(Log.Count()));
        Observer.Observe('test session is the install session', Format(SessionId() = InstallId));
        Observer.Expect('install per database row', 'Yes');
        Observer.Expect('OnCompanyOpen C1', ExpectedRead());
        Observer.Expect('install per company C1', ExpectedRead());
        Observer.Expect('OnCompanyOpen C2', ExpectedRead());
        Observer.Expect('install per company C2', ExpectedRead());
        Observer.Expect('install per database blank', ExpectedRead());
        Observer.Expect('install session', 'OnCompanyOpen|C1|Install;install per company|C1|Install;OnCompanyOpen|C2|Install;install per company|C2|Install;install per database|blank|Install;');
        Observer.Expect('rows of other sessions', '0');
        Observer.Expect('test session is the install session', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure InstallSession_WindowsLanguage_SameAsTestSession()
    // CLAIM: every read of the install session equals the same read in the test session, whatever the values are.
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT WLI Log";
        Subs: Codeunit "LT WLI Subs";
        Companies: List of [Text];
        TestRead: Text;
        Rows: Integer;
    begin
        TestRead := Subs.ReadWindowsLanguage();
        Log.SetCurrentKey(Id);
        Log.SetRange("Session Id", InstallSessionId());
        if Log.FindSet() then
            repeat
                Rows += 1;
                Observer.Observe(Log.Kind + ' ' + CompanyNo(Companies, Log.Company) + ' equals the test session', Format(Log."Read" = TestRead));
            until Log.Next() = 0;
        Observer.Observe('install session rows', Format(Rows));
        Observer.Expect('OnCompanyOpen C1 equals the test session', 'Yes');
        Observer.Expect('install per company C1 equals the test session', 'Yes');
        Observer.Expect('OnCompanyOpen C2 equals the test session', 'Yes');
        Observer.Expect('install per company C2 equals the test session', 'Yes');
        Observer.Expect('install per database blank equals the test session', 'Yes');
        Observer.Expect('install session rows', '5');
        Observer.Verify();
    end;

    [Test]
    procedure TestSession_Control_WindowsLanguage_InSubscriberAndTestProcedure()
    // CLAIM: the test session reads the same rows in its own OnCompanyOpen subscriber and in the test procedure.
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "LT WLI State";
        Subs: Codeunit "LT WLI Subs";
    begin
        Observer.Observe('subscriber in the test session', State.AsText());
        Observer.Observe('test procedure', Subs.ReadWindowsLanguage());
        Observer.Expect('subscriber in the test session', 'OnCompanyOpen|' + ExpectedRead() + ';');
        Observer.Expect('test procedure', ExpectedRead());
        Observer.Verify();
    end;
}
