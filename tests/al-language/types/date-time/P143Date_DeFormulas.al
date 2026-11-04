// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: table 74647 and codeunit 74648 (P143Fixtures.al), codeunit 69160 "Probe Observer"
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74657 "LT P143 DeFormulas"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P143_DeFormulas()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P143 Helper";
        OldLanguage: Integer;
    begin
        Helper.Seed();
        OldLanguage := GlobalLanguage();
        GlobalLanguage(1031);
        Run(Observer, Helper);
        GlobalLanguage(OldLanguage);
        Observer.Observe('language_restored', Format(GlobalLanguage() = OldLanguage));
        Observer.Expect('CD_err|text', 'Der Filter ''CD'' ist für das Feld ''D'' der Tabelle ''LT P143 Row'' nicht gültig. Das Format Date „CD“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.');
        Observer.Expect('CD_err|code', 'Filter:CSide');
        Observer.Expect('T_count_eq_on_expected', 'Ja');
        Observer.Expect('T_filter_is_text', 'Nein');
        Observer.Expect('T_filter_is_expected_date', 'Ja');
        Observer.Expect('W_count_eq_on_expected', 'Ja');
        Observer.Expect('W_filter_is_text', 'Nein');
        Observer.Expect('W_filter_is_expected_date', 'Ja');
        Observer.Expect('lower_CD_err|text', 'Der Filter ''cd'' ist für das Feld ''D'' der Tabelle ''LT P143 Row'' nicht gültig. Das Format Date „cd“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.');
        Observer.Expect('lower_CD_err|code', 'Filter:CSide');
        Observer.Expect('lower_T_count_eq_on_expected', 'Ja');
        Observer.Expect('lower_T_filter_is_text', 'Nein');
        Observer.Expect('lower_T_filter_is_expected_date', 'Ja');
        Observer.Expect('lower_W_count_eq_on_expected', 'Ja');
        Observer.Expect('lower_W_filter_is_text', 'Nein');
        Observer.Expect('lower_W_filter_is_expected_date', 'Ja');
        Observer.Expect('T_range_open_count_eq_on_expected', 'Nein');
        Observer.Expect('T_range_open_filter_is_text', 'Nein');
        Observer.Expect('T_range_open_filter_is_expected_date', 'Nein');
        Observer.Expect('count_all', '1');
        Observer.Expect('language_restored', 'Yes');
        Observer.Verify();
    end;

    // every statement that can raise sits inside the helper's TryFunctions, so Run cannot leave the language changed
    local procedure Run(var Observer: Codeunit "Probe Observer"; var Helper: Codeunit "LT P143 Helper")
    begin
        Helper.ProbeFormula(Observer, 'CD', 'CD', Today());
        Helper.ProbeFormula(Observer, 'T', 'T', Today());
        Helper.ProbeFormula(Observer, 'W', 'W', WorkDate());
        Helper.ProbeFormula(Observer, 'lower_CD', 'cd', Today());
        Helper.ProbeFormula(Observer, 'lower_T', 't', Today());
        Helper.ProbeFormula(Observer, 'lower_W', 'w', WorkDate());
        Helper.ProbeFormula(Observer, 'T_range_open', '..T', Today());
        Observer.Observe('count_all', Format(Helper.CountOn(0D) + 0));
    end;

    // Corpus issue 668 item 7 (writer BQ): date filter formulas with arithmetic under German and French (Canada) (microsoft/AL issue 5923).
    // The filter text is compared with the date computed in the same language, so no value depends on the run date.
    [TryFunction]
    local procedure BqTryLanguage(LanguageId: Integer)
    begin
        GlobalLanguage(LanguageId);
    end;

    // The date a formula gives, named relative to Today() (within one day, or one week, month, quarter or year back or ahead) or to the
    // work date (within a week). BqRunFormulas sets the work date to 10 January 2024 (a Wednesday), so a formula that resolves against the
    // work date (or a weekday near it) does not depend on the run date. Prefix is '..' for an open range.
    local procedure BqProbe(var Observer: Codeunit "Probe Observer"; var Helper: Codeunit "LT P143 Helper"; Name: Text; FilterText: Text; Prefix: Text)
    var
        Got: Text;
        Cnt: Integer;
        D: Date;
    begin
        if not Helper.TryDate(FilterText, Got, Cnt) then begin
            Observer.ObserveError(Name + '_err');
            exit;
        end;
        if (CopyStr(Got, 1, StrLen(Prefix)) = Prefix) and Evaluate(D, CopyStr(Got, StrLen(Prefix) + 1)) then
            Observer.Observe(Name, 'ok ' + Prefix + BqNameDate(D))
        else
            Observer.Observe(Name, 'ok not a single date');
    end;

    local procedure BqNameDate(D: Date): Text
    var
        Units: List of [Text];
        U: Text;
    begin
        if Abs(D - Today()) <= 1 then
            exit('today' + Format(D - Today()));
        Units.AddRange('W', 'M', 'Q', 'Y');
        foreach U in Units do begin
            if D = CalcDate('<-1' + U + '>', Today()) then
                exit('today-1' + U);
            if D = CalcDate('<+1' + U + '>', Today()) then
                exit('today+1' + U);
        end;
        if Abs(D - WorkDate()) <= 7 then
            exit('workdate' + Format(D - WorkDate()));
        exit('other');
    end;

    // Probes First..Last of: ..t-1d, ..t-1t, t+1d, h, a, j (a failure message keeps about 2000 characters, so the localized error texts
    // are split over two tests per language).
    local procedure BqRunFormulas(var Observer: Codeunit "Probe Observer"; var Helper: Codeunit "LT P143 Helper"; Prefix: Text; First: Integer; Last: Integer)
    var
        OldWorkDate: Date;
    begin
        OldWorkDate := WorkDate();
        WorkDate(20240110D);
        if (First <= 1) and (Last >= 1) then
            BqProbe(Observer, Helper, Prefix + '_dotdot_t_minus_1d', '..t-1d', '..');
        if (First <= 2) and (Last >= 2) then
            BqProbe(Observer, Helper, Prefix + '_dotdot_t_minus_1t', '..t-1t', '..');
        if (First <= 3) and (Last >= 3) then
            BqProbe(Observer, Helper, Prefix + '_t_plus_1d', 't+1d', '');
        if (First <= 4) and (Last >= 4) then
            BqProbe(Observer, Helper, Prefix + '_h', 'h', '');
        if (First <= 5) and (Last >= 5) then
            BqProbe(Observer, Helper, Prefix + '_a', 'a', '');
        if (First <= 6) and (Last >= 6) then
            BqProbe(Observer, Helper, Prefix + '_j', 'j', '');
        WorkDate(OldWorkDate);
    end;

    [Test]
    procedure P143_LocalizedFormulas_Arithmetic_BQ()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P143 Helper";
    begin
        Helper.Seed();
        BqRunFormulas(Observer, Helper, 'en', 1, 6);
        Observer.Expect('en_dotdot_t_minus_1d', 'ok ..today-1');
        Observer.Expect('en_dotdot_t_minus_1t_err|text', 'The filter "..t-1t" is not valid for the D field on the LT P143 Row table. The format of the Date ''t-1t'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('en_dotdot_t_minus_1t_err|code', 'Filter:CSide');
        Observer.Expect('en_t_plus_1d', 'ok today1');
        Observer.Expect('en_h_err|text', 'The filter "h" is not valid for the D field on the LT P143 Row table. The format of the Date ''h'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('en_h_err|code', 'Filter:CSide');
        Observer.Expect('en_a_err|text', 'The filter "a" is not valid for the D field on the LT P143 Row table. The format of the Date ''a'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('en_a_err|code', 'Filter:CSide');
        Observer.Expect('en_j_err|text', 'The filter "j" is not valid for the D field on the LT P143 Row table. The format of the Date ''j'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('en_j_err|code', 'Filter:CSide');
        Observer.Verify();
    end;

    local procedure BqGerman(var Observer: Codeunit "Probe Observer"; First: Integer; Last: Integer)
    var
        Helper: Codeunit "LT P143 Helper";
        OldLanguage: Integer;
    begin
        Helper.Seed();
        OldLanguage := GlobalLanguage();
        GlobalLanguage(1031);
        BqRunFormulas(Observer, Helper, 'de', First, Last);
        GlobalLanguage(OldLanguage);
    end;

    local procedure BqFrenchCanada(var Observer: Codeunit "Probe Observer"; First: Integer; Last: Integer)
    var
        Helper: Codeunit "LT P143 Helper";
        OldLanguage: Integer;
    begin
        Helper.Seed();
        OldLanguage := GlobalLanguage();
        if BqTryLanguage(3084) then begin
            Observer.Observe('frca_language', 'ok');
            BqRunFormulas(Observer, Helper, 'frca', First, Last);
        end else
            Observer.ObserveError('frca_language');
        GlobalLanguage(OldLanguage);
        Observer.Observe('language_restored', Format(GlobalLanguage() = OldLanguage));
    end;

    [Test]
    procedure P143_LocalizedFormulas_German_First_BQ()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BqGerman(Observer, 1, 3);
        Observer.Expect('de_dotdot_t_minus_1d_err|text', 'Der Filter ''..t-1d'' ist für das Feld ''D'' der Tabelle ''LT P143 Row'' nicht gültig. Das Format Date „t-1d“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.');
        Observer.Expect('de_dotdot_t_minus_1d_err|code', 'Filter:CSide');
        Observer.Expect('de_dotdot_t_minus_1t', 'ok ..today-1');
        Observer.Expect('de_t_plus_1d_err|text', 'Der Filter ''t+1d'' ist für das Feld ''D'' der Tabelle ''LT P143 Row'' nicht gültig. Das Format Date „t+1d“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.');
        Observer.Expect('de_t_plus_1d_err|code', 'Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure P143_LocalizedFormulas_German_Last_BQ()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BqGerman(Observer, 4, 6);
        Observer.Expect('de_h', 'ok today0');
        Observer.Expect('de_a', 'ok workdate0');
        Observer.Expect('de_j', 'ok today0');
        Observer.Verify();
    end;

    [Test]
    procedure P143_LocalizedFormulas_FrenchCanada_First_BQ()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BqFrenchCanada(Observer, 1, 3);
        Observer.Expect('frca_language', 'ok');
        Observer.Expect('frca_dotdot_t_minus_1d_err|text', 'The filter "..t-1d" is not valid for the D field on the LT P143 Row table. The format of the Date ''t-1d'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('frca_dotdot_t_minus_1d_err|code', 'Filter:CSide');
        Observer.Expect('frca_dotdot_t_minus_1t', 'ok ..today-1Q');
        Observer.Expect('frca_t_plus_1d_err|text', 'The filter "t+1d" is not valid for the D field on the LT P143 Row table. The format of the Date ''t+1d'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('frca_t_plus_1d_err|code', 'Filter:CSide');
        Observer.Expect('language_restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P143_LocalizedFormulas_FrenchCanada_Last_BQ()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BqFrenchCanada(Observer, 4, 6);
        Observer.Expect('frca_language', 'ok');
        Observer.Expect('frca_h', 'ok today-1');
        Observer.Expect('frca_a', 'ok today0');
        Observer.Expect('frca_j', 'ok workdate1');
        Observer.Expect('language_restored', 'Yes');
        Observer.Verify();
    end;
}
