// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: tables 72622-72624, queries of P71Queries.al, Probe Observer (codeunit 69160), Seed (72625)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Minimal shape of the Locations-from-items query: Item (parent), Line (inner), Loc (outer joined, static filter on Code or Zone)
// BC versions: 29 (27 and 28 by CI)

codeunit 72808 "LT P71 Shape Loc From Item"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Shape_Inner_ZoneN()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 S Inner Zone";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.LineId) + '|' + Format(Q.LineQty) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocActive));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|1|5|L1|Main|N|Yes');
        Observer.Expect('r2', 'B|3|2|L3|Dock|N|Yes');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Shape_Left_ZoneN()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 S Left Zone";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.LineId) + '|' + Format(Q.LineQty) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocActive));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|1|5|L1|Main|N|Yes');
        Observer.Expect('r2', 'B|3|2|L3|Dock|N|Yes');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Shape_Right_ZoneN()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 S Right Zone";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.LineId) + '|' + Format(Q.LineQty) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocActive));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '|0|0|L5|Yard|N|No');
        Observer.Expect('r2', 'A|1|5|L1|Main|N|Yes');
        Observer.Expect('r3', 'B|3|2|L3|Dock|N|Yes');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Shape_Full_ZoneN()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 S Full Zone";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.LineId) + '|' + Format(Q.LineQty) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocActive));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '|0|0|L5|Yard|N|No');
        Observer.Expect('r2', 'A|1|5|L1|Main|N|Yes');
        Observer.Expect('r3', 'B|3|2|L3|Dock|N|Yes');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Shape_Left_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 S Left None";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.LineId) + '|' + Format(Q.LineQty) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocActive));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|1|5|L1|Main|N|Yes');
        Observer.Expect('r2', 'A|2|7|L2|Side|S|No');
        Observer.Expect('r3', 'B|3|2|L3|Dock|N|Yes');
        Observer.Expect('r4', 'B|4|3||||No');
        Observer.Expect('r5', 'C|5|4||||No');
        Observer.Expect('rows', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Shape_Left_CodeFilterL1L3()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 S Left Codes";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.LineId) + '|' + Format(Q.LineQty) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocActive));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|1|5|L1|Main|N|Yes');
        Observer.Expect('r2', 'B|3|2|L3|Dock|N|Yes');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Shape_Left_CodeNonBlank()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 S Left NonBlank";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.LineId) + '|' + Format(Q.LineQty) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocActive));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|1|5|L1|Main|N|Yes');
        Observer.Expect('r2', 'A|2|7|L2|Side|S|No');
        Observer.Expect('r3', 'B|3|2|L3|Dock|N|Yes');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Shape_Left_ParentGrpG1()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 S Left ParFilter";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.LineId) + '|' + Format(Q.LineQty) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocActive));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|1|5|L1|Main|N|Yes');
        Observer.Expect('r2', 'B|3|2|L3|Dock|N|Yes');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Shape_LineLeft_LocInner()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 S LineLeft Zone";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.LineId) + '|' + Format(Q.LineQty) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocActive));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|1|5|L1|Main|N|Yes');
        Observer.Expect('r2', 'B|3|2|L3|Dock|N|Yes');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Shape_Left_RuntimeLocActive()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 S Left None";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetRange(LocActive, true);
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.LineId) + '|' + Format(Q.LineQty) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocActive));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|1|5|L1|Main|N|Yes');
        Observer.Expect('r2', 'B|3|2|L3|Dock|N|Yes');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Shape_Left_RuntimeLocCodeBlank()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 S Left None";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetFilter(LocCode, '');
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.LineId) + '|' + Format(Q.LineQty) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocActive));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|1|5|L1|Main|N|Yes');
        Observer.Expect('r2', 'A|2|7|L2|Side|S|No');
        Observer.Expect('r3', 'B|3|2|L3|Dock|N|Yes');
        Observer.Expect('r4', 'B|4|3||||No');
        Observer.Expect('r5', 'C|5|4||||No');
        Observer.Expect('rows', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Shape_LeftZoneN_RuntimeItemNoB()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 S Left Zone";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetRange(ItemNo, 'B');
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.LineId) + '|' + Format(Q.LineQty) + '|' + Format(Q.LocCode) + '|' + Format(Q.LocName) + '|' + Format(Q.LocZone) + '|' + Format(Q.LocActive));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'B|3|2|L3|Dock|N|Yes');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;
}
