// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-integer-string-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against local BC 27.5 and 29.0 observe hosts (identical results); 28.5 is covered by the corpus CI matrix. Every literal asserted below is what BC produced.
// Facts: Format(Value, Length, FormatString) of an Integer, a BigInteger and a Decimal with a Length and a format string.
//   BC formats with the format string first, then fits the text to Length: a shorter text is padded on the LEFT with blanks, a longer one is cut to its first
//   Length characters, Length 0 keeps the text, a negative Length cuts a longer text to its first |Length| characters like a positive one but never pads (Format(8, -5, '<Integer>') = '8', Format(123, -2, '<Integer>') = '12').
//   Format(8, 2, '<Integer>') = ' 8', Format(123, 2, '<Integer>') = '12', Format(12, 2, '<Integer>') = '12'. '<Integer>' without <Sign> drops the minus sign
//   (Format(-5, 4, '<Integer>') = '   5'); '<Sign><Integer>' keeps it. The own width of the string is applied before the fit:
//   Format(8, 2, '<Integer,4>') = '  ' (the first 2 characters of '   8'), Format(8, 0, '<Integer,4>') = '   8'. Literal text in the string counts toward the text
//   that is fitted (Format(8, 2, 'N<Integer>') = 'N8'). BigInteger and Decimal behave like Integer.
// BC versions: 27.5 and 29.0 measured locally, identical.

