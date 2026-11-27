// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modifyall-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT Y19 Perm Helper (91935, record/Y19PermObjects.al); Permissions Mock (131006) from the dependency.
// local object: the tests assign permission sets that must name their own tables, and a table trigger must run the write.
// Probe (al-runner issue 8068, whole topic): whether BC denies ModifyAll, ModifyAll(true), ModifyAll of the filter field, DeleteAll,
//   DeleteAll(true) and Modify on "PRM BW Target" under a lowered session, by the number of rows the filter matches and the place
//   the write runs in. Each cell: clear the assignment, seed the target, assign ONE set (Permissions Mock.Set: the set plus All
//   Objects), run the write inside asserterror, end with the own error 'PRM BW ok', observe text and code, clear the assignment.
//   Rows (the filter is SetRange(Grp, 'M')): e = empty table; 0 = no match, 2 other rows; 1 = one match, 1 other row;
//   3 = three matches, 1 other row. Modify: the first match, or a record with Id 999 that does not exist when nothing matches.
//   Places: T = local procedure of the test codeunit; C = codeunit without Permissions; CP = codeunit with
//   Permissions = tabledata "PRM BW Target" = rimd; D, M, I = OnDelete (Delete(true)), OnModify (Modify(true)), OnInsert
//   (Insert(true)) of a table without Permissions; DP = OnDelete of a table with that Permissions property.
//   Sets: R = R on the target; RInd = R plus indirect imd on the target; RIMD = direct RIMD (control). Every set grants RIMD on
//   the two host tables.
// Expected values: observed on Business Central on Windows (official BC containers) 27.5, 28.5 and 29.0; all three agree. On
//   those hosts a write whose filter matches no row is not denied in any place or set, and the pinned no-match cases of
//   record/Y19PermNoMatchShapes.al and Y19PermNoMatchTriggers.al (denied on the Linux corpus CI) are not denied either. Windows
//   is the reference: a Linux CI failure of the no-match cells here is a BC on Linux difference.
// BC versions: 27, 28, 29

table 77741 "PRM BW Target"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
        field(3; Value; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 77742 "PRM BW Host"
{
    DataClassification = SystemMetadata;
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }

    trigger OnInsert()
    begin
        RunArmed('I');
    end;

    trigger OnModify()
    begin
        RunArmed('M');
    end;

    trigger OnDelete()
    begin
        RunArmed('D');
    end;

    local procedure RunArmed(TriggerKind: Text)
    var
        Arm: Codeunit "PRM BW Arm";
    begin
        if Arm.Armed(TriggerKind) then
            DoOp(Arm.Op());
    end;

    local procedure DoOp(Op: Integer)
    var
        Target: Record "PRM BW Target";
    begin
        Target.SetRange(Grp, 'M');
        case Op of
            1:
                Target.ModifyAll(Value, 99);
            2:
                Target.ModifyAll(Value, 99, true);
            3:
                Target.ModifyAll(Grp, '');
            4:
                Target.DeleteAll();
            5:
                Target.DeleteAll(true);
            6:
                if Target.FindFirst() then begin
                    Target.Value := 99;
                    Target.Modify();
                end else begin
                    Target.Init();
                    Target.Id := 999;
                    Target.Modify();
                end;
        end;
    end;
}

table 77743 "PRM BW Host Perm"
{
    DataClassification = SystemMetadata;
    Permissions = tabledata "PRM BW Target" = rimd;
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }

    trigger OnInsert()
    begin
        RunArmed('I');
    end;

    trigger OnModify()
    begin
        RunArmed('M');
    end;

    trigger OnDelete()
    begin
        RunArmed('D');
    end;

    local procedure RunArmed(TriggerKind: Text)
    var
        Arm: Codeunit "PRM BW Arm";
    begin
        if Arm.Armed(TriggerKind) then
            DoOp(Arm.Op());
    end;

    local procedure DoOp(Op: Integer)
    var
        Target: Record "PRM BW Target";
    begin
        Target.SetRange(Grp, 'M');
        case Op of
            1:
                Target.ModifyAll(Value, 99);
            2:
                Target.ModifyAll(Value, 99, true);
            3:
                Target.ModifyAll(Grp, '');
            4:
                Target.DeleteAll();
            5:
                Target.DeleteAll(true);
            6:
                if Target.FindFirst() then begin
                    Target.Value := 99;
                    Target.Modify();
                end else begin
                    Target.Init();
                    Target.Id := 999;
                    Target.Modify();
                end;
        end;
    end;
}

codeunit 77744 "PRM BW Arm"
{
    SingleInstance = true;

    var
        ArmedKind: Text;
        ArmedOp: Integer;

    procedure Arm(TriggerKind: Text; Op: Integer)
    begin
        ArmedKind := TriggerKind;
        ArmedOp := Op;
    end;

    procedure Disarm()
    begin
        ArmedKind := '';
        ArmedOp := 0;
    end;

    procedure Armed(TriggerKind: Text): Boolean
    begin
        exit((ArmedKind <> '') and (ArmedKind = TriggerKind));
    end;

    procedure Op(): Integer
    begin
        exit(ArmedOp);
    end;
}

codeunit 77745 "PRM BW Writer"
{
    procedure Run(Op: Integer)
    begin
        DoOp(Op);
    end;

    local procedure DoOp(Op: Integer)
    var
        Target: Record "PRM BW Target";
    begin
        Target.SetRange(Grp, 'M');
        case Op of
            1:
                Target.ModifyAll(Value, 99);
            2:
                Target.ModifyAll(Value, 99, true);
            3:
                Target.ModifyAll(Grp, '');
            4:
                Target.DeleteAll();
            5:
                Target.DeleteAll(true);
            6:
                if Target.FindFirst() then begin
                    Target.Value := 99;
                    Target.Modify();
                end else begin
                    Target.Init();
                    Target.Id := 999;
                    Target.Modify();
                end;
        end;
    end;
}

codeunit 77746 "PRM BW Writer Perm"
{
    Permissions = tabledata "PRM BW Target" = rimd;

    procedure Run(Op: Integer)
    begin
        DoOp(Op);
    end;

    local procedure DoOp(Op: Integer)
    var
        Target: Record "PRM BW Target";
    begin
        Target.SetRange(Grp, 'M');
        case Op of
            1:
                Target.ModifyAll(Value, 99);
            2:
                Target.ModifyAll(Value, 99, true);
            3:
                Target.ModifyAll(Grp, '');
            4:
                Target.DeleteAll();
            5:
                Target.DeleteAll(true);
            6:
                if Target.FindFirst() then begin
                    Target.Value := 99;
                    Target.Modify();
                end else begin
                    Target.Init();
                    Target.Id := 999;
                    Target.Modify();
                end;
        end;
    end;
}

permissionset 77747 "PRM BW R"
{
    Assignable = true;
    Permissions = tabledata "PRM BW Target" = R,
        tabledata "PRM BW Host" = RIMD, tabledata "PRM BW Host Perm" = RIMD;
}

permissionset 77748 "PRM BW R IND"
{
    Assignable = true;
    Permissions = tabledata "PRM BW Target" = Rimd,
        tabledata "PRM BW Host" = RIMD, tabledata "PRM BW Host Perm" = RIMD;
}

permissionset 77749 "PRM BW RIMD"
{
    Assignable = true;
    Permissions = tabledata "PRM BW Target" = RIMD,
        tabledata "PRM BW Host" = RIMD, tabledata "PRM BW Host Perm" = RIMD;
}

