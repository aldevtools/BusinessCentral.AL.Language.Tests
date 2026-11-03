// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); codeunit 93545 (writer Y67, gap cycle 6 follow-up)
// Probe: how the platform composes the Expanded Permission rows of TENANT permission sets: a set with its own Tenant Permission rows, a set that
//   includes another tenant set (Tenant Permission Set Rel., Type Include), a set that EXCLUDES another tenant set (Type Exclude), a set whose
//   own Tenant Permission has Type Exclude, two included sets that overlap, an included set that is included twice (diamond), and the Scope
//   and App ID columns of the rows. Each test uses its own role ids and reads only after all inserts (a grant inserted after a set's first
//   read is not seen by the next read: permissions/TestMetadataExpandedPermission.al:196-207). Metadata sets with an excluded set are pinned by
//   codeunit/lt-x-object-props/XObjectProps.al PermissionSet_ExcludedPermissionSets_RemovedFromEffectiveSet; Security Filter by
//   permissions/lt-y48-security-filter/Y48ExpandedSecurityFilter.al.
// BC versions: 27, 28, 29

codeunit 93545 "LT Y67 Perm Compose"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure AddSet(RoleId: Code[20])
    var
        TenantSet: Record "Tenant Permission Set";
    begin
        TenantSet."App ID" := '00000000-0000-0000-0000-000000000000';
        TenantSet."Role ID" := RoleId;
        TenantSet.Name := CopyStr(RoleId, 1, 30);
        TenantSet.Insert();
    end;

    local procedure AddPerm(RoleId: Code[20]; TableId: Integer; Read: Option; Insert: Option; Modify: Option; PermType: Option)
    var
        TenantPerm: Record "Tenant Permission";
    begin
        TenantPerm."App ID" := '00000000-0000-0000-0000-000000000000';
        TenantPerm."Role ID" := RoleId;
        TenantPerm."Object Type" := TenantPerm."Object Type"::"Table Data";
        TenantPerm."Object ID" := TableId;
        TenantPerm."Read Permission" := Read;
        TenantPerm."Insert Permission" := Insert;
        TenantPerm."Modify Permission" := Modify;
        TenantPerm.Type := PermType;
        TenantPerm.Insert();
    end;

    local procedure AddRel(RoleId: Code[20]; Related: Code[20]; RelType: Option)
    var
        Rel: Record "Tenant Permission Set Rel.";
    begin
        Rel."App ID" := '00000000-0000-0000-0000-000000000000';
        Rel."Role ID" := RoleId;
        Rel."Related App ID" := '00000000-0000-0000-0000-000000000000';
        Rel."Related Role ID" := Related;
        Rel.Type := RelType;
        Rel."Related Scope" := Rel."Related Scope"::Tenant;
        Rel.Insert();
    end;

    // The Expanded Permission rows of a role for the three probe tables: Read, Insert, Modify as Format texts, and the scope.
    local procedure Rows(RoleId: Code[20]): Text
    var
        Expanded: Record "Expanded Permission";
        Result: Text;
    begin
        Expanded.SetRange("Role ID", RoleId);
        Expanded.SetRange("Object Type", Expanded."Object Type"::"Table Data");
        if Expanded.FindSet() then
            repeat
                Result += Format(Expanded."Object ID") + ':R=' + Format(Expanded."Read Permission") + ',I=' + Format(Expanded."Insert Permission") + ',M=' + Format(Expanded."Modify Permission") + ',' + Format(Expanded.Scope) + ' ';
            until Expanded.Next() = 0;
        if Result = '' then
            exit('no rows');
        exit(Result);
    end;

    local procedure Clean(Prefix: Text)
    var
        TenantSet: Record "Tenant Permission Set";
        TenantPerm: Record "Tenant Permission";
        Rel: Record "Tenant Permission Set Rel.";
    begin
        TenantSet.SetFilter("Role ID", Prefix + '*');
        TenantSet.DeleteAll();
        TenantPerm.SetFilter("Role ID", Prefix + '*');
        TenantPerm.DeleteAll();
        Rel.SetFilter("Role ID", Prefix + '*');
        Rel.DeleteAll();
    end;

    [Test]
    procedure Compose_OwnAndIncluded()
    var
        Observer: Codeunit "Probe Observer";
        Perm: Record "Tenant Permission";
    begin
        Clean('Y67A');
        AddSet('Y67A BASE');
        AddSet('Y67A MAIN');
        AddPerm('Y67A BASE', Database::Customer, 1, 1, 0, Perm.Type::Include);
        AddPerm('Y67A BASE', Database::Vendor, 1, 0, 0, Perm.Type::Include);
        AddPerm('Y67A MAIN', Database::Customer, 0, 0, 1, Perm.Type::Include);
        AddPerm('Y67A MAIN', Database::Item, 1, 1, 1, Perm.Type::Include);
        AddRel('Y67A MAIN', 'Y67A BASE', 0);
        Observer.Observe('base', Rows('Y67A BASE'));
        Observer.Observe('main includes base', Rows('Y67A MAIN'));
        Observer.Expect('base', '18:R=Yes,I=Yes,M= ,Tenant 23:R=Yes,I= ,M= ,Tenant ');
        Observer.Expect('main includes base', '18:R=Yes,I=Yes,M=Yes,Tenant 23:R=Yes,I= ,M= ,Tenant 27:R=Yes,I=Yes,M=Yes,Tenant ');
        Observer.Verify();
    end;

    [Test]
    procedure Compose_ExcludedSet()
    var
        Observer: Codeunit "Probe Observer";
        Perm: Record "Tenant Permission";
    begin
        Clean('Y67B');
        AddSet('Y67B BASE');
        AddSet('Y67B NEG');
        AddSet('Y67B MAIN');
        AddPerm('Y67B BASE', Database::Customer, 1, 1, 1, Perm.Type::Include);
        AddPerm('Y67B BASE', Database::Vendor, 1, 1, 0, Perm.Type::Include);
        AddPerm('Y67B NEG', Database::Customer, 0, 1, 0, Perm.Type::Include);
        AddPerm('Y67B NEG', Database::Vendor, 1, 1, 1, Perm.Type::Include);
        AddRel('Y67B MAIN', 'Y67B BASE', 0);
        AddRel('Y67B MAIN', 'Y67B NEG', 1);
        Observer.Observe('neg', Rows('Y67B NEG'));
        Observer.Observe('main includes base excludes neg', Rows('Y67B MAIN'));
        Observer.Expect('neg', '18:R= ,I=Yes,M= ,Tenant 23:R=Yes,I=Yes,M=Yes,Tenant ');
        Observer.Expect('main includes base excludes neg', '18:R=Yes,I= ,M=Yes,Tenant ');
        Observer.Verify();
    end;

    [Test]
    procedure Compose_ExcludePermissionRow()
    var
        Observer: Codeunit "Probe Observer";
        Perm: Record "Tenant Permission";
    begin
        Clean('Y67C');
        AddSet('Y67C BASE');
        AddSet('Y67C MAIN');
        AddPerm('Y67C BASE', Database::Customer, 1, 1, 1, Perm.Type::Include);
        AddPerm('Y67C MAIN', Database::Customer, 0, 1, 0, Perm.Type::Exclude);
        AddPerm('Y67C MAIN', Database::Item, 1, 0, 0, Perm.Type::Exclude);
        AddRel('Y67C MAIN', 'Y67C BASE', 0);
        Observer.Observe('own exclude only', Rows('Y67C BASE'));
        Observer.Observe('main with exclude rows', Rows('Y67C MAIN'));
        Observer.Expect('own exclude only', '18:R=Yes,I=Yes,M=Yes,Tenant ');
        Observer.Expect('main with exclude rows', '18:R=Yes,I= ,M=Yes,Tenant ');
        Observer.Verify();
    end;

    [Test]
    procedure Compose_OverlapAndDiamond()
    var
        Observer: Codeunit "Probe Observer";
        Perm: Record "Tenant Permission";
    begin
        Clean('Y67D');
        AddSet('Y67D LEAF');
        AddSet('Y67D LEFT');
        AddSet('Y67D RIGHT');
        AddSet('Y67D TOP');
        AddPerm('Y67D LEAF', Database::Customer, 1, 0, 0, Perm.Type::Include);
        AddPerm('Y67D LEFT', Database::Customer, 0, 1, 0, Perm.Type::Include);
        AddPerm('Y67D RIGHT', Database::Customer, 0, 0, 1, Perm.Type::Include);
        AddRel('Y67D LEFT', 'Y67D LEAF', 0);
        AddRel('Y67D RIGHT', 'Y67D LEAF', 0);
        AddRel('Y67D TOP', 'Y67D LEFT', 0);
        AddRel('Y67D TOP', 'Y67D RIGHT', 0);
        Observer.Observe('left', Rows('Y67D LEFT'));
        Observer.Observe('right', Rows('Y67D RIGHT'));
        Observer.Observe('top (diamond)', Rows('Y67D TOP'));
        Observer.Expect('left', '18:R=Yes,I=Yes,M= ,Tenant ');
        Observer.Expect('right', '18:R=Yes,I= ,M=Yes,Tenant ');
        Observer.Expect('top (diamond)', '18:R=Yes,I=Yes,M=Yes,Tenant ');
        Observer.Verify();
    end;

    [Test]
    procedure Compose_IncludedSetMissing_And_Cycle()
    var
        Observer: Codeunit "Probe Observer";
        Perm: Record "Tenant Permission";
    begin
        Clean('Y67E');
        AddSet('Y67E ONE');
        AddSet('Y67E TWO');
        AddPerm('Y67E ONE', Database::Customer, 1, 0, 0, Perm.Type::Include);
        AddPerm('Y67E TWO', Database::Vendor, 1, 0, 0, Perm.Type::Include);
        AddRel('Y67E ONE', 'Y67E MISSING', 0);
        AddRel('Y67E ONE', 'Y67E TWO', 0);
        AddRel('Y67E TWO', 'Y67E ONE', 0);
        Observer.Observe('one (missing and cycle)', Rows('Y67E ONE'));
        Observer.Observe('two (cycle)', Rows('Y67E TWO'));
        Observer.Expect('one (missing and cycle)', '18:R=Yes,I= ,M= ,Tenant 23:R=Yes,I= ,M= ,Tenant ');
        Observer.Expect('two (cycle)', '18:R=Yes,I= ,M= ,Tenant 23:R=Yes,I= ,M= ,Tenant ');
        Observer.Verify();
    end;
}
