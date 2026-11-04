// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-permissions
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Permissions Mock (131006) from the dependency; own table 86450.
// Probe: writer QC, for the al-runtime-rs assumption runner-permission-sets-grant-all. Microsoft's Base Application test runner calls
//   codeunit 130302 "Set State Test Run" before each test codeunit; it calls "Permission Test Catalog".InitializePermissionSetForTest,
//   which (for a codeunit whose TestPermissions is not Disabled) runs "Library - Lower Permissions".StartLoggingNAVPermissions('D365 Full Access'):
//   Permissions Mock Start(), Set('D365 Full Access') (Set clears the effective sets, then assigns "All Objects" and the named set),
//   Assign('Test Tables'), Assign('D365 Basic') and, when a permission set LOCAL exists, Assign('LOCAL').
//   These tests make the same calls (skipping a set that does not exist in the corpus database, observed first) and then read and
//   write a Base Application table, a system table and a table of the test app, and read ReadPermission, WritePermission and
//   "User Permissions".GetEffectivePermission (NavUserAccountHelper.GetEffectivePermissionForObject).
//   Writes run inside asserterror and end with an own error, so they are rolled back and leave no rows in Microsoft tables.
//   Written against a local BC 29.0 service tier; every literal below is what that tier produced; 27.5 and 28.5 by the CI matrix.
// Facts (BC 29.0): "Test Tables" does not exist in the corpus database (it ships in Microsoft's Tests-TestLibraries app); All Objects,
//   D365 Full Access, D365 Basic and LOCAL do. Under the runner sets:
//   - Base Application tables (Company Information, Standard Text): read and write are allowed; ReadPermission and WritePermission
//     are true; GetEffectivePermission gives Yes for read, insert, modify and delete.
//   - System tables: AllObj and Access Control read and write; Tenant Media has only indirect insert, modify and delete: WritePermission is
//     false and an insert fails with "Sorry, the current permissions prevented the action. (TableData 2000000184 Tenant Media Insert: ...)".
//   - A table of the test app that no assigned set names: ReadPermission and WritePermission are false, FindFirst fails with
//     DB:ClientReadDenied and Insert with DB:ClientInsertDenied; GetEffectivePermission gives nothing for its table data and only
//     Execute for the table and the test codeunit (from All Objects). Without the mock everything is allowed.
//   So the runner sets do NOT grant everything: they grant what D365 Full Access, D365 Basic and LOCAL name, plus Execute on every object.
// BC versions: 27, 28, 29

