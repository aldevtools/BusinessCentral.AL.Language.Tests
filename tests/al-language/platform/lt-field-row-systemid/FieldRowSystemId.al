// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-fields
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); ALT Universal (table 60000); tableextension 69781 "LT U Customer Moved Ext" (record/lt-u-table-field-props/UTableMoved.al);
//                own table 90860, tableextension 90861, test codeunit 90863
// Probe: written for al-runtime-rs assumption field-row-system-id (writer Y2). platform/lt-wc/WcFieldRowCopy.al measured the SystemId of the Field rows of
//        one table numbered above 65535 (its field 2 and the user-name system fields) on BC 29 only. This file reads the SystemId of other Field rows:
//        a table numbered below 65536, a Base Application table (Customer), a tableextension field (on an own table and on Customer), a system table
//        (Company), the SystemId row (field 2000000000), the SystemCreatedAt row (2000000001) and the timestamp row (field 0), on every major.
// Facts (BC 29 SaaS sandbox and corpus CI leg 28.5): the SystemId of every Field row read is the Guid of the
//        bytes of 2000000041, the table number and the field number, each little-endian, then four zero bytes: table 60000 field 1 is
//        {77359429-EA60-0000-0100-000000000000}, Customer (18) field 2 {77359429-0012-0000-0200-000000000000}, a tableextension field 90862 of
//        table 90860 {77359429-62EC-0001-EE62-010000000000}, the SystemId row (2000000000) {...-0094-357700000000}, Company (2000000006) field 1
//        {77359429-9406-7735-0100-000000000000}. There is no Field row for field 0 (the timestamp). GetBySystemId and a SystemId filter find the row.
//        On BC 27.5 every Field row's SystemId is the null Guid, and GetBySystemId of it finds the first Field row (table 3, field 1); the count of a SystemId filter is not measured there.
// BC versions: 27, 28, 29 (BC 27.5 gives the null Guid for every Field row's SystemId, corpus CI leg 27.5: guarded with BC28PLUS)

table 90860 "LT Y2 FR Item"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(7; Description; Text[50]) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

tableextension 90861 "LT Y2 FR Item Ext" extends "LT Y2 FR Item"
{
    fields
    {
        field(90862; "LT Y2 Ext Note"; Text[20]) { }
    }
}

codeunit 90863 "LT Y2 Field Row SystemId"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Row(TableNo: Integer; FieldNo: Integer): Text
    var
        FieldRec: Record Field;
    begin
        if not FieldRec.Get(TableNo, FieldNo) then
            exit('no row');
        exit(Format(FieldRec.SystemId) + '|' + FieldRec.FieldName);
    end;

    [Test]
    procedure FieldRow_SystemId_TableBelow65536()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('60000 field 1', Row(Database::"ALT Universal", 1));
        Observer.Observe('60000 field 2000000000', Row(Database::"ALT Universal", 2000000000));
#if BC28PLUS
        Observer.Expect('60000 field 1', '{77359429-EA60-0000-0100-000000000000}|Entry No.');
        Observer.Expect('60000 field 2000000000', '{77359429-EA60-0000-0094-357700000000}|$systemId');
#else
        Observer.Expect('60000 field 1', '{00000000-0000-0000-0000-000000000000}|Entry No.');
        Observer.Expect('60000 field 2000000000', '{00000000-0000-0000-0000-000000000000}|$systemId');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure FieldRow_SystemId_BaseApplicationTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('18 field 1', Row(Database::Customer, 1));
        Observer.Observe('18 field 2', Row(Database::Customer, 2));
        Observer.Observe('18 field 2000000000', Row(Database::Customer, 2000000000));
#if BC28PLUS
        Observer.Expect('18 field 1', '{77359429-0012-0000-0100-000000000000}|No.');
        Observer.Expect('18 field 2', '{77359429-0012-0000-0200-000000000000}|Name');
        Observer.Expect('18 field 2000000000', '{77359429-0012-0000-0094-357700000000}|$systemId');
