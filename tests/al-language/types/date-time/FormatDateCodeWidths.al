// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: observed on the corpus CI (BC on Linux, legs 27.5, 28.5 and 29.0); every literal asserted below is what BC produced.
// Topic: the width of the date codes <Day>, <Month>, <Year> and <Year4> in a custom format string, on a Date and on a DateTime.
//   Each code without a width and with the widths 0 to 6, on dates in the years 5, 999, 2016 and 9999 (Date) and in 2016 (DateTime).
//   A format string BC refuses is observed as err:<error code> (the whole text of the widths 0 and 6 in Date_Format_ErrorText).
//   (AL Runner issue 6966: <Year4,4><Month,2><Day,2> of an ISV's import.)
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
        Observer.Finish();
    end;

    [Test]
    procedure Date_Format_Year4Width_LargeYears()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveLargeYears(Observer, 'Year4');
        Observer.Finish();
    end;

    [Test]
    procedure Date_Format_YearWidth_SmallYears()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSmallYears(Observer, 'Year');
        Observer.Finish();
    end;

    [Test]
    procedure Date_Format_YearWidth_LargeYears()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveLargeYears(Observer, 'Year');
        Observer.Finish();
    end;

    [Test]
    procedure Date_Format_MonthWidth_SmallYears()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSmallYears(Observer, 'Month');
        Observer.Finish();
    end;

    [Test]
    procedure Date_Format_MonthWidth_LargeYears()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveLargeYears(Observer, 'Month');
        Observer.Finish();
    end;

    [Test]
    procedure Date_Format_DayWidth_SmallYears()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSmallYears(Observer, 'Day');
        Observer.Finish();
    end;

    [Test]
    procedure Date_Format_DayWidth_LargeYears()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveLargeYears(Observer, 'Day');
        Observer.Finish();
    end;

    [Test]
    procedure DateTime_Format_Year4Width()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveDateTimes(Observer, 'Year4');
        Observer.Finish();
    end;

    [Test]
    procedure DateTime_Format_YearWidth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveDateTimes(Observer, 'Year');
        Observer.Finish();
    end;

    [Test]
    procedure DateTime_Format_MonthWidth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveDateTimes(Observer, 'Month');
        Observer.Finish();
    end;

    [Test]
    procedure DateTime_Format_DayWidth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveDateTimes(Observer, 'Day');
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
