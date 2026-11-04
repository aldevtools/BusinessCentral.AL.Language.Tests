// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/companyproperty/companyproperty-id-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); the system table Company
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Risky: reads the fields Id and "Display Name" of the Company table; if either does not compile the whole file is dropped.
// Facts: CompanyProperty.ID() against Company.Id of the current company; CompanyProperty.DisplayName() against Company."Display Name" (empty or not) and CompanyName().
// BC versions: 29 (27 and 28 by CI)

codeunit 71931 "LT P160 Company Record"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ID_EqualsTheCompanyRecordId()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
    begin
        Observer.Observe('company found', Format(Company.Get(CompanyName())));
        Observer.Observe('Company.Id equals CompanyProperty.ID', Format(Company.Id = CompanyProperty.ID()));
        Observer.Observe('Company.Id is null', Format(IsNullGuid(Company.Id)));
        Observer.Expect('company found', 'Yes');
        Observer.Expect('Company.Id equals CompanyProperty.ID', 'Yes');
        Observer.Expect('Company.Id is null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure DisplayName_AgainstTheCompanyRecord()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
    begin
        Observer.Observe('company found', Format(Company.Get(CompanyName())));
        Observer.Observe('Display Name empty', Format(Company."Display Name" = ''));
        Observer.Observe('Display Name equals CompanyName', Format(Company."Display Name" = CompanyName()));
        Observer.Observe('CompanyProperty.DisplayName equals Display Name', Format(CompanyProperty.DisplayName() = Company."Display Name"));
        Observer.Observe('CompanyProperty.DisplayName equals CompanyName', Format(CompanyProperty.DisplayName() = CompanyName()));
        Observer.Expect('company found', 'Yes');
        Observer.Expect('Display Name empty', 'Yes');
        Observer.Expect('Display Name equals CompanyName', 'No');
        Observer.Expect('CompanyProperty.DisplayName equals Display Name', 'No');
        Observer.Expect('CompanyProperty.DisplayName equals CompanyName', 'Yes');
        Observer.Verify();
    end;
}
