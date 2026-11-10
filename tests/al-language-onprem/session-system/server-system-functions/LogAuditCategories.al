// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-logauditmessage-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-logsecurityaudit-method
// Scope: in-scope (OnPrem app only: Session.LogAuditMessage and Session.LogSecurityAudit)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 98201
// Probe: from al-runner issue 7586 item 1 (Session.LogAuditMessage(..., AuditCategory::Authentication, 1, 0), met in Microsoft's test
//   apps).
// RISKY: writes audit messages to the telemetry of the service tier
// Area: LogAuditMessage and LogSecurityAudit with every member of AuditCategory: does the call run, and the error text when not.
//   LogAuditMessage is called with operation 1 and operation result 0 (the reported arguments), with and without custom dimensions.
// Already pinned elsewhere, not repeated: the ordinal and the text of every AuditCategory member (tests/al-language/format-evaluate/
//   ACAuditCategory.al, AC_AuditCategory_FormatOrdinal: Authentication is 3, CustomerFacing 17); LogAuditMessage with
//   ApplicationManagement and Authorization and its operation numbers (PLogAuditMessage.al); LogSecurityAudit with
//   ApplicationManagement and Authentication (OBlobAndSession.al).
// Observation form: every test ends in Finish(); the values are what BC produced.
// BC versions: 27.5, 28.5, 29.0 (measured by the corpus CI)

