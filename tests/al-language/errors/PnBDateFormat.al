// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunits 70537-70540
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
//   70537: "Dates | CreateDateTime with a closing date is refused" (141), "Dates | Date2DWY year of a date whose ISO week..." (142)
//   70538: "CalcDate | A weekday formula (WDn) on a day that already is that weekday..." (143)
//   70539: "Format | format strings: <Day>, <Month> and <Year> are unpadded..." (144), "Round | a precision that is not positive..." (145)
//   70540: "Text order | <, >, <=, >= on text order by base letter..." (226), "Decimal | a quotient is rounded to 18 significant digits" (227),
//          "Text characters | Text[i] := c works for i up to one past the current length..." (201)
// BC versions: 29 (27 and 28 by CI)

codeunit 70537 "LT PnB Date2DWY Create"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryDmy(D: Date; P: Integer; var R: Integer)
    begin
        R := Date2DMY(D, P);
    end;

    [TryFunction]
    local procedure TryDwy(D: Date; P: Integer; var R: Integer)
    begin
        R := Date2DWY(D, P);
    end;

    [TryFunction]
    local procedure TryCreate(D: Date; T: Time; var R: DateTime)
    begin
        R := CreateDateTime(D, T);
    end;

    local procedure Dmy(D: Date; P: Integer): Text
    var
        R: Integer;
    begin
        if TryDmy(D, P, R) then
            exit(Format(R));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Dwy(D: Date; P: Integer): Text
    var
        R: Integer;
    begin
        if TryDwy(D, P, R) then
            exit(Format(R));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Create(D: Date; T: Time): Text
    var
        R: DateTime;
    begin
        if TryCreate(D, T, R) then
            exit(Format(R));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure CreateDateTime_ClosingDate()
    var
        Obs: Codeunit "Probe Observer";
        D: Date;
    begin
        D := ClosingDate(20240131D);
        Obs.Observe('normalDate', Create(20240131D, 120000T));
        Obs.Observe('closingDate', Create(D, 120000T));
        Obs.Observe('closingDateNoTime', Create(D, 0T));
        Obs.Observe('closingFormat', Format(D));
        Obs.Observe('closingNormal', Format(NormalDate(D)));
        Obs.Observe('closingDate2DMY1', Dmy(D, 1));
        Obs.Observe('closingDate2DMY2', Dmy(D, 2));
        Obs.Observe('closingDate2DMY3', Dmy(D, 3));
        Obs.Observe('closingDate2DWY1', Dwy(D, 1));
        Obs.Observe('closingDate2DWY2', Dwy(D, 2));
        Obs.Observe('closingDate2DWY3', Dwy(D, 3));
        Obs.Expect('normalDate', '01/31/24 12:00 PM');
        Obs.Expect('closingDate', '02/01/24 11:59 AM');
        Obs.Expect('closingDateNoTime', '01/31/24 11:59 PM');
        Obs.Expect('closingFormat', 'C01/31/24');
        Obs.Expect('closingNormal', '01/31/24');
        Obs.Expect('closingDate2DMY1', '31');
        Obs.Expect('closingDate2DMY2', '1');
        Obs.Expect('closingDate2DMY3', '2024');
        Obs.Expect('closingDate2DWY1', '3');
        Obs.Expect('closingDate2DWY2', '5');
        Obs.Expect('closingDate2DWY3', '2024');
        Obs.Verify();
    end;

    [Test]
    procedure Date2DWY_IsoWeekAcrossYears()
    var
        Obs: Codeunit "Probe Observer";
        i: Integer;
        Dates: List of [Date];
        D: Date;
    begin
        Dates.Add(20241230D);
        Dates.Add(20241231D);
        Dates.Add(20210103D);
        Dates.Add(20201231D);
        Dates.Add(20240101D);
        Dates.Add(20230101D);
        foreach D in Dates do begin
            i += 1;
            Obs.Observe('d' + Format(i) + '.dow', Dwy(D, 1));
            Obs.Observe('d' + Format(i) + '.week', Dwy(D, 2));
            Obs.Observe('d' + Format(i) + '.year', Dwy(D, 3));
        end;
        Obs.Expect('d1.dow', '1');
        Obs.Expect('d1.week', '1');
        Obs.Expect('d1.year', '2025');
        Obs.Expect('d2.dow', '2');
        Obs.Expect('d2.week', '1');
        Obs.Expect('d2.year', '2025');
        Obs.Expect('d3.dow', '7');
        Obs.Expect('d3.week', '53');
        Obs.Expect('d3.year', '2020');
        Obs.Expect('d4.dow', '4');
        Obs.Expect('d4.week', '53');
        Obs.Expect('d4.year', '2020');
        Obs.Expect('d5.dow', '1');
        Obs.Expect('d5.week', '1');
        Obs.Expect('d5.year', '2024');
        Obs.Expect('d6.dow', '7');
        Obs.Expect('d6.week', '52');
        Obs.Expect('d6.year', '2022');
        Obs.Verify();
    end;

    [Test]
    procedure Date2DWY_PartsOutOfRange()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('part0', Dwy(20240115D, 0));
        Obs.Observe('part4', Dwy(20240115D, 4));
        Obs.Observe('partMinus1', Dwy(20240115D, -1));
        Obs.Observe('dmyPart4', Dmy(20240115D, 4));
        Obs.Observe('dmyPart0', Dmy(20240115D, 0));
        Obs.Observe('dmyPart5', Dmy(20240115D, 5));
        Obs.Observe('mondayIs1', Dwy(20240115D, 1));
        Obs.Observe('sundayIs7', Dwy(20240121D, 1));
        Obs.Observe('undefinedDate1', Dwy(0D, 1));
        Obs.Observe('undefinedDate2', Dwy(0D, 2));
        Obs.Observe('undefinedDmy', Dmy(0D, 1));
        Obs.Expect('part0', 'error:The value of DATE2DWY parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 3.|OutsidePermittedRange');
        Obs.Expect('part4', 'error:The value of DATE2DWY parameter 2 is outside of the permitted range. The current value is: 4. The permitted range is: from 1 to 3.|OutsidePermittedRange');
        Obs.Expect('partMinus1', 'error:The value of DATE2DWY parameter 2 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 3.|OutsidePermittedRange');
        Obs.Expect('dmyPart4', 'error:The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: 4. The permitted range is: from 1 to 3.|OutsidePermittedRange');
        Obs.Expect('dmyPart0', 'error:The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 3.|OutsidePermittedRange');
        Obs.Expect('dmyPart5', 'error:The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: 5. The permitted range is: from 1 to 3.|OutsidePermittedRange');
        Obs.Expect('mondayIs1', '1');
        Obs.Expect('sundayIs7', '7');
        Obs.Expect('undefinedDate1', 'error:The date is not valid.|DateInvalid');
        Obs.Expect('undefinedDate2', 'error:The date is not valid.|DateInvalid');
        Obs.Expect('undefinedDmy', 'error:The date is not valid.|DateInvalid');
        Obs.Verify();
    end;
}

