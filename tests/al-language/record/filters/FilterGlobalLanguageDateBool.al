// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope. SetFilter on a Date field with date texts, and on a Boolean field with Yes/No words, under GlobalLanguage 1030, 1036, 1044 and 1053 (the session region stays en-US).
// Fixtures used: Probe Observer (codeunit 69160); own objects 75407-75408 (LT GL LF Row, LT GL Filter Language)
// Probe: from al-runner issues 8178, 8182, 8183, 8197, 8199 and 8200 (an outside reporter measured BC 28.4 W1, en-US region). Observed on
//   Windows BC containers 27.5, 28.5 and 29.0; every literal asserted below is what BC produced. The corpus CI matrix checks it on BC on Linux.
// Facts (identical on 27.5, 28.5 and 29.0):
//   - Date filters keep the en-US region form under every language: 2024-03-15, 03/15/24, 031524, 03152024 and ranges work;
//     15.03.2024, 15-03-2024 and 150324 raise the localized "does not match your device's date settings" error (code Filter:CSide).
//     GetFilter shows the en-US form.
//   - A closing-date filter needs the letter of the current language (C under 1033 and 1036, U under 1030, 1031, 1044, S under
//     1053); any other letter raises the same error.
//   - Boolean filters accept the words of the current language (any case), true/false and 1/0; GetFilter shows the local word.
//     Words of other languages (Yes, No, Oui, Sand, and Nei under 1030 and 1053, Nej under 1044) raise the localized "can't be
//     evaluated into type Boolean" error. SetRange then GetFilter gives the local word, and SetFilter of that word selects the same rows.
// BC versions: 27, 28, 29

