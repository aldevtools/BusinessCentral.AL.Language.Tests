// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained test codeunit 69371
// Facts: the 20 text methods (Contains, EndsWith, IndexOf, IndexOfAny with a list of Char and with a Text, LastIndexOf, PadLeft, PadRight, Remove, Replace, Split with Text, with a list of Char and with a list of Text,
// StartsWith, Substring, ToLower, ToUpper, Trim, TrimEnd, TrimStart) called on a TextConst variable and, for each case, on a Text variable that holds the same text. Every case is observed twice, as "tc <case>" and
// "text <case>", and the two values are the same; the error cases pin the error text.
// BC versions: 27.0 and later

codeunit 69371 "LT T TextConst Methods"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        TcHello: TextConst ENU = 'Hello World Hello';
        TcSep: TextConst ENU = 'a,b;c d,,e';
        TcMixed: TextConst ENU = 'MiXed Case 123 ÄÖ';
        TcPad: TextConst ENU = '  padded  ';
        TcChars: TextConst ENU = 'xxabcxx';
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];

    local procedure Join(Parts: List of [Text]): Text
    var
        Part: Text;
        Result: Text;
    begin
        foreach Part in Parts do
            Result += '|' + Part;
        exit(Format(Parts.Count()) + Result);
    end;

    [Test]
    procedure TextConst_Contains()
    var
        Ok: Boolean;
    begin
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        T := TcHello;
        Observer.Observe('tc true', Format(TcHello.Contains('World')));
        Observer.Observe('text true', Format(T.Contains('World')));
        Observer.Observe('tc false', Format(TcHello.Contains('xyz')));
        Observer.Observe('text false', Format(T.Contains('xyz')));
        Observer.Observe('tc different case', Format(TcHello.Contains('world')));
        Observer.Observe('text different case', Format(T.Contains('world')));
        Observer.Observe('tc empty value', Format(TcHello.Contains('')));
        Observer.Observe('text empty value', Format(T.Contains('')));
        Observer.Observe('tc whole text', Format(TcHello.Contains('Hello World Hello')));
        Observer.Observe('text whole text', Format(T.Contains('Hello World Hello')));
        Observer.Expect('tc true', 'Yes');
        Observer.Expect('text true', 'Yes');
        Observer.Expect('tc false', 'No');
        Observer.Expect('text false', 'No');
        Observer.Expect('tc different case', 'No');
        Observer.Expect('text different case', 'No');
        Observer.Expect('tc empty value', 'Yes');
        Observer.Expect('text empty value', 'Yes');
        Observer.Expect('tc whole text', 'Yes');
        Observer.Expect('text whole text', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_EndsWith()
    var
        Ok: Boolean;
    begin
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        T := TcHello;
        Observer.Observe('tc true', Format(TcHello.EndsWith('Hello')));
        Observer.Observe('text true', Format(T.EndsWith('Hello')));
        Observer.Observe('tc false', Format(TcHello.EndsWith('World')));
        Observer.Observe('text false', Format(T.EndsWith('World')));
        Observer.Observe('tc different case', Format(TcHello.EndsWith('hello')));
        Observer.Observe('text different case', Format(T.EndsWith('hello')));
        Observer.Observe('tc empty value', Format(TcHello.EndsWith('')));
        Observer.Observe('text empty value', Format(T.EndsWith('')));
        Observer.Expect('tc true', 'Yes');
        Observer.Expect('text true', 'Yes');
        Observer.Expect('tc false', 'No');
        Observer.Expect('text false', 'No');
        Observer.Expect('tc different case', 'No');
        Observer.Expect('text different case', 'No');
        Observer.Expect('tc empty value', 'Yes');
        Observer.Expect('text empty value', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_IndexOf()
    var
        Ok: Boolean;
    begin
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        T := TcHello;
        Observer.Observe('tc found', Format(TcHello.IndexOf('o')));
        Observer.Observe('text found', Format(T.IndexOf('o')));
        Observer.Observe('tc found from 6', Format(TcHello.IndexOf('o', 6)));
        Observer.Observe('text found from 6', Format(T.IndexOf('o', 6)));
        Observer.Observe('tc found text from 2', Format(TcHello.IndexOf('Hello', 2)));
        Observer.Observe('text found text from 2', Format(T.IndexOf('Hello', 2)));
        Observer.Observe('tc missing', Format(TcHello.IndexOf('zzz')));
        Observer.Observe('text missing', Format(T.IndexOf('zzz')));
        Observer.Observe('tc missing from 3', Format(TcHello.IndexOf('zzz', 3)));
        Observer.Observe('text missing from 3', Format(T.IndexOf('zzz', 3)));
        Observer.Observe('tc different case', Format(TcHello.IndexOf('world')));
        Observer.Observe('text different case', Format(T.IndexOf('world')));
        Observer.Observe('tc empty value', Format(TcHello.IndexOf('')));
        Observer.Observe('text empty value', Format(T.IndexOf('')));
        Ok := Try1();
        Observer.Observe('tc start 0', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try2();
        Observer.Observe('text start 0', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try3();
        Observer.Observe('tc start past end', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try4();
        Observer.Observe('text start past end', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Observer.Expect('tc found', '5');
        Observer.Expect('text found', '5');
        Observer.Expect('tc found from 6', '8');
        Observer.Expect('text found from 6', '8');
        Observer.Expect('tc found text from 2', '13');
        Observer.Expect('text found text from 2', '13');
        Observer.Expect('tc missing', '0');
        Observer.Expect('text missing', '0');
        Observer.Expect('tc missing from 3', '0');
        Observer.Expect('text missing from 3', '0');
        Observer.Expect('tc different case', '0');
        Observer.Expect('text different case', '0');
        Observer.Expect('tc empty value', '1');
        Observer.Expect('text empty value', '1');
        Observer.Expect('tc start 0', 'No|Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Observer.Expect('text start 0', 'No|Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Observer.Expect('tc start past end', 'No|Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Observer.Expect('text start past end', 'No|Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_IndexOfAnyChars()
    var
        Ok: Boolean;
    begin
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        C.Add('W'); C.Add('o');
        D.Add('z'); D.Add('q');
        T := TcHello;
        Observer.Observe('tc found', Format(TcHello.IndexOfAny(C)));
        Observer.Observe('text found', Format(T.IndexOfAny(C)));
        Observer.Observe('tc found from 6', Format(TcHello.IndexOfAny(C, 6)));
        Observer.Observe('text found from 6', Format(T.IndexOfAny(C, 6)));
        Observer.Observe('tc missing', Format(TcHello.IndexOfAny(D)));
        Observer.Observe('text missing', Format(T.IndexOfAny(D)));
        Observer.Observe('tc missing from 3', Format(TcHello.IndexOfAny(D, 3)));
        Observer.Observe('text missing from 3', Format(T.IndexOfAny(D, 3)));
        Observer.Expect('tc found', '5');
        Observer.Expect('text found', '5');
        Observer.Expect('tc found from 6', '7');
        Observer.Expect('text found from 6', '7');
        Observer.Expect('tc missing', '0');
        Observer.Expect('text missing', '0');
        Observer.Expect('tc missing from 3', '0');
        Observer.Expect('text missing from 3', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_IndexOfAnyText()
    var
        Ok: Boolean;
    begin
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        T := TcHello;
        Observer.Observe('tc found', Format(TcHello.IndexOfAny('Wo')));
        Observer.Observe('text found', Format(T.IndexOfAny('Wo')));
        Observer.Observe('tc found from 6', Format(TcHello.IndexOfAny('Wo', 6)));
        Observer.Observe('text found from 6', Format(T.IndexOfAny('Wo', 6)));
        Observer.Observe('tc missing', Format(TcHello.IndexOfAny('zq')));
        Observer.Observe('text missing', Format(T.IndexOfAny('zq')));
        Observer.Observe('tc missing from 3', Format(TcHello.IndexOfAny('zq', 3)));
        Observer.Observe('text missing from 3', Format(T.IndexOfAny('zq', 3)));
        Observer.Expect('tc found', '5');
        Observer.Expect('text found', '5');
        Observer.Expect('tc found from 6', '7');
        Observer.Expect('text found from 6', '7');
        Observer.Expect('tc missing', '0');
        Observer.Expect('text missing', '0');
        Observer.Expect('tc missing from 3', '0');
        Observer.Expect('text missing from 3', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_LastIndexOf()
    var
        Ok: Boolean;
    begin
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        T := TcHello;
        Observer.Observe('tc found', Format(TcHello.LastIndexOf('o')));
        Observer.Observe('text found', Format(T.LastIndexOf('o')));
        Observer.Observe('tc found with start 17', Format(TcHello.LastIndexOf('o', 17)));
        Observer.Observe('text found with start 17', Format(T.LastIndexOf('o', 17)));
        Observer.Observe('tc found with start 10', Format(TcHello.LastIndexOf('o', 10)));
        Observer.Observe('text found with start 10', Format(T.LastIndexOf('o', 10)));
        Observer.Observe('tc found text', Format(TcHello.LastIndexOf('Hello')));
        Observer.Observe('text found text', Format(T.LastIndexOf('Hello')));
        Observer.Observe('tc missing', Format(TcHello.LastIndexOf('zzz')));
        Observer.Observe('text missing', Format(T.LastIndexOf('zzz')));
        Observer.Observe('tc missing with start 5', Format(TcHello.LastIndexOf('zzz', 5)));
        Observer.Observe('text missing with start 5', Format(T.LastIndexOf('zzz', 5)));
        Ok := Try5();
        Observer.Observe('tc start 0', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try6();
        Observer.Observe('text start 0', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try7();
        Observer.Observe('tc start past end', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try8();
        Observer.Observe('text start past end', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Observer.Expect('tc found', '17');
        Observer.Expect('text found', '17');
        Observer.Expect('tc found with start 17', '17');
        Observer.Expect('text found with start 17', '17');
        Observer.Expect('tc found with start 10', '8');
        Observer.Expect('text found with start 10', '8');
        Observer.Expect('tc found text', '13');
        Observer.Expect('text found text', '13');
        Observer.Expect('tc missing', '0');
        Observer.Expect('text missing', '0');
        Observer.Expect('tc missing with start 5', '0');
        Observer.Expect('text missing with start 5', '0');
        Observer.Expect('tc start 0', 'No|Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Observer.Expect('text start 0', 'No|Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Observer.Expect('tc start past end', 'No|Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Observer.Expect('text start past end', 'No|Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_PadLeft()
    var
        Ok: Boolean;
    begin
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        T := TcHello;
        Observer.Observe('tc default char', TcHello.PadLeft(20));
        Observer.Observe('text default char', T.PadLeft(20));
        Observer.Observe('tc given char', TcHello.PadLeft(20, '*'));
        Observer.Observe('text given char', T.PadLeft(20, '*'));
        Observer.Observe('tc shorter count', TcHello.PadLeft(3));
        Observer.Observe('text shorter count', T.PadLeft(3));
        Observer.Observe('tc same count', TcHello.PadLeft(17, '*'));
        Observer.Observe('text same count', T.PadLeft(17, '*'));
        Observer.Observe('tc count 0', TcHello.PadLeft(0));
        Observer.Observe('text count 0', T.PadLeft(0));
        Ok := Try9();
        Observer.Observe('tc negative count', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try10();
        Observer.Observe('text negative count', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Observer.Expect('tc default char', '   Hello World Hello');
        Observer.Expect('text default char', '   Hello World Hello');
        Observer.Expect('tc given char', '***Hello World Hello');
        Observer.Expect('text given char', '***Hello World Hello');
        Observer.Expect('tc shorter count', 'Hello World Hello');
        Observer.Expect('text shorter count', 'Hello World Hello');
        Observer.Expect('tc same count', 'Hello World Hello');
        Observer.Expect('text same count', 'Hello World Hello');
        Observer.Expect('tc count 0', 'Hello World Hello');
        Observer.Expect('text count 0', 'Hello World Hello');
        Observer.Expect('tc negative count', 'No|totalWidth (''-1'') must be a non-negative value. (Parameter ''totalWidth'')\Actual value was -1.|ArgumentOutOfRange');
        Observer.Expect('text negative count', 'No|totalWidth (''-1'') must be a non-negative value. (Parameter ''totalWidth'')\Actual value was -1.|ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_PadRight()
    var
        Ok: Boolean;
    begin
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        T := TcHello;
        Observer.Observe('tc default char', TcHello.PadRight(20));
        Observer.Observe('text default char', T.PadRight(20));
        Observer.Observe('tc given char', TcHello.PadRight(20, '*'));
        Observer.Observe('text given char', T.PadRight(20, '*'));
        Observer.Observe('tc shorter count', TcHello.PadRight(3));
        Observer.Observe('text shorter count', T.PadRight(3));
        Observer.Observe('tc same count', TcHello.PadRight(17, '*'));
        Observer.Observe('text same count', T.PadRight(17, '*'));
        Observer.Observe('tc count 0', TcHello.PadRight(0));
        Observer.Observe('text count 0', T.PadRight(0));
        Ok := Try11();
        Observer.Observe('tc negative count', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try12();
        Observer.Observe('text negative count', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Observer.Expect('tc default char', 'Hello World Hello   ');
        Observer.Expect('text default char', 'Hello World Hello   ');
        Observer.Expect('tc given char', 'Hello World Hello***');
        Observer.Expect('text given char', 'Hello World Hello***');
        Observer.Expect('tc shorter count', 'Hello World Hello');
        Observer.Expect('text shorter count', 'Hello World Hello');
        Observer.Expect('tc same count', 'Hello World Hello');
        Observer.Expect('text same count', 'Hello World Hello');
        Observer.Expect('tc count 0', 'Hello World Hello');
        Observer.Expect('text count 0', 'Hello World Hello');
        Observer.Expect('tc negative count', 'No|totalWidth (''-1'') must be a non-negative value. (Parameter ''totalWidth'')\Actual value was -1.|ArgumentOutOfRange');
        Observer.Expect('text negative count', 'No|totalWidth (''-1'') must be a non-negative value. (Parameter ''totalWidth'')\Actual value was -1.|ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_Remove()
    var
        Ok: Boolean;
    begin
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        T := TcHello;
        Observer.Observe('tc from 7', TcHello.Remove(7));
        Observer.Observe('text from 7', T.Remove(7));
        Observer.Observe('tc from 7 count 6', TcHello.Remove(7, 6));
        Observer.Observe('text from 7 count 6', T.Remove(7, 6));
        Observer.Observe('tc from 1 count 0', TcHello.Remove(1, 0));
        Observer.Observe('text from 1 count 0', T.Remove(1, 0));
        Observer.Observe('tc last char', TcHello.Remove(17, 1));
        Observer.Observe('text last char', T.Remove(17, 1));
        Ok := Try13();
        Observer.Observe('tc start 0', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try14();
        Observer.Observe('text start 0', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try15();
        Observer.Observe('tc start past end', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try16();
        Observer.Observe('text start past end', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try17();
        Observer.Observe('tc start after end', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try18();
        Observer.Observe('text start after end', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try19();
        Observer.Observe('tc count past end', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try20();
        Observer.Observe('text count past end', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try21();
        Observer.Observe('tc negative count', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try22();
        Observer.Observe('text negative count', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Observer.Expect('tc from 7', 'Hello ');
        Observer.Expect('text from 7', 'Hello ');
        Observer.Expect('tc from 7 count 6', 'Hello Hello');
        Observer.Expect('text from 7 count 6', 'Hello Hello');
        Observer.Expect('tc from 1 count 0', 'Hello World Hello');
        Observer.Expect('text from 1 count 0', 'Hello World Hello');
        Observer.Expect('tc last char', 'Hello World Hell');
        Observer.Expect('text last char', 'Hello World Hell');
        Observer.Expect('tc start 0', 'No|StartIndex cannot be less than 1. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Observer.Expect('text start 0', 'No|StartIndex cannot be less than 1. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Observer.Expect('tc start past end', 'No|startIndex cannot be larger than length of string. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Observer.Expect('text start past end', 'No|startIndex cannot be larger than length of string. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Observer.Expect('tc start after end', 'Yes||');
        Observer.Expect('text start after end', 'Yes||');
        Observer.Expect('tc count past end', 'No|count (''100'') must be less than or equal to ''11''. (Parameter ''count'')\Actual value was 100.|ArgumentOutOfRange');
        Observer.Expect('text count past end', 'No|count (''100'') must be less than or equal to ''11''. (Parameter ''count'')\Actual value was 100.|ArgumentOutOfRange');
        Observer.Expect('tc negative count', 'No|count (''-1'') must be a non-negative value. (Parameter ''count'')\Actual value was -1.|ArgumentOutOfRange');
        Observer.Expect('text negative count', 'No|count (''-1'') must be a non-negative value. (Parameter ''count'')\Actual value was -1.|ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_Replace()
    var
        Ok: Boolean;
    begin
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        T := TcHello;
        Observer.Observe('tc single match', TcHello.Replace('World', 'There'));
        Observer.Observe('text single match', T.Replace('World', 'There'));
        Observer.Observe('tc repeated match', TcHello.Replace('Hello', 'Bye'));
        Observer.Observe('text repeated match', T.Replace('Hello', 'Bye'));
        Observer.Observe('tc missing', TcHello.Replace('zzz', 'Bye'));
        Observer.Observe('text missing', T.Replace('zzz', 'Bye'));
        Observer.Observe('tc remove by empty', TcHello.Replace('o', ''));
        Observer.Observe('text remove by empty', T.Replace('o', ''));
        Observer.Observe('tc different case', TcHello.Replace('hello', 'Bye'));
        Observer.Observe('text different case', T.Replace('hello', 'Bye'));
        Ok := Try23();
        Observer.Observe('tc empty old value', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try24();
        Observer.Observe('text empty old value', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Observer.Expect('tc single match', 'Hello There Hello');
        Observer.Expect('text single match', 'Hello There Hello');
        Observer.Expect('tc repeated match', 'Bye World Bye');
        Observer.Expect('text repeated match', 'Bye World Bye');
        Observer.Expect('tc missing', 'Hello World Hello');
        Observer.Expect('text missing', 'Hello World Hello');
        Observer.Expect('tc remove by empty', 'Hell Wrld Hell');
        Observer.Expect('text remove by empty', 'Hell Wrld Hell');
        Observer.Expect('tc different case', 'Hello World Hello');
        Observer.Expect('text different case', 'Hello World Hello');
        Observer.Expect('tc empty old value', 'No|The value cannot be an empty string. (Parameter ''oldValue'')|Argument');
        Observer.Expect('text empty old value', 'No|The value cannot be an empty string. (Parameter ''oldValue'')|Argument');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_SplitText()
    var
        Ok: Boolean;
    begin
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        T := TcSep;
        Observer.Observe('tc default', Join(TcSep.Split()));
        Observer.Observe('text default', Join(T.Split()));
        Observer.Observe('tc comma', Join(TcSep.Split(',')));
        Observer.Observe('text comma', Join(T.Split(',')));
        Observer.Observe('tc comma and semicolon', Join(TcSep.Split(',', ';')));
        Observer.Observe('text comma and semicolon', Join(T.Split(',', ';')));
        Observer.Observe('tc space', Join(TcSep.Split(' ')));
        Observer.Observe('text space', Join(T.Split(' ')));
        Observer.Observe('tc missing separator', Join(TcSep.Split('#')));
        Observer.Observe('text missing separator', Join(T.Split('#')));
        Observer.Observe('tc empty separator', Join(TcSep.Split('')));
        Observer.Observe('text empty separator', Join(T.Split('')));
        Observer.Expect('tc default', '2|a,b;c|d,,e');
        Observer.Expect('text default', '2|a,b;c|d,,e');
        Observer.Expect('tc comma', '4|a|b;c d||e');
        Observer.Expect('text comma', '4|a|b;c d||e');
        Observer.Expect('tc comma and semicolon', '5|a|b|c d||e');
        Observer.Expect('text comma and semicolon', '5|a|b|c d||e');
        Observer.Expect('tc space', '2|a,b;c|d,,e');
        Observer.Expect('text space', '2|a,b;c|d,,e');
        Observer.Expect('tc missing separator', '1|a,b;c d,,e');
        Observer.Expect('text missing separator', '1|a,b;c d,,e');
        Observer.Expect('tc empty separator', '1|a,b;c d,,e');
        Observer.Expect('text empty separator', '1|a,b;c d,,e');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_SplitChars()
    var
        Ok: Boolean;
    begin
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        C.Add(','); C.Add(';');
        D.Add('#');
        T := TcSep;
        Observer.Observe('tc comma and semicolon', Join(TcSep.Split(C)));
        Observer.Observe('text comma and semicolon', Join(T.Split(C)));
        Observer.Observe('tc missing', Join(TcSep.Split(D)));
        Observer.Observe('text missing', Join(T.Split(D)));
        Observer.Expect('tc comma and semicolon', '5|a|b|c d||e');
        Observer.Expect('text comma and semicolon', '5|a|b|c d||e');
        Observer.Expect('tc missing', '1|a,b;c d,,e');
        Observer.Expect('text missing', '1|a,b;c d,,e');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_SplitTexts()
    var
        Ok: Boolean;
    begin
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        L.Add(',,'); L.Add(';');
        M.Add('#');
        T := TcSep;
        Observer.Observe('tc two texts', Join(TcSep.Split(L)));
        Observer.Observe('text two texts', Join(T.Split(L)));
        Observer.Observe('tc missing', Join(TcSep.Split(M)));
        Observer.Observe('text missing', Join(T.Split(M)));
        Observer.Expect('tc two texts', '3|a,b|c d|e');
        Observer.Expect('text two texts', '3|a,b|c d|e');
        Observer.Expect('tc missing', '1|a,b;c d,,e');
        Observer.Expect('text missing', '1|a,b;c d,,e');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_StartsWith()
    var
        Ok: Boolean;
    begin
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        T := TcHello;
        Observer.Observe('tc true', Format(TcHello.StartsWith('Hello')));
        Observer.Observe('text true', Format(T.StartsWith('Hello')));
        Observer.Observe('tc false', Format(TcHello.StartsWith('World')));
        Observer.Observe('text false', Format(T.StartsWith('World')));
        Observer.Observe('tc different case', Format(TcHello.StartsWith('hello')));
        Observer.Observe('text different case', Format(T.StartsWith('hello')));
        Observer.Observe('tc empty value', Format(TcHello.StartsWith('')));
        Observer.Observe('text empty value', Format(T.StartsWith('')));
        Observer.Expect('tc true', 'Yes');
        Observer.Expect('text true', 'Yes');
        Observer.Expect('tc false', 'No');
        Observer.Expect('text false', 'No');
        Observer.Expect('tc different case', 'No');
        Observer.Expect('text different case', 'No');
        Observer.Expect('tc empty value', 'Yes');
        Observer.Expect('text empty value', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_Substring()
    var
        Ok: Boolean;
    begin
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        T := TcHello;
        Observer.Observe('tc from 7', TcHello.Substring(7));
        Observer.Observe('text from 7', T.Substring(7));
        Observer.Observe('tc from 7 count 5', TcHello.Substring(7, 5));
        Observer.Observe('text from 7 count 5', T.Substring(7, 5));
        Observer.Observe('tc from 1 count 0', TcHello.Substring(1, 0));
        Observer.Observe('text from 1 count 0', T.Substring(1, 0));
        Observer.Observe('tc last char', TcHello.Substring(17, 1));
        Observer.Observe('text last char', T.Substring(17, 1));
        Ok := Try25();
        Observer.Observe('tc start 0', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try26();
        Observer.Observe('text start 0', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try27();
        Observer.Observe('tc start past end', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try28();
        Observer.Observe('text start past end', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try29();
        Observer.Observe('tc start after end', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try30();
        Observer.Observe('text start after end', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try31();
        Observer.Observe('tc count past end', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try32();
        Observer.Observe('text count past end', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try33();
        Observer.Observe('tc negative count', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := Try34();
        Observer.Observe('text negative count', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Observer.Expect('tc from 7', 'World Hello');
        Observer.Expect('text from 7', 'World Hello');
        Observer.Expect('tc from 7 count 5', 'World');
        Observer.Expect('text from 7 count 5', 'World');
        Observer.Expect('tc from 1 count 0', '');
        Observer.Expect('text from 1 count 0', '');
        Observer.Expect('tc last char', 'o');
        Observer.Expect('text last char', 'o');
        Observer.Expect('tc start 0', 'No|startIndex (''-1'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -1.|ArgumentOutOfRange');
        Observer.Expect('text start 0', 'No|startIndex (''-1'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -1.|ArgumentOutOfRange');
        Observer.Expect('tc start past end', 'No|startIndex cannot be larger than length of string. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Observer.Expect('text start past end', 'No|startIndex cannot be larger than length of string. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Observer.Expect('tc start after end', 'Yes||');
        Observer.Expect('text start after end', 'Yes||');
        Observer.Expect('tc count past end', 'Yes||');
        Observer.Expect('text count past end', 'Yes||');
        Observer.Expect('tc negative count', 'No|length (''-1'') must be a non-negative value. (Parameter ''length'')\Actual value was -1.|ArgumentOutOfRange');
        Observer.Expect('text negative count', 'No|length (''-1'') must be a non-negative value. (Parameter ''length'')\Actual value was -1.|ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_ToLower()
    var
        Ok: Boolean;
    begin
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        T := TcMixed;
        Observer.Observe('tc mixed', TcMixed.ToLower());
        Observer.Observe('text mixed', T.ToLower());
        Observer.Expect('tc mixed', 'mixed case 123 äö');
        Observer.Expect('text mixed', 'mixed case 123 äö');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_ToUpper()
    var
        Ok: Boolean;
    begin
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        T := TcMixed;
        Observer.Observe('tc mixed', TcMixed.ToUpper());
        Observer.Observe('text mixed', T.ToUpper());
        Observer.Expect('tc mixed', 'MIXED CASE 123 ÄÖ');
        Observer.Expect('text mixed', 'MIXED CASE 123 ÄÖ');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_Trim()
    var
        Ok: Boolean;
    begin
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        T := TcPad;
        Observer.Observe('tc spaces both sides', '[' + TcPad.Trim() + ']');
        Observer.Observe('text spaces both sides', '[' + T.Trim() + ']');
        Observer.Expect('tc spaces both sides', '[padded]');
        Observer.Expect('text spaces both sides', '[padded]');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_TrimEnd()
    var
        Ok: Boolean;
    begin
        T3 := TcPad;
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        T := TcChars;
        Observer.Observe('tc default', '[' + TcChars.TrimEnd() + ']');
        Observer.Observe('text default', '[' + T.TrimEnd() + ']');
        Observer.Observe('tc given chars', '[' + TcChars.TrimEnd('x') + ']');
        Observer.Observe('text given chars', '[' + T.TrimEnd('x') + ']');
        Observer.Observe('tc several chars', '[' + TcChars.TrimEnd('cx') + ']');
        Observer.Observe('text several chars', '[' + T.TrimEnd('cx') + ']');
        Observer.Observe('tc char not at end', '[' + TcChars.TrimEnd('a') + ']');
        Observer.Observe('text char not at end', '[' + T.TrimEnd('a') + ']');
        Observer.Observe('tc padded default', '[' + TcPad.TrimEnd() + ']');
        Observer.Observe('text padded default', '[' + T3.TrimEnd() + ']');
        Observer.Expect('tc default', '[xxabcxx]');
        Observer.Expect('text default', '[xxabcxx]');
        Observer.Expect('tc given chars', '[xxabc]');
        Observer.Expect('text given chars', '[xxabc]');
        Observer.Expect('tc several chars', '[xxab]');
        Observer.Expect('text several chars', '[xxab]');
        Observer.Expect('tc char not at end', '[xxabcxx]');
        Observer.Expect('text char not at end', '[xxabcxx]');
        Observer.Expect('tc padded default', '[  padded]');
        Observer.Expect('text padded default', '[  padded]');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_TrimStart()
    var
        Ok: Boolean;
    begin
        T3 := TcPad;
        Clear(C);
        Clear(D);
        Clear(L);
        Clear(M);
        T := TcChars;
        Observer.Observe('tc default', '[' + TcChars.TrimStart() + ']');
        Observer.Observe('text default', '[' + T.TrimStart() + ']');
        Observer.Observe('tc given chars', '[' + TcChars.TrimStart('x') + ']');
        Observer.Observe('text given chars', '[' + T.TrimStart('x') + ']');
        Observer.Observe('tc several chars', '[' + TcChars.TrimStart('ax') + ']');
        Observer.Observe('text several chars', '[' + T.TrimStart('ax') + ']');
        Observer.Observe('tc char not at start', '[' + TcChars.TrimStart('c') + ']');
        Observer.Observe('text char not at start', '[' + T.TrimStart('c') + ']');
        Observer.Observe('tc padded default', '[' + TcPad.TrimStart() + ']');
        Observer.Observe('text padded default', '[' + T3.TrimStart() + ']');
        Observer.Expect('tc default', '[xxabcxx]');
        Observer.Expect('text default', '[xxabcxx]');
        Observer.Expect('tc given chars', '[abcxx]');
        Observer.Expect('text given chars', '[abcxx]');
        Observer.Expect('tc several chars', '[bcxx]');
        Observer.Expect('text several chars', '[bcxx]');
        Observer.Expect('tc char not at start', '[xxabcxx]');
        Observer.Expect('text char not at start', '[xxabcxx]');
        Observer.Expect('tc padded default', '[padded  ]');
        Observer.Expect('text padded default', '[padded  ]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure Try1()
    begin
        I := TcHello.IndexOf('o', 0);
    end;

    [TryFunction]
    local procedure Try2()
    begin
        I := T.IndexOf('o', 0);
    end;

    [TryFunction]
    local procedure Try3()
    begin
        I := TcHello.IndexOf('o', 100);
    end;

    [TryFunction]
    local procedure Try4()
    begin
        I := T.IndexOf('o', 100);
    end;

    [TryFunction]
    local procedure Try5()
    begin
        I := TcHello.LastIndexOf('o', 0);
    end;

    [TryFunction]
    local procedure Try6()
    begin
        I := T.LastIndexOf('o', 0);
    end;

    [TryFunction]
    local procedure Try7()
    begin
        I := TcHello.LastIndexOf('o', 100);
    end;

    [TryFunction]
    local procedure Try8()
    begin
        I := T.LastIndexOf('o', 100);
    end;

    [TryFunction]
    local procedure Try9()
    begin
        T2 := TcHello.PadLeft(-1);
    end;

    [TryFunction]
    local procedure Try10()
    begin
        T2 := T.PadLeft(-1);
    end;

    [TryFunction]
    local procedure Try11()
    begin
        T2 := TcHello.PadRight(-1);
    end;

    [TryFunction]
    local procedure Try12()
    begin
        T2 := T.PadRight(-1);
    end;

    [TryFunction]
    local procedure Try13()
    begin
        T2 := TcHello.Remove(0);
    end;

    [TryFunction]
    local procedure Try14()
    begin
        T2 := T.Remove(0);
    end;

    [TryFunction]
    local procedure Try15()
    begin
        T2 := TcHello.Remove(100);
    end;

    [TryFunction]
    local procedure Try16()
    begin
        T2 := T.Remove(100);
    end;

    [TryFunction]
    local procedure Try17()
    begin
        T2 := TcHello.Remove(18);
    end;

    [TryFunction]
    local procedure Try18()
    begin
        T2 := T.Remove(18);
    end;

    [TryFunction]
    local procedure Try19()
    begin
        T2 := TcHello.Remove(7, 100);
    end;

    [TryFunction]
    local procedure Try20()
    begin
        T2 := T.Remove(7, 100);
    end;

    [TryFunction]
    local procedure Try21()
    begin
        T2 := TcHello.Remove(7, -1);
    end;

    [TryFunction]
    local procedure Try22()
    begin
        T2 := T.Remove(7, -1);
    end;

    [TryFunction]
    local procedure Try23()
    begin
        T2 := TcHello.Replace('', 'x');
    end;

    [TryFunction]
    local procedure Try24()
    begin
        T2 := T.Replace('', 'x');
    end;

    [TryFunction]
    local procedure Try25()
    begin
        T2 := TcHello.Substring(0);
    end;

    [TryFunction]
    local procedure Try26()
    begin
        T2 := T.Substring(0);
    end;

    [TryFunction]
    local procedure Try27()
    begin
        T2 := TcHello.Substring(100);
    end;

    [TryFunction]
    local procedure Try28()
    begin
        T2 := T.Substring(100);
    end;

    [TryFunction]
    local procedure Try29()
    begin
        T2 := TcHello.Substring(18);
    end;

    [TryFunction]
    local procedure Try30()
    begin
        T2 := T.Substring(18);
    end;

    [TryFunction]
    local procedure Try31()
    begin
        T2 := TcHello.Substring(7, 100);
    end;

    [TryFunction]
    local procedure Try32()
    begin
        T2 := T.Substring(7, 100);
    end;

    [TryFunction]
    local procedure Try33()
    begin
        T2 := TcHello.Substring(7, -1);
    end;

    [TryFunction]
    local procedure Try34()
    begin
        T2 := T.Substring(7, -1);
    end;
}
