// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: table 74647 and codeunit 74648 (P143Fixtures.al), codeunit 69160 "Probe Observer"
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74658 "LT P143 GuidBraced"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P143_GuidBraced()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P143 Helper";
    begin
        Helper.Seed();
        Helper.ProbeGuid(Observer, 'braced_upper', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Helper.ProbeGuid(Observer, 'braced_lower', '{aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee}');
        Helper.ProbeGuid(Observer, 'unbraced_upper', 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE');
        Helper.ProbeGuid(Observer, 'unbraced_lower', 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee');
        Helper.ProbeGuid(Observer, 'braced_mixed', '{aAaAaAaA-bBbB-cCcC-dDdD-eEeEeEeEeEeE}');
        Helper.ProbeGuid(Observer, 'digits_only', '{11111111-2222-3333-4444-555555555555}');
        Helper.ProbeGuid(Observer, 'no_dashes', 'AAAAAAAABBBBCCCCDDDDEEEEEEEEEEEE');
        Helper.ProbeGuid(Observer, 'braced_no_dashes', '{AAAAAAAABBBBCCCCDDDDEEEEEEEEEEEE}');
        Observer.Expect('braced_upper_filter', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('braced_upper_count', '1');
        Observer.Expect('braced_lower_filter', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('braced_lower_count', '1');
        Observer.Expect('unbraced_upper_filter', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('unbraced_upper_count', '1');
        Observer.Expect('unbraced_lower_filter', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('unbraced_lower_count', '1');
        Observer.Expect('braced_mixed_filter', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('braced_mixed_count', '1');
        Observer.Expect('digits_only_filter', '{11111111-2222-3333-4444-555555555555}');
        Observer.Expect('digits_only_count', '1');
        Observer.Expect('no_dashes_filter', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('no_dashes_count', '1');
        Observer.Expect('braced_no_dashes_err|text', 'The filter "{AAAAAAAABBBBCCCCDDDDEEEEEEEEEEEE}" is not valid for the G field on the LT P143 Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('braced_no_dashes_err|code', 'Filter:CSide');
        Observer.Verify();
    end;
}

codeunit 74659 "LT P143 GuidEmpty"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P143_GuidEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P143 Helper";
    begin
        Helper.Seed();
        Helper.ProbeGuid(Observer, 'empty_text', '');
        Helper.ProbeGuid(Observer, 'empty_braced_zero', '{00000000-0000-0000-0000-000000000000}');
        Helper.ProbeGuid(Observer, 'empty_unbraced_zero', '00000000-0000-0000-0000-000000000000');
        Helper.ProbeGuid(Observer, 'not_empty_braced_zero', '<>{00000000-0000-0000-0000-000000000000}');
        Helper.ProbeGuid(Observer, 'not_equal_row1', '<>{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Helper.ProbeGuid(Observer, 'two_with_or', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}|{11111111-2222-3333-4444-555555555555}');
        Helper.ProbeGuid(Observer, 'range_two', '{11111111-2222-3333-4444-555555555555}..{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('empty_text_filter', '');
        Observer.Expect('empty_text_count', '10');
        Observer.Expect('empty_braced_zero_filter', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('empty_braced_zero_count', '7');
        Observer.Expect('empty_unbraced_zero_filter', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('empty_unbraced_zero_count', '7');
        Observer.Expect('not_empty_braced_zero_filter', '<>{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('not_empty_braced_zero_count', '3');
        Observer.Expect('not_equal_row1_filter', '<>{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('not_equal_row1_count', '9');
        Observer.Expect('two_with_or_filter', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}|{11111111-2222-3333-4444-555555555555}');
        Observer.Expect('two_with_or_count', '2');
        Observer.Expect('range_two_filter', '{11111111-2222-3333-4444-555555555555}..{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('range_two_count', '2');
        Observer.Verify();
    end;
}

codeunit 74660 "LT P143 GuidInvalid"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P143_GuidInvalid()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P143 Helper";
    begin
        Helper.Seed();
        Helper.ProbeGuid(Observer, 'abc', 'abc');
        Helper.ProbeGuid(Observer, 'short_last_group', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE}');
        Helper.ProbeGuid(Observer, 'long_last_group', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEEE}');
        Helper.ProbeGuid(Observer, 'non_hex', '{GGGGGGGG-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Helper.ProbeGuid(Observer, 'open_brace_only', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE');
        Helper.ProbeGuid(Observer, 'close_brace_only', 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Helper.ProbeGuid(Observer, 'number', '12345');
        Helper.ProbeGuid(Observer, 'wildcard', 'AAAAAAAA*');
        Helper.ProbeGuid(Observer, 'wildcard_braced', '{AAAAAAAA*');
        Helper.ProbeGuid(Observer, 'first_valid_second_bad', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}|abc');
        Observer.Expect('abc_err|text', 'The filter "abc" is not valid for the G field on the LT P143 Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('abc_err|code', 'Filter:CSide');
        Observer.Expect('short_last_group_err|text', 'The filter "{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE}" is not valid for the G field on the LT P143 Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('short_last_group_err|code', 'Filter:CSide');
        Observer.Expect('long_last_group_err|text', 'The filter "{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEEE}" is not valid for the G field on the LT P143 Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('long_last_group_err|code', 'Filter:CSide');
        Observer.Expect('non_hex_err|text', 'The filter "{GGGGGGGG-BBBB-CCCC-DDDD-EEEEEEEEEEEE}" is not valid for the G field on the LT P143 Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('non_hex_err|code', 'Filter:CSide');
        Observer.Expect('open_brace_only_err|text', 'The filter "{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE" is not valid for the G field on the LT P143 Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('open_brace_only_err|code', 'Filter:CSide');
        Observer.Expect('close_brace_only_err|text', 'The filter "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}" is not valid for the G field on the LT P143 Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('close_brace_only_err|code', 'Filter:CSide');
        Observer.Expect('number_err|text', 'The filter "12345" is not valid for the G field on the LT P143 Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('number_err|code', 'Filter:CSide');
        Observer.Expect('wildcard_err|text', 'The filter "AAAAAAAA*" is not valid for the G field on the LT P143 Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('wildcard_err|code', 'Filter:CSide');
        Observer.Expect('wildcard_braced_err|text', 'The filter "{AAAAAAAA*" is not valid for the G field on the LT P143 Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('wildcard_braced_err|code', 'Filter:CSide');
        Observer.Expect('first_valid_second_bad_err|text', 'The filter "{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}|abc" is not valid for the G field on the LT P143 Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('first_valid_second_bad_err|code', 'Filter:CSide');
        Observer.Verify();
    end;




}

codeunit 74661 "LT P143 GuidVariable"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P143_GuidVariable()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P143 Helper";
        Row: Record "LT P143 Row";
        Gv: Guid;
    begin
        Helper.Seed();
        Evaluate(Gv, '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Row.SetFilter(G, '%1', Gv);
        Observer.Observe('setfilter_pct1_count', Format(Row.Count()));
        Observer.Observe('setfilter_pct1_filter_is_braced_upper', Format(Row.GetFilter(G) = '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}'));
        Observer.Observe('setfilter_pct1_filter_is_lower', Format(Row.GetFilter(G) = '{aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee}'));
        Row.Reset();
        Row.SetRange(G, Gv);
        Observer.Observe('setrange_count', Format(Row.Count()));
        Observer.Observe('setrange_filter_equals_setfilter_filter', Format(Row.GetFilter(G) = Format(Gv)));
        Row.Reset();
        Clear(Gv);
        Row.SetRange(G, Gv);
        Observer.Observe('setrange_empty_count', Format(Row.Count()));
        Observer.Observe('setrange_empty_filter', Row.GetFilter(G));
        Row.Reset();
        Row.SetFilter(G, '%1', Gv);
        Observer.Observe('setfilter_pct1_empty_count', Format(Row.Count()));
        Observer.Observe('setfilter_pct1_empty_filter', Row.GetFilter(G));
        Row.Reset();
        Row.SetFilter(G, '<>%1', Gv);
        Observer.Observe('setfilter_ne_empty_count', Format(Row.Count()));
        Evaluate(Gv, '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Row.Reset();
        Row.SetFilter(G, '{aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee}');
        Observer.Observe('lower_text_count', Format(Row.Count()));
        Observer.Expect('setfilter_pct1_count', '1');
        Observer.Expect('setfilter_pct1_filter_is_braced_upper', 'Yes');
        Observer.Expect('setfilter_pct1_filter_is_lower', 'No');
        Observer.Expect('setrange_count', '1');
        Observer.Expect('setrange_filter_equals_setfilter_filter', 'Yes');
        Observer.Expect('setrange_empty_count', '7');
        Observer.Expect('setrange_empty_filter', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('setfilter_pct1_empty_count', '7');
        Observer.Expect('setfilter_pct1_empty_filter', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('setfilter_ne_empty_count', '3');
        Observer.Expect('lower_text_count', '1');
        Observer.Verify();
    end;
}
