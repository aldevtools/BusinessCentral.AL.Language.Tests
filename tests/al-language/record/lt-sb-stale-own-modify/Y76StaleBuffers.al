// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 94078, 94079 (same shape as ALT Universal and ALT Keyed), test table 94078 "LT Y76 SB Row"
// Probe (writer Y76, al-runtime-rs assumptions stale-buffer-other-origin-written and stale-own-insert-two-commits-other-insert).
// Part 1: a buffer made stale by a Commit, whose row version came from a Find, an assignment, Copy or TransferFields (not from a Get or from the
// variable's own Insert), written after the new transaction did nothing, only read the row, modified it (changed or unchanged) or locked it.
// Part 2: a buffer of the variable's own Insert (with and without an own Modify) made stale before two Commits, written after the new transaction
// inserted another row of the table and beside that Insert deleted another row, renamed it, inserted into another table or modified another row.
// BC versions: 27+

table 94078 "LT Y76 SB Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Text Field"; Text[100]) { }
        field(3; "Integer Field"; Integer) { }
        field(4; "Decimal Field"; Decimal) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 94079 "LT Y76 SB Keyed"
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

codeunit 94058 "LT Y76 Stale Buffers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Rows: Record "LT Y76 SB Row";
        Middle: Record "LT Y76 SB Keyed";
    begin
        Rows.DeleteAll();
        Middle.DeleteAll();
        Commit();
    end;

    // A TryFunction may not write to the database, so the write runs in an asserterror statement that raises a marker error after the write; an
    // error of the write itself is what GetLastErrorCode then holds.
    local procedure WriteOutcome(var Row: Record "LT Y76 SB Row"; Deleting: Boolean): Text
    begin
        ClearLastError();
        if Deleting then
            asserterror
            begin
                Row.Delete(false);
                Error('LT_Y76_WRITE_DONE');
            end
        else
            asserterror
            begin
                Row.Modify(false);
                Error('LT_Y76_WRITE_DONE');
            end;
        if GetLastErrorText() = 'LT_Y76_WRITE_DONE' then
            exit('ok');
        exit(GetLastErrorCode());
    end;

    local procedure Stored(): Text
    var
        Row: Record "LT Y76 SB Row";
    begin
        if not Row.Get(5) then
            exit('none');
        exit(Row."Text Field" + '|' + Format(Row."Integer Field"));
    end;

    local procedure MakeBuffer(var Row: Record "LT Y76 SB Row"; Origin: Text)
    var
        Src: Record "LT Y76 SB Row";
        TempCopy: Record "LT Y76 SB Row" temporary;
    begin
        case Origin of
            'get':
                Row.Get(5);
            'find':
                Row.FindFirst();
            'findlast':
                Row.FindLast();
            'findset':
                Row.FindSet();
            'assign':
                begin
                    Src.Get(5);
                    Row := Src;
                end;
            'copy':
                begin
                    Src.Get(5);
                    Row.Copy(Src);
                end;
            'transfer_from_record':
                begin
                    Src.Get(5);
                    Row.TransferFields(Src);
                end;
            'transfer_from_temp':
                begin
                    Src.Get(5);
                    TempCopy.Init();
                    TempCopy.TransferFields(Src);
                    TempCopy.Insert();
                    Row.TransferFields(TempCopy);
                end;
        end;
    end;

    local procedure Between(What: Text)
    var
        Later: Record "LT Y76 SB Row";
    begin
        case What of
            'get':
                Later.Get(5);
            'modify_changed':
                begin
                    Later.Get(5);
                    Later."Text Field" := 'later';
                    Later.Modify(false);
                end;
            'modify_unchanged':
                begin
                    Later.Get(5);
                    Later.Modify(false);
                end;
            'lock':
                begin
                    Later.LockTable();
                    Later.Get(5);
                end;
        end;
    end;

    // Returns "<write outcome> stored=<text>|<integer>". SameTx: the row is inserted by another variable in the transaction the Commit closes,
    // and the buffer is made in that transaction (the row version was written in it); otherwise the row is committed first and the buffer is
    // made in the next transaction.
    local procedure Part1Run(Origin: Text; What: Text; Deleting: Boolean; SameTx: Boolean; Plain: Boolean): Text
    var
        Row: Record "LT Y76 SB Row";
        Inserter: Record "LT Y76 SB Row";
        Other: Record "LT Y76 SB Row";
        Rows: Record "LT Y76 SB Row";
        Outcome: Text;
    begin
        Initialize();
        Inserter.Init();
        Inserter."Entry No." := 5;
        Inserter."Text Field" := 'start';
        Inserter.Insert(false);
        if not SameTx then
            Commit();
        MakeBuffer(Row, Origin);
        Other.Get(5);
        Other."Text Field" := 'other';
        Other.Modify(false);
        Commit();
        Between(What);
        Row."Integer Field" := 5;
        if Plain then begin
            if Deleting then
                Row.Delete(false)
            else
                Row.Modify(false);
            Outcome := 'ok';
        end else
            Outcome := WriteOutcome(Row, Deleting);
        Outcome += ' stored=' + Stored();
        Rows.DeleteAll();
        Commit();
        exit(Outcome);
    end;

    // The write runs once inside an asserterror (which rolls its writes back) to learn whether it is accepted; an accepted write runs again
    // as a plain statement so the stored row can be read.
    local procedure Part1(Origin: Text; What: Text; Deleting: Boolean; SameTx: Boolean): Text
    var
        First: Text;
    begin
        First := Part1Run(Origin, What, Deleting, SameTx, false);
        if First.StartsWith('ok') then
            exit(Part1Run(Origin, What, Deleting, SameTx, true));
        exit(First);
    end;

    local procedure Part1Modes(var Observer: Codeunit "Probe Observer"; Origin: Text)
    begin
        Observer.Observe(Origin + '/nothing', Part1(Origin, 'nothing', false, true));
        Observer.Observe(Origin + '/get', Part1(Origin, 'get', false, true));
        Observer.Observe(Origin + '/modify_changed', Part1(Origin, 'modify_changed', false, true));
        Observer.Observe(Origin + '/modify_unchanged', Part1(Origin, 'modify_unchanged', false, true));
        Observer.Observe(Origin + '/lock', Part1(Origin, 'lock', false, true));
        Observer.Observe(Origin + '/delete_nothing', Part1(Origin, 'nothing', true, true));
        Observer.Observe(Origin + '/delete_modify_changed', Part1(Origin, 'modify_changed', true, true));
        Observer.Observe(Origin + '/committed_nothing', Part1(Origin, 'nothing', false, false));
        Observer.Observe(Origin + '/committed_modify_changed', Part1(Origin, 'modify_changed', false, false));
    end;

    [Test]
    procedure Y76_Part1_Get_Control()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'get');
        Observer.Finish();
    end;

    [Test]
    procedure Y76_Part1_FindFirst_FindLast()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'find');
        Part1Modes(Observer, 'findlast');
        Observer.Finish();
    end;

    [Test]
    procedure Y76_Part1_FindSet_Assign()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'findset');
        Part1Modes(Observer, 'assign');
        Observer.Finish();
    end;

    [Test]
    procedure Y76_Part1_Copy_TransferFromRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'copy');
        Part1Modes(Observer, 'transfer_from_record');
        Observer.Finish();
    end;

    [Test]
    procedure Y76_Part1_TransferFromTemp()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'transfer_from_temp');
        Observer.Finish();
    end;

    // ---- Part 2
    local procedure KeyedInsert(EntryNo: Integer)
    var
        Middle: Record "LT Y76 SB Keyed";
    begin
        Middle.Init();
        Middle."Entry No." := EntryNo;
        Middle.Insert(true);
    end;

    local procedure UniversalInsert(EntryNo: Integer)
    var
        Another: Record "LT Y76 SB Row";
    begin
        Another.Init();
        Another."Entry No." := EntryNo;
        Another."Text Field" := 'another';
        Another.Insert(true);
    end;

    local procedure Part2Run(OwnModify: Boolean; Commits: Integer; Beside: Text; Deleting: Boolean; Plain: Boolean): Text
    var
        Row: Record "LT Y76 SB Row";
        Another: Record "LT Y76 SB Row";
        Other: Record "LT Y76 SB Row";
        Rows: Record "LT Y76 SB Row";
        Keyed: Record "LT Y76 SB Keyed";
        i: Integer;
        Outcome: Text;
        Stored6: Text;
    begin
        Initialize();
        Row.Init();
        Row."Entry No." := 6;
        Row."Text Field" := 'start';
        Row.Insert(true);
        if OwnModify then begin
            Row."Decimal Field" := 1;
            Row.Modify(false);
        end;
        UniversalInsert(8);
        Other.Get(6);
        Other."Text Field" := 'other';
        Other.Modify(false);
        Commit();
        for i := 2 to Commits do begin
            KeyedInsert(i);
            Commit();
        end;
        UniversalInsert(10);
        case Beside of
            'none':
                ;
            'delete':
                begin
                    Another.Get(8);
                    Another.Delete(false);
                end;
            'rename':
                begin
                    Another.Get(8);
                    Another.Rename(9);
                end;
            'othertable':
                KeyedInsert(100);
            'modify_other':
                begin
                    Another.Get(8);
                    Another."Integer Field" := 7;
                    Another.Modify(false);
                end;
            'deleteall_other_table':
                begin
                    Keyed.DeleteAll();
                end;
        end;
        Row."Integer Field" := 5;
        if Plain then begin
            if Deleting then
                Row.Delete(false)
            else
                Row.Modify(false);
            Outcome := 'ok';
        end else
            Outcome := WriteOutcome(Row, Deleting);
        if Other.Get(6) then
            Stored6 := Other."Text Field" + '|' + Format(Other."Integer Field") + '|' + Format(Other."Decimal Field")
        else
            Stored6 := 'none';
        Outcome += ' stored6=' + Stored6;
        Rows.DeleteAll();
        Keyed.DeleteAll();
        Commit();
        exit(Outcome);
    end;

    local procedure Part2(OwnModify: Boolean; Commits: Integer; Beside: Text; Deleting: Boolean): Text
    var
        First: Text;
    begin
        First := Part2Run(OwnModify, Commits, Beside, Deleting, false);
        if First.StartsWith('ok') then
            exit(Part2Run(OwnModify, Commits, Beside, Deleting, true));
        exit(First);
    end;

    [Test]
    procedure Y76_Part2_OwnModify_TwoCommits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('none', Part2(true, 2, 'none', false));
        Observer.Observe('delete', Part2(true, 2, 'delete', false));
        Observer.Observe('rename', Part2(true, 2, 'rename', false));
        Observer.Observe('othertable', Part2(true, 2, 'othertable', false));
        Observer.Observe('modify_other', Part2(true, 2, 'modify_other', false));
        Observer.Observe('del_none', Part2(true, 2, 'none', true));
        Observer.Observe('del_delete', Part2(true, 2, 'delete', true));
        Observer.Observe('del_rename', Part2(true, 2, 'rename', true));
        Observer.Observe('del_othertable', Part2(true, 2, 'othertable', true));
        Observer.Finish();
    end;

    [Test]
    procedure Y76_Part2_OwnInsertOnly_TwoCommits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('none', Part2(false, 2, 'none', false));
        Observer.Observe('delete', Part2(false, 2, 'delete', false));
        Observer.Observe('rename', Part2(false, 2, 'rename', false));
        Observer.Observe('othertable', Part2(false, 2, 'othertable', false));
        Observer.Observe('modify_other', Part2(false, 2, 'modify_other', false));
        Observer.Observe('del_none', Part2(false, 2, 'none', true));
        Observer.Observe('del_delete', Part2(false, 2, 'delete', true));
        Observer.Observe('del_rename', Part2(false, 2, 'rename', true));
        Observer.Observe('del_othertable', Part2(false, 2, 'othertable', true));
        Observer.Finish();
    end;

    [Test]
    procedure Y76_Part2_ThreeCommits_AndOneCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('own_modify_3_delete', Part2(true, 3, 'delete', false));
        Observer.Observe('own_modify_3_rename', Part2(true, 3, 'rename', false));
        Observer.Observe('own_modify_3_othertable', Part2(true, 3, 'othertable', false));
        Observer.Observe('own_insert_3_delete', Part2(false, 3, 'delete', false));
        Observer.Observe('own_insert_3_othertable', Part2(false, 3, 'othertable', false));
        Observer.Observe('own_modify_1_delete', Part2(true, 1, 'delete', false));
        Observer.Observe('own_modify_1_rename', Part2(true, 1, 'rename', false));
        Observer.Observe('own_modify_1_othertable', Part2(true, 1, 'othertable', false));
        Observer.Observe('own_insert_1_delete', Part2(false, 1, 'delete', false));
        Observer.Observe('own_insert_1_rename', Part2(false, 1, 'rename', false));
        Observer.Finish();
    end;
}
