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
        Observer.Observe(Label + '_2000000000', Describe(ObjectType, 2000000000));
    end;

    [Test]
    procedure LicensePermission_Table_UnusedNumbers()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        ObserveType(Observer, 'table', LicensePermission."Object Type"::Table);
        Observer.Finish();
    end;

    [Test]
    procedure LicensePermission_TableData_UnusedNumbers()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        ObserveType(Observer, 'tabledata', LicensePermission."Object Type"::TableData);
        Observer.Finish();
    end;

    [Test]
    procedure LicensePermission_XmlportQuery_UnusedNumbers()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        ObserveType(Observer, 'xmlport', LicensePermission."Object Type"::XMLport);
        ObserveType(Observer, 'query', LicensePermission."Object Type"::Query);
        Observer.Finish();
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
        Observer.Finish();
    end;
}
