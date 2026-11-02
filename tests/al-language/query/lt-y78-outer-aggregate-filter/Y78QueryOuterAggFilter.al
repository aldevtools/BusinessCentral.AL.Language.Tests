// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-columnfilter-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 94130 94131, queries 94132 to 94149, test codeunit 94150 (writer Y78)
// Probe: measured on Windows BC 27.5 and 28.5 containers and a BC 29 SaaS sandbox: identical on all three.
// Facts: a static ColumnFilter and a runtime SetFilter / SetRange on an AGGREGATED column (Sum, Average, Min, Max, Count) of a query whose
//   child data item is a LeftOuterJoin, RightOuterJoin or FullOuterJoin, with parents that have no child, a child that has no parent, and
//   groups that total zero: which groups come back and with which aggregate values (AL Runner issue 6675, a Microsoft O365 Activities page).

table 94130 "LT Y78 Par"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[20]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 94131 "LT Y78 Chi"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Entry; Integer) { }
        field(2; ParCode; Code[10]) { }
        field(3; Qty; Decimal) { }
    }

    keys
    {
        key(PK; Entry) { Clustered = true; }
    }
}

query 94132 "LT Y78 Q Left All"
{
    QueryType = Normal;
    OrderBy = ascending(PCode);

    elements
    {
        dataitem(P; "LT Y78 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT Y78 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = LeftOuterJoin;
                column(SumQ; Qty)
                {
                    Method = Sum;
                }
                column(AvgQ; Qty)
                {
                    Method = Average;
                }
                column(MinQ; Qty)
                {
                    Method = Min;
                }
                column(MaxQ; Qty)
                {
                    Method = Max;
                }
                column(CntQ)
                {
                    Method = Count;
                }
            }
        }
    }
}

query 94133 "LT Y78 Q Left Sum"
{
    QueryType = Normal;
    OrderBy = ascending(PCode);

    elements
    {
        dataitem(P; "LT Y78 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT Y78 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = LeftOuterJoin;
                column(SumQ; Qty)
                {
                    Method = Sum;
                    ColumnFilter = SumQ = filter(> 0);
                }
                column(AvgQ; Qty)
                {
                    Method = Average;
                }
                column(MinQ; Qty)
                {
                    Method = Min;
                }
                column(MaxQ; Qty)
                {
                    Method = Max;
                }
                column(CntQ)
                {
                    Method = Count;
                }
            }
        }
    }
}

query 94134 "LT Y78 Q Left Avg"
{
    QueryType = Normal;
    OrderBy = ascending(PCode);

    elements
    {
        dataitem(P; "LT Y78 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT Y78 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = LeftOuterJoin;
                column(SumQ; Qty)
                {
                    Method = Sum;
                }
                column(AvgQ; Qty)
                {
                    Method = Average;
                    ColumnFilter = AvgQ = filter(> 10);
                }
                column(MinQ; Qty)
                {
                    Method = Min;
                }
                column(MaxQ; Qty)
                {
                    Method = Max;
                }
                column(CntQ)
                {
                    Method = Count;
                }
            }
        }
    }
}

query 94135 "LT Y78 Q Left Min"
{
    QueryType = Normal;
    OrderBy = ascending(PCode);

    elements
    {
        dataitem(P; "LT Y78 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT Y78 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = LeftOuterJoin;
                column(SumQ; Qty)
                {
                    Method = Sum;
                }
                column(AvgQ; Qty)
                {
                    Method = Average;
                }
                column(MinQ; Qty)
                {
                    Method = Min;
                    ColumnFilter = MinQ = filter(< 10);
                }
                column(MaxQ; Qty)
                {
                    Method = Max;
                }
                column(CntQ)
                {
                    Method = Count;
                }
            }
        }
    }
}

query 94136 "LT Y78 Q Left Max"
{
    QueryType = Normal;
    OrderBy = ascending(PCode);

    elements
    {
        dataitem(P; "LT Y78 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT Y78 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = LeftOuterJoin;
                column(SumQ; Qty)
                {
                    Method = Sum;
                }
                column(AvgQ; Qty)
                {
                    Method = Average;
                }
                column(MinQ; Qty)
                {
                    Method = Min;
                }
                column(MaxQ; Qty)
                {
                    Method = Max;
                    ColumnFilter = MaxQ = filter(>= 20);
                }
                column(CntQ)
                {
                    Method = Count;
                }
            }
        }
    }
}

query 94137 "LT Y78 Q Left Cnt"
{
    QueryType = Normal;
    OrderBy = ascending(PCode);

    elements
    {
        dataitem(P; "LT Y78 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT Y78 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = LeftOuterJoin;
                column(SumQ; Qty)
                {
                    Method = Sum;
                }
                column(AvgQ; Qty)
                {
                    Method = Average;
                }
                column(MinQ; Qty)
                {
                    Method = Min;
                }
                column(MaxQ; Qty)
                {
                    Method = Max;
                }
                column(CntQ)
                {
                    Method = Count;
                    ColumnFilter = CntQ = filter(0);
                }
            }
        }
    }
}

query 94138 "LT Y78 Q Right All"
{
    QueryType = Normal;
    OrderBy = ascending(PCode);

    elements
    {
        dataitem(P; "LT Y78 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT Y78 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = RightOuterJoin;
                column(SumQ; Qty)
                {
                    Method = Sum;
                }
                column(AvgQ; Qty)
                {
                    Method = Average;
                }
                column(MinQ; Qty)
                {
                    Method = Min;
                }
                column(MaxQ; Qty)
                {
                    Method = Max;
                }
                column(CntQ)
                {
                    Method = Count;
                }
            }
        }
    }
}

query 94139 "LT Y78 Q Right Sum"
{
    QueryType = Normal;
    OrderBy = ascending(PCode);

    elements
    {
        dataitem(P; "LT Y78 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT Y78 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = RightOuterJoin;
                column(SumQ; Qty)
                {
                    Method = Sum;
                    ColumnFilter = SumQ = filter(> 0);
                }
                column(AvgQ; Qty)
                {
                    Method = Average;
                }
                column(MinQ; Qty)
                {
                    Method = Min;
                }
                column(MaxQ; Qty)
                {
                    Method = Max;
                }
                column(CntQ)
                {
                    Method = Count;
                }
            }
        }
    }
}

