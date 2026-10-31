// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/objects/devenv-permissionset-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y19PermObjects.al (91900-91935); Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 stage 1 probes, writer Y19:
//   P7 frame rule: a codeunit with Permissions = ri inserting in its own procedure, in a local procedure, through an interface implemented by a
//      codeunit without the property, and through a table procedure; the user has only ri;
//   P9 role id resolution (one app): a role id given in lower case, a non-assignable set;
//   P10 permission set extensions: an own extension of an own set and of D365 BASIC, at run time and in Expanded Permission;
//   P11 composition corners: an excluded set that includes a set, RIMD excluding rimd, R and r on the same table from two included sets;
//   P12 wildcard sets tabledata * = R, * = r and * = RIMD: read and insert directly and from the codeunit with Permissions.
// Shape: as Y19PermWrites.al. Permissions Mock.Set runs in a TryFunction, so a set that cannot be assigned is observed (its error text) and
//   the operation is skipped.
// Facts (BC 27.5, 28.5, 29.0): the Permissions property covers the object's own and local procedures, not an interface implementation in
//   another codeunit and not a table procedure (Insert, the direct word). Mock.Set takes Code[20], so a lower-case role id resolves; a
//   non-assignable set can be assigned; a missing set fails in "Permission Set".Get (DB:RecordNotFound). Permission set extensions (own
//   set, D365 BASIC) grant at run time and merge into the set's one Expanded Permission row. An excluded set removes what it includes
//   too; RIMD excluding rimd leaves indirect only; R and r from two included sets give R. Wildcard sets work at run time; their
//   Expanded Permission row has Object ID 0.
// BC versions: 27, 28, 29

