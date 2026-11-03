// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y90PermMoreObjects.al (94880-94899); Y90PermObjects.al; Permissions Mock (131006).
// Probe (owner items 1, 3 and 4): (1) the session user's rows in Access Control and which system tables hold permissions; (3) a tenant permission set created
//   in code (Tenant Permission Set and Tenant Permission rows) offered to the mock;
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
        Observer.Expect('super_direct',
            'LT Y90 ok modified');
        Observer.Expect('direct_M_direct',
            'LT Y90 ok modified');
        Observer.Expect('direct_M_codeunit',
            'LT Y90 ok modified');
        Observer.Expect('indirect_m_direct',
            'Sorry, the current permissions prevented the action. (TableData 17 G/L Entry Modify: AL Language Coverage Tests) | DB:ClientModifyDenied');
        Observer.Expect('indirect_m_codeunit',
            'LT Y90 ok modified');
        Observer.Verify();
    end;

    [Test]
    procedure Y90_AccessControl_Tables()
    begin
        Run('tables', '', 3);
        Run('own_rows', '', 4);
        Observer.Expect('tables',
            'LT Y90 ok AccessControl>0 Yes User>0 Yes PermissionSet>0 Yes Aggregate>0 Yes Expanded>0 Yes');
        Observer.Expect('own_rows',
            'LT Y90 ok rows 1 roles SUPER/System ');
        Observer.Verify();
    end;

    [Test]
    procedure Y90_TenantSet_Mock()
    var
        WasStarted: Boolean;
        ErrorText: Text;
    begin
        WasStarted := StartMock();
        CreateTenantSet(false);
        ClearLastError();
        asserterror Mock.SetExactPermissionSet('LT Y90 TS');
        ErrorText := GetLastErrorText();
        ClearLastError();
        Observer.Observe('mock_exact', ErrorText);
        asserterror Mock.Set('LT Y90 TS');
        ErrorText := GetLastErrorText();
        ClearLastError();
        Observer.Observe('mock_set', ErrorText);
        RestoreMock(WasStarted);
        Observer.Expect('mock_exact',
            'The Permission Set does not exist. Identification fields and values: Role ID=''LT Y90 TS''');
        Observer.Expect('mock_set',
            'The Permission Set does not exist. Identification fields and values: Role ID=''LT Y90 TS''');
        Observer.Verify();
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

    local procedure Describe(): Text
    var
        Text1: Text;
        Text2: Text;
    begin
        ClearLastError();
        if TryRead(Text1) then
            Text1 := 'customer read ' + Text1
        else begin
            Text1 := 'customer read error: ' + GetLastErrorText();
            ClearLastError();
        end;
        if Codeunit.Run(Codeunit::"LT Y90 Try Insert") then
            Text2 := 'own row inserted'
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
                    Format(not PermSet.IsEmpty()) + ' Aggregate>0 ' + Format(not Aggregate.IsEmpty()) + ' Expanded>0 ' + Format(not Expanded.IsEmpty());
            4:
                begin
                    AccessControl.SetRange("User Security ID", UserSecurityId());
                    if AccessControl.FindSet() then
                        repeat
                            Roles += AccessControl."Role ID" + '/' + Format(AccessControl.Scope) + ' ';
                        until AccessControl.Next() = 0;
                    Result := 'rows ' + Format(AccessControl.Count()) + ' roles ' + Roles;
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
