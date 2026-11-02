// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-dmy2date-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own test codeunit 94250
// Probe (writer Y81): DMY2Date with the year 0 and valid day and month, the value and the parts of the result; the result for Decimal, BigInteger, Byte and Char
// arguments (rounding, range errors); the result of the one and two argument forms at the edges.
// Pinned elsewhere: errors for day or month 0, -1, 13, 32, year -1 and 10000, years 1, 24, 99, 100: types/lt-datetime/DateFuncs.al:210-300.
// BC versions: 27, 28, 29

codeunit 94250 "LT Y81 DMY2Date"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Show(R: Date): Text
    begin
        if R = 0D then
            exit('[' + Format(R, 0, 9) + ']|0D');
        exit(Format(R, 0, 9) + '|' + Format(Date2DMY(R, 1)) + '.' + Format(Date2DMY(R, 2)) + '.' + Format(Date2DMY(R, 3)));
    end;

    [TryFunction]
    local procedure TryInt(D: Integer; M: Integer; Y: Integer; var R: Date)
    begin
        R := DMY2Date(D, M, Y);
    end;

    local procedure Dmy(D: Integer; M: Integer; Y: Integer): Text
    var
        R: Date;
    begin
        ClearLastError();
        if TryInt(D, M, Y, R) then
            exit(Show(R));
        exit('E ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Y81_DMY2Date_Year0_A()
    begin
        Observer.Observe('1.1.0', Dmy(1, 1, 0));
        Observer.Observe('2.1.0', Dmy(2, 1, 0));
        Observer.Observe('15.6.0', Dmy(15, 6, 0));
        Observer.Observe('28.2.0', Dmy(28, 2, 0));
        Observer.Observe('29.2.0', Dmy(29, 2, 0));
        Observer.Observe('30.2.0', Dmy(30, 2, 0));
        Observer.Observe('31.4.0', Dmy(31, 4, 0));
        Observer.Finish();
    end;

    [Test]
    procedure Y81_DMY2Date_Year0_B()
    begin
        Observer.Observe('31.12.0', Dmy(31, 12, 0));
        Observer.Observe('1.1.1', Dmy(1, 1, 1));
        Observer.Observe('2.1.1', Dmy(2, 1, 1));
        Observer.Observe('31.12.1', Dmy(31, 12, 1));
        Observer.Observe('29.2.4', Dmy(29, 2, 4));
        Observer.Observe('29.2.1', Dmy(29, 2, 1));
        Observer.Finish();
    end;

    [Test]
    procedure Y81_DMY2Date_Year0_C()
    begin
        Observer.Observe('29.2.100', Dmy(29, 2, 100));
        Observer.Observe('29.2.1900', Dmy(29, 2, 1900));
        Observer.Observe('29.2.2000', Dmy(29, 2, 2000));
        Observer.Observe('31.12.9999', Dmy(31, 12, 9999));
        Observer.Observe('1.1.9999', Dmy(1, 1, 9999));
        Observer.Finish();
    end;

    [Test]
    procedure Y81_DMY2Date_Year1_Arithmetic()
    var
        D: Date;
        Z: Date;
    begin
        D := DMY2Date(15, 6, 1);
        Observer.Observe('same as 0D', Format(D = Z));
        Observer.Observe('plus 1', Show(D + 1));
        Observer.Observe('calcdate', Show(CalcDate('<+1D>', D)));
        Observer.Observe('format 0', Format(D));
        Observer.Observe('format 1', Format(D, 0, 1));
        Observer.Observe('format 4', Format(D, 0, 4));
        Observer.Observe('dwy 1', Format(Date2DWY(D, 1)));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryDecimal(D: Decimal; M: Decimal; Y: Decimal; var R: Date)
    begin
        R := DMY2Date(D, M, Y);
    end;

    local procedure Dec(D: Decimal; M: Decimal; Y: Decimal): Text
    var
        R: Date;
    begin
        ClearLastError();
        if TryDecimal(D, M, Y, R) then
            exit(Show(R));
        exit('E ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryBig(D: BigInteger; M: BigInteger; Y: BigInteger; var R: Date)
    begin
        R := DMY2Date(D, M, Y);
    end;

    local procedure Big(D: BigInteger; M: BigInteger; Y: BigInteger): Text
    var
        R: Date;
    begin
        ClearLastError();
        if TryBig(D, M, Y, R) then
            exit(Show(R));
        exit('E ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryByte(D: Byte; M: Byte; Y: Byte; var R: Date)
    begin
        R := DMY2Date(D, M, Y);
    end;

    local procedure Byt(D: Integer; M: Integer; Y: Integer): Text
    var
        R: Date;
    begin
        ClearLastError();
        if TryByte(D, M, Y, R) then
            exit(Show(R));
        exit('E ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryChar(D: Char; M: Char; Y: Char; var R: Date)
    begin
        R := DMY2Date(D, M, Y);
    end;

    local procedure Chr(D: Integer; M: Integer; Y: Integer): Text
    var
        R: Date;
    begin
        ClearLastError();
        if TryChar(D, M, Y, R) then
            exit(Show(R));
        exit('E ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Y81_DMY2Date_DecimalArguments()
    begin
        Observer.Observe('15.0 3.0 2024.0', Dec(15, 3, 2024));
        Observer.Observe('15.4 3 2024', Dec(15.4, 3, 2024));
        Observer.Observe('15.5 3 2024', Dec(15.5, 3, 2024));
        Observer.Observe('15.6 3 2024', Dec(15.6, 3, 2024));
        Observer.Observe('15 3.5 2024', Dec(15, 3.5, 2024));
        Observer.Observe('15 3 2024.5', Dec(15, 3, 2024.5));
        Observer.Observe('0.4 3 2024', Dec(0.4, 3, 2024));
        Observer.Observe('0.5 3 2024', Dec(0.5, 3, 2024));
        Observer.Observe('1 1 0.4', Dec(1, 1, 0.4));
        Observer.Observe('1 1 0.5', Dec(1, 1, 0.5));
        Observer.Observe('-0.4 3 2024', Dec(-0.4, 3, 2024));
        Observer.Observe('1 12.5 2024', Dec(1, 12.5, 2024));
        Observer.Observe('1 1 9999.5', Dec(1, 1, 9999.5));
        Observer.Finish();
    end;

    [Test]
    procedure Y81_DMY2Date_BigIntegerArguments()
    begin
        Observer.Observe('15 3 2024', Big(15, 3, 2024));
        Observer.Observe('0 3 2024', Big(0, 3, 2024));
        Observer.Observe('1 1 0', Big(1, 1, 0));
        Observer.Observe('1 1 2147483648', Big(1, 1, 2147483648L));
        Observer.Observe('4294967297 1 2024', Big(4294967297L, 1, 2024));
        Observer.Observe('1 4294967297 2024', Big(1, 4294967297L, 2024));
        Observer.Observe('1 1 -2147483649', Big(1, 1, -2147483649L));
        Observer.Finish();
    end;

    [Test]
    procedure Y81_DMY2Date_ByteAndCharArguments()
    begin
        Observer.Observe('byte 15 3 24', Byt(15, 3, 24));
        Observer.Observe('byte 1 1 0', Byt(1, 1, 0));
        Observer.Observe('byte 0 3 24', Byt(0, 3, 24));
        Observer.Observe('byte 31 12 255', Byt(31, 12, 255));
        Observer.Observe('char 15 3 24', Chr(15, 3, 24));
        Observer.Observe('char 1 1 0', Chr(1, 1, 0));
        Observer.Observe('char 0 3 24', Chr(0, 3, 24));
        Observer.Observe('char 31 12 65535', Chr(31, 12, 65535));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryOne(D: Integer; var R: Date)
    begin
        R := DMY2Date(D);
    end;

    [TryFunction]
    local procedure TryTwo(D: Integer; M: Integer; var R: Date)
    begin
        R := DMY2Date(D, M);
    end;

    local procedure One(D: Integer): Text
    var
        R: Date;
    begin
        ClearLastError();
        if TryOne(D, R) then
            exit(Format(Date2DMY(R, 1)) + '.' + Format(Date2DMY(R, 2)) + '.' + Format(Date2DMY(R, 3) = Date2DMY(Today(), 3)));
        exit('E ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Two(D: Integer; M: Integer): Text
    var
        R: Date;
    begin
        ClearLastError();
        if TryTwo(D, M, R) then
            exit(Format(Date2DMY(R, 1)) + '.' + Format(Date2DMY(R, 2)) + '.' + Format(Date2DMY(R, 3) = Date2DMY(Today(), 3)));
        exit('E ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // The one-argument form takes the month and the year of Today(); the longest day is the length of that month.
    [Test]
    procedure Y81_DMY2Date_ShortForms_Edges()
    var
        MonthNo: Text;
        Longest: Text;
        Err: Text;
    begin
        MonthNo := Format(Date2DMY(Today(), 2));
        Longest := Format(Date2DMY(CalcDate('<CM>', Today()), 1));
        Err := 'The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: %1. The permitted range is: from 1 to ' + Longest + '.|OutsidePermittedRange';
        Observer.Observe('one 1', One(1));
        Observer.Observe('one 28', One(28));
        Observer.Observe('one 0', One(0));
        Observer.Observe('one 32', One(32));
        Observer.Observe('one -1', One(-1));
        Observer.Observe('two 31 1', Two(31, 1));
        Observer.Observe('two 31 4', Two(31, 4));
        Observer.Observe('two 1 0', Two(1, 0));
        Observer.Observe('two 1 13', Two(1, 13));
        Observer.Observe('two 0 1', Two(0, 1));
        Observer.Observe('two 28 2', Two(28, 2));
        Observer.Expect('one 1', '1.' + MonthNo + '.Yes');
        Observer.Expect('one 28', '28.' + MonthNo + '.Yes');
        Observer.Expect('one 0', 'E ' + StrSubstNo(Err, 0));
        Observer.Expect('one 32', 'E ' + StrSubstNo(Err, 32));
        Observer.Expect('one -1', 'E ' + StrSubstNo(Err, -1));
        Observer.Expect('two 31 1', '31.1.Yes');
        Observer.Expect('two 31 4', 'E The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 31. The permitted range is: from 1 to 30.|OutsidePermittedRange');
        Observer.Expect('two 1 0', 'E The value of DMY2Date parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 12.|OutsidePermittedRange');
        Observer.Expect('two 1 13', 'E The value of DMY2Date parameter 2 is outside of the permitted range. The current value is: 13. The permitted range is: from 1 to 12.|OutsidePermittedRange');
        Observer.Expect('two 0 1', 'E The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 31.|OutsidePermittedRange');
        Observer.Expect('two 28 2', '28.2.Yes');
        Observer.Verify();
    end;
}
