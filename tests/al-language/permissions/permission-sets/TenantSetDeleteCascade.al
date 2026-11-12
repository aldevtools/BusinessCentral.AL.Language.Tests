// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); test codeunit 75191.
// Probe: al-runner issue 7854. What a Delete of a TENANT permission set does to its Tenant Permission and Tenant Permission Set Rel.
//   rows. System Application's Permission Set page deletes only the set row; Microsoft's Permission Import Export Tests read the
//   set's permissions after TenantPermissionSet.DeleteAll(). Each test uses its own role ids (prefix TSDC) and cleans them first.
//   Measured: Delete, Delete(true) and DeleteAll (filtered to one set) of a set that has its own Tenant Permission rows, a Rel. row
//   that includes another set, and a Rel. row of another set that includes it; the rows left in both tables for the deleted set and
//   for a second set that is not deleted.
// BC versions: 27, 28, 29 (observe form; the values come from the measurement run)

codeunit 75191 "XP TSDC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure AddSet(RoleId: Code[20])
    var
        TenantSet: Record "Tenant Permission Set";
    begin
        TenantSet."App ID" := '00000000-0000-0000-0000-000000000000';
        TenantSet."Role ID" := RoleId;
        TenantSet.Name := CopyStr(RoleId, 1, 30);
        TenantSet.Insert();
    end;

    local procedure AddPerm(RoleId: Code[20]; TableId: Integer)
    var
        TenantPerm: Record "Tenant Permission";
    begin
        TenantPerm."App ID" := '00000000-0000-0000-0000-000000000000';
        TenantPerm."Role ID" := RoleId;
        TenantPerm."Object Type" := TenantPerm."Object Type"::"Table Data";
        TenantPerm."Object ID" := TableId;
        TenantPerm."Read Permission" := TenantPerm."Read Permission"::Yes;
        TenantPerm.Insert();
    end;

    local procedure AddRel(RoleId: Code[20]; Related: Code[20])
    var
        Rel: Record "Tenant Permission Set Rel.";
    begin
        Rel."App ID" := '00000000-0000-0000-0000-000000000000';
        Rel."Role ID" := RoleId;
        Rel."Related App ID" := '00000000-0000-0000-0000-000000000000';
        Rel."Related Role ID" := Related;
        Rel."Related Scope" := Rel."Related Scope"::Tenant;
        Rel.Insert();
    end;

    local procedure Clean()
    var
        TenantSet: Record "Tenant Permission Set";
        TenantPerm: Record "Tenant Permission";
        Rel: Record "Tenant Permission Set Rel.";
    begin
        TenantPerm.SetFilter("Role ID", 'TSDC*');
        TenantPerm.DeleteAll();
        Rel.SetFilter("Role ID", 'TSDC*');
        Rel.DeleteAll();
        TenantSet.SetFilter("Role ID", 'TSDC*');
        TenantSet.DeleteAll();
    end;

    local procedure Setup()
    begin
        Clean();
        AddSet('TSDC GONE');
        AddSet('TSDC KEPT');
        AddPerm('TSDC GONE', 18);
        AddPerm('TSDC GONE', 23);
        AddPerm('TSDC KEPT', 18);
        AddRel('TSDC GONE', 'TSDC KEPT');
        AddRel('TSDC KEPT', 'TSDC GONE');
    end;

    local procedure Left(): Text
    var
        TenantSet: Record "Tenant Permission Set";
        TenantPerm: Record "Tenant Permission";
        Rel: Record "Tenant Permission Set Rel.";
        Result: Text;
    begin
        TenantSet.SetFilter("Role ID", 'TSDC*');
        Result := 'sets=' + Format(TenantSet.Count());
        TenantPerm.SetRange("Role ID", 'TSDC GONE');
        Result += ' perms gone=' + Format(TenantPerm.Count());
        TenantPerm.SetRange("Role ID", 'TSDC KEPT');
        Result += ' perms kept=' + Format(TenantPerm.Count());
        Rel.SetRange("Role ID", 'TSDC GONE');
        Result += ' rel of gone=' + Format(Rel.Count());
        Rel.SetRange("Role ID", 'TSDC KEPT');
        Result += ' rel of kept=' + Format(Rel.Count());
        exit(Result);
    end;

    [Test]
    procedure TSDC_Delete()
    var
        TenantSet: Record "Tenant Permission Set";
    begin
        Setup();
        TenantSet.Get('00000000-0000-0000-0000-000000000000', 'TSDC GONE');
        TenantSet.Delete();
        Observer.Observe('after Delete', Left());
        Clean();
        Observer.Finish();
    end;

    [Test]
    procedure TSDC_DeleteTrue()
    var
        TenantSet: Record "Tenant Permission Set";
    begin
        Setup();
        TenantSet.Get('00000000-0000-0000-0000-000000000000', 'TSDC GONE');
        TenantSet.Delete(true);
        Observer.Observe('after Delete(true)', Left());
        Clean();
        Observer.Finish();
    end;

    [Test]
    procedure TSDC_DeleteAll()
    var
        TenantSet: Record "Tenant Permission Set";
    begin
        Setup();
        TenantSet.SetRange("Role ID", 'TSDC GONE');
        TenantSet.DeleteAll();
        Observer.Observe('after DeleteAll', Left());
        Clean();
        Observer.Finish();
    end;
}
