// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 95710-95713 and codeunit 95718 "QOF Seed" (queries/flowfields-filters/QueryOuterFlowKinds.al),
//   own queries 95719-95723, test codeunit 95725
// local object: the FlowField kinds (Sum, Count, Exist, Lookup, ...) and the FlowFilter of a joined table are the subject of the probe; no shared fixture has them
// Probe: written for al-runner issues 6990 and 6991 (follow-ups to 6174); every literal asserted below is what BC 29.0 produced in corpus CI run 41943930008; 27.5 and 28.5 are checked by the CI matrix.
// Facts: a filter() element over a FlowField (Count, Lookup, Exist) of the JOINED data item, LeftOuterJoin and InnerJoin: ColumnName,
//   SetFilter / SetRange on it, and which rows come back (a parent without a child included); a filter() element over the FlowFilter
//   field that the CalcFormula of a FlowField column uses, on a left-outer-joined child: with plain FlowField columns, and with Method =
//   Sum columns over the FlowFields grouped by the parent (the shape of Base Application query 1319 "Sales by Cust. Grp. Chart Mgt.",
//   whose child data item has no SqlJoinType), and the InnerJoin control.
//   Rows: parents 1 (children 10, 11), 2 (no child), 3 (child 30 without details), 4 (child 40); child 50 has no parent.
//   Details: 10 -> 5 (day 1), 7.25 (day 2); 11 -> 1 (day 1); 40 -> -3 (day 2), 4 (day 1). Child Cnt and Total count and sum the days in "Day Filter".
//   Measured: a parent without a child meets a filter() element over a FlowField of the outer-joined child with the field's
//   default (Count 0, Lookup blank, Exist false): SetRange(FCnt, 0), SetRange(FRef, '') and SetRange(FHas, false) keep it. A FlowFilter
//   filter() element sets the flow filter of the FlowFields of its data item and never drops a row; a parent without a child gives
//   0 in a Method = Sum column.
// BC versions: 27, 28, 29 (by CI)

query 95719 "QOF Outer Filter Elem"
{
    QueryType = Normal;
    OrderBy = ascending(PId), ascending(CId);

    elements
    {
        dataitem(Parent; "QOF Parent")
        {
            column(PId; Id) { }

            dataitem(Child; "QOF Child")
            {
                DataItemLink = ParentId = Parent.Id;
                SqlJoinType = LeftOuterJoin;
                column(CId; Id) { }
                filter(FCnt; Cnt) { }
                filter(FRef; RefName) { }
                filter(FHas; HasDetail) { }
                filter(DayF; "Day Filter") { }
            }
        }
    }
}

query 95720 "QOF Inner Filter Elem"
{
    QueryType = Normal;
    OrderBy = ascending(PId), ascending(CId);

    elements
    {
        dataitem(Parent; "QOF Parent")
        {
            column(PId; Id) { }

            dataitem(Child; "QOF Child")
            {
                DataItemLink = ParentId = Parent.Id;
                SqlJoinType = InnerJoin;
                column(CId; Id) { }
                filter(FCnt; Cnt) { }
                filter(FRef; RefName) { }
                filter(FHas; HasDetail) { }
                filter(DayF; "Day Filter") { }
            }
        }
    }
}

query 95721 "QOF Outer FlowFilter"
{
    QueryType = Normal;
    OrderBy = ascending(PId), ascending(CId);

    elements
    {
        dataitem(Parent; "QOF Parent")
        {
            column(PId; Id) { }

            dataitem(Child; "QOF Child")
            {
                DataItemLink = ParentId = Parent.Id;
                SqlJoinType = LeftOuterJoin;
                filter(DayF; "Day Filter") { }
                column(CId; Id) { }
                column(Total; Total) { }
                column(Cnt; Cnt) { }
            }
        }
    }
}

query 95722 "QOF Outer FlowFilter Sum"
{
    QueryType = Normal;
    OrderBy = ascending(PId);

    elements
    {
        dataitem(Parent; "QOF Parent")
        {
            column(PId; Id) { }

            dataitem(Child; "QOF Child")
            {
                DataItemLink = ParentId = Parent.Id;
                filter(DayF; "Day Filter") { }
                column(SumTotal; Total) { Method = Sum; }
                column(SumCnt; Cnt) { Method = Sum; }
            }
        }
    }
}

