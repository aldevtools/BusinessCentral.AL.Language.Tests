// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: tables 72622-72624, queries of P71Queries.al, Probe Observer (codeunit 69160), Seed (72625)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Count, Sum, Min, Max and Average over an outer-joined column, grouped by the parent item
// BC versions: 29 (27 and 28 by CI)

codeunit 72810 "LT P71 Agg Grouped"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Group_Inner()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 A Grp Inner";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.CntAll) + '|' + Format(Q.SumCost) + '|' + Format(Q.MinRank) + '|' + Format(Q.MaxRank) + '|' + Format(Q.AvgCost));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|2|30.75|1|2|15.375');
        Observer.Expect('r2', 'B|1|30|3|3|30');
        Observer.Expect('r3', 'C|1|0|5|5|0');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Group_Left()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 A Grp Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.CntAll) + '|' + Format(Q.SumCost) + '|' + Format(Q.MinRank) + '|' + Format(Q.MaxRank) + '|' + Format(Q.AvgCost));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|2|30.75|1|2|15.375');
        Observer.Expect('r2', 'B|1|30|3|3|30');
        Observer.Expect('r3', 'C|1|0|5|5|0');
        Observer.Expect('r4', 'D|0|0|0|0|0');
        Observer.Expect('rows', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Group_Right()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 A Grp Right";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.CntAll) + '|' + Format(Q.SumCost) + '|' + Format(Q.MinRank) + '|' + Format(Q.MaxRank) + '|' + Format(Q.AvgCost));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '|1|40|4|4|40');
        Observer.Expect('r2', 'A|2|30.75|1|2|15.375');
        Observer.Expect('r3', 'B|1|30|3|3|30');
        Observer.Expect('r4', 'C|1|0|5|5|0');
        Observer.Expect('rows', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Group_Full()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 A Grp Full";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.CntAll) + '|' + Format(Q.SumCost) + '|' + Format(Q.MinRank) + '|' + Format(Q.MaxRank) + '|' + Format(Q.AvgCost));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '|1|40|4|4|40');
        Observer.Expect('r2', 'A|2|30.75|1|2|15.375');
        Observer.Expect('r3', 'B|1|30|3|3|30');
        Observer.Expect('r4', 'C|1|0|5|5|0');
        Observer.Expect('r5', 'D|0|0|0|0|0');
        Observer.Expect('rows', '5');
        Observer.Verify();
    end;

    [Test]
    procedure GroupStatic_Left()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 A Grp Left Static";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.CntAll) + '|' + Format(Q.SumCost) + '|' + Format(Q.MinRank) + '|' + Format(Q.MaxRank) + '|' + Format(Q.AvgCost));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|1|10.5|1|1|10.5');
        Observer.Expect('r2', 'B|1|30|3|3|30');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure GroupStatic_Right()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 A Grp Right Static";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.CntAll) + '|' + Format(Q.SumCost) + '|' + Format(Q.MinRank) + '|' + Format(Q.MaxRank) + '|' + Format(Q.AvgCost));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '|1|40|4|4|40');
        Observer.Expect('r2', 'A|1|10.5|1|1|10.5');
        Observer.Expect('r3', 'B|1|30|3|3|30');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure GroupStatic_Full()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 A Grp Full Static";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.CntAll) + '|' + Format(Q.SumCost) + '|' + Format(Q.MinRank) + '|' + Format(Q.MaxRank) + '|' + Format(Q.AvgCost));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '|1|40|4|4|40');
        Observer.Expect('r2', 'A|1|10.5|1|1|10.5');
        Observer.Expect('r3', 'B|1|30|3|3|30');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Group_Left_RuntimeItemNoD()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 A Grp Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetRange(ItemNo, 'D');
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.CntAll) + '|' + Format(Q.SumCost) + '|' + Format(Q.MinRank) + '|' + Format(Q.MaxRank) + '|' + Format(Q.AvgCost));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'D|0|0|0|0|0');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure GroupLine_Left()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 A Line Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.CntAll) + '|' + Format(Q.SumQty) + '|' + Format(Q.MinQty) + '|' + Format(Q.MaxQty) + '|' + Format(Q.AvgQty));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|2|12|5|7|6');
        Observer.Expect('r2', 'B|2|5|2|3|2.5');
        Observer.Expect('r3', 'C|1|4|4|4|4');
        Observer.Expect('r4', 'D|0|0|0|0|0');
        Observer.Expect('rows', '4');
        Observer.Verify();
    end;
}
