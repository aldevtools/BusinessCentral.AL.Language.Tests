// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); declares tables 74054, 74055, queries 74056-74061 (writer PX: queries 86166-86175)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a nested dataitem that is outer-joined (no SqlJoinType at all, and LeftOuterJoin spelled out) and carries a static filter: a Count column with ColumnFilter = const(0) or > 0 over the outer item (parents with no child), a plain column with a ColumnFilter, a DataItemTableFilter on an item with the default join type; two-field DataItemLink
// BC versions: 29 (27 and 28 by CI)

table 74054 "LT P133 Parent"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; DocNo; Code[20]) { }
        field(2; PostDate; Date) { }
        field(3; Amount; Decimal) { }
        field(4; Debit; Decimal) { }
    }

    keys
    {
        key(PK; DocNo, PostDate) { Clustered = true; }
    }
}

table 74055 "LT P133 Child"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; EntryNo; Integer) { }
        field(2; DocNo; Code[20]) { }
        field(3; PostDate; Date) { }
        field(4; Kind; Integer) { }
    }

    keys
    {
        key(PK; EntryNo) { Clustered = true; }
    }
}

query 74056 "LT P133 Q CountZero Default"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            column(PostDate; PostDate) { }
            column(SumAmount; Amount) { Method = Sum; }
            column(SumDebit; Debit) { Method = Sum; }
            column(NoOfParents) { Method = Count; }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                column(NoOfChildren)
                {
                    ColumnFilter = NoOfChildren = const(0);
                    Method = Count;
                }
            }
        }
    }
}

query 74057 "LT P133 Q CountZero Left"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            column(PostDate; PostDate) { }
            column(SumAmount; Amount) { Method = Sum; }
            column(NoOfParents) { Method = Count; }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                SqlJoinType = LeftOuterJoin;
                column(NoOfChildren)
                {
                    ColumnFilter = NoOfChildren = const(0);
                    Method = Count;
                }
            }
        }
    }
}

query 74058 "LT P133 Q CountPositive Left"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            column(PostDate; PostDate) { }
            column(NoOfParents) { Method = Count; }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                SqlJoinType = LeftOuterJoin;
                column(NoOfChildren)
                {
                    ColumnFilter = NoOfChildren = filter(> 0);
                    Method = Count;
                }
            }
        }
    }
}

query 74059 "LT P133 Q TableFilter Default"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo), ascending(EntryNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            column(PostDate; PostDate) { }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                DataItemTableFilter = Kind = const(1);
                column(EntryNo; EntryNo) { }
                column(Kind; Kind) { }
            }
        }
    }
}

query 74060 "LT P133 Q ColumnFilter Left"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo), ascending(EntryNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            column(PostDate; PostDate) { }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                SqlJoinType = LeftOuterJoin;
                column(EntryNo; EntryNo) { }
                column(Kind; Kind)
                {
                    ColumnFilter = Kind = const(1);
                }
            }
        }
    }
}

query 74061 "LT P133 Q TableFilter Left"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo), ascending(EntryNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            column(PostDate; PostDate) { }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                SqlJoinType = LeftOuterJoin;
                DataItemTableFilter = Kind = const(1);
                column(EntryNo; EntryNo) { }
                column(Kind; Kind) { }
            }
        }
    }
}

