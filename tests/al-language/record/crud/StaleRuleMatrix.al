// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 97290 and 97291, codeunits 97290 and 97291
// local object: the tests must commit and call Codeunit.Run with a used return value, and the row table needs an OnModify trigger that counts.
// Probe: al-runner issue 6924, the matrix behind one rule for the stale record buffer. Every value is the one BC 27.5, 28.5 and 29.0
// produced (the same on all three), pinned with Observer.Expect and Observer.Verify.
// A buffer is a record variable and the row version it holds. It is stale when the committed row is newer. Each cell builds a buffer,
// lets other record variables make it stale across one or more Commits, lets the open transaction (everything since the last Commit) do
// something, and then writes through the stale buffer. Each cell observes: 'ok' or 'error' (with GetLastErrorText and GetLastErrorCode),
// and the stored row as Text|Integer|Decimal|Modify Count (or 'none') followed by buf=<Modify Count of the buffer after the write>. The
// OnModify trigger of the row table adds 1 to "Modify Count", so buf shows whether OnModify ran before a refusal.
// The write runs once inside an asserterror that raises a marker error after it (to learn whether it raises); an accepted cell runs again
// with the plain write so the stored row can be read. A refused write leaves the committed row.
// Tables: "REC StaleMx Row" (row 6 is the buffer's row, rows 8 and 9 are other rows) and "REC StaleMx Other" (rows 1 and 2).
// Buffer kinds:
//   insert               the variable's own Insert(true) of row 6 (Text 'start')
//   insert_modify        its own Insert(true), then its own Modify(true) (Decimal 1)
//   get_committed        another variable inserted row 6, Commit, then the buffer's Get (no own write)
//   get_committed_modify the same, then the buffer's own Modify(true) (Decimal 1)
//   get_uncommitted      another variable inserted row 6, the buffer's Get in that transaction (no Commit between)
// Steps after the buffer exists, separated by blanks, run in order (codeunit "REC StaleMx Ops"; n is the position of the step):
//   C    Commit
//   rm   another variable: Get(6), Text := 'o<n>', Modify(false)        rg   another variable: Get(6) only
//   fs   FindSet over the row table, read to the end                     lk   LockTable on the row table
//   lg   LockTable on the row table, then Get(6)                         lf   LockTable, SetRange on row 6, FindFirst
//   oi   Insert of another row (100 + n)                                 om   Modify(false) of row 8
//   od   Delete(false) of row 9                                          on   Rename of row 8 to 80
//   oma  ModifyAll on the row table filtered to the other rows           oda  DeleteAll on the row table filtered to the other rows
//   ki   Insert into the other table                                     km   Modify of row 1 of the other table
//   kd   Delete of row 2 of the other table                              kim  Insert into the other table, then Modify of that row
//   kda  DeleteAll on the other table                                    kma  ModifyAll on the other table
//   kl   LockTable on the other table                                    kr   ReadIsolation UpdLock, FindFirst on the other table
//   rb   asserterror Error(...): rolls back the open transaction
//   g:x  step x inside `if Codeunit.Run(...)` (return value used); the cell records Y or N for the return value in '<cell>|runs'
//   r:x  step x inside Codeunit.Run(...) as a statement (return value not used); recorded as r in '<cell>|runs'
// The stale write: modify_true (Integer := 5, Modify(true)), modify_false (Integer := 5, Modify(false)) or delete_false (Delete(false)).
// Groups (test names): the base cell (own Insert and Modify, Commit, row modified by another variable, Commit, row modified again in the
// open transaction) and the Commit count; which closed transaction wrote the row; a second action beside the row's Modify for both
// own-write buffers; the row read under LockTable; table contact only (other rows written, LockTable) at 1, 2 and 4 Commits; ModifyAll and
// DeleteAll on the same table; no contact with the table at 1, 2 and 4 Commits; Modify(false) and Delete(false) as the stale write; a
// rolled-back open transaction; `if Codeunit.Run` and Codeunit.Run as a statement around the writes; the committed-read buffer and the
// two Get buffers with an own write or an uncommitted row.
// Already pinned elsewhere (this file measures the mixes they leave open): record/crud/SbStaleOwnModify.al (own Insert and Modify, 1 to 3
// Commits, one action in the new transaction), record/crud/Y76StaleBuffers.al and record/stale-find/Y89StaleFind.al (an Insert of another
// row plus one more action), record/crud/Y27StaleOtherVarTests.al and Y27StaleOwnInsertMore.al (the row modified in the new transaction),
// record/TestRecordStaleBufferWrite.al (the committed-read buffer at one Commit), record/crud/StaleTwoCommitsOtherVars.al (the reporter's
// sequence with `if Codeunit.Run`).
// BC versions: 27+

table 97290 "REC StaleMx Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Text Field"; Text[100]) { }
        field(3; "Integer Field"; Integer) { }
        field(4; "Decimal Field"; Decimal) { }
        field(5; "Modify Count"; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }

    trigger OnModify()
    begin
        "Modify Count" += 1;
    end;
}

// The other table of the steps; a temporary record of it is also the argument of the Ops codeunit (Name = the step, "Entry No." = its position).
table 97291 "REC StaleMx Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

