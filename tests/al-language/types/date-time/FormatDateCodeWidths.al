// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: observed on the corpus CI (BC on Linux, legs 27.5, 28.5 and 29.0); every literal asserted below is what BC produced.
// Topic: the width of the date codes <Day>, <Month>, <Year> and <Year4> in a custom format string, on a Date and on a DateTime.
//   Each code without a width and with the widths 0 to 6, on dates in the years 5, 999, 2016 and 9999 (Date) and in 2016 (DateTime).
//   A format string BC refuses is observed as err:<error code> (the whole text of the widths 0 and 6 in Date_Format_ErrorText).
//   (AL Runner issue 6966: <Year4,4><Month,2><Day,2> of an ISV's import.) <Year>, <Year,2>, <Year,3> and <Year,4> of the years 1900,
//   1949, 1950, 1965, 1997, 2000, 2001, 2032, 2049, 2050, 2065 and 2100 on a Date and a DateTime (AL Runner issue 7019: <Year> of 1965).
// Facts (29.0): no format string here is refused. Without a width and with width 0 each code gives its number as is: <Day> and <Month>
//   without padding, <Year4> with four digits (0005, 0999, 2016, 9999), <Year> with two digits for 2016 and four for 5, 999 and 9999. With a
//   width N of 1 to 6 that number is padded with zeros on the left to N characters, or is N stars when it has more characters than N
//   (<Year4,2> is **, <Year,3> of 2016 is 016, <Day,1> of 14 is *). Date and DateTime alike; <year4,4> is read as <Year4,4>.
//   <Year> has two digits for the years 1950 to 2049 and four for the others (1900, 1949, 2050, 2065, 2100), on a Date and a DateTime;
//   its widths follow the same rule (<Year,4> of 1965 is 0065, <Year,2> of 2050 is **).
// BC versions: 27.5, 28.5, 29.0