table 86450 "LT QC Perm Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 86450 "LT QC Runner Sets Tests"
{
    Subtype = Test;

    var
        RollbackErr: Label 'LT QC rolled back', Locked = true;

    local procedure SetExists(RoleId: Code[20]): Boolean
    var
#pragma warning disable AL0432
        PermissionSet: Record "Permission Set";
#pragma warning restore AL0432
    begin
        exit(PermissionSet.Get(RoleId));
    end;

    // The calls of Library - Lower Permissions.StartLoggingNAVPermissions('D365 Full Access').
    local procedure ApplyRunnerSets(var Mock: Codeunit "Permissions Mock") WasStarted: Boolean
    begin
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
        Mock.Set('D365 Full Access');
        if SetExists('Test Tables') then
            Mock.Assign('Test Tables');
        Mock.Assign('D365 Basic');
        if SetExists('LOCAL') then
            Mock.Assign('LOCAL');
    end;

    local procedure RestoreMock(var Mock: Codeunit "Permissions Mock"; WasStarted: Boolean)
    begin
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
    end;

    local procedure Rights(ObjectType: Option "Table Data","Table",,"Report",,"Codeunit","XMLport",MenuSuite,"Page","Query","System",,,,,,,,,; ObjectId: Integer): Text
    var
        UserPermissions: Codeunit "User Permissions";
        Expanded: Record "Expanded Permission" temporary;
    begin
        Expanded := UserPermissions.GetEffectivePermission(ObjectType, ObjectId);
        exit(Format(Expanded."Read Permission") + ',' + Format(Expanded."Insert Permission") + ',' + Format(Expanded."Modify Permission") + ',' +
            Format(Expanded."Delete Permission") + ',' + Format(Expanded."Execute Permission"));
    end;

    local procedure SeedOwn()
    var
        Row: Record "LT QC Perm Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
    end;

    local procedure WriteStandardText()
    var
        StandardText: Record "Standard Text";
    begin
        StandardText.Init();
        StandardText.Code := 'LTQC86450';
        StandardText.Description := 'inserted';
        StandardText.Insert();
        StandardText.Description := 'modified';
        StandardText.Modify();
        StandardText.Delete();
        Error(RollbackErr);
    end;

    local procedure WriteTenantMedia()
    var
        TenantMedia: Record "Tenant Media";
    begin
        TenantMedia.Init();
        TenantMedia.ID := CreateGuid();
        TenantMedia.Description := 'inserted';
        TenantMedia.Insert();
        TenantMedia.Description := 'modified';
        TenantMedia.Modify();
        TenantMedia.Delete();
        Error(RollbackErr);
    end;

    local procedure WriteOwn()
    var
        Row: Record "LT QC Perm Row";
    begin
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Row.Name := 'two modified';
        Row.Modify();
        Row.Get(1);
        Row.Delete();
        Error(RollbackErr);
    end;

    local procedure ReadCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        Error('%1: get=%2', RollbackErr, CompanyInformation.Get());
    end;

    local procedure ReadAllObj()
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", Database::"LT QC Perm Row");
        Error('%1: findfirst=%2', RollbackErr, AllObj.FindFirst());
    end;

    local procedure ReadAccessControl()
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId());
        Error('%1: isempty=%2', RollbackErr, AccessControl.IsEmpty());
    end;

    local procedure ReadOwn()
    var
        Row: Record "LT QC Perm Row";
    begin
        Row.FindFirst();
        Error('%1: name=%2', RollbackErr, Row.Name);
    end;

    [Test]
    procedure RunnerSets_WhichSetsExist()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('all_objects', Format(SetExists('All Objects')));
        Observer.Observe('d365_full_access', Format(SetExists('D365 Full Access')));
        Observer.Observe('test_tables', Format(SetExists('Test Tables')));
        Observer.Observe('d365_basic', Format(SetExists('D365 Basic')));
        Observer.Observe('local', Format(SetExists('LOCAL')));
        Observer.Expect('all_objects', 'Yes');
        Observer.Expect('d365_full_access', 'Yes');
        Observer.Expect('test_tables', 'No');
        Observer.Expect('d365_basic', 'Yes');
        Observer.Expect('local', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RunnerSets_BaseApplicationTable()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        CompanyInformation: Record "Company Information";
        StandardText: Record "Standard Text";
        WasStarted: Boolean;
    begin
        WasStarted := ApplyRunnerSets(Mock);
        asserterror ReadCompanyInformation();
        Observer.ObserveError('company_information_get');
        Observer.Observe('company_information_read_permission', Format(CompanyInformation.ReadPermission()));
        Observer.Observe('company_information_write_permission', Format(CompanyInformation.WritePermission()));
        Observer.Observe('standard_text_read_permission', Format(StandardText.ReadPermission()));
        Observer.Observe('standard_text_write_permission', Format(StandardText.WritePermission()));
        asserterror WriteStandardText();
        Observer.ObserveError('standard_text_write');
        Observer.Observe('effective_standard_text', Rights(0, Database::"Standard Text"));
        Observer.Observe('effective_company_information', Rights(0, Database::"Company Information"));
        RestoreMock(Mock, WasStarted);
        Observer.Expect('company_information_get|text', 'LT QC rolled back: get=Yes');
        Observer.Expect('company_information_get|code', 'Dialog');
        Observer.Expect('company_information_read_permission', 'Yes');
        Observer.Expect('company_information_write_permission', 'Yes');
        Observer.Expect('standard_text_read_permission', 'Yes');
        Observer.Expect('standard_text_write_permission', 'Yes');
        Observer.Expect('standard_text_write|text', 'LT QC rolled back');
        Observer.Expect('standard_text_write|code', 'Dialog');
        Observer.Expect('effective_standard_text', 'Yes,Yes,Yes,Yes, ');
        Observer.Expect('effective_company_information', 'Yes,Yes,Yes,Yes, ');
        Observer.Verify();
    end;

    [Test]
    procedure RunnerSets_SystemTable()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        AllObj: Record AllObj;
        TenantMedia: Record "Tenant Media";
        AccessControl: Record "Access Control";
        WasStarted: Boolean;
    begin
        WasStarted := ApplyRunnerSets(Mock);
        asserterror ReadAllObj();
        Observer.ObserveError('allobj_findfirst');
        Observer.Observe('allobj_read_permission', Format(AllObj.ReadPermission()));
        Observer.Observe('tenant_media_read_permission', Format(TenantMedia.ReadPermission()));
        Observer.Observe('tenant_media_write_permission', Format(TenantMedia.WritePermission()));
        asserterror WriteTenantMedia();
        Observer.ObserveError('tenant_media_write');
        Observer.Observe('access_control_read_permission', Format(AccessControl.ReadPermission()));
        Observer.Observe('access_control_write_permission', Format(AccessControl.WritePermission()));
        asserterror ReadAccessControl();
        Observer.ObserveError('access_control_isempty');
        Observer.Observe('effective_tenant_media', Rights(0, Database::"Tenant Media"));
        Observer.Observe('effective_access_control', Rights(0, Database::"Access Control"));
        RestoreMock(Mock, WasStarted);
        Observer.Expect('allobj_findfirst|text', 'LT QC rolled back: findfirst=Yes');
        Observer.Expect('allobj_findfirst|code', 'Dialog');
        Observer.Expect('allobj_read_permission', 'Yes');
        Observer.Expect('tenant_media_read_permission', 'Yes');
        Observer.Expect('tenant_media_write_permission', 'No');
        Observer.Expect('tenant_media_write|text', 'Sorry, the current permissions prevented the action. (TableData 2000000184 Tenant Media Insert: AL Language Coverage Tests)');
        Observer.Expect('tenant_media_write|code', 'DB:ClientInsertDenied');
        Observer.Expect('access_control_read_permission', 'Yes');
        Observer.Expect('access_control_write_permission', 'Yes');
        Observer.Expect('access_control_isempty|text', 'LT QC rolled back: isempty=No');
        Observer.Expect('access_control_isempty|code', 'Dialog');
        Observer.Expect('effective_tenant_media', 'Yes,Indirect,Indirect,Indirect, ');
        Observer.Expect('effective_access_control', 'Yes,Yes,Yes,Yes, ');
        Observer.Verify();
    end;

    [Test]
    procedure RunnerSets_TestAppTable()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Row: Record "LT QC Perm Row";
        WasStarted: Boolean;
    begin
        SeedOwn();
        WasStarted := ApplyRunnerSets(Mock);
        Observer.Observe('read_permission', Format(Row.ReadPermission()));
        Observer.Observe('write_permission', Format(Row.WritePermission()));
        asserterror ReadOwn();
        Observer.ObserveError('findfirst');
        asserterror WriteOwn();
        Observer.ObserveError('write');
        Observer.Observe('effective_table_data', Rights(0, Database::"LT QC Perm Row"));
        Observer.Observe('effective_table', Rights(1, Database::"LT QC Perm Row"));
        Observer.Observe('effective_codeunit', Rights(5, Codeunit::"LT QC Runner Sets Tests"));
        RestoreMock(Mock, WasStarted);
        Observer.Expect('read_permission', 'No');
        Observer.Expect('write_permission', 'No');
        Observer.Expect('findfirst|text', 'Sorry, the current permissions prevented the action. (TableData 86450 LT QC Perm Row Read: AL Language Coverage Tests)');
        Observer.Expect('findfirst|code', 'DB:ClientReadDenied');
        Observer.Expect('write|text', 'Sorry, the current permissions prevented the action. (TableData 86450 LT QC Perm Row Insert: AL Language Coverage Tests)');
        Observer.Expect('write|code', 'DB:ClientInsertDenied');
        Observer.Expect('effective_table_data', ' , , , , ');
        Observer.Expect('effective_table', ' , , , ,Yes');
        Observer.Expect('effective_codeunit', ' , , , ,Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RunnerSets_TestAppTable_NoMock()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QC Perm Row";
    begin
        // Control arm: the same reads without the mock.
        SeedOwn();
        Observer.Observe('read_permission', Format(Row.ReadPermission()));
        Observer.Observe('write_permission', Format(Row.WritePermission()));
        Observer.Observe('findfirst', Format(Row.FindFirst()));
        asserterror WriteOwn();
        Observer.ObserveError('write');
        Observer.Observe('effective_table_data', Rights(0, Database::"LT QC Perm Row"));
        Observer.Expect('read_permission', 'Yes');
        Observer.Expect('write_permission', 'Yes');
        Observer.Expect('findfirst', 'Yes');
        Observer.Expect('write|text', 'LT QC rolled back');
        Observer.Expect('write|code', 'Dialog');
        Observer.Expect('effective_table_data', 'Yes,Yes,Yes,Yes, ');
        Observer.Verify();
    end;
}
