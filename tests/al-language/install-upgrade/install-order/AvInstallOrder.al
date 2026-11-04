// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: Probe Observer (69160); read only: Install Seed (60617), Install Seed Database (60621), Install Env Observation (60588), written by the install codeunit
//   "Install Seeder" (60618) when the app was installed, and LT V Event Log (69840), written by the subscribers of the "Extension Triggers" install events (PeVFixtures.al)
// Probe: corpus issue 647 item 2 (writer AV). No new install codeunit (check-install-triggers.py): the order is read back from what the existing install code wrote.
// Facts: how many companies OnInstallAppPerCompany ran in, whether OnInstallAppPerDatabase ran before or after it (SystemRowVersion is one counter for the whole
//   database, so it orders rows of different tables and companies), what CompanyName() answered inside each per-company run, and the same order for the
//   "Extension Triggers" events (AutoIncrement Id of LT V Event Log).
// Measured: OnInstallAppPerCompany ran once in each of the two companies (session company first) and BEFORE OnInstallAppPerDatabase, in one session; the same on 27.5, 28.5, 29.0.
// BC versions: 27, 28, 29
codeunit 80200 "LT AV Install Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure InstallCodeunit_PerDatabaseAndPerCompany_OrderAndCount()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
        Seed: Record "Install Seed";
        SeedDatabase: Record "Install Seed Database";
        Observation: Record "Install Env Observation";
        DatabaseVersion: BigInteger;
        FirstCompanyVersion: BigInteger;
        Companies: Integer;
        SessionFirst: Text;
        Tag: Text;
    begin
        Observer.Observe('database row', Format(SeedDatabase.Get('DATABASE')));
        DatabaseVersion := SeedDatabase.SystemRowVersion;
        Observer.Observe('database rows', Format(SeedDatabase.Count()));
        if Company.FindSet() then
            repeat
                Companies += 1;
                if Company.Name = CompanyName() then
                    Tag := 'session company'
                else
                    Tag := 'other company';
                Seed.ChangeCompany(Company.Name);
                Observation.ChangeCompany(Company.Name);
                Observer.Observe(Tag + ' seed rows', Format(Seed.Count()));
                if Seed.Get('COMPANY1') then begin
                    Observer.Observe(Tag + ' per-company after per-database', Format(Seed.SystemRowVersion > DatabaseVersion));
                    if (FirstCompanyVersion = 0) or (Seed.SystemRowVersion < FirstCompanyVersion) then begin
                        FirstCompanyVersion := Seed.SystemRowVersion;
                        SessionFirst := Tag;
                    end;
                end;
                Observer.Observe(Tag + ' env rows', Format(Observation.Count()));
                if Observation.Get('ENV') then
                    Observer.Observe(Tag + ' CompanyName() inside per-company is this company', Format(Observation."Observed Company Name" = Company.Name));
            until Company.Next() = 0;
        Observer.Observe('companies', Format(Companies));
        Observer.Observe('first per-company run', SessionFirst);
        Observer.Expect('database row', 'Yes');
        Observer.Expect('database rows', '1');
        Observer.Expect('session company seed rows', '2');
        Observer.Expect('session company per-company after per-database', 'No');
        Observer.Expect('session company env rows', '1');
        Observer.Expect('session company CompanyName() inside per-company is this company', 'Yes');
        Observer.Expect('other company seed rows', '2');
        Observer.Expect('other company per-company after per-database', 'No');
        Observer.Expect('other company env rows', '1');
        Observer.Expect('other company CompanyName() inside per-company is this company', 'Yes');
        Observer.Expect('companies', '2');
        Observer.Expect('first per-company run', 'session company');
        Observer.Verify();
    end;

    [Test]
    procedure ExtensionTriggers_PerDatabaseAndPerCompany_Order()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT V Event Log";
        Sequence: Text;
        FirstSession: Integer;
        SameSession: Boolean;
    begin
        SameSession := true;
        Row.SetFilter("Event Name", '%1|%2', 'OnInstallAppPerCompany', 'OnInstallAppPerDatabase');
        Row.SetCurrentKey(Id);
        if Row.FindSet() then begin
            FirstSession := Row."Session Id";
            repeat
                if Row."Session Id" <> FirstSession then
                    SameSession := false;
                if Row."Event Name" = 'OnInstallAppPerDatabase' then
                    Sequence += 'database;'
                else
                    if Row.Info = CompanyName() then
                        Sequence += 'company(session company);'
                    else
                        if Row.Info = '' then
                            Sequence += 'company(blank);'
                        else
                            Sequence += 'company(other company);';
            until Row.Next() = 0;
        end;
        Observer.Observe('sequence', Sequence);
        Observer.Observe('one session', Format(SameSession));
        Observer.Expect('sequence', 'company(session company);company(other company);database;');
        Observer.Expect('one session', 'Yes');
        Observer.Verify();
    end;
}
