// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (69160); TiReadEventObjects.al (codeunit 73603: subscribers to the ten table events of Company, in-memory log codeunit 73607)
// Probe (al-runner issue 8238): which table events of the platform table Company a read raises (install code that counts or picks companies).
//   Each statement runs alone and the test observes the names of the events it raised ([] = no table event). Company data (count, names) is
//   not observed. The control validates "Display Name" with its own value (no write).
// BC result (measured on BC 28.5 and 27.5): no read of Company raises a table event (IsEmpty, Count, FindFirst, Get, FindSet with Next,
//   SetRange + Count, Reset, a field read, RecordRef IsEmpty/Count). The control: Validate "Display Name" raises OnBeforeValidate then
//   OnAfterValidate; Insert, Modify, Rename and Delete of a temporary Company record raise their OnBefore/OnAfter pair.
//   Side finding (first version of this probe): install code raises the Company OnBeforeInsertEvent inside OnInstallAppPerCompany, so a
//   Company subscriber that writes to the database breaks the app install (the subscribers here log in memory).
// BC versions: 27 - 29
codeunit 73605 "LT TI Company Read Events"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Take(): Text
    var
        Log: Codeunit "LT TI Company Event Log";
    begin
        exit(Log.Take());
    end;

    [Test]
    procedure Company_Reads_RaiseNoTableEvent()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
        RecRef: RecordRef;
        Name: Text;
        Found: Boolean;
        N: Integer;
    begin
        Take();
        Found := Company.IsEmpty();
        Observer.Observe('IsEmpty', Take());
        N := Company.Count();
        Observer.Observe('Count', Take());
        Found := Company.FindFirst();
        Observer.Observe('FindFirst', Take());
        Observer.Observe('Get CompanyName', Format(Company.Get(CompanyName())) + ' ' + Take());
        if Company.FindSet() then
            repeat
                N += 1;
            until Company.Next() = 0;
        Observer.Observe('FindSet Next', Take());
        Company.SetRange(Name, CompanyName());
        Observer.Observe('SetRange Count', Format(Company.Count()) + ' ' + Take());
        Company.Reset();
        Observer.Observe('Reset', Take());
        Company.Get(CompanyName());
        Name := Company."Display Name";
        Observer.Observe('field read', Take());
        RecRef.Open(Database::Company);
        Found := RecRef.IsEmpty();
        N := RecRef.Count();
        Observer.Observe('RecordRef IsEmpty Count', Take());
        RecRef.Close();
        Observer.Expect('IsEmpty', '[]');
        Observer.Expect('Count', '[]');
        Observer.Expect('FindFirst', '[]');
        Observer.Expect('Get CompanyName', 'Yes []');
        Observer.Expect('FindSet Next', '[]');
        Observer.Expect('SetRange Count', '1 []');
        Observer.Expect('Reset', '[]');
        Observer.Expect('field read', '[]');
        Observer.Expect('RecordRef IsEmpty Count', '[]');
        Observer.Verify();
    end;

    // The control: the Company subscribers are bound (Validate raises its events without a write).
    [Test]
    procedure Company_ValidateSameValue_RaisesValidateEvents()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
    begin
        Take();
        Company.Get(CompanyName());
        Company.Validate("Display Name", Company."Display Name");
        Observer.Observe('Validate Display Name', Take());
        Observer.Expect('Validate Display Name', '[Company.OnBeforeValidate,Company.OnAfterValidate]');
        Observer.Verify();
    end;

    // The control on a temporary Company record: writes raise the table events without touching the database.
    [Test]
    procedure Company_TemporaryRecordWrites_RaiseTheirEvents()
    var
        Observer: Codeunit "Probe Observer";
        TempCompany: Record Company temporary;
    begin
        Take();
        TempCompany.Init();
        TempCompany.Name := 'LT TI TEMP';
        TempCompany.Insert();
        Observer.Observe('temp Insert', Take());
        TempCompany."Display Name" := 'Temp';
        TempCompany.Modify();
        Observer.Observe('temp Modify', Take());
        TempCompany.Rename('LT TI TEMP2');
        Observer.Observe('temp Rename', Take());
        TempCompany.Delete();
        Observer.Observe('temp Delete', Take());
        Observer.Expect('temp Insert', '[Company.OnBeforeInsert,Company.OnAfterInsert]');
        Observer.Expect('temp Modify', '[Company.OnBeforeModify,Company.OnAfterModify]');
        Observer.Expect('temp Rename', '[Company.OnBeforeRename,Company.OnAfterRename]');
        Observer.Expect('temp Delete', '[Company.OnBeforeDelete,Company.OnAfterDelete]');
        Observer.Verify();
    end;
}