codeunit 95480 "DT Format Date Code Width"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFormatInner(V: Variant; F: Text; var Result: Text)
    var
        D: Date;
        DT: DateTime;
    begin
        if V.IsDate() then begin
            D := V;
            Result := Format(D, 0, F);
        end else begin
            DT := V;
            Result := Format(DT, 0, F);
        end;
    end;

    // A refused string gives err:<error code>; Date_Format_ErrorText observes the whole text of one.
    local procedure TryFormat(V: Variant; F: Text): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if not TryFormatInner(V, F, Result) then
            exit('err:' + GetLastErrorCode());
        exit(Result);
    end;

    local procedure TryFormatText(V: Variant; F: Text): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if not TryFormatInner(V, F, Result) then
            exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit(Result);
    end;

    // Observes <Code>, <Code,0> ... <Code,6> of V under the name prefix Name.
    local procedure ObserveWidths(var Observer: Codeunit "Probe Observer"; Name: Text; V: Variant; Code: Text)
    var
        W: Integer;
    begin
        Observer.Observe(Name + ' <' + Code + '>', TryFormat(V, '<' + Code + '>'));
        for W := 0 to 6 do
            Observer.Observe(Name + ' <' + Code + ',' + Format(W) + '>', TryFormat(V, '<' + Code + ',' + Format(W) + '>'));
    end;

    local procedure ObserveSmallYears(var Observer: Codeunit "Probe Observer"; Code: Text)
    begin
        ObserveWidths(Observer, '0005-03-05', DMY2Date(5, 3, 5), Code);
        ObserveWidths(Observer, '0999-11-25', DMY2Date(25, 11, 999), Code);
    end;

    local procedure ObserveLargeYears(var Observer: Codeunit "Probe Observer"; Code: Text)
    begin
        ObserveWidths(Observer, '2016-12-14', DMY2Date(14, 12, 2016), Code);
        ObserveWidths(Observer, '9999-12-31', DMY2Date(31, 12, 9999), Code);
    end;

    local procedure ObserveDateTimes(var Observer: Codeunit "Probe Observer"; Code: Text)
    begin
        ObserveWidths(Observer, 'DT 2016-03-05', CreateDateTime(DMY2Date(5, 3, 2016), 120000T), Code);
        ObserveWidths(Observer, 'DT 2016-12-14', CreateDateTime(DMY2Date(14, 12, 2016), 120000T), Code);
    end;

    [Test]
    procedure Date_Format_Year4Width_SmallYears()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSmallYears(Observer, 'Year4');
        Observer.Expect('0005-03-05 <Year4>', '0005');
        Observer.Expect('0005-03-05 <Year4,0>', '0005');
        Observer.Expect('0005-03-05 <Year4,1>', '*');
        Observer.Expect('0005-03-05 <Year4,2>', '**');
        Observer.Expect('0005-03-05 <Year4,3>', '***');
        Observer.Expect('0005-03-05 <Year4,4>', '0005');
        Observer.Expect('0005-03-05 <Year4,5>', '00005');
        Observer.Expect('0005-03-05 <Year4,6>', '000005');
        Observer.Expect('0999-11-25 <Year4>', '0999');
        Observer.Expect('0999-11-25 <Year4,0>', '0999');
        Observer.Expect('0999-11-25 <Year4,1>', '*');
        Observer.Expect('0999-11-25 <Year4,2>', '**');
        Observer.Expect('0999-11-25 <Year4,3>', '***');
        Observer.Expect('0999-11-25 <Year4,4>', '0999');
        Observer.Expect('0999-11-25 <Year4,5>', '00999');
        Observer.Expect('0999-11-25 <Year4,6>', '000999');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Format_Year4Width_LargeYears()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveLargeYears(Observer, 'Year4');
        Observer.Expect('2016-12-14 <Year4>', '2016');
        Observer.Expect('2016-12-14 <Year4,0>', '2016');
        Observer.Expect('2016-12-14 <Year4,1>', '*');
        Observer.Expect('2016-12-14 <Year4,2>', '**');
        Observer.Expect('2016-12-14 <Year4,3>', '***');
        Observer.Expect('2016-12-14 <Year4,4>', '2016');
        Observer.Expect('2016-12-14 <Year4,5>', '02016');
        Observer.Expect('2016-12-14 <Year4,6>', '002016');
        Observer.Expect('9999-12-31 <Year4>', '9999');
        Observer.Expect('9999-12-31 <Year4,0>', '9999');
        Observer.Expect('9999-12-31 <Year4,1>', '*');
        Observer.Expect('9999-12-31 <Year4,2>', '**');
        Observer.Expect('9999-12-31 <Year4,3>', '***');
        Observer.Expect('9999-12-31 <Year4,4>', '9999');
        Observer.Expect('9999-12-31 <Year4,5>', '09999');
        Observer.Expect('9999-12-31 <Year4,6>', '009999');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Format_YearWidth_SmallYears()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSmallYears(Observer, 'Year');
        Observer.Expect('0005-03-05 <Year>', '0005');
        Observer.Expect('0005-03-05 <Year,0>', '0005');
        Observer.Expect('0005-03-05 <Year,1>', '*');
        Observer.Expect('0005-03-05 <Year,2>', '**');
        Observer.Expect('0005-03-05 <Year,3>', '***');
        Observer.Expect('0005-03-05 <Year,4>', '0005');
        Observer.Expect('0005-03-05 <Year,5>', '00005');
        Observer.Expect('0005-03-05 <Year,6>', '000005');
        Observer.Expect('0999-11-25 <Year>', '0999');
        Observer.Expect('0999-11-25 <Year,0>', '0999');
        Observer.Expect('0999-11-25 <Year,1>', '*');
        Observer.Expect('0999-11-25 <Year,2>', '**');
        Observer.Expect('0999-11-25 <Year,3>', '***');
        Observer.Expect('0999-11-25 <Year,4>', '0999');
        Observer.Expect('0999-11-25 <Year,5>', '00999');
        Observer.Expect('0999-11-25 <Year,6>', '000999');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Format_YearWidth_LargeYears()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveLargeYears(Observer, 'Year');
        Observer.Expect('2016-12-14 <Year>', '16');
        Observer.Expect('2016-12-14 <Year,0>', '16');
        Observer.Expect('2016-12-14 <Year,1>', '*');
        Observer.Expect('2016-12-14 <Year,2>', '16');
        Observer.Expect('2016-12-14 <Year,3>', '016');
        Observer.Expect('2016-12-14 <Year,4>', '0016');
        Observer.Expect('2016-12-14 <Year,5>', '00016');
        Observer.Expect('2016-12-14 <Year,6>', '000016');
        Observer.Expect('9999-12-31 <Year>', '9999');
        Observer.Expect('9999-12-31 <Year,0>', '9999');
        Observer.Expect('9999-12-31 <Year,1>', '*');
        Observer.Expect('9999-12-31 <Year,2>', '**');
        Observer.Expect('9999-12-31 <Year,3>', '***');
        Observer.Expect('9999-12-31 <Year,4>', '9999');
        Observer.Expect('9999-12-31 <Year,5>', '09999');
        Observer.Expect('9999-12-31 <Year,6>', '009999');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Format_MonthWidth_SmallYears()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSmallYears(Observer, 'Month');
        Observer.Expect('0005-03-05 <Month>', '3');
        Observer.Expect('0005-03-05 <Month,0>', '3');
        Observer.Expect('0005-03-05 <Month,1>', '3');
        Observer.Expect('0005-03-05 <Month,2>', '03');
        Observer.Expect('0005-03-05 <Month,3>', '003');
        Observer.Expect('0005-03-05 <Month,4>', '0003');
        Observer.Expect('0005-03-05 <Month,5>', '00003');
        Observer.Expect('0005-03-05 <Month,6>', '000003');
        Observer.Expect('0999-11-25 <Month>', '11');
        Observer.Expect('0999-11-25 <Month,0>', '11');
        Observer.Expect('0999-11-25 <Month,1>', '*');
        Observer.Expect('0999-11-25 <Month,2>', '11');
        Observer.Expect('0999-11-25 <Month,3>', '011');
        Observer.Expect('0999-11-25 <Month,4>', '0011');
        Observer.Expect('0999-11-25 <Month,5>', '00011');
        Observer.Expect('0999-11-25 <Month,6>', '000011');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Format_MonthWidth_LargeYears()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveLargeYears(Observer, 'Month');
        Observer.Expect('2016-12-14 <Month>', '12');
        Observer.Expect('2016-12-14 <Month,0>', '12');
        Observer.Expect('2016-12-14 <Month,1>', '*');
        Observer.Expect('2016-12-14 <Month,2>', '12');
        Observer.Expect('2016-12-14 <Month,3>', '012');
        Observer.Expect('2016-12-14 <Month,4>', '0012');
        Observer.Expect('2016-12-14 <Month,5>', '00012');
        Observer.Expect('2016-12-14 <Month,6>', '000012');
        Observer.Expect('9999-12-31 <Month>', '12');
        Observer.Expect('9999-12-31 <Month,0>', '12');
        Observer.Expect('9999-12-31 <Month,1>', '*');
        Observer.Expect('9999-12-31 <Month,2>', '12');
        Observer.Expect('9999-12-31 <Month,3>', '012');
        Observer.Expect('9999-12-31 <Month,4>', '0012');
        Observer.Expect('9999-12-31 <Month,5>', '00012');
        Observer.Expect('9999-12-31 <Month,6>', '000012');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Format_DayWidth_SmallYears()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSmallYears(Observer, 'Day');
        Observer.Expect('0005-03-05 <Day>', '5');
        Observer.Expect('0005-03-05 <Day,0>', '5');
        Observer.Expect('0005-03-05 <Day,1>', '5');
        Observer.Expect('0005-03-05 <Day,2>', '05');
        Observer.Expect('0005-03-05 <Day,3>', '005');
        Observer.Expect('0005-03-05 <Day,4>', '0005');
        Observer.Expect('0005-03-05 <Day,5>', '00005');
        Observer.Expect('0005-03-05 <Day,6>', '000005');
        Observer.Expect('0999-11-25 <Day>', '25');
        Observer.Expect('0999-11-25 <Day,0>', '25');
        Observer.Expect('0999-11-25 <Day,1>', '*');
        Observer.Expect('0999-11-25 <Day,2>', '25');
        Observer.Expect('0999-11-25 <Day,3>', '025');
        Observer.Expect('0999-11-25 <Day,4>', '0025');
        Observer.Expect('0999-11-25 <Day,5>', '00025');
        Observer.Expect('0999-11-25 <Day,6>', '000025');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Format_DayWidth_LargeYears()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveLargeYears(Observer, 'Day');
        Observer.Expect('2016-12-14 <Day>', '14');
        Observer.Expect('2016-12-14 <Day,0>', '14');
        Observer.Expect('2016-12-14 <Day,1>', '*');
        Observer.Expect('2016-12-14 <Day,2>', '14');
        Observer.Expect('2016-12-14 <Day,3>', '014');
        Observer.Expect('2016-12-14 <Day,4>', '0014');
        Observer.Expect('2016-12-14 <Day,5>', '00014');
        Observer.Expect('2016-12-14 <Day,6>', '000014');
        Observer.Expect('9999-12-31 <Day>', '31');
        Observer.Expect('9999-12-31 <Day,0>', '31');
        Observer.Expect('9999-12-31 <Day,1>', '*');
        Observer.Expect('9999-12-31 <Day,2>', '31');
        Observer.Expect('9999-12-31 <Day,3>', '031');
        Observer.Expect('9999-12-31 <Day,4>', '0031');
        Observer.Expect('9999-12-31 <Day,5>', '00031');
        Observer.Expect('9999-12-31 <Day,6>', '000031');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Format_Year4Width()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveDateTimes(Observer, 'Year4');
        Observer.Expect('DT 2016-03-05 <Year4>', '2016');
        Observer.Expect('DT 2016-03-05 <Year4,0>', '2016');
        Observer.Expect('DT 2016-03-05 <Year4,1>', '*');
        Observer.Expect('DT 2016-03-05 <Year4,2>', '**');
        Observer.Expect('DT 2016-03-05 <Year4,3>', '***');
        Observer.Expect('DT 2016-03-05 <Year4,4>', '2016');
        Observer.Expect('DT 2016-03-05 <Year4,5>', '02016');
        Observer.Expect('DT 2016-03-05 <Year4,6>', '002016');
        Observer.Expect('DT 2016-12-14 <Year4>', '2016');
        Observer.Expect('DT 2016-12-14 <Year4,0>', '2016');
        Observer.Expect('DT 2016-12-14 <Year4,1>', '*');
        Observer.Expect('DT 2016-12-14 <Year4,2>', '**');
        Observer.Expect('DT 2016-12-14 <Year4,3>', '***');
        Observer.Expect('DT 2016-12-14 <Year4,4>', '2016');
        Observer.Expect('DT 2016-12-14 <Year4,5>', '02016');
        Observer.Expect('DT 2016-12-14 <Year4,6>', '002016');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Format_YearWidth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveDateTimes(Observer, 'Year');
        Observer.Expect('DT 2016-03-05 <Year>', '16');
        Observer.Expect('DT 2016-03-05 <Year,0>', '16');
        Observer.Expect('DT 2016-03-05 <Year,1>', '*');
        Observer.Expect('DT 2016-03-05 <Year,2>', '16');
        Observer.Expect('DT 2016-03-05 <Year,3>', '016');
        Observer.Expect('DT 2016-03-05 <Year,4>', '0016');
        Observer.Expect('DT 2016-03-05 <Year,5>', '00016');
        Observer.Expect('DT 2016-03-05 <Year,6>', '000016');
        Observer.Expect('DT 2016-12-14 <Year>', '16');
        Observer.Expect('DT 2016-12-14 <Year,0>', '16');
        Observer.Expect('DT 2016-12-14 <Year,1>', '*');
        Observer.Expect('DT 2016-12-14 <Year,2>', '16');
        Observer.Expect('DT 2016-12-14 <Year,3>', '016');
        Observer.Expect('DT 2016-12-14 <Year,4>', '0016');
        Observer.Expect('DT 2016-12-14 <Year,5>', '00016');
        Observer.Expect('DT 2016-12-14 <Year,6>', '000016');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Format_MonthWidth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveDateTimes(Observer, 'Month');
        Observer.Expect('DT 2016-03-05 <Month>', '3');
        Observer.Expect('DT 2016-03-05 <Month,0>', '3');
        Observer.Expect('DT 2016-03-05 <Month,1>', '3');
        Observer.Expect('DT 2016-03-05 <Month,2>', '03');
        Observer.Expect('DT 2016-03-05 <Month,3>', '003');
        Observer.Expect('DT 2016-03-05 <Month,4>', '0003');
        Observer.Expect('DT 2016-03-05 <Month,5>', '00003');
        Observer.Expect('DT 2016-03-05 <Month,6>', '000003');
        Observer.Expect('DT 2016-12-14 <Month>', '12');
        Observer.Expect('DT 2016-12-14 <Month,0>', '12');
        Observer.Expect('DT 2016-12-14 <Month,1>', '*');
        Observer.Expect('DT 2016-12-14 <Month,2>', '12');
        Observer.Expect('DT 2016-12-14 <Month,3>', '012');
        Observer.Expect('DT 2016-12-14 <Month,4>', '0012');
        Observer.Expect('DT 2016-12-14 <Month,5>', '00012');
        Observer.Expect('DT 2016-12-14 <Month,6>', '000012');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Format_DayWidth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveDateTimes(Observer, 'Day');
        Observer.Expect('DT 2016-03-05 <Day>', '5');
        Observer.Expect('DT 2016-03-05 <Day,0>', '5');
        Observer.Expect('DT 2016-03-05 <Day,1>', '5');
        Observer.Expect('DT 2016-03-05 <Day,2>', '05');
        Observer.Expect('DT 2016-03-05 <Day,3>', '005');
        Observer.Expect('DT 2016-03-05 <Day,4>', '0005');
        Observer.Expect('DT 2016-03-05 <Day,5>', '00005');
        Observer.Expect('DT 2016-03-05 <Day,6>', '000005');
        Observer.Expect('DT 2016-12-14 <Day>', '14');
        Observer.Expect('DT 2016-12-14 <Day,0>', '14');
        Observer.Expect('DT 2016-12-14 <Day,1>', '*');
        Observer.Expect('DT 2016-12-14 <Day,2>', '14');
        Observer.Expect('DT 2016-12-14 <Day,3>', '014');
        Observer.Expect('DT 2016-12-14 <Day,4>', '0014');
        Observer.Expect('DT 2016-12-14 <Day,5>', '00014');
        Observer.Expect('DT 2016-12-14 <Day,6>', '000014');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Format_IssueStrings()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := DMY2Date(14, 12, 2016);
        Observer.Observe('<Year4,4><Month,2><Day,2>', TryFormat(D, '<Year4,4><Month,2><Day,2>'));
        Observer.Observe('<Day,2>.<Month,2>.<Year4,4>', TryFormat(D, '<Day,2>.<Month,2>.<Year4,4>'));
        Observer.Observe('<year4,4>', TryFormat(D, '<year4,4>'));
        Observer.Observe('<Filler Character,0><Year4,6>', TryFormat(D, '<Filler Character,0><Year4,6>'));
        Observer.Observe('<Filler Character,0><Year,4>', TryFormat(D, '<Filler Character,0><Year,4>'));
        Observer.Expect('<Year4,4><Month,2><Day,2>', '20161214');
        Observer.Expect('<Day,2>.<Month,2>.<Year4,4>', '14.12.2016');
        Observer.Expect('<year4,4>', '2016');
        Observer.Expect('<Filler Character,0><Year4,6>', '002016');
        Observer.Expect('<Filler Character,0><Year,4>', '0016');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Format_ErrorText()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := DMY2Date(14, 12, 2016);
        Observer.Observe('<Year4,0>', TryFormatText(D, '<Year4,0>'));
        Observer.Observe('<Year4,6>', TryFormatText(D, '<Year4,6>'));
        Observer.Observe('<Year,0>', TryFormatText(D, '<Year,0>'));
        Observer.Observe('<Month,0>', TryFormatText(D, '<Month,0>'));
        Observer.Observe('<Day,0>', TryFormatText(D, '<Day,0>'));
        Observer.Observe('<Day,6>', TryFormatText(D, '<Day,6>'));
        Observer.Expect('<Year4,0>', '2016');
        Observer.Expect('<Year4,6>', '002016');
        Observer.Expect('<Year,0>', '16');
        Observer.Expect('<Month,0>', '12');
        Observer.Expect('<Day,0>', '14');
        Observer.Expect('<Day,6>', '000014');
        Observer.Verify();
    end;

    // <Year> and its widths across the century boundaries (AL Runner issue 7019: <Year> of a date in 1965), on a Date and on a DateTime.
    local procedure ObserveYearWindow(var Observer: Codeunit "Probe Observer"; Year: Integer)
    var
        D: Date;
        DT: DateTime;
    begin
        D := DMY2Date(1, 1, Year);
        DT := CreateDateTime(DMY2Date(1, 7, Year), 120000T);
        Observer.Observe(Format(Year) + ' <Year>', TryFormat(D, '<Year>'));
        Observer.Observe(Format(Year) + ' <Year,2>', TryFormat(D, '<Year,2>'));
        Observer.Observe(Format(Year) + ' <Year,3>', TryFormat(D, '<Year,3>'));
        Observer.Observe(Format(Year) + ' <Year,4>', TryFormat(D, '<Year,4>'));
        Observer.Observe(Format(Year) + ' DT <Year>', TryFormat(DT, '<Year>'));
        Observer.Observe(Format(Year) + ' DT <Year,2>', TryFormat(DT, '<Year,2>'));
    end;

    [Test]
    procedure Date_Format_YearWindow_1900To1950()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveYearWindow(Observer, 1900);
        ObserveYearWindow(Observer, 1949);
        ObserveYearWindow(Observer, 1950);
        ObserveYearWindow(Observer, 1965);
        Observer.Expect('1900 <Year>', '1900');
        Observer.Expect('1900 <Year,2>', '**');
        Observer.Expect('1900 <Year,3>', '***');
        Observer.Expect('1900 <Year,4>', '1900');
        Observer.Expect('1900 DT <Year>', '1900');
        Observer.Expect('1900 DT <Year,2>', '**');
        Observer.Expect('1949 <Year>', '1949');
        Observer.Expect('1949 <Year,2>', '**');
        Observer.Expect('1949 <Year,3>', '***');
        Observer.Expect('1949 <Year,4>', '1949');
        Observer.Expect('1949 DT <Year>', '1949');
        Observer.Expect('1949 DT <Year,2>', '**');
        Observer.Expect('1950 <Year>', '50');
        Observer.Expect('1950 <Year,2>', '50');
        Observer.Expect('1950 <Year,3>', '050');
        Observer.Expect('1950 <Year,4>', '0050');
        Observer.Expect('1950 DT <Year>', '50');
        Observer.Expect('1950 DT <Year,2>', '50');
        Observer.Expect('1965 <Year>', '65');
        Observer.Expect('1965 <Year,2>', '65');
        Observer.Expect('1965 <Year,3>', '065');
        Observer.Expect('1965 <Year,4>', '0065');
        Observer.Expect('1965 DT <Year>', '65');
        Observer.Expect('1965 DT <Year,2>', '65');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Format_YearWindow_1997To2032()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveYearWindow(Observer, 1997);
        ObserveYearWindow(Observer, 2000);
        ObserveYearWindow(Observer, 2001);
        ObserveYearWindow(Observer, 2032);
        Observer.Expect('1997 <Year>', '97');
        Observer.Expect('1997 <Year,2>', '97');
        Observer.Expect('1997 <Year,3>', '097');
        Observer.Expect('1997 <Year,4>', '0097');
        Observer.Expect('1997 DT <Year>', '97');
        Observer.Expect('1997 DT <Year,2>', '97');
        Observer.Expect('2000 <Year>', '00');
        Observer.Expect('2000 <Year,2>', '00');
        Observer.Expect('2000 <Year,3>', '000');
        Observer.Expect('2000 <Year,4>', '0000');
        Observer.Expect('2000 DT <Year>', '00');
        Observer.Expect('2000 DT <Year,2>', '00');
        Observer.Expect('2001 <Year>', '01');
        Observer.Expect('2001 <Year,2>', '01');
        Observer.Expect('2001 <Year,3>', '001');
        Observer.Expect('2001 <Year,4>', '0001');
        Observer.Expect('2001 DT <Year>', '01');
        Observer.Expect('2001 DT <Year,2>', '01');
        Observer.Expect('2032 <Year>', '32');
        Observer.Expect('2032 <Year,2>', '32');
        Observer.Expect('2032 <Year,3>', '032');
        Observer.Expect('2032 <Year,4>', '0032');
        Observer.Expect('2032 DT <Year>', '32');
        Observer.Expect('2032 DT <Year,2>', '32');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Format_YearWindow_2049To2100()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveYearWindow(Observer, 2049);
        ObserveYearWindow(Observer, 2050);
        ObserveYearWindow(Observer, 2065);
        ObserveYearWindow(Observer, 2100);
        Observer.Expect('2049 <Year>', '49');
        Observer.Expect('2049 <Year,2>', '49');
        Observer.Expect('2049 <Year,3>', '049');
        Observer.Expect('2049 <Year,4>', '0049');
        Observer.Expect('2049 DT <Year>', '49');
        Observer.Expect('2049 DT <Year,2>', '49');
        Observer.Expect('2050 <Year>', '2050');
        Observer.Expect('2050 <Year,2>', '**');
        Observer.Expect('2050 <Year,3>', '***');
        Observer.Expect('2050 <Year,4>', '2050');
        Observer.Expect('2050 DT <Year>', '2050');
        Observer.Expect('2050 DT <Year,2>', '**');
        Observer.Expect('2065 <Year>', '2065');
        Observer.Expect('2065 <Year,2>', '**');
        Observer.Expect('2065 <Year,3>', '***');
        Observer.Expect('2065 <Year,4>', '2065');
        Observer.Expect('2065 DT <Year>', '2065');
        Observer.Expect('2065 DT <Year,2>', '**');
        Observer.Expect('2100 <Year>', '2100');
        Observer.Expect('2100 <Year,2>', '**');
        Observer.Expect('2100 <Year,3>', '***');
        Observer.Expect('2100 <Year,4>', '2100');
        Observer.Expect('2100 DT <Year>', '2100');
        Observer.Expect('2100 DT <Year,2>', '**');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Format_YearWindow_IssueString()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('<Month,2>/<Day,2>/<Year>', TryFormat(DMY2Date(1, 1, 1965), '<Month,2>/<Day,2>/<Year>'));
        Observer.Expect('<Month,2>/<Day,2>/<Year>', '01/01/65');
        Observer.Verify();
    end;
}
