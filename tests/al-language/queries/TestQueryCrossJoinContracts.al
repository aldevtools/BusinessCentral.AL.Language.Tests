// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sqljointype-property
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained tables 68490 and 68491, queries 68492..68494,
//                codeunit 68495
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins SqlJoinType = CrossJoin on a nested query data item without DataItemLink:
//  - the rows are the product of the two tables, in the order of the outer table's key and then the
//    inner one's (1X 1Y 2X 2Y 3X 3Y);
//  - a column filter on either side applies to its own table (the product of the filtered sets);
//    DataItemTableFilter on each data item applies too;
//  - a Sum column of the inner item sums the whole inner table for every outer row;
//  - an empty inner table gives no rows at all.
// BC versions: 27.5

table 68490 "Probe Cross A"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amt; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 68491 "Probe Cross B"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Qty; Integer) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

query 68492 "Probe Cross Join"
{
    QueryType = Normal;

    elements
    {
        dataitem(A; "Probe Cross A")
        {
            column(Id; Id) { }
            column(Amt; Amt) { }

            dataitem(B; "Probe Cross B")
            {
                SqlJoinType = CrossJoin;

                column(Code; Code) { }
                column(Qty; Qty) { }
            }
        }
    }
}

query 68493 "Probe Cross Join Filtered"
{
    QueryType = Normal;

    elements
    {
        dataitem(A; "Probe Cross A")
        {
            DataItemTableFilter = Id = filter('>=2');

            column(Id; Id) { }

            dataitem(B; "Probe Cross B")
            {
                SqlJoinType = CrossJoin;
                DataItemTableFilter = Qty = filter('>5');

                column(Code; Code) { }
            }
        }
    }
}

query 68494 "Probe Cross Join Sum"
{
    QueryType = Normal;

    elements
    {
        dataitem(A; "Probe Cross A")
        {
            column(Id; Id) { }

            dataitem(B; "Probe Cross B")
            {
                SqlJoinType = CrossJoin;

                column(SumQty; Qty)
                {
                    Method = Sum;
                }
            }
        }
    }
}

codeunit 68495 "Probe Query Cross Join"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Seed()
    var
        CrossA: Record "Probe Cross A";
        CrossB: Record "Probe Cross B";
    begin
        CrossA.DeleteAll();
        CrossB.DeleteAll();
        CrossA.Id := 1;
        CrossA.Amt := 10;
        CrossA.Insert();
        CrossA.Id := 2;
        CrossA.Amt := 20;
        CrossA.Insert();
        CrossA.Id := 3;
        CrossA.Amt := 30;
        CrossA.Insert();
        CrossB.Code := 'X';
        CrossB.Qty := 4;
        CrossB.Insert();
        CrossB.Code := 'Y';
        CrossB.Qty := 8;
        CrossB.Insert();
        Commit();
    end;

    local procedure Pairs(var CrossQuery: Query "Probe Cross Join"): Text
    var
        Result: Text;
    begin
        CrossQuery.Open();
        while CrossQuery.Read() do
            Result += Format(CrossQuery.Id) + CrossQuery.Code + ' ';
        CrossQuery.Close();
        exit(Result);
    end;

    [Test]
    procedure CrossJoin_GivesTheProductOfBothTables()
    var
        CrossQuery: Query "Probe Cross Join";
    begin
        Seed();

        Assert.AreEqual('1X 1Y 2X 2Y 3X 3Y ', Pairs(CrossQuery), 'rows');
    end;

    [Test]
    procedure CrossJoin_ColumnFilters_ApplyToTheirOwnTable()
    var
        CrossQuery: Query "Probe Cross Join";
    begin
        Seed();

        CrossQuery.SetRange(Code, 'Y');
        Assert.AreEqual('1Y 2Y 3Y ', Pairs(CrossQuery), 'filter on the inner column');

        CrossQuery.SetRange(Code);
        CrossQuery.SetRange(Id, 2);
        Assert.AreEqual('2X 2Y ', Pairs(CrossQuery), 'filter on the outer column');
    end;

    [Test]
    procedure CrossJoin_DataItemTableFilters_ApplyToBothItems()
    var
        FilteredQuery: Query "Probe Cross Join Filtered";
        Result: Text;
    begin
        Seed();

        FilteredQuery.Open();
        while FilteredQuery.Read() do
            Result += Format(FilteredQuery.Id) + FilteredQuery.Code + ' ';

        Assert.AreEqual('2Y 3Y ', Result, 'rows');
    end;

    [Test]
    procedure CrossJoin_SumOfTheInnerItem_IsTheSameForEveryOuterRow()
    var
        SumQuery: Query "Probe Cross Join Sum";
        Result: Text;
    begin
        Seed();

        SumQuery.Open();
        while SumQuery.Read() do
            Result += Format(SumQuery.Id) + '=' + Format(SumQuery.SumQty) + ' ';

        Assert.AreEqual('1=12 2=12 3=12 ', Result, 'rows');
    end;

    [Test]
    procedure CrossJoin_WithAnEmptyInnerTable_GivesNoRows()
    var
        CrossB: Record "Probe Cross B";
        CrossQuery: Query "Probe Cross Join";
    begin
        Seed();
        CrossB.DeleteAll();
        Commit();

        Assert.AreEqual('', Pairs(CrossQuery), 'rows');
    end;
}
