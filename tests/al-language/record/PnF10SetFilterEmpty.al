// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73885, codeunit 73886
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "SetFilter(Field, '') on a Record" (Tests-SCM round 2)
// Facts: SetFilter(F, '') after SetRange(F, 1) and after SetFilter(F, '>1'), in filter group 0 and 2, with a second field filtered; GetFilters, GetFilter, HasFilter and Count after it
// BC versions: 29 (27 and 28 by CI)

table 73885 "LT PnF SFE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73886 "LT PnF SetFilter Empty"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT PnF SFE Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 4 do begin
            Row.Id := i;
            Row.Grp := i mod 2;
            Row.Insert();
        end;
    end;

    local procedure State(Name: Text; var Row: Record "LT PnF SFE Row"; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe(Name + '|filters', Row.GetFilters());
        Observer.Observe(Name + '|id_filter', Row.GetFilter(Id));
        Observer.Observe(Name + '|has', Format(Row.HasFilter()));
        Observer.Observe(Name + '|count', Format(Row.Count()));
    end;

    [Test]
    procedure SetFilterEmpty_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF SFE Row";
    begin
        Seed();
        Row.SetRange(Id, 1);
        State('range_before', Row, Observer);
        Row.SetFilter(Id, '');
        State('range_after', Row, Observer);
        Row.Reset();
        Row.SetFilter(Id, '>1');
        State('filter_before', Row, Observer);
        Row.SetFilter(Id, '');
        State('filter_after', Row, Observer);
        Observer.Expect('range_before|filters', 'Id: 1');
        Observer.Expect('range_before|id_filter', '1');
        Observer.Expect('range_before|has', 'Yes');
        Observer.Expect('range_before|count', '1');
        Observer.Expect('range_after|filters', '');
        Observer.Expect('range_after|id_filter', '');
        Observer.Expect('range_after|has', 'No');
        Observer.Expect('range_after|count', '4');
        Observer.Expect('filter_before|filters', 'Id: >1');
        Observer.Expect('filter_before|id_filter', '>1');
        Observer.Expect('filter_before|has', 'Yes');
        Observer.Expect('filter_before|count', '3');
        Observer.Expect('filter_after|filters', '');
        Observer.Expect('filter_after|id_filter', '');
        Observer.Expect('filter_after|has', 'No');
        Observer.Expect('filter_after|count', '4');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilterEmpty_SecondFieldKept()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF SFE Row";
    begin
        Seed();
        Row.SetRange(Id, 1, 3);
        Row.SetRange(Grp, 1);
        State('both_before', Row, Observer);
        Row.SetFilter(Id, '');
        State('both_after', Row, Observer);
        Observer.Observe('grp_filter', Row.GetFilter(Grp));
        Observer.Expect('both_before|filters', 'Id: 1..3, Grp: 1');
        Observer.Expect('both_before|id_filter', '1..3');
        Observer.Expect('both_before|has', 'Yes');
        Observer.Expect('both_before|count', '2');
        Observer.Expect('both_after|filters', 'Grp: 1');
        Observer.Expect('both_after|id_filter', '');
        Observer.Expect('both_after|has', 'Yes');
        Observer.Expect('both_after|count', '2');
        Observer.Expect('grp_filter', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilterEmpty_Group2()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF SFE Row";
    begin
        Seed();
        Row.SetRange(Id, 1);
        Row.FilterGroup(2);
        Row.SetRange(Id, 2);
        State('g2_before', Row, Observer);
        Row.SetFilter(Id, '');
        State('g2_after_in_g2', Row, Observer);
        Row.FilterGroup(0);
        State('g2_after_in_g0', Row, Observer);
        Observer.Observe('group', Format(Row.FilterGroup()));
        Observer.Expect('g2_before|filters', 'Id: 2');
        Observer.Expect('g2_before|id_filter', '2');
        Observer.Expect('g2_before|has', 'Yes');
        Observer.Expect('g2_before|count', '0');
        Observer.Expect('g2_after_in_g2|filters', '');
        Observer.Expect('g2_after_in_g2|id_filter', '');
        Observer.Expect('g2_after_in_g2|has', 'No');
        Observer.Expect('g2_after_in_g2|count', '1');
        Observer.Expect('g2_after_in_g0|filters', 'Id: 1');
        Observer.Expect('g2_after_in_g0|id_filter', '1');
        Observer.Expect('g2_after_in_g0|has', 'Yes');
        Observer.Expect('g2_after_in_g0|count', '1');
        Observer.Expect('group', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilterEmpty_Group2_ClearedFromGroup0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF SFE Row";
    begin
        Seed();
        Row.FilterGroup(2);
        Row.SetRange(Id, 2);
        Row.FilterGroup(0);
        Row.SetRange(Id, 1);
        Row.SetFilter(Id, '');
        State('g0_cleared', Row, Observer);
        Row.FilterGroup(2);
        State('g2_still', Row, Observer);
        Row.FilterGroup(0);
        Observer.Expect('g0_cleared|filters', '');
        Observer.Expect('g0_cleared|id_filter', '');
        Observer.Expect('g0_cleared|has', 'No');
        Observer.Expect('g0_cleared|count', '1');
        Observer.Expect('g2_still|filters', 'Id: 2');
        Observer.Expect('g2_still|id_filter', '2');
        Observer.Expect('g2_still|has', 'Yes');
        Observer.Expect('g2_still|count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilterEmpty_NoFilterBefore()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF SFE Row";
    begin
        Seed();
        Row.SetFilter(Id, '');
        State('nothing', Row, Observer);
        Row.SetFilter(Name, '');
        Observer.Observe('name_filters', Row.GetFilters());
        Observer.Expect('nothing|filters', '');
        Observer.Expect('nothing|id_filter', '');
        Observer.Expect('nothing|has', 'No');
        Observer.Expect('nothing|count', '4');
        Observer.Expect('name_filters', '');
        Observer.Verify();
    end;
}
