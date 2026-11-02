// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained objects 92922 - 92925
// Probe: gap cycle 5, spec G5-03 (writer Y48). "Security Filter" (column 12) of Expanded Permission rows: of a permissionset object
//        (a metadata set has no syntax for a filter), of a tenant set whose Tenant Permission has a filter set by Evaluate, of a tenant set
//        that includes another tenant set, and after the filter changes. Microsoft's Permission Set Copy copies
//        `TenantPermission."Security Filter" := ExpandedPermission."Security Filter"`.
//        TestMetadataExpandedPermission.al:196-207 pins that a grant inserted after a set's first read is not seen by the next read:
//        each test uses its own role ids and reads only after all inserts.
//        Asserted values: the CI containers BC 27.5, 28.5 and 29.0 and a SaaS sandbox BC 29, all the same.
// BC versions: 27, 28, 29

table 92922 "LT Y48 SF Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 92923 "LT Y48 SF Table2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

permissionset 92924 "LTY48PSMETA"
{
    Assignable = true;
    Permissions = tabledata "LT Y48 SF Table" = R,
        tabledata "LT Y48 SF Table2" = RIMD;
}

codeunit 92925 "LT Y48 Expanded Sec Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Rows(AppId: Guid; RoleId: Code[30]): Text
    var
        EP: Record "Expanded Permission";
        Result: Text;
    begin
        EP.SetRange("App ID", AppId);
        EP.SetRange("Role ID", RoleId);
        if not EP.FindSet() then
            exit('none');
        repeat
            Result += Format(EP."Object Type") + '|' + Format(EP."Object ID") + '|' + Format(EP."Read Permission") + ',' + Format(EP."Insert Permission") + ',' +
                Format(EP."Modify Permission") + ',' + Format(EP."Delete Permission") + ',' + Format(EP."Execute Permission") + '|[' +
                Format(EP."Security Filter") + ']|[' + Format(EP."Security Filter", 0, 9) + ']|' + Format(EP.Scope) + ';';
        until EP.Next() = 0;
        exit(Result);
    end;

    local procedure ObjectIds(): Text
    begin
        exit(StrSubstNo('ids: table=%1 table2=%2', Database::"LT Y48 SF Table", Database::"LT Y48 SF Table2"));
    end;

    local procedure NewSet(RoleId: Code[20])
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        NullGuid: Guid;
    begin
        TenantPermissionSet."App ID" := NullGuid;
        TenantPermissionSet."Role ID" := RoleId;
        TenantPermissionSet.Name := RoleId;
        TenantPermissionSet.Insert();
    end;

    // Every permission column's InitValue is Yes (TestMetadataExpandedPermission.al): the grant sets all five.
    local procedure Grant(RoleId: Code[20]; TableId: Integer; R: Boolean; I: Boolean; M: Boolean; D: Boolean; FilterText: Text)
    var
        TenantPermission: Record "Tenant Permission";
        NullGuid: Guid;
    begin
        TenantPermission."App ID" := NullGuid;
        TenantPermission."Role ID" := RoleId;
        TenantPermission."Object Type" := TenantPermission."Object Type"::"Table Data";
        TenantPermission."Object ID" := TableId;
        TenantPermission."Read Permission" := Perm(R);
        TenantPermission."Insert Permission" := Perm(I);
        TenantPermission."Modify Permission" := Perm(M);
        TenantPermission."Delete Permission" := Perm(D);
        TenantPermission."Execute Permission" := TenantPermission."Execute Permission"::" ";
        if FilterText <> '' then
            Evaluate(TenantPermission."Security Filter", FilterText);
        TenantPermission.Insert();
    end;

    local procedure Perm(Granted: Boolean): Integer
    begin
        if Granted then
            exit(1);
        exit(0);
    end;

    [Test]
    procedure EP_SecurityFilter_MetadataSet()
    var
        EP: Record "Expanded Permission";
        Observer: Codeunit "Probe Observer";
        ThisModule: ModuleInfo;
        NonBlank: Integer;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);
        Observer.Observe('object ids', ObjectIds());
        Observer.Observe('LTY48PSMETA', Rows(ThisModule.Id(), 'LTY48PSMETA'));
        // Only the sets of this app: Microsoft's sets are environment data.
        EP.SetRange("App ID", ThisModule.Id());
        EP.SetRange(Scope, EP.Scope::System);
        Observer.Observe('rows of this app > 0', Format(not EP.IsEmpty()));
        if EP.FindSet() then
            repeat
                if Format(EP."Security Filter", 0, 9) <> '' then
                    NonBlank += 1;
            until EP.Next() = 0;
        Observer.Observe('rows of this app with a security filter', Format(NonBlank));
        Observer.Expect('object ids', 'ids: table=92922 table2=92923');
        Observer.Expect('LTY48PSMETA', 'Table Data|92922|Yes, , , , |[]|[]|System;Table Data|92923|Yes,Yes,Yes,Yes, |[]|[]|System;');
        Observer.Expect('rows of this app > 0', 'Yes');
        Observer.Expect('rows of this app with a security filter', '0');
        Observer.Verify();
    end;

    [Test]
    procedure EP_SecurityFilter_TenantSet()
    var
        EP: Record "Expanded Permission";
        TP: Record "Tenant Permission";
        Observer: Codeunit "Probe Observer";
        NullGuid: Guid;
    begin
        NewSet('LTY48TEN');
        Grant('LTY48TEN', Database::"LT Y48 SF Table", true, false, false, false, 'LT Y48 SF Table: Id=1..5');
        Grant('LTY48TEN', Database::"LT Y48 SF Table2", true, true, true, true, '');
        Observer.Observe('object ids', ObjectIds());
        Observer.Observe('LTY48TEN', Rows(NullGuid, 'LTY48TEN'));
        Observer.Observe('get', Format(EP.Get(NullGuid, 'LTY48TEN', EP."Object Type"::"Table Data", Database::"LT Y48 SF Table")));
        Observer.Observe('get format', Format(EP."Security Filter"));
        Observer.Observe('get format 9', Format(EP."Security Filter", 0, 9));
        TP."Security Filter" := EP."Security Filter";
        Observer.Observe('copied into tenant permission, format 9', Format(TP."Security Filter", 0, 9));
        Observer.Expect('object ids', 'ids: table=92922 table2=92923');
        Observer.Expect('LTY48TEN', 'Table Data|92922|Yes, , , , |[LT Y48 SF Table: Id=1..5]|[LT Y48 SF Table: Id=1..5]|Tenant;Table Data|92923|Yes,Yes,Yes,Yes, |[]|[]|Tenant;');
        Observer.Expect('get', 'Yes');
        Observer.Expect('get format', 'LT Y48 SF Table: Id=1..5');
        Observer.Expect('get format 9', 'LT Y48 SF Table: Id=1..5');
        Observer.Expect('copied into tenant permission, format 9', 'LT Y48 SF Table: Id=1..5');
        Observer.Verify();
    end;

    [Test]
    procedure EP_SecurityFilter_IncludedTenantSet()
    var
        Rel: Record "Tenant Permission Set Rel.";
        Observer: Codeunit "Probe Observer";
        NullGuid: Guid;
    begin
        NewSet('LTY48BASE');
        Grant('LTY48BASE', Database::"LT Y48 SF Table", true, false, false, false, 'LT Y48 SF Table: Id=1..5');
        NewSet('LTY48INC');
        Grant('LTY48INC', Database::"LT Y48 SF Table", false, false, true, false, 'LT Y48 SF Table: Id=10..20');
        Rel."App ID" := NullGuid;
        Rel."Role ID" := 'LTY48INC';
        Rel."Related App ID" := NullGuid;
        Rel."Related Role ID" := 'LTY48BASE';
        Rel."Related Scope" := Rel."Related Scope"::Tenant;
        Rel.Type := Rel.Type::Include;
        Rel.Insert();
        Observer.Observe('LTY48INC', Rows(NullGuid, 'LTY48INC'));
        Observer.Observe('LTY48BASE', Rows(NullGuid, 'LTY48BASE'));
        Observer.Expect('LTY48INC', 'Table Data|92922|Yes, ,Yes, , |[LT Y48 SF Table: Id=>=1&(<=20&(>=10|<=5))]|[LT Y48 SF Table: Id=>=1&(<=20&(>=10|<=5))]|Tenant;');
        Observer.Expect('LTY48BASE', 'Table Data|92922|Yes, , , , |[LT Y48 SF Table: Id=1..5]|[LT Y48 SF Table: Id=1..5]|Tenant;');
        Observer.Verify();
    end;

    [Test]
    procedure EP_SecurityFilter_ChangedAfterFirstRead()
    var
        TP: Record "Tenant Permission";
        EP: Record "Expanded Permission";
        EP2: Record "Expanded Permission";
        Observer: Codeunit "Probe Observer";
        NullGuid: Guid;
    begin
        NewSet('LTY48CHG');
        Grant('LTY48CHG', Database::"LT Y48 SF Table", true, false, false, false, 'LT Y48 SF Table: Id=1..5');
        Observer.Observe('first read', Rows(NullGuid, 'LTY48CHG'));
        EP.Get(NullGuid, 'LTY48CHG', EP."Object Type"::"Table Data", Database::"LT Y48 SF Table");
        TP.Get(NullGuid, 'LTY48CHG', TP."Object Type"::"Table Data", Database::"LT Y48 SF Table");
        Evaluate(TP."Security Filter", 'LT Y48 SF Table: Id=6..9');
        TP.Modify();
        Observer.Observe('second read', Rows(NullGuid, 'LTY48CHG'));
        EP.Get(NullGuid, 'LTY48CHG', EP."Object Type"::"Table Data", Database::"LT Y48 SF Table");
        Observer.Observe('same variable, get again', Format(EP."Security Filter", 0, 9));
        EP2.Get(NullGuid, 'LTY48CHG', EP2."Object Type"::"Table Data", Database::"LT Y48 SF Table");
        Observer.Observe('new variable, get', Format(EP2."Security Filter", 0, 9));
        Observer.Expect('first read', 'Table Data|92922|Yes, , , , |[LT Y48 SF Table: Id=1..5]|[LT Y48 SF Table: Id=1..5]|Tenant;');
        Observer.Expect('second read', 'Table Data|92922|Yes, , , , |[LT Y48 SF Table: Id=1..5]|[LT Y48 SF Table: Id=1..5]|Tenant;');
        Observer.Expect('same variable, get again', 'LT Y48 SF Table: Id=1..5');
        Observer.Expect('new variable, get', 'LT Y48 SF Table: Id=1..5');
        Observer.Verify();
    end;
}
