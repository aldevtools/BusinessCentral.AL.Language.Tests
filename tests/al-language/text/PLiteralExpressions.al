// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-literals
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 67291
// Every literal form: integer, big integer, decimal, text (with an escaped quote and empty), boolean, date, time, datetime, duration-free forms, and the undefined date, time and datetime. Dates and times are shown in the invariant format (Format(x, 0, 9)).
// BC versions: 27, 28, 29
codeunit 67291 "LT P Literal Expressions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PLiteral_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigInteger;
        Dec: Decimal;
    begin
        Observer.Observe('int_42', Format(42));
        Observer.Observe('int_0', Format(0));
        Observer.Observe('int_max', Format(2147483647));
        Observer.Observe('int_negative', Format(-7));
        Big := 9223372036854775807L;
        Observer.Observe('big_max', Format(Big));
        Big := -9223372036854775807L;
        Observer.Observe('big_negative', Format(Big));
        Observer.Observe('big_literal_over_int', Format(2147483648L));
        Dec := 3.14;
        Observer.Observe('dec_3_14', Format(Dec, 0, 9));
        Observer.Observe('dec_0_5', Format(0.5, 0, 9));
        Observer.Observe('dec_trailing_zero', Format(1.10, 0, 9));
        Observer.Observe('dec_whole', Format(100.0, 0, 9));
        Observer.Observe('dec_many_digits', Format(123456789.123456, 0, 9));
        Observer.Observe('dec_negative', Format(-0.25, 0, 9));
        Observer.Expect('int_42', '42');
        Observer.Expect('int_0', '0');
        Observer.Expect('int_max', '2147483647');
        Observer.Expect('int_negative', '-7');
        Observer.Expect('big_max', '9223372036854775807');
        Observer.Expect('big_negative', '-9223372036854775807');
        Observer.Expect('big_literal_over_int', '2147483648');
        Observer.Expect('dec_3_14', '3.14');
        Observer.Expect('dec_0_5', '0.5');
        Observer.Expect('dec_trailing_zero', '1.1');
        Observer.Expect('dec_whole', '100');
        Observer.Expect('dec_many_digits', '123456789.123456');
        Observer.Expect('dec_negative', '-0.25');
        Observer.Verify();
    end;

    [Test]
    procedure PLiteral_Text()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('text_abc', 'abc');
        Observer.Observe('text_empty_length', Format(StrLen('')));
        Observer.Observe('text_quote', 'it''s');
        Observer.Observe('text_quote_length', Format(StrLen('it''s')));
        Observer.Observe('text_only_quote', '''');
        Observer.Observe('text_double_quote', 'say "hi"');
        Observer.Observe('text_space', '[ ]');
        Observer.Observe('text_unicode', 'ä€');
        Observer.Observe('text_unicode_length', Format(StrLen('ä€')));
        Observer.Expect('text_abc', 'abc');
        Observer.Expect('text_empty_length', '0');
        Observer.Expect('text_quote', 'it''s');
        Observer.Expect('text_quote_length', '4');
        Observer.Expect('text_only_quote', '''');
        Observer.Expect('text_double_quote', 'say "hi"');
        Observer.Expect('text_space', '[ ]');
        Observer.Expect('text_unicode', 'ä€');
        Observer.Expect('text_unicode_length', '2');
        Observer.Verify();
    end;

    [Test]
    procedure PLiteral_Boolean()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('true', Format(true));
        Observer.Observe('false', Format(false));
        Observer.Observe('true_xml', Format(true, 0, 9));
        Observer.Observe('false_xml', Format(false, 0, 9));
        Observer.Expect('true', 'Yes');
        Observer.Expect('false', 'No');
        Observer.Expect('true_xml', 'true');
        Observer.Expect('false_xml', 'false');
        Observer.Verify();
    end;

    [Test]
    procedure PLiteral_DateTimeForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('date_ymd', Format(20260115D, 0, 9));
        Observer.Observe('date_undefined', Format(0D, 0, 9));
        Observer.Observe('date_undefined_is_zero', Format(0D = 0D));
        Observer.Observe('date_leap_day', Format(20240229D, 0, 9));
        Observer.Observe('time_hms', Format(123456T, 0, 9));
        Observer.Observe('time_midnight', Format(000000T, 0, 9));
        Observer.Observe('time_undefined', Format(0T, 0, 9));
        Observer.Observe('time_millis', Format(235959.999T, 0, 9));
        Observer.Observe('datetime_ymdhms', Format(CreateDateTime(20260115D, 123456T), 0, 9));
        Observer.Observe('datetime_undefined', Format(0DT, 0, 9));
        Observer.Expect('date_ymd', '2026-01-15');
        Observer.Expect('date_undefined', '');
        Observer.Expect('date_undefined_is_zero', 'Yes');
        Observer.Expect('date_leap_day', '2024-02-29');
        Observer.Expect('time_hms', '12:34:56');
        Observer.Expect('time_midnight', '00:00:00');
        Observer.Expect('time_undefined', '');
        Observer.Expect('time_millis', '23:59:59.999');
        Observer.Expect('datetime_ymdhms', '2026-01-15T12:34:56Z');
        Observer.Expect('datetime_undefined', '');
        Observer.Verify();
    end;

    [Test]
    procedure PLiteral_Char()
    var
        Observer: Codeunit "Probe Observer";
        C: Char;
    begin
        C := 65;
        Observer.Observe('char_from_integer', Format(C));
        Observer.Observe('char_equals_65', Format(C = 65));
        Observer.Observe('char_length_as_text', Format(StrLen(Format(C))));
        C := 'B';
        Observer.Observe('char_from_text_literal', Format(C));
        Observer.Expect('char_from_integer', 'A');
        Observer.Expect('char_equals_65', 'Yes');
        Observer.Expect('char_length_as_text', '1');
        Observer.Expect('char_from_text_literal', 'B');
        Observer.Verify();
    end;

    // Corpus issue 672 (odd AL behavior leads, part G), item 47: a multiline text literal (@'...', BC 26 and later). This file
    // has LF line endings; the CRLF form is in text/lt-bu-multiline-crlf/BuMultilineCrlf.al. The second line of T2 is indented
    // by four blanks inside the literal.
    [Test]
    procedure LT_BU_Literal_MultilineText()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        T2: Text;
        T3: Text;
        T4: Text;
        Code2: Integer;
    begin
        T := @'a
b';
        T2 := @'first
    second';
        T3 := @'it''s
quoted';
        T4 := @'single line';
        Observer.Observe('two lines', T);
        Observer.Observe('two lines len', Format(StrLen(T)));
        Code2 := T[2];
        Observer.Observe('char 2 code', Format(Code2));
        Observer.Observe('indented', T2);
        Observer.Observe('indented len', Format(StrLen(T2)));
        Observer.Observe('escaped quote', T3);
        Observer.Observe('single line', T4);
        Observer.Observe('split lf', Format(T.Split(Format(T[2])).Count()));
        Observer.Expect('two lines', 'a\nb');
        Observer.Expect('two lines len', '3');
        Observer.Expect('char 2 code', '10');
        Observer.Expect('indented', 'first\n    second');
        Observer.Expect('indented len', '16');
        Observer.Expect('escaped quote', 'it''s\nquoted');
        Observer.Expect('single line', 'single line');
        Observer.Expect('split lf', '2');
        Observer.Verify();
    end;
}
