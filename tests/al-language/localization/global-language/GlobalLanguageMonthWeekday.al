// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope. Format(Date, 0, picture) with <Month Text> and <Weekday Text> (with and without a length) and standard format 4, under GlobalLanguage 1033, 1030, 1031, 1036, 1044 and 1053.
// Fixtures used: Probe Observer (codeunit 69160); own objects 75402 (LT GL Month Weekday)
// Probe: from al-runner issues 8178, 8182, 8183, 8197, 8199 and 8200 (an outside reporter measured BC 28.4 W1, en-US region). Observed on
//   Windows BC containers 27.5, 28.5 and 29.0; every literal asserted below is what BC produced. The corpus CI matrix checks it on BC on Linux.
// Facts (identical on 27.5, 28.5 and 29.0):
//   - <Month Text> and <Weekday Text> give the names of the GlobalLanguage (French juin and juillet both abbreviate to jui).
//     <Month Text,3> and <Weekday Text,3> cut the name; <...,2> of a weekday gives the two-letter form.
//   - A length shorter than the name cuts it; a length longer than the name pads it on the right with spaces.
//   - Std 4 keeps the en-US order (<Month Text> <Day>, <Year4>) and only translates the month name.
//   - A picture with <Month Text> on a closing date puts the closing letter of the language in front (CMarch, Umarts, Smars).
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
        Observer.Expect('month 1', '[January][Jan]');
        Observer.Expect('month 2', '[February][Feb]');
        Observer.Expect('month 3', '[March][Mar]');
        Observer.Expect('month 4', '[April][Apr]');
        Observer.Expect('month 5', '[May][May]');
        Observer.Expect('month 6', '[June][Jun]');
        Observer.Expect('month 7', '[July][Jul]');
        Observer.Expect('month 8', '[August][Aug]');
        Observer.Expect('month 9', '[September][Sep]');
        Observer.Expect('month 10', '[October][Oct]');
        Observer.Expect('month 11', '[November][Nov]');
        Observer.Expect('month 12', '[December][Dec]');
        Observer.Verify();
    end;

    [Test]
    procedure MonthText_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Months(Observer, 1030);
        Observer.Expect('month 1', '[januar][jan]');
        Observer.Expect('month 2', '[februar][feb]');
        Observer.Expect('month 3', '[marts][mar]');
        Observer.Expect('month 4', '[april][apr]');
        Observer.Expect('month 5', '[maj][maj]');
        Observer.Expect('month 6', '[juni][jun]');
        Observer.Expect('month 7', '[juli][jul]');
        Observer.Expect('month 8', '[august][aug]');
        Observer.Expect('month 9', '[september][sep]');
        Observer.Expect('month 10', '[oktober][okt]');
        Observer.Expect('month 11', '[november][nov]');
        Observer.Expect('month 12', '[december][dec]');
        Observer.Verify();
    end;

    [Test]
    procedure MonthText_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Months(Observer, 1031);
        Observer.Expect('month 1', '[Januar][Jan]');
        Observer.Expect('month 2', '[Februar][Feb]');
        Observer.Expect('month 3', '[März][Mär]');
        Observer.Expect('month 4', '[April][Apr]');
        Observer.Expect('month 5', '[Mai][Mai]');
        Observer.Expect('month 6', '[Juni][Jun]');
        Observer.Expect('month 7', '[Juli][Jul]');
        Observer.Expect('month 8', '[August][Aug]');
        Observer.Expect('month 9', '[September][Sep]');
        Observer.Expect('month 10', '[Oktober][Okt]');
        Observer.Expect('month 11', '[November][Nov]');
        Observer.Expect('month 12', '[Dezember][Dez]');
        Observer.Verify();
    end;

    [Test]
    procedure MonthText_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Months(Observer, 1036);
        Observer.Expect('month 1', '[janvier][jan]');
        Observer.Expect('month 2', '[février][fév]');
        Observer.Expect('month 3', '[mars][mar]');
        Observer.Expect('month 4', '[avril][avr]');
        Observer.Expect('month 5', '[mai][mai]');
        Observer.Expect('month 6', '[juin][jui]');
        Observer.Expect('month 7', '[juillet][jui]');
        Observer.Expect('month 8', '[août][aoû]');
        Observer.Expect('month 9', '[septembre][sep]');
        Observer.Expect('month 10', '[octobre][oct]');
        Observer.Expect('month 11', '[novembre][nov]');
        Observer.Expect('month 12', '[décembre][déc]');
        Observer.Verify();
    end;

    [Test]
    procedure MonthText_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Months(Observer, 1044);
        Observer.Expect('month 1', '[januar][jan]');
        Observer.Expect('month 2', '[februar][feb]');
        Observer.Expect('month 3', '[mars][mar]');
        Observer.Expect('month 4', '[april][apr]');
        Observer.Expect('month 5', '[mai][mai]');
        Observer.Expect('month 6', '[juni][jun]');
        Observer.Expect('month 7', '[juli][jul]');
        Observer.Expect('month 8', '[august][aug]');
        Observer.Expect('month 9', '[september][sep]');
        Observer.Expect('month 10', '[oktober][okt]');
        Observer.Expect('month 11', '[november][nov]');
        Observer.Expect('month 12', '[desember][des]');
        Observer.Verify();
    end;

    [Test]
    procedure MonthText_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Months(Observer, 1053);
        Observer.Expect('month 1', '[januari][jan]');
        Observer.Expect('month 2', '[februari][feb]');
        Observer.Expect('month 3', '[mars][mar]');
        Observer.Expect('month 4', '[april][apr]');
        Observer.Expect('month 5', '[maj][maj]');
        Observer.Expect('month 6', '[juni][jun]');
        Observer.Expect('month 7', '[juli][jul]');
        Observer.Expect('month 8', '[augusti][aug]');
        Observer.Expect('month 9', '[september][sep]');
        Observer.Expect('month 10', '[oktober][okt]');
        Observer.Expect('month 11', '[november][nov]');
        Observer.Expect('month 12', '[december][dec]');
        Observer.Verify();
    end;

    [Test]
    procedure WeekdayText_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Weekdays(Observer, 1033);
        Observer.Expect('weekday 1', '[Monday][Mo][Mon]');
        Observer.Expect('weekday 2', '[Tuesday][Tu][Tue]');
        Observer.Expect('weekday 3', '[Wednesday][We][Wed]');
        Observer.Expect('weekday 4', '[Thursday][Th][Thu]');
        Observer.Expect('weekday 5', '[Friday][Fr][Fri]');
        Observer.Expect('weekday 6', '[Saturday][Sa][Sat]');
        Observer.Expect('weekday 7', '[Sunday][Su][Sun]');
        Observer.Expect('Sep 2: Month Text 1, 2, 4, 20', '[S][Se][Sept][September           ]');
        Observer.Expect('Sep 2: Weekday Text 1, 4, 20', '[M][Mond][Monday              ]');
        Observer.Expect('<Day,2>. <Month Text> <Year4>', '[15. March 2024][06. August 2024]');
        Observer.Expect('<Weekday Text>, <Day>. <Month Text,3>', '[Tuesday, 6. Aug]');
        Observer.Expect('std 4', '[March 15, 2024][August 6, 2024]');
        Observer.Expect('Format of a closing date with <Month Text>', '[CMarch]');
        Observer.Verify();
    end;

    [Test]
    procedure WeekdayText_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Weekdays(Observer, 1030);
        Observer.Expect('weekday 1', '[mandag][ma][man]');
        Observer.Expect('weekday 2', '[tirsdag][ti][tir]');
        Observer.Expect('weekday 3', '[onsdag][on][ons]');
        Observer.Expect('weekday 4', '[torsdag][to][tor]');
        Observer.Expect('weekday 5', '[fredag][fr][fre]');
        Observer.Expect('weekday 6', '[lørdag][lø][lør]');
        Observer.Expect('weekday 7', '[søndag][sø][søn]');
        Observer.Expect('Sep 2: Month Text 1, 2, 4, 20', '[s][se][sept][september           ]');
        Observer.Expect('Sep 2: Weekday Text 1, 4, 20', '[m][mand][mandag              ]');
        Observer.Expect('<Day,2>. <Month Text> <Year4>', '[15. marts 2024][06. august 2024]');
        Observer.Expect('<Weekday Text>, <Day>. <Month Text,3>', '[tirsdag, 6. aug]');
        Observer.Expect('std 4', '[marts 15, 2024][august 6, 2024]');
        Observer.Expect('Format of a closing date with <Month Text>', '[Umarts]');
        Observer.Verify();
    end;

    [Test]
    procedure WeekdayText_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Weekdays(Observer, 1031);
        Observer.Expect('weekday 1', '[Montag][Mo][Mon]');
        Observer.Expect('weekday 2', '[Dienstag][Di][Die]');
        Observer.Expect('weekday 3', '[Mittwoch][Mi][Mit]');
        Observer.Expect('weekday 4', '[Donnerstag][Do][Don]');
        Observer.Expect('weekday 5', '[Freitag][Fr][Fre]');
        Observer.Expect('weekday 6', '[Samstag][Sa][Sam]');
        Observer.Expect('weekday 7', '[Sonntag][So][Son]');
        Observer.Expect('Sep 2: Month Text 1, 2, 4, 20', '[S][Se][Sept][September           ]');
        Observer.Expect('Sep 2: Weekday Text 1, 4, 20', '[M][Mont][Montag              ]');
        Observer.Expect('<Day,2>. <Month Text> <Year4>', '[15. März 2024][06. August 2024]');
        Observer.Expect('<Weekday Text>, <Day>. <Month Text,3>', '[Dienstag, 6. Aug]');
        Observer.Expect('std 4', '[März 15, 2024][August 6, 2024]');
        Observer.Expect('Format of a closing date with <Month Text>', '[UMärz]');
        Observer.Verify();
    end;

    [Test]
    procedure WeekdayText_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Weekdays(Observer, 1036);
        Observer.Expect('weekday 1', '[lundi][lu][lun]');
        Observer.Expect('weekday 2', '[mardi][ma][mar]');
        Observer.Expect('weekday 3', '[mercredi][me][mer]');
        Observer.Expect('weekday 4', '[jeudi][je][jeu]');
        Observer.Expect('weekday 5', '[vendredi][ve][ven]');
        Observer.Expect('weekday 6', '[samedi][sa][sam]');
        Observer.Expect('weekday 7', '[dimanche][di][dim]');
        Observer.Expect('Sep 2: Month Text 1, 2, 4, 20', '[s][se][sept][septembre           ]');
        Observer.Expect('Sep 2: Weekday Text 1, 4, 20', '[l][lund][lundi               ]');
        Observer.Expect('<Day,2>. <Month Text> <Year4>', '[15. mars 2024][06. août 2024]');
        Observer.Expect('<Weekday Text>, <Day>. <Month Text,3>', '[mardi, 6. aoû]');
        Observer.Expect('std 4', '[mars 15, 2024][août 6, 2024]');
        Observer.Expect('Format of a closing date with <Month Text>', '[Cmars]');
        Observer.Verify();
    end;

    [Test]
    procedure WeekdayText_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Weekdays(Observer, 1044);
        Observer.Expect('weekday 1', '[mandag][ma][man]');
        Observer.Expect('weekday 2', '[tirsdag][ti][tir]');
        Observer.Expect('weekday 3', '[onsdag][on][ons]');
        Observer.Expect('weekday 4', '[torsdag][to][tor]');
        Observer.Expect('weekday 5', '[fredag][fr][fre]');
        Observer.Expect('weekday 6', '[lørdag][lø][lør]');
        Observer.Expect('weekday 7', '[søndag][sø][søn]');
        Observer.Expect('Sep 2: Month Text 1, 2, 4, 20', '[s][se][sept][september           ]');
        Observer.Expect('Sep 2: Weekday Text 1, 4, 20', '[m][mand][mandag              ]');
        Observer.Expect('<Day,2>. <Month Text> <Year4>', '[15. mars 2024][06. august 2024]');
        Observer.Expect('<Weekday Text>, <Day>. <Month Text,3>', '[tirsdag, 6. aug]');
        Observer.Expect('std 4', '[mars 15, 2024][august 6, 2024]');
        Observer.Expect('Format of a closing date with <Month Text>', '[Umars]');
        Observer.Verify();
    end;

    [Test]
    procedure WeekdayText_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Weekdays(Observer, 1053);
        Observer.Expect('weekday 1', '[måndag][må][mån]');
        Observer.Expect('weekday 2', '[tisdag][ti][tis]');
        Observer.Expect('weekday 3', '[onsdag][on][ons]');
        Observer.Expect('weekday 4', '[torsdag][to][tor]');
        Observer.Expect('weekday 5', '[fredag][fr][fre]');
        Observer.Expect('weekday 6', '[lördag][lö][lör]');
        Observer.Expect('weekday 7', '[söndag][sö][sön]');
        Observer.Expect('Sep 2: Month Text 1, 2, 4, 20', '[s][se][sept][september           ]');
        Observer.Expect('Sep 2: Weekday Text 1, 4, 20', '[m][månd][måndag              ]');
        Observer.Expect('<Day,2>. <Month Text> <Year4>', '[15. mars 2024][06. augusti 2024]');
        Observer.Expect('<Weekday Text>, <Day>. <Month Text,3>', '[tisdag, 6. aug]');
        Observer.Expect('std 4', '[mars 15, 2024][augusti 6, 2024]');
        Observer.Expect('Format of a closing date with <Month Text>', '[Smars]');
        Observer.Verify();
    end;
}
