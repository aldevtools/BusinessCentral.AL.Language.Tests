// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table 72678, test codeunit 72679 (P85)
// Probe: written against BC 29 (P85); the facts are measured later on a local BC 29 service tier.
// Facts: SetFilter(F, '') after SetRange / SetFilter on the same field, in filter group 0 and 2, FilterGroup restored: GetFilters, GetFilter, Count, HasFilter; format argument and FieldRef forms
// BC versions: 29

table 72678 "LT P85 Flt"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Num; Integer) { }
        field(4; Dec; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 72679 "LT P85 Blank Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P85 Flt";
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 4 do begin
            R.Init();
            R.Id := i;
            R.Name := 'N' + Format(i);
            R.Num := i * 10;
            R.Dec := i / 2;
            R.Insert();
        end;
    end;

    local procedure Snap(var R: Record "LT P85 Flt"): Text
    begin
        exit(R.GetFilters() + '|' + R.GetFilter(Id) + '|' + Format(R.Count()) + '|' + Format(R.HasFilter()));
    end;

    [Test]
    procedure Blank_AfterSetRange_Group0()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetRange(Id, 1);
        Observer.Observe('before', Snap(R));
        R.SetFilter(Id, '');
        Observer.Observe('after', Snap(R));
        Observer.Observe('getfilters', R.GetFilters());
        Observer.Observe('getfilter', R.GetFilter(Id));
        Observer.Observe('count', Format(R.Count()));
        Observer.Observe('hasfilter', Format(R.HasFilter()));
        Observer.Observe('getview', R.GetView());
        R.SetFilter(Id, '');
        Observer.Observe('again', Snap(R));
        R.SetRange(Id, 2);
        Observer.Observe('range_again', Snap(R));
        R.SetFilter(Id, '');
        Observer.Observe('blank_again', Snap(R));
        Observer.Expect('before', 'Id: 1|1|1|Yes');
        Observer.Expect('after', '||4|No');
        Observer.Expect('getfilters', '');
        Observer.Expect('getfilter', '');
        Observer.Expect('count', '4');
        Observer.Expect('hasfilter', 'No');
        Observer.Expect('getview', 'VERSION(1) SORTING(Id)');
        Observer.Expect('again', '||4|No');
        Observer.Expect('range_again', 'Id: 2|2|1|Yes');
        Observer.Expect('blank_again', '||4|No');
        Observer.Verify();
    end;

    [Test]
    procedure Blank_AfterSetFilterGt_Group0()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetFilter(Id, '>1');
        Observer.Observe('before', Snap(R));
        R.SetFilter(Id, '');
        Observer.Observe('after', Snap(R));
        Observer.Observe('getview', R.GetView());
        R.SetFilter(Id, '>1');
        R.SetFilter(Id, '<>%1', 0);
        Observer.Observe('replaced', Snap(R));
        R.SetFilter(Id, '');
        Observer.Observe('blank', Snap(R));
        R.SetFilter(Id, '2..3');
        Observer.Observe('range', Snap(R));
        R.SetFilter(Id, '');
        Observer.Observe('blank2', Snap(R));
        Observer.Expect('before', 'Id: >1|>1|3|Yes');
        Observer.Expect('after', '||4|No');
        Observer.Expect('getview', 'VERSION(1) SORTING(Id)');
        Observer.Expect('replaced', 'Id: <>0|<>0|4|Yes');
        Observer.Expect('blank', '||4|No');
        Observer.Expect('range', 'Id: 2..3|2..3|2|Yes');
        Observer.Expect('blank2', '||4|No');
        Observer.Verify();
    end;

    [Test]
    procedure Blank_Group2_AfterSetRange()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.FilterGroup(2);
        R.SetRange(Id, 1);
        Observer.Observe('g2_before', Snap(R));
        R.SetFilter(Id, '');
        Observer.Observe('g2_after', Snap(R));
        Observer.Observe('g2_getfilter', R.GetFilter(Id));
        Observer.Observe('g2_count', Format(R.Count()));
        R.FilterGroup(0);
        Observer.Observe('g0', Snap(R));
        Observer.Observe('g0_hasfilter', Format(R.HasFilter()));
        Observer.Observe('group_now', Format(R.FilterGroup()));
        Observer.Expect('g2_before', 'Id: 1|1|1|Yes');
        Observer.Expect('g2_after', '||4|No');
        Observer.Expect('g2_getfilter', '');
        Observer.Expect('g2_count', '4');
        Observer.Expect('g0', '||4|No');
        Observer.Expect('g0_hasfilter', 'No');
        Observer.Expect('group_now', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Blank_Group2_AfterSetFilterGt()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.FilterGroup(2);
        R.SetFilter(Id, '>1');
        Observer.Observe('g2_before', Snap(R));
        R.SetFilter(Id, '');
        Observer.Observe('g2_after', Snap(R));
        R.FilterGroup(0);
        Observer.Observe('g0', Snap(R));
        R.FilterGroup(2);
        Observer.Observe('g2_back', Snap(R));
        Observer.Expect('g2_before', 'Id: >1|>1|3|Yes');
        Observer.Expect('g2_after', '||4|No');
        Observer.Expect('g0', '||4|No');
        Observer.Expect('g2_back', '||4|No');
        Observer.Verify();
    end;

    [Test]
    procedure Blank_Group0_Filter_Group2_Blank()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
        OldGroup: Integer;
    begin
        Seed();
        R.SetRange(Id, 1);
        OldGroup := R.FilterGroup(2);
        Observer.Observe('old_group', Format(OldGroup));
        R.SetFilter(Id, '');
        Observer.Observe('g2_blank', Snap(R));
        R.FilterGroup(OldGroup);
        Observer.Observe('g0_after', Snap(R));
        Observer.Observe('g0_getfilters', R.GetFilters());
        R.FilterGroup(2);
        R.SetFilter(Id, '>2');
        Observer.Observe('g2_set', Snap(R));
        R.FilterGroup(0);
        Observer.Observe('g0_and', Snap(R));
        R.SetFilter(Id, '');
        Observer.Observe('g0_blank', Snap(R));
        R.FilterGroup(2);
        Observer.Observe('g2_stays', Snap(R));
        R.FilterGroup(0);
        Observer.Expect('old_group', '2');
        Observer.Expect('g2_blank', '||1|No');
        Observer.Expect('g0_after', '||1|No');
        Observer.Expect('g0_getfilters', '');
        Observer.Expect('g2_set', 'Id: >2|>2|0|Yes');
        Observer.Expect('g0_and', 'Id: 1|1|0|Yes');
        Observer.Expect('g0_blank', '||2|No');
        Observer.Expect('g2_stays', 'Id: >2|>2|2|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Blank_Group_FilterGroup_Restored_Value()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
        Old: Integer;
    begin
        Seed();
        Old := R.FilterGroup(2);
        Observer.Observe('returns_old', Format(Old));
        Observer.Observe('now', Format(R.FilterGroup()));
        R.SetRange(Id, 3);
        R.FilterGroup(Old);
        Observer.Observe('restored', Format(R.FilterGroup()));
        R.SetFilter(Id, '');
        Observer.Observe('g0_blank_g2_kept', Snap(R));
        R.FilterGroup(2);
        Observer.Observe('g2_view', R.GetView());
        R.FilterGroup(0);
        Observer.Observe('g0_view', R.GetView());
        R.Reset();
        Observer.Observe('reset', Snap(R));
        R.FilterGroup(2);
        Observer.Observe('reset_g2', Snap(R));
        R.FilterGroup(0);
        Observer.Expect('returns_old', '2');
        Observer.Expect('now', '2');
        Observer.Expect('restored', '2');
        Observer.Expect('g0_blank_g2_kept', '||4|No');
        Observer.Expect('g2_view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('g0_view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('reset', '||4|No');
        Observer.Expect('reset_g2', '||4|No');
        Observer.Verify();
    end;

    [Test]
    procedure Blank_OtherFieldKept()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetRange(Id, 1, 3);
        R.SetRange(Num, 20);
        R.SetFilter(Id, '');
        Observer.Observe('after', Snap(R));
        Observer.Observe('getfilter_num', R.GetFilter(Num));
        Observer.Observe('getfilters', R.GetFilters());
        R.SetFilter(Num, '');
        Observer.Observe('both_blank', Snap(R));
        Observer.Observe('hasfilter', Format(R.HasFilter()));
        Observer.Expect('after', 'Num: 20||1|Yes');
        Observer.Expect('getfilter_num', '20');
        Observer.Expect('getfilters', 'Num: 20');
        Observer.Expect('both_blank', '||4|No');
        Observer.Expect('hasfilter', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Blank_TextAndDecimalFields()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetRange(Name, 'N1');
        R.SetFilter(Name, '');
        Observer.Observe('text_after_range', R.GetFilter(Name) + '|' + Format(R.Count()) + '|' + Format(R.HasFilter()));
        R.SetFilter(Name, '<>N1');
        R.SetFilter(Name, '');
        Observer.Observe('text_after_filter', R.GetFilter(Name) + '|' + Format(R.Count()) + '|' + Format(R.HasFilter()));
        R.Reset();
        R.SetRange(Dec, 1);
        R.SetFilter(Dec, '');
        Observer.Observe('dec_after_range', R.GetFilter(Dec) + '|' + Format(R.Count()) + '|' + Format(R.HasFilter()));
        R.SetFilter(Dec, '>1');
        R.SetFilter(Dec, '');
        Observer.Observe('dec_after_filter', R.GetFilter(Dec) + '|' + Format(R.Count()) + '|' + Format(R.HasFilter()));
        R.SetRange(Num, 10);
        R.SetFilter(Num, '');
        Observer.Observe('num_after_range', R.GetFilter(Num) + '|' + Format(R.Count()) + '|' + Format(R.HasFilter()));
        Observer.Expect('text_after_range', '|4|No');
        Observer.Expect('text_after_filter', '|4|No');
        Observer.Expect('dec_after_range', '|4|No');
        Observer.Expect('dec_after_filter', '|4|No');
        Observer.Expect('num_after_range', '|4|No');
        Observer.Verify();
    end;

    [Test]
    procedure Blank_FormatArgument()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
        Empty: Text;
        Zero: Integer;
    begin
        Seed();
        R.SetRange(Id, 1);
        R.SetFilter(Name, '%1', Empty);
        Observer.Observe('empty_text_arg', Snap(R));
        R.SetRange(Id, 1);
        R.SetFilter(Id, '%1', Zero);
        Observer.Observe('zero_arg', Snap(R));
        R.SetFilter(Id, '');
        R.SetRange(Name, 'N2');
        R.SetFilter(Name, '%1', '');
        Observer.Observe('name_empty_arg', R.GetFilter(Name) + '|' + Format(R.Count()) + '|' + Format(R.HasFilter()));
        R.SetFilter(Name, '%1|%2', '', 'N3');
        Observer.Observe('name_empty_or', R.GetFilter(Name) + '|' + Format(R.Count()));
        R.SetFilter(Name, ' ');
        Observer.Observe('name_space', R.GetFilter(Name) + '|' + Format(R.Count()) + '|' + Format(R.HasFilter()));
        Observer.Expect('empty_text_arg', 'Id: 1, Name: ''''|1|0|Yes');
        Observer.Expect('zero_arg', 'Id: 0, Name: ''''|0|0|Yes');
        Observer.Expect('name_empty_arg', '''''|0|Yes');
        Observer.Expect('name_empty_or', '''''|N3|1');
        Observer.Expect('name_space', '|4|No');
        Observer.Verify();
    end;

    [Test]
    procedure Blank_SetRangeNoArguments()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetRange(Id, 1);
        R.SetRange(Id);
        Observer.Observe('setrange_noargs', Snap(R));
        R.SetFilter(Id, '>1');
        R.SetRange(Id);
        Observer.Observe('setrange_noargs_after_filter', Snap(R));
        R.SetFilter(Id, '>1');
        R.SetFilter(Id, '');
        Observer.Observe('setfilter_blank', Snap(R));
        Observer.Expect('setrange_noargs', '||4|No');
        Observer.Expect('setrange_noargs_after_filter', '||4|No');
        Observer.Expect('setfilter_blank', '||4|No');
        Observer.Verify();
    end;

    [Test]
    procedure Blank_FieldRef_SetFilter()
    var
        R: Record "LT P85 Flt";
        RRef: RecordRef;
        FRef: FieldRef;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RRef.Open(Database::"LT P85 Flt");
        FRef := RRef.Field(1);
        FRef.SetRange(1);
        Observer.Observe('range', Format(RRef.Count()) + '|' + FRef.GetFilter() + '|' + Format(RRef.HasFilter()));
        FRef.SetFilter('');
        Observer.Observe('blank', Format(RRef.Count()) + '|' + FRef.GetFilter() + '|' + Format(RRef.HasFilter()));
        FRef.SetFilter('>1');
        Observer.Observe('gt', Format(RRef.Count()) + '|' + FRef.GetFilter() + '|' + Format(RRef.HasFilter()));
        FRef.SetFilter('');
        Observer.Observe('blank_gt', Format(RRef.Count()) + '|' + FRef.GetFilter() + '|' + Format(RRef.HasFilter()));
        RRef.FilterGroup(2);
        FRef.SetRange(2);
        RRef.FilterGroup(0);
        Observer.Observe('g2_set_g0_count', Format(RRef.Count()));
        RRef.FilterGroup(2);
        FRef.SetFilter('');
        Observer.Observe('g2_blank_count', Format(RRef.Count()) + '|' + Format(RRef.HasFilter()));
        RRef.FilterGroup(0);
        Observer.Observe('g0_count', Format(RRef.Count()) + '|' + Format(RRef.HasFilter()));
        RRef.Close();
        Observer.Expect('range', '1|1|Yes');
        Observer.Expect('blank', '4||No');
        Observer.Expect('gt', '3|>1|Yes');
        Observer.Expect('blank_gt', '4||No');
        Observer.Expect('g2_set_g0_count', '1');
        Observer.Expect('g2_blank_count', '4|No');
        Observer.Expect('g0_count', '4|No');
        Observer.Verify();
    end;
}
