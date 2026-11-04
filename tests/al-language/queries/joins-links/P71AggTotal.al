// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: tables 72622-72624, queries of P71Queries.al, Probe Observer (codeunit 69160), Seed (72625)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Aggregates over an outer-joined column with no group column (one result row?), and grouped by a column of the joined table
// BC versions: 29 (27 and 28 by CI)

codeunit 72811 "LT P71 Agg Total"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Total_Inner()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 A Tot Inner";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.CntAll) + '|' + Format(Q.SumCost) + '|' + Format(Q.MinRank) + '|' + Format(Q.MaxRank) + '|' + Format(Q.AvgCost));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '4|60.75|1|5|15.1875');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Total_Left()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 A Tot Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.CntAll) + '|' + Format(Q.SumCost) + '|' + Format(Q.MinRank) + '|' + Format(Q.MaxRank) + '|' + Format(Q.AvgCost));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '4|60.75|1|5|15.1875');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Total_Right()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 A Tot Right";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.CntAll) + '|' + Format(Q.SumCost) + '|' + Format(Q.MinRank) + '|' + Format(Q.MaxRank) + '|' + Format(Q.AvgCost));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '5|100.75|1|5|20.15');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Total_Full()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 A Tot Full";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.CntAll) + '|' + Format(Q.SumCost) + '|' + Format(Q.MinRank) + '|' + Format(Q.MaxRank) + '|' + Format(Q.AvgCost));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '5|100.75|1|5|20.15');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure TotalStatic_Left()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 A Tot Left Static";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.CntAll) + '|' + Format(Q.SumCost) + '|' + Format(Q.MinRank) + '|' + Format(Q.MaxRank) + '|' + Format(Q.AvgCost));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '2|40.5|1|3|20.25');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure TotalStatic_Right()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 A Tot Right Static";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.CntAll) + '|' + Format(Q.SumCost) + '|' + Format(Q.MinRank) + '|' + Format(Q.MaxRank) + '|' + Format(Q.AvgCost));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '3|80.5|1|4|26.8333333333333333');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure ZoneGroup_Left()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 A Zone Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.LocZone) + '|' + Format(Q.CntAll) + '|' + Format(Q.SumCost) + '|' + Format(Q.MinRank) + '|' + Format(Q.MaxRank) + '|' + Format(Q.AvgCost));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '|0|0|0|0|0');
        Observer.Expect('r2', 'N|3|40.5|1|5|13.5');
        Observer.Expect('r3', 'S|1|20.25|2|2|20.25');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure ZoneGroup_Full()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 A Zone Full";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.LocZone) + '|' + Format(Q.CntAll) + '|' + Format(Q.SumCost) + '|' + Format(Q.MinRank) + '|' + Format(Q.MaxRank) + '|' + Format(Q.AvgCost));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '|1|40|4|4|40');
        Observer.Expect('r2', 'N|3|40.5|1|5|13.5');
        Observer.Expect('r3', 'S|1|20.25|2|2|20.25');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;
}
