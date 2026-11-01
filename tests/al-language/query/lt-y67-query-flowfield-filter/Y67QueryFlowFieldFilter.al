// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 93636-93637, queries 93638-93643, codeunit 93644 (writer Y67, gap cycle 6 follow-up)
// Probe: a query filter() element over a FlowField (static ColumnFilter and run time SetFilter / SetRange) and over a FlowFilter field, in
//   queries with a join and with a Method column (Sum, Count): the FlowField's data item is the root with a joined item that sums; the
//   FlowField's data item is the JOINED one and the root sums; a FlowField column and a Count column beside the filter; a left outer join;
//   a FlowFilter field filter element on the joined item that narrows a FlowField column of that item. The single data item without a
//   Method column is pinned by query/lt-cg-query-leads/CgQueryLeads.al:759,792; the FlowField column and flow-filtered columns by
//   query/TestQueryFlowFieldColumn.al.
//   Rows: H1 (lines 10, 20), H2 (line 5), H3 (no line), H4 (lines 7 and -7: sum 0), line days 1 and 2.
// BC versions: 27, 28, 29

table 93636 "LT Y67 QF Hdr"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; LineCount; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT Y67 QF Line" where("Hdr No." = field("No."), "Day" = field("Day Filter")));
        }
        field(4; LineSum; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT Y67 QF Line".Amount where("Hdr No." = field("No.")));
        }
        field(5; "Day Filter"; Integer) { FieldClass = FlowFilter; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 93637 "LT Y67 QF Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Hdr No."; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; Amount; Decimal) { }
        field(4; "Day"; Integer) { }
    }

    keys
    {
        key(PK; "Hdr No.", "Line No.") { Clustered = true; }
    }
}

query 93638 "LT Y67 QF Root Sum"
{
    QueryType = Normal;

    elements
    {
        dataitem(H; "LT Y67 QF Hdr")
        {
            column(No; "No.") { }
            filter(LineSum; LineSum) { ColumnFilter = LineSum = filter(<> 0); }
            dataitem(L; "LT Y67 QF Line")
            {
                DataItemLink = "Hdr No." = H."No.";
                SqlJoinType = InnerJoin;
                column(Total; Amount) { Method = Sum; }
            }
        }
    }
}

query 93639 "LT Y67 QF Joined Filter"
{
    QueryType = Normal;

    elements
    {
        dataitem(L; "LT Y67 QF Line")
        {
            column(HdrNo; "Hdr No.") { }
            column(Total; Amount) { Method = Sum; }
            dataitem(H; "LT Y67 QF Hdr")
            {
                DataItemLink = "No." = L."Hdr No.";
                SqlJoinType = InnerJoin;
                filter(LineSum; LineSum) { ColumnFilter = LineSum = filter(<> 0); }
            }
        }
    }
}

query 93640 "LT Y67 QF Joined Open"
{
    QueryType = Normal;

    elements
    {
        dataitem(L; "LT Y67 QF Line")
        {
            column(HdrNo; "Hdr No.") { }
            column(Total; Amount) { Method = Sum; }
            dataitem(H; "LT Y67 QF Hdr")
            {
                DataItemLink = "No." = L."Hdr No.";
                SqlJoinType = InnerJoin;
                filter(LineSum; LineSum) { }
                column(Cnt; LineCount) { }
            }
        }
    }
}

query 93641 "LT Y67 QF Single Method"
{
    QueryType = Normal;

    elements
    {
        dataitem(H; "LT Y67 QF Hdr")
        {
            column(Rows) { Method = Count; }
            filter(LineSum; LineSum) { ColumnFilter = LineSum = filter(<> 0); }
        }
    }
}

query 93642 "LT Y67 QF Left Outer"
{
    QueryType = Normal;

    elements
    {
        dataitem(H; "LT Y67 QF Hdr")
        {
            column(No; "No.") { }
            filter(LineSum; LineSum) { ColumnFilter = LineSum = filter(<> 0); }
            dataitem(L; "LT Y67 QF Line")
            {
                DataItemLink = "Hdr No." = H."No.";
                SqlJoinType = LeftOuterJoin;
                column(Total; Amount) { Method = Sum; }
            }
        }
    }
}