codeunit 74062 "LT P133 Query Outer Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Parent: Record "LT P133 Parent";
        Child: Record "LT P133 Child";
    begin
        Parent.DeleteAll();
        Child.DeleteAll();
        // D1: two children (kinds 1 and 2); D2: one child (kind 2); D3: none; D4: one child with another date (no link match)
        InsertParent('D1', DMY2Date(1, 1, 2024), 10, 1);
        InsertParent('D2', DMY2Date(1, 1, 2024), 20, 2);
        InsertParent('D3', DMY2Date(1, 1, 2024), 30, 3);
        InsertParent('D4', DMY2Date(1, 1, 2024), 40, 4);
        InsertChild(1, 'D1', DMY2Date(1, 1, 2024), 1);
        InsertChild(2, 'D1', DMY2Date(1, 1, 2024), 2);
        InsertChild(3, 'D2', DMY2Date(1, 1, 2024), 2);
        InsertChild(4, 'D4', DMY2Date(2, 1, 2024), 1);
    end;

    local procedure InsertParent(DocNo: Code[20]; PostDate: Date; Amount: Decimal; Debit: Decimal)
    var
        Parent: Record "LT P133 Parent";
    begin
        Parent.DocNo := DocNo;
        Parent.PostDate := PostDate;
        Parent.Amount := Amount;
        Parent.Debit := Debit;
        Parent.Insert();
    end;

    local procedure InsertChild(EntryNo: Integer; DocNo: Code[20]; PostDate: Date; Kind: Integer)
    var
        Child: Record "LT P133 Child";
    begin
        Child.EntryNo := EntryNo;
        Child.DocNo := DocNo;
        Child.PostDate := PostDate;
        Child.Kind := Kind;
        Child.Insert();
    end;

    [TryFunction]
    local procedure TryDrainCountZeroDefault(var Result: Text)
    var
        Q: Query "LT P133 Q CountZero Default";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':parents=' + Format(Q.NoOfParents) + ',children=' + Format(Q.NoOfChildren) + ',amount=' + Format(Q.SumAmount, 0, 9) + ',debit=' + Format(Q.SumDebit, 0, 9) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainCountZeroLeft(var Result: Text)
    var
        Q: Query "LT P133 Q CountZero Left";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':parents=' + Format(Q.NoOfParents) + ',children=' + Format(Q.NoOfChildren) + ',amount=' + Format(Q.SumAmount, 0, 9) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainCountPositiveLeft(var Result: Text)
    var
        Q: Query "LT P133 Q CountPositive Left";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':parents=' + Format(Q.NoOfParents) + ',children=' + Format(Q.NoOfChildren) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainTableFilterDefault(var Result: Text)
    var
        Q: Query "LT P133 Q TableFilter Default";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':entry=' + Format(Q.EntryNo) + ',kind=' + Format(Q.Kind) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainColumnFilterLeft(var Result: Text)
    var
        Q: Query "LT P133 Q ColumnFilter Left";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':entry=' + Format(Q.EntryNo) + ',kind=' + Format(Q.Kind) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainTableFilterLeft(var Result: Text)
    var
        Q: Query "LT P133 Q TableFilter Left";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':entry=' + Format(Q.EntryNo) + ',kind=' + Format(Q.Kind) + ' ';
    end;

    local procedure Show(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean; Rows: Text)
    begin
        if Ok then
            Observer.Observe(Name, Rows)
        else begin
            Observer.Observe(Name, 'err ' + GetLastErrorText());
            ClearLastError();
        end;
    end;

    [Test]
    procedure P133_Query_CountColumnFilterZero_OverTheOuterItem()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        Seed();
        Show(Observer, 'default join', TryDrainCountZeroDefault(Rows), Rows);
        Clear(Rows);
        Show(Observer, 'left outer join', TryDrainCountZeroLeft(Rows), Rows);
        Clear(Rows);
        Show(Observer, 'left outer join, filter > 0', TryDrainCountPositiveLeft(Rows), Rows);
        Observer.Expect('default join', 'D3:parents=1,children=0,amount=30,debit=3 D4:parents=1,children=0,amount=40,debit=4 ');
        Observer.Expect('left outer join', 'D3:parents=1,children=0,amount=30 D4:parents=1,children=0,amount=40 ');
        Observer.Expect('left outer join, filter > 0', 'D1:parents=2,children=2 D2:parents=1,children=1 ');
        Observer.Verify();
    end;

    [Test]
    procedure P133_Query_StaticFiltersOnTheOuterItem_TableAndColumn()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        Seed();
        Show(Observer, 'default join, table filter kind 1', TryDrainTableFilterDefault(Rows), Rows);
        Clear(Rows);
        Show(Observer, 'left outer join, table filter kind 1', TryDrainTableFilterLeft(Rows), Rows);
        Clear(Rows);
        Show(Observer, 'left outer join, column filter kind 1', TryDrainColumnFilterLeft(Rows), Rows);
        Observer.Expect('default join, table filter kind 1', 'D1:entry=1,kind=1 ');
        Observer.Expect('left outer join, table filter kind 1', 'D1:entry=1,kind=1 ');
        Observer.Expect('left outer join, column filter kind 1', 'D1:entry=1,kind=1 ');
        Observer.Verify();
    end;

    [Test]
    procedure P133_Query_CountZero_NoChildrenAtAll()
    var
        Observer: Codeunit "Probe Observer";
        Child: Record "LT P133 Child";
        Rows: Text;
    begin
        Seed();
        Child.DeleteAll();
        Show(Observer, 'default join, no children', TryDrainCountZeroDefault(Rows), Rows);
        Clear(Rows);
        Show(Observer, 'left outer join, no children', TryDrainCountZeroLeft(Rows), Rows);
        Clear(Rows);
        Show(Observer, 'left outer join, filter > 0, no children', TryDrainCountPositiveLeft(Rows), Rows);
        Clear(Rows);
        Show(Observer, 'default join, table filter, no children', TryDrainTableFilterDefault(Rows), Rows);
        Observer.Expect('default join, no children', 'D1:parents=1,children=0,amount=10,debit=1 D2:parents=1,children=0,amount=20,debit=2 D3:parents=1,children=0,amount=30,debit=3 D4:parents=1,children=0,amount=40,debit=4 ');
        Observer.Expect('left outer join, no children', 'D1:parents=1,children=0,amount=10 D2:parents=1,children=0,amount=20 D3:parents=1,children=0,amount=30 D4:parents=1,children=0,amount=40 ');
        Observer.Expect('left outer join, filter > 0, no children', '');
        Observer.Expect('default join, table filter, no children', '');
        Observer.Verify();
    end;

    // Writer PX (probes-needed, PR 326 "Not done"): a ColumnFilter on a Sum, Average, Min or Max column of an outer-joined dataitem
    // (queries 86166-86173, data of Seed: D1 kinds 1 and 2, D2 kind 2, D3 and D4 no linked child), and the same aggregates without a filter (86175).
    // Rule seen: a parent without a linked child reads 0 for Sum, Average, Min and Max; the ColumnFilter filters the groups on that value (const(0)
    // keeps D3 and D4, the join stays outer); Average of an Integer column is cut to an Integer (D1: 1, not 1.5), and the filter sees the cut value.

    [TryFunction]
    local procedure TryDrainPxSumZero(var Result: Text)
    var
        Q: Query "LT PX Q Outer Sum Zero";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':' + Format(Q.Agg, 0, 9) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainPxSumAtLeast2(var Result: Text)
    var
        Q: Query "LT PX Q Outer Sum AtLeast2";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':' + Format(Q.Agg, 0, 9) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainPxAverageZero(var Result: Text)
    var
        Q: Query "LT PX Q Outer Average Zero";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':' + Format(Q.Agg, 0, 9) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainPxAverageAtLeast2(var Result: Text)
    var
        Q: Query "LT PX Q Outer Average AtLeast2";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':' + Format(Q.Agg, 0, 9) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainPxMinZero(var Result: Text)
    var
        Q: Query "LT PX Q Outer Min Zero";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':' + Format(Q.Agg, 0, 9) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainPxMinAtLeast2(var Result: Text)
    var
        Q: Query "LT PX Q Outer Min AtLeast2";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':' + Format(Q.Agg, 0, 9) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainPxMaxZero(var Result: Text)
    var
        Q: Query "LT PX Q Outer Max Zero";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':' + Format(Q.Agg, 0, 9) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainPxMaxAtLeast2(var Result: Text)
    var
        Q: Query "LT PX Q Outer Max AtLeast2";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':' + Format(Q.Agg, 0, 9) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainPxAllAggregates(var Result: Text)
    var
        Q: Query "LT PX Q Outer All Aggregates";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':sum=' + Format(Q.SumKind, 0, 9) + ',avg=' + Format(Q.AvgKind, 0, 9) + ',min=' + Format(Q.MinKind, 0, 9) + ',max=' + Format(Q.MaxKind, 0, 9) + ' ';
    end;

    [Test]
    procedure PX_Query_OuterAggregates_NoColumnFilter()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        Seed();
        Show(Observer, 'all aggregates', TryDrainPxAllAggregates(Rows), Rows);
        Observer.Expect('all aggregates', 'D1:sum=3,avg=1,min=1,max=2 D2:sum=2,avg=2,min=2,max=2 D3:sum=0,avg=0,min=0,max=0 D4:sum=0,avg=0,min=0,max=0 ');
        Observer.Verify();
    end;

    [Test]
    procedure PX_Query_OuterColumnFilter_Sum()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        Seed();
        Clear(Rows);
        Show(Observer, 'sum const(0)', TryDrainPxSumZero(Rows), Rows);
        Clear(Rows);
        Show(Observer, 'sum filter(>= 2)', TryDrainPxSumAtLeast2(Rows), Rows);
        Observer.Expect('sum const(0)', 'D3:0 D4:0 ');
        Observer.Expect('sum filter(>= 2)', 'D1:3 D2:2 ');
        Observer.Verify();
    end;

    [Test]
    procedure PX_Query_OuterColumnFilter_Average()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        Seed();
        Clear(Rows);
        Show(Observer, 'average const(0)', TryDrainPxAverageZero(Rows), Rows);
        Clear(Rows);
        Show(Observer, 'average filter(>= 2)', TryDrainPxAverageAtLeast2(Rows), Rows);
        Observer.Expect('average const(0)', 'D3:0 D4:0 ');
        Observer.Expect('average filter(>= 2)', 'D2:2 ');
        Observer.Verify();
    end;

    [Test]
    procedure PX_Query_OuterColumnFilter_Min()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        Seed();
        Clear(Rows);
        Show(Observer, 'min const(0)', TryDrainPxMinZero(Rows), Rows);
        Clear(Rows);
        Show(Observer, 'min filter(>= 2)', TryDrainPxMinAtLeast2(Rows), Rows);
        Observer.Expect('min const(0)', 'D3:0 D4:0 ');
        Observer.Expect('min filter(>= 2)', 'D2:2 ');
        Observer.Verify();
    end;

    [Test]
    procedure PX_Query_OuterColumnFilter_Max()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        Seed();
        Clear(Rows);
        Show(Observer, 'max const(0)', TryDrainPxMaxZero(Rows), Rows);
        Clear(Rows);
        Show(Observer, 'max filter(>= 2)', TryDrainPxMaxAtLeast2(Rows), Rows);
        Observer.Expect('max const(0)', 'D3:0 D4:0 ');
        Observer.Expect('max filter(>= 2)', 'D1:2 D2:2 ');
        Observer.Verify();
    end;

    // Writer PX (probes-needed, PR 326 "Not done"): Query.GetFilters with filters on columns of two dataitems (query 74059: Parent DocNo field 1,
    // PostDate field 2; Child EntryNo field 1, Kind field 4) and with filter elements on both dataitems (query 86174: column DocNo, filter FPost,
    // column EntryNo, filter FKind), every order of the four SetRange calls.
    // Rule seen: column filters always come in column order, whatever the set order and the dataitem; filter elements are placed by set order
    // among themselves and around the columns as asserted below (no column of the Child dataitem moves ahead of a Parent column).
    local procedure PxSetDefault(var Q: Query "LT P133 Q TableFilter Default"; Name: Text)
    begin
        case Name of
            'DocNo':
                Q.SetRange(DocNo, 'D1');
            'PostDate':
                Q.SetRange(PostDate, DMY2Date(1, 1, 2024));
            'EntryNo':
                Q.SetRange(EntryNo, 2);
            'Kind':
                Q.SetRange(Kind, 1);
        end;
    end;

    local procedure PxSetTwoItems(var Q: Query "LT PX Q Two Items"; Name: Text)
    begin
        case Name of
            'DocNo':
                Q.SetRange(DocNo, 'D1');
            'FPost':
                Q.SetRange(FPost, DMY2Date(1, 1, 2024));
            'EntryNo':
                Q.SetRange(EntryNo, 2);
            'FKind':
                Q.SetRange(FKind, 1);
        end;
    end;

    local procedure PxOrderDefault(var Observer: Codeunit "Probe Observer"; Order: Text)
    var
        Q: Query "LT P133 Q TableFilter Default";
        Name: Text;
    begin
        foreach Name in Order.Split('-') do
            PxSetDefault(Q, Name);
        Observer.Observe(Order, Q.GetFilters());
    end;

    local procedure PxOrderTwoItems(var Observer: Codeunit "Probe Observer"; Order: Text)
    var
        Q: Query "LT PX Q Two Items";
        Name: Text;
    begin
        foreach Name in Order.Split('-') do
            PxSetTwoItems(Q, Name);
        Observer.Observe(Order, Q.GetFilters());
    end;

    [Test]
    procedure PX_Query_GetFilters_TwoDataItems_Columns_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PxOrderDefault(Observer, 'DocNo-PostDate-EntryNo-Kind');
        PxOrderDefault(Observer, 'DocNo-PostDate-Kind-EntryNo');
        PxOrderDefault(Observer, 'DocNo-EntryNo-PostDate-Kind');
        PxOrderDefault(Observer, 'DocNo-EntryNo-Kind-PostDate');
        PxOrderDefault(Observer, 'DocNo-Kind-PostDate-EntryNo');
        PxOrderDefault(Observer, 'DocNo-Kind-EntryNo-PostDate');
        PxOrderDefault(Observer, 'PostDate-DocNo-EntryNo-Kind');
        PxOrderDefault(Observer, 'PostDate-DocNo-Kind-EntryNo');
        PxOrderDefault(Observer, 'PostDate-EntryNo-DocNo-Kind');
        PxOrderDefault(Observer, 'PostDate-EntryNo-Kind-DocNo');
        PxOrderDefault(Observer, 'PostDate-Kind-DocNo-EntryNo');
        PxOrderDefault(Observer, 'PostDate-Kind-EntryNo-DocNo');
        Observer.Expect('DocNo-PostDate-EntryNo-Kind', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('DocNo-PostDate-Kind-EntryNo', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('DocNo-EntryNo-PostDate-Kind', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('DocNo-EntryNo-Kind-PostDate', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('DocNo-Kind-PostDate-EntryNo', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('DocNo-Kind-EntryNo-PostDate', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('PostDate-DocNo-EntryNo-Kind', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('PostDate-DocNo-Kind-EntryNo', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('PostDate-EntryNo-DocNo-Kind', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('PostDate-EntryNo-Kind-DocNo', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('PostDate-Kind-DocNo-EntryNo', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('PostDate-Kind-EntryNo-DocNo', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Verify();
    end;

    [Test]
    procedure PX_Query_GetFilters_TwoDataItems_Columns_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PxOrderDefault(Observer, 'EntryNo-DocNo-PostDate-Kind');
        PxOrderDefault(Observer, 'EntryNo-DocNo-Kind-PostDate');
        PxOrderDefault(Observer, 'EntryNo-PostDate-DocNo-Kind');
        PxOrderDefault(Observer, 'EntryNo-PostDate-Kind-DocNo');
        PxOrderDefault(Observer, 'EntryNo-Kind-DocNo-PostDate');
        PxOrderDefault(Observer, 'EntryNo-Kind-PostDate-DocNo');
        PxOrderDefault(Observer, 'Kind-DocNo-PostDate-EntryNo');
        PxOrderDefault(Observer, 'Kind-DocNo-EntryNo-PostDate');
        PxOrderDefault(Observer, 'Kind-PostDate-DocNo-EntryNo');
        PxOrderDefault(Observer, 'Kind-PostDate-EntryNo-DocNo');
        PxOrderDefault(Observer, 'Kind-EntryNo-DocNo-PostDate');
        PxOrderDefault(Observer, 'Kind-EntryNo-PostDate-DocNo');
        Observer.Expect('EntryNo-DocNo-PostDate-Kind', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('EntryNo-DocNo-Kind-PostDate', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('EntryNo-PostDate-DocNo-Kind', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('EntryNo-PostDate-Kind-DocNo', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('EntryNo-Kind-DocNo-PostDate', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('EntryNo-Kind-PostDate-DocNo', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('Kind-DocNo-PostDate-EntryNo', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('Kind-DocNo-EntryNo-PostDate', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('Kind-PostDate-DocNo-EntryNo', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('Kind-PostDate-EntryNo-DocNo', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('Kind-EntryNo-DocNo-PostDate', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Expect('Kind-EntryNo-PostDate-DocNo', 'DocNo: D1, PostDate: 01/01/24, EntryNo: 2, Kind: 1');
        Observer.Verify();
    end;

    [Test]
    procedure PX_Query_GetFilters_TwoDataItems_FilterElements_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PxOrderTwoItems(Observer, 'DocNo-FPost-EntryNo-FKind');
        PxOrderTwoItems(Observer, 'DocNo-FPost-FKind-EntryNo');
        PxOrderTwoItems(Observer, 'DocNo-EntryNo-FPost-FKind');
        PxOrderTwoItems(Observer, 'DocNo-EntryNo-FKind-FPost');
        PxOrderTwoItems(Observer, 'DocNo-FKind-FPost-EntryNo');
        PxOrderTwoItems(Observer, 'DocNo-FKind-EntryNo-FPost');
        PxOrderTwoItems(Observer, 'FPost-DocNo-EntryNo-FKind');
        PxOrderTwoItems(Observer, 'FPost-DocNo-FKind-EntryNo');
        PxOrderTwoItems(Observer, 'FPost-EntryNo-DocNo-FKind');
        PxOrderTwoItems(Observer, 'FPost-EntryNo-FKind-DocNo');
        PxOrderTwoItems(Observer, 'FPost-FKind-DocNo-EntryNo');
        PxOrderTwoItems(Observer, 'FPost-FKind-EntryNo-DocNo');
        Observer.Expect('DocNo-FPost-EntryNo-FKind', 'DocNo: D1, PostDate: 01/01/24, Kind: 1, EntryNo: 2');
        Observer.Expect('DocNo-FPost-FKind-EntryNo', 'DocNo: D1, PostDate: 01/01/24, Kind: 1, EntryNo: 2');
        Observer.Expect('DocNo-EntryNo-FPost-FKind', 'DocNo: D1, PostDate: 01/01/24, Kind: 1, EntryNo: 2');
        Observer.Expect('DocNo-EntryNo-FKind-FPost', 'DocNo: D1, Kind: 1, PostDate: 01/01/24, EntryNo: 2');
        Observer.Expect('DocNo-FKind-FPost-EntryNo', 'DocNo: D1, Kind: 1, PostDate: 01/01/24, EntryNo: 2');
        Observer.Expect('DocNo-FKind-EntryNo-FPost', 'DocNo: D1, Kind: 1, PostDate: 01/01/24, EntryNo: 2');
        Observer.Expect('FPost-DocNo-EntryNo-FKind', 'PostDate: 01/01/24, DocNo: D1, Kind: 1, EntryNo: 2');
        Observer.Expect('FPost-DocNo-FKind-EntryNo', 'PostDate: 01/01/24, DocNo: D1, Kind: 1, EntryNo: 2');
        Observer.Expect('FPost-EntryNo-DocNo-FKind', 'PostDate: 01/01/24, DocNo: D1, Kind: 1, EntryNo: 2');
        Observer.Expect('FPost-EntryNo-FKind-DocNo', 'PostDate: 01/01/24, Kind: 1, DocNo: D1, EntryNo: 2');
        Observer.Expect('FPost-FKind-DocNo-EntryNo', 'PostDate: 01/01/24, Kind: 1, DocNo: D1, EntryNo: 2');
        Observer.Expect('FPost-FKind-EntryNo-DocNo', 'PostDate: 01/01/24, Kind: 1, DocNo: D1, EntryNo: 2');
        Observer.Verify();
    end;

    [Test]
    procedure PX_Query_GetFilters_TwoDataItems_FilterElements_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PxOrderTwoItems(Observer, 'EntryNo-DocNo-FPost-FKind');
        PxOrderTwoItems(Observer, 'EntryNo-DocNo-FKind-FPost');
        PxOrderTwoItems(Observer, 'EntryNo-FPost-DocNo-FKind');
        PxOrderTwoItems(Observer, 'EntryNo-FPost-FKind-DocNo');
        PxOrderTwoItems(Observer, 'EntryNo-FKind-DocNo-FPost');
        PxOrderTwoItems(Observer, 'EntryNo-FKind-FPost-DocNo');
        PxOrderTwoItems(Observer, 'FKind-DocNo-FPost-EntryNo');
        PxOrderTwoItems(Observer, 'FKind-DocNo-EntryNo-FPost');
        PxOrderTwoItems(Observer, 'FKind-FPost-DocNo-EntryNo');
        PxOrderTwoItems(Observer, 'FKind-FPost-EntryNo-DocNo');
        PxOrderTwoItems(Observer, 'FKind-EntryNo-DocNo-FPost');
        PxOrderTwoItems(Observer, 'FKind-EntryNo-FPost-DocNo');
        Observer.Expect('EntryNo-DocNo-FPost-FKind', 'DocNo: D1, PostDate: 01/01/24, Kind: 1, EntryNo: 2');
        Observer.Expect('EntryNo-DocNo-FKind-FPost', 'DocNo: D1, Kind: 1, PostDate: 01/01/24, EntryNo: 2');
        Observer.Expect('EntryNo-FPost-DocNo-FKind', 'PostDate: 01/01/24, DocNo: D1, Kind: 1, EntryNo: 2');
        Observer.Expect('EntryNo-FPost-FKind-DocNo', 'PostDate: 01/01/24, Kind: 1, DocNo: D1, EntryNo: 2');
        Observer.Expect('EntryNo-FKind-DocNo-FPost', 'Kind: 1, DocNo: D1, PostDate: 01/01/24, EntryNo: 2');
        Observer.Expect('EntryNo-FKind-FPost-DocNo', 'Kind: 1, PostDate: 01/01/24, DocNo: D1, EntryNo: 2');
        Observer.Expect('FKind-DocNo-FPost-EntryNo', 'Kind: 1, DocNo: D1, PostDate: 01/01/24, EntryNo: 2');
        Observer.Expect('FKind-DocNo-EntryNo-FPost', 'Kind: 1, DocNo: D1, PostDate: 01/01/24, EntryNo: 2');
        Observer.Expect('FKind-FPost-DocNo-EntryNo', 'Kind: 1, PostDate: 01/01/24, DocNo: D1, EntryNo: 2');
        Observer.Expect('FKind-FPost-EntryNo-DocNo', 'Kind: 1, PostDate: 01/01/24, DocNo: D1, EntryNo: 2');
        Observer.Expect('FKind-EntryNo-DocNo-FPost', 'Kind: 1, DocNo: D1, PostDate: 01/01/24, EntryNo: 2');
        Observer.Expect('FKind-EntryNo-FPost-DocNo', 'Kind: 1, PostDate: 01/01/24, DocNo: D1, EntryNo: 2');
        Observer.Verify();
    end;
}

query 86166 "LT PX Q Outer Sum Zero"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                SqlJoinType = LeftOuterJoin;
                column(Agg; Kind)
                {
                    ColumnFilter = Agg = const(0);
                    Method = Sum;
                }
            }
        }
    }
}

query 86167 "LT PX Q Outer Sum AtLeast2"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                SqlJoinType = LeftOuterJoin;
                column(Agg; Kind)
                {
                    ColumnFilter = Agg = filter(>= 2);
                    Method = Sum;
                }
            }
        }
    }
}

query 86168 "LT PX Q Outer Average Zero"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                SqlJoinType = LeftOuterJoin;
                column(Agg; Kind)
                {
                    ColumnFilter = Agg = const(0);
                    Method = Average;
                }
            }
        }
    }
}

query 86169 "LT PX Q Outer Average AtLeast2"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                SqlJoinType = LeftOuterJoin;
                column(Agg; Kind)
                {
                    ColumnFilter = Agg = filter(>= 2);
                    Method = Average;
                }
            }
        }
    }
}

query 86170 "LT PX Q Outer Min Zero"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                SqlJoinType = LeftOuterJoin;
                column(Agg; Kind)
                {
                    ColumnFilter = Agg = const(0);
                    Method = Min;
                }
            }
        }
    }
}

query 86171 "LT PX Q Outer Min AtLeast2"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                SqlJoinType = LeftOuterJoin;
                column(Agg; Kind)
                {
                    ColumnFilter = Agg = filter(>= 2);
                    Method = Min;
                }
            }
        }
    }
}

query 86172 "LT PX Q Outer Max Zero"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                SqlJoinType = LeftOuterJoin;
                column(Agg; Kind)
                {
                    ColumnFilter = Agg = const(0);
                    Method = Max;
                }
            }
        }
    }
}

query 86173 "LT PX Q Outer Max AtLeast2"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                SqlJoinType = LeftOuterJoin;
                column(Agg; Kind)
                {
                    ColumnFilter = Agg = filter(>= 2);
                    Method = Max;
                }
            }
        }
    }
}

query 86174 "LT PX Q Two Items"
{
    QueryType = Normal;

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            filter(FPost; PostDate) { }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                filter(FKind; Kind) { }
                column(EntryNo; EntryNo) { }
            }
        }
    }
}

query 86175 "LT PX Q Outer All Aggregates"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                SqlJoinType = LeftOuterJoin;
                column(SumKind; Kind) { Method = Sum; }
                column(AvgKind; Kind) { Method = Average; }
                column(MinKind; Kind) { Method = Min; }
                column(MaxKind; Kind) { Method = Max; }
            }
        }
    }
}
