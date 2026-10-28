// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Assert (codeunit 130000); own table 89190, codeunit 89191; writer SK (al-runner issue 5861); writer SZ adds tables 89750-89751, codeunits 89752-89753
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
