// Batch 6, md:319 [NavUserAccountHelper.GetEffectivePermissionForObject] through Codeunit "User Permissions" (GetEffectivePermission);
// md:320 [NavTestExecution.IsInTestMode] through Codeunit "Environment Information".CanStartSession (true branch of IsInTestMode, then CanCreateTask), read in OnRun
// of the test codeunit and in a test; md:322 [Platform order] IsSaaS / IsSandbox and the Tenant License State table and codeunit;
// md:397 [NavTenantSettingsHelper.TryGetStringTenantSetting] through Codeunit "Tenant Information" (TENANTID, DISPLAYNAME) and "Azure AD Tenant" (AADTENANTID).
// Observe-only. Tenant ids and names are tier data: only blank, equality and parse-as-GUID are observed.
// Skipped on purpose (not observable from AL): NavTenantSettingsHelper.GetEnvironmentName / GetEnvironmentApplicationSetting (the wrapper hides the helper), ALConfigSettings.Instance,
// and the "refused, no registry member" list (md:321).

report 67326 "W6 EP Report"
{
    ProcessingOnly = true;
    UsageCategory = None;
}

codeunit 67327 "W6 IT Log"
{
    SingleInstance = true;

    var
        Text1: Text;

    procedure SetText(Value: Text)
    begin
        Text1 := Value;
    end;

    procedure GetText(): Text
    begin
        exit(Text1);
    end;
}