query 95723 "QOF Inner FlowFilter Sum"
{
    QueryType = Normal;
    OrderBy = ascending(PId);

    elements
    {
        dataitem(Parent; "QOF Parent")
        {
            column(PId; Id) { }

            dataitem(Child; "QOF Child")
            {
                DataItemLink = ParentId = Parent.Id;
                SqlJoinType = InnerJoin;
                filter(DayF; "Day Filter") { }
                column(SumTotal; Total) { Method = Sum; }
                column(SumCnt; Cnt) { Method = Sum; }
            }
        }
    }
}

codeunit 95725 "QOF Outer Flow Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Err(): Text
    var
        Result: Text;
    begin
        Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure ReadOuterElem(var Q: Query "QOF Outer Filter Elem"; var Rows: Text)
    begin
        Rows := '';
        Q.Open();
        while Q.Read() do
            Rows += Format(Q.PId) + ':' + Format(Q.CId) + ' ';
        Q.Close();
    end;

    [TryFunction]
    local procedure ReadInnerElem(var Q: Query "QOF Inner Filter Elem"; var Rows: Text)
    begin
        Rows := '';
        Q.Open();
        while Q.Read() do
            Rows += Format(Q.PId) + ':' + Format(Q.CId) + ' ';
        Q.Close();
    end;

    [TryFunction]
    local procedure ReadOuterFlowFilter(var Q: Query "QOF Outer FlowFilter"; var Rows: Text)
    begin
        Rows := '';
        Q.Open();
        while Q.Read() do
            Rows += Format(Q.PId) + ':' + Format(Q.CId) + '=' + Format(Q.Total, 0, 9) + '/' + Format(Q.Cnt) + ' ';
        Q.Close();
    end;

    [TryFunction]
    local procedure ReadOuterSum(var Q: Query "QOF Outer FlowFilter Sum"; var Rows: Text)
    begin
        Rows := '';
        Q.Open();
        while Q.Read() do
            Rows += Format(Q.PId) + '=' + Format(Q.SumTotal, 0, 9) + '/' + Format(Q.SumCnt) + ' ';
        Q.Close();
    end;

    [TryFunction]
    local procedure ReadInnerSum(var Q: Query "QOF Inner FlowFilter Sum"; var Rows: Text)
    begin
        Rows := '';
        Q.Open();
        while Q.Read() do
            Rows += Format(Q.PId) + '=' + Format(Q.SumTotal, 0, 9) + '/' + Format(Q.SumCnt) + ' ';
        Q.Close();
    end;

    [Test]
    procedure OuterFilterElem_ColumnName()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "QOF Outer Filter Elem";
    begin
        Observer.Observe('FCnt', Q.ColumnName(Q.FCnt));
        Observer.Observe('FRef', Q.ColumnName(Q.FRef));
        Observer.Observe('FHas', Q.ColumnName(Q.FHas));
        Observer.Observe('DayF', Q.ColumnName(Q.DayF));
        Observer.Expect('FCnt', 'FCnt');
        Observer.Expect('FRef', 'FRef');
        Observer.Expect('FHas', 'FHas');
        Observer.Expect('DayF', 'DayF');
        Observer.Verify();
    end;

    [Test]
    procedure OuterFilterElem_Count_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Seeder: Codeunit "QOF Seed";
        Q: Query "QOF Outer Filter Elem";
        Rows: Text;
    begin
        Seeder.Seed();
        if ReadOuterElem(Q, Rows) then
            Observer.Observe('no filter', Rows)
        else
            Observer.Observe('no filter', Err());
        Clear(Q);
        Q.SetFilter(FCnt, '>0');
        if ReadOuterElem(Q, Rows) then
            Observer.Observe('FCnt >0', Rows)
        else
            Observer.Observe('FCnt >0', Err());
        Clear(Q);
        Q.SetRange(FCnt, 0);
        if ReadOuterElem(Q, Rows) then
            Observer.Observe('FCnt 0', Rows)
        else
            Observer.Observe('FCnt 0', Err());
        Clear(Q);
        Q.SetRange(FCnt, 2);
        if ReadOuterElem(Q, Rows) then
            Observer.Observe('FCnt 2', Rows)
        else
            Observer.Observe('FCnt 2', Err());
        Clear(Q);
        Q.SetRange(DayF, 1);
        Q.SetRange(FCnt, 1);
        if ReadOuterElem(Q, Rows) then
            Observer.Observe('DayF 1 FCnt 1', Rows)
        else
            Observer.Observe('DayF 1 FCnt 1', Err());
        Observer.Expect('no filter', '1:10 1:11 2:0 3:30 4:40 ');
        Observer.Expect('FCnt >0', '1:10 1:11 4:40 ');
        Observer.Expect('FCnt 0', '2:0 3:30 ');
        Observer.Expect('FCnt 2', '1:10 4:40 ');
        Observer.Expect('DayF 1 FCnt 1', '1:10 1:11 4:40 ');
        Observer.Verify();
    end;

    [Test]
    procedure OuterFilterElem_LookupExist_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Seeder: Codeunit "QOF Seed";
        Q: Query "QOF Outer Filter Elem";
        Rows: Text;
    begin
        Seeder.Seed();
        Q.SetFilter(FRef, 'Ref*');
        if ReadOuterElem(Q, Rows) then
            Observer.Observe('FRef Ref*', Rows)
        else
            Observer.Observe('FRef Ref*', Err());
        Clear(Q);
        Q.SetRange(FRef, '');
        if ReadOuterElem(Q, Rows) then
            Observer.Observe('FRef blank', Rows)
        else
            Observer.Observe('FRef blank', Err());
        Clear(Q);
        Q.SetRange(FHas, true);
        if ReadOuterElem(Q, Rows) then
            Observer.Observe('FHas true', Rows)
        else
            Observer.Observe('FHas true', Err());
        Clear(Q);
        Q.SetRange(FHas, false);
        if ReadOuterElem(Q, Rows) then
            Observer.Observe('FHas false', Rows)
        else
            Observer.Observe('FHas false', Err());
        Observer.Expect('FRef Ref*', '1:10 3:30 ');
        Observer.Expect('FRef blank', '1:11 2:0 4:40 ');
        Observer.Expect('FHas true', '1:10 1:11 4:40 ');
        Observer.Expect('FHas false', '2:0 3:30 ');
        Observer.Verify();
    end;

    [Test]
    procedure InnerFilterElem_CountLookupExist_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Seeder: Codeunit "QOF Seed";
        Q: Query "QOF Inner Filter Elem";
        Rows: Text;
    begin
        Seeder.Seed();
        if ReadInnerElem(Q, Rows) then
            Observer.Observe('no filter', Rows)
        else
            Observer.Observe('no filter', Err());
        Clear(Q);
        Q.SetRange(FCnt, 0);
        if ReadInnerElem(Q, Rows) then
            Observer.Observe('FCnt 0', Rows)
        else
            Observer.Observe('FCnt 0', Err());
        Clear(Q);
        Q.SetRange(DayF, 1);
        Q.SetRange(FCnt, 1);
        if ReadInnerElem(Q, Rows) then
            Observer.Observe('DayF 1 FCnt 1', Rows)
        else
            Observer.Observe('DayF 1 FCnt 1', Err());
        Clear(Q);
        Q.SetRange(FRef, '');
        if ReadInnerElem(Q, Rows) then
            Observer.Observe('FRef blank', Rows)
        else
            Observer.Observe('FRef blank', Err());
        Clear(Q);
        Q.SetRange(FHas, false);
        if ReadInnerElem(Q, Rows) then
            Observer.Observe('FHas false', Rows)
        else
            Observer.Observe('FHas false', Err());
        Observer.Expect('no filter', '1:10 1:11 3:30 4:40 ');
        Observer.Expect('FCnt 0', '3:30 ');
        Observer.Expect('DayF 1 FCnt 1', '1:10 1:11 4:40 ');
        Observer.Expect('FRef blank', '1:11 4:40 ');
        Observer.Expect('FHas false', '3:30 ');
        Observer.Verify();
    end;

    [Test]
    procedure OuterFlowFilter_PlainColumns_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Seeder: Codeunit "QOF Seed";
        Q: Query "QOF Outer FlowFilter";
        Rows: Text;
    begin
        Seeder.Seed();
        if ReadOuterFlowFilter(Q, Rows) then
            Observer.Observe('no filter', Rows)
        else
            Observer.Observe('no filter', Err());
        Clear(Q);
        Q.SetRange(DayF, 1);
        if ReadOuterFlowFilter(Q, Rows) then
            Observer.Observe('day 1', Rows)
        else
            Observer.Observe('day 1', Err());
        Clear(Q);
        Q.SetRange(DayF, 2, 3);
        if ReadOuterFlowFilter(Q, Rows) then
            Observer.Observe('day 2..3', Rows)
        else
            Observer.Observe('day 2..3', Err());
        Clear(Q);
        Q.SetRange(DayF, 9);
        if ReadOuterFlowFilter(Q, Rows) then
            Observer.Observe('day 9', Rows)
        else
            Observer.Observe('day 9', Err());
        Observer.Expect('no filter', '1:10=12.25/2 1:11=1/1 2:0=0/0 3:30=0/0 4:40=1/2 ');
        Observer.Expect('day 1', '1:10=5/1 1:11=1/1 2:0=0/0 3:30=0/0 4:40=4/1 ');
        Observer.Expect('day 2..3', '1:10=7.25/1 1:11=0/0 2:0=0/0 3:30=0/0 4:40=-3/1 ');
        Observer.Expect('day 9', '1:10=0/0 1:11=0/0 2:0=0/0 3:30=0/0 4:40=0/0 ');
        Observer.Verify();
    end;

    [Test]
    procedure OuterFlowFilter_SumColumns_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Seeder: Codeunit "QOF Seed";
        Q: Query "QOF Outer FlowFilter Sum";
        Rows: Text;
    begin
        Seeder.Seed();
        if ReadOuterSum(Q, Rows) then
            Observer.Observe('no filter', Rows)
        else
            Observer.Observe('no filter', Err());
        Clear(Q);
        Q.SetRange(DayF, 1);
        if ReadOuterSum(Q, Rows) then
            Observer.Observe('day 1', Rows)
        else
            Observer.Observe('day 1', Err());
        Clear(Q);
        Q.SetRange(DayF, 2, 3);
        if ReadOuterSum(Q, Rows) then
            Observer.Observe('day 2..3', Rows)
        else
            Observer.Observe('day 2..3', Err());
        Clear(Q);
        Q.SetRange(DayF, 9);
        if ReadOuterSum(Q, Rows) then
            Observer.Observe('day 9', Rows)
        else
            Observer.Observe('day 9', Err());
        Observer.Expect('no filter', '1=13.25/3 2=0/0 3=0/0 4=1/2 ');
        Observer.Expect('day 1', '1=6/2 2=0/0 3=0/0 4=4/1 ');
        Observer.Expect('day 2..3', '1=7.25/1 2=0/0 3=0/0 4=-3/1 ');
        Observer.Expect('day 9', '1=0/0 2=0/0 3=0/0 4=0/0 ');
        Observer.Verify();
    end;

    [Test]
    procedure InnerFlowFilter_SumColumns_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Seeder: Codeunit "QOF Seed";
        Q: Query "QOF Inner FlowFilter Sum";
        Rows: Text;
    begin
        Seeder.Seed();
        if ReadInnerSum(Q, Rows) then
            Observer.Observe('no filter', Rows)
        else
            Observer.Observe('no filter', Err());
        Clear(Q);
        Q.SetRange(DayF, 1);
        if ReadInnerSum(Q, Rows) then
            Observer.Observe('day 1', Rows)
        else
            Observer.Observe('day 1', Err());
        Clear(Q);
        Q.SetRange(DayF, 9);
        if ReadInnerSum(Q, Rows) then
            Observer.Observe('day 9', Rows)
        else
            Observer.Observe('day 9', Err());
        Observer.Expect('no filter', '1=13.25/3 3=0/0 4=1/2 ');
        Observer.Expect('day 1', '1=6/2 3=0/0 4=4/1 ');
        Observer.Expect('day 9', '1=0/0 3=0/0 4=0/0 ');
        Observer.Verify();
    end;
}
