// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-integer-string-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 27.5 / 28.5 / 29.0 observe host; every literal asserted below is what BC produced.
// Facts: Format(Value, Length, FormatString) of an Integer, a BigInteger and a Decimal with a positive Length and a format string: shorter than,
//   equal to and longer than the text of the format string result, negative numbers, zero, literal text in the string, <Sign><Integer>,
//   <Integer Thousand>, a Length shorter than the string's own width, Length 0 and negative Length.
// BC versions: see the asserted values; a version guard is used only where the versions differ.

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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
