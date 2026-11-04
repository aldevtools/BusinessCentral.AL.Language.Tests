// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: tables 72622-72624, queries of P71Queries.al, Probe Observer (codeunit 69160), Seed (72625)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Runtime SetRange/SetFilter on columns of the outer-joined dataitem in right and full outer joins, and on the parent
// BC versions: 29 (27 and 28 by CI)

codeunit 72806 "LT P71 Filter Joined RF"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Right_SetRange_LocActiveTrue()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Right";
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
        Observer.Expect('r1', '||L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r2', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r3', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Right_SetRange_LocZoneN()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Right";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetRange(LocZone, 'N');
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r2', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r3', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Right_SetRange_ItemNoA()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Right";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetRange(ItemNo, 'A');
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r2', 'A|Alpha|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Right_SetFilter_ItemNoBlank()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Right";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetFilter(ItemNo, '');
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '||L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r2', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r3', 'A|Alpha|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r4', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r5', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('rows', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Full_SetRange_LocActiveTrue()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Full";
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
        Observer.Expect('r1', '||L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r2', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r3', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Full_SetRange_ItemNoA()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Full";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetRange(ItemNo, 'A');
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r2', 'A|Alpha|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Full_SetFilter_ItemNoBlank()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Full";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetFilter(ItemNo, '');
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '||L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r2', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r3', 'A|Alpha|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r4', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r5', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('r6', 'D|Delta|||0|0||No||');
        Observer.Expect('rows', '6');
        Observer.Verify();
    end;

    [Test]
    procedure Full_SetFilter_LocCodeBlank()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Full";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetFilter(LocCode, '');
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '||L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r2', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r3', 'A|Alpha|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r4', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r5', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('r6', 'D|Delta|||0|0||No||');
        Observer.Expect('rows', '6');
        Observer.Verify();
    end;

    [Test]
    procedure Left_SetRange_ItemNoD()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetRange(ItemNo, 'D');
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'D|Delta|||0|0||No||');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Left_SetFilter_ItemNameBeta()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetFilter(ItemName, 'Beta|Delta');
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r2', 'D|Delta|||0|0||No||');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Inner_SetRange_LocActiveTrue()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Inner";
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
        Observer.Expect('r1', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r2', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;
}
