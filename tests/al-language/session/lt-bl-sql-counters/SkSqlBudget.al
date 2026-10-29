// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Assert (codeunit 130000); own table 89190, codeunit 89191; writer SK (al-runner issue 5861); writer SZ adds tables 89750-89751, codeunits 89752-89753; writer TW adds tables 90148-90149, codeunit 90150 and the TW_ tests (al-runner issue 6116: reads between the counter reads)
// Probe: the statement budget test of al-runner issue 5861 (no Commit before the first read, a two-field key, a procedure in another
// codeunit that copies a temporary record into the table with FindSet, Next and Insert, then SetRange and Count), and the size of the
// change of SessionInformation.SqlStatementsExecuted() and SqlRowsRead() around that shape for several row counts, with and without a
// Commit before the first read. Each size is measured three times in the same run.
// Facts: the reporter's two tests pass; the differences are counts, compared with a number and formatted with StrSubstNo. The sizes
// equal those of SqlCounters.al (one-field key, no other codeunit) for inserts and inserts plus Count: the Inserts are buffered, Count
// sends them. Without a Commit, Inserts still buffered from an earlier measurement are counted in the next one (copy N=2, first value).
// Measured the same on BC 27.5, 28.5 and 29.0.
// BC versions: 27+

table 89190 "LT SK Rule Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Group Code"; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Value; Text[50]) { }
        field(4; Weight; Integer) { }
    }

    keys
    {
        key(PK; "Group Code", "Line No.") { }
    }
}

codeunit 89191 "LT SK Rule Builder"
{
    // The reporter's procedure: copy every row of the buffer under GroupCode, then count the rows of that group.
    procedure CopyLines(GroupCode: Code[20]; var TempRuleLine: Record "LT SK Rule Line" temporary): Integer
    var
        RuleLine: Record "LT SK Rule Line";
    begin
        if TempRuleLine.FindSet() then
            repeat
                RuleLine := TempRuleLine;
                RuleLine."Group Code" := GroupCode;
                RuleLine.Insert();
            until TempRuleLine.Next() = 0;
        RuleLine.SetRange("Group Code", GroupCode);
        exit(RuleLine.Count());
    end;

    // The same copy without the SetRange and Count at the end.
    procedure CopyLinesOnly(GroupCode: Code[20]; var TempRuleLine: Record "LT SK Rule Line" temporary)
    var
        RuleLine: Record "LT SK Rule Line";
    begin
        if TempRuleLine.FindSet() then
            repeat
                RuleLine := TempRuleLine;
                RuleLine."Group Code" := GroupCode;
                RuleLine.Insert();
            until TempRuleLine.Next() = 0;
    end;

    procedure CountGroup(GroupCode: Code[20]): Integer
    var
        RuleLine: Record "LT SK Rule Line";
    begin
        RuleLine.SetRange("Group Code", GroupCode);
        exit(RuleLine.Count());
    end;
}

