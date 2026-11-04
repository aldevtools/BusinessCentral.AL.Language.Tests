// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P89 Helper (74627)
// Probe: written against BC 29 (observation only; facts are measured later). P89
// BC versions: 29

codeunit 74637 "LT P89 TextConst Methods"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Src: TextConst ENU = 'Hello, World', DEU = 'Hallo, Welt';
        PadSrc: TextConst ENU = '  xx, yy  ';
        SplitSrc: TextConst ENU = 'a,b;c,,d';

    [TryFunction]
    local procedure TrySplitEmptyF(Value: Text; var R: Text)
    var
        Helper: Codeunit "LT P89 Helper";
    begin
        R := Helper.Join(Value.Split(''));
    end;

    local procedure TrySplitEmpty(Value: Text): Text
    var
        R: Text;
    begin
        if TrySplitEmptyF(Value, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Search_1()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := Src;
        Observer.Observe('same_as_text', Format(T = Src));
        Observer.Observe('contains_tc', Format(Src.Contains('World')));
        Observer.Observe('contains_t', Format(T.Contains('World')));
        Observer.Observe('contains_case_tc', Format(Src.Contains('world')));
        Observer.Observe('contains_case_t', Format(T.Contains('world')));
        Observer.Observe('contains_empty_tc', Format(Src.Contains('')));
        Observer.Observe('contains_empty_t', Format(T.Contains('')));
        Observer.Observe('starts_tc', Format(Src.StartsWith('Hello')));
        Observer.Observe('starts_t', Format(T.StartsWith('Hello')));
        Observer.Observe('starts_case_tc', Format(Src.StartsWith('hello')));
        Observer.Observe('starts_case_t', Format(T.StartsWith('hello')));
        Observer.Observe('ends_tc', Format(Src.EndsWith('World')));
        Observer.Observe('ends_t', Format(T.EndsWith('World')));
        Observer.Observe('ends_empty_tc', Format(Src.EndsWith('')));
        Observer.Observe('ends_empty_t', Format(T.EndsWith('')));
        Observer.Observe('indexof_tc', Format(Src.IndexOf('o')));
        Observer.Observe('indexof_t', Format(T.IndexOf('o')));
        Observer.Observe('indexof_start_tc', Format(Src.IndexOf('o', 6)));
        Observer.Observe('indexof_start_t', Format(T.IndexOf('o', 6)));
        Observer.Observe('indexof_miss_tc', Format(Src.IndexOf('zz')));
        Observer.Observe('indexof_miss_t', Format(T.IndexOf('zz')));
        Observer.Observe('indexof_empty_tc', Format(Src.IndexOf('')));
        Observer.Observe('indexof_empty_t', Format(T.IndexOf('')));
        Observer.Observe('lastindexof_tc', Format(Src.LastIndexOf('o')));
        Observer.Observe('lastindexof_t', Format(T.LastIndexOf('o')));
        Observer.Expect('same_as_text', 'Yes');
        Observer.Expect('contains_tc', 'Yes');
        Observer.Expect('contains_t', 'Yes');
        Observer.Expect('contains_case_tc', 'No');
        Observer.Expect('contains_case_t', 'No');
        Observer.Expect('contains_empty_tc', 'Yes');
        Observer.Expect('contains_empty_t', 'Yes');
        Observer.Expect('starts_tc', 'Yes');
        Observer.Expect('starts_t', 'Yes');
        Observer.Expect('starts_case_tc', 'No');
        Observer.Expect('starts_case_t', 'No');
        Observer.Expect('ends_tc', 'Yes');
        Observer.Expect('ends_t', 'Yes');
        Observer.Expect('ends_empty_tc', 'Yes');
        Observer.Expect('ends_empty_t', 'Yes');
        Observer.Expect('indexof_tc', '5');
        Observer.Expect('indexof_t', '5');
        Observer.Expect('indexof_start_tc', '9');
        Observer.Expect('indexof_start_t', '9');
        Observer.Expect('indexof_miss_tc', '0');
        Observer.Expect('indexof_miss_t', '0');
        Observer.Expect('indexof_empty_tc', '1');
        Observer.Expect('indexof_empty_t', '1');
        Observer.Expect('lastindexof_tc', '9');
        Observer.Expect('lastindexof_t', '9');
        Observer.Verify();
    end;

    [Test]
    procedure Search_2()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := Src;
        Observer.Observe('same_as_text', Format(T = Src));
        Observer.Observe('lastindexof_start_tc', Format(Src.LastIndexOf('o', 5)));
        Observer.Observe('lastindexof_start_t', Format(T.LastIndexOf('o', 5)));
        Observer.Observe('lastindexof_miss_tc', Format(Src.LastIndexOf('zz')));
        Observer.Observe('lastindexof_miss_t', Format(T.LastIndexOf('zz')));
        Observer.Expect('same_as_text', 'Yes');
        Observer.Expect('lastindexof_start_tc', '5');
        Observer.Expect('lastindexof_start_t', '5');
        Observer.Expect('lastindexof_miss_tc', '0');
        Observer.Expect('lastindexof_miss_t', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Edit_1()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := Src;
        Observer.Observe('same_as_text', Format(T = Src));
        Observer.Observe('padleft_tc', Format(Src.PadLeft(15)));
        Observer.Observe('padleft_t', Format(T.PadLeft(15)));
        Observer.Observe('padleft_chr_tc', Format(Src.PadLeft(15, '*')));
        Observer.Observe('padleft_chr_t', Format(T.PadLeft(15, '*')));
        Observer.Observe('padleft_short_tc', Format(Src.PadLeft(3)));
        Observer.Observe('padleft_short_t', Format(T.PadLeft(3)));
        Observer.Observe('padright_tc', Format(Src.PadRight(15)));
        Observer.Observe('padright_t', Format(T.PadRight(15)));
        Observer.Observe('padright_chr_tc', Format(Src.PadRight(15, '*')));
        Observer.Observe('padright_chr_t', Format(T.PadRight(15, '*')));
        Observer.Observe('remove_tc', Format(Src.Remove(6)));
        Observer.Observe('remove_t', Format(T.Remove(6)));
        Observer.Observe('remove_count_tc', Format(Src.Remove(6, 3)));
        Observer.Observe('remove_count_t', Format(T.Remove(6, 3)));
        Observer.Observe('replace_tc', Format(Src.Replace('l', 'L')));
        Observer.Observe('replace_t', Format(T.Replace('l', 'L')));
        Observer.Observe('replace_miss_tc', Format(Src.Replace('zz', 'L')));
        Observer.Observe('replace_miss_t', Format(T.Replace('zz', 'L')));
        Observer.Observe('substring_tc', Format(Src.Substring(8)));
        Observer.Observe('substring_t', Format(T.Substring(8)));
        Observer.Observe('substring_len_tc', Format(Src.Substring(8, 3)));
        Observer.Observe('substring_len_t', Format(T.Substring(8, 3)));
        Observer.Observe('tolower_tc', Format(Src.ToLower()));
        Observer.Observe('tolower_t', Format(T.ToLower()));
        Observer.Expect('same_as_text', 'Yes');
        Observer.Expect('padleft_tc', '   Hello, World');
        Observer.Expect('padleft_t', '   Hello, World');
        Observer.Expect('padleft_chr_tc', '***Hello, World');
        Observer.Expect('padleft_chr_t', '***Hello, World');
        Observer.Expect('padleft_short_tc', 'Hello, World');
        Observer.Expect('padleft_short_t', 'Hello, World');
        Observer.Expect('padright_tc', 'Hello, World   ');
        Observer.Expect('padright_t', 'Hello, World   ');
        Observer.Expect('padright_chr_tc', 'Hello, World***');
        Observer.Expect('padright_chr_t', 'Hello, World***');
        Observer.Expect('remove_tc', 'Hello');
        Observer.Expect('remove_t', 'Hello');
        Observer.Expect('remove_count_tc', 'Helloorld');
        Observer.Expect('remove_count_t', 'Helloorld');
        Observer.Expect('replace_tc', 'HeLLo, WorLd');
        Observer.Expect('replace_t', 'HeLLo, WorLd');
        Observer.Expect('replace_miss_tc', 'Hello, World');
        Observer.Expect('replace_miss_t', 'Hello, World');
        Observer.Expect('substring_tc', 'World');
        Observer.Expect('substring_t', 'World');
        Observer.Expect('substring_len_tc', 'Wor');
        Observer.Expect('substring_len_t', 'Wor');
        Observer.Expect('tolower_tc', 'hello, world');
        Observer.Expect('tolower_t', 'hello, world');
        Observer.Verify();
    end;

    [Test]
    procedure Edit_2()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := Src;
        Observer.Observe('same_as_text', Format(T = Src));
        Observer.Observe('toupper_tc', Format(Src.ToUpper()));
        Observer.Observe('toupper_t', Format(T.ToUpper()));
        Observer.Expect('same_as_text', 'Yes');
        Observer.Expect('toupper_tc', 'HELLO, WORLD');
        Observer.Expect('toupper_t', 'HELLO, WORLD');
        Observer.Verify();
    end;

    [Test]
    procedure Trim_Family()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := PadSrc;
        Observer.Observe('trim_tc', '[' + PadSrc.Trim() + ']');
        Observer.Observe('trim_t', '[' + T.Trim() + ']');
        Observer.Observe('trimstart_tc', '[' + PadSrc.TrimStart(' ') + ']');
        Observer.Observe('trimstart_t', '[' + T.TrimStart(' ') + ']');
        Observer.Observe('trimend_tc', '[' + PadSrc.TrimEnd(' ') + ']');
        Observer.Observe('trimend_t', '[' + T.TrimEnd(' ') + ']');
        Observer.Observe('trimstart_chars_tc', '[' + PadSrc.TrimStart(' x') + ']');
        Observer.Observe('trimstart_chars_t', '[' + T.TrimStart(' x') + ']');
        Observer.Observe('trimend_chars_tc', '[' + PadSrc.TrimEnd(' x') + ']');
        Observer.Observe('trimend_chars_t', '[' + T.TrimEnd(' x') + ']');
        Observer.Expect('trim_tc', '[xx, yy]');
        Observer.Expect('trim_t', '[xx, yy]');
        Observer.Expect('trimstart_tc', '[xx, yy  ]');
        Observer.Expect('trimstart_t', '[xx, yy  ]');
        Observer.Expect('trimend_tc', '[  xx, yy]');
        Observer.Expect('trimend_t', '[  xx, yy]');
        Observer.Expect('trimstart_chars_tc', '[, yy  ]');
        Observer.Expect('trimstart_chars_t', '[, yy  ]');
        Observer.Expect('trimend_chars_tc', '[  xx, yy]');
        Observer.Expect('trimend_chars_t', '[  xx, yy]');
        Observer.Verify();
    end;

    [Test]
    procedure Split_Overloads()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P89 Helper";
        T: Text;
        Seps: List of [Text];
    begin
        T := SplitSrc;
        Seps.Add(',');
        Seps.Add(';');
        Observer.Observe('one_sep_l', Helper.Join(SplitSrc.Split(',')));
        Observer.Observe('one_sep_t', Helper.Join(T.Split(',')));
        Observer.Observe('two_sep_l', Helper.Join(SplitSrc.Split(',', ';')));
        Observer.Observe('two_sep_t', Helper.Join(T.Split(',', ';')));
        Observer.Observe('list_sep_l', Helper.Join(SplitSrc.Split(Seps)));
        Observer.Observe('list_sep_t', Helper.Join(T.Split(Seps)));
        Observer.Observe('miss_sep_l', Helper.Join(SplitSrc.Split('|')));
        Observer.Observe('miss_sep_t', Helper.Join(T.Split('|')));
        Observer.Observe('empty_sep_l', TrySplitEmpty(SplitSrc));
        Observer.Observe('empty_sep_t', TrySplitEmpty(T));
        Observer.Expect('one_sep_l', '4[a][b;c][][d]');
        Observer.Expect('one_sep_t', '4[a][b;c][][d]');
        Observer.Expect('two_sep_l', '5[a][b][c][][d]');
        Observer.Expect('two_sep_t', '5[a][b][c][][d]');
        Observer.Expect('list_sep_l', '5[a][b][c][][d]');
        Observer.Expect('list_sep_t', '5[a][b][c][][d]');
        Observer.Expect('miss_sep_l', '1[a,b;c,,d]');
        Observer.Expect('miss_sep_t', '1[a,b;c,,d]');
        Observer.Expect('empty_sep_l', '1[a,b;c,,d]');
        Observer.Expect('empty_sep_t', '1[a,b;c,,d]');
        Observer.Verify();
    end;

    [Test]
    procedure IndexOfAny_Overloads()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        Chars: List of [Char];
        NoChars: List of [Char];
    begin
        T := Src;
        Chars.Add('o');
        Chars.Add(',');
        Observer.Observe('anyof_l', Format(Src.IndexOfAny(Chars)));
        Observer.Observe('anyof_t', Format(T.IndexOfAny(Chars)));
        Observer.Observe('anyof_start_l', Format(Src.IndexOfAny(Chars, 6)));
        Observer.Observe('anyof_start_t', Format(T.IndexOfAny(Chars, 6)));
        Observer.Observe('anyof_none_l', Format(Src.IndexOfAny(NoChars)));
        Observer.Observe('anyof_none_t', Format(T.IndexOfAny(NoChars)));
        Observer.Expect('anyof_l', '5');
        Observer.Expect('anyof_t', '5');
        Observer.Expect('anyof_start_l', '6');
        Observer.Expect('anyof_start_t', '6');
        Observer.Expect('anyof_none_l', '0');
        Observer.Expect('anyof_none_t', '0');
        Observer.Verify();
    end;

}
