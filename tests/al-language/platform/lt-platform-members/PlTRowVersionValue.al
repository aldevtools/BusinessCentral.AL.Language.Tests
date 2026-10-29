// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-minimumactiverowversion-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 67516, codeunit 67515
// Probe: Database.MinimumActiveRowVersion against LastUsedRowVersion() + 1 with no write, inside an open write transaction and after Commit (issue 580 item 8). The existing PlTDatabase.al checks only that it is not below zero and not above LastUsedRowVersion() + 1.
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

table 90542 "LT NP3 RV Flow"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Total; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT RV Row");
        }
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

    local procedure Relations(var Observer: Codeunit "Probe Observer"; Name: Text; LastBefore: BigInteger; MinBefore: BigInteger)
    var
        Min: BigInteger;
        Last: BigInteger;
    begin
        Min := MinimumActiveRowVersion();
        Last := LastUsedRowVersion();
        Observer.Observe(Name + '_last_grew', Format(Last > LastBefore));
        Observer.Observe(Name + '_min_unchanged', Format(Min = MinBefore));
        Observer.Observe(Name + '_min_not_above_last_plus_one', Format(Min <= Last + 1));
        Observer.Observe(Name + '_in_write_transaction', Format(IsInWriteTransaction()));
    end;

    local procedure InsertRow(Id: Integer): Guid
    var
        Row: Record "LT RV Row";
    begin
        Row.Id := Id;
        Row.Insert();
        exit(Row.SystemId);
    end;

    [Test]
    procedure NP3_RowVersions_InsertThenGetBySystemId_OpenTransaction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RV Row";
        Id: Guid;
        LastBefore: BigInteger;
        MinBefore: BigInteger;
    begin
        Row.DeleteAll();
        Commit();
        LastBefore := LastUsedRowVersion();
        MinBefore := MinimumActiveRowVersion();
        Id := InsertRow(1);
        Relations(Observer, 'after_insert', LastBefore, MinBefore);
        Row.GetBySystemId(Id);
        Relations(Observer, 'after_get_by_system_id', LastBefore, MinBefore);
        Observer.Finish();
    end;

    [Test]
    procedure NP3_RowVersions_InsertThenFind_OpenTransaction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RV Row";
        LastBefore: BigInteger;
        MinBefore: BigInteger;
    begin
        Row.DeleteAll();
        Commit();
        LastBefore := LastUsedRowVersion();
        MinBefore := MinimumActiveRowVersion();
        InsertRow(1);
        Row.Id := 1;
        Row.Find('=');
        Relations(Observer, 'after_find_equal', LastBefore, MinBefore);
        Clear(Row);
        Row.Find('-');
        Relations(Observer, 'after_find_first', LastBefore, MinBefore);
        Clear(Row);
        Row.Find('+');
        Relations(Observer, 'after_find_last', LastBefore, MinBefore);
        Observer.Finish();
    end;

    [Test]
    procedure NP3_RowVersions_InsertThenNext_OpenTransaction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RV Row";
        LastBefore: BigInteger;
        MinBefore: BigInteger;
    begin
        Row.DeleteAll();
        Commit();
        LastBefore := LastUsedRowVersion();
        MinBefore := MinimumActiveRowVersion();
        InsertRow(1);
        InsertRow(2);
        Row.Id := 1;
        Row.Find('=');
        Row.Next();
        Relations(Observer, 'after_next', LastBefore, MinBefore);
        Observer.Observe('next_id', Format(Row.Id));
        Observer.Finish();
    end;

    [Test]
    procedure NP3_RowVersions_InsertThenCalcFields_OpenTransaction()
    var
        Observer: Codeunit "Probe Observer";
        Flow: Record "LT NP3 RV Flow";
        LastBefore: BigInteger;
        MinBefore: BigInteger;
    begin
        Flow.DeleteAll();
        Commit();
        LastBefore := LastUsedRowVersion();
        MinBefore := MinimumActiveRowVersion();
        InsertRow(1);
        Flow.Id := 1;
        Flow.Insert();
        Relations(Observer, 'after_insert_flow_table', LastBefore, MinBefore);
        Flow.CalcFields(Total);
        Relations(Observer, 'after_calcfields', LastBefore, MinBefore);
        Observer.Observe('total', Format(Flow.Total));
        Observer.Finish();
    end;

    [Test]
    procedure NP3_RowVersions_ReadsAfterCommit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RV Row";
        Flow: Record "LT NP3 RV Flow";
        Id: Guid;
        LastBefore: BigInteger;
        MinBefore: BigInteger;
    begin
        Row.DeleteAll();
        Flow.DeleteAll();
        Commit();
        LastBefore := LastUsedRowVersion();
        MinBefore := MinimumActiveRowVersion();
        Id := InsertRow(1);
        Flow.Id := 1;
        Flow.Insert();
        Commit();
        Relations(Observer, 'after_commit', LastBefore, MinBefore);
        Row.GetBySystemId(Id);
        Relations(Observer, 'after_get_by_system_id', LastBefore, MinBefore);
        Row.Id := 1;
        Row.Find('=');
        Relations(Observer, 'after_find', LastBefore, MinBefore);
        Row.Find('-');
        Relations(Observer, 'after_find_first', LastBefore, MinBefore);
        Flow.CalcFields(Total);
        Relations(Observer, 'after_calcfields', LastBefore, MinBefore);
        Observer.Finish();
    end;
}