codeunit 89192 "LT SK Sql Budget"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Seq: Integer;

    local procedure FillBuffer(var TempRuleLine: Record "LT SK Rule Line" temporary; N: Integer)
    var
        i: Integer;
    begin
        TempRuleLine.Reset();
        TempRuleLine.DeleteAll();
        for i := 1 to N do begin
            TempRuleLine.Init();
            TempRuleLine."Group Code" := 'TEMP';
            TempRuleLine."Line No." := i;
            TempRuleLine.Value := 'Value';
            TempRuleLine.Weight := i;
            TempRuleLine.Insert();
        end;
    end;

    local procedure NextGroup(): Code[20]
    begin
        Seq += 1;
        exit('SK' + Format(Seq));
    end;

    // Kind: 1 CopyLines (copy, SetRange, Count); 2 CopyLinesOnly (copy only); 3 CopyLinesOnly then CountGroup.
    // WithCommit: a Commit right before the first read.
    local procedure Measure(Kind: Integer; N: Integer; WithCommit: Boolean): Text
    var
        TempRuleLine: Record "LT SK Rule Line" temporary;
        RuleBuilder: Codeunit "LT SK Rule Builder";
        StmtsBefore: BigInteger;
        RowsBefore: BigInteger;
        StmtsDelta: BigInteger;
        RowsDelta: BigInteger;
        Group: Code[20];
        Copied: Integer;
    begin
        FillBuffer(TempRuleLine, N);
        Group := NextGroup();
        if WithCommit then
            Commit();
        StmtsBefore := SessionInformation.SqlStatementsExecuted();
        RowsBefore := SessionInformation.SqlRowsRead();
        case Kind of
            1:
                Copied := RuleBuilder.CopyLines(Group, TempRuleLine);
            2:
                RuleBuilder.CopyLinesOnly(Group, TempRuleLine);
            3:
                begin
                    RuleBuilder.CopyLinesOnly(Group, TempRuleLine);
                    Copied := RuleBuilder.CountGroup(Group);
                end;
        end;
        StmtsDelta := SessionInformation.SqlStatementsExecuted() - StmtsBefore;
        RowsDelta := SessionInformation.SqlRowsRead() - RowsBefore;
        if (Kind <> 2) and (Copied <> N) then
            Error('Copied %1 rows, expected %2.', Copied, N);
        exit(Format(StmtsDelta) + '/' + Format(RowsDelta));
    end;

    local procedure Repeat3(Kind: Integer; N: Integer; WithCommit: Boolean): Text
    begin
        exit(Measure(Kind, N, WithCommit) + ' ' + Measure(Kind, N, WithCommit) + ' ' + Measure(Kind, N, WithCommit));
    end;

    local procedure Series(var Observer: Codeunit "Probe Observer"; Name: Text; Kind: Integer; WithCommit: Boolean)
    begin
        Observer.Observe(Name + ' N=1', Repeat3(Kind, 1, WithCommit));
        Observer.Observe(Name + ' N=2', Repeat3(Kind, 2, WithCommit));
        Observer.Observe(Name + ' N=5', Repeat3(Kind, 5, WithCommit));
        Observer.Observe(Name + ' N=10', Repeat3(Kind, 10, WithCommit));
        Observer.Observe(Name + ' N=20', Repeat3(Kind, 20, WithCommit));
    end;

    // The reporter's first test (al-runner issue 5861), unchanged apart from names: no Commit before the first read.
    [Test]
    procedure SK_Repro_StatementBudget()
    var
        TempRuleLine: Record "LT SK Rule Line" temporary;
        RuleBuilder: Codeunit "LT SK Rule Builder";
        Before: BigInteger;
        After: BigInteger;
        Executed: BigInteger;
        Copied: Integer;
    begin
        FillBuffer(TempRuleLine, 10);

        Before := SessionInformation.SqlStatementsExecuted();
        Copied := RuleBuilder.CopyLines('BUDGET1', TempRuleLine);
        After := SessionInformation.SqlStatementsExecuted();
        Executed := After - Before;

        Assert.AreEqual(10, Copied, 'Copied lines');
        Assert.IsTrue(Executed <= 1000, StrSubstNo('SQL statements: %1, expected <= 1000', Executed));
    end;

    // The reporter's second test: a direct read minus a stored read, for both counters.
    [Test]
    procedure SK_Repro_StatementAndRowBudget()
    var
        TempRuleLine: Record "LT SK Rule Line" temporary;
        RuleBuilder: Codeunit "LT SK Rule Builder";
        StmtsBefore: BigInteger;
        RowsBefore: BigInteger;
        StmtsDelta: BigInteger;
        RowsDelta: BigInteger;
        Copied: Integer;
    begin
        FillBuffer(TempRuleLine, 10);

        StmtsBefore := SessionInformation.SqlStatementsExecuted();
        RowsBefore := SessionInformation.SqlRowsRead();
        Copied := RuleBuilder.CopyLines('BUDGET2', TempRuleLine);
        StmtsDelta := SessionInformation.SqlStatementsExecuted() - StmtsBefore;
        RowsDelta := SessionInformation.SqlRowsRead() - RowsBefore;

        Assert.AreEqual(10, Copied, 'Copied lines');
        Assert.IsTrue(StmtsDelta <= 1000, StrSubstNo('SQL statements: %1, expected <= 1000', StmtsDelta));
        Assert.IsTrue(RowsDelta <= 10000, StrSubstNo('SQL rows read: %1, expected <= 10000', RowsDelta));
    end;

    // The values of the reporter's shape: the differences, the budget comparisons and the StrSubstNo texts.
    [Test]
    procedure SK_Repro_Values()
    var
        Observer: Codeunit "Probe Observer";
        TempRuleLine: Record "LT SK Rule Line" temporary;
        RuleBuilder: Codeunit "LT SK Rule Builder";
        StmtsBefore: BigInteger;
        RowsBefore: BigInteger;
        StmtsDelta: BigInteger;
        RowsDelta: BigInteger;
        Copied: Integer;
    begin
        FillBuffer(TempRuleLine, 10);

        StmtsBefore := SessionInformation.SqlStatementsExecuted();
        RowsBefore := SessionInformation.SqlRowsRead();
        Copied := RuleBuilder.CopyLines('BUDGET3', TempRuleLine);
        StmtsDelta := SessionInformation.SqlStatementsExecuted() - StmtsBefore;
        RowsDelta := SessionInformation.SqlRowsRead() - RowsBefore;

        Observer.Observe('copied', Format(Copied));
        Observer.Observe('statements', Format(StmtsDelta));
        Observer.Observe('rows', Format(RowsDelta));
        Observer.Observe('statements <= 1000', Format(StmtsDelta <= 1000));
        Observer.Observe('rows <= 10000', Format(RowsDelta <= 10000));
        Observer.Observe('statements > 0', Format(StmtsDelta > 0));
        Observer.Observe('message', StrSubstNo('SQL statements: %1, expected <= 1000', StmtsDelta));
        Observer.Expect('copied', '10');
        Observer.Expect('statements', '3');
        Observer.Expect('rows', '1');
        Observer.Expect('statements <= 1000', 'Yes');
        Observer.Expect('rows <= 10000', 'Yes');
        Observer.Expect('statements > 0', 'Yes');
        Observer.Expect('message', 'SQL statements: 3, expected <= 1000');
        Observer.Verify();
    end;

    // Each value: three measurements "statements/rows" of the same operations, each on a new group code, no Commit.
    [Test]
    procedure SK_Sizes_CopyAndCount()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Series(Observer, 'copy+count', 1, false);
        Observer.Expect('copy+count N=1', '2/1 2/1 2/1');
        Observer.Expect('copy+count N=2', '3/1 3/1 3/1');
        Observer.Expect('copy+count N=5', '2/1 2/1 2/1');
        Observer.Expect('copy+count N=10', '3/1 3/1 3/1');
        Observer.Expect('copy+count N=20', '5/1 5/1 5/1');
        Observer.Verify();
    end;

    [Test]
    procedure SK_Sizes_CopyAndCount_Commit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Series(Observer, 'commit copy+count', 1, true);
        Observer.Expect('commit copy+count N=1', '2/1 2/1 2/1');
        Observer.Expect('commit copy+count N=2', '3/1 3/1 3/1');
        Observer.Expect('commit copy+count N=5', '2/1 2/1 2/1');
        Observer.Expect('commit copy+count N=10', '3/1 3/1 3/1');
        Observer.Expect('commit copy+count N=20', '5/1 5/1 5/1');
        Observer.Verify();
    end;

    [Test]
    procedure SK_Sizes_CopyOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Series(Observer, 'copy', 2, false);
        Series(Observer, 'commit copy', 2, true);
        Observer.Expect('copy N=1', '0/0 0/0 0/0');
        Observer.Expect('copy N=2', '1/0 0/0 0/0');
        Observer.Expect('copy N=5', '1/0 1/0 1/0');
        Observer.Expect('copy N=10', '2/0 2/0 2/0');
        Observer.Expect('copy N=20', '4/0 4/0 4/0');
        Observer.Expect('commit copy N=1', '0/0 0/0 0/0');
        Observer.Expect('commit copy N=2', '0/0 0/0 0/0');
        Observer.Expect('commit copy N=5', '1/0 1/0 1/0');
        Observer.Expect('commit copy N=10', '2/0 2/0 2/0');
        Observer.Expect('commit copy N=20', '4/0 4/0 4/0');
        Observer.Verify();
    end;

    [Test]
    procedure SK_Sizes_CopyThenCountElsewhere()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Series(Observer, 'copy, count in a second call', 3, false);
        Observer.Expect('copy, count in a second call N=1', '2/1 2/1 2/1');
        Observer.Expect('copy, count in a second call N=2', '3/1 3/1 3/1');
        Observer.Expect('copy, count in a second call N=5', '2/1 2/1 2/1');
        Observer.Expect('copy, count in a second call N=10', '3/1 3/1 3/1');
        Observer.Expect('copy, count in a second call N=20', '5/1 5/1 5/1');
        Observer.Verify();
    end;
}

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

    local procedure Stmt(): BigInteger
    begin
        exit(SessionInformation.SqlStatementsExecuted());
    end;

    // (a) The first Insert into a table whose trigger setup runs AL code, against the first Insert into a plain table. The size of the
    // first Insert into the table with trigger setup was 2 and 7 on different runs (BC 29 SaaS), so only "more than the plain table's one
    // statement" is pinned for it; the plain table's first Insert, the later Inserts and the flush by Count were the same on every run.
    [Test]
    procedure SZ_FirstInsert_TriggerSetupRunsAl()
    var
        Observer: Codeunit "Probe Observer";
        Subs: Codeunit "LT SZ Gt Subs";
        Gt: Record "LT SZ Gt Row";
        Plain: Record "LT SZ Plain Row";
        GtFirst: BigInteger;
        PlainFirst: BigInteger;
        Acc: Text;
    begin
        BindSubscription(Subs);
        Commit();
        Mark();
        Gt.Id := 1;
        Gt.Insert();
        GtFirst := Stmt() - Stmts;
        Mark();
        Gt.Id := 2;
        Gt.Insert();
        Acc := 'gt second ' + Delta() + '; ';
        Mark();
        Gt.Id := 3;
        Gt.Insert();
        Acc += 'gt third ' + Delta() + '; ';
        Mark();
        Acc += 'gt count ' + Format(Gt.Count()) + ' ' + Delta() + '; ';
        Mark();
        Plain.Id := 1;
        Plain.Insert();
        PlainFirst := Stmt() - Stmts;
        Mark();
        Plain.Id := 2;
        Plain.Insert();
        Acc += 'plain second ' + Delta() + '; ';
        Mark();
        Plain.Id := 3;
        Plain.Insert();
        Acc += 'plain third ' + Delta() + '; ';
        Mark();
        Acc += 'plain count ' + Format(Plain.Count()) + ' ' + Delta();
        Observer.Observe('plain first', Format(PlainFirst));
        Observer.Observe('gt first more than plain first', Format(GtFirst > PlainFirst));
        Observer.Observe('gt first at least 2', Format(GtFirst >= 2));
        Observer.Observe('rest', Acc);
        Observer.Observe('subscriber ran', Format(Subs.Seen()));
        UnbindSubscription(Subs);
        Observer.Expect('plain first', '1');
        Observer.Expect('gt first more than plain first', 'Yes');
        Observer.Expect('gt first at least 2', 'Yes');
        Observer.Expect('rest', 'gt second 0/0; gt third 0/0; gt count 3 4/1; plain second 0/0; plain third 0/0; plain count 3 4/1');
        Observer.Expect('subscriber ran', '3');
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

    // Each value: insert-window, copy-window, Count result, flush window ("statements/rows"), on three repeats. Same on 3 runs.
    [Test]
    procedure SZ_CopyLoop_WhileInsertsBuffered()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('K0 N10', Buffered(0, 10) + ' | ' + Buffered(0, 10) + ' | ' + Buffered(0, 10));
        Observer.Observe('K1 N10', Buffered(1, 10) + ' | ' + Buffered(1, 10) + ' | ' + Buffered(1, 10));
        Observer.Observe('K5 N10', Buffered(5, 10) + ' | ' + Buffered(5, 10) + ' | ' + Buffered(5, 10));
        Observer.Observe('K5 N1', Buffered(5, 1) + ' | ' + Buffered(5, 1) + ' | ' + Buffered(5, 1));
        Observer.Observe('K20 N20', Buffered(20, 20) + ' | ' + Buffered(20, 20) + ' | ' + Buffered(20, 20));
        Observer.Expect('K0 N10', '0/0 2/0 10 1/1 | 0/0 2/0 10 1/1 | 0/0 2/0 10 1/1');
        Observer.Expect('K1 N10', '0/0 2/0 11 2/1 | 0/0 2/0 11 2/1 | 0/0 2/0 11 2/1');
        Observer.Expect('K5 N10', '1/0 2/0 15 1/1 | 1/0 2/0 15 1/1 | 1/0 2/0 15 1/1');
        Observer.Expect('K5 N1', '1/0 0/0 6 2/1 | 1/0 0/0 6 2/1 | 1/0 0/0 6 2/1');
        Observer.Expect('K20 N20', '4/0 4/0 40 1/1 | 4/0 4/0 40 1/1 | 4/0 4/0 40 1/1');
        Observer.Verify();
    end;

    // ---- writer TW (al-runner issue 6116, reporter's real-BC 29.0 run): the change of both counters around a procedure of another codeunit
    //      that READS a table, with no Commit before the first read and ten rows inserted just before it: Get with SetLoadFields, a filtered
    //      FindSet + Next with SetLoadFields, a Get + Modify loop over five rows, and five FindFirst that find nothing, each followed by
    //      Insert(true) into a table with an AutoIncrement field. Value: "statements/rows" and the result the procedure returned. ----
    local procedure TwInsertLines(GroupCode: Code[20]; LineCount: Integer)
    var
        RuleLine: Record "LT TW Sk Rule Line";
        i: Integer;
    begin
        for i := 1 to LineCount do begin
            RuleLine.Init();
            RuleLine."Group Code" := GroupCode;
            RuleLine."Line No." := i;
            RuleLine.Value := 'Value';
            RuleLine.Weight := i;
            RuleLine.Insert();
        end;
    end;

    [Test]
    procedure TW_GetWithLoadFields_Counts()
    var
        RuleStore: Codeunit "LT TW Sk Rule Store";
        Obs: Codeunit "Probe Observer";
        StmtsBefore: BigInteger;
        RowsBefore: BigInteger;
        StmtsDelta: BigInteger;
        RowsDelta: BigInteger;
        Weight: Integer;
    begin
        TwInsertLines('TWREAD1', 10);
        StmtsBefore := SessionInformation.SqlStatementsExecuted();
        RowsBefore := SessionInformation.SqlRowsRead();
        Weight := RuleStore.ReadWeight('TWREAD1', 5);
        StmtsDelta := SessionInformation.SqlStatementsExecuted() - StmtsBefore;
        RowsDelta := SessionInformation.SqlRowsRead() - RowsBefore;
        Obs.Observe('result', Format(Weight));
        Obs.Observe('statements/rows', Format(StmtsDelta) + '/' + Format(RowsDelta));
        Obs.Observe('within 5/5', Format((StmtsDelta <= 5) and (RowsDelta <= 5)));
        Obs.Expect('result', '5');
        Obs.Expect('statements/rows', '1/1');
        Obs.Expect('within 5/5', 'Yes');
        Obs.Verify();
    end;

    [Test]
    procedure TW_FilteredFindSet_Counts()
    var
        RuleStore: Codeunit "LT TW Sk Rule Store";
        Obs: Codeunit "Probe Observer";
        StmtsBefore: BigInteger;
        RowsBefore: BigInteger;
        StmtsDelta: BigInteger;
        RowsDelta: BigInteger;
        Total: Integer;
    begin
        TwInsertLines('TWREAD2', 10);
        StmtsBefore := SessionInformation.SqlStatementsExecuted();
        RowsBefore := SessionInformation.SqlRowsRead();
        Total := RuleStore.SumWeights('TWREAD2');
        StmtsDelta := SessionInformation.SqlStatementsExecuted() - StmtsBefore;
        RowsDelta := SessionInformation.SqlRowsRead() - RowsBefore;
        Obs.Observe('result', Format(Total));
        Obs.Observe('statements/rows', Format(StmtsDelta) + '/' + Format(RowsDelta));
        Obs.Observe('within 5/25', Format((StmtsDelta <= 5) and (RowsDelta <= 25)));
        Obs.Expect('result', '55');
        Obs.Expect('statements/rows', '1/11');
        Obs.Expect('within 5/25', 'Yes');
        Obs.Verify();
    end;

    [Test]
    procedure TW_GetAndModifyLoop_Counts()
    var
        RuleLine: Record "LT TW Sk Rule Line";
        RuleStore: Codeunit "LT TW Sk Rule Store";
        Obs: Codeunit "Probe Observer";
        StmtsBefore: BigInteger;
        RowsBefore: BigInteger;
        StmtsDelta: BigInteger;
        RowsDelta: BigInteger;
    begin
        TwInsertLines('TWWRITE1', 10);
        StmtsBefore := SessionInformation.SqlStatementsExecuted();
        RowsBefore := SessionInformation.SqlRowsRead();
        RuleStore.RaiseWeights('TWWRITE1', 5);
        StmtsDelta := SessionInformation.SqlStatementsExecuted() - StmtsBefore;
        RowsDelta := SessionInformation.SqlRowsRead() - RowsBefore;
        RuleLine.Get('TWWRITE1', 5);
        Obs.Observe('result', Format(RuleLine.Weight));
        Obs.Observe('statements/rows', Format(StmtsDelta) + '/' + Format(RowsDelta));
        Obs.Observe('within 25/25', Format((StmtsDelta <= 25) and (RowsDelta <= 25)));
        Obs.Expect('result', '105');
        Obs.Expect('statements/rows', '10/10');
        Obs.Expect('within 25/25', 'Yes');
        Obs.Verify();
    end;

    [Test]
    procedure TW_FindFirstOrInsert_Counts()
    var
        TreeNode: Record "LT TW Sk Tree Node";
        RuleStore: Codeunit "LT TW Sk Rule Store";
        Obs: Codeunit "Probe Observer";
        StmtsBefore: BigInteger;
        RowsBefore: BigInteger;
        StmtsDelta: BigInteger;
        RowsDelta: BigInteger;
        LastNode: Integer;
    begin
        StmtsBefore := SessionInformation.SqlStatementsExecuted();
        RowsBefore := SessionInformation.SqlRowsRead();
        LastNode := RuleStore.BuildPath('TWTREE1', 5);
        StmtsDelta := SessionInformation.SqlStatementsExecuted() - StmtsBefore;
        RowsDelta := SessionInformation.SqlRowsRead() - RowsBefore;
        TreeNode.SetRange("Group Code", 'TWTREE1');
        Obs.Observe('nodes', Format(TreeNode.Count()));
        Obs.Observe('last node set', Format(LastNode <> 0));
        Obs.Observe('statements/rows', Format(StmtsDelta) + '/' + Format(RowsDelta));
        Obs.Observe('within 25/15', Format((StmtsDelta <= 25) and (RowsDelta <= 15)));
        Obs.Expect('nodes', '5');
        Obs.Expect('last node set', 'Yes');
        Obs.Expect('statements/rows', '11/5');
        Obs.Expect('within 25/15', 'Yes');
        Obs.Verify();
    end;
}

