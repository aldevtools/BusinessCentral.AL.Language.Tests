// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71524 "LT P103 TC Edge"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Src: TextConst ENU = 'Hello, World';
        PadSrc: TextConst ENU = '  xx, yy  ';
        EmptySrc: TextConst ENU = '';
        Uni: TextConst ENU = 'Gruesse Aerger';

    [Test]
    procedure P103_TcSearch_Edge()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('contains_self', Format(Src.Contains(Src)));
        Observer.Observe('contains_longer', Format(Src.Contains('Hello, World!')));
        Observer.Observe('contains_empty_src', Format(EmptySrc.Contains('a')));
        Observer.Observe('contains_empty_both', Format(EmptySrc.Contains('')));
        Observer.Observe('starts_self', Format(Src.StartsWith(Src)));
        Observer.Observe('starts_empty', Format(Src.StartsWith('')));
        Observer.Observe('starts_empty_src', Format(EmptySrc.StartsWith('a')));
        Observer.Observe('ends_self', Format(Src.EndsWith(Src)));
        Observer.Observe('ends_empty_src', Format(EmptySrc.EndsWith('a')));
        Observer.Observe('ends_longer', Format(Src.EndsWith('xHello, World')));
        Observer.Observe('indexof_start_last', Format(Src.IndexOf('d', 12)));
        Observer.Observe('indexof_start_after', Format(Src.IndexOf('d', 13)));
        Observer.Observe('indexof_empty_start', Format(Src.IndexOf('', 5)));
        Observer.Observe('indexof_empty_src', Format(EmptySrc.IndexOf('a')));
        Observer.Observe('indexof_empty_src_empty', Format(EmptySrc.IndexOf('')));
        Observer.Observe('lastindexof_empty', Format(Src.LastIndexOf('')));
        Observer.Observe('lastindexof_empty_src', Format(EmptySrc.LastIndexOf('a')));
        Observer.Observe('lastindexof_start1', Format(Src.LastIndexOf('H', 1)));
        Observer.Observe('lastindexof_start_end', Format(Src.LastIndexOf('o', 12)));
        asserterror Observer.Observe('indexof_start_0', Format(Src.IndexOf('o', 0)));
        Observer.ObserveError('indexof_start_0_err');
        asserterror Observer.Observe('indexof_start_big', Format(Src.IndexOf('o', 99)));
        Observer.ObserveError('indexof_start_big_err');
        asserterror Observer.Observe('lastindexof_start_0', Format(Src.LastIndexOf('o', 0)));
        Observer.ObserveError('lastindexof_start_0_err');
        asserterror Observer.Observe('lastindexof_start_big', Format(Src.LastIndexOf('o', 99)));
        Observer.ObserveError('lastindexof_start_big_err');
        Observer.Expect('contains_self', 'Yes');
        Observer.Expect('contains_longer', 'No');
        Observer.Expect('contains_empty_src', 'No');
        Observer.Expect('contains_empty_both', 'Yes');
        Observer.Expect('starts_self', 'Yes');
        Observer.Expect('starts_empty', 'Yes');
        Observer.Expect('starts_empty_src', 'No');
        Observer.Expect('ends_self', 'Yes');
        Observer.Expect('ends_empty_src', 'No');
        Observer.Expect('ends_longer', 'No');
        Observer.Expect('indexof_start_last', '12');
        Observer.Expect('indexof_start_after', '0');
        Observer.Expect('indexof_empty_start', '5');
        Observer.Expect('indexof_empty_src', '0');
        Observer.Expect('indexof_empty_src_empty', '1');
        Observer.Expect('lastindexof_empty', '13');
        Observer.Expect('lastindexof_empty_src', '0');
        Observer.Expect('lastindexof_start1', '1');
        Observer.Expect('lastindexof_start_end', '9');
        Observer.Expect('indexof_start_0_err|text', 'Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('indexof_start_0_err|code', 'ArgumentOutOfRange');
        Observer.Expect('indexof_start_big_err|text', 'Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('indexof_start_big_err|code', 'ArgumentOutOfRange');
        Observer.Expect('lastindexof_start_0_err|text', 'Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('lastindexof_start_0_err|code', 'ArgumentOutOfRange');
        Observer.Expect('lastindexof_start_big_err|text', 'Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('lastindexof_start_big_err|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure P103_TcPadRemove_Edge()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('padleft_zero', '[' + Src.PadLeft(0) + ']');
        Observer.Observe('padleft_exact', '[' + Src.PadLeft(12, '*') + ']');
        Observer.Observe('padleft_one_more', '[' + Src.PadLeft(13, '*') + ']');
        Observer.Observe('padleft_empty_src', '[' + EmptySrc.PadLeft(3, '-') + ']');
        Observer.Observe('padright_zero', '[' + Src.PadRight(0) + ']');
        Observer.Observe('padright_exact', '[' + Src.PadRight(12, '*') + ']');
        Observer.Observe('padright_one_more', '[' + Src.PadRight(13, '*') + ']');
        Observer.Observe('padright_empty_src', '[' + EmptySrc.PadRight(3, '-') + ']');
        Observer.Observe('remove_first', '[' + Src.Remove(1) + ']');
        Observer.Observe('remove_first_count', '[' + Src.Remove(1, 7) + ']');
        Observer.Observe('remove_count_zero', '[' + Src.Remove(3, 0) + ']');
        Observer.Observe('remove_all', '[' + Src.Remove(1, 12) + ']');
        Observer.Observe('remove_last', '[' + Src.Remove(12, 1) + ']');
        asserterror Observer.Observe('padleft_neg', Src.PadLeft(-1));
        Observer.ObserveError('padleft_neg_err');
        asserterror Observer.Observe('padright_neg', Src.PadRight(-1));
        Observer.ObserveError('padright_neg_err');
        asserterror Observer.Observe('remove_zero', Src.Remove(0));
        Observer.ObserveError('remove_zero_err');
        asserterror Observer.Observe('remove_big', Src.Remove(14));
        Observer.ObserveError('remove_big_err');
        asserterror Observer.Observe('remove_count_big', Src.Remove(8, 99));
        Observer.ObserveError('remove_count_big_err');
        asserterror Observer.Observe('remove_count_neg', Src.Remove(8, -1));
        Observer.ObserveError('remove_count_neg_err');
        Observer.Expect('padleft_zero', '[Hello, World]');
        Observer.Expect('padleft_exact', '[Hello, World]');
        Observer.Expect('padleft_one_more', '[*Hello, World]');
        Observer.Expect('padleft_empty_src', '[---]');
        Observer.Expect('padright_zero', '[Hello, World]');
        Observer.Expect('padright_exact', '[Hello, World]');
        Observer.Expect('padright_one_more', '[Hello, World*]');
        Observer.Expect('padright_empty_src', '[---]');
        Observer.Expect('remove_first', '[]');
        Observer.Expect('remove_first_count', '[World]');
        Observer.Expect('remove_count_zero', '[Hello, World]');
        Observer.Expect('remove_all', '[]');
        Observer.Expect('remove_last', '[Hello, Worl]');
        Observer.Expect('padleft_neg_err|text', 'totalWidth (''-1'') must be a non-negative value. (Parameter ''totalWidth'')\Actual value was -1.');
        Observer.Expect('padleft_neg_err|code', 'ArgumentOutOfRange');
        Observer.Expect('padright_neg_err|text', 'totalWidth (''-1'') must be a non-negative value. (Parameter ''totalWidth'')\Actual value was -1.');
        Observer.Expect('padright_neg_err|code', 'ArgumentOutOfRange');
        Observer.Expect('remove_zero_err|text', 'StartIndex cannot be less than 1. (Parameter ''startIndex'')');
        Observer.Expect('remove_zero_err|code', 'ArgumentOutOfRange');
        Observer.Expect('remove_big_err|text', 'startIndex cannot be larger than length of string. (Parameter ''startIndex'')');
        Observer.Expect('remove_big_err|code', 'ArgumentOutOfRange');
        Observer.Expect('remove_count_big_err|text', 'count (''99'') must be less than or equal to ''5''. (Parameter ''count'')\Actual value was 99.');
        Observer.Expect('remove_count_big_err|code', 'ArgumentOutOfRange');
        Observer.Expect('remove_count_neg_err|text', 'count (''-1'') must be a non-negative value. (Parameter ''count'')\Actual value was -1.');
        Observer.Expect('remove_count_neg_err|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure P103_TcReplaceSub_Edge()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('replace_delete', '[' + Src.Replace('l', '') + ']');
        Observer.Observe('replace_longer', '[' + Src.Replace('o', 'oo') + ']');
        Observer.Observe('replace_multi', '[' + Src.Replace('Hello', 'Bye') + ']');
        Observer.Observe('replace_case', '[' + Src.Replace('hello', 'Bye') + ']');
        Observer.Observe('replace_whole', '[' + Src.Replace(Src, 'x') + ']');
        Observer.Observe('replace_empty_src', '[' + EmptySrc.Replace('a', 'b') + ']');
        asserterror Observer.Observe('replace_empty_old', Src.Replace('', 'x'));
        Observer.ObserveError('replace_empty_old_err');
        Observer.Observe('substring_first', '[' + Src.Substring(1) + ']');
        Observer.Observe('substring_one', '[' + Src.Substring(1, 1) + ']');
        Observer.Observe('substring_last', '[' + Src.Substring(12) + ']');
        Observer.Observe('substring_all', '[' + Src.Substring(1, 12) + ']');
        Observer.Observe('substring_count_zero', '[' + Src.Substring(5, 0) + ']');
        Observer.Observe('substring_empty_src', '[' + EmptySrc.Substring(1) + ']');
        asserterror Observer.Observe('substring_zero', Src.Substring(0));
        Observer.ObserveError('substring_zero_err');
        asserterror Observer.Observe('substring_big', Src.Substring(14));
        Observer.ObserveError('substring_big_err');
        Observer.Observe('substring_count_big', Src.Substring(8, 99));
        Observer.Observe('substring_count_big_err', 'no error');
        asserterror Observer.Observe('substring_count_neg', Src.Substring(8, -1));
        Observer.ObserveError('substring_count_neg_err');
        Observer.Expect('replace_delete', '[Heo, Word]');
        Observer.Expect('replace_longer', '[Helloo, Woorld]');
        Observer.Expect('replace_multi', '[Bye, World]');
        Observer.Expect('replace_case', '[Hello, World]');
        Observer.Expect('replace_whole', '[x]');
        Observer.Expect('replace_empty_src', '[]');
        Observer.Expect('replace_empty_old_err|text', 'The value cannot be an empty string. (Parameter ''oldValue'')');
        Observer.Expect('replace_empty_old_err|code', 'Argument');
        Observer.Expect('substring_first', '[Hello, World]');
        Observer.Expect('substring_one', '[H]');
        Observer.Expect('substring_last', '[d]');
        Observer.Expect('substring_all', '[Hello, World]');
        Observer.Expect('substring_count_zero', '[]');
        Observer.Expect('substring_empty_src', '[]');
        Observer.Expect('substring_zero_err|text', 'startIndex (''-1'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -1.');
        Observer.Expect('substring_zero_err|code', 'ArgumentOutOfRange');
        Observer.Expect('substring_big_err|text', 'startIndex cannot be larger than length of string. (Parameter ''startIndex'')');
        Observer.Expect('substring_big_err|code', 'ArgumentOutOfRange');
        Observer.Expect('substring_count_big', 'World');
        Observer.Expect('substring_count_big_err', 'no error');
        Observer.Expect('substring_count_neg_err|text', 'length (''-1'') must be a non-negative value. (Parameter ''length'')\Actual value was -1.');
        Observer.Expect('substring_count_neg_err|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure P103_TcCaseTrim_Edge()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('tolower_empty', '[' + EmptySrc.ToLower() + ']');
        Observer.Observe('toupper_empty', '[' + EmptySrc.ToUpper() + ']');
        Observer.Observe('tolower_pad', '[' + PadSrc.ToLower() + ']');
        Observer.Observe('toupper_pad', '[' + PadSrc.ToUpper() + ']');
        Observer.Observe('trim_empty', '[' + EmptySrc.Trim() + ']');
        Observer.Observe('trim_nothing', '[' + Src.Trim() + ']');
        Observer.Observe('trimstart_noargs', '[' + PadSrc.TrimStart() + ']');
        Observer.Observe('trimend_noargs', '[' + PadSrc.TrimEnd() + ']');
        Observer.Observe('trimstart_empty_chars', '[' + PadSrc.TrimStart('') + ']');
        Observer.Observe('trimend_empty_chars', '[' + PadSrc.TrimEnd('') + ']');
        Observer.Observe('trimstart_miss', '[' + PadSrc.TrimStart('q') + ']');
        Observer.Observe('trimend_miss', '[' + PadSrc.TrimEnd('q') + ']');
        Observer.Observe('trimstart_all', '[' + PadSrc.TrimStart(' xy,') + ']');
        Observer.Observe('trimend_all', '[' + PadSrc.TrimEnd(' xy,') + ']');
        Observer.Observe('trimstart_case', '[' + PadSrc.TrimStart(' X') + ']');
        Observer.Observe('trimend_empty_src', '[' + EmptySrc.TrimEnd(' ') + ']');
        Observer.Observe('trimstart_empty_src', '[' + EmptySrc.TrimStart(' ') + ']');
        Observer.Expect('tolower_empty', '[]');
        Observer.Expect('toupper_empty', '[]');
        Observer.Expect('tolower_pad', '[  xx, yy  ]');
        Observer.Expect('toupper_pad', '[  XX, YY  ]');
        Observer.Expect('trim_empty', '[]');
        Observer.Expect('trim_nothing', '[Hello, World]');
        Observer.Expect('trimstart_noargs', '[xx, yy  ]');
        Observer.Expect('trimend_noargs', '[  xx, yy]');
        Observer.Expect('trimstart_empty_chars', '[xx, yy  ]');
        Observer.Expect('trimend_empty_chars', '[  xx, yy]');
        Observer.Expect('trimstart_miss', '[  xx, yy  ]');
        Observer.Expect('trimend_miss', '[  xx, yy  ]');
        Observer.Expect('trimstart_all', '[]');
        Observer.Expect('trimend_all', '[]');
        Observer.Expect('trimstart_case', '[xx, yy  ]');
        Observer.Expect('trimend_empty_src', '[]');
        Observer.Expect('trimstart_empty_src', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure P103_TcConcat_Edge()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := Src.Replace('World', 'AL').ToUpper().PadRight(10, '.');
        Observer.Observe('chain', '[' + T + ']');
        Observer.Observe('chain_sub', Src.Substring(8).ToLower().Replace('o', '0'));
        Observer.Observe('len_after_pad', Format(StrLen(PadSrc.Trim())));
        Observer.Observe('contains_after_trim', Format(PadSrc.Trim().Contains('xx')));
        Observer.Observe('split_count_chain', Format(Src.Replace(',', ';').Split(';').Count()));
        Observer.Expect('chain', '[HELLO, AL.]');
        Observer.Expect('chain_sub', 'w0rld');
        Observer.Expect('len_after_pad', '6');
        Observer.Expect('contains_after_trim', 'Yes');
        Observer.Expect('split_count_chain', '2');
        Observer.Verify();
    end;
}
