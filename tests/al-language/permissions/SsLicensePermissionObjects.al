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

    local procedure ObserveIsvNumbers(var Observer: Codeunit "Probe Observer"; Label: Text; ObjectType: Option)
    var
        Numbers: List of [Integer];
        N: Integer;
    begin
        // al-runner issue 6214 (last comment): numbers in the ISV and customer ranges below 99999999 that no other test names.
        Numbers.AddRange(50001, 60000, 70000000, 70000500, 74999999, 80000, 99999998, 99999999);
        foreach N in Numbers do begin
            Observer.Observe(Label + '_' + Format(N), Describe(ObjectType, N));
            Observer.Expect(Label + '_' + Format(N), AllYes());
        end;
    end;

    [Test]
    procedure LicensePermission_Table_IsvRangeNumbers()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        ObserveIsvNumbers(Observer, 'table', LicensePermission."Object Type"::Table);
        Observer.Verify();
    end;

    [Test]
    procedure LicensePermission_TableData_IsvRangeNumbers()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        ObserveIsvNumbers(Observer, 'tabledata', LicensePermission."Object Type"::TableData);
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

    local procedure ExpectedFor(Label: Text; ObjectNumber: Integer): Text
    begin
        // Numbers below the system range and at the very top have all-blank rows (0), the system range starts at 2000000000.
        case ObjectNumber of
            100000:
                exit('1/1/1/1/1');
            1999999999, 2147483647:
                exit('0/0/0/0/0');
            2000000000:
                begin
#if BC28PLUS
                    if Label = 'page' then
                        exit('0/0/0/0/1');
#endif
                    exit('1/1/1/1/1');
                end;
            2000000001:
                begin
#if BC28PLUS
                    if Label = 'page' then
                        exit('0/0/0/0/1');
#endif
                    if Label = 'table' then
                        exit('1/1/1/0/1');
                    exit('1/1/1/1/1');
                end;
        end;
    end;

    local procedure ObserveOne(var Observer: Codeunit "Probe Observer"; Label: Text; ObjectType: Option; ObjectNumber: Integer)
    begin
        Observer.Observe(Label + '_' + Format(ObjectNumber), Describe(ObjectType, ObjectNumber));
        Observer.Expect(Label + '_' + Format(ObjectNumber), ExpectedFor(Label, ObjectNumber));
    end;

    local procedure ObserveBoundary(var Observer: Codeunit "Probe Observer"; Label: Text; ObjectType: Option)
    begin
        ObserveOne(Observer, Label, ObjectType, 100000);
        ObserveOne(Observer, Label, ObjectType, 1999999999);
        ObserveOne(Observer, Label, ObjectType, 2000000000);
        ObserveOne(Observer, Label, ObjectType, 2000000001);
        ObserveOne(Observer, Label, ObjectType, 2147483647);
    end;

    [Test]
    procedure LicensePermission_Table_Top()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        ObserveBoundary(Observer, 'table', LicensePermission."Object Type"::Table);
        Observer.Verify();
    end;

    [Test]
    procedure LicensePermission_TableData_Top()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        ObserveBoundary(Observer, 'tabledata', LicensePermission."Object Type"::TableData);
        Observer.Verify();
    end;

    [Test]
    procedure LicensePermission_XmlportQuery_Top()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        ObserveBoundary(Observer, 'xmlport', LicensePermission."Object Type"::XMLport);
        ObserveBoundary(Observer, 'query', LicensePermission."Object Type"::Query);
        Observer.Verify();
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
        Observer.Verify();
    end;
}
