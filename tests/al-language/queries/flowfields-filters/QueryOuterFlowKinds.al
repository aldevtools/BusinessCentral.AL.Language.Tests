// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 95710-95713, queries 95714-95717, test codeunit 95724
// local object: the FlowField kinds (Sum, negative Sum, Count, Exist, Min, Max, Average, Lookup) and the FlowFilter of a joined table are the subject of the probe; no shared fixture has them
// Probe: written for al-runner issues 6988 and 6989 (follow-ups to 6174); every literal asserted below is what BC produced in the corpus CI.
// Facts: a plain query column over a FlowField of the JOINED data item, for every FlowField kind (Sum, negative Sum, Count, Exist, Min,
//   Max, Average, Lookup), with a LeftOuterJoin and with an InnerJoin as the control; rows for a parent with two children, a parent
//   without a child, a child without detail rows and a child whose Lookup finds no row. A negative-Sum column of a left-outer-joined
//   child that has a left-outer-joined child of its own, with a ColumnFilter on another column of the child and a run time filter on a
//   filter() element of the grandchild (the shape of issue 6988).
//   Rows: parents 1 (children 10, 11), 2 (no child), 3 (child 30 without details), 4 (child 40); child 50 has no parent.
//   Details: 10 -> 5 (day 1), 7.25 (day 2); 11 -> 1 (day 1); 40 -> -3 (day 2), 4 (day 1).
// BC versions: 27, 28, 29 (by CI)

table 95710 "QOF Parent"
{
    DataClassification = SystemMetadata;

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

table 95711 "QOF Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; RefCode; Code[10]) { }
        field(4; Kind; Code[10]) { }
        field(10; Total; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("QOF Detail".Amount where(ChildId = field(Id), Day = field("Day Filter")));
        }
        field(11; NegTotal; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = - sum("QOF Detail".Amount where(ChildId = field(Id)));
        }
        field(12; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("QOF Detail" where(ChildId = field(Id), Day = field("Day Filter")));
        }
        field(13; HasDetail; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("QOF Detail" where(ChildId = field(Id)));
        }
        field(14; MinAmt; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = min("QOF Detail".Amount where(ChildId = field(Id)));
        }
        field(15; MaxAmt; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = max("QOF Detail".Amount where(ChildId = field(Id)));
        }
        field(16; AvgAmt; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = average("QOF Detail".Amount where(ChildId = field(Id)));
        }
        field(17; ParentName; Text[30])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("QOF Parent".Name where(Id = field(ParentId)));
        }
        field(18; RefName; Text[30])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("QOF Ref".Name where(Code = field(RefCode)));
        }
        field(20; "Day Filter"; Integer) { FieldClass = FlowFilter; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByParent; ParentId) { }
    }
}

table 95712 "QOF Detail"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ChildId; Integer) { }
        field(3; Amount; Decimal) { }
        field(4; Day; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByChild; ChildId) { }
    }
}

table 95713 "QOF Ref"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

query 95714 "QOF Outer Kinds"
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
                column(Total; Total) { }
                column(NegTotal; NegTotal) { }
                column(Cnt; Cnt) { }
                column(HasDetail; HasDetail) { }
                column(MinAmt; MinAmt) { }
                column(MaxAmt; MaxAmt) { }
                column(AvgAmt; AvgAmt) { }
                column(ParentName; ParentName) { }
                column(RefName; RefName) { }
            }
        }
    }
}

query 95715 "QOF Inner Kinds"
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
                column(Total; Total) { }
                column(NegTotal; NegTotal) { }
                column(Cnt; Cnt) { }
                column(HasDetail; HasDetail) { }
                column(MinAmt; MinAmt) { }
                column(MaxAmt; MaxAmt) { }
                column(AvgAmt; AvgAmt) { }
                column(ParentName; ParentName) { }
                column(RefName; RefName) { }
            }
        }
    }
}

query 95716 "QOF Outer Grandchild"
{
    QueryType = Normal;
    OrderBy = ascending(PId), ascending(CId), ascending(DId);

    elements
    {
        dataitem(Parent; "QOF Parent")
        {
            column(PId; Id) { }

            dataitem(Child; "QOF Child")
            {
                DataItemLink = ParentId = Parent.Id;
                SqlJoinType = LeftOuterJoin;
                column(Kind; Kind) { ColumnFilter = Kind = const('A'); }
                column(CId; Id) { }
                column(NegTotal; NegTotal) { }

                dataitem(Detail; "QOF Detail")
                {
                    DataItemLink = ChildId = Child.Id;
                    SqlJoinType = LeftOuterJoin;
                    filter(DDay; Day) { }
                    column(DId; Id) { }
                }
            }
        }
    }
}

