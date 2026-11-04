// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 70040
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Text indexing t[i] on variables and literals, assignment through t[i], out-of-range and unicode; plus long text and chained method calls.
// BC versions: 29 (27 and 28 by CI)

codeunit 70040 "LT TxA Index 1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Index_Read_Variable()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
        C: Char;
    begin
        T := 'abcdef';
        Observer.Observe('i1', Format(T[1]));
        Observer.Observe('i3', Format(T[3]));
        Observer.Observe('i6', Format(T[6]));
        Observer.Observe('i1_int', Format(Integer_(T[1])));
        Observer.Observe('i1_code', Format(Integer_(T[6])));
        C := T[2];
        Observer.Observe('char_var', Format(C));
        Observer.Observe('compare_char', Format(T[1] = 'a'));
        Observer.Observe('compare_char_case', Format(T[1] = 'A'));
        asserterror Observer.Observe('i0', Format(T[0]));
        Observer.ObserveError('i0_err');
        Observer.Observe('i7', Format(T[7]));
        Observer.Observe('i7_err', 'no error');
        asserterror Observer.Observe('ineg', Format(T[-1]));
        Observer.ObserveError('ineg_err');
        Observer.Observe('i100', Format(T[100]));
        Observer.Observe('i100_err', 'no error');
        Observer.Observe('empty_i1', Format(E[1]));
        Observer.Observe('empty_i1_err', 'no error');
        asserterror Observer.Observe('empty_i0', Format(E[0]));
        Observer.ObserveError('empty_i0_err');
        Observer.Expect('i1', 'a');
        Observer.Expect('i3', 'c');
        Observer.Expect('i6', 'f');
        Observer.Expect('i1_int', '97');
        Observer.Expect('i1_code', '102');
        Observer.Expect('char_var', 'b');
        Observer.Expect('compare_char', 'Yes');
        Observer.Expect('compare_char_case', 'No');
        Observer.Expect('i0_err|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('i0_err|code', 'OutsidePermittedRange');
        Observer.Expect('i7', '\u0000');
        Observer.Expect('i7_err', 'no error');
        Observer.Expect('ineg_err|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('ineg_err|code', 'OutsidePermittedRange');
        Observer.Expect('i100', '\u0000');
        Observer.Expect('i100_err', 'no error');
        Observer.Expect('empty_i1', '\u0000');
        Observer.Expect('empty_i1_err', 'no error');
        Observer.Expect('empty_i0_err|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('empty_i0_err|code', 'OutsidePermittedRange');
        Observer.Verify();
    end;

    local procedure Uml(): Text
    begin
        exit('ä');
    end;

    local procedure Integer_(C: Char): Integer
    begin
        exit(C);
    end;

    [Test]
    procedure Index_Read_Literal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('lit_i1', Format('hello'[1]));
        Observer.Observe('lit_i5', Format('hello'[5]));
        Observer.Observe('lit_code', Format(Integer_('hello'[2])));
        asserterror Observer.Observe('lit_i6', Format('hello'[6]));
        Observer.ObserveError('lit_i6_err');
        asserterror Observer.Observe('lit_i0', Format('hello'[0]));
        Observer.ObserveError('lit_i0_err');
        asserterror Observer.Observe('lit_empty', Format(''[1]));
        Observer.ObserveError('lit_empty_err');
        Observer.Observe('lit_uml', Format(Integer_(Uml()[1])));
        Observer.Expect('lit_i1', 'h');
        Observer.Expect('lit_i5', 'o');
        Observer.Expect('lit_code', '101');
        Observer.Expect('lit_i6_err|text', 'Index was outside the bounds of the array.');
        Observer.Expect('lit_i6_err|code', 'AL:IndexOutOfRange');
        Observer.Expect('lit_i0_err|text', 'Index was outside the bounds of the array.');
        Observer.Expect('lit_i0_err|code', 'AL:IndexOutOfRange');
        Observer.Expect('lit_empty_err|text', 'Index was outside the bounds of the array.');
        Observer.Expect('lit_empty_err|code', 'AL:IndexOutOfRange');
        Observer.Expect('lit_uml', '228');
        Observer.Verify();
    end;

    [Test]
    procedure Index_Write_Variable()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
        C: Char;
    begin
        T := 'abcdef';
        T[1] := 'X';
        Observer.Observe('w1', T);
        C := 'Y';
        T[6] := C;
        Observer.Observe('w6', T);
        T[3] := 65;
        Observer.Observe('w_int', T);
        Observer.Observe('w_len', Format(StrLen(T)));
        T[7] := 'Z';
        Observer.Observe('w7_err', 'no error');
        Observer.Observe('w7_after', T);
        asserterror T[0] := 'Z';
        Observer.ObserveError('w0_err');
        E[1] := 'Z';
        Observer.Observe('wempty_err', 'no error');
        Observer.Observe('wempty_after', Format(StrLen(E)));
        Observer.Expect('w1', 'Xbcdef');
        Observer.Expect('w6', 'XbcdeY');
        Observer.Expect('w_int', 'XbAdeY');
        Observer.Expect('w_len', '6');
        Observer.Expect('w7_err', 'no error');
        Observer.Expect('w7_after', 'XbAdeYZ');
        Observer.Expect('w0_err|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 7.');
        Observer.Expect('w0_err|code', 'OutsidePermittedRange');
        Observer.Expect('wempty_err', 'no error');
        Observer.Expect('wempty_after', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Index_Write_TextWithLength()
    var
        Observer: Codeunit "Probe Observer";
        T: Text[5];
        U: Text[10];
    begin
        T := 'abc';
        T[2] := 'X';
        Observer.Observe('tl_w2', T);
        T[4] := 'Z';
        Observer.Observe('tl_w4_err', 'no error');
        asserterror T[6] := 'Z';
        Observer.ObserveError('tl_w6_err');
        Observer.Observe('tl_after', T);
        Observer.Observe('tl_len', Format(StrLen(T)));
        U[1] := 'a';
        Observer.Observe('empty_assign_len', Format(StrLen(U)));
        Observer.Expect('tl_w2', 'aXc');
        Observer.Expect('tl_w4_err', 'no error');
        Observer.Expect('tl_w6_err|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 6. The permitted range is: from 1 to 4.');
        Observer.Expect('tl_w6_err|code', 'OutsidePermittedRange');
        Observer.Expect('tl_after', 'aXcZ');
        Observer.Expect('tl_len', '4');
        Observer.Expect('empty_assign_len', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Index_Unicode()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := 'äßÖ€日';
        Observer.Observe('u_len', Format(StrLen(T)));
        Observer.Observe('u1', Format(Integer_(T[1])));
        Observer.Observe('u2', Format(Integer_(T[2])));
        Observer.Observe('u3', Format(Integer_(T[3])));
        Observer.Observe('u4', Format(Integer_(T[4])));
        Observer.Observe('u5', Format(Integer_(T[5])));
        T := '😀a';
        Observer.Observe('emoji_len', Format(StrLen(T)));
        Observer.Observe('emoji_1', Format(Integer_(T[1])));
        Observer.Observe('emoji_2', Format(Integer_(T[2])));
        Observer.Observe('emoji_3', Format(Integer_(T[3])));
        Observer.Observe('emoji_upper_len', Format(StrLen(T.ToUpper())));
        Observer.Observe('emoji_substring', Format(StrLen(T.Substring(1, 1))));
        Observer.Observe('emoji_indexof_a', Format(T.IndexOf('a')));
        Observer.Observe('emoji_pad', Format(StrLen(T.PadLeft(5, 'x'))));
        Observer.Observe('emoji_remove', Format(StrLen(T.Remove(1, 1))));
        Observer.Expect('u_len', '5');
        Observer.Expect('u1', '228');
        Observer.Expect('u2', '223');
        Observer.Expect('u3', '214');
        Observer.Expect('u4', '8364');
        Observer.Expect('u5', '26085');
        Observer.Expect('emoji_len', '3');
        Observer.Expect('emoji_1', '55357');
        Observer.Expect('emoji_2', '56832');
        Observer.Expect('emoji_3', '97');
        Observer.Expect('emoji_upper_len', '3');
        Observer.Expect('emoji_substring', '1');
        Observer.Expect('emoji_indexof_a', '3');
        Observer.Expect('emoji_pad', '5');
        Observer.Expect('emoji_remove', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Chaining_And_LongText()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        I: Integer;
    begin
        T := '  Hello, World  ';
        Observer.Observe('chain1', T.Trim().ToUpper().Replace('L', '_'));
        Observer.Observe('chain2', T.Trim().Substring(1, 5).PadRight(8, '.'));
        Observer.Observe('chain3', Format(T.Trim().Split(',').Count()));
        Observer.Observe('chain4', Format(T.Trim().ToLower().Contains('world')));
        Observer.Observe('chain5', T.TrimStart().ToUpper());
        for I := 1 to 3000 do
            T += 'ab';
        Observer.Observe('long_len', Format(StrLen(T)));
        Observer.Observe('long_indexof_last', Format(T.LastIndexOf('ab')));
        Observer.Observe('long_indexof_first', Format(T.IndexOf('ab')));
        Observer.Observe('long_replace_len', Format(StrLen(T.Replace('ab', 'abc'))));
        Observer.Observe('long_contains', Format(T.Contains('baba')));
        Observer.Observe('long_split_count', Format(T.Split('ab').Count()));
        Observer.Observe('long_substring', T.Substring(StrLen(T) - 3));
        Observer.Observe('long_endswith', Format(T.EndsWith('abab')));
        Observer.Expect('chain1', 'HE__O, WOR_D');
        Observer.Expect('chain2', 'Hello...');
        Observer.Expect('chain3', '2');
        Observer.Expect('chain4', 'Yes');
        Observer.Expect('chain5', 'HELLO, WORLD  ');
        Observer.Expect('long_len', '6016');
        Observer.Expect('long_indexof_last', '6015');
        Observer.Expect('long_indexof_first', '17');
        Observer.Expect('long_replace_len', '9016');
        Observer.Expect('long_contains', 'Yes');
        Observer.Expect('long_split_count', '3001');
        Observer.Expect('long_substring', 'abab');
        Observer.Expect('long_endswith', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Methods_On_Constants_And_Labels()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Label 'Hello World';
        TxtP: Label 'Value %1 of %2', Comment = '%1=a,%2=b';
    begin
        Observer.Observe('label_contains', Format(Txt.Contains('World')));
        Observer.Observe('label_upper', Txt.ToUpper());
        Observer.Observe('label_index', Format(Txt.IndexOf('o')));
        Observer.Observe('label_split', Format(Txt.Split(' ').Count()));
        Observer.Observe('label_substring', Txt.Substring(7));
        Observer.Observe('label_replace', Txt.Replace('World', 'AL'));
        Observer.Observe('label_pad', Txt.PadLeft(13, '*'));
        Observer.Observe('label_trimend', Txt.TrimEnd('d'));
        Observer.Observe('label_param', TxtP.Replace('%1', 'X'));
        Observer.Observe('label_startswith', Format(Txt.StartsWith('Hello')));
        Observer.Observe('label_endswith', Format(Txt.EndsWith('World')));
        Observer.Observe('label_remove', Txt.Remove(6));
        asserterror Observer.Observe('label_oob', Txt.Substring(20));
        Observer.ObserveError('label_oob_err');
        Observer.Expect('label_contains', 'Yes');
        Observer.Expect('label_upper', 'HELLO WORLD');
        Observer.Expect('label_index', '5');
        Observer.Expect('label_split', '2');
        Observer.Expect('label_substring', 'World');
        Observer.Expect('label_replace', 'Hello AL');
        Observer.Expect('label_pad', '**Hello World');
        Observer.Expect('label_trimend', 'Hello Worl');
        Observer.Expect('label_param', 'Value X of %2');
        Observer.Expect('label_startswith', 'Yes');
        Observer.Expect('label_endswith', 'Yes');
        Observer.Expect('label_remove', 'Hello');
        Observer.Expect('label_oob_err|text', 'startIndex cannot be larger than length of string. (Parameter ''startIndex'')');
        Observer.Expect('label_oob_err|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    // Corpus issue 672 (odd AL behavior leads, part G), item 52: writing a character by index into a Code variable at its
    // length + 1 and further (the Text forms are in Index_Write_Variable and Index_Write_TextWithLength above).
    [Test]
    procedure LT_BU_Index_Write_Code()
    var
        Observer: Codeunit "Probe Observer";
        C: Code[10];
        C3: Code[3];
    begin
        C := 'abc';
        ClearLastError();
        if TrySetCodeChar(C, 4, 'd') then
            Observer.Observe('code len+1', C + '|' + Format(StrLen(C)))
        else
            Observer.Observe('code len+1', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        C := 'abc';
        ClearLastError();
        if TrySetCodeChar(C, 6, 'x') then
            Observer.Observe('code len+3', C + '|' + Format(StrLen(C)))
        else
            Observer.Observe('code len+3', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        C3 := 'abc';
        ClearLastError();
        if TrySetCode3Char(C3, 4, 'd') then
            Observer.Observe('code3 past declared', C3)
        else
            Observer.Observe('code3 past declared', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        C := 'abc';
        ClearLastError();
        if TrySetCodeChar(C, 2, ' ') then
            Observer.Observe('code blank inside', '[' + C + ']|' + Format(StrLen(C)))
        else
            Observer.Observe('code blank inside', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        C := 'abc';
        ClearLastError();
        if TrySetCodeChar(C, 3, ' ') then
            Observer.Observe('code blank last', '[' + C + ']|' + Format(StrLen(C)))
        else
            Observer.Observe('code blank last', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('code len+1', 'ABCD|4');
        Observer.Expect('code len+3', 'error:The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 6. The permitted range is: from 1 to 3.|OutsidePermittedRange');
        Observer.Expect('code3 past declared', 'error:The length of the string is 4, but it must be less than or equal to 3 characters. Value: ABCd|StringLengthExceeded');
        Observer.Expect('code blank inside', '[A C]|3');
        Observer.Expect('code blank last', '[AB]|2');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetCodeChar(var C: Code[10]; Pos: Integer; Ch: Char)
    begin
        C[Pos] := Ch;
    end;

    [TryFunction]
    local procedure TrySetCode3Char(var C: Code[3]; Pos: Integer; Ch: Char)
    begin
        C[Pos] := Ch;
    end;

    // Corpus issue 672, item 60: Text is UTF-16 like .NET strings. CopyStr that splits a surrogate pair, and case
    // conversion of a letter outside the Basic Multilingual Plane (U+10428 DESERET SMALL LETTER LONG I, upper U+10400).
    [Test]
    procedure LT_BU_Index_SurrogatePairs()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        Part: Text;
        Code1: Integer;
    begin
        T := '😀a';
        Part := CopyStr(T, 1, 1);
        Code1 := Part[1];
        Observer.Observe('copystr first half', Format(StrLen(Part)) + '|' + Format(Code1));
        Part := CopyStr(T, 2);
        Code1 := Part[1];
        Observer.Observe('copystr second half', Format(StrLen(Part)) + '|' + Format(Code1));
        Observer.Observe('copystr whole pair', Format(CopyStr(T, 1, 2) = '😀'));
        T := '𐐨';
        Observer.Observe('deseret len', Format(StrLen(T)));
        Observer.Observe('uppercase deseret', Format(UpperCase(T) = '𐐀'));
        Observer.Observe('toupper deseret', Format(T.ToUpper() = '𐐀'));
        Observer.Observe('lowercase deseret', Format(LowerCase('𐐀') = '𐐨'));
        Observer.Observe('strpos emoji', Format(StrPos('x😀a', 'a')));
        Observer.Observe('delstr half pair', Format(StrLen(DelStr('😀a', 1, 1))));
        Observer.Expect('copystr first half', '1|55357');
        Observer.Expect('copystr second half', '2|56832');
        Observer.Expect('copystr whole pair', 'Yes');
        Observer.Expect('deseret len', '2');
        Observer.Expect('uppercase deseret', 'Yes');
        Observer.Expect('toupper deseret', 'Yes');
        Observer.Expect('lowercase deseret', 'Yes');
        Observer.Expect('strpos emoji', '4');
        Observer.Expect('delstr half pair', '2');
        Observer.Verify();
    end;
}
