// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: self-contained tables 69186 to 69188, queries 69188 to 69192, codeunit 69186
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// A query data item (Leaf) whose DataItemLink names a column of the GRANDPARENT (not the immediate parent) compiles and joins on that grandparent column:
// - Inner / Inner: every parent of a grandparent pairs with every leaf of that grandparent (grandparent 1: parents 11, 12 x leaves 101, 102; grandparent 2: parent 21 x leaves 103, 104);
// - LeftOuter / LeftOuter: the same rows plus one row [3,0,0] for the grandparent without parents (the missing columns read 0);
// - a middle data item with SqlJoinType = CrossJoin (no link) and a leaf linked to the grandparent: each grandparent is paired with ALL parents (11, 12, 21) and then with its own leaves;
// - the control with the leaf linked to the PARENT gives [1,11,101] [1,11,104] [1,12,102] [2,21,103]: leaf 104 carries grandparent 2 but parent 11, and shows under parent 11 of grandparent 1;
// - a Sum column of such a leaf sums the pairs: [1,6] [2,12].
// BC versions: 27.5

table 69186 "PX Grand"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 69187 "PX Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; GrandId; Integer) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 69188 "PX Leaf"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; GrandId; Integer) { }
        field(3; ParentId; Integer) { }
        field(4; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

query 69188 "PX Outer Inner"
{
    elements
    {
        dataitem(Grand; "PX Grand")
        {
            column(GrandId; Id) { }

            dataitem(Parent; "PX Parent")
            {
                DataItemLink = GrandId = Grand.Id;
                SqlJoinType = InnerJoin;

                column(ParentId; Id) { }

                dataitem(Leaf; "PX Leaf")
                {
                    DataItemLink = GrandId = Grand.Id;
                    SqlJoinType = InnerJoin;

                    column(LeafId; Id) { }
                }
            }
        }
    }
}

query 69189 "PX Outer Left"
{
    elements
    {
        dataitem(Grand; "PX Grand")
        {
            column(GrandId; Id) { }

            dataitem(Parent; "PX Parent")
            {
                DataItemLink = GrandId = Grand.Id;
                SqlJoinType = LeftOuterJoin;

                column(ParentId; Id) { }

                dataitem(Leaf; "PX Leaf")
                {
                    DataItemLink = GrandId = Grand.Id;
                    SqlJoinType = LeftOuterJoin;

                    column(LeafId; Id) { }
                }
            }
        }
    }
}

query 69190 "PX Outer Cross"
{
    elements
    {
        dataitem(Grand; "PX Grand")
        {
            column(GrandId; Id) { }

            dataitem(Parent; "PX Parent")
            {
                SqlJoinType = CrossJoin;

                column(ParentId; Id) { }

                dataitem(Leaf; "PX Leaf")
                {
                    DataItemLink = GrandId = Grand.Id;
                    SqlJoinType = InnerJoin;

                    column(LeafId; Id) { }
                }
            }
        }
    }
}

query 69191 "PX Parent Link"
{
    elements
    {
        dataitem(Grand; "PX Grand")
        {
            column(GrandId; Id) { }

            dataitem(Parent; "PX Parent")
            {
                DataItemLink = GrandId = Grand.Id;
                SqlJoinType = InnerJoin;

                column(ParentId; Id) { }

                dataitem(Leaf; "PX Leaf")
                {
                    DataItemLink = ParentId = Parent.Id;
                    SqlJoinType = InnerJoin;

                    column(LeafId; Id) { }
                }
            }
        }
    }
}

query 69192 "PX Outer Sum"
{
    elements
    {
        dataitem(Grand; "PX Grand")
        {
            column(GrandId; Id) { }

            dataitem(Parent; "PX Parent")
            {
                DataItemLink = GrandId = Grand.Id;
                SqlJoinType = InnerJoin;

                dataitem(Leaf; "PX Leaf")
                {
                    DataItemLink = GrandId = Grand.Id;
                    SqlJoinType = InnerJoin;

                    column(LeafSum; Amount)
                    {
                        Method = Sum;
                    }
                }
            }
        }
    }
}

codeunit 69186 "PX Query Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        G: Record "PX Grand";
        P: Record "PX Parent";
        L: Record "PX Leaf";
    begin
        G.DeleteAll();
        P.DeleteAll();
        L.DeleteAll();
        G.Id := 1;
        G.Amount := 10;
        G.Insert();
        G.Id := 2;
        G.Amount := 20;
        G.Insert();
        G.Id := 3;
        G.Amount := 30;
        G.Insert();
        P.Id := 11;
        P.GrandId := 1;
        P.Insert();
        P.Id := 12;
        P.GrandId := 1;
        P.Insert();
        P.Id := 21;
        P.GrandId := 2;
        P.Insert();
        L.Id := 101;
        L.GrandId := 1;
        L.ParentId := 11;
        L.Amount := 1;
        L.Insert();
        L.Id := 102;
        L.GrandId := 1;
        L.ParentId := 12;
        L.Amount := 2;
        L.Insert();
        L.Id := 103;
        L.GrandId := 2;
        L.ParentId := 21;
        L.Amount := 4;
        L.Insert();
        L.Id := 104;
        L.GrandId := 2;
        L.ParentId := 11;
        L.Amount := 8;
        L.Insert();
    end;

    local procedure Sorted(var Rows: List of [Text]): Text
    var
        i: Integer;
        j: Integer;
        Tmp: Text;
        Result: Text;
    begin
        for i := 1 to Rows.Count() do
            for j := i + 1 to Rows.Count() do
                if Rows.Get(j) < Rows.Get(i) then begin
                    Tmp := Rows.Get(i);
                    Rows.Set(i, Rows.Get(j));
                    Rows.Set(j, Tmp);
                end;
        for i := 1 to Rows.Count() do
            Result += Rows.Get(i) + ' ';
        exit(Result);
    end;

    [Test]
    procedure Link_ToGrandparent_Inner()
    var
        Q: Query "PX Outer Inner";
        Rows: List of [Text];
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Q.Open();
        while Q.Read() do
            Rows.Add(StrSubstNo('[%1,%2,%3]', Q.GrandId, Q.ParentId, Q.LeafId));
        Observer.Observe('rows', Sorted(Rows));
        Observer.Expect('rows', '[1,11,101] [1,11,102] [1,12,101] [1,12,102] [2,21,103] [2,21,104] ');
        Observer.Verify();
    end;

    [Test]
    procedure Link_ToGrandparent_LeftOuter()
    var
        Q: Query "PX Outer Left";
        Rows: List of [Text];
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Q.Open();
        while Q.Read() do
            Rows.Add(StrSubstNo('[%1,%2,%3]', Q.GrandId, Q.ParentId, Q.LeafId));
        Observer.Observe('rows', Sorted(Rows));
        Observer.Expect('rows', '[1,11,101] [1,11,102] [1,12,101] [1,12,102] [2,21,103] [2,21,104] [3,0,0] ');
        Observer.Verify();
    end;

    [Test]
    procedure Link_ToGrandparent_UnderCrossJoin()
    var
        Q: Query "PX Outer Cross";
        Rows: List of [Text];
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Q.Open();
        while Q.Read() do
            Rows.Add(StrSubstNo('[%1,%2,%3]', Q.GrandId, Q.ParentId, Q.LeafId));
        Observer.Observe('rows', Sorted(Rows));
        Observer.Expect('rows', '[1,11,101] [1,11,102] [1,12,101] [1,12,102] [1,21,101] [1,21,102] [2,11,103] [2,11,104] [2,12,103] [2,12,104] [2,21,103] [2,21,104] ');
        Observer.Verify();
    end;

    [Test]
    procedure Link_ToParent_Control()
    var
        Q: Query "PX Parent Link";
        Rows: List of [Text];
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Q.Open();
        while Q.Read() do
            Rows.Add(StrSubstNo('[%1,%2,%3]', Q.GrandId, Q.ParentId, Q.LeafId));
        Observer.Observe('rows', Sorted(Rows));
        Observer.Expect('rows', '[1,11,101] [1,11,104] [1,12,102] [2,21,103] ');
        Observer.Verify();
    end;

    [Test]
    procedure Link_ToGrandparent_SumColumn()
    var
        Q: Query "PX Outer Sum";
        Rows: List of [Text];
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Q.Open();
        while Q.Read() do
            Rows.Add(StrSubstNo('[%1,%2]', Q.GrandId, Q.LeafSum));
        Observer.Observe('rows', Sorted(Rows));
        Observer.Expect('rows', '[1,6] [2,12] ');
        Observer.Verify();
    end;
}