codeunit 70538 "LT PnB CalcDate Forms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCalc(Formula: Text; Base: Date; var R: Date)
    begin
        R := CalcDate(Formula, Base);
    end;

    [TryFunction]
    local procedure TryCalcOmitted(Formula: Text; var R: Date)
    begin
        R := CalcDate(Formula);
    end;

    local procedure Calc(Formula: Text; Base: Date): Text
    var
        R: Date;
    begin
        if TryCalc(Formula, Base, R) then
            exit(Format(R, 0, 9));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure CalcOmitted(Formula: Text): Text
    var
        R: Date;
    begin
        if TryCalcOmitted(Formula, R) then
            exit(Format(R, 0, 9));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure WeekdayFormula_SameDay()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('mon+WD1', Calc('<WD1>', 20240115D));
        Obs.Observe('sun+WD1', Calc('<WD1>', 20240114D));
        Obs.Observe('tue+WD1', Calc('<WD1>', 20240116D));
        Obs.Observe('mon+WD7', Calc('<WD7>', 20240115D));
        Obs.Observe('sun+WD7', Calc('<WD7>', 20240121D));
        Obs.Observe('mon-WD1', Calc('<-WD1>', 20240115D));
        Obs.Observe('mon+1W+WD1', Calc('<1W+WD1>', 20240115D));
        Obs.Observe('mon+CW', Calc('<CW>', 20240115D));
        Obs.Observe('mon-CW', Calc('<-CW>', 20240115D));
        Obs.Observe('mon+1WD1', Calc('<WD2>', 20240115D));
        Obs.Expect('mon+WD1', '2024-01-22');
        Obs.Expect('sun+WD1', '2024-01-15');
        Obs.Expect('tue+WD1', '2024-01-22');
        Obs.Expect('mon+WD7', '2024-01-21');
        Obs.Expect('sun+WD7', '2024-01-28');
        Obs.Expect('mon-WD1', '2024-01-08');
        Obs.Expect('mon+1W+WD1', '2024-01-29');
        Obs.Expect('mon+CW', '2024-01-21');
        Obs.Expect('mon-CW', '2024-01-15');
        Obs.Expect('mon+1WD1', '2024-01-16');
        Obs.Verify();
    end;

    [Test]
    procedure Formula_Spellings()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('upper', Calc('<1D+1M>', 20240115D));
        Obs.Observe('lower', Calc('<1d+1m>', 20240115D));
        Obs.Observe('noSignSecond', Calc('<1D1M>', 20240115D));
        Obs.Observe('noBrackets', Calc('1M', 20240115D));
        Obs.Observe('minusFirst', Calc('<-1M-1D>', 20240115D));
        Obs.Observe('CM', Calc('<CM>', 20240115D));
        Obs.Observe('CY', Calc('<CY>', 20240115D));
        Obs.Observe('CQ', Calc('<CQ>', 20240115D));
        Obs.Observe('lowerWeekday', Calc('<wd1>', 20240116D));
        Obs.Observe('endOfMonthClamp', Calc('<1M>', 20240131D));
        Obs.Observe('leap', Calc('<1Y>', 20240229D));
        Obs.Observe('badUnit', Calc('<1X>', 20240115D));
        Obs.Observe('emptyBrackets', Calc('<>', 20240115D));
        Obs.Expect('upper', '2024-02-16');
        Obs.Expect('lower', '2024-02-16');
        Obs.Expect('noSignSecond', 'error:The date formula ''1D1M'' must include plus (+) or minus (-).|Evaluate');
        Obs.Expect('noBrackets', '2024-02-15');
        Obs.Expect('minusFirst', '2023-12-14');
        Obs.Expect('CM', '2024-01-31');
        Obs.Expect('CY', '2024-12-31');
        Obs.Expect('CQ', '2024-03-31');
        Obs.Expect('lowerWeekday', '2024-01-22');
        Obs.Expect('endOfMonthClamp', '2024-02-29');
        Obs.Expect('leap', '2025-02-28');
        Obs.Expect('badUnit', 'error:The date formula ''1X'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.|Evaluate');
        Obs.Expect('emptyBrackets', '2024-01-15');
        Obs.Verify();
    end;

    [Test]
    procedure BaseDates_ClosingAndOmitted()
    var
        Obs: Codeunit "Probe Observer";
        Clos: Date;
        Orig: Date;
    begin
        Clos := ClosingDate(20240131D);
        Obs.Observe('closingBase', Calc('<1D>', Clos));
        Obs.Observe('closingBaseCM', Calc('<CM>', Clos));
        Orig := WorkDate();
        WorkDate(20240215D);
        Obs.Observe('omittedBase', CalcOmitted('<1D>'));
        Obs.Observe('base0D', Calc('<1D>', 0D));
        WorkDate(Orig);
        Obs.Expect('closingBase', '2024-02-01');
        Obs.Expect('closingBaseCM', '2024-01-31');
        Obs.Expect('omittedBase', Format(Today() + 1, 0, 9));
        Obs.Expect('base0D', 'error:You cannot base a date calculation on an undefined date.\\Date: 0D\Formula: 1D.|Argument');
        Obs.Verify();
    end;
}

