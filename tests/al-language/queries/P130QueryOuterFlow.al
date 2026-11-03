// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: own tables 73572-73574, queries 73575 and 73576, codeunit 73577, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a query column that reads a FlowField (Sum and Count) of the OUTER-joined (LeftOuterJoin) data item, for parents with a child that has detail rows, a child without detail rows
//   and a parent without a child; the same query with an inner join as the control
// Settles issue 130 reason 34 (Query: column Cost_of_Open_Production_Orders reads a FlowField of an outer-joined dataitem)
// BC versions: 29 (27 and 28 by CI)

table 73572 "LT P130 Q Parent"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73573 "LT P130 Q Child"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Total; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT P130 Q Detail".Amount where(ChildId = field(Id)));
        }
        field(4; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT P130 Q Detail" where(ChildId = field(Id)));
        }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByParent; ParentId) { }
    }
}

table 73574 "LT P130 Q Detail"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; ChildId; Integer) { }
        field(3; Amount; Decimal) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByChild; ChildId) { }
    }
}

query 73575 "LT P130 Outer Flow"
{
    QueryType = Normal;
    OrderBy = ascending(PId), ascending(CId);

    elements
    {
        dataitem(Parent; "LT P130 Q Parent")
        {
            column(PId; Id) { }

            dataitem(Child; "LT P130 Q Child")
            {
                DataItemLink = ParentId = Parent.Id;
                SqlJoinType = LeftOuterJoin;
                column(CId; Id) { }
                column(CTotal; Total) { }
                column(CCnt; Cnt) { }
            }
        }
    }
}

query 73576 "LT P130 Inner Flow"
{
    QueryType = Normal;
    OrderBy = ascending(PId), ascending(CId);

    elements
    {
        dataitem(Parent; "LT P130 Q Parent")
        {
            column(PId; Id) { }

            dataitem(Child; "LT P130 Q Child")
            {
                DataItemLink = ParentId = Parent.Id;
                SqlJoinType = InnerJoin;
                column(CId; Id) { }
                column(CTotal; Total) { }
                column(CCnt; Cnt) { }
            }
        }
    }
}

codeunit 73577 "LT P130 Query Outer Flow"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Parent: Record "LT P130 Q Parent";
        Child: Record "LT P130 Q Child";
        Detail: Record "LT P130 Q Detail";
    begin
        Parent.DeleteAll();
        Child.DeleteAll();
        Detail.DeleteAll();
        Parent.Id := 1;
        Parent.Insert();
        Parent.Id := 2;
        Parent.Insert();
        Parent.Id := 3;
        Parent.Insert();
        Parent.Id := 4;
        Parent.Insert();
        // parent 1: child 10 with two details, child 11 with one
        AddChild(10, 1);
        AddChild(11, 1);
        // parent 2: no child
        // parent 3: child 30 without details
        AddChild(30, 3);
        // parent 4: child 40 with one detail
        AddChild(40, 4);
        AddDetail(100, 10, 5);
        AddDetail(101, 10, 7.25);
        AddDetail(102, 11, 1);
        AddDetail(103, 40, -3);
    end;

    local procedure AddChild(Id: Integer; ParentId: Integer)
    var
        Child: Record "LT P130 Q Child";
    begin
        Child.Id := Id;
        Child.ParentId := ParentId;
        Child.Insert();
    end;

    local procedure AddDetail(Id: Integer; ChildId: Integer; Amount: Decimal)
    var
        Detail: Record "LT P130 Q Detail";
    begin
        Detail.Id := Id;
        Detail.ChildId := ChildId;
        Detail.Amount := Amount;
        Detail.Insert();
    end;

    [Test]
    procedure P130_Query_FlowFieldOfOuterJoinedItem()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P130 Outer Flow";
        i: Integer;
    begin
        Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.PId) + '|' + Format(Q.CId) + '|' + Format(Q.CTotal) + '|' + Format(Q.CCnt));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '1|10|12.25|2');
        Observer.Expect('r2', '1|11|1|1');
        Observer.Expect('r3', '2|0|0|0');
        Observer.Expect('r4', '3|30|0|0');
        Observer.Expect('r5', '4|40|-3|1');
        Observer.Expect('rows', '5');
        Observer.Verify();
    end;

    [Test]
    procedure P130_Query_FlowFieldOfInnerJoinedItem_Control()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P130 Inner Flow";
        i: Integer;
    begin
        Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.PId) + '|' + Format(Q.CId) + '|' + Format(Q.CTotal) + '|' + Format(Q.CCnt));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '1|10|12.25|2');
        Observer.Expect('r2', '1|11|1|1');
        Observer.Expect('r3', '3|30|0|0');
        Observer.Expect('r4', '4|40|-3|1');
        Observer.Expect('rows', '4');
        Observer.Verify();
    end;

    [Test]
    procedure P130_Query_FlowFieldOfOuterJoinedItem_WithFilterOnParent()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P130 Outer Flow";
        i: Integer;
    begin
        Seed();
        Q.SetRange(PId, 2, 3);
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.PId) + '|' + Format(Q.CId) + '|' + Format(Q.CTotal) + '|' + Format(Q.CCnt));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '2|0|0|0');
        Observer.Expect('r2', '3|30|0|0');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;
}
