// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); the tables "REC StaleMx Row" (97290) and "REC StaleMx Other" (97291) and the step codeunit
//   "REC StaleMx Ops" (97290) of record/crud/StaleRuleMatrix.al; own codeunits 76600 and 76601
// local object: codeunit 76600 must fail inside `if Codeunit.Run` after a write, so the rollback of a failed guarded run can be measured.
// Probe: al-runner issue 6924, the edges that record/crud/StaleRuleMatrix.al leaves open for the one rule of the stale record buffer.
//   Area: how the open transaction ends or loses its contact with the row's table before the stale write (LockTable then a rollback with
//   nothing after it, a failed `if Codeunit.Run` that wrote), the row itself
//   deleted, deleted and inserted again, renamed, renamed back, a ModifyAll that matches no row, a Truncate of another table.
//   The cell notation is the one of the header of StaleRuleMatrix.al (buffer kind, steps, final write). New steps of this file:
//     f:x  step x inside `if Codeunit.Run` of codeunit 76600, which raises an error after the step; '<cell>|runs' records Y or N
//     rd   another variable: Get(6), Delete(false)                    ri   another variable inserts row 6 again (Text 'again')
//     rn   another variable: Get(6), Rename(60)                       rnb  another variable: Get(60), Rename(6)
//     oman ModifyAll on the row table filtered to row 1000 (no row)   kt   Truncate of the other table
// Every test records what BC produced with Observer.Expect and ends in Verify().
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
        Observer: Codeunit "Probe Observer";
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
    begin
        Clear(Observer);
        Cell(Observer, 'lk_rb', 'insert_modify', 'C rm C lk rb', 'modify_true');
        Cell(Observer, 'lk_rb_insert', 'insert', 'C rm C lk rb', 'modify_true');
        Cell(Observer, 'lk_rb_lk', 'insert_modify', 'C rm C lk rb lk', 'modify_true');
        Cell(Observer, 'lk_rb_false', 'insert_modify', 'C rm C lk rb', 'modify_false');
        Observer.Expect('lk_rb', 'error');
        Observer.Expect('lk_rb|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('lk_rb|code', 'DB:RecordChanged');
        Observer.Expect('lk_rb|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('lk_rb_insert', 'error');
        Observer.Expect('lk_rb_insert|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('lk_rb_insert|code', 'DB:RecordChanged');
        Observer.Expect('lk_rb_insert|stored', 'o2|0|0|0 buf=1');
        Observer.Expect('lk_rb_lk', 'ok');
        Observer.Expect('lk_rb_lk|stored', 'start|5|1|2 buf=2');
        Observer.Expect('lk_rb_false', 'error');
        Observer.Expect('lk_rb_false|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('lk_rb_false|code', 'DB:RecordChanged');
        Observer.Expect('lk_rb_false|stored', 'o2|0|1|1 buf=1');
        Observer.Verify();
    end;




    // A failed `if Codeunit.Run` that wrote before its error: the row, another row, another table.
    [Test]
    procedure StaleEdge_FailedGuardedRun()
    begin
        Clear(Observer);
        Cell(Observer, 'f_rm', 'insert_modify', 'C rm C f:rm', 'modify_true');
        Cell(Observer, 'f_om', 'insert_modify', 'C rm C f:om', 'modify_true');
        Cell(Observer, 'f_ki', 'insert_modify', 'C rm C f:ki', 'modify_true');
        Cell(Observer, 'f_lk', 'insert_modify', 'C rm C f:lk', 'modify_true');
        Cell(Observer, 'f_rm_rm', 'insert_modify', 'C rm C f:rm rm', 'modify_true');
        Cell(Observer, 'f_rm_insert', 'insert', 'C rm C f:rm', 'modify_true');
        Observer.Expect('f_rm', 'error');
        Observer.Expect('f_rm|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('f_rm|code', 'DB:RecordChanged');
        Observer.Expect('f_rm|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('f_rm|runs', 'N');
        Observer.Expect('f_om', 'error');
        Observer.Expect('f_om|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('f_om|code', 'DB:RecordChanged');
        Observer.Expect('f_om|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('f_om|runs', 'N');
        Observer.Expect('f_ki', 'error');
        Observer.Expect('f_ki|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('f_ki|code', 'DB:RecordChanged');
        Observer.Expect('f_ki|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('f_ki|runs', 'N');
        Observer.Expect('f_lk', 'error');
        Observer.Expect('f_lk|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('f_lk|code', 'DB:RecordChanged');
        Observer.Expect('f_lk|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('f_lk|runs', 'N');
        Observer.Expect('f_rm_rm', 'ok');
        Observer.Expect('f_rm_rm|stored', 'start|5|1|2 buf=2');
        Observer.Expect('f_rm_rm|runs', 'N');
        Observer.Expect('f_rm_insert', 'error');
        Observer.Expect('f_rm_insert|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('f_rm_insert|code', 'DB:RecordChanged');
        Observer.Expect('f_rm_insert|stored', 'o2|0|0|0 buf=1');
        Observer.Expect('f_rm_insert|runs', 'N');
        Observer.Verify();
    end;




    // The row itself deleted by another variable in the open transaction, and inserted again after it.
    [Test]
    procedure StaleEdge_RowDeletedAndInserted()
    begin
        Clear(Observer);
        Cell(Observer, 'rd', 'insert_modify', 'C rm C rd', 'modify_true');
        Cell(Observer, 'rd_ri', 'insert_modify', 'C rm C rd ri', 'modify_true');
        Cell(Observer, 'rd_ri_false', 'insert_modify', 'C rm C rd ri', 'modify_false');
        Cell(Observer, 'rd_ri_delete', 'insert_modify', 'C rm C rd ri', 'delete_false');
        Cell(Observer, 'rd_ri_committed', 'get_committed', 'C rd ri', 'modify_true');
        Observer.Expect('rd', 'error');
        Observer.Expect('rd|text', 'The REC StaleMx Row does not exist. Identification fields and values: Entry No.=''6''');
        Observer.Expect('rd|code', 'DB:RecordNotFound');
        Observer.Expect('rd|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('rd_ri', 'ok');
        Observer.Expect('rd_ri|stored', 'start|5|1|2 buf=2');
        Observer.Expect('rd_ri_false', 'ok');
        Observer.Expect('rd_ri_false|stored', 'start|5|1|1 buf=1');
        Observer.Expect('rd_ri_delete', 'ok');
        Observer.Expect('rd_ri_delete|stored', 'none buf=1');
        Observer.Expect('rd_ri_committed', 'error');
        Observer.Expect('rd_ri_committed|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('rd_ri_committed|code', 'DB:RecordChanged');
        Observer.Expect('rd_ri_committed|stored', 'start|0|0|0 buf=1');
        Observer.Verify();
    end;




    // The row itself renamed by another variable in the open transaction, and renamed back.
    [Test]
    procedure StaleEdge_RowRenamed()
    begin
        Clear(Observer);
        Cell(Observer, 'rn', 'insert_modify', 'C rm C rn', 'modify_true');
        Cell(Observer, 'rn_rnb', 'insert_modify', 'C rm C rn rnb', 'modify_true');
        Cell(Observer, 'rn_rnb_false', 'insert_modify', 'C rm C rn rnb', 'modify_false');
        Observer.Expect('rn', 'error');
        Observer.Expect('rn|text', 'The REC StaleMx Row does not exist. Identification fields and values: Entry No.=''6''');
        Observer.Expect('rn|code', 'DB:RecordNotFound');
        Observer.Expect('rn|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('rn_rnb', 'ok');
        Observer.Expect('rn_rnb|stored', 'start|5|1|2 buf=2');
        Observer.Expect('rn_rnb_false', 'ok');
        Observer.Expect('rn_rnb_false|stored', 'start|5|1|1 buf=1');
        Observer.Verify();
    end;




    // A ModifyAll on the row's table that matches no row.
    [Test]
    procedure StaleEdge_NoRowModifyAll()
    begin
        Clear(Observer);
        Cell(Observer, 'oman', 'insert_modify', 'C rm C oman', 'modify_true');
        Cell(Observer, 'oman_1c', 'insert_modify', 'rm C oman', 'modify_true');
        Observer.Expect('oman', 'ok');
        Observer.Expect('oman|stored', 'start|5|1|2 buf=2');
        Observer.Expect('oman_1c', 'ok');
        Observer.Expect('oman_1c|stored', 'start|5|1|2 buf=2');
        Observer.Verify();
    end;




    // A Truncate of another table in the open transaction.
    [Test]
    procedure StaleEdge_TruncateOtherTable()
    begin
        Clear(Observer);
        Cell(Observer, 'kt', 'insert_modify', 'C rm C kt', 'modify_true');
        Observer.Expect('kt', 'error');
        Observer.Expect('kt|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('kt|code', 'DB:RecordChanged');
        Observer.Expect('kt|stored', 'o2|0|1|1 buf=2');
        Observer.Verify();
    end;




}
