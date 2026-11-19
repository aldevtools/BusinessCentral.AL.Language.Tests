// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-integer-string-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); helper codeunit 96388 "FLN Fmt" (FormatLengthHelper.al); own temporary table 96395
// Probe: written against a local BC 27.5 service tier (Windows); every literal asserted below is what BC produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format(Value, Length, FormatString) for the shapes the format-length probes left open:
//   - the Tests-Data Exchange shape Format(D, 6, '<Day,2><Month,2><Year,2>') with lengths shorter than, as long as and longer than the text, both signs,
//     for a defined Date, a closing date, 0D and a Date table field;
//   - a defined Time in Format(T, L), Format(T, L, 0) and Format(T, L, '<Standard Format,0>'), lengths shorter, as long, longer, both signs;
//   - a text exactly as long as the length under '<Standard Format,0>' (and '<Standard Format,9>' for a Date), both signs, for every scalar type;
//   - a Decimal, an Integer, a Text and a defined Date under the format strings other corpus lines use with a length, lengths shorter, as long and
//     longer, both signs; 0DT and 0D under those format strings.
// Results (BC 27.5): every cell follows the same length rule as Format(Value, Length) without a format string: a length shorter than the text cuts it
//   to its first |L| characters, whatever the sign; a length equal to the text keeps it, both signs; a longer positive length pads on the left for a
//   Date, Time, Decimal and Integer and on the right for a Text and a Code under '<Text>'; a longer negative length keeps the text.
//   Format(15.01.2024, 6, '<Day,2><Month,2><Year,2>') = '150124' (L = 4: '1501', L = 8: two blanks + '150124'); a closing date gives the same text (no C);
//   a Date field formats like a variable. 0D and 0DT under any of these format strings give '' and, with a length, |L| blanks (positive) or ''
//   (negative). A defined Time gives the same text in Format(T, L), Format(T, L, 0) and Format(T, L, '<Standard Format,0>') (' 1:45:06 PM' in en-US,
//   milliseconds not shown). Under '<Standard Format,0>' a text as long as the length is kept for every scalar type, both signs. 0D under
//   '<Second dec.>' or '<Hours24,2>:<Minutes,2>' raises InvalidFormatString, with or without a length; 0DT under them gives blanks or ''.
//   '<Precision,2:2>' alone gives '' for a Decimal (L = 3: three blanks).
// BC versions: 27.5 measured on a local Windows container (28.5 and 29.0 by the corpus CI matrix on BC on Linux)

