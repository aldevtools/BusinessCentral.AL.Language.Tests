// Probe: member lists and ordinals of ClientType, ExecutionMode and TransactionType; CurrentTransactionType behaviour.
codeunit 69456 "Probe System Enum Members"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ClientType_MembersAndOrdinals()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Default', Format(ClientType::Default, 0, 2));
        Observer.Observe('Windows', Format(ClientType::Windows, 0, 2));
        Observer.Observe('SOAP', Format(ClientType::SOAP, 0, 2));
        Observer.Observe('OData', Format(ClientType::OData, 0, 2));
        Observer.Observe('Api', Format(ClientType::Api, 0, 2));
        Observer.Observe('Background', Format(ClientType::Background, 0, 2));
        Observer.Observe('Management', Format(ClientType::Management, 0, 2));
        Observer.Observe('Web', Format(ClientType::Web, 0, 2));
        Observer.Observe('Tablet', Format(ClientType::Tablet, 0, 2));
        Observer.Observe('Phone', Format(ClientType::Phone, 0, 2));
        Observer.Observe('Desktop', Format(ClientType::Desktop, 0, 2));
        Observer.Observe('ChildSession', Format(ClientType::ChildSession, 0, 2));
        Observer.Observe('ODataV4', Format(ClientType::ODataV4, 0, 2));
        Observer.Observe('ODataV4_text', Format(ClientType::ODataV4));
        Observer.Expect('Default', '1');
        Observer.Expect('Windows', '2');
        Observer.Expect('SOAP', '4');
        Observer.Expect('OData', '5');
        Observer.Expect('Api', '14');
        Observer.Expect('Background', '7');
        Observer.Expect('Management', '8');
        Observer.Expect('Web', '3');
        Observer.Expect('Tablet', '9');
        Observer.Expect('Phone', '10');
        Observer.Expect('Desktop', '11');
        Observer.Expect('ChildSession', '15');
        Observer.Expect('ODataV4', '13');
        Observer.Expect('ODataV4_text', 'ODataV4');
        Observer.Verify();
    end;

    [Test]
    procedure ExecutionMode_MembersAndOrdinals()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Standard', Format(ExecutionMode::Standard, 0, 2));
        Observer.Observe('Debug', Format(ExecutionMode::Debug, 0, 2));
        Observer.Observe('Current', Format(Session.CurrentExecutionMode()));
        Observer.Observe('CurrentOrdinal', Format(Session.CurrentExecutionMode(), 0, 2));
        Observer.Expect('Standard', '0');
        Observer.Expect('Debug', '1');
        Observer.Expect('Current', 'Standard');
        Observer.Expect('CurrentOrdinal', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TransactionType_MembersAndOrdinals()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Update', Format(TransactionType::Update, 0, 2));
        Observer.Observe('Snapshot', Format(TransactionType::Snapshot, 0, 2));
        Observer.Observe('Report', Format(TransactionType::Report, 0, 2));
        Observer.Observe('UpdateNoLocks', Format(TransactionType::UpdateNoLocks, 0, 2));
        Observer.Observe('Browse', Format(TransactionType::Browse, 0, 2));
        Observer.Expect('Update', '1');
        Observer.Expect('Snapshot', '2');
        Observer.Expect('Report', '4');
        Observer.Expect('UpdateNoLocks', '0');
        Observer.Expect('Browse', '3');
        Observer.Verify();
    end;

    [Test]
    procedure CurrentTransactionType_DefaultSetBeforeAnyCall()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default', Format(CurrentTransactionType()));
        CurrentTransactionType(TransactionType::Report);
        Observer.Observe('afterSetReport', Format(CurrentTransactionType()));
        CurrentTransactionType(TransactionType::Update);
        Observer.Observe('afterSetUpdate', Format(CurrentTransactionType()));
        Observer.Expect('default', 'UpdateNoLocks');
        Observer.Expect('afterSetReport', 'Report');
        Observer.Expect('afterSetUpdate', 'Update');
        Observer.Verify();
    end;

    [Test]
    procedure CurrentTransactionType_SetAfterReadOnlyAndAfterCommit()
    var
        Row: Record "Probe Pf Row";
        Observer: Codeunit "Probe Observer";
    begin
        if Row.FindFirst() then;
        CurrentTransactionType(TransactionType::Report);
        Observer.Observe('afterReadThenSetReport', Format(CurrentTransactionType()));
        Commit();
        Observer.Observe('afterCommit', Format(CurrentTransactionType()));
        CurrentTransactionType(TransactionType::Browse);
        Observer.Observe('afterCommitThenSetBrowse', Format(CurrentTransactionType()));
        CurrentTransactionType(TransactionType::UpdateNoLocks);
        Observer.Expect('afterReadThenSetReport', 'Update');
        Observer.Expect('afterCommit', 'Update');
        Observer.Expect('afterCommitThenSetBrowse', 'Browse');
        Observer.Verify();
    end;

    [Test]
    procedure CurrentTransactionType_SetAfterWrite_ErrorOrIgnored()
    var
        Row: Record "Probe Pf Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.Id := 69450001;
        Row.Insert();
        Observer.Observe('afterInsertRead', Format(CurrentTransactionType()));
        Observer.Observe('setReportAfterInsert', Format(TrySet(TransactionType::Report)));
        Observer.ObserveError('setReportAfterInsert');
        Observer.Observe('afterFailedSetRead', Format(CurrentTransactionType()));
        Observer.Observe('setUpdateAfterInsert', Format(TrySet(TransactionType::Update)));
        Observer.ObserveError('setUpdateAfterInsert');
        Observer.Observe('afterSetUpdateRead', Format(CurrentTransactionType()));
        TrySet(TransactionType::UpdateNoLocks);
        Observer.Expect('afterInsertRead', 'UpdateNoLocks');
        Observer.Expect('setReportAfterInsert', 'Yes');
        Observer.Expect('setReportAfterInsert|text', '');
        Observer.Expect('setReportAfterInsert|code', '');
        Observer.Expect('afterFailedSetRead', 'UpdateNoLocks');
        Observer.Expect('setUpdateAfterInsert', 'No');
        Observer.Expect('setUpdateAfterInsert|text', 'The transaction type cannot be changed after a transaction has started.\\A transaction starts when the first database operation, such as FIND, NEXT, INSERT, DELETE, MODIFY, SUM, or COUNT, is run.\\The error occurred because the transaction type was changed from UpdateNoLocks to Update.');
        Observer.Expect('setUpdateAfterInsert|code', 'DB:CannotChangeTransactionType');
        Observer.Expect('afterSetUpdateRead', 'UpdateNoLocks');
        Observer.Verify();
    end;

    [Test]
    procedure CurrentTransactionType_AfterDeleteAllOfNoRows()
    var
        Row: Record "Probe Pf Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.SetRange(Id, -77);
        Row.DeleteAll();
        Observer.Observe('afterEmptyDeleteAllRead', Format(CurrentTransactionType()));
        Observer.Observe('setReportAfterEmptyDeleteAll', Format(TrySet(TransactionType::Report)));
        Observer.ObserveError('setReportAfterEmptyDeleteAll');
        Observer.Observe('afterSetReportRead', Format(CurrentTransactionType()));
        TrySet(TransactionType::UpdateNoLocks);
        Observer.Expect('afterEmptyDeleteAllRead', 'UpdateNoLocks');
        Observer.Expect('setReportAfterEmptyDeleteAll', 'Yes');
        Observer.Expect('setReportAfterEmptyDeleteAll|text', '');
        Observer.Expect('setReportAfterEmptyDeleteAll|code', '');
        Observer.Expect('afterSetReportRead', 'UpdateNoLocks');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySet(NewType: TransactionType)
    begin
        CurrentTransactionType(NewType);
    end;
}
