// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: Probe Observer (69160); read only: LT BF Install Log (81250, BfInstallFixtures.al), LT BF Fixture Install Log (61052, internals fixture app),
//   LT V Event Log (69840, PeVFixtures.al), Install Seed (60617), Install Seed Database (60621), Install StartSession Obs, BEI Setup: all written by install code
//   when the apps were installed.
// Probe: corpus issue 661 (writer BF): P1 companies, P3 what each company holds, P4 subscribers of a dependency app, P5 order across apps, P6 order inside one app,
//   P7 the per-database part, P8 sessions and SingleInstance state of the install run.
// Order across tables: SystemRowVersion is one counter for the whole database (install/lt-av-install-order/AvInstallOrder.al uses it the same way), so sorting
//   the rows the install code inserted by SystemRowVersion gives the order in which the install code ran.
// Measured on 27.5, 28.5 and 29.0 (the same on all three except the row counts of two Base Application tables, BC28PLUS):
//   P1 two companies, "CRONUS International Ltd." (the session company, Evaluation Company = Yes) then "My Company"; Display Name is empty for both.
//   P3 "My Company" holds no Company Information, General Ledger Setup or Source Code Setup row, 2 Report Selections rows, 0 (27) or 1 (28, 29) No. Series rows,
//      the same inside this app's install code as later in a test.
//   P4 the fixture app's subscribers ran only at its own install (3 rows). P5 the fixture app's whole install ended before this app's install began.
//   P6 per company, all install routines of the app run in one sequence: install codeunit triggers and subscribers are not grouped by kind ("LT BF Install Late"
//      runs between the two subscriber codeunits), not by name ("LT BF Z Subs" runs before "LT BF A Subs") and not by ascending object id (60445, 60618 and
//      60894 run after 81255). The rule behind the sequence is not known; the same sequence repeats in each company and (for the routines that have one) in
//      the per-database part. One company completes before the next; the per-database part runs last.
//   P7 CompanyName() is empty in the per-database part (subscriber and install codeunit); IsEmpty and FindFirst of a per-company table fail with
//      'You must choose a company before you can access the "<table>" table.', GetLastErrorCode 'DB:Ok'.
//   P8 one session for the whole install of this app, another for the fixture app's, neither is the test session; execution context Install; a SingleInstance
//      codeunit starts again from its initial state in each company and in the per-database part (the counter restarts at 1), and keeps its state between the
//      codeunits of one company. The install session raised OnCompanyOpen and OnCompanyOpenCompleted in each company (2 calls), none in the per-database part.
// Not pinned: P2 (session company first, or the key order of the Company table): in this CI the session company also sorts first. A per-company table
//   insert from the per-database part: an error there cannot be caught (a write in a TryFunction), so the app would not install.
// BC versions: 27 - 29
codeunit 81257 "LT BF Install Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Tag(Company: Text): Text
    begin
        if Company = '' then
            exit('blank');
        if Company = CompanyName() then
            exit('session company');
        exit('other company');
    end;

    local procedure Plain(Value: Text): Text
    begin
        // The Probe Observer replaces the session company name by <Company>; underscores keep the name visible.
        exit(Value.Replace(' ', '_'));
    end;

    [Test]
    procedure Companies_OfTheDatabase_NamesInKeyOrder()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
        N: Integer;
    begin
        if Company.FindSet() then
            repeat
                N += 1;
                Observer.Observe('company #' + Format(N), Plain(Company.Name) + '|' + Plain(Company."Display Name") + '|evaluation=' + Format(Company."Evaluation Company") + '|' + Tag(Company.Name));
            until Company.Next() = 0;
        Observer.Observe('companies', Format(N));
        Observer.Expect('company #1', 'CRONUS_International_Ltd.||evaluation=Yes|session company');
        Observer.Expect('company #2', 'My_Company||evaluation=No|other company');
        Observer.Expect('companies', '2');
        Observer.Verify();
    end;

    local procedure CountIn(TableNo: Integer; Company: Text): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo, false, Company);
        exit(Format(RecRef.Count()));
    end;

    [Test]
    procedure Companies_BaseTableRows_ReadFromATest()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
    begin
        if Company.FindSet() then
            repeat
                Observer.Observe(Tag(Company.Name) + ' rows', '79=' + CountIn(79, Company.Name) + ';98=' + CountIn(98, Company.Name) + ';242=' + CountIn(242, Company.Name) + ';77=' + CountIn(77, Company.Name) + ';308=' + CountIn(308, Company.Name));
            until Company.Next() = 0;
#if BC28PLUS
        Observer.Expect('session company rows', '79=1;98=1;242=1;77=71;308=119');
#else
        Observer.Expect('session company rows', '79=1;98=1;242=1;77=70;308=118');
#endif
#if BC28PLUS
        Observer.Expect('other company rows', '79=0;98=0;242=0;77=2;308=1');
