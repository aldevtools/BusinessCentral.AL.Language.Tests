// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 70000
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Text.Contains, StartsWith, EndsWith, IndexOf, LastIndexOf, IndexOfAny on variables and literals.
// BC versions: 29 (27 and 28 by CI)

codeunit 70000 "LT TxA Search 1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Contains_Variable()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
    begin
        T := 'Hello World';
        Observer.Observe('contains_World', Format(T.Contains('World')));
        Observer.Observe('contains_world_lower', Format(T.Contains('world')));
        Observer.Observe('contains_empty', Format(T.Contains('')));
        Observer.Observe('contains_self', Format(T.Contains('Hello World')));
        Observer.Observe('contains_longer', Format(T.Contains('Hello World!')));
        Observer.Observe('contains_space', Format(T.Contains(' ')));
        Observer.Observe('contains_first', Format(T.Contains('H')));
        Observer.Observe('contains_last', Format(T.Contains('d')));
        Observer.Observe('empty_contains_empty', Format(E.Contains('')));
        Observer.Observe('empty_contains_a', Format(E.Contains('a')));
        Observer.Observe('contains_trailing_space', Format('abc'.Contains('c ')));
        Observer.Expect('contains_World', 'Yes');
        Observer.Expect('contains_world_lower', 'No');
        Observer.Expect('contains_empty', 'Yes');
        Observer.Expect('contains_self', 'Yes');
        Observer.Expect('contains_longer', 'No');
        Observer.Expect('contains_space', 'Yes');
        Observer.Expect('contains_first', 'Yes');
        Observer.Expect('contains_last', 'Yes');
        Observer.Expect('empty_contains_empty', 'Yes');
        Observer.Expect('empty_contains_a', 'No');
        Observer.Expect('contains_trailing_space', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Contains_Literal_Unicode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('lit_contains', Format('abcdef'.Contains('cd')));
        Observer.Observe('lit_contains_case', Format('abcdef'.Contains('CD')));
        Observer.Observe('lit_empty_empty', Format(''.Contains('')));
        Observer.Observe('lit_empty_a', Format(''.Contains('a')));
        Observer.Observe('uml_contains', Format('Straße'.Contains('ss')));
        Observer.Observe('uml_contains_sz', Format('Straße'.Contains('ß')));
        Observer.Observe('uml_upper', Format('Ärger'.Contains('ä')));
        Observer.Observe('uml_exact', Format('Ärger'.Contains('Är')));
        Observer.Observe('turkish_i', Format('Istanbul'.Contains('i')));
        Observer.Observe('turkish_dotted', Format('İstanbul'.Contains('i')));
        Observer.Expect('lit_contains', 'Yes');
        Observer.Expect('lit_contains_case', 'No');
        Observer.Expect('lit_empty_empty', 'Yes');
        Observer.Expect('lit_empty_a', 'No');
        Observer.Expect('uml_contains', 'No');
        Observer.Expect('uml_contains_sz', 'Yes');
        Observer.Expect('uml_upper', 'No');
        Observer.Expect('uml_exact', 'Yes');
        Observer.Expect('turkish_i', 'No');
        Observer.Expect('turkish_dotted', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure StartsWith_EndsWith()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
    begin
        T := 'Hello World';
        Observer.Observe('sw_Hello', Format(T.StartsWith('Hello')));
        Observer.Observe('sw_hello_lower', Format(T.StartsWith('hello')));
        Observer.Observe('sw_empty', Format(T.StartsWith('')));
        Observer.Observe('sw_self', Format(T.StartsWith(T)));
        Observer.Observe('sw_longer', Format(T.StartsWith('Hello World and more')));
        Observer.Observe('sw_World', Format(T.StartsWith('World')));
        Observer.Observe('ew_World', Format(T.EndsWith('World')));
        Observer.Observe('ew_world_lower', Format(T.EndsWith('world')));
        Observer.Observe('ew_empty', Format(T.EndsWith('')));
        Observer.Observe('ew_self', Format(T.EndsWith(T)));
        Observer.Observe('ew_longer', Format(T.EndsWith('Say Hello World')));
        Observer.Observe('ew_Hello', Format(T.EndsWith('Hello')));
        Observer.Observe('empty_sw_empty', Format(E.StartsWith('')));
        Observer.Observe('empty_ew_empty', Format(E.EndsWith('')));
        Observer.Observe('empty_sw_a', Format(E.StartsWith('a')));
        Observer.Observe('empty_ew_a', Format(E.EndsWith('a')));
        Observer.Observe('lit_sw', Format('abc'.StartsWith('ab')));
        Observer.Observe('lit_ew', Format('abc'.EndsWith('bc')));
        Observer.Observe('lit_sw_trailing_space', Format('abc '.EndsWith('c')));
        Observer.Observe('lit_ew_space', Format('abc '.EndsWith(' ')));
        Observer.Observe('uml_sw', Format('Ärger'.StartsWith('ä')));
        Observer.Observe('uml_ew', Format('Straße'.EndsWith('ße')));
        Observer.Expect('sw_Hello', 'Yes');
        Observer.Expect('sw_hello_lower', 'No');
        Observer.Expect('sw_empty', 'Yes');
        Observer.Expect('sw_self', 'Yes');
        Observer.Expect('sw_longer', 'No');
        Observer.Expect('sw_World', 'No');
        Observer.Expect('ew_World', 'Yes');
        Observer.Expect('ew_world_lower', 'No');
        Observer.Expect('ew_empty', 'Yes');
        Observer.Expect('ew_self', 'Yes');
        Observer.Expect('ew_longer', 'No');
        Observer.Expect('ew_Hello', 'No');
        Observer.Expect('empty_sw_empty', 'Yes');
        Observer.Expect('empty_ew_empty', 'Yes');
        Observer.Expect('empty_sw_a', 'No');
        Observer.Expect('empty_ew_a', 'No');
        Observer.Expect('lit_sw', 'Yes');
        Observer.Expect('lit_ew', 'Yes');
        Observer.Expect('lit_sw_trailing_space', 'No');
        Observer.Expect('lit_ew_space', 'Yes');
        Observer.Expect('uml_sw', 'No');
        Observer.Expect('uml_ew', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure IndexOf_Basic()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
    begin
        T := 'abcabcabc';
        Observer.Observe('io_b', Format(T.IndexOf('b')));
        Observer.Observe('io_abc', Format(T.IndexOf('abc')));
        Observer.Observe('io_cab', Format(T.IndexOf('cab')));
        Observer.Observe('io_missing', Format(T.IndexOf('x')));
        Observer.Observe('io_case', Format(T.IndexOf('B')));
        Observer.Observe('io_empty', Format(T.IndexOf('')));
        Observer.Observe('io_longer', Format(T.IndexOf('abcabcabcabc')));
        Observer.Observe('io_self', Format(T.IndexOf(T)));
        Observer.Observe('empty_io_empty', Format(E.IndexOf('')));
        Observer.Observe('empty_io_a', Format(E.IndexOf('a')));
        Observer.Observe('lit_io', Format('hello'.IndexOf('l')));
        Observer.Observe('lit_io_ll', Format('hello'.IndexOf('ll')));
        Observer.Observe('lit_io_uml', Format('Straße'.IndexOf('ss')));
        Observer.Observe('lit_io_sz', Format('Straße'.IndexOf('ß')));
        Observer.Expect('io_b', '2');
        Observer.Expect('io_abc', '1');
        Observer.Expect('io_cab', '3');
        Observer.Expect('io_missing', '0');
        Observer.Expect('io_case', '0');
        Observer.Expect('io_empty', '1');
        Observer.Expect('io_longer', '0');
        Observer.Expect('io_self', '1');
        Observer.Expect('empty_io_empty', '1');
        Observer.Expect('empty_io_a', '0');
        Observer.Expect('lit_io', '3');
        Observer.Expect('lit_io_ll', '3');
        Observer.Expect('lit_io_uml', '0');
        Observer.Expect('lit_io_sz', '5');
        Observer.Verify();
    end;

    [Test]
    procedure IndexOf_StartIndex()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := 'abcabcabc';
        Observer.Observe('start1', Format(T.IndexOf('abc', 1)));
        Observer.Observe('start2', Format(T.IndexOf('abc', 2)));
        Observer.Observe('start4', Format(T.IndexOf('abc', 4)));
        Observer.Observe('start7', Format(T.IndexOf('abc', 7)));
        Observer.Observe('start8', Format(T.IndexOf('abc', 8)));
        Observer.Observe('start9_c', Format(T.IndexOf('c', 9)));
        Observer.Observe('start9_empty', Format(T.IndexOf('', 9)));
        Observer.Observe('start10_empty', Format(T.IndexOf('', 10)));
        Observer.Observe('start5_empty', Format(T.IndexOf('', 5)));
        Observer.Observe('start3_b', Format(T.IndexOf('b', 3)));
        asserterror Observer.Observe('start0', Format(T.IndexOf('a', 0)));
        Observer.ObserveError('start0_err');
        asserterror Observer.Observe('startneg', Format(T.IndexOf('a', -1)));
        Observer.ObserveError('startneg_err');
        Observer.Observe('start10', Format(T.IndexOf('a', 10)));
        Observer.Observe('start10_err', 'no error');
        asserterror Observer.Observe('start11', Format(T.IndexOf('a', 11)));
        Observer.ObserveError('start11_err');
        asserterror Observer.Observe('start100', Format(T.IndexOf('a', 100)));
        Observer.ObserveError('start100_err');
        Observer.Expect('start1', '1');
        Observer.Expect('start2', '4');
        Observer.Expect('start4', '4');
        Observer.Expect('start7', '7');
        Observer.Expect('start8', '0');
        Observer.Expect('start9_c', '9');
        Observer.Expect('start9_empty', '9');
        Observer.Expect('start10_empty', '10');
        Observer.Expect('start5_empty', '5');
        Observer.Expect('start3_b', '5');
        Observer.Expect('start0_err|text', 'Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('start0_err|code', 'ArgumentOutOfRange');
        Observer.Expect('startneg_err|text', 'Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('startneg_err|code', 'ArgumentOutOfRange');
        Observer.Expect('start10', '0');
        Observer.Expect('start10_err', 'no error');
        Observer.Expect('start11_err|text', 'Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('start11_err|code', 'ArgumentOutOfRange');
        Observer.Expect('start100_err|text', 'Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('start100_err|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure IndexOf_StartIndex_EmptyAndLiteral()
    var
        Observer: Codeunit "Probe Observer";
        E: Text;
    begin
        Observer.Observe('empty_start1', Format(E.IndexOf('', 1)));
        Observer.Observe('empty_start1_err', 'no error');
        Observer.Observe('empty_start1_a', Format(E.IndexOf('a', 1)));
        Observer.Observe('empty_start1_a_err', 'no error');
        asserterror Observer.Observe('empty_start0', Format(E.IndexOf('a', 0)));
        Observer.ObserveError('empty_start0_err');
        Observer.Observe('lit_start2', Format('hello'.IndexOf('l', 4)));
        Observer.Observe('lit_start_past_match', Format('hello'.IndexOf('h', 2)));
        Observer.Observe('lit_start5', Format('hello'.IndexOf('o', 5)));
        Observer.Observe('lit_start6', Format('hello'.IndexOf('o', 6)));
        Observer.Observe('lit_start6_err', 'no error');
        Observer.Expect('empty_start1', '1');
        Observer.Expect('empty_start1_err', 'no error');
        Observer.Expect('empty_start1_a', '0');
        Observer.Expect('empty_start1_a_err', 'no error');
        Observer.Expect('empty_start0_err|text', 'Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('empty_start0_err|code', 'ArgumentOutOfRange');
        Observer.Expect('lit_start2', '4');
        Observer.Expect('lit_start_past_match', '0');
        Observer.Expect('lit_start5', '5');
        Observer.Expect('lit_start6', '0');
        Observer.Expect('lit_start6_err', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure LastIndexOf_Basic()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
    begin
        T := 'abcabcabc';
        Observer.Observe('lio_b', Format(T.LastIndexOf('b')));
        Observer.Observe('lio_abc', Format(T.LastIndexOf('abc')));
        Observer.Observe('lio_cab', Format(T.LastIndexOf('cab')));
        Observer.Observe('lio_missing', Format(T.LastIndexOf('x')));
        Observer.Observe('lio_case', Format(T.LastIndexOf('B')));
        Observer.Observe('lio_empty', Format(T.LastIndexOf('')));
        Observer.Observe('lio_longer', Format(T.LastIndexOf('abcabcabcabc')));
        Observer.Observe('lio_self', Format(T.LastIndexOf(T)));
        Observer.Observe('empty_lio_empty', Format(E.LastIndexOf('')));
        Observer.Observe('empty_lio_a', Format(E.LastIndexOf('a')));
        Observer.Observe('lit_lio', Format('hello'.LastIndexOf('l')));
        Observer.Observe('lit_lio_ll', Format('hello'.LastIndexOf('ll')));
        Observer.Observe('lit_lio_o', Format('hello'.LastIndexOf('o')));
        Observer.Observe('lit_lio_h', Format('hello'.LastIndexOf('h')));
        Observer.Expect('lio_b', '8');
        Observer.Expect('lio_abc', '7');
        Observer.Expect('lio_cab', '6');
        Observer.Expect('lio_missing', '0');
        Observer.Expect('lio_case', '0');
        Observer.Expect('lio_empty', '10');
        Observer.Expect('lio_longer', '0');
        Observer.Expect('lio_self', '1');
        Observer.Expect('empty_lio_empty', '1');
        Observer.Expect('empty_lio_a', '0');
        Observer.Expect('lit_lio', '4');
        Observer.Expect('lit_lio_ll', '3');
        Observer.Expect('lit_lio_o', '5');
        Observer.Expect('lit_lio_h', '1');
        Observer.Verify();
    end;

    [Test]
    procedure LastIndexOf_StartIndex()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := 'abcabcabc';
        Observer.Observe('lstart9', Format(T.LastIndexOf('abc', 9)));
        Observer.Observe('lstart8', Format(T.LastIndexOf('abc', 8)));
        Observer.Observe('lstart7', Format(T.LastIndexOf('abc', 7)));
        Observer.Observe('lstart6', Format(T.LastIndexOf('abc', 6)));
        Observer.Observe('lstart3', Format(T.LastIndexOf('abc', 3)));
        Observer.Observe('lstart1', Format(T.LastIndexOf('abc', 1)));
        Observer.Observe('lstart1_a', Format(T.LastIndexOf('a', 1)));
        Observer.Observe('lstart2_a', Format(T.LastIndexOf('a', 2)));
        Observer.Observe('lstart9_empty', Format(T.LastIndexOf('', 9)));
        Observer.Observe('lstart5_empty', Format(T.LastIndexOf('', 5)));
        asserterror Observer.Observe('lstart0', Format(T.LastIndexOf('a', 0)));
        Observer.ObserveError('lstart0_err');
        asserterror Observer.Observe('lstartneg', Format(T.LastIndexOf('a', -1)));
        Observer.ObserveError('lstartneg_err');
        Observer.Observe('lstart10', Format(T.LastIndexOf('a', 10)));
        Observer.Observe('lstart10_err', 'no error');
        asserterror Observer.Observe('lstart100', Format(T.LastIndexOf('a', 100)));
        Observer.ObserveError('lstart100_err');
        Observer.Expect('lstart9', '7');
        Observer.Expect('lstart8', '4');
        Observer.Expect('lstart7', '4');
        Observer.Expect('lstart6', '4');
        Observer.Expect('lstart3', '1');
        Observer.Expect('lstart1', '0');
        Observer.Expect('lstart1_a', '1');
        Observer.Expect('lstart2_a', '1');
        Observer.Expect('lstart9_empty', '10');
        Observer.Expect('lstart5_empty', '6');
        Observer.Expect('lstart0_err|text', 'Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('lstart0_err|code', 'ArgumentOutOfRange');
        Observer.Expect('lstartneg_err|text', 'Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('lstartneg_err|code', 'ArgumentOutOfRange');
        Observer.Expect('lstart10', '7');
        Observer.Expect('lstart10_err', 'no error');
        Observer.Expect('lstart100_err|text', 'Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('lstart100_err|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure LastIndexOf_StartIndex_Empty()
    var
        Observer: Codeunit "Probe Observer";
        E: Text;
    begin
        Observer.Observe('empty_l1', Format(E.LastIndexOf('', 1)));
        Observer.Observe('empty_l1_err', 'no error');
        Observer.Observe('empty_l1_a', Format(E.LastIndexOf('a', 1)));
        Observer.Observe('empty_l1_a_err', 'no error');
        Observer.Observe('empty_l0', Format(E.LastIndexOf('a', 0)));
        Observer.Observe('empty_l0_err', 'no error');
        Observer.Observe('lit_l5', Format('hello'.LastIndexOf('l', 5)));
        Observer.Observe('lit_l3', Format('hello'.LastIndexOf('l', 3)));
        Observer.Observe('lit_l2', Format('hello'.LastIndexOf('l', 2)));
        Observer.Observe('lit_l6', Format('hello'.LastIndexOf('l', 6)));
        Observer.Observe('lit_l6_err', 'no error');
        Observer.Expect('empty_l1', '1');
        Observer.Expect('empty_l1_err', 'no error');
        Observer.Expect('empty_l1_a', '0');
        Observer.Expect('empty_l1_a_err', 'no error');
        Observer.Expect('empty_l0', '0');
        Observer.Expect('empty_l0_err', 'no error');
        Observer.Expect('lit_l5', '4');
        Observer.Expect('lit_l3', '3');
        Observer.Expect('lit_l2', '0');
        Observer.Expect('lit_l6', '4');
        Observer.Expect('lit_l6_err', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure IndexOfAny_Basic()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
        Chars: List of [Char];
        NoChars: List of [Char];
        C: Char;
    begin
        T := 'Hello World';
        C := 'o';
        Chars.Add(C);
        Observer.Observe('any_o', Format(T.IndexOfAny(Chars)));
        C := 'W';
        Chars.Add(C);
        Observer.Observe('any_oW', Format(T.IndexOfAny(Chars)));
        C := 'l';
        Clear(Chars);
        Chars.Add(C);
        Observer.Observe('any_l', Format(T.IndexOfAny(Chars)));
        C := 'x';
        Clear(Chars);
        Chars.Add(C);
        Observer.Observe('any_missing', Format(T.IndexOfAny(Chars)));
        C := 'h';
        Clear(Chars);
        Chars.Add(C);
        Observer.Observe('any_case', Format(T.IndexOfAny(Chars)));
        Observer.Observe('any_nochars', Format(T.IndexOfAny(NoChars)));
        Observer.Observe('empty_any_nochars', Format(E.IndexOfAny(NoChars)));
        Observer.Observe('empty_any_h', Format(E.IndexOfAny(Chars)));
        Observer.Observe('lit_any_nochars', Format('abc'.IndexOfAny(NoChars)));
        C := 'c';
        Clear(Chars);
        Chars.Add(C);
        C := 'b';
        Chars.Add(C);
        Observer.Observe('lit_any_cb', Format('abc'.IndexOfAny(Chars)));
        Observer.Expect('any_o', '5');
        Observer.Expect('any_oW', '5');
        Observer.Expect('any_l', '3');
        Observer.Expect('any_missing', '0');
        Observer.Expect('any_case', '0');
        Observer.Expect('any_nochars', '0');
        Observer.Expect('empty_any_nochars', '0');
        Observer.Expect('empty_any_h', '0');
        Observer.Expect('lit_any_nochars', '0');
        Observer.Expect('lit_any_cb', '2');
        Observer.Verify();
    end;

    [Test]
    procedure IndexOfAny_StartIndex()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        Chars: List of [Char];
        C: Char;
    begin
        T := 'Hello World';
        C := 'o';
        Chars.Add(C);
        Observer.Observe('any_start1', Format(T.IndexOfAny(Chars, 1)));
        Observer.Observe('any_start5', Format(T.IndexOfAny(Chars, 5)));
        Observer.Observe('any_start6', Format(T.IndexOfAny(Chars, 6)));
        Observer.Observe('any_start8', Format(T.IndexOfAny(Chars, 8)));
        Observer.Observe('any_start11', Format(T.IndexOfAny(Chars, 11)));
        Observer.Observe('any_start12', Format(T.IndexOfAny(Chars, 12)));
        Observer.Observe('any_start12_err', 'no error');
        Observer.Expect('any_start1', '5');
        Observer.Expect('any_start5', '5');
        Observer.Expect('any_start6', '8');
        Observer.Expect('any_start8', '8');
        Observer.Expect('any_start11', '0');
        Observer.Expect('any_start12', '0');
        Observer.Expect('any_start12_err', 'no error');
        Observer.Verify();
    end;
    // Writer PW: docs/probes-needed.md "Values and builtins": Text.LastIndexOf('', 0) on an empty text (LastIndexOf('', 1) is 1 above), and the
    // neighbors: an empty value with start 0 and -1 on an empty and a non-empty text.
    [TryFunction]
    local procedure PwTryLastIndexOf(T: Text; Value: Text; StartIndex: Integer; var Result: Integer)
    begin
        Result := T.LastIndexOf(Value, StartIndex);
    end;

    local procedure PwLastIndexOf(T: Text; Value: Text; StartIndex: Integer): Text
    var
        Result: Integer;
        Outcome: Text;
    begin
        ClearLastError();
        if PwTryLastIndexOf(T, Value, StartIndex, Result) then
            exit(Format(Result));
        Outcome := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Outcome);
    end;

    [Test]
    procedure PW_LastIndexOf_EmptyValue_StartZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('empty_text_empty_value_0', PwLastIndexOf('', '', 0));
        Observer.Observe('empty_text_empty_value_minus1', PwLastIndexOf('', '', -1));
        Observer.Observe('empty_text_empty_value_2', PwLastIndexOf('', '', 2));
        Observer.Observe('hello_empty_value_0', PwLastIndexOf('hello', '', 0));
        Observer.Observe('hello_empty_value_1', PwLastIndexOf('hello', '', 1));
        Observer.Observe('hello_empty_value_5', PwLastIndexOf('hello', '', 5));
        Observer.Observe('hello_empty_value_6', PwLastIndexOf('hello', '', 6));
        Observer.Observe('hello_empty_value_7', PwLastIndexOf('hello', '', 7));
        Observer.Expect('empty_text_empty_value_0', '1');
        Observer.Expect('empty_text_empty_value_minus1', 'error:Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Observer.Expect('empty_text_empty_value_2', 'error:Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Observer.Expect('hello_empty_value_0', 'error:Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Observer.Expect('hello_empty_value_1', '2');
        Observer.Expect('hello_empty_value_5', '6');
        Observer.Expect('hello_empty_value_6', '6');
        Observer.Expect('hello_empty_value_7', 'error:Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Observer.Verify();
    end;
}
