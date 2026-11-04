// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71522 "LT P103 Label SplitAny"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SplitSrc: Label 'a,b;c,,d';
        AnySrc: Label 'Hello, World;x';

    local procedure Join(L: List of [Text]): Text
    var
        S: Text;
        Item: Text;
    begin
        foreach Item in L do
            S += '[' + Item + ']';
        exit(Format(L.Count()) + S);
    end;

    [Test]
    procedure P103_LbSplit_CharList()
    var
        Observer: Codeunit "Probe Observer";
        Seps: List of [Char];
        NoSeps: List of [Char];
    begin
        Seps.Add(',');
        Seps.Add(';');
        Observer.Observe('chars_two', Join(SplitSrc.Split(Seps)));
        Observer.Observe('chars_none', Join(SplitSrc.Split(NoSeps)));
        Seps.Add('d');
        Observer.Observe('chars_three', Join(SplitSrc.Split(Seps)));
        Seps.Add('a');
        Observer.Observe('chars_four', Join(SplitSrc.Split(Seps)));
        Observer.Expect('chars_two', '5[a][b][c][][d]');
        Observer.Expect('chars_none', '1[a,b;c,,d]');
        Observer.Expect('chars_three', '6[a][b][c][][][]');
        Observer.Expect('chars_four', '7[][][b][c][][][]');
        Observer.Verify();
    end;

    [Test]
    procedure P103_LbSplit_TextList()
    var
        Observer: Codeunit "Probe Observer";
        Seps: List of [Text];
        NoSeps: List of [Text];
    begin
        Seps.Add(',');
        Seps.Add(';');
        Observer.Observe('texts_two', Join(SplitSrc.Split(Seps)));
        Observer.Observe('texts_none', Join(SplitSrc.Split(NoSeps)));
        Seps.Add(',,');
        Observer.Observe('texts_multichar', Join(SplitSrc.Split(Seps)));
        Clear(Seps);
        Seps.Add('');
        Observer.Observe('texts_emptysep', Join(SplitSrc.Split(Seps)));
        Clear(Seps);
        Seps.Add(';c');
        Observer.Observe('texts_two_char_sep', Join(SplitSrc.Split(Seps)));
        Observer.Expect('texts_two', '5[a][b][c][][d]');
        Observer.Expect('texts_none', '1[a,b;c,,d]');
        Observer.Expect('texts_multichar', '5[a][b][c][][d]');
        Observer.Expect('texts_emptysep', '1[a,b;c,,d]');
        Observer.Expect('texts_two_char_sep', '2[a,b][,,d]');
        Observer.Verify();
    end;

    [Test]
    procedure P103_LbSplit_Params()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('no_args', Join(SplitSrc.Split()));
        Observer.Observe('one', Join(SplitSrc.Split(',')));
        Observer.Observe('two', Join(SplitSrc.Split(',', ';')));
        Observer.Observe('three', Join(SplitSrc.Split(',', ';', 'd')));
        Observer.Observe('multichar', Join(SplitSrc.Split(',,')));
        Observer.Observe('miss', Join(SplitSrc.Split('|')));
        Observer.Expect('no_args', '1[a,b;c,,d]');
        Observer.Expect('one', '4[a][b;c][][d]');
        Observer.Expect('two', '5[a][b][c][][d]');
        Observer.Expect('three', '6[a][b][c][][][]');
        Observer.Expect('multichar', '2[a,b;c][d]');
        Observer.Expect('miss', '1[a,b;c,,d]');
        Observer.Verify();
    end;

    [Test]
    procedure P103_LbIndexOfAny_Chars()
    var
        Observer: Codeunit "Probe Observer";
        Chars: List of [Char];
        NoChars: List of [Char];
    begin
        Chars.Add('o');
        Chars.Add(',');
        Observer.Observe('chars', Format(AnySrc.IndexOfAny(Chars)));
        Observer.Observe('chars_start', Format(AnySrc.IndexOfAny(Chars, 6)));
        Observer.Observe('chars_start_1', Format(AnySrc.IndexOfAny(Chars, 1)));
        Observer.Observe('chars_none', Format(AnySrc.IndexOfAny(NoChars)));
        Observer.Expect('chars', '5');
        Observer.Expect('chars_start', '6');
        Observer.Expect('chars_start_1', '5');
        Observer.Expect('chars_none', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P103_LbIndexOfAny_Text()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('text', Format(AnySrc.IndexOfAny('o,')));
        Observer.Observe('text_start', Format(AnySrc.IndexOfAny('o,', 6)));
        Observer.Observe('text_start_1', Format(AnySrc.IndexOfAny('o,', 1)));
        Observer.Observe('text_empty', Format(AnySrc.IndexOfAny('')));
        Observer.Observe('text_empty_start', Format(AnySrc.IndexOfAny('', 3)));
        Observer.Observe('text_miss', Format(AnySrc.IndexOfAny('qz')));
        Observer.Observe('text_case', Format(AnySrc.IndexOfAny('W')));
        Observer.Observe('text_case_lower', Format(AnySrc.IndexOfAny('w')));
        Observer.Observe('text_last', Format(AnySrc.IndexOfAny('x')));
        Observer.Expect('text', '5');
        Observer.Expect('text_start', '6');
        Observer.Expect('text_start_1', '5');
        Observer.Expect('text_empty', '0');
        Observer.Expect('text_empty_start', '0');
        Observer.Expect('text_miss', '0');
        Observer.Expect('text_case', '8');
        Observer.Expect('text_case_lower', '0');
        Observer.Expect('text_last', '14');
        Observer.Verify();
    end;
}
