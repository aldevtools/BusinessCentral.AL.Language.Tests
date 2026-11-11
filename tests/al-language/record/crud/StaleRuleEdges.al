// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), ALT Triggered and ALT Trigger Log (60002, 60003), ALTFixtureCleanup (60019); the tables "REC StaleMx Row" (97290) and "REC StaleMx Other" (97291) and the step codeunit
//   "REC StaleMx Ops" (97290) of record/crud/StaleRuleMatrix.al; own codeunits 76600 and 76601
// local object: codeunit 76600 must fail inside `if Codeunit.Run` after a write, so the rollback of a failed guarded run can be measured.
// Probe: al-runner issues 6924 and 7464, the edges that record/crud/StaleRuleMatrix.al leaves open for the one rule of the stale record buffer.
//   Area: how the open transaction ends or loses its contact with the row's table before the stale write (LockTable then a rollback with
//   nothing after it, a rollback by an error of the database instead of Error(), a failed `if Codeunit.Run` that wrote), the row itself
//   deleted, deleted and inserted again, renamed, renamed back, a ModifyAll that matches no row, a Truncate of another table; and a Modify
//   through a buffer whose own Modify and the Insert of its row a rollback undid, on a table without Modify event subscribers; and a Modify(true)
//   after a rolled-back Modify on the shared fixture "ALT Triggered" (60002), which has global and database triggers (codeunit 60025).
//   The cell notation is the one of the header of StaleRuleMatrix.al (buffer kind, steps, final write). New steps of this file:
//     rbi  asserterror of a duplicate Insert of row 8 (an error of the database rolls back the open transaction)
//     f:x  step x inside `if Codeunit.Run` of codeunit 76600, which raises an error after the step; '<cell>|runs' records Y or N
//     rd   another variable: Get(6), Delete(false)                    ri   another variable inserts row 6 again (Text 'again')
//     rn   another variable: Get(6), Rename(60)                       rnb  another variable: Get(60), Rename(6)
//     oman ModifyAll on the row table filtered to row 1000 (no row)   kt   Truncate of the other table
// Observation form: every test ends in Finish(), so the run fails on purpose and the failure message carries what BC produced.
// BC versions: 27, 28, 29

codeunit 76600 "REC StaleEdge Fail Run"
{
    TableNo = "REC StaleMx Other";

    trigger OnRun()
    var
        Ops: Codeunit "REC StaleMx Ops";
    begin
        Ops.Step(Rec.Name, Rec."Entry No.");
        Error('REC_STALEEDGE_RUN_FAILS');
    end;
}