// ---- writer TW (al-runner issue 6116): the reporter's tables and the codeunit whose procedures read them. ----
table 90148 "LT TW Sk Rule Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Group Code"; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Value; Text[50]) { }
        field(4; Weight; Integer) { }
    }

    keys
    {
        key(PK; "Group Code", "Line No.") { Clustered = true; }
    }
}

table 90149 "LT TW Sk Tree Node"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Group Code"; Code[20]) { }
        field(2; "Parent Node"; Integer) { }
        field(3; Hash; Integer) { }
        field(4; "Node ID"; Integer) { AutoIncrement = true; }
    }

    keys
    {
        key(PK; "Group Code", "Parent Node", Hash) { Clustered = true; }
        key(NodeID; "Group Code", "Node ID") { Unique = true; }
    }
}

codeunit 90150 "LT TW Sk Rule Store"
{
    procedure ReadWeight(GroupCode: Code[20]; LineNo: Integer): Integer
    var
        RuleLine: Record "LT TW Sk Rule Line";
    begin
        RuleLine.SetLoadFields(Weight);
        if not RuleLine.Get(GroupCode, LineNo) then
            exit(0);
        exit(RuleLine.Weight);
    end;

    procedure SumWeights(GroupCode: Code[20]): Integer
    var
        RuleLine: Record "LT TW Sk Rule Line";
        Total: Integer;
    begin
        RuleLine.SetRange("Group Code", GroupCode);
        RuleLine.SetLoadFields(Weight);
        if RuleLine.FindSet() then
            repeat
                Total += RuleLine.Weight;
            until RuleLine.Next() = 0;
        exit(Total);
    end;

    procedure RaiseWeights(GroupCode: Code[20]; LastLineNo: Integer)
    var
        RuleLine: Record "LT TW Sk Rule Line";
        LineNo: Integer;
    begin
        for LineNo := 1 to LastLineNo do begin
            RuleLine.Get(GroupCode, LineNo);
            RuleLine.Weight += 100;
            RuleLine.Modify();
        end;
    end;

    procedure BuildPath(GroupCode: Code[20]; Depth: Integer): Integer
    var
        ParentNode: Integer;
        i: Integer;
    begin
        for i := 1 to Depth do
            ParentNode := GetOrCreateNode(GroupCode, ParentNode, i * 31);
        exit(ParentNode);
    end;

    local procedure GetOrCreateNode(GroupCode: Code[20]; ParentNode: Integer; Hash: Integer): Integer
    var
        TreeNode: Record "LT TW Sk Tree Node";
    begin
        TreeNode.SetRange("Group Code", GroupCode);
        TreeNode.SetRange("Parent Node", ParentNode);
        TreeNode.SetRange(Hash, Hash);
        if TreeNode.FindFirst() then
            exit(TreeNode."Node ID");

        TreeNode.Init();
        TreeNode."Group Code" := GroupCode;
        TreeNode."Parent Node" := ParentNode;
        TreeNode.Hash := Hash;
        TreeNode.Insert(true);
        exit(TreeNode."Node ID");
    end;
}
