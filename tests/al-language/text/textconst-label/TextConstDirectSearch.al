// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71965 "LT TextConst Direct Search"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        TcOne: TextConst ENU = 'Hello, World; hello';
        TcTwo: TextConst ENU = 'Hello, World; hello', DEU = 'Hallo, Welt; hallo';
        TcEmpty: TextConst ENU = '';

    [Test]
    procedure P193_Contains_Starts_Ends()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
        TxtTwo: Text;
    begin
        Txt := TcOne;
        TxtTwo := TcTwo;
        Observer.Observe('contains_tc', Format(TcOne.Contains('World')));
        Observer.Observe('contains_txt', Format(Txt.Contains('World')));
        Observer.Observe('contains_two_tc', Format(TcTwo.Contains('World')));
        Observer.Observe('contains_two_txt', Format(TxtTwo.Contains('World')));
        Observer.Observe('contains_case_tc', Format(TcOne.Contains('WORLD')));
        Observer.Observe('contains_case_txt', Format(Txt.Contains('WORLD')));
        Observer.Observe('contains_empty_tc', Format(TcOne.Contains('')));
        Observer.Observe('contains_empty_txt', Format(Txt.Contains('')));
        Observer.Observe('contains_empty_src_tc', Format(TcEmpty.Contains('a')));
        Observer.Observe('starts_tc', Format(TcOne.StartsWith('Hello')));
        Observer.Observe('starts_txt', Format(Txt.StartsWith('Hello')));
        Observer.Observe('starts_two_tc', Format(TcTwo.StartsWith('Hello')));
        Observer.Observe('starts_empty_tc', Format(TcOne.StartsWith('')));
        Observer.Observe('starts_empty_txt', Format(Txt.StartsWith('')));
        Observer.Observe('starts_case_tc', Format(TcOne.StartsWith('hello')));
        Observer.Observe('ends_tc', Format(TcOne.EndsWith('hello')));
        Observer.Observe('ends_txt', Format(Txt.EndsWith('hello')));
        Observer.Observe('ends_two_tc', Format(TcTwo.EndsWith('hello')));
        Observer.Observe('ends_empty_tc', Format(TcOne.EndsWith('')));
        Observer.Observe('ends_empty_txt', Format(Txt.EndsWith('')));
        Observer.Observe('ends_case_tc', Format(TcOne.EndsWith('HELLO')));
        Observer.Observe('ends_empty_src_tc', Format(TcEmpty.EndsWith('')));
        Observer.Expect('contains_tc', 'Yes');
        Observer.Expect('contains_txt', 'Yes');
        Observer.Expect('contains_two_tc', 'Yes');
        Observer.Expect('contains_two_txt', 'Yes');
        Observer.Expect('contains_case_tc', 'No');
        Observer.Expect('contains_case_txt', 'No');
        Observer.Expect('contains_empty_tc', 'Yes');
        Observer.Expect('contains_empty_txt', 'Yes');
        Observer.Expect('contains_empty_src_tc', 'No');
        Observer.Expect('starts_tc', 'Yes');
        Observer.Expect('starts_txt', 'Yes');
        Observer.Expect('starts_two_tc', 'Yes');
        Observer.Expect('starts_empty_tc', 'Yes');
        Observer.Expect('starts_empty_txt', 'Yes');
        Observer.Expect('starts_case_tc', 'No');
        Observer.Expect('ends_tc', 'Yes');
        Observer.Expect('ends_txt', 'Yes');
        Observer.Expect('ends_two_tc', 'Yes');
        Observer.Expect('ends_empty_tc', 'Yes');
        Observer.Expect('ends_empty_txt', 'Yes');
        Observer.Expect('ends_case_tc', 'No');
        Observer.Expect('ends_empty_src_tc', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P193_IndexOf_LastIndexOf()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
    begin
        Txt := TcOne;
        Observer.Observe('indexof_tc', Format(TcOne.IndexOf('o')));
        Observer.Observe('indexof_txt', Format(Txt.IndexOf('o')));
        Observer.Observe('indexof_two_tc', Format(TcTwo.IndexOf('a')));
        Observer.Observe('indexof_start_tc', Format(TcOne.IndexOf('o', 6)));
        Observer.Observe('indexof_start_txt', Format(Txt.IndexOf('o', 6)));
        Observer.Observe('indexof_empty_tc', Format(TcOne.IndexOf('')));
        Observer.Observe('indexof_empty_txt', Format(Txt.IndexOf('')));
        Observer.Observe('indexof_miss_tc', Format(TcOne.IndexOf('q')));
        Observer.Observe('indexof_case_tc', Format(TcOne.IndexOf('h')));
        Observer.Observe('lastindexof_tc', Format(TcOne.LastIndexOf('o')));
        Observer.Observe('lastindexof_txt', Format(Txt.LastIndexOf('o')));
        Observer.Observe('lastindexof_two_tc', Format(TcTwo.LastIndexOf('a')));
        Observer.Observe('lastindexof_start_tc', Format(TcOne.LastIndexOf('o', 10)));
        Observer.Observe('lastindexof_start_txt', Format(Txt.LastIndexOf('o', 10)));
        Observer.Observe('lastindexof_empty_tc', Format(TcOne.LastIndexOf('')));
        Observer.Observe('lastindexof_empty_txt', Format(Txt.LastIndexOf('')));
        asserterror Observer.Observe('indexof_start_big_tc', Format(TcOne.IndexOf('o', 99)));
        Observer.ObserveError('indexof_start_big_tc_err');
        asserterror Observer.Observe('indexof_start_big_txt', Format(Txt.IndexOf('o', 99)));
        Observer.ObserveError('indexof_start_big_txt_err');
        asserterror Observer.Observe('lastindexof_start_big_tc', Format(TcOne.LastIndexOf('o', 99)));
        Observer.ObserveError('lastindexof_start_big_tc_err');
        asserterror Observer.Observe('indexof_start_0_tc', Format(TcOne.IndexOf('o', 0)));
        Observer.ObserveError('indexof_start_0_tc_err');
        Observer.Expect('indexof_tc', '5');
        Observer.Expect('indexof_txt', '5');
        Observer.Expect('indexof_two_tc', '0');
        Observer.Expect('indexof_start_tc', '9');
        Observer.Expect('indexof_start_txt', '9');
        Observer.Expect('indexof_empty_tc', '1');
        Observer.Expect('indexof_empty_txt', '1');
        Observer.Expect('indexof_miss_tc', '0');
        Observer.Expect('indexof_case_tc', '15');
        Observer.Expect('lastindexof_tc', '19');
        Observer.Expect('lastindexof_txt', '19');
        Observer.Expect('lastindexof_two_tc', '0');
        Observer.Expect('lastindexof_start_tc', '9');
        Observer.Expect('lastindexof_start_txt', '9');
        Observer.Expect('lastindexof_empty_tc', '20');
        Observer.Expect('lastindexof_empty_txt', '20');
        Observer.Expect('indexof_start_big_tc_err|text', 'Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('indexof_start_big_tc_err|code', 'ArgumentOutOfRange');
        Observer.Expect('indexof_start_big_txt_err|text', 'Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('indexof_start_big_txt_err|code', 'ArgumentOutOfRange');
        Observer.Expect('lastindexof_start_big_tc_err|text', 'Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('lastindexof_start_big_tc_err|code', 'ArgumentOutOfRange');
        Observer.Expect('indexof_start_0_tc_err|text', 'Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('indexof_start_0_tc_err|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;
}
