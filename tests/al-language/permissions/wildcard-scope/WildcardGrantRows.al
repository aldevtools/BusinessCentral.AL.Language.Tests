// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissionset-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); the wildcard sets of Y93WildObjects.al (94980-94998); LT Y19 Perm Helper (91935,
//   record/Y19PermObjects.al); Permissions Mock (131006) from the dependency.
// Probe (al-runner issue 8032): the rows that a permission set with a whole-object-type grant (table * = X, tabledata * = RIMD,
//   codeunit * = X, several of them, * mixed with a named object, an indirect *, * through IncludedPermissionSets and
//   ExcludedPermissionSets) shows in Metadata Permission, Expanded Permission and the Permission table; an unfiltered read of
//   Metadata Permission (the platform's own sets hold such grants too); and reads of the three tables under Permissions Mock,
//   whose All Objects set holds table * = X, with a set that grants tabledata Permission = R by name, by tabledata *, or not.
// Row format: <object type ordinal>:<object id>:<R I M D X letters; lower case = indirect; - = none>.
// BC versions: 27, 28, 29

// local object: the test checks the rows of this set's own grants (a named grant next to *).
permissionset 91000 "PERM W Mix Table"
{
    Assignable = true;
    Permissions =
        table * = X,
        tabledata "LT Y93 Row" = R,
        table "LT Y93 Row Narrow" = X;
}

// local object: the reporter's set of issue 8032 (a named grant of tabledata Permission).
permissionset 91001 "PERM Grant Perm Tbl"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y93 Row" = R,
        tabledata Permission = R;
}

