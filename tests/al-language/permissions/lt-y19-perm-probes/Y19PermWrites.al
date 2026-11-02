// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y19PermObjects.al (91900-91935); Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 (permission enforcement in stages), stage 1 probes, writer Y19:
//   P1 Rename under a set with R, RIM and RIMD on a table with rows;
//   P2 DeleteAll/ModifyAll (with and without triggers) on 2 rows and on a filter that matches no row of a non-empty table, sets R and RI;
//   P3 table triggers that write another table, the triggering table with and without Permissions = imd on it, user with imd and with nothing;
//   P4 IndirectDelete: a codeunit with Permissions = d, user with d and with nothing; Permissions = m with a user who has M;
//   P6 RecordRef writes and writes of temporary records (Temporary variable, TableType = Temporary) under a set without the grant.
// Shape (CpPermLeads.al): each case reseeds with no set assigned, assigns the set (Permissions Mock.Set: the set plus All Objects), runs ONE
//   operation inside asserterror that ends with the own error 'LT Y19 ok <rows after>', observes text and code, clears the assignment.
//   The rows after are read through an InherentPermissions procedure ("LT Y19 Perm Helper".DescribeRows), so the read itself is never denied.
// Facts (BC 27.5, 28.5, 29.0): Rename needs M (R: Modify error; RIM renames). DeleteAll/ModifyAll, with or without triggers, need D/M
//   even when the filter matches no row of a non-empty table. A trigger write on B is checked against the triggering table's Permissions
//   property: without it the user's imd is not enough (Insert/Modify/Delete); with Permissions = imd the user's imd works and a user with
//   nothing on B gets IndirectInsert/IndirectModify/IndirectDelete. Permissions = d with a user who has d deletes; with nothing:
//   IndirectDelete (DB:ClientDeleteDenied). Direct M beats Permissions = m. RecordRef writes are checked like record writes; temporary
//   records (variable, TableType = Temporary, RecordRef.Open(.., true)) are never checked.
// BC versions: 27, 28, 29

