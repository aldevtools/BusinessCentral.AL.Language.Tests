// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: tables 72622-72624, queries of P71Queries.al, Probe Observer (codeunit 69160), Seed (72625)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Outer joins when one side is empty
// BC versions: 29 (27 and 28 by CI)

codeunit 72804 "LT P71 Join Empty"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Left_LocEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Item: Record "LT P71 Item";
        Loc: Record "LT P71 Loc";
        Q: Query "LT P71 Q Left";
        i: Integer;
    begin
        Seed.Seed();
        Loc.DeleteAll();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|Alpha|||0|0||No||');
        Observer.Expect('r2', 'B|Beta|||0|0||No||');
        Observer.Expect('r3', 'C|Gamma|||0|0||No||');
        Observer.Expect('r4', 'D|Delta|||0|0||No||');
        Observer.Expect('rows', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Right_LocEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Item: Record "LT P71 Item";
        Loc: Record "LT P71 Loc";
        Q: Query "LT P71 Q Right";
        i: Integer;
    begin
        Seed.Seed();
        Loc.DeleteAll();
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
    procedure Full_LocEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Item: Record "LT P71 Item";
        Loc: Record "LT P71 Loc";
        Q: Query "LT P71 Q Full";
        i: Integer;
    begin
        Seed.Seed();
        Loc.DeleteAll();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|Alpha|||0|0||No||');
        Observer.Expect('r2', 'B|Beta|||0|0||No||');
        Observer.Expect('r3', 'C|Gamma|||0|0||No||');
        Observer.Expect('r4', 'D|Delta|||0|0||No||');
        Observer.Expect('rows', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Inner_LocEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Item: Record "LT P71 Item";
        Loc: Record "LT P71 Loc";
        Q: Query "LT P71 Q Inner";
        i: Integer;
    begin
        Seed.Seed();
        Loc.DeleteAll();
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
    procedure Left_ItemEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Item: Record "LT P71 Item";
        Loc: Record "LT P71 Loc";
        Q: Query "LT P71 Q Left";
        i: Integer;
    begin
        Seed.Seed();
        Item.DeleteAll();
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
    procedure Right_ItemEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Item: Record "LT P71 Item";
        Loc: Record "LT P71 Loc";
        Q: Query "LT P71 Q Right";
        i: Integer;
    begin
        Seed.Seed();
        Item.DeleteAll();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '||L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r2', '||L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r3', '||L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r4', '||L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r5', '||L5|Yard|5|0||No|N|C');
        Observer.Expect('rows', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Full_ItemEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Item: Record "LT P71 Item";
        Loc: Record "LT P71 Loc";
        Q: Query "LT P71 Q Full";
        i: Integer;
    begin
        Seed.Seed();
        Item.DeleteAll();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '||L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r2', '||L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r3', '||L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r4', '||L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r5', '||L5|Yard|5|0||No|N|C');
        Observer.Expect('rows', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Full_BothEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Item: Record "LT P71 Item";
        Loc: Record "LT P71 Loc";
        Q: Query "LT P71 Q Full";
        i: Integer;
    begin
        Seed.Seed();
        Item.DeleteAll();
        Loc.DeleteAll();
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
    procedure Left_StaticNoMatchAtAll()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Item: Record "LT P71 Item";
        Loc: Record "LT P71 Loc";
        Q: Query "LT P71 Q Left Static";
        i: Integer;
    begin
        Seed.Seed();
        Loc.ModifyAll(Active, false);
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
    procedure Full_StaticNoMatchAtAll()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Item: Record "LT P71 Item";
        Loc: Record "LT P71 Loc";
        Q: Query "LT P71 Q Full Static";
        i: Integer;
    begin
        Seed.Seed();
        Loc.ModifyAll(Active, false);
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
}
