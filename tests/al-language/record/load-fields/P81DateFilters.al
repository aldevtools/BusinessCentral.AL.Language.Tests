// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 70316 and codeunit 70317
// Probe: written against BC 29 (tag P81, GitHub issue 81); every literal asserted later is what a local BC 29 tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.SetFilter on a Date field with text values ('01012026', '010126', 'T', 'W', ranges, '..' forms, 0D, invalid dates) and with %1 / %2 placeholders: which forms work, the filter text BC keeps (GetFilter), the rows found, the exact error texts and codes
// BC versions: 29 (27 and 28 by CI)

table 70316 "LT P81 DF"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; D; Date) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 70317 "LT P81 Date Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P81 DF";
    begin
        Row.DeleteAll();
        AddRow('E0', 0D);
        AddRow('E1', 20251231D);
        AddRow('E2', 20260101D);
        AddRow('E3', 20260102D);
        AddRow('E4', 20260201D);
    end;

    local procedure AddRow(NewCode: Code[10]; NewDate: Date)
    var
        Row: Record "LT P81 DF";
    begin
        Row.Code := NewCode;
        Row.D := NewDate;
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryFilter(var Row: Record "LT P81 DF"; Txt: Text)
    begin
        Row.SetFilter(D, Txt);
    end;

    [TryFunction]
    local procedure TryFilter2(var Row: Record "LT P81 DF"; Txt: Text; D1: Date; D2: Date)
    begin
        Row.SetFilter(D, Txt, D1, D2);
    end;

    [TryFunction]
    local procedure TryFilter1(var Row: Record "LT P81 DF"; Txt: Text; D1: Date)
    begin
        Row.SetFilter(D, Txt, D1);
    end;

    local procedure Describe(var Row: Record "LT P81 DF"): Text
    var
        Codes: Text;
    begin
        if Row.FindSet() then
            repeat
                Codes += Row.Code + ',';
            until Row.Next() = 0;
        exit('ok|filter=' + Scrub(Row.GetFilter(D)) + '|rows=' + Codes);
    end;

    local procedure Scrub(Txt: Text): Text
    begin
        exit(Txt.Replace(Format(Today()), '<today>').Replace(Format(WorkDate()), '<workdate>'));
    end;

    local procedure Failed(): Text
    begin
        exit('error:' + Scrub(GetLastErrorText()) + '|' + GetLastErrorCode());
    end;

    local procedure Apply(Txt: Text): Text
    var
        Row: Record "LT P81 DF";
    begin
        if TryFilter(Row, Txt) then
            exit(Describe(Row));
        exit(Failed());
    end;

    local procedure Apply1(Txt: Text; D1: Date): Text
    var
        Row: Record "LT P81 DF";
    begin
        if TryFilter1(Row, Txt, D1) then
            exit(Describe(Row));
        exit(Failed());
    end;

    local procedure Apply2(Txt: Text; D1: Date; D2: Date): Text
    var
        Row: Record "LT P81 DF";
    begin
        if TryFilter2(Row, Txt, D1, D2) then
            exit(Describe(Row));
        exit(Failed());
    end;

    local procedure ObserveList(var Observer: Codeunit "Probe Observer"; Texts: List of [Text]; Prefix: Text)
    var
        i: Integer;
    begin
        for i := 1 to Texts.Count() do
            Observer.Observe(Prefix + Format(i) + '[' + Texts.Get(i) + ']', Apply(Texts.Get(i)));
    end;

    [Test]
    procedure SetFilter_Date_RangeForms()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
    begin
        Seed();
        Texts.Add('010126..020126');
        Texts.Add('01012026..02012026');
        Texts.Add('01012026..');
        Texts.Add('..01012026');
        Texts.Add('..');
        Texts.Add('010126|020126');
        Texts.Add('<>010126');
        Texts.Add('<010126');
        Texts.Add('>010126');
        Texts.Add('>=010126');
        Texts.Add('<=010126');
        Texts.Add('>010126&<010226');
        Texts.Add('020126..010126');
        Texts.Add('<010126|>020126');
        Texts.Add('010126..010126');
        Texts.Add('311225..010126|010226');
        ObserveList(Observer, Texts, 'r');
        Observer.Expect('r1[010126..020126]', 'ok|filter=01/01/26..02/01/26|rows=E2,E3,E4,');
        Observer.Expect('r2[01012026..02012026]', 'ok|filter=01/01/26..02/01/26|rows=E2,E3,E4,');
        Observer.Expect('r3[01012026..]', 'ok|filter=01/01/26..|rows=E2,E3,E4,');
        Observer.Expect('r4[..01012026]', 'ok|filter=..01/01/26|rows=E0,E1,E2,');
        Observer.Expect('r5[..]', 'error:The filter ".." is not valid for the D field on the LT P81 DF table. Both sides of the range (''..'') cannot be empty.|Filter:CSide');
        Observer.Expect('r6[010126|020126]', 'ok|filter=01/01/26|02/01/26|rows=E2,E4,');
        Observer.Expect('r7[<>010126]', 'ok|filter=<>01/01/26|rows=E0,E1,E3,E4,');
        Observer.Expect('r8[<010126]', 'ok|filter=<01/01/26|rows=E0,E1,');
        Observer.Expect('r9[>010126]', 'ok|filter=>01/01/26|rows=E3,E4,');
        Observer.Expect('r10[>=010126]', 'ok|filter=>=01/01/26|rows=E2,E3,E4,');
        Observer.Expect('r11[<=010126]', 'ok|filter=<=01/01/26|rows=E0,E1,E2,');
        Observer.Expect('r12[>010126&<010226]', 'ok|filter=>01/01/26&<01/02/26|rows=');
        Observer.Expect('r13[020126..010126]', 'ok|filter=02/01/26..01/01/26|rows=');
        Observer.Expect('r14[<010126|>020126]', 'ok|filter=<01/01/26|>02/01/26|rows=E0,E1,');
        Observer.Expect('r15[010126..010126]', 'ok|filter=01/01/26..01/01/26|rows=E2,');
        Observer.Expect('r16[311225..010126|010226]', 'error:The filter "311225..010126|010226" is not valid for the D field on the LT P81 DF table. The format of the Date ''311225'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Date_EmptyAndZeroForms()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
    begin
        Seed();
        Texts.Add('');
        Texts.Add(' ');
        Texts.Add('0D');
        Texts.Add('0D..');
        Texts.Add('..0D');
        Texts.Add('<>0D');
        Texts.Add('>0D');
        Texts.Add('0D..010126');
        Texts.Add('''''');
        Texts.Add('<>''''');
        Texts.Add('0');
        Texts.Add('000000');
        Texts.Add('0D|010126');
        ObserveList(Observer, Texts, 'z');
        Observer.Expect('z1[]', 'ok|filter=|rows=E0,E1,E2,E3,E4,');
        Observer.Expect('z2[ ]', 'ok|filter=|rows=E0,E1,E2,E3,E4,');
        Observer.Expect('z3[0D]', 'ok|filter=<today>|rows=');
        Observer.Expect('z4[0D..]', 'ok|filter=<today>..|rows=');
        Observer.Expect('z5[..0D]', 'ok|filter=..<today>|rows=E0,E1,E2,E3,E4,');
        Observer.Expect('z6[<>0D]', 'ok|filter=<><today>|rows=E0,E1,E2,E3,E4,');
        Observer.Expect('z7[>0D]', 'ok|filter=><today>|rows=');
        Observer.Expect('z8[0D..010126]', 'ok|filter=<today>..01/01/26|rows=');
        Observer.Expect('z9['''']', 'ok|filter=''''|rows=E0,');
        Observer.Expect('z10[<>'''']', 'ok|filter=<>''''|rows=E1,E2,E3,E4,');
        Observer.Expect('z11[0]', 'error:The filter "0" is not valid for the D field on the LT P81 DF table. The format of the Date ''0'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('z12[000000]', 'error:The filter "000000" is not valid for the D field on the LT P81 DF table. The format of the Date ''000000'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('z13[0D|010126]', 'ok|filter=<today>|01/01/26|rows=E2,');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Date_TodayAndWorkDateKeywords()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        SavedWorkDate: Date;
    begin
        SavedWorkDate := WorkDate();
        WorkDate(20260101D);
        Seed();
        Texts.Add('T');
        Texts.Add('t');
        Texts.Add('W');
        Texts.Add('w');
        Texts.Add('T..');
        Texts.Add('..T');
        Texts.Add('W..');
        Texts.Add('..W');
        Texts.Add('T|W');
        Texts.Add('<>W');
        Texts.Add('>W');
        Texts.Add('<=W');
        Texts.Add('W..T');
        Texts.Add('T..W');
        ObserveList(Observer, Texts, 'k');
        WorkDate(SavedWorkDate);
        Observer.Expect('k1[T]', 'ok|filter=<today>|rows=');
        Observer.Expect('k2[t]', 'ok|filter=<today>|rows=');
        Observer.Expect('k3[W]', 'ok|filter=<workdate>|rows=E2,');
        Observer.Expect('k4[w]', 'ok|filter=<workdate>|rows=E2,');
        Observer.Expect('k5[T..]', 'ok|filter=<today>..|rows=');
        Observer.Expect('k6[..T]', 'ok|filter=..<today>|rows=E0,E1,E2,E3,E4,');
        Observer.Expect('k7[W..]', 'ok|filter=<workdate>..|rows=E2,E3,E4,');
        Observer.Expect('k8[..W]', 'ok|filter=..<workdate>|rows=E0,E1,E2,');
        Observer.Expect('k9[T|W]', 'ok|filter=<today>|<workdate>|rows=E2,');
        Observer.Expect('k10[<>W]', 'ok|filter=<><workdate>|rows=E0,E1,E3,E4,');
        Observer.Expect('k11[>W]', 'ok|filter=><workdate>|rows=E3,E4,');
        Observer.Expect('k12[<=W]', 'ok|filter=<=<workdate>|rows=E0,E1,E2,');
        Observer.Expect('k13[W..T]', 'ok|filter=<workdate>..<today>|rows=E2,E3,E4,');
        Observer.Expect('k14[T..W]', 'ok|filter=<today>..<workdate>|rows=');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Date_Placeholders_TwoDates()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('range', Apply2('%1..%2', 20260101D, 20260102D));
        Observer.Observe('range_reversed', Apply2('%1..%2', 20260102D, 20260101D));
        Observer.Observe('range_same', Apply2('%1..%2', 20260101D, 20260101D));
        Observer.Observe('range_zero_first', Apply2('%1..%2', 0D, 20260101D));
        Observer.Observe('range_zero_second', Apply2('%1..%2', 20260101D, 0D));
        Observer.Observe('range_both_zero', Apply2('%1..%2', 0D, 0D));
        Observer.Observe('or', Apply2('%1|%2', 20251231D, 20260201D));
        Observer.Observe('and', Apply2('>%1&<%2', 20251231D, 20260201D));
        Observer.Observe('swapped_placeholders', Apply2('%2..%1', 20260101D, 20260102D));
        Observer.Observe('only_second', Apply2('%2', 20260101D, 20260102D));
        Observer.Observe('only_first_extra_arg', Apply2('%1', 20260101D, 20260102D));
        Observer.Observe('no_placeholder_extra_args', Apply2('010126', 20260102D, 20260201D));
        Observer.Observe('not_equal', Apply2('<>%1&<>%2', 20260101D, 20260102D));
        Observer.Observe('repeated', Apply2('%1|%1', 20260101D, 20260102D));
        Observer.Expect('range', 'ok|filter=01/01/26..01/02/26|rows=E2,E3,');
        Observer.Expect('range_reversed', 'ok|filter=01/02/26..01/01/26|rows=');
        Observer.Expect('range_same', 'ok|filter=01/01/26..01/01/26|rows=E2,');
        Observer.Expect('range_zero_first', 'ok|filter=''''..01/01/26|rows=E0,E1,E2,');
        Observer.Expect('range_zero_second', 'ok|filter=01/01/26..''''|rows=');
        Observer.Expect('range_both_zero', 'ok|filter=''''..''''|rows=E0,');
        Observer.Expect('or', 'ok|filter=12/31/25|02/01/26|rows=E1,E4,');
        Observer.Expect('and', 'ok|filter=>12/31/25&<02/01/26|rows=E2,E3,');
        Observer.Expect('swapped_placeholders', 'ok|filter=01/02/26..01/01/26|rows=');
        Observer.Expect('only_second', 'ok|filter=01/02/26|rows=E3,');
        Observer.Expect('only_first_extra_arg', 'ok|filter=01/01/26|rows=E2,');
        Observer.Expect('no_placeholder_extra_args', 'ok|filter=01/01/26|rows=E2,');
        Observer.Expect('not_equal', 'ok|filter=<>01/01/26&<>01/02/26|rows=E0,E1,E4,');
        Observer.Expect('repeated', 'ok|filter=01/01/26|01/01/26|rows=E2,');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Date_InvalidTexts()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
    begin
        Seed();
        Texts.Add('abc');
        Texts.Add('13132026');
        Texts.Add('32012026');
        Texts.Add('00012026');
        Texts.Add('31022026');
        Texts.Add('01012026..abc');
        Texts.Add('abc..01012026');
        Texts.Add('..abc');
        Texts.Add('|');
        Texts.Add('&');
        Texts.Add('01012026||020126');
        Texts.Add('(01012026)');
        Texts.Add('99999999');
        Texts.Add('01-01-2026');
        Texts.Add('A..B');
        Texts.Add('*');
        Texts.Add('01012026 ');
        Texts.Add(' 01012026');
        Texts.Add('0101202');
        Texts.Add('010126...020126');
        ObserveList(Observer, Texts, 'i');
        Observer.Expect('i1[abc]', 'error:The filter "abc" is not valid for the D field on the LT P81 DF table. The format of the Date ''abc'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('i2[13132026]', 'error:The filter "13132026" is not valid for the D field on the LT P81 DF table. The format of the Date ''13132026'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('i3[32012026]', 'error:The filter "32012026" is not valid for the D field on the LT P81 DF table. The format of the Date ''32012026'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('i4[00012026]', 'error:The filter "00012026" is not valid for the D field on the LT P81 DF table. The format of the Date ''00012026'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('i5[31022026]', 'error:The filter "31022026" is not valid for the D field on the LT P81 DF table. The format of the Date ''31022026'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('i6[01012026..abc]', 'error:The filter "01012026..abc" is not valid for the D field on the LT P81 DF table. The format of the Date ''abc'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('i7[abc..01012026]', 'error:The filter "abc..01012026" is not valid for the D field on the LT P81 DF table. The format of the Date ''abc'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('i8[..abc]', 'error:The filter "..abc" is not valid for the D field on the LT P81 DF table. The format of the Date ''abc'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('i9[|]', 'error:The filter "|" is not valid for the D field on the LT P81 DF table. The left side of ''|'' operators cannot be empty.|Filter:CSide');
        Observer.Expect('i10[&]', 'error:The filter "&" is not valid for the D field on the LT P81 DF table. The left side of ''&'' operators cannot be empty.|Filter:CSide');
        Observer.Expect('i11[01012026||020126]', 'error:The filter "01012026||020126" is not valid for the D field on the LT P81 DF table. The right side of ''|'' operators cannot be empty.|Filter:CSide');
        Observer.Expect('i12[(01012026)]', 'ok|filter=01/01/26|rows=E2,');
        Observer.Expect('i13[99999999]', 'error:The filter "99999999" is not valid for the D field on the LT P81 DF table. The format of the Date ''99999999'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('i14[01-01-2026]', 'ok|filter=01/01/26|rows=E2,');
        Observer.Expect('i15[A..B]', 'error:The filter "A..B" is not valid for the D field on the LT P81 DF table. The format of the Date ''A'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('i16[*]', 'ok|filter=<today>|rows=');
        Observer.Expect('i17[01012026 ]', 'ok|filter=01/01/26|rows=E2,');
        Observer.Expect('i18[ 01012026]', 'ok|filter=01/01/26|rows=E2,');
        Observer.Expect('i19[0101202]', 'ok|filter=01/01/0202|rows=');
        Observer.Expect('i20[010126...020126]', 'ok|filter=01/01/26..02/01/26|rows=E2,E3,E4,');
        Observer.Verify();
    end;





    [Test]
    procedure SetFilter_Date_InvalidKeepsOldFilter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 DF";
    begin
        Seed();
        Row.SetFilter(D, '010126..020126');
        Observer.Observe('before', Row.GetFilter(D));
        if TryFilter(Row, 'abc') then
            Observer.Observe('apply_abc', 'no error')
        else
            Observer.Observe('apply_abc', Failed());
        Observer.Observe('after_invalid', Row.GetFilter(D));
        Observer.Observe('count_after_invalid', Format(Row.Count()));
        Row.SetFilter(D, '');
        Observer.Observe('after_empty', Row.GetFilter(D));
        Observer.Observe('has_filter_after_empty', Format(Row.GetFilter(D) <> ''));
        Observer.Expect('before', '01/01/26..02/01/26');
        Observer.Expect('apply_abc', 'error:The filter "abc" is not valid for the D field on the LT P81 DF table. The format of the Date ''abc'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('after_invalid', '01/01/26..02/01/26');
        Observer.Expect('count_after_invalid', '3');
        Observer.Expect('after_empty', '');
        Observer.Expect('has_filter_after_empty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Date_GetRangeAndFilterText()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 DF";
    begin
        Seed();
        Row.SetFilter(D, '010126..020126');
        Observer.Observe('range_min', Format(Row.GetRangeMin(D)));
        Observer.Observe('range_max', Format(Row.GetRangeMax(D)));
        Observer.Observe('filter', Row.GetFilter(D));
        Observer.Observe('filters', Row.GetFilters());
        Row.SetFilter(D, '%1|%2', 20260101D, 20260201D);
        Observer.Observe('or_filter', Row.GetFilter(D));
        Row.SetFilter(D, '01012026');
        Observer.Observe('single_filter', Row.GetFilter(D));
        Observer.Observe('single_min', Format(Row.GetRangeMin(D)));
        Observer.Observe('single_max', Format(Row.GetRangeMax(D)));
        Observer.Observe('single_count', Format(Row.Count()));
        Row.SetRange(D, 20260101D, 20260102D);
        Observer.Observe('setrange_filter', Row.GetFilter(D));
        Row.SetRange(D, 0D);
        Observer.Observe('setrange_zero_filter', Row.GetFilter(D));
        Observer.Observe('setrange_zero_count', Format(Row.Count()));
        Row.SetRange(D, 20260102D, 20260101D);
        Observer.Observe('setrange_reversed_filter', Row.GetFilter(D));
        Observer.Observe('setrange_reversed_count', Format(Row.Count()));
        Observer.Expect('range_min', '01/01/26');
        Observer.Expect('range_max', '02/01/26');
        Observer.Expect('filter', '01/01/26..02/01/26');
        Observer.Expect('filters', 'D: 01/01/26..02/01/26');
        Observer.Expect('or_filter', '01/01/26|02/01/26');
        Observer.Expect('single_filter', '01/01/26');
        Observer.Expect('single_min', '01/01/26');
        Observer.Expect('single_max', '01/01/26');
        Observer.Expect('single_count', '1');
        Observer.Expect('setrange_filter', '01/01/26..01/02/26');
        Observer.Expect('setrange_zero_filter', '''''');
        Observer.Expect('setrange_zero_count', '1');
        Observer.Expect('setrange_reversed_filter', '01/02/26..01/01/26');
        Observer.Expect('setrange_reversed_count', '0');
        Observer.Verify();
    end;
}
