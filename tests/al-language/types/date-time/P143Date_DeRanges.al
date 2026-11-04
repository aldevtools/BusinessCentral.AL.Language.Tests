// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: table 74647 and codeunit 74648 (P143Fixtures.al), codeunit 69160 "Probe Observer"
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74654 "LT P143 DeRanges"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P143_DeRanges()
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
        Observer.Expect('r_both_err|text', 'Der Filter ''01.01.27..31.01.27'' ist für das Feld ''D'' der Tabelle ''LT P143 Row'' nicht gültig. Das Format Date „31.01.27“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.');
        Observer.Expect('r_both_err|code', 'Filter:CSide');
        Observer.Expect('r_open_from_err|text', 'Der Filter ''..31.01.27'' ist für das Feld ''D'' der Tabelle ''LT P143 Row'' nicht gültig. Das Format Date „31.01.27“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.');
        Observer.Expect('r_open_from_err|code', 'Filter:CSide');
        Observer.Expect('r_open_to_err|text', 'Der Filter ''17.01.27..'' ist für das Feld ''D'' der Tabelle ''LT P143 Row'' nicht gültig. Das Format Date „17.01.27“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.');
        Observer.Expect('r_open_to_err|code', 'Filter:CSide');
        Observer.Expect('r_or_err|text', 'Der Filter ''17.01.27|18.10.26'' ist für das Feld ''D'' der Tabelle ''LT P143 Row'' nicht gültig. Das Format Date „17.01.27“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.');
        Observer.Expect('r_or_err|code', 'Filter:CSide');
        Observer.Expect('r_lt_err|text', 'Der Filter ''<17.01.27'' ist für das Feld ''D'' der Tabelle ''LT P143 Row'' nicht gültig. Das Format Date „17.01.27“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.');
        Observer.Expect('r_lt_err|code', 'Filter:CSide');
        Observer.Expect('r_ge_err|text', 'Der Filter ''>=31.01.27'' ist für das Feld ''D'' der Tabelle ''LT P143 Row'' nicht gültig. Das Format Date „31.01.27“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.');
        Observer.Expect('r_ge_err|code', 'Filter:CSide');
        Observer.Expect('r_us_range_filter', '01/01/27..01/31/27');
        Observer.Expect('r_us_range_count', Format(4 + Helper.InRows(20270101D, 20270131D)));
        Observer.Expect('language_restored', 'Yes');
        Observer.Verify();
    end;





    // every statement that can raise sits inside the helper's TryFunctions, so Run cannot leave the language changed
    local procedure Run(var Observer: Codeunit "Probe Observer"; var Helper: Codeunit "LT P143 Helper")
    begin
        Helper.ProbeDate(Observer, 'r_both', '01.01.27..31.01.27');
        Helper.ProbeDate(Observer, 'r_open_from', '..31.01.27');
        Helper.ProbeDate(Observer, 'r_open_to', '17.01.27..');
        Helper.ProbeDate(Observer, 'r_or', '17.01.27|18.10.26');
        Helper.ProbeDate(Observer, 'r_lt', '<17.01.27');
        Helper.ProbeDate(Observer, 'r_ge', '>=31.01.27');
        Helper.ProbeDate(Observer, 'r_us_range', '01/01/27..01/31/27');
    end;
}
