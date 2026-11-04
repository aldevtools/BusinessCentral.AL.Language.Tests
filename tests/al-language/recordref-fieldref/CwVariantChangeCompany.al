// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-changecompany-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 85444, codeunit 85445, test codeunit 85446 (creates and deletes
//   the company 'LT CW CHGCO'; creating a company takes about a minute on the Linux tier, see TestChangeCompanyFiltersCopyDeleteContracts.al)
// Probe: corpus #670 item 74 (writer CW; AL issues 7933 and 7810). A record moved to another company with ChangeCompany, then:
//   - assigned to a Variant and read back with RecordRef.GetTable(Variant) and Record := Variant: CurrentCompany, filters, Count;
//   - Variant := RecordRef (a RecordRef that took the record's company) and back;
//   - the Variant passed by var into an interface method that does RecordRef.GetTable on it.
// Results: Variant := Record drops the ChangeCompany company (RecordRef.GetTable(Variant) and Record := Variant are in the session
//   company; GetTable keeps the filters, Record := Variant does not); Variant := RecordRef keeps it; a Variant passed by var into an
//   interface method also loses it (AL issue 7933 still open in BC 29).
// BC versions: 27, 28, 29

table 85444 "LT CW Chg Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

interface "LT CW I74"
{
    procedure Describe(var V: Variant): Text;
}

codeunit 85445 "LT CW Impl 74" implements "LT CW I74"
{
    procedure Describe(var V: Variant): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(V);
        exit(RecRef.CurrentCompany() + '|' + Format(RecRef.Count()));
    end;
}

codeunit 85446 "LT CW Variant ChangeCompany"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        CompanyTok: Label 'LT CW CHGCO', Locked = true;

    local procedure InsertCompany()
    var
        Company: Record Company;
    begin
        if Company.Get(CompanyTok) then
            Company.Delete(true);
        Company.Init();
        Company.Name := CompanyTok;
        Company.Insert();
        Commit();
    end;

    local procedure DeleteCompany()
    var
        Company: Record Company;
        Home: Record "LT CW Chg Row";
    begin
        Home.DeleteAll();
        if Company.Get(CompanyTok) then
            Company.Delete(true);
        Commit();
    end;

    local procedure Where(Name: Text): Text
    begin
        if Name = CompanyName() then
            exit('session');
        if Name = CompanyTok then
            exit('other');
        exit('[' + Name + ']');
    end;

    [Test]
    procedure CW_Variant_KeepsOrDropsChangeCompany()
    var
        Observer: Codeunit "Probe Observer";
        Home: Record "LT CW Chg Row";
        Other: Record "LT CW Chg Row";
        Back: Record "LT CW Chg Row";
        Impl: Codeunit "LT CW Impl 74";
        I: Interface "LT CW I74";
        RecRef: RecordRef;
        RecRef2: RecordRef;
        V: Variant;
        Parts: List of [Text];
    begin
        InsertCompany();
        Home.DeleteAll();
        Home.Id := 1;
        Home.Insert();
        Other.ChangeCompany(CompanyTok);
        Other.DeleteAll();
        Other.Id := 1;
        Other.Insert();
        Other.Id := 2;
        Other.Insert();
        Other.Id := 3;
        Other.Insert();
        Commit();

        Other.SetFilter(Id, '>=2');
        Observer.Observe('record', Where(Other.CurrentCompany()) + '|' + Format(Other.Count()));
        V := Other;
        RecRef.GetTable(V);
        Observer.Observe('variant to recordref', Where(RecRef.CurrentCompany()) + '|' + Format(RecRef.Count()) + '|' + RecRef.GetFilters());
        Back := V;
        Observer.Observe('variant to record', Where(Back.CurrentCompany()) + '|' + Format(Back.Count()) + '|' + Back.GetFilters());
        RecRef.Close();

        RecRef.GetTable(Other);
        Observer.Observe('recordref direct', Where(RecRef.CurrentCompany()) + '|' + Format(RecRef.Count()));
        V := RecRef;
        RecRef2 := V;
        Observer.Observe('recordref variant', Where(RecRef2.CurrentCompany()) + '|' + Format(RecRef2.Count()));
        Clear(Back);
        RecRef2.SetTable(Back);
        Observer.Observe('recordref variant settable', Where(Back.CurrentCompany()) + '|' + Format(Back.Count()));

        V := Other;
        I := Impl;
        Parts := I.Describe(V).Split('|');
        Observer.Observe('interface var variant', Where(Parts.Get(1)) + '|' + Parts.Get(2));

        DeleteCompany();
        Observer.Expect('record', 'other|2');
        Observer.Expect('variant to recordref', 'session|0|Id: >=2');
        Observer.Expect('variant to record', 'session|1|');
        Observer.Expect('recordref direct', 'other|2');
        Observer.Expect('recordref variant', 'other|2');
        Observer.Expect('recordref variant settable', 'session|0');
        Observer.Expect('interface var variant', 'session|0');
        Observer.Verify();
    end;
}