codeunit 75960 "FLF Integer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Integer_Integer_Lengths()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        I := 8;
        Observer.Observe('8 L2 <Integer>', '[' + Format(I, 2, '<Integer>') + ']');
        Observer.Observe('8 L1 <Integer>', '[' + Format(I, 1, '<Integer>') + ']');
        Observer.Observe('8 L5 <Integer>', '[' + Format(I, 5, '<Integer>') + ']');
        Observer.Observe('8 L0 <Integer>', '[' + Format(I, 0, '<Integer>') + ']');
        Observer.Observe('8 L-2 <Integer>', '[' + Format(I, -2, '<Integer>') + ']');
        Observer.Observe('8 L-5 <Integer>', '[' + Format(I, -5, '<Integer>') + ']');
        I := 12;
        Observer.Observe('12 L2 <Integer>', '[' + Format(I, 2, '<Integer>') + ']');
        Observer.Observe('12 L1 <Integer>', '[' + Format(I, 1, '<Integer>') + ']');
        I := 123;
        Observer.Observe('123 L2 <Integer>', '[' + Format(I, 2, '<Integer>') + ']');
        Observer.Observe('123 L3 <Integer>', '[' + Format(I, 3, '<Integer>') + ']');
        Observer.Observe('123 L6 <Integer>', '[' + Format(I, 6, '<Integer>') + ']');
        Observer.Observe('123 L-2 <Integer>', '[' + Format(I, -2, '<Integer>') + ']');
        Observer.Observe('123 L-6 <Integer>', '[' + Format(I, -6, '<Integer>') + ']');
        Observer.Observe('literal 8 L2 <Integer>', '[' + Format(8, 2, '<Integer>') + ']');
        Observer.Observe('literal 123 L2 <Integer>', '[' + Format(123, 2, '<Integer>') + ']');
        Observer.Expect('8 L2 <Integer>', '[ 8]');
        Observer.Expect('8 L1 <Integer>', '[8]');
        Observer.Expect('8 L5 <Integer>', '[    8]');
        Observer.Expect('8 L0 <Integer>', '[8]');
        Observer.Expect('8 L-2 <Integer>', '[8]');
        Observer.Expect('8 L-5 <Integer>', '[8]');
        Observer.Expect('12 L2 <Integer>', '[12]');
        Observer.Expect('12 L1 <Integer>', '[1]');
        Observer.Expect('123 L2 <Integer>', '[12]');
        Observer.Expect('123 L3 <Integer>', '[123]');
        Observer.Expect('123 L6 <Integer>', '[   123]');
        Observer.Expect('123 L-2 <Integer>', '[12]');
        Observer.Expect('123 L-6 <Integer>', '[123]');
        Observer.Expect('literal 8 L2 <Integer>', '[ 8]');
        Observer.Expect('literal 123 L2 <Integer>', '[12]');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_ZeroAndNegative()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        I := 0;
        Observer.Observe('0 L3 <Integer>', '[' + Format(I, 3, '<Integer>') + ']');
        Observer.Observe('0 L1 <Integer>', '[' + Format(I, 1, '<Integer>') + ']');
        I := -5;
        Observer.Observe('-5 L4 <Integer>', '[' + Format(I, 4, '<Integer>') + ']');
        Observer.Observe('-5 L2 <Integer>', '[' + Format(I, 2, '<Integer>') + ']');
        Observer.Observe('-5 L1 <Integer>', '[' + Format(I, 1, '<Integer>') + ']');
        Observer.Observe('-5 L0 <Integer>', '[' + Format(I, 0, '<Integer>') + ']');
        I := -123;
        Observer.Observe('-123 L2 <Integer>', '[' + Format(I, 2, '<Integer>') + ']');
        Observer.Observe('-123 L6 <Integer>', '[' + Format(I, 6, '<Integer>') + ']');
        Observer.Observe('-123 L4 <Sign><Integer>', '[' + Format(I, 4, '<Sign><Integer>') + ']');
        Observer.Observe('-123 L8 <Sign><Integer>', '[' + Format(I, 8, '<Sign><Integer>') + ']');
        I := 5;
        Observer.Observe('5 L4 <Sign><Integer>', '[' + Format(I, 4, '<Sign><Integer>') + ']');
        Observer.Observe('5 L1 <Sign><Integer>', '[' + Format(I, 1, '<Sign><Integer>') + ']');
        I := 0;
        Observer.Observe('0 L4 <Sign><Integer>', '[' + Format(I, 4, '<Sign><Integer>') + ']');
        Observer.Expect('0 L3 <Integer>', '[  0]');
        Observer.Expect('0 L1 <Integer>', '[0]');
        Observer.Expect('-5 L4 <Integer>', '[   5]');
        Observer.Expect('-5 L2 <Integer>', '[ 5]');
        Observer.Expect('-5 L1 <Integer>', '[5]');
        Observer.Expect('-5 L0 <Integer>', '[5]');
        Observer.Expect('-123 L2 <Integer>', '[12]');
        Observer.Expect('-123 L6 <Integer>', '[   123]');
        Observer.Expect('-123 L4 <Sign><Integer>', '[-123]');
        Observer.Expect('-123 L8 <Sign><Integer>', '[    -123]');
        Observer.Expect('5 L4 <Sign><Integer>', '[   5]');
        Observer.Expect('5 L1 <Sign><Integer>', '[5]');
        Observer.Expect('0 L4 <Sign><Integer>', '[   0]');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_OwnWidthAndFiller()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        I := 8;
        Observer.Observe('8 L2 <Integer,2><Filler Character,0>', '[' + Format(I, 2, '<Integer,2><Filler Character,0>') + ']');
        Observer.Observe('8 L5 <Integer,2><Filler Character,0>', '[' + Format(I, 5, '<Integer,2><Filler Character,0>') + ']');
        Observer.Observe('8 L1 <Integer,2><Filler Character,0>', '[' + Format(I, 1, '<Integer,2><Filler Character,0>') + ']');
        Observer.Observe('8 L5 <Integer,4>', '[' + Format(I, 5, '<Integer,4>') + ']');
        Observer.Observe('8 L2 <Integer,4>', '[' + Format(I, 2, '<Integer,4>') + ']');
        Observer.Observe('8 L0 <Integer,4>', '[' + Format(I, 0, '<Integer,4>') + ']');
        Observer.Observe('8 L3 <Integer,5><Filler Character,0>', '[' + Format(I, 3, '<Integer,5><Filler Character,0>') + ']');
        Observer.Observe('8 L7 <Integer,5><Filler Character,0>', '[' + Format(I, 7, '<Integer,5><Filler Character,0>') + ']');
        I := 123;
        Observer.Observe('123 L2 <Integer,5><Filler Character,0>', '[' + Format(I, 2, '<Integer,5><Filler Character,0>') + ']');
        Observer.Observe('123 L5 <Integer,5><Filler Character,0>', '[' + Format(I, 5, '<Integer,5><Filler Character,0>') + ']');
        Observer.Expect('8 L2 <Integer,2><Filler Character,0>', '[08]');
        Observer.Expect('8 L5 <Integer,2><Filler Character,0>', '[   08]');
        Observer.Expect('8 L1 <Integer,2><Filler Character,0>', '[0]');
        Observer.Expect('8 L5 <Integer,4>', '[    8]');
        Observer.Expect('8 L2 <Integer,4>', '[  ]');
        Observer.Expect('8 L0 <Integer,4>', '[   8]');
        Observer.Expect('8 L3 <Integer,5><Filler Character,0>', '[000]');
        Observer.Expect('8 L7 <Integer,5><Filler Character,0>', '[  00008]');
        Observer.Expect('123 L2 <Integer,5><Filler Character,0>', '[00]');
        Observer.Expect('123 L5 <Integer,5><Filler Character,0>', '[00123]');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_LiteralText()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        I := 8;
        Observer.Observe('8 L10 N<Integer>', '[' + Format(I, 10, 'N<Integer>') + ']');
        Observer.Observe('8 L2 N<Integer>', '[' + Format(I, 2, 'N<Integer>') + ']');
        Observer.Observe('8 L0 N<Integer>', '[' + Format(I, 0, 'N<Integer>') + ']');
        Observer.Observe('8 L12 No. <Integer> of 9', '[' + Format(I, 12, 'No. <Integer> of 9') + ']');
        Observer.Observe('8 L6 No. <Integer> of 9', '[' + Format(I, 6, 'No. <Integer> of 9') + ']');
        Observer.Observe('8 L3 <Integer>.<Integer>', '[' + Format(I, 3, '<Integer>.<Integer>') + ']');
        Observer.Observe('8 L5 abc', '[' + Format(I, 5, 'abc') + ']');
        Observer.Observe('8 L5 empty string', '[' + Format(I, 5, '') + ']');
        Observer.Expect('8 L10 N<Integer>', '[        N8]');
        Observer.Expect('8 L2 N<Integer>', '[N8]');
        Observer.Expect('8 L0 N<Integer>', '[N8]');
        Observer.Expect('8 L12 No. <Integer> of 9', '[  No. 8 of 9]');
        Observer.Expect('8 L6 No. <Integer> of 9', '[No. 8 ]');
        Observer.Expect('8 L3 <Integer>.<Integer>', '[8.8]');
        Observer.Expect('8 L5 abc', '[  abc]');
        Observer.Expect('8 L5 empty string', '[     ]');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_Thousand()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        I := 1234567;
        Observer.Observe('1234567 L12 <Integer Thousand>', '[' + Format(I, 12, '<Integer Thousand>') + ']');
        Observer.Observe('1234567 L9 <Integer Thousand>', '[' + Format(I, 9, '<Integer Thousand>') + ']');
        Observer.Observe('1234567 L5 <Integer Thousand>', '[' + Format(I, 5, '<Integer Thousand>') + ']');
        Observer.Observe('1234567 L0 <Integer Thousand>', '[' + Format(I, 0, '<Integer Thousand>') + ']');
        Observer.Observe('1234567 L12 <Integer>', '[' + Format(I, 12, '<Integer>') + ']');
        I := 123;
        Observer.Observe('123 L6 <Integer Thousand>', '[' + Format(I, 6, '<Integer Thousand>') + ']');
        I := -1234;
        Observer.Observe('-1234 L9 <Integer Thousand>', '[' + Format(I, 9, '<Integer Thousand>') + ']');
        Observer.Observe('-1234 L3 <Integer Thousand>', '[' + Format(I, 3, '<Integer Thousand>') + ']');
        Observer.Expect('1234567 L12 <Integer Thousand>', '[   1,234,567]');
        Observer.Expect('1234567 L9 <Integer Thousand>', '[1,234,567]');
        Observer.Expect('1234567 L5 <Integer Thousand>', '[1,234]');
        Observer.Expect('1234567 L0 <Integer Thousand>', '[1,234,567]');
        Observer.Expect('1234567 L12 <Integer>', '[     1234567]');
        Observer.Expect('123 L6 <Integer Thousand>', '[   123]');
        Observer.Expect('-1234 L9 <Integer Thousand>', '[    1,234]');
        Observer.Expect('-1234 L3 <Integer Thousand>', '[1,2]');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_Lengths()
    var
        Observer: Codeunit "Probe Observer";
        B: BigInteger;
    begin
        B := 8;
        Observer.Observe('big 8 L2 <Integer>', '[' + Format(B, 2, '<Integer>') + ']');
        Observer.Observe('big 8 L0 <Integer>', '[' + Format(B, 0, '<Integer>') + ']');
        B := 123;
        Observer.Observe('big 123 L2 <Integer>', '[' + Format(B, 2, '<Integer>') + ']');
        Observer.Observe('big 123 L3 <Integer>', '[' + Format(B, 3, '<Integer>') + ']');
        B := -5;
        Observer.Observe('big -5 L4 <Integer>', '[' + Format(B, 4, '<Integer>') + ']');
        B := 8;
        Observer.Observe('big 8 L2 <Integer,2><Filler Character,0>', '[' + Format(B, 2, '<Integer,2><Filler Character,0>') + ']');
        Observer.Observe('big 8 L5 <Integer,2><Filler Character,0>', '[' + Format(B, 5, '<Integer,2><Filler Character,0>') + ']');
        B := 1234567890123L;
        Observer.Observe('big 1234567890123 L8 <Integer>', '[' + Format(B, 8, '<Integer>') + ']');
        Observer.Observe('big 1234567890123 L16 <Integer>', '[' + Format(B, 16, '<Integer>') + ']');
        Observer.Observe('big 1234567890123 L16 <Integer Thousand>', '[' + Format(B, 16, '<Integer Thousand>') + ']');
        Observer.Expect('big 8 L2 <Integer>', '[ 8]');
        Observer.Expect('big 8 L0 <Integer>', '[8]');
        Observer.Expect('big 123 L2 <Integer>', '[12]');
        Observer.Expect('big 123 L3 <Integer>', '[123]');
        Observer.Expect('big -5 L4 <Integer>', '[   5]');
        Observer.Expect('big 8 L2 <Integer,2><Filler Character,0>', '[08]');
        Observer.Expect('big 8 L5 <Integer,2><Filler Character,0>', '[   08]');
        Observer.Expect('big 1234567890123 L8 <Integer>', '[12345678]');
        Observer.Expect('big 1234567890123 L16 <Integer>', '[   1234567890123]');
        Observer.Expect('big 1234567890123 L16 <Integer Thousand>', '[1,234,567,890,12]');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Lengths()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := 8;
        Observer.Observe('dec 8 L2 <Integer>', '[' + Format(D, 2, '<Integer>') + ']');
        D := 123;
        Observer.Observe('dec 123 L2 <Integer>', '[' + Format(D, 2, '<Integer>') + ']');
        Observer.Observe('dec 123 L6 <Integer>', '[' + Format(D, 6, '<Integer>') + ']');
        D := 12.5;
        Observer.Observe('dec 12.5 L2 <Integer>', '[' + Format(D, 2, '<Integer>') + ']');
        Observer.Observe('dec 12.5 L8 <Integer><Decimals>', '[' + Format(D, 8, '<Integer><Decimals>') + ']');
        Observer.Observe('dec 12.5 L3 <Integer><Decimals>', '[' + Format(D, 3, '<Integer><Decimals>') + ']');
        Observer.Observe('dec 12.5 L8 <Integer><Decimals,3>', '[' + Format(D, 8, '<Integer><Decimals,3>') + ']');
        D := -12.5;
        Observer.Observe('dec -12.5 L8 <Sign><Integer><Decimals>', '[' + Format(D, 8, '<Sign><Integer><Decimals>') + ']');
        D := 1234.5;
        Observer.Observe('dec 1234.5 L10 <Integer Thousand><Decimals>', '[' + Format(D, 10, '<Integer Thousand><Decimals>') + ']');
        D := 0;
        Observer.Observe('dec 0 L3 <Integer>', '[' + Format(D, 3, '<Integer>') + ']');
        D := 8;
        Observer.Observe('dec 8 L2 <Integer,2><Filler Character,0>', '[' + Format(D, 2, '<Integer,2><Filler Character,0>') + ']');
        Observer.Observe('dec 8 L5 <Integer,2><Filler Character,0>', '[' + Format(D, 5, '<Integer,2><Filler Character,0>') + ']');
        Observer.Expect('dec 8 L2 <Integer>', '[ 8]');
        Observer.Expect('dec 123 L2 <Integer>', '[12]');
        Observer.Expect('dec 123 L6 <Integer>', '[   123]');
        Observer.Expect('dec 12.5 L2 <Integer>', '[12]');
        Observer.Expect('dec 12.5 L8 <Integer><Decimals>', '[    12.5]');
        Observer.Expect('dec 12.5 L3 <Integer><Decimals>', '[12.]');
        Observer.Expect('dec 12.5 L8 <Integer><Decimals,3>', '[   12.50]');
        Observer.Expect('dec -12.5 L8 <Sign><Integer><Decimals>', '[   -12.5]');
        Observer.Expect('dec 1234.5 L10 <Integer Thousand><Decimals>', '[   1,234.5]');
        Observer.Expect('dec 0 L3 <Integer>', '[  0]');
        Observer.Expect('dec 8 L2 <Integer,2><Filler Character,0>', '[08]');
        Observer.Expect('dec 8 L5 <Integer,2><Filler Character,0>', '[   08]');
        Observer.Verify();
    end;
}