table 96395 "FLN Str Holder"
{
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; D; Date) { }
        field(3; DT; DateTime) { }
        field(4; T; Time) { }
        field(5; Amt; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 96391 "FLN Fmt Strings"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        DayMonthYear2Txt: Label '<Day,2><Month,2><Year,2>', Locked = true;

    [Test]
    procedure DayMonthYear2_DefinedDate_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        D: Date;
    begin
        D := DMY2Date(15, 1, 2024);
        Observer.Observe('D plain', F.DateS(D, 0, DayMonthYear2Txt));
        Observer.Observe('D L=6', F.DateS(D, 6, DayMonthYear2Txt));
        Observer.Observe('D L=1', F.DateS(D, 1, DayMonthYear2Txt));
        Observer.Observe('D L=4', F.DateS(D, 4, DayMonthYear2Txt));
        Observer.Observe('D L=5', F.DateS(D, 5, DayMonthYear2Txt));
        Observer.Observe('D L=7', F.DateS(D, 7, DayMonthYear2Txt));
        Observer.Observe('D L=8', F.DateS(D, 8, DayMonthYear2Txt));
        Observer.Observe('D L=12', F.DateS(D, 12, DayMonthYear2Txt));
        Observer.Observe('D L=-6', F.DateS(D, -6, DayMonthYear2Txt));
        Observer.Observe('D L=-1', F.DateS(D, -1, DayMonthYear2Txt));
        Observer.Observe('D L=-4', F.DateS(D, -4, DayMonthYear2Txt));
        Observer.Observe('D L=-5', F.DateS(D, -5, DayMonthYear2Txt));
        Observer.Observe('D L=-7', F.DateS(D, -7, DayMonthYear2Txt));
        Observer.Observe('D L=-8', F.DateS(D, -8, DayMonthYear2Txt));
        Observer.Observe('D L=-12', F.DateS(D, -12, DayMonthYear2Txt));
        Observer.Observe('D literal L=6', '[' + Format(D, 6, '<Day,2><Month,2><Year,2>') + ']');
        D := DMY2Date(5, 3, 2024);
        Observer.Observe('D2 plain', F.DateS(D, 0, DayMonthYear2Txt));
        Observer.Observe('D2 L=6', F.DateS(D, 6, DayMonthYear2Txt));
        Observer.Observe('D2 L=4', F.DateS(D, 4, DayMonthYear2Txt));
        Observer.Observe('D2 L=8', F.DateS(D, 8, DayMonthYear2Txt));
        Observer.Observe('D2 L=-6', F.DateS(D, -6, DayMonthYear2Txt));
        Observer.Observe('D2 L=-4', F.DateS(D, -4, DayMonthYear2Txt));
        Observer.Expect('D plain', '[150124]');
        Observer.Expect('D L=6', '[150124]');
        Observer.Expect('D L=1', '[1]');
        Observer.Expect('D L=4', '[1501]');
        Observer.Expect('D L=5', '[15012]');
        Observer.Expect('D L=7', '[ 150124]');
        Observer.Expect('D L=8', '[  150124]');
        Observer.Expect('D L=12', '[      150124]');
        Observer.Expect('D L=-6', '[150124]');
        Observer.Expect('D L=-1', '[1]');
        Observer.Expect('D L=-4', '[1501]');
        Observer.Expect('D L=-5', '[15012]');
        Observer.Expect('D L=-7', '[150124]');
        Observer.Expect('D L=-8', '[150124]');
        Observer.Expect('D L=-12', '[150124]');
        Observer.Expect('D literal L=6', '[150124]');
        Observer.Expect('D2 plain', '[050324]');
        Observer.Expect('D2 L=6', '[050324]');
        Observer.Expect('D2 L=4', '[0503]');
        Observer.Expect('D2 L=8', '[  050324]');
        Observer.Expect('D2 L=-6', '[050324]');
        Observer.Expect('D2 L=-4', '[0503]');
        Observer.Verify();
    end;

    [Test]
    procedure DayMonthYear2_UndefinedAndClosingDate_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        D: Date;
    begin
        Observer.Observe('0D plain', F.DateS(0D, 0, DayMonthYear2Txt));
        Observer.Observe('0D L=6', F.DateS(0D, 6, DayMonthYear2Txt));
        Observer.Observe('0D L=1', F.DateS(0D, 1, DayMonthYear2Txt));
        Observer.Observe('0D L=4', F.DateS(0D, 4, DayMonthYear2Txt));
        Observer.Observe('0D L=8', F.DateS(0D, 8, DayMonthYear2Txt));
        Observer.Observe('0D L=-6', F.DateS(0D, -6, DayMonthYear2Txt));
        Observer.Observe('0D L=-1', F.DateS(0D, -1, DayMonthYear2Txt));
        Observer.Observe('0D L=-4', F.DateS(0D, -4, DayMonthYear2Txt));
        Observer.Observe('0D L=-8', F.DateS(0D, -8, DayMonthYear2Txt));
        Observer.Observe('0D literal L=6', '[' + Format(0D, 6, '<Day,2><Month,2><Year,2>') + ']');
        D := ClosingDate(DMY2Date(15, 1, 2024));
        Observer.Observe('C plain', F.DateS(D, 0, DayMonthYear2Txt));
        Observer.Observe('C L=6', F.DateS(D, 6, DayMonthYear2Txt));
        Observer.Observe('C L=4', F.DateS(D, 4, DayMonthYear2Txt));
        Observer.Observe('C L=8', F.DateS(D, 8, DayMonthYear2Txt));
        Observer.Observe('C L=-6', F.DateS(D, -6, DayMonthYear2Txt));
        Observer.Observe('C L=-4', F.DateS(D, -4, DayMonthYear2Txt));
        Observer.Observe('C L=-8', F.DateS(D, -8, DayMonthYear2Txt));
        Observer.Expect('0D plain', '[]');
        Observer.Expect('0D L=6', '[      ]');
        Observer.Expect('0D L=1', '[ ]');
        Observer.Expect('0D L=4', '[    ]');
        Observer.Expect('0D L=8', '[        ]');
        Observer.Expect('0D L=-6', '[]');
        Observer.Expect('0D L=-1', '[]');
        Observer.Expect('0D L=-4', '[]');
        Observer.Expect('0D L=-8', '[]');
        Observer.Expect('0D literal L=6', '[      ]');
        Observer.Expect('C plain', '[150124]');
        Observer.Expect('C L=6', '[150124]');
        Observer.Expect('C L=4', '[1501]');
        Observer.Expect('C L=8', '[  150124]');
        Observer.Expect('C L=-6', '[150124]');
        Observer.Expect('C L=-4', '[1501]');
        Observer.Expect('C L=-8', '[150124]');
        Observer.Verify();
    end;

    [Test]
    procedure DayMonthYear2_DateField_Length()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FLN Str Holder";
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.D := DMY2Date(15, 1, 2024);
        Rec.Insert();
        Observer.Observe('field D L=6', '[' + Format(Rec.D, 6, '<Day,2><Month,2><Year,2>') + ']');
        Observer.Observe('field D L=4', '[' + Format(Rec.D, 4, '<Day,2><Month,2><Year,2>') + ']');
        Observer.Observe('field D L=8', '[' + Format(Rec.D, 8, '<Day,2><Month,2><Year,2>') + ']');
        Observer.Observe('field D L=-6', '[' + Format(Rec.D, -6, '<Day,2><Month,2><Year,2>') + ']');
        Observer.Observe('field D L=-8', '[' + Format(Rec.D, -8, '<Day,2><Month,2><Year,2>') + ']');
        Rec.D := 0D;
        Rec.Modify();
        Observer.Observe('field 0D L=6', '[' + Format(Rec.D, 6, '<Day,2><Month,2><Year,2>') + ']');
        Observer.Observe('field 0D L=-6', '[' + Format(Rec.D, -6, '<Day,2><Month,2><Year,2>') + ']');
        Observer.Expect('field D L=6', '[150124]');
        Observer.Expect('field D L=4', '[1501]');
        Observer.Expect('field D L=8', '[  150124]');
        Observer.Expect('field D L=-6', '[150124]');
        Observer.Expect('field D L=-8', '[150124]');
        Observer.Expect('field 0D L=6', '[      ]');
        Observer.Expect('field 0D L=-6', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Time_StandardFormat0_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TimeLadders(Observer, 'T', 134506T);
        Observer.Expect('T plain', '[ 1:45:06 PM]');
        Observer.Expect('T L=3', '[ 1:]');
        Observer.Expect('T L=x-1', '[ 1:45:06 P]');
        Observer.Expect('T L=x', '[ 1:45:06 PM]');
        Observer.Expect('T L=x+5', '[      1:45:06 PM]');
        Observer.Expect('T L=-3', '[ 1:]');
        Observer.Expect('T L=-x', '[ 1:45:06 PM]');
        Observer.Expect('T L=-(x+5)', '[ 1:45:06 PM]');
        Observer.Expect('T N0=3', '[ 1:]');
        Observer.Expect('T N0=x-1', '[ 1:45:06 P]');
        Observer.Expect('T N0=x', '[ 1:45:06 PM]');
        Observer.Expect('T N0=x+5', '[      1:45:06 PM]');
        Observer.Expect('T N0=-3', '[ 1:]');
        Observer.Expect('T N0=-x', '[ 1:45:06 PM]');
        Observer.Expect('T N0=-(x+5)', '[ 1:45:06 PM]');
        Observer.Expect('T SF0 L=3', '[ 1:]');
        Observer.Expect('T SF0 L=x-1', '[ 1:45:06 P]');
        Observer.Expect('T SF0 L=x', '[ 1:45:06 PM]');
        Observer.Expect('T SF0 L=x+5', '[      1:45:06 PM]');
        Observer.Expect('T SF0 L=-3', '[ 1:]');
        Observer.Expect('T SF0 L=-x', '[ 1:45:06 PM]');
        Observer.Expect('T SF0 L=-(x+5)', '[ 1:45:06 PM]');
        Observer.Verify();
    end;

    [Test]
    procedure Time_StandardFormat0_Length_SingleDigitHour()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TimeLadders(Observer, 'T9', 090503T);
        Observer.Expect('T9 plain', '[ 9:05:03 AM]');
        Observer.Expect('T9 L=3', '[ 9:]');
        Observer.Expect('T9 L=x-1', '[ 9:05:03 A]');
        Observer.Expect('T9 L=x', '[ 9:05:03 AM]');
        Observer.Expect('T9 L=x+5', '[      9:05:03 AM]');
        Observer.Expect('T9 L=-3', '[ 9:]');
        Observer.Expect('T9 L=-x', '[ 9:05:03 AM]');
        Observer.Expect('T9 L=-(x+5)', '[ 9:05:03 AM]');
        Observer.Expect('T9 N0=3', '[ 9:]');
        Observer.Expect('T9 N0=x-1', '[ 9:05:03 A]');
        Observer.Expect('T9 N0=x', '[ 9:05:03 AM]');
        Observer.Expect('T9 N0=x+5', '[      9:05:03 AM]');
        Observer.Expect('T9 N0=-3', '[ 9:]');
        Observer.Expect('T9 N0=-x', '[ 9:05:03 AM]');
        Observer.Expect('T9 N0=-(x+5)', '[ 9:05:03 AM]');
        Observer.Expect('T9 SF0 L=3', '[ 9:]');
        Observer.Expect('T9 SF0 L=x-1', '[ 9:05:03 A]');
        Observer.Expect('T9 SF0 L=x', '[ 9:05:03 AM]');
        Observer.Expect('T9 SF0 L=x+5', '[      9:05:03 AM]');
        Observer.Expect('T9 SF0 L=-3', '[ 9:]');
        Observer.Expect('T9 SF0 L=-x', '[ 9:05:03 AM]');
        Observer.Expect('T9 SF0 L=-(x+5)', '[ 9:05:03 AM]');
        Observer.Verify();
    end;

    [Test]
    procedure Time_StandardFormat0_Length_Milliseconds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TimeLadders(Observer, 'Tms', 134506.078T);
        Observer.Expect('Tms plain', '[ 1:45:06 PM]');
        Observer.Expect('Tms L=3', '[ 1:]');
        Observer.Expect('Tms L=x-1', '[ 1:45:06 P]');
        Observer.Expect('Tms L=x', '[ 1:45:06 PM]');
        Observer.Expect('Tms L=x+5', '[      1:45:06 PM]');
        Observer.Expect('Tms L=-3', '[ 1:]');
        Observer.Expect('Tms L=-x', '[ 1:45:06 PM]');
        Observer.Expect('Tms L=-(x+5)', '[ 1:45:06 PM]');
        Observer.Expect('Tms N0=3', '[ 1:]');
        Observer.Expect('Tms N0=x-1', '[ 1:45:06 P]');
        Observer.Expect('Tms N0=x', '[ 1:45:06 PM]');
        Observer.Expect('Tms N0=x+5', '[      1:45:06 PM]');
        Observer.Expect('Tms N0=-3', '[ 1:]');
        Observer.Expect('Tms N0=-x', '[ 1:45:06 PM]');
        Observer.Expect('Tms N0=-(x+5)', '[ 1:45:06 PM]');
        Observer.Expect('Tms SF0 L=3', '[ 1:]');
        Observer.Expect('Tms SF0 L=x-1', '[ 1:45:06 P]');
        Observer.Expect('Tms SF0 L=x', '[ 1:45:06 PM]');
        Observer.Expect('Tms SF0 L=x+5', '[      1:45:06 PM]');
        Observer.Expect('Tms SF0 L=-3', '[ 1:]');
        Observer.Expect('Tms SF0 L=-x', '[ 1:45:06 PM]');
        Observer.Expect('Tms SF0 L=-(x+5)', '[ 1:45:06 PM]');
        Observer.Verify();
    end;

    [Test]
    procedure Time_StandardFormat0_Length_Field()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FLN Str Holder";
        X: Integer;
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.T := 134506T;
        Rec.Insert();
        X := StrLen(Format(Rec.T));
        Observer.Observe('field T L=3 N=0', '[' + Format(Rec.T, 3, 0) + ']');
        Observer.Observe('field T L=x N=0', '[' + Format(Rec.T, X, 0) + ']');
        Observer.Observe('field T L=x+5 N=0', '[' + Format(Rec.T, X + 5, 0) + ']');
        Observer.Observe('field T L=-3 N=0', '[' + Format(Rec.T, -3, 0) + ']');
        Observer.Observe('field T L=-x N=0', '[' + Format(Rec.T, -X, 0) + ']');
        Observer.Observe('field T L=-(x+5) N=0', '[' + Format(Rec.T, -(X + 5), 0) + ']');
        Observer.Observe('field T L=3 SF0', '[' + Format(Rec.T, 3, '<Standard Format,0>') + ']');
        Observer.Observe('field T L=x SF0', '[' + Format(Rec.T, X, '<Standard Format,0>') + ']');
        Observer.Observe('field T L=x+5 SF0', '[' + Format(Rec.T, X + 5, '<Standard Format,0>') + ']');
        Observer.Observe('field T L=-x SF0', '[' + Format(Rec.T, -X, '<Standard Format,0>') + ']');
        Observer.Observe('field T L=-(x+5) SF0', '[' + Format(Rec.T, -(X + 5), '<Standard Format,0>') + ']');
        Observer.Expect('field T L=3 N=0', '[ 1:]');
        Observer.Expect('field T L=x N=0', '[ 1:45:06 PM]');
        Observer.Expect('field T L=x+5 N=0', '[      1:45:06 PM]');
        Observer.Expect('field T L=-3 N=0', '[ 1:]');
        Observer.Expect('field T L=-x N=0', '[ 1:45:06 PM]');
        Observer.Expect('field T L=-(x+5) N=0', '[ 1:45:06 PM]');
        Observer.Expect('field T L=3 SF0', '[ 1:]');
        Observer.Expect('field T L=x SF0', '[ 1:45:06 PM]');
        Observer.Expect('field T L=x+5 SF0', '[      1:45:06 PM]');
        Observer.Expect('field T L=-x SF0', '[ 1:45:06 PM]');
        Observer.Expect('field T L=-(x+5) SF0', '[ 1:45:06 PM]');
        Observer.Verify();
    end;

    [Test]
    procedure StandardFormat0_EqualLength_DateTypes()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        D: Date;
        Dur: Duration;
    begin
        D := DMY2Date(15, 1, 2024);
        Observer.Observe('D x', Format(StrLen(Format(D, 0, 0))));
        Observer.Observe('D SF0 L=x', F.DateS(D, StrLen(Format(D, 0, 0)), '<Standard Format,0>'));
        Observer.Observe('D SF0 L=-x', F.DateS(D, -StrLen(Format(D, 0, 0)), '<Standard Format,0>'));
        Observer.Observe('D N0 L=x', F.Date(D, StrLen(Format(D, 0, 0)), 0));
        Observer.Observe('D N0 L=-x', F.Date(D, -StrLen(Format(D, 0, 0)), 0));
        Observer.Observe('D SF9 L=x', F.DateS(D, StrLen(Format(D, 0, 9)), '<Standard Format,9>'));
        Observer.Observe('D SF9 L=-x', F.DateS(D, -StrLen(Format(D, 0, 9)), '<Standard Format,9>'));
        Observer.Observe('D N9 L=-x', F.Date(D, -StrLen(Format(D, 0, 9)), 9));
        D := ClosingDate(D);
        Observer.Observe('C SF0 L=x', F.DateS(D, StrLen(Format(D, 0, 0)), '<Standard Format,0>'));
        Observer.Observe('C SF0 L=-x', F.DateS(D, -StrLen(Format(D, 0, 0)), '<Standard Format,0>'));
        Observer.Observe('C N0 L=x', F.Date(D, StrLen(Format(D, 0, 0)), 0));
        Observer.Observe('C N0 L=-x', F.Date(D, -StrLen(Format(D, 0, 0)), 0));
        Dur := 3723004;
        Observer.Observe('Dur SF0 L=x', F.DurationS(Dur, StrLen(Format(Dur, 0, 0)), '<Standard Format,0>'));
        Observer.Observe('Dur SF0 L=-x', F.DurationS(Dur, -StrLen(Format(Dur, 0, 0)), '<Standard Format,0>'));
        Observer.Observe('Dur N0 L=x', F.Duration(Dur, StrLen(Format(Dur, 0, 0)), 0));
        Observer.Observe('Dur N0 L=-x', F.Duration(Dur, -StrLen(Format(Dur, 0, 0)), 0));
        Observer.Expect('D x', '8');
        Observer.Expect('D SF0 L=x', '[01/15/24]');
        Observer.Expect('D SF0 L=-x', '[01/15/24]');
        Observer.Expect('D N0 L=x', '[01/15/24]');
        Observer.Expect('D N0 L=-x', '[01/15/24]');
        Observer.Expect('D SF9 L=x', '[2024-01-15]');
        Observer.Expect('D SF9 L=-x', '[2024-01-15]');
        Observer.Expect('D N9 L=-x', '[2024-01-15]');
        Observer.Expect('C SF0 L=x', '[C01/15/24]');
        Observer.Expect('C SF0 L=-x', '[C01/15/24]');
        Observer.Expect('C N0 L=x', '[C01/15/24]');
        Observer.Expect('C N0 L=-x', '[C01/15/24]');
        Observer.Expect('Dur SF0 L=x', '[1 hour 2 minutes 3 seconds 4 milliseconds]');
        Observer.Expect('Dur SF0 L=-x', '[1 hour 2 minutes 3 seconds 4 milliseconds]');
        Observer.Expect('Dur N0 L=x', '[1 hour 2 minutes 3 seconds 4 milliseconds]');
        Observer.Expect('Dur N0 L=-x', '[1 hour 2 minutes 3 seconds 4 milliseconds]');
        Observer.Verify();
    end;

    [Test]
    procedure StandardFormat0_EqualLength_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        I: Integer;
        B: BigInteger;
        Dec: Decimal;
        By: Byte;
    begin
        I := 1234567;
        Observer.Observe('Int SF0 L=x', F.IntegerS(I, StrLen(Format(I, 0, 0)), '<Standard Format,0>'));
        Observer.Observe('Int SF0 L=-x', F.IntegerS(I, -StrLen(Format(I, 0, 0)), '<Standard Format,0>'));
        Observer.Observe('Int N0 L=x', F.Integer(I, StrLen(Format(I, 0, 0)), 0));
        Observer.Observe('Int N0 L=-x', F.Integer(I, -StrLen(Format(I, 0, 0)), 0));
        B := 12345678901L;
        Observer.Observe('Big SF0 L=x', F.BigIntegerS(B, StrLen(Format(B, 0, 0)), '<Standard Format,0>'));
        Observer.Observe('Big SF0 L=-x', F.BigIntegerS(B, -StrLen(Format(B, 0, 0)), '<Standard Format,0>'));
        Observer.Observe('Big N0 L=x', F.BigInteger(B, StrLen(Format(B, 0, 0)), 0));
        Observer.Observe('Big N0 L=-x', F.BigInteger(B, -StrLen(Format(B, 0, 0)), 0));
        Dec := 1234.5;
        Observer.Observe('Dec SF0 L=x', F.DecimalS(Dec, StrLen(Format(Dec, 0, 0)), '<Standard Format,0>'));
        Observer.Observe('Dec SF0 L=-x', F.DecimalS(Dec, -StrLen(Format(Dec, 0, 0)), '<Standard Format,0>'));
        Observer.Observe('Dec N0 L=x', F.Decimal(Dec, StrLen(Format(Dec, 0, 0)), 0));
        Observer.Observe('Dec N0 L=-x', F.Decimal(Dec, -StrLen(Format(Dec, 0, 0)), 0));
        By := 97;
        Observer.Observe('Byte SF0 L=1', F.ByteS(By, 1, '<Standard Format,0>'));
        Observer.Observe('Byte SF0 L=-1', F.ByteS(By, -1, '<Standard Format,0>'));
        Observer.Observe('Byte N0 L=1', F.Byte(By, 1, 0));
        Observer.Observe('Byte N0 L=-1', F.Byte(By, -1, 0));
        Observer.Expect('Int SF0 L=x', '[1234567]');
        Observer.Expect('Int SF0 L=-x', '[1234567]');
        Observer.Expect('Int N0 L=x', '[1234567]');
        Observer.Expect('Int N0 L=-x', '[1234567]');
        Observer.Expect('Big SF0 L=x', '[12345678901]');
        Observer.Expect('Big SF0 L=-x', '[12345678901]');
        Observer.Expect('Big N0 L=x', '[12345678901]');
        Observer.Expect('Big N0 L=-x', '[12345678901]');
        Observer.Expect('Dec SF0 L=x', '[1,234.5]');
        Observer.Expect('Dec SF0 L=-x', '[1,234.5]');
        Observer.Expect('Dec N0 L=x', '[1,234.5]');
        Observer.Expect('Dec N0 L=-x', '[1,234.5]');
        Observer.Expect('Byte SF0 L=1', '[a]');
        Observer.Expect('Byte SF0 L=-1', '[a]');
        Observer.Expect('Byte N0 L=1', '[a]');
        Observer.Expect('Byte N0 L=-1', '[a]');
        Observer.Verify();
    end;

    [Test]
    procedure StandardFormat0_EqualLength_Others()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        C: Char;
        Cd: Code[20];
        G: Guid;
    begin
        C := 'a';
        Observer.Observe('Char SF0 L=1', F.CharS(C, 1, '<Standard Format,0>'));
        Observer.Observe('Char SF0 L=-1', F.CharS(C, -1, '<Standard Format,0>'));
        Observer.Observe('Char N0 L=1', F.Char(C, 1, 0));
        Observer.Observe('Char N0 L=-1', F.Char(C, -1, 0));
        Observer.Observe('Bool SF0 L=x', F.BooleanS(true, StrLen(Format(true, 0, 0)), '<Standard Format,0>'));
        Observer.Observe('Bool SF0 L=-x', F.BooleanS(true, -StrLen(Format(true, 0, 0)), '<Standard Format,0>'));
        Observer.Observe('Bool N0 L=x', F.Boolean(true, StrLen(Format(true, 0, 0)), 0));
        Observer.Observe('Bool N0 L=-x', F.Boolean(true, -StrLen(Format(true, 0, 0)), 0));
        Cd := 'ABCDE';
        Observer.Observe('Code SF0 L=5', F.CodeS(Cd, 5, '<Standard Format,0>'));
        Observer.Observe('Code SF0 L=-5', F.CodeS(Cd, -5, '<Standard Format,0>'));
        Observer.Observe('Code N0 L=-5', F.Code(Cd, -5, 0));
        Observer.Observe('Guid SF0 L=38', F.GuidS(G, 38, '<Standard Format,0>'));
        Observer.Observe('Guid SF0 L=-38', F.GuidS(G, -38, '<Standard Format,0>'));
        Observer.Observe('Guid N0 L=38', F.Guid(G, 38, 0));
        Observer.Observe('Guid N0 L=-38', F.Guid(G, -38, 0));
        Observer.Observe('Text SF0 L=5', F.TextS('abcde', 5, '<Standard Format,0>'));
        Observer.Observe('Text SF0 L=-5', F.TextS('abcde', -5, '<Standard Format,0>'));
        Observer.Expect('Char SF0 L=1', '[a]');
        Observer.Expect('Char SF0 L=-1', '[a]');
        Observer.Expect('Char N0 L=1', '[a]');
        Observer.Expect('Char N0 L=-1', '[a]');
        Observer.Expect('Bool SF0 L=x', '[Yes]');
        Observer.Expect('Bool SF0 L=-x', '[Yes]');
        Observer.Expect('Bool N0 L=x', '[Yes]');
        Observer.Expect('Bool N0 L=-x', '[Yes]');
        Observer.Expect('Code SF0 L=5', '[ABCDE]');
        Observer.Expect('Code SF0 L=-5', '[ABCDE]');
        Observer.Expect('Code N0 L=-5', '[ABCDE]');
        Observer.Expect('Guid SF0 L=38', '[{00000000-0000-0000-0000-000000000000}]');
        Observer.Expect('Guid SF0 L=-38', '[{00000000-0000-0000-0000-000000000000}]');
        Observer.Expect('Guid N0 L=38', '[{00000000-0000-0000-0000-000000000000}]');
        Observer.Expect('Guid N0 L=-38', '[{00000000-0000-0000-0000-000000000000}]');
        Observer.Expect('Text SF0 L=5', '[abcde]');
        Observer.Expect('Text SF0 L=-5', '[abcde]');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_SignIntThousandDec_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecLadder(Observer, 'dec', 1234.5, '<Sign><Integer Thousand><Decimals>');
        DecLadder(Observer, 'neg', -1234.5, '<Sign><Integer Thousand><Decimals>');
        Observer.Expect('dec plain', '[1,234.5]');
        Observer.Expect('dec L=x', '[1,234.5]');
        Observer.Expect('dec L=x+3', '[   1,234.5]');
        Observer.Expect('dec L=x-2', '[1,234]');
        Observer.Expect('dec L=-x', '[1,234.5]');
        Observer.Expect('dec L=-(x+3)', '[1,234.5]');
        Observer.Expect('dec L=-(x-2)', '[1,234]');
        Observer.Expect('neg plain', '[-1,234.5]');
        Observer.Expect('neg L=x', '[-1,234.5]');
        Observer.Expect('neg L=x+3', '[   -1,234.5]');
        Observer.Expect('neg L=x-2', '[-1,234]');
        Observer.Expect('neg L=-x', '[-1,234.5]');
        Observer.Expect('neg L=-(x+3)', '[-1,234.5]');
        Observer.Expect('neg L=-(x-2)', '[-1,234]');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_IntThousand_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecLadder(Observer, 'dec', 1234.5, '<Integer Thousand>');
        DecLadder(Observer, 'neg', -1234.5, '<Integer Thousand>');
        Observer.Expect('dec plain', '[1,234]');
        Observer.Expect('dec L=x', '[1,234]');
        Observer.Expect('dec L=x+3', '[   1,234]');
        Observer.Expect('dec L=x-2', '[1,2]');
        Observer.Expect('dec L=-x', '[1,234]');
        Observer.Expect('dec L=-(x+3)', '[1,234]');
        Observer.Expect('dec L=-(x-2)', '[1,2]');
        Observer.Expect('neg plain', '[1,234]');
        Observer.Expect('neg L=x', '[1,234]');
        Observer.Expect('neg L=x+3', '[   1,234]');
        Observer.Expect('neg L=x-2', '[1,2]');
        Observer.Expect('neg L=-x', '[1,234]');
        Observer.Expect('neg L=-(x+3)', '[1,234]');
        Observer.Expect('neg L=-(x-2)', '[1,2]');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Prec11Sf0Comma_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecLadder(Observer, 'dec', 1234.5, '<Precision,1:1><Standard Format,0><Comma,,>');
        DecLadder(Observer, 'neg', -1234.5, '<Precision,1:1><Standard Format,0><Comma,,>');
        Observer.Expect('dec plain', '[1,234,5]');
        Observer.Expect('dec L=x', '[1,234,5]');
        Observer.Expect('dec L=x+3', '[   1,234,5]');
        Observer.Expect('dec L=x-2', '[1,234]');
        Observer.Expect('dec L=-x', '[1,234,5]');
        Observer.Expect('dec L=-(x+3)', '[1,234,5]');
        Observer.Expect('dec L=-(x-2)', '[1,234]');
        Observer.Expect('neg plain', '[-1,234,5]');
        Observer.Expect('neg L=x', '[-1,234,5]');
        Observer.Expect('neg L=x+3', '[   -1,234,5]');
        Observer.Expect('neg L=x-2', '[-1,234]');
        Observer.Expect('neg L=-x', '[-1,234,5]');
        Observer.Expect('neg L=-(x+3)', '[-1,234,5]');
        Observer.Expect('neg L=-(x-2)', '[-1,234]');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Int4Fill0Dec4Fill0_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecLadder(Observer, 'dec', 1234.5, '<Integer,4><Filler character,0><Decimal,4><Filler character,0>');
        DecLadder(Observer, 'neg', -1234.5, '<Integer,4><Filler character,0><Decimal,4><Filler character,0>');
        Observer.Expect('dec plain', '[1234.500]');
        Observer.Expect('dec L=x', '[1234.500]');
        Observer.Expect('dec L=x+3', '[   1234.500]');
        Observer.Expect('dec L=x-2', '[1234.5]');
        Observer.Expect('dec L=-x', '[1234.500]');
        Observer.Expect('dec L=-(x+3)', '[1234.500]');
        Observer.Expect('dec L=-(x-2)', '[1234.5]');
        Observer.Expect('neg plain', '[1234.500]');
        Observer.Expect('neg L=x', '[1234.500]');
        Observer.Expect('neg L=x+3', '[   1234.500]');
        Observer.Expect('neg L=x-2', '[1234.5]');
        Observer.Expect('neg L=-x', '[1234.500]');
        Observer.Expect('neg L=-(x+3)', '[1234.500]');
        Observer.Expect('neg L=-(x-2)', '[1234.5]');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Prec22_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecLadder(Observer, 'dec', 1234.5, '<Precision,2:2>');
        DecLadder(Observer, 'neg', -1234.5, '<Precision,2:2>');
        Observer.Expect('dec plain', '[]');
        Observer.Expect('dec L=3', '[   ]');
        Observer.Expect('dec L=-3', '[]');
        Observer.Expect('neg plain', '[]');
        Observer.Expect('neg L=3', '[   ]');
        Observer.Expect('neg L=-3', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Prec22Sf0_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecLadder(Observer, 'dec', 1234.5, '<Precision,2:2><Standard Format,0>');
        DecLadder(Observer, 'neg', -1234.5, '<Precision,2:2><Standard Format,0>');
        Observer.Expect('dec plain', '[1,234.50]');
        Observer.Expect('dec L=x', '[1,234.50]');
        Observer.Expect('dec L=x+3', '[   1,234.50]');
        Observer.Expect('dec L=x-2', '[1,234.]');
        Observer.Expect('dec L=-x', '[1,234.50]');
        Observer.Expect('dec L=-(x+3)', '[1,234.50]');
        Observer.Expect('dec L=-(x-2)', '[1,234.]');
        Observer.Expect('neg plain', '[-1,234.50]');
        Observer.Expect('neg L=x', '[-1,234.50]');
        Observer.Expect('neg L=x+3', '[   -1,234.50]');
        Observer.Expect('neg L=x-2', '[-1,234.]');
        Observer.Expect('neg L=-x', '[-1,234.50]');
        Observer.Expect('neg L=-(x+3)', '[-1,234.50]');
        Observer.Expect('neg L=-(x-2)', '[-1,234.]');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Sf1_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecLadder(Observer, 'dec', 1234.5, '<Standard Format,1>');
        DecLadder(Observer, 'neg', -1234.5, '<Standard Format,1>');
        Observer.Expect('dec plain', '[1234.5]');
        Observer.Expect('dec L=x', '[1234.5]');
        Observer.Expect('dec L=x+3', '[   1234.5]');
        Observer.Expect('dec L=x-2', '[1234]');
        Observer.Expect('dec L=-x', '[1234.5]');
        Observer.Expect('dec L=-(x+3)', '[1234.5]');
        Observer.Expect('dec L=-(x-2)', '[1234]');
        Observer.Expect('neg plain', '[-1234.5]');
        Observer.Expect('neg L=x', '[-1234.5]');
        Observer.Expect('neg L=x+3', '[   -1234.5]');
        Observer.Expect('neg L=x-2', '[-1234]');
        Observer.Expect('neg L=-x', '[-1234.5]');
        Observer.Expect('neg L=-(x+3)', '[-1234.5]');
        Observer.Expect('neg L=-(x-2)', '[-1234]');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Sf9_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecLadder(Observer, 'dec', 1234.5, '<Standard Format,9>');
        DecLadder(Observer, 'neg', -1234.5, '<Standard Format,9>');
        Observer.Expect('dec plain', '[1234.5]');
        Observer.Expect('dec L=x', '[1234.5]');
        Observer.Expect('dec L=x+3', '[   1234.5]');
        Observer.Expect('dec L=x-2', '[1234]');
        Observer.Expect('dec L=-x', '[1234.5]');
        Observer.Expect('dec L=-(x+3)', '[1234.5]');
        Observer.Expect('dec L=-(x-2)', '[1234]');
        Observer.Expect('neg plain', '[-1234.5]');
        Observer.Expect('neg L=x', '[-1234.5]');
        Observer.Expect('neg L=x+3', '[   -1234.5]');
        Observer.Expect('neg L=x-2', '[-1234]');
        Observer.Expect('neg L=-x', '[-1234.5]');
        Observer.Expect('neg L=-(x+3)', '[-1234.5]');
        Observer.Expect('neg L=-(x-2)', '[-1234]');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Year4Month2_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLadder(Observer, 'D', DMY2Date(15, 1, 2024), '<Year4>-<Month,2>');
        Observer.Expect('D plain', '[2024-01]');
        Observer.Expect('D L=1', '[2]');
        Observer.Expect('D L=-1', '[2]');
        Observer.Expect('D L=x', '[2024-01]');
        Observer.Expect('D L=x+3', '[   2024-01]');
        Observer.Expect('D L=x-1', '[2024-0]');
        Observer.Expect('D L=x-2', '[2024-]');
        Observer.Expect('D L=-x', '[2024-01]');
        Observer.Expect('D L=-(x+3)', '[2024-01]');
        Observer.Expect('D L=-(x-1)', '[2024-0]');
        Observer.Expect('D L=-(x-2)', '[2024-]');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Year4Month2Day2_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLadder(Observer, 'D', DMY2Date(15, 1, 2024), '<Year4>-<Month,2>-<Day,2>');
        Observer.Expect('D plain', '[2024-01-15]');
        Observer.Expect('D L=1', '[2]');
        Observer.Expect('D L=-1', '[2]');
        Observer.Expect('D L=x', '[2024-01-15]');
        Observer.Expect('D L=x+3', '[   2024-01-15]');
        Observer.Expect('D L=x-1', '[2024-01-1]');
        Observer.Expect('D L=x-2', '[2024-01-]');
        Observer.Expect('D L=-x', '[2024-01-15]');
        Observer.Expect('D L=-(x+3)', '[2024-01-15]');
        Observer.Expect('D L=-(x-1)', '[2024-01-1]');
        Observer.Expect('D L=-(x-2)', '[2024-01-]');
        Observer.Verify();
    end;

    [Test]
    procedure Date_DayMonthYear2_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLadder(Observer, 'D', DMY2Date(15, 1, 2024), '<Day,2><Month,2><Year,2>');
        Observer.Expect('D plain', '[150124]');
        Observer.Expect('D L=1', '[1]');
        Observer.Expect('D L=-1', '[1]');
        Observer.Expect('D L=x', '[150124]');
        Observer.Expect('D L=x+3', '[   150124]');
        Observer.Expect('D L=x-1', '[15012]');
        Observer.Expect('D L=x-2', '[1501]');
        Observer.Expect('D L=-x', '[150124]');
        Observer.Expect('D L=-(x+3)', '[150124]');
        Observer.Expect('D L=-(x-1)', '[15012]');
        Observer.Expect('D L=-(x-2)', '[1501]');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Sf0_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLadder(Observer, 'D', DMY2Date(15, 1, 2024), '<Standard Format,0>');
        Observer.Expect('D plain', '[01/15/24]');
        Observer.Expect('D L=1', '[0]');
        Observer.Expect('D L=-1', '[0]');
        Observer.Expect('D L=x', '[01/15/24]');
        Observer.Expect('D L=x+3', '[   01/15/24]');
        Observer.Expect('D L=x-1', '[01/15/2]');
        Observer.Expect('D L=x-2', '[01/15/]');
        Observer.Expect('D L=-x', '[01/15/24]');
        Observer.Expect('D L=-(x+3)', '[01/15/24]');
        Observer.Expect('D L=-(x-1)', '[01/15/2]');
        Observer.Expect('D L=-(x-2)', '[01/15/]');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Sf9_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLadder(Observer, 'D', DMY2Date(15, 1, 2024), '<Standard Format,9>');
        Observer.Expect('D plain', '[2024-01-15]');
        Observer.Expect('D L=1', '[2]');
        Observer.Expect('D L=-1', '[2]');
        Observer.Expect('D L=x', '[2024-01-15]');
        Observer.Expect('D L=x+3', '[   2024-01-15]');
        Observer.Expect('D L=x-1', '[2024-01-1]');
        Observer.Expect('D L=x-2', '[2024-01-]');
        Observer.Expect('D L=-x', '[2024-01-15]');
        Observer.Expect('D L=-(x+3)', '[2024-01-15]');
        Observer.Expect('D L=-(x-1)', '[2024-01-1]');
        Observer.Expect('D L=-(x-2)', '[2024-01-]');
        Observer.Verify();
    end;

    [Test]
    procedure Date_ClosingDay_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLadder(Observer, 'D', DMY2Date(15, 1, 2024), '<Closing><Day>');
        Observer.Expect('D plain', '[15]');
        Observer.Expect('D L=1', '[1]');
        Observer.Expect('D L=-1', '[1]');
        Observer.Verify();
    end;

    [Test]
    procedure UndefinedDateTime_SecondDec_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UndefinedLadder(Observer, '<Second dec.>');
        Observer.Expect('0DT plain', '[]');
        Observer.Expect('0DT L=1', '[ ]');
        Observer.Expect('0DT L=5', '[     ]');
        Observer.Expect('0DT L=30', '[                              ]');
        Observer.Expect('0DT L=-1', '[]');
        Observer.Expect('0DT L=-5', '[]');
        Observer.Expect('0DT L=-30', '[]');
        Observer.Expect('0D plain', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Second dec.> | InvalidFormatString');
        Observer.Expect('0D L=5', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Second dec.> | InvalidFormatString');
        Observer.Expect('0D L=-5', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Second dec.> | InvalidFormatString');
        Observer.Verify();
    end;

    [Test]
    procedure UndefinedDateTime_Year4Month2Day2_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UndefinedLadder(Observer, '<Year4>-<Month,2>-<Day,2>');
        Observer.Expect('0DT plain', '[]');
        Observer.Expect('0DT L=1', '[ ]');
        Observer.Expect('0DT L=5', '[     ]');
        Observer.Expect('0DT L=30', '[                              ]');
        Observer.Expect('0DT L=-1', '[]');
        Observer.Expect('0DT L=-5', '[]');
        Observer.Expect('0DT L=-30', '[]');
        Observer.Expect('0D plain', '[]');
        Observer.Expect('0D L=5', '[     ]');
        Observer.Expect('0D L=-5', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure UndefinedDateTime_DayMonthYear2_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UndefinedLadder(Observer, '<Day,2><Month,2><Year,2>');
        Observer.Expect('0DT plain', '[]');
        Observer.Expect('0DT L=1', '[ ]');
        Observer.Expect('0DT L=5', '[     ]');
        Observer.Expect('0DT L=30', '[                              ]');
        Observer.Expect('0DT L=-1', '[]');
        Observer.Expect('0DT L=-5', '[]');
        Observer.Expect('0DT L=-30', '[]');
        Observer.Expect('0D plain', '[]');
        Observer.Expect('0D L=5', '[     ]');
        Observer.Expect('0D L=-5', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure UndefinedDateTime_Sf0_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UndefinedLadder(Observer, '<Standard Format,0>');
        Observer.Expect('0DT plain', '[]');
        Observer.Expect('0DT L=1', '[ ]');
        Observer.Expect('0DT L=5', '[     ]');
        Observer.Expect('0DT L=30', '[                              ]');
        Observer.Expect('0DT L=-1', '[]');
        Observer.Expect('0DT L=-5', '[]');
        Observer.Expect('0DT L=-30', '[]');
        Observer.Expect('0D plain', '[]');
        Observer.Expect('0D L=5', '[     ]');
        Observer.Expect('0D L=-5', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure UndefinedDateTime_Sf9_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UndefinedLadder(Observer, '<Standard Format,9>');
        Observer.Expect('0DT plain', '[]');
        Observer.Expect('0DT L=1', '[ ]');
        Observer.Expect('0DT L=5', '[     ]');
        Observer.Expect('0DT L=30', '[                              ]');
        Observer.Expect('0DT L=-1', '[]');
        Observer.Expect('0DT L=-5', '[]');
        Observer.Expect('0DT L=-30', '[]');
        Observer.Expect('0D plain', '[]');
        Observer.Expect('0D L=5', '[     ]');
        Observer.Expect('0D L=-5', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure UndefinedDateTime_Hours24Minutes_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UndefinedLadder(Observer, '<Hours24,2>:<Minutes,2>');
        Observer.Expect('0DT plain', '[]');
        Observer.Expect('0DT L=1', '[ ]');
        Observer.Expect('0DT L=5', '[     ]');
        Observer.Expect('0DT L=30', '[                              ]');
        Observer.Expect('0DT L=-1', '[]');
        Observer.Expect('0DT L=-5', '[]');
        Observer.Expect('0DT L=-30', '[]');
        Observer.Expect('0D plain', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Hours24,2>:<Minutes,2> | InvalidFormatString');
        Observer.Expect('0D L=5', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Hours24,2>:<Minutes,2> | InvalidFormatString');
        Observer.Expect('0D L=-5', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Hours24,2>:<Minutes,2> | InvalidFormatString');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_Int2Fill0_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        IntLadder(Observer, 'i7', 7, '<Integer,2><Filler Character,0>');
        IntLadder(Observer, 'i1234567', 1234567, '<Integer,2><Filler Character,0>');
        Observer.Expect('i7 plain', '[07]');
        Observer.Expect('i7 L=x', '[07]');
        Observer.Expect('i7 L=x+3', '[   07]');
        Observer.Expect('i7 L=1', '[0]');
        Observer.Expect('i7 L=-x', '[07]');
        Observer.Expect('i7 L=-(x+3)', '[07]');
        Observer.Expect('i7 L=-1', '[0]');
        Observer.Expect('i1234567 plain', '[**]');
        Observer.Expect('i1234567 L=x', '[**]');
        Observer.Expect('i1234567 L=x+3', '[   **]');
        Observer.Expect('i1234567 L=1', '[*]');
        Observer.Expect('i1234567 L=-x', '[**]');
        Observer.Expect('i1234567 L=-(x+3)', '[**]');
        Observer.Expect('i1234567 L=-1', '[*]');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_Int4Fill0_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        IntLadder(Observer, 'i7', 7, '<Integer,4><Filler Character,0>');
        IntLadder(Observer, 'i1234567', 1234567, '<Integer,4><Filler Character,0>');
        Observer.Expect('i7 plain', '[0007]');
        Observer.Expect('i7 L=x', '[0007]');
        Observer.Expect('i7 L=x+3', '[   0007]');
        Observer.Expect('i7 L=1', '[0]');
        Observer.Expect('i7 L=-x', '[0007]');
        Observer.Expect('i7 L=-(x+3)', '[0007]');
        Observer.Expect('i7 L=-1', '[0]');
        Observer.Expect('i1234567 plain', '[****]');
        Observer.Expect('i1234567 L=x', '[****]');
        Observer.Expect('i1234567 L=x+3', '[   ****]');
        Observer.Expect('i1234567 L=1', '[*]');
        Observer.Expect('i1234567 L=-x', '[****]');
        Observer.Expect('i1234567 L=-(x+3)', '[****]');
        Observer.Expect('i1234567 L=-1', '[*]');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_IntThousand_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        IntLadder(Observer, 'i7', 7, '<Integer Thousand>');
        IntLadder(Observer, 'i1234567', 1234567, '<Integer Thousand>');
        Observer.Expect('i7 plain', '[7]');
        Observer.Expect('i7 L=x', '[7]');
        Observer.Expect('i7 L=x+3', '[   7]');
        Observer.Expect('i7 L=1', '[7]');
        Observer.Expect('i7 L=-x', '[7]');
        Observer.Expect('i7 L=-(x+3)', '[7]');
        Observer.Expect('i7 L=-1', '[7]');
        Observer.Expect('i1234567 plain', '[1,234,567]');
        Observer.Expect('i1234567 L=x', '[1,234,567]');
        Observer.Expect('i1234567 L=x+3', '[   1,234,567]');
        Observer.Expect('i1234567 L=1', '[1]');
        Observer.Expect('i1234567 L=-x', '[1,234,567]');
        Observer.Expect('i1234567 L=-(x+3)', '[1,234,567]');
        Observer.Expect('i1234567 L=-1', '[1]');
        Observer.Verify();
    end;

    [Test]
    procedure Text_TextCode_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        Cd: Code[20];
    begin
        TextLadder(Observer, 'txt', 'abcdefgh');
        Cd := 'ABCDEFGH';
        Observer.Observe('code plain', F.CodeS(Cd, 0, '<Text>'));
        Observer.Observe('code L=8', F.CodeS(Cd, 8, '<Text>'));
        Observer.Observe('code L=11', F.CodeS(Cd, 11, '<Text>'));
        Observer.Observe('code L=6', F.CodeS(Cd, 6, '<Text>'));
        Observer.Observe('code L=-8', F.CodeS(Cd, -8, '<Text>'));
        Observer.Observe('code L=-11', F.CodeS(Cd, -11, '<Text>'));
        Observer.Observe('code L=-6', F.CodeS(Cd, -6, '<Text>'));
        Observer.Expect('txt plain', '[abcdefgh]');
        Observer.Expect('txt L=8', '[abcdefgh]');
        Observer.Expect('txt L=11', '[abcdefgh   ]');
        Observer.Expect('txt L=6', '[abcdef]');
        Observer.Expect('txt L=-8', '[abcdefgh]');
        Observer.Expect('txt L=-11', '[abcdefgh]');
        Observer.Expect('txt L=-6', '[abcdef]');
        Observer.Expect('code plain', '[ABCDEFGH]');
        Observer.Expect('code L=8', '[ABCDEFGH]');
        Observer.Expect('code L=11', '[ABCDEFGH   ]');
        Observer.Expect('code L=6', '[ABCDEF]');
        Observer.Expect('code L=-8', '[ABCDEFGH]');
        Observer.Expect('code L=-11', '[ABCDEFGH]');
        Observer.Expect('code L=-6', '[ABCDEF]');
        Observer.Verify();
    end;

    [Test]
    procedure UndefinedDateTime_Field_Length()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FLN Str Holder";
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Insert();
        Observer.Observe('field 0DT L=5 Year4', '[' + Format(Rec.DT, 5, '<Year4>-<Month,2>-<Day,2>') + ']');
        Observer.Observe('field 0DT L=-5 Year4', '[' + Format(Rec.DT, -5, '<Year4>-<Month,2>-<Day,2>') + ']');
        Observer.Observe('field 0DT L=10 SF9', '[' + Format(Rec.DT, 10, '<Standard Format,9>') + ']');
        Observer.Observe('field 0DT L=-10 SF9', '[' + Format(Rec.DT, -10, '<Standard Format,9>') + ']');
        Observer.Expect('field 0DT L=5 Year4', '[     ]');
        Observer.Expect('field 0DT L=-5 Year4', '[]');
        Observer.Expect('field 0DT L=10 SF9', '[          ]');
        Observer.Expect('field 0DT L=-10 SF9', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure UndefinedDate_Templates_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
    begin
        Observer.Observe('0D Year4Month2 L=7', F.DateS(0D, 7, '<Year4>-<Month,2>'));
        Observer.Observe('0D Year4Month2 L=-7', F.DateS(0D, -7, '<Year4>-<Month,2>'));
        Observer.Observe('0D SF0 L=8', F.DateS(0D, 8, '<Standard Format,0>'));
        Observer.Observe('0D SF0 L=-8', F.DateS(0D, -8, '<Standard Format,0>'));
        Observer.Observe('0D SF9 L=10', F.DateS(0D, 10, '<Standard Format,9>'));
        Observer.Observe('0D SF9 L=-10', F.DateS(0D, -10, '<Standard Format,9>'));
        Observer.Observe('0D ClosingDay L=1', F.DateS(0D, 1, '<Closing><Day>'));
        Observer.Observe('0D ClosingDay L=-3', F.DateS(0D, -3, '<Closing><Day>'));
        Observer.Expect('0D Year4Month2 L=7', '[       ]');
        Observer.Expect('0D Year4Month2 L=-7', '[]');
        Observer.Expect('0D SF0 L=8', '[        ]');
        Observer.Expect('0D SF0 L=-8', '[]');
        Observer.Expect('0D SF9 L=10', '[          ]');
        Observer.Expect('0D SF9 L=-10', '[]');
        Observer.Expect('0D ClosingDay L=1', '[ ]');
        Observer.Expect('0D ClosingDay L=-3', '[]');
        Observer.Verify();
    end;

    local procedure TimeLadders(var Observer: Codeunit "Probe Observer"; P: Text; T: Time)
    var
        F: Codeunit "FLN Fmt";
        X: Integer;
    begin
        X := StrLen(Format(T, 0, 0));
        Observer.Observe(P + ' plain', F.Time(T, 0, -1));
        TimeRow(Observer, P + ' L', T, 3, X, -1);
        TimeRow(Observer, P + ' N0', T, 3, X, 0);
        Observer.Observe(P + ' SF0 L=3', F.TimeS(T, 3, '<Standard Format,0>'));
        Observer.Observe(P + ' SF0 L=x-1', F.TimeS(T, X - 1, '<Standard Format,0>'));
        Observer.Observe(P + ' SF0 L=x', F.TimeS(T, X, '<Standard Format,0>'));
        Observer.Observe(P + ' SF0 L=x+5', F.TimeS(T, X + 5, '<Standard Format,0>'));
        Observer.Observe(P + ' SF0 L=-3', F.TimeS(T, -3, '<Standard Format,0>'));
        Observer.Observe(P + ' SF0 L=-x', F.TimeS(T, -X, '<Standard Format,0>'));
        Observer.Observe(P + ' SF0 L=-(x+5)', F.TimeS(T, -(X + 5), '<Standard Format,0>'));
    end;

    local procedure TimeRow(var Observer: Codeunit "Probe Observer"; P: Text; T: Time; Short: Integer; X: Integer; N: Integer)
    var
        F: Codeunit "FLN Fmt";
    begin
        Observer.Observe(P + '=3', F.Time(T, Short, N));
        Observer.Observe(P + '=x-1', F.Time(T, X - 1, N));
        Observer.Observe(P + '=x', F.Time(T, X, N));
        Observer.Observe(P + '=x+5', F.Time(T, X + 5, N));
        Observer.Observe(P + '=-3', F.Time(T, -Short, N));
        Observer.Observe(P + '=-x', F.Time(T, -X, N));
        Observer.Observe(P + '=-(x+5)', F.Time(T, -(X + 5), N));
    end;

    local procedure DecLadder(var Observer: Codeunit "Probe Observer"; P: Text; V: Decimal; S: Text)
    var
        F: Codeunit "FLN Fmt";
        X: Integer;
    begin
        X := StrLen(Format(V, 0, S));
        Observer.Observe(P + ' plain', F.DecimalS(V, 0, S));
        if X < 3 then begin
            Observer.Observe(P + ' L=3', F.DecimalS(V, 3, S));
            Observer.Observe(P + ' L=-3', F.DecimalS(V, -3, S));
            exit;
        end;
        Observer.Observe(P + ' L=x', F.DecimalS(V, X, S));
        Observer.Observe(P + ' L=x+3', F.DecimalS(V, X + 3, S));
        Observer.Observe(P + ' L=x-2', F.DecimalS(V, X - 2, S));
        Observer.Observe(P + ' L=-x', F.DecimalS(V, -X, S));
        Observer.Observe(P + ' L=-(x+3)', F.DecimalS(V, -(X + 3), S));
        Observer.Observe(P + ' L=-(x-2)', F.DecimalS(V, -(X - 2), S));
    end;

    local procedure DateLadder(var Observer: Codeunit "Probe Observer"; P: Text; V: Date; S: Text)
    var
        F: Codeunit "FLN Fmt";
        X: Integer;
    begin
        X := StrLen(Format(V, 0, S));
        Observer.Observe(P + ' plain', F.DateS(V, 0, S));
        Observer.Observe(P + ' L=1', F.DateS(V, 1, S));
        Observer.Observe(P + ' L=-1', F.DateS(V, -1, S));
        if X < 3 then
            exit;
        Observer.Observe(P + ' L=x', F.DateS(V, X, S));
        Observer.Observe(P + ' L=x+3', F.DateS(V, X + 3, S));
        Observer.Observe(P + ' L=x-1', F.DateS(V, X - 1, S));
        Observer.Observe(P + ' L=x-2', F.DateS(V, X - 2, S));
        Observer.Observe(P + ' L=-x', F.DateS(V, -X, S));
        Observer.Observe(P + ' L=-(x+3)', F.DateS(V, -(X + 3), S));
        Observer.Observe(P + ' L=-(x-1)', F.DateS(V, -(X - 1), S));
        Observer.Observe(P + ' L=-(x-2)', F.DateS(V, -(X - 2), S));
    end;

    local procedure UndefinedLadder(var Observer: Codeunit "Probe Observer"; S: Text)
    var
        F: Codeunit "FLN Fmt";
    begin
        Observer.Observe('0DT plain', F.DateTimeS(0DT, 0, S));
        Observer.Observe('0DT L=1', F.DateTimeS(0DT, 1, S));
        Observer.Observe('0DT L=5', F.DateTimeS(0DT, 5, S));
        Observer.Observe('0DT L=30', F.DateTimeS(0DT, 30, S));
        Observer.Observe('0DT L=-1', F.DateTimeS(0DT, -1, S));
        Observer.Observe('0DT L=-5', F.DateTimeS(0DT, -5, S));
        Observer.Observe('0DT L=-30', F.DateTimeS(0DT, -30, S));
        Observer.Observe('0D plain', F.DateS(0D, 0, S));
        Observer.Observe('0D L=5', F.DateS(0D, 5, S));
        Observer.Observe('0D L=-5', F.DateS(0D, -5, S));
    end;

    local procedure IntLadder(var Observer: Codeunit "Probe Observer"; P: Text; V: Integer; S: Text)
    var
        F: Codeunit "FLN Fmt";
        X: Integer;
    begin
        X := StrLen(Format(V, 0, S));
        Observer.Observe(P + ' plain', F.IntegerS(V, 0, S));
        Observer.Observe(P + ' L=x', F.IntegerS(V, X, S));
        Observer.Observe(P + ' L=x+3', F.IntegerS(V, X + 3, S));
        Observer.Observe(P + ' L=1', F.IntegerS(V, 1, S));
        Observer.Observe(P + ' L=-x', F.IntegerS(V, -X, S));
        Observer.Observe(P + ' L=-(x+3)', F.IntegerS(V, -(X + 3), S));
        Observer.Observe(P + ' L=-1', F.IntegerS(V, -1, S));
    end;

    local procedure TextLadder(var Observer: Codeunit "Probe Observer"; P: Text; V: Text)
    var
        F: Codeunit "FLN Fmt";
    begin
        Observer.Observe(P + ' plain', F.TextS(V, 0, '<Text>'));
        Observer.Observe(P + ' L=8', F.TextS(V, 8, '<Text>'));
        Observer.Observe(P + ' L=11', F.TextS(V, 11, '<Text>'));
        Observer.Observe(P + ' L=6', F.TextS(V, 6, '<Text>'));
        Observer.Observe(P + ' L=-8', F.TextS(V, -8, '<Text>'));
        Observer.Observe(P + ' L=-11', F.TextS(V, -11, '<Text>'));
        Observer.Observe(P + ' L=-6', F.TextS(V, -6, '<Text>'));
    end;
}
