// Batch 7 probes: tables, queries and a seeding helper shared by the query test codeunits. Not tests.
table 68275 "W7 Q Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Entry; Integer) { }
        field(2; IntF; Integer) { }
        field(3; Txt; Text[30]) { }
        field(4; DecF; Decimal) { }
        field(5; Big; BigInteger) { }
        field(6; Dur; Duration) { }
        field(7; Grp; Code[10]) { }
        field(8; Dt; Date) { }
        field(9; Flag; Boolean) { }
        field(10; "Line Total"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("W7 Q Line".Amount where("Row Entry" = field(Entry)));
        }
        field(11; "Line Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("W7 Q Line" where("Row Entry" = field(Entry)));
        }
    }

    keys
    {
        key(PK; Entry) { Clustered = true; }
    }
}

table 68276 "W7 Q Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; "Row Entry"; Integer) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}

query 68277 "W7 Q Filters"
{
    OrderBy = ascending(IntF);

    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(Entry; Entry) { }
            column(IntF; IntF) { }
            column(Txt; Txt) { }
            column(DecF; DecF) { }
            column(Grp; Grp) { }
            column(Dt; Dt) { }
            column(Flag; Flag) { }
        }
    }
}

query 68278 "W7 Q Filters Plain"
{
    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(Entry; Entry) { }
            column(IntF; IntF) { }
            column(Txt; Txt) { }
            column(DecF; DecF) { }
            column(Grp; Grp) { }
            column(Dt; Dt) { }
            column(Flag; Flag) { }
        }
    }
}

query 68279 "W7 Q Filters Text Order"
{
    OrderBy = ascending(Txt);

    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(Entry; Entry) { }
            column(IntF; IntF) { }
            column(Txt; Txt) { }
            column(DecF; DecF) { }
            column(Grp; Grp) { }
            column(Dt; Dt) { }
            column(Flag; Flag) { }
        }
    }
}

query 68280 "W7 Q Plain"
{
    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(Entry; Entry) { }
            column(Txt; Txt) { }
            filter(FIntF; IntF) { }
            column(Dup; IntF) { }
        }
    }
}

query 68281 "W7 Q Reordered"
{
    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(Dup; IntF) { }
            filter(FIntF; IntF) { }
            column(Txt; Txt) { }
            column(Entry; Entry) { }
        }
    }
}

query 68282 "W7 Q Other Names"
{
    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(Alpha; Entry) { }
            column(Beta; Txt) { }
            filter(Gamma; IntF) { }
            column(Delta; IntF) { }
        }
    }
}

query 68283 "W7 Q Single Column"
{
    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(Entry; Entry) { }
        }
    }
}

query 68284 "W7 Q Aggregates"
{
    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(Cnt) { Method = Count; }
            column(SumInt; IntF) { Method = Sum; }
            column(AvgInt; IntF) { Method = Average; }
            column(SumDec; DecF) { Method = Sum; }
            column(AvgDec; DecF) { Method = Average; }
            column(MinDec; DecF) { Method = Min; }
            column(MaxDec; DecF) { Method = Max; }
        }
    }
}

query 68285 "W7 Q Aggregates Big"
{
    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(SumBig; Big) { Method = Sum; }
            column(AvgBig; Big) { Method = Average; }
            column(MinBig; Big) { Method = Min; }
            column(MaxBig; Big) { Method = Max; }
        }
    }
}

query 68286 "W7 Q Aggregates Dur"
{
    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(SumDur; Dur) { Method = Sum; }
            column(AvgDur; Dur) { Method = Average; }
            column(MinDur; Dur) { Method = Min; }
            column(MaxDur; Dur) { Method = Max; }
        }
    }
}

query 68287 "W7 Q Groups"
{
    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(Grp; Grp) { }
            column(Cnt) { Method = Count; }
            column(SumInt; IntF) { Method = Sum; }
        }
    }
}

query 68288 "W7 Q Groups Two"
{
    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(Grp; Grp) { }
            column(Txt; Txt) { }
            column(Cnt) { Method = Count; }
        }
    }
}

query 68289 "W7 Q Cross Group Outer"
{
    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(Grp; Grp) { }
            dataitem(Line; "W7 Q Line")
            {
                SqlJoinType = CrossJoin;
                column(LineSum; Amount) { Method = Sum; }
            }
        }
    }
}

query 68290 "W7 Q Cross Group Inner"
{
    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(RowCount) { Method = Count; }
            dataitem(Line; "W7 Q Line")
            {
                SqlJoinType = CrossJoin;
                column(LineNo; "Line No.") { }
            }
        }
    }
}

query 68291 "W7 Q Cross Group Both"
{
    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(Grp; Grp) { }
            dataitem(Line; "W7 Q Line")
            {
                SqlJoinType = CrossJoin;
                column(LineNo; "Line No.") { }
                column(Cnt) { Method = Count; }
            }
        }
    }
}

query 68292 "W7 Q Flow Method"
{
    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            filter(FEntry; Entry) { }
            column(SumTotal; "Line Total") { Method = Sum; }
            column(CntTotal) { Method = Count; }
        }
    }
}

query 68299 "W7 Q Flow Method Grouped"
{
    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(RowEntry; Entry) { }
            column(SumTotal; "Line Total") { Method = Sum; }
        }
    }
}

query 68293 "W7 Q Save"
{
    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(Entry; Entry) { }
            column(Txt; Txt) { }
            column(DecF; DecF) { }
            column(Dt; Dt) { }
        }
    }
}

query 68294 "W7 Q Save Integers"
{
    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(Entry; Entry) { }
            column(IntF; IntF) { }
        }
    }
}

query 68295 "W7 Q Vars"
{
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(Entry; Entry) { }
        }
    }

    var
        Counter: Integer;
        BeforeOpenRuns: Integer;
        FilterInTrigger: Boolean;

    trigger OnBeforeOpen()
    begin
        BeforeOpenRuns += 1;
        if FilterInTrigger then
            SetRange(Entry, 2);
    end;

    procedure Bump(): Integer
    begin
        Counter += 1;
        exit(Counter);
    end;

    procedure Runs(): Integer
    begin
        exit(BeforeOpenRuns);
    end;

    procedure SetFilterInTrigger(NewValue: Boolean)
    begin
        FilterInTrigger := NewValue;
    end;
}

query 68545 "W7 Q About"
{
    AboutTitle = 'About this query';
    AboutText = 'Help text with no effect on the rows.';

    elements
    {
        dataitem(Row; "W7 Q Row")
        {
            column(Entry; Entry) { }
            column(Txt; Txt) { }
        }
    }
}

codeunit 68296 "W7 Q Seed"
{
    procedure Clear()
    var
        Row: Record "W7 Q Row";
        Line: Record "W7 Q Line";
    begin
        Row.DeleteAll();
        Line.DeleteAll();
    end;

    procedure Row(Entry: Integer; IntF: Integer; Txt: Text[30]; DecF: Decimal; Grp: Code[10])
    var
        NewRow: Record "W7 Q Row";
    begin
        NewRow.Init();
        NewRow.Entry := Entry;
        NewRow.IntF := IntF;
        NewRow.Txt := Txt;
        NewRow.DecF := DecF;
        NewRow.Grp := Grp;
        NewRow.Insert();
    end;

    procedure Line(LineNo: Integer; RowEntry: Integer; Amount: Decimal)
    var
        NewLine: Record "W7 Q Line";
    begin
        NewLine.Init();
        NewLine."Line No." := LineNo;
        NewLine."Row Entry" := RowEntry;
        NewLine.Amount := Amount;
        NewLine.Insert();
    end;
}
