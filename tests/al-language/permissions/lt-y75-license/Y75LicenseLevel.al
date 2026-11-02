// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: al-runtime-rs ADR-060 decision 6 (license level in a permission check), stage 5 of ADR-062. Observe only, no asserted values:
//   the CI containers run the Cronus license (all Yes), so the License Permission rows and the denials below can only differ on an
//   environment with another license. Used to read what a restricted license (BC SaaS Dev sandbox) gives.
// BC versions: 27-29

codeunit 94000 "LT Y75 License Level"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(ObjectType: Integer; ObjectNumber: Integer): Text
    var
        LicensePermission: Record "License Permission";
    begin
        if not LicensePermission.Get(ObjectType, ObjectNumber) then
            exit('no row');
        exit(Format(LicensePermission."Read Permission", 0, 9) + '/' + Format(LicensePermission."Insert Permission", 0, 9) + '/' +
            Format(LicensePermission."Modify Permission", 0, 9) + '/' + Format(LicensePermission."Delete Permission", 0, 9) + '/' +
            Format(LicensePermission."Execute Permission", 0, 9) + '/' + Format(LicensePermission."Limited Usage Permission", 0, 9));
    end;

    [Test]
    procedure Y75_LicenseRows()
    var
        Observer: Codeunit "Probe Observer";
        Numbers: List of [Integer];
        N: Integer;
    begin
        Numbers.AddRange(15, 17, 18, 21, 25, 32, 36, 37, 45, 81, 112, 113, 169, 203, 254, 271, 379, 380, 5802, 5625, 7312, 94000, 94001, 99999, 100000, 2000000000);
        foreach N in Numbers do
            Observer.Observe('tabledata_' + Format(N), Describe(0, N));
        Numbers.RemoveRange(1, Numbers.Count());
        Numbers.AddRange(1, 80, 231, 5800, 94000, 94001, 99999, 100000);
        foreach N in Numbers do
            Observer.Observe('codeunit_' + Format(N), Describe(5, N));
        Numbers.RemoveRange(1, Numbers.Count());
        Numbers.AddRange(21, 22, 30, 94000, 94001, 99999);
        foreach N in Numbers do
            Observer.Observe('page_' + Format(N), Describe(8, N));
        Numbers.RemoveRange(1, Numbers.Count());
        Numbers.AddRange(1, 206, 94000, 99999);
        foreach N in Numbers do
            Observer.Observe('report_' + Format(N), Describe(3, N));
        Observer.Observe('table_17', Describe(1, 17));
        Observer.Observe('table_94000', Describe(1, 94000));
        Observer.Observe('system_2000000043', Describe(10, 2000000043));
        Observer.Finish();
    end;

    [Test]
    procedure Y75_Operations()
    var
        Observer: Codeunit "Probe Observer";
        Direct: Codeunit "LT Y75 Direct";
        Indirect: Codeunit "LT Y75 Indirect";
        GLEntry: Record "G/L Entry";
        Row: Record "LT Y75 Row";
        Cust: Record Customer;
    begin
        Observer.Observe('gl_read_permission', Format(GLEntry.ReadPermission()));
        Observer.Observe('gl_write_permission', Format(GLEntry.WritePermission()));
        Observer.Observe('cust_write_permission', Format(Cust.WritePermission()));
        Observer.Observe('row_write_permission', Format(Row.WritePermission()));
        asserterror Direct.InsertGL();
        Observer.ObserveError('direct_insert_gl_entry');
        asserterror Indirect.InsertGL();
        Observer.ObserveError('indirect_insert_gl_entry');
        asserterror Direct.InsertRow();
        Observer.ObserveError('direct_insert_own_row');
        asserterror Direct.RunCodeunit();
        Observer.ObserveError('run_codeunit_80');
        asserterror Direct.OpenPage();
        Observer.ObserveError('run_page_21');
        asserterror Direct.RunReportSave();
        Observer.ObserveError('save_report_1');
        Observer.Finish();
    end;
}

table 94000 "LT Y75 Row"
{
    fields
    {
        field(1; "No."; Integer) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 94001 "LT Y75 Direct"
{
    procedure InsertGL()
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry."Entry No." := 2147000001;
        GLEntry.Insert();
        Error('LT Y75 ok');
    end;

    procedure InsertRow()
    var
        Row: Record "LT Y75 Row";
    begin
        Row."No." := 1;
        Row.Insert();
        Error('LT Y75 ok');
    end;

    procedure RunCodeunit()
    begin
        Codeunit.Run(80);
        Error('LT Y75 ok');
    end;

    procedure OpenPage()
    var
        Pg: TestPage "Customer List";
    begin
        Pg.OpenView();
        Pg.Close();
        Error('LT Y75 ok');
    end;

    procedure RunReportSave()
    var
        OutS: OutStream;
        TempBlob: Codeunit "Temp Blob";
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(Report::"Trial Balance", '', ReportFormat::Xml, OutS);
        Error('LT Y75 ok');
    end;
}

codeunit 94002 "LT Y75 Indirect"
{
    Permissions = tabledata "G/L Entry" = rimd;

    procedure InsertGL()
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry."Entry No." := 2147000002;
        GLEntry.Insert();
        Error('LT Y75 ok');
    end;
}
