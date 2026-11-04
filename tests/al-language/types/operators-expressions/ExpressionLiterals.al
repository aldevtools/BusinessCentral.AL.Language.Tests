// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-data-types
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained enum 72787, test codeunit 72788
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: one literal of every type (Integer, BigInteger, Decimal, Text with quotes, Char, Boolean, Date, Time, DateTime, Option member, Enum member), its value and its Format; the largest Integer literal.
enum 72787 "LT Lit Enum"
{
    Extensible = true;

    value(0; First) { }
    value(5; Fifth) { }
    value(9; "Ninth Value") { }
}

codeunit 72788 "LT Literals"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P195_Literal_IntegerBigIntegerDecimal()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigInteger;
        Dec: Decimal;
        Int: Integer;
    begin
        Observer.Observe('int-max', Format(2147483647));
        Observer.Observe('int-neg-max', Format(-2147483647));
        Int := 2147483647;
        asserterror Int := Int + 1;
        Observer.ObserveError('int-max-plus-one');
        Big := 2147483647;
        Observer.Observe('big-from-int-max', Format(Big));
        Big := Big + 1;
        Observer.Observe('big-max-plus-one', Format(Big));
        Big := Big * 2147483647;
        Observer.Observe('big-product', Format(Big));
        Observer.Observe('big-product-xml', Format(Big, 0, 9));
        Big := 0;
        Observer.Observe('big-zero', Format(Big));
        Observer.Observe('dec-simple', Format(1.5));
        Observer.Observe('dec-six-places', Format(3.141592));
        Observer.Observe('dec-nine-places', Format(0.123456789));
        Dec := 0.123456789;
        Observer.Observe('dec-nine-places-xml', Format(Dec, 0, 9));
        Observer.Observe('dec-leading-dot-compare', Format(0.5 = 0.50));
        Observer.Observe('dec-big-integer-part', Format(123456789012.5));
        Observer.Observe('dec-neg', Format(-12.25));
        Observer.Observe('dec-zero-form', Format(0.0));
        Observer.Observe('dec-int-conv', Format(7 / 2));
        Observer.Observe('dec-literal-to-int', Format(Round(2.5, 1)));
        Observer.Expect('int-max', '2147483647');
        Observer.Expect('int-neg-max', '-2147483647');
        Observer.Expect('int-max-plus-one|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('int-max-plus-one|code', 'AL:Overflow');
        Observer.Expect('big-from-int-max', '2147483647');
        Observer.Expect('big-max-plus-one', '2147483648');
        Observer.Expect('big-product', '4611686016279904256');
        Observer.Expect('big-product-xml', '4611686016279904256');
        Observer.Expect('big-zero', '0');
        Observer.Expect('dec-simple', '1.5');
        Observer.Expect('dec-six-places', '3.141592');
        Observer.Expect('dec-nine-places', '0.123456789');
        Observer.Expect('dec-nine-places-xml', '0.123456789');
        Observer.Expect('dec-leading-dot-compare', 'Yes');
        Observer.Expect('dec-big-integer-part', '123,456,789,012.5');
        Observer.Expect('dec-neg', '-12.25');
        Observer.Expect('dec-zero-form', '0');
        Observer.Expect('dec-int-conv', '3.5');
        Observer.Expect('dec-literal-to-int', '3');
        Observer.Verify();
    end;

    [Test]
    procedure P195_Literal_TextCharBoolean()
    var
        Observer: Codeunit "Probe Observer";
        Ch: Char;
        T: Text;
    begin
        Observer.Observe('text-plain', 'abc');
        Observer.Observe('text-quote', 'it''s');
        Observer.Observe('text-quote-len', Format(StrLen('it''s')));
        Observer.Observe('text-only-quote', '''');
        Observer.Observe('text-only-quote-len', Format(StrLen('''')));
        Observer.Observe('text-two-quotes-len', Format(StrLen('''''')));
        Observer.Observe('text-empty-len', Format(StrLen('')));
        Observer.Observe('text-double-quote-char', 'say "hi"');
        Observer.Observe('text-backslash', 'a\b');
        Observer.Observe('text-unicode-len', Format(StrLen('äöü€')));
        T := 'x';
        Observer.Observe('text-var', T);
        Ch := 65;
        Observer.Observe('char-from-int', Format(Ch));
        Observer.Observe('char-as-int', Format(Ch + 0));
        Ch := 228;
        Observer.Observe('char-228', Format(Ch));
        Observer.Observe('char-compare', Format(Ch = 228));
        Observer.Observe('bool-true', Format(true));
        Observer.Observe('bool-false', Format(false));
        Observer.Observe('bool-true-xml', Format(true, 0, 9));
        Observer.Observe('bool-true-as-int', Format(true, 0, 2));
        Observer.Expect('text-plain', 'abc');
        Observer.Expect('text-quote', 'it''s');
        Observer.Expect('text-quote-len', '4');
        Observer.Expect('text-only-quote', '''');
        Observer.Expect('text-only-quote-len', '1');
        Observer.Expect('text-two-quotes-len', '2');
        Observer.Expect('text-empty-len', '0');
        Observer.Expect('text-double-quote-char', 'say "hi"');
        Observer.Expect('text-backslash', 'a\b');
        Observer.Expect('text-unicode-len', '4');
        Observer.Expect('text-var', 'x');
        Observer.Expect('char-from-int', 'A');
        Observer.Expect('char-as-int', '65');
        Observer.Expect('char-228', 'ä');
        Observer.Expect('char-compare', 'Yes');
        Observer.Expect('bool-true', 'Yes');
        Observer.Expect('bool-false', 'No');
        Observer.Expect('bool-true-xml', 'true');
        Observer.Expect('bool-true-as-int', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P195_Literal_DateTimeDateTime()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
        T: Time;
        DT: DateTime;
    begin
        D := 20240115D;
        Observer.Observe('date-xml', Format(D, 0, 9));
        Observer.Observe('date-year', Format(Date2DMY(D, 3)));
        Observer.Observe('date-month', Format(Date2DMY(D, 2)));
        Observer.Observe('date-day', Format(Date2DMY(D, 1)));
        Observer.Observe('date-weekday', Format(Date2DWY(D, 1)));
        Observer.Observe('date-leap-day', Format(20240229D, 0, 9));
        Observer.Observe('date-zero-xml', Format(0D, 0, 9));
        Observer.Observe('date-zero-is-undefined', Format(0D = D));
        Observer.Observe('date-min-edge', Format(17540101D, 0, 9));
        Observer.Observe('date-max-edge', Format(99991231D, 0, 9));
        T := 120000T;
        Observer.Observe('time-xml', Format(T, 0, 9));
        Observer.Observe('time-hour', Format(Round((T - 000000T) / 3600000, 1, '<')));
        Observer.Observe('time-zero-xml', Format(0T, 0, 9));
        DT := CreateDateTime(20240115D, 120000T);
        Observer.Observe('datetime-xml', Format(DT, 0, 9));
        Observer.Observe('datetime-date-part', Format(DT2Date(DT), 0, 9));
        Observer.Observe('datetime-time-part', Format(DT2Time(DT), 0, 9));
        Observer.Observe('datetime-zero-xml', Format(0DT, 0, 9));
        DT := CreateDateTime(20240115D, 0T);
        Observer.Observe('datetime-midnight-xml', Format(DT, 0, 9));
        Observer.Observe('datetime-literal-compare', Format(CreateDateTime(20240115D, 120000T) > CreateDateTime(20240115D, 110000T)));
        Observer.Expect('date-xml', '2024-01-15');
        Observer.Expect('date-year', '2024');
        Observer.Expect('date-month', '1');
        Observer.Expect('date-day', '15');
        Observer.Expect('date-weekday', '1');
        Observer.Expect('date-leap-day', '2024-02-29');
        Observer.Expect('date-zero-xml', '');
        Observer.Expect('date-zero-is-undefined', 'No');
        Observer.Expect('date-min-edge', '1754-01-01');
        Observer.Expect('date-max-edge', '9999-12-31');
        Observer.Expect('time-xml', '12:00:00');
        Observer.Expect('time-hour', '12');
        Observer.Expect('time-zero-xml', '');
        Observer.Expect('datetime-xml', '2024-01-15T12:00:00Z');
        Observer.Expect('datetime-date-part', '2024-01-15');
        Observer.Expect('datetime-time-part', '12:00:00');
        Observer.Expect('datetime-zero-xml', '');
        Observer.Expect('datetime-midnight-xml', '2024-01-15T00:00:00Z');
        Observer.Expect('datetime-literal-compare', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P195_Literal_OptionAndEnumMembers()
    var
        Observer: Codeunit "Probe Observer";
        Opt: Option Alpha,Beta,"Gamma Delta";
        E: Enum "LT Lit Enum";
    begin
        Opt := Opt::Beta;
        Observer.Observe('option-beta', Format(Opt));
        Observer.Observe('option-beta-int', Format(Opt, 0, 2));
        Observer.Observe('option-beta-eq-1', Format(Opt = 1));
        Opt := Opt::"Gamma Delta";
        Observer.Observe('option-quoted', Format(Opt));
        Observer.Observe('option-quoted-int', Format(Opt, 0, 2));
        Opt := Opt::Alpha;
        Observer.Observe('option-first-default', Format(Opt));
        E := E::Fifth;
        Observer.Observe('enum-fifth', Format(E));
        Observer.Observe('enum-fifth-ordinal', Format(E.AsInteger()));
        Observer.Observe('enum-fifth-int-format', Format(E, 0, 2));
        E := E::"Ninth Value";
        Observer.Observe('enum-ninth', Format(E));
        Observer.Observe('enum-ninth-ordinal', Format(E.AsInteger()));
        Observer.Observe('enum-qualified-literal', Format(Enum::"LT Lit Enum"::Fifth));
        Observer.Observe('enum-qualified-ordinal', Format(Enum::"LT Lit Enum"::"Ninth Value".AsInteger()));
        Observer.Observe('enum-default', Format(E::First));
        Observer.Observe('enum-compare', Format(Enum::"LT Lit Enum"::Fifth = E::Fifth));
        Observer.Observe('enum-from-ordinal', Format(Enum::"LT Lit Enum".FromInteger(9)));
        Observer.Expect('option-beta', 'Beta');
        Observer.Expect('option-beta-int', '1');
        Observer.Expect('option-beta-eq-1', 'Yes');
        Observer.Expect('option-quoted', 'Gamma Delta');
        Observer.Expect('option-quoted-int', '2');
        Observer.Expect('option-first-default', 'Alpha');
        Observer.Expect('enum-fifth', 'Fifth');
        Observer.Expect('enum-fifth-ordinal', '5');
        Observer.Expect('enum-fifth-int-format', '5');
        Observer.Expect('enum-ninth', 'Ninth Value');
        Observer.Expect('enum-ninth-ordinal', '9');
        Observer.Expect('enum-qualified-literal', 'Fifth');
        Observer.Expect('enum-qualified-ordinal', '9');
        Observer.Expect('enum-default', 'First');
        Observer.Expect('enum-compare', 'Yes');
        Observer.Expect('enum-from-ordinal', 'Ninth Value');
        Observer.Verify();
    end;

    // Corpus #664 item 25: a backslash in a Text literal is not an escape character; '\q' and '\n' compile with no AL0630 (AL 30 beta).
    // This records the length and characters of such literals, and the text of an Error raised with one.
    [Test]
    procedure BM_Literal_BackslashSequences()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := 'a\qb';
        Observer.Observe('aqb_len', Format(StrLen(T)));
        Observer.Observe('aqb_char2', Format(CodeAt(T, 2)));
        Observer.Observe('aqb_value', T);
        T := '\n';
        Observer.Observe('n_len', Format(StrLen(T)));
        Observer.Observe('n_char1', Format(CodeAt(T, 1)));
        Observer.Observe('n_char2', Format(CodeAt(T, 2)));
        Observer.Observe('n_equals_backslash_n', Format(T = '\' + 'n'));
        Observer.Observe('lone_backslash_len', Format(StrLen('\')));
        asserterror Error('x\ty');
        Observer.ObserveError('error_backslash_t');
        asserterror Error('line1\line2');
        Observer.ObserveError('error_backslash_line');
        Observer.Expect('aqb_len', '4');
        Observer.Expect('aqb_char2', '92');
        Observer.Expect('aqb_value', 'a\qb');
        Observer.Expect('n_len', '2');
        Observer.Expect('n_char1', '92');
        Observer.Expect('n_char2', '110');
        Observer.Expect('n_equals_backslash_n', 'Yes');
        Observer.Expect('lone_backslash_len', '1');
        Observer.Expect('error_backslash_t|text', 'x\ty');
        Observer.Expect('error_backslash_t|code', 'Dialog');
        Observer.Expect('error_backslash_line|text', 'line1\line2');
        Observer.Expect('error_backslash_line|code', 'Dialog');
        Observer.Verify();
    end;

    local procedure CodeAt(T: Text; Pos: Integer): Integer
    var
        C: Integer;
    begin
        C := T[Pos];
        exit(C);
    end;
}
