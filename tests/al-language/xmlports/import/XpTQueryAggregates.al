// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Fixtures.al (own tables 73406-73409, helper 73430, DT runner 73450), XmlPortFixtures.al, QueryFixtures.al, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Query columns with Count, Sum, Min, Max, Average, grouping by a plain column, empty tables and filters on aggregate columns.
// BC versions: 29 (27 and 28 by CI)

codeunit 73511 "LT XpT Query Aggregates"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure DumpG(var Q: Query "LT XpT Q Agg Group"): Text
    var
        R: Text;
    begin
        while Q.Read() do
            R += StrSubstNo('%1|%2|%3|%4|%5|%6;', Q.CategoryCol, Q.Cnt, Q.SumQty, Q.MinQty, Q.MaxQty, Format(Q.AvgAmount, 0, 9));
        exit(R);
    end;

    local procedure DumpT(var Q: Query "LT XpT Q Agg Total"): Text
    var
        R: Text;
    begin
        while Q.Read() do
            R += StrSubstNo('%1|%2|%3|%4|%5;', Q.Cnt, Q.SumQty, Q.MinQty, Q.MaxQty, Format(Q.AvgAmount, 0, 9));
        exit(R);
    end;

    [Test]
    procedure Group_ByCategory()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Agg Group";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Observer.Observe('rows', DumpG(Q));
        Observer.Expect('rows', 'A|2|30|10|20|2;B|1|30|30|30|3.5;');
        Observer.Verify();
    end;

    [Test]
    procedure Group_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Agg Group";
    begin
        Helper.Wipe();
        Q.Open();
        Observer.Observe('rows', DumpG(Q));
        Observer.Expect('rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure Group_SingleRow()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Agg Group";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a', 5, 2, true, 'A', 0D);
        Q.Open();
        Observer.Observe('rows', DumpG(Q));
        Observer.Expect('rows', 'A|1|5|5|5|2;');
        Observer.Verify();
    end;

    [Test]
    procedure Group_NegativeAndZero()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Agg Group";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a', -5, -2, true, 'A', 0D);
        Helper.AddItem(2, 'b', 0, 0, true, 'A', 0D);
        Helper.AddItem(3, 'c', 5, 1, true, 'A', 0D);
        Q.Open();
        Observer.Observe('rows', DumpG(Q));
        Observer.Expect('rows', 'A|3|0|-5|5|-0.333333333333333333;');
        Observer.Verify();
    end;

    [Test]
    procedure Group_BlankCategory()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Agg Group";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a', 1, 1, true, '', 0D);
        Helper.AddItem(2, 'b', 2, 3, true, '', 0D);
        Helper.AddItem(3, 'c', 5, 1, true, 'A', 0D);
        Q.Open();
        Observer.Observe('rows', DumpG(Q));
        Observer.Expect('rows', '|2|3|1|2|2;A|1|5|5|5|1;');
        Observer.Verify();
    end;

    [Test]
    procedure Group_AverageRounding()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Agg Group";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a', 1, 1, true, 'A', 0D);
        Helper.AddItem(2, 'b', 1, 1, true, 'A', 0D);
        Helper.AddItem(3, 'c', 1, 2, true, 'A', 0D);
        Q.Open();
        Observer.Observe('rows', DumpG(Q));
        Observer.Expect('rows', 'A|3|3|1|1|1.33333333333333333;');
        Observer.Verify();
    end;

    [Test]
    procedure Group_FilterOnQty()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Agg Group";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetFilter(SumQty, '>=0');
        Q.SetRange(MinQty, 10, 20);
        Q.Open();
        Observer.Observe('rows', DumpG(Q));
        Observer.Expect('rows', 'A|2|30|10|20|2;');
        Observer.Verify();
    end;

    [Test]
    procedure Group_CaseDifferentCategories()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Agg Group";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a', 1, 1, true, 'a', 0D);
        Helper.AddItem(2, 'b', 2, 1, true, 'A', 0D);
        Q.Open();
        Observer.Observe('rows', DumpG(Q));
        Observer.Expect('rows', 'A|2|3|1|2|1;');
        Observer.Verify();
    end;

    [Test]
    procedure Total_Seeded()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Agg Total";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Observer.Observe('rows', DumpT(Q));
        Observer.Expect('rows', '3|60|10|30|2.5;');
        Observer.Verify();
    end;

    [Test]
    procedure Total_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Agg Total";
    begin
        Helper.Wipe();
        Q.Open();
        Observer.Observe('rows', DumpT(Q));
        Observer.Expect('rows', '0|0|0|0|0;');
        Observer.Verify();
    end;

    [Test]
    procedure Total_NoMatchingRows()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Agg Total";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(MaxQty, 1000);
        Q.Open();
        Observer.Observe('rows', DumpT(Q));
        Observer.Expect('rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure Total_FilterOnSource()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Agg Total";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(SumQty, 20);
        Q.Open();
        Observer.Observe('rows', DumpT(Q));
        Observer.Expect('rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure Total_CountOnlyOneRow()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Agg Total";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a', 3, 1, true, 'A', 0D);
        Q.Open();
        Observer.Observe('read', Format(Q.Read()));
        Observer.Observe('cnt', Format(Q.Cnt));
        Observer.Observe('read2', Format(Q.Read()));
        Observer.Expect('read', 'Yes');
        Observer.Expect('cnt', '1');
        Observer.Expect('read2', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Total_AfterReopenSeesChanges()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Agg Total";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Observer.Observe('rows1', DumpT(Q));
        Q.Close();
        Helper.AddItem(9, 'z', 100, 10, true, 'Z', 0D);
        Q.Open();
        Observer.Observe('rows2', DumpT(Q));
        Observer.Expect('rows1', '3|60|10|30|2.5;');
        Observer.Expect('rows2', '4|160|10|100|4.375;');
        Observer.Verify();
    end;

    [Test]
    procedure Total_LargeAmountAverage()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Agg Total";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a', 1, 0.00001, true, 'A', 0D);
        Helper.AddItem(2, 'b', 1, 0.00002, true, 'A', 0D);
        Q.Open();
        Observer.Observe('rows', DumpT(Q));
        Observer.Expect('rows', '2|2|1|1|0.000015;');
        Observer.Verify();
    end;
}