query 94140 "LT Y78 Q Right Avg"
{
    QueryType = Normal;
    OrderBy = ascending(PCode);

    elements
    {
        dataitem(P; "LT Y78 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT Y78 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = RightOuterJoin;
                column(SumQ; Qty)
                {
                    Method = Sum;
                }
                column(AvgQ; Qty)
                {
                    Method = Average;
                    ColumnFilter = AvgQ = filter(> 10);
                }
                column(MinQ; Qty)
                {
                    Method = Min;
                }
                column(MaxQ; Qty)
                {
                    Method = Max;
                }
                column(CntQ)
                {
                    Method = Count;
                }
            }
        }
    }
}

query 94141 "LT Y78 Q Right Min"
{
    QueryType = Normal;
    OrderBy = ascending(PCode);

    elements
    {
        dataitem(P; "LT Y78 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT Y78 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = RightOuterJoin;
                column(SumQ; Qty)
                {
                    Method = Sum;
                }
                column(AvgQ; Qty)
                {
                    Method = Average;
                }
                column(MinQ; Qty)
                {
                    Method = Min;
                    ColumnFilter = MinQ = filter(< 10);
                }
                column(MaxQ; Qty)
                {
                    Method = Max;
                }
                column(CntQ)
                {
                    Method = Count;
                }
            }
        }
    }
}

query 94142 "LT Y78 Q Right Max"
{
    QueryType = Normal;
    OrderBy = ascending(PCode);

    elements
    {
        dataitem(P; "LT Y78 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT Y78 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = RightOuterJoin;
                column(SumQ; Qty)
                {
                    Method = Sum;
                }
                column(AvgQ; Qty)
                {
                    Method = Average;
                }
                column(MinQ; Qty)
                {
                    Method = Min;
                }
                column(MaxQ; Qty)
                {
                    Method = Max;
                    ColumnFilter = MaxQ = filter(>= 20);
                }
                column(CntQ)
                {
                    Method = Count;
                }
            }
        }
    }
}

query 94143 "LT Y78 Q Right Cnt"
{
    QueryType = Normal;
    OrderBy = ascending(PCode);

    elements
    {
        dataitem(P; "LT Y78 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT Y78 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = RightOuterJoin;
                column(SumQ; Qty)
                {
                    Method = Sum;
                }
                column(AvgQ; Qty)
                {
                    Method = Average;
                }
                column(MinQ; Qty)
                {
                    Method = Min;
                }
                column(MaxQ; Qty)
                {
                    Method = Max;
                }
                column(CntQ)
                {
                    Method = Count;
                    ColumnFilter = CntQ = filter(0);
                }
            }
        }
    }
}

query 94144 "LT Y78 Q Full All"
{
    QueryType = Normal;
    OrderBy = ascending(PCode);

    elements
    {
        dataitem(P; "LT Y78 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT Y78 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = FullOuterJoin;
                column(SumQ; Qty)
                {
                    Method = Sum;
                }
                column(AvgQ; Qty)
                {
                    Method = Average;
                }
                column(MinQ; Qty)
                {
                    Method = Min;
                }
                column(MaxQ; Qty)
                {
                    Method = Max;
                }
                column(CntQ)
                {
                    Method = Count;
                }
            }
        }
    }
}

query 94145 "LT Y78 Q Full Sum"
{
    QueryType = Normal;
    OrderBy = ascending(PCode);

    elements
    {
        dataitem(P; "LT Y78 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT Y78 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = FullOuterJoin;
                column(SumQ; Qty)
                {
                    Method = Sum;
                    ColumnFilter = SumQ = filter(> 0);
                }
                column(AvgQ; Qty)
                {
                    Method = Average;
                }
                column(MinQ; Qty)
                {
                    Method = Min;
                }
                column(MaxQ; Qty)
                {
                    Method = Max;
                }
                column(CntQ)
                {
                    Method = Count;
                }
            }
        }
    }
}

query 94146 "LT Y78 Q Full Avg"
{
    QueryType = Normal;
    OrderBy = ascending(PCode);

    elements
    {
        dataitem(P; "LT Y78 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT Y78 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = FullOuterJoin;
                column(SumQ; Qty)
                {
                    Method = Sum;
                }
                column(AvgQ; Qty)
                {
                    Method = Average;
                    ColumnFilter = AvgQ = filter(> 10);
                }
                column(MinQ; Qty)
                {
                    Method = Min;
                }
                column(MaxQ; Qty)
                {
                    Method = Max;
                }
                column(CntQ)
                {
                    Method = Count;
                }
            }
        }
    }
}

query 94147 "LT Y78 Q Full Min"
{
    QueryType = Normal;
    OrderBy = ascending(PCode);

    elements
    {
        dataitem(P; "LT Y78 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT Y78 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = FullOuterJoin;
                column(SumQ; Qty)
                {
                    Method = Sum;
                }
                column(AvgQ; Qty)
                {
                    Method = Average;
                }
                column(MinQ; Qty)
                {
                    Method = Min;
                    ColumnFilter = MinQ = filter(< 10);
                }
                column(MaxQ; Qty)
                {
                    Method = Max;
                }
                column(CntQ)
                {
                    Method = Count;
                }
            }
        }
    }
}

query 94148 "LT Y78 Q Full Max"
{
    QueryType = Normal;
    OrderBy = ascending(PCode);

    elements
    {
        dataitem(P; "LT Y78 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT Y78 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = FullOuterJoin;
                column(SumQ; Qty)
                {
                    Method = Sum;
                }
                column(AvgQ; Qty)
                {
                    Method = Average;
                }
                column(MinQ; Qty)
                {
                    Method = Min;
                }
                column(MaxQ; Qty)
                {
                    Method = Max;
                    ColumnFilter = MaxQ = filter(>= 20);
                }
                column(CntQ)
                {
                    Method = Count;
                }
            }
        }
    }
}

