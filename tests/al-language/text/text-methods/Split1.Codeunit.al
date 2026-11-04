// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 70030
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Text.Split overloads (none, text, char, list of text, list of char, several separators) and edge cases.
// BC versions: 29 (27 and 28 by CI)

codeunit 70030 "LT TxA Split 1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Join(Parts: List of [Text]): Text
    var
        P: Text;
        Result: Text;
    begin
        foreach P in Parts do
            Result += '[' + P + ']';
        exit(Format(Parts.Count()) + ':' + Result);
    end;

    [Test]
    procedure Split_NoArgs()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
    begin
        T := 'a b  c';
        Observer.Observe('none_spaces', Join(T.Split()));
        Observer.Observe('none_empty', Join(E.Split()));
        Observer.Observe('none_lit', Join('x,y z'.Split()));
        Observer.Observe('none_single', Join('abc'.Split()));
        Observer.Observe('none_leading', Join(' a b'.Split()));
        Observer.Observe('none_trailing', Join('a b '.Split()));
        Observer.Observe('none_only_space', Join(S(' ').Split()));
        Observer.Observe('none_two_spaces', Join('  '.Split()));
        Observer.Observe('none_tab', Join(('a' + Format(Tab()) + 'b').Split()));
        Observer.Expect('none_spaces', '4:[a][b][][c]');
        Observer.Expect('none_empty', '1:[]');
        Observer.Expect('none_lit', '2:[x,y][z]');
        Observer.Expect('none_single', '1:[abc]');
        Observer.Expect('none_leading', '3:[][a][b]');
        Observer.Expect('none_trailing', '3:[a][b][]');
        Observer.Expect('none_only_space', '2:[][]');
        Observer.Expect('none_two_spaces', '3:[][][]');
        Observer.Expect('none_tab', '2:[a][b]');
        Observer.Verify();
    end;

    local procedure S(Value: Text): Text
    begin
        exit(Value);
    end;

    local procedure Tab(): Text[1]
    var
        C: Text[1];
    begin
        C[1] := 9;
        exit(C);
    end;

    [Test]
    procedure Split_NoArgs_Whitespace()
    var
        Observer: Codeunit "Probe Observer";
        Tb: Text;
        Lf: Text[1];
        Cr: Text[1];
    begin
        Tb := Tab();
        Lf[1] := 10;
        Cr[1] := 13;
        Observer.Observe('tab', Join((('a' + Tb + 'b')).Split()));
        Observer.Observe('lf', Join(('a' + Lf + 'b').Split()));
        Observer.Observe('crlf', Join(('a' + Cr + Lf + 'b').Split()));
        Observer.Observe('mixed', Join(('a ' + Tb + Lf + 'b').Split()));
        Observer.Expect('tab', '2:[a][b]');
        Observer.Expect('lf', '2:[a][b]');
        Observer.Expect('crlf', '3:[a][][b]');
        Observer.Expect('mixed', '4:[a][][][b]');
        Observer.Verify();
    end;

    [Test]
    procedure Split_SingleText()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        E: Text;
    begin
        T := 'a,b,c';
        Observer.Observe('comma', Join(T.Split(',')));
        Observer.Observe('adjacent', Join('a,,b'.Split(',')));
        Observer.Observe('triple_adjacent', Join('a,,,b'.Split(',')));
        Observer.Observe('leading', Join(',a,b'.Split(',')));
        Observer.Observe('trailing', Join('a,b,'.Split(',')));
        Observer.Observe('only_sep', Join(S(',').Split(',')));
        Observer.Observe('two_sep', Join(',,'.Split(',')));
        Observer.Observe('empty_text', Join(E.Split(',')));
        Observer.Observe('lit_empty_text', Join(''.Split(',')));
        Observer.Observe('no_sep_present', Join('abc'.Split(',')));
        Observer.Observe('multichar_sep', Join('a--b--c'.Split('--')));
        Observer.Observe('multichar_sep_partial', Join('a-b--c'.Split('--')));
        Observer.Observe('multichar_overlap', Join('a---b'.Split('--')));
        Observer.Observe('multichar_overlap4', Join('a----b'.Split('--')));
        Observer.Observe('case', Join('aXbxc'.Split('x')));
        Observer.Observe('empty_separator', Join('abc'.Split('')));
        Observer.Observe('empty_separator_empty_text', Join(''.Split('')));
        Observer.Observe('space_sep', Join('a b  c'.Split(' ')));
        Observer.Observe('sep_is_whole', Join('abc'.Split('abc')));
        Observer.Observe('sep_longer', Join('abc'.Split('abcd')));
        Observer.Observe('uml', Join('äßö'.Split('ß')));
        Observer.Expect('comma', '3:[a][b][c]');
        Observer.Expect('adjacent', '3:[a][][b]');
        Observer.Expect('triple_adjacent', '4:[a][][][b]');
        Observer.Expect('leading', '3:[][a][b]');
        Observer.Expect('trailing', '3:[a][b][]');
        Observer.Expect('only_sep', '2:[][]');
        Observer.Expect('two_sep', '3:[][][]');
        Observer.Expect('empty_text', '1:[]');
        Observer.Expect('lit_empty_text', '1:[]');
        Observer.Expect('no_sep_present', '1:[abc]');
        Observer.Expect('multichar_sep', '3:[a][b][c]');
        Observer.Expect('multichar_sep_partial', '2:[a-b][c]');
        Observer.Expect('multichar_overlap', '2:[a][-b]');
        Observer.Expect('multichar_overlap4', '3:[a][][b]');
        Observer.Expect('case', '2:[aXb][c]');
        Observer.Expect('empty_separator', '1:[abc]');
        Observer.Expect('empty_separator_empty_text', '1:[]');
        Observer.Expect('space_sep', '4:[a][b][][c]');
        Observer.Expect('sep_is_whole', '2:[][]');
        Observer.Expect('sep_longer', '1:[abc]');
        Observer.Expect('uml', '2:[ä][ö]');
        Observer.Verify();
    end;

    [Test]
    procedure Split_SingleChar()
    var
        Observer: Codeunit "Probe Observer";
        C: Char;
        T: Text;
    begin
        C := ',';
        T := 'a,b,,c,';
        Observer.Observe('char_var', Join(T.Split(C)));
        C := 'x';
        Observer.Observe('char_var_x', Join('axbXc'.Split(C)));
        C := 'z';
        Observer.Observe('char_var_missing', Join('abc'.Split(C)));
        Observer.Observe('char_var_empty', Join(''.Split(C)));
        C := ' ';
        Observer.Observe('char_space', Join('a b  c '.Split(C)));
        Observer.Observe('char_literal', Join('a;b;c'.Split(';')));
        Observer.Expect('char_var', '5:[a][b][][c][]');
        Observer.Expect('char_var_x', '2:[a][bXc]');
        Observer.Expect('char_var_missing', '1:[abc]');
        Observer.Expect('char_var_empty', '1:[]');
        Observer.Expect('char_space', '5:[a][b][][c][]');
        Observer.Expect('char_literal', '3:[a][b][c]');
        Observer.Verify();
    end;

    [Test]
    procedure Split_ListOfText()
    var
        Observer: Codeunit "Probe Observer";
        Seps: List of [Text];
        NoSeps: List of [Text];
    begin
        Seps.Add(',');
        Seps.Add(';');
        Observer.Observe('two_seps', Join('a,b;c'.Split(Seps)));
        Observer.Observe('two_seps_adjacent', Join('a,;b'.Split(Seps)));
        Observer.Observe('two_seps_leading', Join(';a,b'.Split(Seps)));
        Observer.Observe('two_seps_trailing', Join('a;b,'.Split(Seps)));
        Observer.Observe('two_seps_empty_text', Join(''.Split(Seps)));
        Observer.Observe('two_seps_none_present', Join('abc'.Split(Seps)));
        Observer.Observe('no_seps_list', Join('a b'.Split(NoSeps)));
        Observer.Observe('no_seps_list_empty_text', Join(''.Split(NoSeps)));
        Clear(Seps);
        Seps.Add('ab');
        Seps.Add('a');
        Observer.Observe('overlap_order_ab_a', Join('xabyaz'.Split(Seps)));
        Clear(Seps);
        Seps.Add('a');
        Seps.Add('ab');
        Observer.Observe('overlap_order_a_ab', Join('xabyaz'.Split(Seps)));
        Clear(Seps);
        Seps.Add('');
        Observer.Observe('seps_with_empty', Join('abc'.Split(Seps)));
        Clear(Seps);
        Seps.Add('');
        Seps.Add(',');
        Observer.Observe('seps_with_empty_and_comma', Join('a,b'.Split(Seps)));
        Clear(Seps);
        Seps.Add(',');
        Seps.Add(',');
        Observer.Observe('seps_duplicates', Join('a,b'.Split(Seps)));
        Clear(Seps);
        Seps.Add('--');
        Seps.Add('-');
        Observer.Observe('seps_dash', Join('a---b-c--d'.Split(Seps)));
        Observer.Expect('two_seps', '3:[a][b][c]');
        Observer.Expect('two_seps_adjacent', '3:[a][][b]');
        Observer.Expect('two_seps_leading', '3:[][a][b]');
        Observer.Expect('two_seps_trailing', '3:[a][b][]');
        Observer.Expect('two_seps_empty_text', '1:[]');
        Observer.Expect('two_seps_none_present', '1:[abc]');
        Observer.Expect('no_seps_list', '2:[a][b]');
        Observer.Expect('no_seps_list_empty_text', '1:[]');
        Observer.Expect('overlap_order_ab_a', '3:[x][y][z]');
        Observer.Expect('overlap_order_a_ab', '3:[x][by][z]');
        Observer.Expect('seps_with_empty', '1:[abc]');
        Observer.Expect('seps_with_empty_and_comma', '2:[a][b]');
        Observer.Expect('seps_duplicates', '2:[a][b]');
        Observer.Expect('seps_dash', '5:[a][][b][c][d]');
        Observer.Verify();
    end;

    [Test]
    procedure Split_ListOfChar()
    var
        Observer: Codeunit "Probe Observer";
        Seps: List of [Char];
        NoSeps: List of [Char];
        C: Char;
    begin
        C := ',';
        Seps.Add(C);
        C := ';';
        Seps.Add(C);
        Observer.Observe('two_chars', Join('a,b;c'.Split(Seps)));
        Observer.Observe('two_chars_adjacent', Join('a,;b'.Split(Seps)));
        Observer.Observe('two_chars_leading', Join(';a,b'.Split(Seps)));
        Observer.Observe('two_chars_trailing', Join('a;b,'.Split(Seps)));
        Observer.Observe('two_chars_empty_text', Join(''.Split(Seps)));
        Observer.Observe('two_chars_none_present', Join('abc'.Split(Seps)));
        Observer.Observe('no_chars_list', Join('a b'.Split(NoSeps)));
        Observer.Observe('no_chars_list_empty_text', Join(''.Split(NoSeps)));
        Observer.Expect('two_chars', '3:[a][b][c]');
        Observer.Expect('two_chars_adjacent', '3:[a][][b]');
        Observer.Expect('two_chars_leading', '3:[][a][b]');
        Observer.Expect('two_chars_trailing', '3:[a][b][]');
        Observer.Expect('two_chars_empty_text', '1:[]');
        Observer.Expect('two_chars_none_present', '1:[abc]');
        Observer.Expect('no_chars_list', '2:[a][b]');
        Observer.Expect('no_chars_list_empty_text', '1:[]');
        Observer.Verify();
    end;

    [Test]
    procedure Split_Variadic()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('two_texts', Join('a,b;c'.Split(',', ';')));
        Observer.Observe('three_texts', Join('a,b;c|d'.Split(',', ';', '|')));
        Observer.Observe('two_texts_adjacent', Join('a,;b'.Split(',', ';')));
        Observer.Observe('two_texts_multi', Join('a--b-c'.Split('--', '-')));
        Observer.Observe('two_texts_multi_rev', Join('a--b-c'.Split('-', '--')));
        Observer.Observe('dup_texts', Join('a,b'.Split(',', ',')));
        Observer.Observe('with_empty_text', Join('a,b'.Split(',', '')));
        Observer.Observe('empty_src', Join(''.Split(',', ';')));
        Observer.Expect('two_texts', '3:[a][b][c]');
        Observer.Expect('three_texts', '4:[a][b][c][d]');
        Observer.Expect('two_texts_adjacent', '3:[a][][b]');
        Observer.Expect('two_texts_multi', '3:[a][b][c]');
        Observer.Expect('two_texts_multi_rev', '4:[a][][b][c]');
        Observer.Expect('dup_texts', '2:[a][b]');
        Observer.Expect('with_empty_text', '2:[a][b]');
        Observer.Expect('empty_src', '1:[]');
        Observer.Verify();
    end;

    [Test]
    procedure Split_ResultList_Facts()
    var
        Observer: Codeunit "Probe Observer";
        Parts: List of [Text];
        T: Text;
    begin
        T := 'one,two,three';
        Parts := T.Split(',');
        Observer.Observe('count', Format(Parts.Count()));
        Observer.Observe('first', Parts.Get(1));
        Observer.Observe('last', Parts.Get(3));
        Observer.Observe('contains_two', Format(Parts.Contains('two')));
        Parts := ''.Split(',');
        Observer.Observe('empty_count', Format(Parts.Count()));
        Observer.Observe('empty_first_len', Format(StrLen(Parts.Get(1))));
        Parts := S(',').Split(',');
        Observer.Observe('sep_only_count', Format(Parts.Count()));
        Parts := S('a').Split(',');
        Observer.Observe('single_count', Format(Parts.Count()));
        Observer.Observe('long_split_count', Format(Padded(1000).Split(',').Count()));
        Observer.Expect('count', '3');
        Observer.Expect('first', 'one');
        Observer.Expect('last', 'three');
        Observer.Expect('contains_two', 'Yes');
        Observer.Expect('empty_count', '1');
        Observer.Expect('empty_first_len', '0');
        Observer.Expect('sep_only_count', '2');
        Observer.Expect('single_count', '1');
        Observer.Expect('long_split_count', '1001');
        Observer.Verify();
    end;

    local procedure Padded(N: Integer): Text
    var
        I: Integer;
        Result: Text;
    begin
        for I := 1 to N do
            Result += 'x,';
        exit(Result);
    end;

    // Corpus issue 672 (odd AL behavior leads, part G), item 61: Text.Split with a Char returned by a procedure of another app
    // (codeunit DotNet_Array of the Base Application, GetValueAsChar). Reported as a publish failure (generated C# error CS0030).
    [Test]
    procedure LT_BU_Split_CharFromOtherApp()
    var
        Observer: Codeunit "Probe Observer";
        Arr: Codeunit DotNet_Array;
        Parts: List of [Text];
    begin
        Arr.CharArray(1);
        Arr.SetCharValue(';', 0);
        Parts := 'Alpha;Bravo;Charlie'.Split(Arr.GetValueAsChar(0));
        Observer.Observe('char from other app', Join(Parts));
        Parts := 'Alpha::Bravo::Charlie'.Split('::');
        Observer.Observe('two char separator', Join(Parts));
        Observer.Expect('char from other app', '3:[Alpha][Bravo][Charlie]');
        Observer.Expect('two char separator', '3:[Alpha][Bravo][Charlie]');
        Observer.Verify();
    end;
}
