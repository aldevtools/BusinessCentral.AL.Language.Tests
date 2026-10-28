
// Writer SZ (al-runner issue 5861): a table whose global trigger setup runs AL code (OnAfterGetDatabaseTableTriggerSetup registers it for
// OnDatabaseInsert; OnAfterOnDatabaseInsert runs AL code), and a plain table. Each is first used in the session by one test.
table 89750 "LT SZ Gt Row"
{
    DataClassification = CustomerContent;

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

table 89751 "LT SZ Plain Row"
{
    DataClassification = CustomerContent;

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

codeunit 89752 "LT SZ Gt Subs"
{
    EventSubscriberInstance = Manual;

    var
        InsertsSeen: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure Setup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        if TableId = Database::"LT SZ Gt Row" then
            OnDatabaseInsert := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseInsert', '', false, false)]
    local procedure DbInsert(RecRef: RecordRef)
    begin
        if RecRef.Number() = Database::"LT SZ Gt Row" then
            InsertsSeen += 1;
    end;

    procedure Seen(): Integer
    begin
        exit(InsertsSeen);
    end;
}

codeunit 89753 "LT SZ Sql Budget"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Stmts: BigInteger;
        Rows: BigInteger;

    local procedure Mark()
    begin
        Stmts := SessionInformation.SqlStatementsExecuted();
        Rows := SessionInformation.SqlRowsRead();
    end;

    local procedure Delta(): Text
    begin
        exit(Format(SessionInformation.SqlStatementsExecuted() - Stmts) + '/' + Format(SessionInformation.SqlRowsRead() - Rows));
    end;

    // (a) The first Insert into a table whose trigger setup runs AL code, then the next Inserts, then a flush by Count.
    [Test]
    procedure SZ_FirstInsert_TriggerSetupRunsAl()
    var
        Observer: Codeunit "Probe Observer";
        Subs: Codeunit "LT SZ Gt Subs";
        Row: Record "LT SZ Gt Row";
    begin
        BindSubscription(Subs);
        Commit();
        Mark();
        Row.Id := 1;
        Row.Insert();
        Observer.Observe('gt first insert', Delta());
        Mark();
        Row.Id := 2;
        Row.Insert();
        Observer.Observe('gt second insert', Delta());
        Mark();
        Row.Id := 3;
        Row.Insert();
        Observer.Observe('gt third insert', Delta());
        Mark();
        Observer.Observe('gt count', Format(Row.Count()));
        Observer.Observe('gt count delta', Delta());
        Observer.Observe('gt subscriber ran', Format(Subs.Seen()));
        UnbindSubscription(Subs);
        Observer.Verify();
    end;

    // The same shape on a table without trigger setup, as the reference.
    [Test]
    procedure SZ_FirstInsert_PlainTable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SZ Plain Row";
    begin
        Commit();
        Mark();
        Row.Id := 1;
        Row.Insert();
        Observer.Observe('plain first insert', Delta());
        Mark();
        Row.Id := 2;
        Row.Insert();
        Observer.Observe('plain second insert', Delta());
        Mark();
        Row.Id := 3;
        Row.Insert();
        Observer.Observe('plain third insert', Delta());
        Mark();
        Observer.Observe('plain count', Format(Row.Count()));
        Observer.Observe('plain count delta', Delta());
        Observer.Verify();
    end;

    // (b) A copy loop while earlier Inserts are still buffered: K rows inserted first with no read in between, then N copied.
    local procedure Buffered(K: Integer; N: Integer): Text
    var
        Row: Record "LT SZ Plain Row";
        Temp: Record "LT SZ Plain Row" temporary;
        i: Integer;
        Base: Integer;
        Copy: Text;
    begin
        Row.Reset();
        Row.DeleteAll();
        Commit();
        for i := 1 to N do begin
            Temp.Id := i;
            Temp.Insert();
        end;
        Base := 1000;
        Mark();
        for i := 1 to K do begin
            Row.Id := Base + i;
            Row.Insert();
        end;
        Copy := Delta();
        Mark();
        if Temp.FindSet() then
            repeat
                Row.Id := Temp.Id;
                Row.Insert();
            until Temp.Next() = 0;
        Copy += ' ' + Delta();
        Mark();
        Row.SetRange(Id, 0, 2000);
        Copy += ' ' + Format(Row.Count()) + ' ' + Delta();
        exit(Copy);
    end;

    [Test]
    procedure SZ_CopyLoop_WhileInsertsBuffered()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('K=0 N=10', Buffered(0, 10) + ' | ' + Buffered(0, 10) + ' | ' + Buffered(0, 10));
        Observer.Observe('K=1 N=10', Buffered(1, 10) + ' | ' + Buffered(1, 10) + ' | ' + Buffered(1, 10));
        Observer.Observe('K=5 N=10', Buffered(5, 10) + ' | ' + Buffered(5, 10) + ' | ' + Buffered(5, 10));
        Observer.Observe('K=5 N=1', Buffered(5, 1) + ' | ' + Buffered(5, 1) + ' | ' + Buffered(5, 1));
        Observer.Observe('K=20 N=20', Buffered(20, 20) + ' | ' + Buffered(20, 20) + ' | ' + Buffered(20, 20));
        Observer.Verify();
    end;
}
