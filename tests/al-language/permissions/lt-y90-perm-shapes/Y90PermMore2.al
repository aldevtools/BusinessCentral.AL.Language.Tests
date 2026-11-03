// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y90PermMoreObjects.al (94880-94899); Y90PermObjects.al; Permissions Mock (131006).
// Probe (owner items 1, 3 and 4): (1) the session user's rows in Access Control and which system tables hold permissions; what happens to Customer and to an
//   own table after the SUPER row of the user is deleted, and after a row for an own permission set replaces it (all inside asserterror, so nothing stays);
//   (3) a tenant permission set created in code (Tenant Permission Set and Tenant Permission rows), assigned with the mock, then widened, reduced and removed;
//   (4) the license ceiling: Modify of G/L Entry directly under SUPER, under a set that grants direct M, from a codeunit with Permissions = tabledata
//   "G/L Entry" = m, and under a set that grants only indirect m.
// BC versions: 27, 28, 29

codeunit 94897 "LT Y90 Perm More2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y90_License_GLEntryModify()
    var
        WasStarted: Boolean;
        GLEntry: Record "G/L Entry";
    begin
        if GLEntry.IsEmpty() then begin
            GLEntry.Init();
            GLEntry."Entry No." := 1;
            GLEntry.Insert();
        end;
        WasStarted := StartMock();
        Run('super_direct', '', 1);
        Run('direct_M_direct', 'LT Y90 L Direct', 1);
        Run('direct_M_codeunit', 'LT Y90 L Direct', 2);
        Run('indirect_m_direct', 'LT Y90 L Indir', 1);
        Run('indirect_m_codeunit', 'LT Y90 L Indir', 2);
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y90_AccessControl_Tables()
    begin
        Run('tables', '', 3);
        Run('own_rows', '', 4);
        Observer.Finish();
    end;

    [Test]
    procedure Y90_AccessControl_RemoveSuper()
    begin
        Run('remove_super', '', 5);
        Run('replace_super', '', 6);
        Observer.Finish();
    end;

    [Test]
    procedure Y90_TenantSet_Lifecycle()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        CreateTenantSet(false);
        Run('ts_read_only', 'LT Y90 TS', 7);
        CreateTenantSet(true);
        Run('ts_widened', 'LT Y90 TS', 7);
        ReduceTenantSet();
        Run('ts_reduced', 'LT Y90 TS', 7);
        RemoveTenantSet();
        Run('ts_removed', 'LT Y90 TS', 7);
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    local procedure Run(Tag: Text; SetName: Code[20]; Which: Integer)
    var
        ErrorText: Text;
        ErrorCode: Text;
    begin
        Mock.ClearAssignments();
        if SetName <> '' then
            Mock.SetExactPermissionSet(SetName);
        asserterror Op(Which);
        ErrorText := GetLastErrorText();
        ErrorCode := GetLastErrorCode();
        Mock.ClearAssignments();
        ClearLastError();
        if ErrorText.StartsWith('LT Y90 ok') then
            Observer.Observe(Tag, ErrorText)
        else
            Observer.Observe(Tag, ErrorText + ' | ' + ErrorCode);
    end;

    local procedure CreateTenantSet(WithInsert: Boolean)
    var
        TenantSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
        Zero: Guid;
    begin
        if not TenantSet.Get(Zero, 'LT Y90 TS') then begin
            TenantSet."App ID" := Zero;
            TenantSet."Role ID" := 'LT Y90 TS';
            TenantSet.Name := 'LT Y90 tenant set';
            TenantSet.Insert();
        end;
        if not TenantPermission.Get(Zero, 'LT Y90 TS', TenantPermission."Object Type"::"Table Data", Database::"LT Y90 Row") then begin
            TenantPermission."App ID" := Zero;
            TenantPermission."Role ID" := 'LT Y90 TS';
            TenantPermission."Object Type" := TenantPermission."Object Type"::"Table Data";
            TenantPermission."Object ID" := Database::"LT Y90 Row";
            TenantPermission."Read Permission" := TenantPermission."Read Permission"::Yes;
            TenantPermission.Insert();
        end;
        if WithInsert then begin
            TenantPermission."Insert Permission" := TenantPermission."Insert Permission"::Yes;
            TenantPermission.Modify();
        end;
    end;

    local procedure ReduceTenantSet()
    var
        TenantPermission: Record "Tenant Permission";
        Zero: Guid;
    begin
        TenantPermission.Get(Zero, 'LT Y90 TS', TenantPermission."Object Type"::"Table Data", Database::"LT Y90 Row");
        TenantPermission."Insert Permission" := TenantPermission."Insert Permission"::" ";
        TenantPermission.Modify();
    end;

    local procedure RemoveTenantSet()
    var
        TenantSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
    begin
        TenantPermission.SetRange("Role ID", 'LT Y90 TS');
        TenantPermission.DeleteAll();
        TenantSet.SetRange("Role ID", 'LT Y90 TS');
        TenantSet.DeleteAll();
    end;

    [TryFunction]
    local procedure TryRead(var Result: Text)
    var
        Customer: Record Customer;
    begin
        Result := Format(Customer.FindFirst());
    end;

    [TryFunction]
    local procedure TryInsertRow(var Result: Text)
    var
        Row: Record "LT Y90 Row";
    begin
        Row.Id := 777;
        Row.Insert();
        Result := 'inserted';
    end;

    local procedure Describe(): Text
    var
        Text1: Text;
        Text2: Text;
    begin
        if TryRead(Text1) then
            Text1 := 'customer read ' + Text1
        else begin
            Text1 := 'customer read error: ' + GetLastErrorText();
            ClearLastError();
        end;
        if TryInsertRow(Text2) then
            Text2 := 'own row ' + Text2
        else begin
            Text2 := 'own row error: ' + GetLastErrorText();
            ClearLastError();
        end;
        exit(Text1 + '; ' + Text2);
    end;

    local procedure Op(Which: Integer)
    var
        GLEntry: Record "G/L Entry";
        GLMod: Codeunit "LT Y90 GL Mod";
        AccessControl: Record "Access Control";
        UserRec: Record User;
        PermSet: Record "Permission Set";
        Aggregate: Record "Aggregate Permission Set";
        TenantSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
        Expanded: Record "Expanded Permission";
        Info: ModuleInfo;
        Row: Record "LT Y90 Row";
        Result: Text;
        Roles: Text;
    begin
        case Which of
            1:
                begin
                    GLEntry.FindFirst();
                    GLEntry.Modify();
                    Result := 'modified';
                end;
            2:
                begin
                    GLMod.ModifyFirst();
                    Result := 'modified';
                end;
            3:
                Result := 'AccessControl>0 ' + Format(not AccessControl.IsEmpty()) + ' User>0 ' + Format(not UserRec.IsEmpty()) + ' PermissionSet>0 ' +
                    Format(not PermSet.IsEmpty()) + ' Aggregate>0 ' + Format(not Aggregate.IsEmpty()) + ' TenantSet>0 ' + Format(not TenantSet.IsEmpty()) +
                    ' TenantPermission>0 ' + Format(not TenantPermission.IsEmpty()) + ' Expanded>0 ' + Format(not Expanded.IsEmpty());
            4:
                begin
                    AccessControl.SetRange("User Security ID", UserSecurityId());
                    if AccessControl.FindSet() then
                        repeat
                            Roles += AccessControl."Role ID" + '/' + Format(AccessControl.Scope) + ' ';
                        until AccessControl.Next() = 0;
                    Result := 'rows ' + Format(AccessControl.Count()) + ' roles ' + Roles;
                end;
            5:
                begin
                    AccessControl.SetRange("User Security ID", UserSecurityId());
                    AccessControl.SetRange("Role ID", 'SUPER');
                    AccessControl.DeleteAll();
                    Result := 'after delete: ' + Describe();
                end;
            6:
                begin
                    NavApp.GetCurrentModuleInfo(Info);
                    AccessControl.SetRange("User Security ID", UserSecurityId());
                    AccessControl.SetRange("Role ID", 'SUPER');
                    AccessControl.DeleteAll();
                    Clear(AccessControl);
                    AccessControl."User Security ID" := UserSecurityId();
                    AccessControl."Role ID" := 'LT Y90 I Base';
                    AccessControl.Scope := AccessControl.Scope::System;
                    AccessControl."App ID" := Info.Id();
                    AccessControl.Insert();
                    Result := 'after replace: ' + Describe();
                end;
            7:
                begin
                    Row.DeleteAll();
                    Result := Describe();
                end;
        end;
        Error('LT Y90 ok %1', Result);
    end;

    local procedure StartMock() WasStarted: Boolean
    begin
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
    end;

    local procedure RestoreMock(WasStarted: Boolean)
    begin
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
    end;
}
