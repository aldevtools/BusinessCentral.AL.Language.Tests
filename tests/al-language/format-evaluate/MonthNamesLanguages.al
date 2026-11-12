// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: month names of the standard formats 4 and 7 under GlobalLanguage for languages that format-evaluate/AxLanguageFormats.al
//   (1033, 1031, 1036, 3082) and EvalLanguageBoolean.al (December only, 1030, 1043, 2067) do not cover.
// Facts: Format(DMY2Date(5, m, 2026), 0, 4) and Format(DMY2Date(5, m, 2026), 0, 7) for every month 1 to 12, and both formats for
//   15 March 2026, with GlobalLanguage set to 2067, 1043, 1030, 2060, 1044, 1053, 1035, 2055, 3079 and 4108; whether setting the
//   language raises an error. Each test sets GlobalLanguage back before it records its values. The full text is asserted.
// BC versions: 27 - 29

codeunit 76404 "LT Month Names Languages"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetLanguage(Language: Integer)
    begin
        GlobalLanguage(Language);
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Language: Integer)
    var
        Saved: Integer;
        F4: List of [Text];
        F7: List of [Text];
        D15F4: Text;
        D15F7: Text;
        Ok: Boolean;
        ErrorText: Text;
        M: Integer;
    begin
        Saved := GlobalLanguage();
        ClearLastError();
        Ok := TrySetLanguage(Language);
        if Ok then begin
            for M := 1 to 12 do begin
                F4.Add(Format(DMY2Date(5, M, 2026), 0, 4));
                F7.Add(Format(DMY2Date(5, M, 2026), 0, 7));
            end;
            D15F4 := Format(DMY2Date(15, 3, 2026), 0, 4);
            D15F7 := Format(DMY2Date(15, 3, 2026), 0, 7);
        end else
            ErrorText := GetLastErrorText();
        GlobalLanguage(Saved);
        ClearLastError();
        Observer.Observe('set language ok', Format(Ok));
        if not Ok then begin
            Observer.Observe('set language error', ErrorText);
            exit;
        end;
        for M := 1 to 12 do
            Observer.Observe('f4 m' + Format(M), F4.Get(M));
        for M := 1 to 12 do
            Observer.Observe('f7 m' + Format(M), F7.Get(M));
        Observer.Observe('f4 15 March', D15F4);
        Observer.Observe('f7 15 March', D15F7);
        Observer.Observe('language restored', Format(GlobalLanguage() = Saved));
    end;

    [Test]
    procedure Months_Dutch_Belgium_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2067);
        Observer.Expect('set language ok', 'Yes');
        Observer.Expect('f4 m1', 'januari 5, 2026');
        Observer.Expect('f4 m2', 'februari 5, 2026');
        Observer.Expect('f4 m3', 'maart 5, 2026');
        Observer.Expect('f4 m4', 'april 5, 2026');
        Observer.Expect('f4 m5', 'mei 5, 2026');
        Observer.Expect('f4 m6', 'juni 5, 2026');
        Observer.Expect('f4 m7', 'juli 5, 2026');
        Observer.Expect('f4 m8', 'augustus 5, 2026');
        Observer.Expect('f4 m9', 'september 5, 2026');
        Observer.Expect('f4 m10', 'oktober 5, 2026');
        Observer.Expect('f4 m11', 'november 5, 2026');
        Observer.Expect('f4 m12', 'december 5, 2026');
        Observer.Expect('f7 m1', 'jan 5, 2026');
        Observer.Expect('f7 m2', 'feb 5, 2026');
        Observer.Expect('f7 m3', 'mrt 5, 2026');
        Observer.Expect('f7 m4', 'apr 5, 2026');
        Observer.Expect('f7 m5', 'mei 5, 2026');
        Observer.Expect('f7 m6', 'jun 5, 2026');
        Observer.Expect('f7 m7', 'jul 5, 2026');
        Observer.Expect('f7 m8', 'aug 5, 2026');
        Observer.Expect('f7 m9', 'sep 5, 2026');
        Observer.Expect('f7 m10', 'okt 5, 2026');
        Observer.Expect('f7 m11', 'nov 5, 2026');
        Observer.Expect('f7 m12', 'dec 5, 2026');
        Observer.Expect('f4 15 March', 'maart 15, 2026');
        Observer.Expect('f7 15 March', 'mrt 15, 2026');
        Observer.Expect('language restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Months_Dutch_1043()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1043);
        Observer.Expect('set language ok', 'Yes');
        Observer.Expect('f4 m1', 'januari 5, 2026');
        Observer.Expect('f4 m2', 'februari 5, 2026');
        Observer.Expect('f4 m3', 'maart 5, 2026');
        Observer.Expect('f4 m4', 'april 5, 2026');
        Observer.Expect('f4 m5', 'mei 5, 2026');
        Observer.Expect('f4 m6', 'juni 5, 2026');
        Observer.Expect('f4 m7', 'juli 5, 2026');
        Observer.Expect('f4 m8', 'augustus 5, 2026');
        Observer.Expect('f4 m9', 'september 5, 2026');
        Observer.Expect('f4 m10', 'oktober 5, 2026');
        Observer.Expect('f4 m11', 'november 5, 2026');
        Observer.Expect('f4 m12', 'december 5, 2026');
        Observer.Expect('f7 m1', 'jan 5, 2026');
        Observer.Expect('f7 m2', 'feb 5, 2026');
        Observer.Expect('f7 m3', 'mrt 5, 2026');
        Observer.Expect('f7 m4', 'apr 5, 2026');
        Observer.Expect('f7 m5', 'mei 5, 2026');
        Observer.Expect('f7 m6', 'jun 5, 2026');
        Observer.Expect('f7 m7', 'jul 5, 2026');
        Observer.Expect('f7 m8', 'aug 5, 2026');
        Observer.Expect('f7 m9', 'sep 5, 2026');
        Observer.Expect('f7 m10', 'okt 5, 2026');
        Observer.Expect('f7 m11', 'nov 5, 2026');
        Observer.Expect('f7 m12', 'dec 5, 2026');
        Observer.Expect('f4 15 March', 'maart 15, 2026');
        Observer.Expect('f7 15 March', 'mrt 15, 2026');
        Observer.Expect('language restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Months_Danish_1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1030);
        Observer.Expect('set language ok', 'Yes');
        Observer.Expect('f4 m1', 'januar 5, 2026');
        Observer.Expect('f4 m2', 'februar 5, 2026');
        Observer.Expect('f4 m3', 'marts 5, 2026');
        Observer.Expect('f4 m4', 'april 5, 2026');
        Observer.Expect('f4 m5', 'maj 5, 2026');
        Observer.Expect('f4 m6', 'juni 5, 2026');
        Observer.Expect('f4 m7', 'juli 5, 2026');
        Observer.Expect('f4 m8', 'august 5, 2026');
        Observer.Expect('f4 m9', 'september 5, 2026');
        Observer.Expect('f4 m10', 'oktober 5, 2026');
        Observer.Expect('f4 m11', 'november 5, 2026');
        Observer.Expect('f4 m12', 'december 5, 2026');
        Observer.Expect('f7 m1', 'jan 5, 2026');
        Observer.Expect('f7 m2', 'feb 5, 2026');
        Observer.Expect('f7 m3', 'mar 5, 2026');
        Observer.Expect('f7 m4', 'apr 5, 2026');
        Observer.Expect('f7 m5', 'maj 5, 2026');
        Observer.Expect('f7 m6', 'jun 5, 2026');
        Observer.Expect('f7 m7', 'jul 5, 2026');
        Observer.Expect('f7 m8', 'aug 5, 2026');
        Observer.Expect('f7 m9', 'sep 5, 2026');
        Observer.Expect('f7 m10', 'okt 5, 2026');
        Observer.Expect('f7 m11', 'nov 5, 2026');
        Observer.Expect('f7 m12', 'dec 5, 2026');
        Observer.Expect('f4 15 March', 'marts 15, 2026');
        Observer.Expect('f7 15 March', 'mar 15, 2026');
        Observer.Expect('language restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Months_French_Belgium_2060()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2060);
        Observer.Expect('set language ok', 'Yes');
        Observer.Expect('f4 m1', 'janvier 5, 2026');
        Observer.Expect('f4 m2', 'février 5, 2026');
        Observer.Expect('f4 m3', 'mars 5, 2026');
        Observer.Expect('f4 m4', 'avril 5, 2026');
        Observer.Expect('f4 m5', 'mai 5, 2026');
        Observer.Expect('f4 m6', 'juin 5, 2026');
        Observer.Expect('f4 m7', 'juillet 5, 2026');
        Observer.Expect('f4 m8', 'août 5, 2026');
        Observer.Expect('f4 m9', 'septembre 5, 2026');
        Observer.Expect('f4 m10', 'octobre 5, 2026');
        Observer.Expect('f4 m11', 'novembre 5, 2026');
        Observer.Expect('f4 m12', 'décembre 5, 2026');
        Observer.Expect('f7 m1', 'janv. 5, 2026');
        Observer.Expect('f7 m2', 'févr. 5, 2026');
        Observer.Expect('f7 m3', 'mars 5, 2026');
        Observer.Expect('f7 m4', 'avr. 5, 2026');
        Observer.Expect('f7 m5', 'mai 5, 2026');
        Observer.Expect('f7 m6', 'juin 5, 2026');
        Observer.Expect('f7 m7', 'juil. 5, 2026');
        Observer.Expect('f7 m8', 'août 5, 2026');
        Observer.Expect('f7 m9', 'sept. 5, 2026');
        Observer.Expect('f7 m10', 'oct. 5, 2026');
        Observer.Expect('f7 m11', 'nov. 5, 2026');
        Observer.Expect('f7 m12', 'déc. 5, 2026');
        Observer.Expect('f4 15 March', 'mars 15, 2026');
        Observer.Expect('f7 15 March', 'mars 15, 2026');
        Observer.Expect('language restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Months_Norwegian_1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1044);
        Observer.Expect('set language ok', 'Yes');
        Observer.Expect('f4 m1', 'januar 5, 2026');
        Observer.Expect('f4 m2', 'februar 5, 2026');
        Observer.Expect('f4 m3', 'mars 5, 2026');
        Observer.Expect('f4 m4', 'april 5, 2026');
        Observer.Expect('f4 m5', 'mai 5, 2026');
        Observer.Expect('f4 m6', 'juni 5, 2026');
        Observer.Expect('f4 m7', 'juli 5, 2026');
        Observer.Expect('f4 m8', 'august 5, 2026');
        Observer.Expect('f4 m9', 'september 5, 2026');
        Observer.Expect('f4 m10', 'oktober 5, 2026');
        Observer.Expect('f4 m11', 'november 5, 2026');
        Observer.Expect('f4 m12', 'desember 5, 2026');
        Observer.Expect('f7 m1', 'jan. 5, 2026');
        Observer.Expect('f7 m2', 'feb. 5, 2026');
        Observer.Expect('f7 m3', 'mar. 5, 2026');
        Observer.Expect('f7 m4', 'apr. 5, 2026');
        Observer.Expect('f7 m5', 'mai 5, 2026');
        Observer.Expect('f7 m6', 'jun. 5, 2026');
        Observer.Expect('f7 m7', 'jul. 5, 2026');
        Observer.Expect('f7 m8', 'aug. 5, 2026');
        Observer.Expect('f7 m9', 'sep. 5, 2026');
        Observer.Expect('f7 m10', 'okt. 5, 2026');
        Observer.Expect('f7 m11', 'nov. 5, 2026');
        Observer.Expect('f7 m12', 'des. 5, 2026');
        Observer.Expect('f4 15 March', 'mars 15, 2026');
        Observer.Expect('f7 15 March', 'mar. 15, 2026');
        Observer.Expect('language restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Months_Swedish_1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1053);
        Observer.Expect('set language ok', 'Yes');
        Observer.Expect('f4 m1', 'januari 5, 2026');
        Observer.Expect('f4 m2', 'februari 5, 2026');
        Observer.Expect('f4 m3', 'mars 5, 2026');
        Observer.Expect('f4 m4', 'april 5, 2026');
        Observer.Expect('f4 m5', 'maj 5, 2026');
        Observer.Expect('f4 m6', 'juni 5, 2026');
        Observer.Expect('f4 m7', 'juli 5, 2026');
        Observer.Expect('f4 m8', 'augusti 5, 2026');
        Observer.Expect('f4 m9', 'september 5, 2026');
        Observer.Expect('f4 m10', 'oktober 5, 2026');
        Observer.Expect('f4 m11', 'november 5, 2026');
        Observer.Expect('f4 m12', 'december 5, 2026');
        Observer.Expect('f7 m1', 'jan 5, 2026');
        Observer.Expect('f7 m2', 'feb 5, 2026');
        Observer.Expect('f7 m3', 'mar 5, 2026');
        Observer.Expect('f7 m4', 'apr 5, 2026');
        Observer.Expect('f7 m5', 'maj 5, 2026');
        Observer.Expect('f7 m6', 'jun 5, 2026');
        Observer.Expect('f7 m7', 'jul 5, 2026');
        Observer.Expect('f7 m8', 'aug 5, 2026');
        Observer.Expect('f7 m9', 'sep 5, 2026');
        Observer.Expect('f7 m10', 'okt 5, 2026');
        Observer.Expect('f7 m11', 'nov 5, 2026');
        Observer.Expect('f7 m12', 'dec 5, 2026');
        Observer.Expect('f4 15 March', 'mars 15, 2026');
        Observer.Expect('f7 15 March', 'mar 15, 2026');
        Observer.Expect('language restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Months_Finnish_1035()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1035);
        Observer.Expect('set language ok', 'Yes');
        Observer.Expect('f4 m1', 'tammikuuta 5, 2026');
        Observer.Expect('f4 m2', 'helmikuuta 5, 2026');
        Observer.Expect('f4 m3', 'maaliskuuta 5, 2026');
        Observer.Expect('f4 m4', 'huhtikuuta 5, 2026');
        Observer.Expect('f4 m5', 'toukokuuta 5, 2026');
        Observer.Expect('f4 m6', 'kesäkuuta 5, 2026');
        Observer.Expect('f4 m7', 'heinäkuuta 5, 2026');
        Observer.Expect('f4 m8', 'elokuuta 5, 2026');
        Observer.Expect('f4 m9', 'syyskuuta 5, 2026');
        Observer.Expect('f4 m10', 'lokakuuta 5, 2026');
        Observer.Expect('f4 m11', 'marraskuuta 5, 2026');
        Observer.Expect('f4 m12', 'joulukuuta 5, 2026');
        Observer.Expect('f7 m1', 'tammik. 5, 2026');
        Observer.Expect('f7 m2', 'helmik. 5, 2026');
        Observer.Expect('f7 m3', 'maalisk. 5, 2026');
        Observer.Expect('f7 m4', 'huhtik. 5, 2026');
        Observer.Expect('f7 m5', 'toukok. 5, 2026');
        Observer.Expect('f7 m6', 'kesäk. 5, 2026');
        Observer.Expect('f7 m7', 'heinäk. 5, 2026');
        Observer.Expect('f7 m8', 'elok. 5, 2026');
        Observer.Expect('f7 m9', 'syysk. 5, 2026');
        Observer.Expect('f7 m10', 'lokak. 5, 2026');
        Observer.Expect('f7 m11', 'marrask. 5, 2026');
        Observer.Expect('f7 m12', 'jouluk. 5, 2026');
        Observer.Expect('f4 15 March', 'maaliskuuta 15, 2026');
        Observer.Expect('f7 15 March', 'maalisk. 15, 2026');
        Observer.Expect('language restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Months_German_Switzerland_2055()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2055);
        Observer.Expect('set language ok', 'Yes');
        Observer.Expect('f4 m1', 'Januar 5, 2026');
        Observer.Expect('f4 m2', 'Februar 5, 2026');
        Observer.Expect('f4 m3', 'März 5, 2026');
        Observer.Expect('f4 m4', 'April 5, 2026');
        Observer.Expect('f4 m5', 'Mai 5, 2026');
        Observer.Expect('f4 m6', 'Juni 5, 2026');
        Observer.Expect('f4 m7', 'Juli 5, 2026');
        Observer.Expect('f4 m8', 'August 5, 2026');
        Observer.Expect('f4 m9', 'September 5, 2026');
        Observer.Expect('f4 m10', 'Oktober 5, 2026');
        Observer.Expect('f4 m11', 'November 5, 2026');
        Observer.Expect('f4 m12', 'Dezember 5, 2026');
        Observer.Expect('f7 m1', 'Jan. 5, 2026');
        Observer.Expect('f7 m2', 'Feb. 5, 2026');
        Observer.Expect('f7 m3', 'März 5, 2026');
        Observer.Expect('f7 m4', 'Apr. 5, 2026');
        Observer.Expect('f7 m5', 'Mai 5, 2026');
        Observer.Expect('f7 m6', 'Juni 5, 2026');
        Observer.Expect('f7 m7', 'Juli 5, 2026');
        Observer.Expect('f7 m8', 'Aug. 5, 2026');
        Observer.Expect('f7 m9', 'Sept. 5, 2026');
        Observer.Expect('f7 m10', 'Okt. 5, 2026');
        Observer.Expect('f7 m11', 'Nov. 5, 2026');
        Observer.Expect('f7 m12', 'Dez. 5, 2026');
        Observer.Expect('f4 15 March', 'März 15, 2026');
        Observer.Expect('f7 15 March', 'März 15, 2026');
        Observer.Expect('language restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Months_German_Austria_3079()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3079);
        Observer.Expect('set language ok', 'Yes');
        Observer.Expect('f4 m1', 'Jänner 5, 2026');
        Observer.Expect('f4 m2', 'Februar 5, 2026');
        Observer.Expect('f4 m3', 'März 5, 2026');
        Observer.Expect('f4 m4', 'April 5, 2026');
        Observer.Expect('f4 m5', 'Mai 5, 2026');
        Observer.Expect('f4 m6', 'Juni 5, 2026');
        Observer.Expect('f4 m7', 'Juli 5, 2026');
        Observer.Expect('f4 m8', 'August 5, 2026');
        Observer.Expect('f4 m9', 'September 5, 2026');
        Observer.Expect('f4 m10', 'Oktober 5, 2026');
        Observer.Expect('f4 m11', 'November 5, 2026');
        Observer.Expect('f4 m12', 'Dezember 5, 2026');
        Observer.Expect('f7 m1', 'Jän. 5, 2026');
        Observer.Expect('f7 m2', 'Feb. 5, 2026');
        Observer.Expect('f7 m3', 'März 5, 2026');
        Observer.Expect('f7 m4', 'Apr. 5, 2026');
        Observer.Expect('f7 m5', 'Mai 5, 2026');
        Observer.Expect('f7 m6', 'Juni 5, 2026');
        Observer.Expect('f7 m7', 'Juli 5, 2026');
        Observer.Expect('f7 m8', 'Aug. 5, 2026');
        Observer.Expect('f7 m9', 'Sep. 5, 2026');
        Observer.Expect('f7 m10', 'Okt. 5, 2026');
        Observer.Expect('f7 m11', 'Nov. 5, 2026');
        Observer.Expect('f7 m12', 'Dez. 5, 2026');
        Observer.Expect('f4 15 March', 'März 15, 2026');
        Observer.Expect('f7 15 March', 'März 15, 2026');
        Observer.Expect('language restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Months_French_Switzerland_4108()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4108);
        Observer.Expect('set language ok', 'Yes');
        Observer.Expect('f4 m1', 'janvier 5, 2026');
        Observer.Expect('f4 m2', 'février 5, 2026');
        Observer.Expect('f4 m3', 'mars 5, 2026');
        Observer.Expect('f4 m4', 'avril 5, 2026');
        Observer.Expect('f4 m5', 'mai 5, 2026');
        Observer.Expect('f4 m6', 'juin 5, 2026');
        Observer.Expect('f4 m7', 'juillet 5, 2026');
        Observer.Expect('f4 m8', 'août 5, 2026');
        Observer.Expect('f4 m9', 'septembre 5, 2026');
        Observer.Expect('f4 m10', 'octobre 5, 2026');
        Observer.Expect('f4 m11', 'novembre 5, 2026');
        Observer.Expect('f4 m12', 'décembre 5, 2026');
        Observer.Expect('f7 m1', 'janv. 5, 2026');
        Observer.Expect('f7 m2', 'févr. 5, 2026');
        Observer.Expect('f7 m3', 'mars 5, 2026');
        Observer.Expect('f7 m4', 'avr. 5, 2026');
        Observer.Expect('f7 m5', 'mai 5, 2026');
        Observer.Expect('f7 m6', 'juin 5, 2026');
        Observer.Expect('f7 m7', 'juil. 5, 2026');
        Observer.Expect('f7 m8', 'août 5, 2026');
        Observer.Expect('f7 m9', 'sept. 5, 2026');
        Observer.Expect('f7 m10', 'oct. 5, 2026');
        Observer.Expect('f7 m11', 'nov. 5, 2026');
        Observer.Expect('f7 m12', 'déc. 5, 2026');
        Observer.Expect('f4 15 March', 'mars 15, 2026');
        Observer.Expect('f7 15 March', 'mars 15, 2026');
        Observer.Expect('language restored', 'Yes');
        Observer.Verify();
    end;
}