// One step of a cell through record variables of its own. OnRun runs the step named in Rec.Name (for Codeunit.Run).
codeunit 97290 "REC StaleMx Ops"
{
    TableNo = "REC StaleMx Other";

    trigger OnRun()
    begin
        Step(Rec.Name, Rec."Entry No.");
    end;

    procedure Step(Token: Text; Seq: Integer)
    var
        Row: Record "REC StaleMx Row";
        Other: Record "REC StaleMx Other";
    begin
        case Token of
            'rm':
                begin
                    Row.Get(6);
                    Row."Text Field" := 'o' + Format(Seq);
                    Row.Modify(false);
                end;
            'rg':
                Row.Get(6);
            'fs':
                if Row.FindSet() then
                    repeat
                    until Row.Next() = 0;
            'lk':
                Row.LockTable();
            'lg':
                begin
                    Row.LockTable();
                    Row.Get(6);
                end;
            'lf':
                begin
                    Row.LockTable();
                    Row.SetRange("Entry No.", 6);
                    Row.FindFirst();
                end;
            'oi':
                begin
                    Row.Init();
                    Row."Entry No." := 100 + Seq;
                    Row."Text Field" := 'new';
                    Row.Insert(false);
                end;
            'om':
                begin
                    Row.Get(8);
                    Row."Integer Field" := Seq;
                    Row.Modify(false);
                end;
            'od':
                begin
                    Row.Get(9);
                    Row.Delete(false);
                end;
            'on':
                begin
                    Row.Get(8);
                    Row.Rename(80);
                end;
            'oma':
                begin
                    Row.SetFilter("Entry No.", '<>%1', 6);
                    Row.ModifyAll("Integer Field", Seq);
                end;
            'oda':
                begin
                    Row.SetFilter("Entry No.", '<>%1', 6);
                    Row.DeleteAll();
                end;
            'ki':
                begin
                    Other.Init();
                    Other."Entry No." := 100 + Seq;
                    Other.Name := 'new';
                    Other.Insert();
                end;
            'km':
                begin
                    Other.Get(1);
                    Other.Name := 'm' + Format(Seq);
                    Other.Modify();
                end;
            'kd':
                begin
                    Other.Get(2);
                    Other.Delete();
                end;
            'kim':
                begin
                    Other.Init();
                    Other."Entry No." := 100 + Seq;
                    Other.Name := 'new';
                    Other.Insert();
                    Other.Get(100 + Seq);
                    Other.Name := 'final';
                    Other.Modify();
                end;
            'kda':
                Other.DeleteAll();
            'kma':
                Other.ModifyAll(Name, 'all' + Format(Seq));
            'kl':
                Other.LockTable();
            'kr':
                begin
                    Other.ReadIsolation := IsolationLevel::UpdLock;
                    Other.FindFirst();
                end;
            'rb':
                begin
                    asserterror Error('REC_STALEMX_ROLLBACK');
                    ClearLastError();
                end;
            else
                Error('REC StaleMx: unknown step %1', Token);
        end;
    end;
}

