// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: rows of the system table License Permission (2000000043) for Codeunit objects and a sample of other object types, read by key and by
// filter on the fresh tenant of a test container. A Count over the whole table takes minutes (see platform/lt-platform-rows-fresh), so only
// keyed reads and narrow filters are used.
// Facts: whether Codeunit 410 and other objects, the app's own objects included, have a row; the permission columns of those rows.
// BC versions: 27-29

codeunit 78401 "LT AG License Permission"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Describe(ObjectType: Option; ObjectNumber: Integer): Text
    var
        LicensePermission: Record "License Permission";
    begin
        if not LicensePermission.Get(ObjectType, ObjectNumber) then
            exit('no row');
        exit('Read=' + Format(LicensePermission."Read Permission") + ' Insert=' + Format(LicensePermission."Insert Permission") + ' Modify=' + Format(LicensePermission."Modify Permission") + ' Delete=' + Format(LicensePermission."Delete Permission") + ' Execute=' + Format(LicensePermission."Execute Permission") + ' Limited=' + Format(LicensePermission."Limited Usage Permission"));
    end;

    local procedure Ids(var LicensePermission: Record "License Permission"): Text
    var
        Result: Text;
    begin
        if LicensePermission.FindSet() then
            repeat
                Result += Format(LicensePermission."Object Number") + ',';
            until LicensePermission.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure LicensePermission_CodeunitRows_ByKey()
    var
        LicensePermission: Record "License Permission";
    begin
        Observer.Observe('codeunit_410', Describe(LicensePermission."Object Type"::Codeunit, 410));
        Observer.Observe('codeunit_1', Describe(LicensePermission."Object Type"::Codeunit, 1));
        Observer.Observe('codeunit_80', Describe(LicensePermission."Object Type"::Codeunit, 80));
        Observer.Observe('codeunit_99999999', Describe(LicensePermission."Object Type"::Codeunit, 99999999));
        Observer.Observe('codeunit_own_78401', Describe(LicensePermission."Object Type"::Codeunit, 78401));
        Observer.Observe('table_18', Describe(LicensePermission."Object Type"::Table, 18));
        Observer.Observe('tabledata_18', Describe(LicensePermission."Object Type"::TableData, 18));
        Observer.Observe('page_21', Describe(LicensePermission."Object Type"::Page, 21));
        Observer.Observe('report_1', Describe(LicensePermission."Object Type"::Report, 1));
        Observer.Observe('xmlport_1', Describe(LicensePermission."Object Type"::XMLport, 1));
        Observer.Observe('query_1', Describe(LicensePermission."Object Type"::Query, 1));
        Observer.Observe('system_1', Describe(LicensePermission."Object Type"::System, 1));
        Observer.Expect('codeunit_410', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('codeunit_1', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('codeunit_80', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('codeunit_99999999', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('codeunit_own_78401', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('table_18', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('tabledata_18', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('page_21', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('report_1', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('xmlport_1', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('query_1', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('system_1', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Verify();
    end;

    [Test]
    procedure LicensePermission_CodeunitRows_ByFilter()
    var
        LicensePermission: Record "License Permission";
    begin
        LicensePermission.SetRange("Object Type", LicensePermission."Object Type"::Codeunit);
        LicensePermission.SetRange("Object Number", 410);
        Observer.Observe('codeunit_410_count', Format(LicensePermission.Count()));
        LicensePermission.SetRange("Object Number", 400, 420);
        Observer.Observe('codeunit_400_420_ids', Ids(LicensePermission));
        LicensePermission.SetRange("Object Number", 1, 5);
        Observer.Observe('codeunit_1_5_ids', Ids(LicensePermission));
        LicensePermission.SetRange("Object Number", 78400, 78402);
        Observer.Observe('codeunit_own_ids', Ids(LicensePermission));
        Observer.Expect('codeunit_410_count', '1');
        Observer.Expect('codeunit_400_420_ids', '400,401,402,403,404,405,406,407,408,409,410,411,412,413,414,415,416,417,418,419,420,');
        Observer.Expect('codeunit_1_5_ids', '1,2,3,4,5,');
        Observer.Expect('codeunit_own_ids', '78400,78401,78402,');
        Observer.Verify();
    end;

    // UQ (al-runner 6214): keyed reads of object numbers in the customer range, the ISV range and the 50000-99999 range.
    [Test]
    procedure LicensePermission_ByKey_CustomerAndIsvRanges()
    var
        LicensePermission: Record "License Permission";
    begin
        Observer.Observe('codeunit_50000', Describe(LicensePermission."Object Type"::Codeunit, 50000));
        Observer.Observe('codeunit_50123', Describe(LicensePermission."Object Type"::Codeunit, 50123));
        Observer.Observe('codeunit_99999', Describe(LicensePermission."Object Type"::Codeunit, 99999));
        Observer.Observe('codeunit_70000123', Describe(LicensePermission."Object Type"::Codeunit, 70000123));
        Observer.Observe('table_70000123', Describe(LicensePermission."Object Type"::Table, 70000123));
        Observer.Observe('tabledata_70000123', Describe(LicensePermission."Object Type"::TableData, 70000123));
        Observer.Observe('page_50100', Describe(LicensePermission."Object Type"::Page, 50100));
        Observer.Observe('report_70000001', Describe(LicensePermission."Object Type"::Report, 70000001));
        Observer.Observe('codeunit_2000000000', Describe(LicensePermission."Object Type"::Codeunit, 2000000000));
        Observer.Observe('codeunit_0', Describe(LicensePermission."Object Type"::Codeunit, 0));
        Observer.Observe('codeunit_neg1', Describe(LicensePermission."Object Type"::Codeunit, -1));
        Observer.Observe('table_50000', Describe(LicensePermission."Object Type"::Table, 50000));
        Observer.Expect('codeunit_50000', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('codeunit_50123', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('codeunit_99999', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('codeunit_70000123', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('table_70000123', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('tabledata_70000123', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('page_50100', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('report_70000001', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('codeunit_2000000000', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('codeunit_0', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('codeunit_neg1', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Expect('table_50000', 'Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
        Observer.Verify();
    end;
}
