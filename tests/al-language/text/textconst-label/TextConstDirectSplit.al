// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71967 "LT TextConst Direct Split"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        TcOne: TextConst ENU = 'a,b;c,,d';
        TcTwo: TextConst ENU = 'a,b;c,,d', DEU = 'e,f;g,,h';
        TcEmpty: TextConst ENU = '';

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
    procedure P193_Split_Params()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
    begin
        Txt := TcOne;
        Observer.Observe('none_tc', Join(TcOne.Split()));
        Observer.Observe('none_txt', Join(Txt.Split()));
        Observer.Observe('one_tc', Join(TcOne.Split(',')));
        Observer.Observe('one_txt', Join(Txt.Split(',')));
        Observer.Observe('one_two_tc', Join(TcTwo.Split(',')));
        Observer.Observe('two_tc', Join(TcOne.Split(',', ';')));
        Observer.Observe('two_txt', Join(Txt.Split(',', ';')));
        Observer.Observe('multi_tc', Join(TcOne.Split(',,')));
        Observer.Observe('multi_txt', Join(Txt.Split(',,')));
        Observer.Observe('empty_sep_tc', Join(TcOne.Split('')));
        Observer.Observe('empty_sep_txt', Join(Txt.Split('')));
        Observer.Observe('miss_tc', Join(TcOne.Split('|')));
        Observer.Observe('empty_src_tc', Join(TcEmpty.Split(',')));
        Observer.Observe('empty_src_none_tc', Join(TcEmpty.Split()));
        Observer.Expect('none_tc', '1[a,b;c,,d]');
        Observer.Expect('none_txt', '1[a,b;c,,d]');
        Observer.Expect('one_tc', '4[a][b;c][][d]');
        Observer.Expect('one_txt', '4[a][b;c][][d]');
        Observer.Expect('one_two_tc', '4[a][b;c][][d]');
        Observer.Expect('two_tc', '5[a][b][c][][d]');
        Observer.Expect('two_txt', '5[a][b][c][][d]');
        Observer.Expect('multi_tc', '2[a,b;c][d]');
        Observer.Expect('multi_txt', '2[a,b;c][d]');
        Observer.Expect('empty_sep_tc', '1[a,b;c,,d]');
        Observer.Expect('empty_sep_txt', '1[a,b;c,,d]');
        Observer.Expect('miss_tc', '1[a,b;c,,d]');
        Observer.Expect('empty_src_tc', '1[]');
        Observer.Expect('empty_src_none_tc', '1[]');
        Observer.Verify();
    end;

    [Test]
    procedure P193_Split_CharList()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
        Seps: List of [Char];
        NoSeps: List of [Char];
    begin
        Txt := TcOne;
        Seps.Add(',');
        Seps.Add(';');
        Observer.Observe('chars_tc', Join(TcOne.Split(Seps)));
        Observer.Observe('chars_txt', Join(Txt.Split(Seps)));
        Observer.Observe('chars_two_tc', Join(TcTwo.Split(Seps)));
        Observer.Observe('chars_none_tc', Join(TcOne.Split(NoSeps)));
        Observer.Observe('chars_none_txt', Join(Txt.Split(NoSeps)));
        Observer.Observe('chars_empty_src_tc', Join(TcEmpty.Split(Seps)));
        Observer.Expect('chars_tc', '5[a][b][c][][d]');
        Observer.Expect('chars_txt', '5[a][b][c][][d]');
        Observer.Expect('chars_two_tc', '5[a][b][c][][d]');
        Observer.Expect('chars_none_tc', '1[a,b;c,,d]');
        Observer.Expect('chars_none_txt', '1[a,b;c,,d]');
        Observer.Expect('chars_empty_src_tc', '1[]');
        Observer.Verify();
    end;

    [Test]
    procedure P193_Split_TextList()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
        Seps: List of [Text];
        NoSeps: List of [Text];
    begin
        Txt := TcOne;
        Seps.Add(',');
        Seps.Add(';');
        Observer.Observe('texts_tc', Join(TcOne.Split(Seps)));
        Observer.Observe('texts_txt', Join(Txt.Split(Seps)));
        Observer.Observe('texts_two_tc', Join(TcTwo.Split(Seps)));
        Observer.Observe('texts_none_tc', Join(TcOne.Split(NoSeps)));
        Observer.Observe('texts_none_txt', Join(Txt.Split(NoSeps)));
        Seps.Add(',,');
        Observer.Observe('texts_multi_tc', Join(TcOne.Split(Seps)));
        Observer.Observe('texts_multi_txt', Join(Txt.Split(Seps)));
        Clear(Seps);
        Seps.Add('');
        Observer.Observe('texts_emptysep_tc', Join(TcOne.Split(Seps)));
        Observer.Observe('texts_emptysep_txt', Join(Txt.Split(Seps)));
        Observer.Observe('texts_empty_src_tc', Join(TcEmpty.Split(Seps)));
        Observer.Expect('texts_tc', '5[a][b][c][][d]');
        Observer.Expect('texts_txt', '5[a][b][c][][d]');
        Observer.Expect('texts_two_tc', '5[a][b][c][][d]');
        Observer.Expect('texts_none_tc', '1[a,b;c,,d]');
        Observer.Expect('texts_none_txt', '1[a,b;c,,d]');
        Observer.Expect('texts_multi_tc', '5[a][b][c][][d]');
        Observer.Expect('texts_multi_txt', '5[a][b][c][][d]');
        Observer.Expect('texts_emptysep_tc', '1[a,b;c,,d]');
        Observer.Expect('texts_emptysep_txt', '1[a,b;c,,d]');
        Observer.Expect('texts_empty_src_tc', '1[]');
        Observer.Verify();
    end;
}