#else
        Observer.Expect('other company rows', '79=0;98=0;242=0;77=2;308=0');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure InstallLog_RowsOfThisApp_InIdOrder()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BF Install Log";
        FixtureRow: Record "LT BF Fixture Install Log";
        Sessions: List of [Integer];
        FixtureSessions: List of [Integer];
    begin
        Row.SetCurrentKey(Id);
        if Row.FindSet() then
            repeat
                Observer.Observe('row #' + Format(Row.Id), Row."Source" + '|' + Row."Event Name" + '|' + Tag(Row."Company") + '|context=' + Row."Context" + '|counter=' + Format(Row."Counter")
                    + '|fixture counter=' + Format(Row."Fixture Counter") + '|company open calls=' + Format(Row."Company Open Calls") + '|' + Row.Info);
                if not Sessions.Contains(Row."Session Id") then
                    Sessions.Add(Row."Session Id");
            until Row.Next() = 0;
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Observe('sessions of this app''s install', Format(Sessions.Count()));
        Observer.Observe('install session is the test session', Format(Sessions.Contains(SessionId())));
        if FixtureRow.FindSet() then
            repeat
                if not FixtureSessions.Contains(FixtureRow."Session Id") then
                    FixtureSessions.Add(FixtureRow."Session Id");
            until FixtureRow.Next() = 0;
        if (Sessions.Count() = 1) and (FixtureSessions.Count() = 1) then
            Observer.Observe('fixture install ran in the same session', Format(Sessions.Get(1) = FixtureSessions.Get(1)));
#if BC28PLUS
        Observer.Expect('row #1', 'Z Subs|OnInstallAppPerCompany|session company|context=Install|counter=1|fixture counter=0|company open calls=2|79=1;98=1;242=1;77=71;308=119');
#else
        Observer.Expect('row #1', 'Z Subs|OnInstallAppPerCompany|session company|context=Install|counter=1|fixture counter=0|company open calls=2|79=1;98=1;242=1;77=70;308=118');
#endif
        Observer.Expect('row #2', 'Install Late|OnInstallAppPerCompany|session company|context=Install|counter=2|fixture counter=0|company open calls=2|');
        Observer.Expect('row #3', 'A Subs|OnInstallAppPerCompany|session company|context=Install|counter=3|fixture counter=0|company open calls=2|');
#if BC28PLUS
        Observer.Expect('row #4', 'Z Subs|OnInstallAppPerCompany|other company|context=Install|counter=1|fixture counter=0|company open calls=2|79=0;98=0;242=0;77=2;308=1');
#else
        Observer.Expect('row #4', 'Z Subs|OnInstallAppPerCompany|other company|context=Install|counter=1|fixture counter=0|company open calls=2|79=0;98=0;242=0;77=2;308=0');