codeunit 67328 "W6 Environment Helpers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        Log: Codeunit "W6 IT Log";
    begin
        Log.SetText('can_start_session=' + Format(EnvironmentInformation.CanStartSession()) + ' can_create_task=' + Format(TaskScheduler.CanCreateTask()));
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

    [Test]
    procedure EffectivePermission_TableData_OwnTable_And_Customer()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('own_table_data', Rights(0, Database::"W6 AO Table"));
        Observer.Observe('customer_table_data', Rights(0, Database::Customer));
        Observer.Observe('own_table_object', Rights(1, Database::"W6 AO Table"));
        Observer.Expect('own_table_data', 'Yes,Yes,Yes,Yes, ');
        Observer.Expect('customer_table_data', 'Yes,Yes,Yes,Yes, ');
        Observer.Expect('own_table_object', ' , , , ,Yes');
        Observer.Verify();
    end;

    [Test]
    procedure EffectivePermission_Codeunit_Page_Report()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('own_codeunit', Rights(5, Codeunit::"W6 AO Code"));
        Observer.Observe('own_page', Rights(8, Page::"W6 AO Page"));
        Observer.Observe('own_report', Rights(3, Report::"W6 EP Report"));
        Observer.Observe('base_app_codeunit_sales_post', Rights(5, Codeunit::"Sales-Post"));
        Observer.Observe('base_app_page_customer_card', Rights(8, Page::"Customer Card"));
        Observer.Observe('base_app_report_customer_top_10', Rights(3, Report::"Customer - Top 10 List"));
        Observer.Expect('own_codeunit', ' , , , ,Yes');
        Observer.Expect('own_page', ' , , , ,Yes');
        Observer.Expect('own_report', ' , , , ,Yes');
        Observer.Expect('base_app_codeunit_sales_post', ' , , , ,Yes');
        Observer.Expect('base_app_page_customer_card', ' , , , ,Yes');
        Observer.Expect('base_app_report_customer_top_10', ' , , , ,Yes');
        Observer.Verify();
    end;

    // The next three may raise on a kind or an object BC does not know; each stands alone, so the failure text of one is its own finding.
    [Test]
    procedure EffectivePermission_CodeunitIdAsTableData()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('own_codeunit_id_as_table_data', Rights(0, Codeunit::"W6 AO Code"));
        Observer.Expect('own_codeunit_id_as_table_data', 'Yes,Yes,Yes,Yes, ');
        Observer.Verify();
    end;

    [Test]
    procedure EffectivePermission_NoSuchCodeunit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('no_such_codeunit', Rights(5, 67399));
        Observer.Expect('no_such_codeunit', ' , , , ,Yes');
        Observer.Verify();
    end;

    [Test]
    procedure EffectivePermission_SystemObjectType()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('system_object_type_id_zero', Rights(10, 0));
        Observer.Expect('system_object_type_id_zero', ' , , , , ');
        Observer.Verify();
    end;

    [Test]
    procedure TestMode_CanStartSession_InTest_And_InOnRun()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        Log: Codeunit "W6 IT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('in_on_run_before_first_test', Log.GetText());
        Observer.Observe('in_test_can_start_session', Format(EnvironmentInformation.CanStartSession()));
        Observer.Observe('in_test_can_create_task', Format(TaskScheduler.CanCreateTask()));
        Observer.Expect('in_on_run_before_first_test', 'can_start_session=No can_create_task=No');
        Observer.Expect('in_test_can_start_session', 'No');
        Observer.Expect('in_test_can_create_task', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure PlatformOrder_IsSaaS_IsSandbox_And_TenantLicenseState()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        LicenseState: Codeunit "Tenant License State";
        StateRec: Record "Tenant License State";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('is_saas', Format(EnvironmentInformation.IsSaaS()));
        Observer.Observe('is_sandbox', Format(EnvironmentInformation.IsSandbox()));
        Observer.Observe('is_production', Format(EnvironmentInformation.IsProduction()));
        Observer.Observe('is_onprem', Format(EnvironmentInformation.IsOnPrem()));
        Observer.Observe('environment_name_blank', Format(EnvironmentInformation.GetEnvironmentName() = ''));
        Observer.Observe('tenant_license_state_row_count', Format(StateRec.Count()));
        Observer.Observe('tenant_license_state_is_empty', Format(StateRec.IsEmpty()));
        Observer.Observe('license_state', Format(LicenseState.GetLicenseState()));
        Observer.Observe('license_state_ordinal', Format(LicenseState.GetLicenseState(), 0, 2));
        Observer.Observe('start_date_is_zero', Format(LicenseState.GetStartDate() = 0DT));
        Observer.Observe('end_date_is_zero', Format(LicenseState.GetEndDate() = 0DT));
        Observer.Expect('is_saas', 'Yes');
        Observer.Expect('is_sandbox', 'Yes');
        Observer.Expect('is_production', 'No');
        Observer.Expect('is_onprem', 'Yes');
        Observer.Expect('environment_name_blank', 'No');
        Observer.Expect('tenant_license_state_row_count', '0');
        Observer.Expect('tenant_license_state_is_empty', 'Yes');
        Observer.Expect('license_state', 'Evaluation');
        Observer.Expect('license_state_ordinal', '0');
        Observer.Expect('start_date_is_zero', 'Yes');
        Observer.Expect('end_date_is_zero', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TenantSettings_TenantId_DisplayName_AadTenantId()
    var
        TenantInformation: Codeunit "Tenant Information";
        AzureADTenant: Codeunit "Azure AD Tenant";
        AadTenantId: Text;
        Parsed: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('tenant_id_blank', Format(TenantInformation.GetTenantId() = ''));
        Observer.Observe('tenant_id_equals_database_tenant_id', Format(TenantInformation.GetTenantId() = Database.TenantId()));
        Observer.Observe('tenant_id_equals_default', Format(TenantInformation.GetTenantId() = 'default'));
        Observer.Observe('display_name_blank', Format(TenantInformation.GetTenantDisplayName() = ''));
        AadTenantId := AzureADTenant.GetAadTenantId();
        Observer.Observe('aad_tenant_id_blank', Format(AadTenantId = ''));
        Observer.Observe('aad_tenant_id_equals_common', Format(AadTenantId = 'common'));
        Observer.Observe('aad_tenant_id_is_a_guid', Format(Evaluate(Parsed, AadTenantId)));
        Observer.Expect('tenant_id_blank', 'No');
        Observer.Expect('tenant_id_equals_database_tenant_id', 'Yes');
        Observer.Expect('tenant_id_equals_default', 'Yes');
        Observer.Expect('display_name_blank', 'Yes');
        Observer.Expect('aad_tenant_id_blank', 'No');
        Observer.Expect('aad_tenant_id_equals_common', 'Yes');
        Observer.Expect('aad_tenant_id_is_a_guid', 'No');
        Observer.Verify();
    end;
}