query 95717 "QOF Outer Grandchild Open"
{
    QueryType = Normal;
    OrderBy = ascending(PId), ascending(CId), ascending(DId);

    elements
    {
        dataitem(Parent; "QOF Parent")
        {
            column(PId; Id) { }

            dataitem(Child; "QOF Child")
            {
                DataItemLink = ParentId = Parent.Id;
                SqlJoinType = LeftOuterJoin;
                column(Kind; Kind) { }
                column(CId; Id) { }
                column(NegTotal; NegTotal) { }

                dataitem(Detail; "QOF Detail")
                {
                    DataItemLink = ChildId = Child.Id;
                    SqlJoinType = LeftOuterJoin;
                    filter(DDay; Day) { }
                    column(DId; Id) { }
                }
            }
        }
    }
}

codeunit 95718 "QOF Seed"
{
    procedure Seed()
    var
        Parent: Record "QOF Parent";
        Child: Record "QOF Child";
        Detail: Record "QOF Detail";
        Ref: Record "QOF Ref";
    begin
        Parent.DeleteAll();
        Child.DeleteAll();
        Detail.DeleteAll();
        Ref.DeleteAll();
        AddParent(1, 'P-One');
        AddParent(2, 'P-Two');
        AddParent(3, 'P-Three');
        AddParent(4, 'P-Four');
        Ref.Code := 'R1';
        Ref.Name := 'Ref One';
        Ref.Insert();
        Ref.Code := 'R2';
        Ref.Name := 'Ref Two';
        Ref.Insert();
        AddChild(10, 1, 'R1', 'A');
        AddChild(11, 1, '', 'B');
        AddChild(30, 3, 'R2', 'A');
        AddChild(40, 4, 'RX', 'A');
        AddChild(50, 99, 'R1', 'A');
        AddDetail(100, 10, 5, 1);
        AddDetail(101, 10, 7.25, 2);
        AddDetail(102, 11, 1, 1);
        AddDetail(103, 40, -3, 2);
        AddDetail(104, 40, 4, 1);
    end;

    local procedure AddParent(Id: Integer; Name: Text[30])
    var
        Parent: Record "QOF Parent";
    begin
        Parent.Id := Id;
        Parent.Name := Name;
        Parent.Insert();
    end;

    local procedure AddChild(Id: Integer; ParentId: Integer; RefCode: Code[10]; Kind: Code[10])
    var
        Child: Record "QOF Child";
    begin
        Child.Id := Id;
        Child.ParentId := ParentId;
        Child.RefCode := RefCode;
        Child.Kind := Kind;
        Child.Insert();
    end;

    local procedure AddDetail(Id: Integer; ChildId: Integer; Amount: Decimal; Day: Integer)
    var
        Detail: Record "QOF Detail";
    begin
        Detail.Id := Id;
        Detail.ChildId := ChildId;
        Detail.Amount := Amount;
        Detail.Day := Day;
        Detail.Insert();
    end;
}

