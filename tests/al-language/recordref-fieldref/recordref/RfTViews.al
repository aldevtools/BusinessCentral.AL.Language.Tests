// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-setview-method
// Scope: in-scope
// Fixtures used: tables 73000, 73001 (RfTObjects.al), codeunit 73010 (RfTHelpers.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// SetView/GetView, SetRecFilter, Mark/MarkedOnly/ClearMarks, Copy, SetTable/GetTable, Reset, filter group, CopyFilters, HasFilter, GetFilters.
// BC versions: 29 (27 and 28 by CI)

codeunit 73023 "LT RfT Views"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure View_Roundtrip()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        View: Text;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Observer.Observe('empty_view', RecRef.GetView());
        Observer.Observe('empty_view_noctl', RecRef.GetView(false));
        RecRef.Field(3).SetRange(20, 40);
        View := RecRef.GetView();
        Observer.Observe('view_range', View);
        Observer.Observe('view_range_false', RecRef.GetView(false));
        RecRef.Reset();
        Observer.Observe('after_reset', RecRef.GetView());
        RecRef.SetView(View);
        Observer.Observe('count_after_setview', Format(RecRef.Count()));
        Observer.Observe('view_again', RecRef.GetView());
        RecRef.SetView('');
        Observer.Observe('count_empty_view', Format(RecRef.Count()));
        Observer.Expect('empty_view', 'VERSION(1) SORTING(Code Caption)');
        Observer.Expect('empty_view_noctl', 'VERSION(1) SORTING(Field1)');
        Observer.Expect('view_range', 'VERSION(1) SORTING(Code Caption) WHERE(Int=FILTER(20..40))');
        Observer.Expect('view_range_false', 'VERSION(1) SORTING(Field1) WHERE(Field3=1(20..40))');
        Observer.Expect('after_reset', 'VERSION(1) SORTING(Code Caption)');
        Observer.Expect('count_after_setview', '3');
        Observer.Expect('view_again', 'VERSION(1) SORTING(Code Caption) WHERE(Int=FILTER(20..40))');
        Observer.Expect('count_empty_view', '5');
        Observer.Verify();
    end;

    [Test]
    procedure View_WithKeyAndOrder()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        RecRef.SetView('SORTING(Int,Txt) ORDER(Descending) WHERE(Int=FILTER(>=20))');
        Observer.Observe('view', RecRef.GetView());
        Observer.Observe('count', Format(RecRef.Count()));
        Observer.Observe('keyindex', Format(RecRef.CurrentKeyIndex()));
        Observer.Observe('ascending', Format(RecRef.Ascending()));
        RecRef.FindFirst();
        Observer.Observe('first', Format(RecRef.Field(1).Value));
        RecRef.SetView('SORTING(Dec)');
        Observer.Observe('keyindex_dec', Format(RecRef.CurrentKeyIndex()));
        Observer.Observe('view_dec', RecRef.GetView());
        Observer.Expect('view', 'VERSION(1) SORTING(Int,Txt Caption) ORDER(Descending) WHERE(Int=FILTER(>=20))');
        Observer.Expect('count', '4');
        Observer.Expect('keyindex', '2');
        Observer.Expect('ascending', 'No');
        Observer.Expect('first', 'D5');
        Observer.Expect('keyindex_dec', '3');
        Observer.Expect('view_dec', 'VERSION(1) SORTING(Dec) ORDER(Descending)');
        Observer.Verify();
    end;

    [Test]
    procedure SetRecFilter_Cases()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        RecRef.FindFirst();
        RecRef.Next(2);
        RecRef.SetRecFilter();
        Observer.Observe('count', Format(RecRef.Count()));
        Observer.Observe('view', RecRef.GetView());
        Observer.Observe('filter_code', RecRef.Field(1).GetFilter());
        Observer.Observe('filter_int', RecRef.Field(3).GetFilter());
        RecRef.Reset();
        RecRef.Init();
        RecRef.SetRecFilter();
        Observer.Observe('blank_pk_view', RecRef.GetView());
        Observer.Observe('blank_pk_count', Format(RecRef.Count()));
        Observer.Expect('count', '1');
        Observer.Expect('view', 'VERSION(1) SORTING(Code Caption) WHERE(Code Caption=FILTER(D3))');
        Observer.Expect('filter_code', 'D3');
        Observer.Expect('filter_int', '');
        Observer.Expect('blank_pk_view', 'VERSION(1) SORTING(Code Caption) WHERE(Code Caption=FILTER(D3))');
        Observer.Expect('blank_pk_count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Marks()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Seq: Text;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        RecRef.FindFirst();
        Observer.Observe('mark_initial', Format(RecRef.Mark()));
        RecRef.Mark(true);
        Observer.Observe('mark_set', Format(RecRef.Mark()));
        RecRef.Next(2);
        Observer.Observe('mark_other', Format(RecRef.Mark()));
        RecRef.Mark(true);
        Observer.Observe('markedonly_default', Format(RecRef.MarkedOnly()));
        RecRef.MarkedOnly(true);
        Observer.Observe('markedonly_true', Format(RecRef.MarkedOnly()));
        Observer.Observe('count_marked', Format(RecRef.Count()));
        if RecRef.FindSet() then
            repeat
                Seq += Format(RecRef.Field(1).Value) + ';';
            until RecRef.Next() = 0;
        Observer.Observe('marked_rows', Seq);
        RecRef.MarkedOnly(false);
        Observer.Observe('count_all', Format(RecRef.Count()));
        RecRef.FindFirst();
        RecRef.Mark(false);
        RecRef.MarkedOnly(true);
        Observer.Observe('count_after_unmark', Format(RecRef.Count()));
        RecRef.ClearMarks();
        Observer.Observe('count_after_clear', Format(RecRef.Count()));
        Observer.Observe('markedonly_after_clear', Format(RecRef.MarkedOnly()));
        Observer.Expect('mark_initial', 'No');
        Observer.Expect('mark_set', 'Yes');
        Observer.Expect('mark_other', 'No');
        Observer.Expect('markedonly_default', 'No');
        Observer.Expect('markedonly_true', 'Yes');
        Observer.Expect('count_marked', '2');
        Observer.Expect('marked_rows', 'D1;D3;');
        Observer.Expect('count_all', '5');
        Observer.Expect('count_after_unmark', '1');
        Observer.Expect('count_after_clear', '0');
        Observer.Expect('markedonly_after_clear', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Marks_Reset_And_Delete()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        RecRef.FindFirst();
        RecRef.Mark(true);
        RecRef.Reset();
        Observer.Observe('markedonly_after_reset', Format(RecRef.MarkedOnly()));
        Observer.Observe('mark_after_reset', Format(RecRef.Mark()));
        RecRef.MarkedOnly(true);
        Observer.Observe('count_after_reset', Format(RecRef.Count()));
        RecRef.MarkedOnly(false);
        RecRef.FindFirst();
        RecRef.Delete();
        RecRef.MarkedOnly(true);
        Observer.Observe('count_after_delete', Format(RecRef.Count()));
        Observer.Expect('markedonly_after_reset', 'No');
        Observer.Expect('mark_after_reset', 'No');
        Observer.Expect('count_after_reset', '0');
        Observer.Expect('count_after_delete', '0');
        Observer.Verify();
    end;

    [Test]
    procedure GetTable_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Temp: Record "LT RfT Data" temporary;
        Back: Record "LT RfT Data" temporary;
        Real: Record "LT RfT Data";
    begin
        Helper.Seed();
        Temp.Code := 'TT';
        Temp.Insert();
        RecRef.GetTable(Temp);
        Observer.Observe('istemp', Format(RecRef.IsTemporary()));
        Observer.Observe('count', Format(RecRef.Count()));
        RecRef.SetTable(Back);
        Observer.Observe('back_count', Format(Back.Count()));
        RecRef.GetTable(Real);
        Observer.Observe('real_istemp', Format(RecRef.IsTemporary()));
        Observer.Observe('real_count', Format(RecRef.Count()));
        RecRef.SetTable(Back);
        Observer.Observe('real_into_temp', 'no error');
        Observer.Expect('istemp', 'Yes');
        Observer.Expect('count', '1');
        Observer.Expect('back_count', '0');
        Observer.Expect('real_istemp', 'No');
        Observer.Expect('real_count', '5');
        Observer.Expect('real_into_temp', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Filter_Info()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Other: RecordRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Observer.Observe('hasfilter_none', Format(RecRef.HasFilter()));
        Observer.Observe('getfilters_none', RecRef.GetFilters());
        RecRef.Field(3).SetRange(10, 30);
        RecRef.Field(2).SetFilter('Text 1|Text 3');
        Observer.Observe('hasfilter', Format(RecRef.HasFilter()));
        Observer.Observe('getfilters', RecRef.GetFilters());
        Other.Open(73001);
        Other.SetView(RecRef.GetView());
        Observer.Observe('setview_view', Other.GetView());
        Observer.Observe('setview_count', Format(Other.Count()));
        Other.Reset();
        Observer.Observe('hasfilter_after_reset', Format(Other.HasFilter()));
        Observer.Observe('orig_hasfilter', Format(RecRef.HasFilter()));
        RecRef.Field(3).SetRange();
        Observer.Observe('getfilters_cleared_one', RecRef.GetFilters());
        Observer.Expect('hasfilter_none', 'No');
        Observer.Expect('getfilters_none', '');
        Observer.Expect('hasfilter', 'Yes');
        Observer.Expect('getfilters', 'Txt Caption: Text 1|Text 3, Int: 10..30');
        Observer.Expect('setview_view', 'VERSION(1) SORTING(Code Caption) WHERE(Txt Caption=FILTER(Text 1|Text 3),Int=FILTER(10..30))');
        Observer.Expect('setview_count', '2');
        Observer.Expect('hasfilter_after_reset', 'No');
        Observer.Expect('orig_hasfilter', 'Yes');
        Observer.Expect('getfilters_cleared_one', 'Txt Caption: Text 1|Text 3');
        Observer.Verify();
    end;

    [Test]
    procedure FilterGroup_Cases()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Observer.Observe('group_default', Format(RecRef.FilterGroup()));
        RecRef.Field(3).SetRange(10, 40);
        RecRef.FilterGroup(2);
        Observer.Observe('group_2', Format(RecRef.FilterGroup()));
        Observer.Observe('count_in_2', Format(RecRef.Count()));
        RecRef.Field(3).SetFilter('>=30');
        Observer.Observe('count_both', Format(RecRef.Count()));
        Observer.Observe('getfilters_g2', RecRef.GetFilters());
        RecRef.FilterGroup(0);
        Observer.Observe('count_group0', Format(RecRef.Count()));
        Observer.Observe('getfilters_g0', RecRef.GetFilters());
        RecRef.FilterGroup(-1);
        Observer.Observe('group_neg', 'no error');
        RecRef.FilterGroup(100);
        Observer.Observe('group_100', Format(RecRef.FilterGroup()));
        Observer.Expect('group_default', '0');
        Observer.Expect('group_2', '2');
        Observer.Expect('count_in_2', '4');
        Observer.Expect('count_both', '2');
        Observer.Expect('getfilters_g2', 'Int: >=30');
        Observer.Expect('count_group0', '2');
        Observer.Expect('getfilters_g0', 'Int: 10..40');
        Observer.Expect('group_neg', 'no error');
        Observer.Expect('group_100', '100');
        Observer.Verify();
    end;

    [Test]
    procedure LockTable_And_ReadPermission()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(73001);
        RecRef.LockTable();
        Observer.Observe('locktable', 'ok');
        Observer.Observe('readperm', Format(RecRef.ReadPermission()));
        Observer.Observe('writeperm', Format(RecRef.WritePermission()));
        Observer.Observe('hasfilter', Format(RecRef.HasFilter()));
        Observer.Expect('locktable', 'ok');
        Observer.Expect('readperm', 'Yes');
        Observer.Expect('writeperm', 'Yes');
        Observer.Expect('hasfilter', 'No');
        Observer.Verify();
    end;

    // Corpus issue 668 item 52 (writer br): RecordRef.LockTable with the Wait and VersionCheck arguments.
    [Test]
    procedure LockTable_WaitArgument_Overloads()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        // RecordRef.LockTable(true, true) raises the Wait = FALSE error (AL:LockTableBadParm) on 27.5, 28.5 and 29.0, as the lead
        // reports; LockTable(true) and LockTable(true, false) do not. Each call runs in its own asserterror block with a marker error.
        RecRef.Open(73001);
        Observer.Observe('wait true', LockOutcome(RecRef, 1));
        Observer.Observe('wait true versioncheck true', LockOutcome(RecRef, 2));
        Observer.Observe('wait true versioncheck false', LockOutcome(RecRef, 3));
        Observer.Expect('wait true', 'no error|Dialog');
        Observer.Expect('wait true versioncheck true', 'The request to lock the LT RfT Data table with a Wait parameter of FALSE is not supported.|AL:LockTableBadParm');
        Observer.Expect('wait true versioncheck false', 'no error|Dialog');
        Observer.Verify();
    end;

    // Corpus issue 668 item 52 (writer br): each Wait = false form alone on a fresh RecordRef (no earlier LockTable in the test).
    [Test]
    procedure LockTable_WaitFalse_OneArgument()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(73001);
        Observer.Observe('wait false', LockOutcome(RecRef, 4));
        Observer.Expect('wait false', 'The request to lock the LT RfT Data table with a Wait parameter of FALSE is not supported.|AL:LockTableBadParm');
        Observer.Verify();
    end;

    [Test]
    procedure LockTable_WaitFalse_VersionCheckTrue()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(73001);
        Observer.Observe('wait false versioncheck true', LockOutcome(RecRef, 5));
        Observer.Expect('wait false versioncheck true', 'The request to lock the LT RfT Data table with a Wait parameter of FALSE is not supported.|AL:LockTableBadParm');
        Observer.Verify();
    end;

    [Test]
    procedure LockTable_WaitFalse_VersionCheckFalse()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(73001);
        Observer.Observe('wait false versioncheck false', LockOutcome(RecRef, 6));
        Observer.Expect('wait false versioncheck false', 'The request to lock the LT RfT Data table with a Wait parameter of FALSE is not supported.|AL:LockTableBadParm');
        Observer.Verify();
    end;

    local procedure LockOutcome(var RecRef: RecordRef; Arm: Integer): Text
    begin
        ClearLastError();
        asserterror begin
            case Arm of
                1:
                    RecRef.LockTable(true);
                2:
                    RecRef.LockTable(true, true);
                3:
                    RecRef.LockTable(true, false);
                4:
                    RecRef.LockTable(false);
                5:
                    RecRef.LockTable(false, true);
                6:
                    RecRef.LockTable(false, false);
            end;
            Error('no error');
        end;
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // Corpus issue 668 item 55 (writer br): GetView after SetView and a later filter change on the same RecordRef.
    [Test]
    procedure View_SetViewThenFilterChange_GetView()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        RecRef.SetView('SORTING(Int) WHERE(Int=FILTER(>=20))');
        Observer.Observe('after setview', RecRef.GetView());
        RecRef.Field(3).SetRange(30);
        Observer.Observe('after setrange same field', RecRef.GetView());
        RecRef.Field(2).SetFilter('Text*');
        Observer.Observe('after setfilter other field', RecRef.GetView());
        Observer.Observe('count', Format(RecRef.Count()));
        RecRef.Field(3).SetRange();
        Observer.Observe('after clearing int', RecRef.GetView(false));
        Observer.Expect('after setview', 'VERSION(1) SORTING(Int,Txt Caption) WHERE(Int=FILTER(>=20))');
        Observer.Expect('after setrange same field', 'VERSION(1) SORTING(Int,Txt Caption) WHERE(Int=FILTER(30))');
        Observer.Expect('after setfilter other field', 'VERSION(1) SORTING(Int,Txt Caption) WHERE(Txt Caption=FILTER(Text*),Int=FILTER(30))');
        Observer.Expect('count', '1');
        Observer.Expect('after clearing int', 'VERSION(1) SORTING(Field3,Field2) WHERE(Field2=1(Text*))');
        Observer.Verify();
    end;
}
