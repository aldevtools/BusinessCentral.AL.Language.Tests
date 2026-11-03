// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 70020
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Text.ToLower, ToUpper, Trim, TrimStart, TrimEnd with and without a character set; culture and unicode behaviour.
// BC versions: 29 (27 and 28 by CI)

codeunit 70020 "LT TxA Case Trim 1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure L(Value: Text): Text
    begin
        exit(Value);
    end;

    [Test]
    procedure ToLower_ToUpper_Ascii()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
    begin
        T := 'Hello World 123 _-!';
        Observer.Observe('lower', T.ToLower());
        Observer.Observe('upper', T.ToUpper());
        Observer.Observe('lower_empty', E.ToLower() + '|');
        Observer.Observe('upper_empty', E.ToUpper() + '|');
        Observer.Observe('lit_lower', 'ABC'.ToLower());
        Observer.Observe('lit_upper', 'abc'.ToUpper());
        Observer.Observe('lit_lower_empty', ''.ToLower() + '|');
        Observer.Observe('upper_len', Format(StrLen(T.ToUpper())));
        Observer.Observe('lower_idempotent', Format(T.ToLower().ToLower() = T.ToLower()));
        Observer.Observe('spaces', '[' + '  a  '.ToUpper() + ']');
        Observer.Expect('lower', 'hello world 123 _-!');
        Observer.Expect('upper', 'HELLO WORLD 123 _-!');
        Observer.Expect('lower_empty', '|');
        Observer.Expect('upper_empty', '|');
        Observer.Expect('lit_lower', 'abc');
        Observer.Expect('lit_upper', 'ABC');
        Observer.Expect('lit_lower_empty', '|');
        Observer.Expect('upper_len', '19');
        Observer.Expect('lower_idempotent', 'Yes');
        Observer.Expect('spaces', '[  A  ]');
        Observer.Verify();
    end;

    [Test]
    procedure ToLower_ToUpper_Unicode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('upper_uml', 'äöüß'.ToUpper());
        Observer.Observe('lower_uml', 'ÄÖÜ'.ToLower());
        Observer.Observe('upper_sz_len', Format(StrLen(L('ß').ToUpper())));
        Observer.Observe('upper_e_acute', L('é').ToUpper());
        Observer.Observe('lower_E_acute', L('É').ToLower());
        Observer.Observe('upper_greek', 'αβγ'.ToUpper());
        Observer.Observe('lower_greek_sigma', 'ΣΑΣ'.ToLower());
        Observer.Observe('upper_cyrillic', 'привет'.ToUpper());
        Observer.Observe('upper_turkish_i', L('i').ToUpper());
        Observer.Observe('lower_turkish_I', L('I').ToLower());
        Observer.Observe('lower_turkish_dotted_I', L('İ').ToLower());
        Observer.Observe('lower_turkish_dotted_I_len', Format(StrLen(L('İ').ToLower())));
        Observer.Observe('upper_dotless_i', L('ı').ToUpper());
        Observer.Observe('upper_long_s', L('ſ').ToUpper());
        Observer.Observe('lower_kelvin', L('K').ToLower());
        Observer.Observe('upper_cjk', '日本語'.ToUpper());
        Observer.Observe('upper_fi_ligature', L('ﬁ').ToUpper());
        Observer.Expect('upper_uml', 'ÄÖÜß');
        Observer.Expect('lower_uml', 'äöü');
        Observer.Expect('upper_sz_len', '1');
        Observer.Expect('upper_e_acute', 'É');
        Observer.Expect('lower_E_acute', 'é');
        Observer.Expect('upper_greek', 'ΑΒΓ');
        Observer.Expect('lower_greek_sigma', 'σασ');
        Observer.Expect('upper_cyrillic', 'ПРИВЕТ');
        Observer.Expect('upper_turkish_i', 'I');
        Observer.Expect('lower_turkish_I', 'i');
        Observer.Expect('lower_turkish_dotted_I', 'İ');
        Observer.Expect('lower_turkish_dotted_I_len', '1');
        Observer.Expect('upper_dotless_i', 'ı');
        Observer.Expect('upper_long_s', 'S');
        Observer.Expect('lower_kelvin', 'k');
        Observer.Expect('upper_cjk', '日本語');
        Observer.Expect('upper_fi_ligature', 'ﬁ');
        Observer.Verify();
    end;

    [Test]
    procedure Trim_NoArgs()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
        Tab: Text[1];
        Cr: Text[1];
        Lf: Text[1];
        Nbsp: Text[1];
    begin
        Tab[1] := 9;
        Cr[1] := 13;
        Lf[1] := 10;
        Nbsp[1] := 160;
        T := '  abc  ';
        Observer.Observe('trim', '[' + T.Trim() + ']');
        Observer.Observe('trimstart', '[' + T.TrimStart(' ') + ']');
        Observer.Observe('trimend', '[' + T.TrimEnd(' ') + ']');
        Observer.Observe('trim_empty', '[' + E.Trim() + ']');
        Observer.Observe('trim_blank', '[' + '    '.Trim() + ']');
        Observer.Observe('trim_inner', '[' + ' a b '.Trim() + ']');
        Observer.Observe('trim_tab', Format(StrLen((Tab + 'a' + Tab).Trim())));
        Observer.Observe('trim_crlf', Format(StrLen((Cr + Lf + 'a' + Cr + Lf).Trim())));
        Observer.Observe('trim_nbsp', Format(StrLen((Nbsp + 'a' + Nbsp).Trim())));
        Observer.Observe('trim_lit', '[' + '  x '.Trim() + ']');
        Observer.Observe('trim_no_ws', '[' + 'abc'.Trim() + ']');
        Observer.Observe('trim_only_tab', Format(StrLen(Tab.Trim())));
        Observer.Observe('trim_only_nbsp', Format(StrLen(Nbsp.Trim())));
        Observer.Expect('trim', '[abc]');
        Observer.Expect('trimstart', '[abc  ]');
        Observer.Expect('trimend', '[  abc]');
        Observer.Expect('trim_empty', '[]');
        Observer.Expect('trim_blank', '[]');
        Observer.Expect('trim_inner', '[a b]');
        Observer.Expect('trim_tab', '1');
        Observer.Expect('trim_crlf', '1');
        Observer.Expect('trim_nbsp', '1');
        Observer.Expect('trim_lit', '[x]');
        Observer.Expect('trim_no_ws', '[abc]');
        Observer.Expect('trim_only_tab', '0');
        Observer.Expect('trim_only_nbsp', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Trim_Whitespace_Kinds()
    var
        Observer: Codeunit "Probe Observer";
        Ch: Text[1];
        Code: Integer;
        Codes: List of [Integer];
    begin
        Codes.AddRange(9, 10, 11, 12, 13, 28, 29, 30, 31, 32);
        Codes.AddRange(133, 160, 5760, 8192, 8203, 8232, 8233, 8239, 12288, 65279);
        foreach Code in Codes do begin
            Ch[1] := Code;
            Observer.Observe('trim_code_' + Format(Code), Format(StrLen((Ch + 'a' + Ch).Trim())));
        end;
        Observer.Expect('trim_code_9', '1');
        Observer.Expect('trim_code_10', '1');
        Observer.Expect('trim_code_11', '1');
        Observer.Expect('trim_code_12', '1');
        Observer.Expect('trim_code_13', '1');
        Observer.Expect('trim_code_28', '3');
        Observer.Expect('trim_code_29', '3');
        Observer.Expect('trim_code_30', '3');
        Observer.Expect('trim_code_31', '3');
        Observer.Expect('trim_code_32', '1');
        Observer.Expect('trim_code_133', '1');
        Observer.Expect('trim_code_160', '1');
        Observer.Expect('trim_code_5760', '1');
        Observer.Expect('trim_code_8192', '1');
        Observer.Expect('trim_code_8203', '3');
        Observer.Expect('trim_code_8232', '1');
        Observer.Expect('trim_code_8233', '1');
        Observer.Expect('trim_code_8239', '1');
        Observer.Expect('trim_code_12288', '1');
        Observer.Expect('trim_code_65279', '3');
        Observer.Verify();
    end;

    [Test]
    procedure TrimStart_TrimEnd_CharSet()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
    begin
        T := 'xxabcxx';
        Observer.Observe('ts_x', T.TrimStart('x'));
        Observer.Observe('te_x', T.TrimEnd('x'));
        Observer.Observe('ts_xa', T.TrimStart('xa'));
        Observer.Observe('te_xc', T.TrimEnd('xc'));
        Observer.Observe('te_cx_order', T.TrimEnd('cx'));
        Observer.Observe('ts_abcx', T.TrimStart('abcx') + '|');
        Observer.Observe('te_abcx', T.TrimEnd('abcx') + '|');
        Observer.Observe('ts_none', T.TrimStart('z'));
        Observer.Observe('te_none', T.TrimEnd('z'));
        Observer.Observe('ts_case', T.TrimStart('X'));
        Observer.Observe('te_case', T.TrimEnd('X'));
        Observer.Observe('ts_empty_set', T.TrimStart(''));
        Observer.Observe('te_empty_set', T.TrimEnd(''));
        Observer.Observe('ts_empty_text', E.TrimStart('x') + '|');
        Observer.Observe('te_empty_text', E.TrimEnd('x') + '|');
        Observer.Observe('ts_empty_both', E.TrimStart('') + '|');
        Observer.Observe('ts_inner_stop', 'xaxbx'.TrimStart('x'));
        Observer.Observe('te_inner_stop', 'xaxbx'.TrimEnd('x'));
        Observer.Observe('ts_multi_char_set_is_set', 'abbaabc'.TrimStart('ab'));
        Observer.Observe('te_multi_char_set_is_set', 'cbaabba'.TrimEnd('ab'));
        Observer.Observe('ts_space_default', '[' + '  a '.TrimStart(' ') + ']');
        Observer.Observe('ts_uml', 'ääxä'.TrimStart('ä'));
        Observer.Observe('te_uml', 'äxää'.TrimEnd('ä'));
        Observer.Expect('ts_x', 'abcxx');
        Observer.Expect('te_x', 'xxabc');
        Observer.Expect('ts_xa', 'bcxx');
        Observer.Expect('te_xc', 'xxab');
        Observer.Expect('te_cx_order', 'xxab');
        Observer.Expect('ts_abcx', '|');
        Observer.Expect('te_abcx', '|');
        Observer.Expect('ts_none', 'xxabcxx');
        Observer.Expect('te_none', 'xxabcxx');
        Observer.Expect('ts_case', 'xxabcxx');
        Observer.Expect('te_case', 'xxabcxx');
        Observer.Expect('ts_empty_set', 'xxabcxx');
        Observer.Expect('te_empty_set', 'xxabcxx');
        Observer.Expect('ts_empty_text', '|');
        Observer.Expect('te_empty_text', '|');
        Observer.Expect('ts_empty_both', '|');
        Observer.Expect('ts_inner_stop', 'axbx');
        Observer.Expect('te_inner_stop', 'xaxb');
        Observer.Expect('ts_multi_char_set_is_set', 'c');
        Observer.Expect('te_multi_char_set_is_set', 'c');
        Observer.Expect('ts_space_default', '[a ]');
        Observer.Expect('ts_uml', 'xä');
        Observer.Expect('te_uml', 'äx');
        Observer.Verify();
    end;

    [Test]
    procedure TrimStart_TrimEnd_WhitespaceDefault()
    var
        Observer: Codeunit "Probe Observer";
        Tab: Text[1];
        T: Text;
    begin
        Tab[1] := 9;
        T := '  a  ';
        Observer.Observe('ts_ws_set', '[' + T.TrimStart(' ' + Tab) + ']');
        Observer.Observe('te_ws_set', '[' + T.TrimEnd(' ' + Tab) + ']');
        Observer.Observe('ts_tab_not_in_set', Format(StrLen((Tab + ' a').TrimStart(' '))));
        Observer.Observe('te_tab_not_in_set', Format(StrLen(('a ' + Tab).TrimEnd(' '))));
        Observer.Observe('trim_start_chain', '[' + T.TrimStart(' ').TrimEnd(' ') + ']');
        Observer.Expect('ts_ws_set', '[a  ]');
        Observer.Expect('te_ws_set', '[  a]');
        Observer.Expect('ts_tab_not_in_set', '3');
        Observer.Expect('te_tab_not_in_set', '3');
        Observer.Expect('trim_start_chain', '[a]');
        Observer.Verify();
    end;
}
