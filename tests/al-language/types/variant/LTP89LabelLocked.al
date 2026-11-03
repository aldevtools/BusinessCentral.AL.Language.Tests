// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P89 Helper (74627)
// Probe: written against BC 29 (observation only; facts are measured later). P89
// BC versions: 29

codeunit 74639 "LT P89 Label Locked Max"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Src: Label 'Hello, World', Locked = true;
        MaxSrc: Label 'Hello, World', MaxLength = 20;
        PadSrc: Label '  xx, yy  ', Locked = true, MaxLength = 20;
        SplitSrc: Label 'a,b;c,,d', Locked = true, Comment = 'unused';

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
        Observer.Observe('contains_lk', Format(Src.Contains('World')));
        Observer.Observe('contains_mx', Format(MaxSrc.Contains('World')));
        Observer.Observe('contains_t', Format(T.Contains('World')));
        Observer.Observe('contains_case_lk', Format(Src.Contains('world')));
        Observer.Observe('contains_case_mx', Format(MaxSrc.Contains('world')));
        Observer.Observe('contains_case_t', Format(T.Contains('world')));
        Observer.Observe('contains_empty_lk', Format(Src.Contains('')));
        Observer.Observe('contains_empty_mx', Format(MaxSrc.Contains('')));
        Observer.Observe('contains_empty_t', Format(T.Contains('')));
        Observer.Observe('starts_lk', Format(Src.StartsWith('Hello')));
        Observer.Observe('starts_mx', Format(MaxSrc.StartsWith('Hello')));
        Observer.Observe('starts_t', Format(T.StartsWith('Hello')));
        Observer.Observe('starts_case_lk', Format(Src.StartsWith('hello')));
        Observer.Observe('starts_case_mx', Format(MaxSrc.StartsWith('hello')));
        Observer.Observe('starts_case_t', Format(T.StartsWith('hello')));
        Observer.Observe('ends_lk', Format(Src.EndsWith('World')));
        Observer.Observe('ends_mx', Format(MaxSrc.EndsWith('World')));
        Observer.Observe('ends_t', Format(T.EndsWith('World')));
        Observer.Observe('ends_empty_lk', Format(Src.EndsWith('')));
        Observer.Observe('ends_empty_mx', Format(MaxSrc.EndsWith('')));
        Observer.Observe('ends_empty_t', Format(T.EndsWith('')));
        Observer.Observe('indexof_lk', Format(Src.IndexOf('o')));
        Observer.Observe('indexof_mx', Format(MaxSrc.IndexOf('o')));
        Observer.Observe('indexof_t', Format(T.IndexOf('o')));
        Observer.Expect('same_as_text', 'Yes');
        Observer.Expect('contains_lk', 'Yes');
        Observer.Expect('contains_mx', 'Yes');
        Observer.Expect('contains_t', 'Yes');
        Observer.Expect('contains_case_lk', 'No');
        Observer.Expect('contains_case_mx', 'No');
        Observer.Expect('contains_case_t', 'No');
        Observer.Expect('contains_empty_lk', 'Yes');
        Observer.Expect('contains_empty_mx', 'Yes');
        Observer.Expect('contains_empty_t', 'Yes');
        Observer.Expect('starts_lk', 'Yes');
        Observer.Expect('starts_mx', 'Yes');
        Observer.Expect('starts_t', 'Yes');
        Observer.Expect('starts_case_lk', 'No');
        Observer.Expect('starts_case_mx', 'No');
        Observer.Expect('starts_case_t', 'No');
        Observer.Expect('ends_lk', 'Yes');
        Observer.Expect('ends_mx', 'Yes');
        Observer.Expect('ends_t', 'Yes');
        Observer.Expect('ends_empty_lk', 'Yes');
        Observer.Expect('ends_empty_mx', 'Yes');
        Observer.Expect('ends_empty_t', 'Yes');
        Observer.Expect('indexof_lk', '5');
        Observer.Expect('indexof_mx', '5');
        Observer.Expect('indexof_t', '5');
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
        Observer.Observe('indexof_start_lk', Format(Src.IndexOf('o', 6)));
        Observer.Observe('indexof_start_mx', Format(MaxSrc.IndexOf('o', 6)));
        Observer.Observe('indexof_start_t', Format(T.IndexOf('o', 6)));
        Observer.Observe('indexof_miss_lk', Format(Src.IndexOf('zz')));
        Observer.Observe('indexof_miss_mx', Format(MaxSrc.IndexOf('zz')));
        Observer.Observe('indexof_miss_t', Format(T.IndexOf('zz')));
        Observer.Observe('indexof_empty_lk', Format(Src.IndexOf('')));
        Observer.Observe('indexof_empty_mx', Format(MaxSrc.IndexOf('')));
        Observer.Observe('indexof_empty_t', Format(T.IndexOf('')));
        Observer.Observe('lastindexof_lk', Format(Src.LastIndexOf('o')));
        Observer.Observe('lastindexof_mx', Format(MaxSrc.LastIndexOf('o')));
        Observer.Observe('lastindexof_t', Format(T.LastIndexOf('o')));
        Observer.Observe('lastindexof_start_lk', Format(Src.LastIndexOf('o', 5)));
        Observer.Observe('lastindexof_start_mx', Format(MaxSrc.LastIndexOf('o', 5)));
        Observer.Observe('lastindexof_start_t', Format(T.LastIndexOf('o', 5)));
        Observer.Observe('lastindexof_miss_lk', Format(Src.LastIndexOf('zz')));
        Observer.Observe('lastindexof_miss_mx', Format(MaxSrc.LastIndexOf('zz')));
        Observer.Observe('lastindexof_miss_t', Format(T.LastIndexOf('zz')));
        Observer.Expect('same_as_text', 'Yes');
        Observer.Expect('indexof_start_lk', '9');
        Observer.Expect('indexof_start_mx', '9');
        Observer.Expect('indexof_start_t', '9');
        Observer.Expect('indexof_miss_lk', '0');
        Observer.Expect('indexof_miss_mx', '0');
        Observer.Expect('indexof_miss_t', '0');
        Observer.Expect('indexof_empty_lk', '1');
        Observer.Expect('indexof_empty_mx', '1');
        Observer.Expect('indexof_empty_t', '1');
        Observer.Expect('lastindexof_lk', '9');
        Observer.Expect('lastindexof_mx', '9');
        Observer.Expect('lastindexof_t', '9');
        Observer.Expect('lastindexof_start_lk', '5');
        Observer.Expect('lastindexof_start_mx', '5');
        Observer.Expect('lastindexof_start_t', '5');
        Observer.Expect('lastindexof_miss_lk', '0');
        Observer.Expect('lastindexof_miss_mx', '0');
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
        Observer.Observe('padleft_lk', Format(Src.PadLeft(15)));
        Observer.Observe('padleft_mx', Format(MaxSrc.PadLeft(15)));
        Observer.Observe('padleft_t', Format(T.PadLeft(15)));
        Observer.Observe('padleft_chr_lk', Format(Src.PadLeft(15, '*')));
        Observer.Observe('padleft_chr_mx', Format(MaxSrc.PadLeft(15, '*')));
        Observer.Observe('padleft_chr_t', Format(T.PadLeft(15, '*')));
        Observer.Observe('padleft_short_lk', Format(Src.PadLeft(3)));
        Observer.Observe('padleft_short_mx', Format(MaxSrc.PadLeft(3)));
        Observer.Observe('padleft_short_t', Format(T.PadLeft(3)));
        Observer.Observe('padright_lk', Format(Src.PadRight(15)));
        Observer.Observe('padright_mx', Format(MaxSrc.PadRight(15)));
        Observer.Observe('padright_t', Format(T.PadRight(15)));
        Observer.Observe('padright_chr_lk', Format(Src.PadRight(15, '*')));
        Observer.Observe('padright_chr_mx', Format(MaxSrc.PadRight(15, '*')));
        Observer.Observe('padright_chr_t', Format(T.PadRight(15, '*')));
        Observer.Observe('remove_lk', Format(Src.Remove(6)));
        Observer.Observe('remove_mx', Format(MaxSrc.Remove(6)));
        Observer.Observe('remove_t', Format(T.Remove(6)));
        Observer.Observe('remove_count_lk', Format(Src.Remove(6, 3)));
        Observer.Observe('remove_count_mx', Format(MaxSrc.Remove(6, 3)));
        Observer.Observe('remove_count_t', Format(T.Remove(6, 3)));
        Observer.Observe('replace_lk', Format(Src.Replace('l', 'L')));
        Observer.Observe('replace_mx', Format(MaxSrc.Replace('l', 'L')));
        Observer.Observe('replace_t', Format(T.Replace('l', 'L')));
        Observer.Expect('same_as_text', 'Yes');
        Observer.Expect('padleft_lk', '   Hello, World');
        Observer.Expect('padleft_mx', '   Hello, World');
        Observer.Expect('padleft_t', '   Hello, World');
        Observer.Expect('padleft_chr_lk', '***Hello, World');
        Observer.Expect('padleft_chr_mx', '***Hello, World');
        Observer.Expect('padleft_chr_t', '***Hello, World');
        Observer.Expect('padleft_short_lk', 'Hello, World');
        Observer.Expect('padleft_short_mx', 'Hello, World');
        Observer.Expect('padleft_short_t', 'Hello, World');
        Observer.Expect('padright_lk', 'Hello, World   ');
        Observer.Expect('padright_mx', 'Hello, World   ');
        Observer.Expect('padright_t', 'Hello, World   ');
        Observer.Expect('padright_chr_lk', 'Hello, World***');
        Observer.Expect('padright_chr_mx', 'Hello, World***');
        Observer.Expect('padright_chr_t', 'Hello, World***');
        Observer.Expect('remove_lk', 'Hello');
        Observer.Expect('remove_mx', 'Hello');
        Observer.Expect('remove_t', 'Hello');
        Observer.Expect('remove_count_lk', 'Helloorld');
        Observer.Expect('remove_count_mx', 'Helloorld');
        Observer.Expect('remove_count_t', 'Helloorld');
        Observer.Expect('replace_lk', 'HeLLo, WorLd');
        Observer.Expect('replace_mx', 'HeLLo, WorLd');
        Observer.Expect('replace_t', 'HeLLo, WorLd');
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
        Observer.Observe('replace_miss_lk', Format(Src.Replace('zz', 'L')));
        Observer.Observe('replace_miss_mx', Format(MaxSrc.Replace('zz', 'L')));
        Observer.Observe('replace_miss_t', Format(T.Replace('zz', 'L')));
        Observer.Observe('substring_lk', Format(Src.Substring(8)));
        Observer.Observe('substring_mx', Format(MaxSrc.Substring(8)));
        Observer.Observe('substring_t', Format(T.Substring(8)));
        Observer.Observe('substring_len_lk', Format(Src.Substring(8, 3)));
        Observer.Observe('substring_len_mx', Format(MaxSrc.Substring(8, 3)));
        Observer.Observe('substring_len_t', Format(T.Substring(8, 3)));
        Observer.Observe('tolower_lk', Format(Src.ToLower()));
        Observer.Observe('tolower_mx', Format(MaxSrc.ToLower()));
        Observer.Observe('tolower_t', Format(T.ToLower()));
        Observer.Observe('toupper_lk', Format(Src.ToUpper()));
        Observer.Observe('toupper_mx', Format(MaxSrc.ToUpper()));
        Observer.Observe('toupper_t', Format(T.ToUpper()));
        Observer.Expect('same_as_text', 'Yes');
        Observer.Expect('replace_miss_lk', 'Hello, World');
        Observer.Expect('replace_miss_mx', 'Hello, World');
        Observer.Expect('replace_miss_t', 'Hello, World');
        Observer.Expect('substring_lk', 'World');
        Observer.Expect('substring_mx', 'World');
        Observer.Expect('substring_t', 'World');
        Observer.Expect('substring_len_lk', 'Wor');
        Observer.Expect('substring_len_mx', 'Wor');
        Observer.Expect('substring_len_t', 'Wor');
        Observer.Expect('tolower_lk', 'hello, world');
        Observer.Expect('tolower_mx', 'hello, world');
        Observer.Expect('tolower_t', 'hello, world');
        Observer.Expect('toupper_lk', 'HELLO, WORLD');
        Observer.Expect('toupper_mx', 'HELLO, WORLD');
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
        Observer.Observe('trim_lk', '[' + PadSrc.Trim() + ']');
        Observer.Observe('trim_t', '[' + T.Trim() + ']');
        Observer.Observe('trimstart_lk', '[' + PadSrc.TrimStart(' ') + ']');
        Observer.Observe('trimstart_t', '[' + T.TrimStart(' ') + ']');
        Observer.Observe('trimend_lk', '[' + PadSrc.TrimEnd(' ') + ']');
        Observer.Observe('trimend_t', '[' + T.TrimEnd(' ') + ']');
        Observer.Observe('trimstart_chars_lk', '[' + PadSrc.TrimStart(' x') + ']');
        Observer.Observe('trimstart_chars_t', '[' + T.TrimStart(' x') + ']');
        Observer.Observe('trimend_chars_lk', '[' + PadSrc.TrimEnd(' x') + ']');
        Observer.Observe('trimend_chars_t', '[' + T.TrimEnd(' x') + ']');
        Observer.Expect('trim_lk', '[xx, yy]');
        Observer.Expect('trim_t', '[xx, yy]');
        Observer.Expect('trimstart_lk', '[xx, yy  ]');
        Observer.Expect('trimstart_t', '[xx, yy  ]');
        Observer.Expect('trimend_lk', '[  xx, yy]');
        Observer.Expect('trimend_t', '[  xx, yy]');
        Observer.Expect('trimstart_chars_lk', '[, yy  ]');
        Observer.Expect('trimstart_chars_t', '[, yy  ]');
        Observer.Expect('trimend_chars_lk', '[  xx, yy]');
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