codeunit 97291 "REC StaleMx Probe"
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

    // Rows 8 and 9 of the row table and rows 1 and 2 of the other table, through other variables; WithRow: row 6 too.
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
            'get_committed', 'get_committed_modify':
                begin
                    Seed(true);
                    Commit();
                    Row.Get(6);
                end;
            'get_uncommitted':
                begin
                    Seed(true);
                    Row.Get(6);
                end;
            else
                Error('REC StaleMx: unknown buffer %1', Buffer);
        end;
        if Buffer in ['insert_modify', 'get_committed_modify'] then begin
            Row."Decimal Field" := 1;
            Row.Modify(true);
        end;
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
                    Token.StartsWith('r:'):
                        begin
                            Arg.Init();
                            Arg."Entry No." := Seq;
                            Arg.Name := CopyStr(Token.Substring(3), 1, MaxStrLen(Arg.Name));
                            Codeunit.Run(Codeunit::"REC StaleMx Ops", Arg);
                            Notes += 'r';
                        end;
                    else
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
                Error('REC StaleMx: unknown final write %1', Final);
        end;
    end;

    // A TryFunction may not write to the database, so the write runs in an asserterror statement that raises a marker error after the write.
    // True: the write went through (and is rolled back with the open transaction). False: LastText and LastCode hold the error of the write.
    local procedure TryWrite(var Row: Record "REC StaleMx Row"; Final: Text): Boolean
    begin
        ClearLastError();
        asserterror
        begin
            FinalWrite(Row, Final);
            Error('REC_STALEMX_WRITE_DONE');
        end;
        if GetLastErrorText() = 'REC_STALEMX_WRITE_DONE' then begin
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

    // Base cell and the Commit count, the open transaction modified the row.
    [Test]
    procedure StaleMx_RowContact_CommitCount()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'base_2c', 'insert_modify', 'C rm C rm', 'modify_true');
        Cell(Observer, '3c_each_tx', 'insert_modify', 'C rm C rm C rm', 'modify_true');
        Cell(Observer, '4c', 'insert_modify', 'C ki C ki C rm C rm', 'modify_true');
        Cell(Observer, '6c', 'insert_modify', 'C ki C ki C ki C ki C rm C rm', 'modify_true');
        Observer.Expect('base_2c', 'ok');
        Observer.Expect('base_2c|stored', 'start|5|1|2 buf=2');
        Observer.Expect('3c_each_tx', 'ok');
        Observer.Expect('3c_each_tx|stored', 'start|5|1|2 buf=2');
        Observer.Expect('4c', 'ok');
        Observer.Expect('4c|stored', 'start|5|1|2 buf=2');
        Observer.Expect('6c', 'ok');
        Observer.Expect('6c|stored', 'start|5|1|2 buf=2');
        Observer.Verify();
    end;

    // Which closed transaction wrote the row, with an empty transaction (two Commits in a row); the open transaction modified the row.
    [Test]
    procedure StaleMx_RowContact_History()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'own_tx_empty', 'insert_modify', 'rm C C rm', 'modify_true');
        Cell(Observer, 'two_back_empty', 'insert_modify', 'C rm C C rm', 'modify_true');
        Cell(Observer, 'empty_then_last', 'insert_modify', 'C C rm C rm', 'modify_true');
        Observer.Expect('own_tx_empty', 'ok');
        Observer.Expect('own_tx_empty|stored', 'start|5|1|2 buf=2');
        Observer.Expect('two_back_empty', 'ok');
        Observer.Expect('two_back_empty|stored', 'start|5|1|2 buf=2');
        Observer.Expect('empty_then_last', 'ok');
        Observer.Expect('empty_then_last|stored', 'start|5|1|2 buf=2');
        Observer.Verify();
    end;

    // Two Commits, the open transaction modified the row and did one more thing beside it.
    [Test]
    procedure StaleMx_Beside_InsertModify_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'rm_oi', 'insert_modify', 'C rm C rm oi', 'modify_true');
        Cell(Observer, 'rm_om', 'insert_modify', 'C rm C rm om', 'modify_true');
        Cell(Observer, 'rm_od', 'insert_modify', 'C rm C rm od', 'modify_true');
        Cell(Observer, 'rm_on', 'insert_modify', 'C rm C rm on', 'modify_true');
        Observer.Expect('rm_oi', 'ok');
        Observer.Expect('rm_oi|stored', 'start|5|1|2 buf=2');
        Observer.Expect('rm_om', 'ok');
        Observer.Expect('rm_om|stored', 'start|5|1|2 buf=2');
        Observer.Expect('rm_od', 'ok');
        Observer.Expect('rm_od|stored', 'start|5|1|2 buf=2');
        Observer.Expect('rm_on', 'ok');
        Observer.Expect('rm_on|stored', 'start|5|1|2 buf=2');
        Observer.Verify();
    end;

    // Two Commits, the open transaction modified the row and did one more thing beside it.
    [Test]
    procedure StaleMx_Beside_InsertModify_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'rm_ki', 'insert_modify', 'C rm C rm ki', 'modify_true');
        Cell(Observer, 'rm_km', 'insert_modify', 'C rm C rm km', 'modify_true');
        Cell(Observer, 'rm_kd', 'insert_modify', 'C rm C rm kd', 'modify_true');
        Cell(Observer, 'rm_kim', 'insert_modify', 'C rm C rm kim', 'modify_true');
        Observer.Expect('rm_ki', 'ok');
        Observer.Expect('rm_ki|stored', 'start|5|1|2 buf=2');
        Observer.Expect('rm_km', 'ok');
        Observer.Expect('rm_km|stored', 'start|5|1|2 buf=2');
        Observer.Expect('rm_kd', 'ok');
        Observer.Expect('rm_kd|stored', 'start|5|1|2 buf=2');
        Observer.Expect('rm_kim', 'ok');
        Observer.Expect('rm_kim|stored', 'start|5|1|2 buf=2');
        Observer.Verify();
    end;

    // Two Commits, the open transaction modified the row and did one more thing beside it.
    [Test]
    procedure StaleMx_Beside_InsertModify_C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'rm_kda', 'insert_modify', 'C rm C rm kda', 'modify_true');
        Cell(Observer, 'rm_kma', 'insert_modify', 'C rm C rm kma', 'modify_true');
        Observer.Expect('rm_kda', 'ok');
        Observer.Expect('rm_kda|stored', 'start|5|1|2 buf=2');
        Observer.Expect('rm_kma', 'ok');
        Observer.Expect('rm_kma|stored', 'start|5|1|2 buf=2');
        Observer.Verify();
    end;

    // Two Commits, the open transaction modified the row and did one more thing beside it.
    [Test]
    procedure StaleMx_Beside_InsertModify_D()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'rm_lk', 'insert_modify', 'C rm C rm lk', 'modify_true');
        Cell(Observer, 'rm_kl', 'insert_modify', 'C rm C rm kl', 'modify_true');
        Cell(Observer, 'rm_kr', 'insert_modify', 'C rm C rm kr', 'modify_true');
        Observer.Expect('rm_lk', 'ok');
        Observer.Expect('rm_lk|stored', 'start|5|1|2 buf=2');
        Observer.Expect('rm_kl', 'ok');
        Observer.Expect('rm_kl|stored', 'start|5|1|2 buf=2');
        Observer.Expect('rm_kr', 'ok');
        Observer.Expect('rm_kr|stored', 'start|5|1|2 buf=2');
        Observer.Verify();
    end;

    // Two Commits, the open transaction modified the row and did one more thing beside it.
    [Test]
    procedure StaleMx_Beside_InsertOnly_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'rm_oi', 'insert', 'C rm C rm oi', 'modify_true');
        Cell(Observer, 'rm_om', 'insert', 'C rm C rm om', 'modify_true');
        Cell(Observer, 'rm_od', 'insert', 'C rm C rm od', 'modify_true');
        Cell(Observer, 'rm_on', 'insert', 'C rm C rm on', 'modify_true');
        Observer.Expect('rm_oi', 'ok');
        Observer.Expect('rm_oi|stored', 'start|5|0|1 buf=1');
        Observer.Expect('rm_om', 'ok');
        Observer.Expect('rm_om|stored', 'start|5|0|1 buf=1');
        Observer.Expect('rm_od', 'ok');
        Observer.Expect('rm_od|stored', 'start|5|0|1 buf=1');
        Observer.Expect('rm_on', 'ok');
        Observer.Expect('rm_on|stored', 'start|5|0|1 buf=1');
        Observer.Verify();
    end;

    // Two Commits, the open transaction modified the row and did one more thing beside it.
    [Test]
    procedure StaleMx_Beside_InsertOnly_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'rm_ki', 'insert', 'C rm C rm ki', 'modify_true');
        Cell(Observer, 'rm_km', 'insert', 'C rm C rm km', 'modify_true');
        Cell(Observer, 'rm_kd', 'insert', 'C rm C rm kd', 'modify_true');
        Cell(Observer, 'rm_kim', 'insert', 'C rm C rm kim', 'modify_true');
        Observer.Expect('rm_ki', 'ok');
        Observer.Expect('rm_ki|stored', 'start|5|0|1 buf=1');
        Observer.Expect('rm_km', 'ok');
        Observer.Expect('rm_km|stored', 'start|5|0|1 buf=1');
        Observer.Expect('rm_kd', 'ok');
        Observer.Expect('rm_kd|stored', 'start|5|0|1 buf=1');
        Observer.Expect('rm_kim', 'ok');
        Observer.Expect('rm_kim|stored', 'start|5|0|1 buf=1');
        Observer.Verify();
    end;

    // Two Commits, the open transaction modified the row and did one more thing beside it.
    [Test]
    procedure StaleMx_Beside_InsertOnly_C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'rm_kda', 'insert', 'C rm C rm kda', 'modify_true');
        Cell(Observer, 'rm_kma', 'insert', 'C rm C rm kma', 'modify_true');
        Observer.Expect('rm_kda', 'ok');
        Observer.Expect('rm_kda|stored', 'start|5|0|1 buf=1');
        Observer.Expect('rm_kma', 'ok');
        Observer.Expect('rm_kma|stored', 'start|5|0|1 buf=1');
        Observer.Verify();
    end;

    // Two Commits, the open transaction modified the row and did one more thing beside it.
    [Test]
    procedure StaleMx_Beside_InsertOnly_D()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'rm_lk', 'insert', 'C rm C rm lk', 'modify_true');
        Cell(Observer, 'rm_kl', 'insert', 'C rm C rm kl', 'modify_true');
        Cell(Observer, 'rm_kr', 'insert', 'C rm C rm kr', 'modify_true');
        Observer.Expect('rm_lk', 'ok');
        Observer.Expect('rm_lk|stored', 'start|5|0|1 buf=1');
        Observer.Expect('rm_kl', 'ok');
        Observer.Expect('rm_kl|stored', 'start|5|0|1 buf=1');
        Observer.Expect('rm_kr', 'ok');
        Observer.Expect('rm_kr|stored', 'start|5|0|1 buf=1');
        Observer.Verify();
    end;

    // The open transaction read the row under LockTable and wrote nothing.
    [Test]
    procedure StaleMx_RowReadUnderLock()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'lg_2c', 'insert_modify', 'C rm C lg', 'modify_true');
        Cell(Observer, 'lg_3c', 'insert_modify', 'C ki C rm C lg', 'modify_true');
        Cell(Observer, 'lf_2c', 'insert_modify', 'C rm C lf', 'modify_true');
        Cell(Observer, 'ins_lg_2c', 'insert', 'C rm C lg', 'modify_true');
        Observer.Expect('lg_2c', 'ok');
        Observer.Expect('lg_2c|stored', 'start|5|1|2 buf=2');
        Observer.Expect('lg_3c', 'ok');
        Observer.Expect('lg_3c|stored', 'start|5|1|2 buf=2');
        Observer.Expect('lf_2c', 'ok');
        Observer.Expect('lf_2c|stored', 'start|5|1|2 buf=2');
        Observer.Expect('ins_lg_2c', 'ok');
        Observer.Expect('ins_lg_2c|stored', 'start|5|0|1 buf=1');
        Observer.Verify();
    end;

    // 1 Commit(s); the open transaction did not touch the row, it wrote other rows of the table or locked the table.
    [Test]
    procedure StaleMx_TableContact_1C_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'om_od', 'insert_modify', 'rm C om od', 'modify_true');
        Cell(Observer, 'om_ki', 'insert_modify', 'rm C om ki', 'modify_true');
        Cell(Observer, 'om_km', 'insert_modify', 'rm C om km', 'modify_true');
        Cell(Observer, 'lk_ki', 'insert_modify', 'rm C lk ki', 'modify_true');
        Observer.Expect('om_od', 'ok');
        Observer.Expect('om_od|stored', 'start|5|1|2 buf=2');
        Observer.Expect('om_ki', 'ok');
        Observer.Expect('om_ki|stored', 'start|5|1|2 buf=2');
        Observer.Expect('om_km', 'ok');
        Observer.Expect('om_km|stored', 'start|5|1|2 buf=2');
        Observer.Expect('lk_ki', 'ok');
        Observer.Expect('lk_ki|stored', 'start|5|1|2 buf=2');
        Observer.Verify();
    end;

    // 1 Commit(s); the open transaction did not touch the row, it wrote other rows of the table or locked the table.
    [Test]
    procedure StaleMx_TableContact_1C_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'lk_om', 'insert_modify', 'rm C lk om', 'modify_true');
        Cell(Observer, 'kl_om', 'insert_modify', 'rm C kl om', 'modify_true');
        Cell(Observer, 'oi_od_on', 'insert_modify', 'rm C oi od on', 'modify_true');
        Cell(Observer, 'oi_kma', 'insert_modify', 'rm C oi kma', 'modify_true');
        Observer.Expect('lk_om', 'ok');
        Observer.Expect('lk_om|stored', 'start|5|1|2 buf=2');
        Observer.Expect('kl_om', 'ok');
        Observer.Expect('kl_om|stored', 'start|5|1|2 buf=2');
        Observer.Expect('oi_od_on', 'ok');
        Observer.Expect('oi_od_on|stored', 'start|5|1|2 buf=2');
        Observer.Expect('oi_kma', 'ok');
        Observer.Expect('oi_kma|stored', 'start|5|1|2 buf=2');
        Observer.Verify();
    end;

    // 2 Commit(s); the open transaction did not touch the row, it wrote other rows of the table or locked the table.
    [Test]
    procedure StaleMx_TableContact_2C_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'om_od', 'insert_modify', 'C rm C om od', 'modify_true');
        Cell(Observer, 'om_ki', 'insert_modify', 'C rm C om ki', 'modify_true');
        Cell(Observer, 'om_km', 'insert_modify', 'C rm C om km', 'modify_true');
        Cell(Observer, 'lk_ki', 'insert_modify', 'C rm C lk ki', 'modify_true');
        Observer.Expect('om_od', 'ok');
        Observer.Expect('om_od|stored', 'start|5|1|2 buf=2');
        Observer.Expect('om_ki', 'ok');
        Observer.Expect('om_ki|stored', 'start|5|1|2 buf=2');
        Observer.Expect('om_km', 'ok');
        Observer.Expect('om_km|stored', 'start|5|1|2 buf=2');
        Observer.Expect('lk_ki', 'ok');
        Observer.Expect('lk_ki|stored', 'start|5|1|2 buf=2');
        Observer.Verify();
    end;

    // 2 Commit(s); the open transaction did not touch the row, it wrote other rows of the table or locked the table.
    [Test]
    procedure StaleMx_TableContact_2C_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'lk_om', 'insert_modify', 'C rm C lk om', 'modify_true');
        Cell(Observer, 'kl_om', 'insert_modify', 'C rm C kl om', 'modify_true');
        Cell(Observer, 'oi_od_on', 'insert_modify', 'C rm C oi od on', 'modify_true');
        Cell(Observer, 'oi_kma', 'insert_modify', 'C rm C oi kma', 'modify_true');
        Observer.Expect('lk_om', 'ok');
        Observer.Expect('lk_om|stored', 'start|5|1|2 buf=2');
        Observer.Expect('kl_om', 'ok');
        Observer.Expect('kl_om|stored', 'start|5|1|2 buf=2');
        Observer.Expect('oi_od_on', 'ok');
        Observer.Expect('oi_od_on|stored', 'start|5|1|2 buf=2');
        Observer.Expect('oi_kma', 'ok');
        Observer.Expect('oi_kma|stored', 'start|5|1|2 buf=2');
        Observer.Verify();
    end;

    // 4 Commit(s); the open transaction did not touch the row, it wrote other rows of the table or locked the table.
    [Test]
    procedure StaleMx_TableContact_4C_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'om_od', 'insert_modify', 'C ki C ki C rm C om od', 'modify_true');
        Cell(Observer, 'om_ki', 'insert_modify', 'C ki C ki C rm C om ki', 'modify_true');
        Cell(Observer, 'om_km', 'insert_modify', 'C ki C ki C rm C om km', 'modify_true');
        Cell(Observer, 'lk_ki', 'insert_modify', 'C ki C ki C rm C lk ki', 'modify_true');
        Observer.Expect('om_od', 'ok');
        Observer.Expect('om_od|stored', 'start|5|1|2 buf=2');
        Observer.Expect('om_ki', 'ok');
        Observer.Expect('om_ki|stored', 'start|5|1|2 buf=2');
        Observer.Expect('om_km', 'ok');
        Observer.Expect('om_km|stored', 'start|5|1|2 buf=2');
        Observer.Expect('lk_ki', 'ok');
        Observer.Expect('lk_ki|stored', 'start|5|1|2 buf=2');
        Observer.Verify();
    end;

    // 4 Commit(s); the open transaction did not touch the row, it wrote other rows of the table or locked the table.
    [Test]
    procedure StaleMx_TableContact_4C_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'lk_om', 'insert_modify', 'C ki C ki C rm C lk om', 'modify_true');
        Cell(Observer, 'kl_om', 'insert_modify', 'C ki C ki C rm C kl om', 'modify_true');
        Cell(Observer, 'oi_od_on', 'insert_modify', 'C ki C ki C rm C oi od on', 'modify_true');
        Cell(Observer, 'oi_kma', 'insert_modify', 'C ki C ki C rm C oi kma', 'modify_true');
        Observer.Expect('lk_om', 'ok');
        Observer.Expect('lk_om|stored', 'start|5|1|2 buf=2');
        Observer.Expect('kl_om', 'ok');
        Observer.Expect('kl_om|stored', 'start|5|1|2 buf=2');
        Observer.Expect('oi_od_on', 'ok');
        Observer.Expect('oi_od_on|stored', 'start|5|1|2 buf=2');
        Observer.Expect('oi_kma', 'ok');
        Observer.Expect('oi_kma|stored', 'start|5|1|2 buf=2');
        Observer.Verify();
    end;

    // 1 Commit(s); the open transaction ran ModifyAll or DeleteAll filtered to other rows of the table.
    // Linux suspect: measured on the Linux CI containers only. record/TestRecordStaleBufferWrite.al notes that a stale Modify after a ModifyAll of
    // the row itself (no Commit) is accepted on the Windows container and refused on the Linux image, so these cells wait for a Windows check.
    [Test]
    procedure StaleMx_BulkSameTable_1C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'oi_oma', 'insert_modify', 'rm C oi oma', 'modify_true');
        Cell(Observer, 'oma', 'insert_modify', 'rm C oma', 'modify_true');
        Cell(Observer, 'oda', 'insert_modify', 'rm C oda', 'modify_true');
        Observer.Expect('oi_oma', 'ok');
        Observer.Expect('oi_oma|stored', 'start|5|1|2 buf=2');
        Observer.Expect('oma', 'ok');
        Observer.Expect('oma|stored', 'start|5|1|2 buf=2');
        Observer.Expect('oda', 'ok');
        Observer.Expect('oda|stored', 'start|5|1|2 buf=2');
        Observer.Verify();
    end;

    // 2 Commit(s); the open transaction ran ModifyAll or DeleteAll filtered to other rows of the table.
    // Linux suspect: measured on the Linux CI containers only. record/TestRecordStaleBufferWrite.al notes that a stale Modify after a ModifyAll of
    // the row itself (no Commit) is accepted on the Windows container and refused on the Linux image, so these cells wait for a Windows check.
    [Test]
    procedure StaleMx_BulkSameTable_2C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'oi_oma', 'insert_modify', 'C rm C oi oma', 'modify_true');
        Cell(Observer, 'oma', 'insert_modify', 'C rm C oma', 'modify_true');
        Cell(Observer, 'oda', 'insert_modify', 'C rm C oda', 'modify_true');
        Observer.Expect('oi_oma', 'ok');
        Observer.Expect('oi_oma|stored', 'start|5|1|2 buf=2');
        Observer.Expect('oma', 'ok');
        Observer.Expect('oma|stored', 'start|5|1|2 buf=2');
        Observer.Expect('oda', 'ok');
        Observer.Expect('oda|stored', 'start|5|1|2 buf=2');
        Observer.Verify();
    end;

    // 1 Commit(s); the open transaction did not write or lock the table of the row.
    [Test]
    procedure StaleMx_NoContact_1C_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'kl_ki', 'insert_modify', 'rm C kl ki', 'modify_true');
        Cell(Observer, 'km', 'insert_modify', 'rm C km', 'modify_true');
        Cell(Observer, 'kd', 'insert_modify', 'rm C kd', 'modify_true');
        Cell(Observer, 'kda', 'insert_modify', 'rm C kda', 'modify_true');
        Observer.Expect('kl_ki', 'error');
        Observer.Expect('kl_ki|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('kl_ki|code', 'DB:RecordChanged');
        Observer.Expect('kl_ki|stored', 'o1|0|1|1 buf=2');
        Observer.Expect('km', 'error');
        Observer.Expect('km|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('km|code', 'DB:RecordChanged');
        Observer.Expect('km|stored', 'o1|0|1|1 buf=2');
        Observer.Expect('kd', 'error');
        Observer.Expect('kd|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('kd|code', 'DB:RecordChanged');
        Observer.Expect('kd|stored', 'o1|0|1|1 buf=2');
        Observer.Expect('kda', 'error');
        Observer.Expect('kda|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('kda|code', 'DB:RecordChanged');
        Observer.Expect('kda|stored', 'o1|0|1|1 buf=2');
        Observer.Verify();
    end;

    // 1 Commit(s); the open transaction did not write or lock the table of the row.
    [Test]
    procedure StaleMx_NoContact_1C_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'kl_km', 'insert_modify', 'rm C kl km', 'modify_true');
        Cell(Observer, 'rg', 'insert_modify', 'rm C rg', 'modify_true');
        Cell(Observer, 'fs', 'insert_modify', 'rm C fs', 'modify_true');
        Cell(Observer, 'nothing', 'insert_modify', 'rm C', 'modify_true');
        Observer.Expect('kl_km', 'error');
        Observer.Expect('kl_km|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('kl_km|code', 'DB:RecordChanged');
        Observer.Expect('kl_km|stored', 'o1|0|1|1 buf=2');
        Observer.Expect('rg', 'error');
        Observer.Expect('rg|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('rg|code', 'DB:RecordChanged');
        Observer.Expect('rg|stored', 'o1|0|1|1 buf=2');
        Observer.Expect('fs', 'error');
        Observer.Expect('fs|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('fs|code', 'DB:RecordChanged');
        Observer.Expect('fs|stored', 'o1|0|1|1 buf=2');
        Observer.Expect('nothing', 'error');
        Observer.Expect('nothing|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('nothing|code', 'DB:RecordChanged');
        Observer.Expect('nothing|stored', 'o1|0|1|1 buf=2');
        Observer.Verify();
    end;

    // 2 Commit(s); the open transaction did not write or lock the table of the row.
    [Test]
    procedure StaleMx_NoContact_2C_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'kl_ki', 'insert_modify', 'C rm C kl ki', 'modify_true');
        Cell(Observer, 'km', 'insert_modify', 'C rm C km', 'modify_true');
        Cell(Observer, 'kd', 'insert_modify', 'C rm C kd', 'modify_true');
        Cell(Observer, 'kda', 'insert_modify', 'C rm C kda', 'modify_true');
        Observer.Expect('kl_ki', 'error');
        Observer.Expect('kl_ki|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('kl_ki|code', 'DB:RecordChanged');
        Observer.Expect('kl_ki|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('km', 'error');
        Observer.Expect('km|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('km|code', 'DB:RecordChanged');
        Observer.Expect('km|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('kd', 'error');
        Observer.Expect('kd|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('kd|code', 'DB:RecordChanged');
        Observer.Expect('kd|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('kda', 'error');
        Observer.Expect('kda|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('kda|code', 'DB:RecordChanged');
        Observer.Expect('kda|stored', 'o2|0|1|1 buf=2');
        Observer.Verify();
    end;

    // 2 Commit(s); the open transaction did not write or lock the table of the row.
    [Test]
    procedure StaleMx_NoContact_2C_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'kl_km', 'insert_modify', 'C rm C kl km', 'modify_true');
        Cell(Observer, 'rg', 'insert_modify', 'C rm C rg', 'modify_true');
        Cell(Observer, 'fs', 'insert_modify', 'C rm C fs', 'modify_true');
        Cell(Observer, 'nothing', 'insert_modify', 'C rm C', 'modify_true');
        Observer.Expect('kl_km', 'error');
        Observer.Expect('kl_km|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('kl_km|code', 'DB:RecordChanged');
        Observer.Expect('kl_km|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('rg', 'error');
        Observer.Expect('rg|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('rg|code', 'DB:RecordChanged');
        Observer.Expect('rg|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('fs', 'error');
        Observer.Expect('fs|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('fs|code', 'DB:RecordChanged');
        Observer.Expect('fs|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('nothing', 'error');
        Observer.Expect('nothing|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('nothing|code', 'DB:RecordChanged');
        Observer.Expect('nothing|stored', 'o2|0|1|1 buf=2');
        Observer.Verify();
    end;

    // 4 Commit(s); the open transaction did not write or lock the table of the row.
    [Test]
    procedure StaleMx_NoContact_4C_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'kl_ki', 'insert_modify', 'C ki C ki C rm C kl ki', 'modify_true');
        Cell(Observer, 'km', 'insert_modify', 'C ki C ki C rm C km', 'modify_true');
        Cell(Observer, 'kd', 'insert_modify', 'C ki C ki C rm C kd', 'modify_true');
        Cell(Observer, 'kda', 'insert_modify', 'C ki C ki C rm C kda', 'modify_true');
        Observer.Expect('kl_ki', 'error');
        Observer.Expect('kl_ki|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('kl_ki|code', 'DB:RecordChanged');
        Observer.Expect('kl_ki|stored', 'o6|0|1|1 buf=2');
        Observer.Expect('km', 'error');
        Observer.Expect('km|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('km|code', 'DB:RecordChanged');
        Observer.Expect('km|stored', 'o6|0|1|1 buf=2');
        Observer.Expect('kd', 'error');
        Observer.Expect('kd|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('kd|code', 'DB:RecordChanged');
        Observer.Expect('kd|stored', 'o6|0|1|1 buf=2');
        Observer.Expect('kda', 'error');
        Observer.Expect('kda|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('kda|code', 'DB:RecordChanged');
        Observer.Expect('kda|stored', 'o6|0|1|1 buf=2');
        Observer.Verify();
    end;

    // 4 Commit(s); the open transaction did not write or lock the table of the row.
    [Test]
    procedure StaleMx_NoContact_4C_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'kl_km', 'insert_modify', 'C ki C ki C rm C kl km', 'modify_true');
        Cell(Observer, 'rg', 'insert_modify', 'C ki C ki C rm C rg', 'modify_true');
        Cell(Observer, 'fs', 'insert_modify', 'C ki C ki C rm C fs', 'modify_true');
        Cell(Observer, 'nothing', 'insert_modify', 'C ki C ki C rm C', 'modify_true');
        Observer.Expect('kl_km', 'error');
        Observer.Expect('kl_km|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('kl_km|code', 'DB:RecordChanged');
        Observer.Expect('kl_km|stored', 'o6|0|1|1 buf=2');
        Observer.Expect('rg', 'error');
        Observer.Expect('rg|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('rg|code', 'DB:RecordChanged');
        Observer.Expect('rg|stored', 'o6|0|1|1 buf=2');
        Observer.Expect('fs', 'error');
        Observer.Expect('fs|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('fs|code', 'DB:RecordChanged');
        Observer.Expect('fs|stored', 'o6|0|1|1 buf=2');
        Observer.Expect('nothing', 'error');
        Observer.Expect('nothing|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('nothing|code', 'DB:RecordChanged');
        Observer.Expect('nothing|stored', 'o6|0|1|1 buf=2');
        Observer.Verify();
    end;

    // Two Commits; the stale write is Modify(false) after row contact, table contact and no contact.
    [Test]
    procedure StaleMx_Final_ModifyFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'rm', 'insert_modify', 'C rm C rm', 'modify_false');
        Cell(Observer, 'om_od', 'insert_modify', 'C rm C om od', 'modify_false');
        Cell(Observer, 'km', 'insert_modify', 'C rm C km', 'modify_false');
        Observer.Expect('rm', 'ok');
        Observer.Expect('rm|stored', 'start|5|1|1 buf=1');
        Observer.Expect('om_od', 'ok');
        Observer.Expect('om_od|stored', 'start|5|1|1 buf=1');
        Observer.Expect('km', 'error');
        Observer.Expect('km|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('km|code', 'DB:RecordChanged');
        Observer.Expect('km|stored', 'o2|0|1|1 buf=1');
        Observer.Verify();
    end;

    // Two Commits; the stale write is Delete(false) after row contact, table contact and no contact.
    [Test]
    procedure StaleMx_Final_DeleteFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'rm', 'insert_modify', 'C rm C rm', 'delete_false');
        Cell(Observer, 'om_od', 'insert_modify', 'C rm C om od', 'delete_false');
        Cell(Observer, 'km', 'insert_modify', 'C rm C km', 'delete_false');
        Observer.Expect('rm', 'ok');
        Observer.Expect('rm|stored', 'none buf=1');
        Observer.Expect('om_od', 'ok');
        Observer.Expect('om_od|stored', 'none buf=1');
        Observer.Expect('km', 'error');
        Observer.Expect('km|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('km|code', 'DB:RecordChanged');
        Observer.Expect('km|stored', 'o2|0|1|1 buf=1');
        Observer.Verify();
    end;

    // The open transaction wrote and was rolled back by asserterror Error before the stale write.
    [Test]
    procedure StaleMx_Rollback()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'rm_rb_1c', 'insert_modify', 'rm C rm rb', 'modify_true');
        Cell(Observer, 'rm_rb_2c', 'insert_modify', 'C rm C rm rb', 'modify_true');
        Cell(Observer, 'om_rb_2c', 'insert_modify', 'C rm C om rb', 'modify_true');
        Cell(Observer, 'rm_rb_rm_2c', 'insert_modify', 'C rm C rm rb rm', 'modify_true');
        Observer.Expect('rm_rb_1c', 'error');
        Observer.Expect('rm_rb_1c|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('rm_rb_1c|code', 'DB:RecordChanged');
        Observer.Expect('rm_rb_1c|stored', 'o1|0|1|1 buf=2');
        Observer.Expect('rm_rb_2c', 'error');
        Observer.Expect('rm_rb_2c|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('rm_rb_2c|code', 'DB:RecordChanged');
        Observer.Expect('rm_rb_2c|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('om_rb_2c', 'error');
        Observer.Expect('om_rb_2c|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('om_rb_2c|code', 'DB:RecordChanged');
        Observer.Expect('om_rb_2c|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('rm_rb_rm_2c', 'ok');
        Observer.Expect('rm_rb_rm_2c|stored', 'start|5|1|2 buf=2');
        Observer.Verify();
    end;

    // The closed write of the row is made inside `if Codeunit.Run` (which commits); one more `if Codeunit.Run` only reads.
    [Test]
    procedure StaleMx_GuardedRun_ClosedWrite()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'g_rm', 'insert_modify', 'C g:rm rm', 'modify_true');
        Cell(Observer, 'g_read_rm', 'insert_modify', 'C g:rm g:rg rm', 'modify_true');
        Cell(Observer, 'g_read', 'insert_modify', 'C g:rm g:rg', 'modify_true');
        Cell(Observer, 'g_read_om', 'insert_modify', 'C g:rm g:rg om', 'modify_true');
        Observer.Expect('g_rm', 'ok');
        Observer.Expect('g_rm|stored', 'start|5|1|2 buf=2');
        Observer.Expect('g_rm|runs', 'Y');
        Observer.Expect('g_read_rm', 'ok');
        Observer.Expect('g_read_rm|stored', 'start|5|1|2 buf=2');
        Observer.Expect('g_read_rm|runs', 'YY');
        Observer.Expect('g_read', 'error');
        Observer.Expect('g_read|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('g_read|code', 'DB:RecordChanged');
        Observer.Expect('g_read|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('g_read|runs', 'YY');
        Observer.Expect('g_read_om', 'ok');
        Observer.Expect('g_read_om|stored', 'start|5|1|2 buf=2');
        Observer.Expect('g_read_om|runs', 'YY');
        Observer.Verify();
    end;

    // Two Commits, then `if Codeunit.Run` after them: it modifies the row, only reads it, or only locks the table.
    [Test]
    procedure StaleMx_GuardedRun_Open()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'g_rm', 'insert_modify', 'C rm C g:rm', 'modify_true');
        Cell(Observer, 'g_rg', 'insert_modify', 'C rm C g:rg', 'modify_true');
        Cell(Observer, 'g_rg_rm', 'insert_modify', 'C rm C g:rg rm', 'modify_true');
        Cell(Observer, 'g_lk', 'insert_modify', 'C rm C g:lk', 'modify_true');
        Observer.Expect('g_rm', 'error');
        Observer.Expect('g_rm|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('g_rm|code', 'DB:RecordChanged');
        Observer.Expect('g_rm|stored', 'o4|0|1|1 buf=2');
        Observer.Expect('g_rm|runs', 'Y');
        Observer.Expect('g_rg', 'error');
        Observer.Expect('g_rg|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('g_rg|code', 'DB:RecordChanged');
        Observer.Expect('g_rg|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('g_rg|runs', 'Y');
        Observer.Expect('g_rg_rm', 'ok');
        Observer.Expect('g_rg_rm|stored', 'start|5|1|2 buf=2');
        Observer.Expect('g_rg_rm|runs', 'Y');
        Observer.Expect('g_lk', 'error');
        Observer.Expect('g_lk|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('g_lk|code', 'DB:RecordChanged');
        Observer.Expect('g_lk|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('g_lk|runs', 'Y');
        Observer.Verify();
    end;

    // Codeunit.Run as a statement (return value not used, no Commit of its own) makes the closed write or the open one.
    [Test]
    procedure StaleMx_RunStatement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'closed_rm', 'insert_modify', 'C r:rm C rm', 'modify_true');
        Cell(Observer, 'closed_only', 'insert_modify', 'C r:rm C', 'modify_true');
        Cell(Observer, 'open_rm', 'insert_modify', 'C rm C r:rm', 'modify_true');
        Cell(Observer, 'open_rg', 'insert_modify', 'C rm C r:rg', 'modify_true');
        Observer.Expect('closed_rm', 'ok');
        Observer.Expect('closed_rm|stored', 'start|5|1|2 buf=2');
        Observer.Expect('closed_rm|runs', 'r');
        Observer.Expect('closed_only', 'error');
        Observer.Expect('closed_only|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('closed_only|code', 'DB:RecordChanged');
        Observer.Expect('closed_only|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('closed_only|runs', 'r');
        Observer.Expect('open_rm', 'ok');
        Observer.Expect('open_rm|stored', 'start|5|1|2 buf=2');
        Observer.Expect('open_rm|runs', 'r');
        Observer.Expect('open_rg', 'error');
        Observer.Expect('open_rg|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('open_rg|code', 'DB:RecordChanged');
        Observer.Expect('open_rg|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('open_rg|runs', 'r');
        Observer.Verify();
    end;

    // Committed-read buffer (Get of a committed row, no own write), 1 Commit(s) after the Get.
    [Test]
    procedure StaleMx_CommittedRead_1C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'nothing', 'get_committed', 'rm C', 'modify_true');
        Cell(Observer, 'rm', 'get_committed', 'rm C rm', 'modify_true');
        Cell(Observer, 'lk', 'get_committed', 'rm C lk', 'modify_true');
        Cell(Observer, 'om', 'get_committed', 'rm C om', 'modify_true');
        Observer.Expect('nothing', 'error');
        Observer.Expect('nothing|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('nothing|code', 'DB:RecordChanged');
        Observer.Expect('nothing|stored', 'o1|0|0|0 buf=1');
        Observer.Expect('rm', 'error');
        Observer.Expect('rm|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('rm|code', 'DB:RecordChanged');
        Observer.Expect('rm|stored', 'o1|0|0|0 buf=1');
        Observer.Expect('lk', 'error');
        Observer.Expect('lk|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('lk|code', 'DB:RecordChanged');
        Observer.Expect('lk|stored', 'o1|0|0|0 buf=1');
        Observer.Expect('om', 'error');
        Observer.Expect('om|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('om|code', 'DB:RecordChanged');
        Observer.Expect('om|stored', 'o1|0|0|0 buf=1');
        Observer.Verify();
    end;

    // Committed-read buffer (Get of a committed row, no own write), 2 Commit(s) after the Get.
    [Test]
    procedure StaleMx_CommittedRead_2C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'nothing', 'get_committed', 'C rm C', 'modify_true');
        Cell(Observer, 'rm', 'get_committed', 'C rm C rm', 'modify_true');
        Cell(Observer, 'lk', 'get_committed', 'C rm C lk', 'modify_true');
        Cell(Observer, 'om', 'get_committed', 'C rm C om', 'modify_true');
        Observer.Expect('nothing', 'error');
        Observer.Expect('nothing|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('nothing|code', 'DB:RecordChanged');
        Observer.Expect('nothing|stored', 'o2|0|0|0 buf=1');
        Observer.Expect('rm', 'error');
        Observer.Expect('rm|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('rm|code', 'DB:RecordChanged');
        Observer.Expect('rm|stored', 'o2|0|0|0 buf=1');
        Observer.Expect('lk', 'error');
        Observer.Expect('lk|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('lk|code', 'DB:RecordChanged');
        Observer.Expect('lk|stored', 'o2|0|0|0 buf=1');
        Observer.Expect('om', 'error');
        Observer.Expect('om|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('om|code', 'DB:RecordChanged');
        Observer.Expect('om|stored', 'o2|0|0|0 buf=1');
        Observer.Verify();
    end;

    // Committed-read buffer: the row read under LockTable, row and table contact together, four Commits.
    [Test]
    procedure StaleMx_CommittedRead_More()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'lg_1c', 'get_committed', 'rm C lg', 'modify_true');
        Cell(Observer, 'lg_2c', 'get_committed', 'C rm C lg', 'modify_true');
        Cell(Observer, 'rm_om_2c', 'get_committed', 'C rm C rm om', 'modify_true');
        Cell(Observer, 'rm_4c', 'get_committed', 'C ki C ki C rm C rm', 'modify_true');
        Observer.Expect('lg_1c', 'error');
        Observer.Expect('lg_1c|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('lg_1c|code', 'DB:RecordChanged');
        Observer.Expect('lg_1c|stored', 'o1|0|0|0 buf=1');
        Observer.Expect('lg_2c', 'error');
        Observer.Expect('lg_2c|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('lg_2c|code', 'DB:RecordChanged');
        Observer.Expect('lg_2c|stored', 'o2|0|0|0 buf=1');
        Observer.Expect('rm_om_2c', 'error');
        Observer.Expect('rm_om_2c|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('rm_om_2c|code', 'DB:RecordChanged');
        Observer.Expect('rm_om_2c|stored', 'o2|0|0|0 buf=1');
        Observer.Expect('rm_4c', 'error');
        Observer.Expect('rm_4c|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('rm_4c|code', 'DB:RecordChanged');
        Observer.Expect('rm_4c|stored', 'o6|0|0|0 buf=1');
        Observer.Verify();
    end;

    // Buffer that read a committed row by Get and then did its own Modify in that transaction, two Commits.
    [Test]
    procedure StaleMx_GetThenOwnModify_2C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'nothing', 'get_committed_modify', 'C rm C', 'modify_true');
        Cell(Observer, 'rm', 'get_committed_modify', 'C rm C rm', 'modify_true');
        Cell(Observer, 'lk', 'get_committed_modify', 'C rm C lk', 'modify_true');
        Cell(Observer, 'om', 'get_committed_modify', 'C rm C om', 'modify_true');
        Observer.Expect('nothing', 'error');
        Observer.Expect('nothing|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('nothing|code', 'DB:RecordChanged');
        Observer.Expect('nothing|stored', 'o2|0|1|1 buf=2');
        Observer.Expect('rm', 'ok');
        Observer.Expect('rm|stored', 'start|5|1|2 buf=2');
        Observer.Expect('lk', 'ok');
        Observer.Expect('lk|stored', 'start|5|1|2 buf=2');
        Observer.Expect('om', 'ok');
        Observer.Expect('om|stored', 'start|5|1|2 buf=2');
        Observer.Verify();
    end;

    // Buffer that read the row by Get in the transaction that inserted it through another variable, two Commits.
    [Test]
    procedure StaleMx_GetUncommitted_2C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'nothing', 'get_uncommitted', 'C rm C', 'modify_true');
        Cell(Observer, 'rm', 'get_uncommitted', 'C rm C rm', 'modify_true');
        Cell(Observer, 'lk', 'get_uncommitted', 'C rm C lk', 'modify_true');
        Cell(Observer, 'om', 'get_uncommitted', 'C rm C om', 'modify_true');
        Observer.Expect('nothing', 'error');
        Observer.Expect('nothing|text', 'The changes to the REC StaleMx Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Entry No.=''6''');
        Observer.Expect('nothing|code', 'DB:RecordChanged');
        Observer.Expect('nothing|stored', 'o2|0|0|0 buf=1');
        Observer.Expect('rm', 'ok');
        Observer.Expect('rm|stored', 'start|5|0|1 buf=1');
        Observer.Expect('lk', 'ok');
        Observer.Expect('lk|stored', 'start|5|0|1 buf=1');
        Observer.Expect('om', 'ok');
        Observer.Expect('om|stored', 'start|5|0|1 buf=1');
        Observer.Verify();
    end;
}