codeunit 95724 "QOF Outer Flow Kinds"
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
    local procedure ReadOuterSums(var Q: Query "QOF Outer Kinds"; var Rows: Text)
    begin
        Rows := '';
        Q.Open();
        while Q.Read() do
            Rows += Format(Q.PId) + ':' + Format(Q.CId) + '=' + Format(Q.Total, 0, 9) + '/' + Format(Q.NegTotal, 0, 9) + '/' + Format(Q.Cnt) + ' ';
        Q.Close();
    end;

    [TryFunction]
    local procedure ReadOuterStats(var Q: Query "QOF Outer Kinds"; var Rows: Text)
    begin
        Rows := '';
        Q.Open();
        while Q.Read() do
            Rows += Format(Q.PId) + ':' + Format(Q.CId) + '=' + Format(Q.HasDetail, 0, 9) + '/' + Format(Q.MinAmt, 0, 9) + '/' + Format(Q.MaxAmt, 0, 9) + '/' + Format(Q.AvgAmt, 0, 9) + ' ';
        Q.Close();
    end;

    [TryFunction]
    local procedure ReadOuterLookups(var Q: Query "QOF Outer Kinds"; var Rows: Text)
    begin
        Rows := '';
        Q.Open();
        while Q.Read() do
            Rows += Format(Q.PId) + ':' + Format(Q.CId) + '=[' + Q.ParentName + ']/[' + Q.RefName + '] ';
        Q.Close();
    end;

    [TryFunction]
    local procedure ReadInnerAll(var Q: Query "QOF Inner Kinds"; var Rows: Text)
    begin
        Rows := '';
        Q.Open();
        while Q.Read() do
            Rows += Format(Q.PId) + ':' + Format(Q.CId) + '=' + Format(Q.Total, 0, 9) + '/' + Format(Q.NegTotal, 0, 9) + '/' + Format(Q.Cnt) + '/' +
                Format(Q.HasDetail, 0, 9) + '/' + Format(Q.MinAmt, 0, 9) + '/' + Format(Q.MaxAmt, 0, 9) + '/' + Format(Q.AvgAmt, 0, 9) + '/[' +
                Q.ParentName + ']/[' + Q.RefName + '] ';
        Q.Close();
    end;

    [TryFunction]
    local procedure ReadGrandchild(var Q: Query "QOF Outer Grandchild"; var Rows: Text)
    begin
        Rows := '';
        Q.Open();
        while Q.Read() do
            Rows += Format(Q.PId) + ':' + Format(Q.CId) + ':' + Format(Q.DId) + '=' + Q.Kind + '/' + Format(Q.NegTotal, 0, 9) + ' ';
        Q.Close();
    end;

    [TryFunction]
    local procedure ReadGrandchildOpen(var Q: Query "QOF Outer Grandchild Open"; var Rows: Text)
    begin
        Rows := '';
        Q.Open();
        while Q.Read() do
            Rows += Format(Q.PId) + ':' + Format(Q.CId) + ':' + Format(Q.DId) + '=' + Q.Kind + '/' + Format(Q.NegTotal, 0, 9) + ' ';
        Q.Close();
    end;

    [Test]
    procedure OuterFlowField_SumNegSumCount_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Seeder: Codeunit "QOF Seed";
        Q: Query "QOF Outer Kinds";
        Rows: Text;
    begin
        Seeder.Seed();
        if ReadOuterSums(Q, Rows) then
            Observer.Observe('rows', Rows)
        else
            Observer.Observe('rows', Err());
        Clear(Q);
        Q.SetRange(PId, 2, 3);
        if ReadOuterSums(Q, Rows) then
            Observer.Observe('parent 2..3', Rows)
        else
            Observer.Observe('parent 2..3', Err());
        Observer.Finish();
    end;

    [Test]
    procedure OuterFlowField_ExistMinMaxAverage_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Seeder: Codeunit "QOF Seed";
        Q: Query "QOF Outer Kinds";
        Rows: Text;
    begin
        Seeder.Seed();
        if ReadOuterStats(Q, Rows) then
            Observer.Observe('rows', Rows)
        else
            Observer.Observe('rows', Err());
        Observer.Finish();
    end;

    [Test]
    procedure OuterFlowField_Lookup_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Seeder: Codeunit "QOF Seed";
        Q: Query "QOF Outer Kinds";
        Rows: Text;
    begin
        Seeder.Seed();
        if ReadOuterLookups(Q, Rows) then
            Observer.Observe('rows', Rows)
        else
            Observer.Observe('rows', Err());
        Observer.Finish();
    end;

    [Test]
    procedure InnerFlowField_AllKinds_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Seeder: Codeunit "QOF Seed";
        Q: Query "QOF Inner Kinds";
        Rows: Text;
    begin
        Seeder.Seed();
        if ReadInnerAll(Q, Rows) then
            Observer.Observe('rows', Rows)
        else
            Observer.Observe('rows', Err());
        Observer.Finish();
    end;

    [Test]
    procedure OuterFlowField_NegSumWithGrandchild_ColumnFilter()
    var
        Observer: Codeunit "Probe Observer";
        Seeder: Codeunit "QOF Seed";
        Q: Query "QOF Outer Grandchild";
        Rows: Text;
    begin
        Seeder.Seed();
        if ReadGrandchild(Q, Rows) then
            Observer.Observe('rows', Rows)
        else
            Observer.Observe('rows', Err());
        Clear(Q);
        Q.SetRange(DDay, 1);
        if ReadGrandchild(Q, Rows) then
            Observer.Observe('grandchild day 1', Rows)
        else
            Observer.Observe('grandchild day 1', Err());
        Observer.Finish();
    end;

    [Test]
    procedure OuterFlowField_NegSumWithGrandchild_NoColumnFilter()
    var
        Observer: Codeunit "Probe Observer";
        Seeder: Codeunit "QOF Seed";
        Q: Query "QOF Outer Grandchild Open";
        Rows: Text;
    begin
        Seeder.Seed();
        if ReadGrandchildOpen(Q, Rows) then
            Observer.Observe('rows', Rows)
        else
            Observer.Observe('rows', Err());
        Clear(Q);
        Q.SetRange(Kind, 'A');
        if ReadGrandchildOpen(Q, Rows) then
            Observer.Observe('child kind A', Rows)
        else
            Observer.Observe('child kind A', Err());
        Clear(Q);
        Q.SetRange(DDay, 2);
        if ReadGrandchildOpen(Q, Rows) then
            Observer.Observe('grandchild day 2', Rows)
        else
            Observer.Observe('grandchild day 2', Err());
        Observer.Finish();
    end;
}
