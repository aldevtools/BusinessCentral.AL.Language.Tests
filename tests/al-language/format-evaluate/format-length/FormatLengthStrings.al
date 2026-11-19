// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-integer-string-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); helper codeunit 96388 "FLN Fmt" (FormatLengthHelper.al); own temporary table 96395
// Probe: written against a local BC service tier; every literal asserted below is what BC produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format(Value, Length, FormatString) for the shapes the format-length probes left open:
//   - the Tests-Data Exchange shape Format(D, 6, '<Day,2><Month,2><Year,2>') with lengths shorter than, as long as and longer than the text, both signs,
//     for a defined Date, a closing date, 0D and a Date table field;
//   - a defined Time in Format(T, L), Format(T, L, 0) and Format(T, L, '<Standard Format,0>'), lengths shorter, as long, longer, both signs;
//   - a text exactly as long as the length under '<Standard Format,0>' (and '<Standard Format,9>' for a Date), both signs, for every scalar type;
//   - a Decimal, an Integer, a Text and a defined Date under the format strings other corpus lines use with a length, lengths shorter, as long and
//     longer, both signs; 0DT and 0D under those format strings.
// Results: see the Expect lines of each test.
// BC versions: measured on a local container (the other majors by the corpus CI matrix)

table 96395 "FLN Date Holder"
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure DayMonthYear2_DateField_Length()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FLN Date Holder";
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
        Observer.Finish();
    end;

    [Test]
    procedure Time_StandardFormat0_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TimeLadders(Observer, 'T', 134506T);
        Observer.Finish();
    end;

    [Test]
    procedure Time_StandardFormat0_Length_SingleDigitHour()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TimeLadders(Observer, 'T9', 090503T);
        Observer.Finish();
    end;

    [Test]
    procedure Time_StandardFormat0_Length_Milliseconds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TimeLadders(Observer, 'Tms', 134506.078T);
        Observer.Finish();
    end;

    [Test]
    procedure Time_StandardFormat0_Length_Field()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FLN Date Holder";
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Decimal_SignIntThousandDec_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecLadder(Observer, 'dec', 1234.5, '<Sign><Integer Thousand><Decimals>');
        DecLadder(Observer, 'neg', -1234.5, '<Sign><Integer Thousand><Decimals>');
        Observer.Finish();
    end;

    [Test]
    procedure Decimal_IntThousand_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecLadder(Observer, 'dec', 1234.5, '<Integer Thousand>');
        DecLadder(Observer, 'neg', -1234.5, '<Integer Thousand>');
        Observer.Finish();
    end;

    [Test]
    procedure Decimal_Prec11Sf0Comma_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecLadder(Observer, 'dec', 1234.5, '<Precision,1:1><Standard Format,0><Comma,,>');
        DecLadder(Observer, 'neg', -1234.5, '<Precision,1:1><Standard Format,0><Comma,,>');
        Observer.Finish();
    end;

    [Test]
    procedure Decimal_Int4Fill0Dec4Fill0_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecLadder(Observer, 'dec', 1234.5, '<Integer,4><Filler character,0><Decimal,4><Filler character,0>');
        DecLadder(Observer, 'neg', -1234.5, '<Integer,4><Filler character,0><Decimal,4><Filler character,0>');
        Observer.Finish();
    end;

    [Test]
    procedure Decimal_Prec22_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecLadder(Observer, 'dec', 1234.5, '<Precision,2:2>');
        DecLadder(Observer, 'neg', -1234.5, '<Precision,2:2>');
        Observer.Finish();
    end;

    [Test]
    procedure Decimal_Prec22Sf0_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecLadder(Observer, 'dec', 1234.5, '<Precision,2:2><Standard Format,0>');
        DecLadder(Observer, 'neg', -1234.5, '<Precision,2:2><Standard Format,0>');
        Observer.Finish();
    end;

    [Test]
    procedure Decimal_Sf1_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecLadder(Observer, 'dec', 1234.5, '<Standard Format,1>');
        DecLadder(Observer, 'neg', -1234.5, '<Standard Format,1>');
        Observer.Finish();
    end;

    [Test]
    procedure Decimal_Sf9_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecLadder(Observer, 'dec', 1234.5, '<Standard Format,9>');
        DecLadder(Observer, 'neg', -1234.5, '<Standard Format,9>');
        Observer.Finish();
    end;

    [Test]
    procedure Date_Year4Month2_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLadder(Observer, 'D', DMY2Date(15, 1, 2024), '<Year4>-<Month,2>');
        Observer.Finish();
    end;

    [Test]
    procedure Date_Year4Month2Day2_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLadder(Observer, 'D', DMY2Date(15, 1, 2024), '<Year4>-<Month,2>-<Day,2>');
        Observer.Finish();
    end;

    [Test]
    procedure Date_DayMonthYear2_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLadder(Observer, 'D', DMY2Date(15, 1, 2024), '<Day,2><Month,2><Year,2>');
        Observer.Finish();
    end;

    [Test]
    procedure Date_Sf0_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLadder(Observer, 'D', DMY2Date(15, 1, 2024), '<Standard Format,0>');
        Observer.Finish();
    end;

    [Test]
    procedure Date_Sf9_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLadder(Observer, 'D', DMY2Date(15, 1, 2024), '<Standard Format,9>');
        Observer.Finish();
    end;

    [Test]
    procedure Date_ClosingDay_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLadder(Observer, 'D', DMY2Date(15, 1, 2024), '<Closing><Day>');
        Observer.Finish();
    end;

    [Test]
    procedure UndefinedDateTime_SecondDec_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UndefinedLadder(Observer, '<Second dec.>');
        Observer.Finish();
    end;

    [Test]
    procedure UndefinedDateTime_Year4Month2Day2_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UndefinedLadder(Observer, '<Year4>-<Month,2>-<Day,2>');
        Observer.Finish();
    end;

    [Test]
    procedure UndefinedDateTime_DayMonthYear2_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UndefinedLadder(Observer, '<Day,2><Month,2><Year,2>');
        Observer.Finish();
    end;

    [Test]
    procedure UndefinedDateTime_Sf0_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UndefinedLadder(Observer, '<Standard Format,0>');
        Observer.Finish();
    end;

    [Test]
    procedure UndefinedDateTime_Sf9_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UndefinedLadder(Observer, '<Standard Format,9>');
        Observer.Finish();
    end;

    [Test]
    procedure UndefinedDateTime_Hours24Minutes_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UndefinedLadder(Observer, '<Hours24,2>:<Minutes,2>');
        Observer.Finish();
    end;

    [Test]
    procedure Integer_Int2Fill0_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        IntLadder(Observer, 'i7', 7, '<Integer,2><Filler Character,0>');
        IntLadder(Observer, 'i1234567', 1234567, '<Integer,2><Filler Character,0>');
        Observer.Finish();
    end;

    [Test]
    procedure Integer_Int4Fill0_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        IntLadder(Observer, 'i7', 7, '<Integer,4><Filler Character,0>');
        IntLadder(Observer, 'i1234567', 1234567, '<Integer,4><Filler Character,0>');
        Observer.Finish();
    end;

    [Test]
    procedure Integer_IntThousand_Length()
    var
        Observer: Codeunit "Probe Observer";
    begin
        IntLadder(Observer, 'i7', 7, '<Integer Thousand>');
        IntLadder(Observer, 'i1234567', 1234567, '<Integer Thousand>');
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure UndefinedDateTime_Field_Length()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FLN Date Holder";
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Insert();
        Observer.Observe('field 0DT L=5 Year4', '[' + Format(Rec.DT, 5, '<Year4>-<Month,2>-<Day,2>') + ']');
        Observer.Observe('field 0DT L=-5 Year4', '[' + Format(Rec.DT, -5, '<Year4>-<Month,2>-<Day,2>') + ']');
        Observer.Observe('field 0DT L=10 SF9', '[' + Format(Rec.DT, 10, '<Standard Format,9>') + ']');
        Observer.Observe('field 0DT L=-10 SF9', '[' + Format(Rec.DT, -10, '<Standard Format,9>') + ']');
        Observer.Finish();
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
        Observer.Finish();
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
