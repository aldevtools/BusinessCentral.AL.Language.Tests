// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: tables 72622-72624, queries of P71Queries.al, Probe Observer (codeunit 69160), Seed (72625)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CrossJoin (no DataItemLink) of Item and Loc, without and with a static filter on Loc
// BC versions: 29 (27 and 28 by CI)

codeunit 72803 "LT P71 Join Cross"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Cross_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Cross";
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
        Observer.Expect('r3', 'A|Alpha|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r4', 'A|Alpha|L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r5', 'A|Alpha|L5|Yard|5|0||No|N|C');
        Observer.Expect('r6', 'B|Beta|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r7', 'B|Beta|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r8', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r9', 'B|Beta|L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r10', 'B|Beta|L5|Yard|5|0||No|N|C');
        Observer.Expect('r11', 'C|Gamma|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r12', 'C|Gamma|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r13', 'C|Gamma|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r14', 'C|Gamma|L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r15', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('r16', 'D|Delta|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r17', 'D|Delta|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r18', 'D|Delta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r19', 'D|Delta|L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r20', 'D|Delta|L5|Yard|5|0||No|N|C');
        Observer.Expect('rows', '20');
        Observer.Verify();
    end;

    [Test]
    procedure Cross_StaticActive()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Cross Static";
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
        Observer.Expect('r2', 'A|Alpha|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r3', 'A|Alpha|L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r4', 'B|Beta|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r5', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r6', 'B|Beta|L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r7', 'C|Gamma|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r8', 'C|Gamma|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r9', 'C|Gamma|L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('r10', 'D|Delta|L1|Main|1|10.5|01/01/20|Yes|N|A');
        Observer.Expect('r11', 'D|Delta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r12', 'D|Delta|L4|Lost|4|40|03/03/22|Yes||X');
        Observer.Expect('rows', '12');
        Observer.Verify();
    end;

    [Test]
    procedure Cross_Counts()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Cross";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetRange(ItemNo, 'A');
        Q.Open();
        while Q.Read() do
            i += 1;
        Q.Close();
        Observer.Observe('item_a', Format(i));
        i := 0;
        Q.SetRange(ItemNo);
        Q.SetRange(LocActive, false);
        Q.Open();
        while Q.Read() do
            i += 1;
        Q.Close();
        Observer.Observe('inactive_all_items', Format(i));
        Observer.Expect('item_a', '5');
        Observer.Expect('inactive_all_items', '8');
        Observer.Verify();
    end;
}
