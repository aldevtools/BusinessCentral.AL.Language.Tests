// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: table 74647 and codeunit 74648 (P143Fixtures.al), codeunit 69160 "Probe Observer"
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74653 "LT P143 DePlain"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P143_DePlain()
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
        Observer.Expect('d_0117_27_err|text', 'Der Filter ''17.01.27'' ist für das Feld ''D'' der Tabelle ''LT P143 Row'' nicht gültig. Das Format Date „17.01.27“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.');
        Observer.Expect('d_0117_27_err|code', 'Filter:CSide');
        Observer.Expect('d_closing_1018_26_err|text', 'Der Filter ''C18.10.26'' ist für das Feld ''D'' der Tabelle ''LT P143 Row'' nicht gültig. Das Format Date „C18.10.26“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.');
        Observer.Expect('d_closing_1018_26_err|code', 'Filter:CSide');
        Observer.Expect('d_max_err|text', 'Der Filter ''31.12.9999'' ist für das Feld ''D'' der Tabelle ''LT P143 Row'' nicht gültig. Das Format Date „31.12.9999“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.');
        Observer.Expect('d_max_err|code', 'Filter:CSide');
        Observer.Expect('d_1_1_2027_filter', '01/01/27');
        Observer.Expect('d_1_1_2027_count', Format(1 + Helper.InRows(20270101D, 20270101D)));
        Observer.Expect('d_empty_filter', '');
        Observer.Expect('d_empty_count', '10');
        Observer.Expect('d_us_text_filter', '01/17/27');
        Observer.Expect('d_us_text_count', Format(1 + Helper.InRows(20270117D, 20270117D)));
        Observer.Expect('d_0117_2027_err|text', 'Der Filter ''17.01.2027'' ist für das Feld ''D'' der Tabelle ''LT P143 Row'' nicht gültig. Das Format Date „17.01.2027“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.');
        Observer.Expect('d_0117_2027_err|code', 'Filter:CSide');
        Observer.Expect('language_restored', 'Yes');
        Observer.Verify();
    end;





    // every statement that can raise sits inside the helper's TryFunctions, so Run cannot leave the language changed
    local procedure Run(var Observer: Codeunit "Probe Observer"; var Helper: Codeunit "LT P143 Helper")
    begin
        Helper.ProbeDate(Observer, 'd_0117_27', '17.01.27');
        Helper.ProbeDate(Observer, 'd_closing_1018_26', 'C18.10.26');
        Helper.ProbeDate(Observer, 'd_max', '31.12.9999');
        Helper.ProbeDate(Observer, 'd_1_1_2027', '1.1.2027');
        Helper.ProbeDate(Observer, 'd_empty', '');
        Helper.ProbeDate(Observer, 'd_us_text', '01/17/27');
        Helper.ProbeDate(Observer, 'd_0117_2027', '17.01.2027');
    end;
}
