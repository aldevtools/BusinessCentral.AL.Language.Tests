// Batch 7 probes: Query Average quotients, BigInteger and Duration aggregates, aggregates over FlowFields, group order, cross join groups. Observe only.
codeunit 68512 "W7 Query Aggregates"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedDecimals(Values: Text)
    var
        Seed: Codeunit "W7 Q Seed";
        Parts: List of [Text];
        Part: Text;
        Value: Decimal;
        n: Integer;
    begin
        Seed.Clear();
        Parts := Values.Split(',');
        foreach Part in Parts do begin
            n += 1;
            Evaluate(Value, Part, 9);
            Seed.Row(n, 0, '', Value, '');
        end;
    end;

    local procedure RunDecimals(var Observer: Codeunit "Probe Observer"; Values: Text)
    var
        Q: Query "W7 Q Aggregates";
    begin
        SeedDecimals(Values);
        Q.Open();
        if Q.Read() then begin
            Observer.Observe('avg of ' + CopyStr(Values, 1, 40), Format(Q.AvgDec, 0, 9));
            Observer.Observe('sum of ' + CopyStr(Values, 1, 40), Format(Q.SumDec, 0, 9));
        end else
            Observer.Observe('avg of ' + CopyStr(Values, 1, 40), 'no row');
        Q.Close();
    end;

    [Test]
    procedure Average_Decimal_QuotientsWhereCutAndRoundDiffer()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDecimals(Observer, '2,2,1');
        RunDecimals(Observer, '1000,1000,0');
        RunDecimals(Observer, '1,0,0,0,0,0,0');
        RunDecimals(Observer, '1,1,0');
        RunDecimals(Observer, '1,2');
        RunDecimals(Observer, '-2,-2,-1');
        RunDecimals(Observer, '0.000000000000000001,0,0');
        RunDecimals(Observer, '99999999999,0,1');
        RunDecimals(Observer, '0.1,0.1,0.1,0.1,0.1,0.1,0.1');
        RunDecimals(Observer, '1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0');
        Observer.Expect('avg of 2,2,1', '1.66666666666666667');
        Observer.Expect('sum of 2,2,1', '5');
        Observer.Expect('avg of 1000,1000,0', '666.666666666666667');
        Observer.Expect('sum of 1000,1000,0', '2000');
        Observer.Expect('avg of 1,0,0,0,0,0,0', '0.142857142857142857');
        Observer.Expect('sum of 1,0,0,0,0,0,0', '1');
        Observer.Expect('avg of 1,1,0', '0.666666666666666667');
        Observer.Expect('sum of 1,1,0', '2');
        Observer.Expect('avg of 1,2', '1.5');
        Observer.Expect('sum of 1,2', '3');
        Observer.Expect('avg of -2,-2,-1', '-1.66666666666666667');
        Observer.Expect('sum of -2,-2,-1', '-5');
        Observer.Expect('avg of 0.000000000000000001,0,0', '0');
        Observer.Expect('sum of 0.000000000000000001,0,0', '0.000000000000000001');
        Observer.Expect('avg of 99999999999,0,1', '33333333333.3333333');
        Observer.Expect('sum of 99999999999,0,1', '100000000000');
        Observer.Expect('avg of 0.1,0.1,0.1,0.1,0.1,0.1,0.1', '0.1');
        Observer.Expect('sum of 0.1,0.1,0.1,0.1,0.1,0.1,0.1', '0.7');
        Observer.Expect('avg of 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,', '0.986111111111111111');
        Observer.Expect('sum of 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,', '71');
        Observer.Verify();
    end;

    [Test]
    procedure Average_Decimal_FewerDigitsThanTheLimit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDecimals(Observer, '1,2,3');
        RunDecimals(Observer, '1,1,2,2');
        RunDecimals(Observer, '0.5,0.25');
        RunDecimals(Observer, '10,0,0,0,0,0,0,0,0');
        RunDecimals(Observer, '1,0,0');
        Observer.Expect('avg of 1,2,3', '2');
        Observer.Expect('sum of 1,2,3', '6');
        Observer.Expect('avg of 1,1,2,2', '1.5');
        Observer.Expect('sum of 1,1,2,2', '6');
        Observer.Expect('avg of 0.5,0.25', '0.375');
        Observer.Expect('sum of 0.5,0.25', '0.75');
        Observer.Expect('avg of 10,0,0,0,0,0,0,0,0', '1.11111111111111111');
        Observer.Expect('sum of 10,0,0,0,0,0,0,0,0', '10');
        Observer.Expect('avg of 1,0,0', '0.333333333333333333');
        Observer.Expect('sum of 1,0,0', '1');
        Observer.Verify();
    end;

    local procedure SeedBig(Values: Text)
    var
        Seed: Codeunit "W7 Q Seed";
        Row: Record "W7 Q Row";
        Parts: List of [Text];
        Part: Text;
        Value: BigInteger;
        n: Integer;
    begin
        Seed.Clear();
        Parts := Values.Split(',');
        foreach Part in Parts do begin
            n += 1;
            Evaluate(Value, Part, 9);
            Seed.Row(n, 0, '', 0, '');
            Row.Get(n);
            Row.Big := Value;
            Row.Modify();
        end;
    end;

    [TryFunction]
    local procedure TryReadBig(var Q: Query "W7 Q Aggregates Big"; var HasRow: Boolean)
    begin
        Q.Open();
        HasRow := Q.Read();
    end;

    local procedure RunBig(var Observer: Codeunit "Probe Observer"; Values: Text)
    var
        Q: Query "W7 Q Aggregates Big";
        HasRow: Boolean;
    begin
        SeedBig(Values);
        if not TryReadBig(Q, HasRow) then begin
            Observer.Observe('big ' + Values, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
            exit;
        end;
        Observer.Observe('big ' + Values + ' has row', Format(HasRow));
        if HasRow then begin
            Observer.Observe('big ' + Values + ' sum', Format(Q.SumBig, 0, 9));
            Observer.Observe('big ' + Values + ' avg', Format(Q.AvgBig, 0, 9));
            Observer.Observe('big ' + Values + ' min', Format(Q.MinBig, 0, 9));
            Observer.Observe('big ' + Values + ' max', Format(Q.MaxBig, 0, 9));
        end;
        Q.Close();
    end;

#if BC29PLUS
    [Test]
    procedure Aggregates_OverBigInteger()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunBig(Observer, '1,2,2');
        RunBig(Observer, '10000000000,20000000000');
        RunBig(Observer, '9223372036854775807,1');
        RunBig(Observer, '-5,-5,-4');
        Observer.Expect('big 1,2,2 has row', 'Yes');
        Observer.Expect('big 1,2,2 sum', '5');
        Observer.Expect('big 1,2,2 avg', '1');
        Observer.Expect('big 1,2,2 min', '1');
        Observer.Expect('big 1,2,2 max', '2');
        Observer.Expect('big 10000000000,20000000000 has row', 'Yes');
        Observer.Expect('big 10000000000,20000000000 sum', '30000000000');
        Observer.Expect('big 10000000000,20000000000 avg', '15000000000');
        Observer.Expect('big 10000000000,20000000000 min', '10000000000');
        Observer.Expect('big 10000000000,20000000000 max', '20000000000');
        Observer.Expect('big 9223372036854775807,1', 'error:An arithmetic overflow occurred while calculating a value, for example when a sum of an Integer field exceeds the maximum value the data type can hold. Use a larger data type, such as BigInteger or Decimal, for the field or the calculation.|CalculationOverflow:Sql');
        Observer.Expect('big -5,-5,-4 has row', 'Yes');
        Observer.Expect('big -5,-5,-4 sum', '-14');
        Observer.Expect('big -5,-5,-4 avg', '-4');
        Observer.Expect('big -5,-5,-4 min', '-5');
        Observer.Expect('big -5,-5,-4 max', '-4');
        Observer.Verify();
    end;
#endif

    local procedure SeedDur(Values: Text)
    var
        Seed: Codeunit "W7 Q Seed";
        Row: Record "W7 Q Row";
        Parts: List of [Text];
        Part: Text;
        Value: Integer;
        n: Integer;
    begin
        Seed.Clear();
        Parts := Values.Split(',');
        foreach Part in Parts do begin
            n += 1;
            Evaluate(Value, Part, 9);
            Seed.Row(n, 0, '', 0, '');
            Row.Get(n);
            Row.Dur := Value;
            Row.Modify();
        end;
    end;

    [TryFunction]
    local procedure TryReadDur(var Q: Query "W7 Q Aggregates Dur"; var HasRow: Boolean)
    begin
        Q.Open();
        HasRow := Q.Read();
    end;

    local procedure RunDur(var Observer: Codeunit "Probe Observer"; Values: Text)
    var
        Q: Query "W7 Q Aggregates Dur";
        HasRow: Boolean;
    begin
        SeedDur(Values);
        if not TryReadDur(Q, HasRow) then begin
            Observer.Observe('duration ' + Values, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
            exit;
        end;
        Observer.Observe('duration ' + Values + ' has row', Format(HasRow));
        if HasRow then begin
            Observer.Observe('duration ' + Values + ' sum', Format(Q.SumDur, 0, 9));
            Observer.Observe('duration ' + Values + ' avg', Format(Q.AvgDur, 0, 9));
            Observer.Observe('duration ' + Values + ' min', Format(Q.MinDur, 0, 9));
            Observer.Observe('duration ' + Values + ' max', Format(Q.MaxDur, 0, 9));
        end;
        Q.Close();
    end;

    [Test]
    procedure Aggregates_OverDuration()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDur(Observer, '1000,2000,2000');
        RunDur(Observer, '1,2,2');
        RunDur(Observer, '60000,120000');
        Observer.Expect('duration 1000,2000,2000 has row', 'Yes');
        Observer.Expect('duration 1000,2000,2000 sum', 'P0DT0H0M5.0S');
        Observer.Expect('duration 1000,2000,2000 avg', 'P0DT0H0M1.666S');
        Observer.Expect('duration 1000,2000,2000 min', 'P0DT0H0M1.0S');
        Observer.Expect('duration 1000,2000,2000 max', 'P0DT0H0M2.0S');
        Observer.Expect('duration 1,2,2 has row', 'Yes');
        Observer.Expect('duration 1,2,2 sum', 'P0DT0H0M0.005S');
        Observer.Expect('duration 1,2,2 avg', 'P0DT0H0M0.001S');
        Observer.Expect('duration 1,2,2 min', 'P0DT0H0M0.001S');
        Observer.Expect('duration 1,2,2 max', 'P0DT0H0M0.002S');
        Observer.Expect('duration 60000,120000 has row', 'Yes');
        Observer.Expect('duration 60000,120000 sum', 'P0DT0H3M0.0S');
        Observer.Expect('duration 60000,120000 avg', 'P0DT0H1M30.0S');
        Observer.Expect('duration 60000,120000 min', 'P0DT0H1M0.0S');
        Observer.Expect('duration 60000,120000 max', 'P0DT0H2M0.0S');
        Observer.Verify();
    end;

    local procedure SeedFlow()
    var
        Seed: Codeunit "W7 Q Seed";
    begin
        Seed.Clear();
        Seed.Row(1, 0, '', 0, '');
        Seed.Row(2, 0, '', 0, '');
        Seed.Row(3, 0, '', 0, '');
        Seed.Line(1, 1, 10);
        Seed.Line(2, 1, 20);
        Seed.Line(3, 2, 5);
    end;

    [TryFunction]
    local procedure TryReadFlow(var Q: Query "W7 Q Flow Method"; var HasRow: Boolean)
    begin
        Q.Open();
        HasRow := Q.Read();
    end;

    [Test]
    procedure MethodOverAFlowField_SumAndCount()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "W7 Q Flow Method";
        HasRow: Boolean;
    begin
        SeedFlow();
        Observer.Observe('unfiltered ok', Format(TryReadFlow(Q, HasRow)));
        Observer.ObserveError('unfiltered');
        Observer.Observe('unfiltered has row', Format(HasRow));
        if HasRow then begin
            Observer.Observe('unfiltered sum of Line Total', Format(Q.SumTotal, 0, 9));
            Observer.Observe('unfiltered count', Format(Q.CntTotal));
        end;
        Q.Close();

        Clear(Q);
        Q.SetRange(FEntry, 1, 2);
        Observer.Observe('entries 1..2 ok', Format(TryReadFlow(Q, HasRow)));
        Observer.ObserveError('entries 1..2');
        if HasRow then begin
            Observer.Observe('entries 1..2 sum of Line Total', Format(Q.SumTotal, 0, 9));
            Observer.Observe('entries 1..2 count', Format(Q.CntTotal));
        end;
        Q.Close();

        Clear(Q);
        Q.SetRange(FEntry, 3);
        Observer.Observe('entry 3 ok', Format(TryReadFlow(Q, HasRow)));
        Observer.ObserveError('entry 3');
        if HasRow then begin
            Observer.Observe('entry 3 sum of Line Total', Format(Q.SumTotal, 0, 9));
            Observer.Observe('entry 3 count', Format(Q.CntTotal));
        end;
        Q.Close();
        Observer.Expect('unfiltered ok', 'Yes');
        Observer.Expect('unfiltered|text', '');
        Observer.Expect('unfiltered|code', '');
        Observer.Expect('unfiltered has row', 'Yes');
        Observer.Expect('unfiltered sum of Line Total', '35');
        Observer.Expect('unfiltered count', '3');
        Observer.Expect('entries 1..2 ok', 'Yes');
        Observer.Expect('entries 1..2|text', '');
        Observer.Expect('entries 1..2|code', '');
        Observer.Expect('entries 1..2 sum of Line Total', '35');
        Observer.Expect('entries 1..2 count', '2');
        Observer.Expect('entry 3 ok', 'Yes');
        Observer.Expect('entry 3|text', '');
        Observer.Expect('entry 3|code', '');
        Observer.Expect('entry 3 sum of Line Total', '0');
        Observer.Expect('entry 3 count', '1');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryDrainFlowGrouped(var Result: Text)
    var
        Q: Query "W7 Q Flow Method Grouped";
    begin
        Q.Open();
        while Q.Read() do
            Result += Format(Q.RowEntry) + '=' + Format(Q.SumTotal, 0, 9) + ' ';
    end;

    [Test]
    procedure MethodOverAFlowField_GroupedByTheRow()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        SeedFlow();
        Observer.Observe('ok', Format(TryDrainFlowGrouped(Result)));
        Observer.ObserveError('grouped');
        Observer.Observe('rows', Result);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('grouped|text', '');
        Observer.Expect('grouped|code', '');
        Observer.Expect('rows', '1=30 2=5 3=0 ');
        Observer.Verify();
    end;

    local procedure SeedGroups()
    var
        Seed: Codeunit "W7 Q Seed";
    begin
        Seed.Clear();
        Seed.Row(1, 1, 'x', 0, 'B');
        Seed.Row(2, 2, 'y', 0, 'A');
        Seed.Row(3, 4, 'x', 0, 'C');
        Seed.Row(4, 8, 'y', 0, 'A');
        Seed.Row(5, 16, 'x', 0, 'B');
        Seed.Row(6, 32, 'y', 0, 'C');
    end;

    [Test]
    procedure Groups_NoOrderBy_TiedCounts()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "W7 Q Groups";
        Result: Text;
    begin
        SeedGroups();
        Q.Open();
        while Q.Read() do
            Result += Q.Grp + ':' + Format(Q.Cnt) + ':' + Format(Q.SumInt) + ' ';
        Q.Close();
        Observer.Observe('groups in the order read', Result);
        Observer.Expect('groups in the order read', 'A:2:10 B:2:17 C:2:36 ');
        Observer.Verify();
    end;

    [Test]
    procedure Groups_NoOrderBy_TwoGroupingColumns()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "W7 Q Groups Two";
        Result: Text;
    begin
        SeedGroups();
        Q.Open();
        while Q.Read() do
            Result += Q.Grp + '/' + Q.Txt + ':' + Format(Q.Cnt) + ' ';
        Q.Close();
        Observer.Observe('groups in the order read', Result);
        Observer.Expect('groups in the order read', 'A/y:2 B/x:2 C/x:1 C/y:1 ');
        Observer.Verify();
    end;

    [Test]
    procedure Groups_NoOrderBy_RowsInsertedInAnotherOrder()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "W7 Q Seed";
        Q: Query "W7 Q Groups";
        Result: Text;
    begin
        Seed.Clear();
        Seed.Row(1, 1, '', 0, 'Z');
        Seed.Row(2, 1, '', 0, 'M');
        Seed.Row(3, 1, '', 0, 'M');
        Seed.Row(4, 1, '', 0, 'A');
        Seed.Row(5, 1, '', 0, 'A');
        Seed.Row(6, 1, '', 0, 'A');
        Q.Open();
        while Q.Read() do
            Result += Q.Grp + ':' + Format(Q.Cnt) + ' ';
        Q.Close();
        Observer.Observe('groups in the order read', Result);
        Observer.Expect('groups in the order read', 'A:3 M:2 Z:1 ');
        Observer.Verify();
    end;

    local procedure SeedCross()
    var
        Seed: Codeunit "W7 Q Seed";
    begin
        Seed.Clear();
        Seed.Row(1, 0, '', 0, 'B');
        Seed.Row(2, 0, '', 0, 'A');
        Seed.Row(3, 0, '', 0, 'C');
        Seed.Row(4, 0, '', 0, 'A');
        Seed.Line(5, 1, 1);
        Seed.Line(2, 1, 2);
        Seed.Line(9, 1, 4);
    end;

    [TryFunction]
    local procedure TryDrainCrossOuter(var Result: Text)
    var
        Q: Query "W7 Q Cross Group Outer";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.Grp + '=' + Format(Q.LineSum, 0, 9) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainCrossInner(var Result: Text)
    var
        Q: Query "W7 Q Cross Group Inner";
    begin
        Q.Open();
        while Q.Read() do
            Result += Format(Q.LineNo) + '=' + Format(Q.RowCount) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainCrossBoth(var Result: Text)
    var
        Q: Query "W7 Q Cross Group Both";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.Grp + '/' + Format(Q.LineNo) + '=' + Format(Q.Cnt) + ' ';
    end;

    [Test]
    procedure CrossJoin_GroupedByTheOuterNonKeyColumn()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        SeedCross();
        Observer.Observe('ok', Format(TryDrainCrossOuter(Result)));
        Observer.ObserveError('outer');
        Observer.Observe('groups in the order read', Result);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('outer|text', '');
        Observer.Expect('outer|code', '');
        Observer.Expect('groups in the order read', 'A=14 B=7 C=7 ');
        Observer.Verify();
    end;

    [Test]
    procedure CrossJoin_GroupedByTheInnerKey()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        SeedCross();
        Observer.Observe('ok', Format(TryDrainCrossInner(Result)));
        Observer.ObserveError('inner');
        Observer.Observe('groups in the order read', Result);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('inner|text', '');
        Observer.Expect('inner|code', '');
        Observer.Expect('groups in the order read', '2=4 5=4 9=4 ');
        Observer.Verify();
    end;

    [Test]
    procedure CrossJoin_GroupedByOuterAndInnerColumns()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        SeedCross();
        Observer.Observe('ok', Format(TryDrainCrossBoth(Result)));
        Observer.ObserveError('both');
        Observer.Observe('groups in the order read', Result);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('both|text', '');
        Observer.Expect('both|code', '');
        Observer.Expect('groups in the order read', 'A/2=2 A/5=2 A/9=2 B/2=1 B/5=1 B/9=1 C/2=1 C/5=1 C/9=1 ');
        Observer.Verify();
    end;
}