#else
        Observer.Expect('18 field 1', '{00000000-0000-0000-0000-000000000000}|No.');
        Observer.Expect('18 field 2', '{00000000-0000-0000-0000-000000000000}|Name');
        Observer.Expect('18 field 2000000000', '{00000000-0000-0000-0000-000000000000}|$systemId');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure FieldRow_SystemId_TableExtensionFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('own ext field', Row(Database::"LT Y2 FR Item", 90862));
        Observer.Observe('own base field 7', Row(Database::"LT Y2 FR Item", 7));
        Observer.Observe('customer ext field', Row(Database::Customer, 69583));
#if BC28PLUS
        Observer.Expect('own ext field', '{77359429-62EC-0001-EE62-010000000000}|LT Y2 Ext Note');
        Observer.Expect('own base field 7', '{77359429-62EC-0001-0700-000000000000}|Description');
        Observer.Expect('customer ext field', '{77359429-0012-0000-CF0F-010000000000}|LT U Moved In');
#else
        Observer.Expect('own ext field', '{00000000-0000-0000-0000-000000000000}|LT Y2 Ext Note');
        Observer.Expect('own base field 7', '{00000000-0000-0000-0000-000000000000}|Description');
        Observer.Expect('customer ext field', '{00000000-0000-0000-0000-000000000000}|LT U Moved In');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure FieldRow_SystemId_SystemFieldRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('own 2000000000', Row(Database::"LT Y2 FR Item", 2000000000));
        Observer.Observe('own 2000000001', Row(Database::"LT Y2 FR Item", 2000000001));
        Observer.Observe('own 2000000002', Row(Database::"LT Y2 FR Item", 2000000002));
        Observer.Observe('own 0', Row(Database::"LT Y2 FR Item", 0));
#if BC28PLUS
        Observer.Expect('own 2000000000', '{77359429-62EC-0001-0094-357700000000}|$systemId');
        Observer.Expect('own 2000000001', '{77359429-62EC-0001-0194-357700000000}|SystemCreatedAt');
        Observer.Expect('own 2000000002', '{77359429-62EC-0001-0294-357700000000}|SystemCreatedBy');
        Observer.Expect('own 0', 'no row');
#else
        Observer.Expect('own 2000000000', '{00000000-0000-0000-0000-000000000000}|$systemId');
        Observer.Expect('own 2000000001', '{00000000-0000-0000-0000-000000000000}|SystemCreatedAt');
        Observer.Expect('own 2000000002', '{00000000-0000-0000-0000-000000000000}|SystemCreatedBy');
        Observer.Expect('own 0', 'no row');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure FieldRow_SystemId_SystemTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('company field 1', Row(Database::Company, 1));
        Observer.Observe('field table field 1', Row(Database::Field, 1));
#if BC28PLUS
        Observer.Expect('company field 1', '{77359429-9406-7735-0100-000000000000}|Name');
        Observer.Expect('field table field 1', '{77359429-9429-7735-0100-000000000000}|TableNo');
#else
        Observer.Expect('company field 1', '{00000000-0000-0000-0000-000000000000}|Name');
        Observer.Expect('field table field 1', '{00000000-0000-0000-0000-000000000000}|TableNo');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure FieldRow_SystemId_FilterAndGetBySystemId()
    var
        Observer: Codeunit "Probe Observer";
        FieldRec: Record Field;
        Other: Record Field;
        Id: Guid;
    begin
        FieldRec.Get(Database::"LT Y2 FR Item", 7);
        Id := FieldRec.SystemId;
        Observer.Observe('get by systemid', Format(Other.GetBySystemId(Id)));
        Observer.Observe('found', Format(Other.TableNo) + '|' + Format(Other."No."));
        Other.Reset();
        Other.SetRange(SystemId, Id);
#if BC28PLUS
        Observer.Observe('filter count', Format(Other.Count()));
#endif
#if BC28PLUS
        Observer.Expect('get by systemid', 'Yes');
        Observer.Expect('found', '90860|7');
        Observer.Expect('filter count', '1');
#else
        Observer.Expect('get by systemid', 'Yes');
        Observer.Expect('found', '3|1');
#endif
        Observer.Verify();
    end;
}