codeunit 70539 "LT PnB Format Round Power"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryF(V: Variant; Pic: Text; var R: Text)
    begin
        R := Format(V, 0, Pic);
    end;

    local procedure F(V: Variant; Pic: Text): Text
    var
        R: Text;
    begin
        if TryF(V, Pic, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryRound(V: Decimal; P: Decimal; Dir: Text; var R: Decimal)
    begin
        R := Round(V, P, Dir);
    end;

    local procedure Rnd(V: Decimal; P: Decimal; Dir: Text): Text
    var
        R: Decimal;
    begin
        if TryRound(V, P, Dir, R) then
            exit(Format(R, 0, 9));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure PictureCodes_Dates()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('day', F(20240105D, '<Day>'));
        Obs.Observe('day2', F(20240105D, '<Day,2>'));
        Obs.Observe('month', F(20240105D, '<Month>'));
        Obs.Observe('month2', F(20240105D, '<Month,2>'));
        Obs.Observe('year', F(20240105D, '<Year>'));
        Obs.Observe('year4', F(20240105D, '<Year4>'));
        Obs.Observe('year2digit', F(20240105D, '<Year,2>'));
        Obs.Observe('year2005', F(20050301D, '<Year>'));
        Obs.Observe('year2005y4', F(20050301D, '<Year4>'));
        Obs.Observe('year1999', F(19990301D, '<Year>'));
        Obs.Observe('year1999y4', F(19990301D, '<Year4>'));
        Obs.Observe('year2009', F(20091231D, '<Year>'));
        Obs.Observe('year2010', F(20100101D, '<Year>'));
        Obs.Expect('day', '5');
        Obs.Expect('day2', '05');
        Obs.Expect('month', '1');
        Obs.Expect('month2', '01');
        Obs.Expect('year', '24');
        Obs.Expect('year4', '2024');
        Obs.Expect('year2digit', '24');
        Obs.Expect('year2005', '05');
        Obs.Expect('year2005y4', '2005');
        Obs.Expect('year1999', '99');
        Obs.Expect('year1999y4', '1999');
        Obs.Expect('year2009', '09');
        Obs.Expect('year2010', '10');
        Obs.Verify();
    end;

    [Test]
    procedure PictureCodes_Numbers()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('signNegative', F(-5, '<Sign><Integer>'));
        Obs.Observe('signPositive', F(5, '<Sign><Integer>'));
        Obs.Observe('decimalsNoWidth', F(5.5, '<Decimals>'));
        Obs.Observe('thousandWidth', F(1234, '<Integer Thousand,8>'));
        Obs.Observe('thousand', F(1234567, '<Integer Thousand>'));
        Obs.Observe('decimals3', F(5.5, '<Integer><Decimals,3>'));
        Obs.Observe('intWidth', F(5, '<Integer,4>'));
        Obs.Observe('intFill', F(5, '<Integer,4><Filler Character,0>'));
        Obs.Observe('hours12', F(090000T, '<Hours12,2>:<Minutes,2>'));
        Obs.Observe('hours12pm', F(150000T, '<Hours12,2>:<Minutes,2> <AM/PM>'));
        Obs.Observe('hours24', F(090000T, '<Hours24,2>:<Minutes,2>'));
        Obs.Observe('hours12single', F(090000T, '<Hours12>'));
        Obs.Expect('signNegative', '-5');
        Obs.Expect('signPositive', '5');
        Obs.Expect('decimalsNoWidth', '.5');
        Obs.Expect('thousandWidth', '   1,234');
        Obs.Expect('thousand', '1,234,567');
        Obs.Expect('decimals3', '5.50');
        Obs.Expect('intWidth', '   5');
        Obs.Expect('intFill', '0005');
        Obs.Expect('hours12', ' 9:00');
        Obs.Expect('hours12pm', ' 3:00 PM');
        Obs.Expect('hours24', ' 9:00');
        Obs.Expect('hours12single', '9');
        Obs.Verify();
    end;

    [Test]
    procedure Round_Precision()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('r0.1', Rnd(5.55, 0.1, '='));
        Obs.Observe('precision0', Rnd(5.55, 0, '='));
        Obs.Observe('precisionNegative', Rnd(5.55, -0.1, '='));
        Obs.Observe('direction>', Rnd(5.1, 1, '>'));
        Obs.Observe('direction<', Rnd(5.9, 1, '<'));
        Obs.Observe('badDirection', Rnd(5.5, 1, 'x'));
        Obs.Observe('big', Rnd(123456789.123456789, 0.000001, '='));
        Obs.Expect('r0.1', '5.6');
        Obs.Expect('precision0', 'error:The value of ROUND parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.|OutsidePermittedRange');
        Obs.Expect('precisionNegative', 'error:The value of ROUND parameter 2 is outside of the permitted range. The current value is: 0.1. The permitted range is: from 1 to 2,147,483,647.|OutsidePermittedRange');
        Obs.Expect('direction>', '6');
        Obs.Expect('direction<', '5');
        Obs.Expect('badDirection', 'error:The supplied value is not valid.|InvalidValue');
        Obs.Expect('big', '123456789.123457');
        Obs.Verify();
    end;

    [Test]
    procedure Power_ExactAndFractional()
    var
        Obs: Codeunit "Probe Observer";
    begin
        asserterror Obs.Observe('3^40', Format(Power(3, 40), 0, 9));
        Obs.ObserveError('af315');
        asserterror Obs.Observe('10^20', Format(Power(10, 20), 0, 9));
        Obs.ObserveError('af317');
        Obs.Observe('2^0.5', Format(Power(2, 0.5), 0, 9));
        Obs.Observe('3^0.5', Format(Power(3, 0.5), 0, 9));
        Obs.Observe('2^-1', Format(Power(2, -1), 0, 9));
        asserterror Obs.Observe('7^25', Format(Power(7, 25), 0, 9));
        Obs.ObserveError('af322');
        Obs.Observe('1.1^30', Format(Power(1.1, 30), 0, 9));
        Obs.Observe('0^0', Format(Power(0, 0), 0, 9));
        Obs.Observe('10^-10', Format(Power(10, -10), 0, 9));
        Obs.Observe('9^0.5', Format(Power(9, 0.5), 0, 9));
        Obs.Observe('2^30', Format(Power(2, 30), 0, 9));
        Obs.Expect('af315|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 12,157,665,459,056,928,800. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Obs.Expect('af315|code', 'OutsidePermittedRange');
        Obs.Expect('af317|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 100,000,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Obs.Expect('af317|code', 'OutsidePermittedRange');
        Obs.Expect('2^0.5', '1.4142135623731');
        Obs.Expect('3^0.5', '1.73205080756888');
        Obs.Expect('2^-1', '0.5');
        Obs.Expect('af322|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 1,341,068,619,663,964,900,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Obs.Expect('af322|code', 'OutsidePermittedRange');
        Obs.Expect('1.1^30', '17.4494022688864073');
        Obs.Expect('0^0', '1');
        Obs.Expect('10^-10', '0.0000000001');
        Obs.Expect('9^0.5', '3');
        Obs.Expect('2^30', '1073741824');
        Obs.Verify();
    end;
}

codeunit 70540 "LT PnB TextOrder Decimal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Lt(A: Text; B: Text): Text
    begin
        exit(Format(A < B) + '/' + Format(A = B));
    end;

    [Test]
    procedure TextOrder_BaseLetterAccentCase()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('a<b', Lt('a', 'b'));
        Obs.Observe('a<A', Lt('a', 'A'));
        Obs.Observe('A<b', Lt('A', 'b'));
        Obs.Observe('a<ä', Lt('a', 'ä'));
        Obs.Observe('ä<b', Lt('ä', 'b'));
        Obs.Observe('ä<A', Lt('ä', 'A'));
        Obs.Observe('é<è', Lt('é', 'è'));
        Obs.Observe('è<é', Lt('è', 'é'));
        Obs.Observe('ä<ö', Lt('ä', 'ö'));
        Obs.Observe('o<ö', Lt('o', 'ö'));
        Obs.Observe('z<ä', Lt('z', 'ä'));
        Obs.Observe('ñ<o', Lt('ñ', 'o'));
        Obs.Observe('ß<ss', Lt('ß', 'ss'));
        Obs.Observe('æ<af', Lt('æ', 'af'));
        Obs.Observe('ø<p', Lt('ø', 'p'));
        Obs.Observe('ab<a', Lt('ab', 'a'));
        Obs.Observe('empty<a', Lt('', 'a'));
        Obs.Expect('a<b', 'Yes/No');
        Obs.Expect('a<A', 'Yes/No');
        Obs.Expect('A<b', 'Yes/No');
        Obs.Expect('a<ä', 'Yes/No');
        Obs.Expect('ä<b', 'Yes/No');
        Obs.Expect('ä<A', 'No/No');
        Obs.Expect('é<è', 'Yes/No');
        Obs.Expect('è<é', 'No/No');
        Obs.Expect('ä<ö', 'Yes/No');
        Obs.Expect('o<ö', 'Yes/No');
        Obs.Expect('z<ä', 'No/No');
        Obs.Expect('ñ<o', 'Yes/No');
        Obs.Expect('ß<ss', 'No/No');
        Obs.Expect('æ<af', 'Yes/No');
        Obs.Expect('ø<p', 'Yes/No');
        Obs.Expect('ab<a', 'No/No');
        Obs.Expect('empty<a', 'Yes/No');
        Obs.Verify();
    end;

    [Test]
    procedure TextOrder_Punctuation()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('space<a', Lt(' ', 'a'));
        Obs.Observe('_<a', Lt('_', 'a'));
        Obs.Observe('1<a', Lt('1', 'a'));
        Obs.Observe('-<_', Lt('-', '_'));
        Obs.Observe('.<,', Lt('.', ','));
        Obs.Observe('!<"', Lt('!', '"'));
        Obs.Observe('(<)', Lt('(', ')'));
        Obs.Observe('+<=', Lt('+', '='));
        Obs.Observe('@<#', Lt('@', '#'));
        Obs.Observe('~<^', Lt('~', '^'));
        Obs.Observe('2<10', Lt('2', '10'));
        Obs.Observe('a-b<ab', Lt('a-b', 'ab'));
        Obs.Observe('a b<ab', Lt('a b', 'ab'));
        Obs.Observe('ä<ā', Lt('ä', 'ā'));
        Obs.Observe('Ω<a', Lt('Ω', 'a'));
        Obs.Expect('space<a', 'Yes/No');
        Obs.Expect('_<a', 'Yes/No');
        Obs.Expect('1<a', 'Yes/No');
        Obs.Expect('-<_', 'No/No');
        Obs.Expect('.<,', 'No/No');
        Obs.Expect('!<"', 'Yes/No');
        Obs.Expect('(<)', 'Yes/No');
        Obs.Expect('+<=', 'Yes/No');
        Obs.Expect('@<#', 'Yes/No');
        Obs.Expect('~<^', 'No/No');
        Obs.Expect('2<10', 'No/No');
        Obs.Expect('a-b<ab', 'Yes/No');
        Obs.Expect('a b<ab', 'Yes/No');
        Obs.Expect('ä<ā', 'Yes/No');
        Obs.Expect('Ω<a', 'No/No');
        Obs.Verify();
    end;

    [Test]
    procedure Decimal_QuotientDigits()
    var
        Obs: Codeunit "Probe Observer";
        A: Decimal;
        B: Decimal;
    begin
        A := 1;
        B := 3;
        Obs.Observe('1/3', Format(A / B, 0, 9));
        A := 2;
        Obs.Observe('2/3', Format(A / B, 0, 9));
        A := 10;
        Obs.Observe('10/3', Format(A / B, 0, 9));
        A := 1;
        B := 7;
        Obs.Observe('1/7', Format(A / B, 0, 9));
        A := 100000000;
        B := 3;
        Obs.Observe('1e8/3', Format(A / B, 0, 9));
        A := 1;
        B := 3000000000.0;
        Obs.Observe('1/3e9', Format(A / B, 0, 9));
        A := 0.1234567890123456789;
        B := 3;
        Obs.Observe('mul', Format(A * B, 0, 9));
        A := 0.1234567890123456789;
        B := 0.1234567890123456789;
        Obs.Observe('mulSquare', Format(A * B, 0, 9));
        Obs.Observe('add', Format(A + B, 0, 9));
        A := 12345678901234567.89;
        B := 3;
        asserterror Obs.Observe('bigDiv', Format(A / B, 0, 9));
        Obs.ObserveError('af422');
        asserterror Obs.Observe('bigMul', Format(A * B, 0, 9));
        Obs.ObserveError('af425');
        Obs.Expect('1/3', '0.333333333333333333');
        Obs.Expect('2/3', '0.666666666666666667');
        Obs.Expect('10/3', '3.33333333333333333');
        Obs.Expect('1/7', '0.142857142857142857');
        Obs.Expect('1e8/3', '33333333.3333333333');
        Obs.Expect('1/3e9', '0.000000000333333333');
        Obs.Expect('mul', '0.370370367037037037');
        Obs.Expect('mulSquare', '0.015241578753238837');
        Obs.Expect('add', '0.246913578024691358');
        Obs.Expect('af422|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 4,115,226,300,411,522.63. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Obs.Expect('af422|code', 'OutsidePermittedRange');
        Obs.Expect('af425|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 37,037,036,703,703,703.7. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Obs.Expect('af425|code', 'OutsidePermittedRange');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TrySet(var T: Text[5]; Pos: Integer; Ch: Integer)
    begin
        T[Pos] := Ch;
    end;

    local procedure SetCh(var T: Text[5]; Pos: Integer; Ch: Integer): Text
    begin
        if TrySet(T, Pos, Ch) then
            exit('ok:' + T);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure TextCharAssign()
    var
        Obs: Codeunit "Probe Observer";
        T: Text[5];
        C: Code[5];
        Big: Text;
    begin
        T := 'abc';
        Obs.Observe('replace', SetCh(T, 2, 88));
        Obs.Observe('appendAtLenPlus1', SetCh(T, 4, 89));
        Obs.Observe('farBeyond', SetCh(T, 7, 90));
        Obs.Observe('afterFar', T);
        Obs.Observe('atDeclaredLen', SetCh(T, 5, 87));
        Obs.Observe('pastDeclared', SetCh(T, 6, 86));
        T := 'abc';
        Obs.Observe('gap', SetCh(T, 5, 81));
        Obs.Observe('index0', SetCh(T, 0, 81));
        Obs.Observe('negative', SetCh(T, -1, 81));
        Obs.Observe('code233', SetCh(T, 1, 233));
        Obs.Observe('code65', SetCh(T, 1, 65));
        Obs.Observe('code0', SetCh(T, 1, 0));
        Obs.Observe('code65535', SetCh(T, 1, 65535));
        Obs.Observe('surrogate', SetCh(T, 1, 55357));
        Obs.Observe('code65536', SetCh(T, 1, 65536));
        C := 'ab';
        C[1] := 'z';
        Obs.Observe('codeAssign', C);
        Big := 'hello';
        Big[1] := 'J';
        Obs.Observe('bigText', Big);
        Big[6] := '!';
        Obs.Observe('bigAppend', Big);
        Obs.Expect('replace', 'ok:aXc');
        Obs.Expect('appendAtLenPlus1', 'ok:aXcY');
        Obs.Expect('farBeyond', 'error:The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 7. The permitted range is: from 1 to 4.|OutsidePermittedRange');
        Obs.Expect('afterFar', 'aXcY');
        Obs.Expect('atDeclaredLen', 'ok:aXcYW');
        Obs.Expect('pastDeclared', 'error:The length of the string is 6, but it must be less than or equal to 5 characters. Value: aXcYWV|StringLengthExceeded');
        Obs.Expect('gap', 'error:The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 5. The permitted range is: from 1 to 3.|OutsidePermittedRange');
        Obs.Expect('index0', 'error:The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 3.|OutsidePermittedRange');
        Obs.Expect('negative', 'error:The value of INDEXING parameter 1 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 3.|OutsidePermittedRange');
        Obs.Expect('code233', 'ok:ébc');
        Obs.Expect('code65', 'ok:Abc');
        Obs.Expect('code0', 'ok:');
        Obs.Expect('code65535', 'ok:\uFFFF');
        Obs.Expect('surrogate', 'ok:\uD83D');
        Obs.Expect('code65536', 'error:Overflow under conversion of System.Int32 value 65536 to System.Char.|ConversionCast');
        Obs.Expect('codeAssign', 'ZB');
        Obs.Expect('bigText', 'Jello');
        Obs.Expect('bigAppend', 'Jello!');
        Obs.Verify();
    end;
}
