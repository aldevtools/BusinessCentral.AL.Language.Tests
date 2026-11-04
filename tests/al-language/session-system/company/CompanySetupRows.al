// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-area
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); no own fixtures; reads System Application tables "Application Area Setup" and "Experience Tier Setup" without writing
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: whether the company the tests run in holds a row in Application Area Setup and in Experience Tier Setup after Company-Initialize (read only), and which Boolean flags of those rows are set
// Settles docs/probes-needed.md row "Rows of Application Area Setup and Experience Tier Setup" (Queries: AboutTitle ... section)
// RISKY (own file): the field names "Company Name", "Profile ID", "User ID" of Application Area Setup are assumed; the second test of each table reads field values of rows other test codeunits may have changed
// BC versions: 29 (27 and 28 by CI)

codeunit 74306 "LT P166 Company Setup Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TrueBooleanFields(var RecRef: RecordRef): Text
    var
        FRef: FieldRef;
        i: Integer;
        Names: Text;
        Count: Integer;
    begin
        for i := 1 to RecRef.FieldCount() do begin
            FRef := RecRef.FieldIndex(i);
            if FRef.Type() = FieldType::Boolean then
                if FRef.Value() then begin
                    Count += 1;
                    if StrLen(Names) < 700 then
                        Names += FRef.Name() + ',';
                end;
        end;
        exit(Format(Count) + '|' + Names);
    end;

    [Test]
    procedure ExperienceTierSetup_RowOfTheCompany_Exists()
    var
        Observer: Codeunit "Probe Observer";
        Tier: Record "Experience Tier Setup";
    begin
        Observer.Observe('anyRow', Format(not Tier.IsEmpty()));
        Observer.Observe('getCompanyRow', Format(Tier.Get(CompanyName())));
        Observer.Observe('allRows', Format(Tier.Count()));
        Observer.Expect('anyRow', 'Yes');
        Observer.Expect('getCompanyRow', 'Yes');
        Observer.Expect('allRows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure ExperienceTierSetup_RowOfTheCompany_Flags()
    var
        Observer: Codeunit "Probe Observer";
        Tier: Record "Experience Tier Setup";
        RecRef: RecordRef;
    begin
        if Tier.Get(CompanyName()) then begin
            RecRef.GetTable(Tier);
            Observer.Observe('flags', TrueBooleanFields(RecRef));
            Observer.Observe('basic', Format(Tier.Basic));
            Observer.Observe('essential', Format(Tier.Essential));
            Observer.Observe('custom', Format(Tier.Custom));
        end else
            Observer.Observe('flags', 'no row');
        Observer.Expect('flags', '1|Essential,');
        Observer.Expect('basic', 'No');
        Observer.Expect('essential', 'Yes');
        Observer.Expect('custom', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ApplicationAreaSetup_RowsOfTheCompany_Exist()
    var
        Observer: Codeunit "Probe Observer";
        AreaSetup: Record "Application Area Setup";
    begin
        Observer.Observe('anyRow', Format(not AreaSetup.IsEmpty()));
        AreaSetup.SetRange("Company Name", CompanyName());
        Observer.Observe('rowsOfThisCompany', Format(AreaSetup.Count()));
        AreaSetup.SetRange("Profile ID", '');
        AreaSetup.SetRange("User ID", '');
        Observer.Observe('companyWideRows', Format(AreaSetup.Count()));
        Observer.Expect('anyRow', 'Yes');
        Observer.Expect('rowsOfThisCompany', '1');
        Observer.Expect('companyWideRows', '1');
        Observer.Verify();
    end;
}
