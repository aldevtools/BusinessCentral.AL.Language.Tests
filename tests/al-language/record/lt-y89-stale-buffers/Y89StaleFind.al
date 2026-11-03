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
    begin
        case Origin of
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
        Observer.Finish();
    end;


    [Test]
    procedure Y89_Part1_find_eq()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'find_eq');
        Observer.Finish();
    end;


    [Test]
    procedure Y89_Part1_find_gt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'find_gt');
        Observer.Finish();
    end;


    [Test]
    procedure Y89_Part1_find_ge()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'find_ge');
        Observer.Finish();
    end;


    [Test]
    procedure Y89_Part1_find_lt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'find_lt');
        Observer.Finish();
    end;


    [Test]
    procedure Y89_Part1_find_le()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'find_le');
        Observer.Finish();
    end;


    [Test]
    procedure Y89_Part1_find_minus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'find_minus');
        Observer.Finish();
    end;


    [Test]
    procedure Y89_Part1_find_plus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'find_plus');
        Observer.Finish();
    end;


    [Test]
    procedure Y89_Part1_next()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'next');
        Observer.Finish();
    end;


    [Test]
    procedure Y89_Part1_next_back_forth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'next_back_forth');
        Observer.Finish();
    end;


    [Test]
    procedure Y89_Part1_findset_next()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'findset_next');
        Observer.Finish();
    end;


    [Test]
    procedure Y89_Part1_descending_next()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Part1Modes(Observer, 'descending_next');
        Observer.Finish();
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

        Observer.Finish();
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

        Observer.Finish();
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

        Observer.Finish();
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

        Observer.Finish();
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

        Observer.Finish();
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

        Observer.Finish();
    end;

}