codeunit 91000 "PERM Wildcard Grant Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y19 Perm Helper";
        Mock: Codeunit "Permissions Mock";
        RowFilterTok: Label '0|2|18|94980|94981|94988|2000000005', Locked = true;

    // The rows of 'LT Y93 W Table' in Metadata Permission, Expanded Permission and Permission (filtered on Role ID): count, and the rows of
    // Object ID 0 and of a few named objects (see RowFilterTok).
    [Test]
    procedure Rows_WTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('metadata', MetadataRows('LT Y93 W Table'));
        Observer.Observe('expanded', ExpandedRows('LT Y93 W Table'));
        Observer.Observe('permission', PermissionRows('LT Y93 W Table'));
        Observer.Finish();
    end;

    // The rows of 'LT Y93 W Data' in Metadata Permission, Expanded Permission and Permission (filtered on Role ID): count, and the rows of
    // Object ID 0 and of a few named objects (see RowFilterTok).
    [Test]
    procedure Rows_WData()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('metadata', MetadataRows('LT Y93 W Data'));
        Observer.Observe('expanded', ExpandedRows('LT Y93 W Data'));
        Observer.Observe('permission', PermissionRows('LT Y93 W Data'));
        Observer.Finish();
    end;

    // The rows of 'LT Y93 W Cu' in Metadata Permission, Expanded Permission and Permission (filtered on Role ID): count, and the rows of
    // Object ID 0 and of a few named objects (see RowFilterTok).
    [Test]
    procedure Rows_WCu()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('metadata', MetadataRows('LT Y93 W Cu'));
        Observer.Observe('expanded', ExpandedRows('LT Y93 W Cu'));
        Observer.Observe('permission', PermissionRows('LT Y93 W Cu'));
        Observer.Finish();
    end;

    // The rows of 'LT Y93 W Mix Data' in Metadata Permission, Expanded Permission and Permission (filtered on Role ID): count, and the rows of
    // Object ID 0 and of a few named objects (see RowFilterTok).
    [Test]
    procedure Rows_WMixData()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('metadata', MetadataRows('LT Y93 W Mix Data'));
        Observer.Observe('expanded', ExpandedRows('LT Y93 W Mix Data'));
        Observer.Observe('permission', PermissionRows('LT Y93 W Mix Data'));
        Observer.Finish();
    end;

    // The rows of 'LT Y93 W Mix Cu' in Metadata Permission, Expanded Permission and Permission (filtered on Role ID): count, and the rows of
    // Object ID 0 and of a few named objects (see RowFilterTok).
    [Test]
    procedure Rows_WMixCu()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('metadata', MetadataRows('LT Y93 W Mix Cu'));
        Observer.Observe('expanded', ExpandedRows('LT Y93 W Mix Cu'));
        Observer.Observe('permission', PermissionRows('LT Y93 W Mix Cu'));
        Observer.Finish();
    end;

    // The rows of 'LT Y93 W All' in Metadata Permission, Expanded Permission and Permission (filtered on Role ID): count, and the rows of
    // Object ID 0 and of a few named objects (see RowFilterTok).
    [Test]
    procedure Rows_WAll()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('metadata', MetadataRows('LT Y93 W All'));
        Observer.Observe('expanded', ExpandedRows('LT Y93 W All'));
        Observer.Observe('permission', PermissionRows('LT Y93 W All'));
        Observer.Finish();
    end;

    // The rows of 'LT Y93 W Ind' in Metadata Permission, Expanded Permission and Permission (filtered on Role ID): count, and the rows of
    // Object ID 0 and of a few named objects (see RowFilterTok).
    [Test]
    procedure Rows_WInd()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('metadata', MetadataRows('LT Y93 W Ind'));
        Observer.Observe('expanded', ExpandedRows('LT Y93 W Ind'));
        Observer.Observe('permission', PermissionRows('LT Y93 W Ind'));
        Observer.Finish();
    end;

    // The rows of 'LT Y93 W Excl' in Metadata Permission, Expanded Permission and Permission (filtered on Role ID): count, and the rows of
    // Object ID 0 and of a few named objects (see RowFilterTok).
    [Test]
    procedure Rows_WExcl()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('metadata', MetadataRows('LT Y93 W Excl'));
        Observer.Observe('expanded', ExpandedRows('LT Y93 W Excl'));
        Observer.Observe('permission', PermissionRows('LT Y93 W Excl'));
        Observer.Finish();
    end;

    // The rows of 'PERM W Mix Table' in Metadata Permission, Expanded Permission and Permission (filtered on Role ID): count, and the rows of
    // Object ID 0 and of a few named objects (see RowFilterTok).
    [Test]
    procedure Rows_MixTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('metadata', MetadataRows('PERM W Mix Table'));
        Observer.Observe('expanded', ExpandedRows('PERM W Mix Table'));
        Observer.Observe('permission', PermissionRows('PERM W Mix Table'));
        Observer.Finish();
    end;

    // The rows of 'PERM Grant Perm Tbl' in Metadata Permission, Expanded Permission and Permission (filtered on Role ID): count, and the rows of
    // Object ID 0 and of a few named objects (see RowFilterTok).
    [Test]
    procedure Rows_GrantPerm()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('metadata', MetadataRows('PERM Grant Perm Tbl'));
        Observer.Observe('expanded', ExpandedRows('PERM Grant Perm Tbl'));
        Observer.Observe('permission', PermissionRows('PERM Grant Perm Tbl'));
        Observer.Finish();
    end;

    // An unfiltered FindSet over Metadata Permission (every set, the platform's own included): it runs, and the rows of
    // 'LT Y93 W Table' it meets.
    [Test]
    procedure Unfiltered_MetadataPermission()
    var
        Observer: Codeunit "Probe Observer";
        MetadataPermission: Record "Metadata Permission";
        Seen: Text;
        N: Integer;
    begin
        if MetadataPermission.FindSet() then
            repeat
                N += 1;
                if MetadataPermission."Role ID" = 'LT Y93 W TABLE' then
                    Seen += MetadataRow(MetadataPermission);
            until MetadataPermission.Next() = 0;
        Observer.Observe('any_rows', Format(N > 0));
        Observer.Observe('count_equals_loop', Format(MetadataPermission.Count() = N));
        Observer.Observe('is_empty', Format(MetadataPermission.IsEmpty()));
        Observer.Observe('seen_w_table', Seen);
        Observer.Finish();
    end;

    // The same over Expanded Permission and Permission.
    [Test]
    procedure Unfiltered_ExpandedAndPermission()
    var
        Observer: Codeunit "Probe Observer";
        ExpandedPermission: Record "Expanded Permission";
        Permission: Record Permission;
    begin
        Observer.Observe('expanded_is_empty', Format(ExpandedPermission.IsEmpty()));
        Observer.Observe('expanded_findfirst', Format(ExpandedPermission.FindFirst()));
        Observer.Observe('permission_is_empty', Format(Permission.IsEmpty()));
        Observer.Observe('permission_findfirst', Format(Permission.FindFirst()));
        Observer.Finish();
    end;

    // Reads of Permission, Metadata Permission and Expanded Permission under Permissions Mock.Set('PERM Grant Perm Tbl') (the mock adds its
    // All Objects set, which holds table * = X). Ops: 1 Permission FindFirst, 2 Permission IsEmpty, 3 Permission Count of the
    // rows of 'LT Y93 W Table', 4 Metadata Permission Count of those rows, 5 Metadata Permission IsEmpty unfiltered,
    // 6 Expanded Permission Count of those rows.
    [Test]
    procedure Mock_GrantPerm()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
        Which: Integer;
    begin
        WasStarted := Helper.StartMock(Mock);
        for Which := 1 to 6 do begin
            Mock.ClearAssignments();
            Mock.Set('PERM Grant Perm Tbl');
            asserterror ReadOp(Which);
            Observer.ObserveError('op' + Format(Which));
            Mock.ClearAssignments();
        end;
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    // Reads of Permission, Metadata Permission and Expanded Permission under Permissions Mock.Set('LT Y93 W Data') (the mock adds its
    // All Objects set, which holds table * = X). Ops: 1 Permission FindFirst, 2 Permission IsEmpty, 3 Permission Count of the
    // rows of 'LT Y93 W Table', 4 Metadata Permission Count of those rows, 5 Metadata Permission IsEmpty unfiltered,
    // 6 Expanded Permission Count of those rows.
    [Test]
    procedure Mock_WData()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
        Which: Integer;
    begin
        WasStarted := Helper.StartMock(Mock);
        for Which := 1 to 6 do begin
            Mock.ClearAssignments();
            Mock.Set('LT Y93 W Data');
            asserterror ReadOp(Which);
            Observer.ObserveError('op' + Format(Which));
            Mock.ClearAssignments();
        end;
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    // Reads of Permission, Metadata Permission and Expanded Permission under Permissions Mock.Set('LT Y93 W Cu') (the mock adds its
    // All Objects set, which holds table * = X). Ops: 1 Permission FindFirst, 2 Permission IsEmpty, 3 Permission Count of the
    // rows of 'LT Y93 W Table', 4 Metadata Permission Count of those rows, 5 Metadata Permission IsEmpty unfiltered,
    // 6 Expanded Permission Count of those rows.
    [Test]
    procedure Mock_WCu()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
        Which: Integer;
    begin
        WasStarted := Helper.StartMock(Mock);
        for Which := 1 to 6 do begin
            Mock.ClearAssignments();
            Mock.Set('LT Y93 W Cu');
            asserterror ReadOp(Which);
            Observer.ObserveError('op' + Format(Which));
            Mock.ClearAssignments();
        end;
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    // Reads of Permission, Metadata Permission and Expanded Permission under Permissions Mock.Set('LT Y93 W Table') (the mock adds its
    // All Objects set, which holds table * = X). Ops: 1 Permission FindFirst, 2 Permission IsEmpty, 3 Permission Count of the
    // rows of 'LT Y93 W Table', 4 Metadata Permission Count of those rows, 5 Metadata Permission IsEmpty unfiltered,
    // 6 Expanded Permission Count of those rows.
    [Test]
    procedure Mock_WTable()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
        Which: Integer;
    begin
        WasStarted := Helper.StartMock(Mock);
        for Which := 1 to 6 do begin
            Mock.ClearAssignments();
            Mock.Set('LT Y93 W Table');
            asserterror ReadOp(Which);
            Observer.ObserveError('op' + Format(Which));
            Mock.ClearAssignments();
        end;
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    local procedure ReadOp(Which: Integer)
    var
        Permission: Record Permission;
        MetadataPermission: Record "Metadata Permission";
        ExpandedPermission: Record "Expanded Permission";
    begin
        case Which of
            1:
                Error('PERM ok %1', Permission.FindFirst());
            2:
                Error('PERM ok %1', Permission.IsEmpty());
            3:
                begin
                    Permission.SetRange("Role ID", 'LT Y93 W TABLE');
                    Error('PERM ok %1', Permission.Count());
                end;
            4:
                begin
                    MetadataPermission.SetRange("Role ID", 'LT Y93 W TABLE');
                    Error('PERM ok %1', MetadataPermission.Count());
                end;
            5:
                Error('PERM ok %1', MetadataPermission.IsEmpty());
            6:
                begin
                    ExpandedPermission.SetRange("Role ID", 'LT Y93 W TABLE');
                    Error('PERM ok %1', ExpandedPermission.Count());
                end;
        end;
    end;

    local procedure MetadataRows(RoleId: Code[20]) Result: Text
    var
        MetadataPermission: Record "Metadata Permission";
    begin
        MetadataPermission.SetRange("Role ID", RoleId);
        Result := Format(MetadataPermission.Count()) + ' rows ';
        MetadataPermission.SetFilter("Object ID", RowFilterTok);
        if MetadataPermission.FindSet() then
            repeat
                Result += MetadataRow(MetadataPermission);
            until MetadataPermission.Next() = 0;
    end;

    local procedure MetadataRow(MetadataPermission: Record "Metadata Permission"): Text
    begin
        exit(Format(MetadataPermission."Object Type", 0, 2) + ':' + Format(MetadataPermission."Object ID") + ':' +
            Letter(MetadataPermission."Read Permission", 'R') + Letter(MetadataPermission."Insert Permission", 'I') +
            Letter(MetadataPermission."Modify Permission", 'M') + Letter(MetadataPermission."Delete Permission", 'D') +
            Letter(MetadataPermission."Execute Permission", 'X') + ';');
    end;

    local procedure ExpandedRows(RoleId: Code[20]) Result: Text
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        ExpandedPermission.SetRange("Role ID", RoleId);
        Result := Format(ExpandedPermission.Count()) + ' rows ';
        ExpandedPermission.SetFilter("Object ID", RowFilterTok);
        if ExpandedPermission.FindSet() then
            repeat
                Result += Format(ExpandedPermission."Object Type", 0, 2) + ':' + Format(ExpandedPermission."Object ID") + ':' +
                    Letter(ExpandedPermission."Read Permission", 'R') + Letter(ExpandedPermission."Insert Permission", 'I') +
                    Letter(ExpandedPermission."Modify Permission", 'M') + Letter(ExpandedPermission."Delete Permission", 'D') +
                    Letter(ExpandedPermission."Execute Permission", 'X') + ';';
            until ExpandedPermission.Next() = 0;
    end;

    local procedure PermissionRows(RoleId: Code[20]) Result: Text
    var
        Permission: Record Permission;
    begin
        Permission.SetRange("Role ID", RoleId);
        Result := Format(Permission.Count()) + ' rows ';
        Permission.SetFilter("Object ID", RowFilterTok);
        if Permission.FindSet() then
            repeat
                Result += Format(Permission."Object Type", 0, 2) + ':' + Format(Permission."Object ID") + ':' +
                    Letter(Permission."Read Permission", 'R') + Letter(Permission."Insert Permission", 'I') +
                    Letter(Permission."Modify Permission", 'M') + Letter(Permission."Delete Permission", 'D') +
                    Letter(Permission."Execute Permission", 'X') + ';';
            until Permission.Next() = 0;
    end;

    local procedure Letter(Value: Option " ",Yes,Indirect; Which: Text[1]): Text
    begin
        case Value of
            Value::Yes:
                exit(Which);
            Value::Indirect:
                exit(Which.ToLower());
        end;
        exit('-');
    end;
}
