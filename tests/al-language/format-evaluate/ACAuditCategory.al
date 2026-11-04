// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/auditcategory/auditcategory-option
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: the AuditCategory option type: Format of every member as text (Format 0,0), as ordinal (Format 0,2) and as number text (Format 0,1), a case statement over every member, Evaluate by name and by number, and the error text of Evaluate for an invalid name and ordinal. The type is option-like: AsInteger does not exist and an Integer is not assignable (AL0132 and AL0122 at compile time).
//   Settles #626 items 11 to 15 for AuditCategory.
// BC versions: 27, 28, 29

codeunit 77512 "LT AC Audit Category Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_AuditCategory_FormatText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('text_Other', Format(AuditCategory::Other));
        Observer.Observe('text_UserManagement', Format(AuditCategory::UserManagement));
        Observer.Observe('text_GroupManagement', Format(AuditCategory::GroupManagement));
        Observer.Observe('text_Authentication', Format(AuditCategory::Authentication));
        Observer.Observe('text_Authorization', Format(AuditCategory::Authorization));
        Observer.Observe('text_RoleManagement', Format(AuditCategory::RoleManagement));
        Observer.Observe('text_ApplicationManagement', Format(AuditCategory::ApplicationManagement));
        Observer.Observe('text_KeyManagement', Format(AuditCategory::KeyManagement));
        Observer.Observe('text_DirectoryManagement', Format(AuditCategory::DirectoryManagement));
        Observer.Observe('text_ResourceManagement', Format(AuditCategory::ResourceManagement));
        Observer.Observe('text_PolicyManagement', Format(AuditCategory::PolicyManagement));
        Observer.Observe('text_DeviceManagement', Format(AuditCategory::DeviceManagement));
        Observer.Observe('text_EntitlementManagement', Format(AuditCategory::EntitlementManagement));
        Observer.Observe('text_PasswordManagement', Format(AuditCategory::PasswordManagement));
        Observer.Observe('text_IdentityProtection', Format(AuditCategory::IdentityProtection));
        Observer.Observe('text_ObjectManagement', Format(AuditCategory::ObjectManagement));
        Observer.Observe('text_ProvisioningManagement', Format(AuditCategory::ProvisioningManagement));
        Observer.Observe('text_CustomerFacing', Format(AuditCategory::CustomerFacing));
        Observer.Observe('text_Euii', Format(AuditCategory::Euii));
        Observer.Expect('text_Other', 'Other');
        Observer.Expect('text_UserManagement', 'UserManagement');
        Observer.Expect('text_GroupManagement', 'GroupManagement');
        Observer.Expect('text_Authentication', 'Authentication');
        Observer.Expect('text_Authorization', 'Authorization');
        Observer.Expect('text_RoleManagement', 'RoleManagement');
        Observer.Expect('text_ApplicationManagement', 'ApplicationManagement');
        Observer.Expect('text_KeyManagement', 'KeyManagement');
        Observer.Expect('text_DirectoryManagement', 'DirectoryManagement');
        Observer.Expect('text_ResourceManagement', 'ResourceManagement');
        Observer.Expect('text_PolicyManagement', 'PolicyManagement');
        Observer.Expect('text_DeviceManagement', 'DeviceManagement');
        Observer.Expect('text_EntitlementManagement', 'EntitlementManagement');
        Observer.Expect('text_PasswordManagement', 'PasswordManagement');
        Observer.Expect('text_IdentityProtection', 'IdentityProtection');
        Observer.Expect('text_ObjectManagement', 'ObjectManagement');
        Observer.Expect('text_ProvisioningManagement', 'ProvisioningManagement');
        Observer.Expect('text_CustomerFacing', 'CustomerFacing');
        Observer.Expect('text_Euii', 'Euii');
        Observer.Verify();
    end;

    [Test]
    procedure AC_AuditCategory_FormatOrdinal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('ordinal_Other', Format(AuditCategory::Other, 0, 2));
        Observer.Observe('ordinal_UserManagement', Format(AuditCategory::UserManagement, 0, 2));
        Observer.Observe('ordinal_GroupManagement', Format(AuditCategory::GroupManagement, 0, 2));
        Observer.Observe('ordinal_Authentication', Format(AuditCategory::Authentication, 0, 2));
        Observer.Observe('ordinal_Authorization', Format(AuditCategory::Authorization, 0, 2));
        Observer.Observe('ordinal_RoleManagement', Format(AuditCategory::RoleManagement, 0, 2));
        Observer.Observe('ordinal_ApplicationManagement', Format(AuditCategory::ApplicationManagement, 0, 2));
        Observer.Observe('ordinal_KeyManagement', Format(AuditCategory::KeyManagement, 0, 2));
        Observer.Observe('ordinal_DirectoryManagement', Format(AuditCategory::DirectoryManagement, 0, 2));
        Observer.Observe('ordinal_ResourceManagement', Format(AuditCategory::ResourceManagement, 0, 2));
        Observer.Observe('ordinal_PolicyManagement', Format(AuditCategory::PolicyManagement, 0, 2));
        Observer.Observe('ordinal_DeviceManagement', Format(AuditCategory::DeviceManagement, 0, 2));
        Observer.Observe('ordinal_EntitlementManagement', Format(AuditCategory::EntitlementManagement, 0, 2));
        Observer.Observe('ordinal_PasswordManagement', Format(AuditCategory::PasswordManagement, 0, 2));
        Observer.Observe('ordinal_IdentityProtection', Format(AuditCategory::IdentityProtection, 0, 2));
        Observer.Observe('ordinal_ObjectManagement', Format(AuditCategory::ObjectManagement, 0, 2));
        Observer.Observe('ordinal_ProvisioningManagement', Format(AuditCategory::ProvisioningManagement, 0, 2));
        Observer.Observe('ordinal_CustomerFacing', Format(AuditCategory::CustomerFacing, 0, 2));
        Observer.Observe('ordinal_Euii', Format(AuditCategory::Euii, 0, 2));
        Observer.Expect('ordinal_Other', '0');
        Observer.Expect('ordinal_UserManagement', '1');
        Observer.Expect('ordinal_GroupManagement', '2');
        Observer.Expect('ordinal_Authentication', '3');
        Observer.Expect('ordinal_Authorization', '4');
        Observer.Expect('ordinal_RoleManagement', '5');
        Observer.Expect('ordinal_ApplicationManagement', '6');
        Observer.Expect('ordinal_KeyManagement', '7');
        Observer.Expect('ordinal_DirectoryManagement', '8');
        Observer.Expect('ordinal_ResourceManagement', '9');
        Observer.Expect('ordinal_PolicyManagement', '10');
        Observer.Expect('ordinal_DeviceManagement', '11');
        Observer.Expect('ordinal_EntitlementManagement', '12');
        Observer.Expect('ordinal_PasswordManagement', '13');
        Observer.Expect('ordinal_IdentityProtection', '14');
        Observer.Expect('ordinal_ObjectManagement', '15');
        Observer.Expect('ordinal_ProvisioningManagement', '16');
        Observer.Expect('ordinal_CustomerFacing', '17');
        Observer.Expect('ordinal_Euii', '18');
        Observer.Verify();
    end;

    [Test]
    procedure AC_AuditCategory_FormatNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('number_Other', Format(AuditCategory::Other, 0, 1));
        Observer.Observe('number_UserManagement', Format(AuditCategory::UserManagement, 0, 1));
        Observer.Observe('number_GroupManagement', Format(AuditCategory::GroupManagement, 0, 1));
        Observer.Observe('number_Authentication', Format(AuditCategory::Authentication, 0, 1));
        Observer.Observe('number_Authorization', Format(AuditCategory::Authorization, 0, 1));
        Observer.Observe('number_RoleManagement', Format(AuditCategory::RoleManagement, 0, 1));
        Observer.Observe('number_ApplicationManagement', Format(AuditCategory::ApplicationManagement, 0, 1));
        Observer.Observe('number_KeyManagement', Format(AuditCategory::KeyManagement, 0, 1));
        Observer.Observe('number_DirectoryManagement', Format(AuditCategory::DirectoryManagement, 0, 1));
        Observer.Observe('number_ResourceManagement', Format(AuditCategory::ResourceManagement, 0, 1));
        Observer.Observe('number_PolicyManagement', Format(AuditCategory::PolicyManagement, 0, 1));
        Observer.Observe('number_DeviceManagement', Format(AuditCategory::DeviceManagement, 0, 1));
        Observer.Observe('number_EntitlementManagement', Format(AuditCategory::EntitlementManagement, 0, 1));
        Observer.Observe('number_PasswordManagement', Format(AuditCategory::PasswordManagement, 0, 1));
        Observer.Observe('number_IdentityProtection', Format(AuditCategory::IdentityProtection, 0, 1));
        Observer.Observe('number_ObjectManagement', Format(AuditCategory::ObjectManagement, 0, 1));
        Observer.Observe('number_ProvisioningManagement', Format(AuditCategory::ProvisioningManagement, 0, 1));
        Observer.Observe('number_CustomerFacing', Format(AuditCategory::CustomerFacing, 0, 1));
        Observer.Observe('number_Euii', Format(AuditCategory::Euii, 0, 1));
        Observer.Expect('number_Other', 'Other');
        Observer.Expect('number_UserManagement', 'UserManagement');
        Observer.Expect('number_GroupManagement', 'GroupManagement');
        Observer.Expect('number_Authentication', 'Authentication');
        Observer.Expect('number_Authorization', 'Authorization');
        Observer.Expect('number_RoleManagement', 'RoleManagement');
        Observer.Expect('number_ApplicationManagement', 'ApplicationManagement');
        Observer.Expect('number_KeyManagement', 'KeyManagement');
        Observer.Expect('number_DirectoryManagement', 'DirectoryManagement');
        Observer.Expect('number_ResourceManagement', 'ResourceManagement');
        Observer.Expect('number_PolicyManagement', 'PolicyManagement');
        Observer.Expect('number_DeviceManagement', 'DeviceManagement');
        Observer.Expect('number_EntitlementManagement', 'EntitlementManagement');
        Observer.Expect('number_PasswordManagement', 'PasswordManagement');
        Observer.Expect('number_IdentityProtection', 'IdentityProtection');
        Observer.Expect('number_ObjectManagement', 'ObjectManagement');
        Observer.Expect('number_ProvisioningManagement', 'ProvisioningManagement');
        Observer.Expect('number_CustomerFacing', 'CustomerFacing');
        Observer.Expect('number_Euii', 'Euii');
        Observer.Verify();
    end;

    [Test]
    procedure AC_AuditCategory_Variable()
    var
        Observer: Codeunit "Probe Observer";
        V: AuditCategory;
    begin

        Observer.Observe('default', Format(V));
        Observer.Observe('default_ordinal', Format(V, 0, 2));
        V := AuditCategory::Euii;
        Observer.Observe('last', Format(V));
        Observer.Observe('last_ordinal', Format(V, 0, 2));
        Observer.Observe('eq_last', Format(V = AuditCategory::Euii));
        Observer.Observe('eq_first', Format(V = AuditCategory::Other));
        Clear(V);
        Observer.Observe('cleared', Format(V));
        Observer.Expect('default', 'Other');
        Observer.Expect('default_ordinal', '0');
        Observer.Expect('last', 'Euii');
        Observer.Expect('last_ordinal', '18');
        Observer.Expect('eq_last', 'Yes');
        Observer.Expect('eq_first', 'No');
        Observer.Expect('cleared', 'Other');
        Observer.Verify();
    end;

    [Test]
    procedure AC_AuditCategory_Case()
    var
        Observer: Codeunit "Probe Observer";
        V: AuditCategory;
    begin
        V := AuditCategory::Other;
        Observer.Observe('case_Other', CaseName(V));
        V := AuditCategory::UserManagement;
        Observer.Observe('case_UserManagement', CaseName(V));
        V := AuditCategory::GroupManagement;
        Observer.Observe('case_GroupManagement', CaseName(V));
        V := AuditCategory::Authentication;
        Observer.Observe('case_Authentication', CaseName(V));
        V := AuditCategory::Authorization;
        Observer.Observe('case_Authorization', CaseName(V));
        V := AuditCategory::RoleManagement;
        Observer.Observe('case_RoleManagement', CaseName(V));
        V := AuditCategory::ApplicationManagement;
        Observer.Observe('case_ApplicationManagement', CaseName(V));
        V := AuditCategory::KeyManagement;
        Observer.Observe('case_KeyManagement', CaseName(V));
        V := AuditCategory::DirectoryManagement;
        Observer.Observe('case_DirectoryManagement', CaseName(V));
        V := AuditCategory::ResourceManagement;
        Observer.Observe('case_ResourceManagement', CaseName(V));
        V := AuditCategory::PolicyManagement;
        Observer.Observe('case_PolicyManagement', CaseName(V));
        V := AuditCategory::DeviceManagement;
        Observer.Observe('case_DeviceManagement', CaseName(V));
        V := AuditCategory::EntitlementManagement;
        Observer.Observe('case_EntitlementManagement', CaseName(V));
        V := AuditCategory::PasswordManagement;
        Observer.Observe('case_PasswordManagement', CaseName(V));
        V := AuditCategory::IdentityProtection;
        Observer.Observe('case_IdentityProtection', CaseName(V));
        V := AuditCategory::ObjectManagement;
        Observer.Observe('case_ObjectManagement', CaseName(V));
        V := AuditCategory::ProvisioningManagement;
        Observer.Observe('case_ProvisioningManagement', CaseName(V));
        V := AuditCategory::CustomerFacing;
        Observer.Observe('case_CustomerFacing', CaseName(V));
        V := AuditCategory::Euii;
        Observer.Observe('case_Euii', CaseName(V));
        Observer.Expect('case_Other', 'is_Other');
        Observer.Expect('case_UserManagement', 'is_UserManagement');
        Observer.Expect('case_GroupManagement', 'is_GroupManagement');
        Observer.Expect('case_Authentication', 'is_Authentication');
        Observer.Expect('case_Authorization', 'is_Authorization');
        Observer.Expect('case_RoleManagement', 'is_RoleManagement');
        Observer.Expect('case_ApplicationManagement', 'is_ApplicationManagement');
        Observer.Expect('case_KeyManagement', 'is_KeyManagement');
        Observer.Expect('case_DirectoryManagement', 'is_DirectoryManagement');
        Observer.Expect('case_ResourceManagement', 'is_ResourceManagement');
        Observer.Expect('case_PolicyManagement', 'is_PolicyManagement');
        Observer.Expect('case_DeviceManagement', 'is_DeviceManagement');
        Observer.Expect('case_EntitlementManagement', 'is_EntitlementManagement');
        Observer.Expect('case_PasswordManagement', 'is_PasswordManagement');
        Observer.Expect('case_IdentityProtection', 'is_IdentityProtection');
        Observer.Expect('case_ObjectManagement', 'is_ObjectManagement');
        Observer.Expect('case_ProvisioningManagement', 'is_ProvisioningManagement');
        Observer.Expect('case_CustomerFacing', 'is_CustomerFacing');
        Observer.Expect('case_Euii', 'is_Euii');
        Observer.Verify();
    end;

    local procedure CaseName(V: AuditCategory): Text
    begin
        case V of
            AuditCategory::Other:
                exit('is_Other');
            AuditCategory::UserManagement:
                exit('is_UserManagement');
            AuditCategory::GroupManagement:
                exit('is_GroupManagement');
            AuditCategory::Authentication:
                exit('is_Authentication');
            AuditCategory::Authorization:
                exit('is_Authorization');
            AuditCategory::RoleManagement:
                exit('is_RoleManagement');
            AuditCategory::ApplicationManagement:
                exit('is_ApplicationManagement');
            AuditCategory::KeyManagement:
                exit('is_KeyManagement');
            AuditCategory::DirectoryManagement:
                exit('is_DirectoryManagement');
            AuditCategory::ResourceManagement:
                exit('is_ResourceManagement');
            AuditCategory::PolicyManagement:
                exit('is_PolicyManagement');
            AuditCategory::DeviceManagement:
                exit('is_DeviceManagement');
            AuditCategory::EntitlementManagement:
                exit('is_EntitlementManagement');
            AuditCategory::PasswordManagement:
                exit('is_PasswordManagement');
            AuditCategory::IdentityProtection:
                exit('is_IdentityProtection');
            AuditCategory::ObjectManagement:
                exit('is_ObjectManagement');
            AuditCategory::ProvisioningManagement:
                exit('is_ProvisioningManagement');
            AuditCategory::CustomerFacing:
                exit('is_CustomerFacing');
            AuditCategory::Euii:
                exit('is_Euii');
            else
                exit('other');
        end;
    end;
}

