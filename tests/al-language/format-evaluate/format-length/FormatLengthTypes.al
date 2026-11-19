// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-integer-string-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); helper codeunit 96388 "FLN Fmt" (FormatLengthHelper.al)
// Probe: observe form (values not yet asserted).
// Facts: Format(Value, Length) and Format(Value, Length, 0 | 9) of a Duration, Char, Byte, BigInteger, Time, Code, Guid, Integer, Decimal and Text,
//   for lengths 1, 3, 10, 30, their negatives, and the text's own length, one more and one less, positive and negative.
// BC versions: measured locally, checked by the corpus CI matrix

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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