query 93643 "LT Y67 QF Joined Flowfilter"
{
    QueryType = Normal;

    elements
    {
        dataitem(L; "LT Y67 QF Line")
        {
            column(HdrNo; "Hdr No.") { }
            column(Total; Amount) { Method = Sum; }
            dataitem(H; "LT Y67 QF Hdr")
            {
                DataItemLink = "No." = L."Hdr No.";
                SqlJoinType = InnerJoin;
                filter(DayFilter; "Day Filter") { }
                column(DayCount; LineCount) { }
            }
        }
    }
}

codeunit 93644 "LT Y67 QF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Hdr: Record "LT Y67 QF Hdr";
        Line: Record "LT Y67 QF Line";
    begin
        Hdr.DeleteAll();
        Line.DeleteAll();
        AddHdr('H1');
        AddHdr('H2');
        AddHdr('H3');
        AddHdr('H4');
        AddLine('H1', 1, 10, 1);
        AddLine('H1', 2, 20, 2);
        AddLine('H2', 1, 5, 1);
        AddLine('H4', 1, 7, 1);
        AddLine('H4', 2, -7, 2);
    end;

    local procedure AddHdr(No: Code[10])
    var
        Hdr: Record "LT Y67 QF Hdr";
    begin
        Hdr."No." := No;
        Hdr.Name := 'name ' + No;
        Hdr.Insert();
    end;

    local procedure AddLine(HdrNo: Code[10]; LineNo: Integer; Amount: Decimal; Day: Integer)
    var
        Line: Record "LT Y67 QF Line";
    begin
        Line."Hdr No." := HdrNo;
        Line."Line No." := LineNo;
        Line.Amount := Amount;
        Line."Day" := Day;
        Line.Insert();
    end;

    local procedure Err(): Text
    var
        Result: Text;
    begin
        Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure ReadRootSum(var Q: Query "LT Y67 QF Root Sum"; var Rows: Text)
    begin
        Rows := '';
        Q.Open();
        while Q.Read() do
            Rows += Q.No + '=' + Format(Q.Total, 0, 9) + ' ';
        Q.Close();
    end;

    [TryFunction]
    local procedure ReadJoinedFilter(var Q: Query "LT Y67 QF Joined Filter"; var Rows: Text)
    begin
        Rows := '';
        Q.Open();
        while Q.Read() do
            Rows += Q.HdrNo + '=' + Format(Q.Total, 0, 9) + ' ';
        Q.Close();
    end;

    [TryFunction]
    local procedure ReadJoinedOpen(var Q: Query "LT Y67 QF Joined Open"; var Rows: Text)
    begin
        Rows := '';
        Q.Open();
        while Q.Read() do
            Rows += Q.HdrNo + '=' + Format(Q.Total, 0, 9) + '/' + Format(Q.Cnt) + ' ';
        Q.Close();
    end;

    [TryFunction]
    local procedure ReadSingle(var Q: Query "LT Y67 QF Single Method"; var Rows: Text)
    begin
        Rows := '';
        Q.Open();
        while Q.Read() do
            Rows += Format(Q.Rows) + ' ';
        Q.Close();
    end;

    [TryFunction]
    local procedure ReadLeft(var Q: Query "LT Y67 QF Left Outer"; var Rows: Text)
    begin
        Rows := '';
        Q.Open();
        while Q.Read() do
            Rows += Q.No + '=' + Format(Q.Total, 0, 9) + ' ';
        Q.Close();
    end;

    [TryFunction]
    local procedure ReadFlowFilter(var Q: Query "LT Y67 QF Joined Flowfilter"; var Rows: Text)
    begin
        Rows := '';
        Q.Open();
        while Q.Read() do
            Rows += Q.HdrNo + '=' + Format(Q.Total, 0, 9) + '/' + Format(Q.DayCount) + ' ';
        Q.Close();
    end;

    [Test]
    procedure FlowFieldFilter_Root_JoinedSum()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT Y67 QF Root Sum";
        Rows: Text;
    begin
        Seed();
        ClearLastError();
        if ReadRootSum(Q, Rows) then
            Observer.Observe('static <> 0', Rows)
        else
            Observer.Observe('static <> 0', Err());
        Clear(Q);
        Q.SetFilter(LineSum, '>15');
        if ReadRootSum(Q, Rows) then
            Observer.Observe('SetFilter >15', Rows)
        else
            Observer.Observe('SetFilter >15', Err());
        Clear(Q);
        Q.SetRange(LineSum, 5);
        if ReadRootSum(Q, Rows) then
            Observer.Observe('SetRange 5', Rows)
        else
            Observer.Observe('SetRange 5', Err());
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldFilter_Joined_RootSum()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT Y67 QF Joined Filter";
        Rows: Text;
    begin
        Seed();
        ClearLastError();
        if ReadJoinedFilter(Q, Rows) then
            Observer.Observe('static <> 0', Rows)
        else
            Observer.Observe('static <> 0', Err());
        Clear(Q);
        Q.SetFilter(LineSum, '>15');
        if ReadJoinedFilter(Q, Rows) then
            Observer.Observe('SetFilter >15 over static', Rows)
        else
            Observer.Observe('SetFilter >15 over static', Err());
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldFilter_Joined_RunTimeOnly()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT Y67 QF Joined Open";
        Rows: Text;
    begin
        Seed();
        ClearLastError();
        if ReadJoinedOpen(Q, Rows) then
            Observer.Observe('no filter', Rows)
        else
            Observer.Observe('no filter', Err());
        Clear(Q);
        Q.SetFilter(LineSum, '>15');
        if ReadJoinedOpen(Q, Rows) then
            Observer.Observe('SetFilter >15', Rows)
        else
            Observer.Observe('SetFilter >15', Err());
        Clear(Q);
        Q.SetRange(LineSum, 0);
        if ReadJoinedOpen(Q, Rows) then
            Observer.Observe('SetRange 0', Rows)
        else
            Observer.Observe('SetRange 0', Err());
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldFilter_SingleItem_CountColumn()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT Y67 QF Single Method";
        Rows: Text;
    begin
        Seed();
        ClearLastError();
        if ReadSingle(Q, Rows) then
            Observer.Observe('static <> 0', Rows)
        else
            Observer.Observe('static <> 0', Err());
        Clear(Q);
        Q.SetFilter(LineSum, '>6');
        if ReadSingle(Q, Rows) then
            Observer.Observe('SetFilter >6', Rows)
        else
            Observer.Observe('SetFilter >6', Err());
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldFilter_Root_LeftOuterSum()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT Y67 QF Left Outer";
        Rows: Text;
    begin
        Seed();
        ClearLastError();
        if ReadLeft(Q, Rows) then
            Observer.Observe('static <> 0', Rows)
        else
            Observer.Observe('static <> 0', Err());
        Observer.Finish();
    end;

    [Test]
    procedure FlowFilterField_Joined_NarrowsFlowFieldColumn()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT Y67 QF Joined Flowfilter";
        Rows: Text;
    begin
        Seed();
        ClearLastError();
        if ReadFlowFilter(Q, Rows) then
            Observer.Observe('no filter', Rows)
        else
            Observer.Observe('no filter', Err());
        Clear(Q);
        Q.SetRange(DayFilter, 1);
        if ReadFlowFilter(Q, Rows) then
            Observer.Observe('day 1', Rows)
        else
            Observer.Observe('day 1', Err());
        Clear(Q);
        Q.SetRange(DayFilter, 2);
        if ReadFlowFilter(Q, Rows) then
            Observer.Observe('day 2', Rows)
        else
            Observer.Observe('day 2', Err());
        Observer.Finish();
    end;
}
