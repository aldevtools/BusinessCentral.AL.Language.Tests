// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: tables 72622-72624, queries of P71Queries.al, Probe Observer (codeunit 69160), Seed (72625)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Runtime SetRange/SetFilter on a column of the outer-joined dataitem: does an unmatched parent row survive
// BC versions: 29 (27 and 28 by CI)

codeunit 72805 "LT P71 Filter Joined"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Left_SetRange_LocActiveTrue()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left";
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

    [Test]
    procedure Left_SetRange_LocActiveFalse()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetRange(LocActive, false);
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|Alpha|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r2', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('r3', 'D|Delta|||0|0||No||');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Left_SetRange_LocZoneN()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left";
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
    procedure Left_SetFilter_LocRankGe3()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetFilter(LocRank, '>=3');
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r2', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Left_SetFilter_LocZoneBlank()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetFilter(LocZone, '');
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
        Observer.Expect('r4', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('r5', 'D|Delta|||0|0||No||');
        Observer.Expect('rows', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Left_SetFilter_LocCodeBlank()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left";
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
        Observer.Expect('r1', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r2', 'A|Alpha|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r3', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r4', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('r5', 'D|Delta|||0|0||No||');
        Observer.Expect('rows', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Left_SetRange_LocRankZero()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetRange(LocRank, 0);
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
    procedure Left_SetRange_LocCostZero()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetRange(LocCost, 0);
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('r2', 'D|Delta|||0|0||No||');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Left_SetRange_LocSinceBlank()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetRange(LocSince, 0D);
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r2', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('r3', 'D|Delta|||0|0||No||');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Left_SetFilter_LocNameNotBlank()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetFilter(LocName, '<>%1', '');
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
        Observer.Expect('r4', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('rows', '4');
        Observer.Verify();
    end;
}
