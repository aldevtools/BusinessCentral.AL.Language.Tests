// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.security.user.user-permissions
// Scope: in-scope
// Fixtures used: Probe Observer (69160); the corpus permission set ALTPermissionSet (60022, _fixtures/ALTPermissionSet.permissionset.al).
// Probe: al-runner issue 5796 (aldevtools/BusinessCentral.AL.Runner). "User Permissions" (152) HasUserPermissionSetAssigned: codeunit 153
//   first looks for an Access Control row (company '' or the given company, same scope and app id); when there is none and the user has a
//   User row, it asks the platform's NavUserAccountHelper.IsPermissionSetAssigned, first with company '' and then with the given company.
//   Pinned here, for the session user and the app's own module id: a set the user does not hold (the reporter's shape), a set assigned
//   directly for all companies, for the current company and for another company, asked with the current company and with company '';
//   an assignment with another app id; an unknown user; SUPER. Access Control rows are written in the test's own transaction (test
//   isolation rolls them back). Not pinned: an assignment through a security group (the CI container has no Entra or Windows groups).
// BC versions: 27, 28, 29. Object id 88722.

codeunit 88722 "LT RV Permission Set Assigned"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SetTok: Label 'ALTPERMISSIONSET', Locked = true;
        OtherCompanyTok: Label 'LT RV Other Company', Locked = true;

    local procedure OwnAppId(): Guid
    var
        ModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        exit(ModuleInfo.Id());
    end;

    local procedure Assign(Company: Text; AppId: Guid)
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.Init();
        AccessControl."User Security ID" := UserSecurityId();
        AccessControl."Role ID" := SetTok;
        AccessControl."Company Name" := CopyStr(Company, 1, MaxStrLen(AccessControl."Company Name"));
        AccessControl.Scope := AccessControl.Scope::System;
        AccessControl."App ID" := AppId;
        AccessControl.Insert();
    end;

    local procedure Has(Company: Text; AppId: Guid): Text
    var
        AccessControl: Record "Access Control";
        UserPermissions: Codeunit "User Permissions";
    begin
        exit(Format(UserPermissions.HasUserPermissionSetAssigned(UserSecurityId(), Company, SetTok, AccessControl.Scope::System, AppId)));
    end;

    local procedure HeldBefore(): Text
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId());
        AccessControl.SetRange("Role ID", SetTok);
        exit(Format(not AccessControl.IsEmpty()));
    end;

    // al-runner issue 5796: the reporter's shape, a set the session user does not hold.
    [Test]
    procedure RV_HasSet_NotHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows before', HeldBefore());
        Observer.Observe('current company', Has(CompanyName(), OwnAppId()));
        Observer.Observe('no company', Has('', OwnAppId()));
        Observer.Observe('null app id', Has(CompanyName(), NullGuidValue()));
        Observer.Expect('rows before', 'No');
        Observer.Expect('current company', 'No');
        Observer.Expect('no company', 'No');
        Observer.Expect('null app id', 'No');
        Observer.Verify();
    end;

    // Assigned for all companies (Company Name '').
    [Test]
    procedure RV_HasSet_AssignedAllCompanies()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Assign('', OwnAppId());
        Observer.Observe('current company', Has(CompanyName(), OwnAppId()));
        Observer.Observe('no company', Has('', OwnAppId()));
        Observer.Observe('other company', Has(OtherCompanyTok, OwnAppId()));
        Observer.Expect('current company', 'Yes');
        Observer.Expect('no company', 'Yes');
        Observer.Expect('other company', 'Yes');
        Observer.Verify();
    end;

    // Assigned for the current company only.
    [Test]
    procedure RV_HasSet_AssignedCurrentCompany()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Assign(CompanyName(), OwnAppId());
        Observer.Observe('current company', Has(CompanyName(), OwnAppId()));
        Observer.Observe('no company', Has('', OwnAppId()));
        Observer.Observe('other company', Has(OtherCompanyTok, OwnAppId()));
        Observer.Expect('current company', 'Yes');
        Observer.Expect('no company', 'No');
        Observer.Expect('other company', 'No');
        Observer.Verify();
    end;

    // Assigned for another company only.
    [Test]
    procedure RV_HasSet_AssignedOtherCompany()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Assign(OtherCompanyTok, OwnAppId());
        Observer.Observe('current company', Has(CompanyName(), OwnAppId()));
        Observer.Observe('no company', Has('', OwnAppId()));
        Observer.Observe('other company', Has(OtherCompanyTok, OwnAppId()));
        Observer.Expect('current company', 'No');
        Observer.Expect('no company', 'No');
        Observer.Expect('other company', 'Yes');
        Observer.Verify();
    end;

    // Assigned with the null app id, asked with the own app id, and the other way round.
    [Test]
    procedure RV_HasSet_AssignedOtherAppId()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Assign('', NullGuidValue());
        Observer.Observe('asked own app id', Has(CompanyName(), OwnAppId()));
        Observer.Observe('asked null app id', Has(CompanyName(), NullGuidValue()));
        Observer.Expect('asked own app id', 'No');
        Observer.Expect('asked null app id', 'Yes');
        Observer.Verify();
    end;

    // A security id that belongs to no user, and SUPER for the session user.
    [Test]
    procedure RV_HasSet_UnknownUserAndSuper()
    var
        Observer: Codeunit "Probe Observer";
        AccessControl: Record "Access Control";
        UserPermissions: Codeunit "User Permissions";
    begin
        Observer.Observe('unknown user', Format(UserPermissions.HasUserPermissionSetAssigned(CreateGuid(), CompanyName(), SetTok, AccessControl.Scope::System, OwnAppId())));
        Observer.Observe('super', Format(UserPermissions.HasUserPermissionSetAssigned(UserSecurityId(), CompanyName(), 'SUPER', AccessControl.Scope::System, NullGuidValue())));
        Observer.Expect('unknown user', 'No');
        Observer.Expect('super', 'Yes');
        Observer.Verify();
    end;

    local procedure NullGuidValue(): Guid
    var
        NullId: Guid;
    begin
        exit(NullId);
    end;
}
