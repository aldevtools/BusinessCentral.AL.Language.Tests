// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71525 "LT P103 Label Edge"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Src: Label 'Hello, World';
        PadSrc: Label '  xx, yy  ';
        EmptySrc: Label '';

    [Test]
    procedure P103_LbSearch_Edge()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('contains_self', Format(Src.Contains(Src)));
        Observer.Observe('contains_empty_src', Format(EmptySrc.Contains('a')));
        Observer.Observe('contains_empty_both', Format(EmptySrc.Contains('')));
        Observer.Observe('starts_self', Format(Src.StartsWith(Src)));
        Observer.Observe('starts_empty_src', Format(EmptySrc.StartsWith('a')));
        Observer.Observe('ends_self', Format(Src.EndsWith(Src)));
        Observer.Observe('ends_empty_src', Format(EmptySrc.EndsWith('a')));
        Observer.Observe('indexof_start_last', Format(Src.IndexOf('d', 12)));
        Observer.Observe('indexof_start_after', Format(Src.IndexOf('d', 13)));
        Observer.Observe('indexof_empty_src', Format(EmptySrc.IndexOf('a')));
        Observer.Observe('lastindexof_empty', Format(Src.LastIndexOf('')));
        Observer.Observe('lastindexof_empty_src', Format(EmptySrc.LastIndexOf('a')));
        asserterror Observer.Observe('indexof_start_0', Format(Src.IndexOf('o', 0)));
        Observer.ObserveError('indexof_start_0_err');
        asserterror Observer.Observe('lastindexof_start_big', Format(Src.LastIndexOf('o', 99)));
        Observer.ObserveError('lastindexof_start_big_err');
        Observer.Expect('contains_self', 'Yes');
        Observer.Expect('contains_empty_src', 'No');
        Observer.Expect('contains_empty_both', 'Yes');
        Observer.Expect('starts_self', 'Yes');
        Observer.Expect('starts_empty_src', 'No');
        Observer.Expect('ends_self', 'Yes');
        Observer.Expect('ends_empty_src', 'No');
        Observer.Expect('indexof_start_last', '12');
        Observer.Expect('indexof_start_after', '0');
        Observer.Expect('indexof_empty_src', '0');
        Observer.Expect('lastindexof_empty', '13');
        Observer.Expect('lastindexof_empty_src', '0');
        Observer.Expect('indexof_start_0_err|text', 'Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('indexof_start_0_err|code', 'ArgumentOutOfRange');
        Observer.Expect('lastindexof_start_big_err|text', 'Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('lastindexof_start_big_err|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure P103_LbEdit_Edge()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('padleft_zero', '[' + Src.PadLeft(0) + ']');
        Observer.Observe('padright_exact', '[' + Src.PadRight(12, '*') + ']');
        Observer.Observe('padleft_empty_src', '[' + EmptySrc.PadLeft(3, '-') + ']');
        Observer.Observe('remove_all', '[' + Src.Remove(1, 12) + ']');
        Observer.Observe('remove_count_zero', '[' + Src.Remove(3, 0) + ']');
        Observer.Observe('replace_delete', '[' + Src.Replace('l', '') + ']');
        Observer.Observe('replace_empty_src', '[' + EmptySrc.Replace('a', 'b') + ']');
        Observer.Observe('substring_last', '[' + Src.Substring(12) + ']');
        Observer.Observe('substring_count_zero', '[' + Src.Substring(5, 0) + ']');
        Observer.Observe('tolower_empty', '[' + EmptySrc.ToLower() + ']');
        Observer.Observe('toupper_empty', '[' + EmptySrc.ToUpper() + ']');
        Observer.Observe('trim_empty', '[' + EmptySrc.Trim() + ']');
        Observer.Observe('trimstart_noargs', '[' + PadSrc.TrimStart() + ']');
        Observer.Observe('trimend_noargs', '[' + PadSrc.TrimEnd() + ']');
        Observer.Observe('trimstart_all', '[' + PadSrc.TrimStart(' xy,') + ']');
        Observer.Observe('trimend_all', '[' + PadSrc.TrimEnd(' xy,') + ']');
        asserterror Observer.Observe('padleft_neg', Src.PadLeft(-1));
        Observer.ObserveError('padleft_neg_err');
        asserterror Observer.Observe('remove_zero', Src.Remove(0));
        Observer.ObserveError('remove_zero_err');
        asserterror Observer.Observe('remove_count_big', Src.Remove(8, 99));
        Observer.ObserveError('remove_count_big_err');
        asserterror Observer.Observe('replace_empty_old', Src.Replace('', 'x'));
        Observer.ObserveError('replace_empty_old_err');
        asserterror Observer.Observe('substring_zero', Src.Substring(0));
        Observer.ObserveError('substring_zero_err');
        Observer.Observe('substring_count_big', Src.Substring(8, 99));
        Observer.Observe('substring_count_big_err', 'no error');
        Observer.Expect('padleft_zero', '[Hello, World]');
        Observer.Expect('padright_exact', '[Hello, World]');
        Observer.Expect('padleft_empty_src', '[---]');
        Observer.Expect('remove_all', '[]');
        Observer.Expect('remove_count_zero', '[Hello, World]');
        Observer.Expect('replace_delete', '[Heo, Word]');
        Observer.Expect('replace_empty_src', '[]');
        Observer.Expect('substring_last', '[d]');
        Observer.Expect('substring_count_zero', '[]');
        Observer.Expect('tolower_empty', '[]');
        Observer.Expect('toupper_empty', '[]');
        Observer.Expect('trim_empty', '[]');
        Observer.Expect('trimstart_noargs', '[xx, yy  ]');
        Observer.Expect('trimend_noargs', '[  xx, yy]');
        Observer.Expect('trimstart_all', '[]');
        Observer.Expect('trimend_all', '[]');
        Observer.Expect('padleft_neg_err|text', 'totalWidth (''-1'') must be a non-negative value. (Parameter ''totalWidth'')\Actual value was -1.');
        Observer.Expect('padleft_neg_err|code', 'ArgumentOutOfRange');
        Observer.Expect('remove_zero_err|text', 'StartIndex cannot be less than 1. (Parameter ''startIndex'')');
        Observer.Expect('remove_zero_err|code', 'ArgumentOutOfRange');
        Observer.Expect('remove_count_big_err|text', 'count (''99'') must be less than or equal to ''5''. (Parameter ''count'')\Actual value was 99.');
        Observer.Expect('remove_count_big_err|code', 'ArgumentOutOfRange');
        Observer.Expect('replace_empty_old_err|text', 'The value cannot be an empty string. (Parameter ''oldValue'')');
        Observer.Expect('replace_empty_old_err|code', 'Argument');
        Observer.Expect('substring_zero_err|text', 'startIndex (''-1'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -1.');
        Observer.Expect('substring_zero_err|code', 'ArgumentOutOfRange');
        Observer.Expect('substring_count_big', 'World');
        Observer.Expect('substring_count_big_err', 'no error');
        Observer.Verify();
    end;
}
