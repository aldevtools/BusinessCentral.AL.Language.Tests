// Probe (observe only): blank-only filter values in GetFilters / GetView, SetFilter %1 with > " and wildcard-with-operator texts, a text filter on a DateFormula field,
// CopyFilter between a Code and a Text field and inside FilterGroup(2), RecordRef.FilterGroup, TestField of a Blob.
// Settles docs/probes-needed.md rows 371, 402, 932, 961, 979, 981 (batch 4). Object ids 68057 - 68063.

table 68057 "W4 Flt Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Cd; Code[20]) { }
        field(3; Txt; Text[30]) { }
        field(4; Df; DateFormula) { }
        field(5; Dt; Date) { }
        field(6; Num; Integer) { }
        field(7; Bl; Blob) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 68058 "W4 Filter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure AddTxt(Id: Integer; Txt: Text[30])
    var
        R: Record "W4 Flt Row";
    begin
        R.Id := Id;
        R.Txt := Txt;
        R.Insert();
    end;

    local procedure Ids(var R: Record "W4 Flt Row"): Text
    var
        Result: Text;
    begin
        if R.FindSet() then
            repeat
                Result += Format(R.Id) + ',';
            until R.Next() = 0;
        exit(Result);
    end;

    // ---- md:371 ----
    [Test]
    procedure BlankOnlyFilterValues_InGetFiltersAndGetView()
    var
        R: Record "W4 Flt Row";
        Observer: Codeunit "Probe Observer";
    begin
        R.SetRange(Txt, ' ');
        Observer.Observe('text_setrange_one_space_filters', '[' + R.GetFilters() + ']');
        Observer.Observe('text_setrange_one_space_view', R.GetView());
        R.Reset();
        R.SetRange(Txt, '   ');
        Observer.Observe('text_setrange_three_spaces_filters', '[' + R.GetFilters() + ']');
        Observer.Observe('text_setrange_three_spaces_view', R.GetView());
        R.Reset();
        R.SetFilter(Txt, '<>%1', ' ');
        Observer.Observe('text_setfilter_ne_space_filters', '[' + R.GetFilters() + ']');
        Observer.Observe('text_setfilter_ne_space_view', R.GetView());
        R.Reset();
        R.SetFilter(Txt, '<>%1', '');
        Observer.Observe('text_setfilter_ne_empty_filters', '[' + R.GetFilters() + ']');
        Observer.Observe('text_setfilter_ne_empty_view', R.GetView());
        R.Reset();
        R.SetRange(Cd, ' ');
        Observer.Observe('code_setrange_one_space_filters', '[' + R.GetFilters() + ']');
        Observer.Observe('code_setrange_one_space_view', R.GetView());
        R.Reset();
        R.SetFilter(Cd, '<>%1', ' ');
        Observer.Observe('code_setfilter_ne_space_filters', '[' + R.GetFilters() + ']');
        Observer.Observe('code_setfilter_ne_space_view', R.GetView());
        R.Reset();
        R.SetFilter(Txt, '''  ''');
        Observer.Observe('text_quoted_two_spaces_filters', '[' + R.GetFilters() + ']');
        Observer.Observe('text_quoted_two_spaces_view', R.GetView());
        Observer.Expect('text_setrange_one_space_filters', '[Txt: '' '']');
        Observer.Expect('text_setrange_one_space_view', 'VERSION(1) SORTING(Id) WHERE(Txt=FILTER('' ''))');
        Observer.Expect('text_setrange_three_spaces_filters', '[Txt: ''   '']');
        Observer.Expect('text_setrange_three_spaces_view', 'VERSION(1) SORTING(Id) WHERE(Txt=FILTER(''   ''))');
        Observer.Expect('text_setfilter_ne_space_filters', '[Txt: <>'' '']');
        Observer.Expect('text_setfilter_ne_space_view', 'VERSION(1) SORTING(Id) WHERE(Txt=FILTER(<>'' ''))');
        Observer.Expect('text_setfilter_ne_empty_filters', '[Txt: <>'''']');
        Observer.Expect('text_setfilter_ne_empty_view', 'VERSION(1) SORTING(Id) WHERE(Txt=FILTER(<>''''))');
        Observer.Expect('code_setrange_one_space_filters', '[Cd: '''']');
        Observer.Expect('code_setrange_one_space_view', 'VERSION(1) SORTING(Id) WHERE(Cd=FILTER(''''))');
        Observer.Expect('code_setfilter_ne_space_filters', '[Cd: <>'''']');
        Observer.Expect('code_setfilter_ne_space_view', 'VERSION(1) SORTING(Id) WHERE(Cd=FILTER(<>''''))');
        Observer.Expect('text_quoted_two_spaces_filters', '[Txt: ''  '']');
        Observer.Expect('text_quoted_two_spaces_view', 'VERSION(1) SORTING(Id) WHERE(Txt=FILTER(''  ''))');
        Observer.Verify();
    end;

    [Test]
    procedure BlankOnlyFilterValues_MatchOnlyBlankRows()
    var
        R: Record "W4 Flt Row";
        Observer: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        AddTxt(1, '');
        AddTxt(2, ' ');
        AddTxt(3, '  ');
        AddTxt(4, 'a');
        AddTxt(5, ' a');
        R.SetRange(Txt, ' ');
        Observer.Observe('setrange_one_space_ids', Ids(R));
        R.Reset();
        R.SetRange(Txt, '  ');
        Observer.Observe('setrange_two_spaces_ids', Ids(R));
        R.Reset();
        R.SetFilter(Txt, '<>%1', ' ');
        Observer.Observe('setfilter_ne_space_ids', Ids(R));
        R.Reset();
        R.SetFilter(Txt, ' a');
        Observer.Observe('setfilter_leading_space_a_filters', '[' + R.GetFilters() + ']');
        Observer.Observe('setfilter_leading_space_a_ids', Ids(R));
        R.Reset();
        R.SetRange(Txt, ' a');
        Observer.Observe('setrange_leading_space_a_filters', '[' + R.GetFilters() + ']');
        R.Reset();
        R.DeleteAll();
        Observer.Expect('setrange_one_space_ids', '1,2,3,');
        Observer.Expect('setrange_two_spaces_ids', '1,2,3,');
        Observer.Expect('setfilter_ne_space_ids', '4,5,');
        Observer.Expect('setfilter_leading_space_a_filters', '[Txt: a]');
        Observer.Expect('setfilter_leading_space_a_ids', '4,');
        Observer.Expect('setrange_leading_space_a_filters', '[Txt: '' a'']');
        Observer.Verify();
    end;

    // ---- md:932 ----
    [TryFunction]
    local procedure TrySetFilter(var R: Record "W4 Flt Row"; Pattern: Text; Value: Text)
    begin
        R.SetFilter(Txt, Pattern, Value);
    end;

    local procedure SeedSpecial()
    var
        R: Record "W4 Flt Row";
    begin
        R.DeleteAll();
        AddTxt(1, 'a>b');
        AddTxt(2, 'x"y');
        AddTxt(3, 'a&b');
        AddTxt(4, 'a|b');
        AddTxt(5, '(a)');
        AddTxt(6, 'a<b');
        AddTxt(7, 'a=b');
        AddTxt(8, 'a..b');
        AddTxt(9, 'ab');
        AddTxt(10, 'a*b');
        AddTxt(11, 'b');
    end;

    local procedure TryValue(var Observer: Codeunit "Probe Observer"; Name: Text; Value: Text)
    var
        R: Record "W4 Flt Row";
    begin
        if TrySetFilter(R, '%1', Value) then
            Observer.Observe(Name, 'filter=[' + R.GetFilter(Txt) + '] ids=' + Ids(R))
        else begin
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
    end;

    // Rows (Txt): 1 a>b, 2 x"y, 3 a&b, 4 a|b, 5 (a), 6 a<b, 7 a=b, 8 a..b, 9 ab, 10 a*b, 11 b.
    [Test]
    procedure SetFilterPercent1_GreaterThanAndDoubleQuote()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedSpecial();
        TryValue(Observer, 'gt_in_text', 'a>b');
        TryValue(Observer, 'gt_leading', '>b');
        TryValue(Observer, 'gt_trailing', 'a>');
        TryValue(Observer, 'dquote_in_text', 'x"y');
        TryValue(Observer, 'dquote_leading', '"y');
        TryValue(Observer, 'dquote_only', '"');
        Observer.Expect('gt_in_text', 'filter=[''a>b''] ids=1,');
        Observer.Expect('gt_leading', 'filter=[''>b''] ids=');
        Observer.Expect('gt_trailing', 'filter=[''a>''] ids=');
        Observer.Expect('dquote_in_text', 'filter=[x"y] ids=2,');
        Observer.Expect('dquote_leading', 'filter=["y] ids=');
        Observer.Expect('dquote_only', 'filter=["] ids=');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilterPercent1_WildcardTogetherWithOperators()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedSpecial();
        TryValue(Observer, 'star_amp', 'a*&b');
        TryValue(Observer, 'star_pipe', 'a*|b');
        TryValue(Observer, 'star_parens', '(a*)');
        TryValue(Observer, 'star_lt', 'a*<b');
        TryValue(Observer, 'star_eq', 'a*=b');
        TryValue(Observer, 'star_dotdot', 'a*..b');
        TryValue(Observer, 'question_dotdot', 'a?..b');
        TryValue(Observer, 'star_alone', '*');
        TryValue(Observer, 'star_gt', '*>*');
        TryValue(Observer, 'star_dquote', '*"*');
        Observer.Expect('star_amp', 'filter=[''a*&b''] ids=3,');
        Observer.Expect('star_pipe', 'filter=[''a*|b''] ids=4,');
        Observer.Expect('star_parens', 'filter=[''(a*)''] ids=5,');
        Observer.Expect('star_lt', 'filter=[''a*<b''] ids=6,');
        Observer.Expect('star_eq', 'filter=[''a*=b''] ids=7,');
        Observer.Expect('star_dotdot', 'filter=[''a*..b''] ids=8,');
        Observer.Expect('question_dotdot', 'filter=[''a?..b''] ids=');
        Observer.Expect('star_alone', 'filter=[=''*''] ids=');
        Observer.Expect('star_gt', 'filter=[''*>*''] ids=1,');
        Observer.Expect('star_dquote', 'filter=[*"*] ids=2,');
        Observer.Verify();
    end;

    // ---- md:979 ----
    local procedure SeedDateFormulas()
    var
        R: Record "W4 Flt Row";
        D: DateFormula;
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Insert();
        Evaluate(D, '1M');
        R.Id := 2;
        R.Df := D;
        R.Insert();
        Evaluate(D, '<CM>');
        R.Id := 3;
        R.Df := D;
        R.Insert();
    end;

    [TryFunction]
    local procedure TryDfFilter(var R: Record "W4 Flt Row"; Filter: Text)
    begin
        R.SetFilter(Df, Filter);
    end;

    local procedure DfOutcome(var Observer: Codeunit "Probe Observer"; Name: Text; Filter: Text)
    var
        R: Record "W4 Flt Row";
    begin
        if TryDfFilter(R, Filter) then
            Observer.Observe(Name, 'filter=[' + R.GetFilter(Df) + '] ids=' + Ids(R))
        else begin
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
    end;

    // Rows: 1 empty DateFormula, 2 '1M', 3 '<CM>'.
    [Test]
    procedure DateFormulaField_TextFilters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedDateFormulas();
        DfOutcome(Observer, 'empty_quotes', '''''');
        DfOutcome(Observer, 'ne_empty_quotes', '<>''''');
        DfOutcome(Observer, 'text_1M', '1M');
        DfOutcome(Observer, 'text_angle_1M', '<1M>');
        DfOutcome(Observer, 'text_CM', 'CM');
        DfOutcome(Observer, 'text_angle_CM', '<CM>');
        DfOutcome(Observer, 'text_star', '*');
        Observer.Expect('empty_quotes', 'filter=[''''] ids=1,');
        Observer.Expect('ne_empty_quotes', 'filter=[<>''''] ids=2,3,');
        Observer.Expect('text_1M', 'filter=[1M] ids=2,');
        Observer.Expect('text_angle_1M', 'error:The filter "<1M>" is not valid for the Df field on the W4 Flt Row table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.|Filter:CSide');
        Observer.Expect('text_CM', 'filter=[CM] ids=3,');
        Observer.Expect('text_angle_CM', 'error:The filter "<CM>" is not valid for the Df field on the W4 Flt Row table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.|Filter:CSide');
        Observer.Expect('text_star', 'filter=[''''] ids=1,');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormulaField_SetRange()
    var
        R: Record "W4 Flt Row";
        Empty: DateFormula;
        D: DateFormula;
        Observer: Codeunit "Probe Observer";
    begin
        SeedDateFormulas();
        R.SetRange(Df, Empty);
        Observer.Observe('setrange_empty_filter', '[' + R.GetFilter(Df) + ']');
        Observer.Observe('setrange_empty_ids', Ids(R));
        R.Reset();
        Evaluate(D, '1M');
        R.SetRange(Df, D);
        Observer.Observe('setrange_1M_filter', '[' + R.GetFilter(Df) + ']');
        Observer.Observe('setrange_1M_ids', Ids(R));
        R.Reset();
        R.SetFilter(Df, '<>%1', Empty);
        Observer.Observe('setfilter_ne_empty_var_filter', '[' + R.GetFilter(Df) + ']');
        Observer.Observe('setfilter_ne_empty_var_ids', Ids(R));
        R.DeleteAll();
        Observer.Expect('setrange_empty_filter', '['''']');
        Observer.Expect('setrange_empty_ids', '1,');
        Observer.Expect('setrange_1M_filter', '[1M]');
        Observer.Expect('setrange_1M_ids', '2,');
        Observer.Expect('setfilter_ne_empty_var_filter', '[<>'''']');
        Observer.Expect('setfilter_ne_empty_var_ids', '2,3,');
        Observer.Verify();
    end;

    // ---- md:402 ----
    [TryFunction]
    local procedure TryCopyFilterCodeToText(var Source: Record "W4 Flt Row"; var Target: Record "W4 Flt Row")
    begin
        Source.CopyFilter(Cd, Target.Txt);
    end;

    [TryFunction]
    local procedure TryCopyFilterCodeToInteger(var Source: Record "W4 Flt Row"; var Target: Record "W4 Flt Row")
    begin
        Source.CopyFilter(Cd, Target.Num);
    end;

    [TryFunction]
    local procedure TryCopyFilterDateToCode(var Source: Record "W4 Flt Row"; var Target: Record "W4 Flt Row")
    begin
        Source.CopyFilter(Dt, Target.Cd);
    end;

    [Test]
    procedure CopyFilter_CodeToText()
    var
        Source: Record "W4 Flt Row";
        Target: Record "W4 Flt Row";
        Observer: Codeunit "Probe Observer";
    begin
        Source.SetFilter(Cd, 'ab*|C');
        Target.SetRange(Txt, 'old');
        Observer.Observe('source_filters', '[' + Source.GetFilters() + ']');
        if TryCopyFilterCodeToText(Source, Target) then
            Observer.Observe('copy_code_to_text', 'ok target=[' + Target.GetFilters() + ']')
        else begin
            Observer.Observe('copy_code_to_text', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
        // An unfiltered source clears the target field.
        Source.Reset();
        Target.SetRange(Txt, 'old2');
        if TryCopyFilterCodeToText(Source, Target) then
            Observer.Observe('copy_unfiltered_source', 'ok target=[' + Target.GetFilters() + ']')
        else begin
            Observer.Observe('copy_unfiltered_source', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Expect('source_filters', '[Cd: AB*|C]');
        Observer.Expect('copy_code_to_text', 'error:The type of the constant must be compatible with that of the Txt field, and the length of the constant must not exceed the length of the field.\\Type: Text <-- Code\Field: Txt <-- Cd\Table: W4 Flt Row|NCLCSRTS:TableEqualValue');
        Observer.Expect('copy_unfiltered_source', 'error:The type of the constant must be compatible with that of the Txt field, and the length of the constant must not exceed the length of the field.\\Type: Text <-- Code\Field: Txt <-- Cd\Table: W4 Flt Row|NCLCSRTS:TableEqualValue');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFilter_DifferentTypes()
    var
        Source: Record "W4 Flt Row";
        Target: Record "W4 Flt Row";
        Observer: Codeunit "Probe Observer";
    begin
        Source.SetFilter(Cd, '1|2');
        if TryCopyFilterCodeToInteger(Source, Target) then
            Observer.Observe('copy_code_to_integer', 'ok target=[' + Target.GetFilters() + ']')
        else begin
            Observer.Observe('copy_code_to_integer', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
        Source.Reset();
        Source.SetRange(Dt, 20250101D, 20250131D);
        if TryCopyFilterDateToCode(Source, Target) then
            Observer.Observe('copy_date_to_code', 'ok target=[' + Target.GetFilters() + ']')
        else begin
            Observer.Observe('copy_date_to_code', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Expect('copy_code_to_integer', 'error:The type of the constant must be compatible with that of the Num field, and the length of the constant must not exceed the length of the field.\\Type: Integer <-- Code\Field: Num <-- Cd\Table: W4 Flt Row|NCLCSRTS:TableEqualValue');
        Observer.Expect('copy_date_to_code', 'error:The type of the constant must be compatible with that of the Cd field, and the length of the constant must not exceed the length of the field.\\Type: Code <-- Date\Field: Cd <-- Dt\Table: W4 Flt Row|NCLCSRTS:TableEqualValue');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFilter_FilterGroups()
    var
        Source: Record "W4 Flt Row";
        Target: Record "W4 Flt Row";
        Observer: Codeunit "Probe Observer";
    begin
        // The filter lives in group 2 of the source; the source is back in group 0.
        Source.FilterGroup(2);
        Source.SetRange(Cd, 'X');
        Source.FilterGroup(0);
        Source.CopyFilter(Cd, Target.Cd);
        Observer.Observe('group0_source_target_group0', '[' + Target.GetFilters() + ']');
        Target.FilterGroup(2);
        Observer.Observe('group0_source_target_group2', '[' + Target.GetFilters() + ']');
        Target.Reset();
        // The source stands in group 2 while it copies.
        Source.FilterGroup(2);
        Source.CopyFilter(Cd, Target.Cd);
        Observer.Observe('group2_source_target_group2', '[' + Target.GetFilters() + ']');
        Target.FilterGroup(0);
        Observer.Observe('group2_source_target_group0', '[' + Target.GetFilters() + ']');
        // The target stands in group 2 while it receives a group 0 filter.
        Source.Reset();
        Target.Reset();
        Source.SetRange(Cd, 'Y');
        Target.FilterGroup(2);
        Source.CopyFilter(Cd, Target.Cd);
        Observer.Observe('target_in_group2_group2', '[' + Target.GetFilters() + ']');
        Target.FilterGroup(0);
        Observer.Observe('target_in_group2_group0', '[' + Target.GetFilters() + ']');
        Observer.Expect('group0_source_target_group0', '[]');
        Observer.Expect('group0_source_target_group2', '[]');
        Observer.Expect('group2_source_target_group2', '[Cd: X]');
        Observer.Expect('group2_source_target_group0', '[Cd: X]');
        Observer.Expect('target_in_group2_group2', '[Cd: Y]');
        Observer.Expect('target_in_group2_group0', '[]');
        Observer.Verify();
    end;

    // ---- md:961 ----
    [Test]
    procedure RecordRef_FilterGroup()
    var
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        RR.Open(Database::"W4 Flt Row");
        Observer.Observe('group_initial', Format(RR.FilterGroup()));
        Observer.Observe('set_group_2_returns', Format(RR.FilterGroup(2)));
        RR.Field(2).SetRange('X');
        Observer.Observe('group2_filters', '[' + RR.GetFilters() + ']');
        Observer.Observe('set_group_0_returns', Format(RR.FilterGroup(0)));
        Observer.Observe('group0_filters', '[' + RR.GetFilters() + ']');
        Observer.Observe('group_current', Format(RR.FilterGroup()));
        RR.Field(3).SetRange('Y');
        Observer.Observe('group0_filters_after_second', '[' + RR.GetFilters() + ']');
        Observer.Observe('set_group_2_again', Format(RR.FilterGroup(2)));
        Observer.Observe('group2_filters_again', '[' + RR.GetFilters() + ']');
        RR.Reset();
        Observer.Observe('group_after_reset', Format(RR.FilterGroup()));
        Observer.Observe('group2_filters_after_reset', '[' + RR.GetFilters() + ']');
        Observer.Expect('group_initial', '0');
        Observer.Expect('set_group_2_returns', '2');
        Observer.Expect('group2_filters', '[Cd: X]');
        Observer.Expect('set_group_0_returns', '0');
        Observer.Expect('group0_filters', '[]');
        Observer.Expect('group_current', '0');
        Observer.Expect('group0_filters_after_second', '[Txt: Y]');
        Observer.Expect('set_group_2_again', '2');
        Observer.Expect('group2_filters_again', '[Cd: X]');
        Observer.Expect('group_after_reset', '0');
        Observer.Expect('group2_filters_after_reset', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_FilterGroup_GetTableAndSetTable()
    var
        R: Record "W4 Flt Row";
        Back: Record "W4 Flt Row";
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        R.FilterGroup(2);
        R.SetRange(Cd, 'X');
        R.FilterGroup(0);
        RR.GetTable(R);
        Observer.Observe('getTable_group', Format(RR.FilterGroup()));
        Observer.Observe('getTable_group0_filters', '[' + RR.GetFilters() + ']');
        RR.FilterGroup(2);
        Observer.Observe('getTable_group2_filters', '[' + RR.GetFilters() + ']');
        RR.FilterGroup(0);
        RR.Field(3).SetRange('Z');
        RR.SetTable(Back);
        Observer.Observe('settable_group', Format(Back.FilterGroup()));
        Observer.Observe('settable_group0_filters', '[' + Back.GetFilters() + ']');
        Back.FilterGroup(2);
        Observer.Observe('settable_group2_filters', '[' + Back.GetFilters() + ']');
        Observer.Expect('getTable_group', '0');
        Observer.Expect('getTable_group0_filters', '[]');
        Observer.Expect('getTable_group2_filters', '[Cd: X]');
        Observer.Expect('settable_group', '0');
        Observer.Expect('settable_group0_filters', '[Txt: Z]');
        Observer.Expect('settable_group2_filters', '[Cd: X]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryNegativeGroup(var RR: RecordRef; var Result: Text)
    begin
        Result := Format(RR.FilterGroup(-1));
    end;

    [Test]
    procedure RecordRef_FilterGroup_Negative()
    var
        RR: RecordRef;
        Result: Text;
        Observer: Codeunit "Probe Observer";
    begin
        RR.Open(Database::"W4 Flt Row");
        if TryNegativeGroup(RR, Result) then
            Observer.Observe('negative_group', 'ok:[' + Result + ']')
        else begin
            Observer.Observe('negative_group', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Expect('negative_group', 'ok:[-1]');
        Observer.Verify();
    end;

    // ---- md:981 ----
    [TryFunction]
    local procedure TryTestFieldBlob(var R: Record "W4 Flt Row")
    begin
        R.TestField(Bl);
    end;

    local procedure BlobOutcome(var R: Record "W4 Flt Row"): Text
    begin
        if TryTestFieldBlob(R) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure TestField_Blob()
    var
        R: Record "W4 Flt Row";
        OutS: OutStream;
        Observer: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Insert();
        R.Id := 2;
        R.Bl.CreateOutStream(OutS);
        OutS.WriteText('data');
        R.Insert();
        R.Id := 3;
        Clear(R.Bl);
        R.Bl.CreateOutStream(OutS);
        OutS.WriteText('');
        R.Insert();
        Clear(R);

        R.Get(1);
        Observer.Observe('empty_blob_not_calculated', BlobOutcome(R));
        ClearLastError();
        R.CalcFields(Bl);
        Observer.Observe('empty_blob_calculated', BlobOutcome(R));
        ClearLastError();
        R.Get(2);
        Observer.Observe('blob_with_data_not_calculated', BlobOutcome(R));
        ClearLastError();
        R.CalcFields(Bl);
        Observer.Observe('blob_with_data_calculated', BlobOutcome(R));
        ClearLastError();
        R.Get(3);
        R.CalcFields(Bl);
        Observer.Observe('blob_written_empty_text_calculated', BlobOutcome(R));
        ClearLastError();
        Observer.Observe('hasvalue_row_3', Format(R.Bl.HasValue()));
        R.DeleteAll();
        Observer.Expect('empty_blob_not_calculated', 'error:Bl must have a value in W4 Flt Row: Id=1. It cannot be zero or empty.|TestField');
        Observer.Expect('empty_blob_calculated', 'error:Bl must have a value in W4 Flt Row: Id=1. It cannot be zero or empty.|TestField');
        Observer.Expect('blob_with_data_not_calculated', 'ok');
        Observer.Expect('blob_with_data_calculated', 'ok');
        Observer.Expect('blob_written_empty_text_calculated', 'error:Bl must have a value in W4 Flt Row: Id=3. It cannot be zero or empty.|TestField');
        Observer.Expect('hasvalue_row_3', 'No');
        Observer.Verify();
    end;

    // ---- corpus issue 668 item 6 (writer BQ) ----
    // SetFilter with the placeholder %1 next to wildcards or operators in the filter text (microsoft/AL issues 7283 and 7631), on a Text, a
    // Code and an Integer field. Rows (Id Cd Txt Num): 1 ABC abc 18, 2 XA xa 8, 3 B b 28, 4 A a 80, 5 *8 *8 0, 6 BA Ba 5.
    local procedure BqSeedPlaceholderRows()
    var
        R: Record "W4 Flt Row";
    begin
        R.DeleteAll();
        BqAdd(1, 'ABC', 'abc', 18);
        BqAdd(2, 'XA', 'xa', 8);
        BqAdd(3, 'B', 'b', 28);
        BqAdd(4, 'A', 'a', 80);
        BqAdd(5, '*8', '*8', 0);
        BqAdd(6, 'BA', 'Ba', 5);
    end;

    local procedure BqAdd(Id: Integer; Cd: Code[20]; Txt: Text[30]; Num: Integer)
    var
        R: Record "W4 Flt Row";
    begin
        R.Init();
        R.Id := Id;
        R.Cd := Cd;
        R.Txt := Txt;
        R.Num := Num;
        R.Insert();
    end;

    [TryFunction]
    local procedure BqTrySetFilterPattern(var R: Record "W4 Flt Row"; FieldNo: Integer; Pattern: Text; Value: Text)
    begin
        case FieldNo of
            2:
                R.SetFilter(Cd, Pattern, Value);
            3:
                R.SetFilter(Txt, Pattern, Value);
        end;
    end;

    [TryFunction]
    local procedure BqTrySetFilterNumber(var R: Record "W4 Flt Row"; Pattern: Text; Value: Integer)
    begin
        R.SetFilter(Num, Pattern, Value);
    end;

    local procedure BqPattern(FieldNo: Integer; Pattern: Text; Value: Text): Text
    var
        R: Record "W4 Flt Row";
        Result: Text;
    begin
        if BqTrySetFilterPattern(R, FieldNo, Pattern, Value) then
            exit('filter=[' + R.GetFilters() + '] ids=' + Ids(R));
        Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    local procedure BqNumberPattern(Pattern: Text; Value: Integer): Text
    var
        R: Record "W4 Flt Row";
        Result: Text;
    begin
        if BqTrySetFilterNumber(R, Pattern, Value) then
            exit('filter=[' + R.GetFilters() + '] ids=' + Ids(R));
        Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    [Test]
    procedure SetFilterPercent1_WildcardsAroundThePlaceholder_BQ()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BqSeedPlaceholderRows();
        Observer.Observe('txt_star_both', BqPattern(3, '*%1*', 'a'));
        Observer.Observe('txt_at_star_both', BqPattern(3, '@*%1*', 'A'));
        Observer.Observe('txt_star_after', BqPattern(3, '%1*', 'a'));
        Observer.Observe('txt_star_before', BqPattern(3, '*%1', 'a'));
        Observer.Observe('txt_question_before', BqPattern(3, '?%1', 'a'));
        Observer.Observe('txt_lt', BqPattern(3, '<%1', 'b'));
        Observer.Observe('txt_gt', BqPattern(3, '>%1', 'b'));
        Observer.Observe('txt_ne', BqPattern(3, '<>%1', 'a'));
        Observer.Observe('txt_range_open', BqPattern(3, '%1..', 'b'));
        Observer.Observe('txt_or', BqPattern(3, '%1|b', 'a'));
        Observer.Observe('txt_and', BqPattern(3, '%1&*a*', 'a'));
        Observer.Observe('txt_value_wildcard', BqPattern(3, '%1', '*8'));
        Observer.Observe('txt_star_value_wildcard', BqPattern(3, '*%1', '8'));
        Observer.Observe('cd_star_both', BqPattern(2, '*%1*', 'a'));
        Observer.Observe('cd_star_after', BqPattern(2, '%1*', 'B'));
        Observer.Observe('cd_value_wildcard', BqPattern(2, '%1', '*8'));
        Observer.Observe('num_star_after', BqNumberPattern('%1*', 8));
        Observer.Observe('num_star_before', BqNumberPattern('*%1', 8));
        Observer.Observe('num_lt', BqNumberPattern('<%1', 10));
        Observer.Observe('num_range', BqNumberPattern('%1..', 28));
        Observer.Expect('txt_star_both', 'filter=[Txt: *%1*] ids=');
        Observer.Expect('txt_at_star_both', 'filter=[Txt: @*%1*] ids=');
        Observer.Expect('txt_star_after', 'filter=[Txt: %1*] ids=');
        Observer.Expect('txt_star_before', 'filter=[Txt: *%1] ids=');
        Observer.Expect('txt_question_before', 'filter=[Txt: ?%1] ids=');
        Observer.Expect('txt_lt', 'filter=[Txt: <b] ids=1,4,5,');
        Observer.Expect('txt_gt', 'filter=[Txt: >b] ids=2,6,');
        Observer.Expect('txt_ne', 'filter=[Txt: <>a] ids=1,2,3,5,6,');
        Observer.Expect('txt_range_open', 'filter=[Txt: b..] ids=2,3,6,');
        Observer.Expect('txt_or', 'filter=[Txt: a|b] ids=3,4,');
        Observer.Expect('txt_and', 'filter=[Txt: a&*a*] ids=4,');
        Observer.Expect('txt_value_wildcard', 'filter=[Txt: *8] ids=5,');
        Observer.Expect('txt_star_value_wildcard', 'filter=[Txt: *%1] ids=');
        Observer.Expect('cd_star_both', 'filter=[Cd: *%1*] ids=');
        Observer.Expect('cd_star_after', 'filter=[Cd: %1*] ids=');
        Observer.Expect('cd_value_wildcard', 'filter=[Cd: *8] ids=5,');
        Observer.Expect('num_star_after', 'error:The filter "%1*" is not valid for the Num field on the W4 Flt Row table. The variable "%1*" was not understood.|Filter:CSide');
        Observer.Expect('num_star_before', 'error:The filter "*%1" is not valid for the Num field on the W4 Flt Row table. The value "*%1" can''t be evaluated into type Integer.|Filter:CSide');
        Observer.Expect('num_lt', 'filter=[Num: <10] ids=2,5,6,');
        Observer.Expect('num_range', 'filter=[Num: 28..] ids=3,4,');
        Observer.Verify();
    end;

    // Writer UN (2026-10-29): '@' inside a SetView filter value, at the start and in the middle.
    local procedure UnSeedAt()
    var
        R: Record "W4 Flt Row";
    begin
        R.DeleteAll();
        BqAdd(1, 'ABC', 'abc', 0);
        BqAdd(2, 'ABCD', 'ABCD', 0);
        BqAdd(3, 'XABC', 'xabc', 0);
        BqAdd(4, 'AT1', 'a@b.dk', 0);
        BqAdd(5, 'AT2', 'A@B.DK', 0);
        BqAdd(6, 'AT3', '@abc', 0);
        BqAdd(7, 'AT4', 'ab@', 0);
        BqAdd(8, 'AT5', 'b@a.dk', 0);
    end;

    [TryFunction]
    local procedure UnTryView(View: Text; var Outcome: Text)
    var
        R: Record "W4 Flt Row";
    begin
        R.SetView(View);
        Outcome := 'ids=' + Ids(R) + '|txt=' + R.GetFilter(Txt) + '|cd=' + R.GetFilter(Cd) + '|view=' + R.GetView();
    end;

    local procedure UnViewProbe(var Observer: Codeunit "Probe Observer"; View: Text)
    var
        O: Text;
    begin
        ClearLastError();
        if UnTryView(View, O) then
            Observer.Observe(View, O)
        else
            Observer.ObserveError(View);
    end;

    [Test]
    procedure UN_SetView_AtSignInValue_Text()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UnSeedAt();
        UnViewProbe(Observer, 'WHERE(Txt=FILTER(@abc*))');
        UnViewProbe(Observer, 'WHERE(Txt=FILTER(@ABC))');
        UnViewProbe(Observer, 'WHERE(Txt=FILTER(a@b.dk))');
        Observer.Expect('WHERE(Txt=FILTER(@abc*))', 'ids=1,2,|txt=@abc*|cd=|view=VERSION(1) SORTING(Id) WHERE(Txt=FILTER(@abc*))');
        Observer.Expect('WHERE(Txt=FILTER(@ABC))', 'ids=1,|txt=@ABC|cd=|view=VERSION(1) SORTING(Id) WHERE(Txt=FILTER(@ABC))');
        Observer.Expect('WHERE(Txt=FILTER(a@b.dk))', 'ids=4,|txt=a@b.dk|cd=|view=VERSION(1) SORTING(Id) WHERE(Txt=FILTER(a@b.dk))');
        Observer.Verify();
    end;

    [Test]
    procedure UN_SetView_AtSignInValue_Text_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UnSeedAt();
        UnViewProbe(Observer, 'WHERE(Txt=FILTER(@a@b.dk))');
        UnViewProbe(Observer, 'WHERE(Txt=FILTER(*@b*))');
        UnViewProbe(Observer, 'WHERE(Txt=FILTER(ab@))');
        Observer.Expect('WHERE(Txt=FILTER(@a@b.dk))', 'ids=4,5,|txt=@a@b.dk|cd=|view=VERSION(1) SORTING(Id) WHERE(Txt=FILTER(@a@b.dk))');
        Observer.Expect('WHERE(Txt=FILTER(*@b*))', 'ids=4,|txt=*@b*|cd=|view=VERSION(1) SORTING(Id) WHERE(Txt=FILTER(*@b*))');
        Observer.Expect('WHERE(Txt=FILTER(ab@))', 'ids=7,|txt=ab@|cd=|view=VERSION(1) SORTING(Id) WHERE(Txt=FILTER(ab@))');
        Observer.Verify();
    end;

    [Test]
    procedure UN_SetView_AtSignInValue_TextMore()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UnSeedAt();
        UnViewProbe(Observer, 'WHERE(Txt=FILTER(@@abc))');
        UnViewProbe(Observer, 'WHERE(Txt=CONST(@abc))');
        UnViewProbe(Observer, 'WHERE(Txt=FILTER(''@abc''))');
        Observer.Expect('WHERE(Txt=FILTER(@@abc))', 'ids=1,|txt=@@abc|cd=|view=VERSION(1) SORTING(Id) WHERE(Txt=FILTER(@@abc))');
        Observer.Expect('WHERE(Txt=CONST(@abc))', 'ids=6,|txt=''@abc''|cd=|view=VERSION(1) SORTING(Id) WHERE(Txt=FILTER(''@abc''))');
        Observer.Expect('WHERE(Txt=FILTER(''@abc''))', 'ids=1,|txt=@abc|cd=|view=VERSION(1) SORTING(Id) WHERE(Txt=FILTER(@abc))');
        Observer.Verify();
    end;

    [Test]
    procedure UN_SetView_AtSignInValue_TextMore_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UnSeedAt();
        UnViewProbe(Observer, 'WHERE(Txt=FILTER(@abc|@xabc))');
        UnViewProbe(Observer, 'WHERE(Cd=FILTER(@abc*))');
        UnViewProbe(Observer, 'WHERE(Cd=FILTER(@at*))');
        Observer.Expect('WHERE(Txt=FILTER(@abc|@xabc))', 'ids=1,3,|txt=@abc|@xabc|cd=|view=VERSION(1) SORTING(Id) WHERE(Txt=FILTER(@abc|@xabc))');
        Observer.Expect('WHERE(Cd=FILTER(@abc*))', 'ids=1,2,|txt=|cd=@ABC*|view=VERSION(1) SORTING(Id) WHERE(Cd=FILTER(@ABC*))');
        Observer.Expect('WHERE(Cd=FILTER(@at*))', 'ids=4,5,6,7,8,|txt=|cd=@AT*|view=VERSION(1) SORTING(Id) WHERE(Cd=FILTER(@AT*))');
        Observer.Verify();
    end;

    [Test]
    procedure UN_SetView_AtSignInValue_TextMore_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UnSeedAt();
        UnViewProbe(Observer, 'WHERE(Cd=FILTER(AT1@))');
        Observer.Expect('WHERE(Cd=FILTER(AT1@))', 'ids=|txt=|cd=AT1@|view=VERSION(1) SORTING(Id) WHERE(Cd=FILTER(AT1@))');
        Observer.Verify();
    end;
}
