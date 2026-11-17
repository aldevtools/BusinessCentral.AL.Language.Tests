// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope. Format(Date, 0, picture) with <Month Text> and <Weekday Text> (with and without a length) and standard format 4, under GlobalLanguage 1033, 1030, 1031, 1036, 1044 and 1053.
// Fixtures used: Probe Observer (codeunit 69160); own objects 75402 (LT GL Month Weekday)
// Probe: from al-runner issues 8178, 8182, 8183, 8197, 8199 and 8200 (an outside reporter measured BC 28.4 W1, en-US region). Observed on
//   Windows BC containers 27.5, 28.5 and 29.0; every literal asserted below is what BC produced. The corpus CI matrix checks it on BC on Linux.
// Facts: TODO
// BC versions: 27, 28, 29

codeunit 75402 "LT GL Month Weekday"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFormatPicture(D: Date; Picture: Text; var Txt: Text)
    begin
        Txt := Format(D, 0, Picture);
    end;

    [TryFunction]
    local procedure TryFormatStd(D: Date; Std: Integer; var Txt: Text)
    begin
        Txt := Format(D, 0, Std);
    end;

    local procedure Pic(D: Date; Picture: Text): Text
    var
        Txt: Text;
    begin
        ClearLastError();
        if TryFormatPicture(D, Picture, Txt) then
            exit('[' + Txt + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Std(D: Date; N: Integer): Text
    var
        Txt: Text;
    begin
        ClearLastError();
        if TryFormatStd(D, N, Txt) then
            exit('[' + Txt + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // Month m: <Month Text> and <Month Text,3> of the 15th of that month in 2024.
    local procedure Months(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Results: List of [Text];
        D: Date;
        M: Integer;
    begin
        GlobalLanguage(Lang);
        for M := 1 to 12 do begin
            D := DMY2Date(15, M, 2024);
            Results.Add(Pic(D, '<Month Text>') + Pic(D, '<Month Text,3>'));
        end;
        GlobalLanguage(1033);
        for M := 1 to 12 do
            Observer.Observe('month ' + Format(M), Results.Get(M));
    end;

    // Weekday n (1 = Monday): <Weekday Text>, <Weekday Text,2> and <Weekday Text,3> of 11 to 17 March 2024; then other lengths,
    // a day-month-year picture and standard format 4.
    local procedure Weekdays(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Names: List of [Text];
        Results: List of [Text];
        D: Date;
        Mar15: Date;
        Aug6: Date;
        Sep2: Date;
        I: Integer;
    begin
        Mar15 := DMY2Date(15, 3, 2024);
        Aug6 := DMY2Date(6, 8, 2024);
        Sep2 := DMY2Date(2, 9, 2024);
        GlobalLanguage(Lang);
        for I := 0 to 6 do begin
            D := DMY2Date(11 + I, 3, 2024);
            Names.Add('weekday ' + Format(Date2DWY(D, 1)));
            Results.Add(Pic(D, '<Weekday Text>') + Pic(D, '<Weekday Text,2>') + Pic(D, '<Weekday Text,3>'));
        end;
        Names.Add('Sep 2: Month Text 1, 2, 4, 20');
        Results.Add(Pic(Sep2, '<Month Text,1>') + Pic(Sep2, '<Month Text,2>') + Pic(Sep2, '<Month Text,4>') + Pic(Sep2, '<Month Text,20>'));
        Names.Add('Sep 2: Weekday Text 1, 4, 20');
        Results.Add(Pic(Sep2, '<Weekday Text,1>') + Pic(Sep2, '<Weekday Text,4>') + Pic(Sep2, '<Weekday Text,20>'));
        Names.Add('<Day,2>. <Month Text> <Year4>');
        Results.Add(Pic(Mar15, '<Day,2>. <Month Text> <Year4>') + Pic(Aug6, '<Day,2>. <Month Text> <Year4>'));
        Names.Add('<Weekday Text>, <Day>. <Month Text,3>');
        Results.Add(Pic(Aug6, '<Weekday Text>, <Day>. <Month Text,3>'));
        Names.Add('std 4');
        Results.Add(Std(Mar15, 4) + Std(Aug6, 4));
        Names.Add('Format of a closing date with <Month Text>');
        Results.Add(Pic(ClosingDate(Mar15), '<Closing><Month Text>'));
        GlobalLanguage(1033);
        for I := 1 to Names.Count() do
            Observer.Observe(Names.Get(I), Results.Get(I));
    end;

    [Test]
    procedure MonthText_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Months(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure MonthText_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Months(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure MonthText_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Months(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure MonthText_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Months(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure MonthText_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Months(Observer, 1044);
        Observer.Finish();
    end;

    [Test]
    procedure MonthText_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Months(Observer, 1053);
        Observer.Finish();
    end;

    [Test]
    procedure WeekdayText_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Weekdays(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure WeekdayText_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Weekdays(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure WeekdayText_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Weekdays(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure WeekdayText_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Weekdays(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure WeekdayText_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Weekdays(Observer, 1044);
        Observer.Finish();
    end;

    [Test]
    procedure WeekdayText_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Weekdays(Observer, 1053);
        Observer.Finish();
    end;
}
