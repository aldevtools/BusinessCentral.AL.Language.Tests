// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-integer-string-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); helper codeunit 96388 "FLN Fmt" (FormatLengthHelper.al)
// Probe: written against a local BC 27.5 service tier (Windows); every literal asserted below is what BC produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format(Value, Length) and Format(Value, Length, 0 | 9) of a Duration, Char, Byte, BigInteger, Time, Code, Guid, Integer, Decimal and Text,
//   for lengths 1, 3, 10, 30, their negatives, and the text's own length, one more and one less, positive and negative.
// Results (BC 27.5): for every type measured here a length shorter than the text cuts it to its first |L| characters, whatever the sign; a length equal to
//   the text keeps it; a longer positive length pads: Integer, Decimal, BigInteger, Time, Date-like and Duration texts on the left (right-aligned), Text,
//   Code, Char, Byte and Guid on the right; a longer negative length keeps the text. A Duration's text (1 hour 2 minutes ...) is cut like any other text.
//   Format of a Byte is its character (Byte 97 = 'a'); an undefined Time (0T) behaves like 0D (positive: blanks, negative: '').
// BC versions: 27.5 measured on a local Windows container (28.5 and 29.0 by the corpus CI matrix on BC on Linux)

codeunit 96382 "FLN Type Lengths"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Duration_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Duration;
    begin
        V := 3723004;
        Observer.Observe('dur 3723004ms plain', '[' + Format(V) + ']');
        Observer.Observe('dur 3723004ms L=1', F.Duration(V, 1, -1));
        Observer.Observe('dur 3723004ms L=3', F.Duration(V, 3, -1));
        Observer.Observe('dur 3723004ms L=10', F.Duration(V, 10, -1));
        Observer.Observe('dur 3723004ms L=30', F.Duration(V, 30, -1));
        Observer.Observe('dur 3723004ms L=-1', F.Duration(V, -1, -1));
        Observer.Observe('dur 3723004ms L=-3', F.Duration(V, -3, -1));
        Observer.Observe('dur 3723004ms L=-10', F.Duration(V, -10, -1));
        Observer.Observe('dur 3723004ms L=-30', F.Duration(V, -30, -1));
        Observer.Observe('dur 3723004ms L=exact', F.Duration(V, StrLen(Format(V)), -1));
        Observer.Observe('dur 3723004ms L=-exact', F.Duration(V, -StrLen(Format(V)), -1));
        Observer.Observe('dur 3723004ms L=exact+1', F.Duration(V, StrLen(Format(V)) + 1, -1));
        Observer.Observe('dur 3723004ms L=-(exact+1)', F.Duration(V, -(StrLen(Format(V)) + 1), -1));
        Observer.Observe('dur 3723004ms L=exact-1', F.Duration(V, StrLen(Format(V)) - 1, -1));
        Observer.Observe('dur 3723004ms L=-(exact-1)', F.Duration(V, -(StrLen(Format(V)) - 1), -1));
        Observer.Expect('dur 3723004ms plain', '[1 hour 2 minutes 3 seconds 4 milliseconds]');
        Observer.Expect('dur 3723004ms L=1', '[1]');
        Observer.Expect('dur 3723004ms L=3', '[1 h]');
        Observer.Expect('dur 3723004ms L=10', '[1 hour 2 m]');
        Observer.Expect('dur 3723004ms L=30', '[1 hour 2 minutes 3 seconds 4 m]');
        Observer.Expect('dur 3723004ms L=-1', '[1]');
        Observer.Expect('dur 3723004ms L=-3', '[1 h]');
        Observer.Expect('dur 3723004ms L=-10', '[1 hour 2 m]');
        Observer.Expect('dur 3723004ms L=-30', '[1 hour 2 minutes 3 seconds 4 m]');
        Observer.Expect('dur 3723004ms L=exact', '[1 hour 2 minutes 3 seconds 4 milliseconds]');
        Observer.Expect('dur 3723004ms L=-exact', '[1 hour 2 minutes 3 seconds 4 milliseconds]');
        Observer.Expect('dur 3723004ms L=exact+1', '[ 1 hour 2 minutes 3 seconds 4 milliseconds]');
        Observer.Expect('dur 3723004ms L=-(exact+1)', '[1 hour 2 minutes 3 seconds 4 milliseconds]');
        Observer.Expect('dur 3723004ms L=exact-1', '[1 hour 2 minutes 3 seconds 4 millisecond]');
        Observer.Expect('dur 3723004ms L=-(exact-1)', '[1 hour 2 minutes 3 seconds 4 millisecond]');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_Length_Number()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Duration;
    begin
        V := 3723004;
        Observer.Observe('dur 3723004ms plain N=9', '[' + Format(V, 0, 9) + ']');
        Observer.Observe('dur 3723004ms L=3 N=9', F.Duration(V, 3, 9));
        Observer.Observe('dur 3723004ms L=30 N=9', F.Duration(V, 30, 9));
        Observer.Observe('dur 3723004ms L=-3 N=9', F.Duration(V, -3, 9));
        Observer.Observe('dur 3723004ms L=-30 N=9', F.Duration(V, -30, 9));
        Observer.Observe('dur 3723004ms L=3 N=0', F.Duration(V, 3, 0));
        Observer.Observe('dur 3723004ms L=30 N=0', F.Duration(V, 30, 0));
        Observer.Observe('dur 3723004ms L=-3 N=0', F.Duration(V, -3, 0));
        Observer.Observe('dur 3723004ms L=-30 N=0', F.Duration(V, -30, 0));
        V := 0;
        Observer.Observe('dur 0 plain', '[' + Format(V) + ']');
        Observer.Observe('dur 0 L=3', F.Duration(V, 3, -1));
        Observer.Observe('dur 0 L=30', F.Duration(V, 30, -1));
        Observer.Observe('dur 0 L=-3', F.Duration(V, -3, -1));
        Observer.Observe('dur 0 L=-30', F.Duration(V, -30, -1));
        Observer.Observe('dur 0 L=exact', F.Duration(V, StrLen(Format(V)), -1));
        Observer.Observe('dur 0 L=-exact', F.Duration(V, -StrLen(Format(V)), -1));
        Observer.Expect('dur 3723004ms plain N=9', '[P0DT1H2M3.004S]');
        Observer.Expect('dur 3723004ms L=3 N=9', '[P0D]');
        Observer.Expect('dur 3723004ms L=30 N=9', '[                P0DT1H2M3.004S]');
        Observer.Expect('dur 3723004ms L=-3 N=9', '[P0D]');
        Observer.Expect('dur 3723004ms L=-30 N=9', '[P0DT1H2M3.004S]');
        Observer.Expect('dur 3723004ms L=3 N=0', '[1 h]');
        Observer.Expect('dur 3723004ms L=30 N=0', '[1 hour 2 minutes 3 seconds 4 m]');
        Observer.Expect('dur 3723004ms L=-3 N=0', '[1 h]');
        Observer.Expect('dur 3723004ms L=-30 N=0', '[1 hour 2 minutes 3 seconds 4 m]');
        Observer.Expect('dur 0 plain', '[]');
        Observer.Expect('dur 0 L=3', '[   ]');
        Observer.Expect('dur 0 L=30', '[                              ]');
        Observer.Expect('dur 0 L=-3', '[]');
        Observer.Expect('dur 0 L=-30', '[]');
        Observer.Expect('dur 0 L=exact', '[]');
        Observer.Expect('dur 0 L=-exact', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_Negative_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Duration;
    begin
        V := -1500;
        Observer.Observe('dur -1500ms plain', '[' + Format(V) + ']');
        Observer.Observe('dur -1500ms L=1', F.Duration(V, 1, -1));
        Observer.Observe('dur -1500ms L=3', F.Duration(V, 3, -1));
        Observer.Observe('dur -1500ms L=10', F.Duration(V, 10, -1));
        Observer.Observe('dur -1500ms L=30', F.Duration(V, 30, -1));
        Observer.Observe('dur -1500ms L=-1', F.Duration(V, -1, -1));
        Observer.Observe('dur -1500ms L=-3', F.Duration(V, -3, -1));
        Observer.Observe('dur -1500ms L=-10', F.Duration(V, -10, -1));
        Observer.Observe('dur -1500ms L=-30', F.Duration(V, -30, -1));
        Observer.Observe('dur -1500ms L=exact', F.Duration(V, StrLen(Format(V)), -1));
        Observer.Observe('dur -1500ms L=-exact', F.Duration(V, -StrLen(Format(V)), -1));
        Observer.Observe('dur -1500ms L=exact+1', F.Duration(V, StrLen(Format(V)) + 1, -1));
        Observer.Observe('dur -1500ms L=-(exact+1)', F.Duration(V, -(StrLen(Format(V)) + 1), -1));
        Observer.Observe('dur -1500ms L=exact-1', F.Duration(V, StrLen(Format(V)) - 1, -1));
        Observer.Observe('dur -1500ms L=-(exact-1)', F.Duration(V, -(StrLen(Format(V)) - 1), -1));
        Observer.Expect('dur -1500ms plain', '[-1 second 500 milliseconds]');
        Observer.Expect('dur -1500ms L=1', '[-]');
        Observer.Expect('dur -1500ms L=3', '[-1 ]');
        Observer.Expect('dur -1500ms L=10', '[-1 second ]');
        Observer.Expect('dur -1500ms L=30', '[    -1 second 500 milliseconds]');
        Observer.Expect('dur -1500ms L=-1', '[-]');
        Observer.Expect('dur -1500ms L=-3', '[-1 ]');
        Observer.Expect('dur -1500ms L=-10', '[-1 second ]');
        Observer.Expect('dur -1500ms L=-30', '[-1 second 500 milliseconds]');
        Observer.Expect('dur -1500ms L=exact', '[-1 second 500 milliseconds]');
        Observer.Expect('dur -1500ms L=-exact', '[-1 second 500 milliseconds]');
        Observer.Expect('dur -1500ms L=exact+1', '[ -1 second 500 milliseconds]');
        Observer.Expect('dur -1500ms L=-(exact+1)', '[-1 second 500 milliseconds]');
        Observer.Expect('dur -1500ms L=exact-1', '[-1 second 500 millisecond]');
        Observer.Expect('dur -1500ms L=-(exact-1)', '[-1 second 500 millisecond]');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_Negative_Length_Number()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Duration;
    begin
        V := -1500;
        Observer.Observe('dur -1500ms plain N=9', '[' + Format(V, 0, 9) + ']');
        Observer.Observe('dur -1500ms L=3 N=9', F.Duration(V, 3, 9));
        Observer.Observe('dur -1500ms L=30 N=9', F.Duration(V, 30, 9));
        Observer.Observe('dur -1500ms L=-3 N=9', F.Duration(V, -3, 9));
        Observer.Observe('dur -1500ms L=-30 N=9', F.Duration(V, -30, 9));
        Observer.Observe('dur -1500ms L=3 N=0', F.Duration(V, 3, 0));
        Observer.Observe('dur -1500ms L=30 N=0', F.Duration(V, 30, 0));
        Observer.Observe('dur -1500ms L=-3 N=0', F.Duration(V, -3, 0));
        Observer.Observe('dur -1500ms L=-30 N=0', F.Duration(V, -30, 0));
        Observer.Expect('dur -1500ms plain N=9', '[-P0DT0H0M1.5S]');
        Observer.Expect('dur -1500ms L=3 N=9', '[-P0]');
        Observer.Expect('dur -1500ms L=30 N=9', '[                 -P0DT0H0M1.5S]');
        Observer.Expect('dur -1500ms L=-3 N=9', '[-P0]');
        Observer.Expect('dur -1500ms L=-30 N=9', '[-P0DT0H0M1.5S]');
        Observer.Expect('dur -1500ms L=3 N=0', '[-1 ]');
        Observer.Expect('dur -1500ms L=30 N=0', '[    -1 second 500 milliseconds]');
        Observer.Expect('dur -1500ms L=-3 N=0', '[-1 ]');
        Observer.Expect('dur -1500ms L=-30 N=0', '[-1 second 500 milliseconds]');
        Observer.Verify();
    end;

    [Test]
    procedure Char_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Char;
    begin
        V := 'a';
        Observer.Observe('char a plain', '[' + Format(V) + ']');
        Observer.Observe('char a L=1', F.Char(V, 1, -1));
        Observer.Observe('char a L=3', F.Char(V, 3, -1));
        Observer.Observe('char a L=10', F.Char(V, 10, -1));
        Observer.Observe('char a L=30', F.Char(V, 30, -1));
        Observer.Observe('char a L=-1', F.Char(V, -1, -1));
        Observer.Observe('char a L=-3', F.Char(V, -3, -1));
        Observer.Observe('char a L=-10', F.Char(V, -10, -1));
        Observer.Observe('char a L=-30', F.Char(V, -30, -1));
        Observer.Observe('char a L=exact', F.Char(V, StrLen(Format(V)), -1));
        Observer.Observe('char a L=-exact', F.Char(V, -StrLen(Format(V)), -1));
        Observer.Observe('char a L=exact+1', F.Char(V, StrLen(Format(V)) + 1, -1));
        Observer.Observe('char a L=-(exact+1)', F.Char(V, -(StrLen(Format(V)) + 1), -1));
        Observer.Observe('char a L=exact-1', F.Char(V, StrLen(Format(V)) - 1, -1));
        Observer.Observe('char a L=-(exact-1)', F.Char(V, -(StrLen(Format(V)) - 1), -1));
        Observer.Expect('char a plain', '[a]');
        Observer.Expect('char a L=1', '[a]');
        Observer.Expect('char a L=3', '[a  ]');
        Observer.Expect('char a L=10', '[a         ]');
        Observer.Expect('char a L=30', '[a                             ]');
        Observer.Expect('char a L=-1', '[a]');
        Observer.Expect('char a L=-3', '[a]');
        Observer.Expect('char a L=-10', '[a]');
        Observer.Expect('char a L=-30', '[a]');
        Observer.Expect('char a L=exact', '[a]');
        Observer.Expect('char a L=-exact', '[a]');
        Observer.Expect('char a L=exact+1', '[a ]');
        Observer.Expect('char a L=-(exact+1)', '[a]');
        Observer.Expect('char a L=exact-1', '[a]');
        Observer.Expect('char a L=-(exact-1)', '[a]');
        Observer.Verify();
    end;

    [Test]
    procedure Char_Length_Number()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Char;
    begin
        V := 'a';
        Observer.Observe('char a plain N=9', '[' + Format(V, 0, 9) + ']');
        Observer.Observe('char a L=3 N=9', F.Char(V, 3, 9));
        Observer.Observe('char a L=30 N=9', F.Char(V, 30, 9));
        Observer.Observe('char a L=-3 N=9', F.Char(V, -3, 9));
        Observer.Observe('char a L=-30 N=9', F.Char(V, -30, 9));
        Observer.Observe('char a L=3 N=0', F.Char(V, 3, 0));
        Observer.Observe('char a L=30 N=0', F.Char(V, 30, 0));
        Observer.Observe('char a L=-3 N=0', F.Char(V, -3, 0));
        Observer.Observe('char a L=-30 N=0', F.Char(V, -30, 0));
        V := 8364;
        Observer.Observe('char 8364 plain', '[' + Format(V) + ']');
        Observer.Observe('char 8364 L=3', F.Char(V, 3, -1));
        Observer.Observe('char 8364 L=30', F.Char(V, 30, -1));
        Observer.Observe('char 8364 L=-3', F.Char(V, -3, -1));
        Observer.Observe('char 8364 L=-30', F.Char(V, -30, -1));
        Observer.Observe('char 8364 L=exact', F.Char(V, StrLen(Format(V)), -1));
        Observer.Observe('char 8364 L=-exact', F.Char(V, -StrLen(Format(V)), -1));
        Observer.Expect('char a plain N=9', '[a]');
        Observer.Expect('char a L=3 N=9', '[a  ]');
        Observer.Expect('char a L=30 N=9', '[a                             ]');
        Observer.Expect('char a L=-3 N=9', '[a]');
        Observer.Expect('char a L=-30 N=9', '[a]');
        Observer.Expect('char a L=3 N=0', '[a  ]');
        Observer.Expect('char a L=30 N=0', '[a                             ]');
        Observer.Expect('char a L=-3 N=0', '[a]');
        Observer.Expect('char a L=-30 N=0', '[a]');
        Observer.Expect('char 8364 plain', '[€]');
        Observer.Expect('char 8364 L=3', '[€  ]');
        Observer.Expect('char 8364 L=30', '[€                             ]');
        Observer.Expect('char 8364 L=-3', '[€]');
        Observer.Expect('char 8364 L=-30', '[€]');
        Observer.Expect('char 8364 L=exact', '[€]');
        Observer.Expect('char 8364 L=-exact', '[€]');
        Observer.Verify();
    end;

    [Test]
    procedure Byte_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Byte;
    begin
        V := 200;
        Observer.Observe('byte 200 plain', '[' + Format(V) + ']');
        Observer.Observe('byte 200 plain char code', Format(CharCode(Format(V))));
        Observer.Observe('byte 200 L=1', F.Byte(V, 1, -1));
        Observer.Observe('byte 200 L=3', F.Byte(V, 3, -1));
        Observer.Observe('byte 200 L=10', F.Byte(V, 10, -1));
        Observer.Observe('byte 200 L=30', F.Byte(V, 30, -1));
        Observer.Observe('byte 200 L=-1', F.Byte(V, -1, -1));
        Observer.Observe('byte 200 L=-3', F.Byte(V, -3, -1));
        Observer.Observe('byte 200 L=-10', F.Byte(V, -10, -1));
        Observer.Observe('byte 200 L=-30', F.Byte(V, -30, -1));
        Observer.Observe('byte 200 L=exact', F.Byte(V, StrLen(Format(V)), -1));
        Observer.Observe('byte 200 L=-exact', F.Byte(V, -StrLen(Format(V)), -1));
        Observer.Observe('byte 200 L=exact+1', F.Byte(V, StrLen(Format(V)) + 1, -1));
        Observer.Observe('byte 200 L=-(exact+1)', F.Byte(V, -(StrLen(Format(V)) + 1), -1));
        Observer.Observe('byte 200 L=exact-1', F.Byte(V, StrLen(Format(V)) - 1, -1));
        Observer.Observe('byte 200 L=-(exact-1)', F.Byte(V, -(StrLen(Format(V)) - 1), -1));
        Observer.Expect('byte 200 plain', '[˜]');
        Observer.Expect('byte 200 plain char code', '732');
        Observer.Expect('byte 200 L=1', '[˜]');
        Observer.Expect('byte 200 L=3', '[˜  ]');
        Observer.Expect('byte 200 L=10', '[˜         ]');
        Observer.Expect('byte 200 L=30', '[˜                             ]');
        Observer.Expect('byte 200 L=-1', '[˜]');
        Observer.Expect('byte 200 L=-3', '[˜]');
        Observer.Expect('byte 200 L=-10', '[˜]');
        Observer.Expect('byte 200 L=-30', '[˜]');
        Observer.Expect('byte 200 L=exact', '[˜]');
        Observer.Expect('byte 200 L=-exact', '[˜]');
        Observer.Expect('byte 200 L=exact+1', '[˜ ]');
        Observer.Expect('byte 200 L=-(exact+1)', '[˜]');
        Observer.Expect('byte 200 L=exact-1', '[˜]');
        Observer.Expect('byte 200 L=-(exact-1)', '[˜]');
        Observer.Verify();
    end;

    [Test]
    procedure Byte_Length_Number()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Byte;
    begin
        V := 200;
        Observer.Observe('byte 200 plain N=9', '[' + Format(V, 0, 9) + ']');
        Observer.Observe('byte 200 L=3 N=9', F.Byte(V, 3, 9));
        Observer.Observe('byte 200 L=30 N=9', F.Byte(V, 30, 9));
        Observer.Observe('byte 200 L=-3 N=9', F.Byte(V, -3, 9));
        Observer.Observe('byte 200 L=-30 N=9', F.Byte(V, -30, 9));
        Observer.Observe('byte 200 L=3 N=0', F.Byte(V, 3, 0));
        Observer.Observe('byte 200 L=30 N=0', F.Byte(V, 30, 0));
        Observer.Observe('byte 200 L=-3 N=0', F.Byte(V, -3, 0));
        Observer.Observe('byte 200 L=-30 N=0', F.Byte(V, -30, 0));
        V := 7;
        Observer.Observe('byte 7 plain', '[' + Format(V) + ']');
        Observer.Observe('byte 7 L=3', F.Byte(V, 3, -1));
        Observer.Observe('byte 7 L=30', F.Byte(V, 30, -1));
        Observer.Observe('byte 7 L=-3', F.Byte(V, -3, -1));
        Observer.Observe('byte 7 L=-30', F.Byte(V, -30, -1));
        Observer.Observe('byte 7 L=exact', F.Byte(V, StrLen(Format(V)), -1));
        Observer.Observe('byte 7 L=-exact', F.Byte(V, -StrLen(Format(V)), -1));
        Observer.Expect('byte 200 plain N=9', '[˜]');
        Observer.Expect('byte 200 L=3 N=9', '[˜  ]');
        Observer.Expect('byte 200 L=30 N=9', '[˜                             ]');
        Observer.Expect('byte 200 L=-3 N=9', '[˜]');
        Observer.Expect('byte 200 L=-30 N=9', '[˜]');
        Observer.Expect('byte 200 L=3 N=0', '[˜  ]');
        Observer.Expect('byte 200 L=30 N=0', '[˜                             ]');
        Observer.Expect('byte 200 L=-3 N=0', '[˜]');
        Observer.Expect('byte 200 L=-30 N=0', '[˜]');
        Observer.Expect('byte 7 plain', '[\u0007]');
        Observer.Expect('byte 7 L=3', '[\u0007  ]');
        Observer.Expect('byte 7 L=30', '[\u0007                             ]');
        Observer.Expect('byte 7 L=-3', '[\u0007]');
        Observer.Expect('byte 7 L=-30', '[\u0007]');
        Observer.Expect('byte 7 L=exact', '[\u0007]');
        Observer.Expect('byte 7 L=-exact', '[\u0007]');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: BigInteger;
    begin
        V := 1234567890123L;
        Observer.Observe('bigint 1234567890123 plain', '[' + Format(V) + ']');
        Observer.Observe('bigint 1234567890123 L=1', F.BigInteger(V, 1, -1));
        Observer.Observe('bigint 1234567890123 L=3', F.BigInteger(V, 3, -1));
        Observer.Observe('bigint 1234567890123 L=10', F.BigInteger(V, 10, -1));
        Observer.Observe('bigint 1234567890123 L=30', F.BigInteger(V, 30, -1));
        Observer.Observe('bigint 1234567890123 L=-1', F.BigInteger(V, -1, -1));
        Observer.Observe('bigint 1234567890123 L=-3', F.BigInteger(V, -3, -1));
        Observer.Observe('bigint 1234567890123 L=-10', F.BigInteger(V, -10, -1));
        Observer.Observe('bigint 1234567890123 L=-30', F.BigInteger(V, -30, -1));
        Observer.Observe('bigint 1234567890123 L=exact', F.BigInteger(V, StrLen(Format(V)), -1));
        Observer.Observe('bigint 1234567890123 L=-exact', F.BigInteger(V, -StrLen(Format(V)), -1));
        Observer.Observe('bigint 1234567890123 L=exact+1', F.BigInteger(V, StrLen(Format(V)) + 1, -1));
        Observer.Observe('bigint 1234567890123 L=-(exact+1)', F.BigInteger(V, -(StrLen(Format(V)) + 1), -1));
        Observer.Observe('bigint 1234567890123 L=exact-1', F.BigInteger(V, StrLen(Format(V)) - 1, -1));
        Observer.Observe('bigint 1234567890123 L=-(exact-1)', F.BigInteger(V, -(StrLen(Format(V)) - 1), -1));
        Observer.Expect('bigint 1234567890123 plain', '[1234567890123]');
        Observer.Expect('bigint 1234567890123 L=1', '[1]');
        Observer.Expect('bigint 1234567890123 L=3', '[123]');
        Observer.Expect('bigint 1234567890123 L=10', '[1234567890]');
        Observer.Expect('bigint 1234567890123 L=30', '[                 1234567890123]');
        Observer.Expect('bigint 1234567890123 L=-1', '[1]');
        Observer.Expect('bigint 1234567890123 L=-3', '[123]');
        Observer.Expect('bigint 1234567890123 L=-10', '[1234567890]');
        Observer.Expect('bigint 1234567890123 L=-30', '[1234567890123]');
        Observer.Expect('bigint 1234567890123 L=exact', '[1234567890123]');
        Observer.Expect('bigint 1234567890123 L=-exact', '[1234567890123]');
        Observer.Expect('bigint 1234567890123 L=exact+1', '[ 1234567890123]');
        Observer.Expect('bigint 1234567890123 L=-(exact+1)', '[1234567890123]');
        Observer.Expect('bigint 1234567890123 L=exact-1', '[123456789012]');
        Observer.Expect('bigint 1234567890123 L=-(exact-1)', '[123456789012]');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_Length_Number()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: BigInteger;
    begin
        V := 1234567890123L;
        Observer.Observe('bigint 1234567890123 plain N=9', '[' + Format(V, 0, 9) + ']');
        Observer.Observe('bigint 1234567890123 L=3 N=9', F.BigInteger(V, 3, 9));
        Observer.Observe('bigint 1234567890123 L=30 N=9', F.BigInteger(V, 30, 9));
        Observer.Observe('bigint 1234567890123 L=-3 N=9', F.BigInteger(V, -3, 9));
        Observer.Observe('bigint 1234567890123 L=-30 N=9', F.BigInteger(V, -30, 9));
        Observer.Observe('bigint 1234567890123 L=3 N=0', F.BigInteger(V, 3, 0));
        Observer.Observe('bigint 1234567890123 L=30 N=0', F.BigInteger(V, 30, 0));
        Observer.Observe('bigint 1234567890123 L=-3 N=0', F.BigInteger(V, -3, 0));
        Observer.Observe('bigint 1234567890123 L=-30 N=0', F.BigInteger(V, -30, 0));
        V := -42L;
        Observer.Observe('bigint -42 plain', '[' + Format(V) + ']');
        Observer.Observe('bigint -42 L=3', F.BigInteger(V, 3, -1));
        Observer.Observe('bigint -42 L=30', F.BigInteger(V, 30, -1));
        Observer.Observe('bigint -42 L=-3', F.BigInteger(V, -3, -1));
        Observer.Observe('bigint -42 L=-30', F.BigInteger(V, -30, -1));
        Observer.Observe('bigint -42 L=exact', F.BigInteger(V, StrLen(Format(V)), -1));
        Observer.Observe('bigint -42 L=-exact', F.BigInteger(V, -StrLen(Format(V)), -1));
        Observer.Expect('bigint 1234567890123 plain N=9', '[1234567890123]');
        Observer.Expect('bigint 1234567890123 L=3 N=9', '[123]');
        Observer.Expect('bigint 1234567890123 L=30 N=9', '[                 1234567890123]');
        Observer.Expect('bigint 1234567890123 L=-3 N=9', '[123]');
        Observer.Expect('bigint 1234567890123 L=-30 N=9', '[1234567890123]');
        Observer.Expect('bigint 1234567890123 L=3 N=0', '[123]');
        Observer.Expect('bigint 1234567890123 L=30 N=0', '[                 1234567890123]');
        Observer.Expect('bigint 1234567890123 L=-3 N=0', '[123]');
        Observer.Expect('bigint 1234567890123 L=-30 N=0', '[1234567890123]');
        Observer.Expect('bigint -42 plain', '[-42]');
        Observer.Expect('bigint -42 L=3', '[-42]');
        Observer.Expect('bigint -42 L=30', '[                           -42]');
        Observer.Expect('bigint -42 L=-3', '[-42]');
        Observer.Expect('bigint -42 L=-30', '[-42]');
        Observer.Expect('bigint -42 L=exact', '[-42]');
        Observer.Expect('bigint -42 L=-exact', '[-42]');
        Observer.Verify();
    end;

    [Test]
    procedure Time_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Time;
    begin
        V := 134501T;
        Observer.Observe('time 134501T plain', '[' + Format(V) + ']');
        Observer.Observe('time 134501T L=1', F.Time(V, 1, -1));
        Observer.Observe('time 134501T L=3', F.Time(V, 3, -1));
        Observer.Observe('time 134501T L=10', F.Time(V, 10, -1));
        Observer.Observe('time 134501T L=30', F.Time(V, 30, -1));
        Observer.Observe('time 134501T L=-1', F.Time(V, -1, -1));
        Observer.Observe('time 134501T L=-3', F.Time(V, -3, -1));
        Observer.Observe('time 134501T L=-10', F.Time(V, -10, -1));
        Observer.Observe('time 134501T L=-30', F.Time(V, -30, -1));
        Observer.Observe('time 134501T L=exact', F.Time(V, StrLen(Format(V)), -1));
        Observer.Observe('time 134501T L=-exact', F.Time(V, -StrLen(Format(V)), -1));
        Observer.Observe('time 134501T L=exact+1', F.Time(V, StrLen(Format(V)) + 1, -1));
        Observer.Observe('time 134501T L=-(exact+1)', F.Time(V, -(StrLen(Format(V)) + 1), -1));
        Observer.Observe('time 134501T L=exact-1', F.Time(V, StrLen(Format(V)) - 1, -1));
        Observer.Observe('time 134501T L=-(exact-1)', F.Time(V, -(StrLen(Format(V)) - 1), -1));
        Observer.Expect('time 134501T plain', '[ 1:45:01 PM]');
        Observer.Expect('time 134501T L=1', '[ ]');
        Observer.Expect('time 134501T L=3', '[ 1:]');
        Observer.Expect('time 134501T L=10', '[ 1:45:01 P]');
        Observer.Expect('time 134501T L=30', '[                    1:45:01 PM]');
        Observer.Expect('time 134501T L=-1', '[ ]');
        Observer.Expect('time 134501T L=-3', '[ 1:]');
        Observer.Expect('time 134501T L=-10', '[ 1:45:01 P]');
        Observer.Expect('time 134501T L=-30', '[ 1:45:01 PM]');
        Observer.Expect('time 134501T L=exact', '[ 1:45:01 PM]');
        Observer.Expect('time 134501T L=-exact', '[ 1:45:01 PM]');
        Observer.Expect('time 134501T L=exact+1', '[  1:45:01 PM]');
        Observer.Expect('time 134501T L=-(exact+1)', '[ 1:45:01 PM]');
        Observer.Expect('time 134501T L=exact-1', '[ 1:45:01 P]');
        Observer.Expect('time 134501T L=-(exact-1)', '[ 1:45:01 P]');
        Observer.Verify();
    end;

    [Test]
    procedure Time_Length_Number()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Time;
    begin
        V := 134501T;
        Observer.Observe('time 134501T plain N=9', '[' + Format(V, 0, 9) + ']');
        Observer.Observe('time 134501T L=3 N=9', F.Time(V, 3, 9));
        Observer.Observe('time 134501T L=30 N=9', F.Time(V, 30, 9));
        Observer.Observe('time 134501T L=-3 N=9', F.Time(V, -3, 9));
        Observer.Observe('time 134501T L=-30 N=9', F.Time(V, -30, 9));
        Observer.Observe('time 134501T L=3 N=0', F.Time(V, 3, 0));
        Observer.Observe('time 134501T L=30 N=0', F.Time(V, 30, 0));
        Observer.Observe('time 134501T L=-3 N=0', F.Time(V, -3, 0));
        Observer.Observe('time 134501T L=-30 N=0', F.Time(V, -30, 0));
        V := 0T;
        Observer.Observe('time 0T plain', '[' + Format(V) + ']');
        Observer.Observe('time 0T L=3', F.Time(V, 3, -1));
        Observer.Observe('time 0T L=30', F.Time(V, 30, -1));
        Observer.Observe('time 0T L=-3', F.Time(V, -3, -1));
        Observer.Observe('time 0T L=-30', F.Time(V, -30, -1));
        Observer.Observe('time 0T L=exact', F.Time(V, StrLen(Format(V)), -1));
        Observer.Observe('time 0T L=-exact', F.Time(V, -StrLen(Format(V)), -1));
        Observer.Expect('time 134501T plain N=9', '[13:45:01]');
        Observer.Expect('time 134501T L=3 N=9', '[13:]');
        Observer.Expect('time 134501T L=30 N=9', '[                      13:45:01]');
        Observer.Expect('time 134501T L=-3 N=9', '[13:]');
        Observer.Expect('time 134501T L=-30 N=9', '[13:45:01]');
        Observer.Expect('time 134501T L=3 N=0', '[ 1:]');
        Observer.Expect('time 134501T L=30 N=0', '[                    1:45:01 PM]');
        Observer.Expect('time 134501T L=-3 N=0', '[ 1:]');
        Observer.Expect('time 134501T L=-30 N=0', '[ 1:45:01 PM]');
        Observer.Expect('time 0T plain', '[]');
        Observer.Expect('time 0T L=3', '[   ]');
        Observer.Expect('time 0T L=30', '[                              ]');
        Observer.Expect('time 0T L=-3', '[]');
        Observer.Expect('time 0T L=-30', '[]');
        Observer.Expect('time 0T L=exact', '[]');
        Observer.Expect('time 0T L=-exact', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Code_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Code[20];
    begin
        V := 'ABC12';
        Observer.Observe('code ABC12 plain', '[' + Format(V) + ']');
        Observer.Observe('code ABC12 L=1', F.Code(V, 1, -1));
        Observer.Observe('code ABC12 L=3', F.Code(V, 3, -1));
        Observer.Observe('code ABC12 L=10', F.Code(V, 10, -1));
        Observer.Observe('code ABC12 L=30', F.Code(V, 30, -1));
        Observer.Observe('code ABC12 L=-1', F.Code(V, -1, -1));
        Observer.Observe('code ABC12 L=-3', F.Code(V, -3, -1));
        Observer.Observe('code ABC12 L=-10', F.Code(V, -10, -1));
        Observer.Observe('code ABC12 L=-30', F.Code(V, -30, -1));
        Observer.Observe('code ABC12 L=exact', F.Code(V, StrLen(Format(V)), -1));
        Observer.Observe('code ABC12 L=-exact', F.Code(V, -StrLen(Format(V)), -1));
        Observer.Observe('code ABC12 L=exact+1', F.Code(V, StrLen(Format(V)) + 1, -1));
        Observer.Observe('code ABC12 L=-(exact+1)', F.Code(V, -(StrLen(Format(V)) + 1), -1));
        Observer.Observe('code ABC12 L=exact-1', F.Code(V, StrLen(Format(V)) - 1, -1));
        Observer.Observe('code ABC12 L=-(exact-1)', F.Code(V, -(StrLen(Format(V)) - 1), -1));
        Observer.Expect('code ABC12 plain', '[ABC12]');
        Observer.Expect('code ABC12 L=1', '[A]');
        Observer.Expect('code ABC12 L=3', '[ABC]');
        Observer.Expect('code ABC12 L=10', '[ABC12     ]');
        Observer.Expect('code ABC12 L=30', '[ABC12                         ]');
        Observer.Expect('code ABC12 L=-1', '[A]');
        Observer.Expect('code ABC12 L=-3', '[ABC]');
        Observer.Expect('code ABC12 L=-10', '[ABC12]');
        Observer.Expect('code ABC12 L=-30', '[ABC12]');
        Observer.Expect('code ABC12 L=exact', '[ABC12]');
        Observer.Expect('code ABC12 L=-exact', '[ABC12]');
        Observer.Expect('code ABC12 L=exact+1', '[ABC12 ]');
        Observer.Expect('code ABC12 L=-(exact+1)', '[ABC12]');
        Observer.Expect('code ABC12 L=exact-1', '[ABC1]');
        Observer.Expect('code ABC12 L=-(exact-1)', '[ABC1]');
        Observer.Verify();
    end;

    [Test]
    procedure Code_Length_Number()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Code[20];
    begin
        V := 'ABC12';
        Observer.Observe('code ABC12 plain N=9', '[' + Format(V, 0, 9) + ']');
        Observer.Observe('code ABC12 L=3 N=9', F.Code(V, 3, 9));
        Observer.Observe('code ABC12 L=30 N=9', F.Code(V, 30, 9));
        Observer.Observe('code ABC12 L=-3 N=9', F.Code(V, -3, 9));
        Observer.Observe('code ABC12 L=-30 N=9', F.Code(V, -30, 9));
        Observer.Observe('code ABC12 L=3 N=0', F.Code(V, 3, 0));
        Observer.Observe('code ABC12 L=30 N=0', F.Code(V, 30, 0));
        Observer.Observe('code ABC12 L=-3 N=0', F.Code(V, -3, 0));
        Observer.Observe('code ABC12 L=-30 N=0', F.Code(V, -30, 0));
        V := '';
        Observer.Observe('code empty plain', '[' + Format(V) + ']');
        Observer.Observe('code empty L=3', F.Code(V, 3, -1));
        Observer.Observe('code empty L=30', F.Code(V, 30, -1));
        Observer.Observe('code empty L=-3', F.Code(V, -3, -1));
        Observer.Observe('code empty L=-30', F.Code(V, -30, -1));
        Observer.Observe('code empty L=exact', F.Code(V, StrLen(Format(V)), -1));
        Observer.Observe('code empty L=-exact', F.Code(V, -StrLen(Format(V)), -1));
        Observer.Expect('code ABC12 plain N=9', '[ABC12]');
        Observer.Expect('code ABC12 L=3 N=9', '[ABC]');
        Observer.Expect('code ABC12 L=30 N=9', '[ABC12                         ]');
        Observer.Expect('code ABC12 L=-3 N=9', '[ABC]');
        Observer.Expect('code ABC12 L=-30 N=9', '[ABC12]');
        Observer.Expect('code ABC12 L=3 N=0', '[ABC]');
        Observer.Expect('code ABC12 L=30 N=0', '[ABC12                         ]');
        Observer.Expect('code ABC12 L=-3 N=0', '[ABC]');
        Observer.Expect('code ABC12 L=-30 N=0', '[ABC12]');
        Observer.Expect('code empty plain', '[]');
        Observer.Expect('code empty L=3', '[   ]');
        Observer.Expect('code empty L=30', '[                              ]');
        Observer.Expect('code empty L=-3', '[]');
        Observer.Expect('code empty L=-30', '[]');
        Observer.Expect('code empty L=exact', '[]');
        Observer.Expect('code empty L=-exact', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Guid_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Guid;
    begin
        Evaluate(V, '{6F9619FF-8B86-D011-B42D-00C04FC964FF}');
        Observer.Observe('guid 6F9619FF plain', '[' + Format(V) + ']');
        Observer.Observe('guid 6F9619FF L=1', F.Guid(V, 1, -1));
        Observer.Observe('guid 6F9619FF L=3', F.Guid(V, 3, -1));
        Observer.Observe('guid 6F9619FF L=10', F.Guid(V, 10, -1));
        Observer.Observe('guid 6F9619FF L=30', F.Guid(V, 30, -1));
        Observer.Observe('guid 6F9619FF L=-1', F.Guid(V, -1, -1));
        Observer.Observe('guid 6F9619FF L=-3', F.Guid(V, -3, -1));
        Observer.Observe('guid 6F9619FF L=-10', F.Guid(V, -10, -1));
        Observer.Observe('guid 6F9619FF L=-30', F.Guid(V, -30, -1));
        Observer.Observe('guid 6F9619FF L=exact', F.Guid(V, StrLen(Format(V)), -1));
        Observer.Observe('guid 6F9619FF L=-exact', F.Guid(V, -StrLen(Format(V)), -1));
        Observer.Observe('guid 6F9619FF L=exact+1', F.Guid(V, StrLen(Format(V)) + 1, -1));
        Observer.Observe('guid 6F9619FF L=-(exact+1)', F.Guid(V, -(StrLen(Format(V)) + 1), -1));
        Observer.Observe('guid 6F9619FF L=exact-1', F.Guid(V, StrLen(Format(V)) - 1, -1));
        Observer.Observe('guid 6F9619FF L=-(exact-1)', F.Guid(V, -(StrLen(Format(V)) - 1), -1));
        Observer.Expect('guid 6F9619FF plain', '[{6F9619FF-8B86-D011-B42D-00C04FC964FF}]');
        Observer.Expect('guid 6F9619FF L=1', '[{]');
        Observer.Expect('guid 6F9619FF L=3', '[{6F]');
        Observer.Expect('guid 6F9619FF L=10', '[{6F9619FF-]');
        Observer.Expect('guid 6F9619FF L=30', '[{6F9619FF-8B86-D011-B42D-00C04]');
        Observer.Expect('guid 6F9619FF L=-1', '[{]');
        Observer.Expect('guid 6F9619FF L=-3', '[{6F]');
        Observer.Expect('guid 6F9619FF L=-10', '[{6F9619FF-]');
        Observer.Expect('guid 6F9619FF L=-30', '[{6F9619FF-8B86-D011-B42D-00C04]');
        Observer.Expect('guid 6F9619FF L=exact', '[{6F9619FF-8B86-D011-B42D-00C04FC964FF}]');
        Observer.Expect('guid 6F9619FF L=-exact', '[{6F9619FF-8B86-D011-B42D-00C04FC964FF}]');
        Observer.Expect('guid 6F9619FF L=exact+1', '[{6F9619FF-8B86-D011-B42D-00C04FC964FF} ]');
        Observer.Expect('guid 6F9619FF L=-(exact+1)', '[{6F9619FF-8B86-D011-B42D-00C04FC964FF}]');
        Observer.Expect('guid 6F9619FF L=exact-1', '[{6F9619FF-8B86-D011-B42D-00C04FC964FF]');
        Observer.Expect('guid 6F9619FF L=-(exact-1)', '[{6F9619FF-8B86-D011-B42D-00C04FC964FF]');
        Observer.Verify();
    end;

    [Test]
    procedure Guid_Length_Number()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Guid;
    begin
        Evaluate(V, '{6F9619FF-8B86-D011-B42D-00C04FC964FF}');
        Observer.Observe('guid 6F9619FF plain N=9', '[' + Format(V, 0, 9) + ']');
        Observer.Observe('guid 6F9619FF L=3 N=9', F.Guid(V, 3, 9));
        Observer.Observe('guid 6F9619FF L=30 N=9', F.Guid(V, 30, 9));
        Observer.Observe('guid 6F9619FF L=-3 N=9', F.Guid(V, -3, 9));
        Observer.Observe('guid 6F9619FF L=-30 N=9', F.Guid(V, -30, 9));
        Observer.Observe('guid 6F9619FF L=3 N=0', F.Guid(V, 3, 0));
        Observer.Observe('guid 6F9619FF L=30 N=0', F.Guid(V, 30, 0));
        Observer.Observe('guid 6F9619FF L=-3 N=0', F.Guid(V, -3, 0));
        Observer.Observe('guid 6F9619FF L=-30 N=0', F.Guid(V, -30, 0));
        Clear(V);
        Observer.Observe('guid null plain', '[' + Format(V) + ']');
        Observer.Observe('guid null L=3', F.Guid(V, 3, -1));
        Observer.Observe('guid null L=30', F.Guid(V, 30, -1));
        Observer.Observe('guid null L=-3', F.Guid(V, -3, -1));
        Observer.Observe('guid null L=-30', F.Guid(V, -30, -1));
        Observer.Observe('guid null L=exact', F.Guid(V, StrLen(Format(V)), -1));
        Observer.Observe('guid null L=-exact', F.Guid(V, -StrLen(Format(V)), -1));
        Observer.Expect('guid 6F9619FF plain N=9', '[{6F9619FF-8B86-D011-B42D-00C04FC964FF}]');
        Observer.Expect('guid 6F9619FF L=3 N=9', '[{6F]');
        Observer.Expect('guid 6F9619FF L=30 N=9', '[{6F9619FF-8B86-D011-B42D-00C04]');
        Observer.Expect('guid 6F9619FF L=-3 N=9', '[{6F]');
        Observer.Expect('guid 6F9619FF L=-30 N=9', '[{6F9619FF-8B86-D011-B42D-00C04]');
        Observer.Expect('guid 6F9619FF L=3 N=0', '[{6F]');
        Observer.Expect('guid 6F9619FF L=30 N=0', '[{6F9619FF-8B86-D011-B42D-00C04]');
        Observer.Expect('guid 6F9619FF L=-3 N=0', '[{6F]');
        Observer.Expect('guid 6F9619FF L=-30 N=0', '[{6F9619FF-8B86-D011-B42D-00C04]');
        Observer.Expect('guid null plain', '[{00000000-0000-0000-0000-000000000000}]');
        Observer.Expect('guid null L=3', '[{00]');
        Observer.Expect('guid null L=30', '[{00000000-0000-0000-0000-00000]');
        Observer.Expect('guid null L=-3', '[{00]');
        Observer.Expect('guid null L=-30', '[{00000000-0000-0000-0000-00000]');
        Observer.Expect('guid null L=exact', '[{00000000-0000-0000-0000-000000000000}]');
        Observer.Expect('guid null L=-exact', '[{00000000-0000-0000-0000-000000000000}]');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Integer;
    begin
        V := 1234567;
        Observer.Observe('int 1234567 plain', '[' + Format(V) + ']');
        Observer.Observe('int 1234567 L=1', F.Integer(V, 1, -1));
        Observer.Observe('int 1234567 L=3', F.Integer(V, 3, -1));
        Observer.Observe('int 1234567 L=10', F.Integer(V, 10, -1));
        Observer.Observe('int 1234567 L=30', F.Integer(V, 30, -1));
        Observer.Observe('int 1234567 L=-1', F.Integer(V, -1, -1));
        Observer.Observe('int 1234567 L=-3', F.Integer(V, -3, -1));
        Observer.Observe('int 1234567 L=-10', F.Integer(V, -10, -1));
        Observer.Observe('int 1234567 L=-30', F.Integer(V, -30, -1));
        Observer.Observe('int 1234567 L=exact', F.Integer(V, StrLen(Format(V)), -1));
        Observer.Observe('int 1234567 L=-exact', F.Integer(V, -StrLen(Format(V)), -1));
        Observer.Observe('int 1234567 L=exact+1', F.Integer(V, StrLen(Format(V)) + 1, -1));
        Observer.Observe('int 1234567 L=-(exact+1)', F.Integer(V, -(StrLen(Format(V)) + 1), -1));
        Observer.Observe('int 1234567 L=exact-1', F.Integer(V, StrLen(Format(V)) - 1, -1));
        Observer.Observe('int 1234567 L=-(exact-1)', F.Integer(V, -(StrLen(Format(V)) - 1), -1));
        Observer.Expect('int 1234567 plain', '[1234567]');
        Observer.Expect('int 1234567 L=1', '[1]');
        Observer.Expect('int 1234567 L=3', '[123]');
        Observer.Expect('int 1234567 L=10', '[   1234567]');
        Observer.Expect('int 1234567 L=30', '[                       1234567]');
        Observer.Expect('int 1234567 L=-1', '[1]');
        Observer.Expect('int 1234567 L=-3', '[123]');
        Observer.Expect('int 1234567 L=-10', '[1234567]');
        Observer.Expect('int 1234567 L=-30', '[1234567]');
        Observer.Expect('int 1234567 L=exact', '[1234567]');
        Observer.Expect('int 1234567 L=-exact', '[1234567]');
        Observer.Expect('int 1234567 L=exact+1', '[ 1234567]');
        Observer.Expect('int 1234567 L=-(exact+1)', '[1234567]');
        Observer.Expect('int 1234567 L=exact-1', '[123456]');
        Observer.Expect('int 1234567 L=-(exact-1)', '[123456]');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_Length_Number()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Integer;
    begin
        V := 1234567;
        Observer.Observe('int 1234567 plain N=9', '[' + Format(V, 0, 9) + ']');
        Observer.Observe('int 1234567 L=3 N=9', F.Integer(V, 3, 9));
        Observer.Observe('int 1234567 L=30 N=9', F.Integer(V, 30, 9));
        Observer.Observe('int 1234567 L=-3 N=9', F.Integer(V, -3, 9));
        Observer.Observe('int 1234567 L=-30 N=9', F.Integer(V, -30, 9));
        Observer.Observe('int 1234567 L=3 N=0', F.Integer(V, 3, 0));
        Observer.Observe('int 1234567 L=30 N=0', F.Integer(V, 30, 0));
        Observer.Observe('int 1234567 L=-3 N=0', F.Integer(V, -3, 0));
        Observer.Observe('int 1234567 L=-30 N=0', F.Integer(V, -30, 0));
        V := -42;
        Observer.Observe('int -42 plain', '[' + Format(V) + ']');
        Observer.Observe('int -42 L=3', F.Integer(V, 3, -1));
        Observer.Observe('int -42 L=30', F.Integer(V, 30, -1));
        Observer.Observe('int -42 L=-3', F.Integer(V, -3, -1));
        Observer.Observe('int -42 L=-30', F.Integer(V, -30, -1));
        Observer.Observe('int -42 L=exact', F.Integer(V, StrLen(Format(V)), -1));
        Observer.Observe('int -42 L=-exact', F.Integer(V, -StrLen(Format(V)), -1));
        Observer.Expect('int 1234567 plain N=9', '[1234567]');
        Observer.Expect('int 1234567 L=3 N=9', '[123]');
        Observer.Expect('int 1234567 L=30 N=9', '[                       1234567]');
        Observer.Expect('int 1234567 L=-3 N=9', '[123]');
        Observer.Expect('int 1234567 L=-30 N=9', '[1234567]');
        Observer.Expect('int 1234567 L=3 N=0', '[123]');
        Observer.Expect('int 1234567 L=30 N=0', '[                       1234567]');
        Observer.Expect('int 1234567 L=-3 N=0', '[123]');
        Observer.Expect('int 1234567 L=-30 N=0', '[1234567]');
        Observer.Expect('int -42 plain', '[-42]');
        Observer.Expect('int -42 L=3', '[-42]');
        Observer.Expect('int -42 L=30', '[                           -42]');
        Observer.Expect('int -42 L=-3', '[-42]');
        Observer.Expect('int -42 L=-30', '[-42]');
        Observer.Expect('int -42 L=exact', '[-42]');
        Observer.Expect('int -42 L=-exact', '[-42]');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Decimal;
    begin
        V := 1234.5;
        Observer.Observe('dec 1234.5 plain', '[' + Format(V) + ']');
        Observer.Observe('dec 1234.5 L=1', F.Decimal(V, 1, -1));
        Observer.Observe('dec 1234.5 L=3', F.Decimal(V, 3, -1));
        Observer.Observe('dec 1234.5 L=10', F.Decimal(V, 10, -1));
        Observer.Observe('dec 1234.5 L=30', F.Decimal(V, 30, -1));
        Observer.Observe('dec 1234.5 L=-1', F.Decimal(V, -1, -1));
        Observer.Observe('dec 1234.5 L=-3', F.Decimal(V, -3, -1));
        Observer.Observe('dec 1234.5 L=-10', F.Decimal(V, -10, -1));
        Observer.Observe('dec 1234.5 L=-30', F.Decimal(V, -30, -1));
        Observer.Observe('dec 1234.5 L=exact', F.Decimal(V, StrLen(Format(V)), -1));
        Observer.Observe('dec 1234.5 L=-exact', F.Decimal(V, -StrLen(Format(V)), -1));
        Observer.Observe('dec 1234.5 L=exact+1', F.Decimal(V, StrLen(Format(V)) + 1, -1));
        Observer.Observe('dec 1234.5 L=-(exact+1)', F.Decimal(V, -(StrLen(Format(V)) + 1), -1));
        Observer.Observe('dec 1234.5 L=exact-1', F.Decimal(V, StrLen(Format(V)) - 1, -1));
        Observer.Observe('dec 1234.5 L=-(exact-1)', F.Decimal(V, -(StrLen(Format(V)) - 1), -1));
        Observer.Expect('dec 1234.5 plain', '[1,234.5]');
        Observer.Expect('dec 1234.5 L=1', '[1]');
        Observer.Expect('dec 1234.5 L=3', '[1,2]');
        Observer.Expect('dec 1234.5 L=10', '[   1,234.5]');
        Observer.Expect('dec 1234.5 L=30', '[                       1,234.5]');
        Observer.Expect('dec 1234.5 L=-1', '[1]');
        Observer.Expect('dec 1234.5 L=-3', '[1,2]');
        Observer.Expect('dec 1234.5 L=-10', '[1,234.5]');
        Observer.Expect('dec 1234.5 L=-30', '[1,234.5]');
        Observer.Expect('dec 1234.5 L=exact', '[1,234.5]');
        Observer.Expect('dec 1234.5 L=-exact', '[1,234.5]');
        Observer.Expect('dec 1234.5 L=exact+1', '[ 1,234.5]');
        Observer.Expect('dec 1234.5 L=-(exact+1)', '[1,234.5]');
        Observer.Expect('dec 1234.5 L=exact-1', '[1,234.]');
        Observer.Expect('dec 1234.5 L=-(exact-1)', '[1,234.]');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Length_Number()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Decimal;
    begin
        V := 1234.5;
        Observer.Observe('dec 1234.5 plain N=9', '[' + Format(V, 0, 9) + ']');
        Observer.Observe('dec 1234.5 L=3 N=9', F.Decimal(V, 3, 9));
        Observer.Observe('dec 1234.5 L=30 N=9', F.Decimal(V, 30, 9));
        Observer.Observe('dec 1234.5 L=-3 N=9', F.Decimal(V, -3, 9));
        Observer.Observe('dec 1234.5 L=-30 N=9', F.Decimal(V, -30, 9));
        Observer.Observe('dec 1234.5 L=3 N=0', F.Decimal(V, 3, 0));
        Observer.Observe('dec 1234.5 L=30 N=0', F.Decimal(V, 30, 0));
        Observer.Observe('dec 1234.5 L=-3 N=0', F.Decimal(V, -3, 0));
        Observer.Observe('dec 1234.5 L=-30 N=0', F.Decimal(V, -30, 0));
        V := -0.25;
        Observer.Observe('dec -0.25 plain', '[' + Format(V) + ']');
        Observer.Observe('dec -0.25 L=3', F.Decimal(V, 3, -1));
        Observer.Observe('dec -0.25 L=30', F.Decimal(V, 30, -1));
        Observer.Observe('dec -0.25 L=-3', F.Decimal(V, -3, -1));
        Observer.Observe('dec -0.25 L=-30', F.Decimal(V, -30, -1));
        Observer.Observe('dec -0.25 L=exact', F.Decimal(V, StrLen(Format(V)), -1));
        Observer.Observe('dec -0.25 L=-exact', F.Decimal(V, -StrLen(Format(V)), -1));
        Observer.Expect('dec 1234.5 plain N=9', '[1234.5]');
        Observer.Expect('dec 1234.5 L=3 N=9', '[123]');
        Observer.Expect('dec 1234.5 L=30 N=9', '[                        1234.5]');
        Observer.Expect('dec 1234.5 L=-3 N=9', '[123]');
        Observer.Expect('dec 1234.5 L=-30 N=9', '[1234.5]');
        Observer.Expect('dec 1234.5 L=3 N=0', '[1,2]');
        Observer.Expect('dec 1234.5 L=30 N=0', '[                       1,234.5]');
        Observer.Expect('dec 1234.5 L=-3 N=0', '[1,2]');
        Observer.Expect('dec 1234.5 L=-30 N=0', '[1,234.5]');
        Observer.Expect('dec -0.25 plain', '[-0.25]');
        Observer.Expect('dec -0.25 L=3', '[-0.]');
        Observer.Expect('dec -0.25 L=30', '[                         -0.25]');
        Observer.Expect('dec -0.25 L=-3', '[-0.]');
        Observer.Expect('dec -0.25 L=-30', '[-0.25]');
        Observer.Expect('dec -0.25 L=exact', '[-0.25]');
        Observer.Expect('dec -0.25 L=-exact', '[-0.25]');
        Observer.Verify();
    end;

    [Test]
    procedure Text_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Text;
    begin
        V := 'abcde';
        Observer.Observe('text abcde plain', '[' + Format(V) + ']');
        Observer.Observe('text abcde L=1', F.Text(V, 1, -1));
        Observer.Observe('text abcde L=3', F.Text(V, 3, -1));
        Observer.Observe('text abcde L=10', F.Text(V, 10, -1));
        Observer.Observe('text abcde L=30', F.Text(V, 30, -1));
        Observer.Observe('text abcde L=-1', F.Text(V, -1, -1));
        Observer.Observe('text abcde L=-3', F.Text(V, -3, -1));
        Observer.Observe('text abcde L=-10', F.Text(V, -10, -1));
        Observer.Observe('text abcde L=-30', F.Text(V, -30, -1));
        Observer.Observe('text abcde L=exact', F.Text(V, StrLen(Format(V)), -1));
        Observer.Observe('text abcde L=-exact', F.Text(V, -StrLen(Format(V)), -1));
        Observer.Observe('text abcde L=exact+1', F.Text(V, StrLen(Format(V)) + 1, -1));
        Observer.Observe('text abcde L=-(exact+1)', F.Text(V, -(StrLen(Format(V)) + 1), -1));
        Observer.Observe('text abcde L=exact-1', F.Text(V, StrLen(Format(V)) - 1, -1));
        Observer.Observe('text abcde L=-(exact-1)', F.Text(V, -(StrLen(Format(V)) - 1), -1));
        Observer.Expect('text abcde plain', '[abcde]');
        Observer.Expect('text abcde L=1', '[a]');
        Observer.Expect('text abcde L=3', '[abc]');
        Observer.Expect('text abcde L=10', '[abcde     ]');
        Observer.Expect('text abcde L=30', '[abcde                         ]');
        Observer.Expect('text abcde L=-1', '[a]');
        Observer.Expect('text abcde L=-3', '[abc]');
        Observer.Expect('text abcde L=-10', '[abcde]');
        Observer.Expect('text abcde L=-30', '[abcde]');
        Observer.Expect('text abcde L=exact', '[abcde]');
        Observer.Expect('text abcde L=-exact', '[abcde]');
        Observer.Expect('text abcde L=exact+1', '[abcde ]');
        Observer.Expect('text abcde L=-(exact+1)', '[abcde]');
        Observer.Expect('text abcde L=exact-1', '[abcd]');
        Observer.Expect('text abcde L=-(exact-1)', '[abcd]');
        Observer.Verify();
    end;

    [Test]
    procedure Text_Length_Number()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Text;
    begin
        V := 'abcde';
        Observer.Observe('text abcde plain N=9', '[' + Format(V, 0, 9) + ']');
        Observer.Observe('text abcde L=3 N=9', F.Text(V, 3, 9));
        Observer.Observe('text abcde L=30 N=9', F.Text(V, 30, 9));
        Observer.Observe('text abcde L=-3 N=9', F.Text(V, -3, 9));
        Observer.Observe('text abcde L=-30 N=9', F.Text(V, -30, 9));
        Observer.Observe('text abcde L=3 N=0', F.Text(V, 3, 0));
        Observer.Observe('text abcde L=30 N=0', F.Text(V, 30, 0));
        Observer.Observe('text abcde L=-3 N=0', F.Text(V, -3, 0));
        Observer.Observe('text abcde L=-30 N=0', F.Text(V, -30, 0));
        Observer.Expect('text abcde plain N=9', '[abcde]');
        Observer.Expect('text abcde L=3 N=9', '[abc]');
        Observer.Expect('text abcde L=30 N=9', '[abcde                         ]');
        Observer.Expect('text abcde L=-3 N=9', '[abc]');
        Observer.Expect('text abcde L=-30 N=9', '[abcde]');
        Observer.Expect('text abcde L=3 N=0', '[abc]');
        Observer.Expect('text abcde L=30 N=0', '[abcde                         ]');
        Observer.Expect('text abcde L=-3 N=0', '[abc]');
        Observer.Expect('text abcde L=-30 N=0', '[abcde]');
        Observer.Verify();
    end;

    local procedure CharCode(Value: Text): Integer
    var
        C: Char;
    begin
        if Value = '' then
            exit(-1);
        C := Value[1];
        exit(C);
    end;
}
