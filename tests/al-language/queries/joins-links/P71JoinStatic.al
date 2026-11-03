// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: tables 72622-72624, queries of P71Queries.al, Probe Observer (codeunit 69160), Seed (72625)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Join of Item to Loc where the Loc dataitem has DataItemTableFilter = Active = const(true): filter before or after the join
// BC versions: 29 (27 and 28 by CI)

codeunit 72801 "LT P71 Join Static"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Join_Inner_StaticActive()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Inner Static";
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
        Observer.Expect('r2', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Join_Left_StaticActive()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left Static";
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
        Observer.Expect('r2', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Join_Right_StaticActive()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Right Static";
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
        Observer.Expect('r1', '||L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r2', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r3', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Join_Full_StaticActive()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Full Static";
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
        Observer.Expect('r1', '||L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r2', 'A|Alpha|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r3', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Join_Left_StaticZoneN()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left Zone";
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
        Observer.Expect('r2', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r3', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Join_Left_StaticZoneBlank()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left ZoneBlank";
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
        Observer.Expect('rows', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Join_Left_StaticRank()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left Rank";
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
        Observer.Expect('r1', 'A|Alpha|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r2', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r3', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Join_Full_StaticRank()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Full Rank";
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
        Observer.Expect('r1', '||L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r2', 'A|Alpha|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r3', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r4', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('rows', '4');
        Observer.Verify();
    end;
}
