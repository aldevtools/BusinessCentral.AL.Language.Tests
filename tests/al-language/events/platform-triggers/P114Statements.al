// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-control-statements
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained: table 70860, enum 70861, test codeunit 70862
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: statement and expression kinds that no corpus test reached: continue in while / repeat / for / foreach loops, the empty statement (";;", "if .. then;", an empty begin..end),
// unary prefix operators (-, +, not), binary operators (arithmetic, comparison, boolean, in, mod, div, text concatenation) and literals of every kind (Boolean, Integer,
// Decimal, Text with doubled quote, Code, Date, Time, DateTime zero values), exit in table triggers, case with ranges on Integer / Option / Enum.

table 70860 "LT P114 Stmt Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Mode; Option) { OptionMembers = Zero,One,Two,Three,Four; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    begin
        if Id = 99 then
            exit;
        Name := Name + '|inserted';
    end;

    trigger OnModify()
    begin
        if Name = '' then
            exit;
        Name := Name + '|modified';
    end;
}

enum 70861 "LT P114 Stmt Enum"
{
    Extensible = true;

    value(0; Low) { }
    value(1; Mid) { }
    value(5; High) { }
    value(10; Top) { }
}

codeunit 70862 "LT P114 Statements"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Classify(Value: Integer): Text
    begin
        case Value of
            -5 .. -1:
                exit('negative');
            0:
                exit('zero');
            1 .. 3:
                exit('small');
            4, 6, 8:
                exit('even-list');
            9 .. 100:
                exit('large');
            else
                exit('other');
        end;
    end;

    local procedure ClassifyEnum(Value: Enum "LT P114 Stmt Enum"): Text
    begin
        case Value of
            Value::Low:
                exit('low');
            Value::Mid, Value::High:
                exit('mid-or-high');
            else
                exit('else');
        end;
    end;

    local procedure ClassifyOption(Value: Option Zero,One,Two,Three,Four): Text
    begin
        case Value of
            Value::Zero:
                exit('zero');
            Value::One, Value::Two:
                exit('one-or-two');
        end;
        exit('fall-through');
    end;

    local procedure ClassifyText(Value: Text): Text
    begin
        case Value of
            'a', 'b':
                exit('ab');
            'C':
                exit('upper-c');
            '':
                exit('empty');
            else
                exit('other');
        end;
    end;

    [Test]
    procedure P114_ContinueInLoops()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        Sum: Integer;
        Seen: Text;
        Items: List of [Integer];
        Item: Integer;
    begin
        for I := 1 to 10 do begin
            if I mod 2 = 0 then
                continue;
            Sum += I;
        end;
        Observer.Observe('for-odd-sum', Format(Sum));

        I := 0;
        Sum := 0;
        while I < 10 do begin
            I += 1;
            if I = 5 then
                continue;
            Sum += I;
        end;
        Observer.Observe('while-skip-five', Format(Sum));

        I := 0;
        Seen := '';
        repeat
            I += 1;
            if I < 3 then
                continue;
            Seen += Format(I);
        until I >= 6;
        Observer.Observe('repeat-from-three', Seen);

        Items.Add(1);
        Items.Add(2);
        Items.Add(3);
        Items.Add(4);
        Seen := '';
        foreach Item in Items do begin
            if Item = 2 then
                continue;
            Seen += Format(Item);
        end;
        Observer.Observe('foreach-skip-two', Seen);

        Sum := 0;
        for I := 1 to 3 do begin
            if I = 2 then
                continue;
            Sum += I * 10;
        end;
        Observer.Observe('for-ends-with-continue', Format(Sum));

        Sum := 0;
        for I := 1 to 3 do
            continue;
        Observer.Observe('for-only-continue-last-i', Format(I));
        Observer.Expect('for-odd-sum', '25');
        Observer.Expect('while-skip-five', '50');
        Observer.Expect('repeat-from-three', '3456');
        Observer.Expect('foreach-skip-two', '134');
        Observer.Expect('for-ends-with-continue', '40');
        Observer.Expect('for-only-continue-last-i', '3');
        Observer.Verify();
    end;

    [Test]
    procedure P114_ContinueInNestedLoopsAndBreak()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        J: Integer;
        Pairs: Text;
    begin
        for I := 1 to 3 do begin
            for J := 1 to 3 do begin
                if J = 2 then
                    continue;
                if I = 3 then
                    break;
                Pairs += Format(I) + Format(J) + ' ';
            end;
            if I = 1 then
                continue;
            Pairs += '| ';
        end;
        Observer.Observe('pairs', Pairs);
        Observer.Expect('pairs', '11 13 21 23 | | ');
        Observer.Verify();
    end;

    [Test]
    procedure P114_EmptyStatements()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: Boolean;
    begin
        ;
        ;;
        I := 1;;
        if I = 1 then
            ;
        if I = 2 then
            I := 5
        else
            ;
        begin
        end;
        begin
            ;
        end;
        while false do
            ;
        for I := 1 to 3 do
            ;
        B := true;
        case I of
            4:
                ;
            else
                ;
        end;
        Observer.Observe('i-after', Format(I));
        Observer.Observe('b', Format(B));
        Observer.Expect('i-after', '3');
        Observer.Expect('b', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P114_PrefixOperators()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        D: Decimal;
        B: Boolean;
        Big: BigInteger;
        Dur: Duration;
    begin
        I := 5;
        D := 2.5;
        B := true;
        Big := 123456789;
        Big := Big * 1000;
        Dur := 1500;
        Observer.Observe('neg-int', Format(-I));
        Observer.Observe('neg-neg-int', Format(-(-I)));
        Observer.Observe('pos-int', Format(+I));
        Observer.Observe('neg-dec', Format(-D));
        Observer.Observe('pos-dec', Format(+D));
        Observer.Observe('neg-zero', Format(-0));
        Observer.Observe('neg-big', Format(-Big));
        Observer.Observe('neg-duration', Format(Dur * -1));
        Observer.Observe('not-true', Format(not B));
        Observer.Observe('not-not-true', Format(not not B));
        Observer.Observe('not-compare', Format(not (I = 5)));
        Observer.Observe('neg-in-sum', Format(3 + -I));
        Observer.Observe('neg-times-neg', Format(-I * -I));
        Observer.Observe('neg-literal', Format(-7));
        Observer.Observe('neg-decimal-literal', Format(-0.5));
        Observer.Observe('not-false-literal', Format(not false));
        Observer.Expect('neg-int', '-5');
        Observer.Expect('neg-neg-int', '5');
        Observer.Expect('pos-int', '5');
        Observer.Expect('neg-dec', '-2.5');
        Observer.Expect('pos-dec', '2.5');
        Observer.Expect('neg-zero', '0');
        Observer.Expect('neg-big', '-123456789000');
        Observer.Expect('neg-duration', '-1500');
        Observer.Expect('not-true', 'No');
        Observer.Expect('not-not-true', 'Yes');
        Observer.Expect('not-compare', 'No');
        Observer.Expect('neg-in-sum', '-2');
        Observer.Expect('neg-times-neg', '25');
        Observer.Expect('neg-literal', '-7');
        Observer.Expect('neg-decimal-literal', '-0.5');
        Observer.Expect('not-false-literal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P114_BinaryArithmetic()
    var
        Observer: Codeunit "Probe Observer";
        A: Integer;
        B: Integer;
        D: Decimal;
        T: Text;
    begin
        A := 17;
        B := 5;
        D := 7.5;
        Observer.Observe('add', Format(A + B));
        Observer.Observe('sub', Format(A - B));
        Observer.Observe('mul', Format(A * B));
        Observer.Observe('div-slash', Format(A / B));
        Observer.Observe('div-keyword', Format(A div B));
        Observer.Observe('mod', Format(A mod B));
        Observer.Observe('neg-mod', Format(-A mod B));
        Observer.Observe('neg-div', Format(-A div B));
        Observer.Observe('dec-mul', Format(D * 2));
        Observer.Observe('dec-div', Format(D / 2));
        Observer.Observe('precedence', Format(2 + 3 * 4));
        Observer.Observe('parens', Format((2 + 3) * 4));
        Observer.Observe('mixed-int-dec', Format(A + D));
        Observer.Observe('concat', 'a' + 'b' + Format(A));
        T := 'x';
        T := T + T + T;
        Observer.Observe('concat-var', T);
        Observer.Observe('power', Format(Power(2, 10)));
        Observer.Expect('add', '22');
        Observer.Expect('sub', '12');
        Observer.Expect('mul', '85');
        Observer.Expect('div-slash', '3.4');
        Observer.Expect('div-keyword', '3');
        Observer.Expect('mod', '2');
        Observer.Expect('neg-mod', '-2');
        Observer.Expect('neg-div', '-3');
        Observer.Expect('dec-mul', '15');
        Observer.Expect('dec-div', '3.75');
        Observer.Expect('precedence', '14');
        Observer.Expect('parens', '20');
        Observer.Expect('mixed-int-dec', '24.5');
        Observer.Expect('concat', 'ab17');
        Observer.Expect('concat-var', 'xxx');
        Observer.Expect('power', '1,024');
        Observer.Verify();
    end;

    [Test]
    procedure P114_BinaryComparisonAndLogic()
    var
        Observer: Codeunit "Probe Observer";
        A: Integer;
        T: Text;
        C: Code[10];
        Mode: Option Zero,One,Two;
    begin
        A := 3;
        T := 'abc';
        C := 'abc';
        Mode := Mode::One;
        Observer.Observe('eq', Format(A = 3));
        Observer.Observe('ne', Format(A <> 3));
        Observer.Observe('lt', Format(A < 4));
        Observer.Observe('le', Format(A <= 3));
        Observer.Observe('gt', Format(A > 3));
        Observer.Observe('ge', Format(A >= 3));
        Observer.Observe('text-eq-case', Format(T = 'ABC'));
        Observer.Observe('text-code-eq', Format(T = C));
        Observer.Observe('text-lt', Format('abc' < 'abd'));
        Observer.Observe('and', Format((A = 3) and (T = 'abc')));
        Observer.Observe('or', Format((A = 4) or (T = 'abc')));
        Observer.Observe('xor', Format((A = 3) xor (T = 'abc')));
        Observer.Observe('xor-diff', Format((A = 3) xor (T = 'x')));
        Observer.Observe('in-range', Format(A in [1 .. 5]));
        Observer.Observe('in-list', Format(A in [1, 2, 4]));
        Observer.Observe('in-text-set', Format(T in ['abc', 'def']));
        Observer.Observe('in-option', Format(Mode in [Mode::One, Mode::Two]));
        Observer.Observe('option-vs-literal', Format(Mode = 1));
        Observer.Observe('option-vs-text', Format(Mode = Mode::One));
        Observer.Observe('precedence-and-or', Format(true or false and false));
        Observer.Observe('not-precedence', Format(not true or true));
        Observer.Expect('eq', 'Yes');
        Observer.Expect('ne', 'No');
        Observer.Expect('lt', 'Yes');
        Observer.Expect('le', 'Yes');
        Observer.Expect('gt', 'No');
        Observer.Expect('ge', 'Yes');
        Observer.Expect('text-eq-case', 'No');
        Observer.Expect('text-code-eq', 'No');
        Observer.Expect('text-lt', 'Yes');
        Observer.Expect('and', 'Yes');
        Observer.Expect('or', 'Yes');
        Observer.Expect('xor', 'No');
        Observer.Expect('xor-diff', 'Yes');
        Observer.Expect('in-range', 'Yes');
        Observer.Expect('in-list', 'No');
        Observer.Expect('in-text-set', 'Yes');
        Observer.Expect('in-option', 'Yes');
        Observer.Expect('option-vs-literal', 'Yes');
        Observer.Expect('option-vs-text', 'Yes');
        Observer.Expect('precedence-and-or', 'Yes');
        Observer.Expect('not-precedence', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P114_Literals()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
        T: Time;
        DT: DateTime;
        C: Code[10];
        Dec: Decimal;
    begin
        Observer.Observe('true', Format(true));
        Observer.Observe('false', Format(false));
        Observer.Observe('int', Format(2147483647));
        Observer.Observe('int-leading-zeros', Format(007));
        Observer.Observe('dec', Format(1.5));
        Observer.Observe('dec-many-digits', Format(12.3456789012345678));
        Observer.Observe('dec-trailing-zero', Format(1.50));
        Observer.Observe('text', 'plain');
        Observer.Observe('text-empty-len', Format(StrLen('')));
        Observer.Observe('text-doubled-quote', 'it''s');
        Observer.Observe('text-unicode', 'äöü€');
        Observer.Observe('text-spaces-len', Format(StrLen('  a  ')));
        D := 0D;
        Observer.Observe('date-zero', Format(D));
        D := 20240315D;
        Observer.Observe('date-literal', Format(D, 0, 9));
        Observer.Observe('date-literal-day-of-week', Format(Date2DWY(20240315D, 1)));
        T := 0T;
        Observer.Observe('time-zero', Format(T));
        T := 123456T;
        Observer.Observe('time-literal', Format(T, 0, 9));
        DT := 0DT;
        Observer.Observe('datetime-zero', Format(DT));
        C := 'abc';
        Observer.Observe('code-from-literal', C);
        Dec := 0.1;
        Observer.Observe('dec-literal-assign', Format(Dec));
        Observer.Observe('dec-literal-compare', Format(0.1 + 0.2 = 0.3));
        Observer.Expect('true', 'Yes');
        Observer.Expect('false', 'No');
        Observer.Expect('int', '2147483647');
        Observer.Expect('int-leading-zeros', '7');
        Observer.Expect('dec', '1.5');
        Observer.Expect('dec-many-digits', '12.3456789012345678');
        Observer.Expect('dec-trailing-zero', '1.5');
        Observer.Expect('text', 'plain');
        Observer.Expect('text-empty-len', '0');
        Observer.Expect('text-doubled-quote', 'it''s');
        Observer.Expect('text-unicode', 'äöü€');
        Observer.Expect('text-spaces-len', '5');
        Observer.Expect('date-zero', '');
        Observer.Expect('date-literal', '2024-03-15');
        Observer.Expect('date-literal-day-of-week', '5');
        Observer.Expect('time-zero', '');
        Observer.Expect('time-literal', '12:34:56');
        Observer.Expect('datetime-zero', '');
        Observer.Expect('code-from-literal', 'ABC');
        Observer.Expect('dec-literal-assign', '0.1');
        Observer.Expect('dec-literal-compare', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P114_CaseRangesInteger()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        for I := -6 to 10 do
            Observer.Observe('v' + Format(I), Classify(I));
        Observer.Observe('v100', Classify(100));
        Observer.Observe('v101', Classify(101));
        Observer.Expect('v-6', 'other');
        Observer.Expect('v-5', 'negative');
        Observer.Expect('v-4', 'negative');
        Observer.Expect('v-3', 'negative');
        Observer.Expect('v-2', 'negative');
        Observer.Expect('v-1', 'negative');
        Observer.Expect('v0', 'zero');
        Observer.Expect('v1', 'small');
        Observer.Expect('v2', 'small');
        Observer.Expect('v3', 'small');
        Observer.Expect('v4', 'even-list');
        Observer.Expect('v5', 'other');
        Observer.Expect('v6', 'even-list');
        Observer.Expect('v7', 'other');
        Observer.Expect('v8', 'even-list');
        Observer.Expect('v9', 'large');
        Observer.Expect('v10', 'large');
        Observer.Expect('v100', 'large');
        Observer.Expect('v101', 'other');
        Observer.Verify();
    end;

    [Test]
    procedure P114_CaseOptionEnumText()
    var
        Observer: Codeunit "Probe Observer";
        E: Enum "LT P114 Stmt Enum";
    begin
        Observer.Observe('opt-zero', ClassifyOption(0));
        Observer.Observe('opt-one', ClassifyOption(1));
        Observer.Observe('opt-two', ClassifyOption(2));
        Observer.Observe('opt-three-falls-through', ClassifyOption(3));
        Observer.Observe('opt-four-falls-through', ClassifyOption(4));
        Observer.Observe('enum-default', ClassifyEnum(E));
        Observer.Observe('enum-mid', ClassifyEnum(E::Mid));
        Observer.Observe('enum-high', ClassifyEnum(E::High));
        Observer.Observe('enum-top', ClassifyEnum(E::Top));
        Observer.Observe('enum-from-ordinal-five', ClassifyEnum(Enum::"LT P114 Stmt Enum".FromInteger(5)));
        Observer.Observe('text-a', ClassifyText('a'));
        Observer.Observe('text-upper-a', ClassifyText('A'));
        Observer.Observe('text-c-lower', ClassifyText('c'));
        Observer.Observe('text-c-upper', ClassifyText('C'));
        Observer.Observe('text-empty', ClassifyText(''));
        Observer.Observe('text-other', ClassifyText('zz'));
        Observer.Expect('opt-zero', 'zero');
        Observer.Expect('opt-one', 'one-or-two');
        Observer.Expect('opt-two', 'one-or-two');
        Observer.Expect('opt-three-falls-through', 'fall-through');
        Observer.Expect('opt-four-falls-through', 'fall-through');
        Observer.Expect('enum-default', 'low');
        Observer.Expect('enum-mid', 'mid-or-high');
        Observer.Expect('enum-high', 'mid-or-high');
        Observer.Expect('enum-top', 'else');
        Observer.Expect('enum-from-ordinal-five', 'mid-or-high');
        Observer.Expect('text-a', 'ab');
        Observer.Expect('text-upper-a', 'other');
        Observer.Expect('text-c-lower', 'other');
        Observer.Expect('text-c-upper', 'upper-c');
        Observer.Expect('text-empty', 'empty');
        Observer.Expect('text-other', 'other');
        Observer.Verify();
    end;

    [Test]
    procedure P114_ExitInTableTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P114 Stmt Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'a';
        Row.Insert(true);
        Observer.Observe('insert-normal', Row.Name);
        Row.Id := 99;
        Row.Name := 'b';
        Row.Insert(true);
        Observer.Observe('insert-exit-early', Row.Name);
        Row.Id := 2;
        Row.Name := 'c';
        Row.Insert(false);
        Observer.Observe('insert-no-trigger', Row.Name);
        Row.Get(1);
        Row.Name := '';
        Row.Modify(true);
        Observer.Observe('modify-exit-early', Row.Name);
        Row.Name := 'z';
        Row.Modify(true);
        Observer.Observe('modify-normal', Row.Name);
        Observer.Expect('insert-normal', 'a|inserted');
        Observer.Expect('insert-exit-early', 'b');
        Observer.Expect('insert-no-trigger', 'c');
        Observer.Expect('modify-exit-early', '');
        Observer.Expect('modify-normal', 'z|modified');
        Observer.Verify();
    end;

    [Test]
    procedure P114_ConversionsAssign()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        Dec: Decimal;
        C: Code[5];
        T: Text[3];
        B: Boolean;
        Big: BigInteger;
        Ch: Char;
        Mode: Option Zero,One,Two;
    begin
        I := 7;
        Dec := I;
        Observer.Observe('int-to-dec', Format(Dec));
        Big := I;
        Observer.Observe('int-to-big', Format(Big));
        Dec := Big;
        Observer.Observe('big-to-dec', Format(Dec));
        C := 'abc';
        Observer.Observe('code-upper', C);
        T := C;
        Observer.Observe('code-to-text3', T);
        Ch := 65;
        Observer.Observe('char-from-int', Format(Ch));
        I := Ch;
        Observer.Observe('int-from-char', Format(I));
        Mode := 2;
        Observer.Observe('option-from-int', Format(Mode));
        I := Mode;
        Observer.Observe('int-from-option', Format(I));
        B := 1 = 1;
        Observer.Observe('bool-from-compare', Format(B));
        Observer.Observe('evaluate-int', Format(Evaluate(I, '42')) + ':' + Format(I));
        Observer.Observe('evaluate-bool', Format(Evaluate(B, 'No')) + ':' + Format(B));
        Observer.Observe('evaluate-bad', Format(Evaluate(I, 'x')) + ':' + Format(I));
        T := 'abc';
        I := 7;
        asserterror C := CopyStr('abcdefgh', 1, 8);
        Observer.ObserveError('code-overflow');
        Mode := I;
        Observer.Observe('option-out-of-range', 'no error');
        Observer.Expect('int-to-dec', '7');
        Observer.Expect('int-to-big', '7');
        Observer.Expect('big-to-dec', '7');
        Observer.Expect('code-upper', 'ABC');
        Observer.Expect('code-to-text3', 'ABC');
        Observer.Expect('char-from-int', 'A');
        Observer.Expect('int-from-char', '65');
        Observer.Expect('option-from-int', 'Two');
        Observer.Expect('int-from-option', '2');
        Observer.Expect('bool-from-compare', 'Yes');
        Observer.Expect('evaluate-int', 'Yes:42');
        Observer.Expect('evaluate-bool', 'Yes:No');
        Observer.Expect('evaluate-bad', 'No:42');
        Observer.Expect('code-overflow|text', 'The length of the string is 8, but it must be less than or equal to 5 characters. Value: abcdefgh');
        Observer.Expect('code-overflow|code', 'StringLengthExceeded');
        Observer.Expect('option-out-of-range', 'no error');
        Observer.Verify();
    end;
}