codeunit 91952 "LT Y19 Perm Composition"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y19 Perm Helper";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y19_P7_FrameRule()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        RunCase(Observer, 'writer_own_procedure', 'LT Y19 Ind RI', 1);
        RunCase(Observer, 'writer_local_procedure', 'LT Y19 Ind RI', 2);
        RunCase(Observer, 'writer_interface', 'LT Y19 Ind RI', 3);
        RunCase(Observer, 'writer_table_procedure', 'LT Y19 Ind RI', 4);
        RunCase(Observer, 'writer_count', 'LT Y19 Ind RI', 5);
        RunCase(Observer, 'test_direct_insert', 'LT Y19 Ind RI', 6);
        RunCase(Observer, 'test_table_procedure', 'LT Y19 Ind RI', 8);
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('writer_own_procedure|text', 'LT Y19 ok rows 1=10;2=20;5=0;');
        Observer.Expect('writer_own_procedure|code', 'Dialog');
        Observer.Expect('writer_local_procedure|text', 'LT Y19 ok rows 1=10;2=20;5=0;');
        Observer.Expect('writer_local_procedure|code', 'Dialog');
        Observer.Expect('writer_interface|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Insert: AL Language Coverage Tests)');
        Observer.Expect('writer_interface|code', 'DB:ClientInsertDenied');
        Observer.Expect('writer_table_procedure|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Insert: AL Language Coverage Tests)');
        Observer.Expect('writer_table_procedure|code', 'DB:ClientInsertDenied');
        Observer.Expect('writer_count|text', 'LT Y19 ok count 2 rows 1=10;2=20;');
        Observer.Expect('writer_count|code', 'Dialog');
        Observer.Expect('test_direct_insert|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Insert: AL Language Coverage Tests)');
        Observer.Expect('test_direct_insert|code', 'DB:ClientInsertDenied');
        Observer.Expect('test_table_procedure|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Insert: AL Language Coverage Tests)');
        Observer.Expect('test_table_procedure|code', 'DB:ClientInsertDenied');
        Observer.Verify();
    end;

    [Test]
    procedure Y19_P9_RoleIdForms()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        RunCase(Observer, 'lower_case_insert', 'lt y19 ri', 6);
        RunCase(Observer, 'lower_case_mixed_set_insert', 'lt y19 mixed case', 6);
        RunCase(Observer, 'not_assignable_insert', 'LT Y19 Not Assign', 6);
        RunCase(Observer, 'not_assignable_count', 'LT Y19 Not Assign', 7);
        RunCase(Observer, 'missing_set', 'LT Y19 No Such Set', 6);
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('lower_case_insert|text', 'LT Y19 ok rows 1=10;2=20;5=0;');
        Observer.Expect('lower_case_insert|code', 'Dialog');
        Observer.Expect('lower_case_mixed_set_insert|text', 'LT Y19 ok rows 1=10;2=20;5=0;');
        Observer.Expect('lower_case_mixed_set_insert|code', 'Dialog');
        Observer.Expect('not_assignable_insert|text', 'LT Y19 ok rows 1=10;2=20;5=0;');
        Observer.Expect('not_assignable_insert|code', 'Dialog');
        Observer.Expect('not_assignable_count|text', 'LT Y19 ok count 2 rows 1=10;2=20;');
        Observer.Expect('not_assignable_count|code', 'Dialog');
        Observer.Expect('missing_set|set', 'failed: The Permission Set does not exist. Identification fields and values: Role ID=''LT Y19 NO SUCH SET''');
        Observer.Expect('missing_set|set_code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Y19_P10_ExtensionsAtRunTime()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        RunCase(Observer, 'own_ext_insert', 'LT Y19 Ext Base', 6);
        RunCase(Observer, 'own_ext_delete', 'LT Y19 Ext Base', 9);
        RunCase(Observer, 'd365_basic_ext_insert', 'D365 BASIC', 10);
        RunCase(Observer, 'd365_basic_own_row_insert', 'D365 BASIC', 6);
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('own_ext_insert|text', 'LT Y19 ok rows 1=10;2=20;5=0;');
        Observer.Expect('own_ext_insert|code', 'Dialog');
        Observer.Expect('own_ext_delete|text', 'LT Y19 ok rows 2=20;');
        Observer.Expect('own_ext_delete|code', 'Dialog');
        Observer.Expect('d365_basic_ext_insert|text', 'LT Y19 ok ext count 1 rows 1=10;2=20;');
        Observer.Expect('d365_basic_ext_insert|code', 'Dialog');
        Observer.Expect('d365_basic_own_row_insert|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Insert: AL Language Coverage Tests)');
        Observer.Expect('d365_basic_own_row_insert|code', 'DB:ClientInsertDenied');
        Observer.Verify();
    end;

    [Test]
    procedure Y19_P10_ExpandedPermissionRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('expanded_own_ext_base', Expanded('LT Y19 EXT BASE', Database::"LT Y19 Row"));
        Observer.Observe('expanded_d365_basic_ext_row', Expanded('D365 BASIC', Database::"LT Y19 Ext Row"));
        Observer.Observe('expanded_excl_nested_row', Expanded('LT Y19 EXCL NESTED', Database::"LT Y19 Row"));
        Observer.Observe('expanded_excl_nested_b', Expanded('LT Y19 EXCL NESTED', Database::"LT Y19 Trig B"));
        Observer.Observe('expanded_excl_indirect', Expanded('LT Y19 EXCL INDIRECT', Database::"LT Y19 Row"));
        Observer.Observe('expanded_r_and_ind_r', Expanded('LT Y19 R AND IND R', Database::"LT Y19 Row"));
        Observer.Observe('expanded_wild_r', Expanded('LT Y19 WILD R', 0));
        Observer.Observe('expanded_wild_r_own_row', Expanded('LT Y19 WILD R', Database::"LT Y19 Row"));
        Observer.Expect('expanded_own_ext_base', '1: Yes,Yes,Yes,Yes, ;');
        Observer.Expect('expanded_d365_basic_ext_row', '1: Yes,Yes,Yes,Yes, ;');
        Observer.Expect('expanded_excl_nested_row', '1:  ,Yes,Yes,Yes, ;');
        Observer.Expect('expanded_excl_nested_b', '1:  ,Yes,Yes,Yes, ;');
        Observer.Expect('expanded_excl_indirect', '1: Indirect,Indirect,Indirect,Indirect, ;');
        Observer.Expect('expanded_r_and_ind_r', '1: Yes, , , , ;');
        Observer.Expect('expanded_wild_r', '1: Yes, , , , ;');
        Observer.Expect('expanded_wild_r_own_row', '0: ');
        Observer.Verify();
    end;

    [Test]
    procedure Y19_P11_Composition()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        RunCase(Observer, 'excl_nested_count', 'LT Y19 Excl Nested', 7);
        RunCase(Observer, 'excl_nested_insert', 'LT Y19 Excl Nested', 6);
        RunCase(Observer, 'excl_nested_b_count', 'LT Y19 Excl Nested', 11);
        RunCase(Observer, 'excl_indirect_count', 'LT Y19 Excl Indirect', 7);
        RunCase(Observer, 'excl_indirect_insert', 'LT Y19 Excl Indirect', 6);
        RunCase(Observer, 'excl_indirect_writer_insert', 'LT Y19 Excl Indirect', 1);
        RunCase(Observer, 'r_and_ind_r_count', 'LT Y19 R And Ind R', 7);
        RunCase(Observer, 'r_and_ind_r_insert', 'LT Y19 R And Ind R', 6);
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('excl_nested_count|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Read: AL Language Coverage Tests)');
        Observer.Expect('excl_nested_count|code', 'DB:ClientReadDenied');
        Observer.Expect('excl_nested_insert|text', 'LT Y19 ok rows 1=10;2=20;5=0;');
        Observer.Expect('excl_nested_insert|code', 'Dialog');
        Observer.Expect('excl_nested_b_count|text', 'LT Y19 ok b count 0 rows 1=10;2=20;');
        Observer.Expect('excl_nested_b_count|code', 'Dialog');
        Observer.Expect('excl_indirect_count|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Read: AL Language Coverage Tests)');
        Observer.Expect('excl_indirect_count|code', 'DB:ClientReadDenied');
        Observer.Expect('excl_indirect_insert|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Insert: AL Language Coverage Tests)');
        Observer.Expect('excl_indirect_insert|code', 'DB:ClientInsertDenied');
        Observer.Expect('excl_indirect_writer_insert|text', 'LT Y19 ok rows 1=10;2=20;5=0;');
        Observer.Expect('excl_indirect_writer_insert|code', 'Dialog');
        Observer.Expect('r_and_ind_r_count|text', 'LT Y19 ok count 2 rows 1=10;2=20;');
        Observer.Expect('r_and_ind_r_count|code', 'Dialog');
        Observer.Expect('r_and_ind_r_insert|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Insert: AL Language Coverage Tests)');
        Observer.Expect('r_and_ind_r_insert|code', 'DB:ClientInsertDenied');
        Observer.Verify();
    end;

    [Test]
    procedure Y19_P12_WildcardR()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        RunWild(Observer, 'wild_r', 'LT Y19 Wild R');
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('wild_r_count|text', 'LT Y19 ok count 2 rows 1=10;2=20;');
        Observer.Expect('wild_r_count|code', 'Dialog');
        Observer.Expect('wild_r_insert|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Insert: AL Language Coverage Tests)');
        Observer.Expect('wild_r_insert|code', 'DB:ClientInsertDenied');
        Observer.Expect('wild_r_writer_count|text', 'LT Y19 ok count 2 rows 1=10;2=20;');
        Observer.Expect('wild_r_writer_count|code', 'Dialog');
        Observer.Expect('wild_r_writer_insert|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row IndirectInsert: AL Language Coverage Tests)');
        Observer.Expect('wild_r_writer_insert|code', 'DB:ClientInsertDenied');
        Observer.Verify();
    end;

    [Test]
    procedure Y19_P12_WildcardIndR()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        RunWild(Observer, 'wild_ind_r', 'LT Y19 Wild Ind R');
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('wild_ind_r_count|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Read: AL Language Coverage Tests)');
        Observer.Expect('wild_ind_r_count|code', 'DB:ClientReadDenied');
        Observer.Expect('wild_ind_r_insert|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Insert: AL Language Coverage Tests)');
        Observer.Expect('wild_ind_r_insert|code', 'DB:ClientInsertDenied');
        Observer.Expect('wild_ind_r_writer_count|text', 'LT Y19 ok count 2 rows 1=10;2=20;');
        Observer.Expect('wild_ind_r_writer_count|code', 'Dialog');
        Observer.Expect('wild_ind_r_writer_insert|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row IndirectInsert: AL Language Coverage Tests)');
        Observer.Expect('wild_ind_r_writer_insert|code', 'DB:ClientInsertDenied');
        Observer.Verify();
    end;

    [Test]
    procedure Y19_P12_WildcardRIMD()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        RunWild(Observer, 'wild_rimd', 'LT Y19 Wild RIMD');
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('wild_rimd_count|text', 'LT Y19 ok count 2 rows 1=10;2=20;');
        Observer.Expect('wild_rimd_count|code', 'Dialog');
        Observer.Expect('wild_rimd_insert|text', 'LT Y19 ok rows 1=10;2=20;5=0;');
        Observer.Expect('wild_rimd_insert|code', 'Dialog');
        Observer.Expect('wild_rimd_writer_count|text', 'LT Y19 ok count 2 rows 1=10;2=20;');
        Observer.Expect('wild_rimd_writer_count|code', 'Dialog');
        Observer.Expect('wild_rimd_writer_insert|text', 'LT Y19 ok rows 1=10;2=20;5=0;');
        Observer.Expect('wild_rimd_writer_insert|code', 'Dialog');
        Observer.Verify();
    end;

    local procedure RunWild(var Observer: Codeunit "Probe Observer"; Tag: Text; SetName: Code[20])
    begin
        RunCase(Observer, Tag + '_count', SetName, 7);
        RunCase(Observer, Tag + '_insert', SetName, 6);
        RunCase(Observer, Tag + '_writer_count', SetName, 5);
        RunCase(Observer, Tag + '_writer_insert', SetName, 1);
    end;

    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Name: Text; SetName: Code[20]; Which: Integer)
    begin
        Mock.ClearAssignments();
        Helper.Seed();
        ClearLastError();
        if not TrySet(SetName) then begin
            Observer.Observe(Name + '|set', 'failed: ' + GetLastErrorText());
            Observer.Observe(Name + '|set_code', GetLastErrorCode());
            ClearLastError();
            Mock.ClearAssignments();
            exit;
        end;
        asserterror Op(Which);
        Observer.ObserveError(Name);
        Mock.ClearAssignments();
    end;

    [TryFunction]
    local procedure TrySet(SetName: Code[20])
    begin
        Mock.Set(SetName);
    end;

    local procedure Op(Which: Integer)
    var
        Row: Record "LT Y19 Row";
        ExtRow: Record "LT Y19 Ext Row";
        B: Record "LT Y19 Trig B";
        Writer: Codeunit "LT Y19 Frame Writer";
        Result: Text;
    begin
        case Which of
            1:
                Writer.InsertDirect(5);
            2:
                Writer.InsertViaLocal(5);
            3:
                Writer.InsertViaInterface(5);
            4:
                Writer.InsertViaTableProc(5);
            5:
                Result := 'count ' + Format(Writer.CountRows()) + ' ';
            6:
                begin
                    Row.Id := 5;
                    Row.Insert();
                end;
            7:
                Result := 'count ' + Format(Row.Count()) + ' ';
            8:
                Row.InsertSelf(5);
            9:
                begin
                    Row.Id := 1;
                    Row.Delete();
                end;
            10:
                begin
                    ExtRow.Id := 5;
                    ExtRow.Insert();
                    Result := 'ext count ' + Format(ExtRow.Count()) + ' ';
                end;
            11:
                Result := 'b count ' + Format(B.Count()) + ' ';
        end;
        Error('LT Y19 ok %1rows %2', Result, Helper.DescribeRows());
    end;

    // The Expanded Permission rows of a role id for one table data object: per row the app name, then R, I, M, D, X.
    local procedure Expanded(RoleId: Code[20]; ObjectId: Integer): Text
    var
        ExpandedPermission: Record "Expanded Permission";
        Result: Text;
    begin
        ExpandedPermission.SetRange("Role ID", RoleId);
        ExpandedPermission.SetRange("Object Type", ExpandedPermission."Object Type"::"Table Data");
        ExpandedPermission.SetRange("Object ID", ObjectId);
        if ExpandedPermission.FindSet() then
            repeat
                Result += Format(ExpandedPermission."Read Permission") + ',' + Format(ExpandedPermission."Insert Permission") + ',' +
                    Format(ExpandedPermission."Modify Permission") + ',' + Format(ExpandedPermission."Delete Permission") + ',' +
                    Format(ExpandedPermission."Execute Permission") + ';';
            until ExpandedPermission.Next() = 0;
        exit(Format(ExpandedPermission.Count()) + ': ' + Result);
    end;
}
