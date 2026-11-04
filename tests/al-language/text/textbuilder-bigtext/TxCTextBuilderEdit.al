// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/textbuilder/textbuilder-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunits 71010-71016
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// TextBuilder: Insert, Remove, Replace overloads, ToText overloads, out of range errors, reference semantics.
// BC versions: 29 (27 and 28 by CI)

codeunit 71010 "LT TxC TB Insert"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Insert_Positions()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Append('abcdef');
        asserterror TB.Insert(0, 'X');
        Observer.ObserveError('af20');
        Observer.Observe('at0', TB.ToText());
        TB.Insert(1, 'Y');
        Observer.Observe('at1', TB.ToText());
        TB.Insert(TB.Length(), 'E');
        Observer.Observe('atLen', TB.ToText());
        TB.Insert(3, '');
        Observer.Observe('empty', TB.ToText());
        TB.Insert(2, 'LONGER');
        Observer.Observe('mid', TB.ToText());
        Observer.Observe('len', Format(TB.Length()));
        Observer.Expect('af20|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('af20|code', 'ArgumentOutOfRange');
        Observer.Expect('at0', 'abcdef');
        Observer.Expect('at1', 'Yabcdef');
        Observer.Expect('atLen', 'YabcdeEf');
        Observer.Expect('empty', 'YabcdeEf');
        Observer.Expect('mid', 'YLONGERabcdeEf');
        Observer.Expect('len', '14');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_Errors()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Append('abc');
        asserterror TB.Insert(-1, 'X');
        Observer.ObserveError('neg');
        TB.Insert(4, 'X');
        Observer.Observe('lenPlus1', 'no error');
        asserterror TB.Insert(100, 'X');
        Observer.ObserveError('far');
        Observer.Observe('unchanged', TB.ToText());
        Observer.Expect('neg|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('neg|code', 'ArgumentOutOfRange');
        Observer.Expect('lenPlus1', 'no error');
        Observer.Expect('far|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('far|code', 'ArgumentOutOfRange');
        Observer.Expect('unchanged', 'abcX');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_EmptyBuilder()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        asserterror TB.Insert(0, 'abc');
        Observer.ObserveError('af58');
        Observer.Observe('t', TB.ToText());
        asserterror TB.Insert(5, 'z');
        Observer.ObserveError('beyond');
        Observer.Expect('af58|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('af58|code', 'ArgumentOutOfRange');
        Observer.Expect('t', '');
        Observer.Expect('beyond|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('beyond|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;
}

codeunit 71011 "LT TxC TB Remove"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Remove_Ranges()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Append('0123456789');
        asserterror TB.Remove(0, 2);
        Observer.ObserveError('af79');
        Observer.Observe('front', TB.ToText());
        TB.Remove(2, 3);
        Observer.Observe('mid', TB.ToText());
        TB.Remove(TB.Length() - 1, 1);
        Observer.Observe('last', TB.ToText());
        TB.Remove(1, 0);
        Observer.Observe('zeroCount', TB.ToText());
        asserterror TB.Remove(0, TB.Length());
        Observer.ObserveError('af88');
        Observer.Observe('all', TB.ToText());
        Observer.Observe('len', Format(TB.Length()));
        Observer.Expect('af79|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('af79|code', 'ArgumentOutOfRange');
        Observer.Expect('front', '0123456789');
        Observer.Expect('mid', '0456789');
        Observer.Expect('last', '045679');
        Observer.Expect('zeroCount', '045679');
        Observer.Expect('af88|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('af88|code', 'ArgumentOutOfRange');
        Observer.Expect('all', '045679');
        Observer.Expect('len', '6');
        Observer.Verify();
    end;

    [Test]
    procedure Remove_Errors()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Append('abcdef');
        asserterror TB.Remove(-1, 1);
        Observer.ObserveError('negStart');
        asserterror TB.Remove(0, -1);
        Observer.ObserveError('negCount');
        asserterror TB.Remove(0, 7);
        Observer.ObserveError('countTooBig');
        TB.Remove(4, 3);
        Observer.Observe('sumTooBig', 'no error');
        asserterror TB.Remove(6, 1);
        Observer.ObserveError('startAtLen');
        asserterror TB.Remove(7, 0);
        Observer.ObserveError('startPastLen');
        asserterror TB.Remove(6, 0);
        Observer.ObserveError('af114');
        Observer.Observe('startAtLenZero', TB.ToText());
        Observer.Expect('negStart|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('negStart|code', 'ArgumentOutOfRange');
        Observer.Expect('negCount|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('negCount|code', 'ArgumentOutOfRange');
        Observer.Expect('countTooBig|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('countTooBig|code', 'ArgumentOutOfRange');
        Observer.Expect('sumTooBig', 'no error');
        Observer.Expect('startAtLen|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('startAtLen|code', 'ArgumentOutOfRange');
        Observer.Expect('startPastLen|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('startPastLen|code', 'ArgumentOutOfRange');
        Observer.Expect('af114|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('af114|code', 'ArgumentOutOfRange');
        Observer.Expect('startAtLenZero', 'abc');
        Observer.Verify();
    end;
}

codeunit 71012 "LT TxC TB Replace"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Replace_Basic()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        N: Integer;
    begin
        TB.Append('abcabcabc');
        TB.Replace('b', 'X');
        Observer.Observe('all', TB.ToText());
        TB.Replace('XY', 'Q');
        Observer.Observe('absent', TB.ToText());
        TB.Replace('a', '');
        Observer.Observe('toEmpty', TB.ToText());
        TB.Replace('X', 'XX');
        Observer.Observe('grow', TB.ToText());
        Observer.Observe('len', Format(TB.Length()));
        TB.Replace('c', 'c');
        Observer.Observe('same', TB.ToText());
        Observer.Expect('all', 'aXcaXcaXc');
        Observer.Expect('absent', 'aXcaXcaXc');
        Observer.Expect('toEmpty', 'XcXcXc');
        Observer.Expect('grow', 'XXcXXcXXc');
        Observer.Expect('len', '9');
        Observer.Expect('same', 'XXcXXcXXc');
        Observer.Verify();
    end;

    [Test]
    procedure Replace_CaseAndEmptyOld()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Append('Abc aBC abc');
        TB.Replace('abc', '-');
        Observer.Observe('caseSens', TB.ToText());
        asserterror TB.Replace('', 'X');
        Observer.Observe('emptyOld|text', GetLastErrorText());
        ClearLastError();
        Observer.Observe('after', TB.ToText());
        Observer.Expect('caseSens', 'Abc aBC -');
        Observer.Expect('emptyOld|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('after', 'Abc aBC -');
        Observer.Verify();
    end;

    [Test]
    procedure Replace_Overlap_Recursive()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Append('aaaa');
        TB.Replace('aa', 'a');
        Observer.Observe('overlap', TB.ToText());
        TB.Clear();
        TB.Append('abab');
        TB.Replace('ab', 'abab');
        Observer.Observe('selfContaining', TB.ToText());
        Observer.Expect('overlap', 'aa');
        Observer.Expect('selfContaining', 'abababab');
        Observer.Verify();
    end;

    [Test]
    procedure Replace_StartCount()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Append('aXaXaXaX');
        TB.Replace('X', '-', 2, 4);
        Observer.Observe('range', TB.ToText());
        TB.Clear();
        TB.Append('aXaXaXaX');
        asserterror TB.Replace('X', '-', 0, 2);
        Observer.ObserveError('af188');
        Observer.Observe('firstTwoChars', TB.ToText());
        TB.Clear();
        TB.Append('aXaXaXaX');
        asserterror TB.Replace('X', '-', 0, TB.Length());
        Observer.ObserveError('af195');
        Observer.Observe('whole', TB.ToText());
        TB.Clear();
        TB.Append('aXaXaXaX');
        TB.Replace('X', '-', 3, 0);
        Observer.Observe('zeroCount', TB.ToText());
        TB.Clear();
        TB.Append('aXaXaXaX');
        TB.Replace('aX', '-', 1, 4);
        Observer.Observe('straddle', TB.ToText());
        Observer.Expect('range', 'a-a-aXaX');
        Observer.Expect('af188|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('af188|code', 'ArgumentOutOfRange');
        Observer.Expect('firstTwoChars', 'aXaXaXaX');
        Observer.Expect('af195|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('af195|code', 'ArgumentOutOfRange');
        Observer.Expect('whole', 'aXaXaXaX');
        Observer.Expect('zeroCount', 'aXaXaXaX');
        Observer.Expect('straddle', '--aXaX');
        Observer.Verify();
    end;

    [Test]
    procedure Replace_StartCount_Errors()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Append('abcdef');
        asserterror TB.Replace('a', 'b', -1, 2);
        Observer.ObserveError('negStart');
        asserterror TB.Replace('a', 'b', 0, -1);
        Observer.ObserveError('negCount');
        asserterror TB.Replace('a', 'b', 5, 5);
        Observer.ObserveError('sumTooBig');
        TB.Replace('a', 'b', 7, 0);
        Observer.Observe('startPastLen', 'no error');
        asserterror TB.Replace('', 'b', 0, 2);
        Observer.Observe('emptyOld|text', GetLastErrorText());
        ClearLastError();
        TB.Replace('a', 'b', 6, 0);
        Observer.Observe('startAtLen', TB.ToText());
        Observer.Expect('negStart|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('negStart|code', 'ArgumentOutOfRange');
        Observer.Expect('negCount|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('negCount|code', 'ArgumentOutOfRange');
        Observer.Expect('sumTooBig|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('sumTooBig|code', 'ArgumentOutOfRange');
        Observer.Expect('startPastLen', 'no error');
        Observer.Expect('emptyOld|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('startAtLen', 'abcdef');
        Observer.Verify();
    end;
}

codeunit 71013 "LT TxC TB ToText"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ToText_Overloads()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Append('0123456789');
        Observer.Observe('full', TB.ToText());
        Observer.Observe('from3', TB.ToText(3, 4));
        Observer.Observe('from0', TB.ToText(0, 10));
        Observer.Observe('zeroLen', TB.ToText(5, 0));
        Observer.Observe('last', TB.ToText(9, 1));
        Observer.Observe('endEmpty', TB.ToText(10, 0));
        Observer.Expect('full', '0123456789');
        Observer.Expect('from3', '2345');
        Observer.Expect('from0', '0123456789');
        Observer.Expect('zeroLen', '');
        Observer.Expect('last', '8');
        Observer.Expect('endEmpty', '');
        Observer.Verify();
    end;

    [Test]
    procedure ToText_Errors()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        T: Text;
    begin
        TB.Append('0123456789');
        T := TB.ToText(-1, 2);
        Observer.Observe('negStart', 'no error');
        T := TB.ToText(0, -1);
        Observer.Observe('negLen', 'no error');
        T := TB.ToText(0, 11);
        Observer.Observe('lenTooBig', 'no error');
        T := TB.ToText(8, 3);
        Observer.Observe('sumTooBig', 'no error');
        T := TB.ToText(11, 0);
        Observer.Observe('startPast', 'no error');
        T := TB.ToText(10, 1);
        Observer.Observe('startAtEnd', 'no error');
        Observer.Expect('negStart', 'no error');
        Observer.Expect('negLen', 'no error');
        Observer.Expect('lenTooBig', 'no error');
        Observer.Expect('sumTooBig', 'no error');
        Observer.Expect('startPast', 'no error');
        Observer.Expect('startAtEnd', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure ToText_EmptyBuilder()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        T: Text;
    begin
        Observer.Observe('zero', TB.ToText(0, 0));
        T := TB.ToText(0, 1);
        Observer.Observe('oneFromEmpty', 'no error');
        T := TB.ToText(1, 0);
        Observer.Observe('startOne', 'no error');
        Observer.Observe('isEmpty', Format(TB.ToText() = ''));
        Observer.Expect('zero', '');
        Observer.Expect('oneFromEmpty', 'no error');
        Observer.Expect('startOne', 'no error');
        Observer.Expect('isEmpty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToText_IsSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        Snap: Text;
    begin
        TB.Append('abc');
        Snap := TB.ToText();
        TB.Append('def');
        Observer.Observe('snap', Snap);
        Observer.Observe('now', TB.ToText());
        Observer.Expect('snap', 'abc');
        Observer.Expect('now', 'abcdef');
        Observer.Verify();
    end;
}

codeunit 71014 "LT TxC TB Reference"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ByValue(TB: TextBuilder)
    begin
        TB.Append('[value]');
    end;

    local procedure ByVar(var TB: TextBuilder)
    begin
        TB.Append('[var]');
    end;

    local procedure Reassign(var TB: TextBuilder)
    var
        Other: TextBuilder;
    begin
        Other.Append('other');
        TB := Other;
    end;

    local procedure ReassignValue(TB: TextBuilder)
    var
        Other: TextBuilder;
    begin
        Other.Append('other');
        TB := Other;
    end;

    local procedure ClearIt(TB: TextBuilder)
    begin
        TB.Clear();
    end;

    [Test]
    procedure ByValue_SharesInstance()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Append('start');
        ByValue(TB);
        Observer.Observe('afterValue', TB.ToText());
        ByVar(TB);
        Observer.Observe('afterVar', TB.ToText());
        ClearIt(TB);
        Observer.Observe('afterClearByValue', TB.ToText());
        Observer.Expect('afterValue', 'start[value]');
        Observer.Expect('afterVar', 'start[value][var]');
        Observer.Expect('afterClearByValue', '');
        Observer.Verify();
    end;

    [Test]
    procedure Assignment_Semantics()
    var
        Observer: Codeunit "Probe Observer";
        A: TextBuilder;
        B: TextBuilder;
    begin
        A.Append('a');
        B := A;
        B.Append('b');
        Observer.Observe('a', A.ToText());
        Observer.Observe('b', B.ToText());
        A.Clear();
        Observer.Observe('bAfterClearA', B.ToText());
        Observer.Expect('a', 'ab');
        Observer.Expect('b', 'ab');
        Observer.Expect('bAfterClearA', '');
        Observer.Verify();
    end;

    [Test]
    procedure Reassign_Param()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Append('orig');
        ReassignValue(TB);
        Observer.Observe('afterValueReassign', TB.ToText());
        Reassign(TB);
        Observer.Observe('afterVarReassign', TB.ToText());
        Observer.Expect('afterValueReassign', 'orig');
        Observer.Expect('afterVarReassign', 'other');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_Variable()
    var
        Observer: Codeunit "Probe Observer";
        A: TextBuilder;
        B: TextBuilder;
    begin
        A.Append('abc');
        B := A;
        Clear(A);
        Observer.Observe('a', A.ToText());
        Observer.Observe('b', B.ToText());
        Observer.Expect('a', '');
        Observer.Expect('b', 'abc');
        Observer.Verify();
    end;

    [Test]
    procedure Uninitialized_Usable()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        Observer.Observe('len', Format(TB.Length()));
        TB.AppendLine();
        Observer.Observe('len2', Format(TB.Length()));
        Observer.Expect('len', '0');
        Observer.Expect('len2', '2');
        Observer.Verify();
    end;
}

codeunit 71015 "LT TxC TB MaxCap"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure MaxCapacity_Value()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        Observer.Observe('max', Format(TB.MaxCapacity()));
        Observer.Observe('maxIsMaxInt', Format(TB.MaxCapacity() = 2147483647));
        Observer.Expect('max', '2147483647');
        Observer.Expect('maxIsMaxInt', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Capacity_Large()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Capacity(1000000);
        Observer.Observe('cap', Format(TB.Capacity()));
        Observer.Observe('len', Format(TB.Length()));
        Observer.Expect('cap', '1000000');
        Observer.Expect('len', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Length_Larger_Than_Capacity()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Length(100);
        Observer.Observe('len', Format(TB.Length()));
        Observer.Observe('capGE', Format(TB.Capacity() >= 100));
        Observer.Expect('len', '100');
        Observer.Expect('capGE', 'Yes');
        Observer.Verify();
    end;
}

codeunit 71016 "LT TxC TB Text Interop"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TakesText(T: Text): Integer
    begin
        exit(StrLen(T));
    end;

    [Test]
    procedure BuildAndUse()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        Txt: Text;
        Cde: Code[20];
        Parts: List of [Text];
        P: Text;
    begin
        TB.Append('a,b,c');
        Observer.Observe('strlen', Format(TakesText(TB.ToText())));
        Txt := TB.ToText();
        Observer.Observe('split', Format(Txt.Split(',').Count()));
        Cde := CopyStr(TB.ToText(), 1, 20);
        Observer.Observe('code', Cde);
        Observer.Observe('format', Format(TB.Length()));
        Observer.Observe('strsubstno', StrSubstNo('<%1>', TB.ToText()));
        Observer.Observe('upper', TB.ToText().ToUpper());
        TB.Clear();
        foreach P in Txt.Split(',') do
            TB.Append(P.ToUpper());
        Observer.Observe('joined', TB.ToText());
        Observer.Expect('strlen', '5');
        Observer.Expect('split', '3');
        Observer.Expect('code', 'A,B,C');
        Observer.Expect('format', '5');
        Observer.Expect('strsubstno', '<a,b,c>');
        Observer.Expect('upper', 'A,B,C');
        Observer.Expect('joined', 'ABC');
        Observer.Verify();
    end;

    [Test]
    procedure Codeunit_Passing_Large()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        I: Integer;
        Txt: Text[30];
    begin
        for I := 1 to 50 do
            TB.Append('ab');
        Observer.Observe('len', Format(TB.Length()));
        asserterror Txt := TB.ToText();
        Observer.ObserveError('toText30');
        Txt := CopyStr(TB.ToText(), 1, 30);
        Observer.Observe('copy', Txt);
        Observer.Expect('len', '100');
        Observer.Expect('toText30|text', 'The length of the string is 100, but it must be less than or equal to 30 characters. Value: abababababababababababababababababababababababababababababababababababababababababababababababababab');
        Observer.Expect('toText30|code', 'StringLengthExceeded');
        Observer.Expect('copy', 'ababababababababababababababab');
        Observer.Verify();
    end;
}
