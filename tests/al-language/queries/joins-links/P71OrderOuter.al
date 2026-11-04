// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: tables 72622-72624, queries of P71Queries.al, Probe Observer (codeunit 69160), Seed (72625)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: OrderBy on columns of outer-joined queries: where unmatched (null) rows sort
// BC versions: 29 (27 and 28 by CI)

codeunit 72812 "LT P71 Order Outer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Order_Left_LocCodeDesc()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left Desc";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('r2', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r3', 'A|Alpha|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r4', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r5', 'D|Delta|||0|0||No||');
        Observer.Expect('rows', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Order_Right_LocRankAsc()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Right Asc Rank";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r2', 'A|Alpha|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r3', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r4', '||L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r5', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('rows', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Order_Full_LocRankDesc()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Full Desc Rank";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('r2', '||L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r3', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r4', 'A|Alpha|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r5', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r6', 'D|Delta|||0|0||No||');
        Observer.Expect('rows', '6');
        Observer.Verify();
    end;

    [Test]
    procedure Order_Full_ItemNoDesc_LocCodeAsc()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Full Desc Item";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'D|Delta|||0|0||No||');
        Observer.Expect('r2', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('r3', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r4', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r5', 'A|Alpha|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r6', '||L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('rows', '6');
        Observer.Verify();
    end;

    [Test]
    procedure Order_LeftStatic_ItemNoDesc()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left Stat Desc";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r2', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Order_Left_LocCodeDesc_Filtered()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left Desc";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetRange(LocActive, true);
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r2', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Order_Full_LocRankDesc_ItemFiltered()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Full Desc Rank";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetFilter(ItemNo, 'A|D');
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|Alpha|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r2', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r3', 'D|Delta|||0|0||No||');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;
}
