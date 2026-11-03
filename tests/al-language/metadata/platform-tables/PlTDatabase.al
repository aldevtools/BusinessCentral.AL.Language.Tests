// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-data-type
// Scope: in-scope
// Fixtures used: table 74209 "LT PlT Row" (PlTRow.Table.al), self-contained codeunit 74208
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Members: CompanyName, CurrentTransactionType (get/set), SelectLatestVersion, LastUsedRowVersion, MinimumActiveRowVersion, IsInWriteTransaction.
// BC versions: 29 (27 and 28 by CI)

codeunit 74208 "LT PlT Database"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SetType(T: TransactionType; var Observer: Codeunit "Probe Observer")
    var
        Old: TransactionType;
    begin
        Old := CurrentTransactionType();
        CurrentTransactionType(T);
        Observer.Observe('after_set', Format(CurrentTransactionType()));
        Observer.Observe('as_integer', Format(CurrentTransactionType(), 0, 2));
        CurrentTransactionType(Old);
        Observer.Observe('restored', Format(CurrentTransactionType() = Old));
    end;

    [Test]
    procedure CompanyName_Relations()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('not_empty', Format(CompanyName() <> ''));
        Observer.Observe('twice_equal', Format(CompanyName() = CompanyName()));
        Observer.Observe('max_len', Format(StrLen(CompanyName()) <= 30));
        Observer.Observe('database_prefix_equal', Format(Database.CompanyName() = CompanyName()));
        Observer.Observe('display_name_set', Format(CompanyProperty.DisplayName() <> ''));
        Observer.Observe('id_null', Format(IsNullGuid(CompanyProperty.ID())));
        Observer.Expect('not_empty', 'Yes');
        Observer.Expect('twice_equal', 'Yes');
        Observer.Expect('max_len', 'Yes');
        Observer.Expect('database_prefix_equal', 'Yes');
        Observer.Expect('display_name_set', 'Yes');
        Observer.Expect('id_null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure CurrentTransactionType_RoundTripUpdate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetType(TransactionType::Update, Observer);
        Observer.Expect('after_set', 'Update');
        Observer.Expect('as_integer', '1');
        Observer.Expect('restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CurrentTransactionType_RoundTripBrowse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetType(TransactionType::Browse, Observer);
        Observer.Expect('after_set', 'Browse');
        Observer.Expect('as_integer', '3');
        Observer.Expect('restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CurrentTransactionType_RoundTripReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetType(TransactionType::Report, Observer);
        Observer.Expect('after_set', 'Report');
        Observer.Expect('as_integer', '4');
        Observer.Expect('restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CurrentTransactionType_RoundTripSnapshot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetType(TransactionType::Snapshot, Observer);
        Observer.Expect('after_set', 'Snapshot');
        Observer.Expect('as_integer', '2');
        Observer.Expect('restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CurrentTransactionType_RoundTripUpdateNoLocks()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetType(TransactionType::UpdateNoLocks, Observer);
        Observer.Expect('after_set', 'UpdateNoLocks');
        Observer.Expect('as_integer', '0');
        Observer.Expect('restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CurrentTransactionType_EnumValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('update', Format(TransactionType::Update, 0, 2));
        Observer.Observe('updatenolocks', Format(TransactionType::UpdateNoLocks, 0, 2));
        Observer.Observe('browse', Format(TransactionType::Browse, 0, 2));
        Observer.Observe('report', Format(TransactionType::Report, 0, 2));
        Observer.Observe('snapshot', Format(TransactionType::Snapshot, 0, 2));
        Observer.Observe('names', Format(TransactionType::Update) + '|' + Format(TransactionType::UpdateNoLocks) + '|' + Format(TransactionType::Browse) + '|' + Format(TransactionType::Report) + '|' + Format(TransactionType::Snapshot));
        Observer.Expect('update', '1');
        Observer.Expect('updatenolocks', '0');
        Observer.Expect('browse', '3');
        Observer.Expect('report', '4');
        Observer.Expect('snapshot', '2');
        Observer.Expect('names', 'Update|UpdateNoLocks|Browse|Report|Snapshot');
        Observer.Verify();
    end;

    [Test]
    procedure CurrentTransactionType_SetTwiceLastWins()
    var
        Observer: Codeunit "Probe Observer";
        Old: TransactionType;
    begin
        Old := CurrentTransactionType();
        CurrentTransactionType(TransactionType::Browse);
        CurrentTransactionType(TransactionType::Report);
        Observer.Observe('last', Format(CurrentTransactionType()));
        CurrentTransactionType(TransactionType::Update);
        Observer.Observe('back_to_update', Format(CurrentTransactionType()));
        CurrentTransactionType(Old);
        Observer.Expect('last', 'Report');
        Observer.Expect('back_to_update', 'Update');
        Observer.Verify();
    end;

    [Test]
    procedure CurrentTransactionType_ReadsWorkInBrowseAndReport()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PlT Row";
        Old: TransactionType;
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 1;
        Row.Insert();
        Old := CurrentTransactionType();
        CurrentTransactionType(TransactionType::Browse);
        Observer.Observe('browse_count', Format(Row.Count()));
        CurrentTransactionType(TransactionType::Report);
        Observer.Observe('report_count', Format(Row.Count()));
        asserterror CurrentTransactionType(TransactionType::Snapshot);
        Observer.ObserveError('af117');
        Observer.Observe('snapshot_count', Format(Row.Count()));
        CurrentTransactionType(Old);
        Row.DeleteAll();
        Observer.Expect('browse_count', '1');
        Observer.Expect('report_count', '1');
        Observer.Expect('af117|text', 'The transaction type cannot be changed after a transaction has started.\\A transaction starts when the first database operation, such as FIND, NEXT, INSERT, DELETE, MODIFY, SUM, or COUNT, is run.\\The error occurred because the transaction type was changed from UpdateNoLocks to Snapshot.');
        Observer.Expect('af117|code', 'DB:CannotChangeTransactionType');
        Observer.Expect('snapshot_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SelectLatestVersion_NoArgument()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SelectLatestVersion();
        Observer.Observe('done', 'no error');
        SelectLatestVersion();
        Observer.Observe('twice', 'no error');
        Observer.Expect('done', 'no error');
        Observer.Expect('twice', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure SelectLatestVersion_TableNo()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PlT Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 1;
        Row.Insert();
        SelectLatestVersion(Database::"LT PlT Row");
        Observer.Observe('own_table', 'no error');
        Observer.Observe('row_still_there', Format(Row.Count()));
        SelectLatestVersion(0);
        Observer.Observe('zero', 'no error');
        Row.DeleteAll();
        Observer.Expect('own_table', 'no error');
        Observer.Expect('row_still_there', '1');
        Observer.Expect('zero', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure SelectLatestVersion_UnknownTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SelectLatestVersion(99999999);
        Observer.Observe('unknown_table', 'no error');
        Observer.Expect('unknown_table', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure LastUsedRowVersion_Relations()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PlT Row";
        Before: BigInteger;
        After: BigInteger;
    begin
        Row.DeleteAll();
        Before := LastUsedRowVersion();
        Observer.Observe('positive', Format(Before > 0));
        Observer.Observe('stable_without_write', Format(LastUsedRowVersion() >= Before));
        Row.Init();
        Row."No." := 1;
        Row.Insert();
        After := LastUsedRowVersion();
        Observer.Observe('after_insert_greater', Format(After > Before));
        Row."Name" := 'x';
        Row.Modify();
        Observer.Observe('after_modify_greater', Format(LastUsedRowVersion() > After));
        Observer.Observe('database_prefix_not_less', Format(Database.LastUsedRowVersion() >= After));
        Row.DeleteAll();
        Observer.Expect('positive', 'Yes');
        Observer.Expect('stable_without_write', 'Yes');
        Observer.Expect('after_insert_greater', 'No');
        Observer.Expect('after_modify_greater', 'Yes');
        Observer.Expect('database_prefix_not_less', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MinimumActiveRowVersion_Relations()
    var
        Observer: Codeunit "Probe Observer";
        Min: BigInteger;
    begin
        Min := MinimumActiveRowVersion();
        Observer.Observe('not_negative', Format(Min >= 0));
        Observer.Observe('not_above_last_plus_one', Format(Min <= LastUsedRowVersion() + 1));
        Observer.Observe('stable', Format(MinimumActiveRowVersion() >= Min));
        Observer.Observe('database_prefix_not_less', Format(Database.MinimumActiveRowVersion() >= Min));
        Observer.Expect('not_negative', 'Yes');
        Observer.Expect('not_above_last_plus_one', 'Yes');
        Observer.Expect('stable', 'Yes');
        Observer.Expect('database_prefix_not_less', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure IsInWriteTransaction_BeforeAndAfterWrite()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PlT Row";
    begin
        Row.DeleteAll();
        Commit();
        Observer.Observe('after_commit', Format(IsInWriteTransaction()));
        Observer.Observe('count', Format(Row.Count()));
        Observer.Observe('after_count', Format(IsInWriteTransaction()));
        Observer.Observe('find_empty', Format(Row.FindFirst()));
        Observer.Observe('after_find', Format(IsInWriteTransaction()));
        Observer.Expect('after_commit', 'No');
        Observer.Expect('count', '0');
        Observer.Expect('after_count', 'No');
        Observer.Expect('find_empty', 'No');
        Observer.Expect('after_find', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure IsInWriteTransaction_AfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PlT Row";
    begin
        Row.DeleteAll();
        Commit();
        Observer.Observe('before_write', Format(IsInWriteTransaction()));
        Observer.Observe('count', Format(Row.Count()));
        Observer.Observe('after_read_only', Format(IsInWriteTransaction()));
        Row.Init();
        Row."No." := 1;
        Row.Insert();
        Observer.Observe('after_insert', Format(IsInWriteTransaction()));
        Commit();
        Observer.Observe('after_second_commit', Format(IsInWriteTransaction()));
        Row.Modify();
        Observer.Observe('after_modify_without_change', Format(IsInWriteTransaction()));
        Row.Name := 'changed';
        Row.Modify();
        Observer.Observe('after_modify', Format(IsInWriteTransaction()));
        Commit();
        Row.DeleteAll();
        Observer.Observe('after_deleteall', Format(IsInWriteTransaction()));
        Commit();
        Observer.Observe('end', Format(IsInWriteTransaction()));
        Observer.Expect('before_write', 'No');
        Observer.Expect('count', '0');
        Observer.Expect('after_read_only', 'No');
        Observer.Expect('after_insert', 'Yes');
        Observer.Expect('after_second_commit', 'No');
        Observer.Expect('after_modify_without_change', 'Yes');
        Observer.Expect('after_modify', 'Yes');
        Observer.Expect('after_deleteall', 'Yes');
        Observer.Expect('end', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure IsInWriteTransaction_AfterErrorRollback()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PlT Row";
    begin
        Row.DeleteAll();
        Commit();
        Row.Init();
        Row."No." := 1;
        Row.Insert();
        asserterror Error('boom');
        Observer.ObserveError('err');
        Observer.Observe('after_error', Format(IsInWriteTransaction()));
        Observer.Observe('row_rolled_back', Format(Row.Count()));
        Observer.Expect('err|text', 'boom');
        Observer.Expect('err|code', 'Dialog');
        Observer.Expect('after_error', 'No');
        Observer.Expect('row_rolled_back', '0');
        Observer.Verify();
    end;
}