codeunit 76601 "REC StaleEdge Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Notes: Text;
        LastText: Text;
        LastCode: Text;

    local procedure Reset()
    var
        Rows: Record "REC StaleMx Row";
        Others: Record "REC StaleMx Other";
    begin
        Rows.DeleteAll();
        Others.DeleteAll();
        Commit();
    end;

    local procedure Seed(WithRow: Boolean)
    var
        Rows: Record "REC StaleMx Row";
        Others: Record "REC StaleMx Other";
        EntryNo: Integer;
    begin
        for EntryNo := 8 to 9 do begin
            Rows.Init();
            Rows."Entry No." := EntryNo;
            Rows."Text Field" := 'another';
            Rows.Insert(false);
        end;
        for EntryNo := 1 to 2 do begin
            Others.Init();
            Others."Entry No." := EntryNo;
            Others.Name := 'seed';
            Others.Insert();
        end;
        if WithRow then begin
            Rows.Init();
            Rows."Entry No." := 6;
            Rows."Text Field" := 'start';
            Rows.Insert(true);
        end;
    end;

    local procedure MakeBuffer(var Row: Record "REC StaleMx Row"; Buffer: Text)
    begin
        case Buffer of
            'insert', 'insert_modify':
                begin
                    Seed(false);
                    Row.Init();
                    Row."Entry No." := 6;
                    Row."Text Field" := 'start';
                    Row.Insert(true);
                end;
            'get_committed':
                begin
                    Seed(true);
                    Commit();
                    Row.Get(6);
                end;
            else
                Error('REC StaleEdge: unknown buffer %1', Buffer);
        end;
        if Buffer = 'insert_modify' then begin
            Row."Decimal Field" := 1;
            Row.Modify(true);
        end;
    end;

    local procedure LocalStep(Token: Text; Seq: Integer): Boolean
    var
        Row: Record "REC StaleMx Row";
        Other: Record "REC StaleMx Other";
    begin
        case Token of
            'rbi':
                begin
                    Row.Init();
                    Row."Entry No." := 8;
                    asserterror Row.Insert(false);
                    ClearLastError();
                end;
            'rd':
                begin
                    Row.Get(6);
                    Row.Delete(false);
                end;
            'ri':
                begin
                    Row.Init();
                    Row."Entry No." := 6;
                    Row."Text Field" := 'again';
                    Row.Insert(false);
                end;
            'rn':
                begin
                    Row.Get(6);
                    Row.Rename(60);
                end;
            'rnb':
                begin
                    Row.Get(60);
                    Row.Rename(6);
                end;
            'oman':
                begin
                    Row.SetRange("Entry No.", 1000);
                    Row.ModifyAll("Integer Field", Seq);
                end;
            'kt':
                Other.Truncate();
            else
                exit(false);
        end;
        exit(true);
    end;

    local procedure Steps(Spec: Text)
    var
        Arg: Record "REC StaleMx Other" temporary;
        Ops: Codeunit "REC StaleMx Ops";
        Tokens: List of [Text];
        Token: Text;
        Seq: Integer;
    begin
        Tokens := Spec.Split(' ');
        foreach Token in Tokens do begin
            Seq += 1;
            if Token <> '' then
                case true of
                    Token = 'C':
                        Commit();
                    Token.StartsWith('g:'):
                        begin
                            Arg.Init();
                            Arg."Entry No." := Seq;
                            Arg.Name := CopyStr(Token.Substring(3), 1, MaxStrLen(Arg.Name));
                            if Codeunit.Run(Codeunit::"REC StaleMx Ops", Arg) then
                                Notes += 'Y'
                            else
                                Notes += 'N';
                        end;
                    Token.StartsWith('f:'):
                        begin
                            Arg.Init();
                            Arg."Entry No." := Seq;
                            Arg.Name := CopyStr(Token.Substring(3), 1, MaxStrLen(Arg.Name));
                            if Codeunit.Run(Codeunit::"REC StaleEdge Fail Run", Arg) then
                                Notes += 'Y'
                            else
                                Notes += 'N';
                            ClearLastError();
                        end;
                    else
                        if not LocalStep(Token, Seq) then
                            Ops.Step(Token, Seq);
                end;
        end;
    end;

    local procedure FinalWrite(var Row: Record "REC StaleMx Row"; Final: Text)
    begin
        case Final of
            'modify_true':
                begin
                    Row."Integer Field" := 5;
                    Row.Modify(true);
                end;
            'modify_false':
                begin
                    Row."Integer Field" := 5;
                    Row.Modify(false);
                end;
            'delete_false':
                Row.Delete(false);
            else
                Error('REC StaleEdge: unknown final write %1', Final);
        end;
    end;

    local procedure TryWrite(var Row: Record "REC StaleMx Row"; Final: Text): Boolean
    begin
        ClearLastError();
        asserterror
        begin
            FinalWrite(Row, Final);
            Error('REC_STALEEDGE_WRITE_DONE');
        end;
        if GetLastErrorText() = 'REC_STALEEDGE_WRITE_DONE' then begin
            ClearLastError();
            exit(true);
        end;
        LastText := GetLastErrorText();
        LastCode := GetLastErrorCode();
        ClearLastError();
        exit(false);
    end;

    local procedure StoredText(): Text
    var
        Stored: Record "REC StaleMx Row";
    begin
        if not Stored.Get(6) then
            exit('none');
        exit(Stored."Text Field" + '|' + Format(Stored."Integer Field") + '|' + Format(Stored."Decimal Field") + '|' + Format(Stored."Modify Count"));
    end;

    local procedure RunOnce(Buffer: Text; Spec: Text; Final: Text; Plain: Boolean; var Stored: Text) Ok: Boolean
    var
        Row: Record "REC StaleMx Row";
    begin
        Reset();
        Notes := '';
        MakeBuffer(Row, Buffer);
        Steps(Spec);
        if Plain then begin
            FinalWrite(Row, Final);
            Ok := true;
        end else
            Ok := TryWrite(Row, Final);
        Stored := StoredText() + ' buf=' + Format(Row."Modify Count");
        Reset();
    end;

    local procedure Cell(var Observer: Codeunit "Probe Observer"; Name: Text; Buffer: Text; Spec: Text; Final: Text)
    var
        Stored: Text;
    begin
        if RunOnce(Buffer, Spec, Final, false, Stored) then begin
            RunOnce(Buffer, Spec, Final, true, Stored);
            Observer.Observe(Name, 'ok');
        end else begin
            Observer.Observe(Name, 'error');
            Observer.Observe(Name + '|text', LastText);
            Observer.Observe(Name + '|code', LastCode);
        end;
        Observer.Observe(Name + '|stored', Stored);
        if Notes <> '' then
            Observer.Observe(Name + '|runs', Notes);
    end;

    // LockTable on the row's table, then a rollback with nothing after it; LockTable again after the rollback as the control.
    [Test]
    procedure StaleEdge_LockThenRollback()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'lk_rb', 'insert_modify', 'C rm C lk rb', 'modify_true');
        Cell(Observer, 'lk_rb_insert', 'insert', 'C rm C lk rb', 'modify_true');
        Cell(Observer, 'lk_rb_lk', 'insert_modify', 'C rm C lk rb lk', 'modify_true');
        Cell(Observer, 'lk_rb_false', 'insert_modify', 'C rm C lk rb', 'modify_false');
        Observer.Finish();
    end;

    // A rollback by an error of the database (a duplicate Insert under asserterror) instead of Error().
    [Test]
    procedure StaleEdge_DatabaseErrorRollback()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'rm_rbi', 'insert_modify', 'C rm C rm rbi', 'modify_true');
        Cell(Observer, 'om_rbi', 'insert_modify', 'C rm C om rbi', 'modify_true');
        Cell(Observer, 'rbi_rm', 'insert_modify', 'C rm C rbi rm', 'modify_true');
        Cell(Observer, 'rbi_only', 'insert_modify', 'C rm C rbi', 'modify_true');
        Observer.Finish();
    end;

    // A failed `if Codeunit.Run` that wrote before its error: the row, another row, another table.
    [Test]
    procedure StaleEdge_FailedGuardedRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'f_rm', 'insert_modify', 'C rm C f:rm', 'modify_true');
        Cell(Observer, 'f_om', 'insert_modify', 'C rm C f:om', 'modify_true');
        Cell(Observer, 'f_ki', 'insert_modify', 'C rm C f:ki', 'modify_true');
        Cell(Observer, 'f_lk', 'insert_modify', 'C rm C f:lk', 'modify_true');
        Cell(Observer, 'f_rm_rm', 'insert_modify', 'C rm C f:rm rm', 'modify_true');
        Cell(Observer, 'f_rm_insert', 'insert', 'C rm C f:rm', 'modify_true');
        Observer.Finish();
    end;

    // The row itself deleted by another variable in the open transaction, and inserted again after it.
    [Test]
    procedure StaleEdge_RowDeletedAndInserted()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'rd', 'insert_modify', 'C rm C rd', 'modify_true');
        Cell(Observer, 'rd_ri', 'insert_modify', 'C rm C rd ri', 'modify_true');
        Cell(Observer, 'rd_ri_false', 'insert_modify', 'C rm C rd ri', 'modify_false');
        Cell(Observer, 'rd_ri_delete', 'insert_modify', 'C rm C rd ri', 'delete_false');
        Cell(Observer, 'rd_ri_committed', 'get_committed', 'C rd ri', 'modify_true');
        Observer.Finish();
    end;

    // The row itself renamed by another variable in the open transaction, and renamed back.
    [Test]
    procedure StaleEdge_RowRenamed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'rn', 'insert_modify', 'C rm C rn', 'modify_true');
        Cell(Observer, 'rn_rnb', 'insert_modify', 'C rm C rn rnb', 'modify_true');
        Cell(Observer, 'rn_rnb_false', 'insert_modify', 'C rm C rn rnb', 'modify_false');
        Observer.Finish();
    end;

    // A ModifyAll on the row's table that matches no row.
    [Test]
    procedure StaleEdge_NoRowModifyAll()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'oman', 'insert_modify', 'C rm C oman', 'modify_true');
        Cell(Observer, 'oman_1c', 'insert_modify', 'rm C oman', 'modify_true');
        Observer.Finish();
    end;

    // A Truncate of another table in the open transaction.
    [Test]
    procedure StaleEdge_TruncateOtherTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'kt', 'insert_modify', 'C rm C kt', 'modify_true');
        Observer.Finish();
    end;

    local procedure RolledBackInsertAndModify(var Observer: Codeunit "Probe Observer"; Name: Text; RunTrigger: Boolean; ChangeAfter: Boolean)
    var
        Row: Record "REC StaleMx Row";
        Done: Boolean;
    begin
        Reset();
        Row.Init();
        Row."Entry No." := 6;
        Row."Text Field" := 'start';
        Row.Insert(false);
        Row."Integer Field" := 1;
        Row.Modify(RunTrigger);
        asserterror Error('REC_STALEEDGE_ROLLBACK');
        ClearLastError();
        if ChangeAfter then
            Row."Integer Field" := 2;
        ClearLastError();
        asserterror
        begin
            Done := Row.Modify(RunTrigger);
            Error('REC_STALEEDGE_WRITE_DONE %1 %2', Format(Done), StoredText());
        end;
        Observer.Observe(Name, GetLastErrorText());
        if GetLastErrorText() <> '' then
            if not GetLastErrorText().StartsWith('REC_STALEEDGE_WRITE_DONE') then
                Observer.Observe(Name + '|code', GetLastErrorCode());
        ClearLastError();
        Observer.Observe(Name + '|buf', Format(Row."Integer Field") + '|' + Format(Row."Modify Count"));
        Observer.Observe(Name + '|after', StoredText());
        Reset();
    end;

    // al-runner issue 7464: the rollback undid the buffer's own Modify and the Insert of its row (no Commit after the Insert); the table has an
    // OnModify trigger and no Modify event subscribers.
    [Test]
    procedure StaleEdge_RolledBackInsertAndModify_NoSubscribers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RolledBackInsertAndModify(Observer, 'modify_false_unchanged', false, false);
        RolledBackInsertAndModify(Observer, 'modify_true_unchanged', true, false);
        RolledBackInsertAndModify(Observer, 'modify_false_changed', false, true);
        RolledBackInsertAndModify(Observer, 'modify_true_changed', true, true);
        Observer.Finish();
    end;

    local procedure TriggerLog() Result: Text
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        if TrigLog.FindSet() then
            repeat
                Result += TrigLog.TriggerName + ',';
            until TrigLog.Next() = 0;
        TrigLog.DeleteAll();
    end;

    // al-runner issue 7464 on a table with an OnModify trigger, Modify event subscribers, global triggers (OnGlobalModify) and database
    // triggers (OnDatabaseModify): Insert, Commit, Modify(true), a failed Validate-like Error under asserterror, the same value again, Modify(true).
    [Test]
    procedure StaleEdge_RolledBackModify_GlobalAndDatabaseTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Cleanup: Codeunit ALTFixtureCleanup;
        Row: Record "ALT Triggered";
        Check: Record "ALT Triggered";
        Done: Boolean;
    begin
        Cleanup.Initialize();
        Row.Init();
        Row."Entry No." := 1;
        Row.Name := 'start';
        Row.Insert(true);
        Commit();
        TriggerLog();
        Row.Value := 1;
        Row.Modify(true);
        Observer.Observe('first modify log', TriggerLog());
        asserterror Error('REC_STALEEDGE_ROLLBACK');
        ClearLastError();
        Row.Value := 1;
        Done := Row.Modify(true);
        Observer.Observe('second modify', Format(Done));
        Observer.Observe('second modify log', TriggerLog());
        Check.Get(1);
        Observer.Observe('stored', Check.Name + '|' + Format(Check.Value));
        Observer.Observe('buffer', Row.Name + '|' + Format(Row.Value));
        Cleanup.Initialize();
        Commit();
        Observer.Finish();
    end;
}
