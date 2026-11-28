// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/codeunit/codeunit-company-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT UL9 Read, LT UL9 Reader, LT UL9 Subs (UlInstallUserLogin.al).
// Probe: al-runner pin bump (assumption install-user-login-other-company). Which System Application "User Login" (table 9008) rows
//   a read finds inside this app's install session: in the company-open subscriber and in the install code, per company, in the
//   current company and through RecordRef.ChangeCompany into every company, with IsEmpty, Count, FindFirst and the primary key
//   lookup of UserSecurityId(). The test session is the control. Companies are tagged "session company" (the company of the
//   test session), "My Company" (the other company of the CI database, by name) or "other company"; no ids. Count is bucketed
//   (0, 1, more than 1). For a found row only blank / not blank of its fields is recorded, and whether its SID is the current user.
// Measured on BC 27.5 (27.5.54899.59044), 28.5 (28.5.54976.59048) and 29.0 (29.0.54011.59052), W1 sandbox artifacts on the
//   corpus-pinned bc-linux stack (local observation, fresh stack per leg as in CI). The results are the same on all three:
//   - The install session runs as the test user, and every read in it (company-open subscriber, per-company and per-database
//     install code) finds no "User Login" row: IsEmpty = Yes, Count = 0, FindFirst and Get fail, in the session company and
//     in My Company, directly and through ChangeCompany.
//   - In the per-database install code (blank company) a direct read raises "You must choose a company before you can access
//     the "User Login" table."; through ChangeCompany it reads like the other cells (no row).
//   - Control, test session: the session company holds one row, for the current user (penultimate login blank); My Company
//     holds none.
// BC versions: 27 - 29
codeunit 76433 "LT UL9 Install Read Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Tag(Company: Text): Text
    begin
        if Company = '' then
            exit('blank');
        if Company = CompanyName() then
            exit('session company');
        if Company = 'My Company' then
            exit('My Company');
        exit('other company');
    end;

    local procedure ObserveKind(var Observer: Codeunit "Probe Observer"; Kind: Text; ViaChangeCompany: Boolean)
    var
        Log: Record "LT UL9 Read";
        Prefix: Text;
    begin
        Log.SetCurrentKey(Id);
        Log.SetRange(Kind, Kind);
        Log.SetRange("Via ChangeCompany", ViaChangeCompany);
        Observer.Observe('rows', Format(Log.Count()));
        if Log.FindSet() then
            repeat
                if ViaChangeCompany then
                    Prefix := 'in ' + Tag(Log.Company) + ' reading ' + Tag(Log.Target)
                else
                    Prefix := 'in ' + Tag(Log.Company);
                Observer.Observe(Prefix + ': context', Log.Context);
                Observer.Observe(Prefix + ': all rows', Log."All Rows");
                Observer.Observe(Prefix + ': current user', Log."User Rows");
            until Log.Next() = 0;
    end;

    [Test]
    procedure CompanyOpen_CurrentCompany_UserLoginRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveKind(Observer, 'company open', false);
        Observer.Expect('rows', '2');
        Observer.Expect('in session company: context', 'Install');
        Observer.Expect('in session company: all rows', 'isempty=Yes|count=0|findfirst=No');
        Observer.Expect('in session company: current user', 'isempty=Yes|count=0|findfirst=No|get=No');
        Observer.Expect('in My Company: context', 'Install');
        Observer.Expect('in My Company: all rows', 'isempty=Yes|count=0|findfirst=No');
        Observer.Expect('in My Company: current user', 'isempty=Yes|count=0|findfirst=No|get=No');
        Observer.Verify();
    end;

    [Test]
    procedure CompanyOpen_ChangeCompany_UserLoginRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveKind(Observer, 'company open', true);
        Observer.Expect('rows', '4');
        Observer.Expect('in session company reading session company: context', 'Install');
        Observer.Expect('in session company reading session company: all rows', 'isempty=Yes|count=0|findfirst=No');
        Observer.Expect('in session company reading session company: current user', 'isempty=Yes|count=0|findfirst=No|get=No');
        Observer.Expect('in session company reading My Company: context', 'Install');
        Observer.Expect('in session company reading My Company: all rows', 'isempty=Yes|count=0|findfirst=No');
        Observer.Expect('in session company reading My Company: current user', 'isempty=Yes|count=0|findfirst=No|get=No');
        Observer.Expect('in My Company reading session company: context', 'Install');
        Observer.Expect('in My Company reading session company: all rows', 'isempty=Yes|count=0|findfirst=No');
        Observer.Expect('in My Company reading session company: current user', 'isempty=Yes|count=0|findfirst=No|get=No');
        Observer.Expect('in My Company reading My Company: context', 'Install');
        Observer.Expect('in My Company reading My Company: all rows', 'isempty=Yes|count=0|findfirst=No');
        Observer.Expect('in My Company reading My Company: current user', 'isempty=Yes|count=0|findfirst=No|get=No');
        Observer.Verify();
    end;

    [Test]
    procedure InstallPerCompany_CurrentCompany_UserLoginRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveKind(Observer, 'install per company', false);
        Observer.Expect('rows', '2');
        Observer.Expect('in session company: context', 'Install');
        Observer.Expect('in session company: all rows', 'isempty=Yes|count=0|findfirst=No');
        Observer.Expect('in session company: current user', 'isempty=Yes|count=0|findfirst=No|get=No');
        Observer.Expect('in My Company: context', 'Install');
        Observer.Expect('in My Company: all rows', 'isempty=Yes|count=0|findfirst=No');
        Observer.Expect('in My Company: current user', 'isempty=Yes|count=0|findfirst=No|get=No');
        Observer.Verify();
    end;

    [Test]
    procedure InstallPerCompany_ChangeCompany_UserLoginRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveKind(Observer, 'install per company', true);
        Observer.Expect('rows', '4');
        Observer.Expect('in session company reading session company: context', 'Install');
        Observer.Expect('in session company reading session company: all rows', 'isempty=Yes|count=0|findfirst=No');
        Observer.Expect('in session company reading session company: current user', 'isempty=Yes|count=0|findfirst=No|get=No');
        Observer.Expect('in session company reading My Company: context', 'Install');
        Observer.Expect('in session company reading My Company: all rows', 'isempty=Yes|count=0|findfirst=No');
        Observer.Expect('in session company reading My Company: current user', 'isempty=Yes|count=0|findfirst=No|get=No');
        Observer.Expect('in My Company reading session company: context', 'Install');
        Observer.Expect('in My Company reading session company: all rows', 'isempty=Yes|count=0|findfirst=No');
        Observer.Expect('in My Company reading session company: current user', 'isempty=Yes|count=0|findfirst=No|get=No');
        Observer.Expect('in My Company reading My Company: context', 'Install');
        Observer.Expect('in My Company reading My Company: all rows', 'isempty=Yes|count=0|findfirst=No');
        Observer.Expect('in My Company reading My Company: current user', 'isempty=Yes|count=0|findfirst=No|get=No');
        Observer.Verify();
    end;

    [Test]
    procedure InstallPerDatabase_UserLoginRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveKind(Observer, 'install per database', false);
        ObserveKind(Observer, 'install per database', true);
        Observer.Expect('rows', '1');
        Observer.Expect('in blank: context', 'Install');
        Observer.Expect('in blank: all rows', 'error: You must choose a company before you can access the "User Login" table.');
        Observer.Expect('in blank: current user', 'error: You must choose a company before you can access the "User Login" table.');
        Observer.Expect('rows', '2');
        Observer.Expect('in blank reading session company: context', 'Install');
        Observer.Expect('in blank reading session company: all rows', 'isempty=Yes|count=0|findfirst=No');
        Observer.Expect('in blank reading session company: current user', 'isempty=Yes|count=0|findfirst=No|get=No');
        Observer.Expect('in blank reading My Company: context', 'Install');
        Observer.Expect('in blank reading My Company: all rows', 'isempty=Yes|count=0|findfirst=No');
        Observer.Expect('in blank reading My Company: current user', 'isempty=Yes|count=0|findfirst=No|get=No');
        Observer.Verify();
    end;

    [Test]
    procedure InstallSession_User_SameAsTestUser()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT UL9 Read";
        Company: Record Company;
        Other: Integer;
    begin
        Observer.Observe('install rows', Format(not Log.IsEmpty()));
        Log.SetFilter("User SID", '<>%1', UserSecurityId());
        Observer.Observe('install rows of another user', Format(Log.Count()));
        Observer.Observe('test user sid blank', Format(IsNullGuid(UserSecurityId())));
        Company.SetFilter(Name, '<>%1', CompanyName());
        Observer.Observe('companies other than the session company', Format(Company.Count()));
        Company.SetRange(Name, 'My Company');
        Other := Company.Count();
        Observer.Observe('My Company among them', Format(Other = 1));
        Observer.Expect('install rows', 'Yes');
        Observer.Expect('install rows of another user', '0');
        Observer.Expect('test user sid blank', 'No');
        Observer.Expect('companies other than the session company', '1');
        Observer.Expect('My Company among them', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TestSession_Control_UserLoginRows()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT UL9 Reader";
        Company: Record Company;
        AllRows: Text;
        UserRows: Text;
    begin
        Reader.Read('', false, AllRows, UserRows);
        Observer.Observe('in session company: all rows', AllRows);
        Observer.Observe('in session company: current user', UserRows);
        if Company.FindSet() then
            repeat
                Reader.Read(Company.Name, true, AllRows, UserRows);
                Observer.Observe('in session company reading ' + Tag(Company.Name) + ': all rows', AllRows);
                Observer.Observe('in session company reading ' + Tag(Company.Name) + ': current user', UserRows);
            until Company.Next() = 0;
        Observer.Expect('in session company: all rows', 'isempty=No|count=1|findfirst=Yes (sid blank=No, sid is current user=Yes, first login date blank=No, penultimate login blank=Yes, last login blank=No)');
        Observer.Expect('in session company: current user', 'isempty=No|count=1|findfirst=Yes (sid blank=No, sid is current user=Yes, first login date blank=No, penultimate login blank=Yes, last login blank=No)|get=Yes (sid blank=No, sid is current user=Yes, first login date blank=No, penultimate login blank=Yes, last login blank=No)');
        Observer.Expect('in session company reading session company: all rows', 'isempty=No|count=1|findfirst=Yes (sid blank=No, sid is current user=Yes, first login date blank=No, penultimate login blank=Yes, last login blank=No)');
        Observer.Expect('in session company reading session company: current user', 'isempty=No|count=1|findfirst=Yes (sid blank=No, sid is current user=Yes, first login date blank=No, penultimate login blank=Yes, last login blank=No)|get=Yes (sid blank=No, sid is current user=Yes, first login date blank=No, penultimate login blank=Yes, last login blank=No)');
        Observer.Expect('in session company reading My Company: all rows', 'isempty=Yes|count=0|findfirst=No');
        Observer.Expect('in session company reading My Company: current user', 'isempty=Yes|count=0|findfirst=No|get=No');
        Observer.Verify();
    end;
}
