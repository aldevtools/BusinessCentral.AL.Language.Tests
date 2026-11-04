// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-workdate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: (1) WorkDate() against Today() at the start of a test, with the difference in days; (2) the Company Information row of the corpus database (Name, Address,
// Address 2, City, Post Code, Country/Region Code, Phone No.) and the captions of those fields. The report dataset header carries these values; the company
// name is replaced by <Company> in an observation. Object id 67858.

codeunit 67858 "LT Company Information Values"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure WorkDate_AgainstToday()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // The distance to Today() depends on the date of the test image, so only the kind of value is observed.
        Observer.Observe('workdate_not_blank', Format(WorkDate() <> 0D));
        Observer.Observe('workdate_is_a_whole_date', Format(WorkDate() = DT2Date(CreateDateTime(WorkDate(), 0T))));
        Observer.Expect('workdate_not_blank', 'Yes');
        Observer.Expect('workdate_is_a_whole_date', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure WorkDate_SetAndRestore()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Date;
    begin
        Saved := WorkDate();
        WorkDate(Saved + 3);
        Observer.Observe('after_set_days_from_saved', Format(WorkDate() - Saved));
        WorkDate(Saved);
        Observer.Observe('after_restore_equals_saved', Format(WorkDate() = Saved));
        Observer.Expect('after_set_days_from_saved', '3');
        Observer.Expect('after_restore_equals_saved', 'Yes');
        Observer.Verify();
    end;

    // Writer QG (runtime PR 380): the demo rows of the corpus database as a test sees them, read before any test of this codeunit changes them
    // (tests run in declaration order): the Company Information row and the Accounting Period rows. Dates are written with Format(D, 0, 9).
    [Test]
    procedure QG_CompanyInformation_CorpusRow()
    var
        Observer: Codeunit "Probe Observer";
        Info: Record "Company Information";
    begin
        Observer.Observe('count', Format(Info.Count()));
        Observer.Observe('get', Format(Info.Get()));
        Observer.Observe('primary_key', Info."Primary Key");
        Observer.Observe('name', Info.Name);
        Observer.Observe('name_equals_company_name', Format(Info.Name = CompanyName()));
        Observer.Observe('name_2', Info."Name 2");
        Observer.Observe('address', Info.Address);
        Observer.Observe('address_2', Info."Address 2");
        Observer.Observe('city', Info.City);
        Observer.Observe('post_code', Info."Post Code");
        Observer.Observe('county', Info.County);
        Observer.Observe('country_region_code', Info."Country/Region Code");
        Observer.Observe('phone_no', Info."Phone No.");
        Observer.Observe('vat_registration_no', Info."VAT Registration No.");
        Observer.Observe('registration_no', Info."Registration No.");
        Observer.Observe('picture_hasvalue_before_calcfields', Format(Info.Picture.HasValue()));
        Info.CalcFields(Picture);
        Observer.Observe('picture_hasvalue', Format(Info.Picture.HasValue()));
        Observer.Expect('count', '1');
        Observer.Expect('get', 'Yes');
        Observer.Expect('primary_key', '');
        Observer.Expect('name', '<Company>');
        Observer.Expect('name_equals_company_name', 'Yes');
        Observer.Expect('name_2', '');
        Observer.Expect('address', '5 The Ring');
        Observer.Expect('address_2', 'Westminster');
        Observer.Expect('city', 'London');
        Observer.Expect('post_code', 'W2 8HG');
        Observer.Expect('county', '');
        Observer.Expect('country_region_code', 'GB');
        Observer.Expect('phone_no', '0666-666-6666');
        Observer.Expect('vat_registration_no', '777777777');
        Observer.Expect('registration_no', '');
        Observer.Expect('picture_hasvalue_before_calcfields', 'Yes');
        Observer.Expect('picture_hasvalue', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QG_AccountingPeriod_CorpusRows()
    var
        Observer: Codeunit "Probe Observer";
        Period: Record "Accounting Period";
    begin
        Observer.Observe('count', Format(Period.Count()));
        Observer.Observe('isempty', Format(Period.IsEmpty()));
        if Period.FindFirst() then begin
            Observer.Observe('first_starting_date', Format(Period."Starting Date", 0, 9));
            Observer.Observe('first_new_fiscal_year', Format(Period."New Fiscal Year"));
            Observer.Observe('first_closed', Format(Period.Closed));
        end;
        if Period.FindLast() then
            Observer.Observe('last_starting_date', Format(Period."Starting Date", 0, 9));
        Period.SetRange("New Fiscal Year", true);
        Observer.Observe('fiscal_year_starts', Format(Period.Count()));
        Period.SetRange("New Fiscal Year");
        Period.SetRange(Closed, true);
        Observer.Observe('closed_count', Format(Period.Count()));
        Observer.Expect('count', '36');
        Observer.Expect('isempty', 'No');
        Observer.Expect('first_starting_date', '2025-01-01');
        Observer.Expect('first_new_fiscal_year', 'Yes');
        Observer.Expect('first_closed', 'Yes');
        Observer.Expect('last_starting_date', '2027-12-01');
        Observer.Expect('fiscal_year_starts', '3');
        Observer.Expect('closed_count', '12');
        Observer.Verify();
    end;

    [Test]
    procedure CompanyInformation_Values()
    var
        Observer: Codeunit "Probe Observer";
        Info: Record "Company Information";
        Saved: Record "Company Information";
        Existed: Boolean;
    begin
        // The values are set here, so the test does not depend on the demo data of the test image. The row is restored before the assertions.
        Existed := Info.Get();
        if Existed then
            Saved := Info
        else begin
            Info.Init();
            Info.Insert();
        end;
        Info.Name := CopyStr(CompanyName(), 1, MaxStrLen(Info.Name));
        Info.Address := '5 The Ring';
        Info."Address 2" := 'Westminster';
        Info.City := 'London';
        Info."Post Code" := 'W2 8HG';
        Info."Country/Region Code" := 'GB';
        Info.County := '';
        Info."Phone No." := '0666-666-6666';
        Info.Modify();
        Clear(Info);
        Observer.Observe('get', Format(Info.Get()));
        Observer.Observe('name', Info.Name);
        Observer.Observe('address', Info.Address);
        Observer.Observe('address_2', Info."Address 2");
        Observer.Observe('city', Info.City);
        Observer.Observe('post_code', Info."Post Code");
        Observer.Observe('country_region_code', Info."Country/Region Code");
        Observer.Observe('county', Info.County);
        Observer.Observe('phone_no', Info."Phone No.");
        Observer.Observe('name_equals_company_name', Format(Info.Name = CompanyName()));
        if Existed then begin
            Info := Saved;
            Info.Modify();
        end else
            Info.Delete();
        Observer.Expect('get', 'Yes');
        Observer.Expect('name', '<Company>');
        Observer.Expect('address', '5 The Ring');
        Observer.Expect('address_2', 'Westminster');
        Observer.Expect('city', 'London');
        Observer.Expect('post_code', 'W2 8HG');
        Observer.Expect('country_region_code', 'GB');
        Observer.Expect('county', '');
        Observer.Expect('phone_no', '0666-666-6666');
        Observer.Expect('name_equals_company_name', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CompanyInformation_Captions()
    var
        Observer: Codeunit "Probe Observer";
        Info: Record "Company Information";
    begin
        Observer.Observe('table_caption', Info.TableCaption());
        Observer.Observe('name', Info.FieldCaption(Name));
        Observer.Observe('address', Info.FieldCaption(Address));
        Observer.Observe('address_2', Info.FieldCaption("Address 2"));
        Observer.Observe('city', Info.FieldCaption(City));
        Observer.Observe('post_code', Info.FieldCaption("Post Code"));
        Observer.Observe('country_region_code', Info.FieldCaption("Country/Region Code"));
        Observer.Observe('phone_no', Info.FieldCaption("Phone No."));
        Observer.Observe('vat_registration_no', Info.FieldCaption("VAT Registration No."));
        Observer.Observe('bank_name', Info.FieldCaption("Bank Name"));
        Observer.Observe('iban', Info.FieldCaption(IBAN));
        Observer.Expect('table_caption', 'Company Information');
        Observer.Expect('name', 'Name');
        Observer.Expect('address', 'Address');
        Observer.Expect('address_2', 'Address 2');
        Observer.Expect('city', 'City');
        Observer.Expect('post_code', 'Post Code');
        Observer.Expect('country_region_code', 'Country/Region Code');
        Observer.Expect('phone_no', 'Phone No.');
        Observer.Expect('vat_registration_no', 'VAT Registration No.');
        Observer.Expect('bank_name', 'Bank Name');
        Observer.Expect('iban', 'IBAN');
        Observer.Verify();
    end;
}
