// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables 94078 "LT Y76 SB Row" and 94079 "LT Y76 SB Keyed" of record/lt-sb-stale-own-modify/Y76StaleBuffers.al; test codeunits 94737 - 94739
// Probe (writer Y89, from the runtime lanes rt-values-1103 and rt-values-1103f; extends Y76StaleBuffers.al, same method, nothing of it is changed).
// Part 1: the buffers that Y76 does not make: Find() and Find with every search mode ('=', '>', '>=', '<', '<=', '-', '+'), and a buffer a Next (forward, back, after FindSet) loaded.
// Each is made stale by a Commit after another variable modified the row, then written (Modify, Delete) after nothing, a Get, a changed or unchanged
// Modify or a lock of the row happened in the new transaction.
// Part 2: a buffer of the variable's own Insert, with and without an own Modify, made stale across 3, 4 and 5 Commits, written after the new transaction
// did nothing beside, deleted, renamed or modified another row, inserted into another table or emptied another table.
// BC versions: 27, 28, 29

codeunit 94737 "LT Y89 Stale Find"
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
    begin
        case Origin of
            'transfer_find_eq':
                begin
                    Src."Entry No." := 5;
                    Src.Find('=');
                    Row.TransferFields(Src);
                end;
            'transfer_find_gt':
                begin
                    Src."Entry No." := 4;
                    Src.Find('>');
                    Row.TransferFields(Src);
                end;
            'transfer_find_lt':
                begin
                    Src."Entry No." := 6;
                    Src.Find('<');
                    Row.TransferFields(Src);
                end;
            'transfer_find_minus':
                begin
                    Src.SetRange("Entry No.", 5);
                    Src.Find('-');
                    Row.TransferFields(Src);
                end;
            'transfer_find_plus':
                begin
                    Src.SetRange("Entry No.", 5);
                    Src.Find('+');
                    Row.TransferFields(Src);
                end;
            'transfer_next':
                begin
                    Src.FindFirst();
                    Src.Next();
                    Row.TransferFields(Src);
                end;
            'find_def':
                begin
                    Row."Entry No." := 5;
                    Row.Find();
                end;
            'find_eq':
                begin
                    Row."Entry No." := 5;
                    Row.Find('=');
                end;
            'find_gt':
                begin
                    Row."Entry No." := 4;
                    Row.Find('>');
                end;
            'find_ge':
                begin
                    Row."Entry No." := 5;
                    Row.Find('>=');
                end;
            'find_lt':
                begin
                    Row."Entry No." := 6;
                    Row.Find('<');
                end;
            'find_le':
                begin
                    Row."Entry No." := 5;
                    Row.Find('<=');
                end;
            'find_minus':
                begin
                    Row.SetRange("Entry No.", 5);
                    Row.Find('-');
                end;
            'find_plus':
                begin
                    Row.SetRange("Entry No.", 5);
                    Row.Find('+');
                end;
            'next':
                begin
                    Row.FindFirst();
                    Row.Next();
                end;
            'next_back_forth':
                begin
                    Row.FindFirst();
                    Row.Next();
                    Row.Next(-1);
                    Row.Next(1);
                end;
            'findset_next':
                begin
                    Row.FindSet();
                    Row.Next();
                end;
            'descending_next':
                begin
                    Row.Ascending(false);
                    Row.FindSet();
                    Row.Next();
                    Row.Next(-1);
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
        Inserter."Entry No." := 4;
        Inserter."Text Field" := 'first';
        Inserter.Insert(false);
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
        Outcome += ' at=' + Format(Row."Entry No.") + ' stored=' + Stored();
        Rows.DeleteAll();
        Commit();
        exit(Outcome);
    end;

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
    procedure Y89_Part1_find_def()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'find_def');
        Observer.Expect('find_def/nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_def/get', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_def/modify_changed', 'ok at=5 stored=start|5');
        Observer.Expect('find_def/modify_unchanged', 'ok at=5 stored=start|5');
        Observer.Expect('find_def/lock', 'ok at=5 stored=start|5');
        Observer.Expect('find_def/delete_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_def/delete_modify_changed', 'ok at=5 stored=none');
        Observer.Expect('find_def/committed_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_def/committed_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part1_find_eq()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'find_eq');
        Observer.Expect('find_eq/nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_eq/get', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_eq/modify_changed', 'ok at=5 stored=start|5');
        Observer.Expect('find_eq/modify_unchanged', 'ok at=5 stored=start|5');
        Observer.Expect('find_eq/lock', 'ok at=5 stored=start|5');
        Observer.Expect('find_eq/delete_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_eq/delete_modify_changed', 'ok at=5 stored=none');
        Observer.Expect('find_eq/committed_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_eq/committed_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part1_find_gt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'find_gt');
        Observer.Expect('find_gt/nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_gt/get', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_gt/modify_changed', 'ok at=5 stored=start|5');
        Observer.Expect('find_gt/modify_unchanged', 'ok at=5 stored=start|5');
        Observer.Expect('find_gt/lock', 'ok at=5 stored=start|5');
        Observer.Expect('find_gt/delete_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_gt/delete_modify_changed', 'ok at=5 stored=none');
        Observer.Expect('find_gt/committed_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_gt/committed_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part1_find_ge()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'find_ge');
        Observer.Expect('find_ge/nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_ge/get', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_ge/modify_changed', 'ok at=5 stored=start|5');
        Observer.Expect('find_ge/modify_unchanged', 'ok at=5 stored=start|5');
        Observer.Expect('find_ge/lock', 'ok at=5 stored=start|5');
        Observer.Expect('find_ge/delete_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_ge/delete_modify_changed', 'ok at=5 stored=none');
        Observer.Expect('find_ge/committed_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_ge/committed_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part1_find_lt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'find_lt');
        Observer.Expect('find_lt/nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_lt/get', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_lt/modify_changed', 'ok at=5 stored=start|5');
        Observer.Expect('find_lt/modify_unchanged', 'ok at=5 stored=start|5');
        Observer.Expect('find_lt/lock', 'ok at=5 stored=start|5');
        Observer.Expect('find_lt/delete_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_lt/delete_modify_changed', 'ok at=5 stored=none');
        Observer.Expect('find_lt/committed_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_lt/committed_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part1_find_le()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'find_le');
        Observer.Expect('find_le/nothing', 'ok at=4 stored=other|0');
        Observer.Expect('find_le/get', 'ok at=4 stored=other|0');
        Observer.Expect('find_le/modify_changed', 'ok at=4 stored=later|0');
        Observer.Expect('find_le/modify_unchanged', 'ok at=4 stored=other|0');
        Observer.Expect('find_le/lock', 'ok at=4 stored=other|0');
        Observer.Expect('find_le/delete_nothing', 'ok at=4 stored=other|0');
        Observer.Expect('find_le/delete_modify_changed', 'ok at=4 stored=later|0');
        Observer.Expect('find_le/committed_nothing', 'ok at=4 stored=other|0');
        Observer.Expect('find_le/committed_modify_changed', 'ok at=4 stored=later|0');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part1_find_minus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'find_minus');
        Observer.Expect('find_minus/nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_minus/get', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_minus/modify_changed', 'ok at=5 stored=start|5');
        Observer.Expect('find_minus/modify_unchanged', 'ok at=5 stored=start|5');
        Observer.Expect('find_minus/lock', 'ok at=5 stored=start|5');
        Observer.Expect('find_minus/delete_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_minus/delete_modify_changed', 'ok at=5 stored=none');
        Observer.Expect('find_minus/committed_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_minus/committed_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part1_find_plus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'find_plus');
        Observer.Expect('find_plus/nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_plus/get', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_plus/modify_changed', 'ok at=5 stored=start|5');
        Observer.Expect('find_plus/modify_unchanged', 'ok at=5 stored=start|5');
        Observer.Expect('find_plus/lock', 'ok at=5 stored=start|5');
        Observer.Expect('find_plus/delete_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_plus/delete_modify_changed', 'ok at=5 stored=none');
        Observer.Expect('find_plus/committed_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('find_plus/committed_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part1_next()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'next');
        Observer.Expect('next/nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('next/get', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('next/modify_changed', 'ok at=5 stored=start|5');
        Observer.Expect('next/modify_unchanged', 'ok at=5 stored=start|5');
        Observer.Expect('next/lock', 'ok at=5 stored=start|5');
        Observer.Expect('next/delete_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('next/delete_modify_changed', 'ok at=5 stored=none');
        Observer.Expect('next/committed_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('next/committed_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part1_next_back_forth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'next_back_forth');
        Observer.Expect('next_back_forth/nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('next_back_forth/get', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('next_back_forth/modify_changed', 'ok at=5 stored=start|5');
        Observer.Expect('next_back_forth/modify_unchanged', 'ok at=5 stored=start|5');
        Observer.Expect('next_back_forth/lock', 'ok at=5 stored=start|5');
        Observer.Expect('next_back_forth/delete_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('next_back_forth/delete_modify_changed', 'ok at=5 stored=none');
        Observer.Expect('next_back_forth/committed_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('next_back_forth/committed_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part1_findset_next()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'findset_next');
        Observer.Expect('findset_next/nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('findset_next/get', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('findset_next/modify_changed', 'ok at=5 stored=start|5');
        Observer.Expect('findset_next/modify_unchanged', 'ok at=5 stored=start|5');
        Observer.Expect('findset_next/lock', 'ok at=5 stored=start|5');
        Observer.Expect('findset_next/delete_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('findset_next/delete_modify_changed', 'ok at=5 stored=none');
        Observer.Expect('findset_next/committed_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('findset_next/committed_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part1_descending_next()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'descending_next');
        Observer.Expect('descending_next/nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('descending_next/get', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('descending_next/modify_changed', 'ok at=5 stored=start|5');
        Observer.Expect('descending_next/modify_unchanged', 'ok at=5 stored=start|5');
        Observer.Expect('descending_next/lock', 'ok at=5 stored=start|5');
        Observer.Expect('descending_next/delete_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('descending_next/delete_modify_changed', 'ok at=5 stored=none');
        Observer.Expect('descending_next/committed_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('descending_next/committed_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part1_transfer_find_eq()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'transfer_find_eq');
        Observer.Expect('transfer_find_eq/nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_eq/get', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_eq/modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_eq/modify_unchanged', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_eq/lock', 'ok at=5 stored=start|5');
        Observer.Expect('transfer_find_eq/delete_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_eq/delete_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_eq/committed_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_eq/committed_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part1_transfer_find_gt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'transfer_find_gt');
        Observer.Expect('transfer_find_gt/nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_gt/get', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_gt/modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_gt/modify_unchanged', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_gt/lock', 'ok at=5 stored=start|5');
        Observer.Expect('transfer_find_gt/delete_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_gt/delete_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_gt/committed_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_gt/committed_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part1_transfer_find_lt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'transfer_find_lt');
        Observer.Expect('transfer_find_lt/nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_lt/get', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_lt/modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_lt/modify_unchanged', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_lt/lock', 'ok at=5 stored=start|5');
        Observer.Expect('transfer_find_lt/delete_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_lt/delete_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_lt/committed_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_lt/committed_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part1_transfer_find_minus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'transfer_find_minus');
        Observer.Expect('transfer_find_minus/nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_minus/get', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_minus/modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_minus/modify_unchanged', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_minus/lock', 'ok at=5 stored=start|5');
        Observer.Expect('transfer_find_minus/delete_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_minus/delete_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_minus/committed_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_minus/committed_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part1_transfer_find_plus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'transfer_find_plus');
        Observer.Expect('transfer_find_plus/nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_plus/get', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_plus/modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_plus/modify_unchanged', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_plus/lock', 'ok at=5 stored=start|5');
        Observer.Expect('transfer_find_plus/delete_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_plus/delete_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_plus/committed_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_find_plus/committed_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part1_transfer_next()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'transfer_next');
        Observer.Expect('transfer_next/nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_next/get', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_next/modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_next/modify_unchanged', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_next/lock', 'ok at=5 stored=start|5');
        Observer.Expect('transfer_next/delete_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_next/delete_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_next/committed_nothing', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Expect('transfer_next/committed_modify_changed', 'DB:RecordChanged at=5 stored=other|0');
        Observer.Verify();
    end;

}


codeunit 94738 "LT Y89 Stale Own Insert 3"
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
    procedure Y89_Part2_3Commits_OwnInsertOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('none', Part2(false, 3, 'none', false));

        Observer.Observe('delete', Part2(false, 3, 'delete', false));

        Observer.Observe('rename', Part2(false, 3, 'rename', false));

        Observer.Observe('othertable', Part2(false, 3, 'othertable', false));

        Observer.Observe('modify_other', Part2(false, 3, 'modify_other', false));

        Observer.Observe('deleteall_other_table', Part2(false, 3, 'deleteall_other_table', false));

        Observer.Observe('del_none', Part2(false, 3, 'none', true));

        Observer.Observe('del_delete', Part2(false, 3, 'delete', true));

        Observer.Observe('del_rename', Part2(false, 3, 'rename', true));

        Observer.Observe('del_othertable', Part2(false, 3, 'othertable', true));

        Observer.Expect('none', 'ok stored6=start|5|0');
        Observer.Expect('delete', 'ok stored6=start|5|0');
        Observer.Expect('rename', 'ok stored6=start|5|0');
        Observer.Expect('othertable', 'ok stored6=start|5|0');
        Observer.Expect('modify_other', 'ok stored6=start|5|0');
        Observer.Expect('deleteall_other_table', 'ok stored6=start|5|0');
        Observer.Expect('del_none', 'ok stored6=none');
        Observer.Expect('del_delete', 'ok stored6=none');
        Observer.Expect('del_rename', 'ok stored6=none');
        Observer.Expect('del_othertable', 'ok stored6=none');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part2_3Commits_OwnModify()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('none', Part2(true, 3, 'none', false));

        Observer.Observe('delete', Part2(true, 3, 'delete', false));

        Observer.Observe('rename', Part2(true, 3, 'rename', false));

        Observer.Observe('othertable', Part2(true, 3, 'othertable', false));

        Observer.Observe('modify_other', Part2(true, 3, 'modify_other', false));

        Observer.Observe('deleteall_other_table', Part2(true, 3, 'deleteall_other_table', false));

        Observer.Observe('del_none', Part2(true, 3, 'none', true));

        Observer.Observe('del_delete', Part2(true, 3, 'delete', true));

        Observer.Observe('del_rename', Part2(true, 3, 'rename', true));

        Observer.Observe('del_othertable', Part2(true, 3, 'othertable', true));

        Observer.Expect('none', 'ok stored6=start|5|1');
        Observer.Expect('delete', 'ok stored6=start|5|1');
        Observer.Expect('rename', 'ok stored6=start|5|1');
        Observer.Expect('othertable', 'ok stored6=start|5|1');
        Observer.Expect('modify_other', 'ok stored6=start|5|1');
        Observer.Expect('deleteall_other_table', 'ok stored6=start|5|1');
        Observer.Expect('del_none', 'ok stored6=none');
        Observer.Expect('del_delete', 'ok stored6=none');
        Observer.Expect('del_rename', 'ok stored6=none');
        Observer.Expect('del_othertable', 'ok stored6=none');
        Observer.Verify();
    end;

}


codeunit 94739 "LT Y89 Stale Own Insert 45"
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
    procedure Y89_Part2_4Commits_OwnInsertOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('none', Part2(false, 4, 'none', false));

        Observer.Observe('delete', Part2(false, 4, 'delete', false));

        Observer.Observe('rename', Part2(false, 4, 'rename', false));

        Observer.Observe('othertable', Part2(false, 4, 'othertable', false));

        Observer.Observe('modify_other', Part2(false, 4, 'modify_other', false));

        Observer.Observe('deleteall_other_table', Part2(false, 4, 'deleteall_other_table', false));

        Observer.Observe('del_none', Part2(false, 4, 'none', true));

        Observer.Observe('del_delete', Part2(false, 4, 'delete', true));

        Observer.Observe('del_rename', Part2(false, 4, 'rename', true));

        Observer.Observe('del_othertable', Part2(false, 4, 'othertable', true));

        Observer.Expect('none', 'ok stored6=start|5|0');
        Observer.Expect('delete', 'ok stored6=start|5|0');
        Observer.Expect('rename', 'ok stored6=start|5|0');
        Observer.Expect('othertable', 'ok stored6=start|5|0');
        Observer.Expect('modify_other', 'ok stored6=start|5|0');
        Observer.Expect('deleteall_other_table', 'ok stored6=start|5|0');
        Observer.Expect('del_none', 'ok stored6=none');
        Observer.Expect('del_delete', 'ok stored6=none');
        Observer.Expect('del_rename', 'ok stored6=none');
        Observer.Expect('del_othertable', 'ok stored6=none');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part2_4Commits_OwnModify()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('none', Part2(true, 4, 'none', false));

        Observer.Observe('delete', Part2(true, 4, 'delete', false));

        Observer.Observe('rename', Part2(true, 4, 'rename', false));

        Observer.Observe('othertable', Part2(true, 4, 'othertable', false));

        Observer.Observe('modify_other', Part2(true, 4, 'modify_other', false));

        Observer.Observe('deleteall_other_table', Part2(true, 4, 'deleteall_other_table', false));

        Observer.Observe('del_none', Part2(true, 4, 'none', true));

        Observer.Observe('del_delete', Part2(true, 4, 'delete', true));

        Observer.Observe('del_rename', Part2(true, 4, 'rename', true));

        Observer.Observe('del_othertable', Part2(true, 4, 'othertable', true));

        Observer.Expect('none', 'ok stored6=start|5|1');
        Observer.Expect('delete', 'ok stored6=start|5|1');
        Observer.Expect('rename', 'ok stored6=start|5|1');
        Observer.Expect('othertable', 'ok stored6=start|5|1');
        Observer.Expect('modify_other', 'ok stored6=start|5|1');
        Observer.Expect('deleteall_other_table', 'ok stored6=start|5|1');
        Observer.Expect('del_none', 'ok stored6=none');
        Observer.Expect('del_delete', 'ok stored6=none');
        Observer.Expect('del_rename', 'ok stored6=none');
        Observer.Expect('del_othertable', 'ok stored6=none');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part2_5Commits_OwnInsertOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('none', Part2(false, 5, 'none', false));

        Observer.Observe('delete', Part2(false, 5, 'delete', false));

        Observer.Observe('rename', Part2(false, 5, 'rename', false));

        Observer.Observe('othertable', Part2(false, 5, 'othertable', false));

        Observer.Observe('modify_other', Part2(false, 5, 'modify_other', false));

        Observer.Observe('deleteall_other_table', Part2(false, 5, 'deleteall_other_table', false));

        Observer.Observe('del_none', Part2(false, 5, 'none', true));

        Observer.Observe('del_delete', Part2(false, 5, 'delete', true));

        Observer.Observe('del_rename', Part2(false, 5, 'rename', true));

        Observer.Observe('del_othertable', Part2(false, 5, 'othertable', true));

        Observer.Expect('none', 'ok stored6=start|5|0');
        Observer.Expect('delete', 'ok stored6=start|5|0');
        Observer.Expect('rename', 'ok stored6=start|5|0');
        Observer.Expect('othertable', 'ok stored6=start|5|0');
        Observer.Expect('modify_other', 'ok stored6=start|5|0');
        Observer.Expect('deleteall_other_table', 'ok stored6=start|5|0');
        Observer.Expect('del_none', 'ok stored6=none');
        Observer.Expect('del_delete', 'ok stored6=none');
        Observer.Expect('del_rename', 'ok stored6=none');
        Observer.Expect('del_othertable', 'ok stored6=none');
        Observer.Verify();
    end;


    [Test]
    procedure Y89_Part2_5Commits_OwnModify()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('none', Part2(true, 5, 'none', false));

        Observer.Observe('delete', Part2(true, 5, 'delete', false));

        Observer.Observe('rename', Part2(true, 5, 'rename', false));

        Observer.Observe('othertable', Part2(true, 5, 'othertable', false));

        Observer.Observe('modify_other', Part2(true, 5, 'modify_other', false));

        Observer.Observe('deleteall_other_table', Part2(true, 5, 'deleteall_other_table', false));

        Observer.Observe('del_none', Part2(true, 5, 'none', true));

        Observer.Observe('del_delete', Part2(true, 5, 'delete', true));

        Observer.Observe('del_rename', Part2(true, 5, 'rename', true));

        Observer.Observe('del_othertable', Part2(true, 5, 'othertable', true));

        Observer.Expect('none', 'ok stored6=start|5|1');
        Observer.Expect('delete', 'ok stored6=start|5|1');
        Observer.Expect('rename', 'ok stored6=start|5|1');
        Observer.Expect('othertable', 'ok stored6=start|5|1');
        Observer.Expect('modify_other', 'ok stored6=start|5|1');
        Observer.Expect('deleteall_other_table', 'ok stored6=start|5|1');
        Observer.Expect('del_none', 'ok stored6=none');
        Observer.Expect('del_delete', 'ok stored6=none');
        Observer.Expect('del_rename', 'ok stored6=none');
        Observer.Expect('del_othertable', 'ok stored6=none');
        Observer.Verify();
    end;

}