table 75407 "LT GL LF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Doc Date"; Date) { }
        field(3; Active; Boolean) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 75408 "LT GL Filter Language"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetFilter(var Row: Record "LT GL LF Row"; FieldNo: Integer; Filter: Text)
    begin
        if FieldNo = 2 then
            Row.SetFilter("Doc Date", Filter)
        else
            Row.SetFilter(Active, Filter);
    end;

    local procedure Add(var Row: Record "LT GL LF Row"; RowCode: Code[20]; D: Date; IsActive: Boolean)
    begin
        Row."Code" := RowCode;
        Row."Doc Date" := D;
        Row.Active := IsActive;
        Row.Insert();
    end;

    // Rows: A001 2024-03-15 true, A002 2024-03-16 true, B001 2023-12-31 false, B002 closing 2023-12-31 true, C001 2024-03-14 false.
    local procedure Seed()
    var
        Row: Record "LT GL LF Row";
    begin
        Row.DeleteAll();
        Add(Row, 'A001', DMY2Date(15, 3, 2024), true);
        Add(Row, 'A002', DMY2Date(16, 3, 2024), true);
        Add(Row, 'B001', DMY2Date(31, 12, 2023), false);
        Add(Row, 'B002', ClosingDate(DMY2Date(31, 12, 2023)), true);
        Add(Row, 'C001', DMY2Date(14, 3, 2024), false);
    end;

    // ok|GetFilter|the codes the filter selects, or the error text and code
    local procedure Probe(FieldNo: Integer; Filter: Text): Text
    var
        Row: Record "LT GL LF Row";
        Codes: Text;
        Shown: Text;
    begin
        ClearLastError();
        if not TrySetFilter(Row, FieldNo, Filter) then
            exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        if FieldNo = 2 then
            Shown := Row.GetFilter("Doc Date")
        else
            Shown := Row.GetFilter(Active);
        if Row.FindSet() then
            repeat
                Codes += Row."Code" + ',';
            until Row.Next() = 0;
        exit('ok|' + Shown + '|' + Codes);
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Lang: Integer; FieldNo: Integer; Filters: List of [Text])
    var
        Results: List of [Text];
        F: Text;
        I: Integer;
    begin
        Seed();
        GlobalLanguage(Lang);
        foreach F in Filters do
            Results.Add(Probe(FieldNo, F));
        GlobalLanguage(1033);
        for I := 1 to Filters.Count() do
            Observer.Observe('[' + Filters.Get(I) + ']', Results.Get(I));
    end;

    local procedure DateLocalForms(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Filters: List of [Text];
    begin
        Filters.AddRange('15.03.2024', '15-03-2024..', '150324');
        Run(Observer, Lang, 2, Filters);
    end;

    local procedure DateRegionForms(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Filters: List of [Text];
    begin
        Filters.AddRange('2024-03-15', '03/15/24', '031524', '03152024', '03/14/24..03/15/24', 'C12/31/23', '12/31/23');
        Run(Observer, Lang, 2, Filters);
    end;

    local procedure DateClosingLetters(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Filters: List of [Text];
    begin
        Filters.AddRange('U12/31/23', 'S12/31/23');
        Run(Observer, Lang, 2, Filters);
    end;

    local procedure BooleanWords(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Filters: List of [Text];
    begin
        Filters.AddRange('Ja', 'ja', 'Nej', 'Nei', 'true', 'False', '1', '0', 'Ja|Nej');
        Run(Observer, Lang, 3, Filters);
    end;

    local procedure BooleanForeignWords(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Filters: List of [Text];
    begin
        Filters.AddRange('Yes', 'No', 'Oui', 'Sand');
        Run(Observer, Lang, 3, Filters);
    end;

    local procedure BooleanRoundTrip(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Row: Record "LT GL LF Row";
        FalseText: Text;
        TrueText: Text;
        Back: Text;
        BackTrue: Text;
    begin
        Seed();
        GlobalLanguage(Lang);
        Row.SetRange(Active, false);
        FalseText := Row.GetFilter(Active);
        Row.SetRange(Active, true);
        TrueText := Row.GetFilter(Active);
        Back := Probe(3, FalseText);
        BackTrue := Probe(3, TrueText);
        GlobalLanguage(1033);
        Observer.Observe('GetFilter of SetRange false', FalseText);
        Observer.Observe('GetFilter of SetRange true', TrueText);
        Observer.Observe('SetFilter of the false text', Back);
        Observer.Observe('SetFilter of the true text', BackTrue);
    end;

    [Test]
    procedure DateFilter_LocalForms_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLocalForms(Observer, 1030);
        Observer.Expect('[15.03.2024]', 'error:Filteret "15.03.2024" er ikke gyldigt for feltet Doc Date i tabellen LT GL LF Row. Formatet for Date ''15.03.2024'' stemmer ikke overens med enhedens datoindstillinger.\\Kontroller, at dagen, måneden og året er i den rigtige rækkefølge, og brug den korrekte separator (f.eks. - eller /). Du kan også altid bruge formatet ''åååå-mm-dd''.|Filter:CSide');
        Observer.Expect('[15-03-2024..]', 'error:Filteret "15-03-2024.." er ikke gyldigt for feltet Doc Date i tabellen LT GL LF Row. Formatet for Date ''15-03-2024'' stemmer ikke overens med enhedens datoindstillinger.\\Kontroller, at dagen, måneden og året er i den rigtige rækkefølge, og brug den korrekte separator (f.eks. - eller /). Du kan også altid bruge formatet ''åååå-mm-dd''.|Filter:CSide');
        Observer.Expect('[150324]', 'error:Filteret "150324" er ikke gyldigt for feltet Doc Date i tabellen LT GL LF Row. Formatet for Date ''150324'' stemmer ikke overens med enhedens datoindstillinger.\\Kontroller, at dagen, måneden og året er i den rigtige rækkefølge, og brug den korrekte separator (f.eks. - eller /). Du kan også altid bruge formatet ''åååå-mm-dd''.|Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure DateFilter_LocalForms_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLocalForms(Observer, 1031);
        Observer.Expect('[15.03.2024]', 'error:Der Filter ''15.03.2024'' ist für das Feld ''Doc Date'' der Tabelle ''LT GL LF Row'' nicht gültig. Das Format Date „15.03.2024“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.|Filter:CSide');
        Observer.Expect('[15-03-2024..]', 'error:Der Filter ''15-03-2024..'' ist für das Feld ''Doc Date'' der Tabelle ''LT GL LF Row'' nicht gültig. Das Format Date „15-03-2024“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.|Filter:CSide');
        Observer.Expect('[150324]', 'error:Der Filter ''150324'' ist für das Feld ''Doc Date'' der Tabelle ''LT GL LF Row'' nicht gültig. Das Format Date „150324“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.|Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure DateFilter_LocalForms_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLocalForms(Observer, 1036);
        Observer.Expect('[15.03.2024]', 'error:Le filtre « 15.03.2024 » n''est pas valide pour le champ Doc Date de la table LT GL LF Row. Le format de Date « 15.03.2024 » ne correspond pas aux paramètres de date de votre appareil.\\Assurez-vous que le jour, le mois et l''année sont dans le bon ordre et utilisez le séparateur correct (par exemple, - ou /). Sinon, vous pouvez également utiliser le format « aaaa-mm-jj ».|Filter:CSide');
        Observer.Expect('[15-03-2024..]', 'error:Le filtre « 15-03-2024.. » n''est pas valide pour le champ Doc Date de la table LT GL LF Row. Le format de Date « 15-03-2024 » ne correspond pas aux paramètres de date de votre appareil.\\Assurez-vous que le jour, le mois et l''année sont dans le bon ordre et utilisez le séparateur correct (par exemple, - ou /). Sinon, vous pouvez également utiliser le format « aaaa-mm-jj ».|Filter:CSide');
        Observer.Expect('[150324]', 'error:Le filtre « 150324 » n''est pas valide pour le champ Doc Date de la table LT GL LF Row. Le format de Date « 150324 » ne correspond pas aux paramètres de date de votre appareil.\\Assurez-vous que le jour, le mois et l''année sont dans le bon ordre et utilisez le séparateur correct (par exemple, - ou /). Sinon, vous pouvez également utiliser le format « aaaa-mm-jj ».|Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure DateFilter_LocalForms_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLocalForms(Observer, 1044);
        Observer.Expect('[15.03.2024]', 'error:Filteret 15.03.2024 er ikke gyldig for feltet Doc Date i tabellen LT GL LF Row. Formatet på Date 15.03.2024 samsvarer ikke med enhetens datoinnstillinger.\\Kontroller at dagen, måneden og året er i riktig rekkefølge, og at du bruker riktig skilletegn (for eksempel - eller /). Alternativt kan du alltids bruke formatet åååå-mm-dd.|Filter:CSide');
        Observer.Expect('[15-03-2024..]', 'error:Filteret 15-03-2024.. er ikke gyldig for feltet Doc Date i tabellen LT GL LF Row. Formatet på Date 15-03-2024 samsvarer ikke med enhetens datoinnstillinger.\\Kontroller at dagen, måneden og året er i riktig rekkefølge, og at du bruker riktig skilletegn (for eksempel - eller /). Alternativt kan du alltids bruke formatet åååå-mm-dd.|Filter:CSide');
        Observer.Expect('[150324]', 'error:Filteret 150324 er ikke gyldig for feltet Doc Date i tabellen LT GL LF Row. Formatet på Date 150324 samsvarer ikke med enhetens datoinnstillinger.\\Kontroller at dagen, måneden og året er i riktig rekkefølge, og at du bruker riktig skilletegn (for eksempel - eller /). Alternativt kan du alltids bruke formatet åååå-mm-dd.|Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure DateFilter_LocalForms_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLocalForms(Observer, 1053);
        Observer.Expect('[15.03.2024]', 'error:Filtret 15.03.2024 är inte giltigt för fältet Doc Date i tabellen LT GL LF Row. Formatet på Date "15.03.2024" stämmer inte överens med enhetens datuminställningar.\\Kontrollera att dag, månad och år är i rätt ordning och har rätt avgränsare (som – eller /). Alternativt kan du alltid använda formatet "åååå–mm–dd".|Filter:CSide');
        Observer.Expect('[15-03-2024..]', 'error:Filtret 15-03-2024.. är inte giltigt för fältet Doc Date i tabellen LT GL LF Row. Formatet på Date "15-03-2024" stämmer inte överens med enhetens datuminställningar.\\Kontrollera att dag, månad och år är i rätt ordning och har rätt avgränsare (som – eller /). Alternativt kan du alltid använda formatet "åååå–mm–dd".|Filter:CSide');
        Observer.Expect('[150324]', 'error:Filtret 150324 är inte giltigt för fältet Doc Date i tabellen LT GL LF Row. Formatet på Date "150324" stämmer inte överens med enhetens datuminställningar.\\Kontrollera att dag, månad och år är i rätt ordning och har rätt avgränsare (som – eller /). Alternativt kan du alltid använda formatet "åååå–mm–dd".|Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure DateFilter_RegionForms_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateRegionForms(Observer, 1030);
        Observer.Expect('[2024-03-15]', 'ok|03/15/24|A001,');
        Observer.Expect('[03/15/24]', 'ok|03/15/24|A001,');
        Observer.Expect('[031524]', 'ok|03/15/24|A001,');
        Observer.Expect('[03152024]', 'ok|03/15/24|A001,');
        Observer.Expect('[03/14/24..03/15/24]', 'ok|03/14/24..03/15/24|A001,C001,');
        Observer.Expect('[C12/31/23]', 'error:Filteret "C12/31/23" er ikke gyldigt for feltet Doc Date i tabellen LT GL LF Row. Formatet for Date ''C12/31/23'' stemmer ikke overens med enhedens datoindstillinger.\\Kontroller, at dagen, måneden og året er i den rigtige rækkefølge, og brug den korrekte separator (f.eks. - eller /). Du kan også altid bruge formatet ''åååå-mm-dd''.|Filter:CSide');
        Observer.Expect('[12/31/23]', 'ok|12/31/23|B001,');
        Observer.Verify();
    end;

    [Test]
    procedure DateFilter_RegionForms_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateRegionForms(Observer, 1031);
        Observer.Expect('[2024-03-15]', 'ok|03/15/24|A001,');
        Observer.Expect('[03/15/24]', 'ok|03/15/24|A001,');
        Observer.Expect('[031524]', 'ok|03/15/24|A001,');
        Observer.Expect('[03152024]', 'ok|03/15/24|A001,');
        Observer.Expect('[03/14/24..03/15/24]', 'ok|03/14/24..03/15/24|A001,C001,');
        Observer.Expect('[C12/31/23]', 'error:Der Filter ''C12/31/23'' ist für das Feld ''Doc Date'' der Tabelle ''LT GL LF Row'' nicht gültig. Das Format Date „C12/31/23“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.|Filter:CSide');
        Observer.Expect('[12/31/23]', 'ok|12/31/23|B001,');
        Observer.Verify();
    end;

    [Test]
    procedure DateFilter_RegionForms_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateRegionForms(Observer, 1036);
        Observer.Expect('[2024-03-15]', 'ok|03/15/24|A001,');
        Observer.Expect('[03/15/24]', 'ok|03/15/24|A001,');
        Observer.Expect('[031524]', 'ok|03/15/24|A001,');
        Observer.Expect('[03152024]', 'ok|03/15/24|A001,');
        Observer.Expect('[03/14/24..03/15/24]', 'ok|03/14/24..03/15/24|A001,C001,');
        Observer.Expect('[C12/31/23]', 'ok|C12/31/23|B002,');
        Observer.Expect('[12/31/23]', 'ok|12/31/23|B001,');
        Observer.Verify();
    end;

    [Test]
    procedure DateFilter_RegionForms_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateRegionForms(Observer, 1044);
        Observer.Expect('[2024-03-15]', 'ok|03/15/24|A001,');
        Observer.Expect('[03/15/24]', 'ok|03/15/24|A001,');
        Observer.Expect('[031524]', 'ok|03/15/24|A001,');
        Observer.Expect('[03152024]', 'ok|03/15/24|A001,');
        Observer.Expect('[03/14/24..03/15/24]', 'ok|03/14/24..03/15/24|A001,C001,');
        Observer.Expect('[C12/31/23]', 'error:Filteret C12/31/23 er ikke gyldig for feltet Doc Date i tabellen LT GL LF Row. Formatet på Date C12/31/23 samsvarer ikke med enhetens datoinnstillinger.\\Kontroller at dagen, måneden og året er i riktig rekkefølge, og at du bruker riktig skilletegn (for eksempel - eller /). Alternativt kan du alltids bruke formatet åååå-mm-dd.|Filter:CSide');
        Observer.Expect('[12/31/23]', 'ok|12/31/23|B001,');
        Observer.Verify();
    end;

    [Test]
    procedure DateFilter_RegionForms_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateRegionForms(Observer, 1053);
        Observer.Expect('[2024-03-15]', 'ok|03/15/24|A001,');
        Observer.Expect('[03/15/24]', 'ok|03/15/24|A001,');
        Observer.Expect('[031524]', 'ok|03/15/24|A001,');
        Observer.Expect('[03152024]', 'ok|03/15/24|A001,');
        Observer.Expect('[03/14/24..03/15/24]', 'ok|03/14/24..03/15/24|A001,C001,');
        Observer.Expect('[C12/31/23]', 'error:Filtret C12/31/23 är inte giltigt för fältet Doc Date i tabellen LT GL LF Row. Formatet på Date "C12/31/23" stämmer inte överens med enhetens datuminställningar.\\Kontrollera att dag, månad och år är i rätt ordning och har rätt avgränsare (som – eller /). Alternativt kan du alltid använda formatet "åååå–mm–dd".|Filter:CSide');
        Observer.Expect('[12/31/23]', 'ok|12/31/23|B001,');
        Observer.Verify();
    end;

    [Test]
    procedure DateFilter_ClosingLetters_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateClosingLetters(Observer, 1033);
        Observer.Expect('[U12/31/23]', 'error:The filter "U12/31/23" is not valid for the Doc Date field on the LT GL LF Row table. The format of the Date ''U12/31/23'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('[S12/31/23]', 'error:The filter "S12/31/23" is not valid for the Doc Date field on the LT GL LF Row table. The format of the Date ''S12/31/23'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure DateFilter_ClosingLetters_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateClosingLetters(Observer, 1030);
        Observer.Expect('[U12/31/23]', 'ok|U12/31/23|B002,');
        Observer.Expect('[S12/31/23]', 'error:Filteret "S12/31/23" er ikke gyldigt for feltet Doc Date i tabellen LT GL LF Row. Formatet for Date ''S12/31/23'' stemmer ikke overens med enhedens datoindstillinger.\\Kontroller, at dagen, måneden og året er i den rigtige rækkefølge, og brug den korrekte separator (f.eks. - eller /). Du kan også altid bruge formatet ''åååå-mm-dd''.|Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure DateFilter_ClosingLetters_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateClosingLetters(Observer, 1031);
        Observer.Expect('[U12/31/23]', 'ok|U12/31/23|B002,');
        Observer.Expect('[S12/31/23]', 'error:Der Filter ''S12/31/23'' ist für das Feld ''Doc Date'' der Tabelle ''LT GL LF Row'' nicht gültig. Das Format Date „S12/31/23“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.|Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure DateFilter_ClosingLetters_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateClosingLetters(Observer, 1036);
        Observer.Expect('[U12/31/23]', 'error:Le filtre « U12/31/23 » n''est pas valide pour le champ Doc Date de la table LT GL LF Row. Le format de Date « U12/31/23 » ne correspond pas aux paramètres de date de votre appareil.\\Assurez-vous que le jour, le mois et l''année sont dans le bon ordre et utilisez le séparateur correct (par exemple, - ou /). Sinon, vous pouvez également utiliser le format « aaaa-mm-jj ».|Filter:CSide');
        Observer.Expect('[S12/31/23]', 'error:Le filtre « S12/31/23 » n''est pas valide pour le champ Doc Date de la table LT GL LF Row. Le format de Date « S12/31/23 » ne correspond pas aux paramètres de date de votre appareil.\\Assurez-vous que le jour, le mois et l''année sont dans le bon ordre et utilisez le séparateur correct (par exemple, - ou /). Sinon, vous pouvez également utiliser le format « aaaa-mm-jj ».|Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure DateFilter_ClosingLetters_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateClosingLetters(Observer, 1044);
        Observer.Expect('[U12/31/23]', 'ok|U12/31/23|B002,');
        Observer.Expect('[S12/31/23]', 'error:Filteret S12/31/23 er ikke gyldig for feltet Doc Date i tabellen LT GL LF Row. Formatet på Date S12/31/23 samsvarer ikke med enhetens datoinnstillinger.\\Kontroller at dagen, måneden og året er i riktig rekkefølge, og at du bruker riktig skilletegn (for eksempel - eller /). Alternativt kan du alltids bruke formatet åååå-mm-dd.|Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure DateFilter_ClosingLetters_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateClosingLetters(Observer, 1053);
        Observer.Expect('[U12/31/23]', 'error:Filtret U12/31/23 är inte giltigt för fältet Doc Date i tabellen LT GL LF Row. Formatet på Date "U12/31/23" stämmer inte överens med enhetens datuminställningar.\\Kontrollera att dag, månad och år är i rätt ordning och har rätt avgränsare (som – eller /). Alternativt kan du alltid använda formatet "åååå–mm–dd".|Filter:CSide');
        Observer.Expect('[S12/31/23]', 'ok|S12/31/23|B002,');
        Observer.Verify();
    end;

    [Test]
    procedure BoolFilter_Words_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BooleanWords(Observer, 1030);
        Observer.Expect('[Ja]', 'ok|Ja|A001,A002,B002,');
        Observer.Expect('[ja]', 'ok|Ja|A001,A002,B002,');
        Observer.Expect('[Nej]', 'ok|Nej|B001,C001,');
        Observer.Expect('[Nei]', 'error:Filteret "Nei" er ikke gyldigt for feltet Active i tabellen LT GL LF Row. Værdien "Nei" kan ikke evalueres til typen Boolean.|Filter:CSide');
        Observer.Expect('[true]', 'ok|Ja|A001,A002,B002,');
        Observer.Expect('[False]', 'ok|Nej|B001,C001,');
        Observer.Expect('[1]', 'ok|Ja|A001,A002,B002,');
        Observer.Expect('[0]', 'ok|Nej|B001,C001,');
        Observer.Expect('[Ja|Nej]', 'ok|Ja|Nej|A001,A002,B001,B002,C001,');
        Observer.Verify();
    end;

    [Test]
    procedure BoolFilter_Words_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BooleanWords(Observer, 1044);
        Observer.Expect('[Ja]', 'ok|Ja|A001,A002,B002,');
        Observer.Expect('[ja]', 'ok|Ja|A001,A002,B002,');
        Observer.Expect('[Nej]', 'error:Filteret Nej er ikke gyldig for feltet Active i tabellen LT GL LF Row. Verdien Nej kan ikke evalueres til typen Boolean.|Filter:CSide');
        Observer.Expect('[Nei]', 'ok|Nei|B001,C001,');
        Observer.Expect('[true]', 'ok|Ja|A001,A002,B002,');
        Observer.Expect('[False]', 'ok|Nei|B001,C001,');
        Observer.Expect('[1]', 'ok|Ja|A001,A002,B002,');
        Observer.Expect('[0]', 'ok|Nei|B001,C001,');
        Observer.Expect('[Ja|Nej]', 'error:Filteret Ja|Nej er ikke gyldig for feltet Active i tabellen LT GL LF Row. Verdien Nej kan ikke evalueres til typen Boolean.|Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure BoolFilter_Words_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BooleanWords(Observer, 1053);
        Observer.Expect('[Ja]', 'ok|Ja|A001,A002,B002,');
        Observer.Expect('[ja]', 'ok|Ja|A001,A002,B002,');
        Observer.Expect('[Nej]', 'ok|Nej|B001,C001,');
        Observer.Expect('[Nei]', 'error:Filtret Nei är inte giltigt för fältet Active i tabellen LT GL LF Row. Det går inte att utvärdera värdet Nei till typen Boolean.|Filter:CSide');
        Observer.Expect('[true]', 'ok|Ja|A001,A002,B002,');
        Observer.Expect('[False]', 'ok|Nej|B001,C001,');
        Observer.Expect('[1]', 'ok|Ja|A001,A002,B002,');
        Observer.Expect('[0]', 'ok|Nej|B001,C001,');
        Observer.Expect('[Ja|Nej]', 'ok|Ja|Nej|A001,A002,B001,B002,C001,');
        Observer.Verify();
    end;

    [Test]
    procedure BoolFilter_ForeignWords_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BooleanForeignWords(Observer, 1030);
        Observer.Expect('[Yes]', 'error:Filteret "Yes" er ikke gyldigt for feltet Active i tabellen LT GL LF Row. Værdien "Yes" kan ikke evalueres til typen Boolean.|Filter:CSide');
        Observer.Expect('[No]', 'error:Filteret "No" er ikke gyldigt for feltet Active i tabellen LT GL LF Row. Værdien "No" kan ikke evalueres til typen Boolean.|Filter:CSide');
        Observer.Expect('[Oui]', 'error:Filteret "Oui" er ikke gyldigt for feltet Active i tabellen LT GL LF Row. Værdien "Oui" kan ikke evalueres til typen Boolean.|Filter:CSide');
        Observer.Expect('[Sand]', 'error:Filteret "Sand" er ikke gyldigt for feltet Active i tabellen LT GL LF Row. Værdien "Sand" kan ikke evalueres til typen Boolean.|Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure BoolFilter_ForeignWords_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BooleanForeignWords(Observer, 1044);
        Observer.Expect('[Yes]', 'error:Filteret Yes er ikke gyldig for feltet Active i tabellen LT GL LF Row. Verdien Yes kan ikke evalueres til typen Boolean.|Filter:CSide');
        Observer.Expect('[No]', 'error:Filteret No er ikke gyldig for feltet Active i tabellen LT GL LF Row. Verdien No kan ikke evalueres til typen Boolean.|Filter:CSide');
        Observer.Expect('[Oui]', 'error:Filteret Oui er ikke gyldig for feltet Active i tabellen LT GL LF Row. Verdien Oui kan ikke evalueres til typen Boolean.|Filter:CSide');
        Observer.Expect('[Sand]', 'error:Filteret Sand er ikke gyldig for feltet Active i tabellen LT GL LF Row. Verdien Sand kan ikke evalueres til typen Boolean.|Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure BoolFilter_ForeignWords_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BooleanForeignWords(Observer, 1053);
        Observer.Expect('[Yes]', 'error:Filtret Yes är inte giltigt för fältet Active i tabellen LT GL LF Row. Det går inte att utvärdera värdet Yes till typen Boolean.|Filter:CSide');
        Observer.Expect('[No]', 'error:Filtret No är inte giltigt för fältet Active i tabellen LT GL LF Row. Det går inte att utvärdera värdet No till typen Boolean.|Filter:CSide');
        Observer.Expect('[Oui]', 'error:Filtret Oui är inte giltigt för fältet Active i tabellen LT GL LF Row. Det går inte att utvärdera värdet Oui till typen Boolean.|Filter:CSide');
        Observer.Expect('[Sand]', 'error:Filtret Sand är inte giltigt för fältet Active i tabellen LT GL LF Row. Det går inte att utvärdera värdet Sand till typen Boolean.|Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure BoolFilter_RoundTrip_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BooleanRoundTrip(Observer, 1030);
        Observer.Expect('GetFilter of SetRange false', 'Nej');
        Observer.Expect('GetFilter of SetRange true', 'Ja');
        Observer.Expect('SetFilter of the false text', 'ok|Nej|B001,C001,');
        Observer.Expect('SetFilter of the true text', 'ok|Ja|A001,A002,B002,');
        Observer.Verify();
    end;

    [Test]
    procedure BoolFilter_RoundTrip_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BooleanRoundTrip(Observer, 1044);
        Observer.Expect('GetFilter of SetRange false', 'Nei');
        Observer.Expect('GetFilter of SetRange true', 'Ja');
        Observer.Expect('SetFilter of the false text', 'ok|Nei|B001,C001,');
        Observer.Expect('SetFilter of the true text', 'ok|Ja|A001,A002,B002,');
        Observer.Verify();
    end;

    [Test]
    procedure BoolFilter_RoundTrip_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BooleanRoundTrip(Observer, 1053);
        Observer.Expect('GetFilter of SetRange false', 'Nej');
        Observer.Expect('GetFilter of SetRange true', 'Ja');
        Observer.Expect('SetFilter of the false text', 'ok|Nej|B001,C001,');
        Observer.Expect('SetFilter of the true text', 'ok|Ja|A001,A002,B002,');
        Observer.Verify();
    end;
}
