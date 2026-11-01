// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-filters
// Scope: in-scope. A query filter() element over a FlowField of the header data item when the query also joins a line data item, groups with a
//   Method column, or both; static ColumnFilter and run-time SetFilter / SetRange on those filter elements; a FlowFilter filter element with a
//   FlowField column in a joined query.
// Fixtures used: Probe Observer (69160); self-contained tables 93261-93263, queries 93267-93272, codeunit 93261
// Probe: gap cycle 6, spec G6-20 (writer Y62). Every literal asserted below is what BC produced (corpus CI 27.5, 28.5, 29.0; SaaS sandbox BC 29).
// Seed: H1 2026-01-10 lines A qty 3 amt 60 (K1), B qty 1 amt 40 (K2) -> Amount 100; H2 2026-01-20 lines A qty 5 amt 5 (K1), A qty 1 amt -5 (K2)
//   -> Amount 0; H3 2026-01-30 no lines -> Amount 0; H4 2026-02-10 line A qty 2 amt 50 (K1) and a Cancel row -> Cancelled; H5 2026-02-20 line
//   B qty 7 amt 70 (K2) -> Amount 70.
// Results (same on 27.5, 28.5, 29.0 and the SaaS sandbox): a FlowField filter element is evaluated per header row (its own FlowField value),
//   before the join and the grouping; a run-time SetFilter/SetRange on it replaces the static ColumnFilter; with a left outer join a header without
//   lines is kept (blank line columns, Sum 0); a FlowFilter filter element sets the flow filter of the header FlowField column.
// BC versions: 27, 28, 29

table 93261 "LT Y62 FQ Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Posting Date"; Date) { }
        field(3; Cancelled; Boolean) { FieldClass = FlowField; CalcFormula = exist("LT Y62 FQ Cancel" where("Doc No." = field("No."))); }
        field(4; Amount; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT Y62 FQ Line".Amount where("Doc No." = field("No."))); }
        field(5; KindFilter; Code[10]) { FieldClass = FlowFilter; }
        field(6; Gross; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT Y62 FQ Line".Amount where("Doc No." = field("No."), Kind = field(KindFilter))); }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 93262 "LT Y62 FQ Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; ItemNo; Code[20]) { }
        field(4; Qty; Decimal) { }
        field(5; Amount; Decimal) { }
        field(6; Kind; Code[10]) { }
    }

    keys { key(PK; "Doc No.", "Line No.") { Clustered = true; } }
}

table 93263 "LT Y62 FQ Cancel"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[20]) { }
    }

    keys { key(PK; "Doc No.") { Clustered = true; } }
}

query 93267 "LT Y62 FQ Join NoMethod"
{
    OrderBy = ascending(No, LineNo);

    elements
    {
        dataitem(Header; "LT Y62 FQ Header")
        {
            column(No; "No.") { }
            filter(Amt; Amount) { ColumnFilter = Amt = filter(> 0); }
            filter(Canc; Cancelled) { ColumnFilter = Canc = const(false); }
            dataitem(Line; "LT Y62 FQ Line")
            {
                DataItemLink = "Doc No." = Header."No.";
                SqlJoinType = InnerJoin;
                column(LineNo; "Line No.") { }
                column(ItemNo; ItemNo) { }
                column(Qty; Qty) { }
            }
        }
    }
}

query 93268 "LT Y62 FQ Method NoJoin"
{
    OrderBy = ascending(No);

    elements
    {
        dataitem(Header; "LT Y62 FQ Header")
        {
            column(No; "No.") { }
            column(CntAll) { Method = Count; }
            filter(Amt; Amount) { ColumnFilter = Amt = filter(> 0); }
        }
    }
}

query 93269 "LT Y62 FQ Join Method"
{
    OrderBy = descending(SumQty);

    elements
    {
        dataitem(Header; "LT Y62 FQ Header")
        {
            filter(PostDate; "Posting Date") { }
            filter(Canc; Cancelled) { ColumnFilter = Canc = const(false); }
            filter(Amt; Amount) { ColumnFilter = Amt = filter('>0'); }
            dataitem(Line; "LT Y62 FQ Line")
            {
                DataItemLink = "Doc No." = Header."No.";
                SqlJoinType = InnerJoin;
                column(ItemNo; ItemNo) { }
                filter(KindF; Kind) { }
                column(SumQty; Qty) { Method = Sum; }
            }
        }
    }
}

query 93270 "LT Y62 FQ Outer Method"
{
    OrderBy = ascending(No, ItemNo);

    elements
    {
        dataitem(Header; "LT Y62 FQ Header")
        {
            column(No; "No.") { }
            filter(Canc; Cancelled) { ColumnFilter = Canc = const(false); }
            filter(Amt; Amount) { ColumnFilter = Amt = filter('>0'); }
            dataitem(Line; "LT Y62 FQ Line")
            {
                DataItemLink = "Doc No." = Header."No.";
                SqlJoinType = LeftOuterJoin;
                column(ItemNo; ItemNo) { }
                column(SumQty; Qty) { Method = Sum; }
            }
        }
    }
}

