// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-minimumactiverowversion-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 67516, codeunit 67515
// Probe: Database.MinimumActiveRowVersion against LastUsedRowVersion() + 1 with no write, inside an open write transaction and after Commit (issue 580 item 8). The existing PlTDatabase.al checks only that it is not below zero and not above LastUsedRowVersion() + 1.
// Writer TV (2026-10-29, TV_* tests): MinimumActiveRowVersion against its start value, LastUsedRowVersion and the row's SystemRowVersion across Insert, Modify and Commit.
// BC versions: 27+

table 67516 "LT RV Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Writer UK (2026-10-29): two own tables for the LastUsedRowVersion / MinimumActiveRowVersion shape probes in codeunit 67515 (UK_* tests).
table 90410 "LT UK Row A"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 90411 "LT UK Row B"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67515 "LT RV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Snapshot(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Min: BigInteger;
        Last: BigInteger;
    begin
        Min := MinimumActiveRowVersion();
        Last := LastUsedRowVersion();
        Observer.Observe(Name + '_min_minus_last', Format(Min - Last));
        Observer.Observe(Name + '_equals_last_plus_one', Format(Min = Last + 1));
        Observer.Observe(Name + '_min_positive', Format(Min > 0));
    end;

    [Test]
    procedure MinimumActiveRowVersion_NoWrite_Committed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Commit();
        Snapshot(Observer, 'after_commit_no_write');
        Snapshot(Observer, 'again');
        Observer.Observe('in_write_transaction', Format(IsInWriteTransaction()));
        Observer.Expect('after_commit_no_write_min_minus_last', '1');
        Observer.Expect('after_commit_no_write_equals_last_plus_one', 'Yes');
        Observer.Expect('after_commit_no_write_min_positive', 'Yes');
        Observer.Expect('again_min_minus_last', '1');
        Observer.Expect('again_equals_last_plus_one', 'Yes');
        Observer.Expect('again_min_positive', 'Yes');
        Observer.Expect('in_write_transaction', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure MinimumActiveRowVersion_InsideOpenWriteTransaction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RV Row";
        Before: BigInteger;
    begin
        Row.DeleteAll();
        Commit();
        Before := MinimumActiveRowVersion();
        Row.Id := 1;
        Row.Insert();
        Observer.Observe('in_write_transaction', Format(IsInWriteTransaction()));
        Snapshot(Observer, 'after_insert');
        Observer.Observe('min_unchanged_by_open_insert', Format(MinimumActiveRowVersion() = Before));
        Row.Id := 2;
        Row.Insert();
        Snapshot(Observer, 'after_second_insert');
        Row.Name := 'x';
        Row.Modify();
        Observer.Observe('after_modify_not_above_last_plus_one', Format(MinimumActiveRowVersion() <= LastUsedRowVersion() + 1));
        Observer.Expect('in_write_transaction', 'Yes');
        Observer.Expect('after_insert_min_minus_last', '1');
        Observer.Expect('after_insert_equals_last_plus_one', 'Yes');
        Observer.Expect('after_insert_min_positive', 'Yes');
        Observer.Expect('min_unchanged_by_open_insert', 'Yes');
        Observer.Expect('after_second_insert_min_minus_last', '1');
        Observer.Expect('after_second_insert_equals_last_plus_one', 'Yes');
        Observer.Expect('after_second_insert_min_positive', 'Yes');
        Observer.Expect('after_modify_not_above_last_plus_one', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MinimumActiveRowVersion_AfterCommit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RV Row";
        Before: BigInteger;
    begin
        Row.DeleteAll();
        Commit();
        Before := MinimumActiveRowVersion();
        Observer.Observe('before_positive', Format(Before > 0));
        Row.Id := 1;
        Row.Insert();
        Commit();
        Observer.Observe('in_write_transaction', Format(IsInWriteTransaction()));
        Observer.Observe('after_commit_not_above_last_plus_one', Format(MinimumActiveRowVersion() <= LastUsedRowVersion() + 1));
        Observer.Observe('after_commit_below_last_plus_one', Format(MinimumActiveRowVersion() < LastUsedRowVersion() + 1));
        Observer.Observe('after_commit_positive', Format(MinimumActiveRowVersion() > 0));
        Row.DeleteAll();
        Commit();
        Observer.Expect('before_positive', 'Yes');
        Observer.Expect('in_write_transaction', 'No');
        Observer.Expect('after_commit_not_above_last_plus_one', 'Yes');
        Observer.Expect('after_commit_below_last_plus_one', 'Yes');
        Observer.Expect('after_commit_positive', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MinimumActiveRowVersion_PrefixedCallEqualsBareCall()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Commit();
        Observer.Observe('prefixed_equals_bare', Format(Database.MinimumActiveRowVersion() = MinimumActiveRowVersion()));
        Observer.Observe('last_prefixed_equals_bare', Format(Database.LastUsedRowVersion() = LastUsedRowVersion()));
        Observer.Expect('prefixed_equals_bare', 'Yes');
        Observer.Expect('last_prefixed_equals_bare', 'Yes');
        Observer.Verify();
    end;

    // ---- Writer TV (NP lane, 2026-10-29): MinimumActiveRowVersion against the value read before the writes (Start), LastUsedRowVersion and the
    // SystemRowVersion of the written row: inside the write transaction, after the Commit that made the insert durable, after a Modify and its
    // Commit, and after a Commit with no write following a committed write. ----

    local procedure TvState(var Observer: Codeunit "Probe Observer"; Name: Text; Start: BigInteger; StartLast: BigInteger; RowVersion: BigInteger)
    var
        Min: BigInteger;
        Last: BigInteger;
    begin
        Min := MinimumActiveRowVersion();
        Last := LastUsedRowVersion();
        Observer.Observe(Name + ' min = start', Format(Min = Start));
        Observer.Observe(Name + ' min > start', Format(Min > Start));
        Observer.Observe(Name + ' last > start last', Format(Last > StartLast));
        if RowVersion <> 0 then begin
            Observer.Observe(Name + ' row version < min', Format(RowVersion < Min));
            Observer.Observe(Name + ' row version <= last', Format(RowVersion <= Last));
            Observer.Observe(Name + ' row version >= start', Format(RowVersion >= Start));
        end;
        Observer.Observe(Name + ' in write transaction', Format(IsInWriteTransaction()));
    end;

    [Test]
    procedure TV_MinimumActiveRowVersion_AcrossInsertModifyCommit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RV Row";
        Start: BigInteger;
        StartLast: BigInteger;
    begin
        Row.DeleteAll();
        Commit();
        Start := MinimumActiveRowVersion();
        StartLast := LastUsedRowVersion();
        Row.Id := 1;
        Row.Insert();
        Row.Get(1);
        TvState(Observer, 'insert open', Start, StartLast, Row.SystemRowVersion);
        Commit();
        TvState(Observer, 'insert committed', Start, StartLast, Row.SystemRowVersion);
        Row.Name := 'x';
        Row.Modify();
        Row.Get(1);
        TvState(Observer, 'modify open', Start, StartLast, Row.SystemRowVersion);
        Commit();
        TvState(Observer, 'modify committed', Start, StartLast, Row.SystemRowVersion);
        Commit();
        TvState(Observer, 'second commit', Start, StartLast, Row.SystemRowVersion);
        Row.DeleteAll();
        Commit();
        Observer.Expect('insert open min = start', 'Yes');
        Observer.Expect('insert open min > start', 'No');
        Observer.Expect('insert open last > start last', 'Yes');
        Observer.Expect('insert open row version < min', 'No');
        Observer.Expect('insert open row version <= last', 'Yes');
        Observer.Expect('insert open row version >= start', 'Yes');
        Observer.Expect('insert open in write transaction', 'Yes');
        Observer.Expect('insert committed min = start', 'Yes');
        Observer.Expect('insert committed min > start', 'No');
        Observer.Expect('insert committed last > start last', 'Yes');
        Observer.Expect('insert committed row version < min', 'No');
        Observer.Expect('insert committed row version <= last', 'Yes');
        Observer.Expect('insert committed row version >= start', 'Yes');
        Observer.Expect('insert committed in write transaction', 'No');
        Observer.Expect('modify open min = start', 'Yes');
        Observer.Expect('modify open min > start', 'No');
        Observer.Expect('modify open last > start last', 'Yes');
        Observer.Expect('modify open row version < min', 'No');
        Observer.Expect('modify open row version <= last', 'Yes');
        Observer.Expect('modify open row version >= start', 'Yes');
        Observer.Expect('modify open in write transaction', 'Yes');
        Observer.Expect('modify committed min = start', 'Yes');
        Observer.Expect('modify committed min > start', 'No');
        Observer.Expect('modify committed last > start last', 'Yes');
        Observer.Expect('modify committed row version < min', 'No');
        Observer.Expect('modify committed row version <= last', 'Yes');
        Observer.Expect('modify committed row version >= start', 'Yes');
        Observer.Expect('modify committed in write transaction', 'No');
        Observer.Expect('second commit min = start', 'Yes');
        Observer.Expect('second commit min > start', 'No');
        Observer.Expect('second commit last > start last', 'Yes');
        Observer.Expect('second commit row version < min', 'No');
        Observer.Expect('second commit row version <= last', 'Yes');
        Observer.Expect('second commit row version >= start', 'Yes');
        Observer.Expect('second commit in write transaction', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TV_MinimumActiveRowVersion_ReadOnlyAfterCommittedWrite()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RV Row";
        Start: BigInteger;
        StartLast: BigInteger;
        AfterCommit: BigInteger;
    begin
        Row.DeleteAll();
        Commit();
        Start := MinimumActiveRowVersion();
        StartLast := LastUsedRowVersion();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Commit();
        AfterCommit := MinimumActiveRowVersion();
        Row.FindFirst();
        Observer.Observe('read keeps min', Format(MinimumActiveRowVersion() = AfterCommit));
        Observer.Observe('stable', Format(MinimumActiveRowVersion() = MinimumActiveRowVersion()));
        Observer.Observe('min after commit = start', Format(AfterCommit = Start));
        Observer.Observe('rows below min', Format(Row.SystemRowVersion < AfterCommit));
        Row.FindLast();
        Observer.Observe('last row below min', Format(Row.SystemRowVersion < AfterCommit));
        Row.DeleteAll();
        Commit();
        Observer.Expect('read keeps min', 'Yes');
        Observer.Expect('stable', 'Yes');
        Observer.Expect('min after commit = start', 'Yes');
        Observer.Expect('rows below min', 'No');
        Observer.Expect('last row below min', 'No');
        Observer.Verify();
    end;

    // ---- Writer UK (NP lane, 2026-10-29): LastUsedRowVersion and MinimumActiveRowVersion after an Insert followed by each kind of read or write,
    // inside the open write transaction and after Commit. Only relations to the previous value are asserted, never absolute values. ----

    local procedure UkStart(var Last0: BigInteger; var Min0: BigInteger)
    var
        A: Record "LT UK Row A";
        B: Record "LT UK Row B";
    begin
        A.DeleteAll();
        B.DeleteAll();
        Commit();
        B.Id := 1;
        B.Insert();
        Commit();
        Last0 := LastUsedRowVersion();
        Min0 := MinimumActiveRowVersion();
    end;

    local procedure UkSnap(var Observer: Codeunit "Probe Observer"; Name: Text; var PrevLast: BigInteger; var PrevMin: BigInteger; Last0: BigInteger; Min0: BigInteger)
    var
        Last: BigInteger;
        Min: BigInteger;
    begin
        Last := LastUsedRowVersion();
        Min := MinimumActiveRowVersion();
        Observer.Observe(Name + ' last = prev', Format(Last = PrevLast));
        Observer.Observe(Name + ' last > prev', Format(Last > PrevLast));
        Observer.Observe(Name + ' min = prev', Format(Min = PrevMin));
        Observer.Observe(Name + ' min = start', Format(Min = Min0));
        Observer.Observe(Name + ' in write transaction', Format(IsInWriteTransaction()));
        PrevLast := Last;
        PrevMin := Min;
    end;

    [Test]
    procedure UK_InsertThenFindSet()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT UK Row A";
        Last0: BigInteger;
        Min0: BigInteger;
        PrevLast: BigInteger;
        PrevMin: BigInteger;
    begin
        UkStart(Last0, Min0);
        PrevLast := Last0;
        PrevMin := Min0;
        A.Id := 1;
        A.Insert();
        UkSnap(Observer, 'insert', PrevLast, PrevMin, Last0, Min0);
        A.FindSet();
        UkSnap(Observer, 'findset', PrevLast, PrevMin, Last0, Min0);
        Commit();
        UkSnap(Observer, 'commit', PrevLast, PrevMin, Last0, Min0);
        A.DeleteAll();
        Commit();
        Observer.Finish();
    end;

    [Test]
    procedure UK_InsertThenFindFirst()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT UK Row A";
        Last0: BigInteger;
        Min0: BigInteger;
        PrevLast: BigInteger;
        PrevMin: BigInteger;
    begin
        UkStart(Last0, Min0);
        PrevLast := Last0;
        PrevMin := Min0;
        A.Id := 1;
        A.Insert();
        UkSnap(Observer, 'insert', PrevLast, PrevMin, Last0, Min0);
        A.FindFirst();
        UkSnap(Observer, 'findfirst', PrevLast, PrevMin, Last0, Min0);
        Commit();
        UkSnap(Observer, 'commit', PrevLast, PrevMin, Last0, Min0);
        A.DeleteAll();
        Commit();
        Observer.Finish();
    end;

    [Test]
    procedure UK_InsertThenIsEmpty()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT UK Row A";
        Last0: BigInteger;
        Min0: BigInteger;
        PrevLast: BigInteger;
        PrevMin: BigInteger;
    begin
        UkStart(Last0, Min0);
        PrevLast := Last0;
        PrevMin := Min0;
        A.Id := 1;
        A.Insert();
        UkSnap(Observer, 'insert', PrevLast, PrevMin, Last0, Min0);
        Observer.Observe('is empty', Format(A.IsEmpty()));
        UkSnap(Observer, 'isempty', PrevLast, PrevMin, Last0, Min0);
        Commit();
        UkSnap(Observer, 'commit', PrevLast, PrevMin, Last0, Min0);
        A.DeleteAll();
        Commit();
        Observer.Finish();
    end;

    [Test]
    procedure UK_InsertThenCount()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT UK Row A";
        Last0: BigInteger;
        Min0: BigInteger;
        PrevLast: BigInteger;
        PrevMin: BigInteger;
    begin
        UkStart(Last0, Min0);
        PrevLast := Last0;
        PrevMin := Min0;
        A.Id := 1;
        A.Insert();
        UkSnap(Observer, 'insert', PrevLast, PrevMin, Last0, Min0);
        Observer.Observe('count', Format(A.Count()));
        UkSnap(Observer, 'count', PrevLast, PrevMin, Last0, Min0);
        Commit();
        UkSnap(Observer, 'commit', PrevLast, PrevMin, Last0, Min0);
        A.DeleteAll();
        Commit();
        Observer.Finish();
    end;

    [Test]
    procedure UK_InsertThenCalcSums()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT UK Row A";
        Last0: BigInteger;
        Min0: BigInteger;
        PrevLast: BigInteger;
        PrevMin: BigInteger;
    begin
        UkStart(Last0, Min0);
        PrevLast := Last0;
        PrevMin := Min0;
        A.Id := 1;
        A.Amount := 5;
        A.Insert();
        UkSnap(Observer, 'insert', PrevLast, PrevMin, Last0, Min0);
        A.CalcSums(Amount);
        Observer.Observe('sum', Format(A.Amount));
        UkSnap(Observer, 'calcsums', PrevLast, PrevMin, Last0, Min0);
        Commit();
        UkSnap(Observer, 'commit', PrevLast, PrevMin, Last0, Min0);
        A.DeleteAll();
        Commit();
        Observer.Finish();
    end;

    [Test]
    procedure UK_InsertThenGetAndModify()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT UK Row A";
        Last0: BigInteger;
        Min0: BigInteger;
        PrevLast: BigInteger;
        PrevMin: BigInteger;
    begin
        UkStart(Last0, Min0);
        PrevLast := Last0;
        PrevMin := Min0;
        A.Id := 1;
        A.Insert();
        UkSnap(Observer, 'insert', PrevLast, PrevMin, Last0, Min0);
        A.Get(1);
        UkSnap(Observer, 'get', PrevLast, PrevMin, Last0, Min0);
        A.Amount := 1;
        A.Modify();
        UkSnap(Observer, 'modify', PrevLast, PrevMin, Last0, Min0);
        A.Get(1);
        UkSnap(Observer, 'get after modify', PrevLast, PrevMin, Last0, Min0);
        Commit();
        UkSnap(Observer, 'commit', PrevLast, PrevMin, Last0, Min0);
        A.DeleteAll();
        Commit();
        Observer.Finish();
    end;

    [Test]
    procedure UK_InsertThenReadOtherTable()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT UK Row A";
        B: Record "LT UK Row B";
        Last0: BigInteger;
        Min0: BigInteger;
        PrevLast: BigInteger;
        PrevMin: BigInteger;
    begin
        UkStart(Last0, Min0);
        PrevLast := Last0;
        PrevMin := Min0;
        A.Id := 1;
        A.Insert();
        UkSnap(Observer, 'insert', PrevLast, PrevMin, Last0, Min0);
        B.FindFirst();
        UkSnap(Observer, 'findfirst other', PrevLast, PrevMin, Last0, Min0);
        B.Get(1);
        UkSnap(Observer, 'get other', PrevLast, PrevMin, Last0, Min0);
        Commit();
        UkSnap(Observer, 'commit', PrevLast, PrevMin, Last0, Min0);
        A.DeleteAll();
        Commit();
        Observer.Finish();
    end;

    [Test]
    procedure UK_InsertThenModifyOtherTable()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT UK Row A";
        B: Record "LT UK Row B";
        Last0: BigInteger;
        Min0: BigInteger;
        PrevLast: BigInteger;
        PrevMin: BigInteger;
    begin
        UkStart(Last0, Min0);
        PrevLast := Last0;
        PrevMin := Min0;
        A.Id := 1;
        A.Insert();
        UkSnap(Observer, 'insert', PrevLast, PrevMin, Last0, Min0);
        B.Get(1);
        B.Amount := 7;
        B.Modify();
        UkSnap(Observer, 'modify other', PrevLast, PrevMin, Last0, Min0);
        A.FindFirst();
        UkSnap(Observer, 'findfirst', PrevLast, PrevMin, Last0, Min0);
        Commit();
        UkSnap(Observer, 'commit', PrevLast, PrevMin, Last0, Min0);
        A.DeleteAll();
        Commit();
        Observer.Finish();
    end;

    [Test]
    procedure UK_InsertTwoTablesThenGetOne()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT UK Row A";
        B: Record "LT UK Row B";
        Last0: BigInteger;
        Min0: BigInteger;
        PrevLast: BigInteger;
        PrevMin: BigInteger;
    begin
        UkStart(Last0, Min0);
        PrevLast := Last0;
        PrevMin := Min0;
        A.Id := 1;
        A.Insert();
        B.Id := 2;
        B.Insert();
        UkSnap(Observer, 'insert both', PrevLast, PrevMin, Last0, Min0);
        A.Get(1);
        UkSnap(Observer, 'get a', PrevLast, PrevMin, Last0, Min0);
        B.Get(2);
        UkSnap(Observer, 'get b', PrevLast, PrevMin, Last0, Min0);
        Commit();
        UkSnap(Observer, 'commit', PrevLast, PrevMin, Last0, Min0);
        A.DeleteAll();
        B.Get(2);
        B.Delete();
        Commit();
        Observer.Finish();
    end;

    [Test]
    procedure UK_DeleteWithoutInsert()
    var
        Observer: Codeunit "Probe Observer";
        B: Record "LT UK Row B";
        Last0: BigInteger;
        Min0: BigInteger;
        PrevLast: BigInteger;
        PrevMin: BigInteger;
    begin
        UkStart(Last0, Min0);
        PrevLast := Last0;
        PrevMin := Min0;
        B.Get(1);
        B.Delete();
        UkSnap(Observer, 'delete', PrevLast, PrevMin, Last0, Min0);
        Observer.Observe('is empty', Format(B.IsEmpty()));
        UkSnap(Observer, 'isempty', PrevLast, PrevMin, Last0, Min0);
        Commit();
        UkSnap(Observer, 'commit', PrevLast, PrevMin, Last0, Min0);
        Observer.Finish();
    end;

    [Test]
    procedure UK_DeleteAllWithoutInsert()
    var
        Observer: Codeunit "Probe Observer";
        B: Record "LT UK Row B";
        Last0: BigInteger;
        Min0: BigInteger;
        PrevLast: BigInteger;
        PrevMin: BigInteger;
    begin
        UkStart(Last0, Min0);
        PrevLast := Last0;
        PrevMin := Min0;
        B.DeleteAll();
        UkSnap(Observer, 'deleteall', PrevLast, PrevMin, Last0, Min0);
        Observer.Observe('count', Format(B.Count()));
        UkSnap(Observer, 'count', PrevLast, PrevMin, Last0, Min0);
        Commit();
        UkSnap(Observer, 'commit', PrevLast, PrevMin, Last0, Min0);
        Observer.Finish();
    end;

    [Test]
    procedure UK_InsertReadInsertRead()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT UK Row A";
        Last0: BigInteger;
        Min0: BigInteger;
        PrevLast: BigInteger;
        PrevMin: BigInteger;
    begin
        UkStart(Last0, Min0);
        PrevLast := Last0;
        PrevMin := Min0;
        A.Id := 1;
        A.Insert();
        UkSnap(Observer, 'insert', PrevLast, PrevMin, Last0, Min0);
        A.FindFirst();
        UkSnap(Observer, 'read', PrevLast, PrevMin, Last0, Min0);
        A.FindFirst();
        UkSnap(Observer, 'read again', PrevLast, PrevMin, Last0, Min0);
        A.Id := 2;
        A.Insert();
        UkSnap(Observer, 'second insert', PrevLast, PrevMin, Last0, Min0);
        A.FindLast();
        UkSnap(Observer, 'read after second insert', PrevLast, PrevMin, Last0, Min0);
        Commit();
        UkSnap(Observer, 'commit', PrevLast, PrevMin, Last0, Min0);
        A.DeleteAll();
        Commit();
        Observer.Finish();
    end;

    [Test]
    procedure UK_InsertThenReadOtherThenSame()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT UK Row A";
        B: Record "LT UK Row B";
        Last0: BigInteger;
        Min0: BigInteger;
        PrevLast: BigInteger;
        PrevMin: BigInteger;
    begin
        UkStart(Last0, Min0);
        PrevLast := Last0;
        PrevMin := Min0;
        A.Id := 1;
        A.Insert();
        UkSnap(Observer, 'insert', PrevLast, PrevMin, Last0, Min0);
        B.Get(1);
        UkSnap(Observer, 'get other', PrevLast, PrevMin, Last0, Min0);
        B.Count();
        UkSnap(Observer, 'count other', PrevLast, PrevMin, Last0, Min0);
        A.Get(1);
        UkSnap(Observer, 'get same', PrevLast, PrevMin, Last0, Min0);
        Commit();
        UkSnap(Observer, 'commit', PrevLast, PrevMin, Last0, Min0);
        A.DeleteAll();
        Commit();
        Observer.Finish();
    end;

    [Test]
    procedure UK_ModifyThenRead()
    var
        Observer: Codeunit "Probe Observer";
        B: Record "LT UK Row B";
        Last0: BigInteger;
        Min0: BigInteger;
        PrevLast: BigInteger;
        PrevMin: BigInteger;
    begin
        UkStart(Last0, Min0);
        PrevLast := Last0;
        PrevMin := Min0;
        B.Get(1);
        B.Amount := 3;
        B.Modify();
        UkSnap(Observer, 'modify', PrevLast, PrevMin, Last0, Min0);
        B.FindFirst();
        UkSnap(Observer, 'read', PrevLast, PrevMin, Last0, Min0);
        B.Amount := 4;
        B.Modify();
        UkSnap(Observer, 'second modify', PrevLast, PrevMin, Last0, Min0);
        Commit();
        UkSnap(Observer, 'commit', PrevLast, PrevMin, Last0, Min0);
        Observer.Finish();
    end;
}
