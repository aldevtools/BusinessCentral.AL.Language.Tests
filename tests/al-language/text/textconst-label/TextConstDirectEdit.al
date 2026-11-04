// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71966 "LT TextConst Direct Edit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        TcOne: TextConst ENU = '  Hello, World  ';
        TcTwo: TextConst ENU = '  Hello, World  ', DEU = '  Hallo, Welt  ';
        TcEmpty: TextConst ENU = '';

    [Test]
    procedure P193_PadLeft_PadRight_Remove()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
    begin
        Txt := TcOne;
        Observer.Observe('padleft_tc', '[' + TcOne.PadLeft(20) + ']');
        Observer.Observe('padleft_txt', '[' + Txt.PadLeft(20) + ']');
        Observer.Observe('padleft_char_tc', '[' + TcOne.PadLeft(20, '*') + ']');
        Observer.Observe('padleft_char_txt', '[' + Txt.PadLeft(20, '*') + ']');
        Observer.Observe('padleft_two_tc', '[' + TcTwo.PadLeft(20, '*') + ']');
        Observer.Observe('padleft_empty_tc', '[' + TcEmpty.PadLeft(3, '-') + ']');
        Observer.Observe('padright_tc', '[' + TcOne.PadRight(20) + ']');
        Observer.Observe('padright_txt', '[' + Txt.PadRight(20) + ']');
        Observer.Observe('padright_char_tc', '[' + TcOne.PadRight(20, '*') + ']');
        Observer.Observe('padright_char_txt', '[' + Txt.PadRight(20, '*') + ']');
        Observer.Observe('padright_two_tc', '[' + TcTwo.PadRight(20, '*') + ']');
        Observer.Observe('remove_tc', '[' + TcOne.Remove(3) + ']');
        Observer.Observe('remove_txt', '[' + Txt.Remove(3) + ']');
        Observer.Observe('remove_count_tc', '[' + TcOne.Remove(3, 5) + ']');
        Observer.Observe('remove_count_txt', '[' + Txt.Remove(3, 5) + ']');
        Observer.Observe('remove_two_tc', '[' + TcTwo.Remove(3, 5) + ']');
        Observer.Observe('remove_zero_count_tc', '[' + TcOne.Remove(3, 0) + ']');
        asserterror Observer.Observe('padleft_neg_tc', TcOne.PadLeft(-1));
        Observer.ObserveError('padleft_neg_tc_err');
        asserterror Observer.Observe('remove_zero_tc', TcOne.Remove(0));
        Observer.ObserveError('remove_zero_tc_err');
        asserterror Observer.Observe('remove_big_tc', TcOne.Remove(99));
        Observer.ObserveError('remove_big_tc_err');
        asserterror Observer.Observe('remove_big_txt', Txt.Remove(99));
        Observer.ObserveError('remove_big_txt_err');
        Observer.Expect('padleft_tc', '[      Hello, World  ]');
        Observer.Expect('padleft_txt', '[      Hello, World  ]');
        Observer.Expect('padleft_char_tc', '[****  Hello, World  ]');
        Observer.Expect('padleft_char_txt', '[****  Hello, World  ]');
        Observer.Expect('padleft_two_tc', '[****  Hello, World  ]');
        Observer.Expect('padleft_empty_tc', '[---]');
        Observer.Expect('padright_tc', '[  Hello, World      ]');
        Observer.Expect('padright_txt', '[  Hello, World      ]');
        Observer.Expect('padright_char_tc', '[  Hello, World  ****]');
        Observer.Expect('padright_char_txt', '[  Hello, World  ****]');
        Observer.Expect('padright_two_tc', '[  Hello, World  ****]');
        Observer.Expect('remove_tc', '[  ]');
        Observer.Expect('remove_txt', '[  ]');
        Observer.Expect('remove_count_tc', '[  , World  ]');
        Observer.Expect('remove_count_txt', '[  , World  ]');
        Observer.Expect('remove_two_tc', '[  , World  ]');
        Observer.Expect('remove_zero_count_tc', '[  Hello, World  ]');
        Observer.Expect('padleft_neg_tc_err|text', 'totalWidth (''-1'') must be a non-negative value. (Parameter ''totalWidth'')\Actual value was -1.');
        Observer.Expect('padleft_neg_tc_err|code', 'ArgumentOutOfRange');
        Observer.Expect('remove_zero_tc_err|text', 'StartIndex cannot be less than 1. (Parameter ''startIndex'')');
        Observer.Expect('remove_zero_tc_err|code', 'ArgumentOutOfRange');
        Observer.Expect('remove_big_tc_err|text', 'startIndex cannot be larger than length of string. (Parameter ''startIndex'')');
        Observer.Expect('remove_big_tc_err|code', 'ArgumentOutOfRange');
        Observer.Expect('remove_big_txt_err|text', 'startIndex cannot be larger than length of string. (Parameter ''startIndex'')');
        Observer.Expect('remove_big_txt_err|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure P193_Case_Trim()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
    begin
        Txt := TcOne;
        Observer.Observe('lower_tc', '[' + TcOne.ToLower() + ']');
        Observer.Observe('lower_txt', '[' + Txt.ToLower() + ']');
        Observer.Observe('lower_two_tc', '[' + TcTwo.ToLower() + ']');
        Observer.Observe('lower_empty_tc', '[' + TcEmpty.ToLower() + ']');
        Observer.Observe('upper_tc', '[' + TcOne.ToUpper() + ']');
        Observer.Observe('upper_txt', '[' + Txt.ToUpper() + ']');
        Observer.Observe('upper_two_tc', '[' + TcTwo.ToUpper() + ']');
        Observer.Observe('upper_empty_tc', '[' + TcEmpty.ToUpper() + ']');
        Observer.Observe('trim_tc', '[' + TcOne.Trim() + ']');
        Observer.Observe('trim_txt', '[' + Txt.Trim() + ']');
        Observer.Observe('trim_two_tc', '[' + TcTwo.Trim() + ']');
        Observer.Observe('trim_empty_tc', '[' + TcEmpty.Trim() + ']');
        Observer.Observe('trimend_tc', '[' + TcOne.TrimEnd() + ']');
        Observer.Observe('trimend_txt', '[' + Txt.TrimEnd() + ']');
        Observer.Observe('trimend_chars_tc', '[' + TcOne.TrimEnd(' d') + ']');
        Observer.Observe('trimend_chars_txt', '[' + Txt.TrimEnd(' d') + ']');
        Observer.Observe('trimend_chars_two_tc', '[' + TcTwo.TrimEnd(' t') + ']');
        Observer.Observe('trimend_empty_chars_tc', '[' + TcOne.TrimEnd('') + ']');
        Observer.Observe('trimstart_tc', '[' + TcOne.TrimStart() + ']');
        Observer.Observe('trimstart_txt', '[' + Txt.TrimStart() + ']');
        Observer.Observe('trimstart_chars_tc', '[' + TcOne.TrimStart(' H') + ']');
        Observer.Observe('trimstart_chars_txt', '[' + Txt.TrimStart(' H') + ']');
        Observer.Observe('trimstart_chars_two_tc', '[' + TcTwo.TrimStart(' H') + ']');
        Observer.Observe('trimstart_empty_chars_tc', '[' + TcOne.TrimStart('') + ']');
        Observer.Expect('lower_tc', '[  hello, world  ]');
        Observer.Expect('lower_txt', '[  hello, world  ]');
        Observer.Expect('lower_two_tc', '[  hello, world  ]');
        Observer.Expect('lower_empty_tc', '[]');
        Observer.Expect('upper_tc', '[  HELLO, WORLD  ]');
        Observer.Expect('upper_txt', '[  HELLO, WORLD  ]');
        Observer.Expect('upper_two_tc', '[  HELLO, WORLD  ]');
        Observer.Expect('upper_empty_tc', '[]');
        Observer.Expect('trim_tc', '[Hello, World]');
        Observer.Expect('trim_txt', '[Hello, World]');
        Observer.Expect('trim_two_tc', '[Hello, World]');
        Observer.Expect('trim_empty_tc', '[]');
        Observer.Expect('trimend_tc', '[  Hello, World]');
        Observer.Expect('trimend_txt', '[  Hello, World]');
        Observer.Expect('trimend_chars_tc', '[  Hello, Worl]');
        Observer.Expect('trimend_chars_txt', '[  Hello, Worl]');
        Observer.Expect('trimend_chars_two_tc', '[  Hello, World]');
        Observer.Expect('trimend_empty_chars_tc', '[  Hello, World]');
        Observer.Expect('trimstart_tc', '[Hello, World  ]');
        Observer.Expect('trimstart_txt', '[Hello, World  ]');
        Observer.Expect('trimstart_chars_tc', '[ello, World  ]');
        Observer.Expect('trimstart_chars_txt', '[ello, World  ]');
        Observer.Expect('trimstart_chars_two_tc', '[ello, World  ]');
        Observer.Expect('trimstart_empty_chars_tc', '[Hello, World  ]');
        Observer.Verify();
    end;
}