codeunit 77750 "PRM BW Match Counts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y19 Perm Helper";
        Mock: Codeunit "Permissions Mock";
        Arm: Codeunit "PRM BW Arm";

    [Test]
    procedure BW_TestCodeunit_SetR_ModifyAllOps()
    begin
        RunMatches('T', 'PRM BW R', 1);
        RunMatches('T', 'PRM BW R', 2);
        RunMatches('T', 'PRM BW R', 3);
        Observer.Expect('T_R_op1_e|text', 'PRM BW ok');
        Observer.Expect('T_R_op1_e|code', 'Dialog');
        Observer.Expect('T_R_op1_0|text', 'PRM BW ok');
        Observer.Expect('T_R_op1_0|code', 'Dialog');
        Observer.Expect('T_R_op1_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_R_op1_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('T_R_op1_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_R_op1_3|code', 'DB:ClientModifyDenied');
        Observer.Expect('T_R_op2_e|text', 'PRM BW ok');
        Observer.Expect('T_R_op2_e|code', 'Dialog');
        Observer.Expect('T_R_op2_0|text', 'PRM BW ok');
        Observer.Expect('T_R_op2_0|code', 'Dialog');
        Observer.Expect('T_R_op2_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_R_op2_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('T_R_op2_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_R_op2_3|code', 'DB:ClientModifyDenied');
        Observer.Expect('T_R_op3_e|text', 'PRM BW ok');
        Observer.Expect('T_R_op3_e|code', 'Dialog');
        Observer.Expect('T_R_op3_0|text', 'PRM BW ok');
        Observer.Expect('T_R_op3_0|code', 'Dialog');
        Observer.Expect('T_R_op3_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_R_op3_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('T_R_op3_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_R_op3_3|code', 'DB:ClientModifyDenied');
        Observer.Verify();
    end;

    [Test]
    procedure BW_TestCodeunit_SetR_DeleteAllModifyOps()
    begin
        RunMatches('T', 'PRM BW R', 4);
        RunMatches('T', 'PRM BW R', 5);
        RunMatches('T', 'PRM BW R', 6);
        Observer.Expect('T_R_op4_e|text', 'PRM BW ok');
        Observer.Expect('T_R_op4_e|code', 'Dialog');
        Observer.Expect('T_R_op4_0|text', 'PRM BW ok');
        Observer.Expect('T_R_op4_0|code', 'Dialog');
        Observer.Expect('T_R_op4_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('T_R_op4_1|code', 'DB:ClientDeleteDenied');
        Observer.Expect('T_R_op4_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('T_R_op4_3|code', 'DB:ClientDeleteDenied');
        Observer.Expect('T_R_op5_e|text', 'PRM BW ok');
        Observer.Expect('T_R_op5_e|code', 'Dialog');
        Observer.Expect('T_R_op5_0|text', 'PRM BW ok');
        Observer.Expect('T_R_op5_0|code', 'Dialog');
        Observer.Expect('T_R_op5_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('T_R_op5_1|code', 'DB:ClientDeleteDenied');
        Observer.Expect('T_R_op5_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('T_R_op5_3|code', 'DB:ClientDeleteDenied');
        Observer.Expect('T_R_op6_e|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_R_op6_e|code', 'DB:ClientModifyDenied');
        Observer.Expect('T_R_op6_0|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_R_op6_0|code', 'DB:ClientModifyDenied');
        Observer.Expect('T_R_op6_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_R_op6_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('T_R_op6_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_R_op6_3|code', 'DB:ClientModifyDenied');
        Observer.Verify();
    end;

    [Test]
    procedure BW_TestCodeunit_SetRInd_ModifyAllOps()
    begin
        RunMatches('T', 'PRM BW R IND', 1);
        RunMatches('T', 'PRM BW R IND', 2);
        RunMatches('T', 'PRM BW R IND', 3);
        Observer.Expect('T_RIND_op1_e|text', 'PRM BW ok');
        Observer.Expect('T_RIND_op1_e|code', 'Dialog');
        Observer.Expect('T_RIND_op1_0|text', 'PRM BW ok');
        Observer.Expect('T_RIND_op1_0|code', 'Dialog');
        Observer.Expect('T_RIND_op1_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_RIND_op1_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('T_RIND_op1_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_RIND_op1_3|code', 'DB:ClientModifyDenied');
        Observer.Expect('T_RIND_op2_e|text', 'PRM BW ok');
        Observer.Expect('T_RIND_op2_e|code', 'Dialog');
        Observer.Expect('T_RIND_op2_0|text', 'PRM BW ok');
        Observer.Expect('T_RIND_op2_0|code', 'Dialog');
        Observer.Expect('T_RIND_op2_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_RIND_op2_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('T_RIND_op2_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_RIND_op2_3|code', 'DB:ClientModifyDenied');
        Observer.Expect('T_RIND_op3_e|text', 'PRM BW ok');
        Observer.Expect('T_RIND_op3_e|code', 'Dialog');
        Observer.Expect('T_RIND_op3_0|text', 'PRM BW ok');
        Observer.Expect('T_RIND_op3_0|code', 'Dialog');
        Observer.Expect('T_RIND_op3_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_RIND_op3_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('T_RIND_op3_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_RIND_op3_3|code', 'DB:ClientModifyDenied');
        Observer.Verify();
    end;

    [Test]
    procedure BW_TestCodeunit_SetRInd_DeleteAllModifyOps()
    begin
        RunMatches('T', 'PRM BW R IND', 4);
        RunMatches('T', 'PRM BW R IND', 5);
        RunMatches('T', 'PRM BW R IND', 6);
        Observer.Expect('T_RIND_op4_e|text', 'PRM BW ok');
        Observer.Expect('T_RIND_op4_e|code', 'Dialog');
        Observer.Expect('T_RIND_op4_0|text', 'PRM BW ok');
        Observer.Expect('T_RIND_op4_0|code', 'Dialog');
        Observer.Expect('T_RIND_op4_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('T_RIND_op4_1|code', 'DB:ClientDeleteDenied');
        Observer.Expect('T_RIND_op4_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('T_RIND_op4_3|code', 'DB:ClientDeleteDenied');
        Observer.Expect('T_RIND_op5_e|text', 'PRM BW ok');
        Observer.Expect('T_RIND_op5_e|code', 'Dialog');
        Observer.Expect('T_RIND_op5_0|text', 'PRM BW ok');
        Observer.Expect('T_RIND_op5_0|code', 'Dialog');
        Observer.Expect('T_RIND_op5_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('T_RIND_op5_1|code', 'DB:ClientDeleteDenied');
        Observer.Expect('T_RIND_op5_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('T_RIND_op5_3|code', 'DB:ClientDeleteDenied');
        Observer.Expect('T_RIND_op6_e|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_RIND_op6_e|code', 'DB:ClientModifyDenied');
        Observer.Expect('T_RIND_op6_0|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_RIND_op6_0|code', 'DB:ClientModifyDenied');
        Observer.Expect('T_RIND_op6_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_RIND_op6_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('T_RIND_op6_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('T_RIND_op6_3|code', 'DB:ClientModifyDenied');
        Observer.Verify();
    end;

    [Test]
    procedure BW_TestCodeunit_SetRIMD_ModifyAllOps()
    begin
        RunMatches('T', 'PRM BW RIMD', 1);
        RunMatches('T', 'PRM BW RIMD', 2);
        RunMatches('T', 'PRM BW RIMD', 3);
        Observer.Expect('T_RIMD_op1_e|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op1_e|code', 'Dialog');
        Observer.Expect('T_RIMD_op1_0|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op1_0|code', 'Dialog');
        Observer.Expect('T_RIMD_op1_1|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op1_1|code', 'Dialog');
        Observer.Expect('T_RIMD_op1_3|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op1_3|code', 'Dialog');
        Observer.Expect('T_RIMD_op2_e|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op2_e|code', 'Dialog');
        Observer.Expect('T_RIMD_op2_0|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op2_0|code', 'Dialog');
        Observer.Expect('T_RIMD_op2_1|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op2_1|code', 'Dialog');
        Observer.Expect('T_RIMD_op2_3|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op2_3|code', 'Dialog');
        Observer.Expect('T_RIMD_op3_e|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op3_e|code', 'Dialog');
        Observer.Expect('T_RIMD_op3_0|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op3_0|code', 'Dialog');
        Observer.Expect('T_RIMD_op3_1|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op3_1|code', 'Dialog');
        Observer.Expect('T_RIMD_op3_3|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op3_3|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure BW_TestCodeunit_SetRIMD_DeleteAllModifyOps()
    begin
        RunMatches('T', 'PRM BW RIMD', 4);
        RunMatches('T', 'PRM BW RIMD', 5);
        RunMatches('T', 'PRM BW RIMD', 6);
        Observer.Expect('T_RIMD_op4_e|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op4_e|code', 'Dialog');
        Observer.Expect('T_RIMD_op4_0|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op4_0|code', 'Dialog');
        Observer.Expect('T_RIMD_op4_1|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op4_1|code', 'Dialog');
        Observer.Expect('T_RIMD_op4_3|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op4_3|code', 'Dialog');
        Observer.Expect('T_RIMD_op5_e|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op5_e|code', 'Dialog');
        Observer.Expect('T_RIMD_op5_0|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op5_0|code', 'Dialog');
        Observer.Expect('T_RIMD_op5_1|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op5_1|code', 'Dialog');
        Observer.Expect('T_RIMD_op5_3|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op5_3|code', 'Dialog');
        Observer.Expect('T_RIMD_op6_e|text', 'The PRM BW Target does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('T_RIMD_op6_e|code', 'DB:RecordNotFound');
        Observer.Expect('T_RIMD_op6_0|text', 'The PRM BW Target does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('T_RIMD_op6_0|code', 'DB:RecordNotFound');
        Observer.Expect('T_RIMD_op6_1|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op6_1|code', 'Dialog');
        Observer.Expect('T_RIMD_op6_3|text', 'PRM BW ok');
        Observer.Expect('T_RIMD_op6_3|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure BW_OnDelete_SetR_ModifyAllOps()
    begin
        RunMatches('D', 'PRM BW R', 1);
        RunMatches('D', 'PRM BW R', 2);
        RunMatches('D', 'PRM BW R', 3);
        Observer.Expect('D_R_op1_e|text', 'PRM BW ok');
        Observer.Expect('D_R_op1_e|code', 'Dialog');
        Observer.Expect('D_R_op1_0|text', 'PRM BW ok');
        Observer.Expect('D_R_op1_0|code', 'Dialog');
        Observer.Expect('D_R_op1_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_R_op1_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('D_R_op1_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_R_op1_3|code', 'DB:ClientModifyDenied');
        Observer.Expect('D_R_op2_e|text', 'PRM BW ok');
        Observer.Expect('D_R_op2_e|code', 'Dialog');
        Observer.Expect('D_R_op2_0|text', 'PRM BW ok');
        Observer.Expect('D_R_op2_0|code', 'Dialog');
        Observer.Expect('D_R_op2_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_R_op2_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('D_R_op2_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_R_op2_3|code', 'DB:ClientModifyDenied');
        Observer.Expect('D_R_op3_e|text', 'PRM BW ok');
        Observer.Expect('D_R_op3_e|code', 'Dialog');
        Observer.Expect('D_R_op3_0|text', 'PRM BW ok');
        Observer.Expect('D_R_op3_0|code', 'Dialog');
        Observer.Expect('D_R_op3_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_R_op3_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('D_R_op3_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_R_op3_3|code', 'DB:ClientModifyDenied');
        Observer.Verify();
    end;

    [Test]
    procedure BW_OnDelete_SetR_DeleteAllModifyOps()
    begin
        RunMatches('D', 'PRM BW R', 4);
        RunMatches('D', 'PRM BW R', 5);
        RunMatches('D', 'PRM BW R', 6);
        Observer.Expect('D_R_op4_e|text', 'PRM BW ok');
        Observer.Expect('D_R_op4_e|code', 'Dialog');
        Observer.Expect('D_R_op4_0|text', 'PRM BW ok');
        Observer.Expect('D_R_op4_0|code', 'Dialog');
        Observer.Expect('D_R_op4_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('D_R_op4_1|code', 'DB:ClientDeleteDenied');
        Observer.Expect('D_R_op4_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('D_R_op4_3|code', 'DB:ClientDeleteDenied');
        Observer.Expect('D_R_op5_e|text', 'PRM BW ok');
        Observer.Expect('D_R_op5_e|code', 'Dialog');
        Observer.Expect('D_R_op5_0|text', 'PRM BW ok');
        Observer.Expect('D_R_op5_0|code', 'Dialog');
        Observer.Expect('D_R_op5_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('D_R_op5_1|code', 'DB:ClientDeleteDenied');
        Observer.Expect('D_R_op5_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('D_R_op5_3|code', 'DB:ClientDeleteDenied');
        Observer.Expect('D_R_op6_e|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_R_op6_e|code', 'DB:ClientModifyDenied');
        Observer.Expect('D_R_op6_0|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_R_op6_0|code', 'DB:ClientModifyDenied');
        Observer.Expect('D_R_op6_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_R_op6_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('D_R_op6_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_R_op6_3|code', 'DB:ClientModifyDenied');
        Observer.Verify();
    end;

    [Test]
    procedure BW_OnDelete_SetRInd_ModifyAllOps()
    begin
        RunMatches('D', 'PRM BW R IND', 1);
        RunMatches('D', 'PRM BW R IND', 2);
        RunMatches('D', 'PRM BW R IND', 3);
        Observer.Expect('D_RIND_op1_e|text', 'PRM BW ok');
        Observer.Expect('D_RIND_op1_e|code', 'Dialog');
        Observer.Expect('D_RIND_op1_0|text', 'PRM BW ok');
        Observer.Expect('D_RIND_op1_0|code', 'Dialog');
        Observer.Expect('D_RIND_op1_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_RIND_op1_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('D_RIND_op1_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_RIND_op1_3|code', 'DB:ClientModifyDenied');
        Observer.Expect('D_RIND_op2_e|text', 'PRM BW ok');
        Observer.Expect('D_RIND_op2_e|code', 'Dialog');
        Observer.Expect('D_RIND_op2_0|text', 'PRM BW ok');
        Observer.Expect('D_RIND_op2_0|code', 'Dialog');
        Observer.Expect('D_RIND_op2_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_RIND_op2_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('D_RIND_op2_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_RIND_op2_3|code', 'DB:ClientModifyDenied');
        Observer.Expect('D_RIND_op3_e|text', 'PRM BW ok');
        Observer.Expect('D_RIND_op3_e|code', 'Dialog');
        Observer.Expect('D_RIND_op3_0|text', 'PRM BW ok');
        Observer.Expect('D_RIND_op3_0|code', 'Dialog');
        Observer.Expect('D_RIND_op3_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_RIND_op3_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('D_RIND_op3_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_RIND_op3_3|code', 'DB:ClientModifyDenied');
        Observer.Verify();
    end;

    [Test]
    procedure BW_OnDelete_SetRInd_DeleteAllModifyOps()
    begin
        RunMatches('D', 'PRM BW R IND', 4);
        RunMatches('D', 'PRM BW R IND', 5);
        RunMatches('D', 'PRM BW R IND', 6);
        Observer.Expect('D_RIND_op4_e|text', 'PRM BW ok');
        Observer.Expect('D_RIND_op4_e|code', 'Dialog');
        Observer.Expect('D_RIND_op4_0|text', 'PRM BW ok');
        Observer.Expect('D_RIND_op4_0|code', 'Dialog');
        Observer.Expect('D_RIND_op4_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('D_RIND_op4_1|code', 'DB:ClientDeleteDenied');
        Observer.Expect('D_RIND_op4_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('D_RIND_op4_3|code', 'DB:ClientDeleteDenied');
        Observer.Expect('D_RIND_op5_e|text', 'PRM BW ok');
        Observer.Expect('D_RIND_op5_e|code', 'Dialog');
        Observer.Expect('D_RIND_op5_0|text', 'PRM BW ok');
        Observer.Expect('D_RIND_op5_0|code', 'Dialog');
        Observer.Expect('D_RIND_op5_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('D_RIND_op5_1|code', 'DB:ClientDeleteDenied');
        Observer.Expect('D_RIND_op5_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('D_RIND_op5_3|code', 'DB:ClientDeleteDenied');
        Observer.Expect('D_RIND_op6_e|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_RIND_op6_e|code', 'DB:ClientModifyDenied');
        Observer.Expect('D_RIND_op6_0|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_RIND_op6_0|code', 'DB:ClientModifyDenied');
        Observer.Expect('D_RIND_op6_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_RIND_op6_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('D_RIND_op6_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('D_RIND_op6_3|code', 'DB:ClientModifyDenied');
        Observer.Verify();
    end;

    [Test]
    procedure BW_OnDelete_SetRIMD_ModifyAllOps()
    begin
        RunMatches('D', 'PRM BW RIMD', 1);
        RunMatches('D', 'PRM BW RIMD', 2);
        RunMatches('D', 'PRM BW RIMD', 3);
        Observer.Expect('D_RIMD_op1_e|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op1_e|code', 'Dialog');
        Observer.Expect('D_RIMD_op1_0|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op1_0|code', 'Dialog');
        Observer.Expect('D_RIMD_op1_1|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op1_1|code', 'Dialog');
        Observer.Expect('D_RIMD_op1_3|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op1_3|code', 'Dialog');
        Observer.Expect('D_RIMD_op2_e|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op2_e|code', 'Dialog');
        Observer.Expect('D_RIMD_op2_0|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op2_0|code', 'Dialog');
        Observer.Expect('D_RIMD_op2_1|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op2_1|code', 'Dialog');
        Observer.Expect('D_RIMD_op2_3|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op2_3|code', 'Dialog');
        Observer.Expect('D_RIMD_op3_e|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op3_e|code', 'Dialog');
        Observer.Expect('D_RIMD_op3_0|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op3_0|code', 'Dialog');
        Observer.Expect('D_RIMD_op3_1|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op3_1|code', 'Dialog');
        Observer.Expect('D_RIMD_op3_3|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op3_3|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure BW_OnDelete_SetRIMD_DeleteAllModifyOps()
    begin
        RunMatches('D', 'PRM BW RIMD', 4);
        RunMatches('D', 'PRM BW RIMD', 5);
        RunMatches('D', 'PRM BW RIMD', 6);
        Observer.Expect('D_RIMD_op4_e|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op4_e|code', 'Dialog');
        Observer.Expect('D_RIMD_op4_0|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op4_0|code', 'Dialog');
        Observer.Expect('D_RIMD_op4_1|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op4_1|code', 'Dialog');
        Observer.Expect('D_RIMD_op4_3|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op4_3|code', 'Dialog');
        Observer.Expect('D_RIMD_op5_e|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op5_e|code', 'Dialog');
        Observer.Expect('D_RIMD_op5_0|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op5_0|code', 'Dialog');
        Observer.Expect('D_RIMD_op5_1|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op5_1|code', 'Dialog');
        Observer.Expect('D_RIMD_op5_3|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op5_3|code', 'Dialog');
        Observer.Expect('D_RIMD_op6_e|text', 'The PRM BW Target does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('D_RIMD_op6_e|code', 'DB:RecordNotFound');
        Observer.Expect('D_RIMD_op6_0|text', 'The PRM BW Target does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('D_RIMD_op6_0|code', 'DB:RecordNotFound');
        Observer.Expect('D_RIMD_op6_1|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op6_1|code', 'Dialog');
        Observer.Expect('D_RIMD_op6_3|text', 'PRM BW ok');
        Observer.Expect('D_RIMD_op6_3|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure BW_Codeunit_SetR()
    begin
        RunMatches('C', 'PRM BW R', 1);
        RunMatches('C', 'PRM BW R', 4);
        RunMatches('C', 'PRM BW R', 6);
        Observer.Expect('C_R_op1_e|text', 'PRM BW ok');
        Observer.Expect('C_R_op1_e|code', 'Dialog');
        Observer.Expect('C_R_op1_0|text', 'PRM BW ok');
        Observer.Expect('C_R_op1_0|code', 'Dialog');
        Observer.Expect('C_R_op1_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('C_R_op1_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('C_R_op1_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('C_R_op1_3|code', 'DB:ClientModifyDenied');
        Observer.Expect('C_R_op4_e|text', 'PRM BW ok');
        Observer.Expect('C_R_op4_e|code', 'Dialog');
        Observer.Expect('C_R_op4_0|text', 'PRM BW ok');
        Observer.Expect('C_R_op4_0|code', 'Dialog');
        Observer.Expect('C_R_op4_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('C_R_op4_1|code', 'DB:ClientDeleteDenied');
        Observer.Expect('C_R_op4_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('C_R_op4_3|code', 'DB:ClientDeleteDenied');
        Observer.Expect('C_R_op6_e|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('C_R_op6_e|code', 'DB:ClientModifyDenied');
        Observer.Expect('C_R_op6_0|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('C_R_op6_0|code', 'DB:ClientModifyDenied');
        Observer.Expect('C_R_op6_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('C_R_op6_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('C_R_op6_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('C_R_op6_3|code', 'DB:ClientModifyDenied');
        Observer.Verify();
    end;

    [Test]
    procedure BW_Codeunit_SetRInd()
    begin
        RunMatches('C', 'PRM BW R IND', 1);
        RunMatches('C', 'PRM BW R IND', 4);
        RunMatches('C', 'PRM BW R IND', 6);
        Observer.Expect('C_RIND_op1_e|text', 'PRM BW ok');
        Observer.Expect('C_RIND_op1_e|code', 'Dialog');
        Observer.Expect('C_RIND_op1_0|text', 'PRM BW ok');
        Observer.Expect('C_RIND_op1_0|code', 'Dialog');
        Observer.Expect('C_RIND_op1_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('C_RIND_op1_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('C_RIND_op1_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('C_RIND_op1_3|code', 'DB:ClientModifyDenied');
        Observer.Expect('C_RIND_op4_e|text', 'PRM BW ok');
        Observer.Expect('C_RIND_op4_e|code', 'Dialog');
        Observer.Expect('C_RIND_op4_0|text', 'PRM BW ok');
        Observer.Expect('C_RIND_op4_0|code', 'Dialog');
        Observer.Expect('C_RIND_op4_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('C_RIND_op4_1|code', 'DB:ClientDeleteDenied');
        Observer.Expect('C_RIND_op4_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('C_RIND_op4_3|code', 'DB:ClientDeleteDenied');
        Observer.Expect('C_RIND_op6_e|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('C_RIND_op6_e|code', 'DB:ClientModifyDenied');
        Observer.Expect('C_RIND_op6_0|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('C_RIND_op6_0|code', 'DB:ClientModifyDenied');
        Observer.Expect('C_RIND_op6_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('C_RIND_op6_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('C_RIND_op6_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('C_RIND_op6_3|code', 'DB:ClientModifyDenied');
        Observer.Verify();
    end;

    [Test]
    procedure BW_Codeunit_SetRIMD()
    begin
        RunMatches('C', 'PRM BW RIMD', 1);
        RunMatches('C', 'PRM BW RIMD', 4);
        RunMatches('C', 'PRM BW RIMD', 6);
        Observer.Expect('C_RIMD_op1_e|text', 'PRM BW ok');
        Observer.Expect('C_RIMD_op1_e|code', 'Dialog');
        Observer.Expect('C_RIMD_op1_0|text', 'PRM BW ok');
        Observer.Expect('C_RIMD_op1_0|code', 'Dialog');
        Observer.Expect('C_RIMD_op1_1|text', 'PRM BW ok');
        Observer.Expect('C_RIMD_op1_1|code', 'Dialog');
        Observer.Expect('C_RIMD_op1_3|text', 'PRM BW ok');
        Observer.Expect('C_RIMD_op1_3|code', 'Dialog');
        Observer.Expect('C_RIMD_op4_e|text', 'PRM BW ok');
        Observer.Expect('C_RIMD_op4_e|code', 'Dialog');
        Observer.Expect('C_RIMD_op4_0|text', 'PRM BW ok');
        Observer.Expect('C_RIMD_op4_0|code', 'Dialog');
        Observer.Expect('C_RIMD_op4_1|text', 'PRM BW ok');
        Observer.Expect('C_RIMD_op4_1|code', 'Dialog');
        Observer.Expect('C_RIMD_op4_3|text', 'PRM BW ok');
        Observer.Expect('C_RIMD_op4_3|code', 'Dialog');
        Observer.Expect('C_RIMD_op6_e|text', 'The PRM BW Target does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('C_RIMD_op6_e|code', 'DB:RecordNotFound');
        Observer.Expect('C_RIMD_op6_0|text', 'The PRM BW Target does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('C_RIMD_op6_0|code', 'DB:RecordNotFound');
        Observer.Expect('C_RIMD_op6_1|text', 'PRM BW ok');
        Observer.Expect('C_RIMD_op6_1|code', 'Dialog');
        Observer.Expect('C_RIMD_op6_3|text', 'PRM BW ok');
        Observer.Expect('C_RIMD_op6_3|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure BW_CodeunitPermProp_SetR()
    begin
        RunMatches('CP', 'PRM BW R', 1);
        RunMatches('CP', 'PRM BW R', 4);
        RunMatches('CP', 'PRM BW R', 6);
        Observer.Expect('CP_R_op1_e|text', 'PRM BW ok');
        Observer.Expect('CP_R_op1_e|code', 'Dialog');
        Observer.Expect('CP_R_op1_0|text', 'PRM BW ok');
        Observer.Expect('CP_R_op1_0|code', 'Dialog');
        Observer.Expect('CP_R_op1_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target IndirectModify: AL Language Coverage Tests)');
        Observer.Expect('CP_R_op1_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('CP_R_op1_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target IndirectModify: AL Language Coverage Tests)');
        Observer.Expect('CP_R_op1_3|code', 'DB:ClientModifyDenied');
        Observer.Expect('CP_R_op4_e|text', 'PRM BW ok');
        Observer.Expect('CP_R_op4_e|code', 'Dialog');
        Observer.Expect('CP_R_op4_0|text', 'PRM BW ok');
        Observer.Expect('CP_R_op4_0|code', 'Dialog');
        Observer.Expect('CP_R_op4_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target IndirectDelete: AL Language Coverage Tests)');
        Observer.Expect('CP_R_op4_1|code', 'DB:ClientDeleteDenied');
        Observer.Expect('CP_R_op4_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target IndirectDelete: AL Language Coverage Tests)');
        Observer.Expect('CP_R_op4_3|code', 'DB:ClientDeleteDenied');
        Observer.Expect('CP_R_op6_e|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target IndirectModify: AL Language Coverage Tests)');
        Observer.Expect('CP_R_op6_e|code', 'DB:ClientModifyDenied');
        Observer.Expect('CP_R_op6_0|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target IndirectModify: AL Language Coverage Tests)');
        Observer.Expect('CP_R_op6_0|code', 'DB:ClientModifyDenied');
        Observer.Expect('CP_R_op6_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target IndirectModify: AL Language Coverage Tests)');
        Observer.Expect('CP_R_op6_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('CP_R_op6_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target IndirectModify: AL Language Coverage Tests)');
        Observer.Expect('CP_R_op6_3|code', 'DB:ClientModifyDenied');
        Observer.Verify();
    end;

    [Test]
    procedure BW_CodeunitPermProp_SetRInd()
    begin
        RunMatches('CP', 'PRM BW R IND', 1);
        RunMatches('CP', 'PRM BW R IND', 4);
        RunMatches('CP', 'PRM BW R IND', 6);
        Observer.Expect('CP_RIND_op1_e|text', 'PRM BW ok');
        Observer.Expect('CP_RIND_op1_e|code', 'Dialog');
        Observer.Expect('CP_RIND_op1_0|text', 'PRM BW ok');
        Observer.Expect('CP_RIND_op1_0|code', 'Dialog');
        Observer.Expect('CP_RIND_op1_1|text', 'PRM BW ok');
        Observer.Expect('CP_RIND_op1_1|code', 'Dialog');
        Observer.Expect('CP_RIND_op1_3|text', 'PRM BW ok');
        Observer.Expect('CP_RIND_op1_3|code', 'Dialog');
        Observer.Expect('CP_RIND_op4_e|text', 'PRM BW ok');
        Observer.Expect('CP_RIND_op4_e|code', 'Dialog');
        Observer.Expect('CP_RIND_op4_0|text', 'PRM BW ok');
        Observer.Expect('CP_RIND_op4_0|code', 'Dialog');
        Observer.Expect('CP_RIND_op4_1|text', 'PRM BW ok');
        Observer.Expect('CP_RIND_op4_1|code', 'Dialog');
        Observer.Expect('CP_RIND_op4_3|text', 'PRM BW ok');
        Observer.Expect('CP_RIND_op4_3|code', 'Dialog');
        Observer.Expect('CP_RIND_op6_e|text', 'The PRM BW Target does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('CP_RIND_op6_e|code', 'DB:RecordNotFound');
        Observer.Expect('CP_RIND_op6_0|text', 'The PRM BW Target does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('CP_RIND_op6_0|code', 'DB:RecordNotFound');
        Observer.Expect('CP_RIND_op6_1|text', 'PRM BW ok');
        Observer.Expect('CP_RIND_op6_1|code', 'Dialog');
        Observer.Expect('CP_RIND_op6_3|text', 'PRM BW ok');
        Observer.Expect('CP_RIND_op6_3|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure BW_CodeunitPermProp_SetRIMD()
    begin
        RunMatches('CP', 'PRM BW RIMD', 1);
        RunMatches('CP', 'PRM BW RIMD', 4);
        RunMatches('CP', 'PRM BW RIMD', 6);
        Observer.Expect('CP_RIMD_op1_e|text', 'PRM BW ok');
        Observer.Expect('CP_RIMD_op1_e|code', 'Dialog');
        Observer.Expect('CP_RIMD_op1_0|text', 'PRM BW ok');
        Observer.Expect('CP_RIMD_op1_0|code', 'Dialog');
        Observer.Expect('CP_RIMD_op1_1|text', 'PRM BW ok');
        Observer.Expect('CP_RIMD_op1_1|code', 'Dialog');
        Observer.Expect('CP_RIMD_op1_3|text', 'PRM BW ok');
        Observer.Expect('CP_RIMD_op1_3|code', 'Dialog');
        Observer.Expect('CP_RIMD_op4_e|text', 'PRM BW ok');
        Observer.Expect('CP_RIMD_op4_e|code', 'Dialog');
        Observer.Expect('CP_RIMD_op4_0|text', 'PRM BW ok');
        Observer.Expect('CP_RIMD_op4_0|code', 'Dialog');
        Observer.Expect('CP_RIMD_op4_1|text', 'PRM BW ok');
        Observer.Expect('CP_RIMD_op4_1|code', 'Dialog');
        Observer.Expect('CP_RIMD_op4_3|text', 'PRM BW ok');
        Observer.Expect('CP_RIMD_op4_3|code', 'Dialog');
        Observer.Expect('CP_RIMD_op6_e|text', 'The PRM BW Target does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('CP_RIMD_op6_e|code', 'DB:RecordNotFound');
        Observer.Expect('CP_RIMD_op6_0|text', 'The PRM BW Target does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('CP_RIMD_op6_0|code', 'DB:RecordNotFound');
        Observer.Expect('CP_RIMD_op6_1|text', 'PRM BW ok');
        Observer.Expect('CP_RIMD_op6_1|code', 'Dialog');
        Observer.Expect('CP_RIMD_op6_3|text', 'PRM BW ok');
        Observer.Expect('CP_RIMD_op6_3|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure BW_OnDeletePermProp_SetR()
    begin
        RunMatches('DP', 'PRM BW R', 1);
        RunMatches('DP', 'PRM BW R', 4);
        RunMatches('DP', 'PRM BW R', 6);
        Observer.Expect('DP_R_op1_e|text', 'PRM BW ok');
        Observer.Expect('DP_R_op1_e|code', 'Dialog');
        Observer.Expect('DP_R_op1_0|text', 'PRM BW ok');
        Observer.Expect('DP_R_op1_0|code', 'Dialog');
        Observer.Expect('DP_R_op1_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target IndirectModify: AL Language Coverage Tests)');
        Observer.Expect('DP_R_op1_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('DP_R_op1_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target IndirectModify: AL Language Coverage Tests)');
        Observer.Expect('DP_R_op1_3|code', 'DB:ClientModifyDenied');
        Observer.Expect('DP_R_op4_e|text', 'PRM BW ok');
        Observer.Expect('DP_R_op4_e|code', 'Dialog');
        Observer.Expect('DP_R_op4_0|text', 'PRM BW ok');
        Observer.Expect('DP_R_op4_0|code', 'Dialog');
        Observer.Expect('DP_R_op4_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target IndirectDelete: AL Language Coverage Tests)');
        Observer.Expect('DP_R_op4_1|code', 'DB:ClientDeleteDenied');
        Observer.Expect('DP_R_op4_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target IndirectDelete: AL Language Coverage Tests)');
        Observer.Expect('DP_R_op4_3|code', 'DB:ClientDeleteDenied');
        Observer.Expect('DP_R_op6_e|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target IndirectModify: AL Language Coverage Tests)');
        Observer.Expect('DP_R_op6_e|code', 'DB:ClientModifyDenied');
        Observer.Expect('DP_R_op6_0|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target IndirectModify: AL Language Coverage Tests)');
        Observer.Expect('DP_R_op6_0|code', 'DB:ClientModifyDenied');
        Observer.Expect('DP_R_op6_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target IndirectModify: AL Language Coverage Tests)');
        Observer.Expect('DP_R_op6_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('DP_R_op6_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target IndirectModify: AL Language Coverage Tests)');
        Observer.Expect('DP_R_op6_3|code', 'DB:ClientModifyDenied');
        Observer.Verify();
    end;

    [Test]
    procedure BW_OnDeletePermProp_SetRInd()
    begin
        RunMatches('DP', 'PRM BW R IND', 1);
        RunMatches('DP', 'PRM BW R IND', 4);
        RunMatches('DP', 'PRM BW R IND', 6);
        Observer.Expect('DP_RIND_op1_e|text', 'PRM BW ok');
        Observer.Expect('DP_RIND_op1_e|code', 'Dialog');
        Observer.Expect('DP_RIND_op1_0|text', 'PRM BW ok');
        Observer.Expect('DP_RIND_op1_0|code', 'Dialog');
        Observer.Expect('DP_RIND_op1_1|text', 'PRM BW ok');
        Observer.Expect('DP_RIND_op1_1|code', 'Dialog');
        Observer.Expect('DP_RIND_op1_3|text', 'PRM BW ok');
        Observer.Expect('DP_RIND_op1_3|code', 'Dialog');
        Observer.Expect('DP_RIND_op4_e|text', 'PRM BW ok');
        Observer.Expect('DP_RIND_op4_e|code', 'Dialog');
        Observer.Expect('DP_RIND_op4_0|text', 'PRM BW ok');
        Observer.Expect('DP_RIND_op4_0|code', 'Dialog');
        Observer.Expect('DP_RIND_op4_1|text', 'PRM BW ok');
        Observer.Expect('DP_RIND_op4_1|code', 'Dialog');
        Observer.Expect('DP_RIND_op4_3|text', 'PRM BW ok');
        Observer.Expect('DP_RIND_op4_3|code', 'Dialog');
        Observer.Expect('DP_RIND_op6_e|text', 'The PRM BW Target does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('DP_RIND_op6_e|code', 'DB:RecordNotFound');
        Observer.Expect('DP_RIND_op6_0|text', 'The PRM BW Target does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('DP_RIND_op6_0|code', 'DB:RecordNotFound');
        Observer.Expect('DP_RIND_op6_1|text', 'PRM BW ok');
        Observer.Expect('DP_RIND_op6_1|code', 'Dialog');
        Observer.Expect('DP_RIND_op6_3|text', 'PRM BW ok');
        Observer.Expect('DP_RIND_op6_3|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure BW_OnDeletePermProp_SetRIMD()
    begin
        RunMatches('DP', 'PRM BW RIMD', 1);
        RunMatches('DP', 'PRM BW RIMD', 4);
        RunMatches('DP', 'PRM BW RIMD', 6);
        Observer.Expect('DP_RIMD_op1_e|text', 'PRM BW ok');
        Observer.Expect('DP_RIMD_op1_e|code', 'Dialog');
        Observer.Expect('DP_RIMD_op1_0|text', 'PRM BW ok');
        Observer.Expect('DP_RIMD_op1_0|code', 'Dialog');
        Observer.Expect('DP_RIMD_op1_1|text', 'PRM BW ok');
        Observer.Expect('DP_RIMD_op1_1|code', 'Dialog');
        Observer.Expect('DP_RIMD_op1_3|text', 'PRM BW ok');
        Observer.Expect('DP_RIMD_op1_3|code', 'Dialog');
        Observer.Expect('DP_RIMD_op4_e|text', 'PRM BW ok');
        Observer.Expect('DP_RIMD_op4_e|code', 'Dialog');
        Observer.Expect('DP_RIMD_op4_0|text', 'PRM BW ok');
        Observer.Expect('DP_RIMD_op4_0|code', 'Dialog');
        Observer.Expect('DP_RIMD_op4_1|text', 'PRM BW ok');
        Observer.Expect('DP_RIMD_op4_1|code', 'Dialog');
        Observer.Expect('DP_RIMD_op4_3|text', 'PRM BW ok');
        Observer.Expect('DP_RIMD_op4_3|code', 'Dialog');
        Observer.Expect('DP_RIMD_op6_e|text', 'The PRM BW Target does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('DP_RIMD_op6_e|code', 'DB:RecordNotFound');
        Observer.Expect('DP_RIMD_op6_0|text', 'The PRM BW Target does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('DP_RIMD_op6_0|code', 'DB:RecordNotFound');
        Observer.Expect('DP_RIMD_op6_1|text', 'PRM BW ok');
        Observer.Expect('DP_RIMD_op6_1|code', 'Dialog');
        Observer.Expect('DP_RIMD_op6_3|text', 'PRM BW ok');
        Observer.Expect('DP_RIMD_op6_3|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure BW_OnModify_SetR()
    begin
        RunMatches('M', 'PRM BW R', 1);
        RunMatches('M', 'PRM BW R', 4);
        RunMatches('M', 'PRM BW R', 6);
        Observer.Expect('M_R_op1_e|text', 'PRM BW ok');
        Observer.Expect('M_R_op1_e|code', 'Dialog');
        Observer.Expect('M_R_op1_0|text', 'PRM BW ok');
        Observer.Expect('M_R_op1_0|code', 'Dialog');
        Observer.Expect('M_R_op1_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('M_R_op1_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('M_R_op1_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('M_R_op1_3|code', 'DB:ClientModifyDenied');
        Observer.Expect('M_R_op4_e|text', 'PRM BW ok');
        Observer.Expect('M_R_op4_e|code', 'Dialog');
        Observer.Expect('M_R_op4_0|text', 'PRM BW ok');
        Observer.Expect('M_R_op4_0|code', 'Dialog');
        Observer.Expect('M_R_op4_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('M_R_op4_1|code', 'DB:ClientDeleteDenied');
        Observer.Expect('M_R_op4_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('M_R_op4_3|code', 'DB:ClientDeleteDenied');
        Observer.Expect('M_R_op6_e|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('M_R_op6_e|code', 'DB:ClientModifyDenied');
        Observer.Expect('M_R_op6_0|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('M_R_op6_0|code', 'DB:ClientModifyDenied');
        Observer.Expect('M_R_op6_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('M_R_op6_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('M_R_op6_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('M_R_op6_3|code', 'DB:ClientModifyDenied');
        Observer.Verify();
    end;

    [Test]
    procedure BW_OnModify_SetRInd()
    begin
        RunMatches('M', 'PRM BW R IND', 1);
        RunMatches('M', 'PRM BW R IND', 4);
        RunMatches('M', 'PRM BW R IND', 6);
        Observer.Expect('M_RIND_op1_e|text', 'PRM BW ok');
        Observer.Expect('M_RIND_op1_e|code', 'Dialog');
        Observer.Expect('M_RIND_op1_0|text', 'PRM BW ok');
        Observer.Expect('M_RIND_op1_0|code', 'Dialog');
        Observer.Expect('M_RIND_op1_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('M_RIND_op1_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('M_RIND_op1_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('M_RIND_op1_3|code', 'DB:ClientModifyDenied');
        Observer.Expect('M_RIND_op4_e|text', 'PRM BW ok');
        Observer.Expect('M_RIND_op4_e|code', 'Dialog');
        Observer.Expect('M_RIND_op4_0|text', 'PRM BW ok');
        Observer.Expect('M_RIND_op4_0|code', 'Dialog');
        Observer.Expect('M_RIND_op4_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('M_RIND_op4_1|code', 'DB:ClientDeleteDenied');
        Observer.Expect('M_RIND_op4_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('M_RIND_op4_3|code', 'DB:ClientDeleteDenied');
        Observer.Expect('M_RIND_op6_e|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('M_RIND_op6_e|code', 'DB:ClientModifyDenied');
        Observer.Expect('M_RIND_op6_0|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('M_RIND_op6_0|code', 'DB:ClientModifyDenied');
        Observer.Expect('M_RIND_op6_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('M_RIND_op6_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('M_RIND_op6_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('M_RIND_op6_3|code', 'DB:ClientModifyDenied');
        Observer.Verify();
    end;

    [Test]
    procedure BW_OnModify_SetRIMD()
    begin
        RunMatches('M', 'PRM BW RIMD', 1);
        RunMatches('M', 'PRM BW RIMD', 4);
        RunMatches('M', 'PRM BW RIMD', 6);
        Observer.Expect('M_RIMD_op1_e|text', 'PRM BW ok');
        Observer.Expect('M_RIMD_op1_e|code', 'Dialog');
        Observer.Expect('M_RIMD_op1_0|text', 'PRM BW ok');
        Observer.Expect('M_RIMD_op1_0|code', 'Dialog');
        Observer.Expect('M_RIMD_op1_1|text', 'PRM BW ok');
        Observer.Expect('M_RIMD_op1_1|code', 'Dialog');
        Observer.Expect('M_RIMD_op1_3|text', 'PRM BW ok');
        Observer.Expect('M_RIMD_op1_3|code', 'Dialog');
        Observer.Expect('M_RIMD_op4_e|text', 'PRM BW ok');
        Observer.Expect('M_RIMD_op4_e|code', 'Dialog');
        Observer.Expect('M_RIMD_op4_0|text', 'PRM BW ok');
        Observer.Expect('M_RIMD_op4_0|code', 'Dialog');
        Observer.Expect('M_RIMD_op4_1|text', 'PRM BW ok');
        Observer.Expect('M_RIMD_op4_1|code', 'Dialog');
        Observer.Expect('M_RIMD_op4_3|text', 'PRM BW ok');
        Observer.Expect('M_RIMD_op4_3|code', 'Dialog');
        Observer.Expect('M_RIMD_op6_e|text', 'The PRM BW Target does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('M_RIMD_op6_e|code', 'DB:RecordNotFound');
        Observer.Expect('M_RIMD_op6_0|text', 'The PRM BW Target does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('M_RIMD_op6_0|code', 'DB:RecordNotFound');
        Observer.Expect('M_RIMD_op6_1|text', 'PRM BW ok');
        Observer.Expect('M_RIMD_op6_1|code', 'Dialog');
        Observer.Expect('M_RIMD_op6_3|text', 'PRM BW ok');
        Observer.Expect('M_RIMD_op6_3|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure BW_OnInsert_SetR()
    begin
        RunMatches('I', 'PRM BW R', 1);
        RunMatches('I', 'PRM BW R', 4);
        RunMatches('I', 'PRM BW R', 6);
        Observer.Expect('I_R_op1_e|text', 'PRM BW ok');
        Observer.Expect('I_R_op1_e|code', 'Dialog');
        Observer.Expect('I_R_op1_0|text', 'PRM BW ok');
        Observer.Expect('I_R_op1_0|code', 'Dialog');
        Observer.Expect('I_R_op1_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('I_R_op1_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('I_R_op1_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('I_R_op1_3|code', 'DB:ClientModifyDenied');
        Observer.Expect('I_R_op4_e|text', 'PRM BW ok');
        Observer.Expect('I_R_op4_e|code', 'Dialog');
        Observer.Expect('I_R_op4_0|text', 'PRM BW ok');
        Observer.Expect('I_R_op4_0|code', 'Dialog');
        Observer.Expect('I_R_op4_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('I_R_op4_1|code', 'DB:ClientDeleteDenied');
        Observer.Expect('I_R_op4_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('I_R_op4_3|code', 'DB:ClientDeleteDenied');
        Observer.Expect('I_R_op6_e|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('I_R_op6_e|code', 'DB:ClientModifyDenied');
        Observer.Expect('I_R_op6_0|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('I_R_op6_0|code', 'DB:ClientModifyDenied');
        Observer.Expect('I_R_op6_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('I_R_op6_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('I_R_op6_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('I_R_op6_3|code', 'DB:ClientModifyDenied');
        Observer.Verify();
    end;

    [Test]
    procedure BW_OnInsert_SetRInd()
    begin
        RunMatches('I', 'PRM BW R IND', 1);
        RunMatches('I', 'PRM BW R IND', 4);
        RunMatches('I', 'PRM BW R IND', 6);
        Observer.Expect('I_RIND_op1_e|text', 'PRM BW ok');
        Observer.Expect('I_RIND_op1_e|code', 'Dialog');
        Observer.Expect('I_RIND_op1_0|text', 'PRM BW ok');
        Observer.Expect('I_RIND_op1_0|code', 'Dialog');
        Observer.Expect('I_RIND_op1_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('I_RIND_op1_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('I_RIND_op1_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('I_RIND_op1_3|code', 'DB:ClientModifyDenied');
        Observer.Expect('I_RIND_op4_e|text', 'PRM BW ok');
        Observer.Expect('I_RIND_op4_e|code', 'Dialog');
        Observer.Expect('I_RIND_op4_0|text', 'PRM BW ok');
        Observer.Expect('I_RIND_op4_0|code', 'Dialog');
        Observer.Expect('I_RIND_op4_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('I_RIND_op4_1|code', 'DB:ClientDeleteDenied');
        Observer.Expect('I_RIND_op4_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Delete: AL Language Coverage Tests)');
        Observer.Expect('I_RIND_op4_3|code', 'DB:ClientDeleteDenied');
        Observer.Expect('I_RIND_op6_e|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('I_RIND_op6_e|code', 'DB:ClientModifyDenied');
        Observer.Expect('I_RIND_op6_0|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('I_RIND_op6_0|code', 'DB:ClientModifyDenied');
        Observer.Expect('I_RIND_op6_1|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('I_RIND_op6_1|code', 'DB:ClientModifyDenied');
        Observer.Expect('I_RIND_op6_3|text', 'Sorry, the current permissions prevented the action. (TableData 77741 PRM BW Target Modify: AL Language Coverage Tests)');
        Observer.Expect('I_RIND_op6_3|code', 'DB:ClientModifyDenied');
        Observer.Verify();
    end;

    [Test]
    procedure BW_OnInsert_SetRIMD()
    begin
        RunMatches('I', 'PRM BW RIMD', 1);
        RunMatches('I', 'PRM BW RIMD', 4);
        RunMatches('I', 'PRM BW RIMD', 6);
        Observer.Expect('I_RIMD_op1_e|text', 'PRM BW ok');
        Observer.Expect('I_RIMD_op1_e|code', 'Dialog');
        Observer.Expect('I_RIMD_op1_0|text', 'PRM BW ok');
        Observer.Expect('I_RIMD_op1_0|code', 'Dialog');
        Observer.Expect('I_RIMD_op1_1|text', 'PRM BW ok');
        Observer.Expect('I_RIMD_op1_1|code', 'Dialog');
        Observer.Expect('I_RIMD_op1_3|text', 'PRM BW ok');
        Observer.Expect('I_RIMD_op1_3|code', 'Dialog');
        Observer.Expect('I_RIMD_op4_e|text', 'PRM BW ok');
        Observer.Expect('I_RIMD_op4_e|code', 'Dialog');
        Observer.Expect('I_RIMD_op4_0|text', 'PRM BW ok');
        Observer.Expect('I_RIMD_op4_0|code', 'Dialog');
        Observer.Expect('I_RIMD_op4_1|text', 'PRM BW ok');
        Observer.Expect('I_RIMD_op4_1|code', 'Dialog');
        Observer.Expect('I_RIMD_op4_3|text', 'PRM BW ok');
        Observer.Expect('I_RIMD_op4_3|code', 'Dialog');
        Observer.Expect('I_RIMD_op6_e|text', 'The PRM BW Target does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('I_RIMD_op6_e|code', 'DB:RecordNotFound');
        Observer.Expect('I_RIMD_op6_0|text', 'The PRM BW Target does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('I_RIMD_op6_0|code', 'DB:RecordNotFound');
        Observer.Expect('I_RIMD_op6_1|text', 'PRM BW ok');
        Observer.Expect('I_RIMD_op6_1|code', 'Dialog');
        Observer.Expect('I_RIMD_op6_3|text', 'PRM BW ok');
        Observer.Expect('I_RIMD_op6_3|code', 'Dialog');
        Observer.Verify();
    end;

    local procedure RunMatches(Place: Text; SetName: Text; Op: Integer)
    begin
        RunCell(Place, SetName, Op, 'e');
        RunCell(Place, SetName, Op, '0');
        RunCell(Place, SetName, Op, '1');
        RunCell(Place, SetName, Op, '3');
    end;

    local procedure RunCell(Place: Text; SetName: Text; Op: Integer; Rows: Text)
    var
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        Mock.ClearAssignments();
        Arm.Disarm();
        Seed(Rows);
        Mock.Set(SetName);
        asserterror RunPlace(Place, Op);
        Observer.ObserveError(Place + '_' + SetName.Replace('PRM BW ', '').Replace(' ', '') + '_op' + Format(Op) + '_' + Rows);
        Arm.Disarm();
        Helper.RestoreMock(Mock, WasStarted);
    end;

    local procedure Seed(Rows: Text)
    var
        Target: Record "PRM BW Target";
        Host: Record "PRM BW Host";
        HostPerm: Record "PRM BW Host Perm";
        Matches: Integer;
        Others: Integer;
        Index: Integer;
    begin
        Target.DeleteAll();
        Host.DeleteAll();
        HostPerm.DeleteAll();
        case Rows of
            '0':
                Others := 2;
            '1':
                begin
                    Matches := 1;
                    Others := 1;
                end;
            '3':
                begin
                    Matches := 3;
                    Others := 1;
                end;
        end;
        for Index := 1 to Matches do
            InsertTarget(Index, 'M');
        for Index := 1 to Others do
            InsertTarget(100 + Index, 'O');
        Host.Code := 'H1';
        Host.Insert(false);
        HostPerm.Code := 'H1';
        HostPerm.Insert(false);
    end;

    local procedure InsertTarget(NewId: Integer; NewGrp: Code[10])
    var
        Target: Record "PRM BW Target";
    begin
        Target.Id := NewId;
        Target.Grp := NewGrp;
        Target.Value := 10;
        Target.Insert(false);
    end;

    local procedure RunPlace(Place: Text; Op: Integer)
    var
        Host: Record "PRM BW Host";
        HostPerm: Record "PRM BW Host Perm";
        Writer: Codeunit "PRM BW Writer";
        WriterPerm: Codeunit "PRM BW Writer Perm";
    begin
        case Place of
            'T':
                DoOp(Op);
            'C':
                Writer.Run(Op);
            'CP':
                WriterPerm.Run(Op);
            'D':
                begin
                    Host.Get('H1');
                    Arm.Arm('D', Op);
                    Host.Delete(true);
                end;
            'DP':
                begin
                    HostPerm.Get('H1');
                    Arm.Arm('D', Op);
                    HostPerm.Delete(true);
                end;
            'M':
                begin
                    Host.Get('H1');
                    Arm.Arm('M', Op);
                    Host.Modify(true);
                end;
            'I':
                begin
                    Host.Code := 'H2';
                    Arm.Arm('I', Op);
                    Host.Insert(true);
                end;
        end;
        Error('PRM BW ok');
    end;

    local procedure DoOp(Op: Integer)
    var
        Target: Record "PRM BW Target";
    begin
        Target.SetRange(Grp, 'M');
        case Op of
            1:
                Target.ModifyAll(Value, 99);
            2:
                Target.ModifyAll(Value, 99, true);
            3:
                Target.ModifyAll(Grp, '');
            4:
                Target.DeleteAll();
            5:
                Target.DeleteAll(true);
            6:
                if Target.FindFirst() then begin
                    Target.Value := 99;
                    Target.Modify();
                end else begin
                    Target.Init();
                    Target.Id := 999;
                    Target.Modify();
                end;
        end;
    end;
}