#endif
        Observer.Expect('row #5', 'Install Late|OnInstallAppPerCompany|other company|context=Install|counter=2|fixture counter=0|company open calls=2|');
        Observer.Expect('row #6', 'A Subs|OnInstallAppPerCompany|other company|context=Install|counter=3|fixture counter=0|company open calls=2|');
        Observer.Expect('row #7', 'Z Subs|OnInstallAppPerDatabase|blank|context=Install|counter=1|fixture counter=0|company open calls=0|isempty=error|You must choose a company before you can access the "LT BF Per Company Row" table.|DB:Ok;findfirst=error|You must choose a company before you can access the "LT BF Per Company Row" table.|DB:Ok');
        Observer.Expect('row #8', 'Install Late|OnInstallAppPerDatabase|blank|context=Install|counter=2|fixture counter=0|company open calls=0|isempty=error|You must choose a company before you can access the "LT BF Per Company Row" table.|DB:Ok;findfirst=error|You must choose a company before you can access the "LT BF Per Company Row" table.|DB:Ok');
        Observer.Expect('row #9', 'A Subs|OnInstallAppPerDatabase|blank|context=Install|counter=3|fixture counter=0|company open calls=0|');
        Observer.Expect('rows', '9');
        Observer.Expect('sessions of this app''s install', '1');
        Observer.Expect('install session is the test session', 'No');
        Observer.Expect('fixture install ran in the same session', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FixtureLog_RowsOfTheDependencyApp_InIdOrder()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BF Fixture Install Log";
        Sessions: List of [Integer];
    begin
        Row.SetCurrentKey(Id);
        if Row.FindSet() then
            repeat
                Observer.Observe('row #' + Format(Row.Id), Row."Event Name" + '|' + Tag(Row."Company") + '|context=' + Row."Context" + '|counter=' + Format(Row."Counter"));
                if not Sessions.Contains(Row."Session Id") then
                    Sessions.Add(Row."Session Id");
            until Row.Next() = 0;
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Observe('sessions', Format(Sessions.Count()));
        Observer.Expect('row #1', 'OnInstallAppPerCompany|session company|context=Install|counter=1');
        Observer.Expect('row #2', 'OnInstallAppPerCompany|other company|context=Install|counter=1');
        Observer.Expect('row #3', 'OnInstallAppPerDatabase|blank|context=Install|counter=1');
        Observer.Expect('rows', '3');
        Observer.Expect('sessions', '1');
        Observer.Verify();
    end;

    local procedure AddPoint(var Versions: List of [BigInteger]; var Labels: List of [Text]; Version: BigInteger; PointLabel: Text)
    begin
        Versions.Add(Version);
        Labels.Add(PointLabel);
    end;

    local procedure InVersionOrder(var Versions: List of [BigInteger]; var Labels: List of [Text]): Text
    var
        Result: Text;
        Best: Integer;
        i: Integer;
    begin
        while Versions.Count() > 0 do begin
            Best := 1;
            for i := 2 to Versions.Count() do
                if Versions.Get(i) < Versions.Get(Best) then
                    Best := i;
            Result += Labels.Get(Best) + ';';
            Versions.RemoveAt(Best);
            Labels.RemoveAt(Best);
        end;
        exit(Result);
    end;

    [Test]
    procedure InstallOrder_AllInstallRows_InSystemRowVersionOrder()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
        Row: Record "LT BF Install Log";
        FixtureRow: Record "LT BF Fixture Install Log";
        PevRow: Record "LT V Event Log";
        Seed: Record "Install Seed";
        SeedDatabase: Record "Install Seed Database";
        StartSessionObs: Record "Install StartSession Obs";
        BeiSetup: Record "BEI Setup";
        Versions: List of [BigInteger];
        Labels: List of [Text];
    begin
        if FixtureRow.FindSet() then
            repeat
                AddPoint(Versions, Labels, FixtureRow.SystemRowVersion, 'fixture subs ' + FixtureRow."Event Name" + ' (' + Tag(FixtureRow."Company") + ')');
            until FixtureRow.Next() = 0;
        if Row.FindSet() then
            repeat
                AddPoint(Versions, Labels, Row.SystemRowVersion, Row."Source" + ' ' + Row."Event Name" + ' (' + Tag(Row."Company") + ')');
            until Row.Next() = 0;
        PevRow.SetFilter("Event Name", '%1|%2', 'OnInstallAppPerCompany', 'OnInstallAppPerDatabase');
        if PevRow.FindSet() then
            repeat
                AddPoint(Versions, Labels, PevRow.SystemRowVersion, 'PeV subs ' + PevRow."Event Name" + ' (' + Tag(PevRow.Info) + ')');
            until PevRow.Next() = 0;
        if SeedDatabase.Get('DATABASE') then
            AddPoint(Versions, Labels, SeedDatabase.SystemRowVersion, 'Install Seeder OnInstallAppPerDatabase');
        if Company.FindSet() then
            repeat
                Seed.ChangeCompany(Company.Name);
                if Seed.Get('COMPANY1') then
                    AddPoint(Versions, Labels, Seed.SystemRowVersion, 'Install Seeder OnInstallAppPerCompany (' + Tag(Company.Name) + ')');
                StartSessionObs.ChangeCompany(Company.Name);
                if StartSessionObs.Get('STARTSESSION') then
                    AddPoint(Versions, Labels, StartSessionObs.SystemRowVersion, 'Install StartSession Probe OnInstallAppPerCompany (' + Tag(Company.Name) + ')');
                BeiSetup.ChangeCompany(Company.Name);
                if BeiSetup.FindFirst() then
                    AddPoint(Versions, Labels, BeiSetup.SystemRowVersion, 'BEI Installer OnInstallAppPerCompany (' + Tag(Company.Name) + ')');
            until Company.Next() = 0;
        Observer.Observe('order', InVersionOrder(Versions, Labels));
        Observer.Expect('order', 'fixture subs OnInstallAppPerCompany (session company);fixture subs OnInstallAppPerCompany (other company);fixture subs OnInstallAppPerDatabase (blank);PeV subs OnInstallAppPerCompany (session company);Z Subs OnInstallAppPerCompany (session company);Install Late OnInstallAppPerCompany (session company);A Subs OnInstallAppPerCompany (session company);Install StartSession Probe OnInstallAppPerCompany (session company);Install Seeder OnInstallAppPerCompany (session company);BEI Installer OnInstallAppPerCompany (session company);PeV subs OnInstallAppPerCompany (other company);Z Subs OnInstallAppPerCompany (other company);Install Late OnInstallAppPerCompany (other company);A Subs OnInstallAppPerCompany (other company);Install StartSession Probe OnInstallAppPerCompany (other company);Install Seeder OnInstallAppPerCompany (other company);BEI Installer OnInstallAppPerCompany (other company);PeV subs OnInstallAppPerDatabase (blank);Z Subs OnInstallAppPerDatabase (blank);Install Late OnInstallAppPerDatabase (blank);A Subs OnInstallAppPerDatabase (blank);Install Seeder OnInstallAppPerDatabase;');
        Observer.Verify();
    end;

    local procedure CdsText(Company: Text): Text
    var
        Cds: Record "CDS Connection Setup";
        Result: Text;
    begin
        Cds.ChangeCompany(Company);
        Result := 'isempty=' + Format(Cds.IsEmpty()) + ';count=' + Format(Cds.Count());
        if Cds.FindFirst() then
            Result += ';enabled=' + Format(Cds."Is Enabled") + ';server=' + Cds."Server Address";
        exit(Result);
    end;

    local procedure CrmText(Company: Text): Text
    var
        Crm: Record "CRM Connection Setup";
        Result: Text;
    begin
        Crm.ChangeCompany(Company);
        Result := 'isempty=' + Format(Crm.IsEmpty()) + ';count=' + Format(Crm.Count());
        if Crm.FindFirst() then
            Result += ';enabled=' + Format(Crm."Is Enabled");
        exit(Result);
    end;

    local procedure SetupText(Company: Text; WithJobQueue: Boolean): Text
    var
        AppAreaSetup: Record "Application Area Setup";
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        JobQueueEntry: Record "Job Queue Entry";
        CompanyInfo: Record "Company Information";
        Result: Text;
    begin
        AppAreaSetup.ChangeCompany(Company);
        GLSetup.ChangeCompany(Company);
        SalesSetup.ChangeCompany(Company);
        JobQueueEntry.ChangeCompany(Company);
        CompanyInfo.ChangeCompany(Company);
        Result := 'app area setup=' + Format(AppAreaSetup.Count());
        Result += ';gl setup get=' + Format(GLSetup.Get()) + ';gl setup=' + Format(GLSetup.Count());
        Result += ';sales setup get=' + Format(SalesSetup.Get()) + ';sales setup=' + Format(SalesSetup.Count());
        if WithJobQueue then
            Result += ';job queue entries=' + Format(JobQueueEntry.Count());
        Result += ';company information get=' + Format(CompanyInfo.Get()) + ';company information=' + Format(CompanyInfo.Count());
        if CompanyInfo.Get() then
            Result += ';company information name=' + Plain(CompanyInfo.Name);
        exit(Result);
    end;

    [Test]
    procedure SecondCompany_CdsConnectionSetup_ComparedWithSessionCompany()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Read only: ChangeCompany on the tables, nothing is written to either company.
        // Measured on 27.5, 28.5 and 29.0 (the same on all three): neither company has a CDS Connection Setup row (no Is Enabled / Server Address to read).
        Observer.Observe('session company cds', CdsText(CompanyName()));
        Observer.Observe('My Company cds', CdsText('My Company'));
        Observer.Expect('session company cds', 'isempty=Yes;count=0');
        Observer.Expect('My Company cds', 'isempty=Yes;count=0');
        Observer.Verify();
    end;

    [Test]
    procedure SecondCompany_CrmConnectionSetup_ComparedWithSessionCompany()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Read only: ChangeCompany on the table, nothing is written to either company. Probe: corpus issue 811.
        // Measured on RESULT
        Observer.Observe('session company crm', CrmText(CompanyName()));
        Observer.Observe('My Company crm', CrmText('My Company'));
        Observer.Expect('session company crm', 'isempty=Yes;count=0');
        Observer.Expect('My Company crm', 'isempty=Yes;count=0');
        Observer.Verify();
    end;

    [Test]
    procedure SecondCompany_SetupTablesReadByCompanyInitialize_ComparedWithSessionCompany()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Measured on 27.5, 28.5 and 29.0 (the same on all three): the session company has one row in each setup table and Company Information Name
        // CRONUS International Ltd.; "My Company" has one Application Area Setup row, no General Ledger Setup, Sales & Receivables Setup or Company
        // Information row (Get fails) and one Job Queue Entry. The job queue count of the session company (6 in the measured runs) is not asserted: other
        // test codeunits can change it.
        Observer.Observe('session company setup', SetupText(CompanyName(), false));
        Observer.Observe('My Company setup', SetupText('My Company', true));
        Observer.Expect('session company setup', 'app area setup=1;gl setup get=Yes;gl setup=1;sales setup get=Yes;sales setup=1;company information get=Yes;company information=1;company information name=CRONUS_International_Ltd.');
        Observer.Expect('My Company setup', 'app area setup=1;gl setup get=No;gl setup=0;sales setup get=No;sales setup=0;job queue entries=1;company information get=No;company information=0');
        Observer.Verify();
    end;
}
