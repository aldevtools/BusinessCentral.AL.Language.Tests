// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-fields
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); ALT Universal (table 60000); tableextension 69781 "LT U Customer Moved Ext" (record/lt-u-table-field-props/UTableMoved.al);
//                own table 90860, tableextension 90861, test codeunit 90863
// Probe: written for al-runtime-rs assumption field-row-system-id (writer Y2). platform/lt-wc/WcFieldRowCopy.al measured the SystemId of the Field rows of
//        one table numbered above 65535 (its field 2 and the user-name system fields) on BC 29 only. This file reads the SystemId of other Field rows:
//        a table numbered below 65536, a Base Application table (Customer), a tableextension field (on an own table and on Customer), a system table
//        (Company), the SystemId row (field 2000000000), the SystemCreatedAt row (2000000001) and the timestamp row (field 0), on every major.
// Facts: see the asserted values below.
// BC versions: 27, 28, 29

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
        Observer.Finish();
    end;

    [Test]
    procedure FieldRow_SystemId_BaseApplicationTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('18 field 1', Row(Database::Customer, 1));
        Observer.Observe('18 field 2', Row(Database::Customer, 2));
        Observer.Observe('18 field 2000000000', Row(Database::Customer, 2000000000));
        Observer.Finish();
    end;

    [Test]
    procedure FieldRow_SystemId_TableExtensionFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('own ext field', Row(Database::"LT Y2 FR Item", 90862));
        Observer.Observe('own base field 7', Row(Database::"LT Y2 FR Item", 7));
        Observer.Observe('customer ext field', Row(Database::Customer, 69583));
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure FieldRow_SystemId_SystemTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('company field 1', Row(Database::Company, 1));
        Observer.Observe('field table field 1', Row(Database::Field, 1));
        Observer.Finish();
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
        Observer.Observe('filter count', Format(Other.Count()));
        Observer.Finish();
    end;
}
