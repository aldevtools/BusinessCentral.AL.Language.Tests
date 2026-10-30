// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: License Permission read by key for every object type at numbers in the customer range (50000-99999), the ISV range
// (70000000+) and the top of the range, none of them an object of this app. Facts: whether a row exists and its permission columns.

codeunit 99840 "LT SS License Permission"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(ObjectType: Option; ObjectNumber: Integer): Text
    var
        LicensePermission: Record "License Permission";
    begin
        if not LicensePermission.Get(ObjectType, ObjectNumber) then
            exit('no row');
        exit('Read=' + Format(LicensePermission."Read Permission") + ' Insert=' + Format(LicensePermission."Insert Permission") + ' Modify=' + Format(LicensePermission."Modify Permission") + ' Delete=' + Format(LicensePermission."Delete Permission") + ' Execute=' + Format(LicensePermission."Execute Permission") + ' Limited=' + Format(LicensePermission."Limited Usage Permission"));
    end;

    local procedure ObserveType(var Observer: Codeunit "Probe Observer"; Label: Text; ObjectType: Option)
    begin
        Observer.Observe(Label + '_50123', Describe(ObjectType, 50123));
        Observer.Observe(Label + '_99999', Describe(ObjectType, 99999));
        Observer.Observe(Label + '_70000456', Describe(ObjectType, 70000456));
        Observer.Expect(Label + '_50123', AllYes());
        Observer.Expect(Label + '_99999', AllYes());
        Observer.Expect(Label + '_70000456', AllYes());
    end;

    local procedure AllYes(): Text
    begin
        exit('Read=Yes Insert=Yes Modify=Yes Delete=Yes Execute=Yes Limited= ');
    end;

    [Test]
    procedure LicensePermission_Table_UnusedNumbers()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        ObserveType(Observer, 'table', LicensePermission."Object Type"::Table);
        Observer.Verify();
    end;

    [Test]
    procedure LicensePermission_TableData_UnusedNumbers()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        ObserveType(Observer, 'tabledata', LicensePermission."Object Type"::TableData);
        Observer.Verify();
    end;

    [Test]
    procedure LicensePermission_XmlportQuery_UnusedNumbers()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        ObserveType(Observer, 'xmlport', LicensePermission."Object Type"::XMLport);
        ObserveType(Observer, 'query', LicensePermission."Object Type"::Query);
        Observer.Verify();
    end;

    [Test]
    procedure LicensePermission_PageReportCodeunit_UnusedNumbers()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        ObserveType(Observer, 'page', LicensePermission."Object Type"::Page);
        ObserveType(Observer, 'report', LicensePermission."Object Type"::Report);
        ObserveType(Observer, 'codeunit', LicensePermission."Object Type"::Codeunit);
        Observer.Verify();
    end;
}

// Observed first, then turned into expectations (numbers at and past the top of the object range).
codeunit 99841 "LT SS License Permission Top"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
    local procedure Describe(ObjectType: Option; ObjectNumber: Integer): Text
    var
        LicensePermission: Record "License Permission";
    begin
        if not LicensePermission.Get(ObjectType, ObjectNumber) then
            exit('no row');
        exit(Format(LicensePermission."Read Permission", 0, 9) + '/' + Format(LicensePermission."Insert Permission", 0, 9) + '/' + Format(LicensePermission."Modify Permission", 0, 9) + '/' + Format(LicensePermission."Delete Permission", 0, 9) + '/' + Format(LicensePermission."Execute Permission", 0, 9));
    end;

    local procedure ObserveBoundary(var Observer: Codeunit "Probe Observer"; Label: Text; ObjectType: Option)
    begin
        Observer.Observe(Label + '_100000', Describe(ObjectType, 100000));
        Observer.Observe(Label + '_1999999999', Describe(ObjectType, 1999999999));
        Observer.Observe(Label + '_2000000000', Describe(ObjectType, 2000000000));
        Observer.Observe(Label + '_2000000001', Describe(ObjectType, 2000000001));
        Observer.Observe(Label + '_2147483647', Describe(ObjectType, 2147483647));
    end;

    [Test]
    procedure LicensePermission_Table_Top()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        ObserveBoundary(Observer, 'table', LicensePermission."Object Type"::Table);
        Observer.Finish();
    end;

    [Test]
    procedure LicensePermission_TableData_Top()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        ObserveBoundary(Observer, 'tabledata', LicensePermission."Object Type"::TableData);
        Observer.Finish();
    end;

    [Test]
    procedure LicensePermission_XmlportQuery_Top()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        ObserveBoundary(Observer, 'xmlport', LicensePermission."Object Type"::XMLport);
        ObserveBoundary(Observer, 'query', LicensePermission."Object Type"::Query);
        Observer.Finish();
    end;

    [Test]
    procedure LicensePermission_PageReportCodeunit_Top()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        ObserveBoundary(Observer, 'page', LicensePermission."Object Type"::Page);
        ObserveBoundary(Observer, 'report', LicensePermission."Object Type"::Report);
        ObserveBoundary(Observer, 'codeunit', LicensePermission."Object Type"::Codeunit);
        Observer.Finish();
    end;
}