query 94149 "LT Y78 Q Full Cnt"
{
    QueryType = Normal;
    OrderBy = ascending(PCode);

    elements
    {
        dataitem(P; "LT Y78 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT Y78 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = FullOuterJoin;
                column(SumQ; Qty)
                {
                    Method = Sum;
                }
                column(AvgQ; Qty)
                {
                    Method = Average;
                }
                column(MinQ; Qty)
                {
                    Method = Min;
                }
                column(MaxQ; Qty)
                {
                    Method = Max;
                }
                column(CntQ)
                {
                    Method = Count;
                    ColumnFilter = CntQ = filter(0);
                }
            }
        }
    }
}

codeunit 94150 "LT Y78 Query Agg Outer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Par: Record "LT Y78 Par";
        Chi: Record "LT Y78 Chi";
    begin
        Par.DeleteAll();
        Chi.DeleteAll();
        AddPar('P1');
        AddPar('P2');
        AddPar('P3');
        AddPar('P4');
        AddPar('P5');
        AddChi(1, 'P1', 10);
        AddChi(2, 'P1', 20);
        AddChi(3, 'P2', 30);
        AddChi(4, 'P4', 0);
        AddChi(5, 'P5', 5);
        AddChi(6, 'P5', -5);
        AddChi(7, 'PX', 7);
    end;

    local procedure AddPar(NewCode: Code[10])
    var
        Par: Record "LT Y78 Par";
    begin
        Par."Code" := NewCode;
        Par.Name := NewCode;
        Par.Insert();
    end;

    local procedure AddChi(NewEntry: Integer; NewPar: Code[10]; NewQty: Decimal)
    var
        Chi: Record "LT Y78 Chi";
    begin
        Chi.Entry := NewEntry;
        Chi.ParCode := NewPar;
        Chi.Qty := NewQty;
        Chi.Insert();
    end;

    local procedure DumpLeftAll(var Q: Query "LT Y78 Q Left All"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.PCode + '/' + Format(Q.SumQ) + '/' + Format(Q.AvgQ) + '/' + Format(Q.MinQ) + '/' + Format(Q.MaxQ) + '/' + Format(Q.CntQ) + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpLeftSum(var Q: Query "LT Y78 Q Left Sum"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.PCode + '/' + Format(Q.SumQ) + '/' + Format(Q.AvgQ) + '/' + Format(Q.MinQ) + '/' + Format(Q.MaxQ) + '/' + Format(Q.CntQ) + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpLeftAvg(var Q: Query "LT Y78 Q Left Avg"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.PCode + '/' + Format(Q.SumQ) + '/' + Format(Q.AvgQ) + '/' + Format(Q.MinQ) + '/' + Format(Q.MaxQ) + '/' + Format(Q.CntQ) + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpLeftMin(var Q: Query "LT Y78 Q Left Min"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.PCode + '/' + Format(Q.SumQ) + '/' + Format(Q.AvgQ) + '/' + Format(Q.MinQ) + '/' + Format(Q.MaxQ) + '/' + Format(Q.CntQ) + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpLeftMax(var Q: Query "LT Y78 Q Left Max"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.PCode + '/' + Format(Q.SumQ) + '/' + Format(Q.AvgQ) + '/' + Format(Q.MinQ) + '/' + Format(Q.MaxQ) + '/' + Format(Q.CntQ) + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpLeftCnt(var Q: Query "LT Y78 Q Left Cnt"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.PCode + '/' + Format(Q.SumQ) + '/' + Format(Q.AvgQ) + '/' + Format(Q.MinQ) + '/' + Format(Q.MaxQ) + '/' + Format(Q.CntQ) + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpRightAll(var Q: Query "LT Y78 Q Right All"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.PCode + '/' + Format(Q.SumQ) + '/' + Format(Q.AvgQ) + '/' + Format(Q.MinQ) + '/' + Format(Q.MaxQ) + '/' + Format(Q.CntQ) + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpRightSum(var Q: Query "LT Y78 Q Right Sum"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.PCode + '/' + Format(Q.SumQ) + '/' + Format(Q.AvgQ) + '/' + Format(Q.MinQ) + '/' + Format(Q.MaxQ) + '/' + Format(Q.CntQ) + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpRightAvg(var Q: Query "LT Y78 Q Right Avg"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.PCode + '/' + Format(Q.SumQ) + '/' + Format(Q.AvgQ) + '/' + Format(Q.MinQ) + '/' + Format(Q.MaxQ) + '/' + Format(Q.CntQ) + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpRightMin(var Q: Query "LT Y78 Q Right Min"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.PCode + '/' + Format(Q.SumQ) + '/' + Format(Q.AvgQ) + '/' + Format(Q.MinQ) + '/' + Format(Q.MaxQ) + '/' + Format(Q.CntQ) + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpRightMax(var Q: Query "LT Y78 Q Right Max"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.PCode + '/' + Format(Q.SumQ) + '/' + Format(Q.AvgQ) + '/' + Format(Q.MinQ) + '/' + Format(Q.MaxQ) + '/' + Format(Q.CntQ) + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpRightCnt(var Q: Query "LT Y78 Q Right Cnt"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.PCode + '/' + Format(Q.SumQ) + '/' + Format(Q.AvgQ) + '/' + Format(Q.MinQ) + '/' + Format(Q.MaxQ) + '/' + Format(Q.CntQ) + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpFullAll(var Q: Query "LT Y78 Q Full All"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.PCode + '/' + Format(Q.SumQ) + '/' + Format(Q.AvgQ) + '/' + Format(Q.MinQ) + '/' + Format(Q.MaxQ) + '/' + Format(Q.CntQ) + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpFullSum(var Q: Query "LT Y78 Q Full Sum"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.PCode + '/' + Format(Q.SumQ) + '/' + Format(Q.AvgQ) + '/' + Format(Q.MinQ) + '/' + Format(Q.MaxQ) + '/' + Format(Q.CntQ) + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpFullAvg(var Q: Query "LT Y78 Q Full Avg"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.PCode + '/' + Format(Q.SumQ) + '/' + Format(Q.AvgQ) + '/' + Format(Q.MinQ) + '/' + Format(Q.MaxQ) + '/' + Format(Q.CntQ) + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpFullMin(var Q: Query "LT Y78 Q Full Min"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.PCode + '/' + Format(Q.SumQ) + '/' + Format(Q.AvgQ) + '/' + Format(Q.MinQ) + '/' + Format(Q.MaxQ) + '/' + Format(Q.CntQ) + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpFullMax(var Q: Query "LT Y78 Q Full Max"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.PCode + '/' + Format(Q.SumQ) + '/' + Format(Q.AvgQ) + '/' + Format(Q.MinQ) + '/' + Format(Q.MaxQ) + '/' + Format(Q.CntQ) + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpFullCnt(var Q: Query "LT Y78 Q Full Cnt"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.PCode + '/' + Format(Q.SumQ) + '/' + Format(Q.AvgQ) + '/' + Format(Q.MinQ) + '/' + Format(Q.MaxQ) + '/' + Format(Q.CntQ) + ']';
        Q.Close();
        exit(Result);
    end;

    [Test]
    procedure Y78_Left_RuntimeFilterOnAggregates_A()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT Y78 Q Left All";
    begin
        Seed();
        Clear(Q);
        Observer.Observe('none filters', Q.GetFilters());
        Observer.Observe('none', DumpLeftAll(Q));
        Clear(Q);
        Q.SetFilter(SumQ, '>0');
        Observer.Observe('sum gt0 filters', Q.GetFilters());
        Observer.Observe('sum gt0 SumQ', Q.GetFilter(SumQ));
        Observer.Observe('sum gt0', DumpLeftAll(Q));
        Clear(Q);
        Q.SetRange(SumQ, 0);
        Observer.Observe('sum eq0 filters', Q.GetFilters());
        Observer.Observe('sum eq0 SumQ', Q.GetFilter(SumQ));
        Observer.Observe('sum eq0', DumpLeftAll(Q));
        Clear(Q);
        Q.SetFilter(SumQ, '<>0');
        Observer.Observe('sum ne0 filters', Q.GetFilters());
        Observer.Observe('sum ne0 SumQ', Q.GetFilter(SumQ));
        Observer.Observe('sum ne0', DumpLeftAll(Q));
        Clear(Q);
        Q.SetFilter(SumQ, '');
        Observer.Observe('sum empty filters', Q.GetFilters());
        Observer.Observe('sum empty SumQ', Q.GetFilter(SumQ));
        Observer.Observe('sum empty', DumpLeftAll(Q));
        Clear(Q);
        Q.SetFilter(SumQ, '<0|>=30');
        Observer.Observe('sum or filters', Q.GetFilters());
        Observer.Observe('sum or SumQ', Q.GetFilter(SumQ));
        Observer.Observe('sum or', DumpLeftAll(Q));
        Observer.Expect('none filters', '');
        Observer.Expect('none', '[P1/30/15/10/20/2][P2/30/30/30/30/1][P3/0/0/0/0/0][P4/0/0/0/0/1][P5/0/0/-5/5/2]');
        Observer.Expect('sum gt0 filters', 'SumQ: >0');
        Observer.Expect('sum gt0 SumQ', '>0');
        Observer.Expect('sum gt0', '[P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('sum eq0 filters', 'SumQ: 0');
        Observer.Expect('sum eq0 SumQ', '0');
        Observer.Expect('sum eq0', '[P3/0/0/0/0/0][P4/0/0/0/0/1][P5/0/0/-5/5/2]');
        Observer.Expect('sum ne0 filters', 'SumQ: <>0');
        Observer.Expect('sum ne0 SumQ', '<>0');
        Observer.Expect('sum ne0', '[P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('sum empty filters', '');
        Observer.Expect('sum empty SumQ', '');
        Observer.Expect('sum empty', '[P1/30/15/10/20/2][P2/30/30/30/30/1][P3/0/0/0/0/0][P4/0/0/0/0/1][P5/0/0/-5/5/2]');
        Observer.Expect('sum or filters', 'SumQ: <0|>=30');
        Observer.Expect('sum or SumQ', '<0|>=30');
        Observer.Expect('sum or', '[P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Verify();
    end;

    [Test]
    procedure Y78_Left_RuntimeFilterOnAggregates_B()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT Y78 Q Left All";
    begin
        Seed();
        Clear(Q);
        Q.SetFilter(AvgQ, '>10');
        Observer.Observe('avg gt10 filters', Q.GetFilters());
        Observer.Observe('avg gt10 AvgQ', Q.GetFilter(AvgQ));
        Observer.Observe('avg gt10', DumpLeftAll(Q));
        Clear(Q);
        Q.SetFilter(MinQ, '<10');
        Observer.Observe('min lt10 filters', Q.GetFilters());
        Observer.Observe('min lt10 MinQ', Q.GetFilter(MinQ));
        Observer.Observe('min lt10', DumpLeftAll(Q));
        Clear(Q);
        Q.SetFilter(MaxQ, '>=20');
        Observer.Observe('max ge20 filters', Q.GetFilters());
        Observer.Observe('max ge20 MaxQ', Q.GetFilter(MaxQ));
        Observer.Observe('max ge20', DumpLeftAll(Q));
        Clear(Q);
        Q.SetRange(CntQ, 0);
        Observer.Observe('cnt eq0 filters', Q.GetFilters());
        Observer.Observe('cnt eq0 CntQ', Q.GetFilter(CntQ));
        Observer.Observe('cnt eq0', DumpLeftAll(Q));
        Clear(Q);
        Q.SetFilter(CntQ, '>1');
        Observer.Observe('cnt gt1 filters', Q.GetFilters());
        Observer.Observe('cnt gt1 CntQ', Q.GetFilter(CntQ));
        Observer.Observe('cnt gt1', DumpLeftAll(Q));
        Clear(Q);
        Q.SetFilter(SumQ, '>0');
        Q.SetFilter(CntQ, '>1');
        Observer.Observe('sum gt0 cnt gt1 filters', Q.GetFilters());
        Observer.Observe('sum gt0 cnt gt1 SumQ', Q.GetFilter(SumQ));
        Observer.Observe('sum gt0 cnt gt1 CntQ', Q.GetFilter(CntQ));
        Observer.Observe('sum gt0 cnt gt1', DumpLeftAll(Q));
        Observer.Expect('avg gt10 filters', 'AvgQ: >10');
        Observer.Expect('avg gt10 AvgQ', '>10');
        Observer.Expect('avg gt10', '[P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('min lt10 filters', 'MinQ: <10');
        Observer.Expect('min lt10 MinQ', '<10');
        Observer.Expect('min lt10', '[P3/0/0/0/0/0][P4/0/0/0/0/1][P5/0/0/-5/5/2]');
        Observer.Expect('max ge20 filters', 'MaxQ: >=20');
        Observer.Expect('max ge20 MaxQ', '>=20');
        Observer.Expect('max ge20', '[P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('cnt eq0 filters', 'CntQ: 0');
        Observer.Expect('cnt eq0 CntQ', '0');
        Observer.Expect('cnt eq0', '[P3/0/0/0/0/0]');
        Observer.Expect('cnt gt1 filters', 'CntQ: >1');
        Observer.Expect('cnt gt1 CntQ', '>1');
        Observer.Expect('cnt gt1', '[P1/30/15/10/20/2][P5/0/0/-5/5/2]');
        Observer.Expect('sum gt0 cnt gt1 filters', 'SumQ: >0, CntQ: >1');
        Observer.Expect('sum gt0 cnt gt1 SumQ', '>0');
        Observer.Expect('sum gt0 cnt gt1 CntQ', '>1');
        Observer.Expect('sum gt0 cnt gt1', '[P1/30/15/10/20/2]');
        Observer.Verify();
    end;

    [Test]
    procedure Y78_Right_RuntimeFilterOnAggregates_A()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT Y78 Q Right All";
    begin
        Seed();
        Clear(Q);
        Observer.Observe('none filters', Q.GetFilters());
        Observer.Observe('none', DumpRightAll(Q));
        Clear(Q);
        Q.SetFilter(SumQ, '>0');
        Observer.Observe('sum gt0 filters', Q.GetFilters());
        Observer.Observe('sum gt0 SumQ', Q.GetFilter(SumQ));
        Observer.Observe('sum gt0', DumpRightAll(Q));
        Clear(Q);
        Q.SetRange(SumQ, 0);
        Observer.Observe('sum eq0 filters', Q.GetFilters());
        Observer.Observe('sum eq0 SumQ', Q.GetFilter(SumQ));
        Observer.Observe('sum eq0', DumpRightAll(Q));
        Clear(Q);
        Q.SetFilter(SumQ, '<>0');
        Observer.Observe('sum ne0 filters', Q.GetFilters());
        Observer.Observe('sum ne0 SumQ', Q.GetFilter(SumQ));
        Observer.Observe('sum ne0', DumpRightAll(Q));
        Clear(Q);
        Q.SetFilter(SumQ, '');
        Observer.Observe('sum empty filters', Q.GetFilters());
        Observer.Observe('sum empty SumQ', Q.GetFilter(SumQ));
        Observer.Observe('sum empty', DumpRightAll(Q));
        Clear(Q);
        Q.SetFilter(SumQ, '<0|>=30');
        Observer.Observe('sum or filters', Q.GetFilters());
        Observer.Observe('sum or SumQ', Q.GetFilter(SumQ));
        Observer.Observe('sum or', DumpRightAll(Q));
        Observer.Expect('none filters', '');
        Observer.Expect('none', '[/7/7/7/7/1][P1/30/15/10/20/2][P2/30/30/30/30/1][P4/0/0/0/0/1][P5/0/0/-5/5/2]');
        Observer.Expect('sum gt0 filters', 'SumQ: >0');
        Observer.Expect('sum gt0 SumQ', '>0');
        Observer.Expect('sum gt0', '[/7/7/7/7/1][P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('sum eq0 filters', 'SumQ: 0');
        Observer.Expect('sum eq0 SumQ', '0');
        Observer.Expect('sum eq0', '[P4/0/0/0/0/1][P5/0/0/-5/5/2]');
        Observer.Expect('sum ne0 filters', 'SumQ: <>0');
        Observer.Expect('sum ne0 SumQ', '<>0');
        Observer.Expect('sum ne0', '[/7/7/7/7/1][P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('sum empty filters', '');
        Observer.Expect('sum empty SumQ', '');
        Observer.Expect('sum empty', '[/7/7/7/7/1][P1/30/15/10/20/2][P2/30/30/30/30/1][P4/0/0/0/0/1][P5/0/0/-5/5/2]');
        Observer.Expect('sum or filters', 'SumQ: <0|>=30');
        Observer.Expect('sum or SumQ', '<0|>=30');
        Observer.Expect('sum or', '[P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Verify();
    end;

    [Test]
    procedure Y78_Right_RuntimeFilterOnAggregates_B()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT Y78 Q Right All";
    begin
        Seed();
        Clear(Q);
        Q.SetFilter(AvgQ, '>10');
        Observer.Observe('avg gt10 filters', Q.GetFilters());
        Observer.Observe('avg gt10 AvgQ', Q.GetFilter(AvgQ));
        Observer.Observe('avg gt10', DumpRightAll(Q));
        Clear(Q);
        Q.SetFilter(MinQ, '<10');
        Observer.Observe('min lt10 filters', Q.GetFilters());
        Observer.Observe('min lt10 MinQ', Q.GetFilter(MinQ));
        Observer.Observe('min lt10', DumpRightAll(Q));
        Clear(Q);
        Q.SetFilter(MaxQ, '>=20');
        Observer.Observe('max ge20 filters', Q.GetFilters());
        Observer.Observe('max ge20 MaxQ', Q.GetFilter(MaxQ));
        Observer.Observe('max ge20', DumpRightAll(Q));
        Clear(Q);
        Q.SetRange(CntQ, 0);
        Observer.Observe('cnt eq0 filters', Q.GetFilters());
        Observer.Observe('cnt eq0 CntQ', Q.GetFilter(CntQ));
        Observer.Observe('cnt eq0', DumpRightAll(Q));
        Clear(Q);
        Q.SetFilter(CntQ, '>1');
        Observer.Observe('cnt gt1 filters', Q.GetFilters());
        Observer.Observe('cnt gt1 CntQ', Q.GetFilter(CntQ));
        Observer.Observe('cnt gt1', DumpRightAll(Q));
        Clear(Q);
        Q.SetFilter(SumQ, '>0');
        Q.SetFilter(CntQ, '>1');
        Observer.Observe('sum gt0 cnt gt1 filters', Q.GetFilters());
        Observer.Observe('sum gt0 cnt gt1 SumQ', Q.GetFilter(SumQ));
        Observer.Observe('sum gt0 cnt gt1 CntQ', Q.GetFilter(CntQ));
        Observer.Observe('sum gt0 cnt gt1', DumpRightAll(Q));
        Observer.Expect('avg gt10 filters', 'AvgQ: >10');
        Observer.Expect('avg gt10 AvgQ', '>10');
        Observer.Expect('avg gt10', '[P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('min lt10 filters', 'MinQ: <10');
        Observer.Expect('min lt10 MinQ', '<10');
        Observer.Expect('min lt10', '[/7/7/7/7/1][P4/0/0/0/0/1][P5/0/0/-5/5/2]');
        Observer.Expect('max ge20 filters', 'MaxQ: >=20');
        Observer.Expect('max ge20 MaxQ', '>=20');
        Observer.Expect('max ge20', '[P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('cnt eq0 filters', 'CntQ: 0');
        Observer.Expect('cnt eq0 CntQ', '0');
        Observer.Expect('cnt eq0', '');
        Observer.Expect('cnt gt1 filters', 'CntQ: >1');
        Observer.Expect('cnt gt1 CntQ', '>1');
        Observer.Expect('cnt gt1', '[P1/30/15/10/20/2][P5/0/0/-5/5/2]');
        Observer.Expect('sum gt0 cnt gt1 filters', 'SumQ: >0, CntQ: >1');
        Observer.Expect('sum gt0 cnt gt1 SumQ', '>0');
        Observer.Expect('sum gt0 cnt gt1 CntQ', '>1');
        Observer.Expect('sum gt0 cnt gt1', '[P1/30/15/10/20/2]');
        Observer.Verify();
    end;

    [Test]
    procedure Y78_Full_RuntimeFilterOnAggregates_A()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT Y78 Q Full All";
    begin
        Seed();
        Clear(Q);
        Observer.Observe('none filters', Q.GetFilters());
        Observer.Observe('none', DumpFullAll(Q));
        Clear(Q);
        Q.SetFilter(SumQ, '>0');
        Observer.Observe('sum gt0 filters', Q.GetFilters());
        Observer.Observe('sum gt0 SumQ', Q.GetFilter(SumQ));
        Observer.Observe('sum gt0', DumpFullAll(Q));
        Clear(Q);
        Q.SetRange(SumQ, 0);
        Observer.Observe('sum eq0 filters', Q.GetFilters());
        Observer.Observe('sum eq0 SumQ', Q.GetFilter(SumQ));
        Observer.Observe('sum eq0', DumpFullAll(Q));
        Clear(Q);
        Q.SetFilter(SumQ, '<>0');
        Observer.Observe('sum ne0 filters', Q.GetFilters());
        Observer.Observe('sum ne0 SumQ', Q.GetFilter(SumQ));
        Observer.Observe('sum ne0', DumpFullAll(Q));
        Clear(Q);
        Q.SetFilter(SumQ, '');
        Observer.Observe('sum empty filters', Q.GetFilters());
        Observer.Observe('sum empty SumQ', Q.GetFilter(SumQ));
        Observer.Observe('sum empty', DumpFullAll(Q));
        Clear(Q);
        Q.SetFilter(SumQ, '<0|>=30');
        Observer.Observe('sum or filters', Q.GetFilters());
        Observer.Observe('sum or SumQ', Q.GetFilter(SumQ));
        Observer.Observe('sum or', DumpFullAll(Q));
        Observer.Expect('none filters', '');
        Observer.Expect('none', '[/7/7/7/7/1][P1/30/15/10/20/2][P2/30/30/30/30/1][P3/0/0/0/0/0][P4/0/0/0/0/1][P5/0/0/-5/5/2]');
        Observer.Expect('sum gt0 filters', 'SumQ: >0');
        Observer.Expect('sum gt0 SumQ', '>0');
        Observer.Expect('sum gt0', '[/7/7/7/7/1][P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('sum eq0 filters', 'SumQ: 0');
        Observer.Expect('sum eq0 SumQ', '0');
        Observer.Expect('sum eq0', '[P3/0/0/0/0/0][P4/0/0/0/0/1][P5/0/0/-5/5/2]');
        Observer.Expect('sum ne0 filters', 'SumQ: <>0');
        Observer.Expect('sum ne0 SumQ', '<>0');
        Observer.Expect('sum ne0', '[/7/7/7/7/1][P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('sum empty filters', '');
        Observer.Expect('sum empty SumQ', '');
        Observer.Expect('sum empty', '[/7/7/7/7/1][P1/30/15/10/20/2][P2/30/30/30/30/1][P3/0/0/0/0/0][P4/0/0/0/0/1][P5/0/0/-5/5/2]');
        Observer.Expect('sum or filters', 'SumQ: <0|>=30');
        Observer.Expect('sum or SumQ', '<0|>=30');
        Observer.Expect('sum or', '[P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Verify();
    end;

    [Test]
    procedure Y78_Full_RuntimeFilterOnAggregates_B()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT Y78 Q Full All";
    begin
        Seed();
        Clear(Q);
        Q.SetFilter(AvgQ, '>10');
        Observer.Observe('avg gt10 filters', Q.GetFilters());
        Observer.Observe('avg gt10 AvgQ', Q.GetFilter(AvgQ));
        Observer.Observe('avg gt10', DumpFullAll(Q));
        Clear(Q);
        Q.SetFilter(MinQ, '<10');
        Observer.Observe('min lt10 filters', Q.GetFilters());
        Observer.Observe('min lt10 MinQ', Q.GetFilter(MinQ));
        Observer.Observe('min lt10', DumpFullAll(Q));
        Clear(Q);
        Q.SetFilter(MaxQ, '>=20');
        Observer.Observe('max ge20 filters', Q.GetFilters());
        Observer.Observe('max ge20 MaxQ', Q.GetFilter(MaxQ));
        Observer.Observe('max ge20', DumpFullAll(Q));
        Clear(Q);
        Q.SetRange(CntQ, 0);
        Observer.Observe('cnt eq0 filters', Q.GetFilters());
        Observer.Observe('cnt eq0 CntQ', Q.GetFilter(CntQ));
        Observer.Observe('cnt eq0', DumpFullAll(Q));
        Clear(Q);
        Q.SetFilter(CntQ, '>1');
        Observer.Observe('cnt gt1 filters', Q.GetFilters());
        Observer.Observe('cnt gt1 CntQ', Q.GetFilter(CntQ));
        Observer.Observe('cnt gt1', DumpFullAll(Q));
        Clear(Q);
        Q.SetFilter(SumQ, '>0');
        Q.SetFilter(CntQ, '>1');
        Observer.Observe('sum gt0 cnt gt1 filters', Q.GetFilters());
        Observer.Observe('sum gt0 cnt gt1 SumQ', Q.GetFilter(SumQ));
        Observer.Observe('sum gt0 cnt gt1 CntQ', Q.GetFilter(CntQ));
        Observer.Observe('sum gt0 cnt gt1', DumpFullAll(Q));
        Observer.Expect('avg gt10 filters', 'AvgQ: >10');
        Observer.Expect('avg gt10 AvgQ', '>10');
        Observer.Expect('avg gt10', '[P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('min lt10 filters', 'MinQ: <10');
        Observer.Expect('min lt10 MinQ', '<10');
        Observer.Expect('min lt10', '[/7/7/7/7/1][P3/0/0/0/0/0][P4/0/0/0/0/1][P5/0/0/-5/5/2]');
        Observer.Expect('max ge20 filters', 'MaxQ: >=20');
        Observer.Expect('max ge20 MaxQ', '>=20');
        Observer.Expect('max ge20', '[P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('cnt eq0 filters', 'CntQ: 0');
        Observer.Expect('cnt eq0 CntQ', '0');
        Observer.Expect('cnt eq0', '[P3/0/0/0/0/0]');
        Observer.Expect('cnt gt1 filters', 'CntQ: >1');
        Observer.Expect('cnt gt1 CntQ', '>1');
        Observer.Expect('cnt gt1', '[P1/30/15/10/20/2][P5/0/0/-5/5/2]');
        Observer.Expect('sum gt0 cnt gt1 filters', 'SumQ: >0, CntQ: >1');
        Observer.Expect('sum gt0 cnt gt1 SumQ', '>0');
        Observer.Expect('sum gt0 cnt gt1 CntQ', '>1');
        Observer.Expect('sum gt0 cnt gt1', '[P1/30/15/10/20/2]');
        Observer.Verify();
    end;

    [Test]
    procedure Y78_Left_StaticColumnFilterOnAggregates()
    var
        Observer: Codeunit "Probe Observer";
        QSum: Query "LT Y78 Q Left Sum";
        QAvg: Query "LT Y78 Q Left Avg";
        QMin: Query "LT Y78 Q Left Min";
        QMax: Query "LT Y78 Q Left Max";
        QCnt: Query "LT Y78 Q Left Cnt";
    begin
        Seed();
        Observer.Observe('Sum > 0 filters', QSum.GetFilters());
        Observer.Observe('Sum > 0 filter', QSum.GetFilter(SumQ));
        Observer.Observe('Sum > 0', DumpLeftSum(QSum));
        Observer.Observe('Avg > 10 filters', QAvg.GetFilters());
        Observer.Observe('Avg > 10 filter', QAvg.GetFilter(AvgQ));
        Observer.Observe('Avg > 10', DumpLeftAvg(QAvg));
        Observer.Observe('Min < 10 filters', QMin.GetFilters());
        Observer.Observe('Min < 10 filter', QMin.GetFilter(MinQ));
        Observer.Observe('Min < 10', DumpLeftMin(QMin));
        Observer.Observe('Max >= 20 filters', QMax.GetFilters());
        Observer.Observe('Max >= 20 filter', QMax.GetFilter(MaxQ));
        Observer.Observe('Max >= 20', DumpLeftMax(QMax));
        Observer.Observe('Cnt 0 filters', QCnt.GetFilters());
        Observer.Observe('Cnt 0 filter', QCnt.GetFilter(CntQ));
        Observer.Observe('Cnt 0', DumpLeftCnt(QCnt));
        Observer.Expect('Sum > 0 filters', 'SumQ: >0');
        Observer.Expect('Sum > 0 filter', '>0');
        Observer.Expect('Sum > 0', '[P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('Avg > 10 filters', 'AvgQ: >10');
        Observer.Expect('Avg > 10 filter', '>10');
        Observer.Expect('Avg > 10', '[P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('Min < 10 filters', 'MinQ: <10');
        Observer.Expect('Min < 10 filter', '<10');
        Observer.Expect('Min < 10', '[P3/0/0/0/0/0][P4/0/0/0/0/1][P5/0/0/-5/5/2]');
        Observer.Expect('Max >= 20 filters', 'MaxQ: >=20');
        Observer.Expect('Max >= 20 filter', '>=20');
        Observer.Expect('Max >= 20', '[P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('Cnt 0 filters', 'CntQ: 0');
        Observer.Expect('Cnt 0 filter', '0');
        Observer.Expect('Cnt 0', '[P3/0/0/0/0/0]');
        Observer.Verify();
    end;

    [Test]
    procedure Y78_Right_StaticColumnFilterOnAggregates()
    var
        Observer: Codeunit "Probe Observer";
        QSum: Query "LT Y78 Q Right Sum";
        QAvg: Query "LT Y78 Q Right Avg";
        QMin: Query "LT Y78 Q Right Min";
        QMax: Query "LT Y78 Q Right Max";
        QCnt: Query "LT Y78 Q Right Cnt";
    begin
        Seed();
        Observer.Observe('Sum > 0 filters', QSum.GetFilters());
        Observer.Observe('Sum > 0 filter', QSum.GetFilter(SumQ));
        Observer.Observe('Sum > 0', DumpRightSum(QSum));
        Observer.Observe('Avg > 10 filters', QAvg.GetFilters());
        Observer.Observe('Avg > 10 filter', QAvg.GetFilter(AvgQ));
        Observer.Observe('Avg > 10', DumpRightAvg(QAvg));
        Observer.Observe('Min < 10 filters', QMin.GetFilters());
        Observer.Observe('Min < 10 filter', QMin.GetFilter(MinQ));
        Observer.Observe('Min < 10', DumpRightMin(QMin));
        Observer.Observe('Max >= 20 filters', QMax.GetFilters());
        Observer.Observe('Max >= 20 filter', QMax.GetFilter(MaxQ));
        Observer.Observe('Max >= 20', DumpRightMax(QMax));
        Observer.Observe('Cnt 0 filters', QCnt.GetFilters());
        Observer.Observe('Cnt 0 filter', QCnt.GetFilter(CntQ));
        Observer.Observe('Cnt 0', DumpRightCnt(QCnt));
        Observer.Expect('Sum > 0 filters', 'SumQ: >0');
        Observer.Expect('Sum > 0 filter', '>0');
        Observer.Expect('Sum > 0', '[/7/7/7/7/1][P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('Avg > 10 filters', 'AvgQ: >10');
        Observer.Expect('Avg > 10 filter', '>10');
        Observer.Expect('Avg > 10', '[P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('Min < 10 filters', 'MinQ: <10');
        Observer.Expect('Min < 10 filter', '<10');
        Observer.Expect('Min < 10', '[/7/7/7/7/1][P4/0/0/0/0/1][P5/0/0/-5/5/2]');
        Observer.Expect('Max >= 20 filters', 'MaxQ: >=20');
        Observer.Expect('Max >= 20 filter', '>=20');
        Observer.Expect('Max >= 20', '[P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('Cnt 0 filters', 'CntQ: 0');
        Observer.Expect('Cnt 0 filter', '0');
        Observer.Expect('Cnt 0', '');
        Observer.Verify();
    end;

    [Test]
    procedure Y78_Full_StaticColumnFilterOnAggregates()
    var
        Observer: Codeunit "Probe Observer";
        QSum: Query "LT Y78 Q Full Sum";
        QAvg: Query "LT Y78 Q Full Avg";
        QMin: Query "LT Y78 Q Full Min";
        QMax: Query "LT Y78 Q Full Max";
        QCnt: Query "LT Y78 Q Full Cnt";
    begin
        Seed();
        Observer.Observe('Sum > 0 filters', QSum.GetFilters());
        Observer.Observe('Sum > 0 filter', QSum.GetFilter(SumQ));
        Observer.Observe('Sum > 0', DumpFullSum(QSum));
        Observer.Observe('Avg > 10 filters', QAvg.GetFilters());
        Observer.Observe('Avg > 10 filter', QAvg.GetFilter(AvgQ));
        Observer.Observe('Avg > 10', DumpFullAvg(QAvg));
        Observer.Observe('Min < 10 filters', QMin.GetFilters());
        Observer.Observe('Min < 10 filter', QMin.GetFilter(MinQ));
        Observer.Observe('Min < 10', DumpFullMin(QMin));
        Observer.Observe('Max >= 20 filters', QMax.GetFilters());
        Observer.Observe('Max >= 20 filter', QMax.GetFilter(MaxQ));
        Observer.Observe('Max >= 20', DumpFullMax(QMax));
        Observer.Observe('Cnt 0 filters', QCnt.GetFilters());
        Observer.Observe('Cnt 0 filter', QCnt.GetFilter(CntQ));
        Observer.Observe('Cnt 0', DumpFullCnt(QCnt));
        Observer.Expect('Sum > 0 filters', 'SumQ: >0');
        Observer.Expect('Sum > 0 filter', '>0');
        Observer.Expect('Sum > 0', '[/7/7/7/7/1][P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('Avg > 10 filters', 'AvgQ: >10');
        Observer.Expect('Avg > 10 filter', '>10');
        Observer.Expect('Avg > 10', '[P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('Min < 10 filters', 'MinQ: <10');
        Observer.Expect('Min < 10 filter', '<10');
        Observer.Expect('Min < 10', '[/7/7/7/7/1][P3/0/0/0/0/0][P4/0/0/0/0/1][P5/0/0/-5/5/2]');
        Observer.Expect('Max >= 20 filters', 'MaxQ: >=20');
        Observer.Expect('Max >= 20 filter', '>=20');
        Observer.Expect('Max >= 20', '[P1/30/15/10/20/2][P2/30/30/30/30/1]');
        Observer.Expect('Cnt 0 filters', 'CntQ: 0');
        Observer.Expect('Cnt 0 filter', '0');
        Observer.Expect('Cnt 0', '[P3/0/0/0/0/0]');
        Observer.Verify();
    end;
}

