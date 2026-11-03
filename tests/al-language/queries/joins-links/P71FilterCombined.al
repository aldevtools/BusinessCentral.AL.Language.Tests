// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: tables 72622-72624, queries of P71Queries.al, Probe Observer (codeunit 69160), Seed (72625)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: A static DataItemTableFilter on the joined table combined with a run time filter on columns of the same table or the parent
// BC versions: 29 (27 and 28 by CI)

codeunit 72807 "LT P71 Filter Combined"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure LeftStatic_SetRange_LocZoneN()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left Static";
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
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure LeftStatic_SetRange_LocActiveFalse()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left Static";
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
        Observer.Expect('rows', '0');
        Observer.Verify();
    end;

    [Test]
    procedure LeftStatic_SetRange_LocActiveTrue()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left Static";
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
    procedure LeftStatic_SetRange_ItemNoA()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left Static";
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
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure LeftStatic_SetRange_ItemNoC()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left Static";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetRange(ItemNo, 'C');
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
    procedure RightStatic_SetRange_LocZoneN()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Right Static";
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
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure RightStatic_SetRange_ItemNoA()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Right Static";
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
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure FullStatic_SetRange_LocZoneN()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Full Static";
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
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure FullStatic_SetRange_ItemNoD()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Full Static";
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
        Observer.Expect('rows', '0');
        Observer.Verify();
    end;

    [Test]
    procedure InnerStatic_SetRange_LocZoneN()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Inner Static";
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
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure ParLeft_SetRange_LocActiveTrue()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left ParFilter";
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
    procedure BothLeft_SetRange_ItemNoB()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left Both";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetRange(ItemNo, 'B');
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.ItemName) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocRank) + '|' + Format(Q.LocCost) + '|' + Format(Q.LocSince) + '|' + Format(Q.LocActive) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocItem));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;
}