codeunit 77513 "LT AC Audit Category Eval"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_AuditCategory_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        V: AuditCategory;
        Ok: Boolean;
    begin
        Clear(V);
        Ok := Evaluate(V, 'Other');
        Observer.Observe('name_Other', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'UserManagement');
        Observer.Observe('name_UserManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'GroupManagement');
        Observer.Observe('name_GroupManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Authentication');
        Observer.Observe('name_Authentication', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Authorization');
        Observer.Observe('name_Authorization', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'RoleManagement');
        Observer.Observe('name_RoleManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'ApplicationManagement');
        Observer.Observe('name_ApplicationManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'KeyManagement');
        Observer.Observe('name_KeyManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'DirectoryManagement');
        Observer.Observe('name_DirectoryManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'ResourceManagement');
        Observer.Observe('name_ResourceManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'PolicyManagement');
        Observer.Observe('name_PolicyManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'DeviceManagement');
        Observer.Observe('name_DeviceManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'EntitlementManagement');
        Observer.Observe('name_EntitlementManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'PasswordManagement');
        Observer.Observe('name_PasswordManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'IdentityProtection');
        Observer.Observe('name_IdentityProtection', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'ObjectManagement');
        Observer.Observe('name_ObjectManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'ProvisioningManagement');
        Observer.Observe('name_ProvisioningManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'CustomerFacing');
        Observer.Observe('name_CustomerFacing', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Euii');
        Observer.Observe('name_Euii', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'usermanagement');
        Observer.Observe('name_lowercase', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'USERMANAGEMENT');
        Observer.Observe('name_uppercase', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '0');
        Observer.Observe('number_0', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '1');
        Observer.Observe('number_1', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '2');
        Observer.Observe('number_2', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '3');
        Observer.Observe('number_3', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '4');
        Observer.Observe('number_4', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '5');
        Observer.Observe('number_5', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '6');
        Observer.Observe('number_6', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '7');
        Observer.Observe('number_7', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '8');
        Observer.Observe('number_8', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '9');
        Observer.Observe('number_9', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '10');
        Observer.Observe('number_10', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '11');
        Observer.Observe('number_11', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '12');
        Observer.Observe('number_12', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '13');
        Observer.Observe('number_13', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '14');
        Observer.Observe('number_14', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '15');
        Observer.Observe('number_15', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '16');
        Observer.Observe('number_16', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '17');
        Observer.Observe('number_17', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '18');
        Observer.Observe('number_18', Format(Ok) + '/' + Format(V, 0, 2));
        Observer.Expect('name_Other', 'Yes/0');
        Observer.Expect('name_UserManagement', 'Yes/1');
        Observer.Expect('name_GroupManagement', 'Yes/2');
        Observer.Expect('name_Authentication', 'Yes/3');
        Observer.Expect('name_Authorization', 'Yes/4');
        Observer.Expect('name_RoleManagement', 'Yes/5');
        Observer.Expect('name_ApplicationManagement', 'Yes/6');
        Observer.Expect('name_KeyManagement', 'Yes/7');
        Observer.Expect('name_DirectoryManagement', 'Yes/8');
        Observer.Expect('name_ResourceManagement', 'Yes/9');
        Observer.Expect('name_PolicyManagement', 'Yes/10');
        Observer.Expect('name_DeviceManagement', 'Yes/11');
        Observer.Expect('name_EntitlementManagement', 'Yes/12');
        Observer.Expect('name_PasswordManagement', 'Yes/13');
        Observer.Expect('name_IdentityProtection', 'Yes/14');
        Observer.Expect('name_ObjectManagement', 'Yes/15');
        Observer.Expect('name_ProvisioningManagement', 'Yes/16');
        Observer.Expect('name_CustomerFacing', 'Yes/17');
        Observer.Expect('name_Euii', 'Yes/18');
        Observer.Expect('name_lowercase', 'Yes/1');
        Observer.Expect('name_uppercase', 'Yes/1');
        Observer.Expect('number_0', 'Yes/0');
        Observer.Expect('number_1', 'Yes/1');
        Observer.Expect('number_2', 'Yes/2');
        Observer.Expect('number_3', 'Yes/3');
        Observer.Expect('number_4', 'Yes/4');
        Observer.Expect('number_5', 'Yes/5');
        Observer.Expect('number_6', 'Yes/6');
        Observer.Expect('number_7', 'Yes/7');
        Observer.Expect('number_8', 'Yes/8');
        Observer.Expect('number_9', 'Yes/9');
        Observer.Expect('number_10', 'Yes/10');
        Observer.Expect('number_11', 'Yes/11');
        Observer.Expect('number_12', 'Yes/12');
        Observer.Expect('number_13', 'Yes/13');
        Observer.Expect('number_14', 'Yes/14');
        Observer.Expect('number_15', 'Yes/15');
        Observer.Expect('number_16', 'Yes/16');
        Observer.Expect('number_17', 'Yes/17');
        Observer.Expect('number_18', 'Yes/18');
        Observer.Verify();
    end;

    [Test]
    procedure AC_AuditCategory_EvaluateInvalidA()
    var
        Observer: Codeunit "Probe Observer";
        V: AuditCategory;
    begin
        Clear(V);
        if Evaluate(V, 'Bogus') then
            Observer.Observe('bogus_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('bogus');
        Clear(V);
        if Evaluate(V, '') then
            Observer.Observe('empty_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('empty');
        Clear(V);
        if Evaluate(V, '19') then
            Observer.Observe('past_end_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('past_end');
        Observer.Expect('bogus|text', '''Bogus'' is not an option. The existing options are: Other, UserManagement, GroupManagement, Authentication, Authorization, RoleManagement, ApplicationManagement, KeyManagement, DirectoryManagement, ResourceManagement, PolicyManagement, DeviceManagement, EntitlementManagement, PasswordManagement, IdentityProtection, ObjectManagement, ProvisioningManagement, CustomerFacing, Euii');
        Observer.Expect('bogus|code', 'InvalidOptionString');
        Observer.Expect('empty_ok', '0');
        Observer.Expect('past_end|text', '''19'' is not an option. The existing options are: Other, UserManagement, GroupManagement, Authentication, Authorization, RoleManagement, ApplicationManagement, KeyManagement, DirectoryManagement, ResourceManagement, PolicyManagement, DeviceManagement, EntitlementManagement, PasswordManagement, IdentityProtection, ObjectManagement, ProvisioningManagement, CustomerFacing, Euii');
        Observer.Expect('past_end|code', 'InvalidOptionString');
        Observer.Verify();
    end;

    [Test]
    procedure AC_AuditCategory_EvaluateInvalidB()
    var
        Observer: Codeunit "Probe Observer";
        V: AuditCategory;
    begin
        Clear(V);
        if Evaluate(V, '99') then
            Observer.Observe('large_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('large');
        Clear(V);
        if Evaluate(V, '-1') then
            Observer.Observe('negative_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('negative');
        Observer.Expect('large|text', '''99'' is not an option. The existing options are: Other, UserManagement, GroupManagement, Authentication, Authorization, RoleManagement, ApplicationManagement, KeyManagement, DirectoryManagement, ResourceManagement, PolicyManagement, DeviceManagement, EntitlementManagement, PasswordManagement, IdentityProtection, ObjectManagement, ProvisioningManagement, CustomerFacing, Euii');
        Observer.Expect('large|code', 'InvalidOptionString');
        Observer.Expect('negative|text', '''-1'' is not an option. The existing options are: Other, UserManagement, GroupManagement, Authentication, Authorization, RoleManagement, ApplicationManagement, KeyManagement, DirectoryManagement, ResourceManagement, PolicyManagement, DeviceManagement, EntitlementManagement, PasswordManagement, IdentityProtection, ObjectManagement, ProvisioningManagement, CustomerFacing, Euii');
        Observer.Expect('negative|code', 'InvalidOptionString');
        Observer.Verify();
    end;

    [Test]
    procedure AC_AuditCategory_EvaluateInvalidC()
    var
        Observer: Codeunit "Probe Observer";
        V: AuditCategory;
    begin
        Clear(V);
        if Evaluate(V, ' UserManagement') then
            Observer.Observe('space_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('space');
        Clear(V);
        if Evaluate(V, '1.5') then
            Observer.Observe('decimal_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('decimal');
        Observer.Expect('space_ok', '1');
        Observer.Expect('decimal|text', '''1.5'' is not an option. The existing options are: Other, UserManagement, GroupManagement, Authentication, Authorization, RoleManagement, ApplicationManagement, KeyManagement, DirectoryManagement, ResourceManagement, PolicyManagement, DeviceManagement, EntitlementManagement, PasswordManagement, IdentityProtection, ObjectManagement, ProvisioningManagement, CustomerFacing, Euii');
        Observer.Expect('decimal|code', 'InvalidOptionString');
        Observer.Verify();
    end;
}
