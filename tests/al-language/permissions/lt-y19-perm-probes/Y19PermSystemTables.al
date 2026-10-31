// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-permissions
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y19PermObjects.al; Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 probe P13 (stage 1), writer Y19: system tables under a narrow set. Permissions Mock.Set of an own set that
//   names no system table (plus All Objects): insert into Tenant Media, IsolatedStorage.Set/Get/Contains/Delete (the API), and reads of
//   AllObj, Field and Company. Writes end in the own error 'LT Y19 ok', so nothing stays.
// BC versions: 27, 28, 29

codeunit 91954 "LT Y19 Perm System Tables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y19 Perm Helper";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y19_P13_SystemTablesNarrowSet()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        RunCase(Observer, 'tenant_media_insert', 1);
        RunCase(Observer, 'isolated_storage_set', 2);
        RunCase(Observer, 'isolated_storage_set_company', 3);
        RunCase(Observer, 'allobj_read', 4);
        RunCase(Observer, 'field_read', 5);
        RunCase(Observer, 'company_read', 6);
        RunCase(Observer, 'tenant_media_read', 7);
        Mock.Set('LT Y19 R');
        Observer.Observe('tenant_media_read_permission', Format(ReadPermissionOf(Database::"Tenant Media")));
        Observer.Observe('tenant_media_write_permission', Format(WritePermissionOf(Database::"Tenant Media")));
        Observer.Observe('allobj_read_permission', Format(ReadPermissionOf(Database::AllObj)));
        Observer.Observe('field_read_permission', Format(ReadPermissionOf(Database::Field)));
        Observer.Observe('company_read_permission', Format(ReadPermissionOf(Database::Company)));
        Observer.Observe('company_write_permission', Format(WritePermissionOf(Database::Company)));
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Name: Text; Which: Integer)
    begin
        Mock.ClearAssignments();
        Mock.Set('LT Y19 R');
        asserterror Op(Which);
        Observer.ObserveError(Name);
        Mock.ClearAssignments();
    end;

    local procedure ReadPermissionOf(TableId: Integer): Boolean
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableId);
        exit(RecRef.ReadPermission());
    end;

    local procedure WritePermissionOf(TableId: Integer): Boolean
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableId);
        exit(RecRef.WritePermission());
    end;

    local procedure Op(Which: Integer)
    var
        TenantMedia: Record "Tenant Media";
        AllObj: Record AllObj;
        FieldRec: Record Field;
        Company: Record Company;
        Value: Text;
        Result: Text;
    begin
        case Which of
            1:
                begin
                    TenantMedia.Init();
                    TenantMedia.ID := CreateGuid();
                    TenantMedia.Description := 'LT Y19';
                    TenantMedia.Insert();
                end;
            2:
                begin
                    Result := Format(IsolatedStorage.Set('LTY19Key', 'v1'));
                    Result += ' ' + Format(IsolatedStorage.Get('LTY19Key', Value)) + ' ' + Value;
                    Result += ' ' + Format(IsolatedStorage.Contains('LTY19Key'));
                    Result += ' ' + Format(IsolatedStorage.Delete('LTY19Key'));
                end;
            3:
                begin
                    Result := Format(IsolatedStorage.Set('LTY19Key', 'v2', DataScope::Company));
                    Result += ' ' + Format(IsolatedStorage.Get('LTY19Key', DataScope::Company, Value)) + ' ' + Value;
                    Result += ' ' + Format(IsolatedStorage.Delete('LTY19Key', DataScope::Company));
                end;
            4:
                begin
                    AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
                    AllObj.SetRange("Object ID", Database::"LT Y19 Row");
                    Result := Format(AllObj.FindFirst()) + ' ' + AllObj."Object Name";
                end;
            5:
                begin
                    FieldRec.SetRange(TableNo, Database::"LT Y19 Row");
                    Result := Format(FieldRec.Count() > 0);
                end;
            6:
                Result := Format(Company.Get(CompanyName()));
            7:
                Result := Format(TenantMedia.IsEmpty() or true);
        end;
        Error('LT Y19 ok %1', Result);
    end;
}
