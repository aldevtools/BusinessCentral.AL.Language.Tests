// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 95573 and test codeunit 95574
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced
//   (al-runner issue 6995: a not-equal exclusion filter on FieldName of the Field table).
// Facts: the rows of the Field table of an own table (three fields, the system fields and the timestamp row) under a filter on FieldName
//   that is not an equality: `<>A&<>B&<>C&<>D` with the four audit field names, with and without the Class, Enabled and ObsoleteState
//   filters of the issue; a single `<>x` with a placeholder and as a literal; `<>timestamp`; `<>''`; `>x`; a range. Each row prints as
//   `No.:FieldName`, in the order FindSet reads them (rows from 2000000005 on, which BC 29 adds, are left out); whether the timestamp row (No. 0) is among them is the question of the issue.
// BC versions: 27, 28, 29

table 95573 "LT R6 Field Probe"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 95574 "LT R6 Field Name Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Rows(var Fld: Record Field): Text
    var
        Result: Text;
    begin
        if not Fld.FindSet() then
            exit('none');
        repeat
            // The rows from 2000000005 on (SystemCreatedByUserName and the like) exist from BC 29 on: left out here.
            if Fld."No." < 2000000005 then begin
                if Result <> '' then
                    Result += ' ';
                Result += Format(Fld."No.") + ':' + Fld.FieldName;
            end;
        until Fld.Next() = 0;
        exit(Result);
    end;

    local procedure Base(var Fld: Record Field)
    begin
        Fld.Reset();
        Fld.SetRange(TableNo, Database::"LT R6 Field Probe");
    end;

    [Test]
    procedure NotEqual_FourAuditNames()
    var
        Observer: Codeunit "Probe Observer";
        Fld: Record Field;
    begin
        Base(Fld);
        Observer.Observe('all rows', Rows(Fld));
        Fld.SetFilter(FieldName, '<>%1&<>%2&<>%3&<>%4', 'SystemCreatedAt', 'SystemModifiedAt', 'SystemCreatedBy', 'SystemModifiedBy');
        Observer.Observe('four audit names', Rows(Fld));
        Fld.SetRange(Class, Fld.Class::Normal);
        Fld.SetRange(Enabled, true);
        Fld.SetRange(ObsoleteState, Fld.ObsoleteState::No);
        Observer.Observe('four audit names, Class Enabled ObsoleteState', Rows(Fld));
        Observer.Observe('four audit names, Class Enabled ObsoleteState count', Format(Fld.Count()));
        Observer.Expect('all rows', '1:Code 2:Name 3:Amount 2000000000:$systemId 2000000001:SystemCreatedAt 2000000002:SystemCreatedBy 2000000003:SystemModifiedAt 2000000004:SystemModifiedBy');
        Observer.Expect('four audit names', '1:Code 2:Name 3:Amount 2000000000:$systemId');
        Observer.Expect('four audit names, Class Enabled ObsoleteState', '1:Code 2:Name 3:Amount 2000000000:$systemId');
        Observer.Expect('four audit names, Class Enabled ObsoleteState count', '4');
        Observer.Verify();
    end;

    [Test]
    procedure NotEqual_OneName()
    var
        Observer: Codeunit "Probe Observer";
        Fld: Record Field;
    begin
        Base(Fld);
        Fld.SetFilter(FieldName, '<>%1', 'Name');
        Observer.Observe('placeholder Name', Rows(Fld));
        Fld.SetFilter(FieldName, '<>Name');
        Observer.Observe('literal Name', Rows(Fld));
        Fld.SetFilter(FieldName, '<>%1', 'timestamp');
        Observer.Observe('placeholder timestamp', Rows(Fld));
        Fld.SetFilter(FieldName, '<>%1&<>%2', 'Code', 'timestamp');
        Observer.Observe('Code and timestamp', Rows(Fld));
        Fld.SetFilter(FieldName, '<>%1', '');
        Observer.Observe('not blank', Rows(Fld));
        Observer.Expect('placeholder Name', '1:Code 3:Amount 2000000000:$systemId 2000000001:SystemCreatedAt 2000000002:SystemCreatedBy 2000000003:SystemModifiedAt 2000000004:SystemModifiedBy');
        Observer.Expect('literal Name', '1:Code 3:Amount 2000000000:$systemId 2000000001:SystemCreatedAt 2000000002:SystemCreatedBy 2000000003:SystemModifiedAt 2000000004:SystemModifiedBy');
        Observer.Expect('placeholder timestamp', '1:Code 2:Name 3:Amount 2000000000:$systemId 2000000001:SystemCreatedAt 2000000002:SystemCreatedBy 2000000003:SystemModifiedAt 2000000004:SystemModifiedBy');
        Observer.Expect('Code and timestamp', '2:Name 3:Amount 2000000000:$systemId 2000000001:SystemCreatedAt 2000000002:SystemCreatedBy 2000000003:SystemModifiedAt 2000000004:SystemModifiedBy');
        Observer.Expect('not blank', '1:Code 2:Name 3:Amount 2000000000:$systemId 2000000001:SystemCreatedAt 2000000002:SystemCreatedBy 2000000003:SystemModifiedAt 2000000004:SystemModifiedBy');
        Observer.Verify();
    end;

    [Test]
    procedure OtherOperators()
    var
        Observer: Codeunit "Probe Observer";
        Fld: Record Field;
    begin
        Base(Fld);
        Fld.SetFilter(FieldName, '>%1', 'Name');
        Observer.Observe('greater than Name', Rows(Fld));
        Fld.SetFilter(FieldName, '<%1', 'Name');
        Observer.Observe('less than Name', Rows(Fld));
        Fld.SetFilter(FieldName, '%1..%2', 'A', 'z');
        Observer.Observe('range A..z', Rows(Fld));
        Observer.Expect('greater than Name', '2000000001:SystemCreatedAt 2000000002:SystemCreatedBy 2000000003:SystemModifiedAt 2000000004:SystemModifiedBy');
        Observer.Expect('less than Name', '1:Code 3:Amount 2000000000:$systemId');
        Observer.Expect('range A..z', '1:Code 2:Name 3:Amount 2000000001:SystemCreatedAt 2000000002:SystemCreatedBy 2000000003:SystemModifiedAt 2000000004:SystemModifiedBy');
        Observer.Verify();
    end;
}
