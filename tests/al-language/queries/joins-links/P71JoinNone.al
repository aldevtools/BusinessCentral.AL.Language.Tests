// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: tables 72622-72624, queries of P71Queries.al, Probe Observer (codeunit 69160), Seed (72625)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Left/Right/Full/Inner join of Item to Loc without any filter: which rows appear, null side values
// BC versions: 29 (27 and 28 by CI)

codeunit 72800 "LT P71 Join None"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Join_Inner_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Inner";
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
        Observer.Expect('r4', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('rows', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Join_Left_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left";
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
        Observer.Expect('r4', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('r5', 'D|Delta|||0|0||No||');
        Observer.Expect('rows', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Join_Right_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Right";
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
        Observer.Expect('r3', 'A|Alpha|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r4', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r5', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('rows', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Join_Full_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Full";
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
        Observer.Expect('r3', 'A|Alpha|L2|Side|2|20.25|02/02/21|No|S|A');
        Observer.Expect('r4', 'B|Beta|L3|Dock|3|30||Yes|N|B');
        Observer.Expect('r5', 'C|Gamma|L5|Yard|5|0||No|N|C');
        Observer.Expect('r6', 'D|Delta|||0|0||No||');
        Observer.Expect('rows', '6');
        Observer.Verify();
    end;

    [Test]
    procedure NullSide_Left_UnmatchedItem()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do
            if Q.ItemNo = 'D' then begin
                i += 1;
                Observer.Observe('code_blank', Format(Q.LocCode = ''));
                Observer.Observe('text_blank', Format(Q.LocName = ''));
                Observer.Observe('text_len', Format(StrLen(Q.LocName)));
                Observer.Observe('int_zero', Format(Q.LocRank = 0));
                Observer.Observe('dec_zero', Format(Q.LocCost = 0));
                Observer.Observe('date_zero', Format(Q.LocSince = 0D));
                Observer.Observe('bool_false', Format(not Q.LocActive));
                Observer.Observe('zone_blank', Format(Q.LocZone = ''));
                Observer.Observe('item_blank', Format(Q.LocItem = ''));
                Observer.Observe('int_fmt', Format(Q.LocRank));
                Observer.Observe('dec_fmt', Format(Q.LocCost));
                Observer.Observe('date_fmt', '[' + Format(Q.LocSince) + ']');
                Observer.Observe('bool_fmt', Format(Q.LocActive));
            end;
        Q.Close();
        Observer.Observe('hits', Format(i));
        Observer.Expect('code_blank', 'Yes');
        Observer.Expect('text_blank', 'Yes');
        Observer.Expect('text_len', '0');
        Observer.Expect('int_zero', 'Yes');
        Observer.Expect('dec_zero', 'Yes');
        Observer.Expect('date_zero', 'Yes');
        Observer.Expect('bool_false', 'Yes');
        Observer.Expect('zone_blank', 'Yes');
        Observer.Expect('item_blank', 'Yes');
        Observer.Expect('int_fmt', '0');
        Observer.Expect('dec_fmt', '0');
        Observer.Expect('date_fmt', '[]');
        Observer.Expect('bool_fmt', 'No');
        Observer.Expect('hits', '1');
        Observer.Verify();
    end;

    [Test]
    procedure NullSide_Right_UnmatchedLoc()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Right";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do
            if Q.LocCode = 'L4' then begin
                i += 1;
                Observer.Observe('item_blank', Format(Q.ItemNo = ''));
                Observer.Observe('name_blank', Format(Q.ItemName = ''));
                Observer.Observe('name_len', Format(StrLen(Q.ItemName)));
                Observer.Observe('loc_name', Q.LocName);
                Observer.Observe('loc_rank', Format(Q.LocRank));
                Observer.Observe('loc_cost', Format(Q.LocCost));
                Observer.Observe('loc_since', Format(Q.LocSince));
                Observer.Observe('loc_active', Format(Q.LocActive));
                Observer.Observe('loc_item', Q.LocItem);
            end;
        Q.Close();
        Observer.Observe('hits', Format(i));
        Observer.Expect('item_blank', 'Yes');
        Observer.Expect('name_blank', 'Yes');
        Observer.Expect('name_len', '0');
        Observer.Expect('loc_name', 'Lost');
        Observer.Expect('loc_rank', '4');
        Observer.Expect('loc_cost', '40');
        Observer.Expect('loc_since', '03/03/22');
        Observer.Expect('loc_active', 'Yes');
        Observer.Expect('loc_item', 'X');
        Observer.Expect('hits', '1');
        Observer.Verify();
    end;

    [Test]
    procedure NullSide_Full_BothSides()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 Q Full";
        i: Integer;
        j: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            if Q.ItemNo = 'D' then begin
                i += 1;
                Observer.Observe('d_loc_blank', Format(Q.LocCode = ''));
                Observer.Observe('d_rank', Format(Q.LocRank));
                Observer.Observe('d_active', Format(Q.LocActive));
            end;
            if Q.LocCode = 'L4' then begin
                j += 1;
                Observer.Observe('l4_item_blank', Format(Q.ItemNo = ''));
                Observer.Observe('l4_name_blank', Format(Q.ItemName = ''));
            end;
        end;
        Q.Close();
        Observer.Observe('d_hits', Format(i));
        Observer.Observe('l4_hits', Format(j));
        Observer.Expect('l4_item_blank', 'Yes');
        Observer.Expect('l4_name_blank', 'Yes');
        Observer.Expect('d_loc_blank', 'Yes');
        Observer.Expect('d_rank', '0');
        Observer.Expect('d_active', 'No');
        Observer.Expect('d_hits', '1');
        Observer.Expect('l4_hits', '1');
        Observer.Verify();
    end;
}
