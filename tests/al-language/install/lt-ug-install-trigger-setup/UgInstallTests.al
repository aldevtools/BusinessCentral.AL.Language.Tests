// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: Probe Observer (69160); read only: LT UG Setup Log (90363), written by the install subscribers and the trigger setup subscriber of
//   UgInstallFixtures.al while this app was installed.
// Probe: outside issue 6148, see UgInstallFixtures.al.
// BC versions: 27 - 29
codeunit 90367 "LT UG Install Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Tag(Company: Text): Text
    begin
        if Company = '' then
            exit('blank');
        exit('company');
    end;

    local procedure Asks(TableId: Integer; var Companies: List of [Text]): Integer
    var
        Log: Record "LT UG Setup Log";
    begin
        Log.SetRange("Table Id", TableId);
        if Log.FindSet() then
            repeat
                if not Companies.Contains(Log."Company") then
                    Companies.Add(Log."Company");
            until Log.Next() = 0;
        exit(Log.Count());
    end;

    // CLAIM (outside issue 6148): the platform asks for the database trigger setup (Global Triggers / GlobalTriggerManagement.OnAfterGetDatabaseTableTriggerSetup)
    // of a table when an install routine writes it with RunTrigger true, once per company in OnInstallAppPerCompany (a company is open: CompanyName() is not blank,
    // the setup subscriber reads a per-company table without an error) and NOT AT ALL for a write in OnInstallAppPerDatabase (there is no company). So a setup
    // subscriber without a CompanyName() guard is never reached with no company by an install.
    [Test]
    procedure TriggerSetup_AskedPerCompanyInInstall_NeverInPerDatabasePart()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT UG Setup Log";
        Company: Record Company;
        DatabaseRow: Record "LT UG Database Row";
        CompanyRow: Record "LT UG Company Part Row";
        DatabaseCompanies: List of [Text];
        PartCompanies: List of [Text];
        SetupCompanies: List of [Text];
        Blank: Integer;
        NotInstall: Integer;
        NotRead: Integer;
    begin
        Observer.Observe('row of the per-database part was written', Format(DatabaseRow.Count()));
        Observer.Observe('row of the per-company part was written (the second company hits the duplicate)', Format(CompanyRow.Count()));
        Observer.Observe('asks for the table written by the per-database part', Format(Asks(Database::"LT UG Database Row", DatabaseCompanies)));
        Observer.Observe('asks for the table written by the per-company part equal the companies', Format(Asks(Database::"LT UG Company Part Row", PartCompanies) = Company.Count()));
        Observer.Observe('asked once for each company', Format(PartCompanies.Count() = Company.Count()));
        Observer.Observe('asks for the per-company setup table equal the companies', Format(Asks(Database::"LT UG Per Company Setup", SetupCompanies) = Company.Count()));
        Log.SetFilter("Table Id", '<>0');
        if Log.FindSet() then
            repeat
                if Log."Company" = '' then
                    Blank += 1;
                if Log."Context" <> 'Install' then
                    NotInstall += 1;
                if Log.Info <> 'isempty=ok' then
                    NotRead += 1;
            until Log.Next() = 0;
        Observer.Observe('asks with no company', Format(Blank));
        Observer.Observe('asks outside the Install execution context', Format(NotInstall));
        Observer.Observe('asks where the IsEmpty of the per-company table did not work', Format(NotRead));
        Observer.Expect('row of the per-database part was written', '1');
        Observer.Expect('row of the per-company part was written (the second company hits the duplicate)', '1');
        Observer.Expect('asks for the table written by the per-database part', '0');
        Observer.Expect('asks for the table written by the per-company part equal the companies', 'Yes');
        Observer.Expect('asked once for each company', 'Yes');
        Observer.Expect('asks for the per-company setup table equal the companies', 'Yes');
        Observer.Expect('asks with no company', '0');
        Observer.Expect('asks outside the Install execution context', '0');
        Observer.Expect('asks where the IsEmpty of the per-company table did not work', '0');
        Observer.Verify();
    end;

    // CLAIM: the install subscriber of the per-database part itself (not the setup subscriber) runs with CompanyName() blank, and IsEmpty of a per-company table
    // raises the "You must choose a company" error there (install/lt-bf-install-probes/BfInstallTests.al pins the same for a Subtype = Install codeunit).
    [Test]
    procedure PerDatabasePart_IsEmptyOfPerCompanyTable_NoCompany()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT UG Setup Log";
    begin
        Log.SetRange("Table Id", 0);
        Observer.Observe('rows', Format(Log.Count()));
        Log.FindFirst();
        Observer.Observe('company', Tag(Log."Company"));
        Observer.Observe('context', Log."Context");
        Observer.Observe('read', Log.Info);
        Observer.Expect('rows', '1');
        Observer.Expect('company', 'blank');
        Observer.Expect('context', 'Install');
        Observer.Expect('read', 'install subscriber: isempty=error|You must choose a company before you can access the "LT UG Per Company Setup" table.|DB:Ok');
        Observer.Verify();
    end;
}