codeunit 98201 "SS Audit Category Calls"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryMessage(Category: AuditCategory)
    begin
        Session.LogAuditMessage('SS audit category probe', SecurityOperationResult::Success, Category, 1, 0);
    end;

    [TryFunction]
    local procedure TryMessageDimensions(Category: AuditCategory)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('SSAuditProbeKey', 'SSAuditProbeValue');
        Session.LogAuditMessage('SS audit category probe', SecurityOperationResult::Failure, Category, 1, 0, Dimensions);
    end;

    [TryFunction]
    local procedure TrySecurityAudit(Category: AuditCategory)
    begin
        Session.LogSecurityAudit('SS audit category probe', SecurityOperationResult::Success, 'SS audit detail', Category);
    end;

    local procedure Message(Category: AuditCategory): Text
    begin
        ClearLastError();
        if TryMessage(Category) then
            exit('ok');
        exit('error:' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    local procedure MessageDimensions(Category: AuditCategory): Text
    begin
        ClearLastError();
        if TryMessageDimensions(Category) then
            exit('ok');
        exit('error:' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    local procedure SecurityAudit(Category: AuditCategory): Text
    begin
        ClearLastError();
        if TrySecurityAudit(Category) then
            exit('ok');
        exit('error:' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    [Test]
    procedure LogAuditMessage_EveryCategory()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Other', Message(AuditCategory::Other));
        Observer.Observe('UserManagement', Message(AuditCategory::UserManagement));
        Observer.Observe('GroupManagement', Message(AuditCategory::GroupManagement));
        Observer.Observe('Authentication', Message(AuditCategory::Authentication));
        Observer.Observe('Authorization', Message(AuditCategory::Authorization));
        Observer.Observe('RoleManagement', Message(AuditCategory::RoleManagement));
        Observer.Observe('ApplicationManagement', Message(AuditCategory::ApplicationManagement));
        Observer.Observe('KeyManagement', Message(AuditCategory::KeyManagement));
        Observer.Observe('DirectoryManagement', Message(AuditCategory::DirectoryManagement));
        Observer.Observe('ResourceManagement', Message(AuditCategory::ResourceManagement));
        Observer.Observe('PolicyManagement', Message(AuditCategory::PolicyManagement));
        Observer.Observe('DeviceManagement', Message(AuditCategory::DeviceManagement));
        Observer.Observe('EntitlementManagement', Message(AuditCategory::EntitlementManagement));
        Observer.Observe('PasswordManagement', Message(AuditCategory::PasswordManagement));
        Observer.Observe('IdentityProtection', Message(AuditCategory::IdentityProtection));
        Observer.Observe('ObjectManagement', Message(AuditCategory::ObjectManagement));
        Observer.Observe('ProvisioningManagement', Message(AuditCategory::ProvisioningManagement));
        Observer.Observe('CustomerFacing', Message(AuditCategory::CustomerFacing));
        Observer.Observe('Euii', Message(AuditCategory::Euii));
        Observer.Finish();
    end;

    [Test]
    procedure LogAuditMessage_Dimensions_EveryCategory()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Other', MessageDimensions(AuditCategory::Other));
        Observer.Observe('UserManagement', MessageDimensions(AuditCategory::UserManagement));
        Observer.Observe('GroupManagement', MessageDimensions(AuditCategory::GroupManagement));
        Observer.Observe('Authentication', MessageDimensions(AuditCategory::Authentication));
        Observer.Observe('Authorization', MessageDimensions(AuditCategory::Authorization));
        Observer.Observe('RoleManagement', MessageDimensions(AuditCategory::RoleManagement));
        Observer.Observe('ApplicationManagement', MessageDimensions(AuditCategory::ApplicationManagement));
        Observer.Observe('KeyManagement', MessageDimensions(AuditCategory::KeyManagement));
        Observer.Observe('DirectoryManagement', MessageDimensions(AuditCategory::DirectoryManagement));
        Observer.Observe('ResourceManagement', MessageDimensions(AuditCategory::ResourceManagement));
        Observer.Observe('PolicyManagement', MessageDimensions(AuditCategory::PolicyManagement));
        Observer.Observe('DeviceManagement', MessageDimensions(AuditCategory::DeviceManagement));
        Observer.Observe('EntitlementManagement', MessageDimensions(AuditCategory::EntitlementManagement));
        Observer.Observe('PasswordManagement', MessageDimensions(AuditCategory::PasswordManagement));
        Observer.Observe('IdentityProtection', MessageDimensions(AuditCategory::IdentityProtection));
        Observer.Observe('ObjectManagement', MessageDimensions(AuditCategory::ObjectManagement));
        Observer.Observe('ProvisioningManagement', MessageDimensions(AuditCategory::ProvisioningManagement));
        Observer.Observe('CustomerFacing', MessageDimensions(AuditCategory::CustomerFacing));
        Observer.Observe('Euii', MessageDimensions(AuditCategory::Euii));
        Observer.Finish();
    end;

    [Test]
    procedure LogSecurityAudit_EveryCategory()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Other', SecurityAudit(AuditCategory::Other));
        Observer.Observe('UserManagement', SecurityAudit(AuditCategory::UserManagement));
        Observer.Observe('GroupManagement', SecurityAudit(AuditCategory::GroupManagement));
        Observer.Observe('Authentication', SecurityAudit(AuditCategory::Authentication));
        Observer.Observe('Authorization', SecurityAudit(AuditCategory::Authorization));
        Observer.Observe('RoleManagement', SecurityAudit(AuditCategory::RoleManagement));
        Observer.Observe('ApplicationManagement', SecurityAudit(AuditCategory::ApplicationManagement));
        Observer.Observe('KeyManagement', SecurityAudit(AuditCategory::KeyManagement));
        Observer.Observe('DirectoryManagement', SecurityAudit(AuditCategory::DirectoryManagement));
        Observer.Observe('ResourceManagement', SecurityAudit(AuditCategory::ResourceManagement));
        Observer.Observe('PolicyManagement', SecurityAudit(AuditCategory::PolicyManagement));
        Observer.Observe('DeviceManagement', SecurityAudit(AuditCategory::DeviceManagement));
        Observer.Observe('EntitlementManagement', SecurityAudit(AuditCategory::EntitlementManagement));
        Observer.Observe('PasswordManagement', SecurityAudit(AuditCategory::PasswordManagement));
        Observer.Observe('IdentityProtection', SecurityAudit(AuditCategory::IdentityProtection));
        Observer.Observe('ObjectManagement', SecurityAudit(AuditCategory::ObjectManagement));
        Observer.Observe('ProvisioningManagement', SecurityAudit(AuditCategory::ProvisioningManagement));
        Observer.Observe('CustomerFacing', SecurityAudit(AuditCategory::CustomerFacing));
        Observer.Observe('Euii', SecurityAudit(AuditCategory::Euii));
        Observer.Finish();
    end;

    [Test]
    procedure LogAuditMessage_Authentication_Statement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // The reported statement, outside a TryFunction.
        Session.LogAuditMessage('m', SecurityOperationResult::Success, AuditCategory::Authentication, 1, 0);
        Observer.Observe('after statement', 'no error');
        Observer.Finish();
    end;
}