codeunit 91950 "LT Y19 Perm Writes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y19 Perm Helper";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y19_P1_Rename()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        RunCase(Observer, 'rename_r', 'LT Y19 R', 1);
        RunCase(Observer, 'rename_rim', 'LT Y19 RIM', 1);
        RunCase(Observer, 'rename_rimd', 'LT Y19 RIMD', 1);
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('rename_r|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Modify: AL Language Coverage Tests)');
        Observer.Expect('rename_r|code', 'DB:ClientModifyDenied');
        Observer.Expect('rename_rim|text', 'LT Y19 ok rows 2=20;11=10;');
        Observer.Expect('rename_rim|code', 'Dialog');
        Observer.Expect('rename_rimd|text', 'LT Y19 ok rows 2=20;11=10;');
        Observer.Expect('rename_rimd|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Y19_P2_SetR()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        RunP2(Observer, 'r', 'LT Y19 R');
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('deleteall_r|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Delete: AL Language Coverage Tests)');
        Observer.Expect('deleteall_r|code', 'DB:ClientDeleteDenied');
        Observer.Expect('deleteall_true_r|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Delete: AL Language Coverage Tests)');
        Observer.Expect('deleteall_true_r|code', 'DB:ClientDeleteDenied');
        Observer.Expect('modifyall_r|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Modify: AL Language Coverage Tests)');
        Observer.Expect('modifyall_r|code', 'DB:ClientModifyDenied');
        Observer.Expect('modifyall_true_r|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Modify: AL Language Coverage Tests)');
        Observer.Expect('modifyall_true_r|code', 'DB:ClientModifyDenied');
        Observer.Expect('nomatch_deleteall_r|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Delete: AL Language Coverage Tests)');
        Observer.Expect('nomatch_deleteall_r|code', 'DB:ClientDeleteDenied');
        Observer.Expect('nomatch_deleteall_true_r|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Delete: AL Language Coverage Tests)');
        Observer.Expect('nomatch_deleteall_true_r|code', 'DB:ClientDeleteDenied');
        Observer.Expect('nomatch_modifyall_r|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Modify: AL Language Coverage Tests)');
        Observer.Expect('nomatch_modifyall_r|code', 'DB:ClientModifyDenied');
        Observer.Expect('nomatch_modifyall_true_r|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Modify: AL Language Coverage Tests)');
        Observer.Expect('nomatch_modifyall_true_r|code', 'DB:ClientModifyDenied');
        Observer.Verify();
    end;

    [Test]
    procedure Y19_P2_SetRI()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        RunP2(Observer, 'ri', 'LT Y19 RI');
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('deleteall_ri|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Delete: AL Language Coverage Tests)');
        Observer.Expect('deleteall_ri|code', 'DB:ClientDeleteDenied');
        Observer.Expect('deleteall_true_ri|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Delete: AL Language Coverage Tests)');
        Observer.Expect('deleteall_true_ri|code', 'DB:ClientDeleteDenied');
        Observer.Expect('modifyall_ri|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Modify: AL Language Coverage Tests)');
        Observer.Expect('modifyall_ri|code', 'DB:ClientModifyDenied');
        Observer.Expect('modifyall_true_ri|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Modify: AL Language Coverage Tests)');
        Observer.Expect('modifyall_true_ri|code', 'DB:ClientModifyDenied');
        Observer.Expect('nomatch_deleteall_ri|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Delete: AL Language Coverage Tests)');
        Observer.Expect('nomatch_deleteall_ri|code', 'DB:ClientDeleteDenied');
        Observer.Expect('nomatch_deleteall_true_ri|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Delete: AL Language Coverage Tests)');
        Observer.Expect('nomatch_deleteall_true_ri|code', 'DB:ClientDeleteDenied');
        Observer.Expect('nomatch_modifyall_ri|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Modify: AL Language Coverage Tests)');
        Observer.Expect('nomatch_modifyall_ri|code', 'DB:ClientModifyDenied');
        Observer.Expect('nomatch_modifyall_true_ri|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Modify: AL Language Coverage Tests)');
        Observer.Expect('nomatch_modifyall_true_ri|code', 'DB:ClientModifyDenied');
        Observer.Verify();
    end;

    [Test]
    procedure Y19_P3_ImdOnB()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        RunP3(Observer, 'imd', 'LT Y19 Trig Imd B');
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('a_insert_imd|text', 'Sorry, the current permissions prevented the action. (TableData 91903 LT Y19 Trig B Insert: AL Language Coverage Tests)');
        Observer.Expect('a_insert_imd|code', 'DB:ClientInsertDenied');
        Observer.Expect('a_modify_imd|text', 'Sorry, the current permissions prevented the action. (TableData 91903 LT Y19 Trig B Modify: AL Language Coverage Tests)');
        Observer.Expect('a_modify_imd|code', 'DB:ClientModifyDenied');
        Observer.Expect('a_delete_imd|text', 'Sorry, the current permissions prevented the action. (TableData 91903 LT Y19 Trig B Delete: AL Language Coverage Tests)');
        Observer.Expect('a_delete_imd|code', 'DB:ClientDeleteDenied');
        Observer.Expect('aperm_insert_imd|text', 'LT Y19 ok b 1=0;2=0;rows 1=10;2=20;');
        Observer.Expect('aperm_insert_imd|code', 'Dialog');
        Observer.Expect('aperm_modify_imd|text', 'LT Y19 ok b 1=5;rows 1=10;2=20;');
        Observer.Expect('aperm_modify_imd|code', 'Dialog');
        Observer.Expect('aperm_delete_imd|text', 'LT Y19 ok b rows 1=10;2=20;');
        Observer.Expect('aperm_delete_imd|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Y19_P3_NothingOnB()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        RunP3(Observer, 'none', 'LT Y19 Trig No B');
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('a_insert_none|text', 'Sorry, the current permissions prevented the action. (TableData 91903 LT Y19 Trig B Insert: AL Language Coverage Tests)');
        Observer.Expect('a_insert_none|code', 'DB:ClientInsertDenied');
        Observer.Expect('a_modify_none|text', 'Sorry, the current permissions prevented the action. (TableData 91903 LT Y19 Trig B Modify: AL Language Coverage Tests)');
        Observer.Expect('a_modify_none|code', 'DB:ClientModifyDenied');
        Observer.Expect('a_delete_none|text', 'Sorry, the current permissions prevented the action. (TableData 91903 LT Y19 Trig B Delete: AL Language Coverage Tests)');
        Observer.Expect('a_delete_none|code', 'DB:ClientDeleteDenied');
        Observer.Expect('aperm_insert_none|text', 'Sorry, the current permissions prevented the action. (TableData 91903 LT Y19 Trig B IndirectInsert: AL Language Coverage Tests)');
        Observer.Expect('aperm_insert_none|code', 'DB:ClientInsertDenied');
        Observer.Expect('aperm_modify_none|text', 'Sorry, the current permissions prevented the action. (TableData 91903 LT Y19 Trig B IndirectModify: AL Language Coverage Tests)');
        Observer.Expect('aperm_modify_none|code', 'DB:ClientModifyDenied');
        Observer.Expect('aperm_delete_none|text', 'Sorry, the current permissions prevented the action. (TableData 91903 LT Y19 Trig B IndirectDelete: AL Language Coverage Tests)');
        Observer.Expect('aperm_delete_none|code', 'DB:ClientDeleteDenied');
        Observer.Verify();
    end;

    [Test]
    procedure Y19_P4_IndirectDeleteAndModify()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        RunCase(Observer, 'deleter_user_d', 'LT Y19 R Ind D', 41);
        RunCase(Observer, 'deleter_user_none', 'LT Y19 None', 41);
        RunCase(Observer, 'direct_delete_user_d', 'LT Y19 R Ind D', 43);
        RunCase(Observer, 'modifier_user_m', 'LT Y19 R M', 42);
        RunCase(Observer, 'modifier_user_none', 'LT Y19 None', 42);
        RunCase(Observer, 'direct_modify_user_m', 'LT Y19 R M', 44);
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('deleter_user_d|text', 'LT Y19 ok rows 2=20;');
        Observer.Expect('deleter_user_d|code', 'Dialog');
        Observer.Expect('deleter_user_none|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row IndirectDelete: AL Language Coverage Tests)');
        Observer.Expect('deleter_user_none|code', 'DB:ClientDeleteDenied');
        Observer.Expect('direct_delete_user_d|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Delete: AL Language Coverage Tests)');
        Observer.Expect('direct_delete_user_d|code', 'DB:ClientDeleteDenied');
        Observer.Expect('modifier_user_m|text', 'LT Y19 ok rows 1=77;2=20;');
        Observer.Expect('modifier_user_m|code', 'Dialog');
        Observer.Expect('modifier_user_none|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row IndirectModify: AL Language Coverage Tests)');
        Observer.Expect('modifier_user_none|code', 'DB:ClientModifyDenied');
        Observer.Expect('direct_modify_user_m|text', 'LT Y19 ok rows 1=77;2=20;');
        Observer.Expect('direct_modify_user_m|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Y19_P6_RecordRef()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        RunCase(Observer, 'recref_insert', 'LT Y19 None', 61);
        RunCase(Observer, 'recref_modify', 'LT Y19 None', 62);
        RunCase(Observer, 'recref_delete', 'LT Y19 None', 63);
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('recref_insert|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Insert: AL Language Coverage Tests)');
        Observer.Expect('recref_insert|code', 'DB:ClientInsertDenied');
        Observer.Expect('recref_modify|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Modify: AL Language Coverage Tests)');
        Observer.Expect('recref_modify|code', 'DB:ClientModifyDenied');
        Observer.Expect('recref_delete|text', 'Sorry, the current permissions prevented the action. (TableData 91900 LT Y19 Row Delete: AL Language Coverage Tests)');
        Observer.Expect('recref_delete|code', 'DB:ClientDeleteDenied');
        Observer.Verify();
    end;

    [Test]
    procedure Y19_P6_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        RunCase(Observer, 'temp_var_insert', 'LT Y19 None', 64);
        RunCase(Observer, 'temp_var_modify', 'LT Y19 None', 65);
        RunCase(Observer, 'temp_var_delete', 'LT Y19 None', 66);
        RunCase(Observer, 'temp_table_insert', 'LT Y19 None', 67);
        RunCase(Observer, 'temp_table_modify', 'LT Y19 None', 68);
        RunCase(Observer, 'temp_table_delete', 'LT Y19 None', 69);
        RunCase(Observer, 'temp_recref_insert', 'LT Y19 None', 70);
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('temp_var_insert|text', 'LT Y19 ok temp 1 rows 1=10;2=20;');
        Observer.Expect('temp_var_insert|code', 'Dialog');
        Observer.Expect('temp_var_modify|text', 'LT Y19 ok temp 1 rows 1=10;2=20;');
        Observer.Expect('temp_var_modify|code', 'Dialog');
        Observer.Expect('temp_var_delete|text', 'LT Y19 ok temp 0 rows 1=10;2=20;');
        Observer.Expect('temp_var_delete|code', 'Dialog');
        Observer.Expect('temp_table_insert|text', 'LT Y19 ok temp 1 rows 1=10;2=20;');
        Observer.Expect('temp_table_insert|code', 'Dialog');
        Observer.Expect('temp_table_modify|text', 'LT Y19 ok temp 1 rows 1=10;2=20;');
        Observer.Expect('temp_table_modify|code', 'Dialog');
        Observer.Expect('temp_table_delete|text', 'LT Y19 ok temp 0 rows 1=10;2=20;');
        Observer.Expect('temp_table_delete|code', 'Dialog');
        Observer.Expect('temp_recref_insert|text', 'LT Y19 ok temp 1 rows 1=10;2=20;');
        Observer.Expect('temp_recref_insert|code', 'Dialog');
        Observer.Verify();
    end;

    local procedure RunP2(var Observer: Codeunit "Probe Observer"; Tag: Text; SetName: Code[20])
    begin
        RunCase(Observer, 'deleteall_' + Tag, SetName, 21);
        RunCase(Observer, 'deleteall_true_' + Tag, SetName, 22);
        RunCase(Observer, 'modifyall_' + Tag, SetName, 23);
        RunCase(Observer, 'modifyall_true_' + Tag, SetName, 24);
        RunCase(Observer, 'nomatch_deleteall_' + Tag, SetName, 25);
        RunCase(Observer, 'nomatch_deleteall_true_' + Tag, SetName, 26);
        RunCase(Observer, 'nomatch_modifyall_' + Tag, SetName, 27);
        RunCase(Observer, 'nomatch_modifyall_true_' + Tag, SetName, 28);
    end;

    local procedure RunP3(var Observer: Codeunit "Probe Observer"; Tag: Text; SetName: Code[20])
    begin
        RunCase(Observer, 'a_insert_' + Tag, SetName, 31);
        RunCase(Observer, 'a_modify_' + Tag, SetName, 32);
        RunCase(Observer, 'a_delete_' + Tag, SetName, 33);
        RunCase(Observer, 'aperm_insert_' + Tag, SetName, 34);
        RunCase(Observer, 'aperm_modify_' + Tag, SetName, 35);
        RunCase(Observer, 'aperm_delete_' + Tag, SetName, 36);
    end;

    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Name: Text; SetName: Code[20]; Which: Integer)
    begin
        Mock.ClearAssignments();
        Helper.SeedTriggers();
        Mock.Set(SetName);
        asserterror Op(Which);
        Observer.ObserveError(Name);
        Mock.ClearAssignments();
    end;

    local procedure Op(Which: Integer)
    var
        Row: Record "LT Y19 Row";
        TempRow: Record "LT Y19 Row" temporary;
        TempTable: Record "LT Y19 Temp Table";
        A: Record "LT Y19 Trig A";
        APerm: Record "LT Y19 Trig A Perm";
        Deleter: Codeunit "LT Y19 Deleter";
        Modifier: Codeunit "LT Y19 Modifier";
        RecRef: RecordRef;
        Result: Text;
    begin
        case Which of
            1:
                begin
                    Row.Id := 1;
                    Row.Value := 10;
                    Row.Rename(11);
                end;
            21:
                Row.DeleteAll();
            22:
                Row.DeleteAll(true);
            23:
                Row.ModifyAll(Value, 99);
            24:
                Row.ModifyAll(Value, 99, true);
            25, 26, 27, 28:
                begin
                    Row.SetRange(Id, 100);
                    case Which of
                        25:
                            Row.DeleteAll();
                        26:
                            Row.DeleteAll(true);
                        27:
                            Row.ModifyAll(Value, 99);
                        28:
                            Row.ModifyAll(Value, 99, true);
                    end;
                end;
            31:
                begin
                    A.Id := 2;
                    A.Insert(true);
                end;
            32:
                begin
                    A.Id := 1;
                    A.Value := 5;
                    A.Modify(true);
                end;
            33:
                begin
                    A.Id := 1;
                    A.Delete(true);
                end;
            34:
                begin
                    APerm.Id := 2;
                    APerm.Insert(true);
                end;
            35:
                begin
                    APerm.Id := 1;
                    APerm.Value := 5;
                    APerm.Modify(true);
                end;
            36:
                begin
                    APerm.Id := 1;
                    APerm.Delete(true);
                end;
            41:
                Deleter.DeleteRow(1);
            42:
                Modifier.ModifyRow(1, 77);
            43:
                begin
                    Row.Id := 1;
                    Row.Delete();
                end;
            44:
                begin
                    Row.Id := 1;
                    Row.Value := 77;
                    Row.Modify();
                end;
            61:
                begin
                    RecRef.Open(Database::"LT Y19 Row");
                    RecRef.Field(1).Value := 5;
                    RecRef.Insert();
                end;
            62:
                begin
                    RecRef.Open(Database::"LT Y19 Row");
                    RecRef.Field(1).Value := 1;
                    RecRef.Field(2).Value := 77;
                    RecRef.Modify();
                end;
            63:
                begin
                    RecRef.Open(Database::"LT Y19 Row");
                    RecRef.Field(1).Value := 1;
                    RecRef.Delete();
                end;
            64, 65, 66:
                begin
                    TempRow.Id := 5;
                    TempRow.Insert();
                    if Which >= 65 then begin
                        TempRow.Value := 6;
                        TempRow.Modify();
                    end;
                    if Which = 66 then
                        TempRow.Delete();
                    Result := 'temp ' + Format(TempRow.Count()) + ' ';
                end;
            67, 68, 69:
                begin
                    TempTable.Id := 5;
                    TempTable.Insert();
                    if Which >= 68 then begin
                        TempTable.Value := 6;
                        TempTable.Modify();
                    end;
                    if Which = 69 then
                        TempTable.Delete();
                    Result := 'temp ' + Format(TempTable.Count()) + ' ';
                end;
            70:
                begin
                    RecRef.Open(Database::"LT Y19 Row", true);
                    RecRef.Field(1).Value := 5;
                    RecRef.Insert();
                    Result := 'temp ' + Format(RecRef.Count()) + ' ';
                end;
        end;
        if Which in [31 .. 36] then
            Result += 'b ' + Helper.DescribeB();
        Error('LT Y19 ok %1rows %2', Result, Helper.DescribeRows());
    end;
}
