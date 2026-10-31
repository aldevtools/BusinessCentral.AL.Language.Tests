// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-permissions
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y19PermObjects.al (91900-91935); Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 probe P0 (stage 0), writer Y19: SUPER through the mock. Permissions Mock.Set('SUPER') (All Objects plus
//   SUPER) and SetExactPermissionSet('SUPER') (SUPER alone): an insert into an own table, a direct insert into G/L Entry and an insert into
//   Tenant Media (each inside asserterror, ending with the own error 'LT Y19 ok', so nothing stays), ReadPermission and WritePermission of
//   each table, and "User Permissions".GetEffectivePermission for TableData, Codeunit, Page and Report.
// BC versions: 27, 28, 29

codeunit 91951 "LT Y19 Perm Super"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y19 Perm Helper";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y19_P0_SetSuper()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        Mock.Set('SUPER');
        ObserveAll(Observer, false);
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y19_P0_SetExactSuper()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        Mock.SetExactPermissionSet('SUPER');
        ObserveAll(Observer, true);
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    local procedure ObserveAll(var Observer: Codeunit "Probe Observer"; Exact: Boolean)
    var
        Row: Record "LT Y19 Row";
        GLEntry: Record "G/L Entry";
        TenantMedia: Record "Tenant Media";
    begin
        Observer.Observe('own_read_permission', Format(Row.ReadPermission()));
        Observer.Observe('own_write_permission', Format(Row.WritePermission()));
        Observer.Observe('gl_entry_read_permission', Format(GLEntry.ReadPermission()));
        Observer.Observe('gl_entry_write_permission', Format(GLEntry.WritePermission()));
        Observer.Observe('tenant_media_read_permission', Format(TenantMedia.ReadPermission()));
        Observer.Observe('tenant_media_write_permission', Format(TenantMedia.WritePermission()));
        Observer.Observe('effective_own_table_data', Helper.Rights(0, Database::"LT Y19 Row"));
        Observer.Observe('effective_gl_entry', Helper.Rights(0, Database::"G/L Entry"));
        Observer.Observe('effective_tenant_media', Helper.Rights(0, Database::"Tenant Media"));
        Observer.Observe('effective_codeunit', Helper.Rights(5, Codeunit::"Gen. Jnl.-Post Line"));
        Observer.Observe('effective_own_codeunit', Helper.Rights(5, Codeunit::"LT Y19 Perm Super"));
        Observer.Observe('effective_page', Helper.Rights(8, Page::"Customer Card"));
        Observer.Observe('effective_report', Helper.Rights(3, Report::"Trial Balance"));
        asserterror InsertOwn();
        Observer.ObserveError('own_insert');
        Reassign(Exact);
        asserterror InsertGLEntry();
        Observer.ObserveError('gl_entry_insert');
        Reassign(Exact);
        asserterror InsertTenantMedia();
        Observer.ObserveError('tenant_media_insert');
    end;

    local procedure Reassign(Exact: Boolean)
    begin
        if Exact then
            Mock.SetExactPermissionSet('SUPER')
        else
            Mock.Set('SUPER');
    end;

    local procedure InsertOwn()
    var
        Row: Record "LT Y19 Row";
    begin
        Row.Id := 91951;
        Row.Insert();
        Error('LT Y19 ok own');
    end;

    local procedure InsertGLEntry()
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry."Entry No." := 2147483000;
        GLEntry.Description := 'LT Y19';
        GLEntry.Insert();
        Error('LT Y19 ok gl entry');
    end;

    local procedure InsertTenantMedia()
    var
        TenantMedia: Record "Tenant Media";
    begin
        TenantMedia.Init();
        TenantMedia.ID := CreateGuid();
        TenantMedia.Description := 'LT Y19';
        TenantMedia.Insert();
        Error('LT Y19 ok tenant media');
    end;
}
