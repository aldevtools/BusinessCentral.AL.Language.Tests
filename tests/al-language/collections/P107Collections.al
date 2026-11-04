// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-set-method
// Scope: in-scope
// Fixtures used: none (self-contained), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Dictionary.Set with var OldValue, List.GetRange with var Result, List.Set with var OldValue
// BC versions: 29 (27 and 28 by CI)

codeunit 72700 "LT P107 Collections"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P107_DictionarySetOld()
    var
        Observer: Codeunit "Probe Observer";
        Dict: Dictionary of [Text, Integer];
        Old: Integer;
    begin
        Old := 99;
        Dict.Set('a', 1, Old);
        Observer.Observe('absent_old', Format(Old));
        Observer.Observe('absent_added', Format(Dict.ContainsKey('a')));
        Observer.Observe('absent_count', Format(Dict.Count()));
        Dict.Set('a', 2, Old);
        Observer.Observe('present_old', Format(Old));
        Observer.Observe('present_value', Format(Dict.Get('a')));
        Dict.Set('a', 3, Old);
        Observer.Observe('second_old', Format(Old));
        Observer.Observe('count', Format(Dict.Count()));
        Observer.Expect('absent_old', '99');
        Observer.Expect('absent_added', 'Yes');
        Observer.Expect('absent_count', '1');
        Observer.Expect('present_old', '1');
        Observer.Expect('present_value', '2');
        Observer.Expect('second_old', '2');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P107_DictionarySetOldText()
    var
        Observer: Codeunit "Probe Observer";
        Dict: Dictionary of [Integer, Text];
        Old: Text;
    begin
        Old := 'untouched';
        Dict.Set(1, 'x', Old);
        Observer.Observe('absent_old', Old);
        Dict.Set(1, 'y', Old);
        Observer.Observe('present_old', Old);
        Dict.Set(1, '', Old);
        Observer.Observe('prev_y', Old);
        Dict.Set(1, 'z', Old);
        Observer.Observe('prev_empty', '[' + Old + ']');
        Observer.Observe('value', Dict.Get(1));
        Observer.Expect('absent_old', 'untouched');
        Observer.Expect('present_old', 'x');
        Observer.Expect('prev_y', 'y');
        Observer.Expect('prev_empty', '[]');
        Observer.Expect('value', 'z');
        Observer.Verify();
    end;

    [Test]
    procedure P107_ListGetRangeVar()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        R: List of [Integer];
        i: Integer;
    begin
        for i := 1 to 5 do
            L.Add(i * 10);
        R.Add(777);
        L.GetRange(2, 3, R);
        Observer.Observe('count', Format(R.Count()));
        Observer.Observe('first', Format(R.Get(1)));
        Observer.Observe('last', Format(R.Get(3)));
        L.GetRange(1, 0, R);
        Observer.Observe('zero_count', Format(R.Count()));
        L.GetRange(5, 1, R);
        Observer.Observe('last_elem', Format(R.Get(1)));
        L.GetRange(1, 5, R);
        Observer.Observe('all', Format(R.Count()));
        asserterror L.GetRange(0, 1, R);
        Observer.ObserveError('index_zero');
        asserterror L.GetRange(6, 1, R);
        Observer.ObserveError('index_past');
        asserterror L.GetRange(4, 3, R);
        Observer.ObserveError('count_past');
        asserterror L.GetRange(1, -1, R);
        Observer.ObserveError('negative_count');
        Observer.Observe('result_after_errors', Format(R.Count()));
        Observer.Expect('count', '3');
        Observer.Expect('first', '20');
        Observer.Expect('last', '40');
        Observer.Expect('zero_count', '0');
        Observer.Expect('last_elem', '50');
        Observer.Expect('all', '5');
        Observer.Expect('index_zero|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('index_zero|code', 'ArgumentOutOfRange');
        Observer.Expect('index_past|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('index_past|code', 'Argument');
        Observer.Expect('count_past|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('count_past|code', 'Argument');
        Observer.Expect('negative_count|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('negative_count|code', 'ArgumentOutOfRange');
        Observer.Expect('result_after_errors', '5');
        Observer.Verify();
    end;

    [Test]
    procedure P107_ListGetRangeVarSelf()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Text];
        Empty: List of [Text];
    begin
        L.Add('a');
        L.Add('b');
        L.Add('c');
        L.GetRange(2, 2, L);
        Observer.Observe('self_count', Format(L.Count()));
        Empty.GetRange(1, 0, L);
        Observer.Observe('empty_source', Format(L.Count()));
        asserterror Empty.GetRange(1, 1, L);
        Observer.ObserveError('empty_source_one');
        Observer.Expect('self_count', '2');
        Observer.Expect('empty_source', '0');
        Observer.Expect('empty_source_one|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('empty_source_one|code', 'Argument');
        Observer.Verify();
    end;

    [Test]
    procedure P107_ListSetOld()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Text];
        Old: Text;
    begin
        L.Add('a');
        L.Add('b');
        Old := 'untouched';
        L.Set(2, 'B', Old);
        Observer.Observe('old', Old);
        Observer.Observe('new', L.Get(2));
        L.Set(1, '', Old);
        Observer.Observe('old_first', Old);
        L.Set(1, 'x', Old);
        Observer.Observe('old_empty', '[' + Old + ']');
        Old := 'keep';
        asserterror L.Set(0, 'z', Old);
        Observer.ObserveError('index_zero');
        Observer.Observe('old_after_zero', Old);
        asserterror L.Set(3, 'z', Old);
        Observer.ObserveError('index_past');
        asserterror L.Set(-1, 'z', Old);
        Observer.ObserveError('index_negative');
        Observer.Observe('count', Format(L.Count()));
        Observer.Expect('old', 'b');
        Observer.Expect('new', 'B');
        Observer.Expect('old_first', 'a');
        Observer.Expect('old_empty', '[]');
        Observer.Expect('index_zero|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('index_zero|code', 'ArgumentOutOfRange');
        Observer.Expect('old_after_zero', 'keep');
        Observer.Expect('index_past|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('index_past|code', 'ArgumentOutOfRange');
        Observer.Expect('index_negative|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('index_negative|code', 'ArgumentOutOfRange');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P107_ListSetOldInteger()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        Old: Integer;
    begin
        L.Add(1);
        Old := -5;
        L.Set(1, 2, Old);
        Observer.Observe('old', Format(Old));
        L.Set(1, 3, Old);
        Observer.Observe('old2', Format(Old));
        Observer.Observe('value', Format(L.Get(1)));
        Observer.Expect('old', '1');
        Observer.Expect('old2', '2');
        Observer.Expect('value', '3');
        Observer.Verify();
    end;
}
