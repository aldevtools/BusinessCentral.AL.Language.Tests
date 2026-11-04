// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 70010
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Text.PadLeft, PadRight, Replace, Remove, Substring on variables and literals, including out-of-range arguments.
// BC versions: 29 (27 and 28 by CI)

codeunit 70010 "LT TxA Edit 1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure L(Value: Text): Text
    begin
        exit(Value);
    end;

    [Test]
    procedure PadLeft_Basic()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
    begin
        T := 'abc';
        Observer.Observe('pl_6', T.PadLeft(6) + '|');
        Observer.Observe('pl_6_x', T.PadLeft(6, 'x'));
        Observer.Observe('pl_3_x', T.PadLeft(3, 'x'));
        Observer.Observe('pl_2_x', T.PadLeft(2, 'x'));
        Observer.Observe('pl_0_x', T.PadLeft(0, 'x'));
        Observer.Observe('pl_1_x', T.PadLeft(1, 'x'));
        Observer.Observe('pl_4_x', T.PadLeft(4, 'x'));
        Observer.Observe('pl_empty_3', E.PadLeft(3, '*'));
        Observer.Observe('pl_empty_0', E.PadLeft(0, '*') + '|');
        Observer.Observe('pl_lit', 'ab'.PadLeft(5, '-'));
        Observer.Observe('pl_lit_empty', ''.PadLeft(2, '-'));
        Observer.Observe('pl_lit_zero_char', Format(StrLen('ab'.PadLeft(5))));
        Observer.Observe('pl_uml', L('ä').PadLeft(3, 'ö'));
        Observer.Observe('pl_len_1000', Format(StrLen(L('a').PadLeft(1000, 'z'))));
        Observer.Observe('pl_len_10000', Format(StrLen(L('a').PadLeft(10000, 'z'))));
        asserterror Observer.Observe('pl_neg', T.PadLeft(-1, 'x'));
        Observer.ObserveError('pl_neg_err');
        asserterror Observer.Observe('pl_neg5', T.PadLeft(-5));
        Observer.ObserveError('pl_neg5_err');
        Observer.Expect('pl_6', '   abc|');
        Observer.Expect('pl_6_x', 'xxxabc');
        Observer.Expect('pl_3_x', 'abc');
        Observer.Expect('pl_2_x', 'abc');
        Observer.Expect('pl_0_x', 'abc');
        Observer.Expect('pl_1_x', 'abc');
        Observer.Expect('pl_4_x', 'xabc');
        Observer.Expect('pl_empty_3', '***');
        Observer.Expect('pl_empty_0', '|');
        Observer.Expect('pl_lit', '---ab');
        Observer.Expect('pl_lit_empty', '--');
        Observer.Expect('pl_lit_zero_char', '5');
        Observer.Expect('pl_uml', 'ööä');
        Observer.Expect('pl_len_1000', '1000');
        Observer.Expect('pl_len_10000', '10000');
        Observer.Expect('pl_neg_err|text', 'totalWidth (''-1'') must be a non-negative value. (Parameter ''totalWidth'')\Actual value was -1.');
        Observer.Expect('pl_neg_err|code', 'ArgumentOutOfRange');
        Observer.Expect('pl_neg5_err|text', 'totalWidth (''-5'') must be a non-negative value. (Parameter ''totalWidth'')\Actual value was -5.');
        Observer.Expect('pl_neg5_err|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure PadLeft_SpaceAndNumbers()
    var
        Observer: Codeunit "Probe Observer";
        Nine: Text;
        I: Integer;
    begin
        I := 42;
        Observer.Observe('pl_int_zero', Format(I).PadLeft(6, '0'));
        Observer.Observe('pl_int_space', '[' + Format(I).PadLeft(6) + ']');
        Observer.Observe('pl_int_neg', Format(-I).PadLeft(6, '0'));
        Nine := 'x';
        Observer.Observe('pl_chain', Nine.PadLeft(3, 'a').PadLeft(5, 'b'));
        Observer.Observe('pl_pad_space_char', '[' + Nine.PadLeft(3, ' ') + ']');
        Observer.Observe('pl_text_max', Format(StrLen(CopyStr('abc', 1, 2).PadLeft(10, '.'))));
        Observer.Expect('pl_int_zero', '000042');
        Observer.Expect('pl_int_space', '[    42]');
        Observer.Expect('pl_int_neg', '000-42');
        Observer.Expect('pl_chain', 'bbaax');
        Observer.Expect('pl_pad_space_char', '[  x]');
        Observer.Expect('pl_text_max', '10');
        Observer.Verify();
    end;

    [Test]
    procedure PadRight_Basic()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
    begin
        T := 'abc';
        Observer.Observe('pr_6', T.PadRight(6) + '|');
        Observer.Observe('pr_6_x', T.PadRight(6, 'x'));
        Observer.Observe('pr_3_x', T.PadRight(3, 'x'));
        Observer.Observe('pr_2_x', T.PadRight(2, 'x'));
        Observer.Observe('pr_0_x', T.PadRight(0, 'x'));
        Observer.Observe('pr_1_x', T.PadRight(1, 'x'));
        Observer.Observe('pr_4_x', T.PadRight(4, 'x'));
        Observer.Observe('pr_empty_3', E.PadRight(3, '*'));
        Observer.Observe('pr_empty_0', E.PadRight(0, '*') + '|');
        Observer.Observe('pr_lit', 'ab'.PadRight(5, '-'));
        Observer.Observe('pr_lit_empty', ''.PadRight(2, '-'));
        Observer.Observe('pr_lit_len', Format(StrLen('ab'.PadRight(5))));
        Observer.Observe('pr_uml', L('ä').PadRight(3, 'ö'));
        Observer.Observe('pr_len_1000', Format(StrLen(L('a').PadRight(1000, 'z'))));
        Observer.Observe('pr_len_10000', Format(StrLen(L('a').PadRight(10000, 'z'))));
        asserterror Observer.Observe('pr_neg', T.PadRight(-1, 'x'));
        Observer.ObserveError('pr_neg_err');
        asserterror Observer.Observe('pr_neg5', T.PadRight(-5));
        Observer.ObserveError('pr_neg5_err');
        Observer.Expect('pr_6', 'abc   |');
        Observer.Expect('pr_6_x', 'abcxxx');
        Observer.Expect('pr_3_x', 'abc');
        Observer.Expect('pr_2_x', 'abc');
        Observer.Expect('pr_0_x', 'abc');
        Observer.Expect('pr_1_x', 'abc');
        Observer.Expect('pr_4_x', 'abcx');
        Observer.Expect('pr_empty_3', '***');
        Observer.Expect('pr_empty_0', '|');
        Observer.Expect('pr_lit', 'ab---');
        Observer.Expect('pr_lit_empty', '--');
        Observer.Expect('pr_lit_len', '5');
        Observer.Expect('pr_uml', 'äöö');
        Observer.Expect('pr_len_1000', '1000');
        Observer.Expect('pr_len_10000', '10000');
        Observer.Expect('pr_neg_err|text', 'totalWidth (''-1'') must be a non-negative value. (Parameter ''totalWidth'')\Actual value was -1.');
        Observer.Expect('pr_neg_err|code', 'ArgumentOutOfRange');
        Observer.Expect('pr_neg5_err|text', 'totalWidth (''-5'') must be a non-negative value. (Parameter ''totalWidth'')\Actual value was -5.');
        Observer.Expect('pr_neg5_err|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure Replace_Basic()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
    begin
        T := 'abcabcabc';
        Observer.Observe('rep_b_X', T.Replace('b', 'X'));
        Observer.Observe('rep_abc_X', T.Replace('abc', 'X'));
        Observer.Observe('rep_abc_empty', T.Replace('abc', '') + '|');
        Observer.Observe('rep_missing', T.Replace('x', 'Y'));
        Observer.Observe('rep_case', T.Replace('B', 'Y'));
        Observer.Observe('rep_self', T.Replace(T, 'Z'));
        Observer.Observe('rep_grow', T.Replace('b', 'bbb'));
        Observer.Observe('rep_bc_cb', T.Replace('bc', 'cb'));
        Observer.Observe('rep_nonoverlap', 'aaaa'.Replace('aa', 'b'));
        Observer.Observe('rep_nonoverlap3', 'aaaaa'.Replace('aa', 'b'));
        Observer.Observe('rep_recursive', 'aab'.Replace('ab', 'a'));
        Observer.Observe('rep_empty_src', E.Replace('a', 'b') + '|');
        asserterror Observer.Observe('rep_empty_src_empty_old', E.Replace('', 'b') + '|');
        Observer.ObserveError('af116');
        Observer.Observe('rep_lit_space', 'a b c'.Replace(' ', ''));
        Observer.Observe('rep_lit_dollar', 'a.b.c'.Replace('.', '$1'));
        Observer.Observe('rep_lit_regexchars', 'a.b*c'.Replace('.*', '-'));
        Observer.Observe('rep_lit_star', 'a.b*c'.Replace('*', '-'));
        Observer.Observe('rep_uml', 'Straße'.Replace('ß', 'ss'));
        Observer.Observe('rep_uml_upper', 'ÄÖÜ'.Replace('ä', 'a'));
        Observer.Expect('rep_b_X', 'aXcaXcaXc');
        Observer.Expect('rep_abc_X', 'XXX');
        Observer.Expect('rep_abc_empty', '|');
        Observer.Expect('rep_missing', 'abcabcabc');
        Observer.Expect('rep_case', 'abcabcabc');
        Observer.Expect('rep_self', 'Z');
        Observer.Expect('rep_grow', 'abbbcabbbcabbbc');
        Observer.Expect('rep_bc_cb', 'acbacbacb');
        Observer.Expect('rep_nonoverlap', 'bb');
        Observer.Expect('rep_nonoverlap3', 'bba');
        Observer.Expect('rep_recursive', 'aa');
        Observer.Expect('rep_empty_src', '|');
        Observer.Expect('af116|text', 'The value cannot be an empty string. (Parameter ''oldValue'')');
        Observer.Expect('af116|code', 'Argument');
        Observer.Expect('rep_lit_space', 'abc');
        Observer.Expect('rep_lit_dollar', 'a$1b$1c');
        Observer.Expect('rep_lit_regexchars', 'a.b*c');
        Observer.Expect('rep_lit_star', 'a.b-c');
        Observer.Expect('rep_uml', 'Strasse');
        Observer.Expect('rep_uml_upper', 'ÄÖÜ');
        Observer.Verify();
    end;

    [Test]
    procedure Replace_EmptyOldValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Observer.Observe('rep_emptyold', 'abc'.Replace('', 'X'));
        Observer.ObserveError('rep_emptyold_err');
        asserterror Observer.Observe('rep_emptyold_both', 'abc'.Replace('', ''));
        Observer.ObserveError('rep_emptyold_both_err');
        asserterror Observer.Observe('rep_emptyold_emptysrc', ''.Replace('', 'X'));
        Observer.ObserveError('rep_emptyold_emptysrc_err');
        Observer.Observe('rep_newempty', 'abc'.Replace('b', '') + '|');
        Observer.Observe('rep_char_in_new', 'abc'.Replace('b', 'b'));
        Observer.Expect('rep_emptyold_err|text', 'The value cannot be an empty string. (Parameter ''oldValue'')');
        Observer.Expect('rep_emptyold_err|code', 'Argument');
        Observer.Expect('rep_emptyold_both_err|text', 'The value cannot be an empty string. (Parameter ''oldValue'')');
        Observer.Expect('rep_emptyold_both_err|code', 'Argument');
        Observer.Expect('rep_emptyold_emptysrc_err|text', 'The value cannot be an empty string. (Parameter ''oldValue'')');
        Observer.Expect('rep_emptyold_emptysrc_err|code', 'Argument');
        Observer.Expect('rep_newempty', 'ac|');
        Observer.Expect('rep_char_in_new', 'abc');
        Observer.Verify();
    end;

    [Test]
    procedure Remove_OneArg()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
    begin
        T := 'abcdef';
        Observer.Observe('rm_1', T.Remove(1) + '|');
        Observer.Observe('rm_2', T.Remove(2));
        Observer.Observe('rm_6', T.Remove(6));
        Observer.Observe('rm_3', T.Remove(3));
        Observer.Observe('rm_7', T.Remove(7));
        Observer.Observe('rm_7_err', 'no error');
        asserterror Observer.Observe('rm_8', T.Remove(8));
        Observer.ObserveError('rm_8_err');
        asserterror Observer.Observe('rm_0', T.Remove(0));
        Observer.ObserveError('rm_0_err');
        asserterror Observer.Observe('rm_neg', T.Remove(-1));
        Observer.ObserveError('rm_neg_err');
        Observer.Observe('rm_empty_1', E.Remove(1));
        Observer.Observe('rm_empty_1_err', 'no error');
        asserterror Observer.Observe('rm_empty_0', E.Remove(0));
        Observer.ObserveError('rm_empty_0_err');
        Observer.Observe('rm_lit', 'hello'.Remove(3));
        Observer.Observe('rm_lit_6', 'hello'.Remove(6));
        Observer.Observe('rm_lit_6_err', 'no error');
        Observer.Expect('rm_1', '|');
        Observer.Expect('rm_2', 'a');
        Observer.Expect('rm_6', 'abcde');
        Observer.Expect('rm_3', 'ab');
        Observer.Expect('rm_7', 'abcdef');
        Observer.Expect('rm_7_err', 'no error');
        Observer.Expect('rm_8_err|text', 'startIndex cannot be larger than length of string. (Parameter ''startIndex'')');
        Observer.Expect('rm_8_err|code', 'ArgumentOutOfRange');
        Observer.Expect('rm_0_err|text', 'StartIndex cannot be less than 1. (Parameter ''startIndex'')');
        Observer.Expect('rm_0_err|code', 'ArgumentOutOfRange');
        Observer.Expect('rm_neg_err|text', 'StartIndex cannot be less than 1. (Parameter ''startIndex'')');
        Observer.Expect('rm_neg_err|code', 'ArgumentOutOfRange');
        Observer.Expect('rm_empty_1', '');
        Observer.Expect('rm_empty_1_err', 'no error');
        Observer.Expect('rm_empty_0_err|text', 'StartIndex cannot be less than 1. (Parameter ''startIndex'')');
        Observer.Expect('rm_empty_0_err|code', 'ArgumentOutOfRange');
        Observer.Expect('rm_lit', 'he');
        Observer.Expect('rm_lit_6', 'hello');
        Observer.Expect('rm_lit_6_err', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Remove_TwoArgs()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
    begin
        T := 'abcdef';
        Observer.Observe('rm_1_1', T.Remove(1, 1));
        Observer.Observe('rm_1_6', T.Remove(1, 6) + '|');
        Observer.Observe('rm_2_3', T.Remove(2, 3));
        Observer.Observe('rm_6_1', T.Remove(6, 1));
        Observer.Observe('rm_3_0', T.Remove(3, 0));
        Observer.Observe('rm_1_0', T.Remove(1, 0));
        Observer.Observe('rm_6_0', T.Remove(6, 0));
        Observer.Observe('rm_7_0', T.Remove(7, 0));
        Observer.Observe('rm_7_0_err', 'no error');
        asserterror Observer.Observe('rm_1_7', T.Remove(1, 7));
        Observer.ObserveError('rm_1_7_err');
        asserterror Observer.Observe('rm_4_4', T.Remove(4, 4));
        Observer.ObserveError('rm_4_4_err');
        asserterror Observer.Observe('rm_6_2', T.Remove(6, 2));
        Observer.ObserveError('rm_6_2_err');
        asserterror Observer.Observe('rm_0_1', T.Remove(0, 1));
        Observer.ObserveError('rm_0_1_err');
        asserterror Observer.Observe('rm_neg_1', T.Remove(-1, 1));
        Observer.ObserveError('rm_neg_1_err');
        asserterror Observer.Observe('rm_2_neg', T.Remove(2, -1));
        Observer.ObserveError('rm_2_neg_err');
        Observer.Observe('rm_empty_1_0', E.Remove(1, 0));
        Observer.Observe('rm_empty_1_0_err', 'no error');
        asserterror Observer.Observe('rm_empty_1_1', E.Remove(1, 1));
        Observer.ObserveError('rm_empty_1_1_err');
        Observer.Observe('rm_lit', 'hello'.Remove(2, 3));
        asserterror Observer.Observe('rm_lit_err', 'hello'.Remove(2, 5));
        Observer.ObserveError('rm_lit_err_err');
        Observer.Expect('rm_1_1', 'bcdef');
        Observer.Expect('rm_1_6', '|');
        Observer.Expect('rm_2_3', 'aef');
        Observer.Expect('rm_6_1', 'abcde');
        Observer.Expect('rm_3_0', 'abcdef');
        Observer.Expect('rm_1_0', 'abcdef');
        Observer.Expect('rm_6_0', 'abcdef');
        Observer.Expect('rm_7_0', 'abcdef');
        Observer.Expect('rm_7_0_err', 'no error');
        Observer.Expect('rm_1_7_err|text', 'count (''7'') must be less than or equal to ''6''. (Parameter ''count'')\Actual value was 7.');
        Observer.Expect('rm_1_7_err|code', 'ArgumentOutOfRange');
        Observer.Expect('rm_4_4_err|text', 'count (''4'') must be less than or equal to ''3''. (Parameter ''count'')\Actual value was 4.');
        Observer.Expect('rm_4_4_err|code', 'ArgumentOutOfRange');
        Observer.Expect('rm_6_2_err|text', 'count (''2'') must be less than or equal to ''1''. (Parameter ''count'')\Actual value was 2.');
        Observer.Expect('rm_6_2_err|code', 'ArgumentOutOfRange');
        Observer.Expect('rm_0_1_err|text', 'startIndex (''-1'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -1.');
        Observer.Expect('rm_0_1_err|code', 'ArgumentOutOfRange');
        Observer.Expect('rm_neg_1_err|text', 'startIndex (''-2'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -2.');
        Observer.Expect('rm_neg_1_err|code', 'ArgumentOutOfRange');
        Observer.Expect('rm_2_neg_err|text', 'count (''-1'') must be a non-negative value. (Parameter ''count'')\Actual value was -1.');
        Observer.Expect('rm_2_neg_err|code', 'ArgumentOutOfRange');
        Observer.Expect('rm_empty_1_0', '');
        Observer.Expect('rm_empty_1_0_err', 'no error');
        Observer.Expect('rm_empty_1_1_err|text', 'count (''1'') must be less than or equal to ''0''. (Parameter ''count'')\Actual value was 1.');
        Observer.Expect('rm_empty_1_1_err|code', 'ArgumentOutOfRange');
        Observer.Expect('rm_lit', 'ho');
        Observer.Expect('rm_lit_err_err|text', 'count (''5'') must be less than or equal to ''4''. (Parameter ''count'')\Actual value was 5.');
        Observer.Expect('rm_lit_err_err|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure Substring_OneArg()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
    begin
        T := 'abcdef';
        Observer.Observe('ss_1', T.Substring(1));
        Observer.Observe('ss_2', T.Substring(2));
        Observer.Observe('ss_6', T.Substring(6));
        Observer.Observe('ss_7', T.Substring(7) + '|');
        Observer.Observe('ss_7_err', 'no error');
        asserterror Observer.Observe('ss_8', T.Substring(8));
        Observer.ObserveError('ss_8_err');
        asserterror Observer.Observe('ss_0', T.Substring(0));
        Observer.ObserveError('ss_0_err');
        asserterror Observer.Observe('ss_neg', T.Substring(-1));
        Observer.ObserveError('ss_neg_err');
        Observer.Observe('ss_empty_1', E.Substring(1) + '|');
        Observer.Observe('ss_empty_1_err', 'no error');
        asserterror Observer.Observe('ss_empty_0', E.Substring(0));
        Observer.ObserveError('ss_empty_0_err');
        Observer.Observe('ss_lit', 'hello'.Substring(3));
        Observer.Observe('ss_lit_6', 'hello'.Substring(6) + '|');
        Observer.Observe('ss_lit_6_err', 'no error');
        Observer.Expect('ss_1', 'abcdef');
        Observer.Expect('ss_2', 'bcdef');
        Observer.Expect('ss_6', 'f');
        Observer.Expect('ss_7', '|');
        Observer.Expect('ss_7_err', 'no error');
        Observer.Expect('ss_8_err|text', 'startIndex cannot be larger than length of string. (Parameter ''startIndex'')');
        Observer.Expect('ss_8_err|code', 'ArgumentOutOfRange');
        Observer.Expect('ss_0_err|text', 'startIndex (''-1'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -1.');
        Observer.Expect('ss_0_err|code', 'ArgumentOutOfRange');
        Observer.Expect('ss_neg_err|text', 'startIndex (''-2'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -2.');
        Observer.Expect('ss_neg_err|code', 'ArgumentOutOfRange');
        Observer.Expect('ss_empty_1', '|');
        Observer.Expect('ss_empty_1_err', 'no error');
        Observer.Expect('ss_empty_0_err|text', 'startIndex (''-1'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -1.');
        Observer.Expect('ss_empty_0_err|code', 'ArgumentOutOfRange');
        Observer.Expect('ss_lit', 'llo');
        Observer.Expect('ss_lit_6', '|');
        Observer.Expect('ss_lit_6_err', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Substring_TwoArgs()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
    begin
        T := 'abcdef';
        Observer.Observe('ss_1_1', T.Substring(1, 1));
        Observer.Observe('ss_1_6', T.Substring(1, 6));
        Observer.Observe('ss_2_3', T.Substring(2, 3));
        Observer.Observe('ss_6_1', T.Substring(6, 1));
        Observer.Observe('ss_3_0', T.Substring(3, 0) + '|');
        Observer.Observe('ss_6_0', T.Substring(6, 0) + '|');
        Observer.Observe('ss_7_0', T.Substring(7, 0));
        Observer.Observe('ss_7_0_err', 'no error');
        Observer.Observe('ss_1_7', T.Substring(1, 7));
        Observer.Observe('ss_1_7_err', 'no error');
        Observer.Observe('ss_4_4', T.Substring(4, 4));
        Observer.Observe('ss_4_4_err', 'no error');
        asserterror Observer.Observe('ss_0_1', T.Substring(0, 1));
        Observer.ObserveError('ss_0_1_err');
        asserterror Observer.Observe('ss_neg_1', T.Substring(-1, 1));
        Observer.ObserveError('ss_neg_1_err');
        asserterror Observer.Observe('ss_2_neg', T.Substring(2, -1));
        Observer.ObserveError('ss_2_neg_err');
        Observer.Observe('ss_empty_1_0', E.Substring(1, 0));
        Observer.Observe('ss_empty_1_0_err', 'no error');
        Observer.Observe('ss_empty_1_1', E.Substring(1, 1));
        Observer.Observe('ss_empty_1_1_err', 'no error');
        Observer.Observe('ss_lit', 'hello'.Substring(2, 3));
        Observer.Observe('ss_lit_err', 'hello'.Substring(2, 5));
        Observer.Observe('ss_lit_err_err', 'no error');
        Observer.Observe('ss_uml', 'Straße'.Substring(5, 2));
        Observer.Expect('ss_1_1', 'a');
        Observer.Expect('ss_1_6', 'abcdef');
        Observer.Expect('ss_2_3', 'bcd');
        Observer.Expect('ss_6_1', 'f');
        Observer.Expect('ss_3_0', '|');
        Observer.Expect('ss_6_0', '|');
        Observer.Expect('ss_7_0', '');
        Observer.Expect('ss_7_0_err', 'no error');
        Observer.Expect('ss_1_7', 'abcdef');
        Observer.Expect('ss_1_7_err', 'no error');
        Observer.Expect('ss_4_4', 'def');
        Observer.Expect('ss_4_4_err', 'no error');
        Observer.Expect('ss_0_1_err|text', 'startIndex (''-1'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -1.');
        Observer.Expect('ss_0_1_err|code', 'ArgumentOutOfRange');
        Observer.Expect('ss_neg_1_err|text', 'startIndex (''-2'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -2.');
        Observer.Expect('ss_neg_1_err|code', 'ArgumentOutOfRange');
        Observer.Expect('ss_2_neg_err|text', 'length (''-1'') must be a non-negative value. (Parameter ''length'')\Actual value was -1.');
        Observer.Expect('ss_2_neg_err|code', 'ArgumentOutOfRange');
        Observer.Expect('ss_empty_1_0', '');
        Observer.Expect('ss_empty_1_0_err', 'no error');
        Observer.Expect('ss_empty_1_1', '');
        Observer.Expect('ss_empty_1_1_err', 'no error');
        Observer.Expect('ss_lit', 'ell');
        Observer.Expect('ss_lit_err', 'ello');
        Observer.Expect('ss_lit_err_err', 'no error');
        Observer.Expect('ss_uml', 'ße');
        Observer.Verify();
    end;
}
