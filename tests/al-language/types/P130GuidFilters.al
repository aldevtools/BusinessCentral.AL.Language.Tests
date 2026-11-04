// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: table 73548 "LT P130 Filter Row" from P130DateFilters.al, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SetFilter on a Guid field with a literal TEXT (no %1): an empty text, '', <>'', the Guid with and without braces, in lower and upper case, the null Guid,
//   wildcards and partial texts, operators, ranges and alternatives, invalid texts; count and GetFilter, or the error text and code. Guids are fixed literals.
// Settles issue 130 reason 3 (SetFilter: text filter value for Guid: an empty '', a formula, how BC reads the text)
// BC versions: 29 (27 and 28 by CI)

codeunit 73551 "LT P130 Guid Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P130 Filter Row";
    begin
        R.DeleteAll();
        Add(1, '{11111111-1111-1111-1111-111111111111}');
        Add(2, '{22222222-2222-2222-2222-222222222222}');
        Add(3, '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Add(4, '{00000000-0000-0000-0000-000000000000}');
    end;

    local procedure Add(Id: Integer; G: Guid)
    var
        R: Record "LT P130 Filter Row";
    begin
        R.Id := Id;
        R.Gd := G;
        R.Insert();
    end;

    [TryFunction]
    local procedure TrySet(var R: Record "LT P130 Filter Row"; FilterText: Text)
    begin
        R.SetFilter(Gd, FilterText);
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; FilterText: Text)
    var
        R: Record "LT P130 Filter Row";
        Ids: Text;
    begin
        if TrySet(R, FilterText) then begin
            if R.FindSet() then
                repeat
                    Ids += Format(R.Id) + ',';
                until R.Next() = 0;
            Observer.Observe(Name, 'ok ids=' + Ids + ' filter=' + R.GetFilter(Gd));
        end else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P130_GuidFilter_EmptyAndBlankForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'empty', '');
        Probe(Observer, 'two_quotes', '''''');
        Probe(Observer, 'ne_two_quotes', '<>''''');
        Probe(Observer, 'one_space', ' ');
        Probe(Observer, 'null_guid_braced', '{00000000-0000-0000-0000-000000000000}');
        Probe(Observer, 'null_guid_plain', '00000000-0000-0000-0000-000000000000');
        Probe(Observer, 'ne_null_guid_braced', '<>{00000000-0000-0000-0000-000000000000}');
        Probe(Observer, 'zero', '0');
        Probe(Observer, 'star', '*');
        Probe(Observer, 'dotdot', '..');
        Probe(Observer, 'ne_only', '<>');
        Probe(Observer, 'pipe_only', '|');
        Probe(Observer, 'blank_or_g1', '''''|{11111111-1111-1111-1111-111111111111}');
        Observer.Expect('empty', 'ok ids=1,2,3,4, filter=');
        Observer.Expect('two_quotes', 'error:The filter "''''" is not valid for the Gd field on the LT P130 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('ne_two_quotes', 'error:The filter "<>''''" is not valid for the Gd field on the LT P130 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('one_space', 'ok ids=1,2,3,4, filter=');
        Observer.Expect('null_guid_braced', 'ok ids=4, filter={00000000-0000-0000-0000-000000000000}');
        Observer.Expect('null_guid_plain', 'ok ids=4, filter={00000000-0000-0000-0000-000000000000}');
        Observer.Expect('ne_null_guid_braced', 'ok ids=1,2,3, filter=<>{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('zero', 'error:The filter "0" is not valid for the Gd field on the LT P130 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('star', 'error:The filter "*" is not valid for the Gd field on the LT P130 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('dotdot', 'error:The filter ".." is not valid for the Gd field on the LT P130 Filter Row table. Both sides of the range (''..'') cannot be empty.|Filter:CSide');
        Observer.Expect('ne_only', 'error:The filter "<>" is not valid for the Gd field on the LT P130 Filter Row table. A value is expected after the ''<>''.|Filter:CSide');
        Observer.Expect('pipe_only', 'error:The filter "|" is not valid for the Gd field on the LT P130 Filter Row table. The left side of ''|'' operators cannot be empty.|Filter:CSide');
        Observer.Expect('blank_or_g1', 'error:The filter "''''|{11111111-1111-1111-1111-111111111111}" is not valid for the Gd field on the LT P130 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Verify();
    end;





    [Test]
    procedure P130_GuidFilter_ValueForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'g1_braced', '{11111111-1111-1111-1111-111111111111}');
        Probe(Observer, 'g1_plain', '11111111-1111-1111-1111-111111111111');
        Probe(Observer, 'g1_no_dashes', '11111111111111111111111111111111');
        Probe(Observer, 'g3_upper_braced', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Probe(Observer, 'g3_lower_braced', '{aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee}');
        Probe(Observer, 'g3_lower_plain', 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee');
        Probe(Observer, 'g3_mixed', '{AaAaAaAa-BbBb-CcCc-DdDd-EeEeEeEeEeEe}');
        Probe(Observer, 'g1_missing_brace_open', '11111111-1111-1111-1111-111111111111}');
        Probe(Observer, 'g1_missing_brace_close', '{11111111-1111-1111-1111-111111111111');
        Probe(Observer, 'g1_with_spaces', ' {11111111-1111-1111-1111-111111111111} ');
        Probe(Observer, 'g1_quoted', '''{11111111-1111-1111-1111-111111111111}''');
        Probe(Observer, 'too_short', '{1111-1111}');
        Probe(Observer, 'too_long', '{11111111-1111-1111-1111-1111111111112}');
        Probe(Observer, 'not_hex', '{GGGGGGGG-1111-1111-1111-111111111111}');
        Probe(Observer, 'text_abc', 'abc');
        Probe(Observer, 'parens', '({11111111-1111-1111-1111-111111111111})');
        Observer.Expect('g1_braced', 'ok ids=1, filter={11111111-1111-1111-1111-111111111111}');
        Observer.Expect('g1_plain', 'ok ids=1, filter={11111111-1111-1111-1111-111111111111}');
        Observer.Expect('g1_no_dashes', 'ok ids=1, filter={11111111-1111-1111-1111-111111111111}');
        Observer.Expect('g3_upper_braced', 'ok ids=3, filter={AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('g3_lower_braced', 'ok ids=3, filter={AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('g3_lower_plain', 'ok ids=3, filter={AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('g3_mixed', 'ok ids=3, filter={AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('g1_missing_brace_open', 'error:The filter "11111111-1111-1111-1111-111111111111}" is not valid for the Gd field on the LT P130 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('g1_missing_brace_close', 'error:The filter "{11111111-1111-1111-1111-111111111111" is not valid for the Gd field on the LT P130 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('g1_with_spaces', 'ok ids=1, filter={11111111-1111-1111-1111-111111111111}');
        Observer.Expect('g1_quoted', 'ok ids=1, filter={11111111-1111-1111-1111-111111111111}');
        Observer.Expect('too_short', 'error:The filter "{1111-1111}" is not valid for the Gd field on the LT P130 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('too_long', 'error:The filter "{11111111-1111-1111-1111-1111111111112}" is not valid for the Gd field on the LT P130 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('not_hex', 'error:The filter "{GGGGGGGG-1111-1111-1111-111111111111}" is not valid for the Gd field on the LT P130 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('text_abc', 'error:The filter "abc" is not valid for the Gd field on the LT P130 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('parens', 'ok ids=1, filter={11111111-1111-1111-1111-111111111111}');
        Observer.Verify();
    end;





    [Test]
    procedure P130_GuidFilter_WildcardsOperatorsRanges()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'prefix_wildcard', '{1111*');
        Probe(Observer, 'infix_wildcard', '*1111*');
        Probe(Observer, 'at_wildcard', '@*aaaa*');
        Probe(Observer, 'question_wildcard', '{?1111111-1111-1111-1111-111111111111}');
        Probe(Observer, 'ne_g1', '<>{11111111-1111-1111-1111-111111111111}');
        Probe(Observer, 'gt_g1', '>{11111111-1111-1111-1111-111111111111}');
        Probe(Observer, 'ge_g2', '>={22222222-2222-2222-2222-222222222222}');
        Probe(Observer, 'lt_g2', '<{22222222-2222-2222-2222-222222222222}');
        Probe(Observer, 'le_g2', '<={22222222-2222-2222-2222-222222222222}');
        Probe(Observer, 'range_g1_g2', '{11111111-1111-1111-1111-111111111111}..{22222222-2222-2222-2222-222222222222}');
        Probe(Observer, 'open_end', '{22222222-2222-2222-2222-222222222222}..');
        Probe(Observer, 'open_start', '..{22222222-2222-2222-2222-222222222222}');
        Probe(Observer, 'or_g1_g2', '{11111111-1111-1111-1111-111111111111}|{22222222-2222-2222-2222-222222222222}');
        Probe(Observer, 'and_ne_ne', '<>{11111111-1111-1111-1111-111111111111}&<>{22222222-2222-2222-2222-222222222222}');
        Probe(Observer, 'or_plain', '11111111-1111-1111-1111-111111111111|22222222-2222-2222-2222-222222222222');
        Probe(Observer, 'range_plain', '11111111-1111-1111-1111-111111111111..22222222-2222-2222-2222-222222222222');
        Observer.Expect('prefix_wildcard', 'error:The filter "{1111*" is not valid for the Gd field on the LT P130 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('infix_wildcard', 'error:The filter "*1111*" is not valid for the Gd field on the LT P130 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('at_wildcard', 'error:The filter "@*aaaa*" is not valid for the Gd field on the LT P130 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('question_wildcard', 'error:The filter "{?1111111-1111-1111-1111-111111111111}" is not valid for the Gd field on the LT P130 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('ne_g1', 'ok ids=2,3,4, filter=<>{11111111-1111-1111-1111-111111111111}');
        Observer.Expect('gt_g1', 'ok ids=2,3, filter=>{11111111-1111-1111-1111-111111111111}');
        Observer.Expect('ge_g2', 'ok ids=2,3, filter=>={22222222-2222-2222-2222-222222222222}');
        Observer.Expect('lt_g2', 'ok ids=1,4, filter=<{22222222-2222-2222-2222-222222222222}');
        Observer.Expect('le_g2', 'ok ids=1,2,4, filter=<={22222222-2222-2222-2222-222222222222}');
        Observer.Expect('range_g1_g2', 'ok ids=1,2, filter={11111111-1111-1111-1111-111111111111}..{22222222-2222-2222-2222-222222222222}');
        Observer.Expect('open_end', 'ok ids=2,3, filter={22222222-2222-2222-2222-222222222222}..');
        Observer.Expect('open_start', 'ok ids=1,2,4, filter=..{22222222-2222-2222-2222-222222222222}');
        Observer.Expect('or_g1_g2', 'ok ids=1,2, filter={11111111-1111-1111-1111-111111111111}|{22222222-2222-2222-2222-222222222222}');
        Observer.Expect('and_ne_ne', 'ok ids=3,4, filter=<>{11111111-1111-1111-1111-111111111111}&<>{22222222-2222-2222-2222-222222222222}');
        Observer.Expect('or_plain', 'ok ids=1,2, filter={11111111-1111-1111-1111-111111111111}|{22222222-2222-2222-2222-222222222222}');
        Observer.Expect('range_plain', 'ok ids=1,2, filter={11111111-1111-1111-1111-111111111111}..{22222222-2222-2222-2222-222222222222}');
        Observer.Verify();
    end;





    [Test]
    procedure P130_GuidFilter_ViaFormatOfAGuidVariable()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
    begin
        Seed();
        G := '{22222222-2222-2222-2222-222222222222}';
        Probe(Observer, 'format_default', Format(G));
        Probe(Observer, 'format_0', Format(G, 0, 0));
        Probe(Observer, 'format_9', Format(G, 0, 9));
        Probe(Observer, 'format_default_ne', '<>' + Format(G));
        Observer.Expect('format_default', 'ok ids=2, filter={22222222-2222-2222-2222-222222222222}');
        Observer.Expect('format_0', 'ok ids=2, filter={22222222-2222-2222-2222-222222222222}');
        Observer.Expect('format_9', 'ok ids=2, filter={22222222-2222-2222-2222-222222222222}');
        Observer.Expect('format_default_ne', 'ok ids=1,3,4, filter=<>{22222222-2222-2222-2222-222222222222}');
        Observer.Verify();
    end;
}