query 93271 "LT Y62 FQ Join Method Runtime"
{
    OrderBy = descending(SumQty);

    elements
    {
        dataitem(Header; "LT Y62 FQ Header")
        {
            filter(Amt; Amount) { }
            dataitem(Line; "LT Y62 FQ Line")
            {
                DataItemLink = "Doc No." = Header."No.";
                SqlJoinType = InnerJoin;
                column(ItemNo; ItemNo) { }
                column(SumQty; Qty) { Method = Sum; }
            }
        }
    }
}

query 93272 "LT Y62 FQ Join FlowFilter"
{
    OrderBy = ascending(No, LineNo);

    elements
    {
        dataitem(Header; "LT Y62 FQ Header")
        {
            column(No; "No.") { }
            column(Gross; Gross) { }
            filter(KindF; KindFilter) { }
            dataitem(Line; "LT Y62 FQ Line")
            {
                DataItemLink = "Doc No." = Header."No.";
                SqlJoinType = InnerJoin;
                column(LineNo; "Line No.") { }
            }
        }
    }
}

codeunit 93261 "LT Y62 Query FlowField Join"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        H: Record "LT Y62 FQ Header";
        L: Record "LT Y62 FQ Line";
        C: Record "LT Y62 FQ Cancel";
    begin
        H.DeleteAll();
        L.DeleteAll();
        C.DeleteAll();
        AddHeader('H1', 20260110D);
        AddHeader('H2', 20260120D);
        AddHeader('H3', 20260130D);
        AddHeader('H4', 20260210D);
        AddHeader('H5', 20260220D);
        AddLine('H1', 10000, 'A', 3, 60, 'K1');
        AddLine('H1', 20000, 'B', 1, 40, 'K2');
        AddLine('H2', 10000, 'A', 5, 5, 'K1');
        AddLine('H2', 20000, 'A', 1, -5, 'K2');
        AddLine('H4', 10000, 'A', 2, 50, 'K1');
        AddLine('H5', 10000, 'B', 7, 70, 'K2');
        C."Doc No." := 'H4';
        C.Insert();
    end;

    local procedure AddHeader(No: Code[20]; PostingDate: Date)
    var
        H: Record "LT Y62 FQ Header";
    begin
        H."No." := No;
        H."Posting Date" := PostingDate;
        H.Insert();
    end;

    local procedure AddLine(DocNo: Code[20]; LineNo: Integer; ItemNo: Code[20]; Qty: Decimal; Amount: Decimal; Kind: Code[10])
    var
        L: Record "LT Y62 FQ Line";
    begin
        L."Doc No." := DocNo;
        L."Line No." := LineNo;
        L.ItemNo := ItemNo;
        L.Qty := Qty;
        L.Amount := Amount;
        L.Kind := Kind;
        L.Insert();
    end;

    [TryFunction]
    local procedure TryJoinNoMethod(Mode: Integer; var Txt: Text)
    var
        Q: Query "LT Y62 FQ Join NoMethod";
    begin
        Txt := '';
        case Mode of
            2:
                Q.SetRange(Amt, 0);
            3:
                Q.SetFilter(Amt, '>%1', 60);
        end;
        Q.Open();
        while Q.Read() do
            Txt += Q.No + '|' + Q.ItemNo + '|' + Format(Q.Qty, 0, 9) + ';';
    end;

    [Test]
    procedure FlowFieldFilter_Join_NoMethod()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
        i: Integer;
    begin
        Seed();
        for i := 1 to 3 do
            if TryJoinNoMethod(i, Txt) then
                Observer.Observe('mode' + Format(i), Txt)
            else
                Observer.ObserveError('mode' + Format(i));
        Observer.Expect('mode1', 'H1|A|3;H1|B|1;H5|B|7;');
        Observer.Expect('mode2', 'H2|A|5;H2|A|1;');
        Observer.Expect('mode3', 'H1|A|3;H1|B|1;H5|B|7;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryMethodNoJoin(Mode: Integer; var Txt: Text)
    var
        Q: Query "LT Y62 FQ Method NoJoin";
    begin
        Txt := '';
        if Mode = 2 then
            Q.SetRange(Amt, 100);
        Q.Open();
        while Q.Read() do
            Txt += Q.No + '|' + Format(Q.CntAll) + ';';
    end;

    [Test]
    procedure FlowFieldFilter_Method_NoJoin()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
        i: Integer;
    begin
        Seed();
        for i := 1 to 2 do
            if TryMethodNoJoin(i, Txt) then
                Observer.Observe('mode' + Format(i), Txt)
            else
                Observer.ObserveError('mode' + Format(i));
        Observer.Expect('mode1', 'H1|1;H4|1;H5|1;');
        Observer.Expect('mode2', 'H1|1;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryJoinMethod(Mode: Integer; var Txt: Text)
    var
        Q: Query "LT Y62 FQ Join Method";
    begin
        Txt := '';
        case Mode of
            2:
                Q.SetFilter(PostDate, '>=%1&<=%2', 20260101D, 20260131D);
            3:
                Q.SetRange(Canc, true);
            4:
                Q.SetRange(KindF, 'K2');
            5:
                begin
                    Q.SetFilter(PostDate, '>=%1&<=%2', 20260101D, 20260228D);
                    Q.SetRange(KindF, 'K1');
                end;
        end;
        Q.Open();
        while Q.Read() do
            Txt += Q.ItemNo + '|' + Format(Q.SumQty, 0, 9) + ';';
    end;

    [Test]
    procedure FlowFieldFilter_Join_Method()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
        i: Integer;
    begin
        Seed();
        for i := 1 to 5 do
            if TryJoinMethod(i, Txt) then
                Observer.Observe('mode' + Format(i), Txt)
            else
                Observer.ObserveError('mode' + Format(i));
        Observer.Expect('mode1', 'B|8;A|3;');
        Observer.Expect('mode2', 'A|3;B|1;');
        Observer.Expect('mode3', 'A|2;');
        Observer.Expect('mode4', 'B|8;');
        Observer.Expect('mode5', 'A|3;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryOuterMethod(Mode: Integer; var Txt: Text)
    var
        Q: Query "LT Y62 FQ Outer Method";
    begin
        Txt := '';
        if Mode = 2 then
            Q.SetFilter(Amt, '>=0');
        Q.Open();
        while Q.Read() do
            Txt += Q.No + '|' + Q.ItemNo + '|' + Format(Q.SumQty, 0, 9) + ';';
    end;

    [Test]
    procedure FlowFieldFilter_OuterJoin_Method()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
        i: Integer;
    begin
        Seed();
        for i := 1 to 2 do
            if TryOuterMethod(i, Txt) then
                Observer.Observe('mode' + Format(i), Txt)
            else
                Observer.ObserveError('mode' + Format(i));
        Observer.Expect('mode1', 'H1|A|3;H1|B|1;H5|B|7;');
        Observer.Expect('mode2', 'H1|A|3;H1|B|1;H2|A|6;H3||0;H5|B|7;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRuntimeOnly(Mode: Integer; var Txt: Text)
    var
        Q: Query "LT Y62 FQ Join Method Runtime";
    begin
        Txt := '';
        case Mode of
            2:
                Q.SetFilter(Amt, '>%1', 60);
            3:
                Q.SetFilter(Amt, '>%1', 80);
            4:
                Q.SetRange(Amt, 0);
        end;
        Q.Open();
        while Q.Read() do
            Txt += Q.ItemNo + '|' + Format(Q.SumQty, 0, 9) + ';';
    end;

    [Test]
    procedure FlowFieldFilter_Join_Method_RuntimeOnly()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
        i: Integer;
    begin
        Seed();
        for i := 1 to 4 do
            if TryRuntimeOnly(i, Txt) then
                Observer.Observe('mode' + Format(i), Txt)
            else
                Observer.ObserveError('mode' + Format(i));
        Observer.Expect('mode1', 'A|11;B|8;');
        Observer.Expect('mode2', 'B|8;A|3;');
        Observer.Expect('mode3', 'A|3;B|1;');
        Observer.Expect('mode4', 'A|6;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryFlowFilter(Mode: Integer; var Txt: Text)
    var
        Q: Query "LT Y62 FQ Join FlowFilter";
    begin
        Txt := '';
        case Mode of
            2:
                Q.SetFilter(KindF, 'K1');
            3:
                Q.SetRange(KindF, 'K2');
        end;
        Q.Open();
        while Q.Read() do
            Txt += Q.No + '|' + Format(Q.LineNo) + '|' + Format(Q.Gross, 0, 9) + ';';
    end;

    [Test]
    procedure FlowFilterElement_Join_FlowFieldColumn()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
        i: Integer;
    begin
        Seed();
        for i := 1 to 3 do
            if TryFlowFilter(i, Txt) then
                Observer.Observe('mode' + Format(i), Txt)
            else
                Observer.ObserveError('mode' + Format(i));
        Observer.Expect('mode1', 'H1|10000|100;H1|20000|100;H2|10000|0;H2|20000|0;H4|10000|50;H5|10000|70;');
        Observer.Expect('mode2', 'H1|10000|60;H1|20000|60;H2|10000|5;H2|20000|5;H4|10000|50;H5|10000|0;');
        Observer.Expect('mode3', 'H1|10000|40;H1|20000|40;H2|10000|-5;H2|20000|-5;H4|10000|0;H5|10000|70;');
        Observer.Verify();
    end;
}
